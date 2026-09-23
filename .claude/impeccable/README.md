# Impeccable (vendored)

[Impeccable](https://github.com/pbakaus/impeccable) (Apache-2.0, see `LICENSE`
and `NOTICE.md`) — the design skill that `CLAUDE.md` assigns UX, UI and design
system work to — is vendored so every Claude Code session on this repo has it,
including a fresh cloud container where `npx impeccable install` cannot fetch
its signed bundle.

- `.claude/skills/impeccable/` and `.claude/agents/impeccable-*.md` — upstream's
  project-scope Claude build, unchanged. Do not edit; re-sync instead.
- Hooks in `.claude/settings.json`: upstream's `PostToolUse` (Edit|Write, UI
  checks) and `Stop` (design deep pass), copied from `upstream-settings.json`.
- The engine binary is not vendored: the launcher downloads it once per machine
  into `~/.impeccable/bin/`, and `.claude/hooks/session-start.sh` does that at
  session start.
- `UPSTREAM` — the upstream ref and commit currently vendored.
- `sync.sh [git-ref]` — re-vendor (default: the ref in `UPSTREAM`); afterwards
  diff `upstream-settings.json` and update the hooks in `.claude/settings.json`
  if upstream changed them.

Do not also install the `impeccable` plugin or run `npx impeccable install`
here: the skill and hooks would be loaded twice.
