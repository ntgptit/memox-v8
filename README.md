# MemoX V8

Flutter flashcard / spaced-repetition app. Rules: see `CLAUDE.md`. Layering
and tooling: `docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md`.
Folder structure and the verification gate:
`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`. Design:
`docs/superpowers/specs/`. Plans: `docs/superpowers/plans/`. Data model:
`docs/shared/data/schema.md`.

## Toolchain

Flutter version is pinned in `.fvmrc`. Check with:

```bash
.claude/skills/flutter-workflow/scripts/check_flutter_version.sh
```

The vendored guard (`code-verification-guard-v2/`) needs Python 3.12 or newer
with `code-verification-guard-v2/requirements-dev.txt` installed. In Claude
Code on the web, `.claude/hooks/install-guard-deps.sh` installs it when a
session starts. The commands below call it as `python3.13`; use `python3.12`
if that is the newest you have.

## Commands

Generated code is not committed. A fresh clone does not analyze or test
until:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Verification gate (ADR-011):

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

It runs format, analyze, generated-code freshness, the architecture and docs
checks, the guard and its self-tests, and the host test suite. Goldens are
not part of it: CI compares them, and they are regenerated only in the Linux
container (`.claude/skills/flutter-testing/scripts/golden.Dockerfile`).

A guard rule whose layer does not exist yet is listed with
`targets_pending: <layer>` in
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.
Once the rule has a target file, the guard reports
`guard.config.stale_targets_pending` and the gate fails: delete the rule's
entry in the commit that added the file. The list is empty today.

CI (`.github/workflows/ci.yml`) runs on Linux. It is paused during active
development (2026-09-26): it runs only by hand (Actions → CI → Run workflow),
and pull requests are merged on the local gate. The workflow's `on:` block
says how to resume it on every pull request.

- `gate` rebuilds the generated code from scratch (`check_generated.py`),
  then runs the same gate, `dod_check.sh`, in full;
- `goldens` runs `TZ=UTC flutter test --tags golden` against the committed
  pictures and fails if fewer than 60 ran (`count_golden_tests.py`);
- `CI gate` is green only when every other job succeeded. Once CI runs on
  pull requests again, it is the one check to require: a pull request is
  merged only once it is green.

To make that a rule on GitHub after resuming (a required check on a paused
workflow never reports, and blocks every merge), in the repository settings: Settings → Rules →
Rulesets → New ruleset → New branch ruleset. Target the default branch
(`master`) with enforcement Active; under "Require status checks to pass", add
`CI gate` and turn on "Require branches to be up to date before merging".
