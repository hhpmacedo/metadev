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
  # Remote-tracking refs are recorded too, so that a commit made and pushed
  # within one command is still recognised as new afterwards.
  { printf '%s\n' "$top"; git rev-parse -q --verify HEAD 2>/dev/null; git for-each-ref --format='%(objectname)' refs/heads refs/remotes 2>/dev/null; } > "$snap" 2>/dev/null

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

  # Every commit that is new since the snapshot, whether or not it has been
  # pushed in the meantime.
  exclude=()
  for sha in "${before[@]}"; do
    git cat-file -e "$sha^{commit}" 2>/dev/null && exclude+=("^$sha")
  done
  new_commits() { git rev-list "${exclude[@]}" HEAD --branches --remotes 2>/dev/null; }
  total=$(new_commits | wc -l)
  mapfile -t fresh < <(new_commits | head -n 500)
  unpushed=$(unpushed_commits)
  me=$(git config user.email 2>/dev/null || true)

  findings=""; published=""; notes=""
  for sha in "${fresh[@]}"; do
    pushed=0
    if ! grep -qx -- "$sha" <<<"$unpushed"; then
      # Already on a remote. Only this user's own commits are of interest:
      # other people's commits that were fetched are not this session's doing.
      pushed=1
      [[ -n "$me" && "$(git log -1 --format=%ce "$sha" 2>/dev/null)" == "$me" ]] || continue
    fi
    reasons=""
    # Files this commit added or changed, relative to its first parent (or to nothing for a root commit).
    while IFS= read -r -d '' path; do
      if is_env_file "$path"; then
        reasons+="environment file $path; "
        continue
      fi
      size=$(git cat-file -s "$sha:$path" 2>/dev/null || echo 0)
      [[ "$size" -gt 0 ]] || continue
      if [[ "$size" -gt 52428800 ]]; then                       # over 50 MB: say so, do not pretend it was scanned
        notes+="${sha:0:12} $path is larger than 50 MB and was not scanned"$'\n'
        continue
      fi
      hit=$(git cat-file -p "$sha:$path" 2>/dev/null | secret_prefixes | tr '\n' ' ')
      [[ -n "$hit" ]] && reasons+="secret-shaped string in $path (${hit% }); "
    done < <(git -c core.quotePath=false diff-tree -r --root -m --first-parent --no-commit-id --name-only -z --diff-filter=d "$sha" 2>/dev/null)
    [[ -n "$reasons" ]] || continue
    if [[ "$pushed" -eq 1 ]]; then
      published+="${sha:0:12} ${reasons%; }"$'\n'
    else
      findings+="${sha:0:12} ${reasons%; }"$'\n'
      printf '%s %s\n' "$sha" "${reasons%; }" >> "$flag"
    fi
  done
  [[ "$total" -gt 500 ]] && notes+="$total new commits appeared; only the newest 500 were scanned"$'\n'

  live_flags "$flag" >/dev/null     # drop flags for commits that no longer exist

  if [[ -n "$published" ]]; then
    {
      echo "The metadev commit guard found a problem in a commit that is ALREADY ON A REMOTE."
      sed 's/^/  /' <<<"$published"
      echo "It was created and pushed before it could be checked. Stop what you are doing and tell the owner now."
      echo "If the value is a real secret it is exposed and must be rotated; removing the commit afterwards does not undo that."
      echo "Do not rewrite the remote history on your own."
    } >&2
  fi
  if [[ -n "$findings" ]]; then
    {
      echo "The metadev commit guard found a problem in a commit that was just created."
      sed 's/^/  /' <<<"$findings"
      echo "Undo it before doing anything else. For the most recent commit: git reset --soft HEAD~1, then unstage the file or move the value to an environment variable, and commit again."
      echo "Pushing from this repository is blocked until these commits are gone."
      echo "If a real secret was committed and has ever been pushed or shared, it must be rotated: tell the owner."
      echo "If this is a false positive (for example a documented test fixture), tell the owner. The plugin README explains how the owner clears the block."
    } >&2
  fi
  if [[ -n "$notes" ]]; then
    { echo "metadev commit guard, not fully checked (tell the owner):"; sed 's/^/  /' <<<"$notes"; } >&2
  fi
  [[ -n "$published$findings$notes" ]] && exit 2
  exit 0
  ;;
esac
exit 0
