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
  [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root $OutDir

function Fail([string]$msg) { Write-Error "build-mysuperpower: $msg"; exit 1 }

Write-Host "build-mysuperpower: root=$root"
Write-Host "build-mysuperpower: out=$dist"

# --- 1. Clean dist/ ---
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# --- 2. Copy pristine plugin tree into dist/, excluding source-only entries ---
$exclude = @('overlays', 'branding', 'scripts', 'docs', 'tests', '.git', '.github', '.baseline-skills', $OutDir)
Get-ChildItem -Force -Path $root |
  Where-Object { $exclude -notcontains $_.Name } |
  ForEach-Object { Copy-Item -Recurse -Force -Path $_.FullName -Destination (Join-Path $dist $_.Name) }

# --- 3. Overlay branded README / CLAUDE ---
Copy-Item -Force (Join-Path $root 'branding/README.md') (Join-Path $dist 'README.md')
Copy-Item -Force (Join-Path $root 'branding/CLAUDE.md')  (Join-Path $dist 'CLAUDE.md')

# A plugin source dir should not carry a marketplace catalog; that lives at the repo root.
$distMarket = Join-Path $dist '.claude-plugin/marketplace.json'
if (Test-Path $distMarket) { Remove-Item -Force $distMarket }

# --- 4. Apply per-skill HTML overlays (replaces with fail-loud anchors + append) ---
$overlaysDir = Join-Path $root 'overlays'
if (Test-Path $overlaysDir) {
  foreach ($skillDir in (Get-ChildItem -Directory $overlaysDir)) {
    $cfgPath = Join-Path $skillDir.FullName 'overlay.json'
    if (-not (Test-Path $cfgPath)) { continue }
    $cfg = Get-Content -Raw $cfgPath | ConvertFrom-Json
    $skillFile = Join-Path $dist ("skills/{0}/SKILL.md" -f $cfg.skill)
    if (-not (Test-Path $skillFile)) { Fail "overlay target missing: $skillFile" }
    $content = Get-Content -Raw -LiteralPath $skillFile
    foreach ($r in $cfg.replaces) {
      if (-not $content.Contains($r.find)) {
        if ($r.required) { Fail ("required anchor not found in {0}: '{1}'" -f $cfg.skill, $r.find) }
        Write-Warning ("optional anchor not found in {0}: '{1}'" -f $cfg.skill, $r.find)
        continue
      }
      $content = $content.Replace($r.find, $r.replace)
    }
    if ($cfg.append) {
      $addPath = Join-Path $skillDir.FullName $cfg.append
      if (-not (Test-Path $addPath)) { Fail "append file missing: $addPath" }
      $add = Get-Content -Raw -LiteralPath $addPath
      $content = $content.TrimEnd() + "`n`n" + $add.TrimEnd() + "`n"
    }
    Set-Content -NoNewline -LiteralPath $skillFile -Value $content
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
Write-Host "build-mysuperpower: done. plugin=$pjName skills=$skillCount residual 'superpowers:' refs in top-level SKILL.md=$residual"
