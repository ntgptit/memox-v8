# MemoX V8 Settings and Reset Learning Progress Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build package 1 of [`docs/wbs_BE.md`](../../wbs_BE.md) — BE-A1 Settings
(UC-SETTINGS-001) and BE-A2 Reset learning progress (UC-SRS-001) — as domain,
data and di code with one use case per interaction, so the UI session can wire
the Settings tab, the study options of a root deck and the reset confirmation.
No UI.

**Architecture:** A new `settings` feature in the ADR-011 layout, with the import
map entry `settings → ∅`, owns the study options (card limit 1–200, new-card
order), the theme and language choices, the one `app_settings` row and the
override a root deck keeps in `deck.study_config`. `AppDatabase.beforeOpen`
inserts the settings row when it is missing. Each interaction is one
`<Name>UseCase` (AD-12) over `SettingsRepository`, whose implementation runs
every write in one Drift transaction and reads through `watch()` streams; the
options in force for a deck are one joined statement. The `srs` feature gains
the scheduler choice in `resetLearning`, a one-statement `resetSummary` and its
first two use cases.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35. No dependency is added.

**Spec:** [`docs/superpowers/specs/2026-09-24-settings-reset-backend-design.md`](../specs/2026-09-24-settings-reset-backend-design.md),
approved 2026-09-24. Business rules: `docs/features/{settings,srs,study}/rules/`;
data model: [`docs/shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `master` at `532c2cf` (the deck and card backend of #26 and the
WBS ledgers of #27). This plan runs on `claude/be-settings-reset`, from the
commit that adds it; the spec is `2d774f3` on that branch.

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed, and after every task the gate
passed. The code steps were then replayed from this document onto a clean
checkout of `2d774f3`, and each task's result matched the scratch commit file
for file. The "Expected" counts are the ones those runs produced.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme (spec §11). A parallel session builds the
  screens (FE-A3, FE-A4); the shared files this plan touches are
  `test/architecture/boundary_rules.dart` (one line) and
  `lib/core/database/app_database.dart` (`beforeOpen`), both additive (spec §10).
- Import map: `'settings': {}` (spec D3); `srs` stays `∅`. A feature never
  imports another feature's `data/` or `di/`, so the settings tests write the
  decks they need as SQL.
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing
  `call` (AD-12). A write returns `Future<Outcome<void, R>>`, `R` being the
  feature's rejection enum (`SettingsRejection`, `SrsRejection`); a watch returns
  a `Stream` fed by Drift's `watch()`.
- Every write is one transaction through the repository's `_write`. A rule that
  needs the data as it is at write time is checked on rows read inside it, and a
  rejection writes nothing (BR-SETTINGS-007, BR-SRS-027). An unexpected database
  error leaves as a typed `Failure` (`mapDatabaseError`, `mapDatabaseErrors()`).
- Every read and every write of `deck` and `card` filters `delete_batch_id IS NULL`.
- `card_limit` is an integer from 1 to 200, default 20 (spec D1, BR-STUDY-003);
  `StudyOptions` is its one definition. The codes stored in `new_card_order`,
  `theme_mode` and `language` are the enum names.
- `deck.study_config` holds `{"card_limit": <int>, "new_card_order": "created" | "random"}`
  (spec D5). Reading it never writes it (IT-STUDY-013).
- Reset to defaults changes `card_limit`, `new_card_order`, `theme_mode` and
  `language`, and nothing else (spec D6).
- Tests never read the wall clock: repositories and `AppDatabase` take a `now`
  function.
- Drift writes that a watch must see go through the typed API or
  `customInsert` / `customUpdate` with `updates:`; `customStatement` does not
  notify watchers.
- Generated code (`*.g.dart`) is not committed. After adding a `@riverpod`
  provider (Task 2), run `dart run build_runner build --delete-conflicting-outputs`.
- After every task the phased gate of the root `README.md` passes, plus
  `tools/docs/check.py`. On Linux, `flutter test` runs with
  `--exclude-tags golden`: the goldens were made on Windows and fail the same way
  on `master` (FE-D1 in [`docs/wbs_FE.md`](../../wbs_FE.md)).
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- The one business-rule file this plan changes is BR-STUDY-003, which the owner
  allowed (spec D1). Use case files change in their `code:` field only.
- Code, identifiers, test names and commit messages are in English; `docs/` keeps
  its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

The spec left these open, or the code showed a better reading. Each is decided
here and implemented as described; say so if one is wrong.

1. **`AppSettingsEntity`, not `AppSettings`** (Task 1). Drift already generates a
   table class `AppSettings` (row class `AppSetting`) from `app_settings`, so the
   domain type takes the `_entity` name and lives in `domain/entities/`. Spec
   §4's `app_settings_model.dart` becomes one file per type:
   `app_settings_entity.dart`, `theme_choice_model.dart`,
   `language_choice_model.dart`.
2. **Enum names are the stored codes** (Task 1). The codes of `new_card_order`,
   `theme_mode` and `language` are valid Dart names, so the mappers use
   `values.byName`, as `DeckContentType` and `ReviewKind` do, instead of the
   `code` field and `fromCode` of spec §5.1; `SchedulerType` needs those because
   `eight_box` is not a Dart name.
3. **`AppDatabase` takes a `now` function** (Task 2) for the `updated_at` of the
   row `beforeOpen` inserts, so no test reads the wall clock.
   `test/database/invariants_test.dart` stops inserting the row it now finds and
   updates it instead.
4. **`WatchStudyOptionsUseCase` streams `Outcome<EffectiveStudyOptions, SettingsRejection>`**
   (Task 3): `deckNotFound` when the deck is missing, as `WatchDeckUseCase` does.
   The repository stream keeps the spec's `EffectiveStudyOptions?`.
5. **The options in force are one Drift join** (Task 3): the deck, its root
   through `root_id` and the settings row, both deck rows filtered on the Trash;
   no `.drift` query file (spec §7). A test counts one SELECT per emission.
6. **An override with a key the app does not know stays readable** (Task 3). D5
   lists what makes an override unreadable, and an extra key is not among them;
   `schema.md` says so.
7. **A reset that keeps the scheduler keeps the root's `scheduler_version`**
   (Task 4), as today; another scheduler starts at the version this app runs, as
   `changeScheduler` does (D7).
8. **`resetSummary` is one statement** (Task 5): the root row and three counts —
   the cards and the learned cards outside the Trash, as the deck list counts
   them (UC-DECK-003), and the `in_progress` sessions.
9. **The srs tree helpers move to `test/support/srs_fixtures.dart`** (Task 4). The
   reset tests need them in a second file, because one file would pass the
   guard's 500-line limit; `_writes` gives way to the existing `totalChanges`.
10. **Thin use cases are tested through scenarios over the real repositories**
    (Tasks 2, 3 and 5), as in the deck and card backend.
11. **BE-A1 and BE-A2 become `xong` in the commit of the last task** (Task 5),
    with the spec and this plan as evidence. `wbs_BE.md` changes in the commit it
    describes, and the PR merges right after the final review (spec D8).

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **A database file from an earlier build, which has no settings row**: the next
   open inserts it at the defaults — Task 2, "a database file written before the
   row existed".
2. **Resetting one deck while another deck has progress and an open session**:
   the other tree keeps its scheduler, generation, schedule rows and session —
   Task 4, "a reset leaves every other tree as it was".
3. **A sub-deck moved to another tree**: it studies with the new root's options
   at once — Task 3, "a sub-deck moved to another tree".
4. **The deck deleted while its study options are open**: the stream turns into
   `deckNotFound`, never stale options — Task 3, "deleting the deck while its
   options are open".
5. **A tree with no cards**: its summary has nothing to lose, and the reset still
   works — Task 5, "a tree with no cards".

## File Structure

```
lib/features/settings/                                  new feature (Tasks 1–3)
├── domain/
│   ├── entities/app_settings_entity.dart               AppSettingsEntity (1)
│   ├── failures/settings_failure.dart                  SettingsRejection (1)
│   ├── models/study_options_model.dart                 StudyOptions, NewCardOrder (1)
│   ├── models/theme_choice_model.dart                  ThemeChoice (1)
│   ├── models/language_choice_model.dart               LanguageChoice (1)
│   ├── models/effective_study_options_model.dart       EffectiveStudyOptions, StudyOptionsSource (1)
│   ├── repositories/settings_repository.dart           contract (2, 3)
│   └── usecases/                                       five use cases (2), three (3)
├── data/
│   ├── datasources/settings_dao.dart                   (2, 3)
│   ├── mappers/app_settings_mapper.dart                (2)
│   ├── mappers/study_config_mapper.dart                D5 codec and resolution (3)
│   └── repositories/settings_repository_impl.dart      (2, 3)
└── di/settings_repository_provider.dart                (2)
lib/features/srs/domain/models/reset_learning_summary_model.dart    (5)
lib/features/srs/domain/usecases/                       two use cases (5)
test/support/srs_fixtures.dart                          (4)
```

Changed existing files: `app_database.dart` (2); `schedule_repository.dart` and
`schedule_repository_impl.dart` (4, 5); `srs_dao.dart` (5); `boundary_rules.dart`
(1); `invariants_test.dart` (2); `schedule_repository_impl_test.dart` (4); the
docs BR-STUDY-003 (1), the settings README and UC-SETTINGS-001 (2, 3),
`schema.md` (3), the srs README, UC-SRS-001 and `wbs_BE.md` (5).

---


### Task 1: The settings vocabulary — study options, choices, rejections

**Files:**
- Create: `lib/features/settings/domain/failures/settings_failure.dart`, `lib/features/settings/domain/models/study_options_model.dart`, `lib/features/settings/domain/models/theme_choice_model.dart`, `lib/features/settings/domain/models/language_choice_model.dart`, `lib/features/settings/domain/models/effective_study_options_model.dart`, `lib/features/settings/domain/entities/app_settings_entity.dart`
- Modify: `test/architecture/boundary_rules.dart`, `docs/features/study/rules/BR-STUDY-003-gioi-han-the-rieng-biet-moi-phien.md`
- Test (create): `test/features/settings/domain/study_options_model_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `Outcome<T, R>` with `Ok(value)` and `Rejected(reason)`
  (`lib/core/error/outcome.dart`).
- Produces:
  - `enum SettingsRejection { cardLimitOutOfRange, deckNotFound, notARootDeck }`
    in `lib/features/settings/domain/failures/settings_failure.dart`.
  - `enum NewCardOrder { created, random }` and
    `final class StudyOptions({required int cardLimit, required NewCardOrder newCardOrder})`
    with `minCardLimit = 1`, `maxCardLimit = 200`, `defaultCardLimit = 20`,
    `static const defaults` (20, `created`) and
    `Outcome<void, SettingsRejection> check()`, in
    `domain/models/study_options_model.dart`.
  - `enum ThemeChoice { system, light, dark }` (`theme_choice_model.dart`) and
    `enum LanguageChoice { system, en, vi }` (`language_choice_model.dart`).
  - `enum StudyOptionsSource { appDefaults, rootOverride, unreadableRootOverride }`
    and `final class EffectiveStudyOptions({required String rootDeckId, required StudyOptions options, required StudyOptionsSource source})`
    with `bool get hasRootOverride`, in `effective_study_options_model.dart`.
  - `final class AppSettingsEntity({required StudyOptions studyDefaults, required ThemeChoice theme, required LanguageChoice language})`
    with `static const defaults`, in `domain/entities/app_settings_entity.dart`.
  - Import map entry `'settings': {}`.

Spec §5.1 and D1. The bounds and the enum live here once; the study feature will
import them (D3). BR-STUDY-003 gains the bounds in this commit, with the code that
enforces them.


- [ ] **Step 1: Write the failing test**

Create `test/features/settings/domain/study_options_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

// The settings vocabulary: the bounds of BR-STUDY-003, the enums whose names
// are the codes `app_settings` stores, and the defaults of UC-SETTINGS-001.

StudyOptions _options(int cardLimit) =>
    StudyOptions(cardLimit: cardLimit, newCardOrder: NewCardOrder.created);

void main() {
  group('StudyOptions.check (BR-STUDY-003: 1 to 200)', () {
    test('accepts both bounds and the default', () {
      for (final limit in [1, 20, 200]) {
        expect(
          _options(limit).check(),
          isA<Ok<void, SettingsRejection>>(),
          reason: 'card limit $limit',
        );
      }
    });

    test('refuses a limit below 1 or above 200', () {
      for (final limit in [-1, 0, 201]) {
        expect(
          _options(limit).check(),
          isA<Rejected<void, SettingsRejection>>().having(
            (rejected) => rejected.reason,
            'reason',
            SettingsRejection.cardLimitOutOfRange,
          ),
          reason: 'card limit $limit',
        );
      }
    });
  });

  test('the study defaults are 20 cards in created order '
      '(BR-STUDY-003, BR-STUDY-057)', () {
    expect(StudyOptions.defaults.cardLimit, 20);
    expect(StudyOptions.defaults.newCardOrder, NewCardOrder.created);
  });

  test('the app defaults are the study defaults, the system theme and the '
      'system language (BR-SETTINGS-005, BR-SETTINGS-006)', () {
    const defaults = AppSettingsEntity.defaults;
    expect(defaults.studyDefaults.cardLimit, StudyOptions.defaults.cardLimit);
    expect(
      defaults.studyDefaults.newCardOrder,
      StudyOptions.defaults.newCardOrder,
    );
    expect(defaults.theme, ThemeChoice.system);
    expect(defaults.language, LanguageChoice.system);
  });

  test('the enum names are the codes app_settings stores', () {
    expect(
      [for (final order in NewCardOrder.values) order.name],
      ['created', 'random'],
    );
    expect(
      [for (final theme in ThemeChoice.values) theme.name],
      ['system', 'light', 'dark'],
    );
    expect(
      [for (final language in LanguageChoice.values) language.name],
      ['system', 'en', 'vi'],
    );
  });

  test('only a root override offers Use app defaults (UC-SETTINGS-001 A1)', () {
    EffectiveStudyOptions from(StudyOptionsSource source) =>
        EffectiveStudyOptions(
          rootDeckId: 'root',
          options: StudyOptions.defaults,
          source: source,
        );

    expect(from(StudyOptionsSource.appDefaults).hasRootOverride, isFalse);
    expect(from(StudyOptionsSource.rootOverride).hasRootOverride, isTrue);
    expect(
      from(StudyOptionsSource.unreadableRootOverride).hasRootOverride,
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run it to see it fail**

```bash
flutter test test/features/settings/domain/study_options_model_test.dart test/architecture
```

Expected: `+26 -1: Some tests failed.` The new test does not compile: `Error: Type 'StudyOptions' not found.`, `Error: 'SettingsRejection' isn't a type.` The architecture tests pass.

- [ ] **Step 3: Write the settings rejections, study options, choices and entity**

Create `lib/features/settings/domain/entities/app_settings_entity.dart`:

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The values of the one `app_settings` row a person can set in V8.0
/// (BR-SETTINGS-001): the study defaults, the theme and the language.
final class AppSettingsEntity {
  const AppSettingsEntity({
    required this.studyDefaults,
    required this.theme,
    required this.language,
  });

  /// What a fresh database holds and what `Reset to defaults` returns to
  /// (BR-SETTINGS-008).
  static const defaults = AppSettingsEntity(
    studyDefaults: StudyOptions.defaults,
    theme: ThemeChoice.system,
    language: LanguageChoice.system,
  );

  final StudyOptions studyDefaults;
  final ThemeChoice theme;
  final LanguageChoice language;
}
```

Create `lib/features/settings/domain/failures/settings_failure.dart`:

```dart
/// Why the settings feature refuses a write (ADR-011 D6).
enum SettingsRejection {
  /// BR-STUDY-003: the card limit is outside 1 to 200.
  cardLimitOutOfRange,

  /// The deck does not exist or is in the Trash.
  deckNotFound,

  /// The deck is a sub-deck: study options live on its root (BR-STUDY-056).
  notARootDeck,
}
```

Create `lib/features/settings/domain/models/effective_study_options_model.dart`:

```dart
import 'package:memox/features/settings/domain/models/study_options_model.dart';

/// Where the options in force for a deck come from (BR-STUDY-056).
enum StudyOptionsSource {
  /// The root has no override: the app-wide defaults apply.
  appDefaults,

  /// The root's override applies.
  rootOverride,

  /// The root holds an override that cannot be read: the app-wide defaults
  /// apply, and the stored override stays as it is (IT-STUDY-013).
  unreadableRootOverride,
}

/// The study options in force for a deck: its root's override, or the
/// app-wide defaults. A sub-deck has no options of its own (BR-STUDY-056).
final class EffectiveStudyOptions {
  const EffectiveStudyOptions({
    required this.rootDeckId,
    required this.options,
    required this.source,
  });

  final String rootDeckId;
  final StudyOptions options;
  final StudyOptionsSource source;

  /// Whether `Use app defaults` has an override to clear
  /// (UC-SETTINGS-001 A1).
  bool get hasRootOverride => source != StudyOptionsSource.appDefaults;
}
```

Create `lib/features/settings/domain/models/language_choice_model.dart`:

```dart
/// The language a person chose (BR-SETTINGS-006). `system` goes through the
/// platform's resolution and falls back to `en`. The names are the codes of
/// `app_settings.language`.
enum LanguageChoice { system, en, vi }
```

Create `lib/features/settings/domain/models/study_options_model.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';

/// The order in which a learning session takes new cards (BR-STUDY-057).
/// The names are the codes `app_settings` and `deck.study_config` store.
enum NewCardOrder { created, random }

/// The study options of BR-STUDY-056: the app-wide defaults, or the override
/// of a root deck. This is the one definition of their bounds and defaults
/// (BR-SETTINGS-002); the study feature reuses it.
final class StudyOptions {
  const StudyOptions({required this.cardLimit, required this.newCardOrder});

  /// BR-STUDY-003: the fewest and the most distinct cards a session takes.
  static const minCardLimit = 1;
  static const maxCardLimit = 200;

  static const defaultCardLimit = 20;

  /// The options a fresh install starts with (BR-STUDY-003, BR-STUDY-057).
  static const defaults = StudyOptions(
    cardLimit: defaultCardLimit,
    newCardOrder: NewCardOrder.created,
  );

  final int cardLimit;
  final NewCardOrder newCardOrder;

  Outcome<void, SettingsRejection> check() {
    if (cardLimit < minCardLimit || cardLimit > maxCardLimit) {
      return const Rejected(SettingsRejection.cardLimitOutOfRange);
    }
    return const Ok(null);
  }
}
```

Create `lib/features/settings/domain/models/theme_choice_model.dart`:

```dart
/// The theme a person chose (BR-SETTINGS-005). `system` is a choice of its
/// own that the platform resolves at every moment; it is never stored as the
/// brightness it resolved to. The names are the codes of
/// `app_settings.theme_mode`.
enum ThemeChoice { system, light, dark }
```

- [ ] **Step 4: Declare the settings feature in the import map**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'card': {'deck', 'srs', 'tags'},
};
```

with

```dart
  'card': {'deck', 'srs', 'tags'},
  'settings': {},
};
```

- [ ] **Step 5: Write the bounds into BR-STUDY-003**

In `docs/features/study/rules/BR-STUDY-003-gioi-han-the-rieng-biet-moi-phien.md`:

Replace

```markdown
status: active
summary: Mỗi phiên giới hạn số thẻ riêng biệt theo `card_limit`, mặc định 20, là trần mỗi lần lấy.
superseded_by:
```

with

```markdown
status: active
summary: Mỗi phiên giới hạn số thẻ riêng biệt theo `card_limit` (1–200, mặc định 20), là trần mỗi lần lấy.
superseded_by:
```

Replace

```markdown

**Enforced by:** store
**Liên quan:** BR-STUDY-024
```

with

```markdown

`card_limit` MUST là số nguyên từ **1** đến **200**, tính cả hai đầu. Giá trị ngoài khoảng đó MUST bị từ chối trước khi ghi, ở mặc định toàn app cũng như ở ghi đè của root deck (BR-STUDY-056).

**Enforced by:** domain + store
**Liên quan:** BR-STUDY-024
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/settings/domain/study_options_model_test.dart test/architecture
```

Expected: `+32: All tests passed!`

- [ ] **Step 7: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+707: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 17 | Errors: 0 | Warnings: 0 | Info: 17` (the 17 are the UI layers'
`targets_pending`); `PASS — 0 error(s)` (the warnings are older than this plan).

- [ ] **Step 8: Commit**

```bash
git add docs/_generated \
  docs/features/study/rules/BR-STUDY-003-gioi-han-the-rieng-biet-moi-phien.md \
  lib/features/settings/domain/entities/app_settings_entity.dart \
  lib/features/settings/domain/failures/settings_failure.dart \
  lib/features/settings/domain/models/effective_study_options_model.dart \
  lib/features/settings/domain/models/language_choice_model.dart \
  lib/features/settings/domain/models/study_options_model.dart \
  lib/features/settings/domain/models/theme_choice_model.dart \
  test/architecture/boundary_rules.dart \
  test/features/settings/domain/study_options_model_test.dart
git commit -F - <<'EOF'
feat(settings): add study options with their bounds, the theme and language choices and the settings rejections

StudyOptions is the one definition of the card limit bounds, 1 to 200
(BR-STUDY-003), and of the new-card order. The settings feature joins the
import map with no dependency on another feature.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The settings row, its repository and the five settings use cases

**Files:**
- Create: `lib/features/settings/domain/repositories/settings_repository.dart`, `lib/features/settings/data/datasources/settings_dao.dart`, `lib/features/settings/data/mappers/app_settings_mapper.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, `lib/features/settings/di/settings_repository_provider.dart`, `lib/features/settings/domain/usecases/watch_app_settings_use_case.dart`, `lib/features/settings/domain/usecases/save_study_defaults_use_case.dart`, `lib/features/settings/domain/usecases/set_theme_use_case.dart`, `lib/features/settings/domain/usecases/set_language_use_case.dart`, `lib/features/settings/domain/usecases/reset_app_settings_use_case.dart`
- Modify: `lib/core/database/app_database.dart`, `docs/features/settings/README.md`, `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`
- Test (create): `test/database/app_settings_row_test.dart`, `test/features/settings/data/app_settings_repository_test.dart`, `test/features/settings/domain/app_settings_use_cases_test.dart`
- Test (modify): `test/database/invariants_test.dart`, `test/support/test_database.dart`
- Regenerate: `lib/features/settings/di/settings_repository_provider.g.dart` (build_runner, not committed), `docs/_generated/`

**Interfaces:**
- Consumes: Task 1's types; `AppDatabase` and its `appSettings` table (row class
  `AppSetting`, `AppSettingsCompanion`); `mapDatabaseError` and the
  `mapDatabaseErrors()` stream extension (`lib/core/error/failure.dart`);
  `databaseProvider` (`lib/core/database/di/database_provider.dart`);
  `openTestDatabase`, `totalChanges` (`test/support/test_database.dart`).
- Produces:
  - `AppDatabase(QueryExecutor executor, {DateTime Function()? now})` and
    `const appSettingsRowId = 1`, in `app_database.dart`.
  - `abstract interface class SettingsRepository` with
    `Stream<AppSettingsEntity> watchAppSettings()`,
    `saveStudyDefaults({required StudyOptions options})`,
    `setTheme({required ThemeChoice theme})`,
    `setLanguage({required LanguageChoice language})` and `resetToDefaults()`,
    each write returning `Future<Outcome<void, SettingsRejection>>`.
  - `SettingsRepositoryImpl(AppDatabase db, {DateTime Function()? now})`;
    `SettingsDao(AppDatabase db)` with `watchRow()` and
    `updateRow(AppSettingsCompanion values)`;
    `AppSettingsEntity appSettingsOf(AppSetting row)`.
  - `settingsRepositoryProvider` (`@riverpod SettingsRepository settingsRepository(Ref ref)`).
  - Use cases, each `const <Name>UseCase(SettingsRepository settings)`:
    `WatchAppSettingsUseCase` — `Stream<AppSettingsEntity> call()`;
    `SaveStudyDefaultsUseCase` — `call({required StudyOptions options})`;
    `SetThemeUseCase` — `call({required ThemeChoice theme})`;
    `SetLanguageUseCase` — `call({required LanguageChoice language})`;
    `ResetAppSettingsUseCase` — `call()`.
  - For tests, `final class FailingUpdates extends QueryInterceptor` in
    `test/support/test_database.dart`: every UPDATE fails with a constraint
    error.

Spec §5.2 (the first five rows), §5.3 `watchAppSettings`, §5.4 and §5.5. The
row exists from the first open, so a missing row is a corrupt database and
surfaces as an error (UC-SETTINGS-001 E3).


- [ ] **Step 1: Write the failing tests**

In `test/support/test_database.dart`:

Replace

```dart
    return super.runSelect(executor, statement, args);
  }
}
```

with

```dart
    return super.runSelect(executor, statement, args);
  }
}

/// Fails every UPDATE the way a full disk or a broken constraint does, for
/// the error flows of a write.
final class FailingUpdates extends QueryInterceptor {
  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => throw SqliteException(
    extendedResultCode: 19,
    message: 'constraint failed',
  );
}
```

Create `test/database/app_settings_row_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

// BR-SETTINGS-001: the one `app_settings` row exists from the first open, so
// every surface reads real values, never a missing row.

void main() {
  test('a fresh database holds exactly one app_settings row, at the column '
      'defaults', () async {
    final opened = DateTime(2026, 9, 24, 8);
    final db = AppDatabase(NativeDatabase.memory(), now: () => opened);
    addTearDown(db.close);

    final rows = await db.select(db.appSettings).get();

    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.id, 1);
    expect(row.cardLimit, 20);
    expect(row.newCardOrder, 'created');
    expect(row.themeMode, 'system');
    expect(row.language, 'system');
    expect(row.reminderEnabled, 0);
    expect(row.updatedAt, opened);
  });

  test('opening a database again keeps the row it already holds', () async {
    final folder = await Directory.systemTemp.createTemp('memox_settings');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/memox.sqlite');

    final first = AppDatabase(
      NativeDatabase(file),
      now: () => DateTime(2026, 9, 24),
    );
    await first.customStatement(
      "UPDATE app_settings SET theme_mode = 'dark' WHERE id = 1",
    );
    await first.close();
    final second = AppDatabase(
      NativeDatabase(file),
      now: () => DateTime(2026, 9, 25),
    );
    addTearDown(second.close);

    final row = await second.select(second.appSettings).getSingle();
    expect(row.themeMode, 'dark');
    expect(row.updatedAt, DateTime(2026, 9, 24));
  });

  test('a database file written before the row existed gets it on the next '
      'open, at the defaults', () async {
    final folder = await Directory.systemTemp.createTemp('memox_settings');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/memox.sqlite');
    final earlier = AppDatabase(NativeDatabase(file));
    await earlier.customStatement('DELETE FROM app_settings');
    await earlier.close();

    final reopened = AppDatabase(
      NativeDatabase(file),
      now: () => DateTime(2026, 9, 25),
    );
    addTearDown(reopened.close);

    final rows = await reopened.select(reopened.appSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.cardLimit, 20);
    expect(rows.single.themeMode, 'system');
    expect(rows.single.updatedAt, DateTime(2026, 9, 25));
  });
}
```

In `test/database/invariants_test.dart`:

Replace

```dart
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
  "INSERT INTO app_settings (id, updated_at) VALUES (1, 0)",
];
```

with

```dart
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
  // The settings row exists from the first open (BR-SETTINGS-001).
  "UPDATE app_settings SET updated_at = 0 WHERE id = 1",
];
```

Create `test/features/settings/data/app_settings_repository_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

import '../../../support/test_database.dart';

// UC-SETTINGS-001 over the one `app_settings` row: every save is its own
// transaction and every watcher sees it (BR-SETTINGS-001, BR-SETTINGS-007).

DateTime _t0() => DateTime(2026, 9, 24, 9);

const _sevenRandom = StudyOptions(
  cardLimit: 7,
  newCardOrder: NewCardOrder.random,
);

const _rootOverride = '{"card_limit":30,"new_card_order":"created"}';

/// A root deck `r` holding [_rootOverride], written as SQL: the import map
/// keeps settings away from the deck feature.
Future<void> _insertRootWithOverride(AppDatabase db) => db.customStatement(
  'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
  'scheduler_type, scheduler_version, generation, sibling_position, '
  'study_config, created_at, updated_at) '
  "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, ?, 0, 0)",
  [_rootOverride],
);

Future<String?> _rootStudyConfig(AppDatabase db) async =>
    (await db
            .customSelect("SELECT study_config FROM deck WHERE id = 'r'")
            .getSingle())
        .read<String?>('study_config');

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> settingsRow(AppDatabase db) async =>
      (await db
              .customSelect('SELECT * FROM app_settings WHERE id = 1')
              .getSingle())
          .data;

  test('a fresh install reads the defaults (UC-SETTINGS-001 step 1)', () async {
    final current = await settings.watchAppSettings().first;

    expect(current.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
    expect(current.studyDefaults.newCardOrder, NewCardOrder.created);
    expect(current.theme, ThemeChoice.system);
    expect(current.language, LanguageChoice.system);
  });

  test('saving the study defaults writes both values and every watcher sees '
      'them (UC-SETTINGS-001 step 2, BR-SETTINGS-001)', () async {
    final seen = <(int, NewCardOrder)>[];
    final subscription = settings.watchAppSettings().listen(
      (current) => seen.add((
        current.studyDefaults.cardLimit,
        current.studyDefaults.newCardOrder,
      )),
    );
    await pumpEventQueue();

    final result = await settings.saveStudyDefaults(options: _sevenRandom);
    await pumpEventQueue();
    await subscription.cancel();

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect(seen, [(20, NewCardOrder.created), (7, NewCardOrder.random)]);
    expect((await settingsRow(db))['updated_at'], isNotNull);
  });

  test('a card limit out of bounds is refused and writes nothing '
      '(UC-SETTINGS-001 E1, BR-SETTINGS-002)', () async {
    await settings.watchAppSettings().first;
    final before = await totalChanges(db);

    final result = await settings.saveStudyDefaults(
      options: const StudyOptions(
        cardLimit: 201,
        newCardOrder: NewCardOrder.random,
      ),
    );

    expect(
      result,
      isA<Rejected<void, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.cardLimitOutOfRange,
      ),
    );
    expect(await totalChanges(db), before);
  });

  test('each save changes only its own value (BR-SETTINGS-007)', () async {
    await settings.setTheme(theme: ThemeChoice.dark);
    await settings.setLanguage(language: LanguageChoice.vi);

    final current = await settings.watchAppSettings().first;
    expect(current.theme, ThemeChoice.dark);
    expect(current.language, LanguageChoice.vi);
    expect(current.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
    expect(current.studyDefaults.newCardOrder, NewCardOrder.created);
  });

  test('saving the study defaults leaves open sessions and root overrides '
      'alone (BR-SETTINGS-002, BR-SETTINGS-004)', () async {
    await _insertRootWithOverride(db);
    await db.customStatement(
      'INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, '
      "status, cursor, card_limit, started_at) VALUES ('s', 'r', 'r', 1, 'learning', 'browse', "
      "'in_progress', 0, 20, 0)",
    );

    await settings.saveStudyDefaults(options: _sevenRandom);

    final session = await db
        .customSelect("SELECT card_limit FROM study_session WHERE id = 's'")
        .getSingle();
    expect(session.read<int>('card_limit'), 20);
    expect(await _rootStudyConfig(db), _rootOverride);
  });

  test('reset to defaults returns the four values and writes nothing else: '
      'not the reminder columns, not a root override '
      '(UC-SETTINGS-001 A3, BR-SETTINGS-008)', () async {
    await _insertRootWithOverride(db);
    await settings.saveStudyDefaults(options: _sevenRandom);
    await settings.setTheme(theme: ThemeChoice.light);
    await settings.setLanguage(language: LanguageChoice.en);
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 480 '
      'WHERE id = 1',
    );

    final before = await totalChanges(db);

    final result = await settings.resetToDefaults();

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect(await totalChanges(db), before + 1);
    expect(await _rootStudyConfig(db), _rootOverride);
    final current = await settings.watchAppSettings().first;
    expect(
      current.studyDefaults.cardLimit,
      AppSettingsEntity.defaults.studyDefaults.cardLimit,
    );
    expect(current.studyDefaults.newCardOrder, NewCardOrder.created);
    expect(current.theme, ThemeChoice.system);
    expect(current.language, LanguageChoice.system);
    final row = await settingsRow(db);
    expect(row['reminder_enabled'], 1);
    expect(row['reminder_minute_of_day'], 480);
  });

  test('a settings row that is gone is a read failure, never made-up values '
      '(UC-SETTINGS-001 E3)', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(
      settings.watchAppSettings().first,
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('a failed save leaves as a typed Failure and the persisted values stay '
      '(UC-SETTINGS-001 E2, BR-SETTINGS-007)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      broken.setTheme(theme: ThemeChoice.dark),
      throwsA(isA<ConstraintFailure>()),
    );
    expect((await broken.watchAppSettings().first).theme, ThemeChoice.system);
  });

  test('saved values survive closing and reopening the database '
      '(IT-STUDY-008, host half)', () async {
    final folder = await Directory.systemTemp.createTemp('memox_settings');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/memox.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    await SettingsRepositoryImpl(
      first,
      now: _t0,
    ).saveStudyDefaults(options: _sevenRandom);
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    final current = await SettingsRepositoryImpl(
      second,
      now: _t0,
    ).watchAppSettings().first;

    expect(current.studyDefaults.cardLimit, 7);
    expect(current.studyDefaults.newCardOrder, NewCardOrder.random);
  });
}
```

Create `test/features/settings/domain/app_settings_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:memox/features/settings/domain/usecases/save_study_defaults_use_case.dart';
import 'package:memox/features/settings/domain/usecases/set_language_use_case.dart';
import 'package:memox/features/settings/domain/usecases/set_theme_use_case.dart';
import 'package:memox/features/settings/domain/usecases/watch_app_settings_use_case.dart';

import '../../../support/test_database.dart';

// The five use cases of the settings row, through the real repository: what
// a person sees on the Settings tab after each action (UC-SETTINGS-001).

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 24));
  });
  tearDown(() => db.close());

  test('the Settings tab shows every save, then the defaults again after '
      'Reset to defaults (UC-SETTINGS-001 steps 1-5, A3)', () async {
    final seen = <AppSettingsEntity>[];
    final subscription = WatchAppSettingsUseCase(settings)().listen(seen.add);
    await pumpEventQueue();

    final saved = await SaveStudyDefaultsUseCase(settings)(
      options: const StudyOptions(
        cardLimit: 5,
        newCardOrder: NewCardOrder.random,
      ),
    );
    await pumpEventQueue();
    await SetThemeUseCase(settings)(theme: ThemeChoice.dark);
    await pumpEventQueue();
    await SetLanguageUseCase(settings)(language: LanguageChoice.vi);
    await pumpEventQueue();
    await ResetAppSettingsUseCase(settings)();
    await pumpEventQueue();
    await subscription.cancel();

    expect(saved, isA<Ok<void, SettingsRejection>>());
    expect(
      [
        for (final current in seen)
          (current.studyDefaults.cardLimit, current.theme, current.language),
      ],
      [
        (20, ThemeChoice.system, LanguageChoice.system),
        (5, ThemeChoice.system, LanguageChoice.system),
        (5, ThemeChoice.dark, LanguageChoice.system),
        (5, ThemeChoice.dark, LanguageChoice.vi),
        (20, ThemeChoice.system, LanguageChoice.system),
      ],
    );
  });

  test('SaveStudyDefaultsUseCase refuses a card limit of 0 '
      '(UC-SETTINGS-001 E1)', () async {
    final result = await SaveStudyDefaultsUseCase(settings)(
      options: const StudyOptions(
        cardLimit: 0,
        newCardOrder: NewCardOrder.created,
      ),
    );

    expect(
      result,
      isA<Rejected<void, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.cardLimitOutOfRange,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/database/app_settings_row_test.dart test/database/invariants_test.dart \
  test/features/settings/data/app_settings_repository_test.dart \
  test/features/settings/domain/app_settings_use_cases_test.dart
```

Expected: `+66 -3: Some tests failed.` The three new files do not compile: `Error: No named parameter with the name 'now'.`, `Error: Method not found: 'SettingsRepositoryImpl'.`, `Error: Error when reading 'lib/features/settings/domain/usecases/watch_app_settings_use_case.dart': No such file or directory`. `invariants_test.dart` passes.

- [ ] **Step 3: Insert the settings row when the database opens**

In `lib/core/database/app_database.dart`:

Replace

```dart
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

```

with

```dart
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

```

Replace

```dart
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

with

```dart
      await customStatement('PRAGMA foreign_keys = ON');
      // BR-SETTINGS-001: the one settings row exists from the first open, so
      // every surface reads real values. It changes nothing once it exists.
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          id: const Value(appSettingsRowId),
          updatedAt: _now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    },
  );
}

/// The id of the one `app_settings` row: `CHECK (id = 1)` keeps the table at
/// this row (BR-SETTINGS-001).
const appSettingsRowId = 1;
```

- [ ] **Step 4: Write the repository, its DAO, mapper and provider**

Create `lib/features/settings/data/datasources/settings_dao.dart`:

```dart
import 'package:memox/core/database/app_database.dart';

/// Row access for the one `app_settings` row. It returns Drift rows, never
/// domain values, and runs inside the caller's transaction.
final class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Stream<AppSetting> watchRow() => (_db.select(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).watchSingle();

  Future<void> updateRow(AppSettingsCompanion values) => (_db.update(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).write(values);
}
```

Create `lib/features/settings/data/mappers/app_settings_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The stored codes are the enum names, and the table's `CHECK` constraints
/// keep them valid: an unknown code is corrupt data and throws.
AppSettingsEntity appSettingsOf(AppSetting row) => AppSettingsEntity(
  studyDefaults: StudyOptions(
    cardLimit: row.cardLimit,
    newCardOrder: NewCardOrder.values.byName(row.newCardOrder),
  ),
  theme: ThemeChoice.values.byName(row.themeMode),
  language: LanguageChoice.values.byName(row.language),
);
```

Create `lib/features/settings/data/repositories/settings_repository_impl.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';
import 'package:memox/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// Every save is one transaction of its own (BR-SETTINGS-007): its rule is
/// checked inside it, and a refusal writes nothing.
final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = SettingsDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SettingsDao _dao;
  final DateTime Function() _now;

  @override
  Stream<AppSettingsEntity> watchAppSettings() =>
      _dao.watchRow().map(appSettingsOf).mapDatabaseErrors();

  @override
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  }) {
    final at = _now();
    return _write(() async {
      if (options.check() case Rejected(:final reason)) return Rejected(reason);
      await _dao.updateRow(
        AppSettingsCompanion(
          cardLimit: Value(options.cardLimit),
          newCardOrder: Value(options.newCardOrder.name),
          updatedAt: Value(at),
        ),
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  }) => _save(AppSettingsCompanion(themeMode: Value(theme.name)));

  @override
  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  }) => _save(AppSettingsCompanion(language: Value(language.name)));

  @override
  Future<Outcome<void, SettingsRejection>> resetToDefaults() {
    const defaults = AppSettingsEntity.defaults;
    return _save(
      AppSettingsCompanion(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
        newCardOrder: Value(defaults.studyDefaults.newCardOrder.name),
        themeMode: Value(defaults.theme.name),
        language: Value(defaults.language.name),
      ),
    );
  }

  /// [values] and `updated_at`, in one transaction of their own.
  Future<Outcome<void, SettingsRejection>> _save(AppSettingsCompanion values) {
    final at = _now();
    return _write(() async {
      await _dao.updateRow(values.copyWith(updatedAt: Value(at)));
      return const Ok(null);
    });
  }

  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

Create `lib/features/settings/di/settings_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository_provider.g.dart';

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepositoryImpl(ref.watch(databaseProvider));
```

Create `lib/features/settings/domain/repositories/settings_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The one implementation is `SettingsRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class SettingsRepository {
  /// The one `app_settings` row, again after every save (BR-SETTINGS-001).
  Stream<AppSettingsEntity> watchAppSettings();

  /// The app-wide study defaults. It never writes a root's override
  /// (BR-SETTINGS-002), and a session already open keeps its limit
  /// (BR-SETTINGS-004).
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  });

  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  });

  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  });

  /// The four values a person can set back to their defaults, and nothing
  /// else (BR-SETTINGS-008).
  Future<Outcome<void, SettingsRejection>> resetToDefaults();
}
```

- [ ] **Step 5: Write the five use cases**

Create `lib/features/settings/domain/usecases/reset_app_settings_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 A3: every value back to its default after the person
/// confirms. Learning progress is not touched (BR-SETTINGS-008).
final class ResetAppSettingsUseCase {
  const ResetAppSettingsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call() =>
      _settings.resetToDefaults();
}
```

Create `lib/features/settings/domain/usecases/save_study_defaults_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 2: the app-wide card limit and new-card order, for
/// the sessions opened after it (BR-SETTINGS-002, BR-SETTINGS-004).
final class SaveStudyDefaultsUseCase {
  const SaveStudyDefaultsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    required StudyOptions options,
  }) => _settings.saveStudyDefaults(options: options);
}
```

Create `lib/features/settings/domain/usecases/set_language_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 5: the language, saved on the tap (BR-SETTINGS-006).
final class SetLanguageUseCase {
  const SetLanguageUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    required LanguageChoice language,
  }) => _settings.setLanguage(language: language);
}
```

Create `lib/features/settings/domain/usecases/set_theme_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 4: the theme, saved on the tap (BR-SETTINGS-005).
final class SetThemeUseCase {
  const SetThemeUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required ThemeChoice theme}) =>
      _settings.setTheme(theme: theme);
}
```

Create `lib/features/settings/domain/usecases/watch_app_settings_use_case.dart`:

```dart
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 1: the values in force, again after every save
/// (BR-SETTINGS-001).
final class WatchAppSettingsUseCase {
  const WatchAppSettingsUseCase(this._settings);

  final SettingsRepository _settings;

  Stream<AppSettingsEntity> call() => _settings.watchAppSettings();
}
```

- [ ] **Step 6: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner`, and `lib/features/settings/di/settings_repository_provider.g.dart` exists.

- [ ] **Step 7: Point the settings docs at the code**

In `docs/features/settings/README.md`:

Replace

```markdown
feature: settings
code: []
depends_on: [deck, srs, study]
```

with

```markdown
feature: settings
code: [lib/features/settings/domain, lib/features/settings/data, lib/features/settings/di]
depends_on: [deck, srs, study]
```

Replace

```markdown
Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn ngữ trong một dòng `app_settings`.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

```

with

```markdown
Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn ngữ trong một dòng `app_settings`.

```

In `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`:

Replace

```markdown
rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008, BR-SRS-022, BR-STUDY-003, BR-STUDY-024, BR-STUDY-035, BR-STUDY-056, BR-STUDY-057]
code: []
---
```

with

```markdown
rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008, BR-SRS-022, BR-STUDY-003, BR-STUDY-024, BR-STUDY-035, BR-STUDY-056, BR-STUDY-057]
code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart]
---
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/database/app_settings_row_test.dart test/database/invariants_test.dart \
  test/features/settings/data/app_settings_repository_test.dart \
  test/features/settings/domain/app_settings_use_cases_test.dart
```

Expected: `+80: All tests passed!`

- [ ] **Step 9: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+721: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 17 | Errors: 0 | Warnings: 0 | Info: 17` (the 17 are the UI layers'
`targets_pending`); `PASS — 0 error(s)` (the warnings are older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  docs/features/settings/README.md \
  docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md \
  lib/core/database/app_database.dart \
  lib/features/settings/data/datasources/settings_dao.dart \
  lib/features/settings/data/mappers/app_settings_mapper.dart \
  lib/features/settings/data/repositories/settings_repository_impl.dart \
  lib/features/settings/di/settings_repository_provider.dart \
  lib/features/settings/domain/repositories/settings_repository.dart \
  lib/features/settings/domain/usecases/reset_app_settings_use_case.dart \
  lib/features/settings/domain/usecases/save_study_defaults_use_case.dart \
  lib/features/settings/domain/usecases/set_language_use_case.dart \
  lib/features/settings/domain/usecases/set_theme_use_case.dart \
  lib/features/settings/domain/usecases/watch_app_settings_use_case.dart \
  test/database/app_settings_row_test.dart \
  test/database/invariants_test.dart \
  test/features/settings/data/app_settings_repository_test.dart \
  test/features/settings/domain/app_settings_use_cases_test.dart \
  test/support/test_database.dart
git commit -F - <<'EOF'
feat(settings): add the settings row, its repository and the five settings use cases

The database now inserts the one app_settings row when it opens
(BR-SETTINGS-001), so every surface reads real values. SettingsRepository
watches the row and saves the study defaults, the theme, the language and
the reset to defaults, each in one transaction that a rejection leaves
untouched (BR-SETTINGS-007).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: The study options of a root deck

**Files:**
- Create: `lib/features/settings/data/mappers/study_config_mapper.dart`, `lib/features/settings/domain/usecases/watch_study_options_use_case.dart`, `lib/features/settings/domain/usecases/save_root_study_options_use_case.dart`, `lib/features/settings/domain/usecases/use_app_defaults_use_case.dart`
- Modify: `lib/features/settings/domain/repositories/settings_repository.dart`, `lib/features/settings/data/datasources/settings_dao.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, `docs/shared/data/schema.md`, `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`
- Test (create): `test/features/settings/data/study_config_mapper_test.dart`, `test/features/settings/data/root_study_options_repository_test.dart`, `test/features/settings/domain/root_study_options_use_cases_test.dart`
- Regenerate: `docs/_generated/`

**Interfaces:**
- Consumes: Tasks 1 and 2; the `deck` table (row class `Deck`,
  `DeckCompanion`); `SelectCounter` and `FailingUpdates`
  (`test/support/test_database.dart`).
- Produces:
  - On `SettingsRepository`:
    `Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId})`,
    `saveRootStudyOptions({required String rootDeckId, required StudyOptions options})`
    and `clearRootStudyOptions({required String rootDeckId})`, both writes
    `Future<Outcome<void, SettingsRejection>>`.
  - On `SettingsDao`: `Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId)`,
    `Future<Deck?> deckRow(String id)` and
    `setStudyConfig(String rootId, String? studyConfig, DateTime now)`.
  - In `data/mappers/study_config_mapper.dart`:
    `String studyConfigOf(StudyOptions options)`,
    `StudyOptions? studyOptionsOf(String studyConfig)` and
    `EffectiveStudyOptions effectiveStudyOptionsOf(Deck root, AppSetting settings)`.
  - Use cases: `WatchStudyOptionsUseCase` —
    `Stream<Outcome<EffectiveStudyOptions, SettingsRejection>> call({required String deckId})`;
    `SaveRootStudyOptionsUseCase` —
    `call({required String rootDeckId, required StudyOptions options})`;
    `UseAppDefaultsUseCase` — `call({required String rootDeckId})`.

Spec §5.2 (the last three rows), §5.3 and §5.4, decisions D2 and D5. A sub-deck
reads its root's options and cannot hold its own (BR-STUDY-056); an unreadable
override means the app defaults and is never rewritten on read (IT-STUDY-013); a
failed `Use app defaults` leaves the override as it was (UC-SETTINGS-001 E4).


- [ ] **Step 1: Write the failing tests**

Create `test/features/settings/data/root_study_options_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

import '../../../support/test_database.dart';

// The study options of a root deck (UC-SETTINGS-001 A1, BR-STUDY-056): its
// override, or the app-wide defaults when it has none or cannot be read.

DateTime _t0() => DateTime(2026, 9, 24, 9);

const _thirtyRandom = StudyOptions(
  cardLimit: 30,
  newCardOrder: NewCardOrder.random,
);

/// The root `r` and its sub-deck `s`, written as SQL: the import map keeps
/// settings away from the deck feature. [studyConfig] is the root's override.
Future<void> _insertTree(AppDatabase db, {String? studyConfig}) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'scheduler_type, scheduler_version, generation, sibling_position, '
    'study_config, created_at, updated_at) '
    "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, ?, 0, 0)",
    [studyConfig],
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES ('s', 's', 'r', 'r', 2, 'unset', 0, 0, 0)",
  );
}

Future<void> _moveTreeToTrash(AppDatabase db) => db.customStatement(
  "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
);

Future<({String? studyConfig, DateTime updatedAt})> _root(
  AppDatabase db,
) async {
  final row = await db
      .customSelect("SELECT study_config, updated_at FROM deck WHERE id = 'r'")
      .getSingle();
  return (
    studyConfig: row.read<String?>('study_config'),
    updatedAt: row.read<DateTime>('updated_at'),
  );
}

Matcher _rejectedWith(SettingsRejection reason) =>
    isA<Rejected<void, SettingsRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
  });
  tearDown(() => db.close());

  test('a root with no override studies with the app defaults '
      '(BR-STUDY-056)', () async {
    await _insertTree(db);
    await settings.saveStudyDefaults(
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.random,
      ),
    );

    final effective = await settings.watchStudyOptions(deckId: 'r').first;

    expect(effective?.rootDeckId, 'r');
    expect(effective?.options.cardLimit, 7);
    expect(effective?.options.newCardOrder, NewCardOrder.random);
    expect(effective?.source, StudyOptionsSource.appDefaults);
    expect(effective?.hasRootOverride, isFalse);
  });

  test("a sub-deck studies with its root's override (BR-STUDY-056)", () async {
    await _insertTree(
      db,
      studyConfig: '{"card_limit":30,"new_card_order":"random"}',
    );

    final effective = await settings.watchStudyOptions(deckId: 's').first;

    expect(effective?.rootDeckId, 'r');
    expect(effective?.options.cardLimit, 30);
    expect(effective?.options.newCardOrder, NewCardOrder.random);
    expect(effective?.source, StudyOptionsSource.rootOverride);
    expect(effective?.hasRootOverride, isTrue);
  });

  test('a missing deck and a deck in the Trash have no options', () async {
    await _insertTree(db);
    expect(await settings.watchStudyOptions(deckId: 'missing').first, isNull);

    await _moveTreeToTrash(db);

    expect(await settings.watchStudyOptions(deckId: 'r').first, isNull);
    expect(await settings.watchStudyOptions(deckId: 's').first, isNull);
  });

  test('an unreadable override studies with the app defaults and stays '
      'stored as it was (IT-STUDY-013)', () async {
    const unreadable = '{"card_limit":500,"new_card_order":"created"}';
    await _insertTree(db, studyConfig: unreadable);
    final before = await totalChanges(db);

    final effective = await settings.watchStudyOptions(deckId: 's').first;

    expect(effective?.options.cardLimit, StudyOptions.defaultCardLimit);
    expect(effective?.options.newCardOrder, NewCardOrder.created);
    expect(effective?.source, StudyOptionsSource.unreadableRootOverride);
    expect(effective?.hasRootOverride, isTrue);
    expect((await _root(db)).studyConfig, unreadable);
    expect(await totalChanges(db), before);
  });

  test('the options in force follow the override and the app defaults '
      '(UC-SETTINGS-001 A1)', () async {
    await _insertTree(db);
    final seen = <EffectiveStudyOptions?>[];
    final subscription = settings
        .watchStudyOptions(deckId: 's')
        .listen(seen.add);
    await pumpEventQueue();

    await settings.saveRootStudyOptions(
      rootDeckId: 'r',
      options: _thirtyRandom,
    );
    await pumpEventQueue();
    final overridden = seen.last;
    await settings.saveStudyDefaults(
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.created,
      ),
    );
    await pumpEventQueue();
    final overrideStillWins = seen.last;
    await settings.clearRootStudyOptions(rootDeckId: 'r');
    await pumpEventQueue();
    await subscription.cancel();

    expect(
      (overridden?.options.cardLimit, overridden?.source),
      (30, StudyOptionsSource.rootOverride),
    );
    expect(
      (overrideStillWins?.options.cardLimit, overrideStillWins?.source),
      (30, StudyOptionsSource.rootOverride),
    );
    expect(
      (seen.last?.options.cardLimit, seen.last?.source),
      (7, StudyOptionsSource.appDefaults),
    );
  });

  test("saving a root's options writes its override and nothing else "
      '(BR-SETTINGS-003)', () async {
    await _insertTree(db);
    final before = await totalChanges(db);

    final result = await settings.saveRootStudyOptions(
      rootDeckId: 'r',
      options: _thirtyRandom,
    );

    expect(result, isA<Ok<void, SettingsRejection>>());
    final root = await _root(db);
    expect(root.studyConfig, '{"card_limit":30,"new_card_order":"random"}');
    expect(root.updatedAt, _t0());
    expect(await totalChanges(db), before + 1);
  });

  test('a card limit out of bounds is refused for a root too '
      '(BR-STUDY-003)', () async {
    await _insertTree(db);
    final before = await totalChanges(db);

    final result = await settings.saveRootStudyOptions(
      rootDeckId: 'r',
      options: const StudyOptions(
        cardLimit: 0,
        newCardOrder: NewCardOrder.created,
      ),
    );

    expect(result, _rejectedWith(SettingsRejection.cardLimitOutOfRange));
    expect(await totalChanges(db), before);
  });

  test('a sub-deck, a missing deck and a deck in the Trash are refused and '
      'nothing is written (BR-STUDY-056)', () async {
    await _insertTree(db);
    final before = await totalChanges(db);

    expect(
      await settings.saveRootStudyOptions(
        rootDeckId: 's',
        options: _thirtyRandom,
      ),
      _rejectedWith(SettingsRejection.notARootDeck),
    );
    expect(
      await settings.clearRootStudyOptions(rootDeckId: 's'),
      _rejectedWith(SettingsRejection.notARootDeck),
    );
    expect(
      await settings.saveRootStudyOptions(
        rootDeckId: 'missing',
        options: _thirtyRandom,
      ),
      _rejectedWith(SettingsRejection.deckNotFound),
    );
    expect(await totalChanges(db), before);

    await _moveTreeToTrash(db);
    final trashed = await totalChanges(db);

    expect(
      await settings.saveRootStudyOptions(
        rootDeckId: 'r',
        options: _thirtyRandom,
      ),
      _rejectedWith(SettingsRejection.deckNotFound),
    );
    expect(
      await settings.clearRootStudyOptions(rootDeckId: 'r'),
      _rejectedWith(SettingsRejection.deckNotFound),
    );
    expect(await totalChanges(db), trashed);
  });

  test(
    'Use app defaults clears the override and writes only the root; '
    'again, it writes nothing (UC-SETTINGS-001 A1, E4, BR-SETTINGS-003)',
    () async {
      await _insertTree(
        db,
        studyConfig: '{"card_limit":30,"new_card_order":"random"}',
      );
      final before = await totalChanges(db);

      final cleared = await settings.clearRootStudyOptions(rootDeckId: 'r');
      final afterFirst = await totalChanges(db);
      final again = await settings.clearRootStudyOptions(rootDeckId: 'r');

      expect(cleared, isA<Ok<void, SettingsRejection>>());
      expect(afterFirst, before + 1);
      expect(again, isA<Ok<void, SettingsRejection>>());
      final root = await _root(db);
      expect(root.studyConfig, isNull);
      expect(root.updatedAt, _t0());
      expect(await totalChanges(db), afterFirst);
    },
  );

  test('a failed Use app defaults leaves the override as it was '
      '(UC-SETTINGS-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    const override = '{"card_limit":30,"new_card_order":"random"}';
    await _insertTree(failing, studyConfig: override);

    await expectLater(
      SettingsRepositoryImpl(
        failing,
        now: _t0,
      ).clearRootStudyOptions(rootDeckId: 'r'),
      throwsA(isA<ConstraintFailure>()),
    );
    expect((await _root(failing)).studyConfig, override);
  });

  test('Use app defaults clears an unreadable override too (D5)', () async {
    await _insertTree(db, studyConfig: '{"card_limit":"many"}');

    final result = await settings.clearRootStudyOptions(rootDeckId: 'r');

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect((await _root(db)).studyConfig, isNull);
  });

  test(
    'the options in force are one statement per emission (spec §5.3)',
    () async {
      final counter = SelectCounter();
      final counted = openTestDatabase(interceptor: counter);
      addTearDown(counted.close);
      await _insertTree(counted);
      counter.selects = 0;

      await SettingsRepositoryImpl(
        counted,
        now: _t0,
      ).watchStudyOptions(deckId: 's').first;

      expect(counter.selects, 1);
    },
  );

  test("a sub-deck moved to another tree studies with its new root's options "
      '(BR-STUDY-056)', () async {
    await _insertTree(
      db,
      studyConfig: '{"card_limit":30,"new_card_order":"random"}',
    );
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) '
      "VALUES ('other', 'other', NULL, 'other', 1, 'deck', 'eight_box', 1, 1, "
      '1, 0, 0)',
    );
    final seen = <EffectiveStudyOptions?>[];
    final subscription = settings
        .watchStudyOptions(deckId: 's')
        .listen(seen.add);
    await pumpEventQueue();

    await db.customUpdate(
      "UPDATE deck SET parent_id = 'other', root_id = 'other' WHERE id = 's'",
      updates: {db.deck},
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect((seen.first?.rootDeckId, seen.first?.options.cardLimit), ('r', 30));
    expect(
      (seen.last?.rootDeckId, seen.last?.source),
      ('other', StudyOptionsSource.appDefaults),
    );
  });
}
```

Create `test/features/settings/data/study_config_mapper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/mappers/study_config_mapper.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

// The JSON a root deck keeps its own study options in (spec D5).

void main() {
  test('the options a save writes read back the same', () {
    const options = StudyOptions(
      cardLimit: 35,
      newCardOrder: NewCardOrder.random,
    );

    final studyConfig = studyConfigOf(options);
    final read = studyOptionsOf(studyConfig);

    expect(studyConfig, '{"card_limit":35,"new_card_order":"random"}');
    expect(read?.cardLimit, 35);
    expect(read?.newCardOrder, NewCardOrder.random);
  });

  test('both bounds of the card limit read back (BR-STUDY-003)', () {
    expect(
      studyOptionsOf('{"card_limit":1,"new_card_order":"created"}')?.cardLimit,
      1,
    );
    expect(
      studyOptionsOf('{"card_limit":200,"new_card_order":"created"}')
          ?.cardLimit,
      200,
    );
  });

  test('a key the app does not know is ignored', () {
    final read = studyOptionsOf(
      '{"card_limit":20,"new_card_order":"created","review_order":"due"}',
    );

    expect(read?.cardLimit, 20);
    expect(read?.newCardOrder, NewCardOrder.created);
  });

  for (final (shape, studyConfig) in [
    ('not JSON', 'card_limit=20'),
    ('empty', ''),
    ('not an object', '[20, "created"]'),
    ('missing card_limit', '{"new_card_order":"created"}'),
    ('missing new_card_order', '{"card_limit":20}'),
    (
      'a card_limit that is text',
      '{"card_limit":"20","new_card_order":"created"}',
    ),
    (
      'a fractional card_limit',
      '{"card_limit":20.5,"new_card_order":"created"}',
    ),
    ('a null card_limit', '{"card_limit":null,"new_card_order":"created"}'),
    ('a card_limit of 0', '{"card_limit":0,"new_card_order":"created"}'),
    ('a card_limit of 201', '{"card_limit":201,"new_card_order":"created"}'),
    (
      'an unknown new_card_order',
      '{"card_limit":20,"new_card_order":"shuffled"}',
    ),
    (
      'a new_card_order that is a number',
      '{"card_limit":20,"new_card_order":1}',
    ),
  ]) {
    test('an override with $shape cannot be read (D5)', () {
      expect(studyOptionsOf(studyConfig), isNull);
    });
  }
}
```

Create `test/features/settings/domain/root_study_options_use_cases_test.dart`:

```dart
import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/usecases/save_root_study_options_use_case.dart';
import 'package:memox/features/settings/domain/usecases/use_app_defaults_use_case.dart';
import 'package:memox/features/settings/domain/usecases/watch_study_options_use_case.dart';

import '../../../support/test_database.dart';

// The study options screen of a root deck (UC-SETTINGS-001 A1) through its
// three use cases.

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() async {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 24));
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) '
      "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    );
  });
  tearDown(() => db.close());

  test('saving the options of a root, then Use app defaults, shows the '
      'override and then the app defaults (UC-SETTINGS-001 A1)', () async {
    final seen = <Outcome<EffectiveStudyOptions, SettingsRejection>>[];
    final subscription = WatchStudyOptionsUseCase(settings)(deckId: 'r')
        .listen(seen.add);
    await pumpEventQueue();

    final saved = await SaveRootStudyOptionsUseCase(settings)(
      rootDeckId: 'r',
      options: const StudyOptions(
        cardLimit: 50,
        newCardOrder: NewCardOrder.random,
      ),
    );
    await pumpEventQueue();
    final overridden = seen.last;
    final cleared = await UseAppDefaultsUseCase(settings)(rootDeckId: 'r');
    await pumpEventQueue();
    await subscription.cancel();

    expect(saved, isA<Ok<void, SettingsRejection>>());
    expect(cleared, isA<Ok<void, SettingsRejection>>());
    expect(
      overridden,
      isA<Ok<EffectiveStudyOptions, SettingsRejection>>().having(
        (ok) => (ok.value.options.cardLimit, ok.value.hasRootOverride),
        'options',
        (50, true),
      ),
    );
    expect(
      seen.last,
      isA<Ok<EffectiveStudyOptions, SettingsRejection>>().having(
        (ok) => (ok.value.options.cardLimit, ok.value.hasRootOverride),
        'options',
        (StudyOptions.defaultCardLimit, false),
      ),
    );
  });

  test('a deck that does not exist is deckNotFound', () async {
    final first = await WatchStudyOptionsUseCase(settings)(deckId: 'missing')
        .first;

    expect(
      first,
      isA<Rejected<EffectiveStudyOptions, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.deckNotFound,
      ),
    );
  });

  test('deleting the deck while its options are open turns them into '
      'deckNotFound', () async {
    final seen = <Outcome<EffectiveStudyOptions, SettingsRejection>>[];
    final subscription = WatchStudyOptionsUseCase(settings)(deckId: 'r')
        .listen(seen.add);
    await pumpEventQueue();

    await db.customUpdate(
      "DELETE FROM deck WHERE id = 'r'",
      updates: {db.deck},
      updateKind: UpdateKind.delete,
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen.first, isA<Ok<EffectiveStudyOptions, SettingsRejection>>());
    expect(
      seen.last,
      isA<Rejected<EffectiveStudyOptions, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.deckNotFound,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/data/study_config_mapper_test.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/settings/domain/root_study_options_use_cases_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three files compiles: `Error: Method not found: 'studyOptionsOf'.`, `Error: The method 'watchStudyOptions' isn't defined for the type 'SettingsRepositoryImpl'.`, `Error: Method not found: 'WatchStudyOptionsUseCase'.`

- [ ] **Step 3: Write the study_config codec and the resolution**

Create `lib/features/settings/data/mappers/study_config_mapper.dart`:

```dart
import 'dart:convert';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

// The keys of `deck.study_config` (spec D5).
const _cardLimitKey = 'card_limit';
const _newCardOrderKey = 'new_card_order';

/// The JSON a root keeps [options] in (spec D5).
String studyConfigOf(StudyOptions options) => jsonEncode({
  _cardLimitKey: options.cardLimit,
  _newCardOrderKey: options.newCardOrder.name,
});

/// The options [studyConfig] holds, or null when it cannot be read: not a
/// JSON object, a key missing, a value of the wrong type, an unknown order or
/// a card limit out of bounds (D5). A key the app does not know is ignored.
StudyOptions? studyOptionsOf(String studyConfig) {
  final Object? decoded;
  try {
    decoded = jsonDecode(studyConfig);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  final cardLimit = decoded[_cardLimitKey];
  final newCardOrder = NewCardOrder.values
      .asNameMap()[decoded[_newCardOrderKey]];
  if (cardLimit is! int || newCardOrder == null) return null;
  final options = StudyOptions(
    cardLimit: cardLimit,
    newCardOrder: newCardOrder,
  );
  if (options.check() case Rejected()) return null;
  return options;
}

/// The options in force under [root]: its override when it can be read, the
/// app-wide defaults of [settings] otherwise (BR-STUDY-056). An unreadable
/// override is reported, never repaired here (IT-STUDY-013).
EffectiveStudyOptions effectiveStudyOptionsOf(Deck root, AppSetting settings) {
  final appDefaults = appSettingsOf(settings).studyDefaults;
  final studyConfig = root.studyConfig;
  if (studyConfig == null) {
    return EffectiveStudyOptions(
      rootDeckId: root.id,
      options: appDefaults,
      source: StudyOptionsSource.appDefaults,
    );
  }
  final override = studyOptionsOf(studyConfig);
  if (override == null) {
    return EffectiveStudyOptions(
      rootDeckId: root.id,
      options: appDefaults,
      source: StudyOptionsSource.unreadableRootOverride,
    );
  }
  return EffectiveStudyOptions(
    rootDeckId: root.id,
    options: override,
    source: StudyOptionsSource.rootOverride,
  );
}
```

- [ ] **Step 4: Read, save and clear the override in the repository**

Replace the whole of `lib/features/settings/data/datasources/settings_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for the one `app_settings` row and for the study options a
/// root deck keeps in `deck.study_config`. It returns Drift rows, never
/// domain values, and runs inside the caller's transaction.
final class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Stream<AppSetting> watchRow() => (_db.select(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).watchSingle();

  Future<void> updateRow(AppSettingsCompanion values) => (_db.update(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).write(values);

  /// The root of [deckId] and the settings row, in one statement, again when
  /// either changes; null when [deckId] or its root does not exist or is in
  /// the Trash. The root is reached through `root_id` (BR-DECK-003).
  Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId) {
    final deck = _db.deck;
    final root = _db.alias(_db.deck, 'root');
    final settings = _db.appSettings;
    final query = _db.select(deck).join([
      innerJoin(
        root,
        root.id.equalsExp(deck.rootId) & root.deleteBatchId.isNull(),
      ),
      innerJoin(settings, settings.id.equals(appSettingsRowId)),
    ])..where(deck.id.equals(deckId) & deck.deleteBatchId.isNull());
    return query.watchSingleOrNull().map(
      (row) =>
          row == null ? null : (row.readTable(root), row.readTable(settings)),
    );
  }

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// Writes the override of the root [rootId]; null removes it.
  Future<void> setStudyConfig(
    String rootId,
    String? studyConfig,
    DateTime now,
  ) => (_db.update(_db.deck)..where((deck) => deck.id.equals(rootId))).write(
    DeckCompanion(studyConfig: Value(studyConfig), updatedAt: Value(now)),
  );
}
```

Replace the whole of `lib/features/settings/data/repositories/settings_repository_impl.dart` with:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';
import 'package:memox/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:memox/features/settings/data/mappers/study_config_mapper.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// Every save is one transaction of its own (BR-SETTINGS-007): its rule is
/// checked inside it, and a refusal writes nothing.
final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = SettingsDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SettingsDao _dao;
  final DateTime Function() _now;

  @override
  Stream<AppSettingsEntity> watchAppSettings() =>
      _dao.watchRow().map(appSettingsOf).mapDatabaseErrors();

  @override
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  }) {
    final at = _now();
    return _write(() async {
      if (options.check() case Rejected(:final reason)) return Rejected(reason);
      await _dao.updateRow(
        AppSettingsCompanion(
          cardLimit: Value(options.cardLimit),
          newCardOrder: Value(options.newCardOrder.name),
          updatedAt: Value(at),
        ),
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  }) => _save(AppSettingsCompanion(themeMode: Value(theme.name)));

  @override
  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  }) => _save(AppSettingsCompanion(language: Value(language.name)));

  @override
  Future<Outcome<void, SettingsRejection>> resetToDefaults() {
    const defaults = AppSettingsEntity.defaults;
    return _save(
      AppSettingsCompanion(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
        newCardOrder: Value(defaults.studyDefaults.newCardOrder.name),
        themeMode: Value(defaults.theme.name),
        language: Value(defaults.language.name),
      ),
    );
  }

  @override
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
      _dao
          .watchRootAndSettings(deckId)
          .map(
            (rows) => switch (rows) {
              (final Deck root, final AppSetting settings) =>
                effectiveStudyOptionsOf(root, settings),
              null => null,
            },
          )
          .mapDatabaseErrors();

  @override
  Future<Outcome<void, SettingsRejection>> saveRootStudyOptions({
    required String rootDeckId,
    required StudyOptions options,
  }) {
    final at = _now();
    return _write(() async {
      if (options.check() case Rejected(:final reason)) return Rejected(reason);
      final root = await _dao.deckRow(rootDeckId);
      if (root == null) return const Rejected(SettingsRejection.deckNotFound);
      if (root.parentId != null) {
        return const Rejected(SettingsRejection.notARootDeck);
      }
      await _dao.setStudyConfig(rootDeckId, studyConfigOf(options), at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, SettingsRejection>> clearRootStudyOptions({
    required String rootDeckId,
  }) {
    final at = _now();
    return _write(() async {
      final root = await _dao.deckRow(rootDeckId);
      if (root == null) return const Rejected(SettingsRejection.deckNotFound);
      if (root.parentId != null) {
        return const Rejected(SettingsRejection.notARootDeck);
      }
      if (root.studyConfig == null) return const Ok(null);
      await _dao.setStudyConfig(rootDeckId, null, at);
      return const Ok(null);
    });
  }

  /// [values] and `updated_at`, in one transaction of their own.
  Future<Outcome<void, SettingsRejection>> _save(AppSettingsCompanion values) {
    final at = _now();
    return _write(() async {
      await _dao.updateRow(values.copyWith(updatedAt: Value(at)));
      return const Ok(null);
    });
  }

  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

Replace the whole of `lib/features/settings/domain/repositories/settings_repository.dart` with:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The one implementation is `SettingsRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class SettingsRepository {
  /// The one `app_settings` row, again after every save (BR-SETTINGS-001).
  Stream<AppSettingsEntity> watchAppSettings();

  /// The app-wide study defaults. It never writes a root's override
  /// (BR-SETTINGS-002), and a session already open keeps its limit
  /// (BR-SETTINGS-004).
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  });

  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  });

  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  });

  /// The four values a person can set back to their defaults, and nothing
  /// else (BR-SETTINGS-008).
  Future<Outcome<void, SettingsRejection>> resetToDefaults();

  /// The options [deckId] studies with: its root's override, or the app-wide
  /// defaults when there is none or it cannot be read (BR-STUDY-056,
  /// IT-STUDY-013). Again when either changes; null when the deck does not
  /// exist or is in the Trash.
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId});

  /// Gives the root [rootDeckId] options of its own, for the sessions opened
  /// after it (BR-SETTINGS-003). A sub-deck has none (BR-STUDY-056).
  Future<Outcome<void, SettingsRejection>> saveRootStudyOptions({
    required String rootDeckId,
    required StudyOptions options,
  });

  /// Removes the root's override, readable or not, so the app-wide defaults
  /// apply again (UC-SETTINGS-001 A1). A root without one is `Ok` and
  /// nothing is written.
  Future<Outcome<void, SettingsRejection>> clearRootStudyOptions({
    required String rootDeckId,
  });
}
```

- [ ] **Step 5: Write the three use cases**

Create `lib/features/settings/domain/usecases/save_root_study_options_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 (Local): a root deck's own card limit and new-card order,
/// for the sessions of its tree opened after it (BR-SETTINGS-003,
/// BR-STUDY-056).
final class SaveRootStudyOptionsUseCase {
  const SaveRootStudyOptionsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    required String rootDeckId,
    required StudyOptions options,
  }) =>
      _settings.saveRootStudyOptions(rootDeckId: rootDeckId, options: options);
}
```

Create `lib/features/settings/domain/usecases/use_app_defaults_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 A1 and E4: `Use app defaults` on a root deck removes its
/// override, so its tree studies with the app-wide defaults again.
final class UseAppDefaultsUseCase {
  const UseAppDefaultsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required String rootDeckId}) =>
      _settings.clearRootStudyOptions(rootDeckId: rootDeckId);
}
```

Create `lib/features/settings/domain/usecases/watch_study_options_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 A1: the study options a deck studies with and where they
/// come from, again on every change, and deckNotFound once the deck is gone
/// (BR-STUDY-056, IT-STUDY-013).
final class WatchStudyOptionsUseCase {
  const WatchStudyOptionsUseCase(this._settings);

  final SettingsRepository _settings;

  Stream<Outcome<EffectiveStudyOptions, SettingsRejection>> call({
    required String deckId,
  }) => _settings
      .watchStudyOptions(deckId: deckId)
      .map<Outcome<EffectiveStudyOptions, SettingsRejection>>(
        (effective) => switch (effective) {
          final EffectiveStudyOptions effective => Ok(effective),
          null => const Rejected(SettingsRejection.deckNotFound),
        },
      );
}
```

- [ ] **Step 6: Describe the override in schema.md and UC-SETTINGS-001**

In `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`:

Replace

```markdown
rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008, BR-SRS-022, BR-STUDY-003, BR-STUDY-024, BR-STUDY-035, BR-STUDY-056, BR-STUDY-057]
code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart]
---
```

with

```markdown
rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008, BR-SRS-022, BR-STUDY-003, BR-STUDY-024, BR-STUDY-035, BR-STUDY-056, BR-STUDY-057]
code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart, lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/usecases/save_root_study_options_use_case.dart, lib/features/settings/domain/usecases/use_app_defaults_use_case.dart]
---
```

In `docs/shared/data/schema.md`:

Replace

```markdown

## Bất biến — phải kiểm tra được bằng query
```

with

```markdown

**Dạng của `study_config`:** `{"card_limit": <số nguyên 1–200>, "new_card_order":
"created" | "random"}`. Thiếu khoá, sai kiểu, `new_card_order` khác hai giá trị đó
hoặc `card_limit` ngoài 1–200 (BR-STUDY-003) làm giá trị ghi đè **không đọc được**:
giá trị hiệu lực là giá trị của bảng này, và việc đọc MUST NOT sửa text đã lưu
(IT-STUDY-013). Cột chỉ đổi khi người dùng lưu tuỳ chọn của root hoặc chọn
`Use app defaults` (UC-SETTINGS-001 A1). Khoá lạ bị bỏ qua.

## Bất biến — phải kiểm tra được bằng query
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/settings/data/study_config_mapper_test.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/settings/domain/root_study_options_use_cases_test.dart
```

Expected: `+31: All tests passed!`

- [ ] **Step 8: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+752: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 17 | Errors: 0 | Warnings: 0 | Info: 17` (the 17 are the UI layers'
`targets_pending`); `PASS — 0 error(s)` (the warnings are older than this plan).

- [ ] **Step 9: Commit**

```bash
git add docs/_generated \
  docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md \
  docs/shared/data/schema.md \
  lib/features/settings/data/datasources/settings_dao.dart \
  lib/features/settings/data/mappers/study_config_mapper.dart \
  lib/features/settings/data/repositories/settings_repository_impl.dart \
  lib/features/settings/domain/repositories/settings_repository.dart \
  lib/features/settings/domain/usecases/save_root_study_options_use_case.dart \
  lib/features/settings/domain/usecases/use_app_defaults_use_case.dart \
  lib/features/settings/domain/usecases/watch_study_options_use_case.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/settings/data/study_config_mapper_test.dart \
  test/features/settings/domain/root_study_options_use_cases_test.dart
git commit -F - <<'EOF'
feat(settings): read, save and clear the study options of a root deck

A deck studies with its root's override when it can be read and with the
app-wide defaults otherwise (BR-STUDY-056). An unreadable override is
reported as such and never rewritten on read (IT-STUDY-013). The override
is saved as the JSON schema.md now describes, and Use app defaults removes
it; neither touches anything but the root's study_config (BR-SETTINGS-003).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: A reset of learning progress may pick the scheduler

**Files:**
- Modify: `lib/features/srs/domain/repositories/schedule_repository.dart`, `lib/features/srs/data/repositories/schedule_repository_impl.dart`
- Test (create): `test/support/srs_fixtures.dart`, `test/features/srs/data/reset_learning_test.dart`
- Test (modify): `test/features/srs/data/schedule_repository_impl_test.dart`
- Regenerate: `docs/_generated/`

**Interfaces:**
- Consumes: `ScheduleRepository`, `ScheduleRepositoryImpl(AppDatabase db, {DateTime Function()? now})`
  and `SrsDao` (foundation Task 8); `schedulerFor(SchedulerType).version`
  (`srs/domain/models/schedulers_model.dart`); `SchedulerType.{eightBox, sm2}`
  with `code` and `fromCode`; `totalChanges` and
  `openTestDatabase({QueryInterceptor? interceptor})`.
- Produces:
  - `ScheduleRepository.resetLearning({required String rootDeckId, SchedulerType? schedulerType})`.
  - In `test/support/srs_fixtures.dart`:
    `insertBareCard(AppDatabase db, String cardId, String deckId)`;
    `insertStudyTree(AppDatabase db, String rootId, {String scheduler = 'eight_box'})`
    returning `(rootId, cardId, sessionId)`;
    `insertDeepCard(AppDatabase db, String rootId)` returning the card id;
    `deckRowOf`, `scheduleRowOf`, `sessionRowOf` — `Future<QueryRow>`; and
    `expectStartValues(QueryRow row, {required String scheduler, required int generation})`.

Spec §6.1 and D7. Everything else the reset does is today's behavior, in one
transaction; the tests pin it here, since UC-SRS-001 now rests on it: a new
generation, the start values, `first_answered_at` cleared, open sessions
invalidated, `review_log`, the tree, the cards and their tags kept, a failure
midway rolled back.


- [ ] **Step 1: Move the srs tree helpers into a shared fixture file**

Create `test/support/srs_fixtures.dart`:

```dart
import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

// Trees for the srs tests, written as SQL so that every column is set on
// purpose.

/// A card row and nothing else: the caller writes its schedule row.
Future<void> insertBareCard(AppDatabase db, String cardId, String deckId) =>
    db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES (?, ?, 'f', 'b', 0, 0)",
      [cardId, deckId],
    );

/// One tree per [rootId]: a root at generation 1 running [scheduler], a
/// sub-deck `<rootId>-leaf` holding one card, that card's start-value
/// schedule row, and an `in_progress` session of the root.
/// Returns (rootId, cardId, sessionId).
Future<(String, String, String)> insertStudyTree(
  AppDatabase db,
  String rootId, {
  String scheduler = 'eight_box',
}) async {
  final cardId = '$rootId-card';
  final sessionId = '$rootId-session';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES (?, 'root', NULL, ?, 1, 'deck', ?, 1, 1, 0, 0, 0)",
    [rootId, rootId, scheduler],
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'leaf', ?, ?, 2, 'card', 0, 0, 0)",
    ['$rootId-leaf', rootId, rootId],
  );
  await insertBareCard(db, cardId, '$rootId-leaf');
  await db.customStatement(
    scheduler == 'sm2'
        ? 'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, '
              "ease_factor, interval_days, repetitions) VALUES (?, 'sm2', 1, 1, 2.5, 0, 0)"
        : 'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, '
              "current_box) VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  await db.customStatement(
    'INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, '
    "status, cursor, card_limit, started_at) VALUES (?, ?, ?, 1, 'learning', 'self_assess', "
    "'in_progress', 0, 20, 0)",
    [sessionId, rootId, rootId],
  );
  return (rootId, cardId, sessionId);
}

/// A card two levels below [rootId] (root → branch → deep) in an `eight_box`
/// tree: a statement that reaches only the root's children misses it.
Future<String> insertDeepCard(AppDatabase db, String rootId) async {
  final cardId = '$rootId-deep-card';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'branch', ?, ?, 2, 'deck', 1, 0, 0), (?, 'deep', ?, ?, 3, 'card', 0, 0, 0)",
    [
      '$rootId-branch',
      rootId,
      rootId,
      '$rootId-deep',
      '$rootId-branch',
      rootId,
    ],
  );
  await insertBareCard(db, cardId, '$rootId-deep');
  await db.customStatement(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) '
    "VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  return cardId;
}

Future<QueryRow> _row(AppDatabase db, String table, String column, String id) =>
    db
        .customSelect(
          'SELECT * FROM $table WHERE $column = ?',
          variables: [Variable(id)],
        )
        .getSingle();

Future<QueryRow> deckRowOf(AppDatabase db, String id) =>
    _row(db, 'deck', 'id', id);

Future<QueryRow> scheduleRowOf(AppDatabase db, String cardId) =>
    _row(db, 'card_schedule', 'card_id', cardId);

Future<QueryRow> sessionRowOf(AppDatabase db, String id) =>
    _row(db, 'study_session', 'id', id);

/// [row] holds the start values of [scheduler] at [generation].
void expectStartValues(
  QueryRow row, {
  required String scheduler,
  required int generation,
}) {
  expect(row.read<String>('scheduler_type'), scheduler);
  expect(row.read<int>('generation'), generation);
  expect(row.data['learned_at'], isNull);
  expect(row.data['due_at'], isNull);
  expect(row.data['last_answered_at'], isNull);
  expect(row.read<int>('answer_count'), 0);
  expect(row.read<int>('lapse_count'), 0);
  if (scheduler == 'sm2') {
    expect(row.data['current_box'], isNull);
    expect(row.read<double>('ease_factor'), 2.5);
    expect(row.read<int>('interval_days'), 0);
    expect(row.read<int>('repetitions'), 0);
    return;
  }
  expect(row.read<int>('current_box'), 1);
  expect(row.data['ease_factor'], isNull);
}
```

Then take the helpers out of the repository test and call the shared ones.

Run:

```bash
python3 - <<'EOF'
from pathlib import Path
path = Path('test/features/srs/data/schedule_repository_impl_test.dart')
text = path.read_text()
start = text.index('Future<void> _addCard(')
end = text.index('void main() {')
path.write_text(text[:start] + text[end:])
EOF
```

In `test/features/srs/data/schedule_repository_impl_test.dart`:

Replace

```dart
import 'package:drift/drift.dart' show QueryRow, Variable;
```

with

```dart
import 'package:drift/drift.dart' show Variable;
```

Replace

```dart
import '../../../support/test_database.dart';
```

with

```dart
import '../../../support/srs_fixtures.dart';
import '../../../support/test_database.dart';
```

Run:

```bash
sed -i -E \
  -e 's/\b_addCard\(/insertBareCard(/g' \
  -e 's/\b_tree\(/insertStudyTree(/g' \
  -e 's/\b_deepCard\(/insertDeepCard(/g' \
  -e 's/\b_deck\(/deckRowOf(/g' \
  -e 's/\b_schedule\(/scheduleRowOf(/g' \
  -e 's/\b_session\(/sessionRowOf(/g' \
  -e 's/\b_writes\(/totalChanges(/g' \
  -e 's/\b_expectStartValues\(/expectStartValues(/g' \
  test/features/srs/data/schedule_repository_impl_test.dart
dart format test/features/srs/data/schedule_repository_impl_test.dart
```

```bash
flutter test test/features/srs/data/schedule_repository_impl_test.dart
```

Expected: `+20: All tests passed!` — the same tests, on the shared helpers.

- [ ] **Step 2: Write the failing tests**

Create `test/features/srs/data/reset_learning_test.dart`:

```dart
import 'package:drift/drift.dart'
    show QueryExecutor, QueryInterceptor, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';

import '../../../support/srs_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SRS-001: reset learning progress.

/// Fails the statement that writes a reset's new schedule rows, after the
/// root and the old rows already changed in the same transaction.
final class _FailingScheduleInsert extends QueryInterceptor {
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.startsWith('INSERT INTO card_schedule')) {
      throw SqliteException(
        extendedResultCode: 13,
        message: 'database or disk is full',
      );
    }
    return super.runInsert(executor, statement, args);
  }
}

Matcher _refusedWith<T>(SrsRejection reason) => isA<Rejected<T, SrsRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 24);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  for (final (from, to, learn) in <(String, SchedulerType, Object)>[
    ('sm2', SchedulerType.eightBox, Sm2Action.good),
    ('eight_box', SchedulerType.sm2, EightBoxAction.remembered),
  ]) {
    test('a reset switches a locked $from tree to ${to.code} at its start '
        'values (UC-SRS-001 steps 3 and 5)', () async {
      final (rootId, cardId, sessionId) = await insertStudyTree(
        db,
        'r',
        scheduler: from,
      );
      await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: learn,
      );
      expect(
        (await deckRowOf(db, rootId)).data['first_answered_at'],
        isNotNull,
      );

      final result = await repo.resetLearning(
        rootDeckId: rootId,
        schedulerType: to,
      );

      expect(result, isA<Ok<void, SrsRejection>>());
      final root = await deckRowOf(db, rootId);
      expect(root.read<String>('scheduler_type'), to.code);
      expect(root.read<int>('scheduler_version'), schedulerFor(to).version);
      expect(root.data['scheduler_config'], isNull);
      expect(root.read<int>('generation'), 2);
      expect(root.data['first_answered_at'], isNull);
      expectStartValues(
        await scheduleRowOf(db, cardId),
        scheduler: to.code,
        generation: 2,
      );
    });
  }

  test('a reset that names the scheduler the root runs keeps it '
      '(UC-SRS-001 A1)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(
      db,
      'r',
      scheduler: 'sm2',
    );
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: Sm2Action.good,
    );

    final result = await repo.resetLearning(
      rootDeckId: rootId,
      schedulerType: SchedulerType.sm2,
    );

    expect(result, isA<Ok<void, SrsRejection>>());
    final root = await deckRowOf(db, rootId);
    expect(root.read<String>('scheduler_type'), 'sm2');
    expect(root.read<int>('scheduler_version'), 1);
    expect(root.read<int>('generation'), 2);
    expectStartValues(
      await scheduleRowOf(db, cardId),
      scheduler: 'sm2',
      generation: 2,
    );
  });

  test('a reset while a session is open closes it, refuses its next answer '
      'and keeps the answers given before (IT-CONT-009, host half)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await repo.resetLearning(rootDeckId: rootId);
    final lateAnswer = await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    final session = await sessionRowOf(db, sessionId);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
    expect(lateAnswer, _refusedWith<void>(SrsRejection.staleGeneration));
    final logs = await db
        .customSelect(
          'SELECT generation FROM review_log WHERE card_id = ?',
          variables: [Variable(cardId)],
        )
        .get();
    expect([for (final log in logs) log.read<int>('generation')], [1]);
  });

  test('a reset keeps the tree, the cards and their tags (BR-SRS-021)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await insertDeepCard(db, rootId);
    await db.customStatement(
      'INSERT INTO tags (id, name, name_folded, created_at) '
      "VALUES ('t', 'Fruit', 'fruit', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES (?, 't')",
      [cardId],
    );
    Future<List<Map<String, Object?>>> content() async => [
      for (final row
          in await db
              .customSelect(
                'SELECT d.id, d.name, d.parent_id, d.root_id, d.depth, '
                'd.content_type, d.sibling_position, c.id AS card_id, c.front, '
                'c.back, t.tag_id FROM deck d '
                'LEFT JOIN card c ON c.deck_id = d.id '
                'LEFT JOIN card_tags t ON t.card_id = c.id ORDER BY d.id, c.id',
              )
              .get())
        row.data,
    ];
    final before = await content();

    await repo.resetLearning(
      rootDeckId: rootId,
      schedulerType: SchedulerType.sm2,
    );

    expect(await content(), before);
  });

  test('a reset that fails midway leaves the whole tree as it was '
      '(UC-SRS-001 E1, BR-SRS-027)', () async {
    final failing = openTestDatabase(interceptor: _FailingScheduleInsert());
    addTearDown(failing.close);
    final broken = ScheduleRepositoryImpl(failing, now: () => now);
    final (rootId, cardId, sessionId) = await insertStudyTree(failing, 'r');
    await broken.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await expectLater(
      broken.resetLearning(
        rootDeckId: rootId,
        schedulerType: SchedulerType.sm2,
      ),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    final root = await deckRowOf(failing, rootId);
    expect(root.read<String>('scheduler_type'), 'eight_box');
    expect(root.read<int>('generation'), 1);
    expect(root.data['first_answered_at'], isNotNull);
    final schedule = await scheduleRowOf(failing, cardId);
    expect(schedule.read<int>('current_box'), 2);
    expect(schedule.data['learned_at'], isNotNull);
    expect(
      (await sessionRowOf(failing, sessionId)).read<String>('status'),
      'in_progress',
    );
  });

  test('a reset of a root that does not exist is notFound and writes '
      'nothing', () async {
    await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    final result = await repo.resetLearning(
      rootDeckId: 'missing',
      schedulerType: SchedulerType.sm2,
    );

    expect(result, _refusedWith<void>(SrsRejection.notFound));
    expect(await totalChanges(db), before);
  });

  test(
    'a reset leaves every other tree as it was (UC-SRS-001 step 5)',
    () async {
      final (rootId, cardId, sessionId) = await insertStudyTree(db, 'a');
      final (otherId, otherCardId, otherSessionId) = await insertStudyTree(
        db,
        'b',
      );
      for (final (card, session) in [
        (cardId, sessionId),
        (otherCardId, otherSessionId),
      ]) {
        await repo.recordReview(
          cardId: card,
          sessionId: session,
          action: EightBoxAction.remembered,
        );
      }

      await repo.resetLearning(
        rootDeckId: rootId,
        schedulerType: SchedulerType.sm2,
      );

      final other = await deckRowOf(db, otherId);
      expect(other.read<String>('scheduler_type'), 'eight_box');
      expect(other.read<int>('generation'), 1);
      expect(other.data['first_answered_at'], isNotNull);
      expect(
        (await scheduleRowOf(db, otherCardId)).read<int>('current_box'),
        2,
      );
      expect(
        (await sessionRowOf(db, otherSessionId)).read<String>('status'),
        'in_progress',
      );
    },
  );
}
```

- [ ] **Step 3: Run them to see them fail**

```bash
flutter test test/features/srs/data/schedule_repository_impl_test.dart test/features/srs/data/reset_learning_test.dart
```

Expected: `+20 -1: Some tests failed.` The new file does not compile: `Error: No named parameter with the name 'schedulerType'.`

- [ ] **Step 4: Let resetLearning take the scheduler**

In `lib/features/srs/data/repositories/schedule_repository_impl.dart`:

Replace

```dart
    required String rootDeckId,
  }) {
```

with

```dart
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) {
```

Replace

```dart
      }
      final generation = root.generation! + 1;
```

with

```dart
      }
      final current = SchedulerType.fromCode(root.schedulerType!);
      final type = schedulerType ?? current;
      // The scheduler the root keeps keeps its version; another one starts at
      // the version this app runs, as changeScheduler does (spec D7).
      final version = type == current
          ? root.schedulerVersion!
          : schedulerFor(type).version;
      final generation = root.generation! + 1;
```

Replace

```dart
        DeckCompanion(
          generation: Value(generation),
```

with

```dart
        DeckCompanion(
          schedulerType: Value(type.code),
          schedulerVersion: Value(version),
          generation: Value(generation),
```

Replace

```dart
      );
      final type = SchedulerType.fromCode(root.schedulerType!);
      await _dao.replaceTreeSchedules(
```

with

```dart
      );
      await _dao.replaceTreeSchedules(
```

Replace

```dart
          type: type,
          version: root.schedulerVersion!,
        ),
```

with

```dart
          type: type,
          version: version,
        ),
```

In `lib/features/srs/domain/repositories/schedule_repository.dart`:

Replace

```dart

  /// Reset learning progress: a new generation, every schedule row of the
  /// tree back to its start values, the scheduler unlocked, the open sessions
  /// closed.
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
  });
```

with

```dart

  /// Reset learning progress (UC-SRS-001), all of it or nothing of it
  /// (BR-SRS-027): a new generation, every schedule row of the tree back to
  /// the start values of the scheduler it ends up with, the scheduler
  /// unlocked, the open sessions closed. A [schedulerType] other than the
  /// root's switches the scheduler too; null keeps it. This is the only way
  /// to change the scheduler of a locked tree (BR-SRS-024).
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  });
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/srs/data/schedule_repository_impl_test.dart test/features/srs/data/reset_learning_test.dart
```

Expected: `+28: All tests passed!`

- [ ] **Step 7: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+760: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 17 | Errors: 0 | Warnings: 0 | Info: 17` (the 17 are the UI layers'
`targets_pending`); `PASS — 0 error(s)` (the warnings are older than this plan).

- [ ] **Step 8: Commit**

```bash
git add docs/_generated \
  lib/features/srs/data/repositories/schedule_repository_impl.dart \
  lib/features/srs/domain/repositories/schedule_repository.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/support/srs_fixtures.dart
git commit -F - <<'EOF'
feat(srs): let a reset of learning progress pick the scheduler

resetLearning takes an optional scheduler type (UC-SRS-001 steps 3 and 5):
another type sets scheduler_type and the version this app runs, in the same
transaction as the new generation, the start values and the closed sessions
(BR-SRS-027). The srs tests share their SQL trees through
test/support/srs_fixtures.dart, and the reset tests get a file of their own.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: The reset summary and the two reset use cases

**Files:**
- Create: `lib/features/srs/domain/models/reset_learning_summary_model.dart`, `lib/features/srs/domain/usecases/reset_learning_progress_use_case.dart`, `lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart`
- Modify: `lib/features/srs/domain/repositories/schedule_repository.dart`, `lib/features/srs/data/datasources/srs_dao.dart`, `lib/features/srs/data/repositories/schedule_repository_impl.dart`, `docs/features/srs/README.md`, `docs/features/srs/usecases/UC-SRS-001-reset-learning-progress.md`, `docs/wbs_BE.md`
- Test (create): `test/features/srs/domain/reset_learning_use_cases_test.dart`
- Test (modify): `test/features/srs/data/reset_learning_test.dart`
- Regenerate: `docs/_generated/`

**Interfaces:**
- Consumes: Task 4; `SrsRejection.{notFound, notARootDeck}`.
- Produces:
  - `final class ResetLearningSummary({required SchedulerType schedulerType, required bool isSchedulerLocked, required int cardCount, required int learnedCardCount, required int openSessionCount})`
    with `bool get hasProgressToLose`, in
    `srs/domain/models/reset_learning_summary_model.dart`.
  - `ScheduleRepository.resetSummary({required String rootDeckId})` —
    `Future<Outcome<ResetLearningSummary, SrsRejection>>`.
  - `SrsDao.resetSummaryRow(String id)` —
    `Future<({Deck deck, int cardCount, int learnedCardCount, int openSessionCount})?>`.
  - Use cases, each `const <Name>UseCase(ScheduleRepository schedules)`:
    `ResetLearningProgressUseCase` —
    `call({required String rootDeckId, SchedulerType? schedulerType})`;
    `GetResetLearningSummaryUseCase` — `call({required String rootDeckId})`.

Spec §6.1–§6.3 and §8. `hasProgressToLose` is false when no card is learned and
no session is open, which UC-SRS-001 A2 tells the person; the two lists of the
confirmation are UI copy (BR-SRS-030). This task also closes the package's docs:
the srs `code:` fields and the WBS.


- [ ] **Step 1: Write the failing tests**

In `test/features/srs/data/reset_learning_test.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
```

Replace

```dart

// UC-SRS-001: reset learning progress.

```

with

```dart

// UC-SRS-001: reset learning progress, and what its confirmation shows.

```

Replace

```dart
        'in_progress',
      );
    },
  );
}
```

with

```dart
        'in_progress',
      );
    },
  );

  Future<ResetLearningSummary> summaryOf(String rootId) async =>
      switch (await repo.resetSummary(rootDeckId: rootId)) {
        Ok(:final value) => value,
        Rejected(:final reason) => fail('resetSummary refused: $reason'),
      };

  test('the summary of a tree nobody has studied has nothing to lose '
      '(UC-SRS-001 A2)', () async {
    final (rootId, _, sessionId) = await insertStudyTree(
      db,
      'r',
      scheduler: 'sm2',
    );
    await db.customStatement('DELETE FROM study_session WHERE id = ?', [
      sessionId,
    ]);

    final summary = await summaryOf(rootId);

    expect(summary.schedulerType, SchedulerType.sm2);
    expect(summary.isSchedulerLocked, isFalse);
    expect(summary.cardCount, 1);
    expect(summary.learnedCardCount, 0);
    expect(summary.openSessionCount, 0);
    expect(summary.hasProgressToLose, isFalse);
  });

  test('the summary counts the learned cards and the open sessions of the '
      'whole tree, outside the Trash (UC-SRS-001 step 2)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);
    await insertBareCard(db, 'r-trashed', 'r-leaf');
    await db.customStatement(
      'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, '
      "generation, current_box, learned_at) VALUES ('r-trashed', 'eight_box', "
      '1, 1, 2, 0)',
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'r-trashed'",
    );
    for (final id in [cardId, deepCardId]) {
      await repo.recordReview(
        cardId: id,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
    }

    final summary = await summaryOf(rootId);

    expect(summary.isSchedulerLocked, isTrue);
    expect(summary.cardCount, 2);
    expect(summary.learnedCardCount, 2);
    expect(summary.openSessionCount, 1);
    expect(summary.hasProgressToLose, isTrue);
  });

  test(
    'an open session alone is progress to lose (UC-SRS-001 step 2)',
    () async {
      final (rootId, _, _) = await insertStudyTree(db, 'r');

      final summary = await summaryOf(rootId);

      expect(summary.learnedCardCount, 0);
      expect(summary.openSessionCount, 1);
      expect(summary.hasProgressToLose, isTrue);
    },
  );

  test('a sub-deck, a missing root and a root in the Trash have no summary '
      '(UC-SRS-001 A4)', () async {
    await insertStudyTree(db, 'r');

    expect(
      await repo.resetSummary(rootDeckId: 'r-leaf'),
      _refusedWith<ResetLearningSummary>(SrsRejection.notARootDeck),
    );
    expect(
      await repo.resetSummary(rootDeckId: 'missing'),
      _refusedWith<ResetLearningSummary>(SrsRejection.notFound),
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
    );
    expect(
      await repo.resetSummary(rootDeckId: 'r'),
      _refusedWith<ResetLearningSummary>(SrsRejection.notFound),
    );
  });

  test('a tree with no cards has nothing to lose and resets all the same '
      '(UC-SRS-001 A2)', () async {
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) '
      "VALUES ('empty', 'empty', NULL, 'empty', 1, 'deck', 'eight_box', 1, 1, "
      '0, 0, 0)',
    );

    final summary = await summaryOf('empty');
    final result = await repo.resetLearning(rootDeckId: 'empty');

    expect((summary.cardCount, summary.hasProgressToLose), (0, false));
    expect(result, isA<Ok<void, SrsRejection>>());
    expect((await deckRowOf(db, 'empty')).read<int>('generation'), 2);
  });
}
```

Create `test/features/srs/domain/reset_learning_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart';
import 'package:memox/features/srs/domain/usecases/reset_learning_progress_use_case.dart';

import '../../../support/test_database.dart';

// UC-SRS-001 through its two use cases: the confirmation's summary, then the
// reset that picks another scheduler.

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl schedules;
  setUp(() async {
    db = openTestDatabase();
    schedules = ScheduleRepositoryImpl(db, now: () => DateTime(2026, 9, 24));
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) VALUES '
      "('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0), "
      "('leaf', 'leaf', 'r', 'r', 2, 'card', NULL, NULL, NULL, 0, 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
      "VALUES ('c', 'leaf', 'f', 'b', 0, 0)",
    );
    await schedules.initializeCard(cardId: 'c');
    await db.customStatement(
      'INSERT INTO study_session (id, deck_id, root_id, generation, '
      'session_kind, current_mode, status, cursor, card_limit, started_at) '
      "VALUES ('s', 'r', 'r', 1, 'learning', 'self_assess', 'in_progress', "
      '0, 20, 0)',
    );
    await schedules.recordReview(
      cardId: 'c',
      sessionId: 's',
      action: EightBoxAction.remembered,
    );
  });
  tearDown(() => db.close());

  Matcher summaryWith(
    SchedulerType schedulerType, {
    required bool isSchedulerLocked,
    required bool hasProgressToLose,
  }) => isA<Ok<ResetLearningSummary, SrsRejection>>().having(
    (ok) => (
      ok.value.schedulerType,
      ok.value.isSchedulerLocked,
      ok.value.hasProgressToLose,
    ),
    'summary',
    (schedulerType, isSchedulerLocked, hasProgressToLose),
  );

  test('the confirmation shows what a locked tree would lose, and the reset '
      'switches it to sm2 with nothing left to lose (UC-SRS-001)', () async {
    final summary = GetResetLearningSummaryUseCase(schedules);

    final before = await summary(rootDeckId: 'r');
    final reset = await ResetLearningProgressUseCase(schedules)(
      rootDeckId: 'r',
      schedulerType: SchedulerType.sm2,
    );
    final after = await summary(rootDeckId: 'r');

    expect(
      before,
      summaryWith(
        SchedulerType.eightBox,
        isSchedulerLocked: true,
        hasProgressToLose: true,
      ),
    );
    expect(reset, isA<Ok<void, SrsRejection>>());
    expect(
      after,
      summaryWith(
        SchedulerType.sm2,
        isSchedulerLocked: false,
        hasProgressToLose: false,
      ),
    );
  });

  test('a sub-deck has no reset (UC-SRS-001 A4)', () async {
    final result = await ResetLearningProgressUseCase(schedules)(
      rootDeckId: 'leaf',
    );

    expect(
      result,
      isA<Rejected<void, SrsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SrsRejection.notARootDeck,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/srs/data/reset_learning_test.dart test/features/srs/domain/reset_learning_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither file compiles: `Error: Error when reading 'lib/features/srs/domain/models/reset_learning_summary_model.dart': No such file or directory`, `Error: The method 'resetSummary' isn't defined for the type 'ScheduleRepositoryImpl'.`

- [ ] **Step 3: Write the summary model**

Create `lib/features/srs/domain/models/reset_learning_summary_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// What resetting the learning progress of a root's tree would clear, told to
/// the person before they confirm (UC-SRS-001 step 2). The lists of what is
/// kept and what is lost are copy (BR-SRS-030); these are the facts behind
/// them.
final class ResetLearningSummary {
  const ResetLearningSummary({
    required this.schedulerType,
    required this.isSchedulerLocked,
    required this.cardCount,
    required this.learnedCardCount,
    required this.openSessionCount,
  });

  /// The scheduler the tree runs now; the reset keeps it or picks another
  /// (UC-SRS-001 step 3).
  final SchedulerType schedulerType;

  /// A card of the tree finished learning, which locks the scheduler
  /// (BR-SRS-003); only a reset unlocks it (BR-SRS-024).
  final bool isSchedulerLocked;

  /// The cards of the tree at any depth, outside the Trash.
  final int cardCount;

  /// The cards among them that finished learning: the reset makes them new
  /// again (BR-SRS-022).
  final int learnedCardCount;

  /// The sessions of the tree still in progress: the reset closes them
  /// (BR-STUDY-015).
  final int openSessionCount;

  /// False when the reset would take nothing away, which UC-SRS-001 A2 tells
  /// the person.
  bool get hasProgressToLose => learnedCardCount > 0 || openSessionCount > 0;
}
```

- [ ] **Step 4: Read the summary in one statement**

In `lib/features/srs/data/datasources/srs_dao.dart`:

Replace

```dart
    return row == null ? null : _db.deck.map(row.data);
  }
```

with

```dart
    return row == null ? null : _db.deck.map(row.data);
  }

  /// The deck [id] names with what a reset of its tree would clear, in one
  /// statement; null when it does not exist or is in the Trash. The counts
  /// leave the Trash out, as the deck list does (UC-DECK-003).
  Future<
    ({Deck deck, int cardCount, int learnedCardCount, int openSessionCount})?
  >
  resetSummaryRow(String id) async {
    final row = await _db
        .customSelect(
          'SELECT d.*,'
          ' (SELECT COUNT(*) FROM card c JOIN deck k ON k.id = c.deck_id'
          '  WHERE k.root_id = d.id AND c.delete_batch_id IS NULL'
          '  AND k.delete_batch_id IS NULL) AS card_count,'
          ' (SELECT COUNT(*) FROM card c JOIN deck k ON k.id = c.deck_id'
          '  JOIN card_schedule cs ON cs.card_id = c.id'
          '  WHERE k.root_id = d.id AND c.delete_batch_id IS NULL'
          '  AND k.delete_batch_id IS NULL AND cs.learned_at IS NOT NULL)'
          '  AS learned_card_count,'
          ' (SELECT COUNT(*) FROM study_session s'
          '  WHERE s.root_id = d.id AND s.status = ?) AS open_session_count'
          ' FROM deck d WHERE d.id = ? AND d.delete_batch_id IS NULL',
          variables: [
            const Variable<String>(_inProgress),
            Variable<String>(id),
          ],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule, _db.studySession},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      deck: _db.deck.map(row.data),
      cardCount: row.read<int>('card_count'),
      learnedCardCount: row.read<int>('learned_card_count'),
      openSessionCount: row.read<int>('open_session_count'),
    );
  }
```

In `lib/features/srs/data/repositories/schedule_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
```

Replace

```dart
  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
```

with

```dart
  @override
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  }) => _mapped(() async {
    final row = await _dao.resetSummaryRow(rootDeckId);
    if (row == null) return const Rejected(SrsRejection.notFound);
    final root = row.deck;
    if (root.parentId != null) return const Rejected(SrsRejection.notARootDeck);
    return Ok(
      ResetLearningSummary(
        schedulerType: SchedulerType.fromCode(root.schedulerType!),
        isSchedulerLocked: root.firstAnsweredAt != null,
        cardCount: row.cardCount,
        learnedCardCount: row.learnedCardCount,
        openSessionCount: row.openSessionCount,
      ),
    );
  });

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
```

Replace

```dart
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
```

with

```dart
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  /// [body], with an unexpected database error leaving as its [Failure].
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
```

In `lib/features/srs/domain/repositories/schedule_repository.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart

  /// Changes the scheduler of an unlocked tree: every schedule row of the tree
```

with

```dart

  /// What a reset of [rootDeckId] would clear, for its confirmation
  /// (UC-SRS-001 step 2): notFound when the root does not exist or is in the
  /// Trash, notARootDeck for a sub-deck.
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  });

  /// Changes the scheduler of an unlocked tree: every schedule row of the tree
```

- [ ] **Step 5: Write the two use cases**

Create `lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// UC-SRS-001 step 2: what a reset would clear, for its confirmation
/// (BR-SRS-030), including whether there is anything to lose (A2).
final class GetResetLearningSummaryUseCase {
  const GetResetLearningSummaryUseCase(this._schedules);

  final ScheduleRepository _schedules;

  Future<Outcome<ResetLearningSummary, SrsRejection>> call({
    required String rootDeckId,
  }) => _schedules.resetSummary(rootDeckId: rootDeckId);
}
```

Create `lib/features/srs/domain/usecases/reset_learning_progress_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// UC-SRS-001 steps 3 to 5: clears the learning progress of a root's tree in
/// one transaction, keeping its scheduler or switching to [schedulerType]
/// (BR-SRS-020 to BR-SRS-027, BR-STUDY-015).
final class ResetLearningProgressUseCase {
  const ResetLearningProgressUseCase(this._schedules);

  final ScheduleRepository _schedules;

  Future<Outcome<void, SrsRejection>> call({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) => _schedules.resetLearning(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
}
```

- [ ] **Step 6: Point the srs docs at the code and record the package in the WBS**

In `docs/features/srs/README.md`:

Replace

```markdown
feature: srs
code: []
depends_on: [card, deck]
```

with

```markdown
feature: srs
code: [lib/features/srs/domain, lib/features/srs/data, lib/features/srs/di]
depends_on: [card, deck]
```

Replace

```markdown
Hai scheduler (`eight_box`, `sm2`), chọn và khoá/đổi scheduler, loại lượt ôn, reset learning progress và `generation` (V8.0).

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

```

with

```markdown
Hai scheduler (`eight_box`, `sm2`), chọn và khoá/đổi scheduler, loại lượt ôn, reset learning progress và `generation` (V8.0).

```

In `docs/features/srs/usecases/UC-SRS-001-reset-learning-progress.md`:

Replace

```markdown
rules: [BR-SRS-020, BR-SRS-021, BR-SRS-022, BR-SRS-023, BR-SRS-024, BR-SRS-025, BR-SRS-026, BR-SRS-027, BR-SRS-028, BR-SRS-029, BR-SRS-030, BR-STUDY-015]
code: []
---
```

with

```markdown
rules: [BR-SRS-020, BR-SRS-021, BR-SRS-022, BR-SRS-023, BR-SRS-024, BR-SRS-025, BR-SRS-026, BR-SRS-027, BR-SRS-028, BR-SRS-029, BR-SRS-030, BR-STUDY-015]
code: [lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart, lib/features/srs/domain/usecases/reset_learning_progress_use_case.dart]
---
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-05 | Tag trên thẻ: gắn, gỡ, thay tag trong transaction của card (BR-TAG-001, BR-TAG-002) | xong | BE-02 | — | PR #26; test trong `test/features/tags/` | — |

```

with

```markdown
| BE-05 | Tag trên thẻ: gắn, gỡ, thay tag trong transaction của card (BR-TAG-001, BR-TAG-002) | xong | BE-02 | — | PR #26; test trong `test/features/tags/` | — |
| BE-A1 | Settings, 8 use case (UC-SETTINGS-001): dòng `app_settings` có từ lần mở database đầu tiên, đọc qua một stream, mỗi lần lưu là một transaction, reset về mặc định; tuỳ chọn học riêng của root deck: lưu, dùng lại mặc định, đọc giá trị hiệu lực (BR-SETTINGS-001…BR-SETTINGS-008, BR-STUDY-003, BR-STUDY-056) | xong | BE-02 | S | [spec](superpowers/specs/2026-09-24-settings-reset-backend-design.md) và [plan](superpowers/plans/2026-09-24-settings-reset-backend.md) gói BE-A1 + BE-A2; test trong `test/features/settings/` | — |
| BE-A2 | Reset learning progress, 2 use case (UC-SRS-001): reset giữ hoặc đổi scheduler, bản tóm tắt cho bước xác nhận (BR-SRS-020…BR-SRS-030, BR-STUDY-015) | xong | BE-02 | S | Spec và plan gói BE-A1 + BE-A2; test trong `test/features/srs/` | — |

```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-A1 | Settings: repository cho dòng `app_settings`, đọc qua một stream, mỗi lần lưu là một transaction, reset về mặc định (UC-SETTINGS-001; BR-SETTINGS-001…BR-SETTINGS-008) | chưa bắt đầu | BE-02 | S | Bảng `app_settings` và cột `deck.study_config` đã có trong schema v1; UC chưa có code | Làm trước BE-A4: phiên học đọc `card_limit` và `new_card_order` từ đây (BR-STUDY-056, BR-STUDY-057) |
| BE-A2 | Reset learning progress: use case trên `ScheduleRepository.resetLearning`, đối chiếu đủ BR-SRS-020…BR-SRS-030 và BR-STUDY-015 (UC-SRS-001) | chưa bắt đầu | BE-02 | S | `resetLearning` đã có kèm test từ foundation; UC chưa có use case | Đối chiếu từng luật với code hiện có, thêm use case và test |
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, ngưỡng dữ liệu của từng mode (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | chưa bắt đầu | BE-02 | M | [README study-mode](features/study-mode/README.md); guard đã có luật `single_study_mode_dispatch` | Đặc tả chung với BE-A4 |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, ngưỡng dữ liệu của từng mode (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | chưa bắt đầu | BE-02 | M | [README study-mode](features/study-mode/README.md); guard đã có luật `single_study_mode_dispatch` | Đặc tả chung với BE-A4 |
```

Replace

```markdown
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
| BE-D3 | Sửa tài liệu đã lệch với code: `code:` của [README srs](features/srs/README.md) còn ghi "chưa có `lib/`"; [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24 | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở mọi UC | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
```

with

```markdown
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2 | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở mọi UC | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
```

Replace

```markdown
  - `tools/docs/check.py` 0 lỗi.
- **Traceability:** có test chứa ID cho 8/22 UC (UC-DECK-001…UC-DECK-006, UC-CARD-001,
  UC-CARD-002). 14 UC còn lại chưa có code.

```

with

```markdown
  - `tools/docs/check.py` 0 lỗi.
- **BE-A1 và BE-A2** (gói 1, [spec](superpowers/specs/2026-09-24-settings-reset-backend-design.md),
  [plan](superpowers/plans/2026-09-24-settings-reset-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 10/22 UC (UC-DECK-001…UC-DECK-006, UC-CARD-001,
  UC-CARD-002, UC-SETTINGS-001, UC-SRS-001). 12 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm tại `f28bdfd`.

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói BE-A1 + BE-A2.

```

Replace

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 7 ID: IT-DISC-001, IT-DISC-003, IT-DISC-005, IT-DISC-006,
    IT-ORG-001, IT-ORG-003, IT-ORG-005.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
```

with

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 10 ID: IT-CONT-009, IT-DISC-001, IT-DISC-003, IT-DISC-005,
    IT-DISC-006, IT-ORG-001, IT-ORG-003, IT-ORG-005, IT-STUDY-008, IT-STUDY-013.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
```

Replace

```markdown

1. BE-A1 và BE-A2: nhỏ, mở đường cho nhóm study.
2. BE-A3 → BE-A4, đặc tả chung một spec "study", kèm BE-C3.
3. BE-A5 và BE-A6, rồi BE-A7.
4. BE-A8 chen vào bất kỳ lúc nào. BE-D1 phải xong trước migration đầu tiên; BE-D2 càng
   sớm càng tốt.
5. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration đầu tiên), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
```

with

```markdown

1. BE-A3 → BE-A4, đặc tả chung một spec "study", kèm BE-C3.
2. BE-A5 và BE-A6, rồi BE-A7.
3. BE-A8 chen vào bất kỳ lúc nào. BE-D1 phải xong trước migration đầu tiên; BE-D2 càng
   sớm càng tốt.
4. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration đầu tiên), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
```

Replace

```markdown
  worktree sạch.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  worktree sạch.
- **Cập nhật ngày 2026-09-24:** BE-A1 và BE-A2 xong, cùng phần README của BE-D3, trong
  commit cuối của gói BE-A1 + BE-A2.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/srs/data/reset_learning_test.dart test/features/srs/domain/reset_learning_use_cases_test.dart
```

Expected: `+15: All tests passed!`

- [ ] **Step 8: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+767: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 17 | Errors: 0 | Warnings: 0 | Info: 17` (the 17 are the UI layers'
`targets_pending`); `PASS — 0 error(s)` (the warnings are older than this plan).

- [ ] **Step 9: Commit**

```bash
git add docs/_generated \
  docs/features/srs/README.md \
  docs/features/srs/usecases/UC-SRS-001-reset-learning-progress.md \
  docs/wbs_BE.md \
  lib/features/srs/data/datasources/srs_dao.dart \
  lib/features/srs/data/repositories/schedule_repository_impl.dart \
  lib/features/srs/domain/models/reset_learning_summary_model.dart \
  lib/features/srs/domain/repositories/schedule_repository.dart \
  lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart \
  lib/features/srs/domain/usecases/reset_learning_progress_use_case.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart
git commit -F - <<'EOF'
feat(srs): add the reset summary and the two reset learning progress use cases

The confirmation of a reset reads, in one statement, the scheduler of the
tree, whether it is locked, its cards and learned cards outside the Trash
and its open sessions, and says when there is nothing to lose (UC-SRS-001
A2). ResetLearningProgressUseCase and GetResetLearningSummaryUseCase expose
UC-SRS-001 to the UI. The srs and UC-SRS-001 code fields are filled, and
wbs_BE.md records BE-A1 and BE-A2 as done.
EOF
```

Append the session's attribution trailers to the message when you commit.


## Plan self-review

- **Spec coverage.** §4 structure: Tasks 1–5 create every listed responsibility;
  the file split differs as Clarification 1 says. §5.1: Task 1. §5.2: Task 2 (five
  use cases), Task 3 (three). §5.3: Task 2 (`watchAppSettings`), Task 3
  (`watchStudyOptions`, resolution). §5.4: Tasks 2 and 3. §5.5: Task 2. §6.1:
  Task 4 (`resetLearning`), Task 5 (`resetSummary`). §6.2 and §6.3: Task 5. §7:
  Task 1 (import map); nothing else changes, as the spec says. §8: BR-STUDY-003
  (Task 1), `schema.md` (Task 3), `code:` fields (Tasks 2, 3, 5), WBS (Task 5),
  `_generated` (every task). §9: every test the spec lists, in Tasks 1–5.
- **Rule coverage (spec §1).** A test fails when one of these rules breaks:
  BR-SETTINGS-001 (Task 2: the row from the first open, one stream, and an
  error rather than made-up values when the row is gone); BR-SETTINGS-002
  (Tasks 1–2: the bounds; a save of the defaults writes no override);
  BR-SETTINGS-003 (Task 3: the override outlives new defaults, Use app defaults
  writes the root row only, and a failed one changes nothing); BR-SETTINGS-004
  (Task 2: an open session keeps its limit); BR-SETTINGS-005 and BR-SETTINGS-006
  (Tasks 1–2: the choices and their codes); BR-SETTINGS-007 (Task 2: one
  transaction, a typed failure, values that survive a reopen); BR-SETTINGS-008
  (Task 2: reset writes the settings row only); BR-STUDY-003 (Tasks 1–3);
  BR-STUDY-056 (Task 3); BR-STUDY-057 (Tasks 1–3); BR-SRS-020 to BR-SRS-024,
  BR-SRS-026, BR-SRS-027 and BR-STUDY-015 (Task 4, with the foundation's reset
  tests). BR-SRS-025, BR-SRS-028 and BR-SRS-029 stay with the schema and its
  invariant queries, which the foundation smoke test runs after a reset;
  BR-SRS-030 is UI copy, and Task 5 gives it its facts.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the
  replay compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the owning task.
