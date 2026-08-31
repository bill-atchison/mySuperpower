#!/usr/bin/env pwsh
# Tests for the overlay "files" capability in build-mysuperpower.ps1.
#
# Each case points the build at a FIXTURE overlays directory via -OverlaysDir
# and at a throwaway -OutDir, so the repo's real overlays and dist/ are never
# touched. A negative case passes when the build fails and names the entry.
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$build = Join-Path $root 'scripts/build-mysuperpower.ps1'
$fails = 0

function Pass([string]$m) { Write-Host "  ok   $m" }
function Failed([string]$m) { Write-Host "  FAIL $m"; $script:fails++ }

function New-Overlay([string]$dir, [string]$json, [hashtable]$files) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Set-Content -LiteralPath (Join-Path $dir 'overlay.json') -Value $json
  foreach ($k in $files.Keys) {
    $p = Join-Path $dir $k
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
    Set-Content -LiteralPath $p -Value $files[$k]
  }
}

# Returns $true when the build succeeded.
function Invoke-Build([string]$overlays, [string]$out, [ref]$log) {
  $o = & pwsh -NoProfile -ExecutionPolicy Bypass -File $build `
    -OutDir $out -OverlaysDir $overlays 2>&1 | Out-String
  $log.Value = $o
  return ($LASTEXITCODE -eq 0)
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ovl-" + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
  $SKILL = 'subagent-driven-development'
  $out = Join-Path $tmp 'dist'
  $log = ''

  Write-Host "== a declared file lands at its declared 'to' path =="
  $ov = Join-Path $tmp 'ok/sdd'
  New-Overlay $ov ('{"skill":"' + $SKILL + '","replaces":[],"files":[{"from":"scripts/demo","to":"scripts/demo","exec":true}]}') @{ 'scripts/demo' = "#!/usr/bin/env bash`necho demo" }
  if (Invoke-Build (Join-Path $tmp 'ok') $out ([ref]$log)) {
    if (Test-Path (Join-Path $out "skills/$SKILL/scripts/demo")) { Pass "file copied into dist" }
    else { Failed "file copied into dist" }
  } else { Failed "build succeeded for a valid files entry`n$log" }

  Write-Host "== an overlay with no files key still builds under StrictMode =="
  $ov = Join-Path $tmp 'nofiles/sdd'
  New-Overlay $ov ('{"skill":"' + $SKILL + '","replaces":[]}') @{}
  if (Invoke-Build (Join-Path $tmp 'nofiles') $out ([ref]$log)) { Pass "no files key, no append key" }
  else { Failed "no files key, no append key`n$log" }

  Write-Host "== schema violations fail the build, each for its own reason =="
  # Every negative case asserts the SPECIFIC diagnostic. Checking only for a
  # nonzero exit lets an unrelated error satisfy a security test: a '..' fixture
  # whose target does not exist fails on "not an existing file" whether or not
  # the traversal check is there at all. So each escape fixture is made
  # REACHABLE -- the file it points at really exists -- leaving the rule under
  # test as the only thing that can reject it.
  $cases = @(
    @{ name = "missing 'from' file"; expect = "is not an existing file"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"scripts/nope","to":"scripts/x"}]}'; files = @{} }
    @{ name = "absolute 'from' that exists"; expect = "must be a relative path"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"@@ABS@@","to":"scripts/x"}]}'; files = @{} }
    @{ name = "reachable '..' in 'from'"; expect = "must be a relative path"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"../escape","to":"scripts/x"}]}'; files = @{ 'scripts/demo' = 'x' }; sibling = $true }
    @{ name = "reachable '..' in 'to'"; expect = "must be a relative path"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"scripts/demo","to":"../../escape"}]}'; files = @{ 'scripts/demo' = 'x' } }
    @{ name = "'to' already in dist"; expect = "already exists in dist"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"scripts/demo","to":"scripts/task-brief"}]}'; files = @{ 'scripts/demo' = 'x' } }
    @{ name = "duplicate canonical 'to'"; expect = "collides with"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"scripts/demo","to":"scripts/dup"},{"from":"scripts/other","to":"scripts/dup"}]}'; files = @{ 'scripts/demo' = 'x'; 'scripts/other' = 'y' } }
    @{ name = "non-boolean exec"; expect = "non-boolean exec"
       json = '{"skill":"@@SKILL@@","replaces":[],"files":[{"from":"scripts/demo","to":"scripts/x","exec":"true"}]}'; files = @{ 'scripts/demo' = 'x' } }
  )
  $i = 0
  foreach ($c in $cases) {
    $i++
    $dir = Join-Path $tmp ("bad$i")
    # -creplace, and tokens that cannot occur in the JSON otherwise. PowerShell's
    # -replace is CASE-INSENSITIVE by default, so a plain 'SK' placeholder also
    # matched the "sk" inside the key "skill" and renamed the property itself.
    # The backslashes in an absolute path have to be doubled for JSON.
    $json = ($c.json -creplace '@@SKILL@@', $SKILL) -creplace '@@ABS@@', ($build -replace '\\', '\\')
    New-Overlay (Join-Path $dir 'sdd') $json $c.files
    # A '..' in 'from' escapes the overlay into its PARENT, so put a real file
    # there; without it the entry would be rejected for merely not existing.
    if ($c.ContainsKey('sibling')) {
      Set-Content -LiteralPath (Join-Path $dir 'escape') -Value 'reachable from ../escape'
    }
    if (Invoke-Build $dir $out ([ref]$log)) {
      Failed ("{0}: build should have failed" -f $c.name)
    } elseif ($log -notmatch [regex]::Escape($c.expect)) {
      Failed ("{0}: failed for the wrong reason; expected '{1}'`n{2}" -f $c.name, $c.expect, $log)
    } else {
      Pass $c.name
    }
  }

  Write-Host "== destructive output directories are rejected before any cleanup =="
  # These cases are run against a THROWAWAY COPY of the build script, whose
  # $root is a temp directory. That is deliberate: build step 1 removes $dist
  # recursively, so if the guard under test is absent or broken, an -OutDir
  # naming the root deletes it. Pointed at the real repo that is the working
  # copy; pointed here it is a directory we created to be destroyed.
  $guard = Join-Path $tmp 'guard'
  $fakeRoot = Join-Path $guard 'repo'
  New-Item -ItemType Directory -Force -Path (Join-Path $fakeRoot 'scripts') | Out-Null
  Copy-Item -LiteralPath $build -Destination (Join-Path $fakeRoot 'scripts/build-mysuperpower.ps1')
  $fakeBuild = Join-Path $fakeRoot 'scripts/build-mysuperpower.ps1'

  function Invoke-FakeBuild([string]$outDir, [ref]$log) {
    $o = & pwsh -NoProfile -ExecutionPolicy Bypass -File $fakeBuild -OutDir $outDir 2>&1 | Out-String
    $log.Value = $o
    return ($LASTEXITCODE -eq 0)
  }

  $guardCases = @(
    @{ name = "OutDir is the repository itself"; out = $fakeRoot; expect = "must not be the repository itself" }
    @{ name = "OutDir is an ancestor of the repository"; out = $guard; expect = "must not be an ancestor" }
    @{ name = "nested OutDir, lowercased"; out = (Join-Path $fakeRoot 'nested/dist').ToLower(); expect = "direct child" }
  )
  foreach ($g in $guardCases) {
    if (Invoke-FakeBuild $g.out ([ref]$log)) {
      Failed ("{0}: build should have been rejected" -f $g.name)
    } elseif ($log -notmatch [regex]::Escape($g.expect)) {
      Failed ("{0}: rejected for the wrong reason; expected '{1}'`n{2}" -f $g.name, $g.expect, $log)
    } elseif (-not (Test-Path $fakeRoot)) {
      Failed ("{0}: the guard did not fire and the root was deleted" -f $g.name)
    } else {
      Pass $g.name
    }
  }

  Write-Host "== a symlinked ancestor in 'from' is rejected =="
  if ($IsWindows) {
    $dir = Join-Path $tmp 'junction'
    $ovj = Join-Path $dir 'sdd'
    New-Overlay $ovj ('{"skill":"' + $SKILL + '","replaces":[],"files":[{"from":"linkdir/secret","to":"scripts/x"}]}') @{}
    $outside = Join-Path $tmp 'outside'
    New-Item -ItemType Directory -Force -Path $outside | Out-Null
    Set-Content -LiteralPath (Join-Path $outside 'secret') -Value 'outside the overlay'
    New-Item -ItemType Junction -Path (Join-Path $ovj 'linkdir') -Target $outside | Out-Null
    if (Invoke-Build $dir $out ([ref]$log)) {
      Failed "a symlinked ancestor should have failed the build"
    } elseif ($log -notmatch 'traverses a symlinked directory') {
      Failed "symlinked ancestor failed for the wrong reason`n$log"
    } else {
      Pass "symlinked ancestor rejected"
    }
  } else {
    Write-Host "  skip (junctions are a Windows construct)"
  }
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host ""
if ($fails -eq 0) { Write-Host "overlay files tests passed" }
else { Write-Host "$fails assertion(s) failed"; exit 1 }