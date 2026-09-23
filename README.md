# MemoX V8

Flutter flashcard / spaced-repetition app. Rules: see `CLAUDE.md`. Layering
and tooling: `docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md`.
Design: `docs/superpowers/specs/`. Plans: `docs/superpowers/plans/`. Data
model: `docs/shared/data/schema.md`.

## Toolchain

Flutter version is pinned in `.fvmrc`. Check with:

```bash
.claude/skills/flutter-workflow/scripts/check_flutter_version.sh
```

## Commands

Generated code is not committed. A fresh clone does not analyze or test
until:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Verification gate:

```bash
flutter analyze
flutter test
```
