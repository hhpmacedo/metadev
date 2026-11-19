#!/usr/bin/env bash
# Reports which of the plugin's dependencies are present on this machine.
# It reads and prints; it installs nothing. The setup skill acts on its output.
#
# One line per dependency, tab-separated:
#   status  level  name  what it is for  how to install
# status: ok | missing | disabled | unknown (the plugin list could not be read)
# level:  required | recommended | optional
# Exit code 1 if a required dependency is missing, otherwise 0.

set -u

MARKET="claude-plugins-official"
missing_required=0

row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"; }
have() { command -v "$1" >/dev/null 2>&1; }

pkg_hint() {
  if have brew; then echo "brew install $1"
  elif have apt-get; then echo "sudo apt-get install $1"
  elif have dnf; then echo "sudo dnf install $1"
  elif have pacman; then echo "sudo pacman -S $1"
  else echo "install $1 with the system package manager"
  fi
}

# ---- command-line tools -----------------------------------------------------

if have git; then row ok required git "every mandate works on a branch" ""
else row missing required git "every mandate works on a branch" "$(pkg_hint git)"; missing_required=1
fi

if have jq || have python3; then row ok required "jq or python3" "the commit guard reads each shell command with one of them" ""
else row missing required "jq or python3" "the commit guard refuses every git command without one of them" "$(pkg_hint jq)"; missing_required=1
fi

if have gh; then row ok recommended gh "opening the pull request that ends a mandate" ""
else row missing recommended gh "opening the pull request that ends a mandate; without it the owner opens it by hand" "$(pkg_hint gh)"
fi

if have npx; then row ok recommended "node and npx" "the browser tools and the platform command-line tools, which are all started through npx" ""
else row missing recommended "node and npx" "the browser tools and the platform command-line tools, which are all started through npx" "install Node.js (https://nodejs.org)"
fi

# ---- Claude Code plugins ----------------------------------------------------

plugins_json=""
if have claude; then plugins_json="$(claude plugin list --json 2>/dev/null || true)"; fi

# prints: ok | disabled | missing | unknown
plugin_state() {
  local id="$1@$MARKET"
  if [ -z "$plugins_json" ]; then echo unknown; return; fi
  if have jq; then
    printf '%s' "$plugins_json" | jq -r --arg id "$id" '
      (map(select(.id == $id)) | first) as $p
      | if $p == null then "missing" elif $p.enabled then "ok" else "disabled" end' 2>/dev/null || echo unknown
  elif have python3; then
    printf '%s' "$plugins_json" | python3 -c '
import json, sys
try:
    found = [p for p in json.load(sys.stdin) if p.get("id") == sys.argv[1]]
    print("missing" if not found else "ok" if found[0].get("enabled") else "disabled")
except Exception:
    print("unknown")' "$id"
  else
    echo unknown
  fi
}

plugin_row() {
  local name="$1" level="$2" purpose="$3" state
  state="$(plugin_state "$name")"
  case "$state" in
    ok) row ok "$level" "$name plugin" "$purpose" "" ;;
    disabled) row disabled "$level" "$name plugin" "$purpose" "claude plugin enable $name@$MARKET" ;;
    missing) row missing "$level" "$name plugin" "$purpose" "claude plugin install $name@$MARKET" ;;
    *) row unknown "$level" "$name plugin" "$purpose" "claude plugin install $name@$MARKET" ;;
  esac
}

plugin_row playwright recommended "browser tools: QA in a real browser at three widths, the screenshots the design review reads, the production smoke test"
plugin_row frontend-design optional "design direction for the design lead and the frontend developer"
plugin_row pr-review-toolkit optional "extra review agents before a merge (silent failures, test coverage)"
plugin_row context7 optional "current library documentation while building"

exit "$missing_required"
