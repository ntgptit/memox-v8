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
not part of it: they are compared in the Linux container
(`.claude/skills/flutter-testing/scripts/golden.Dockerfile`).

A guard rule whose layer does not exist yet is listed with
`targets_pending: <layer>` in
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.
Once the rule has a target file, the guard reports
`guard.config.stale_targets_pending` and the gate fails: delete the rule's
entry in the commit that added the file. The list is empty today.
