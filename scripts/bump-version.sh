#!/usr/bin/env bash
#
# bump-version.sh — bump version numbers across all declared files,
# with drift detection and repo-wide audit for missed files.
#
# Fork versioning: the version is <upstream-base>+fork.<iteration> (e.g. 1.2.3+fork.4
# = built from upstream 1.2.3, 4th fork iteration since that sync).
#
# Usage:
#   bump-version.sh <new-version>   Bump all declared files (X.Y.Z or X.Y.Z+fork.N)
#   bump-version.sh --fork-bump     Increment fork iteration (<base>+fork.N -> +fork.N+1)
#   bump-version.sh --sync <base>   After upstream merge: set <base>+fork.1
#   bump-version.sh --check         Report current versions (detect drift)
#   bump-version.sh --audit         Check + grep repo for old version strings
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$REPO_ROOT/.version-bump.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "error: .version-bump.json not found at $CONFIG" >&2
  exit 1
fi

# --- helpers ---

# Read a dotted field path from a JSON file.
# Handles both simple ("version") and nested ("plugins.0.version") paths.
read_json_field() {
  local file="$1" field="$2"
  # Convert dot-path to jq path: "plugins.0.version" -> .plugins[0].version
  local jq_path
  jq_path=$(echo "$field" | sed -E 's/\.([0-9]+)/[\1]/g' | sed 's/^/./' | sed 's/\.\././g')
  # tr -d '\r': some Windows jq builds emit CRLF, which would leave a trailing
  # CR on every captured value and silently break string comparisons/matching.
  jq -r "$jq_path" "$file" | tr -d '\r'
}

# Write a dotted field path in a JSON file, preserving formatting.
write_json_field() {
  local file="$1" field="$2" value="$3"
  local jq_path
  jq_path=$(echo "$field" | sed -E 's/\.([0-9]+)/[\1]/g' | sed 's/^/./' | sed 's/\.\././g')
  local tmp="${file}.tmp"
  jq "$jq_path = \"$value\"" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Read the list of declared files from config.
# Outputs lines of "path<TAB>field"
declared_files() {
  jq -r '.files[] | "\(.path)\t\(.field)"' "$CONFIG"
}

# Read the audit exclude patterns from config.
audit_excludes() {
  # tr -d '\r': strip CR from Windows jq's CRLF output so patterns match cleanly.
  jq -r '.audit.exclude[]' "$CONFIG" 2>/dev/null | tr -d '\r'
}

# Determine the current version (most common value across declared files).
get_current_version() {
  while IFS=$'\t' read -r path field; do
    local fullpath="$REPO_ROOT/$path"
    [[ -f "$fullpath" ]] && read_json_field "$fullpath" "$field"
  done < <(declared_files) | sort | uniq -c | sort -rn | head -1 | awk '{print $2}'
}

# --- commands ---

cmd_check() {
  local has_drift=0
  local versions=()

  echo "Version check:"
  echo ""

  while IFS=$'\t' read -r path field; do
    local fullpath="$REPO_ROOT/$path"
    if [[ ! -f "$fullpath" ]]; then
      printf "  %-45s  MISSING\n" "$path ($field)"
      has_drift=1
      continue
    fi
    local ver
    ver=$(read_json_field "$fullpath" "$field")
    printf "  %-45s  %s\n" "$path ($field)" "$ver"
    versions+=("$ver")
  done < <(declared_files)

  echo ""

  # Check if all versions match
  local unique
  unique=$(printf '%s\n' "${versions[@]}" | sort -u | wc -l | tr -d ' ')
  if [[ "$unique" -gt 1 ]]; then
    echo "DRIFT DETECTED — versions are not in sync:"
    printf '%s\n' "${versions[@]}" | sort | uniq -c | sort -rn | while read -r count ver; do
      echo "  $ver ($count files)"
    done
    has_drift=1
  else
    echo "All declared files are in sync at ${versions[0]}"
  fi

  return $has_drift
}

cmd_audit() {
  # First run check
  cmd_check || true
  echo ""

  # Determine the current version (most common across declared files)
  local current_version
  current_version=$(get_current_version)

  if [[ -z "$current_version" ]]; then
    echo "error: could not determine current version" >&2
    return 1
  fi

  echo "Audit: scanning repo for version string '$current_version'..."
  echo ""

  # Build grep exclude args, AND capture the raw patterns for a reliable
  # post-filter. (grep --exclude/--exclude-dir is honored inconsistently across
  # grep builds in this environment, so the post-filter below is authoritative;
  # the grep args remain as a perf hint for large trees.)
  local -a exclude_args=()
  local -a exclude_pats=()
  while IFS= read -r pattern; do
    exclude_args+=("--exclude=$pattern" "--exclude-dir=$pattern")
    exclude_pats+=("$pattern")
  done < <(audit_excludes)

  # Also always exclude binary files and .git
  exclude_args+=("--exclude-dir=.git" "--exclude-dir=node_modules" "--binary-files=without-match")

  # Get list of declared paths for comparison
  local -a declared_paths=()
  while IFS=$'\t' read -r path _field; do
    declared_paths+=("$path")
  done < <(declared_files)

  # Grep for the version string
  local found_undeclared=0
  while IFS= read -r match; do
    local match_file
    match_file=$(echo "$match" | cut -d: -f1)
    # Make path relative to repo root
    local rel_path="${match_file#$REPO_ROOT/}"

    # Reliable exclude filter: skip if any path segment equals an exclude
    # pattern (patterns are basenames, e.g. dist, CHANGELOG.md, node_modules).
    local is_excluded=0 pat
    for pat in "${exclude_pats[@]}"; do
      case "/$rel_path/" in
        */"$pat"/*) is_excluded=1; break ;;
      esac
    done
    [[ "$is_excluded" -eq 1 ]] && continue

    # Check if this file is in the declared list
    local is_declared=0
    for dp in "${declared_paths[@]}"; do
      if [[ "$rel_path" == "$dp" ]]; then
        is_declared=1
        break
      fi
    done

    if [[ "$is_declared" -eq 0 ]]; then
      if [[ "$found_undeclared" -eq 0 ]]; then
        echo "UNDECLARED files containing '$current_version':"
        found_undeclared=1
      fi
      echo "  $match"
    fi
  done < <(grep -rn "${exclude_args[@]}" -F "$current_version" "$REPO_ROOT" 2>/dev/null || true)

  if [[ "$found_undeclared" -eq 0 ]]; then
    echo "No undeclared files contain the version string. All clear."
  else
    echo ""
    echo "Review the above files — if they should be bumped, add them to .version-bump.json"
    echo "If they should be skipped, add them to the audit.exclude list."
  fi
}

cmd_bump() {
  local new_version="$1"

  # Validate: must start with X.Y.Z. The fork build-metadata suffix
  # (e.g. 1.2.3+fork.4 — upstream base 1.2.3, fork iteration 4) is allowed and
  # encouraged for fork releases; see --fork-bump and --sync.
  if ! echo "$new_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(\+fork\.[0-9]+)?$'; then
    echo "error: '$new_version' must be X.Y.Z or X.Y.Z+fork.N" >&2
    exit 1
  fi

  echo "Bumping all declared files to $new_version..."
  echo ""

  while IFS=$'\t' read -r path field; do
    local fullpath="$REPO_ROOT/$path"
    if [[ ! -f "$fullpath" ]]; then
      echo "  SKIP (missing): $path"
      continue
    fi
    local old_ver
    old_ver=$(read_json_field "$fullpath" "$field")
    write_json_field "$fullpath" "$field" "$new_version"
    printf "  %-45s  %s -> %s\n" "$path ($field)" "$old_ver" "$new_version"
  done < <(declared_files)

  echo ""
  echo "Done. Running audit to check for missed files..."
  echo ""
  cmd_audit
}

# Bump the fork iteration: <base>+fork.N -> <base>+fork.(N+1).
# If the current version has no +fork suffix, it becomes <current>+fork.1.
cmd_fork_bump() {
  local cur base n
  cur=$(get_current_version)
  if [[ -z "$cur" ]]; then
    echo "error: could not determine current version" >&2
    exit 1
  fi
  if [[ "$cur" == *"+fork."* ]]; then
    base="${cur%%+fork.*}"
    n="${cur##*+fork.}"
    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
      echo "error: fork iteration '$n' in current version '$cur' is not numeric" >&2
      exit 1
    fi
    n=$((n + 1))
  else
    base="$cur"
    n=1
  fi
  echo "Fork bump: $cur -> ${base}+fork.${n}"
  echo ""
  cmd_bump "${base}+fork.${n}"
}

# Sync to a new upstream base, resetting the fork iteration to 1.
# Use after merging a new upstream release: --sync 6.0.4  ->  6.0.4+fork.1
cmd_sync() {
  local newbase="$1"
  if ! echo "$newbase" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "error: --sync base '$newbase' must be a plain upstream version X.Y.Z" >&2
    exit 1
  fi
  echo "Sync to upstream base $newbase, resetting fork iteration to 1..."
  echo ""
  cmd_bump "${newbase}+fork.1"
}

# --- main ---

case "${1:-}" in
  --check)
    cmd_check
    ;;
  --audit)
    cmd_audit
    ;;
  --fork-bump)
    cmd_fork_bump
    ;;
  --sync)
    shift
    if [[ -z "${1:-}" ]]; then
      echo "error: --sync requires an upstream base version (X.Y.Z)" >&2
      exit 1
    fi
    cmd_sync "$1"
    ;;
  --help|-h|"")
    echo "Usage: bump-version.sh <new-version> | --fork-bump | --sync <base> | --check | --audit"
    echo ""
    echo "  <new-version>   Bump all declared files to the given version (X.Y.Z or X.Y.Z+fork.N)"
    echo "  --fork-bump     Increment the fork iteration: <base>+fork.N -> <base>+fork.(N+1)"
    echo "  --sync <base>   After an upstream merge: set <base>+fork.1 (reset fork iteration)"
    echo "  --check         Show current versions, detect drift"
    echo "  --audit         Check + scan repo for undeclared version references"
    echo ""
    echo "Fork versioning: the version is <upstream-base>+fork.<iteration>, e.g. 1.2.3+fork.4"
    echo "means built from upstream 1.2.3, 4th fork iteration since that sync."
    exit 0
    ;;
  --*)
    echo "error: unknown flag '$1'" >&2
    exit 1
    ;;
  *)
    cmd_bump "$1"
    ;;
esac
