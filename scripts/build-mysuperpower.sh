#!/usr/bin/env bash
# build-mysuperpower.sh
# POSIX entrypoint for the mySuperpower build. The build logic lives in the
# cross-platform PowerShell script build-mysuperpower.ps1; this wrapper simply
# delegates to it so there is a single source of truth.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh "${SCRIPT_DIR}/build-mysuperpower.ps1" "$@"
fi

echo "build-mysuperpower.sh requires PowerShell (pwsh) on PATH." >&2
echo "Install PowerShell 7+ (https://aka.ms/powershell) and re-run." >&2
exit 1
