# MemoX — app sync on the command protocol (BE-E7)

Status: approved 2026-09-28 · Path: architectural · WBS: BE-E7 in
[`wbs_BE.md`](../../wbs_BE.md) · Server side:
[API-A2 design](2026-09-27-api-command-protocol-deck-card-design.md) (merged in
[#118](https://github.com/ntgptit/memox-v8/pull/118)) · Replaces the capture
and push parts of the
[app deck sync design](2026-09-27-app-deck-sync-design.md) (#114) ·
Decisions: [ADR-013](../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md),
[ADR-014](../../shared/decisions/ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md)

## 1. Intent

The app keeps working offline from Drift, and syncs deck and card changes to
the server as the business commands of API-A2 instead of row upserts. Since
#118 the server rejects row upserts, so the app's sync does not work until
this slice ships.

Success means:

- **Every deck or card change the server has a command for reaches the server
  as that command,** from any write path: the deck and card repositories,
  card import, starter decks, and the root study options in settings.
- **A write path that forgets its command fails a test, not a user.**
- **The library already on a device is uploaded once, in causal order,** before
  any later edit.
- **A rejection never silently deletes a person's data,** unless another device
  purged its parent.
- **The pull applies a whole run in one transaction,** and card changes
  published before this slice are not missed.

Out of scope, and local-only until their server item ships (section 8):
Trash restore and purge (API-B3), tags (API-B2), and the SRS fields on
`deck` (API-B5).

## 2. Decisions

| # | Topic | Decision | Why |
|---|---|---|---|
| D1 | Capture | Repositories write commands and patches through `SyncOutbox`, in the same transaction as the change. The six capture triggers of #114 are removed | A command carries intent (a move, a reorder, an undo) that a row trigger cannot. The risk that a write path forgets its command is closed by D2 |
| D2 | `affected`, and the guard against a forgotten command | Per-connection TEMP triggers record every changed `deck`, `card` and `delete_batches` id in a TEMP table `sync_changed`. `SyncOutbox.command` and `patch` drain it, so `affected` is exactly what the write changed, plus the command's subject. The triggers never write the outbox: intent still comes from the repository. An audit test runs each write method and asserts that it recorded an outbox entry. Known gaps sit in an allowlist, each with its reason | `affected` is complete by construction instead of 16 hand-written lists. A forgotten command fails CI (owner's ruling, 2026-09-28) |
| D3 | Existing library | The v5 → v6 migration runs a Dart function that turns every row never acknowledged by the server into commands, in causal order | Commands queued in the migration always come before any later local write. Uploading on first sync instead would let a new card be pushed before its deck |
| D4 | `row: null` on a rejection | The local row is deleted only when the code is `DECK_PARENT_MISSING`. For any other code the row is kept, the rejection is logged, and the entry leaves the outbox | `DECK_PARENT_MISSING` with `row: null` means another device purged the parent, which the person asked for. Any other code is a bug or a legacy row, and deleting it would cascade away cards |
| D5 | Outbox while sync is off | The outbox is written even when the build has no `API_BASE_URL` | The app stays local-first: turning sync on later uploads everything |

## 3. Schema (Drift v6)

**`sync_outbox`**, replaced:

| Column | Type | Notes |
|---|---|---|
| `seq` | `INTEGER PRIMARY KEY AUTOINCREMENT` | Push order |
| `op_id` | `TEXT NOT NULL UNIQUE` | UUID; the idempotency key |
| `kind` | `TEXT NOT NULL CHECK (kind IN ('command','patch'))` | |
| `command_type` | `TEXT NULL` | Command type; `NULL` for a patch. Not `type`, which Drift would clash with |
| `entity_type` | `TEXT NULL` | Patch target; `NULL` for a command |
| `entity_id` | `TEXT NULL` | Patch target |
| `patch_group` | `TEXT NULL` | Patch field group. The name avoids `GROUP`, a reserved word |
| `payload` | `TEXT NULL` | JSON of a command |
| `affected` | `TEXT NOT NULL DEFAULT '[]'` | JSON list of `{entityType, entityId}` |
| `created_at` | `DATETIME NOT NULL` | |
| `attempts` | `INTEGER NOT NULL DEFAULT 0` | |

- A partial unique index on `(entity_type, entity_id, patch_group) WHERE kind = 'patch'` keeps one pending patch per field group.
- **`sync_state`** is unchanged. The `applying_remote` key is no longer used.
- **The six sync triggers are dropped.** The collector of D2 (`sync_changed` and its triggers) is TEMP, created on every open, and not part of the schema.
- `deck.server_version` and `delete_batches.server_version` stay. **`card` gains `server_version INTEGER NULL`**, meaning never acknowledged.

**Migration `from5To6`**, in one transaction:
1. drop the triggers and the old `sync_outbox`, and create the new one;
2. add `card.server_version`;
3. run `seedLibraryUpload(db)` (section 4.3);
4. set `since` to `0`.

A new schema snapshot and migration test follow BE-D1.

## 4. Writing commands

### 4.1 `SyncOutbox` (`lib/core/sync/sync_outbox.dart`)

```dart
Future<void> command(String type, Map<String, Object?> payload,
    {SyncEntityRef? subject, bool drainChanges = true});
Future<void> patch(String entityType, String entityId, String group,
    {bool drainChanges = true});
```

`affected` is the drained `sync_changed` ids plus `subject`. The migration's
seed (section 4.3) passes `drainChanges: false`, since the collector does not
exist during a migration.

- Both are called inside the repository's transaction.
- `patch` stores no field values. The coordinator reads the current fields at
  push time. A second patch of the same group keeps the first one's `seq` and
  gets a new `op_id`, so an acknowledgement of the older push cannot remove it.
- Payload keys and command types are those of API-A2 spec §5, with ids and
  times in wire form (UUID strings, ISO-8601 UTC).

### 4.2 Write paths

| Repository method | Outbox entry |
|---|---|
| `DeckRepositoryImpl.createRootDeck` | `CREATE_ROOT_DECK` |
| `createSubDeck` | `CREATE_SUB_DECK`; `affected` includes the parent |
| `renameDeck` | `RENAME_DECK` |
| `moveDeck` | `MOVE_DECK`; `affected` covers the subtree, the old parent and the new parent |
| `reorderDeck` | `REORDER_DECK`; `affected` covers every sibling whose position changed |
| `deleteDeck` | `DELETE_DECK` with the batch id; `affected` covers the batch, the subtree, its cards and the parent |
| `undoDeckDeletion` | `UNDO_DECK_DELETION`; `affected` covers the same rows as the delete |
| `CardRepositoryImpl.createCard` | `CREATE_CARD`; `affected` includes the deck |
| `editCard` | patch `card/content` |
| `setFlagged` | one patch `card/flag` per card |
| `moveCards` | `MOVE_CARDS`; `affected` covers the cards and both decks |
| `deleteCards` | `DELETE_CARDS` with one batch id per card |
| `undoCardDeletion` | `UNDO_CARD_DELETION` |
| `CardTransferRepositoryImpl.importCards` | one `CREATE_CARD` per imported card |
| `StarterLibraryRepositoryImpl.addStarterDeck` | `CREATE_ROOT_DECK`, `CREATE_SUB_DECK` and `CREATE_CARD` in tree order |
| settings: root study options saved or reset to the app defaults | patch `deck/study_options` |

The ids of new decks, cards and batches are the ones the repository already
generates with `newId()`; they are carried in the payload.

### 4.3 `seedLibraryUpload`

For rows with `server_version IS NULL`, in this order:

1. `CREATE_ROOT_DECK` for each root, by `sibling_position, id`;
2. `CREATE_SUB_DECK` for each sub-deck, by `depth, parent_id, sibling_position, id`;
3. `CREATE_CARD` for each card, by `deck_id, created_at, id`;
4. patch `card/flag` for flagged cards, and patch `deck/study_options` for roots with `study_config`;
5. for each Trash batch by `deleted_at`, `DELETE_DECK` or `DELETE_CARDS` with the batch's own id.

Step 5 makes the server's Trash match the device's.

Rows already acknowledged by an earlier server (`server_version` set, dev
devices only) are skipped. If the server still holds such a row, a create for
it is rejected with `CONFLICT`, and `current` overwrites the local copy.

## 5. Coordinator

- **Push:**
  - batches of 100 by `seq`, as `{opId, kind, type, payload, affected}`;
  - a patch reads its fields at push time through the entity's adapter
    (`readPatch(entityId, group)`);
  - a patch whose entity is gone is dropped.
- **Result `applied`:** the entry is removed if its `op_id` is unchanged.
  `server_version` arrives with the pull.
- **Result `rejected`:**
  - each item of `current` with a `row` overwrites the local row;
  - `row: null` with code `DECK_PARENT_MISSING` deletes the local row;
  - any other code keeps the row and logs `code` and the entity;
  - the entry is removed.
- **Pull:**
  - every page until `hasMore` is false, applied in **one** transaction with
    `PRAGMA defer_foreign_keys = ON`;
  - `since` is stored at commit;
  - a change is skipped while its entity is pending, meaning a patch targets
    it or a command lists it in `affected`.
- **Adapters:**
  - `deck`, `delete_batch` and a new `card` adapter write server rows. `card`
    recomputes `front_folded` and `back_folded` with `foldText`.
  - `readRow` is removed; `readPatch` is added for `deck` and `card`.
- **Unchanged:** triggers of a run (start, reconnect, outbox change debounced
  2 s), backoff, and a push 4xx being logged and backed off.

## 6. Error handling

- Network errors and 5xx keep entries and increase `attempts`, as before.
- A payload the app cannot build (for example a deleted row read at seed time)
  is skipped and logged. It is never sent half-filled.
- Rejections never reach the UI (ADR-013: sync is invisible). The log line
  carries the code, the entity type and the id, never card content
  (BR-TRASH-012).

## 7. Testing

- **Audit test** (`test/core/sync/sync_capture_audit_test.dart`):
  - one case per row of the section 4.2 table asserts that the write recorded
    an outbox entry, and that its `affected` covers every id the write changed
    (read from a test-only copy of the collector);
  - the allowlist names each gap of section 8 with its reason, and fails when
    an allowlisted path starts writing commands, so the list stays current.
- **Migration:** schema snapshot v6, the step test from v5, and a seeded
  library (roots, nested decks, cards, flagged cards, study options, a deck
  batch and a card batch) producing exactly the expected command sequence.
- **Coordinator, with a fake `SyncApi`:**
  - commands are not coalesced and patches are;
  - a patch reads current fields;
  - `current` as a list;
  - both `row: null` branches;
  - pending entities are skipped on pull;
  - a failure on page 2 rolls back page 1 and keeps `since`;
  - a `card` change applies with folded columns.
- **End to end:** the gate of the root README. The server's `SyncApiIT` already
  covers the other side.

## 8. Known gaps (local-only until their item ships)

| Change | Why it stays local | Closes with |
|---|---|---|
| Trash restore, and purge (manual and expired) | No server command yet | API-B3 + BE-E3 |
| Attaching, detaching, renaming, merging and deleting tags | No server command yet | API-B2 + BE-E2 |
| `deck.first_answered_at`, `generation` and scheduler changes, written by SRS | The server derives them from API-B5 on | API-B5 + BE-E4 |

- Another device does not see these changes, and a pull can overwrite them
  when the server sends a newer copy of the same row.
- Each gap is an allowlist entry in the audit test (section 7).

## 9. Amendment to the API-A2 design

§4.1 of the API-A2 design says the client deletes its local row when `current`
has `row: null`. With D4 it deletes the row only when the code is
`DECK_PARENT_MISSING`, and keeps and logs it otherwise. That design gets a
pointer to this section.
