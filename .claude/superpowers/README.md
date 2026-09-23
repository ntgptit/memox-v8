# Superpowers (vendored)

The [Superpowers](https://github.com/obra/superpowers) skills (MIT, see
`LICENSE`) are copied into `.claude/skills/` so every Claude Code session on this
repo has them — including a fresh cloud container, where a plugin declared in
settings is not installed before the session starts.

- `UPSTREAM` — the upstream ref and commit currently vendored.
- `SKILLS` — the skill folders in `.claude/skills/` that came from upstream;
  do not edit them by hand, re-sync instead.
- `sync.sh [git-ref]` — re-vendor (default: the ref in `UPSTREAM`). It rewrites
  plugin-namespaced names `superpowers:<skill>` to `<skill>` and changes nothing
  else.
- `.claude/hooks/session-start.sh` loads `using-superpowers` into every session,
  replacing the plugin's own SessionStart hook.

Do not also install the `superpowers` plugin: the skills would be loaded twice.
