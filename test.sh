#!/usr/bin/env bash
# Smoke test: runs install.sh and the pre-commit hook on a throwaway copy of this repo with a
# throwaway $HOME. Does not touch the real home or this repo's git config.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
KIT="$T/kit"; mkdir "$KIT"
(cd "$SRC" && tar --exclude=.git --exclude=.build -cf - .) | tar -C "$KIT" -xf -
git -C "$KIT" init -q -b main
export HOME="$T/home"; unset CLAUDE_CONFIG_DIR CODEX_HOME XDG_CONFIG_HOME PI_CODING_AGENT_DIR
mkdir -p "$HOME/.claude/skills" "$HOME/.codex" "$HOME/.gemini" "$HOME/.pi/agent"
printf '# Global Agent Rules\nold pasted copy\n' > "$HOME/.codex/AGENTS.md"
printf 'artemis block\n' > "$HOME/.gemini/GEMINI.md"

check() { eval "$1" || { echo "FAIL: $1"; cat "$T/out" 2>/dev/null; exit 1; }; }

echo "== install.sh"
"$KIT/install.sh" --profile mac > "$T/out" 2>&1 || { cat "$T/out"; exit 1; }
"$KIT/install.sh" > "$T/out2" 2>&1 # no flag: the profile is remembered
check '[ -f "$HOME/.agents/skills/release-cicd/SKILL.md" ]'
check '[ -L "$HOME/.claude/skills/docker-hosts" ] && [ -L "$HOME/.claude/skills/worktree-workflow" ]'
check '[ -f "$HOME/.claude/rules/99-machine.md" ] && grep -q "Machine notes: mac" "$HOME/.claude/rules/99-machine.md"'
check 'grep -q "^profile: mac" "$T/out2"'
check '[ "$(grep -c "BEGIN agent-kit" "$HOME/.codex/AGENTS.md")" = 1 ]'
check 'grep -q "Machine notes: mac" "$HOME/.gemini/GEMINI.md" && grep -q "artemis block" "$HOME/.gemini/GEMINI.md"'
check '[ -f "$HOME/.pi/agent/AGENTS.md" ] && grep -q "Machine notes: mac" "$HOME/.pi/agent/AGENTS.md"'
check 'grep -q "^WARN.*old pasted copy" "$T/out"'
check '! grep -Eq "^(link|write)" "$T/out2"' # the second run changes nothing
check '[ "$(git -C "$KIT" config core.hooksPath)" = ".githooks" ]'
rm "$HOME/.agents/.agent-kit-profile"
"$KIT/install.sh" --dry-run > "$T/out3" 2>&1
check 'grep -q "^profile: generic" "$T/out3"' # never guesses mac
if "$KIT/install.sh" --profile nope > /dev/null 2>&1; then echo "FAIL: unknown profile accepted"; exit 1; fi

echo "== pre-commit hook"
cd "$KIT"
git config user.name t; git config user.email t@t
printf 'token = ghp_abcdefghijklmnopqrstuvwxyz0123456789\n' > leak.txt
git add leak.txt
if git commit -q -m leak > "$T/hook" 2>&1; then echo "FAIL: a token was committed"; exit 1; fi
check 'grep -q "^BLOCK" "$T/hook"'
AGENT_KIT_ALLOW_SENSITIVE=1 git commit -q -m allowed > /dev/null 2>&1 || { echo "FAIL: override did not work"; exit 1; }
printf 'password = hunter2hunter2\n' > leak2.txt; git add leak2.txt
if git commit -q -m leak2 > /dev/null 2>&1; then echo "FAIL: a password assignment was committed"; exit 1; fi
git reset -q --hard HEAD
printf 'contact: someone@gmail.com host 8.8.8.8\n' > warn.txt; git add warn.txt
git commit -q -m warn > "$T/hook" 2>&1 || { echo "FAIL: warnings must not block"; cat "$T/hook"; exit 1; }
check 'grep -q "^WARN.*email" "$T/hook" && grep -q "^WARN.*IPv4" "$T/hook"'
git add -A
git commit -q -m "the kit itself" > "$T/hook" 2>&1 || { echo "FAIL: the kit's own content is blocked by its own hook"; cat "$T/hook"; exit 1; }
echo ok
