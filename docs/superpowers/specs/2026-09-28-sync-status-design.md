# SB-U1: sync failures are no longer silent — design

Status: draft 2026-09-28 ·
Path: architectural · Owner rulings 2026-09-28 (§3): R1–R7

## 1. Intent

Sync runs in the background and every failure is swallowed:

- `SyncScheduler._tick` catches any error (no connection, anonymous sign-in, a refused
  RPC), calls `log()` and backs off. Nothing records it.
- Nothing records when a sync last succeeded.
- A push result `rejected` with no `current` keeps the local row, drops the outbox entry
  and only calls `log()`. That row never reaches the server, and nobody knows.

The 2026-09-28 lesson (`wbs_supabase.md`, SB-U1): the release build lacked `INTERNET`,
`signInAnonymously` failed, and the app said nothing.

SB-U1 records what sync did and shows it:

- **Screen 23 "Settings":** a Sync section with one row naming the state; it opens
  screen 27.
- **Screen 27 "Sync" (new):** the last sync, what is waiting, the last problem, Sync now,
  and the changes the server refused, with Try again and Keep on this device.
- **Screen 13 "Study home":** a banner when a change has waited more than a day or the
  server refused one, with Details opening screen 27.

Success means:

- a failed run, a successful run and a refused row are each recorded in Drift and
  survive a restart;
- every state of screens 27 and 13's banner and every variant of the screen-23 row has a
  golden, light and dark;
- a build without Supabase shows none of it.

## 2. Context (2026-09-28)

- Sync: `lib/core/sync/` (`SyncScheduler`, `SyncCoordinator`, `SyncStore`,
  `SupabaseSyncApi`), wired in `lib/core/sync/di/sync_providers.dart`;
  `syncSchedulerProvider` is null when `SupabaseConfig.isEnabled` is false.
- Drift schema version 5. `sync_state` is a name/value table (`sync_keys.dart`);
  `sync_outbox` has one row per pending entity with `created_at`.
- Server codes on a refused row with no server copy: `SYNC_ENTITY_UNSUPPORTED`,
  `VALIDATION_FAILED`, `DECK_PARENT_MISSING`, `DECK_TREE_CYCLE`, `DECK_TREE_TOO_DEEP`
  (spec backend Supabase §4). With a server copy (`current`), the copy is applied: that
  is conflict resolution, not a failure.
- The kit (UI Kit v3) has no sync UI: v3 removed `OfflineBanner` because the product
  had no network then. The UI here comes from Impeccable `shape` (2026-09-28) and is a
  deviation recorded per screen (§8).
- Reused: `MxSection`, `MxSettingsRow`, `MxInlineBanner` (`warning`: a refusal or a
  limit, nothing lost), `MxButton`, `MxSnackbar`, `MxSkeletonList`; `DayClock`
  (`lib/core/clock/day_clock.dart`).

## 3. Decisions

| # | Decision | Source |
|---|---|---|
| R1 | Status in Settings, plus a banner on Study home when a problem lasts | Owner 2026-09-28 |
| R2 | Banner when a change has waited in the outbox more than 24 h, or any refused row remains | Owner 2026-09-28 |
| R3 | Refused rows are recorded per entity; screen 27 offers Try again (re-queue) | Owner 2026-09-28 |
| R4 | Status lives in Drift (`sync_state` keys and a `sync_rejection` table), read as a stream | Owner 2026-09-28 (approach A) |
| R5 | Settings has one row that opens screen 27 | Owner 2026-09-28 (shape) |
| R6 | Times are absolute: "Today, 14:32", "Yesterday, 09:10", "26 Sep, 14:32" | Owner 2026-09-28 (shape) |
| R7 | Keep on this device ends a refusal: the record goes, the data stays, nothing is pushed; the banner has no close button | Owner 2026-09-28 (shape) |

## 4. Structure

**Drift (schema 6):**

- `sync_rejection(entity_type TEXT, entity_id TEXT, code TEXT, rejected_at DATETIME,
  PRIMARY KEY (entity_type, entity_id))` in `sync.drift`. A later refusal of the same
  entity replaces its row.
- `sync_state` keys, in `sync_keys.dart`: `last_success_at`, `last_failure_at`,
  `last_failure_kind` (`network` · `signIn` · `server` · `unknown`). Times are UTC epoch
  seconds, as `created_at`.
- Migration 5 → 6 creates the table; a migration test covers it.

**`lib/core/sync/`:**

- `sync_failure.dart`: `enum SyncFailureKind` and a pure `classifySyncFailure(Object)`:
  - `network`: `SocketException`, `TimeoutException`, `http.ClientException` (the
    RPC's transport error) and `AuthRetryableFetchException` (the sign-in's);
  - `signIn`: any other `AuthException`;
  - `server`: `PostgrestException`, `FormatException`, `TypeError` from decoding;
  - `unknown`: anything else.
- `SyncStore` gains `recordSuccess(now)`, `recordFailure(kind, now)`,
  `recordRejection(type, id, code, now)`, `clearRejection(type, id)`,
  `rejections()`, `requeueRejected()`, `forgetRejected()`, and `watchStatus()`.
- `SyncCoordinator`: a refusal with no `current` calls `recordRejection` in the push
  transaction (it still keeps the row and drops the outbox entry); an `applied` result
  calls `clearRejection` for that entity.
- `SyncScheduler`:
  - records success or failure after each run (`recordSuccess` after a run that
    returned; `recordFailure(classifySyncFailure(error))` in the catch), through two
    callbacks so the scheduler stays free of Drift;
  - `syncNow()` returns a `Future<bool>`: it forgets the backoff and runs now, or joins
    the run in progress and runs again after it; true when that run succeeded.
- `sync_status.dart`: the immutable `SyncStatus` model — `lastSuccessAt`,
  `lastFailure` (kind and time, only when later than the last success), `pendingCount`,
  `oldestPendingAt`, `rejectedCount` — and the pure `needsAttention(status, now)`:
  true when `rejectedCount > 0`, or `oldestPendingAt` is more than 24 h before `now`.
- Providers in `sync_providers.dart`: `syncStatusProvider` (a stream; null when sync is
  off), and the three commands (`syncNow`, `retryRejected`, `keepRejectedLocal`) through
  a small controller in the settings feature.

**`requeueRejected()`** inserts an `upsert` outbox entry for each refused entity that
still exists locally and a `delete` for one that does not, in one transaction with fresh
op ids and `created_at = now`, and leaves the `sync_rejection` rows: the next push clears
or replaces them. **`forgetRejected()`** deletes every `sync_rejection` row and nothing
else.

**Presentation:**

- `lib/features/settings/`: `SettingsSyncSectionWidget` (screen 23), `SyncScreen`
  (screen 27, route `/settings/sync` on the root navigator like Theme and Language), its
  controller (a `Notifier` holding the task status: idle · syncing · retrying ·
  keeping), and `sync_labels.dart` (the status line and the failure sentence per kind,
  and the absolute-time formatter per R6 with `DateFormat` in the app locale).
- `lib/features/study/`: `StudyHomeSyncBannerWidget`, shown above the loaded content.
- `AppIcons.sync` (`Icons.cloud_sync_outlined`); no new shared widget.

## 5. Behaviour

### 5.1 The status line (screen 23 row subtitle, first match wins)

1. `rejectedCount > 0`: "{n} changes kept only on this device".
2. A last failure: "Couldn't sync · no connection" · "· couldn't sign in" · "· server
   error" · "· something went wrong".
3. A last success: "Synced {time}".
4. Otherwise: "Not synced yet".

### 5.2 Screen 27 states

| State | Shows |
|---|---|
| loading | `MxSkeletonList` |
| synced | Status section: Last synced {time}; Waiting to sync "Nothing waiting"; the note; Sync now |
| neverSynced | Last synced "Not yet" |
| pending | Waiting to sync "{n} changes" |
| failed | `warning` banner with the kind's sentence (§5.4) above the section |
| rejected | `warning` banner: title "{n} changes are kept only on this device", message "The server didn't accept them. They're safe here. Try again, or keep them on this device only.", buttons Try again · Keep on this device. Shown above a failure banner if both apply |
| syncing | Sync now shows a spinner and is disabled; Try again likewise while retrying |

Sync now → `syncNow()`; on true a snackbar "Synced", on false "Couldn't sync. Nothing
was lost." Try again → `requeueRejected()` then `syncNow()`, with the same snackbars.
Keep on this device → `forgetRejected()`, snackbar "Kept on this device". Only one of the
three runs at a time.

### 5.3 Screen 13 banner

Shown in every loaded state (including the empty ones) when `needsAttention` is true;
never while loading or on a read error. Message: rule 1 of §5.1 wins —
"{n} changes are kept only on this device." — else "Some changes haven't reached the
server for over a day. They're safe on this device." One compact button, Details, pushes
`/settings/sync`. `needsAttention` is re-evaluated whenever the status stream emits and
when the screen is rebuilt; no timer.

### 5.4 Failure sentences

- network: "No connection. Your changes are safe on this device and will sync when
  you're back online."
- signIn: "Couldn't sign in to sync. Your changes are safe on this device. MemoX will
  try again."
- server: "The server couldn't take the changes. They're safe on this device. MemoX will
  try again."
- unknown: "Sync stopped with an error. Your changes are safe on this device. MemoX will
  try again."

No code, id, SQL or message from the exception reaches the UI (BR-CORE-005).

## 6. Errors

- A write to `sync_state` or `sync_rejection` that fails inside a run fails that run
  (it is in the run's transaction or right after it) and is retried with it.
- `requeueRejected()` or `forgetRejected()` failing: snackbar "Couldn't change that.
  Nothing was lost." with Retry; state unchanged.
- The status stream erroring: screen 27 shows `MxErrorState` "Couldn't open Sync" with
  Retry; the screen-23 row and the screen-13 banner hide.

## 7. Tests

- Unit: `classifySyncFailure` (each kind); `needsAttention` (23 h 59 m vs 24 h 1 m,
  rejected only, nothing pending); the status line order; the time formatter (today,
  yesterday, older, both locales) with a fixed `DayClock`.
- `SyncStore` on an in-memory database: record/clear/replace a rejection;
  `requeueRejected` (existing entity → upsert, deleted → delete, rows kept);
  `forgetRejected`; `watchStatus` emitting on each change; last failure hidden once a
  later success exists.
- `SyncCoordinator` with the fake server: a refusal without `current` is recorded; a
  later `applied` clears it; a refusal with `current` is not recorded.
- `SyncScheduler`: success and failure recorded with the kind; `syncNow` result, joining
  a run in progress.
- Migration 5 → 6.
- Widget: screen 27 flows (Sync now, Try again, Keep on this device, failure snackbar);
  the screen-23 row hidden without Supabase; the screen-13 banner shown/hidden and
  Details navigating.
- Goldens (light, dark): screen 27 `synced`, `never_synced`, `pending`,
  `failed_network`, `failed_server`, `rejected`, `syncing`; screen 23 with the Sync row
  (synced, failed, rejected); screen 13 with each banner message.

## 8. Documents

- Screen handoff: new `27-sync.md`; `23-settings.md` (Sync section) and
  `13-study-home.md` (banner) gain the rows and a deviation each (kit v3 has no sync UI;
  Impeccable shape 2026-09-28); the index gains screen 27.
- `docs/shared/data/schema.md`: `sync_rejection` and the new `sync_state` keys.
- `wbs_supabase.md` SB-U1 and `wbs_FE.md` (the screen).

## 9. Out of scope

A sync log or history; per-entity detail of refused rows; banners on other screens;
changing retry or backoff; login (SB-A2); a sync indicator in the app bar.

## 10. Risks and rollback

- The 24 h rule reads the outbox's oldest `created_at`; a write updates an entry's
  `op_id` but keeps its `created_at`, so an entity edited all day still counts from its
  first unsent change — intended.
- `http` becomes a direct dependency so `ClientException` can be matched. It is already
  in `pubspec.lock` through `supabase_flutter`; the constraint follows the locked
  version, so nothing new is downloaded.
- Rollback: revert the PR. The migration only adds a table and keys; as with every
  schema bump, Drift refuses to open a schema-6 database with an older build, so a device
  that ran this build needs a build at schema 6 or later.
