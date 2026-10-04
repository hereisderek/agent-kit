#!/usr/bin/env bash
# Link this kit's skills and rules into the agents on THIS machine. Safe to re-run.
#   ./install.sh [--profile mac|agent-lxc|generic|<name>] [--dry-run]
# Profile = machines/<name>.md. Resolved as: --profile, else the one remembered from the last run
# (~/.agents/.agent-kit-profile), else agent-lxc if this is the agent LXC, else generic. It never
# guesses "mac": another Mac gets generic. Never overwrites a real file or directory: it prints SKIP
# and leaves it for you to move away.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HOME/.agents"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PROFILE="" DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:?--profile needs a value}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *) echo "usage: $0 [--profile mac|agent-lxc|laptop] [--dry-run]" >&2; exit 2 ;;
  esac
done

REMEMBERED="$AGENTS/.agent-kit-profile"
if [ -z "$PROFILE" ] && [ -f "$REMEMBERED" ]; then PROFILE="$(cat "$REMEMBERED")"; fi
if [ -z "$PROFILE" ]; then
  if [ "$(hostname)" = agent ] && [ -d /opt/config ]; then PROFILE=agent-lxc
  else
    PROFILE=generic
    [ "$(uname)" = Darwin ] && echo "NOTE using profile generic. If this is Derek's main Mac, run: install.sh --profile mac (remembered afterwards)"
  fi
fi
[ -f "$KIT/machines/$PROFILE.md" ] || { echo "no machines/$PROFILE.md" >&2; exit 1; }
if grep -q TODO "$KIT/machines/$PROFILE.md"; then echo "WARN machines/$PROFILE.md still has TODOs"; fi
echo "profile: $PROFILE  kit: $KIT$([ "$DRY" = 1 ] && echo '  (dry run)')"

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" = 1 ]; then say "  + $*"; else "$@"; fi; }
physical() { (cd -P "$1" 2>/dev/null && pwd) || true; }

# link <target> <path>: (re)point a symlink; leave a real file or directory alone.
link() {
  local target="$1" path="$2"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    say "SKIP $path exists and is not a symlink; move it away to let the kit manage it"; return 0
  fi
  if [ "$(readlink "$path" 2>/dev/null || true)" = "$target" ]; then return 0; fi
  run mkdir -p "$(dirname "$path")"
  run ln -sfn "$target" "$path"
  say "link $path -> $target"
}

# 1. Skills: the universal store ~/.agents/skills, then each agent's own skills dir (if it exists).
say "== skills"
run mkdir -p "$AGENTS/skills"
SKILL_DIRS=("$CLAUDE_DIR/skills" "${CODEX_HOME:-$HOME/.codex}/skills" "$HOME/.gemini/skills" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills")
for d in "$KIT"/skills/*/; do
  s="$(basename "$d")"
  link "$KIT/skills/$s" "$AGENTS/skills/$s"
  for a in "${SKILL_DIRS[@]}"; do
    [ -d "$a" ] || continue
    # On the agent LXC these dirs ARE the universal store (symlinks to it): linking into them would loop.
    if [ "$(physical "$a")" = "$(physical "$AGENTS/skills")" ]; then continue; fi
    link "$AGENTS/skills/$s" "$a/$s"
  done
done

# 2. Rules: a directory of symlinks (all of rules/ plus this machine's notes as 99-machine.md).
#    Claude Code reads it directly through ~/.claude/rules.
say "== rules"
B="$KIT/.build/rules"
run rm -rf "$B"
run mkdir -p "$B"
for f in "$KIT"/rules/*.md; do run ln -s "$f" "$B/$(basename "$f")"; done
run ln -s "$KIT/machines/$PROFILE.md" "$B/99-machine.md"
if [ -d "$AGENTS/rules" ] && [ ! -L "$AGENTS/rules" ] && [ -z "$(ls -A "$AGENTS/rules")" ]; then
  run rmdir "$AGENTS/rules"   # an empty placeholder dir (agent LXC)
fi
link "$B" "$AGENTS/rules"
link "$AGENTS/rules" "$CLAUDE_DIR/rules"

# 3. Agents with no rules directory get one managed block in their AGENTS.md / GEMINI.md.
#    Everything outside the BEGIN/END markers (e.g. the ARTEMIS block) is left alone.
say "== AGENTS.md blocks (codex, gemini, opencode, pi)"
KIT="$KIT" PROFILE="$PROFILE" DRY="$DRY" python3 - \
  "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "$HOME/.gemini/GEMINI.md" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/AGENTS.md" \
  "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/AGENTS.md" <<'PY'
import os, re, sys
from pathlib import Path

kit, profile, dry = Path(os.environ["KIT"]), os.environ["PROFILE"], os.environ["DRY"] == "1"
files = sorted((kit / "rules").glob("*.md")) + [kit / "machines" / f"{profile}.md"]
body = "\n\n".join(f"<!-- agent-kit: {p.parent.name}/{p.name} -->\n{p.read_text().strip()}" for p in files)
BEGIN = "<!-- BEGIN agent-kit (managed by install.sh; edits are overwritten) -->"  # never reword: it is the match key
END = "<!-- END agent-kit -->"
block = f"{BEGIN}\n{body}\n{END}\n"
pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)

for target in map(Path, sys.argv[1:]):
    if not target.parent.is_dir():
        print(f"skip {target} (no {target.parent})")
        continue
    text = target.read_text() if target.exists() else ""
    if "# Global Agent Rules" in pattern.sub("", text):
        print(f"WARN {target} still has an old pasted copy of the rules; delete it to avoid duplicates")
    new = pattern.sub(lambda m: block, text) if BEGIN in text else (text.rstrip("\n") + "\n\n" if text else "") + block
    if new == text:
        print(f"ok   {target}")
        continue
    print(f"{'would write' if dry else 'write'} {target}")
    if not dry:
        target.write_text(new)
PY
# 4. This clone is a PUBLIC repo: turn on its commit-time check for secrets and sensitive info.
if [ -d "$KIT/.git" ] && [ -d "$KIT/.githooks" ] && [ "$(git -C "$KIT" config core.hooksPath || true)" != .githooks ]; then
  run git -C "$KIT" config core.hooksPath .githooks
  say "git hooks enabled in $KIT (pre-commit scan for sensitive info)"
fi

# 5. Remember the profile so later runs (and the agent LXC's startup hook) need no flag.
if [ "$DRY" != 1 ]; then mkdir -p "$AGENTS" && printf '%s\n' "$PROFILE" > "$REMEMBERED"; fi
say "done"
