# agent-kit

Derek's own agent skills and global rules, shared by every machine and agent he uses. One repo, cloned to `~/.agents/agent-kit` on each machine, linked into the agents by `install.sh`. For AI agents working in this repo, see [AGENTS.md](AGENTS.md).

> **This repository is public.** Never commit passwords, tokens, API keys, private keys, personal data, or public IP addresses. A pre-commit hook (enabled by `install.sh`) blocks obvious secrets and warns about emails and public IPs. What is here on purpose: private LAN IPs (`172.16.x.x`), LXC IDs and hostnames, Derek's public domains, his GitHub username, ssh key *file names*. Anything that must stay private goes in the private `proxmox-services` repo or on the machine itself.

Third-party skills (the `skills` CLI: taste-skill, android/skills, the official worktrunk skill, ...) are not in here. They are installed separately: `~/.agents/bootstrap.sh` on the Mac, `/opt/scripts/startup.d/skills-startup.sh` on the agent LXC.

## Layout

```
skills/<name>/SKILL.md   Derek's own skills (loaded on demand)
rules/*.md               global rules, loaded every session, identical on every machine
machines/<profile>.md    facts that differ per machine; installed as rules/99-machine.md
install.sh               links skills and rules into this machine's agents
test.sh                  smoke test of install.sh and the hook (throwaway copy and $HOME)
.githooks/pre-commit     the public-repo guard
AGENTS.md                instructions for agents working in this repo (what each part is for)
```

| Skill | What it is |
|-------|------------|
| `markdown-converter` | Convert documents to Markdown with Microsoft's `markitdown`. Asks before installing it. Derived from an existing community skill, see its `SOURCE.md`. |
| `release-cicd` | Default tag format and release CI/CD policy for package releases only. Any runtime instruction overrides it. |
| `docker-hosts` | Use the Docker and Podman LXCs (2028 / 2029) on machines without docker, or when asked: ports, data layout, exposing a service through Caddy under `/sites/<app>`. |
| `worktree-workflow` | Standard feature workflow with Worktrunk: start in a new worktree, work, finish by PR or `wt merge`, when merging is allowed, what is automated. |

## What differs per machine

Anything specific to one machine goes in `machines/<profile>.md`, never in a shared rule or skill. Shared files say "see the machine notes" instead.

| | `mac` | `agent-lxc` | `generic` |
|---|---|---|---|
| Machine | Derek's main Mac, macOS, zsh | LXC 2026 `agent`, Debian 13, bash | any other environment: another laptop, a VM, CI |
| Workspace | `/Volumes/private/workspace/` | `/workspace` | the repo you are in |
| Install tools with | Homebrew | apt, or `/opt/tools/<name>` (no brew, no uv, no pip) | whatever it has; discovered at runtime |
| Docker | native (OrbStack) | none, use LXC 2028 / 2029 | native if present, else LXC 2028 / 2029 |
| Worktrunk | brew | installed by `wt-startup.sh` | discovered; ask before installing |
| Kit updated by | `git pull` + `install.sh` | `agent-kit-startup.sh` on every start; `updater.sh update` pulls | `git pull` + `install.sh` |
| Agents wired | Claude, Codex, Gemini/Antigravity, opencode, Pi (whichever are installed) | same (config dirs under `/opt/config`) | same |

`generic` assumes nothing: it tells the agent to find out. Add `machines/<name>.md` when a machine becomes a regular one.

## Install

```bash
git clone https://github.com/hereisderek/agent-kit.git ~/.agents/agent-kit
~/.agents/agent-kit/install.sh --dry-run     # shows every link and file it would change
~/.agents/agent-kit/install.sh
```

The profile is resolved as: `--profile`, else the one remembered from the last run (`~/.agents/.agent-kit-profile`), else `agent-lxc` on the agent LXC, else `generic`. It never guesses `mac`: on Derek's main Mac run `install.sh --profile mac` once, and it is remembered. `install.sh` is idempotent and never overwrites a real file or directory: it prints `SKIP` and leaves it for you to move away.

What it does:

1. Symlinks each `skills/<name>` into `~/.agents/skills/` and into every agent's `skills/` dir that exists.
2. Builds `.build/rules/` (symlinks to `rules/*.md` plus the machine file as `99-machine.md`), points `~/.agents/rules` at it, and `~/.claude/rules` at that. Claude Code reads it directly.
3. Codex, Gemini/Antigravity, opencode, and Pi have no rules directory, so each gets one managed block between `BEGIN agent-kit` / `END agent-kit` markers in its global `AGENTS.md` / `GEMINI.md` (Pi: `$PI_CODING_AGENT_DIR/AGENTS.md`, default `~/.pi/agent`). Re-running replaces the block. Anything outside the markers (such as the ARTEMIS block) is untouched. Agents that are not installed are skipped. Re-run `install.sh` after editing a rule.
4. Enables the pre-commit hook in this clone (`git config core.hooksPath .githooks`).

### One-time migration on the Mac

`~/.agents/rules` and `~/.agents/myskills` are real directories today. Move them aside, then install:

```bash
mv ~/.agents/rules ~/.agents/rules.pre-kit
mv ~/.agents/myskills ~/.agents/myskills.pre-kit
~/.agents/agent-kit/install.sh --profile mac
```

The old `release-cicd` links in `~/.claude/skills` point into `myskills` and get repointed. `~/.codex/AGENTS.md` and `~/.gemini/GEMINI.md` hold an old pasted copy of `rules.md` (`install.sh` warns about it): delete that copy so the rules are not loaded twice.

## Changing things

- **Edit a skill or rule here**, commit, push. Other machines: `git pull` and `./install.sh` (the agent LXC does this itself).
- **New skill:** `skills/<name>/SKILL.md` with `name` and `description` frontmatter, then `./install.sh`.
- **New rule:** one narrow topic per file in `rules/`. If it only holds on some machines, put it in those machines' notes instead.
- **Machine-specific fact:** `machines/<profile>.md`.
- Run `./test.sh` after changing `install.sh` or the hook.

## Where the old rules went

The old files in `~/.agents/rules/` were split like this.

| Old | Now |
|-----|-----|
| `rules.md`, "AGENTS.md: Unified agent instructions" | `rules/agents-md.md` |
| `rules.md`, "Planning & User Review Protocol" (first two bullets) | `rules/planning-and-review.md` |
| `rules.md`, "Planning & User Review Protocol" (testing policy bullet) | `rules/testing-policy.md` |
| `rules.md`, "General approval rule" | `rules/approvals.md`. Pushing now needs a yes unless Derek asked to commit and push. |
| `rules.md`, "Skills and reusable rules" | `rules/skills-and-rules-loading.md` |
| `rules.md`, "Instruction priority" | `rules/instruction-priority.md` |
| `rules.md`, "Release cycle and CI/CD" | dropped: the `release-cicd` skill already covers all of it. The "no release tags without approval" guard is kept in `rules/approvals.md`. |
| `safe-command-rule.md` | `rules/safe-commands.md` |
| `text-format.md` | `rules/deliverables-raw-syntax.md` |
| `manner.md` | `rules/no-mannered-prose.md` |
| `worktrunk.md` | `rules/worktrunk.md`, reworked, plus the `worktree-workflow` skill. The old `worktree.md` it pointed at is not part of the kit (it was already in the Trash); worktrees are done with Worktrunk only. Worktrunk ships no rule file of its own, only the `worktrunk` skill, which the rule defers to for CLI detail. |
