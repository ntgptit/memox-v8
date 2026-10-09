# Hooks

Wired in `.claude/settings.json`. They stay small and fast; the full test
suite and the whole-tree guard run at the gate (`dod_check.sh`), never here.

| Event | Hook | What it does |
|---|---|---|
| SessionStart | `session-start.sh` | Warms the vendored Impeccable engine and loads the vendored `using-superpowers` skill into the session. |
| SessionStart | `install-flutter.sh` | Installs the Flutter version in `.fvmrc` when the container lacks it. |
| SessionStart | `install-guard-deps.sh` | Installs the guard's Python dependencies. |
| PreToolUse (Bash) | `check_test_command.py` | Notes, beside the result and without blocking, a `flutter test` run over a directory, the whole suite or many files, and points at `run_tests.sh` (or `run_goldens.sh`). |
| PreToolUse (Edit, Write) | `block_released_migrations.py` | Denies a change to a `supabase/migrations/*.sql` or `drift_schemas/*.json` that `master` (local or `origin/master`) already has: a released migration is immutable, so the change goes into a new one. Shell edits are not covered. |
| PreToolUse (Agent, Workflow) | `enforce_subagent_model.py` | Pins every subagent to Sonnet (the final whole-branch review excepted) and refuses a workflow script whose `agent()` calls do not pin a model and an effort. |
| PostToolUse (Write, Edit) | `check_design_tokens.py` | Runs the guard's design-token rules on the Dart file just edited. |
| PostToolUse (Write, Edit), Stop | `impeccable hook` | Runs the vendored Impeccable design detector on UI edits. |

## Subagent model and effort

- Every subagent runs on Sonnet; the hook rewrites an `Agent` call's model and
  refuses an unpinned `agent()` in a workflow script.
- One exception: the final whole-branch review that `executing-plans` and
  `subagent-driven-development` dispatch once per branch runs on Opus. Give it
  `model: "opus"` and a description starting `Final whole-branch review`; any
  other call is still moved to Sonnet.
- A workflow agent pins `{model: 'sonnet', effort: 'low' | 'medium' | 'high' | 'max'}`.
- A workflow whose token floor reaches 300k, fans out to an unknown size or
  asks for another model is offered to the owner with `AskUserQuestion`
  before `Workflow` is called; below that, Claude decides alone.

## Rules

- A hook runs only code vendored in this repo (`.claude/hooks/`,
  `.claude/skills/`, the guard). The Impeccable launcher downloads its own
  pinned engine on first run; nothing else fetches code.
- ECC's hooks are never used.
- `tests/` pins the hooks' behaviour; change a hook and its test together.
