#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks `git commit` when the staged changes include
# .env files or lines that look like secrets. Exit 2 blocks the tool call and
# shows stderr to the agent. A commit it cannot evaluate (compound command,
# another repository) is blocked. It is a backstop, not a boundary: it does not
# see git aliases or commits made outside the Bash tool.
set -uo pipefail

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || exit 0
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null) || exit 0

# Does the command run git commit anywhere (including `git -C dir commit`,
# `/usr/bin/git commit`, `sh -c "git commit"`)? If not, nothing to do.
any_commit='(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)'
grep -Eq "$any_commit" <<<"$cmd" || exit 0

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

# `git commit -a` / `-am` stages tracked modifications at commit time.
if grep -Eq -- '[[:space:]]-[a-zA-Z]*a[a-zA-Z]*([[:space:]]|$)|--all' <<<"$first_line"; then
  files=$( { git diff --cached --name-only; git diff --name-only; } | sort -u )
  diff=$( { git diff --cached -U0; git diff -U0; } )
else
  files=$(git diff --cached --name-only)
  diff=$(git diff --cached -U0)
fi

problems=""

# 1. Environment files (templates are fine).
env_files=$(grep -E '(^|/)\.env(\.[^/]*)?$' <<<"$files" | grep -Ev '\.(example|sample|template|dist)$' || true)
if [[ -n "$env_files" ]]; then
  problems+=$'Environment files staged for commit:\n'"$(sed 's/^/  /' <<<"$env_files")"$'\n'
fi

# 2. Secret-shaped strings on added lines.
patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9]{32,}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{20,}|sk_live_[A-Za-z0-9]{20,}|rk_live_[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
hits=$(grep -E '^\+[^+]' <<<"$diff" | grep -Eo -- "$patterns" | sort -u | head -5 || true)
if [[ -n "$hits" ]]; then
  # Show only a prefix so the secret is not echoed back in full.
  problems+=$'Added lines contain what look like secrets:\n'"$(cut -c1-12 <<<"$hits" | sed 's/$/.../; s/^/  /')"$'\n'
fi

if [[ -n "$problems" ]]; then
  {
    echo "Commit blocked by the metadev commit guard."
    echo "$problems"
    echo "Unstage the file or move the value to an environment variable, then commit again."
    echo "If the value was ever pushed or shared, rotate it and tell the owner."
    echo "If this is a false positive (for example a documented test fixture), say so to the owner and let them commit it."
  } >&2
  exit 2
fi
exit 0
