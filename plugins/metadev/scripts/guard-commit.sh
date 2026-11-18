#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks `git commit` when the staged changes include
# .env files or lines that look like secrets. Exit 2 blocks the tool call and
# shows stderr to the agent. A commit it cannot evaluate (compound command,
# another repository) is blocked. It is a backstop, not a boundary: it does not
# see git aliases or commits made outside the Bash tool.
set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/guard-lib.sh"

input=$(cat)
if ! cmd=$(json_get tool_input.command); then
  # Neither jq nor python3 is available, so the command cannot be read.
  # Refuse anything that involves git rather than let it through unchecked.
  if [[ "$input" == *git* ]]; then
    echo "Blocked by the metadev commit guard: neither jq nor python3 is installed, so git commands cannot be checked. Install jq." >&2
    exit 2
  fi
  exit 0
fi
cwd=$(json_get cwd)
[[ -n "$cmd" ]] || exit 0

# Does the command run git commit anywhere (including `git -C dir commit`,
# `/usr/bin/git commit`, `sh -c "git commit"`)? If not, nothing to do.
any_commit='(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)'
# Detect on a normalised copy, so that quoting, backslashes and line
# continuations (`"git" commit`, `g\it commit`, `git \<newline> commit`) do not
# hide the commit. The strict shape check below runs on the original text and
# refuses those forms.
# Two readings of a backslash-newline: as a space, and as nothing.
bsnl=$'\\\n'
norm_a=${cmd//"$bsnl"/ };  norm_a=${norm_a//[\'\"\\]/}
norm_b=${cmd//"$bsnl"/};   norm_b=${norm_b//[\'\"\\]/}
grep -Eq "$any_commit" <<<"$norm_a" || grep -Eq "$any_commit" <<<"$norm_b" || exit 0

block() { echo "Commit blocked by the metadev commit guard." >&2; echo "$1" >&2; exit 2; }

# The staged content is checked now, before the command runs, in the session's
# working directory. That is only sound when the command can do nothing except
# commit what is already staged here. So the command must match one strict
# shape; everything else is refused rather than parsed:
#
#   git commit [-q -s -v -a --amend --no-edit --allow-empty ...] [-m 'literal']...
#   git commit [flags] -F - <<'DELIM'      (quoted delimiter: body is literal)
#   ...message...
#   DELIM
#
# No pathspecs, no substitution or expansion, no second command.
while [[ "$cmd" == *$'\n' || "$cmd" == *' ' || "$cmd" == *$'\t' ]]; do cmd=${cmd%?}; done
first_line=${cmd%%$'\n'*}

re_flag="(-[aqsv]+|--all|--quiet|--signoff|--verbose|--amend|--no-edit|--allow-empty|--allow-empty-message)"
re_msg="(-[aqsv]*m|--message)[[:space:]]+('[^']*'|\"[^\"\$\`\\\\!]*\")"
re_file="(-[aqsv]*F|--file)[[:space:]]+-[[:space:]]+<<'[A-Za-z_][A-Za-z0-9_]*'"
re_shape="^[[:space:]]*git[[:space:]]+commit([[:space:]]+(${re_flag}|${re_msg}))*([[:space:]]+${re_file})?[[:space:]]*\$"

how="Stage files in a separate command, then commit with either
  git commit -m 'message'
or
  git commit -F - <<'EOF'
  message
  EOF
from the repository directory. Not accepted in the same command: cd, git -C, git add, pathspecs, \$( ), backticks, pipes, && or ; ."

grep -Eq -- "$re_shape" <<<"$first_line" || block "This commit command is not in a form the guard can check. $how"

delim=$(sed -nE "s/.*<<'([A-Za-z_][A-Za-z0-9_]*)'[[:space:]]*\$/\1/p" <<<"$first_line")
if [[ -z "$delim" ]]; then
  [[ "$cmd" == *$'\n'* ]] && block "The command continues after the commit line. $how"
else
  [[ "$cmd" == *$'\n'* ]] || block "The heredoc for the commit message is not closed. $how"
  body=${cmd#*$'\n'}
  [[ "${body##*$'\n'}" == "$delim" ]] || block "Something follows the commit message heredoc. $how"
  [[ $(grep -cFx -- "$delim" <<<"$body") -eq 1 ]] || block "The heredoc delimiter appears inside the message, so text after it would run as a command. $how"
fi

[[ -n "${GIT_DIR:-}${GIT_WORK_TREE:-}" ]] && block "GIT_DIR or GIT_WORK_TREE is set, so the commit target cannot be checked. Unset them and commit from the repository directory."

[[ -n "$cwd" && -d "$cwd" ]] || block "The working directory is unknown, so the staged changes cannot be checked."
cd "$cwd" || block "Cannot enter $cwd to check the staged changes."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
# git reports paths relative to the top of the repository; read them from there.
cd "$(git rev-parse --show-toplevel)" || block "Cannot enter the top of the repository to check the staged changes."

# What this commit would take: the staged files, plus tracked modifications when
# the commit uses -a. The content is read from the index or the working tree
# and scanned whole, so nothing depends on how a diff is rendered.
names() { git -c core.quotePath=false diff --no-ext-diff --name-only -z --diff-filter=d "$@"; }
with_all=0
grep -Eq -- '[[:space:]]-[a-zA-Z]*a[a-zA-Z]*([[:space:]]|$)|--all' <<<"$first_line" && with_all=1

problems=""
check() { # $1 = path, content on stdin
  local hit
  if is_env_file "$1"; then problems+="  environment file: $1"$'\n'; return; fi
  hit=$(secret_prefixes | tr '\n' ' ')
  [[ -n "$hit" ]] && problems+="  secret-shaped string in $1 (${hit% })"$'\n'
}
while IFS= read -r -d '' path; do
  check "$path" < <(git cat-file -p ":$path" 2>/dev/null)
done < <(names --cached)
if [[ "$with_all" -eq 1 ]]; then
  while IFS= read -r -d '' path; do
    if [[ -f "$path" ]]; then check "$path" < "$path"; elif [[ -e "$path" || -L "$path" ]]; then problems+="  could not read $path to check it"$'\n'; fi
  done < <(names)
fi

if [[ -n "$problems" ]]; then
  {
    echo "Commit blocked by the metadev commit guard. The commit would include:"
    printf '%s' "$problems"
    echo "Unstage the file or move the value to an environment variable, then commit again."
    echo "If the value was ever pushed or shared, rotate it and tell the owner."
    echo "If this is a false positive (for example a documented test fixture), say so to the owner and let them commit it."
  } >&2
  exit 2
fi
exit 0
