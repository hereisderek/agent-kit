# Machine notes: mac

Applies only on Derek's main Mac (profile `mac`; install with `install.sh --profile mac`, which is then remembered). Where a shared rule or skill says "see the machine notes", these facts win.

- **OS and shell:** macOS (Apple Silicon), zsh. Package manager: Homebrew (`/opt/homebrew`).
- **Workspace path:** projects live under `/Volumes/private/workspace/`. There is no `/workspace` on this Mac; `/workspace` exists only on the LXCs (2026, 2028, 2029, 2011).
- **Kit location:** `~/.agents/agent-kit`.
- **Worktrunk:** installed with Homebrew (v0.80.0 on 2026-10-04), and the Claude Code plugin is installed (so Claude Code creates worktrees through `wt` and `wt list` shows agent activity). If `wt` is missing, tell the user: `brew install worktrunk && wt config shell install`. The Codex and opencode plugins are not installed (`wt config plugins <agent> install` is a user config change: ask first).
- **Docker:** native. Docker CLI with the OrbStack context (`docker context ls` shows `orbstack`). Use the local engine by default. Use `docker-lxc` / `podman-lxc` (LXC 2028 / 2029) only when the user names them (see the `docker-hosts` skill).
- **SSH to the LXCs:** `ssh derek@172.16.2.<NN>` (key `~/.ssh/key.ed25519`, the same key used for `root@pve.local`).
- **markitdown:** not installed. `uv` is (`~/.local/bin/uv`). After the user agrees: `uv tool install 'markitdown[pdf,docx,pptx,xlsx]'` (add extras per file type).
- **How rules reach each agent:**
  - Claude Code reads `~/.claude/rules/` (a symlink to `~/.agents/rules`).
  - Codex (`~/.codex/AGENTS.md`), Gemini/Antigravity (`~/.gemini/GEMINI.md`), opencode (`~/.config/opencode/AGENTS.md`) and Pi (`~/.pi/agent/AGENTS.md`, not installed here) get a managed block written by `install.sh`. The ARTEMIS block in the Codex and Gemini files belongs to the ARTEMIS tool and is left alone.
- **Skills:** third-party skills are installed by the `skills` CLI (`npx skills ... -g`, see `~/.agents/bootstrap.sh`) into `~/.agents/skills`. Kit skills are symlinked into the same place and into each agent's `skills/` directory.
- **Mac-only, not in the kit:** `~/.agents/agent-overrides/` (skills synced by the Claude desktop app), `~/.agents/bootstrap.sh`, `~/.agents/reinstall-skills.sh`, `~/.agents/migration-backup/`.
