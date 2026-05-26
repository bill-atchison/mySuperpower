#!/usr/bin/env pwsh
# Re-apply the my-superpower brand. Idempotent. Run on a CLEAN index only
# (never against files containing git conflict markers).
# Transform 1: namespace cascade  superpowers:<skill> -> my-superpower:<skill>
# Transform 2: manifest name       "name": "superpowers[-dev]" -> "name": "my-superpower"
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# --- Transform 1: namespace cascade over skills/ and the session-start hook ---
$nsTargets = @()
$nsTargets += Get-ChildItem (Join-Path $root "skills") -Recurse -File
$hook = Join-Path $root "hooks/session-start"
if (Test-Path $hook) { $nsTargets += Get-Item $hook }
foreach ($f in $nsTargets) {
  $orig = Get-Content $f.FullName -Raw
  $new  = $orig -replace 'superpowers:', 'my-superpower:'
  if ($new -ne $orig) { Set-Content $f.FullName $new -NoNewline }
}

# --- Transform 2: manifest name fields ---
$manifests = @(
  ".claude-plugin/plugin.json", ".claude-plugin/marketplace.json",
  ".codex-plugin/plugin.json", ".cursor-plugin/plugin.json",
  "gemini-extension.json", "package.json"
)
foreach ($rel in $manifests) {
  $p = Join-Path $root $rel
  if (-not (Test-Path $p)) { continue }
  $orig = Get-Content $p -Raw
  $new  = $orig -replace '"name":\s*"superpowers-dev"', '"name": "my-superpower"'
  $new  = $new  -replace '"name":\s*"superpowers"',     '"name": "my-superpower"'
  if ($new -ne $orig) { Set-Content $p $new -NoNewline }
}
Write-Host "apply-my-superpower-brand: done."
