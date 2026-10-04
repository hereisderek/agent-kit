# Machine notes: generic

Applies on any machine that has no file of its own in `machines/` (profile `generic`): another laptop, a VM, a cloud box, a CI runner. Nothing about this machine is assumed. Find out; do not guess. Where a shared rule or skill says "see the machine notes", use this.

- **Discover first:** `uname -s`, `$SHELL`, the package manager (`command -v brew apt dnf pacman winget`), and the tools you need (`command -v docker podman uv wt`).
- **Workspace:** the repository you are in. `/workspace` and `/Volumes/private/workspace` exist only on specific machines.
- **Kit location:** `~/.agents/agent-kit`.
- **Docker:** use native docker when `command -v docker` works. If it does not, use the `docker-hosts` skill (LXC 2028 / 2029). That needs this machine to reach `172.16.2.28` (Derek's LAN or VPN) with an ssh key the LXC accepts. If it cannot, say so instead of improvising.
- **Installing tools** (`wt`, `uv`, `markitdown`, ...): ask first, use this machine's package manager, and say what you will install and where. Worktrunk: `brew install worktrunk && wt config shell install` where Homebrew exists, otherwise `cargo install worktrunk`. On Windows `wt` is Windows Terminal; the Worktrunk binary there is `git-wt`.
- **Agents:** `install.sh` wires whichever of Claude Code, Codex, Gemini/Antigravity, opencode, and Pi are installed, and skips the rest.
- **If this machine becomes a regular one,** add `machines/<name>.md` with its real facts and run `install.sh --profile <name>` (the choice is remembered).
