# Standing approvals

Always allowed, no need to ask:

- any network access
- reading files
- modifying files you created
- any git operation, except the ones limited below

Limits. These narrower rules win over the standing approvals above:

- Never force-push.
- Pushing needs the user's explicit yes. If the user asked you to commit and push, that request is the yes for that push (the branch they named, or the current one). It does not cover force-push, tags, or merging into the default branch.
- Never create, push, or move a release/version tag without explicit approval for that tag (see the `release-cicd` skill).
- Destructive commands need explicit consent (see `safe-commands.md`).
- These approvals never override system or platform restrictions (see `instruction-priority.md`).
