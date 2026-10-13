# What V8's database has already settled

Read this before proposing a structural change. Everything below is in the code
today; some of it deliberately differs from generic Drift guidance, and the
difference is a decision, not an oversight. Changing any of it is a task of its
own, with its own WBS entry — never a drive-by inside feature work.

The authority for tables, columns and invariants is
[`docs/shared/data/schema.md`](../../../../docs/shared/data/schema.md); the
decisions behind this file are ADR-001 (the platforms), ADR-002 (sensitive
data, no encryption), ADR-007 (UUID keys), ADR-008 (UTC), ADR-010/ADR-011 (the
layout), and ADR-013 with ADR-015 (the server is canonical, Drift is the
durable local store), in `docs/shared/decisions/`. Where this file and
`schema.md` differ, `schema.md` wins.

## The layout

```
lib/core/database/
├── app_database.dart            schemaVersion, migrations, beforeOpen
├── connection.dart              the only file that opens a database (ADR-002)
├── schema_versions.dart         generated step-by-step schemas (drift_schemas/)
├── table_changes.dart           the tables a read watches
├── di/database_provider.dart    @Riverpod(keepAlive: true), closes on dispose
├── id_chunks.dart               ids in batches under SQLite's bind limit
├── migrations/                  the data a migration step rewrites
├── tables/                      deck, card, tags, srs, study, settings, trash,
│                                sync (outbox, state, capture triggers)
└── queries/                     every query, by topic (.drift), included by
                                 the DAOs' @DriftAccessor (ADR-020)

lib/features/<feature>/data/
├── datasources/                 <name>_dao.dart · *_data_source.dart
├── mappers/                     row → entity, one file per shape
└── repositories/                <feature>_repository_impl.dart

drift_schemas/                   drift_schema_v<n>.json, one per released version
test/drift/                      migration_test.dart; generated/ holds the verifier
test/database/                   invariants_test.dart · schema_test.dart
                                 app_settings_row_test.dart · table_changes_test.dart
```

**Tables and queries are central, DAOs are feature-owned** (ADR-010 decision 2,
ADR-011). A generic feature-first checklist will tell you to put a feature's
`.drift` file under `lib/features/<feature>/data/local/`. This project does not,
because the schema is a single interlocking object: `card` references `deck`,
`card_schedule` and `review_log` reference `card`, `study_session` references
both trees, and `delete_batches` owns rows of `deck` and `card`. Splitting the
`.drift` files by feature would put cross-feature foreign keys in whichever
folder won an argument, while the DAO — the part that genuinely belongs to one
feature — is already feature-owned.

Since ADR-020 a query file is included by the accessors that use it, never by
`AppDatabase`: `@DriftDatabase` holds `tables/*.drift` only. A query file shared
by several accessors (`deck_queries.drift`) generates its result classes once
per accessor, so each feature reads its own DAO's copy. The log database keeps
its table and queries in `core/database/log/log.drift`. Migrations, `PRAGMA`
and `local_data_reset.dart` are the only Dart that may hold SQL.

## Connection and PRAGMA

- `openAppDatabase()` opens it through `driftDatabase(name: 'memox')` from
  `drift_flutter`, which uses a background isolate on native and the WASM worker
  on web. One call handles both because the Web build is the E2E channel
  (ADR-001) and must genuinely open.
- `PRAGMA foreign_keys = ON` in `beforeOpen`. Without it every
  `ON DELETE CASCADE` in the schema is a comment — SQLite defaults enforcement
  **off per connection**, so deletes would silently orphan rows.
- `beforeOpen` also inserts the one `app_settings` row if it is missing
  (BR-SETTINGS-001), so every surface reads real values from the first open.
- **No WAL, no `busy_timeout`, no read pool, no `synchronous` override.** Not an
  omission: this app has one writer and no read isolates, so the tuning would
  buy nothing measurable and would cost the web build. Add one only with a
  benchmark attached, and put it in `connection.dart` so "which PRAGMAs are set"
  keeps a single answer.
- Nothing in the connection path logs a path, an argument or a row. Card content
  and learning history are sensitive (ADR-002: no content in a log at any
  level); a database log would leak all of it at once.

## Identity, time and enums

| Contract | What this repo does | Why it matters later |
|---|---|---|
| Primary key | `TEXT` UUID, client-generated (ADR-007) | A backend cannot renumber rows a device already created |
| Ownership | `owner_id` on `deck`, `tags` and `delete_batches` is **retired**: always `NULL`, read only as the constant `owner_id IS NULL` and in `idx_tags_owner_name_folded` (DEV-198) | One profile per device: sign-in never namespaces local rows (auth spec O12, `LocalDataReset`); the server takes the owner from `auth.uid()`, never from the client (ADR-013, ADR-015). The column goes when its table is rebuilt for another reason (`migrations.md`) |
| Enums | stable lowercase text codes with a `CHECK` — `eight_box`, `sm2`, `unset`, `card`, `deck`, `learning`, `reviewing` | An ordinal would change meaning the day a value is inserted in the middle |
| Timestamps | `DATETIME` columns holding UTC (ADR-008); **no `build.yaml`**, so Drift's default storage applies | See the warning below |

**`DATETIME` is stored as Unix epoch seconds.** With no `build.yaml`, that is
Drift's default, and the first sync slice shipped on it: the wire carries
ISO-8601 UTC (ADR-008), and the adapters in `lib/core/sync/` convert at the
boundary, dropping the fraction of a second Drift does not store. Changing the
storage mode now is a data migration over every timestamp column and a change
to every adapter. Whoever proposes it writes an ADR in
`docs/shared/decisions/` and adds the `build.yaml` option in the same commit as
the migration.

## Reads, windows and pagination

- **The card list is a growing window**: the first `windowSize` cards in the
  query's order, re-read whole on every change, with no `OFFSET`
  (`card_list_dao.dart`, UC-CARD-001). An insert above the window cannot
  duplicate or drop a row the way a shifting offset does, and the cost is
  bounded by the window, not the deck. It reads one row past the window to tell
  whether more follow.
- **Keyset pagination where the user seeks deep**: a card's review history pages
  on `(answered_at DESC, id DESC)` after the last row shown (`cardHistoryPage`,
  BR-CARD-015), and library search pages by a cursor (`search_dao.dart`).
  Neither uses `OFFSET`.
- A read that feeds a screen is a `watch()` stream over the tables it names
  (`table_changes.dart`), so a write to any of them emits again.

## Two traps this schema has already paid for

**Resolve the root through `root_id`, never `COALESCE(parent_id, id)`**
(BR-DECK-003). That expression means "my parent, or me if I have none", which is
the correct root only in a one-level tree — from the third level down it
silently returns the level-2 deck. It is dangerous precisely because it works in
every test fixture anyone writes by hand. Every deck carries `root_id`,
including the root itself, so the resolution is a column read rather than a
recursion inside the hottest query in the app. The guard's
`memox.data_model.no_coalesce_parent_id` rule catches the expression.

**Moving a subtree rewrites `root_id` for every node in it, in one
transaction.** Miss a node and it points at the wrong root: queries still run and
merely return less than they should, which is corruption that reports itself as
a missing card rather than as an error. `schema.md` carries the query that
detects it, and `test/database/invariants_test.dart` runs it.

## What this schema does *not* do

Knowing the negatives prevents half of the bad suggestions:

- **Soft delete is a batch, not a flag.** A deck or card in the Trash carries a
  `delete_batch_id` that points at `delete_batches` (BR-TRASH-001); there is no
  `deleted_at`. Every read of active rows filters `delete_batch_id IS NULL`, and
  only a purge deletes a row (BR-TRASH-010).
- **No sync code in a repository.** `sync.drift` holds `sync_outbox` and
  `sync_state`, and its triggers queue each write to `deck` and
  `delete_batches` in the same statement; `server_version` on those two tables
  records the server's acknowledgement. Locally only `deck` and `card` read it
  back (the delete triggers keep it in the op's payload, DEV-181); on `tags`
  and `delete_batches` it is write-only, a diagnostic, as `sync_outbox.attempts`
  is (DEV-198). A table that does not sync yet has
  neither; its order is the priority of the `Supabase` issues in the Linear
  project MemoX (ADR-021).
- **No encryption.** ADR-002 decides it for now; opening the database in one
  place (`connection.dart`) keeps adding it a change to one function.
- **No `build.yaml`.** Adding one changes code generation for the whole repo —
  treat it as a schema-level decision.
- **No schedule columns in `card`.** Content (`card`), schedule
  (`card_schedule`) and history (`review_log`) are three tables with three
  lifetimes; a due date on `card` would break reset, which starts the schedule
  over and keeps the content (BR-SRS-021). The guard's
  `memox.data_model.no_schedule_columns_on_card_table` rule catches it.

## What "backend-ready" already means here

Decks sync today (BE-E1), and the other tables follow. Four things made that
possible, and each one would be expensive to retrofit:

- **IDs are client-generated**, so rows created offline can be referenced
  immediately and never need renumbering.
- **`owner_id` is retired, not pending**: always `NULL`, because a device holds
  one profile and sign-in resets local data instead of namespacing it (auth spec
  O12). It stays until its table is rebuilt for another reason (`migrations.md`).
- **Enum codes are stable text**, so the database, the DTOs and the domain
  share one vocabulary.
- **The migration path is tested from v1** (`test/drift/migration_test.dart`),
  which is what makes adding sync's tables and columns a routine change rather
  than a gamble.

ADR-013 and ADR-015 make the sync decisions once, so no feature makes them
again. Two of them shape the schema:

- **The server orders conflicts, not a device clock.** Every synced row
  carries the `server_version` the server gave it; last-write-wins keyed on a
  local `updated_at` is not a policy.
- **Not every table syncs.** `review_log` only grows and never conflicts;
  `card_schedule` is derived: only the app computes it, replaying the review
  log (ADR-013 #8, ADR-015); the study-session tables and the reminder
  settings stay on the device.

How a change travels (whole rows pushed through the outbox, changes pulled
after a `server_version` cursor) is ADR-013's, with its design in
`docs/superpowers/specs/2026-09-27-server-sync-design.md` and the Supabase
server in `docs/superpowers/specs/2026-09-28-supabase-backend-design.md`; the
deck slice as built is
`docs/superpowers/specs/2026-09-27-app-deck-sync-design.md`. The database's
part is only to make those states representable.

## Invariants are executable here

`schema.md` lists the data invariants as queries that must return no row, and
`test/database/invariants_test.dart` runs them against a real SQLite database
seeded with rows that satisfy all of them — no descendant points at the wrong
root, no deck nests deeper than ten levels, no schedule row carries another
scheduler or generation than its root, and so on. They are the reason a schema
change can be trusted beyond the diff.

**A new invariant belongs in `schema.md` and in that test, not in a comment.**
If a change introduces a rule the schema cannot express as a constraint, the
invariant test is where it becomes checkable.
`test/support/invariant_queries.dart` reads the queries out of `schema.md`
itself, so there is no copy to keep in step.
