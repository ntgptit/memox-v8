# Study history sync (SB-S4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `review_log` syncs as append-only history, and `card_schedule` syncs as a row. When a schedule is pulled, the schedule that has progressed further wins, so devices converge.

**Architecture:** A fifth Supabase migration adds `public.review_log` (insert-if-absent by id) and `public.card_schedule` (whole-row upsert keyed by `card_id`). Both are refused with `CARD_MISSING` for a card the server has never seen. For a tombstoned card they are acknowledged and dropped. Card and deck deletes now hard-delete the reviews and schedules of the tombstoned cards (card-sync plan R5). Drift schema 10 adds three outbox triggers: insert on `review_log`, and insert and update on `card_schedule`. The step seeds the existing rows. `ReviewLogSyncAdapter` inserts pulled rows if absent. `CardScheduleSyncAdapter` compares a pulled schedule with the local one using `compareScheduleProgress` (spec §3.4). It keeps the local row and re-queues it when that row has progressed further.

**Tech Stack:** Flutter 3.47.5, Drift, Riverpod 3, Supabase Postgres (PL/pgSQL, pgTAP).

**Spec:** [`docs/superpowers/specs/2026-09-28-sync-library-and-study-design.md`](../specs/2026-09-28-sync-library-and-study-design.md) §3.3–3.4, §4, §5; [ADR-017](../../shared/decisions/ADR-017-lich-srs-dong-bo-nhu-mot-dong.md). Previous slices: [card](2026-09-28-card-sync.md), [tag](2026-09-28-tag-sync.md), [account settings](2026-09-28-account-settings-sync.md); rulings R1–R12 still hold.

## Global Constraints

- Server integrity only. The server never computes a schedule (ADR-017). The CHECKs mirror `srs.drift`. New tables have RLS on, no policy and no client privilege. The migration ends with `revoke all on all functions in schema private from public, anon, authenticated;`.
- `review_log` is append-only on the device: its update trigger aborts, and its delete trigger aborts unless the card is gone. Sync never updates or deletes a review row.
- Reviews of every generation are kept (D3); none of them moves a schedule on the receiving device.
- The adapter order becomes `delete_batch, deck, tag, card, card_schedule, review_log, account_settings` (push order R6).
- `lib/core` never imports `lib/features`; a shipped Drift step never changes.

## Review Focus

1. **Two devices review the same card offline.** After both sync twice, both hold the schedule with the later `last_answered_at`, and both hold both reviews. Tested in Task 5.
2. **A reset on one device (generation + 1) against later reviews of the old generation on another.** The reset wins, and the old-generation reviews stay as history on both devices. Tested in Task 5.
3. **A review or schedule for a card that was deleted meanwhile.** It is acknowledged, not refused, so it neither sticks on screen 27 nor loops a retry. Tested in Task 1.
4. **A study turn queues exactly the schedule and the review.** Nothing is queued for a pulled review or schedule, or for `ensureSchedules`. Tested in Task 2.
5. **The same review pushed twice, from a retry after an ack was lost.** No duplicate row and no new version. Tested in Task 1.

## Rulings made while planning

- **R13 — a delete is acknowledged, not refused.** `review_log` and `card_schedule` have no delete operation (spec §3.3). The server answers a delete for either type `applied` with the user's current version and changes nothing. Only `requeueRejected` can produce such a delete, for a refused row whose card has since gone locally. A refusal there would keep it on screen 27 forever.
- **R14 — tombstoned card: drop; unknown card: refuse.** A review or schedule for a tombstoned card is `applied` and not stored, because its history went with the card. For a card the server has never seen, it is `CARD_MISSING` with `current: null`, so it is recorded and a later "Try again" can push it once the card is accepted.
- **R15 — no local `server_version` for these two tables.** `review_log` forbids updates, and nothing reads the value for schedules. Both acknowledgements are no-ops, as for account settings.
- **R16 — progress order in code.** `compareScheduleProgress(local, pulled, rootSchedulerType)` implements spec §3.4's five rules in order. It is a pure function with a test per rule.

## File Structure

| File | Responsibility |
|---|---|
| `supabase/migrations/20261002000000_study_history_sync.sql` (new) | `review_log`, `card_schedule`, their upserts/changes, deletes as no-ops, card/deck delete cascade, dispatch and feed |
| `supabase/tests/database/08_study_history_sync.sql` (new), `01_schema_privileges.sql` | pgTAP |
| `lib/core/database/tables/sync.drift`, `app_database.dart` | schema 10 triggers and seed |
| `lib/core/sync/schedule_progress.dart` (new) | `compareScheduleProgress` |
| `lib/core/sync/review_log_sync_adapter.dart`, `card_schedule_sync_adapter.dart` (new) | wire rows, pull rules |
| `lib/core/sync/di/sync_providers.dart` | adapter order |
| tests under `test/core/sync/`, `test/drift/`; docs |

---

### Task 1: Server

**Files:** Create `supabase/migrations/20261002000000_study_history_sync.sql`, `supabase/tests/database/08_study_history_sync.sql`; modify `01_schema_privileges.sql`.

**Interfaces:** Produces entity types `review_log` (entity id = review id) and `card_schedule` (entity id = card id), and the code `CARD_MISSING`. Wire rows:
- `review_log`: `id, cardId, sessionId, schedulerType, generation, kind, mode, outcomeReason, comparisonVersion, usedHint, direction, action, answeredAt, nextDueAt, previousBox, nextBox, previousEaseFactor, nextEaseFactor, previousIntervalDays, nextIntervalDays`.
- `card_schedule`: `schedulerType, schedulerVersion, generation, learnedAt, dueAt, lastAnsweredAt, answerCount, lapseCount, currentBox, easeFactor, intervalDays, repetitions`.

Times use the wire format; ints stay ints; `usedHint` is `0`, `1` or null, as Drift stores it.

- [ ] **Step 1: Failing pgTAP** `08_study_history_sync.sql` (helpers `t_uuid`, `t_root`, `t_card`, `t_op`, `t_push`, `t_change` as in `06_tag_sync.sql`, plus):

```sql
create function public.t_review(p_id uuid, p_card uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'cardId', p_card, 'sessionId', 's1', 'schedulerType', 'eight_box',
    'generation', 1, 'kind', 'scheduled', 'mode', 'self_assess', 'outcomeReason', null,
    'comparisonVersion', null, 'usedHint', null, 'direction', null, 'action', 'remembered',
    'answeredAt', '2026-09-28T10:00:00Z', 'nextDueAt', '2026-09-30T00:00:00Z', 'previousBox', 1, 'nextBox', 2,
    'previousEaseFactor', null, 'nextEaseFactor', null, 'previousIntervalDays', null, 'nextIntervalDays', null) $$;
create function public.t_schedule(p_answered text) returns jsonb language sql as $$
  select jsonb_build_object('schedulerType', 'eight_box', 'schedulerVersion', 1, 'generation', 1,
    'learnedAt', '2026-09-27T00:00:00Z', 'dueAt', '2026-09-30T00:00:00Z', 'lastAnsweredAt', p_answered,
    'answerCount', 3, 'lapseCount', 0, 'currentBox', 2, 'easeFactor', null, 'intervalDays', null,
    'repetitions', null) $$;
create function public.t_count(p_table text, p_card uuid) returns bigint language plpgsql security definer as $$
declare n bigint;
begin
  execute format('select count(*) from public.%I where card_id = $1', p_table) into n using p_card;
  return n;
end $$;
```

Assertions (plan 14), user A with root R(1), card K(10) in R:
1. R, K, schedule of K (`t_schedule('2026-09-28T10:00:00Z')`) and review V(50) of K are all `applied`.
2. `t_change(V)->'row'` equals `t_review(V, K)` with times in the `.000000Z` form.
3. `t_change(K)` for `card_schedule` needs the type. Add a helper `t_change2(p_type, p_id)` that filters `entityType` too; `->'row'->>'lastAnsweredAt'` = `'2026-09-28T10:00:00.000000Z'`.
4. The same review id under a new opId is `applied` with the same `serverVersion` as the first push, and `t_count('review_log', K)` stays 1.
5. A schedule upsert with `lastAnsweredAt` 11:00 is applied, and the feed shows 11:00 (whole-row upsert; the server does not compare).
6. A schedule with `currentBox` null for `eight_box` → `VALIDATION_FAILED`.
7. A review for an unknown card K404 → `CARD_MISSING`, `current` null.
8. A `review_log` delete of V → `applied`; `t_count('review_log', K)` is still 1 (R13).
9. A `card_schedule` delete of K → `applied`; the schedule is still there.
10. Card K2(11) with a review and a schedule, then a card delete of K2 → `applied`; `t_count('review_log', K2)` = 0.
11. `t_count('card_schedule', K2)` = 0.
12. A review for the now-tombstoned K2 → `applied` (R14), and `t_count('review_log', K2)` stays 0 (asserted in 13).
13. `t_count('review_log', K2)` = 0.
14. User B pushing review id V → `SYNC_ENTITY_CONFLICT`.

`01_schema_privileges.sql`: `plan(12)`; `has_table` for both tables; both names added to the three name lists; the RLS count becomes `10`.

- [ ] **Step 2: Run** — `bash tools/supabase/local_pgtap.sh` → `01` and `08` fail.

- [ ] **Step 3: Migration** —

```sql
-- SB-S4 / library and study sync spec §3.3–3.4, ADR-017: reviews sync as append-only history and schedules
-- as rows; the server never computes a schedule. Both go with their card.

create table public.review_log (
  id uuid primary key,
  user_id uuid not null,
  card_id uuid not null references public.card (id),
  session_id text not null,
  scheduler_type text not null check (scheduler_type in ('eight_box', 'sm2')),
  generation integer not null,
  kind text not null check (kind in ('learning', 'scheduled', 'relearning')),
  mode text not null check (mode in ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
  outcome_reason text check (outcome_reason is null or outcome_reason = 'timeout'),
  comparison_version integer,
  used_hint integer check (used_hint is null or used_hint in (0, 1)),
  direction text check (direction is null or direction in ('korean_to_meaning', 'meaning_to_korean')),
  action text not null check (action in ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')),
  answered_at timestamptz not null,
  next_due_at timestamptz,
  previous_box integer,
  next_box integer,
  previous_ease_factor double precision,
  next_ease_factor double precision,
  previous_interval_days integer,
  next_interval_days integer,
  server_version bigint not null,
  last_device_id uuid not null,
  check (mode = 'fill' or (comparison_version is null and used_hint is null)),
  check (outcome_reason is null or mode = 'recall')
);
create unique index uq_review_log_user_version on public.review_log (user_id, server_version);
create index idx_review_log_card on public.review_log (card_id);

create table public.card_schedule (
  card_id uuid primary key references public.card (id),
  user_id uuid not null,
  scheduler_type text not null check (scheduler_type in ('eight_box', 'sm2')),
  scheduler_version integer not null,
  generation integer not null,
  learned_at timestamptz,
  due_at timestamptz,
  last_answered_at timestamptz,
  answer_count integer not null,
  lapse_count integer not null,
  current_box integer check (current_box between 1 and 8),
  ease_factor double precision,
  interval_days integer,
  repetitions integer,
  server_version bigint not null,
  last_device_id uuid not null,
  check ((scheduler_type = 'eight_box') = (current_box is not null)),
  check ((scheduler_type = 'sm2') = (ease_factor is not null)),
  check ((ease_factor is null) = (interval_days is null)),
  check ((ease_factor is null) = (repetitions is null)),
  check (learned_at is not null or due_at is null)
);
create unique index uq_card_schedule_user_version on public.card_schedule (user_id, server_version);

alter table public.review_log enable row level security;
alter table public.card_schedule enable row level security;
revoke all on table public.review_log, public.card_schedule from public, anon, authenticated;
```

Functions, written in full in the migration:
- `private.review_log_change(r public.review_log)` and `private.card_schedule_change(s public.card_schedule)` build the wire rows above, times via `private.wire_time`. The schedule change's `entityId` is `s.card_id`. `deleted` is always `false`.
- `private.card_of(p_user uuid, p_card uuid) returns text`: `'live'`, `'tombstoned'`, or raises `SYNC_ENTITY_CONFLICT` for another user's card, or `CARD_MISSING` when unknown.
- `private.review_log_upsert(p_user, p_device, p_id, r)`:
  - `(r->>'id')::uuid` must equal `p_id`, else `VALIDATION_FAILED`.
  - An existing row of another user → `SYNC_ENTITY_CONFLICT`. An existing row of this user → return its `server_version`.
  - If `private.card_of` returns `'tombstoned'`, return `private.current_version(p_user)` (R14).
  - Otherwise allocate one version and insert.
- `private.card_schedule_upsert(p_user, p_device, p_id, r)`: the card check as above (tombstoned → current version), then one version and `insert … on conflict (card_id) do update set …` for every column. Another user's schedule row is impossible, because `card_of` already refused another user's card.
- `private.card_delete`: the SB-S3 body, plus `delete from public.review_log where card_id = p_id; delete from public.card_schedule where card_id = p_id;` next to the existing `card_tags` delete.
- `private.deck_delete`: the SB-S3 body, plus the same two deletes over `card_id in (<the live cards of v_deck_ids>)` next to the existing `card_tags` delete.
- `private.current_change`: `review_log` (by id and user) and `card_schedule` (by card id and user) branches.
- `private.apply_operation`: upsert branches for both. For `p_kind = 'delete'` with either type, `return private.current_version(p_user);` (R13).
- `private.push_one`: the type list gains both.
- `public.sync_changes`: two more `union all` branches (`'card_schedule', s.card_id, …` and `'review_log', r.id, …`).

Each `create or replace` copies its body from `20261001000000_account_settings_sync.sql` (or the latest migration that defines it) verbatim, plus only the stated change. End with the revoke.

- [ ] **Step 4: Run** — every pgTAP file is ok, `08 (14)`.
- [ ] **Step 5: Commit** — `SB-S4: server review_log and card_schedule; they go with their card`.

---

### Task 2: Drift schema 10 — triggers and seed

**Files:** `lib/core/database/tables/sync.drift`, `app_database.dart`; regenerate the schema files; tests `sync_triggers_test.dart`, `test/drift/migration_test.dart` (move the `nfc_migration_test.dart` targets from 9 to 10).

**Interfaces:** Produces the triggers `review_log_sync_insert` (`'review_log'`, `new.id`), `card_schedule_sync_insert` and `card_schedule_sync_update` (`'card_schedule'`, `new.card_id`). All three queue `upsert`, and all skip under `applying_remote`. There are no delete triggers.

- [ ] **Step 1: Failing tests** — in `sync_triggers_test.dart`, with `_root`, `_card` from before and:

```dart
Future<void> _schedule(AppDatabase db, String cardId) => db.customStatement(
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
  "answer_count, lapse_count, current_box) VALUES (?, 'eight_box', 1, 1, 0, 0, 1)",
  [cardId],
);

Future<void> _review(AppDatabase db, String id, String cardId) => db.customStatement(
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
  "\"action\", answered_at) VALUES (?, ?, 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 0)",
  [id, cardId],
);
```

```dart
  test('a turn queues its schedule and its review', () async {
    await _root(db, 'R');
    await _card(db, 'K', 'R');
    await _schedule(db, 'K');
    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement("UPDATE card_schedule SET answer_count = 1 WHERE card_id = 'K'");
    await _review(db, 'V', 'K');
    expect({for (final e in await _outbox(db)) '${e['entity_type']}/${e['entity_id']}': e['op']},
        {'card_schedule/K': 'upsert', 'review_log/V': 'upsert'});
  });

  test('pulled schedules and reviews queue nothing', () async {
    await _root(db, 'R');
    await _card(db, 'K', 'R');
    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      "INSERT INTO sync_state (name, value) VALUES ('$syncApplyingRemoteKey', '1')",
    );
    await _schedule(db, 'K');
    await _review(db, 'V', 'K');
    expect(await _outbox(db), isEmpty);
  });

  test('a card delete queues no schedule or review delete', () async {
    await _root(db, 'R');
    await _card(db, 'K', 'R');
    await _schedule(db, 'K');
    await _review(db, 'V', 'K');
    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement("DELETE FROM card WHERE id = 'K'");
    expect({for (final e in await _outbox(db)) '${e['entity_type']}/${e['entity_id']}': e['op']},
        {'card/K': 'delete'});
  });
```

Run → FAIL.

- [ ] **Step 2: Triggers** — in `sync.drift`, `import 'srs.drift';` and the three triggers, in the shape of `card_sync_insert`, each with a one-line comment (`SB-S4: …; reviews are append-only, so only inserts; a schedule is deleted only with its card, which the server handles.`). `schemaVersion => 10`; regenerate.

- [ ] **Step 3: Migration test** — move the `9` targets to `10`, add `v9 upgrades to the schema of v10`, and:

```dart
  test('a v9 database queues its schedules and its reviews', () async {
    final schema = await verifier.schemaAt(9);
    schema.rawDatabase
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, created_at, updated_at) "
        "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'R', 'f', 'b', 0, 0)",
      )
      ..execute(
        "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
        "answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 0, 0, 1)",
      )
      ..execute(
        "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
        "\"action\", answered_at) VALUES ('V2', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 2), "
        "('V1', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
      )
      ..execute('DELETE FROM sync_outbox');
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 10);
    final queued = await db
        .customSelect('SELECT entity_type, entity_id FROM sync_outbox ORDER BY rowid')
        .get();
    expect(queued.map((r) => '${r.read<String>('entity_type')}/${r.read<String>('entity_id')}'),
        ['card_schedule/K', 'review_log/V1', 'review_log/V2']);
  });
```

Run → FAIL.

- [ ] **Step 4: Step** —

```dart
      from9To10: (m, schema) async {
        // SB-S4: reviews and schedules sync (library and study sync spec
        // §3.3–3.4, ADR-017). Existing rows are queued: schedules, then
        // reviews oldest first.
        await m.createTrigger(schema.reviewLogSyncInsert);
        await m.createTrigger(schema.cardScheduleSyncInsert);
        await m.createTrigger(schema.cardScheduleSyncUpdate);
        await customStatement(
          _seedOutbox('card_schedule', '(SELECT card_id AS id FROM card_schedule)', 'id'),
        );
        await customStatement(
          _seedOutbox('review_log', '(SELECT id, answered_at FROM review_log)', 'answered_at, id'),
        );
      },
```

Run `flutter test test/drift/ test/core/sync/sync_triggers_test.dart` → PASS; `flutter analyze` clean.

- [ ] **Step 5: Commit** — `SB-S4: Drift schema 10 — schedule and review triggers, seed`.

---

### Task 3: `compareScheduleProgress` (R16)

**Files:** Create `lib/core/sync/schedule_progress.dart`, `test/core/sync/schedule_progress_test.dart`.

**Interfaces:** Produces:

```dart
/// What spec §3.4 compares; the rest of a schedule row does not take part.
typedef ScheduleProgress = ({
  int generation,
  String schedulerType,
  DateTime? lastAnsweredAt,
  DateTime? learnedAt,
  int answerCount,
});

/// Positive when [local] has progressed further than [pulled] (spec §3.4):
/// generation, then matching the root's scheduler, then the later answer
/// (none first), then learned over not, then more answers. Zero on a tie.
int compareScheduleProgress(
  ScheduleProgress local,
  ScheduleProgress pulled, {
  required String? rootSchedulerType,
});
```

- [ ] **Step 1: Failing tests** — one per rule, each with a pair differing only in that rule and the earlier rules equal, checking the sign both ways:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/schedule_progress.dart';

ScheduleProgress _p({
  int generation = 1,
  String type = 'eight_box',
  DateTime? answered,
  DateTime? learned,
  int answers = 0,
}) => (
  generation: generation,
  schedulerType: type,
  lastAnsweredAt: answered,
  learnedAt: learned,
  answerCount: answers,
);

void main() {
  final t1 = DateTime.utc(2026, 9, 28, 10);
  final t2 = DateTime.utc(2026, 9, 28, 11);

  int cmp(ScheduleProgress a, ScheduleProgress b, [String? root = 'eight_box']) =>
      compareScheduleProgress(a, b, rootSchedulerType: root);

  test('1: a higher generation wins, over any later answer', () {
    expect(cmp(_p(generation: 2), _p(answered: t2, answers: 9)), greaterThan(0));
    expect(cmp(_p(answered: t2, answers: 9), _p(generation: 2)), lessThan(0));
  });

  test("2: the root's scheduler wins at one generation", () {
    expect(cmp(_p(type: 'sm2'), _p(answered: t2), 'sm2'), greaterThan(0));
    expect(cmp(_p(answered: t2), _p(type: 'sm2'), 'sm2'), lessThan(0));
  });

  test('3: the later answer wins; no answer is earliest', () {
    expect(cmp(_p(answered: t2), _p(answered: t1)), greaterThan(0));
    expect(cmp(_p(answered: t1), _p()), greaterThan(0));
    expect(cmp(_p(), _p(answered: t1)), lessThan(0));
  });

  test('4: learned wins over not learned', () {
    expect(cmp(_p(answered: t1, learned: t1), _p(answered: t1)), greaterThan(0));
    expect(cmp(_p(answered: t1), _p(answered: t1, learned: t1)), lessThan(0));
  });

  test('5: more answers win', () {
    expect(cmp(_p(answered: t1, answers: 3), _p(answered: t1, answers: 2)), greaterThan(0));
  });

  test('a tie is zero, and an unknown root skips rule 2', () {
    expect(cmp(_p(answered: t1, answers: 2), _p(answered: t1, answers: 2)), 0);
    expect(cmp(_p(type: 'sm2'), _p(), null), 0);
  });
}
```

Run → FAIL.

- [ ] **Step 2: Implement** — each rule is a guard clause, returning the first non-zero result:

```dart
int compareScheduleProgress(
  ScheduleProgress local,
  ScheduleProgress pulled, {
  required String? rootSchedulerType,
}) {
  final generation = local.generation.compareTo(pulled.generation);
  if (generation != 0) return generation;
  if (rootSchedulerType != null) {
    final localMatches = local.schedulerType == rootSchedulerType;
    final pulledMatches = pulled.schedulerType == rootSchedulerType;
    if (localMatches != pulledMatches) return localMatches ? 1 : -1;
  }
  final answered = _compareNullsFirst(local.lastAnsweredAt, pulled.lastAnsweredAt);
  if (answered != 0) return answered;
  final learned = (local.learnedAt != null ? 1 : 0) - (pulled.learnedAt != null ? 1 : 0);
  if (learned != 0) return learned;
  return local.answerCount.compareTo(pulled.answerCount);
}

int _compareNullsFirst(DateTime? a, DateTime? b) {
  if (a == null || b == null) return (a == null ? 0 : 1) - (b == null ? 0 : 1);
  return a.compareTo(b);
}
```

Run → PASS. Commit — `SB-S4: the schedule progress order of spec §3.4`.

---

### Task 4: Adapters and wiring

**Files:** Create `lib/core/sync/review_log_sync_adapter.dart`, `card_schedule_sync_adapter.dart`, `test/core/sync/study_history_adapters_test.dart`; modify `di/sync_providers.dart` and the test `_Device`s (`sync_coordinator_test`, `card_sync_convergence_test`, `tag_sync_convergence_test`, `account_settings_sync_test`, `sync_bulk_test`). Insert the two adapters after `cards`: `CardScheduleSyncAdapter(db, store)` (in tests `SyncStore(db)`), then `ReviewLogSyncAdapter(db)`.

**Interfaces:**
- `ReviewLogSyncAdapter(AppDatabase db)`, `type = 'review_log'`. `readRow` returns every column in the wire form. `upsertFromServer` does `insertOrIgnore`. `deleteFromServer` and `markAcknowledged` are no-ops (R15).
- `CardScheduleSyncAdapter(AppDatabase db, SyncStore store, {DateTime Function() now = DateTime.now})`, `type = 'card_schedule'`. `readRow(cardId)` returns the row without `card_id`. `upsertFromServer(row, v)` works like this:
  - read the local row and the card's root `scheduler_type` (`card → deck → root`, Trash ignored, null when the card or root is not local);
  - with no local row, write the pulled row;
  - when `compareScheduleProgress(local, pulled, rootSchedulerType: root) > 0`, keep the local row and `store.enqueue('card_schedule', cardId, 'upsert', now())`;
  - otherwise `insertOnConflictUpdate` the pulled row.
  `deleteFromServer` and `markAcknowledged` are no-ops.

- [ ] **Step 1: Failing tests** `study_history_adapters_test.dart`:
  - (a) A review wire row round-trips (`upsertFromServer` then `readRow` gives the same map). A second `upsertFromServer` of the same id changes nothing and does not throw, even though the table forbids updates.
  - (b) A schedule wire row round-trips for `eight_box` and for `sm2`.
  - (c) A pulled schedule with an earlier `lastAnsweredAt` than the local one leaves the local row and queues `card_schedule/K`, under `applyingRemote`.
  - (d) A pulled schedule with a later answer replaces the local row and queues nothing.
  - (e) A pulled schedule of a higher generation replaces a local row with more answers.

  Use raw SQL for fixtures and `SyncStore.applyingRemote(deferForeignKeys: true, …)` around adapter writes. Run → FAIL.

- [ ] **Step 2: Implement** both adapters. Times use the `_time` pattern of the other adapters (drop the fraction). `usedHint` stays an int. The root lookup is one `customSelect`:
  `SELECT r.scheduler_type FROM card c JOIN deck d ON d.id = c.deck_id JOIN deck r ON r.id = d.root_id WHERE c.id = ?`.
  It reads Trash rows on purpose, so add a `tombstone_filter_test.dart` allowlist entry for `card_schedule_sync_adapter.dart#_rootSchedulerType`: "the order of spec §3.4 compares against the card's root in any state (SB-S4)". Do the same for any other flagged read, each with its reason.

- [ ] **Step 3: Wiring** — providers and the test `_Device`s as listed. Run `flutter test test/core/sync/ test/architecture/` → PASS.

- [ ] **Step 4: Commit** — `SB-S4: review and schedule adapters; the more advanced schedule stays and is pushed again`.

---

### Task 5: Convergence

**Files:** Create `test/core/sync/study_history_convergence_test.dart`.

- [ ] **Step 1** — two `_Device`s with every adapter, as in `account_settings_sync_test.dart` plus the two new ones. Fixture: root R (`eight_box`), card K, and an initial schedule on A, synced to B. Cases:
  1. **Offline on both:**
     - A: `UPDATE card_schedule SET last_answered_at = <10:00>, answer_count = 1` and a review `VA` at 10:00.
     - B: the same at 11:00 with review `VB`.
     - Sync order: A, B, A, B.
     - Both devices end with `last_answered_at` 11:00, reviews `{VA, VB}`, and empty outboxes.
  2. **Push order against the rule:** B syncs first, then A (A's older schedule reaches the server last), then B, then A. Both end at 11:00, which is the rule of §3.4, not the push order.
  3. **Reset against old-generation reviews:**
     - A: `UPDATE deck SET generation = 2 WHERE id = 'R'` and `UPDATE card_schedule SET generation = 2, last_answered_at = NULL, answer_count = 0, learned_at = NULL, due_at = NULL`.
     - B: an old-generation review `VB2` at 12:00 and its schedule update at generation 1.
     - Sync A, B, A, B. Both schedules are at generation 2, and both devices hold `VB2`.

  Run → PASS. If a case fails, use `superpowers:systematic-debugging` before changing code.

- [ ] **Step 2: Commit** — `SB-S4: study history converges across two devices`.

---

### Task 6: Docs, gate, WBS

- [ ] `schema.md`: the outbox `entity_type` list gains `card_schedule` and `review_log` (schema 10). The trigger paragraph names them (reviews insert only; schedules insert and update; neither is queued on delete). `flutter-data-layer` skill: "decks, trash batches, cards, tags, account settings, study history and schedules sync today".
- [ ] Gate: `dod_check.sh`, `local_pgtap.sh`, docs generate and check. A test that snapshots tables after a study write (as BR-TAG-009 did) may now see `sync_outbox`. Handle it with a ledgered ruling, as in SB-S3 and SB-S5.
- [ ] WBS: SB-S4 `xong` with the PR link; SB-S8 note: "every data type now syncs; what remains needs login (group C)". Add a dated line.
- [ ] Execution ledger; commit `SB-S4: docs, WBS and ledger`.

## Execution ledger

Executed inline (executing-plans) on 2026-09-28.

- Spec: docs/superpowers/specs/2026-09-28-sync-library-and-study-design.md; ADR-017
- Pre-flight:
- - T1→T4: wire keys of review_log/card_schedule rows — consistent.
- - T3→T4: compareScheduleProgress(local, pulled, rootSchedulerType:) — consistent.
- - T2→T4/T5: triggers skip under applying_remote; adapters write under it — consistent.
- Task 1: Ruling: added a 15th pgTAP assertion for the deck-delete path (reviews of its cards removed); the plan listed only the card-delete path — cost if wrong: none
- Task 1: complete (commits df58089..d367737, tests: bash tools/supabase/local_pgtap.sh → ok    08_study_history_sync.sql (15))
- Task 2: note: the v9→v10 migration test and from9To10 were added in one edit; the missing step is a compile error of stepByStep, the same RED as in earlier slices
- Task 2: complete (commits d367737..9cbb2c0, tests: flutter test test/drift/ test/core/sync/sync_triggers_test.dart → 00:03 +47: All tests passed!)
- Task 3: complete (commits 9cbb2c0..5480dc9, tests: flutter test test/core/sync/schedule_progress_test.dart → 00:00 +6: All tests passed!)
- Task 4: Ruling: the card_schedule wire row carries cardId (the server checks it equals the entity id), because EntitySyncAdapter.upsertFromServer receives no entity id; spec §3.4 said 'every column but card_id' — cost if wrong: one redundant field on the wire
- Task 4: Ruling: card_schedule_sync_adapter.dart#_rootSchedulerType joins the tombstone-read allowlist (the order compares against the root in any state)
- Task 4: complete (commits 5480dc9..4f69eec, tests: flutter test test/core/sync/ test/architecture/ → 00:12 +146: All tests passed!)
- Task 5: Ruling: case 2 needs six runs (b,a,b,a,b,a), not four: B keeps its more advanced schedule and pushes it on its next run, A takes it on the run after (spec §3.4 'after at most one more push'); case 3 likewise six runs; times compared as UTC — cost if wrong: none, the test counted rounds too low
- Task 5: complete (commits 4f69eec..1f518e4, tests: flutter test test/core/sync/ → 00:12 +106: All tests passed!)
- Task 6: Ruling: test/drift/migration_test.dart passed the guard's 400-line limit, so the sync seed tests (v6–v9 steps) moved to test/drift/sync_seed_migration_test.dart, unchanged — cost if wrong: none

Gate: `dod_check.sh` green (2610 tests), `tools/supabase/local_pgtap.sh` 121/121, docs check PASS.
