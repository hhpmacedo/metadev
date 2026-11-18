#!/usr/bin/env bash
# Shared by guard-commit.sh (before a commit) and guard-history.sh (after any
# command). Sourced, not executed.

SECRET_PATTERNS='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9]{32,}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{20,}|sk_live_[A-Za-z0-9]{20,}|rk_live_[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'

# json_get <dotted.path>  - reads the hook payload in $input. Prints the string
# value, or nothing. Returns 3 when no JSON parser is available.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    jq -r ".$1 // empty" <<<"$input" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    d = json.loads(sys.argv[1])
    for k in sys.argv[2].split("."):
        d = d.get(k) if isinstance(d, dict) else None
    sys.stdout.write(d if isinstance(d, str) else "")
except Exception:
    pass
' "$input" "$1" 2>/dev/null || true
  else
    return 3
  fi
}

# Environment files, except templates.
is_env_file() {
  [[ "$1" =~ (^|/)\.env(\.[^/]*)?$ ]] && [[ ! "$1" =~ \.(example|sample|template|dist)$ ]]
}

# Reads content on stdin, prints a short prefix of each secret-shaped string
# found (never the whole value). -a makes grep read binary content as text.
secret_prefixes() {
  LC_ALL=C grep -a -Eo -- "$SECRET_PATTERNS" 2>/dev/null | LC_ALL=C sort -u | head -3 | cut -c1-12 | sed 's/$/.../'
}

# Where the block on pushing is recorded, one file per repository.
guard_state_dir() {
  local d="${XDG_STATE_HOME:-$HOME/.local/state}/metadev-guard"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}
repo_key() { # repository top-level path -> stable file-safe key
  printf '%s' "$1" | cksum | tr -d ' \t\n'
}

# Local commits that are on a branch or HEAD and not on any remote-tracking ref.
# Extra arguments (for example ^<sha> exclusions) go first: after --not their
# meaning would be inverted.
unpushed_commits() { git rev-list "$@" HEAD --branches --not --remotes 2>/dev/null; }
