# MemoX V8 — Foundation Design

Status: draft for review · Date: 2026-09-21 · Path: architectural

## 1. Intent

MemoX V8 is a new Flutter application, built from scratch. Its purpose is to
**rethink the product experience** (UX, UI, design system). The core learning
business is kept from V7; V7's architecture and implementation are not.

Success: a user creates decks and cards and reviews them daily on an SRS
schedule, fully offline on Android, on an architecture with no speculative
layers.

V7 (`D:\workspace\memox-v7`) is a business and behavioral reference only. Its
business rules are preserved unless this spec or a later approved V8 spec
changes them. V7 data compatibility is **not** required: V8 designs its own
schema and has no migration path from V7.

## 2. Scope

### In V8.0 (core learning)

- Deck tree and card CRUD, including V7 nesting rules (section 6).
- Two schedulers, `eight_box` and `sm2`, chosen per root deck.
- Study sessions and review by SRS schedule.
- Basic progress.
- Fully offline. Android only.

### Out of V8.0 (later sub-projects, each with its own spec → plan)

Trash, import/export, tags, daily reminders, starter decks, extended
statistics, iOS, web/desktop targets, sync/backend, auth, media (image/audio).

### Decomposition

1. **Foundation** — this spec.
2. **Product definition + UX/UI + design system** — led by Impeccable; runs
   before the UI of sub-project 3.
3. **Core learning slice** — deck/card CRUD → study/review → progress.
4. Later, one project each: the out-of-scope items above.

## 3. Decisions

| Topic | Decision |
|---|---|
| Platform | Android release target; local-only; no network; no auth |
| State | Riverpod 3 + `riverpod_generator` (codegen, chosen deliberately) |
| Database | Drift/SQLite, single source of truth; `watch()` streams feed the UI |
| Routing | `go_router`; top-level destinations are a UX decision owned by Impeccable |
| Models | Plain Dart 3 classes / `sealed` / records; **no freezed**, so codegen is only Riverpod + Drift |
| IDs | Client-generated UUIDs |
| Architecture | Feature-first, single package, pure-Dart SRS core (approach A) |

Exact dependency versions are pinned and verified against current docs when
the implementation plan is written. Riverpod 3 auto-retry behavior for DB
errors is verified then.

## 4. Structure

```
lib/
  main.dart
  app/            app widget, router, theme wiring
  core/           only what >=2 features share: DB connection, clock, id
  features/
    decks/  cards/  srs/  study/  progress/
```

- Each feature owns its data access, providers and UI. A `logic/` folder
  exists only when the feature has real logic.
- `srs` algorithm code is pure Dart: no Flutter or Drift imports.
- Dependency direction: `study`, `progress` → `srs`, `decks`, `cards`. `srs`
  depends on no feature. A feature never imports another feature's internals,
  only its public providers.
- `Scheduler` is the only interface, because it has two real implementations.
- No repository layer or single-implementation interface. Tests use in-memory
  Drift.
- A folder is created only when it holds a real file.
- Each feature declares its own Drift tables; `core/db` only assembles them
  into one `AppDatabase`.

## 5. Data model

Content, schedule and history are three separate concerns (preserved V7
business rule): editing a card never touches its schedule, and reset never
loses content or history.

| Table | Owner | Purpose | Notes |
|---|---|---|---|
| `deck` | `decks` | Name, tree position, scheduler, generation | See section 6 |
| `card` | `cards` | Content only (front/back) | No SRS columns |
| `card_schedule` | `srs` | Box or ease/interval, `due_at`, `generation` | Recreated on reset |
| `review_log` | `srs` | Append-only: action, `kind`, `generation`, time | `kind` is stored, never inferred |
| `study_session` | `study` | Status, end reason, `generation` | Stored, never inferred |

### SRS core

A pure function `next(state, action, now) -> state`, with time injected.
Each scheduler exposes `supportedActions`; the review UI renders buttons from
it.

| Scheduler | Actions |
|---|---|
| `eight_box` | `forgotten`, `remembered` |
| `sm2` | `again`, `hard`, `good`, `easy` |

The scheduler is chosen when a root deck is created and locked after the first
review; changing it afterwards requires Reset learning progress. Reset
increments `generation`. A review written from a session with a stale
`generation` is rejected, never applied.

## 6. Deck tree rules

Columns on `deck`: `parent_id`, `root_id` (stored), `depth`, `content_type`
(`unset` | `card` | `deck`). Scheduler and generation are stored **only on the
root**; descendants resolve them through `root_id`. Never use
`COALESCE(parent_id, id)` to find a root.

Rules, as pure Dart functions in `features/decks/` returning ok or a rejection
reason:

- Depth is at most 10 (root is level 1). Creating or moving past it is refused
  before anything is written.
- A root deck holds only sub-decks, never cards.
- A new sub-deck starts `unset`; its first child sets it to `card` or `deck`,
  and from then it holds only that kind.
- Emptying a sub-deck puts it back to `unset`, in the same transaction as the
  delete or move that removed the last child. There is no manual reset.
- Moving a subtree under a root with a different scheduler or generation is
  blocked, never silently converted.

Transactions: every write goes through one Drift transaction. Within a single
transaction: `content_type` maintenance; subtree move (update `root_id` and
`depth` of all descendants with a recursive CTE); reset and scheduler change
(increment `generation`).

Safety net: DB `CHECK (depth <= 10)` and foreign keys. The Dart rules are the
source of meaningful errors for the UI; the DB is the last line.

## 7. Data flow

- **Read:** Drift `watch()` → Riverpod provider → `AsyncValue` in the UI. The UI
  displays only; it holds no business logic.
- **Write:** a feature Notifier calls that feature's data class, which opens a
  transaction, runs the rules, writes, and returns a result.
- **Study session:** a Notifier holds session state. Each answer runs one
  transaction: check the session's `generation`, call `srs.next`, write
  `card_schedule` and `review_log`.

## 8. Errors

- Expected business rejections (depth, content type, stale generation) return
  a `sealed` result: `Ok` or `Rejected(reason)`. Not exceptions.
- Unexpected DB errors are mapped in one place into a few failures
  (constraint violation, DB locked, other); the UI shows `AsyncError` with
  retry.
- Riverpod auto-retry is disabled for DB errors so a failed provider does not
  sit in a loading state during hidden retries.
- Card content is never logged at any level. Card content, notes, history and
  exports are private data.

## 9. Testing

| Kind | Verifies |
|---|---|
| Unit, `srs` | Action → state tables for both schedulers, injected clock |
| Unit, deck rules | Depth 10, content type, subtree move |
| Drift in-memory | `content_type` maintenance, `root_id` update, reset, stale-generation rejection |
| Migration | Schema snapshots from the first commit |
| Widget | Key review-session states, including "nothing due today" |
| Import boundary | `srs` imports no Flutter/Drift; no feature imports another's internals |

Verification gate: `flutter analyze` and `flutter test`. Visual regression and
E2E are left to the design-system sub-project.

## 10. Open questions

Not decided here; owned by the named sub-project.

- Which of V7's six study modes (`browse`, `self_assess`, `match`, `guess`,
  `recall`, `fill`) ship in V8.0, and how a new-learning session differs from
  a review session — product definition (sub-project 2).
- Top-level navigation destinations, progress screen content — product
  definition (sub-project 2).
- Trash is deferred; V8.0 deletes are permanent cascades behind a confirmation.
  If product definition wants Trash in V8.0, add `deleted_at` to the schema.
