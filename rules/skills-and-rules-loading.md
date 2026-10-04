# Loading skills and rules

Reusable skills and rule packs live in `~/.agents`: skills in `~/.agents/skills/<name>/SKILL.md`, rules in `~/.agents/rules/`. Third-party skills come from the `skills` CLI. Derek's own skills and these rules come from the `agent-kit` repo (`~/.agents/agent-kit`), linked in by its `install.sh`. To change one of them, edit it in that repo.

Facts that differ per machine (paths, package manager, docker availability, how tools are installed) are in the machine notes, `~/.agents/rules/99-machine.md`. When a rule says "see the machine notes", read that file.

Before beginning work:

1. Load any skill or rule the user explicitly requests.
2. Inspect the available skill and rule names and descriptions.
3. Load only additional skills or rules that are materially relevant to the current task.
4. Do not load unrelated instructions "just in case". Keep context focused.
5. If a relevant skill refers to required supporting instructions, read those too.

Prefer specific task-domain skills (PDF, spreadsheets, Android, security, deployment) over broad generic ones.
