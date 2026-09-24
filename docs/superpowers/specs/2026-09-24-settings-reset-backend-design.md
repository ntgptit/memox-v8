# MemoX V8 — Settings and reset learning progress backend design

Status: decisions approved in chat 2026-09-24 · spec awaiting review · Path: architectural

## 1. Intent

Build package 1 of [`docs/wbs_BE.md`](../../wbs_BE.md): BE-A1 Settings
(UC-SETTINGS-001) and BE-A2 Reset learning progress (UC-SRS-001). The package
writes `domain/`, `data/` and `di/` only; a parallel session builds the screens
(FE-A3 and FE-A4 in [`docs/wbs_FE.md`](../../wbs_FE.md)).

Success means:

- every operation of UC-SETTINGS-001 and UC-SRS-001 is reachable through one use
  case (AD-12, ADR-011 D4);
- every rule those use cases cite that the backend owns is enforced in the domain
  or inside the writing transaction, and a test fails when the rule is broken:
  the store half of BR-SETTINGS-001…BR-SETTINGS-008, BR-STUDY-003 (bounds),
  BR-STUDY-056, BR-STUDY-057, BR-SRS-020…BR-SRS-030 and BR-STUDY-015;
- the phased gate of the root `README.md` passes after every task;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-24)

- `master` is at `532c2cf`: the foundation and the deck and card backend (#26),
  then the WBS ledgers (#27).
- `app_settings` exists in schema v1, one row by `CHECK (id = 1)`, but no code reads
  or writes it, and a fresh database has no row: `AppDatabase.migration` only turns
  on `PRAGMA foreign_keys`. UC-SETTINGS-001 assumes the row always exists.
- `deck.study_config` (TEXT, JSON, root only by `CHECK`) exists. No code reads or
  writes it, and no document defines its JSON.
- `ScheduleRepository.resetLearning(rootDeckId)` exists (foundation Task 8, Trash
  filter in #26): `generation` + 1, the start values of the root's current
  scheduler, `first_answered_at = NULL`, open sessions `invalidated` with
  `scheduler_reset`. It cannot switch the scheduler, while UC-SRS-001 steps 3 and 5
  let the person pick one during the reset. No use case exposes it.
- The V8 documents give `card_limit` a default of 20 (BR-STUDY-003) but no bounds,
  while UC-SETTINGS-001 E1 speaks of a minimum and a maximum. The pre-V8 documents
  (commit `d0b9250`, carried over from V7) state 1–200.
- UC-SETTINGS-001 (A1 and Local), IT-STUDY-013 and the V7 screen requirements
  describe a study options screen on a root deck that sets, saves and clears an
  override; no use case's main flow describes setting it.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Bounds of `card_limit` | An integer from 1 to 200, default 20. BR-STUDY-003 gains that sentence | Owner, 2026-09-24 |
| D2 | Root override | Package 1 sets, clears and resolves the override of a root deck | Owner, 2026-09-24 |
| D3 | Ownership | `settings` owns `StudyOptions`, `NewCardOrder`, the bounds, the resolver and the override writes. Dart import map: `settings → ∅`. The study feature will import `settings` | Owner, 2026-09-24 (approach A of three) |
| D4 | The settings row | When the database opens, `beforeOpen` inserts the default `app_settings` row if it is missing (insert or ignore). No schema version change | Design, approved |
| D5 | Override JSON | `{"card_limit": <int>, "new_card_order": "created" \| "random"}`. A missing key, a wrong type or a value out of bounds makes the override unreadable: the app defaults apply, and the stored text is not repaired while reading | Design, approved; IT-STUDY-013 |
| D6 | Reset to defaults | The four user values (`card_limit`, `new_card_order`, `theme_mode`, `language`) return to their defaults; `reminder_*` and `deck.study_config` are not touched. These four are every value of `app_settings` a person can set in V8.0. `reminder_last_delivered_at` is bookkeeping, never a user value (`schema.md`); whether reset also covers `reminder_enabled` and `reminder_minute_of_day` is for the reminders sub-project to decide | UC-SETTINGS-001 A3 ("cả bốn giá trị"); BR-SETTINGS-008 |
| D7 | Reset with a scheduler | `resetLearning` takes an optional scheduler type. Another type sets `scheduler_type` and `scheduler_version`; `scheduler_config` stays NULL, as `changeScheduler` leaves it | UC-SRS-001 steps 3 and 5 |
| D8 | Branch and PR | Branch `claude/be-settings-reset` from `master`. When the gate is green and the final review is clean, the package is opened as a PR and merged | Owner, 2026-09-24 |

## 4. Structure

```
lib/features/settings/                         new feature
├── domain/
│   ├── models/
│   │   ├── study_options_model.dart           StudyOptions, NewCardOrder
│   │   ├── app_settings_model.dart            AppSettings, ThemeChoice, LanguageChoice
│   │   └── effective_study_options_model.dart EffectiveStudyOptions, StudyOptionsSource
│   ├── failures/settings_failure.dart         SettingsRejection
│   ├── repositories/settings_repository.dart  contract
│   └── usecases/                              eight use cases (§5.2)
├── data/
│   ├── datasources/settings_dao.dart
│   ├── mappers/study_config_mapper.dart       D5 encode and decode
│   └── repositories/settings_repository_impl.dart
└── di/settings_repository_provider.dart

lib/features/srs/
├── domain/models/reset_learning_summary_model.dart   new
├── domain/usecases/                                  new: two use cases (§6.3)
├── domain/repositories/schedule_repository.dart      resetLearning, resetSummary
└── data/                                             DAO and implementation follow

lib/core/database/app_database.dart            beforeOpen inserts the default row (D4)
test/architecture/boundary_rules.dart          'settings': {}
```

The exact file split may move while the plan is written; the responsibilities do
not.

## 5. Settings (BE-A1)

### 5.1 Domain

- **`StudyOptions`** holds `cardLimit` and `newCardOrder`. Constants:
  `minCardLimit = 1`, `maxCardLimit = 200`, and `defaults` (20, `created`).
  `check()` returns `cardLimitOutOfRange` outside the bounds. This is the one
  definition of the bounds and of the enum (BR-SETTINGS-002); the study feature
  reuses it.
- **`NewCardOrder`** `{created, random}`, **`ThemeChoice`** `{system, light, dark}`
  and **`LanguageChoice`** `{system, en, vi}` each carry the code stored in the
  database, with a `fromCode` lookup.
- **`AppSettings`** holds the study defaults (`StudyOptions`), the theme and the
  language. The `reminder_*` columns belong to the reminders sub-project and are not
  part of it.
- **`EffectiveStudyOptions`** holds the root deck id, the options in force and their
  `source`: `appDefaults`, `rootOverride` or `unreadableRootOverride`. The UI shows
  "Use app defaults" when the source is not `appDefaults` (UC-SETTINGS-001 A1).
- **`SettingsRejection`** `{cardLimitOutOfRange, deckNotFound, notARootDeck}`.

### 5.2 Use cases — the contract for the UI

| Use case | Returns | Source |
|---|---|---|
| `WatchAppSettings()` | `Stream<AppSettings>` | UC-SETTINGS-001 step 1, E3; BR-SETTINGS-001 |
| `SaveStudyDefaults(options)` | `Outcome<void, SettingsRejection>` | Step 2, E1, E2; BR-SETTINGS-002, BR-SETTINGS-004, BR-SETTINGS-007 |
| `SetTheme(choice)` | `Outcome<void, SettingsRejection>` | Step 4; BR-SETTINGS-005 |
| `SetLanguage(choice)` | `Outcome<void, SettingsRejection>` | Step 5; BR-SETTINGS-006 |
| `ResetAppSettings()` | `Outcome<void, SettingsRejection>` | A3; BR-SETTINGS-008 |
| `WatchStudyOptions(deckId)` | `Stream<EffectiveStudyOptions?>` | A1; BR-STUDY-056; IT-STUDY-013 |
| `SaveRootStudyOptions(rootDeckId, options)` | `Outcome<void, SettingsRejection>` | Local postconditions; BR-SETTINGS-003 |
| `UseAppDefaults(rootDeckId)` | `Outcome<void, SettingsRejection>` | A1, E4; BR-SETTINGS-003 |

Theme and language take an enum, so no business reason refuses them; they still
return an `Outcome` like every other write.

### 5.3 Reads

- **`watchAppSettings`** reads the row `id = 1` and maps it; errors leave as a
  typed `Failure` through `mapDatabaseErrors()`. The row always exists (D4), so a
  missing row is a corrupt database and surfaces as an error, never as invented
  values (E3).
- **`watchStudyOptions(deckId)`** is one statement: the deck, its root through
  `root_id`, and the `app_settings` row, with every `deck` row filtered on
  `delete_batch_id IS NULL`. It emits again when the root's `study_config` or the
  settings row changes, and emits `null` when the deck does not exist or is in the
  Trash. A sub-deck reads its root's override (BR-STUDY-056).
- **Resolution:** a NULL `study_config` gives the app defaults
  (`appDefaults`); a readable one gives the override (`rootOverride`); an
  unreadable one gives the app defaults (`unreadableRootOverride`) and the stored
  text stays as it is (D5).

### 5.4 Writes

Every write is one transaction through the repository's `_write`; a rejection
writes nothing, and errors leave as a typed `Failure` (BR-SETTINGS-007).

- **Save study defaults:** `check()`, then `card_limit`, `new_card_order` and
  `updated_at`. It never writes `deck.study_config` (BR-SETTINGS-002). Sessions
  already open keep the `card_limit` they stored (BR-SETTINGS-004): nothing here
  touches `study_session`.
- **Set theme, set language:** one column and `updated_at`.
- **Reset to defaults:** the four values of D6 and `updated_at`.
- **Save root study options:** `check()`; the deck must be active
  (`deckNotFound` otherwise) and a root (`notARootDeck` otherwise); then
  `study_config` gets the D5 JSON and the root's `updated_at` changes.
- **Use app defaults:** the same two guards. An override already NULL is `Ok` and
  writes nothing; otherwise `study_config` becomes NULL and the root's `updated_at`
  changes. An unreadable override is cleared the same way: the person asked for it.
- No write here touches `card_schedule`, `review_log`, `study_session`, the
  scheduler columns or `first_answered_at` (BR-SETTINGS-003, BR-SETTINGS-008).

### 5.5 The settings row

`beforeOpen` runs, after `PRAGMA foreign_keys`, an insert-or-ignore of row `id = 1`
with the column defaults and the time of opening as `updated_at`. It runs on every
open, changes nothing once the row exists, and needs no schema version change.

## 6. Reset learning progress (BE-A2)

### 6.1 Repository

- **`resetLearning({rootDeckId, SchedulerType? schedulerType})`:** a null type, or
  the root's current one, keeps the scheduler; another type sets `scheduler_type`
  and `scheduler_version` (D7). The rest is today's behavior, in one transaction
  (BR-SRS-027): `generation` + 1 (BR-SRS-020); every schedule row of the tree back
  to the start values of the resulting scheduler at the new generation
  (BR-SRS-022, BR-CARD-004); `first_answered_at = NULL` (BR-SRS-024); every
  `in_progress` session of the tree `invalidated` with `end_reason =
  scheduler_reset` (BR-STUDY-015); `review_log`, content and tree untouched
  (BR-SRS-021, BR-SRS-023).
- This is the only way to change the scheduler once the tree is locked
  (BR-SRS-024); `ChangeDeckSchedulerUseCase` stays for unlocked trees.
- **`resetSummary(rootDeckId)`** returns
  `Outcome<ResetLearningSummary, SrsRejection>`: `notFound` when the root is
  missing or in the Trash, `notARootDeck` for a sub-deck.

### 6.2 `ResetLearningSummary`

The root's scheduler type, `isSchedulerLocked` (`first_answered_at` set), the
number of active cards in the tree, the number of learned cards among them
(`learned_at` set) and the number of `in_progress` sessions of the tree.
`hasProgressToLose` is true when a card is learned or a session is open;
UC-SRS-001 A2 says so when it is false. The confirmation's two lists are UI copy
(BR-SRS-030).

### 6.3 Use cases

`ResetLearningProgressUseCase(rootDeckId, schedulerType?)` and
`GetResetLearningSummaryUseCase(rootDeckId)`, in a new
`lib/features/srs/domain/usecases/`. UC-SRS-001 is the one use case `srs` owns:
answering belongs to study, and changing the scheduler of an unlocked tree belongs
to deck (UC-DECK-002).

## 7. Import map and tooling

- `test/architecture/boundary_rules.dart` gains `'settings': {}`.
- `verification_impact_map.json` already lists `settings`; no `.drift` query file
  is added, so it does not change.
- No guard rule waits on these layers; the `targets_pending` list does not change.

## 8. Documentation

- **BR-STUDY-003:** the sentence of D1. The owner allowed this one BR file to
  change.
- **`schema.md`:** the note of `deck.study_config` states the D5 shape and that an
  unreadable override means the app defaults, never repaired on read.
- **`code:`** of UC-SETTINGS-001, UC-SRS-001 and the settings and srs READMEs. The
  srs README loses its stale "no `lib/`" line (part of BE-D3).
- **`docs/wbs_BE.md`:** BE-A1 and BE-A2 become `xong`; BE-D3 records the srs part.
- **`docs/_generated/`** is regenerated, since tests will name the use case ids.

## 9. Verification

- Test first in every task; the five-command gate and `tools/docs/check.py` after
  every task.
- **Settings:**
  - bounds 1 and 200 accepted, 0 and 201 refused;
  - the D5 codec, including every unreadable shape;
  - the stream emits once per save;
  - each save changes only its own columns, and reset to defaults only the four
    values of D6;
  - the effective options for a root, a sub-deck, a missing deck, a deck in the
    Trash and an unreadable override (IT-STUDY-013: the stored text is unchanged
    after reading);
  - override saved and cleared; a clear with no override writes nothing;
  - a sub-deck refused;
  - a freshly opened database holds exactly one settings row;
  - values survive closing and reopening a database file (IT-STUDY-008, host
    half).
- **Reset:**
  - reset keeping the scheduler, and switching sm2 ↔ eight_box (type, version,
    start values);
  - `generation` + 1, `first_answered_at` NULL, the old `review_log` rows kept at
    their generation;
  - an open session `invalidated` (IT-CONT-009, host half);
  - a sub-deck, a missing root and a root in the Trash refused;
  - the summary of a new tree (nothing to lose), after cards are learned, and with
    an open session.
- **Final review:** a whole-branch review by an independent reviewer; Critical
  and Important findings are fixed test first before the PR.

## 10. Coordination with the UI session

- New contract for FE-A3 and FE-A4: the use cases of §5.2 and §6.3, and the
  providers in `di/`.
- Shared files touched: `test/architecture/boundary_rules.dart` (one line) and
  `lib/core/database/app_database.dart` (`beforeOpen`). Both edits are additive.

## 11. Out of scope

- Screens, controllers and ARB strings; applying the theme and the language in
  `app.dart` (FE-A3); ignoring a second tap while a save runs (UC-SETTINGS-001 A4,
  a controller concern).
- The `reminder_*` columns (the reminders sub-project).
- A one-shot read of the effective options for opening a session: BE-A4 adds it
  when it has a caller.
- `scheduler_config`: no V8 scheduler takes a configuration.

## 12. Risks and rollback

- **A write on every open:** one insert-or-ignore statement. Rollback: move it to
  `onCreate` with a migration for existing files.
- **A new JSON shape:** only this package writes `study_config`, and no data exists
  yet; changing the shape later needs a data migration.
- **`resetLearning` gains a parameter:** optional, so existing callers compile; its
  callers and tests change in the same commit.
