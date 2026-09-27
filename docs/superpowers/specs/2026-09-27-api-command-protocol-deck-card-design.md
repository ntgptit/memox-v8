# MemoX API — command protocol, Deck and Card (API-A2)

Status: approved 2026-09-27 · Path: architectural · WBS: API-A2 in
[`wbs_API.md`](../../wbs_API.md) · Parent design:
[API authority and command sync](2026-09-27-api-authority-command-sync-design.md)
([ADR-014](../../shared/decisions/ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md))

## 1. Intent

This slice turns `memox-api-services` from a row-sync server into the business
backend for decks and cards. Push carries commands and field-group patches
instead of row upserts. Every deck and card operation runs in one service,
reached both by REST (for any client) and by replayed sync commands (from
Android).

Success means:

- every deck rule in BR-DECK-001…BR-DECK-025, and every card rule this slice
  covers, is enforced by the server, whichever entry point is used;
- REST and a sync command produce the same rows and the same versions for the
  same input;
- offline work under a parent that another device deleted is not lost: it
  follows the parent into Trash;
- `content_type` is derived by the server and never trusted from a client.

Out of scope:

- tags (API-B2);
- the schedule a card starts with (BR-CARD-004): the server computes schedules
  from API-B5 on;
- Trash restore and purge (API-B3);
- the folded search columns and every aggregate read (API-B7);
- batch card creation for import (API-B1);
- the app side (BE-E7, section 9).

## 2. Decisions

| # | Topic | Decision | Why |
|---|---|---|---|
| D1 | Cards in this slice | Card storage and its structural commands are built here, not in API-B1 | Deck rules depend on cards (`content_type`, BR-DECK-010, BR-DECK-022); without cards the server would derive a wrong `content_type` and overwrite the app on pull |
| D2 | Server shape | A service per capability with typed request DTOs. REST controllers bind the DTO from the body; a small `SyncCommandHandler` per command type reads the payload into the **same** DTO and calls the **same** method | Layering of `spring-boot-mybatis-review`; no command bus (repo rule: no speculative structure); Bean Validation runs identically on both entry points |
| D3 | Row upsert of PR #110/#114 | Retired at once. `DeckSyncHandler` and `DeleteBatchSyncHandler` are removed; the old `op: upsert|delete` shape is rejected with `VALIDATION_FAILED` | One write path per entity (ADR-014). Nothing is deployed and the app's sync only runs with `API_BASE_URL` set; real sync resumes with BE-E7 |
| D4 | Create under a parent in Trash | Created, and attached to the parent's delete batch. Rejected only when the parent is purged | Offline work is kept, and BR-DECK-022 already means "everything under a deleted deck is in Trash with it"; restoring the parent brings it back |
| D5 | Reads | Four basic reads: a level's decks, one deck, a deck's cards, one card. Active rows only | Enough for another client to show the tree and its content; aggregates are API-B7 |
| D6 | Text | Server applies NFC (`java.text.Normalizer`) and trim before validating lengths | The server is the authority; BE-C5's stored form must hold without trusting the client |
| D7 | Idempotency on REST | Optional `Idempotency-Key` header (a UUID), recorded in `sync_applied_op`. A replay writes nothing and returns the resource's current state with the original status code | Web retries become safe without storing response bodies |

## 3. Schema (Flyway `V4`)

- **`card`:**
  - `id uuid PK`, `user_id uuid NOT NULL`;
  - `deck_id uuid NOT NULL REFERENCES deck(id)`;
  - `front text NOT NULL`, `back text NOT NULL`;
  - `example`, `hint`, `pronunciation` as `text NULL`;
  - `is_flagged boolean NOT NULL DEFAULT false`;
  - `delete_batch_id uuid NULL REFERENCES delete_batch(id)`;
  - `created_at`, `updated_at` as `timestamptz NOT NULL`;
  - `server_version bigint NOT NULL`, `last_device_id uuid NOT NULL`;
  - `deleted_at timestamptz NULL`.

  Constraints and indexes:
  - `CHECK` lengths as in BR-CARD-001…BR-CARD-003, with the three optional
    fields never `''`;
  - unique `(user_id, server_version)`;
  - index `(deck_id)`.
- **`deck`:** unchanged columns. `delete_batch_id` gains a foreign key to
  `delete_batch(id)`.
- **Two kinds of "deleted":**
  - `delete_batch_id IS NOT NULL` means the row is **in Trash**: it is live
    for sync and hidden from active reads (BR-TRASH-002);
  - `deleted_at IS NOT NULL` means it is **purged**: a sync tombstone, which
    only API-B3 writes.
- **`delete_batch`:** unchanged. Rows are now written only by delete commands.

## 4. Protocol

### 4.1 Push operations

```json
{"opId": "…", "kind": "command", "type": "MOVE_DECK",
 "payload": {"deckId": "…", "targetParentId": "…"},
 "affected": [{"entityType": "deck", "entityId": "…"}]}

{"opId": "…", "kind": "patch", "entityType": "card", "entityId": "…",
 "group": "content", "fields": {"front": "…", "back": "…"}}
```

- `SyncOperation` becomes this shape. A missing or unknown `kind`, `type` or
  `group`, and the old `op` field, are rejected with `VALIDATION_FAILED`.
- Handlers are registered by command `type`, and patch handlers by
  `entityType` + `group`. They replace `SyncEntityHandler`.
- Idempotency, the per-operation transaction, the per-user advisory lock, and
  the `DataIntegrityViolationException` fallback of PR #110 are unchanged.
- **Rejection:** `current` is a list of the server's copies of the entities in
  `affected`:
  - entities another user owns are left out;
  - an entity the server has never seen, or has purged, comes back as
    `row: null`.

  `OperationResult.current` changes from one change to a list.
- **REST takes the same per-user lock** before it writes, so REST and sync
  operations of one user never interleave.

### 4.2 Readers and the change feed

- One `EntityReader` per `entityType` (`deck`, `card`, `delete_batch`). It
  serves `current` for rejections and `changesSince` for the feed.
- `changesSince` merges the readers by `serverVersion`, as today.
- A deck row in the feed now carries the server-derived `content_type`.
- **Change feed:** the feed gains `card`. Rows in Trash are live rows with
  `deleteBatchId` set; tombstones (`deleted: true`) come only from purges.

### 4.3 Versions

Every row a command changes gets a new `server_version` from the per-user
counter, including indirect changes:

- a parent's `content_type`;
- every row of a moved or deleted subtree;
- the old parent of a moved deck.

The service allocates one block per command, as `DeckSyncHandler` does today.

## 5. Commands

All ids are client-generated (ADR-007). A command's `payload` is the same DTO
as its REST body.

| Command | Payload | Rules |
|---|---|---|
| `CREATE_ROOT_DECK` | `id`, `name`, `schedulerType` | Server sets `scheduler_version` to the current algorithm version, `generation = 1`, `content_type = 'deck'`, and appends the deck after the last root |
| `CREATE_SUB_DECK` | `id`, `parentId`, `name` | Parent is `unset` or `deck` (BR-DECK-009, BR-DECK-010); `unset` becomes `deck` (BR-DECK-008); depth ≤ 10 (BR-DECK-001); new deck is `unset` (BR-DECK-006) and appended after its siblings |
| `RENAME_DECK` | `deckId`, `name` | BR-DECK-020; duplicates allowed (BR-DECK-021) |
| `MOVE_DECK` | `deckId`, `targetParentId` | UC-DECK-005 in order: not into itself or a descendant (BR-DECK-017); target `deck` or `unset` (BR-DECK-010); target root has the same `scheduler_type` and `generation` (BR-SRS-006); `targetDepth + subtreeHeight ≤ 10`. Then: target `unset` becomes `deck`; the old parent, if non-root and left with no active child, becomes `unset` (BR-DECK-015); the subtree's `root_id` and `depth` are rewritten (BR-DECK-018). Moving to root level is not a move (UC-DECK-005 A2) |
| `REORDER_DECK` | `deckId`, `anchorId`, `placement` (`before` \| `after`) | Anchor is a sibling; server recomputes `sibling_position` for the group (UC-DECK-006) |
| `DELETE_DECK` | `deckId`, `batchId`, `deletedAt` | One batch (`item_type = 'deck'`) marks the deck, its active descendants and their active cards (BR-DECK-022, BR-TRASH-001, BR-TRASH-003); the non-root parent left with no active child becomes `unset` (BR-TRASH-005) |
| `UNDO_DECK_DELETION` | `batchId` | Reverses exactly that batch to its original place (BR-TRASH-008), and re-derives the parent's `content_type` |
| `CREATE_CARD` | `id`, `deckId`, `front`, `back`, `example`, `hint`, `pronunciation` | Deck is a sub-deck with `unset` or `card`; `unset` becomes `card`; BR-CARD-001…BR-CARD-003 |
| `MOVE_CARDS` | `cardIds`, `targetDeckId` | Between sub-decks of the same root; target `unset` or `card`; source decks left empty become `unset`, target becomes `card` (BR-CARD-010); all or nothing (BR-CARD-011) |
| `DELETE_CARDS` | `items: [{cardId, batchId}]`, `deletedAt` | One batch per card (`item_type = 'card'`, BR-TRASH-001); decks left empty become `unset` (BR-TRASH-005); all or nothing |
| `UNDO_CARD_DELETION` | `batchId` | BR-TRASH-008; the deck's `content_type` is re-derived |

**Patches**

| Entity · group | Fields | Rules |
|---|---|---|
| `deck` · `study_options` | `studyConfig` (JSON or `null`) | Root only (BR-STUDY-056); `null` restores the defaults |
| `card` · `content` | `front`, `back`, `example`, `hint`, `pronunciation` | BR-CARD-001…BR-CARD-003, BR-CARD-005 |
| `card` · `flag` | `isFlagged` | BR-CARD-009 |

**Create under a parent in Trash (D4):**

- **When:** the parent (for `CREATE_SUB_DECK`) or the deck (for
  `CREATE_CARD`) is in Trash.
- **What the server does:** it creates the row with the parent's
  `delete_batch_id` and returns `applied`. The parent's `content_type`
  follows the usual rules.
- **Purged parent:** the operation is rejected with `DECK_PARENT_MISSING`,
  and `current` has `row: null`, so the client deletes its local row.
- **Other commands:** moving into, reordering against, or deleting under a
  deck in Trash is rejected with that deck in `current`.

**Common rules**

- Every command checks ownership. Another user's id is
  `SYNC_ENTITY_CONFLICT`, and a missing id is the command's `*_NOT_FOUND`.
- Commands on a row in Trash are rejected, except `UNDO_*`.

## 6. REST

Every route calls the service method its sync command calls, with the same
DTO.

| Method and path | Operation |
|---|---|
| `POST /api/v1/decks` | `CREATE_ROOT_DECK` |
| `POST /api/v1/decks/{id}/sub-decks` | `CREATE_SUB_DECK` |
| `PATCH /api/v1/decks/{id}` | `RENAME_DECK` |
| `POST /api/v1/decks/{id}/move` | `MOVE_DECK` |
| `POST /api/v1/decks/{id}/reorder` | `REORDER_DECK` |
| `PUT /api/v1/decks/{id}/study-options` | patch `study_options` |
| `DELETE /api/v1/decks/{id}` (body: `batchId`, `deletedAt`) | `DELETE_DECK` |
| `POST /api/v1/decks/{id}/cards` | `CREATE_CARD` |
| `PATCH /api/v1/cards/{id}` | patch `content` |
| `PUT /api/v1/cards/{id}/flag` | patch `flag` |
| `POST /api/v1/cards/move` | `MOVE_CARDS` |
| `POST /api/v1/cards/delete` | `DELETE_CARDS` |
| `POST /api/v1/trash/batches/{batchId}/undo` | `UNDO_DECK_DELETION` or `UNDO_CARD_DELETION`, by the batch's `item_type` |
| `GET /api/v1/decks?parentId=` | A level's active decks (roots when `parentId` is absent), by `sibling_position, id`, paged |
| `GET /api/v1/decks/{id}` | One active deck |
| `GET /api/v1/decks/{id}/cards` | A deck's active cards, paged |
| `GET /api/v1/cards/{id}` | One active card |

- **Status codes:** creates return `201` with the resource; other writes
  return `200` with the changed resource, or `204` for deletes and undo.
- **Errors:** RFC 9457 bodies (`GlobalExceptionHandler`); a rule violation is
  `409` with its code, and a missing resource is `404`.
- **Paging:** lists use `PageQuery` and `PagingResponse`.
- **Idempotency:** a request with an `Idempotency-Key` that was already
  recorded for the user writes nothing and returns the original status code
  with the current state. For a delete or an undo that current state is empty
  (`204`).
- **OpenAPI** documents every route (API-05).

## 7. Errors

New `ErrorCode` constants, each with its `messages.properties` text:

- `DECK_NOT_FOUND`;
- `DECK_CONTENT_TYPE_MISMATCH` (BR-DECK-009, BR-DECK-010);
- `DECK_SCHEDULER_MISMATCH` (BR-SRS-006);
- `DECK_IN_TRASH`;
- `DECK_ROOT_REQUIRED` (a root-only patch on a sub-deck);
- `CARD_NOT_FOUND`;
- `CARD_MOVE_CROSS_ROOT` (BR-CARD-010);
- `BATCH_NOT_FOUND`.

The tree codes of PR #110 and `SYNC_ENTITY_CONFLICT` are kept.
`SYNC_ENTITY_UNSUPPORTED` is replaced by `VALIDATION_FAILED` for unknown kinds,
types and groups.

## 8. Testing

Integration tests against PostgreSQL (Testcontainers), `./mvnw verify` with
coverage ≥ 80%:

- **Service, per rule:** each row of the section 5 tables has a test named
  after its BR, covering the rule and its rejection.
- **Parity:** for each command, REST and a replayed sync command on equal
  fixtures give the same rows and versions.
- **Trash parent (D4):** a create under a deck in Trash lands in its batch,
  and undo restores both; a create under a purged parent is rejected with
  `row: null`.
- **Protocol:**
  - a rejection lists `current` for every affected entity and never another
    user's;
  - a rejection does not stop the batch;
  - the old `op` shape and unknown types are `VALIDATION_FAILED`, never a `500`;
  - the same `opId` twice is applied once.
- **Versions:** indirect changes (parent `content_type`, old parent, subtree)
  appear in the change feed.
- **Idempotency-Key:** a replay writes nothing and returns the original
  status.
- **Concurrency:** the existing concurrency IT keeps passing with REST and
  sync interleaved.

## 9. Rollout and notes for BE-E7

The plan has three phases, each mergeable with a green gate:

1. The protocol and Deck: the new `SyncOperation`, handler registry,
   readers, deck commands, `study_options` patch, retirement of the row
   handlers, and D4 for decks.
2. Card: `V4`, the card commands and patches, card-aware `content_type`,
   `DELETE_DECK` with cards, and D4 for cards.
3. REST: controllers, `Idempotency-Key` and the four reads.

For BE-E7, the app side of this protocol:

- the app pushes card commands and patches as well as deck ones;
- the ids of new decks, cards and batches are generated by the use case and
  carried in the payload;
- `current` is now a list;
- **reset the pull cursor when the card adapter is added.** The current
  coordinator skips unknown entity types and still advances `since`
  (`lib/core/sync/sync_coordinator.dart`), so card changes pulled before
  BE-E7 would otherwise be missed for good.

## 10. Plan-time rulings

- A root cannot be moved, and a move to the deck's current parent is not a move:
  both are `VALIDATION_FAILED`, as the app refuses them (`rootCannotMove`,
  `sameParent`).
- Re-creating an id the user already owns is `CONFLICT`; another user's id is
  `SYNC_ENTITY_CONFLICT`.
- A command on a card in Trash is `CARD_IN_TRASH` (the card twin of
  `DECK_IN_TRASH`).
- Undo tombstones its `delete_batch` row, as the app deletes it
  (`DeckDao.restoreBatch`), and re-places the item under its parent at its old
  position.
- A sub-deck's derived `content_type` counts the children that share its own
  `delete_batch_id`, so a deck in Trash keeps its shape and a create under it
  (D4) marks it correctly before an undo.
- REST names its device with an optional `X-Device-Id` header; without it the
  row records `00000000-0000-0000-0000-000000000000`.
- `POST /api/v1/cards/move` answers `204`: it changes several cards, so there
  is no single resource to return.
- Deck lists order by `sibling_position, id`, and card lists by
  `created_at, id`; their sort enums have that one constant until API-B7.
