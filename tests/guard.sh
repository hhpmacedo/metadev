#!/usr/bin/env bash
# Tests for the commit guard. Drives the hook scripts the way Claude Code does:
# PreToolUse payload -> (run the command) -> PostToolUse payload.
# Usage: bash tests/guard.sh      Exit status 0 when every case passes.
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PRE_COMMIT="$ROOT/plugins/metadev/scripts/guard-commit.sh"
HISTORY="$ROOT/plugins/metadev/scripts/guard-history.sh"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
export XDG_STATE_HOME="$WORK/state"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
FAILED=0; N=0; ID=0
FAKE_KEY="sk-ant-$(printf 'a%.0s' $(seq 30))"
FAKE_AWS="AKIA$(printf 'B%.0s' $(seq 16))"

payload() { jq -n --arg e "$1" --arg c "$2" --arg d "$PWD" --arg i "$3" '{hook_event_name:$e,tool_name:"Bash",cwd:$d,tool_use_id:$i,tool_input:{command:$c}}'; }
expect() { # label, got, want
  N=$((N+1)); if [[ "$2" == "$3" ]]; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s (got %s, want %s)\n' "$1" "$2" "$3"; FAILED=1; fi; }
pre_commit() { payload PreToolUse "$1" t | bash "$PRE_COMMIT" >/dev/null 2>&1; echo $?; }
# step <command>: prints "<pre> <post>" ; the command runs only if both pre hooks allow it
step() {
  ID=$((ID+1)); local a b c
  payload PreToolUse "$1" "t$ID" | bash "$PRE_COMMIT" >/dev/null 2>&1; a=$?
  payload PreToolUse "$1" "t$ID" | bash "$HISTORY" >/dev/null 2>&1; b=$?
  if [[ $a -ne 0 || $b -ne 0 ]]; then echo "blocked -"; return; fi
  bash -c "$1" >/dev/null 2>&1
  payload PostToolUse "$1" "t$ID" | bash "$HISTORY" >/dev/null 2>"$WORK/post.err"; c=$?
  echo "0 $c"
}
flagged() { ls "$XDG_STATE_HOME"/metadev-guard/flag.* >/dev/null 2>&1 && echo yes || echo no; }
newrepo() { rm -rf "$WORK/$1"; mkdir -p "$WORK/$1"; cd "$WORK/$1"; git init -q -b main .; git config user.email t@t; git config user.name t; git config alias.ci commit; rm -f "$XDG_STATE_HOME"/metadev-guard/flag.* 2>/dev/null; }

echo "== layer 1: before the commit"
newrepo a; echo ok > a.txt; git add a.txt; git commit -qm init; echo x > b.txt; git add b.txt
expect "plain ls allowed"                         "$(pre_commit 'ls -la')" 0
expect "git log --grep commit allowed"            "$(pre_commit 'git log --grep commit')" 0
expect "-m single quotes allowed"                 "$(pre_commit "git commit -m 'add b; fix && tidy'")" 0
expect "-m double quotes allowed"                 "$(pre_commit 'git commit -q -m "add b"')" 0
expect "quoted heredoc allowed"                   "$(pre_commit "$(printf "git commit -q -F - <<'EOF'\nfix a && b; \$(x)\nEOF")")" 0
expect "--amend --no-edit allowed"                "$(pre_commit 'git commit --amend --no-edit')" 0
expect 'quoted "git" refused'                     "$(pre_commit '"git" commit -m x')" 2
expect 'backslash in git refused'                 "$(pre_commit 'g\it commit -m x')" 2
expect "line continuation refused"                "$(pre_commit "$(printf 'git \\\ncommit -m x')")" 2
expect "continuation inside the word refused"     "$(pre_commit "$(printf 'git com\\\nmit -m x')")" 2
expect "add && commit refused"                    "$(pre_commit "git add .env && git commit -m 'x'")" 2
expect "git -C refused"                           "$(pre_commit "git -C /tmp commit -m 'x'")" 2
expect "substitution in message refused"          "$(pre_commit 'git commit -m "x$(git add .env)"')" 2
expect "pathspec refused"                         "$(pre_commit "git commit -m 'x' .env")" 2
expect "command after heredoc refused"            "$(pre_commit "$(printf "git commit -F - <<'EOF'\nm\nEOF\ngit add .env")")" 2
echo "KEY=1" > .env; git add -f .env
expect ".env staged blocked"                      "$(pre_commit "git commit -m 'x'")" 2
git reset -q .env; rm .env; mkdir -p "we ird"; echo K=1 > "we ird/.env.local"; git add -f "we ird/.env.local"
expect ".env.local in a path with a space blocked" "$(pre_commit "git commit -m 'x'")" 2
git reset -q "we ird/.env.local"; rm -r "we ird"; echo "KEY=" > .env.example; git add .env.example
expect ".env.example allowed"                     "$(pre_commit "git commit -m 'x'")" 0
printf 'const k = "%s";\n' "$FAKE_KEY" > c.js; git add c.js
expect "secret in a staged file blocked"          "$(pre_commit "git commit -m 'x'")" 2
git reset -q c.js; printf '++ %s\n' "$FAKE_AWS" > c.js; git add c.js
expect "secret on a line starting with ++ blocked" "$(pre_commit "git commit -m 'x'")" 2
git reset -q c.js; printf 'bin\0ary %s \0\n' "$FAKE_KEY" > c.bin; git add c.bin
expect "secret in a binary file blocked"          "$(pre_commit "git commit -m 'x'")" 2
git reset -q c.bin; rm -f c.bin c.js; printf 'KEY=%s\n' "$FAKE_AWS" >> a.txt
expect "commit -am with unstaged secret blocked"  "$(pre_commit "git commit -am 'x'")" 2
expect "commit without -a ignores unstaged file"  "$(pre_commit "git commit -m 'x'")" 0
expect "missing working directory blocked"        "$(jq -n '{tool_input:{command:"git commit -m x"}}' | bash "$PRE_COMMIT" >/dev/null 2>&1; echo $?)" 2

echo "== layer 2: after the command"
newrepo b; echo ok > a.txt; git add a.txt; git commit -qm init
echo x > b.txt; git add b.txt
expect "clean commit passes both layers"          "$(step "git commit -qm 'add b'")" "0 0"
expect "no flag after a clean commit"             "$(flagged)" no
echo "KEY=1" > .env; git add -f .env
expect "aliased commit of .env caught afterwards" "$(step 'git ci -qm x')" "0 2"
expect "repository is flagged"                    "$(flagged)" yes
expect "message names the file, not the value"    "$(grep -c 'environment file .env' "$WORK/post.err")" 1
expect "push is refused while flagged"            "$(step 'git push origin main')" "blocked -"
expect "disguised push is refused while flagged"  "$(step 'git pu\sh origin main')" "blocked -"
expect "other commands still run while flagged"   "$(step 'git status')" "0 0"
expect "undoing the commit passes"                "$(step 'git reset -q --soft HEAD~1')" "0 0"
expect "flag cleared once the commit is gone"     "$(flagged)" no
git reset -q .env; rm -f .env
ID=$((ID+1)); payload PreToolUse 'git push origin main' "t$ID" | bash "$HISTORY" >/dev/null 2>&1
expect "push allowed again after the fix"         "$?" 0

printf 'const k = "%s";\n' "$FAKE_KEY" > c.js; git add c.js
expect "eval of a split-up commit refused up front" "$(step 'eval "g""it comm""it -qm x"')" "blocked -"
expect "commit through a variable caught afterwards" "$(step 'c=commit; git $c -qm x')" "0 2"
expect "secret value not echoed in full"          "$(grep -c "$FAKE_KEY" "$WORK/post.err")" 0
step 'git reset -q --hard HEAD~1' >/dev/null
printf 'bin\0ary %s \0\n' "$FAKE_KEY" > c.bin; git add c.bin
expect "binary file with a secret caught"         "$(step 'git ci -qm x')" "0 2"
step 'git reset -q --hard HEAD~1' >/dev/null
echo "KEY=1" > .env
expect "commit on another branch caught"          "$(step 'git checkout -qb side; git add -f .env; git ci -qm x; git checkout -q main')" "0 2"
git branch -qD side; step 'true' >/dev/null
expect "flag cleared after deleting the branch"   "$(flagged)" no
rm -f .env; echo "KEY=" > .env.example; git add .env.example
expect ".env.example via alias is fine"           "$(step 'git ci -qm x')" "0 0"

newrepo c; echo "KEY=1" > .env; git add -f .env
expect "first commit in a new repository caught"  "$(step 'git ci -qm x')" "0 2"

echo "== commits that arrive from a remote are not flagged"
rm -rf "$WORK/remote.git" "$WORK/other"; git init -q --bare -b main "$WORK/remote.git"
git clone -q "$WORK/remote.git" "$WORK/other" 2>/dev/null; cd "$WORK/other"; git config user.email o@o; git config user.name o
echo ok > a.txt; git add a.txt; git commit -qm init; git push -q origin HEAD:main
newrepo d; git remote add origin "$WORK/remote.git"; git pull -q origin main
cd "$WORK/other"; echo "KEY=1" > .env; git add -f .env; git commit -qm "someone else's mistake"; git push -q origin HEAD:main
cd "$WORK/d"
expect "pulled commit with .env is not flagged"   "$(step 'git pull -q origin main')" "0 0"
expect "no flag for a pulled commit"              "$(flagged)" no

echo "== without jq, python3 is used"
BIN="$WORK/bin"; mkdir -p "$BIN"
for b in bash cat grep git sed sort tr head tail cut wc python3 cksum mkdir rm dirname ls; do
  src=$(type -P "$b") && ln -sf "$src" "$BIN/$b"; done
cd "$WORK/a"
expect "refused shape still refused via python3"  "$(payload PreToolUse "git add .env && git commit -m 'x'" t | PATH="$BIN" bash "$PRE_COMMIT" >/dev/null 2>&1; echo $?)" 2
expect "allowed command still allowed via python3" "$(payload PreToolUse 'ls' t | PATH="$BIN" bash "$PRE_COMMIT" >/dev/null 2>&1; echo $?)" 0
rm -f "$BIN/python3"
expect "no parser: git command blocked"           "$(payload PreToolUse 'git status' t | PATH="$BIN" bash "$PRE_COMMIT" >/dev/null 2>&1; echo $?)" 2
expect "no parser: non-git command allowed"       "$(payload PreToolUse 'ls' t | PATH="$BIN" bash "$PRE_COMMIT" >/dev/null 2>&1; echo $?)" 0

echo; echo "$N cases, $([[ $FAILED -eq 0 ]] && echo 'all passed' || echo 'FAILURES above')"
exit $FAILED
