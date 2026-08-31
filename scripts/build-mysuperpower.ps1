#!/usr/bin/env pwsh
# build-mysuperpower.ps1
# Assemble the branded, HTML-native mySuperpower plugin into dist/ from the
# PRISTINE upstream source tree. The git-tracked source stays pristine (so
# upstream merges remain clean); every mySuperpower-specific transform happens
# here at build time.
#
# Steps: clean dist/ -> copy pristine plugin tree (excluding source-only dirs)
#   -> overlay README/CLAUDE -> apply per-skill HTML overlays (fail-loud anchors)
#   -> namespace + docs rebrand cascade -> apply manifest identity overrides
#   -> verify. Idempotent: safe to re-run.

[CmdletBinding()]
param(
  [string]$OutDir = "dist",
  [string]$OverlaysDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
# Both directory parameters accept an absolute path. Join-Path splices a rooted
# value onto the repo root instead of replacing it -- Join-Path 'C:\repo'
# 'C:\Temp\x' returns 'C:\repo\C:\Temp\x' -- so a test that builds into a
# temporary directory could never succeed without this.
$dist = if ([System.IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $root $OutDir }

function Fail([string]$msg) { Write-Error "build-mysuperpower: $msg"; exit 1 }

# Validate the output directory HERE, before step 1 removes it recursively.
# -OutDir naming the repository itself, or any ancestor of it, would otherwise
# delete the working copy outright: a containment check that runs later is
# already too late to prevent it.
#
# StartsWith is ordinal by default while Windows paths are case-insensitive, so
# 'c:\projects\...\nested\dist' would slip past an ordinal comparison against
# 'C:\Projects\...'. Compare the way the platform's filesystem does.
$sep = [System.IO.Path]::DirectorySeparatorChar
$cmp = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
$rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd($sep)
$distFull = [System.IO.Path]::GetFullPath($dist).TrimEnd($sep)

if ($distFull.Equals($rootFull, $cmp)) {
  Fail "OutDir must not be the repository itself: $distFull"
}
if ($rootFull.StartsWith($distFull + $sep, $cmp)) {
  Fail "OutDir must not be an ancestor of the repository: $distFull"
}
if ($distFull.StartsWith($rootFull + $sep, $cmp)) {
  $rel = $distFull.Substring($rootFull.Length + 1)
  if ($rel.Contains($sep)) {
    Fail "an OutDir inside the repo must be a direct child of it, got '$rel'"
  }
}

# An unvalidated copy step is a file-write primitive pointed at the build output.
# Every rule below fails the build loudly, naming the overlay and the entry.
function Test-RelSafe([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return $false }
  if ([System.IO.Path]::IsPathRooted($p)) { return $false }
  if ($p -match '(^|[\\/])\.\.([\\/]|$)') { return $false }
  return $true
}

function Copy-OverlayFiles($cfg, [string]$overlayRoot, [hashtable]$declared) {
  # $sep and $cmp come from the validation block at the top of the script. Both
  # containment tests below compare a path against the very prefix it was built
  # from, so an ordinal match would work today -- but these are the checks that
  # decide whether an arbitrary file can be written into the release, and they
  # should not depend on that reasoning staying true.
  $skillRoot = Join-Path $dist ("skills/{0}" -f $cfg.skill)
  $skillRootFull = (Resolve-Path -LiteralPath $skillRoot).ProviderPath
  $overlayRootFull = (Resolve-Path -LiteralPath $overlayRoot).ProviderPath

  foreach ($fe in $cfg.files) {
    foreach ($k in @('from', 'to')) {
      if ($fe.PSObject.Properties.Name -notcontains $k) {
        Fail ("overlay {0}: files entry is missing '{1}'" -f $cfg.skill, $k)
      }
    }
    $from = [string]$fe.from
    $to   = [string]$fe.to
    if (-not (Test-RelSafe $from)) {
      Fail ("overlay {0}: files 'from' must be a relative path with no '..': '{1}'" -f $cfg.skill, $from)
    }
    if (-not (Test-RelSafe $to)) {
      Fail ("overlay {0}: files 'to' must be a relative path with no '..': '{1}'" -f $cfg.skill, $to)
    }
    if ($fe.PSObject.Properties.Name -contains 'exec') {
      if ($fe.exec -isnot [bool]) {
        Fail ("overlay {0}: files entry '{1}' has a non-boolean exec" -f $cfg.skill, $to)
      }
    }

    $src = Join-Path $overlayRootFull $from
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
      Fail ("overlay {0}: files 'from' is not an existing file: {1}" -f $cfg.skill, $src)
    }
    $srcFull = (Resolve-Path -LiteralPath $src).ProviderPath
    if (-not $srcFull.StartsWith($overlayRootFull + $sep, $cmp)) {
      Fail ("overlay {0}: files 'from' escapes the overlay directory: '{1}'" -f $cfg.skill, $from)
    }
    if (((Get-Item -LiteralPath $srcFull -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      Fail ("overlay {0}: files 'from' is a symlink, not a regular file: '{1}'" -f $cfg.skill, $from)
    }
    # The leaf check is not enough. Resolve-Path preserves a symlinked ANCESTOR
    # lexically, and Get-Item then inspects the real target leaf, so a path like
    # linkdir/secret satisfies the containment test above while pointing outside
    # the overlay entirely. Walk the ancestors up to the overlay root.
    $probe = Split-Path -Parent $srcFull
    while ($probe -and $probe.Length -gt $overlayRootFull.Length) {
      if (((Get-Item -LiteralPath $probe -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        Fail ("overlay {0}: files 'from' traverses a symlinked directory: '{1}'" -f $cfg.skill, $from)
      }
      $probe = Split-Path -Parent $probe
    }

    # Compare CANONICAL destinations: two overlays for different skills may both
    # legitimately ship scripts/helper, and those are different files.
    $destFull = [System.IO.Path]::GetFullPath((Join-Path $skillRootFull $to))
    if (-not $destFull.StartsWith($skillRootFull + $sep, $cmp)) {
      Fail ("overlay {0}: files 'to' escapes dist/skills/{0}: '{1}'" -f $cfg.skill, $to)
    }
    # Collision BEFORE existence, and the order carries the diagnosis. Each entry
    # is copied as it is validated, so by the time a duplicate is reached its
    # twin is already on disk -- checking existence first would report a
    # same-build collision as "overlays must not replace upstream files", which
    # names the wrong problem and points at a file this build wrote itself.
    if ($declared.ContainsKey($destFull)) {
      Fail ("overlay {0}: files 'to' collides with {1}: '{2}'" -f $cfg.skill, $declared[$destFull], $to)
    }
    if (Test-Path -LiteralPath $destFull) {
      Fail ("overlay {0}: files 'to' already exists in dist; overlays must not replace upstream files: '{1}'" -f $cfg.skill, $to)
    }

    $declared[$destFull] = ("{0}/{1}" -f $cfg.skill, $to)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destFull) | Out-Null
    Copy-Item -Force -LiteralPath $srcFull -Destination $destFull
    Write-Host ("overlay file: {0} -> skills/{1}/{2}" -f $from, $cfg.skill, $to)
  }
}

Write-Host "build-mysuperpower: root=$root"
Write-Host "build-mysuperpower: out=$dist"

# --- 1. Clean dist/ ---
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# --- 2. Copy pristine plugin tree into dist/, excluding source-only entries ---
#
# 'dist' is an UNCONDITIONAL exclusion, not a stand-in for $OutDir: it is this
# repo's generated output and is source-only for every build, including one
# writing somewhere else entirely. Replacing it with the resolved-path test
# alone would copy a stale plugin tree into every custom output directory --
# which is exactly what the capability test does, building outside the repo.
#
# The resolved-path test then covers the case no name-based exclusion can
# express: a custom $OutDir that IS inside the repo. $distFull, $sep and $cmp
# were computed during validation above.
$exclude = @('overlays', 'branding', 'scripts', 'docs', 'tests', '.git', '.github', '.baseline-skills', 'dist')
Get-ChildItem -Force -Path $root |
  Where-Object {
    $exclude -notcontains $_.Name -and
    -not ([System.IO.Path]::GetFullPath($_.FullName).TrimEnd($sep).Equals($distFull, $cmp))
  } |
  ForEach-Object { Copy-Item -Recurse -Force -Path $_.FullName -Destination (Join-Path $dist $_.Name) }

# --- 3. Overlay branded README / CLAUDE ---
Copy-Item -Force (Join-Path $root 'branding/README.md') (Join-Path $dist 'README.md')
Copy-Item -Force (Join-Path $root 'branding/CLAUDE.md')  (Join-Path $dist 'CLAUDE.md')

# A plugin source dir should not carry a marketplace catalog; that lives at the repo root.
$distMarket = Join-Path $dist '.claude-plugin/marketplace.json'
if (Test-Path $distMarket) { Remove-Item -Force $distMarket }

# --- 4. Apply per-skill HTML overlays (replaces + append + fork-owned files) ---
#
# Every fork-owned file an overlay ships is recorded here so step 7 can assert it
# actually landed. A silently skipped copy passes the plugin-name, skill-count and
# residual-namespace checks while shipping a SKILL.md that tells the controller to
# run a script which is not there.
$declaredFiles = @{}

$overlaysDir = if ($OverlaysDir) { $OverlaysDir } else { Join-Path $root 'overlays' }
if (Test-Path $overlaysDir) {
  foreach ($skillDir in (Get-ChildItem -Directory $overlaysDir)) {
    $cfgPath = Join-Path $skillDir.FullName 'overlay.json'
    if (-not (Test-Path $cfgPath)) { continue }
    $cfg = Get-Content -Raw $cfgPath | ConvertFrom-Json
    $skillFile = Join-Path $dist ("skills/{0}/SKILL.md" -f $cfg.skill)
    if (-not (Test-Path $skillFile)) { Fail "overlay target missing: $skillFile" }
    $content = Get-Content -Raw -LiteralPath $skillFile

    # Set-StrictMode -Version Latest turns a missing property into a throw, not a
    # null. Probe every optional key rather than testing it for truthiness.
    if ($cfg.PSObject.Properties.Name -contains 'replaces') {
      foreach ($r in $cfg.replaces) {
        if (-not $content.Contains($r.find)) {
          if ($r.required) { Fail ("required anchor not found in {0}: '{1}'" -f $cfg.skill, $r.find) }
          Write-Warning ("optional anchor not found in {0}: '{1}'" -f $cfg.skill, $r.find)
          continue
        }
        $content = $content.Replace($r.find, $r.replace)
      }
    }
    if (($cfg.PSObject.Properties.Name -contains 'append') -and $cfg.append) {
      $addPath = Join-Path $skillDir.FullName $cfg.append
      if (-not (Test-Path $addPath)) { Fail "append file missing: $addPath" }
      $add = Get-Content -Raw -LiteralPath $addPath
      $content = $content.TrimEnd() + "`n`n" + $add.TrimEnd() + "`n"
    }
    Set-Content -NoNewline -LiteralPath $skillFile -Value $content

    if ($cfg.PSObject.Properties.Name -contains 'files') {
      Copy-OverlayFiles $cfg $skillDir.FullName $declaredFiles
    }
    Write-Host ("overlay applied: {0}" -f $cfg.skill)
  }
}

# --- 5. Namespace + docs rebrand cascade over dist/skills and dist/hooks ---
$cascadeTargets = @()
$skillsDir = Join-Path $dist 'skills'
if (Test-Path $skillsDir) { $cascadeTargets += Get-ChildItem -Recurse -File $skillsDir }
$hookFile = Join-Path $dist 'hooks/session-start'
if (Test-Path $hookFile) { $cascadeTargets += Get-Item $hookFile }
foreach ($f in $cascadeTargets) {
  $orig = Get-Content -Raw -LiteralPath $f.FullName
  $new = $orig -replace 'superpowers:', 'my-superpower:'
  $new = $new -replace 'docs/superpowers/', 'docs/mySuperpower/'
  if ($new -ne $orig) { Set-Content -NoNewline -LiteralPath $f.FullName -Value $new }
}

# --- 6. Apply manifest identity overrides ---
$ov = Get-Content -Raw (Join-Path $root 'branding/manifest-overrides.json') | ConvertFrom-Json

function Set-JsonField($obj, [string]$name, $value) {
  if ($obj.PSObject.Properties.Name -contains $name) { $obj.$name = $value }
  else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
}
function Apply-Overrides([string]$path, $overrides) {
  if (-not (Test-Path $path)) { return }
  $j = Get-Content -Raw $path | ConvertFrom-Json
  foreach ($prop in $overrides.PSObject.Properties) { Set-JsonField $j $prop.Name $prop.Value }
  ($j | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $path
  Write-Host ("manifest overridden: {0}" -f (Resolve-Path -Relative $path))
}

foreach ($rel in $ov.pluginManifests) { Apply-Overrides (Join-Path $dist $rel) $ov.plugin }
Apply-Overrides (Join-Path $dist 'package.json') $ov.packageJson
Apply-Overrides (Join-Path $dist 'gemini-extension.json') $ov.geminiExtension

# --- 7. Verify ---
$pj = Join-Path $dist '.claude-plugin/plugin.json'
if (-not (Test-Path $pj)) { Fail "dist plugin manifest missing: $pj" }
$pjName = (Get-Content -Raw $pj | ConvertFrom-Json).name
if ($pjName -ne 'my-superpower') { Fail "expected dist plugin name 'my-superpower', got '$pjName'" }

$skillCount = @(Get-ChildItem -Recurse -File -Filter 'SKILL.md' (Join-Path $dist 'skills')).Count
$residual = @(Select-String -Path (Join-Path $dist 'skills/*/SKILL.md') -SimpleMatch 'superpowers:' -ErrorAction SilentlyContinue).Count
foreach ($d in $declaredFiles.Keys) {
  if (-not (Test-Path -LiteralPath $d)) {
    Fail ("declared overlay file missing from dist: {0}" -f $declaredFiles[$d])
  }
}
Write-Host ("build-mysuperpower: verified {0} overlay-supplied file(s)" -f $declaredFiles.Count)
Write-Host "build-mysuperpower: done. plugin=$pjName skills=$skillCount residual 'superpowers:' refs in top-level SKILL.md=$residual"
