# MemoX V8 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MemoX V8 foundation: a runnable Flutter skeleton with the
core data model, pure-Dart SRS schedulers, deck-tree rules and their
transactional invariants, all guarded by tests. No product UI.

**Architecture:** Feature-first single package. Per [ADR-010](../../shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md)
and ADR-011 (`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`), each
feature folder is `lib/features/<f>/` with layers `domain/`, `data/` and `di/`,
and every file sits in a bucket of its layer: `domain/{entities,models,repositories,failures}/`,
`data/{datasources,repositories}/`, and a flat `di/` for the Riverpod providers.
`presentation/` and `domain/usecases/` are not created in this plan: there is no
product UI, so there is no interaction for AD-12 to wrap. `domain/` is pure Dart:
no Flutter, no Drift. A feature's public surface is its
`domain/{entities,models,repositories,failures}/`, imported file by file; there are
no barrels. Drift tables and named queries live centrally in
`lib/core/database/{tables,queries}` per
[`flutter-drift/references/project-baseline.md`](../../../.claude/skills/flutter-drift/references/project-baseline.md);
`core/database` assembles them into one `AppDatabase`. A repository
implementation runs every write inside one Drift transaction. A repository
contract has exactly one implementation, which is deliberate (ADR-010's
"concrete architectural reason"), not a speculative interface. A folder is
created only when it holds a real file.

**Prerequisite:** [`2026-09-23-v8-folder-architecture.md`](2026-09-23-v8-folder-architecture.md)
is complete. Its tooling is what this plan's gate runs: the ADR-011 rules in
`test/architecture/`, `check_architecture.py` without per-layer zero scopes, and
the guard's `targets_pending` waiting list.

**Tech Stack:** Flutter 3.47.5 (Dart SDK 3.13.4), pinned in `.fvmrc`.
`flutter_riverpod` 3.4.3 + `riverpod_annotation` 4.0.7 + `riverpod_generator`
4.0.9, `drift` / `drift_dev` 2.35.0, `drift_flutter` 0.3.1, `sqlite3` 3.6.0,
`go_router` 18.0.1, `uuid` 4.6.0, `build_runner` 2.16.1. See "Package
versions" below for per-package Dart SDK constraints and the check date.

**Spec:** `docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md`,
as amended by [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)
(scope) and [ADR-010](../../shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md)
(layering, folder names, Flutter version). Data model authority:
[`docs/shared/data/schema.md`](../../shared/data/schema.md).
Tasks 7–9 also carry stage 1 of
[`2026-09-23-deck-card-backend-design.md`](../specs/2026-09-23-deck-card-backend-design.md)
(§4): the sibling position of a new or moved deck, the start values of a
schedule row, the scheduler change and the reset, and a card created with its
schedule row.

This plan replaces `docs/superpowers/plans/2026-09-21-memox-v8-foundation.md`,
which is kept as history and must not be executed.

## Global Constraints

Every task's requirements implicitly include these.

- Android is the only release target; local-only; no network; no auth.
- State: Riverpod 3 + `riverpod_generator` (codegen). No freezed: models are
  plain Dart 3 classes / `sealed` / records, so codegen is only Riverpod +
  Drift.
- Database: Drift/SQLite is the single source of truth; IDs are
  client-generated UUIDs (ADR-007); datetimes are stored as UTC (ADR-008).
- Structure (ADR-011): `lib/{main.dart, app/, core/<concern>/, features/<f>/{domain,data,di}}`,
  `<f>` from ADR-010's list, snake_case, matching `docs/features/`. Every
  feature file sits in a bucket of its layer (`domain/{entities,models,repositories,failures}/`,
  `data/{datasources,repositories}/`; `di/` is flat) and carries the file suffix
  the guard expects (`_entity`, `_model`, `_scheduler`, `_repository`, `_failure`,
  `_dao`, `_repository_impl`, `_provider`). A folder is created only when it
  holds a real file.
- Imports between features (ADR-011): only another feature's
  `domain/{entities,models,repositories,failures}/` files, plus its `di/` from a
  `di/` file; never its `data/`; no barrels. The import map is `srs → ∅`,
  `deck → {srs}`, `card → {deck, srs}` (`test/architecture/boundary_rules.dart`).
- Drift tables and named `.drift` queries are central in
  `lib/core/database/{tables,queries}`, never per-feature. DAOs are
  feature-owned, under `lib/features/<f>/data/datasources/`.
- A DAO writes through Drift's table API (`into`, `update`, `delete`) or
  `customInsert` / `customUpdate` with `updates:`, never `customStatement`:
  only those tell Drift's `watch()` streams that a table changed, and the read
  models of the deck/card backend spec are streams. `customStatement` stays for
  pragmas and test fixtures.
- `domain/` is pure Dart: no `package:flutter`, no `package:drift`, no
  `package:memox/core/database/`.
- `SrsScheduler` is the only cross-implementation interface in this plan (two
  real implementations: `eight_box`, `sm2`). A repository contract with one
  implementation is accepted only for the "domain stays framework-free, tests
  substitute fakes" reason in ADR-010 — not for "maybe later".
- Depth is at most 10 (root is level 1, `CHECK (depth <= 10)`, invariant 15).
  A root deck holds only sub-decks (invariant 1, 4). Emptying a sub-deck sets
  it back to `unset` in the same transaction (invariant 29). Moving a subtree
  under a root with a different scheduler or generation is blocked, never
  converted.
- `root_id` is a stored column on every deck, resolved once at write time;
  `COALESCE(parent_id, id)` is forbidden (BR-DECK-003, invariant 6/7).
- Scheduler and generation are stored only on the root deck (invariant 10,
  11); descendants resolve them through `root_id`.
- The scheduler is locked after the first review (`first_answered_at` set,
  invariant 30); changing it needs Reset learning progress. Reset increments
  `generation`. A write from a stale-`generation` session is rejected, never
  applied (BR-SRS-026, BR-STUDY-017).
- `review_log.kind`, `study_session.status` / `end_reason` are stored, never
  inferred (invariant 12, 26).
- Expected business rejections return `Outcome<T, R>`'s `Ok` /
  `Rejected(reason)`, not exceptions. `R` is the refusing feature's own reason
  enum in its `domain/failures/`: `DeckRejection`, `SrsRejection`,
  `CardRejection` (ADR-011 D6). Unexpected DB errors are mapped in one place
  (`lib/core/error/failure.dart`) into `Failure` subtypes. Riverpod auto-retry
  is disabled for DB errors.
- Card content, notes, history and exports are never logged at any level.
- Verification gate: the phased gate in `README.md` (ADR-011), after
  `dart run build_runner build --delete-conflicting-outputs` —
  `flutter analyze`, `flutter test`,
  `python3 .claude/skills/flutter-architecture/scripts/check_architecture.py`,
  `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'`
  and `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`.
  Every "Gate and commit" step below runs all five. When the guard reports
  `guard.config.stale_targets_pending` for a rule, the task just added the layer
  that rule waited for: delete the rule's entry from
  `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
  in the same commit (Tasks 3, 5, 7 and 10 name the entries). Generated
  `*.g.dart` files are not committed.

## Package versions (checked 2026-09-23)

Checked against `https://pub.dev/api/packages/<name>` (`latest.version`,
`latest.pubspec.environment`) and
`https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`
(`dart_sdk_version` for `version: 3.47.5`) on 2026-09-23. These are the same
versions the superseded 2026-09-21 plan pinned — nothing published in
between — re-verified here because the Flutter/Dart floor changed.

| Package | Version | `environment.sdk` | `environment.flutter` | Why it's here |
|---|---|---|---|---|
| Flutter | 3.47.5 | — | — | Pinned by ADR-010 decision 3, in `.fvmrc` |
| Dart | 3.13.4 | — | — | Bundled with Flutter 3.47.5 (`dart_sdk_version`) |
| `flutter_riverpod` | 3.4.3 | `^3.12.0` | `>=3.0.0` | State management (spec §3) |
| `riverpod_annotation` | 4.0.7 | `^3.12.0` | — | Codegen annotations for providers |
| `riverpod_generator` | 4.0.9 (dev) | `^3.12.0` | — | Generates provider boilerplate from `riverpod_annotation` |
| `drift` | 2.35.0 | `>=3.10.0 <4.0.0` | — | Typed SQLite access, single source of truth (spec §3) |
| `drift_dev` | 2.35.0 (dev) | `>=3.10.0 <4.0.0` | — | Generates `AppDatabase` code from `.drift` files |
| `drift_flutter` | 0.3.1 | `>=3.10.0 <4.0.0` | — | `driftDatabase()` helper: background isolate on native |
| `sqlite3` | 3.6.0 | `>=3.10.0 <4.0.0` | — | Native SQLite bindings Drift needs at runtime |
| `go_router` | 18.0.1 | `^3.12.0` | `>=3.44.0` | Routing (spec §3); satisfied by 3.47.5 |
| `uuid` | 4.6.0 | `>=3.0.0 <4.0.0` | — | Client-generated UUID primary keys (ADR-007) |
| `build_runner` | 2.16.1 (dev) | `^3.11.0` | — | Runs `drift_dev` + `riverpod_generator` |

Dart SDK 3.13.4 satisfies every constraint above (the tightest floor is
`^3.12.0`). No package needed a version bump for the 3.44.8 → 3.47.5 jump.
If a future `flutter pub get` reports a resolution conflict, lower the
offending package to the newest version that resolves and note it in the
commit message — this table is a floor, not a promise that nothing will move
before Task 1 runs.

`freezed`, `json_serializable`, `flutter_lints` beyond the default, `dio`,
and any HTTP client are deliberately not added: no networking (ADR-001), no
DTOs to serialize, no freezed per spec §3.

## Clarifications to confirm during plan review

The spec, ADR-009, ADR-010 and schema.md are silent or ambiguous on these;
the plan makes the smallest defensible choice and flags it. Items with an
**OPEN QUESTION** line are the ones raised for review; the rest are decisions
made and recorded so review can push back on them, not gaps.

1. **Which of schema.md's 9 central tables are created in this plan.**
   schema.md marks each table's scope. `deck`, `card`, `card_schedule`,
   `review_log` are unscoped (i.e. V8.0) and are the core data model the
   spec names — created now, with full Dart repository/domain code.
   `study_session` and `study_queue_items` are explicitly "**Phạm vi:** V8.0"
   — created now as schema (all columns, all `CHECK`s, all invariant tests)
   because `review_log.session_id` and the stale-generation rejection the
   spec requires both need `study_session` to exist, but **no repository, DAO
   or use case is written for them here**: the session/queue write path
   (opening a session, building rounds, answering) is session/study business
   logic, owned by the core-learning-slice sub-project (spec §2,
   decomposition item 3). One write reaches `study_session` anyway:
   `ScheduleRepository.changeScheduler` and `resetLearning` close the root's
   `in_progress` sessions as `invalidated` in their own transaction
   (BR-STUDY-015, BR-STUDY-016; deck/card backend spec §4), through the srs DAO
   that already reads `study_session.generation` for `recordReview` (Task 8).
   `app_settings` is explicitly "**Phạm vi:** V8.0"
   too — created now as schema only, same reasoning, owned by the future
   `settings` feature. `tags` and `card_tags` are V8.0 for tagging a card
   (ADR-009 decision 4; schema.md updated on 2026-09-23 to match) — created
   now as schema only (all columns, the unique `(COALESCE(owner_id, ''), name_folded)`
   index, both cascading FKs); the tag/untag write path is the
   core-learning-slice's card feature. Tag Management (UC-TAG-001) stays a
   later sub-project. **Resolved 2026-09-23 (project owner):** follow
   ADR-009 and create the tables in this plan.
2. **`deck_templates` and `delete_batches` do not exist yet** — they belong
   to `docs/features/starter-decks/data.md` and `docs/features/trash/data.md`,
   owned by their own sub-projects, and schema.md is explicit that
   feature-only tables live in those files, not here. `deck.delete_batch_id`,
   `card.delete_batch_id`, `deck.source_template_id`, `deck.source_template_version`,
   `deck.owner_id` are still added now, as plain nullable columns **without**
   a foreign key (the target table does not exist), because schema.md says
   these columns are kept in the owning table now "để nghiệp vụ không phải
   đào lại" (so the business logic doesn't have to be re-derived later). The
   FK constraint is added by the sub-project that creates the referenced
   table, as a migration. No Dart code reads or writes these columns in this
   plan.
   **Resolved 2026-09-23 (project owner):** add these columns now, nullable
   and without a FK; the FK arrives with the sub-project that creates the
   referenced table.
3. **Public surface of a feature** is its `domain/{entities,models,repositories,failures}/`,
   imported file by file (ADR-011 D3). There are no barrel files: a barrel that
   re-exported `di/` would pull Riverpod and Drift into a dependent feature's
   `domain/`. Another feature's `di/` is imported only from a `di/` file (and,
   later, from `presentation/`). Pure rules are static members of the entity
   (ADR-011 D7), so they travel with it. Enforced by
   `test/architecture/boundaries_test.dart`.
4. **`srs` depends on no feature** at the Dart level (spec §4). Its *tables*
   reference `card` (foreign key), a schema relationship, not a Dart import.
   The boundary test checks Dart imports only.
5. **`deck` imports `srs`'s `domain/models/scheduler_type_model.dart`**, to
   type the scheduler chosen when a root deck is created (`SchedulerType`). The
   Dart import map is `srs → ∅`, `deck → {srs}`, `card → {deck, srs}`; a future
   `study`/`progress` adds its edges in the commit that creates it. It is the
   contract direction and may differ from `depends_on` in the docs, which is the
   data direction (ADR-011 D2).
6. **Moving a root deck is rejected** (`DeckRejection.rootCannotMove`). The
   spec only describes moving sub-deck subtrees.
7. **Blank deck names and blank card front/back are rejected**
   (`DeckRejection.blankName`, `CardRejection.blankContent`) — a
   trust-boundary check the spec implies but does not spell out.
8. **Application id** is `com.memox.memox` (from
   `flutter create --project-name memox --org com.memox`). Change before the
   first release build if another id is wanted.
9. **Repositories take an optional `now` clock** parameter instead of a
   global `core/clock`, because only repositories that touch time need it
   and the SRS domain functions already receive `now` as an argument.
10. **Repositories are exposed through Riverpod providers** in each
    feature's `di/` folder, one file per repository:
    `deck/di/deck_repository_provider.dart` (`deckRepositoryProvider`),
    `srs/di/schedule_repository_provider.dart` (`scheduleRepositoryProvider`),
    `card/di/card_repository_provider.dart` (`cardRepositoryProvider`). Each
    provider constructs its implementation directly; there is no `app/di/`.
    This is what makes `di/` a real folder in this plan, not a speculative one.
11. **`DATETIME` storage mode**: no `build.yaml` is added in this plan, so
    Drift's default (Unix epoch seconds, UTC assumed at the Dart boundary)
    applies, per `flutter-drift/references/project-baseline.md`. Pinning the
    mode explicitly is deferred to when a backend is designed, per that
    skill's own note.
12. **`current_mode` and `session_kind` enum values on `study_session`** are
    written into the `CHECK` constraint from schema.md verbatim
    (`browse`, `self_assess`, `match`, `guess`, `recall`, `fill`;
    `learning`, `reviewing`) even though this plan writes no code that
    produces those values — the table must accept exactly the domain
    schema.md defines from day one, so a later migration is not needed just
    to loosen a `CHECK`.
13. **The scheduler a root already runs is a no-op, even on a locked tree**
    (Task 8). BR-SRS-002 makes that choice a no-op with no condition, and a
    request that changes nothing breaks no lock, so `changeScheduler` answers
    `Ok` before it looks at `first_answered_at`.
14. **`resetLearning` of a sub-deck answers `SrsRejection.notARootDeck`**, as
    `changeScheduler` does (deck/card backend spec §4). The generation and the
    scheduler live on the root (BR-DECK-025); without the check, the sub-deck's
    `root_id` would reach every schedule row of the tree while the root's
    generation stays as it is.
15. **Known gap, owned by the core-learning slice: the new-card branch of the
    schedulers** (Tasks 3, 4, 8). BR-STUDY-053 makes finishing the new-card
    chain an event, not a review: until then `card_schedule` does not change,
    and the event sets `learned_at`, the lowest level (`eight_box` box 1, `sm2`
    interval 1) and `due_at` at the next local midnight, with no `scheduled`
    log. This plan's `recordReview` instead moves a new card on its first
    `remembered`/`good` (box 2, interval 1) and sets `learned_at` without
    `due_at`, which breaks invariant 24 (BR-STUDY-058) until the card's next
    review. It stays as written (project owner, 2026-09-23): nothing calls
    `recordReview` before the study sub-project, and the deck/card backend
    reads schedule rows without writing reviews. The study sub-project
    replaces the branch and adds the completion event (`completeLearning`,
    schema.md invariant 30). For the same reason Task 5's `CHECK` holds
    invariant 28 only. Running Tasks 3–4 showed that the review branch
    differs too, and it stays as written for the same reason: a `forgotten`
    scheduled review keeps its box here, where BR-SRS-008 sends it to box 1
    and reschedules it; `sm2`'s `again` is `q = 2` here and `q = 0` in
    BR-SRS-010; and the scheduler derives `kind` from the state, where
    BR-SRS-017/018 let the session say which turn is `relearning`, so a lapse
    is counted on the `forgotten`/`again` of a learned card.

## Review Focus

Inputs the spec implies but its rules do not spell out. Each line has a test
in the named task.

1. Blank or whitespace-only deck name / card text is rejected, not stored
   (Tasks 7, 9).
2. An action the deck's scheduler does not support (e.g. `hard` on an
   `eight_box` deck) is rejected, not applied (Task 8).
3. Moving a deck onto itself or into its own descendant is rejected and
   changes nothing (Task 7).
4. Reviewing a card that was deleted mid-session returns `notFound` and does
   not crash or write a log row (Task 8).
5. Due-date calculation across a month and year end (`eight_box` box 8, 128
   days) lands on local midnight of the right day (Task 3).

## File Structure

One path per line; every `lib/` file sits in an ADR-011 bucket.

```
.fvmrc                                                     {"flutter": "3.47.5"}
pubspec.yaml, analysis_options.yaml, README.md
drift_schemas/drift_schema_v1.json                         schema snapshot
lib/main.dart                                              ProviderScope(retry: noRetry) + runApp
lib/app/app.dart                                           MemoxApp
lib/app/router/app_router.dart                             placeholder route
lib/core/id/new_id.dart                                    newId()
lib/core/error/outcome.dart                                Outcome<T, R> / Ok / Rejected
lib/core/error/failure.dart                                Failure + mapDatabaseError
lib/core/database/app_database.dart                        AppDatabase (assembles tables/)
lib/core/database/connection.dart                          driftDatabase(), the only file that opens a DB
lib/core/database/tables/deck.drift, card.drift, tags.drift, srs.drift, study.drift, settings.drift
lib/core/database/queries/                                 added only when a task needs a named query
lib/core/database/di/database_provider.dart                databaseProvider (codegen, keepAlive)
lib/features/srs/domain/models/review_kind_model.dart
lib/features/srs/domain/models/due_date_model.dart
lib/features/srs/domain/models/scheduler_type_model.dart
lib/features/srs/domain/models/review_action_model.dart
lib/features/srs/domain/models/srs_scheduler.dart
lib/features/srs/domain/models/card_schedule_state_model.dart
lib/features/srs/domain/models/review_log_entry_model.dart
lib/features/srs/domain/models/eight_box_scheduler.dart
lib/features/srs/domain/models/sm2_scheduler.dart
lib/features/srs/domain/models/schedulers_model.dart
lib/features/srs/domain/failures/srs_failure.dart
lib/features/srs/domain/repositories/schedule_repository.dart
lib/features/srs/data/datasources/srs_dao.dart
lib/features/srs/data/repositories/schedule_repository_impl.dart
lib/features/srs/di/schedule_repository_provider.dart      scheduleRepositoryProvider
lib/features/deck/domain/entities/deck_entity.dart         DeckEntity + its tree rules
lib/features/deck/domain/models/deck_content_type_model.dart
lib/features/deck/domain/failures/deck_failure.dart
lib/features/deck/domain/repositories/deck_repository.dart
lib/features/deck/data/datasources/deck_dao.dart
lib/features/deck/data/repositories/deck_repository_impl.dart
lib/features/deck/di/deck_repository_provider.dart         deckRepositoryProvider
lib/features/card/domain/entities/card_entity.dart         CardEntity + checkContent
lib/features/card/domain/failures/card_failure.dart
lib/features/card/domain/repositories/card_repository.dart
lib/features/card/data/datasources/card_dao.dart
lib/features/card/data/repositories/card_repository_impl.dart
lib/features/card/di/card_repository_provider.dart         cardRepositoryProvider
test/architecture/boundaries_test.dart, boundary_rules.dart, boundary_rules_test.dart
test/core/<concern>/**, test/features/<f>/{domain,data}/**, test/database/**,
test/integration/**, test/app/**, test/support/test_database.dart
```

`study/`, `settings/`, `tags/` are not created (no Dart file in this plan —
see Clarification 1). `progress/` is not created. `presentation/` and
`domain/usecases/` are not created in any feature (no product UI, so no
interaction for AD-12 to wrap).

---

### Task 1: Toolchain, project skeleton and boundary guard

> **Done before ADR-011, partly superseded.** This task ran as written. Its
> `test/architecture/boundaries_test.dart` (barrel rule, three-feature purity
> list) is replaced by the ADR-011 rules in `test/architecture/boundary_rules.dart`,
> and its `README.md` gate by the phased gate, both in
> [`2026-09-23-v8-folder-architecture.md`](2026-09-23-v8-folder-architecture.md).
> The steps below are kept as the record of what ran; do not re-run them.

**Files:**
- Create: `.fvmrc`, Flutter project files at the repo root (via
  `flutter create`), `README.md`, `analysis_options.yaml`,
  `test/architecture/boundaries_test.dart`
- Modify: `pubspec.yaml`, `.gitignore`

**Interfaces:**
- Produces: a green `flutter analyze` + `flutter test` baseline; `.fvmrc`
  pinning Flutter 3.47.5; `test/architecture/boundaries_test.dart` enforcing
  the layering and import rules every later task must respect.

- [ ] **Step 1: Pin the Flutter version**

Create `.fvmrc`:

```json
{
  "flutter": "3.47.5"
}
```

Run: `.claude/skills/flutter-workflow/scripts/check_flutter_version.sh`
Expected: `✗ .fvmrc pins Flutter 3.47.5 but no flutter is on PATH` (if Flutter
isn't installed yet) or `Flutter 3.47.5 matches .fvmrc`. If a different
version is on PATH, switch to 3.47.5 (`fvm use 3.47.5` or your toolchain's
equivalent) before continuing — do not edit `.fvmrc` to match the installed
version.

- [ ] **Step 2: Scaffold the project in place**

`CLAUDE.md` and `docs/` already exist; `flutter create` leaves them alone.

```bash
flutter create . --project-name memox --org com.memox --platforms android --empty
```

Expected: `lib/main.dart`, `android/`, `pubspec.yaml`, `analysis_options.yaml`
created.

- [ ] **Step 3: Add dependencies**

```bash
flutter pub add flutter_riverpod:^3.4.3 riverpod_annotation:^4.0.7 go_router:^18.0.1 drift:^2.35.0 drift_flutter:^0.3.1 sqlite3:^3.6.0 uuid:^4.6.0
flutter pub add --dev build_runner:^2.16.1 drift_dev:^2.35.0 riverpod_generator:^4.0.9
flutter pub get
```

Expected: `Got dependencies!`. If resolution fails, follow the note under
"Package versions".

- [ ] **Step 4: Replace `analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "**/*.g.dart"

linter:
  rules:
    always_use_package_imports: true
    avoid_print: true
    prefer_const_constructors: true
```

`always_use_package_imports` is what makes the boundary test reliable: every
import is a `package:memox/...` path.

- [ ] **Step 5: Ignore generated code**

Append to `.gitignore`:

```
# generated by build_runner
*.g.dart
```

- [ ] **Step 6: Write `README.md`**

````markdown
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
````

- [ ] **Step 7: Write the failing boundary test**

Create `test/architecture/boundaries_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Which other features each feature may import (through its barrel only).
const _allowedFeatureImports = <String, Set<String>>{
  'deck': {'srs'},
  'srs': {},
  'card': {'deck', 'srs'},
};

/// Layers that must stay free of Flutter, Riverpod and Drift.
const _pureFolders = [
  'lib/features/srs/domain/',
  'lib/features/deck/domain/',
  'lib/features/card/domain/',
];

const _forbiddenInPure = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod_annotation/',
  'package:drift/',
  'package:memox/core/database/',
];

const _featurePrefix = 'package:memox/features/';

class _Source {
  _Source(this.path, this.imports);
  final String path;
  final List<String> imports;
}

List<_Source> _sources() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return const [];
  return [
    for (final file in dir.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
        _Source(
          file.path.replaceAll(r'\', '/'),
          [
            for (final m in _importPattern.allMatches(file.readAsStringSync()))
              m.group(1)!,
          ],
        ),
  ];
}

/// `lib/features/<name>/...` -> `<name>`, otherwise null.
String? _featureOf(String path) {
  const prefix = 'lib/features/';
  if (!path.startsWith(prefix)) return null;
  return path.substring(prefix.length).split('/').first;
}

/// `lib/features/<name>/domain/...` -> true (data/di may see Drift/Riverpod).
bool _isPresentationOrDataOnlyLayer(String path) =>
    path.contains('/data/') || path.contains('/di/');

void main() {
  final sources = _sources();

  test('domain layers import no Flutter, Riverpod, Drift or core/database', () {
    final violations = [
      for (final s in sources)
        if (_pureFolders.any(s.path.startsWith))
          for (final i in s.imports)
            if (_forbiddenInPure.any(i.startsWith)) '${s.path} imports $i',
    ];
    expect(violations, isEmpty);
  });

  test('features import other features only through an allowed barrel', () {
    final violations = <String>[];
    for (final s in sources) {
      final own = _featureOf(s.path);
      if (own == null) continue;
      for (final i in s.imports) {
        if (!i.startsWith(_featurePrefix)) continue;
        final rest = i.substring(_featurePrefix.length);
        final target = rest.split('/').first;
        if (target == own) continue;
        final allowed = _allowedFeatureImports[own] ?? const <String>{};
        if (!allowed.contains(target)) {
          violations.add('${s.path} may not depend on feature $target');
        } else if (rest != '$target/$target.dart') {
          violations.add('${s.path} must import $target via its barrel: $i');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('app and core never import feature internals', () {
    final violations = [
      for (final s in sources)
        if (s.path.startsWith('lib/app/') || s.path.startsWith('lib/core/'))
          for (final i in s.imports)
            if (i.startsWith(_featurePrefix) &&
                !RegExp(r'^package:memox/features/(\w+)/\1\.dart$').hasMatch(i))
              '${s.path} imports $i',
    ];
    expect(violations, isEmpty);
  });

  test('no file sits directly under a feature\'s data or di folder without a layer subfolder', () {
    // Guards the ADR-010 shape: data/{repositories,datasources}, di/ providers only.
    final violations = [
      for (final s in sources)
        if (_featureOf(s.path) != null && _isPresentationOrDataOnlyLayer(s.path))
          if (s.path.endsWith('/data/${_featureOf(s.path)}_repository_impl.dart') == false &&
              !RegExp(r'/data/(repositories|datasources|mappers)/').hasMatch(s.path) &&
              !RegExp(r'/di/').hasMatch(s.path))
            s.path,
    ];
    expect(violations, isEmpty);
  });
}
```

Note the third test lets `app/` and `core/` import a barrel (`core/database`
needs none in this task; `app/` will import barrels in Task 10) but never
internals. The fourth test is the mechanical half of ADR-010's `data/` /
`di/` shape.

- [ ] **Step 8: Run it (baseline passes)**

Run: `flutter test test/architecture/boundaries_test.dart`
Expected: PASS (4 tests), since `lib/` has only `main.dart`.

- [ ] **Step 9: Prove the guard can fail**

Create `lib/features/srs/domain/bad.dart`:

```dart
import 'package:flutter/material.dart';
```

Run: `flutter test test/architecture/boundaries_test.dart`
Expected: FAIL, message
`lib/features/srs/domain/bad.dart imports package:flutter/material.dart`.

Then delete the file: `rm lib/features/srs/domain/bad.dart` (and the
now-empty folders).

- [ ] **Step 10: Run the full gate**

```bash
flutter analyze
flutter test
```

Expected: no analyzer issues; tests pass. If the generated `lib/main.dart`
triggers a lint, fix it in place.

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter project, pin toolchain, add boundary guard" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 2: Core primitives (id, outcome, failure mapping)

**Files:**
- Create: `lib/core/id/new_id.dart`, `lib/core/error/outcome.dart`, `lib/core/error/failure.dart`
- Test: `test/core/id/new_id_test.dart`, `test/core/error/outcome_test.dart`, `test/core/error/failure_test.dart`

**Interfaces:**
- Produces:
  - `String newId()` — a v4 UUID string.
  - `sealed class Outcome<T, R extends Enum>`,
    `final class Ok<T, R extends Enum> extends Outcome<T, R> { T value; }`,
    `final class Rejected<T, R extends Enum> extends Outcome<T, R> { R reason; }`.
    `core/` names no reason: each feature declares its own enum in its
    `domain/failures/` (ADR-011 D6) — `DeckRejection` (Task 6),
    `SrsRejection` (Task 8), `CardRejection` (Task 9).
  - `sealed class Failure { String message; Object? cause; }`,
    `final class ConstraintFailure extends Failure {}`,
    `final class DatabaseLockedFailure extends Failure {}`,
    `final class UnknownDatabaseFailure extends Failure {}`.
  - `Failure mapDatabaseError(Object error)`.

- [ ] **Step 1: Write the failing id test**

`test/core/id/new_id_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/id/new_id.dart';

void main() {
  test('newId returns a v4 UUID and two calls differ', () {
    final a = newId();
    final b = newId();
    expect(a, isNot(equals(b)));
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'),
      allOf(hasMatch(a), hasMatch(b)),
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/id/new_id_test.dart`
Expected: FAIL — `lib/core/id/new_id.dart` does not exist.

- [ ] **Step 3: Implement `newId`**

`lib/core/id/new_id.dart`:

```dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A client-generated UUID v4, per ADR-007.
String newId() => _uuid.v4();
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/core/id/new_id_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing outcome test**

`test/core/error/outcome_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';

enum _Reason { tooDeep }

void main() {
  test('Ok carries a value, Rejected carries a typed reason', () {
    const Outcome<int, _Reason> ok = Ok(1);
    const Outcome<int, _Reason> rejected = Rejected(_Reason.tooDeep);

    expect(switch (ok) {
      Ok(:final value) => value,
      Rejected() => -1,
    }, 1);
    expect(switch (rejected) {
      Ok() => null,
      Rejected(:final reason) => reason,
    }, _Reason.tooDeep);
  });
}
```

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test test/core/error/outcome_test.dart`
Expected: FAIL — `lib/core/error/outcome.dart` does not exist.

- [ ] **Step 7: Implement `Outcome`**

`lib/core/error/outcome.dart`:

```dart
/// The result of an operation that can be legitimately refused. Not an
/// exception: a `Rejected` is an expected outcome the caller must handle.
///
/// [R] is the refusing feature's own reason enum (ADR-011 D6), so `core/`
/// names no business reason and a switch over [R] stays exhaustive.
sealed class Outcome<T, R extends Enum> {
  const Outcome();
}

final class Ok<T, R extends Enum> extends Outcome<T, R> {
  const Ok(this.value);
  final T value;
}

final class Rejected<T, R extends Enum> extends Outcome<T, R> {
  const Rejected(this.reason);
  final R reason;
}
```

- [ ] **Step 8: Run to verify it passes**

Run: `flutter test test/core/error/outcome_test.dart`
Expected: PASS.

- [ ] **Step 9: Write the failing failure-mapping test**

`test/core/error/failure_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('a CHECK/foreign key violation maps to ConstraintFailure', () {
    final failure = mapDatabaseError(
      sqlite3.SqliteException(275, 'CHECK constraint failed: depth'),
    );
    expect(failure, isA<ConstraintFailure>());
    expect(failure.cause, isNotNull);
  });

  test('SQLITE_BUSY maps to DatabaseLockedFailure', () {
    final failure = mapDatabaseError(
      sqlite3.SqliteException(5, 'database is locked'),
    );
    expect(failure, isA<DatabaseLockedFailure>());
  });

  test('anything else maps to UnknownDatabaseFailure and never leaks card content', () {
    final failure = mapDatabaseError(StateError('front: "私の秘密"'));
    expect(failure, isA<UnknownDatabaseFailure>());
    expect(failure.message, isNot(contains('私の秘密')));
  });
}
```

- [ ] **Step 10: Run to verify it fails**

Run: `flutter test test/core/error/failure_test.dart`
Expected: FAIL — `lib/core/error/failure.dart` does not exist.

- [ ] **Step 11: Implement `Failure` and `mapDatabaseError`**

`lib/core/error/failure.dart`:

```dart
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Unexpected failures from the database boundary. Never rendered directly —
/// [message] is safe to show, [cause] is for logs only and must never
/// contain card content (card content is never logged, per CLAUDE.md /
/// the spec's error rules).
sealed class Failure {
  const Failure({required this.message, this.cause});
  final String message;
  final Object? cause;
}

final class ConstraintFailure extends Failure {
  const ConstraintFailure({required super.cause})
      : super(message: 'That change breaks a data rule.');
}

final class DatabaseLockedFailure extends Failure {
  const DatabaseLockedFailure({required super.cause})
      : super(message: 'The database is busy. Try again.');
}

final class UnknownDatabaseFailure extends Failure {
  const UnknownDatabaseFailure({required super.cause})
      : super(message: 'Something went wrong.');
}

/// Maps a raw exception from the Drift/sqlite3 boundary to one [Failure].
/// This is the single place that inspects driver-specific error shapes —
/// no repository does this itself.
Failure mapDatabaseError(Object error) {
  if (error is sqlite3.SqliteException) {
    if (error.extendedResultCode == 275 /* SQLITE_CONSTRAINT_CHECK-ish */ ||
        error.message.toLowerCase().contains('constraint')) {
      return ConstraintFailure(cause: error);
    }
    if (error.extendedResultCode == 5 || error.message.toLowerCase().contains('locked')) {
      return DatabaseLockedFailure(cause: error);
    }
  }
  return UnknownDatabaseFailure(cause: error);
}
```

- [ ] **Step 12: Run to verify it passes**

Run: `flutter test test/core/error/failure_test.dart`
Expected: PASS.

- [ ] **Step 13: Gate and commit**

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core test/core
git commit -m "feat(core): add id, outcome and failure-mapping primitives" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 3: SRS domain types, due-date rule and `eight_box`

**Files:**
- Create, all under `lib/features/srs/domain/models/`: `review_kind_model.dart`,
  `due_date_model.dart`, `scheduler_type_model.dart`, `review_action_model.dart`,
  `srs_scheduler.dart`, `card_schedule_state_model.dart`,
  `review_log_entry_model.dart`, `eight_box_scheduler.dart`
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
  (retire the six `domain` entries, Step 9)
- Test: `test/features/srs/domain/due_date_model_test.dart`,
  `test/features/srs/domain/eight_box_scheduler_test.dart`

**Interfaces:**
- Consumes: nothing outside `dart:core`.
- Produces (one type per file, imported by path — there is no `srs` barrel):
  - `enum ReviewKind { learning, scheduled, relearning }` (`review_kind_model.dart`)
  - `DateTime dueAtLocalMidnight(DateTime now, int daysFromNow)` (`due_date_model.dart`).
    It is a date computation both schedulers share, not a rule that refuses, so it
    stays a top-level function (ADR-011 D7 covers rules that refuse).
  - `enum SchedulerType { eightBox, sm2 }` (`scheduler_type_model.dart`)
  - `enum EightBoxAction { forgotten, remembered }`,
    `enum Sm2Action { again, hard, good, easy }` (`review_action_model.dart`)
  - `sealed class CardScheduleState` with `eightBox`/`sm2` shape fields
    matching `card_schedule` (schema.md): `generation`, `learnedAt`, `dueAt`,
    `lastAnsweredAt`, `answerCount`, `lapseCount`, and scheduler-specific
    fields (`currentBox` or `easeFactor`/`intervalDays`/`repetitions`)
    (`card_schedule_state_model.dart`).
  - `final class ReviewLogEntry` mirroring `review_log`'s scheduler-specific
    columns needed by both schedulers: `kind`, `previousBox`/`nextBox` or
    `previousEaseFactor`/`nextEaseFactor`/`previousIntervalDays`/`nextIntervalDays`,
    `nextDueAt` (`review_log_entry_model.dart`).
  - `abstract interface class SrsScheduler { SchedulerType get type; int get version; Set<Object> get supportedActions; (CardScheduleState, ReviewLogEntry) next(CardScheduleState state, Object action, DateTime now); }`
    (`srs_scheduler.dart`)
  - `const EightBoxScheduler eightBoxScheduler` (`eight_box_scheduler.dart`).

- [ ] **Step 1: Write the failing due-date tests**

`test/features/srs/domain/due_date_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

void main() {
  test('0 days from now is local midnight of today', () {
    final now = DateTime(2026, 3, 14, 21, 5);
    expect(dueAtLocalMidnight(now, 0), DateTime(2026, 3, 14));
  });

  test('crossing a month end lands on the first of the next month', () {
    final now = DateTime(2026, 1, 30, 10);
    expect(dueAtLocalMidnight(now, 3), DateTime(2026, 2, 2));
  });

  test('128 days (eight_box box 8) crosses a year end correctly', () {
    final now = DateTime(2026, 9, 23);
    expect(dueAtLocalMidnight(now, 128), DateTime(2027, 1, 30));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/srs/domain/due_date_model_test.dart`
Expected: FAIL — `lib/features/srs/domain/models/due_date_model.dart` does not exist.

- [ ] **Step 3: Implement `due_date_model.dart`**

`lib/features/srs/domain/models/due_date_model.dart`:

```dart
/// Local midnight [daysFromNow] days after [now]'s local date. Time-of-day
/// on [now] is discarded: a review at 23:59 due "tomorrow" is due at
/// tomorrow's midnight, not 24h later.
DateTime dueAtLocalMidnight(DateTime now, int daysFromNow) {
  final today = DateTime(now.year, now.month, now.day);
  return today.add(Duration(days: daysFromNow));
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/srs/domain/due_date_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing `eight_box` tests**

`test/features/srs/domain/eight_box_scheduler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';

CardScheduleState _newCard({int generation = 1}) => CardScheduleState.eightBox(
      generation: generation,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      currentBox: 1,
    );

void main() {
  final now = DateTime(2026, 9, 23, 8);

  test('supportedActions is exactly forgotten and remembered', () {
    expect(eightBoxScheduler.supportedActions, {
      EightBoxAction.forgotten,
      EightBoxAction.remembered,
    });
  });

  test('remembered on a new card sets learnedAt and moves to box 2', () {
    final (next, log) = eightBoxScheduler.next(_newCard(), EightBoxAction.remembered, now);
    expect(next.currentBox, 2);
    expect(next.learnedAt, now);
    expect(log.kind, ReviewKind.learning);
    expect(log.previousBox, 1);
    expect(log.nextBox, 2);
  });

  test('forgotten on a new card stays in learning, box unchanged, no due date', () {
    final (next, log) = eightBoxScheduler.next(_newCard(), EightBoxAction.forgotten, now);
    expect(next.currentBox, 1);
    expect(next.dueAt, isNull);
    expect(log.kind, ReviewKind.learning);
  });

  test('box 8 remembered schedules 128 days out (BR-SRS box ladder)', () {
    final learned = _newCard().copyWith(learnedAt: now, currentBox: 8);
    final (next, log) = eightBoxScheduler.next(learned, EightBoxAction.remembered, now);
    expect(next.dueAt, dueAtLocalMidnight(now, 128));
    expect(log.kind, ReviewKind.scheduled);
    expect(log.nextDueAt, next.dueAt);
  });

  test('forgotten after learning is relearning and does not change dueAt', () {
    final scheduled = _newCard().copyWith(
      learnedAt: now,
      currentBox: 4,
      dueAt: dueAtLocalMidnight(now, 8),
    );
    final (next, log) = eightBoxScheduler.next(scheduled, EightBoxAction.forgotten, now);
    expect(log.kind, ReviewKind.relearning);
    expect(next.dueAt, scheduled.dueAt, reason: 'BR-SRS-017: relearning does not change the schedule');
    expect(log.previousBox, log.nextBox);
  });
}
```

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test test/features/srs/domain/eight_box_scheduler_test.dart`
Expected: FAIL — `CardScheduleState`, `eightBoxScheduler` etc. do not exist.

- [ ] **Step 7: Implement the remaining domain types and `eight_box`**

Every import in `lib/` is a `package:memox/...` import (`always_use_package_imports`).

`lib/features/srs/domain/models/review_kind_model.dart`:

```dart
/// Stored verbatim on `review_log.kind` (schema.md) — never inferred from
/// before/after values (BR-SRS-015, invariant 26).
enum ReviewKind { learning, scheduled, relearning }
```

`lib/features/srs/domain/models/scheduler_type_model.dart`:

```dart
/// The scheduler a root deck uses (spec §5), stored as a stable text code.
enum SchedulerType { eightBox, sm2 }
```

`lib/features/srs/domain/models/review_action_model.dart`:

```dart
enum EightBoxAction { forgotten, remembered }

enum Sm2Action { again, hard, good, easy }
```

`lib/features/srs/domain/models/card_schedule_state_model.dart`: a `sealed class`
`CardScheduleState` with two variants (`_EightBoxState`, `_Sm2State`) behind named
constructors `CardScheduleState.eightBox(...)` / `CardScheduleState.sm2(...)`,
common fields `generation`, `learnedAt`, `dueAt`, `lastAnsweredAt`, `answerCount`,
`lapseCount` (mirroring `card_schedule` in schema.md), scheduler-only fields
nullable on the other variant, and a `copyWith`.

`lib/features/srs/domain/models/review_log_entry_model.dart`: `final class
ReviewLogEntry` with `kind`, `previousBox`, `nextBox`, `previousEaseFactor`,
`nextEaseFactor`, `previousIntervalDays`, `nextIntervalDays`, `nextDueAt` — all
nullable except `kind`, matching schema.md's per-scheduler `NULL` convention on
`review_log`.

`lib/features/srs/domain/models/srs_scheduler.dart`:

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A pure function of (state, action, now) -> (next state, log entry). Time
/// is injected so tests never depend on the wall clock (spec §5 "SRS core").
abstract interface class SrsScheduler {
  SchedulerType get type;
  int get version;
  Set<Object> get supportedActions;
  (CardScheduleState, ReviewLogEntry) next(
    CardScheduleState state,
    Object action,
    DateTime now,
  );
}
```

`lib/features/srs/domain/models/eight_box_scheduler.dart`: `final class
EightBoxScheduler implements SrsScheduler` and `const EightBoxScheduler
eightBoxScheduler`. The box ladder is
`{1: 1, 2: 2, 3: 4, 4: 8, 5: 16, 6: 32, 7: 64, 8: 128}` days. `remembered`
before `learnedAt` is set: box 1 → 2, sets `learnedAt = now`, `kind = learning`,
no `dueAt`. `remembered` after `learnedAt`: box+1 (max 8), `kind = scheduled`,
`dueAt = dueAtLocalMidnight(now, ladder[nextBox])`. `forgotten` before
`learnedAt`: box unchanged, `kind = learning`. `forgotten` after `learnedAt`:
box unchanged, `kind = relearning`, `dueAt` unchanged (BR-SRS-017, invariant
14).

- [ ] **Step 8: Run to verify it passes**

Run: `flutter test test/features/srs`
Expected: PASS.

- [ ] **Step 9: Retire the `domain` waiting entries, gate and commit**

This task adds the first `lib/features/*/domain/` file, so the guard now reports
`guard.config.stale_targets_pending` for six rules. Delete these six entries, each
with its `targets_pending: domain` line, from
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`:

```
memox.architecture.domain_no_infrastructure_import
memox.architecture.no_drift_type_in_domain
memox.architecture.no_transaction_outside_data_layer
memox.architecture.single_study_mode_dispatch
memox.data_model.scheduler_no_ambient_now
memox.naming.domain_file_role_suffix
```

Also delete the group's comment line above them, the one that starts with `# --`
and names `domain`.

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/srs test/features/srs code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(srs): add SRS domain types, due-date rule and eight_box scheduler" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

Expected: every command exits 0; the guard shows no `stale_targets_pending`.

---

### Task 4: `sm2` scheduler and scheduler lookup

**Files:**
- Create: `lib/features/srs/domain/models/sm2_scheduler.dart`,
  `lib/features/srs/domain/models/schedulers_model.dart`
- Test: `test/features/srs/domain/sm2_scheduler_test.dart`,
  `test/features/srs/domain/schedulers_model_test.dart`

**Interfaces:**
- Consumes: `SrsScheduler`, `CardScheduleState`, `ReviewLogEntry`, `SchedulerType`,
  `Sm2Action`, `dueAtLocalMidnight` (Task 3).
- Produces:
  - `const Sm2Scheduler sm2Scheduler` (`sm2_scheduler.dart`).
  - `SrsScheduler schedulerFor(SchedulerType type)` (`schedulers_model.dart`). It
    lives in its own file so that neither the interface nor the enum has to
    import the implementations.

- [ ] **Step 1: Write the failing `sm2` tests**

`test/features/srs/domain/sm2_scheduler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

CardScheduleState _newCard() => CardScheduleState.sm2(
      generation: 1,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
    );

void main() {
  final now = DateTime(2026, 9, 23, 8);

  test('supportedActions is again/hard/good/easy', () {
    expect(sm2Scheduler.supportedActions, {
      Sm2Action.again, Sm2Action.hard, Sm2Action.good, Sm2Action.easy,
    });
  });

  test('again always resets repetitions and floors ease at 1.3', () {
    final low = _newCard().copyWith(easeFactor: 1.3, repetitions: 5);
    final (next, log) = sm2Scheduler.next(low, Sm2Action.again, now);
    expect(next.repetitions, 0);
    expect(next.easeFactor, greaterThanOrEqualTo(1.3));
    expect(log.previousEaseFactor, 1.3);
  });

  test('good on a new card sets learnedAt and interval 1', () {
    final (next, log) = sm2Scheduler.next(_newCard(), Sm2Action.good, now);
    expect(next.learnedAt, now);
    expect(next.intervalDays, 1);
    expect(log.kind, ReviewKind.learning);
  });

  test('easy grows the interval faster than good from the same state', () {
    final learned = _newCard().copyWith(learnedAt: now, repetitions: 2, intervalDays: 6);
    final (goodNext, _) = sm2Scheduler.next(learned, Sm2Action.good, now);
    final (easyNext, _) = sm2Scheduler.next(learned, Sm2Action.easy, now);
    expect(easyNext.intervalDays, greaterThan(goodNext.intervalDays!));
  });

  test('again after learnedAt is relearning and does not change dueAt', () {
    final scheduled = _newCard().copyWith(
      learnedAt: now, repetitions: 3, intervalDays: 10,
      dueAt: dueAtLocalMidnight(now, 10),
    );
    final (next, log) = sm2Scheduler.next(scheduled, Sm2Action.again, now);
    expect(log.kind, ReviewKind.relearning);
    expect(next.dueAt, scheduled.dueAt);
    expect(log.previousIntervalDays, log.nextIntervalDays);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/srs/domain/sm2_scheduler_test.dart`
Expected: FAIL — `sm2Scheduler` does not exist.

- [ ] **Step 3: Implement `sm2_scheduler.dart` and `schedulers_model.dart`**

`lib/features/srs/domain/models/sm2_scheduler.dart`: `final class Sm2Scheduler
implements SrsScheduler` and `const Sm2Scheduler sm2Scheduler`.

Classic SM-2: `easeFactor' = max(1.3, ease + (0.1 − (5−q)×(0.08+(5−q)×0.02)))`
with `q` mapped from the four actions (`again`→2, `hard`→3, `good`→4,
`easy`→5, matching the "quality" scale SM-2 defines); `again` also resets
`repetitions` to 0. Before `learnedAt`: `good`/`easy` set `learnedAt = now`,
`intervalDays = 1`, `kind = learning`; `again`/`hard` keep `learnedAt = null`,
`kind = learning`. After `learnedAt` and not relearning: `repetitions == 0`
→ interval 1, `repetitions == 1` → interval 6, else `round(interval * ease)`;
`kind = scheduled`, `dueAt` recomputed via `dueAtLocalMidnight`. `again`
after `learnedAt`: `kind = relearning`, `dueAt`/`intervalDays` unchanged,
`lapseCount + 1` (BR-SRS-018).

`lib/features/srs/domain/models/schedulers_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// The lookup table behind "scheduler is chosen per root deck" (spec §5).
SrsScheduler schedulerFor(SchedulerType type) => switch (type) {
  SchedulerType.eightBox => eightBoxScheduler,
  SchedulerType.sm2 => sm2Scheduler,
};
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/srs/domain/sm2_scheduler_test.dart`
Expected: PASS.

- [ ] **Step 5: Write and pass the lookup test**

`test/features/srs/domain/schedulers_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

void main() {
  test('schedulerFor returns the matching implementation', () {
    expect(schedulerFor(SchedulerType.eightBox), same(eightBoxScheduler));
    expect(schedulerFor(SchedulerType.sm2), same(sm2Scheduler));
  });
}
```

Run: `flutter test test/features/srs/domain/schedulers_model_test.dart`
Expected: PASS.

- [ ] **Step 6: Import-boundary check**

Run: `flutter test test/architecture`
Expected: PASS — `srs/domain` still imports nothing forbidden, and every file
sits in an ADR-011 bucket.

- [ ] **Step 7: Gate and commit**

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/srs test/features/srs
git commit -m "feat(srs): add sm2 scheduler and scheduler lookup" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 5: Central database schema and `AppDatabase`

This is the schema task. It creates the 9 tables in scope for V8.0 per
schema.md (Clarification 1): `deck`, `card`, `tags`, `card_tags`,
`card_schedule`, `review_log`, `study_session`, `study_queue_items`,
`app_settings`. Every `CHECK` and column
below is transcribed from `docs/shared/data/schema.md`; every invariant query
is transcribed from its "Bất biến" section, run in `test/database/invariants_test.dart`.

**Files:**
- Create: `lib/core/database/tables/deck.drift`, `card.drift`, `tags.drift`,
  `srs.drift`, `study.drift`, `settings.drift`, `lib/core/database/app_database.dart`,
  `lib/core/database/connection.dart`, `lib/core/database/di/database_provider.dart`,
  `test/support/test_database.dart`, `drift_schemas/drift_schema_v1.json` (generated)
- Test: `test/database/schema_test.dart`, `test/database/invariants_test.dart`

**Interfaces:**
- Consumes: `mapDatabaseError`, `ConstraintFailure` (Task 2).
- Produces:
  - `class AppDatabase extends _$AppDatabase` with `schemaVersion == 1`,
    foreign keys ON at open.
  - Generated row/companion classes for `Deck`, `CardRow`, `CardSchedule`,
    `ReviewLog`, `StudySession`, `StudyQueueItem`, `AppSetting`, `Tag`,
    `CardTag`.
  - `AppDatabase openTestDatabase()` in `test/support/test_database.dart`
    (in-memory, foreign keys ON).
  - `AppDatabase openAppDatabase()` in `lib/core/database/connection.dart`,
    the only file in `lib/` that calls `driftDatabase()`.

Column names in SQL are snake_case; Drift exposes them as camelCase
(`root_id` → `rootId`). Datetimes are stored by Drift as UTC unix seconds
(Clarification 11).

- [ ] **Step 1: Write `lib/core/database/tables/deck.drift`**

```sql
CREATE TABLE deck (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id TEXT REFERENCES deck (id) ON DELETE CASCADE,
  root_id TEXT NOT NULL,
  depth INTEGER NOT NULL CHECK (depth BETWEEN 1 AND 10),
  content_type TEXT NOT NULL DEFAULT 'unset'
    CHECK (content_type IN ('unset', 'card', 'deck')),
  owner_id TEXT, -- NULL = local profile. Scope: sub-project sau (auth).
  scheduler_type TEXT CHECK (scheduler_type IN ('eight_box', 'sm2')),
  scheduler_version INTEGER,
  scheduler_config TEXT, -- JSON. Only on root, same NULL rule as scheduler_type.
  study_config TEXT, -- JSON. Only on root (BR-STUDY-056).
  generation INTEGER,
  first_answered_at DATETIME,
  -- Scope: sub-project sau (Starter decks). No FK yet: deck_templates does not exist.
  source_template_id TEXT,
  source_template_version INTEGER,
  -- Scope: sub-project sau (Trash). No FK yet: delete_batches does not exist.
  delete_batch_id TEXT,
  sibling_position INTEGER NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  -- root deck rules: BR-DECK-002, BR-DECK-004
  CHECK ((parent_id IS NULL) = (root_id = id)),
  CHECK (parent_id IS NOT NULL OR content_type = 'deck'),
  -- scheduler columns only on root: BR-DECK-025
  CHECK ((parent_id IS NULL) = (scheduler_type IS NOT NULL)),
  CHECK ((parent_id IS NULL) = (generation IS NOT NULL)),
  CHECK (parent_id IS NOT NULL OR scheduler_version IS NOT NULL),
  CHECK (parent_id IS NULL OR scheduler_config IS NULL),
  CHECK (parent_id IS NULL OR study_config IS NULL),
  CHECK (parent_id IS NULL OR generation IS NULL)
) AS Deck;

CREATE INDEX idx_deck_parent_position ON deck (parent_id, sibling_position, id);
CREATE INDEX idx_deck_root_position ON deck (root_id, sibling_position, id);
```

`lib/core/database/tables/card.drift`:

```sql
import 'deck.drift';

CREATE TABLE card (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES deck (id) ON DELETE CASCADE,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  front_folded TEXT NOT NULL DEFAULT '',
  back_folded TEXT NOT NULL DEFAULT '',
  is_flagged INTEGER NOT NULL DEFAULT 0 CHECK (is_flagged IN (0, 1)),
  example TEXT,
  hint TEXT,
  pronunciation TEXT,
  -- Scope: sub-project sau (Trash). No FK yet: delete_batches does not exist.
  delete_batch_id TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) AS CardRow;

CREATE INDEX idx_card_deck_created ON card (deck_id, created_at, id);
```

`CardRow`, not `Card`, so the generated class never collides with Flutter's
`Card` widget. `front_folded`/`back_folded` are written by the data layer in
Dart (Task 9) — never `lower()` in SQL (schema.md: SQLite `lower()` is
ASCII-only).

`lib/core/database/tables/srs.drift`:

```sql
import 'card.drift';

CREATE TABLE card_schedule (
  card_id TEXT NOT NULL PRIMARY KEY REFERENCES card (id) ON DELETE CASCADE,
  scheduler_type TEXT NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
  scheduler_version INTEGER NOT NULL,
  generation INTEGER NOT NULL,
  learned_at DATETIME,
  due_at DATETIME,
  last_answered_at DATETIME,
  answer_count INTEGER NOT NULL DEFAULT 0,
  lapse_count INTEGER NOT NULL DEFAULT 0,
  current_box INTEGER CHECK (current_box BETWEEN 1 AND 8),
  ease_factor REAL,
  interval_days INTEGER,
  repetitions INTEGER,
  -- exactly one scheduler's state, matching scheduler_type
  CHECK ((scheduler_type = 'eight_box') = (current_box IS NOT NULL)),
  CHECK ((scheduler_type = 'sm2') = (ease_factor IS NOT NULL)),
  CHECK ((ease_factor IS NULL) = (interval_days IS NULL)),
  CHECK ((ease_factor IS NULL) = (repetitions IS NULL)),
  -- invariant 28: no due date before learning is done. Invariant 24, the other
  -- direction, is not a CHECK yet (Clarification 15).
  CHECK (learned_at IS NOT NULL OR due_at IS NULL)
) AS CardSchedule;

CREATE INDEX idx_card_schedule_due ON card_schedule (due_at);

-- session_id has no foreign key on purpose: srs must not depend on study's table.
CREATE TABLE review_log (
  id TEXT NOT NULL PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  scheduler_type TEXT NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
  generation INTEGER NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('learning', 'scheduled', 'relearning')),
  mode TEXT NOT NULL
    CHECK (mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
  outcome_reason TEXT CHECK (outcome_reason IS NULL OR outcome_reason = 'timeout'),
  comparison_version INTEGER,
  used_hint INTEGER CHECK (used_hint IS NULL OR used_hint IN (0, 1)),
  direction TEXT CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')),
  action TEXT NOT NULL
    CHECK (action IN ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')),
  answered_at DATETIME NOT NULL,
  next_due_at DATETIME,
  previous_box INTEGER,
  next_box INTEGER,
  previous_ease_factor REAL,
  next_ease_factor REAL,
  previous_interval_days INTEGER,
  next_interval_days INTEGER,
  -- invariant 23: fill-only columns only on mode = fill
  CHECK (mode = 'fill' OR (comparison_version IS NULL AND used_hint IS NULL)),
  -- invariant 22: timeout only on recall
  CHECK (outcome_reason IS NULL OR mode = 'recall')
) AS ReviewLog;

CREATE INDEX idx_review_log_card ON review_log (card_id, answered_at);
CREATE INDEX idx_review_log_session ON review_log (session_id);

CREATE TRIGGER review_log_append_only
BEFORE UPDATE ON review_log
BEGIN
  SELECT RAISE(ABORT, 'review_log is append-only');
END;

CREATE TRIGGER review_log_no_delete
BEFORE DELETE ON review_log
WHEN OLD.card_id IN (SELECT id FROM card)
BEGIN
  SELECT RAISE(ABORT, 'review_log rows are only removed by a card cascade');
END;
```

The `review_log_no_delete` trigger only blocks a direct `DELETE`; it does not
fire on the `ON DELETE CASCADE` from `card`, because by the time the cascade
runs the parent row no longer satisfies `OLD.card_id IN (SELECT id FROM card)`.

`lib/core/database/tables/study.drift`:

```sql
import 'deck.drift';

CREATE TABLE study_session (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES deck (id) ON DELETE CASCADE,
  root_id TEXT NOT NULL,
  generation INTEGER NOT NULL,
  session_kind TEXT NOT NULL CHECK (session_kind IN ('learning', 'reviewing')),
  current_mode TEXT NOT NULL
    CHECK (current_mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
  status TEXT NOT NULL CHECK (
    status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')
  ),
  end_reason TEXT CHECK (
    end_reason IN (
      'user_exit', 'interrupted', 'scheduler_reset', 'scheduler_changed',
      'stale_generation', 'persistence_error', 'content_deleted'
    )
  ),
  cursor INTEGER NOT NULL DEFAULT 0,
  card_limit INTEGER NOT NULL DEFAULT 20,
  direction TEXT CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean', 'mixed')),
  started_at DATETIME NOT NULL,
  ended_at DATETIME,
  -- invariant 12
  CHECK (
    (status IN ('in_progress', 'completed') AND end_reason IS NULL)
    OR (status = 'abandoned' AND end_reason IN ('user_exit', 'interrupted'))
    OR (status = 'invalidated' AND end_reason IN (
      'scheduler_reset', 'scheduler_changed', 'stale_generation', 'content_deleted'
    ))
    OR (status = 'failed' AND end_reason = 'persistence_error')
  ),
  -- invariant 13
  CHECK ((status = 'in_progress') = (ended_at IS NULL)),
  -- invariant 31 (session half): direction only on reviewing + self_assess
  CHECK (direction IS NULL OR (session_kind = 'reviewing' AND current_mode = 'self_assess'))
) AS StudySession;

-- Scope: V8.0 (schema.md) — schema and invariants only in this plan; the
-- write path (opening a session, building rounds) is study/session business
-- logic, owned by the core-learning-slice sub-project (Clarification 1).
CREATE TABLE study_queue_items (
  session_id TEXT NOT NULL REFERENCES study_session (id) ON DELETE CASCADE,
  mode TEXT NOT NULL
    CHECK (mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
  round INTEGER NOT NULL DEFAULT 1 CHECK (round >= 1),
  card_id TEXT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'completed')),
  available_at INTEGER NOT NULL DEFAULT 0 CHECK (available_at >= 0),
  answers_in_session INTEGER NOT NULL DEFAULT 0 CHECK (answers_in_session >= 0),
  remaining_ms INTEGER CHECK (remaining_ms IS NULL OR remaining_ms BETWEEN 0 AND 20000),
  is_revealed INTEGER NOT NULL DEFAULT 0 CHECK (is_revealed IN (0, 1)),
  direction TEXT CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')),
  PRIMARY KEY (session_id, mode, round, card_id),
  -- invariant 17 (self_assess relearning cap)
  CHECK (mode = 'self_assess' OR answers_in_session <= 4),
  -- invariant 21 (recall-only timer state)
  CHECK (mode = 'recall' OR (remaining_ms IS NULL AND is_revealed = 0)),
  -- invariant 31 (queue half): direction only on self_assess
  CHECK (mode = 'self_assess' OR direction IS NULL)
) AS StudyQueueItem;

CREATE INDEX idx_study_queue_pending ON study_queue_items (session_id, status, available_at, position);
```

`lib/core/database/tables/settings.drift`:

```sql
-- Scope: V8.0 (schema.md) — schema only in this plan; read/write of these
-- values is the future `settings` feature. reminder_* columns are
-- scope: sub-project sau (daily reminders); kept here per schema.md so the
-- business logic is not re-derived later.
CREATE TABLE app_settings (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  card_limit INTEGER NOT NULL DEFAULT 20,
  new_card_order TEXT NOT NULL DEFAULT 'created' CHECK (new_card_order IN ('created', 'random')),
  theme_mode TEXT NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('system', 'light', 'dark')),
  language TEXT NOT NULL DEFAULT 'system' CHECK (language IN ('system', 'en', 'vi')),
  reminder_enabled INTEGER NOT NULL DEFAULT 0 CHECK (reminder_enabled IN (0, 1)),
  reminder_minute_of_day INTEGER NOT NULL DEFAULT 1200 CHECK (reminder_minute_of_day BETWEEN 0 AND 1439),
  reminder_last_delivered_at DATETIME,
  updated_at DATETIME NOT NULL
) AS AppSetting;
```

`lib/core/database/tables/tags.drift`:

```sql
import 'card.drift';

-- Scope: V8.0, tagging a card only (ADR-009 decision 4). Tag Management
-- (UC-TAG-001) is a later sub-project.
CREATE TABLE tags (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  -- lower(trim(name)), written by Dart: SQLite NOCASE/lower() are ASCII-only.
  name_folded TEXT NOT NULL,
  owner_id TEXT,
  created_at DATETIME NOT NULL
) AS Tag;

-- COALESCE: SQLite treats NULLs as distinct in a unique index, and the local
-- profile's owner_id is NULL (schema.md, resolved 2026-09-23).
CREATE UNIQUE INDEX idx_tags_owner_name_folded ON tags (COALESCE(owner_id, ''), name_folded);

CREATE TABLE card_tags (
  card_id TEXT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
  tag_id TEXT NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
  PRIMARY KEY (card_id, tag_id)
) AS CardTag;

CREATE INDEX idx_card_tags_tag ON card_tags (tag_id, card_id);
```

The unique index normalises `owner_id` with `COALESCE`, so two tags with the
same folded name are rejected for the local profile (`owner_id` NULL) too —
the database, not only the write path, holds BR-TAG-001.

- [ ] **Step 2: Write `AppDatabase` and the connection helper**

`lib/core/database/app_database.dart`:

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {
    'package:memox/core/database/tables/deck.drift',
    'package:memox/core/database/tables/card.drift',
    'package:memox/core/database/tables/tags.drift',
    'package:memox/core/database/tables/srs.drift',
    'package:memox/core/database/tables/study.drift',
    'package:memox/core/database/tables/settings.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

`lib/core/database/connection.dart` (the only file in `lib/` that opens a
database, per `flutter-drift/references/project-baseline.md`):

```dart
import 'package:drift_flutter/drift_flutter.dart';
import 'package:memox/core/database/app_database.dart';

AppDatabase openAppDatabase() => AppDatabase(
      driftDatabase(name: 'memox'),
    );
```

`lib/core/database/di/database_provider.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/connection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
}
```

`test/support/test_database.dart`:

```dart
import 'package:drift/native.dart';
import 'package:memox/core/database/app_database.dart';

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
```

- [ ] **Step 3: Generate code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` and `database_provider.g.dart` generated with
no errors. If a `.drift` file fails to parse, the error names the file and
line; fix the SQL there.

- [ ] **Step 4: Write the failing schema tests**

`test/database/schema_test.dart` (structural checks — invariant queries live
in Step 6's file):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

import '../support/test_database.dart';

Future<void> _root(AppDatabase db, String id, {String scheduler = 'eight_box'}) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES (?, 'r', NULL, ?, 1, 'deck', ?, 1, 1, 0, 0, 0)",
      [id, id, scheduler],
    );

Future<void> _child(AppDatabase db, String id, String parent, String root, int depth,
        {String content = 'unset'}) =>
    db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'sibling_position, created_at, updated_at) '
      "VALUES (?, 'c', ?, ?, ?, ?, 0, 0, 0)",
      [id, parent, root, depth, content],
    );

Future<int> _count(AppDatabase db, String table) async {
  final row = await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle();
  return row.read<int>('n');
}

Future<Failure> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    return mapDatabaseError(e);
  }
  fail('expected the statement to fail');
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('foreign keys are enforced', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('depth 11 violates a constraint and maps to ConstraintFailure', () async {
    await _root(db, 'r');
    final f = await _failureOf(() => _child(db, 'x', 'r', 'r', 11));
    expect(f, isA<ConstraintFailure>());
  });

  test('a sub-deck cannot carry a scheduler', () async {
    await _root(db, 'r');
    final f = await _failureOf(() => db.customStatement(
          'INSERT INTO deck (id, name, parent_id, root_id, depth, scheduler_type, '
          'scheduler_version, generation, sibling_position, created_at, updated_at) '
          "VALUES ('s', 'x', 'r', 'r', 2, 'sm2', 1, 1, 0, 0, 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('deleting a root cascades to sub-decks, cards, schedules, logs and sessions', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) "
      "VALUES ('c', 'eight_box', 1, 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
      "status, cursor, card_limit, started_at) VALUES ('ses', 'r', 'r', 1, 'reviewing', 'self_assess', "
      "'in_progress', 0, 20, 0)",
    );
    await db.customStatement(
      "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
      "action, answered_at) VALUES ('l', 'c', 'ses', 'eight_box', 1, 'scheduled', 'self_assess', 'remembered', 0)",
    );

    await db.customStatement("DELETE FROM deck WHERE id = 'r'");

    for (final table in ['deck', 'card', 'card_schedule', 'review_log', 'study_session']) {
      expect(await _count(db, table), 0, reason: table);
    }
  });

  test('a schedule row carries exactly one scheduler state', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    final f = await _failureOf(() => db.customStatement(
          "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
          "current_box, ease_factor, interval_days, repetitions) VALUES ('c', 'eight_box', 1, 1, 1, 2.5, 0, 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('review_log rejects a direct UPDATE (append-only)', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
      "status, cursor, card_limit, started_at) VALUES ('ses', 'r', 'r', 1, 'reviewing', 'self_assess', "
      "'in_progress', 0, 20, 0)",
    );
    await db.customStatement(
      "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
      "action, answered_at) VALUES ('l', 'c', 'ses', 'eight_box', 1, 'scheduled', 'self_assess', 'good', 0)",
    );
    await expectLater(
      db.customStatement("UPDATE review_log SET action = 'easy' WHERE id = 'l'"),
      throwsA(anything),
    );
  });

  test('study_session accepts only the valid status x end_reason pairs (invariant 12)', () async {
    await _root(db, 'r');
    Future<void> insert(String status, String? reason, {int? ended}) => db.customStatement(
          "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
          "status, end_reason, cursor, card_limit, started_at, ended_at) "
          "VALUES (?, 'r', 'r', 1, 'reviewing', 'self_assess', ?, ?, 0, 20, 0, ?)",
          ['$status-${reason ?? 'none'}', status, reason, ended],
        );

    await insert('in_progress', null);
    await insert('completed', null, ended: 1);
    await insert('abandoned', 'user_exit', ended: 1);
    await insert('invalidated', 'stale_generation', ended: 1);
    await insert('failed', 'persistence_error', ended: 1);

    expect(await _failureOf(() => insert('completed', 'user_exit', ended: 1)), isA<ConstraintFailure>());
    expect(await _failureOf(() => insert('abandoned', 'stale_generation', ended: 1)), isA<ConstraintFailure>());
    expect(await _failureOf(() => insert('in_progress', null, ended: 1)), isA<ConstraintFailure>());
  });

  test('deleting a card or a tag removes its card_tags links', () async {
    await _root(db, 'r');
    await _child(db, 'd', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('c1', 'd', 'f', 'b', 0, 0), ('c2', 'd', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) "
      "VALUES ('t1', 'Noun', 'noun', 0), ('t2', 'Verb', 'verb', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1'), ('c2', 't2')",
    );
    await db.customStatement("DELETE FROM card WHERE id = 'c1'");
    await db.customStatement("DELETE FROM tags WHERE id = 't2'");
    expect(await _count(db, 'card_tags'), 0);
  });

  test('a tag name is unique for the local profile (NULL owner) after folding', () async {
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t1', 'Noun', 'noun', 0)",
    );
    final f = await _failureOf(() => db.customStatement(
          "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t2', 'noun', 'noun', 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('a tag name is unique per owner after folding', () async {
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, owner_id, created_at) "
      "VALUES ('t1', 'Động từ', 'động từ', 'p', 0)",
    );
    final f = await _failureOf(() => db.customStatement(
          "INSERT INTO tags (id, name, name_folded, owner_id, created_at) "
          "VALUES ('t2', 'động từ', 'động từ', 'p', 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('a snapshot exists for the current schema version', () {
    final snapshot = File('drift_schemas/drift_schema_v${db.schemaVersion}.json');
    expect(snapshot.existsSync(), isTrue,
        reason: 'run: dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/');
  });
}
```

- [ ] **Step 5: Run to verify the expected failure**

Run: `flutter test test/database/schema_test.dart`
Expected: everything passes **except** the last test (no snapshot yet). If a
constraint test returns `UnknownDatabaseFailure` instead of
`ConstraintFailure`, inspect `f.cause` and extend `mapDatabaseError` in
`lib/core/error/failure.dart` (and its test from Task 2) accordingly.

- [ ] **Step 6: Write `test/database/invariants_test.dart`**

One test per invariant query this plan's tables can violate — every query
below is copied from `docs/shared/data/schema.md`'s "Bất biến" section
verbatim, run against fixtures inserted with `customStatement`, asserting
zero rows both on a clean fixture and (where practical) after an attempted
violation is rejected by a `CHECK`/trigger instead of landing. Cover, at
minimum: invariants 1–13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
28, 29, 30, 31, 32 (schema.md numbering). Skip 14 only if Task 3/8's
`relearning` tests already prove it at the domain level — otherwise include
it too. Do not write invariants 33–37: they require `delete_batches`, which
does not exist in this plan (Clarification 2).

Example shape (repeat for each invariant, with the exact SQL from schema.md
and a fixture that would violate it if the schema allowed it):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('invariant 1: root deck has no direct card', () async {
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    );
    final rows = await db.customSelect(
      "SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id "
      "WHERE d.parent_id IS NULL AND c.delete_batch_id IS NULL",
    ).get();
    expect(rows, isEmpty);
  });

  // ... invariants 2-13, 15-32, each named "invariant N: <one-line summary>"
  // and citing the BR- code(s) from schema.md's comment on that query.
}
```

- [ ] **Step 7: Run to verify all invariant tests pass on empty/valid fixtures**

Run: `flutter test test/database/invariants_test.dart`
Expected: PASS — every invariant query returns zero rows on the fixtures
written (which are all schema-valid; a schema-invalid fixture is instead
proven impossible via `schema_test.dart`'s `ConstraintFailure` tests where a
`CHECK` exists, or documented as a data-integrity invariant with no `CHECK`
backing it, e.g. invariant 6/7/8/30 which need cross-row/tree reasoning a
single-row `CHECK` cannot express).

- [ ] **Step 8: Dump the v1 snapshot**

```bash
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
```

Expected: `drift_schemas/drift_schema_v1.json` created.

- [ ] **Step 9: Run to verify pass**

Run: `flutter test test/database`
Expected: PASS.

- [ ] **Step 10: Import-boundary check**

Run: `flutter test test/architecture`
Expected: PASS — `core/database/` imports no feature, `app/` or `shared/`, and
`core/` holds only concern folders.

- [ ] **Step 11: Retire the `providers` waiting entries, gate and commit**

`lib/core/database/di/database_provider.dart` is the first `*_provider.dart`
file, so the guard now reports `guard.config.stale_targets_pending` for three
rules. Delete these three entries, each with its `targets_pending: providers`
line, and the group's comment line (it starts with `# --` and names
`providers`), from
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`:

```
memox.state_management.controller_no_build_context
memox.state_management.notifier_no_public_mutable_field
memox.state_management.state_write_after_await_requires_mounted
```

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/database test/support test/database drift_schemas code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(db): add v1 schema, AppDatabase and data invariants" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

Expected: every command exits 0; the guard shows no `stale_targets_pending`.

---

### Task 6: Deck domain — entity, pure rules and repository contract

**Files:**
- Create: `lib/features/deck/domain/entities/deck_entity.dart`,
  `lib/features/deck/domain/models/deck_content_type_model.dart`,
  `lib/features/deck/domain/failures/deck_failure.dart`,
  `lib/features/deck/domain/repositories/deck_repository.dart`
- Test: `test/features/deck/domain/deck_entity_test.dart`

**Interfaces:**
- Consumes: `Outcome`, `Ok`, `Rejected` (Task 2, `lib/core/error/outcome.dart`);
  `SchedulerType` (Task 3, `lib/features/srs/domain/models/scheduler_type_model.dart`
  — `deck → srs` is an edge of the ADR-011 import map).
- Produces:
  - `enum DeckContentType { unset, card, deck }` (`deck_content_type_model.dart`).
  - `enum DeckRejection { blankName, depthExceeded, notADeckContainer, notACardContainer, subtreeSchedulerMismatch, movingIntoOwnSubtree, rootCannotMove, notFound }`
    (`deck_failure.dart`) — deck's own reasons (ADR-011 D6).
  - `final class DeckEntity` mirroring `deck` (schema.md): `id`, `name`, `parentId`,
    `rootId`, `depth`, `contentType`, `schedulerType`, `generation`,
    `firstAnsweredAt`, `siblingPosition`, timestamps. Named `DeckEntity`, not
    `Deck`: Task 5's Drift row class is `Deck` (`AS Deck`), and the data layer
    imports both.
  - The deck tree rules, as static members of `DeckEntity` (ADR-011 D7). They take
    the current tree shape (never the database) and return
    `Outcome<void, DeckRejection>`: `DeckEntity.checkName(String name)`,
    `DeckEntity.checkCreateSubDeck({required int parentDepth})`,
    `DeckEntity.checkCreateCard({required DeckContentType parentContentType})`,
    `DeckEntity.checkMove({required String movingId, required String targetParentId, required List<String> targetAncestorIds, required int targetDepth, required int subtreeHeight, required SchedulerType? movingRootScheduler, required int? movingRootGeneration, required SchedulerType? targetRootScheduler, required int? targetRootGeneration})`.
  - `abstract interface class DeckRepository` with
    `Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({required String name, required SchedulerType schedulerType, DateTime? now})`,
    `Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({required String parentId, required String name, DateTime? now})`,
    `Future<Outcome<void, DeckRejection>> moveDeck({required String deckId, required String newParentId, DateTime? now})`,
    `Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId})`,
    `Future<DeckEntity?> findById(String id)`.

- [ ] **Step 1: Write the failing pure-rule tests**

`test/features/deck/domain/deck_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

typedef _Check = Outcome<void, DeckRejection>;
typedef _Refused = Rejected<void, DeckRejection>;
typedef _Allowed = Ok<void, DeckRejection>;

DeckRejection _reasonOf(_Check result) => (result as _Refused).reason;

void main() {
  group('checkName', () {
    test('blank or whitespace-only name is rejected', () {
      expect(DeckEntity.checkName('   '), isA<_Refused>());
      expect(_reasonOf(DeckEntity.checkName('   ')), DeckRejection.blankName);
    });
    test('a real name is accepted', () {
      expect(DeckEntity.checkName('Korean 101'), isA<_Allowed>());
    });
  });

  group('checkCreateSubDeck', () {
    test('depth 10 is the deepest a sub-deck may be created at', () {
      final result = DeckEntity.checkCreateSubDeck(parentDepth: 10);
      expect(_reasonOf(result), DeckRejection.depthExceeded);
    });
    test('depth 9 may still get a child at depth 10', () {
      expect(DeckEntity.checkCreateSubDeck(parentDepth: 9), isA<_Allowed>());
    });
  });

  group('checkCreateCard', () {
    test('a parent already holding sub-decks refuses a card', () {
      final result = DeckEntity.checkCreateCard(
        parentContentType: DeckContentType.deck,
      );
      expect(_reasonOf(result), DeckRejection.notACardContainer);
    });
    test('unset or card-typed parent accepts a card', () {
      expect(
        DeckEntity.checkCreateCard(parentContentType: DeckContentType.unset),
        isA<_Allowed>(),
      );
      expect(
        DeckEntity.checkCreateCard(parentContentType: DeckContentType.card),
        isA<_Allowed>(),
      );
    });
  });

  group('checkMove', () {
    _Check move({
      String movingId = 'a',
      String targetParentId = 'b',
      List<String> targetAncestorIds = const ['b'],
      int targetDepth = 2,
      int subtreeHeight = 1,
      SchedulerType targetRootScheduler = SchedulerType.eightBox,
      int targetRootGeneration = 1,
    }) => DeckEntity.checkMove(
      movingId: movingId,
      targetParentId: targetParentId,
      targetAncestorIds: targetAncestorIds,
      targetDepth: targetDepth,
      subtreeHeight: subtreeHeight,
      movingRootScheduler: SchedulerType.eightBox,
      movingRootGeneration: 1,
      targetRootScheduler: targetRootScheduler,
      targetRootGeneration: targetRootGeneration,
    );

    // A root deck cannot move (`DeckRejection.rootCannotMove`): only the
    // repository knows a deck has no parent, so Task 7 asserts it there.

    test('moving a deck into its own descendant is rejected', () {
      final result = move(targetAncestorIds: const ['b', 'a'], targetDepth: 3);
      expect(_reasonOf(result), DeckRejection.movingIntoOwnSubtree);
    });

    test('moving onto itself is rejected', () {
      final result = move(targetParentId: 'a', targetAncestorIds: const ['a']);
      expect(_reasonOf(result), DeckRejection.movingIntoOwnSubtree);
    });

    test('moving a subtree past depth 10 is rejected', () {
      final result = move(targetDepth: 9, subtreeHeight: 2);
      expect(_reasonOf(result), DeckRejection.depthExceeded);
    });

    test(
      'moving under a root with another scheduler or generation is blocked',
      () {
        expect(
          _reasonOf(move(targetRootScheduler: SchedulerType.sm2)),
          DeckRejection.subtreeSchedulerMismatch,
        );
        expect(
          _reasonOf(move(targetRootGeneration: 2)),
          DeckRejection.subtreeSchedulerMismatch,
        );
      },
    );

    test('a same-root, in-depth move is accepted', () {
      expect(move(), isA<_Allowed>());
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/deck/domain/deck_entity_test.dart`
Expected: FAIL — `lib/features/deck/domain/entities/deck_entity.dart` does not exist.

- [ ] **Step 3: Implement the model, the reasons, the entity and the contract**

`lib/features/deck/domain/models/deck_content_type_model.dart`:

```dart
/// What a deck holds; `unset` until its first child (BR-DECK-006..008).
enum DeckContentType { unset, card, deck }
```

`lib/features/deck/domain/failures/deck_failure.dart`:

```dart
/// Why the deck feature refuses a write (ADR-011 D6). Every value is a rule
/// from the spec or schema.md, checked before the database is touched.
enum DeckRejection {
  blankName,
  depthExceeded,
  notADeckContainer,
  notACardContainer,
  subtreeSchedulerMismatch,
  movingIntoOwnSubtree,
  rootCannotMove,
  notFound,
}
```

`lib/features/deck/domain/entities/deck_entity.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

const _maxDepth = 10;

final class DeckEntity {
  const DeckEntity({
    required this.id,
    required this.name,
    required this.parentId,
    required this.rootId,
    required this.depth,
    required this.contentType,
    required this.schedulerType,
    required this.generation,
    required this.firstAnsweredAt,
    required this.siblingPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? parentId;
  final String rootId;
  final int depth;
  final DeckContentType contentType;
  final SchedulerType? schedulerType; // non-null only when parentId == null
  final int? generation; // non-null only when parentId == null
  final DateTime? firstAnsweredAt;
  final int siblingPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRoot => parentId == null;

  static Outcome<void, DeckRejection> checkName(String name) =>
      name.trim().isEmpty
      ? const Rejected(DeckRejection.blankName)
      : const Ok(null);

  static Outcome<void, DeckRejection> checkCreateSubDeck({
    required int parentDepth,
  }) => parentDepth >= _maxDepth
      ? const Rejected(DeckRejection.depthExceeded)
      : const Ok(null);

  static Outcome<void, DeckRejection> checkCreateCard({
    required DeckContentType parentContentType,
  }) => parentContentType == DeckContentType.deck
      ? const Rejected(DeckRejection.notACardContainer)
      : const Ok(null);

  /// Whether moving `movingId` under `targetParentId` is allowed. The caller
  /// (the repository, inside its transaction) supplies:
  /// - [targetAncestorIds]: the target parent and every ancestor above it, so
  ///   this stays a pure comparison instead of a recursive query.
  /// - [targetDepth]: depth the target parent is at today.
  /// - [subtreeHeight]: how many levels deep the moving subtree goes below
  ///   `movingId` itself (a leaf has height 1).
  static Outcome<void, DeckRejection> checkMove({
    required String movingId,
    required String targetParentId,
    required List<String> targetAncestorIds,
    required int targetDepth,
    required int subtreeHeight,
    required SchedulerType? movingRootScheduler,
    required int? movingRootGeneration,
    required SchedulerType? targetRootScheduler,
    required int? targetRootGeneration,
  }) {
    if (targetParentId == movingId || targetAncestorIds.contains(movingId)) {
      return const Rejected(DeckRejection.movingIntoOwnSubtree);
    }
    if (targetDepth + subtreeHeight > _maxDepth) {
      return const Rejected(DeckRejection.depthExceeded);
    }
    if (movingRootScheduler != targetRootScheduler ||
        movingRootGeneration != targetRootGeneration) {
      return const Rejected(DeckRejection.subtreeSchedulerMismatch);
    }
    return const Ok(null);
  }
}
```

`lib/features/deck/domain/repositories/deck_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The one implementation is `DeckRepositoryImpl` (data layer, Task 7). The
/// contract exists so `domain/` stays framework-free and tests substitute a
/// fake — see ADR-010's "concrete architectural reason" note.
abstract interface class DeckRepository {
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
    DateTime? now,
  });

  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
    DateTime? now,
  });

  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  });

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId});

  Future<DeckEntity?> findById(String id);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/deck/domain/deck_entity_test.dart`
Expected: PASS.

- [ ] **Step 5: Import-boundary check**

Run: `flutter test test/architecture`
Expected: PASS — `deck/domain` imports only `core/error/` and `srs`'s public
`domain/models/`, along the `deck → srs` edge.

- [ ] **Step 6: Gate and commit**

```bash
dart format lib test
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/deck test/features/deck
git commit -m "feat(deck): add deck entity, pure tree rules and repository contract" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 7: `DeckRepositoryImpl` (transactional deck-tree operations)

**Files:**
- Create: `lib/features/deck/data/datasources/deck_dao.dart`,
  `lib/features/deck/data/repositories/deck_repository_impl.dart`,
  `lib/features/deck/di/deck_repository_provider.dart`
- Test: `test/features/deck/data/deck_repository_impl_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` and its Drift row class `Deck` (Task 5); `DeckEntity`
  and its rules `DeckEntity.checkName` / `checkCreateSubDeck` / `checkMove`,
  `DeckRepository`, `DeckRejection`, `DeckContentType` (Task 6); `schedulerFor`
  (Task 4, for the root's `scheduler_version`); `Outcome`, `mapDatabaseError`
  (Task 2).
- Produces: `class DeckRepositoryImpl implements DeckRepository` with
  constructor `DeckRepositoryImpl(AppDatabase db, {DateTime Function()? now})`;
  `Provider<DeckRepository> deckRepositoryProvider` (depends on `databaseProvider`)
  in `lib/features/deck/di/deck_repository_provider.dart`. A created or moved
  deck takes the end of its sibling group: its `siblingPosition` is the
  group's largest plus one, or `0` for the first child (deck/card backend
  spec §4, BR-SRS-007).

Every method runs inside `db.transaction(() async { ... })`. Per
`flutter-architecture`'s "a rule that needs the data as it stands at the
moment of writing does not go in a use case" — depth, content-type,
emptiness and subtree-move checks are evaluated on data read inside the same
transaction that writes, never hoisted above it.

- [ ] **Step 1: Write the failing repository tests**

`test/features/deck/data/deck_repository_impl_test.dart` — cover, with a fresh
`openTestDatabase()` per test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test('createRootDeck stores content_type deck, generation 1, own root_id', () async {
    final result = await repo.createRootDeck(name: 'Korean', schedulerType: SchedulerType.eightBox);
    final deck = (result as Ok<DeckEntity, DeckRejection>).value;
    expect(deck.contentType, DeckContentType.deck);
    expect(deck.generation, 1);
    expect(deck.rootId, deck.id);
    expect(deck.depth, 1);
  });

  test('createRootDeck rejects a blank name and writes nothing', () async {
    final result = await repo.createRootDeck(name: '   ', schedulerType: SchedulerType.eightBox);
    expect((result as Rejected<DeckEntity, DeckRejection>).reason, DeckRejection.blankName);
    final count = await db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle();
    expect(count.read<int>('n'), 0);
  });

  test('createSubDeck on a fresh root sets content_type unset', () async {
    final root = ((await repo.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final sub = ((await repo.createSubDeck(parentId: root.id, name: 's')) as Ok<DeckEntity, DeckRejection>).value;
    expect(sub.contentType, DeckContentType.unset);
    expect(sub.rootId, root.id);
    expect(sub.depth, 2);
  });

  test('creating a deck at depth 10 is rejected before any write', () async {
    var parentId = ((await repo.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value.id;
    for (var d = 2; d <= 10; d++) {
      parentId = ((await repo.createSubDeck(parentId: parentId, name: 'd$d')) as Ok<DeckEntity, DeckRejection>).value.id;
    }
    final r = await repo.createSubDeck(parentId: parentId, name: 'too deep');
    expect((r as Rejected<DeckEntity, DeckRejection>).reason, DeckRejection.depthExceeded);
  });

  test('emptying a sub-deck resets content_type to unset in the same transaction', () async {
    final root = ((await repo.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final sub = ((await repo.createSubDeck(parentId: root.id, name: 's')) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await repo.createSubDeck(parentId: sub.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;

    await repo.deleteDeck(deckId: leaf.id);

    final refreshed = await repo.findById(sub.id);
    expect(refreshed!.contentType, DeckContentType.unset);
  });

  test('moving a deck onto its own descendant is rejected and changes nothing', () async {
    final root = ((await repo.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final a = ((await repo.createSubDeck(parentId: root.id, name: 'a')) as Ok<DeckEntity, DeckRejection>).value;
    final b = ((await repo.createSubDeck(parentId: a.id, name: 'b')) as Ok<DeckEntity, DeckRejection>).value;

    final result = await repo.moveDeck(deckId: a.id, newParentId: b.id);
    expect((result as Rejected<void, DeckRejection>).reason, DeckRejection.movingIntoOwnSubtree);
    expect((await repo.findById(a.id))!.parentId, root.id);
  });

  test('moving a subtree updates root_id and depth for every descendant', () async {
    final rootA = ((await repo.createRootDeck(name: 'a', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(name: 'b', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final branch = ((await repo.createSubDeck(parentId: rootA.id, name: 'branch')) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await repo.createSubDeck(parentId: branch.id, name: 'leaf')) as Ok<DeckEntity, DeckRejection>).value;

    final result = await repo.moveDeck(deckId: branch.id, newParentId: rootB.id);
    expect(result, isA<Ok<void, DeckRejection>>());

    final movedBranch = await repo.findById(branch.id);
    final movedLeaf = await repo.findById(leaf.id);
    expect(movedBranch!.rootId, rootB.id);
    expect(movedBranch.depth, 2);
    expect(movedLeaf!.rootId, rootB.id);
    expect(movedLeaf.depth, 3);
  });

  test('moving a subtree under a root with a different scheduler is blocked', () async {
    final rootA = ((await repo.createRootDeck(name: 'a', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(name: 'b', schedulerType: SchedulerType.sm2)) as Ok<DeckEntity, DeckRejection>).value;
    final branch = ((await repo.createSubDeck(parentId: rootA.id, name: 'branch')) as Ok<DeckEntity, DeckRejection>).value;

    final result = await repo.moveDeck(deckId: branch.id, newParentId: rootB.id);
    expect((result as Rejected<void, DeckRejection>).reason, DeckRejection.subtreeSchedulerMismatch);
  });

  test('a root deck cannot move', () async {
    final rootA = ((await repo.createRootDeck(name: 'a', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(name: 'b', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;

    final result = await repo.moveDeck(deckId: rootA.id, newParentId: rootB.id);
    expect((result as Rejected<void, DeckRejection>).reason, DeckRejection.rootCannotMove);
  });

  test('a new deck goes to the end of its sibling group (BR-SRS-007)', () async {
    final rootA = ((await repo.createRootDeck(name: 'a', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(name: 'b', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final first = ((await repo.createSubDeck(parentId: rootA.id, name: 'first')) as Ok<DeckEntity, DeckRejection>).value;
    final second = ((await repo.createSubDeck(parentId: rootA.id, name: 'second')) as Ok<DeckEntity, DeckRejection>).value;
    await repo.deleteDeck(deckId: first.id);
    final third = ((await repo.createSubDeck(parentId: rootA.id, name: 'third')) as Ok<DeckEntity, DeckRejection>).value;
    final onlyUnderB = ((await repo.createSubDeck(parentId: rootB.id, name: 'only')) as Ok<DeckEntity, DeckRejection>).value;

    expect([rootA.siblingPosition, rootB.siblingPosition], [0, 1], reason: 'roots share the NULL-parent group');
    expect([first.siblingPosition, second.siblingPosition], [0, 1]);
    expect(third.siblingPosition, 2, reason: 'the end is the largest position plus one, not the sibling count');
    expect(onlyUnderB.siblingPosition, 0, reason: 'each parent numbers its own group');
  });

  test('a moved deck goes to the end of its new sibling group', () async {
    final rootA = ((await repo.createRootDeck(name: 'a', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(name: 'b', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final branch = ((await repo.createSubDeck(parentId: rootA.id, name: 'branch')) as Ok<DeckEntity, DeckRejection>).value;
    final gone = ((await repo.createSubDeck(parentId: rootB.id, name: 'gone')) as Ok<DeckEntity, DeckRejection>).value;
    final kept = ((await repo.createSubDeck(parentId: rootB.id, name: 'kept')) as Ok<DeckEntity, DeckRejection>).value;
    await repo.deleteDeck(deckId: gone.id);

    final result = await repo.moveDeck(deckId: branch.id, newParentId: rootB.id);

    expect(result, isA<Ok<void, DeckRejection>>());
    expect((await repo.findById(branch.id))!.siblingPosition, kept.siblingPosition + 1);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/deck/data/deck_repository_impl_test.dart`
Expected: FAIL — `DeckRepositoryImpl` does not exist.

- [ ] **Step 3: Implement `deck_dao.dart` and `deck_repository_impl.dart`**

`lib/features/deck/data/datasources/deck_dao.dart` wraps raw row access for
`deck` on `AppDatabase` — `Future<Deck?> findRow(String id)` (the Drift row
class from Task 5; a DAO never returns a domain entity), `subtreeIds`
(recursive `UNION`, per schema.md's "Duyệt cây" note: cycle-safe, never
depth-capped), `subtreeHeight` (probe query with a caller-supplied cap
constant), `ancestorIds`, and the raw `insert`/`update` calls
`DeckRepositoryImpl` composes inside its own transaction. It also answers
`Future<int> nextSiblingPosition(String? parentId)`, the end of a sibling
group; `IS` makes a `NULL` parent select the roots:

```sql
SELECT COALESCE(MAX(sibling_position) + 1, 0) AS next FROM deck WHERE parent_id IS ?
```

`lib/features/deck/data/repositories/deck_repository_impl.dart` implements
each `DeckRepository` method: run the matching `DeckEntity` rule(s) against
data read from the DAO inside `db.transaction`, then write via the DAO, mapping
each `Deck` row to a `DeckEntity` on the way out and any thrown DB error through
`mapDatabaseError` into `Rejected`/rethrow as appropriate. `createRootDeck`
writes `generation = 1`, `scheduler_version = schedulerFor(schedulerType).version`
and `scheduler_type` as `'eight_box'` or `'sm2'` (schema.md). `createRootDeck`
and `createSubDeck` write `sibling_position = nextSiblingPosition(parentId)`,
read inside their transaction. `moveDeck` additionally: rejects when
`deckId`'s row has `parentId == null` (`DeckRejection.rootCannotMove`) before
calling `DeckEntity.checkMove`; on success, updates `root_id`/`depth` for the
moving node and every descendant via the DAO's recursive CTE update
(BR-DECK-018); sets the moving deck's `sibling_position` to
`nextSiblingPosition(newParentId)`, read before its `parent_id` changes (its
descendants keep theirs: their parents do not change); recomputes
`content_type` on the old and new parent in the same transaction. `deleteDeck`
cascades via the DB's `ON DELETE CASCADE` and then recomputes the parent's
`content_type`.

`lib/features/deck/di/deck_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_repository_provider.g.dart';

@riverpod
DeckRepository deckRepository(Ref ref) => DeckRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 4: Generate and run to verify it passes**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/data/deck_repository_impl_test.dart
```

Expected: PASS.

- [ ] **Step 5: Import-boundary check**

Run: `flutter test test/architecture`
Expected: PASS — `deck/data` and `deck/di` may import Drift/Riverpod;
`deck/domain` still may not.

- [ ] **Step 6: Retire the `data` waiting entry, gate and commit**

This task adds the first `lib/features/*/data/` file, so the guard now reports
`guard.config.stale_targets_pending` for `memox.naming.data_file_role_suffix`.
Delete that entry, its `targets_pending: data` line and the group's comment line
(it starts with `# --` and names `data`) from
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/deck test/features/deck code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(deck): add transactional deck repository and provider" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 8: `ScheduleRepositoryImpl` (schedule rows, reviews, scheduler change, reset)

**Files:**
- Create: `lib/features/srs/data/datasources/srs_dao.dart`,
  `lib/features/srs/data/repositories/schedule_repository_impl.dart`,
  `lib/features/srs/domain/repositories/schedule_repository.dart`,
  `lib/features/srs/domain/failures/srs_failure.dart`,
  `lib/features/srs/di/schedule_repository_provider.dart`
- Modify: `lib/features/srs/domain/models/card_schedule_state_model.dart` (Task 3):
  add `CardScheduleState.initial`
- Test: `test/features/srs/domain/card_schedule_state_model_test.dart`,
  `test/features/srs/data/schedule_repository_impl_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Task 5); `SrsScheduler`, `schedulerFor`,
  `CardScheduleState`, `ReviewLogEntry`, `SchedulerType`, `EightBoxAction`,
  `Sm2Action` (Tasks 3–4); `Outcome`, `mapDatabaseError` (Task 2). `srs` imports
  no feature (ADR-011 import map: `srs → ∅`): it reads the card's `deck_id` and the
  root deck's `scheduler_type`/`scheduler_version`/`generation`/`first_answered_at`
  through its own DAO over the central tables in `lib/core/database/`.
- Produces:
  - `factory CardScheduleState.initial(SchedulerType type, {required int generation})`
    (`card_schedule_state_model.dart`): the start values of a schedule row
    (BR-CARD-004). Card creation, the scheduler change and the reset all write
    it; nothing else defines start values.
  - `enum SrsRejection { unsupportedAction, schedulerLocked, staleGeneration, notFound, notARootDeck }`
    (`srs_failure.dart`).
  - `abstract interface class ScheduleRepository` with
    `Future<void> initializeCard({required String cardId})`,
    `Future<Outcome<void, SrsRejection>> recordReview({required String cardId, required String sessionId, required Object action, DateTime? now})`,
    `Future<Outcome<void, SrsRejection>> resetLearning({required String rootDeckId})`,
    `Future<Outcome<void, SrsRejection>> changeScheduler({required String rootDeckId, required SchedulerType newType})`.
    Task 9's `CardRepositoryImpl.createCard` calls `initializeCard` inside its own
    transaction.
  - `class ScheduleRepositoryImpl implements ScheduleRepository` with constructor
    `ScheduleRepositoryImpl(AppDatabase db, {DateTime Function()? now})`.
  - `Provider<ScheduleRepository> scheduleRepositoryProvider` in
    `lib/features/srs/di/schedule_repository_provider.dart`.

- [ ] **Step 1: Write the failing start-values test**

`test/features/srs/domain/card_schedule_state_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

void main() {
  test('an eight_box card starts in box 1, unlearned and unscheduled (BR-CARD-004)', () {
    final state = CardScheduleState.initial(SchedulerType.eightBox, generation: 3);
    expect(state.generation, 3);
    expect(state.learnedAt, isNull);
    expect(state.dueAt, isNull);
    expect(state.lastAnsweredAt, isNull);
    expect(state.answerCount, 0);
    expect(state.lapseCount, 0);
    expect(state.currentBox, 1);
    expect(state.easeFactor, isNull);
    expect(state.intervalDays, isNull);
    expect(state.repetitions, isNull);
  });

  test('an sm2 card starts at ease 2.5, interval 0, repetition 0 (BR-CARD-004)', () {
    final state = CardScheduleState.initial(SchedulerType.sm2, generation: 1);
    expect(state.generation, 1);
    expect(state.learnedAt, isNull);
    expect(state.dueAt, isNull);
    expect(state.lastAnsweredAt, isNull);
    expect(state.answerCount, 0);
    expect(state.lapseCount, 0);
    expect(state.currentBox, isNull);
    expect(state.easeFactor, 2.5);
    expect(state.intervalDays, 0);
    expect(state.repetitions, 0);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/srs/domain/card_schedule_state_model_test.dart`
Expected: FAIL — `CardScheduleState` has no member `initial`.

- [ ] **Step 3: Add `CardScheduleState.initial`**

In `lib/features/srs/domain/models/card_schedule_state_model.dart`, import
`package:memox/features/srs/domain/models/scheduler_type_model.dart` and add this
factory next to the `eightBox`/`sm2` constructors:

```dart
  /// The row a card starts with (BR-CARD-004), and the row the scheduler
  /// change (BR-SRS-004) and the reset (BR-SRS-020) write again: nothing
  /// learned, nothing scheduled, the lowest level of [type], at [generation].
  factory CardScheduleState.initial(
    SchedulerType type, {
    required int generation,
  }) => switch (type) {
    SchedulerType.eightBox => CardScheduleState.eightBox(
      generation: generation,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      currentBox: 1,
    ),
    SchedulerType.sm2 => CardScheduleState.sm2(
      generation: generation,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
    ),
  };
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/srs/domain`
Expected: PASS, the Task 3 and Task 4 tests included.

- [ ] **Step 5: Write the failing repository tests**

`test/features/srs/data/schedule_repository_impl_test.dart`. The fixtures are raw
inserts: `srs` imports no feature, so its tests do not either. `_writes` reads
SQLite's `total_changes()`, so "writes nothing" is measured, not assumed.

```dart
import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

Future<void> _addCard(AppDatabase db, String cardId, String deckId) => db.customStatement(
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES (?, ?, 'f', 'b', 0, 0)",
  [cardId, deckId],
);

/// One tree per [rootId]: a root at generation 1 running [scheduler], a
/// sub-deck `<rootId>-leaf` holding one card, that card's start-value
/// schedule row, and an `in_progress` session of the root.
/// Returns (rootId, cardId, sessionId).
Future<(String, String, String)> _tree(
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
  await _addCard(db, cardId, '$rootId-leaf');
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
Future<String> _deepCard(AppDatabase db, String rootId) async {
  final cardId = '$rootId-deep-card';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'branch', ?, ?, 2, 'deck', 1, 0, 0), (?, 'deep', ?, ?, 3, 'card', 0, 0, 0)",
    ['$rootId-branch', rootId, rootId, '$rootId-deep', '$rootId-branch', rootId],
  );
  await _addCard(db, cardId, '$rootId-deep');
  await db.customStatement(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) '
    "VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  return cardId;
}

Future<QueryRow> _row(AppDatabase db, String table, String column, String id) => db
    .customSelect('SELECT * FROM $table WHERE $column = ?', variables: [Variable(id)])
    .getSingle();

Future<QueryRow> _deck(AppDatabase db, String id) => _row(db, 'deck', 'id', id);

Future<QueryRow> _schedule(AppDatabase db, String cardId) =>
    _row(db, 'card_schedule', 'card_id', cardId);

Future<QueryRow> _session(AppDatabase db, String id) => _row(db, 'study_session', 'id', id);

/// Rows inserted, updated or deleted on this connection so far: the same
/// number before and after a call proves the call wrote nothing.
Future<int> _writes(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle()).read<int>('n');

void _expectStartValues(QueryRow row, {required String scheduler, required int generation}) {
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

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 23);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  test('initializeCard writes the start values of the root scheduler at the root generation (BR-CARD-004)', () async {
    await _tree(db, 'r', scheduler: 'sm2');
    await db.customStatement("UPDATE deck SET generation = 3 WHERE id = 'r'");
    await _addCard(db, 'new', 'r-leaf');

    await repo.initializeCard(cardId: 'new');

    _expectStartValues(await _schedule(db, 'new'), scheduler: 'sm2', generation: 3);
  });

  test('initializeCard of a missing card throws', () async {
    await expectLater(repo.initializeCard(cardId: 'missing'), throwsStateError);
  });

  test('recordReview rejects an action the deck scheduler does not support', () async {
    final (_, cardId, sessionId) = await _tree(db, 'r'); // eight_box
    final result = await repo.recordReview(cardId: cardId, sessionId: sessionId, action: Sm2Action.good);
    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.unsupportedAction);
  });

  test('recordReview writes card_schedule and an append-only review_log row', () async {
    final (_, cardId, sessionId) = await _tree(db, 'r');
    final result = await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);
    expect(result, isA<Ok<void, SrsRejection>>());

    expect((await _schedule(db, cardId)).read<int>('current_box'), 2);
    final logCount = await db.customSelect(
      'SELECT COUNT(*) AS n FROM review_log WHERE card_id = ?',
      variables: [Variable(cardId)],
    ).getSingle();
    expect(logCount.read<int>('n'), 1);
  });

  test('reviewing a card deleted mid-session returns notFound and writes no log row', () async {
    final (_, cardId, sessionId) = await _tree(db, 'r');
    await db.customStatement('DELETE FROM card WHERE id = ?', [cardId]);

    final result = await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);
    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.notFound);
    final logCount = await db.customSelect('SELECT COUNT(*) AS n FROM review_log').getSingle();
    expect(logCount.read<int>('n'), 0);
  });

  test('a review from a stale-generation session is rejected, not applied', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.resetLearning(rootDeckId: rootId); // bumps generation to 2

    final result = await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);
    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.staleGeneration);
  });

  test('resetLearning bumps generation and recreates card_schedule', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);

    await repo.resetLearning(rootDeckId: rootId);

    expect((await _deck(db, rootId)).read<int>('generation'), 2);
    _expectStartValues(await _schedule(db, cardId), scheduler: 'eight_box', generation: 2);
  });

  test('resetLearning of an sm2 tree writes sm2 start values', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r', scheduler: 'sm2');
    await repo.recordReview(cardId: cardId, sessionId: sessionId, action: Sm2Action.good);

    await repo.resetLearning(rootDeckId: rootId);

    _expectStartValues(await _schedule(db, cardId), scheduler: 'sm2', generation: 2);
  });

  test('resetLearning unlocks the scheduler and closes the open sessions (BR-SRS-024, BR-STUDY-015)', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);

    await repo.resetLearning(rootDeckId: rootId);

    expect((await _deck(db, rootId)).data['first_answered_at'], isNull);
    final session = await _session(db, sessionId);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_reset');
    expect(session.data['ended_at'], isNotNull);
  });

  test('resetLearning of a sub-deck is rejected with notARootDeck and writes nothing', () async {
    await _tree(db, 'r');
    final before = await _writes(db);

    final result = await repo.resetLearning(rootDeckId: 'r-leaf');

    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.notARootDeck);
    expect(await _writes(db), before);
  });

  test('changeScheduler before the first review is allowed and keeps generation', () async {
    final (rootId, _, _) = await _tree(db, 'r');
    final result = await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);
    expect(result, isA<Ok<void, SrsRejection>>());

    final root = await _deck(db, rootId);
    expect(root.read<String>('scheduler_type'), 'sm2');
    expect(root.read<int>('generation'), 1, reason: 'BR-SRS-002: a change is not a reset');
  });

  test('changeScheduler starts every card of the tree over under the new scheduler (BR-SRS-004)', () async {
    final (rootId, cardId, _) = await _tree(db, 'r');
    final deepCardId = await _deepCard(db, rootId);

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    _expectStartValues(await _schedule(db, cardId), scheduler: 'sm2', generation: 1);
    _expectStartValues(await _schedule(db, deepCardId), scheduler: 'sm2', generation: 1);
  });

  test('changeScheduler closes the open sessions of the tree (BR-STUDY-016)', () async {
    final (rootId, _, sessionId) = await _tree(db, 'r');

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    final session = await _session(db, sessionId);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'scheduler_changed');
    expect(session.data['ended_at'], isNotNull);
  });

  test('changeScheduler leaves other trees alone', () async {
    final (rootId, _, _) = await _tree(db, 'r');
    final (_, otherCardId, otherSessionId) = await _tree(db, 'other');

    await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);

    _expectStartValues(await _schedule(db, otherCardId), scheduler: 'eight_box', generation: 1);
    expect((await _session(db, otherSessionId)).read<String>('status'), 'in_progress');
  });

  test('changeScheduler to the scheduler the root runs writes nothing (UC-DECK-002 A4)', () async {
    final (rootId, _, _) = await _tree(db, 'r');
    final before = await _writes(db);

    final result = await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.eightBox);

    expect(result, isA<Ok<void, SrsRejection>>());
    expect(await _writes(db), before);
  });

  test('the scheduler the root runs is a no-op on a locked tree too, not a rejection', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);
    final before = await _writes(db);

    final result = await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.eightBox);

    expect(result, isA<Ok<void, SrsRejection>>());
    expect(await _writes(db), before);
  });

  test('changeScheduler after the first review is rejected (locked)', () async {
    final (rootId, cardId, sessionId) = await _tree(db, 'r');
    await repo.recordReview(cardId: cardId, sessionId: sessionId, action: EightBoxAction.remembered);
    final before = await _writes(db);

    final result = await repo.changeScheduler(rootDeckId: rootId, newType: SchedulerType.sm2);
    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.schedulerLocked);
    expect(await _writes(db), before);
  });

  test('changeScheduler of a sub-deck is rejected with notARootDeck and writes nothing', () async {
    await _tree(db, 'r');
    final before = await _writes(db);

    final result = await repo.changeScheduler(rootDeckId: 'r-leaf', newType: SchedulerType.sm2);

    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.notARootDeck);
    expect(await _writes(db), before);
  });

  test('changeScheduler of a missing deck is notFound', () async {
    final result = await repo.changeScheduler(rootDeckId: 'missing', newType: SchedulerType.sm2);
    expect((result as Rejected<void, SrsRejection>).reason, SrsRejection.notFound);
  });
}
```

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test test/features/srs/data/schedule_repository_impl_test.dart`
Expected: FAIL — `ScheduleRepositoryImpl` does not exist.

- [ ] **Step 7: Implement `srs_failure.dart`, `schedule_repository.dart`, `srs_dao.dart`, `schedule_repository_impl.dart`**

`lib/features/srs/domain/failures/srs_failure.dart`:

```dart
/// Why the srs feature refuses a write (ADR-011 D6).
enum SrsRejection {
  /// The action is not in the deck scheduler's `supportedActions`.
  unsupportedAction,

  /// The scheduler is locked once the first card finished learning
  /// (BR-SRS-003); only Reset learning progress unlocks it (BR-SRS-024).
  schedulerLocked,

  /// The session's generation is older than the root's (BR-SRS-026).
  staleGeneration,

  /// The card, its schedule row or the deck no longer exists.
  notFound,

  /// The deck is a sub-deck: the scheduler and the generation live on its
  /// root (BR-DECK-025).
  notARootDeck,
}
```

`lib/features/srs/domain/repositories/schedule_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The one implementation is `ScheduleRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class ScheduleRepository {
  /// Writes the schedule row of a card just created (BR-CARD-004): the start
  /// values of its root's scheduler, at the root's generation. Joins the
  /// caller's transaction. Throws [StateError] when the card does not exist:
  /// the caller inserts the card first, in that same transaction, so a
  /// missing card is a bug, not a business outcome.
  Future<void> initializeCard({required String cardId});

  Future<Outcome<void, SrsRejection>> recordReview({
    required String cardId,
    required String sessionId,
    required Object action,
    DateTime? now,
  });

  /// Reset learning progress: a new generation, every schedule row of the
  /// tree back to its start values, the scheduler unlocked, the open sessions
  /// closed.
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
  });

  /// Changes the scheduler of an unlocked tree: every schedule row of the tree
  /// starts over under [newType] at the same generation, and the open sessions
  /// are closed. The scheduler the root already runs changes nothing.
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType newType,
  });
}
```

`srs_dao.dart` wraps raw row access for `card_schedule` and `review_log`, the
read of the owning root deck's `scheduler_type`/`scheduler_version`/`generation`/
`first_answered_at` (via `card.deck_id` → `deck.root_id`, never `COALESCE`), and
the tree-wide statements below. The `scheduler_type` text is `'eight_box'` or
`'sm2'` (schema.md). Datetimes are bound as `Variable<DateTime>`, never as a
hand-made epoch, so Drift's storage mode (Clarification 11) applies.

`schedule_repository_impl.dart`, every method inside one `db.transaction` (a
nested one joins the caller's transaction):

- `initializeCard` reads the card's root:

  ```sql
  SELECT root.scheduler_type, root.scheduler_version, root.generation
  FROM card c
  JOIN deck d ON d.id = c.deck_id
  JOIN deck root ON root.id = d.root_id
  WHERE c.id = ?
  ```

  No row throws `StateError`. Otherwise it inserts the row of
  `CardScheduleState.initial(type, generation: generation)` with the root's
  `scheduler_version`.
- `recordReview` loads the card's schedule row and its root deck's current
  scheduler/generation (`SrsRejection.notFound` if the card is gone); rejects an
  `action` outside `schedulerFor(type).supportedActions`
  (`SrsRejection.unsupportedAction`); rejects when the session's stored
  `generation` (read from `study_session`) differs from the root's current
  `generation` (`SrsRejection.staleGeneration`); otherwise calls
  `SrsScheduler.next`, writes the new `card_schedule` row and one `review_log`
  row, and — if this is the first `learnedAt` ever set for the root — sets
  `deck.first_answered_at` in the same transaction (BR-SRS-003).
- `changeScheduler` reads the deck row and answers, in this order:
  1. no row: `SrsRejection.notFound`;
  2. `parent_id IS NOT NULL`: `SrsRejection.notARootDeck`;
  3. `scheduler_type` is already `newType`: `Ok`, with no write (BR-SRS-002,
     UC-DECK-002 A4). This is checked before the lock, so it holds on a locked
     tree too (Clarification 13);
  4. `first_answered_at IS NOT NULL`: `SrsRejection.schedulerLocked`
     (BR-SRS-003);
  5. otherwise it updates the root, with `schedulerFor(newType).version`:

     ```sql
     UPDATE deck SET scheduler_type = ?, scheduler_version = ?, updated_at = ? WHERE id = ?
     ```

     then replaces the tree's rows with
     `CardScheduleState.initial(newType, generation: <the root's generation>)`
     (BR-SRS-004), and closes the tree's open sessions with
     `end_reason = 'scheduler_changed'` (BR-STUDY-016).
- `resetLearning` answers `notFound` and `notARootDeck` as `changeScheduler`
  does (Clarification 14), then:

  ```sql
  UPDATE deck SET generation = generation + 1, first_answered_at = NULL, updated_at = ? WHERE id = ?
  ```

  then replaces the tree's rows with
  `CardScheduleState.initial(<the root's scheduler>, generation: <the new generation>)`
  at the root's `scheduler_version`, and closes the tree's open sessions with
  `end_reason = 'scheduler_reset'` (BR-STUDY-015). `review_log` is never
  touched: it is append-only and kept across resets (BR-SRS-023).

Replacing the tree's rows is a delete and a re-insert (schema.md: a
`card_schedule` row is deleted and created again on reset). It covers every
card whose deck has this `root_id`, at any depth. Every inserted column is bound
from the `CardScheduleState` value, so `CardScheduleState.initial` stays the only
definition of the start values:

```sql
DELETE FROM card_schedule
WHERE card_id IN (
  SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id WHERE d.root_id = ?
);

INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation,
  learned_at, due_at, last_answered_at, answer_count, lapse_count,
  current_box, ease_factor, interval_days, repetitions)
SELECT c.id, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
FROM card c JOIN deck d ON d.id = c.deck_id
WHERE d.root_id = ?;
```

Closing the tree's open sessions sets `ended_at` to the repository's `now()`.
`srs` writes `study_session` here because no `study` feature exists yet
(Clarification 1):

```sql
UPDATE study_session
SET status = 'invalidated', end_reason = ?, ended_at = ?
WHERE root_id = ? AND status = 'in_progress';
```

`lib/features/srs/di/schedule_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_repository_provider.g.dart';

@riverpod
ScheduleRepository scheduleRepository(Ref ref) =>
    ScheduleRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 8: Generate and run to verify it passes**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/srs/data/schedule_repository_impl_test.dart
```

Expected: PASS.

- [ ] **Step 9: Import-boundary and full-suite check**

```bash
flutter test test/architecture
flutter test test/features/srs
```

Expected: PASS.

- [ ] **Step 10: Gate and commit**

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/srs test/features/srs
git commit -m "feat(srs): add transactional schedule repository (start values, review, reset, scheduler change)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 9: `CardRepositoryImpl`

**Files:**
- Create: `lib/features/card/domain/entities/card_entity.dart`,
  `lib/features/card/domain/failures/card_failure.dart`,
  `lib/features/card/domain/repositories/card_repository.dart`,
  `lib/features/card/data/datasources/card_dao.dart`,
  `lib/features/card/data/repositories/card_repository_impl.dart`,
  `lib/features/card/di/card_repository_provider.dart`
- Test: `test/features/card/data/card_repository_impl_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Task 5); `DeckEntity.checkCreateCard` and
  `DeckContentType` (Task 6, to check the parent deck's `content_type` and maintain
  it after create/delete — `card → deck` is an edge of the ADR-011 import map);
  `ScheduleRepository.initializeCard` and `scheduleRepositoryProvider` (Task 8, to
  write the card's schedule row — `card → srs` is an edge too); `Outcome`,
  `mapDatabaseError` (Task 2).
- Produces: `enum CardRejection { blankContent, notACardContainer, notFound }`
  (`card_failure.dart`); `final class CardEntity` mirroring `card` (schema.md, minus
  `delete_batch_id` which this plan does not expose), with the rule
  `static Outcome<void, CardRejection> checkContent({required String front, required String back})`
  (ADR-011 D7); `abstract interface class CardRepository` with
  `Future<Outcome<CardEntity, CardRejection>> createCard({required String deckId, required String front, required String back, String? example, String? hint, String? pronunciation, DateTime? now})`,
  `Future<Outcome<void, CardRejection>> deleteCard({required String cardId})`;
  `class CardRepositoryImpl implements CardRepository` with constructor
  `CardRepositoryImpl(AppDatabase db, ScheduleRepository schedules, {DateTime Function()? now})`;
  `Provider<CardRepository> cardRepositoryProvider` in
  `lib/features/card/di/card_repository_provider.dart`.

- [ ] **Step 1: Write the failing repository tests**

`test/features/card/data/card_repository_impl_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

import '../../../support/test_database.dart';

DateTime _now() => DateTime(2026, 9, 23);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle()).read<int>('n');

/// Fails the one call `createCard` makes, to prove that the card and its
/// schedule row are written in one transaction (BR-CARD-004).
final class _FailingScheduleRepository implements ScheduleRepository {
  @override
  Future<void> initializeCard({required String cardId}) async =>
      throw StateError('schedule row not written');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(db, ScheduleRepositoryImpl(db, now: _now), now: _now);
  });
  tearDown(() => db.close());

  test('creating a card sets content_type card on the (unset) parent deck', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;

    final result = await cards.createCard(deckId: leaf.id, front: 'front', back: 'back');
    expect(result, isA<Ok<CardEntity, CardRejection>>());
    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.card);
  });

  test('creating a card creates its schedule row from the root scheduler and generation (BR-CARD-004)', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.sm2)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;

    final card = ((await cards.createCard(deckId: leaf.id, front: 'f', back: 'b')) as Ok<CardEntity, CardRejection>).value;

    final row = await db.customSelect(
      'SELECT scheduler_type, generation, ease_factor, current_box, learned_at, due_at '
      'FROM card_schedule WHERE card_id = ?',
      variables: [Variable(card.id)],
    ).getSingle();
    expect(row.read<String>('scheduler_type'), 'sm2');
    expect(row.read<int>('generation'), 1);
    expect(row.read<double>('ease_factor'), 2.5);
    expect(row.data['current_box'], isNull);
    expect(row.data['learned_at'], isNull);
    expect(row.data['due_at'], isNull);
  });

  test('when the schedule row cannot be written, the card is not created either', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;
    final failing = CardRepositoryImpl(db, _FailingScheduleRepository(), now: _now);

    await expectLater(failing.createCard(deckId: leaf.id, front: 'f', back: 'b'), throwsA(anything));

    expect(await _count(db, 'card'), 0);
    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.unset);
  });

  test('a card cannot be created directly on a root deck', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final result = await cards.createCard(deckId: root.id, front: 'f', back: 'b');
    expect((result as Rejected<CardEntity, CardRejection>).reason, CardRejection.notACardContainer);
    expect(await _count(db, 'card'), 0);
    expect(await _count(db, 'card_schedule'), 0);
  });

  test('a card cannot be created in a deck that already holds sub-decks', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final branch = ((await decks.createSubDeck(parentId: root.id, name: 'b')) as Ok<DeckEntity, DeckRejection>).value;
    await decks.createSubDeck(parentId: branch.id, name: 'child');

    final result = await cards.createCard(deckId: branch.id, front: 'f', back: 'b');
    expect((result as Rejected<CardEntity, CardRejection>).reason, CardRejection.notACardContainer);
  });

  test('blank front or back is rejected', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;

    expect((await cards.createCard(deckId: leaf.id, front: '   ', back: 'b') as Rejected<CardEntity, CardRejection>).reason,
        CardRejection.blankContent);
    expect((await cards.createCard(deckId: leaf.id, front: 'f', back: '') as Rejected<CardEntity, CardRejection>).reason,
        CardRejection.blankContent);
  });

  test('optional example/hint/pronunciation trim to NULL, not empty string', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;

    final result = await cards.createCard(deckId: leaf.id, front: 'f', back: 'b', hint: '   ');
    expect((result as Ok<CardEntity, CardRejection>).value.hint, isNull);
  });

  test('front_folded/back_folded are Unicode-lowercase, not SQL lower()', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;

    final result = await cards.createCard(deckId: leaf.id, front: 'CÔNG NGHỆ', back: 'technology');
    final card = (result as Ok<CardEntity, CardRejection>).value;
    final row = await db.customSelect(
      'SELECT front_folded FROM card WHERE id = ?',
      variables: [Variable(card.id)],
    ).getSingle();
    expect(row.read<String>('front_folded'), 'công nghệ');
  });

  test('deleting the last card in a deck resets its content_type to unset', () async {
    final root = ((await decks.createRootDeck(name: 'r', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'l')) as Ok<DeckEntity, DeckRejection>).value;
    final card = ((await cards.createCard(deckId: leaf.id, front: 'f', back: 'b')) as Ok<CardEntity, CardRejection>).value;

    await cards.deleteCard(cardId: card.id);

    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.unset);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/card/data/card_repository_impl_test.dart`
Expected: FAIL — `CardRepositoryImpl` does not exist.

- [ ] **Step 3: Implement the reasons, the entity, the contract, `card_dao.dart` and `card_repository_impl.dart`**

`lib/features/card/domain/failures/card_failure.dart`:

```dart
/// Why the card feature refuses a write (ADR-011 D6).
enum CardRejection {
  /// BR-CARD-001: front or back is blank.
  blankContent,

  /// BR-DECK-004, BR-DECK-009: the target deck is a root or holds sub-decks.
  notACardContainer,

  /// The target deck, or the card, no longer exists.
  notFound,
}
```

`lib/features/card/domain/entities/card_entity.dart` (no `frontFolded`/`backFolded`
— those are a data-layer/search concern, not part of the domain entity):

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';

final class CardEntity {
  const CardEntity({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.isFlagged,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final bool isFlagged;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// BR-CARD-001: both faces carry text.
  static Outcome<void, CardRejection> checkContent({
    required String front,
    required String back,
  }) => front.trim().isEmpty || back.trim().isEmpty
      ? const Rejected(CardRejection.blankContent)
      : const Ok(null);
}
```

`lib/features/card/domain/repositories/card_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';

/// The one implementation is `CardRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class CardRepository {
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required String front,
    required String back,
    String? example,
    String? hint,
    String? pronunciation,
    DateTime? now,
  });

  Future<Outcome<void, CardRejection>> deleteCard({required String cardId});
}
```

`lib/features/card/data/datasources/card_dao.dart`: raw insert/delete on
`card`, computing `front_folded`/`back_folded` via
`value.trim().toLowerCase()` in Dart (never `LOWER()` in SQL, per
schema.md), and trimming `example`/`hint`/`pronunciation` to `null` when
blank.

`lib/features/card/data/repositories/card_repository_impl.dart`:
`CardRepositoryImpl(AppDatabase db, ScheduleRepository schedules, {DateTime Function()? now})`.
`createCard` runs inside `db.transaction`, in this order (UC-CARD-001 step 4):

1. `CardEntity.checkContent` (`CardRejection.blankContent`);
2. read the parent deck's `content_type` via the DAO and apply
   `DeckEntity.checkCreateCard`, answering `CardRejection.notACardContainer` when
   it refuses (`CardRejection.notFound` when the deck is gone);
3. insert the card;
4. `await schedules.initializeCard(cardId: <the new id>)`: the schedule row joins
   this transaction (BR-CARD-004);
5. if the parent was `unset`, update it to `card` (BR-DECK-008).

Nothing inside the transaction callback catches an exception: a throw leaves the
callback, and Drift rolls the card, its schedule row and the deck's
`content_type` back together. `deleteCard` deletes the row (its `card_schedule`
row and its review log go by cascade), then re-checks the parent: if no card
remains, set `content_type` back to `unset` in the same transaction
(BR-DECK-015, invariant 29).

`lib/features/card/di/card_repository_provider.dart` (`card/di` may import
`srs/di`: ADR-011 lets `di/` reach another feature's `di/` along an edge of the
import map). Both repositories get the one `AppDatabase` of `databaseProvider`,
which is what lets `initializeCard` join the card's transaction:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_repository_provider.g.dart';

@riverpod
CardRepository cardRepository(Ref ref) => CardRepositoryImpl(
  ref.watch(databaseProvider),
  ref.watch(scheduleRepositoryProvider),
);
```

- [ ] **Step 4: Generate and run to verify it passes**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/data/card_repository_impl_test.dart
```

Expected: PASS.

- [ ] **Step 5: Import-boundary check**

Run: `flutter test test/architecture`
Expected: PASS — `card` imports only `deck`'s and `srs`'s public buckets, and
`srs`'s `di/` from its own `di/`.

- [ ] **Step 6: Gate and commit**

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/card test/features/card
git commit -m "feat(card): add transactional card repository with schedule row and content-type maintenance" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_011wW1S4MF4eFSFWEhdj3FtD"
```

---

### Task 10: Provider retry policy and end-to-end smoke test

The UI base sub-project already created `lib/main.dart`, `lib/app/app.dart`,
the router and `test/app/app_test.dart`
(spec `2026-09-23-flutter-ui-base-design.md` §7). This task adds only what the
backend owns. It does not create or restructure `app.dart` or the router, and
the `app` guard entries it used to retire are already gone.

**Files:**
- Modify: `lib/main.dart` (the existing `ProviderScope`)
- Test: `test/integration/foundation_smoke_test.dart`

**Interfaces:**
- Consumes: `deckRepositoryProvider`, `cardRepositoryProvider`,
  `scheduleRepositoryProvider` (Tasks 7–9); `databaseProvider` (Task 5).
- Produces: Riverpod retry disabled at the `ProviderScope` root.

- [ ] **Step 1: Disable provider retry in `lib/main.dart`**

```dart
void main() {
  runApp(
    const ProviderScope(
      // DB errors are mapped to Failure explicitly (core/error/failure.dart);
      // Riverpod's default retry-on-error would otherwise sit a failed
      // provider in a hidden retry loop while showing AsyncLoading.
      retry: _noRetry,
      child: MemoxApp(),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
```

Run: `flutter test test/app`
Expected: PASS. The app tests still pump `ProviderScope(child: MemoxApp())`.

- [ ] **Step 2: Write the end-to-end smoke test**

`test/integration/foundation_smoke_test.dart` — the one test that proves the
whole foundation works together: create a root deck, a sub-deck, a card,
record two reviews (crossing the `learning` → `scheduled` boundary), reset
learning, and check the database is left in a state that passes every
`invariants_test.dart` query:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../support/test_database.dart';

void main() {
  test('deck -> card -> two reviews -> reset leaves a consistent database', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final now = DateTime(2026, 9, 23);
    final decks = DeckRepositoryImpl(db, now: () => now);
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(db, schedules, now: () => now);

    final root = ((await decks.createRootDeck(name: 'Korean', schedulerType: SchedulerType.eightBox)) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(parentId: root.id, name: 'Nouns')) as Ok<DeckEntity, DeckRejection>).value;
    final card = ((await cards.createCard(deckId: leaf.id, front: '사과', back: 'apple')) as Ok<CardEntity, CardRejection>).value;

    const sessionId = 'smoke-session';
    await db.customStatement(
      "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
      "status, cursor, card_limit, started_at) VALUES (?, ?, ?, 1, 'learning', 'self_assess', "
      "'in_progress', 0, 20, 0)",
      [sessionId, leaf.id, root.id],
    );

    expect(await schedules.recordReview(cardId: card.id, sessionId: sessionId, action: EightBoxAction.remembered),
        isA<Ok<void, SrsRejection>>());
    expect(await schedules.recordReview(cardId: card.id, sessionId: sessionId, action: EightBoxAction.remembered),
        isA<Ok<void, SrsRejection>>());
    expect(await schedules.resetLearning(rootDeckId: root.id), isA<Ok<void, SrsRejection>>());

    // Every invariant query from Task 5 still returns zero rows.
    final invariantQueries = <String>[
      // BR-DECK-004 (invariant 1)
      "SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id WHERE d.parent_id IS NULL AND c.delete_batch_id IS NULL",
      // invariant 9
      "SELECT s.card_id FROM card_schedule s JOIN card c ON c.id = s.card_id JOIN deck d ON d.id = c.deck_id "
          "JOIN deck root ON root.id = d.root_id WHERE s.generation <> root.generation OR s.scheduler_type <> root.scheduler_type",
      // add the remaining invariant queries this scenario can exercise
    ];
    for (final query in invariantQueries) {
      final rows = await db.customSelect(query).get();
      expect(rows, isEmpty, reason: query);
    }
  });
}
```

- [ ] **Step 3: Run to verify it passes**

Run: `flutter test test/integration/foundation_smoke_test.dart`
Expected: PASS.

- [ ] **Step 4: Run the full gate and commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/main.dart test/integration
git commit -m "feat(app): disable provider retry, add foundation smoke test" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: 0 analyzer issues, all tests pass, and every command exits 0.

---

## Plan self-review

**1. Spec coverage.** §1 intent (offline Android, no speculative layers):
Task 1. §3 decisions (Riverpod 3 codegen, Drift single source of truth,
go_router, no freezed, client UUIDs, feature-first): Tasks 1–2, 5, 7–9. §4
structure: superseded by ADR-010 and ADR-011 everywhere (Clarifications 3, 5,
10, File Structure, Tasks 2–10). §5 data model (three lifetimes, generation
column, SRS core): Tasks 3–5, 8. §6 deck tree rules (depth 10, root-only
cards, content_type maintenance, root_id, subtree move, scheduler lock):
Tasks 6–7. §7 data flow (transactional writes): Tasks 7–9. §8 errors
(`Outcome`, `Failure`, no auto-retry, no content logging): Tasks 2, 10. §9
testing (unit SRS, unit deck rules, Drift in-memory, migration snapshot,
import boundary): Tasks 1, 3–4, 5, 6–9. §10 open questions: superseded by
ADR-009 (modes/search/nav/tags in scope; Trash still deferred) — reflected
in Clarification 1 and Task 5 (`tags`/`card_tags` created; resolved with the
project owner on 2026-09-23). ADR-010 decisions 1–3: folder
names (File Structure), layering (Clarifications 3, 9, 10; Tasks 6–9),
Flutter version (Task 1, package table). schema.md's per-table scope notes:
Clarification 1, Task 5. The deck/card backend spec's stage 1 (§4): sibling
positions (Task 7); start values, `initializeCard`, the scheduler change and
the reset (Task 8); a card created with its schedule row (Task 9).

**2. Placeholder scan.** No "TBD"/"handle edge cases"/"similar to Task N"
strings. Every code step has real code or, where a full listing would only
repeat an established pattern across many similar items (the ~30-line
invariant test list in Task 5, the DAO/impl prose in Tasks 7–9), the plan
names the exact file, gives one worked example, and states the rule that
generates the rest (the invariant number/BR code, or "matches Task 7's
shape") rather than leaving a gap.

**3. Type consistency.** `Outcome<T, R>`/`Ok<T, R>`/`Rejected<T, R>`
(Task 2) are used in Tasks 6–10 with the refusing feature's reason enum as `R`:
`DeckRejection` (Task 6) in Tasks 6, 7, 9 and 10, `SrsRejection` (Task 8) in
Tasks 8 and 10, `CardRejection` (Task 9) in Tasks 9 and 10. `SchedulerType`,
`SrsScheduler`, `schedulerFor`, `CardScheduleState`, `ReviewLogEntry`,
`EightBoxAction`, `Sm2Action` (Tasks 3–4) are consumed unchanged by Task 8.
`DeckRepository`/`DeckEntity`/`DeckContentType` and the rules
`DeckEntity.check*` (Task 6) match what `DeckRepositoryImpl` (Task 7) and
`CardRepositoryImpl` (Task 9) use; the Drift row class stays `Deck` (Task 5).
Every import is a file path from the File Structure list; there is no barrel. `CardRepository`/`CardEntity` (Task 9) match Task 10's smoke test.
Provider names (`deckRepositoryProvider`, `scheduleRepositoryProvider`,
`cardRepositoryProvider`, `databaseProvider`) are declared once (Tasks 5,
7–9) and referenced, never redeclared, afterwards.
`CardScheduleState.initial`, `ScheduleRepository.initializeCard` and
`SrsRejection.notARootDeck` are declared once (Task 8); `CardRepositoryImpl(db,
schedules)` (Task 9) and Task 10's smoke test build on them.

**4. Review Focus.** All five items (blank name/content, unsupported
action, move-into-own-subtree, delete-mid-session, due-date month/year
boundary) each have an explicit test: blank name (Task 6,
`DeckEntity.checkName` tests; Task 9, blank front/back tests), unsupported action (Task 8,
`recordReview rejects an action the deck scheduler does not support`),
move-into-own-subtree (Task 6's `DeckEntity.checkMove` tests; Task 7's repository-level
test of the same name), delete-mid-session (Task 8's
`reviewing a card deleted mid-session` test), due-date boundary (Task 3's
month-end and 128-day year-end tests).
