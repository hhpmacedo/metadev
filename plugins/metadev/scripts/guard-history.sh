#!/usr/bin/env bash
# Second layer of the commit guard. It does not read the command to decide
# whether a commit happened; it looks at what the repository contains.
#
#   PreToolUse  (Bash): remember where every branch points. Refuse a push while
#                       the repository holds an unpushed commit that was flagged.
#   PostToolUse (Bash): find commits that did not exist before the command and
#                       are not on a remote. Scan the files they changed. If one
#                       adds a .env file or a secret-shaped string, flag the
#                       commit, tell the agent how to undo it, and block pushes
#                       until it is gone.
#
# This catches commits made through aliases, eval, wrappers or unusual quoting,
# which a check on the command text cannot see.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/guard-lib.sh"

input=$(cat)
event=$(json_get hook_event_name) || exit 0   # no JSON parser: guard-commit.sh reports it
cwd=$(json_get cwd)
cmd=$(json_get tool_input.command)
tool_id=$(json_get tool_use_id)
tool_id=${tool_id//[^A-Za-z0-9_-]/}; [[ -n "$tool_id" ]] || tool_id=last

state=$(guard_state_dir)
[[ -d "$state" ]] || exit 0
snap="$state/snap.$tool_id"

# Commits recorded in a flag file that still exist unpushed. Rewrites the file.
live_flags() { # $1 = flag file
  [[ -s "$1" ]] || return 0
  local unpushed keep="" sha rest
  unpushed=$(unpushed_commits)
  while IFS=' ' read -r sha rest; do
    [[ -n "$sha" ]] && grep -qx -- "$sha" <<<"$unpushed" && keep+="$sha $rest"$'\n'
  done < "$1"
  if [[ -n "$keep" ]]; then printf '%s' "$keep" > "$1"; printf '%s' "$keep"; else rm -f "$1"; fi
}

case "$event" in
PreToolUse)
  [[ -n "$cwd" && -d "$cwd" ]] && cd "$cwd" || exit 0
  top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
  flag="$state/flag.$(repo_key "$top")"

  # Snapshots left behind by commands that never finished are removed after two hours.
  find "$state" -maxdepth 1 -name 'snap.*' -mmin +120 -delete 2>/dev/null

  # Snapshot: repository path, then every commit the branches and HEAD point to.
  { printf '%s\n' "$top"; git rev-parse -q --verify HEAD 2>/dev/null; git for-each-ref --format='%(objectname)' refs/heads 2>/dev/null; } > "$snap" 2>/dev/null

  # Refuse anything that mentions a push while a flagged commit is unpushed.
  if [[ -s "$flag" ]]; then
    norm=${cmd//[\'\"\\]/}
    if [[ "${norm,,}" == *push* ]]; then
      live=$(live_flags "$flag")
      if [[ -n "$live" ]]; then
        rm -f "$snap"
        {
          echo "Push blocked by the metadev commit guard."
          echo "This repository has unpushed commits that contain environment files or secret-shaped strings:"
          sed 's/^/  /' <<<"$live"
          echo "Remove them from history first. For the most recent commit: git reset --soft HEAD~1, unstage the file or remove the value, and commit again."
          echo "For an older commit, stop and tell the owner; do not rewrite shared history on your own."
          echo "If this is a false positive, tell the owner. The plugin README explains how the owner clears the block."
        } >&2
        exit 2
      fi
    fi
  fi
  exit 0
  ;;

PostToolUse)
  [[ -s "$snap" ]] || exit 0
  top=$(head -n1 "$snap")
  mapfile -t before < <(tail -n +2 "$snap" | grep -E '^[0-9a-f]{40,64}$' | sort -u)
  rm -f "$snap"
  [[ -n "$top" && -d "$top" ]] && cd "$top" || exit 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  flag="$state/flag.$(repo_key "$top")"

  # Commits that are new since the snapshot and not on a remote.
  exclude=()
  for sha in "${before[@]}"; do
    git cat-file -e "$sha^{commit}" 2>/dev/null && exclude+=("^$sha")
  done
  total=$(unpushed_commits "${exclude[@]}" | wc -l)
  mapfile -t fresh < <(unpushed_commits "${exclude[@]}" | head -n 50)

  findings=""
  for sha in "${fresh[@]}"; do
    reasons=""
    # Files this commit added or changed, relative to its first parent (or to nothing for a root commit).
    while IFS= read -r -d '' path; do
      if is_env_file "$path"; then
        reasons+="environment file $path; "
        continue
      fi
      size=$(git cat-file -s "$sha:$path" 2>/dev/null || echo 0)
      [[ "$size" -gt 0 && "$size" -le 5242880 ]] || continue     # skip empty and >5MB blobs
      hit=$(git cat-file -p "$sha:$path" 2>/dev/null | secret_prefixes | tr '\n' ' ')
      [[ -n "$hit" ]] && reasons+="secret-shaped string in $path (${hit% }); "
    done < <(git -c core.quotePath=false diff-tree -r --root -m --first-parent --no-commit-id --name-only -z --diff-filter=ACMR "$sha" 2>/dev/null)
    [[ -n "$reasons" ]] && findings+="${sha:0:12} ${reasons%; }"$'\n' && printf '%s %s\n' "$sha" "${reasons%; }" >> "$flag"
  done

  live_flags "$flag" >/dev/null     # drop flags for commits that no longer exist

  if [[ -n "$findings" ]]; then
    {
      echo "The metadev commit guard found a problem in a commit that was just created."
      sed 's/^/  /' <<<"$findings"
      echo "Undo it before doing anything else. For the most recent commit: git reset --soft HEAD~1, then unstage the file or move the value to an environment variable, and commit again."
      echo "Pushing from this repository is blocked until these commits are gone."
      echo "If a real secret was committed and has ever been pushed or shared, it must be rotated: tell the owner."
      echo "If this is a false positive (for example a documented test fixture), tell the owner. The plugin README explains how the owner clears the block."
      [[ "$total" -gt 50 ]] && echo "Note: $total new commits appeared; only the newest 50 were scanned."
    } >&2
    exit 2
  fi
  [[ "$total" -gt 50 ]] && echo "metadev commit guard: $total new commits appeared; only the newest 50 were scanned." >&2
  exit 0
  ;;
esac
exit 0
