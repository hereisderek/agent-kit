# Source of this skill

Microsoft's [microsoft/markitdown](https://github.com/microsoft/markitdown) ships no agent skill, so this one is based on the existing community skill:

- Origin: [intellectronica/agent-skills](https://github.com/intellectronica/agent-skills), `plugins/markdown-converter/skills`, branch `main`, commit `253e4ff037ba0dc5ebaa08648aa9af90c9e11ade`
- License: CC0-1.0 (public domain dedication), so modification and redistribution are fine.
- Previously installed by hand into `~/.agents/myskills/markdown-converter` (with a `.skillfish.json`, not carried over: it would be wrong after these changes and its updater would overwrite them).

## Local changes

- Added the "Before first use: check, then ask" gate. Upstream ran `uvx markitdown` directly ("no installation required"); here `markitdown` must already be installed, or the user must agree to an install first.
- Dropped the `uvx` examples and the "first run caches dependencies" note.
- Options list rewritten from markitdown's own argparse definitions (`packages/markitdown/src/markitdown/__main__.py`, checked 2026-10-04). Upstream's list lacked `--use-cu`, `--cu-*`, `--keep-data-uris`, `-v`, and the `-p` short form.
- Added the install extras table, the large-document tip, and the untrusted-input note (from the markitdown README's security section).
- Install method per machine moved to the machine notes.

To pick up upstream changes, diff against the commit above; do not overwrite this file.
