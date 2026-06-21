#!/usr/bin/env pwsh
# publish-mysuperpower.ps1
# Build dist/ and publish it as a self-contained plugin marketplace on the
# 'release' branch, with the plugin at the branch ROOT (marketplace source "./").
# This lets the GitHub repo serve the marketplace via:
#   /plugin marketplace add bill-atchison/mySuperpower#release
# while keeping mysuperpower free of generated build artifacts.
#
# Usage:
#   pwsh -NoProfile -File scripts/publish-mysuperpower.ps1            # build + commit release locally
#   pwsh -NoProfile -File scripts/publish-mysuperpower.ps1 -Push      # also push origin/release

[CmdletBinding()]
param(
  [string]$Branch = "release",
  [switch]$Push
)

$ErrorActionPreference = "Stop"
$root = (git rev-parse --show-toplevel).Trim()
Set-Location $root

function Fail([string]$m) { Write-Error "publish-mysuperpower: $m"; exit 1 }

# --- 1. Build dist/ ---
pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/build-mysuperpower.ps1')
if ($LASTEXITCODE -ne 0) { Fail "build failed" }
$dist = Join-Path $root 'dist'
$pjPath = Join-Path $dist '.claude-plugin/plugin.json'
if (-not (Test-Path $pjPath)) { Fail "build did not produce $pjPath" }
$version = (Get-Content -Raw $pjPath | ConvertFrom-Json).version

# --- 2. Compose the release marketplace catalog (plugin at branch root => source './') ---
$mk = Get-Content -Raw (Join-Path $root '.claude-plugin/marketplace.json') | ConvertFrom-Json
$mk.plugins[0].source = "./"
$mk.plugins[0].version = $version
$releaseMarket = $mk | ConvertTo-Json -Depth 20

# --- 3. Prepare a throwaway worktree on the release branch (orphan if new) ---
$wt = Join-Path (Split-Path $root -Parent) "mysuperpower-release"
if (Test-Path $wt) { git worktree remove --force $wt 2>$null | Out-Null }
git worktree prune | Out-Null

git show-ref --verify --quiet "refs/heads/$Branch"; $localExists = ($LASTEXITCODE -eq 0)
git ls-remote --exit-code --heads origin $Branch *> $null; $remoteExists = ($LASTEXITCODE -eq 0)

if ($localExists) {
  git worktree add --force $wt $Branch | Out-Null
} elseif ($remoteExists) {
  git fetch origin $Branch | Out-Null
  git worktree add --force -B $Branch $wt "origin/$Branch" | Out-Null
} else {
  git worktree add --detach --force $wt HEAD | Out-Null
  Push-Location $wt
  git checkout --orphan $Branch | Out-Null
  git rm -rf . *> $null
  Pop-Location
}

# --- 4. Replace worktree contents with the freshly built plugin ---
Push-Location $wt
Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Pop-Location

Get-ChildItem -Force -Path $dist |
  ForEach-Object { Copy-Item -Recurse -Force -Path $_.FullName -Destination (Join-Path $wt $_.Name) }

# Codex requires each plugin in its OWN SUBDIRECTORY — a plugin at the marketplace
# root (path './') is not resolved by `codex plugin add` (verified on codex-cli
# 0.141.0). Claude Code installs the plugin from the branch root (source './'),
# while Codex installs it from ./plugins/<name>/. So mirror the built plugin into
# a subdirectory for Codex; the root copy stays for Claude.
$pluginName = $mk.plugins[0].name
$codexPluginRel = "plugins/$pluginName"
$codexPluginDir = Join-Path $wt $codexPluginRel
New-Item -ItemType Directory -Force -Path $codexPluginDir | Out-Null
Get-ChildItem -Force -Path $dist |
  ForEach-Object { Copy-Item -Recurse -Force -Path $_.FullName -Destination (Join-Path $codexPluginDir $_.Name) }

$relMarketPath = Join-Path $wt '.claude-plugin/marketplace.json'
New-Item -ItemType Directory -Force -Path (Split-Path $relMarketPath) | Out-Null
$releaseMarket | Set-Content -LiteralPath $relMarketPath

# Codex reads a different catalog: .agents/plugins/marketplace.json, pointing at
# the plugin's subdirectory (NOT the branch root — see note above).
$codexMarket = [ordered]@{
  name      = $mk.name
  interface = [ordered]@{ displayName = $mk.plugins[0].displayName }
  plugins   = @(
    [ordered]@{
      name     = $pluginName
      source   = [ordered]@{ source = 'local'; path = "./$codexPluginRel" }
      policy   = [ordered]@{ installation = 'AVAILABLE'; authentication = 'ON_INSTALL' }
      category = 'Coding'
    }
  )
} | ConvertTo-Json -Depth 20
$agentsMarketPath = Join-Path $wt '.agents/plugins/marketplace.json'
New-Item -ItemType Directory -Force -Path (Split-Path $agentsMarketPath) | Out-Null
$codexMarket | Set-Content -LiteralPath $agentsMarketPath

# --- 5. Commit (and optionally push) ---
Push-Location $wt
git add -A
if (@(git status --porcelain).Count -eq 0) {
  Write-Host "publish-mysuperpower: no changes to release ($version)"
} else {
  git commit -m "Publish mySuperpower $version" -m "Co-Authored-By: Oz <oz-agent@warp.dev>" | Out-Null
  Write-Host "publish-mysuperpower: committed release $version"
}
if ($Push) { git push -u origin $Branch | Out-Null; Write-Host "publish-mysuperpower: pushed origin/$Branch" }
Pop-Location

# --- 6. Clean up the worktree ---
git worktree remove --force $wt | Out-Null
Write-Host "publish-mysuperpower: done ($Branch @ $version)"
