# AGENTS.md (agent-kit)

Instructions for AI agents working **in this repository**. What the repo is for and how to install it: [README.md](README.md).

## This repository is public

Everything committed here is visible to the whole internet, forever (history included). Before every commit, read the diff for sensitive information. If anything might be sensitive, stop and ask Derek; do not commit it and do not "fix" it in a later commit (history keeps it).

Never commit: passwords, tokens, API keys, private keys, session cookies, recovery codes; personal email addresses, phone numbers, home address, anything about other people; public IP addresses; screenshots or logs that contain any of those.

Already here on purpose (public or low risk): private LAN addresses (`172.16.x.x`), LXC IDs and hostnames, Derek's public domains (`hereisderek.dpdns.org`, `derek.cloudns.ch`), his GitHub username, and ssh key *file names* (never key contents). If a new addition goes beyond that, ask first. Anything that must stay private belongs in the private `proxmox-services` repo or in a machine's own config, not here.

`.githooks/pre-commit` (enabled by `install.sh`) blocks obvious secrets and warns about emails and public IPs. It is a backstop, not a substitute for reading the diff.

## What each part is for

| Path | Purpose | Applies to |
|------|---------|------------|
| `rules/*.md` | Global rules, loaded into every agent session on every machine. Keep each file to one narrow topic and keep them short: they cost context in every session. | all machines |
| `skills/<name>/SKILL.md` | On-demand playbooks (loaded only when the task matches the description). Put detail here, not in a rule. | all machines |
| `machines/<profile>.md` | Facts that differ per machine; installed as `rules/99-machine.md`. Anything specific to one machine goes here and nowhere else. | one profile each |
| `install.sh` | Links skills and rules into this machine's agents; remembers the profile. Idempotent; never overwrites a real file. | per machine |
| `test.sh` | Sandboxed smoke test of `install.sh` and the hook. Run after changing either. | dev |
| `.githooks/pre-commit` | The public-repo guard above. | dev |

Skills: `markdown-converter` (markitdown, asks before installing), `release-cicd` (default release policy for package releases only), `docker-hosts` (use the Docker/Podman LXCs 2028/2029), `worktree-workflow` (feature work with Worktrunk).

## Rules for changing it

- **Machine-specific facts go in `machines/<profile>.md`.** A shared rule or skill must not name one machine's paths, package manager, or install commands; it says "see the machine notes".
- Profiles: `mac` (Derek's main Mac), `agent-lxc` (LXC 2026), `generic` (anything else; discovers its facts at runtime).
- A rule applies everywhere; if it only holds on some machines, it is a machine note or a skill instead.
- `skills/markdown-converter` is derived from an upstream skill; read its `SOURCE.md` before editing. `skills/release-cicd` is a default that user instructions override; keep that statement.
- `rules/approvals.md` and `rules/worktrunk.md` must agree on pushing: a push needs the user's yes, and "commit and push" is that yes for that push.
- After changing `install.sh` or the hook: `./test.sh`. After changing a rule on a machine that uses the `AGENTS.md` blocks (Codex, Gemini, opencode, Pi): re-run `./install.sh`.
- Write plainly (see `rules/no-mannered-prose.md`).

## Committing and pushing

Follow `rules/approvals.md`: a push needs Derek's yes unless he asked you to commit and push. This repo is cloned on other machines (including the agent LXC, which pulls `main` on update): do not push a broken `install.sh`.
