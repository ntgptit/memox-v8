# memox-api-services Command Protocol, Deck and Card (API-A2) Implementation Plan

> **Superseded 2026-09-28** by [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md)
> and the [Supabase backend design](../specs/2026-09-28-supabase-backend-design.md): the
> backend is Supabase and business rules stay in the app. Kept as history.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the row-sync server into the business backend for decks and cards: push carries commands and field-group patches, and every deck and card operation runs in one service reached by both REST and replayed sync commands.

**Architecture:**
- `sync` keeps the protocol:
  - idempotency by `opId`, one transaction per operation, the per-user lock, and the change feed;
  - it dispatches `command` operations to `SyncCommandHandler`s by `type`, and `patch` operations to `SyncPatchHandler`s by `entityType/group`;
  - it answers rejections with `EntityReader.current` for every affected entity.
- `DeckServiceImpl` and `CardServiceImpl` hold every rule and allocate one `server_version` per changed row through `ChangeVersions`.
- Handlers are one-line beans in `DeckSyncCommands` and `CardSyncCommands`. Each reads the payload into the same request DTO the REST controller binds.
- The row handlers of PR #110 and PR #114 are removed.

**Tech Stack:** Java 17, Spring Boot 3.5.16, MyBatis 3.5.19, PostgreSQL 18, Flyway 11, Jackson, Bean Validation, Apache Commons Lang 3, Lombok, JUnit 5, AssertJ, Testcontainers, MockMvc.

**Spec:** `docs/superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md` (API-A2). Parent: `docs/superpowers/specs/2026-09-27-api-authority-command-sync-design.md` (ADR-014).

## Global Constraints

- **Build and commits:**
  - Maven commands run from `memox-api-services/`. The gate is `./mvnw -B verify` (Docker required): tests, palantir format, and line coverage ≥ 80%. Run `./mvnw -B spotless:apply` before every commit.
  - Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Code conventions:**
  - Layering: Controller → `XxxService` (interface) → `XxxServiceImpl` → Mapper + XML. Controllers hold no rule, no mapper call and no `@Transactional`.
  - Objects with four or more fields are built with Lombok `@Builder`, never setter chains or positional constructors. MyBatis models carry `@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor`.
  - Use Apache Commons (`StringUtils`, `Validate`) before hand-written helpers.
- **Identity:**
  - The owner always comes from `CurrentUserProvider`. Every query filters on `user_id`.
  - Another user's id is `SYNC_ENTITY_CONFLICT`, except for a parent or target deck. A foreign parent is reported as missing (`DECK_PARENT_MISSING` / `DECK_NOT_FOUND`), so its existence never leaks.
- **Wire format of a push operation:**
  - `{opId, kind: "command"|"patch", type, entityType, entityId, group, payload, fields, affected: [{entityType, entityId}]}`.
  - `kind` is a string. A missing or unknown `kind`, `type` or `group`, a missing `entityId` on a patch, and the old `{op, row}` shape are each rejected **per operation** with `VALIDATION_FAILED`, never a 400 for the whole push and never a 500.
- **Results:**
  - Applied: `{opId, status: "applied", serverVersion}`, where `serverVersion` is the user's latest version after the operation.
  - Rejected: `{opId, status: "rejected", code, current: [SyncChange…]}`. `current` lists every entity in `affected`, plus the patch target, that the user owns.
  - An id the server has never seen is `{entityType, entityId, serverVersion: 0, deleted: true, row: null}`. A foreign id is left out.
- **Entity type strings:** `deck`, `card`, `delete_batch`.
- **Command types:** `CREATE_ROOT_DECK`, `CREATE_SUB_DECK`, `RENAME_DECK`, `MOVE_DECK`, `REORDER_DECK`, `DELETE_DECK`, `UNDO_DECK_DELETION`, `CREATE_CARD`, `MOVE_CARDS`, `DELETE_CARDS`, `UNDO_CARD_DELETION`.
- **Patch groups:** `deck/study_options`, `card/content`, `card/flag`.
- **Content types** are stored strings: `unset`, `card`, `deck`.
  - The server derives a sub-deck's `content_type` from its direct children that share its own `delete_batch_id` (both `NULL` for an active deck).
  - A root is always `deck`.
- **Scheduler versions:** `eight_box` → 1 and `sm2` → 1, matching Dart's `EightBoxScheduler.version` and `Sm2Scheduler.version`.
- **Limits:**
  - deck depth ≤ 10 (BR-DECK-001);
  - deck name 1–200 (BR-DECK-020);
  - card front 1–60, back 1–240, `example`/`hint`/`pronunciation` ≤ 240 (BR-CARD-001…003).
  - Lengths are counted in UTF-16 units, like Dart's `String.length`, after `strip()` and NFC. An optional field left blank is stored as `NULL`.
- **Times:**
  - `updated_at`, and `created_at` of new rows, come from the injected `Clock`;
  - `delete_batch.deleted_at` comes from the command (BR-TRASH-009 retention starts at the person's deletion).
- **Versions:** every changed row, direct or indirect, gets its own `server_version` from the per-user counter.
- **REST:**
  - base `/api/v1`;
  - `X-Device-Id` (UUID, optional) names the device; without it the device is `00000000-0000-0000-0000-000000000000`;
  - `Idempotency-Key` (UUID, optional) is recorded in `sync_applied_op`.
- **New error codes (409 unless noted), each with its `messages.properties` text:**
  - `DECK_NOT_FOUND` (404), `CARD_NOT_FOUND` (404), `BATCH_NOT_FOUND` (404);
  - `DECK_CONTENT_TYPE_MISMATCH`, `DECK_SCHEDULER_MISMATCH`, `DECK_IN_TRASH`, `CARD_IN_TRASH`, `CARD_MOVE_CROSS_ROOT`;
  - `DECK_ROOT_REQUIRED` (400).

  `SYNC_ENTITY_UNSUPPORTED` is removed.

## Review Focus

1. **The old app (#114) pushes `{op: "upsert", row}` or an unknown type.** The operation must be rejected with `VALIDATION_FAILED`, and the rest of the batch must still apply. Test in Task 5.
2. **A device creates a sub-deck, and cards in it, under a deck another device just deleted.** Everything lands in the deleted deck's batch, and undoing that batch brings it all back active with the right `content_type`. Tests in Task 4 (decks) and Task 7 (cards).
3. **Two devices move X under Y and Y under X at the same time,** or REST and sync write one user's tree at once. The tree must never hold a cycle. Test in Task 3.
4. **A rejection must never leak another user's row,** even when that user's ids are listed in `affected`. Test in Task 5.
5. **A move that re-parents a deck changes three rows indirectly:** the old parent's and the new parent's `content_type`, and every descendant's placement. Each must appear in the change feed so devices converge. Tests in Task 3 and Task 5.

---

## File map

Paths are under `memox-api-services/src/`.

| File | Task | Responsibility |
|---|---|---|
| `main/java/com/memox/sync/dto/request/{SyncOperation,AffectedEntity}.java` | 1 | new push operation shape |
| `main/java/com/memox/sync/dto/response/{OperationResult,SyncChange}.java` | 1 | `current` is a list; `SyncChange.absent` |
| `main/java/com/memox/sync/service/{WriteContext,SyncCommandHandler,SyncPatchHandler,EntityReader,PayloadReader,ChangeVersions}.java` | 1 | protocol contracts and helpers |
| `main/java/com/memox/sync/service/impl/{SyncServiceImpl,SyncOperationApplier}.java` | 1 | dispatch, rejection, feed |
| `main/java/com/memox/deck/{mapper/DeckMapper,service/impl/DeckReader}.java` + `mapper/deck/DeckMapper.xml` | 1 | deck reads (was `DeckSyncMapper`) |
| `main/java/com/memox/trash/{mapper/DeleteBatchMapper,service/impl/DeleteBatchReader}.java` + `mapper/trash/DeleteBatchMapper.xml` | 1 | batch reads (was `DeleteBatchSyncMapper`) |
| removed: `SyncEntityHandler`, `SyncOperationType`, `DeckSyncHandler`, `DeleteBatchSyncHandler` and their ITs | 1 | row sync retired |
| `test/java/com/memox/sync/SyncProtocolIT.java` | 1 | protocol tests with a test handler |
| `main/java/com/memox/common/util/TextRules.java` + test | 2 | NFC, strip, lengths |
| `main/java/com/memox/deck/{service/DeckService,service/impl/DeckServiceImpl,service/impl/DeckSyncCommands,model/DeckContentTypes,model/DeckPosition,dto/request/*}.java` | 2–4 | deck rules |
| `test/java/com/memox/deck/service/impl/DeckServiceImplIT.java` | 2–4 | deck rule tests |
| `test/java/com/memox/deck/service/impl/DeckMoveConcurrencyIT.java` | 3 | cross moves |
| `test/java/com/memox/sync/SyncApiIT.java` | 5 | end-to-end push/pull with deck commands |
| `main/resources/db/migration/V4__card.sql` | 6 | `card`, deck batch FK |
| `main/java/com/memox/card/{model/Card,dto/CardSyncRow,mapper/CardMapper,service/impl/CardReader}.java` + XML | 6 | card storage and feed |
| `main/java/com/memox/card/{service/CardService,service/impl/CardServiceImpl,service/impl/CardSyncCommands,dto/request/*}.java` | 7–8 | card rules |
| `test/java/com/memox/card/service/impl/CardServiceImplIT.java` | 7–8 | card rule tests |
| `main/java/com/memox/sync/service/{IdempotencyService,impl/IdempotencyServiceImpl}.java` | 9 | REST idempotency; `WriteContext.rest` reads the device header |
| `main/java/com/memox/deck/{controller/DeckController,dto/request/DeckListQuery,dto/response/DeckResponse,enums/DeckSortField}.java` | 9, 11 | deck REST |
| `main/java/com/memox/card/{controller/CardController,dto/request/CardListQuery,dto/response/CardResponse,enums/CardSortField}.java`, `main/java/com/memox/trash/{controller/TrashController,service/TrashService,service/impl/TrashServiceImpl}.java` | 10, 11 | card and undo REST |
| `test/java/com/memox/deck/controller/DeckControllerIT.java`, `test/java/com/memox/card/controller/CardControllerIT.java` | 9–11 | REST, parity, idempotency |
| `memox-api-services/README.md`, the two specs, `docs/wbs_API.md` | 5, 8, 11 | docs |

**Phases** (each ends with a green `./mvnw -B verify` and can be merged on its own):
- Phase 1, Tasks 1–5: the protocol and Deck.
- Phase 2, Tasks 6–8: Card.
- Phase 3, Tasks 9–11: REST.

---

## Phase 1 — protocol and Deck

### Task 1: Command protocol, readers, retirement of row sync

**Files:**
- Modify: `main/java/com/memox/sync/dto/request/SyncOperation.java`
- Create: `main/java/com/memox/sync/dto/request/AffectedEntity.java`
- Delete: `main/java/com/memox/sync/dto/request/SyncOperationType.java`
- Modify: `main/java/com/memox/sync/dto/response/OperationResult.java`, `main/java/com/memox/sync/dto/response/SyncChange.java`
- Create: `main/java/com/memox/sync/service/{WriteContext,SyncCommandHandler,SyncPatchHandler,EntityReader,PayloadReader,ChangeVersions}.java`
- Delete: `main/java/com/memox/sync/service/SyncEntityHandler.java`
- Modify: `main/java/com/memox/sync/service/impl/SyncServiceImpl.java`, `main/java/com/memox/sync/service/impl/SyncOperationApplier.java`, `main/java/com/memox/sync/service/package-info.java`
- Rename: `main/java/com/memox/deck/mapper/DeckSyncMapper.java` → `DeckMapper.java`; `main/resources/mapper/deck/DeckSyncMapper.xml` → `DeckMapper.xml`
- Rename: `main/java/com/memox/trash/mapper/DeleteBatchSyncMapper.java` → `DeleteBatchMapper.java`; `main/resources/mapper/trash/DeleteBatchSyncMapper.xml` → `DeleteBatchMapper.xml`
- Delete: `main/java/com/memox/deck/service/impl/DeckSyncHandler.java`, `main/java/com/memox/trash/service/impl/DeleteBatchSyncHandler.java`
- Create: `main/java/com/memox/deck/service/impl/DeckReader.java`, `main/java/com/memox/trash/service/impl/DeleteBatchReader.java`
- Modify: `main/java/com/memox/common/exception/ErrorCode.java`, `main/resources/messages.properties`
- Delete: `test/java/com/memox/deck/service/impl/DeckSyncHandlerIT.java`, `test/java/com/memox/trash/service/impl/DeleteBatchSyncHandlerIT.java`, `test/java/com/memox/sync/service/impl/SyncOperationApplierConcurrencyIT.java`, `test/java/com/memox/sync/SyncApiIT.java`. Their deck cases return in Tasks 2–5, and the concurrency case in Task 3.
- Test: `test/java/com/memox/sync/SyncProtocolIT.java`

**Interfaces:**
- Produces:
  - `record WriteContext(UUID userId, UUID deviceId)`, with `WriteContext.REST_DEVICE`;
  - `record SyncCommandHandler(String type, BiConsumer<WriteContext, JsonNode> body)`;
  - `record SyncPatchHandler(String entityType, String group, SyncPatchHandler.Applier applier)`, with `Applier.apply(WriteContext, UUID entityId, JsonNode fields)`;
  - `interface EntityReader { String entityType(); SyncChange current(UUID userId, UUID entityId); List<SyncChange> changesSince(UUID userId, long since, int limit); }`;
  - `PayloadReader.read(JsonNode, Class<T>)` and `PayloadReader.id(JsonNode, String field)`;
  - `ChangeVersions.lock(WriteContext)`, `next(WriteContext)`, `block(WriteContext, int count)` (returns the first version) and `latest(UUID userId)`;
  - `SyncChange.absent(String entityType, UUID entityId)`;
  - `DeckMapper` keeps `findDeckById`, `findLiveSubtree`, `updateSubtreePlacement` and `findChangesSince`; `upsertDeck` and `tombstoneSubtree` are removed;
  - `DeleteBatchMapper` keeps `findDeleteBatchById`, `tombstoneDeleteBatch` and `findChangesSince`; `upsertDeleteBatch` becomes `insertDeleteBatch`;
  - `DeckReader.ENTITY_TYPE = "deck"`, `DeleteBatchReader.ENTITY_TYPE = "delete_batch"`.

- [ ] **Step 1: Write the failing protocol test**

`test/java/com/memox/sync/SyncProtocolIT.java` registers two test handlers and drives `POST /api/v1/sync/push` through MockMvc:
- `TEST_CREATE` inserts a root deck through `DeckMapper.insertDeck`, so the change feed has something to show;
- `TEST_REJECT` always throws.

```java
package com.memox.sync;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.security.CurrentUserProvider;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.PayloadReader;
import com.memox.sync.service.SyncCommandHandler;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, SyncProtocolIT.TestHandlers.class})
class SyncProtocolIT {

    private static final String PUSH = "/api/v1/sync/push";

    @TestConfiguration
    static class TestHandlers {
        @Bean
        SyncCommandHandler testCreate(DeckMapper deckMapper, ChangeVersions versions, PayloadReader payloads) {
            return new SyncCommandHandler("TEST_CREATE", (context, payload) -> {
                UUID id = payloads.id(payload, "id");
                Instant now = Instant.parse("2026-09-27T01:00:00Z");
                deckMapper.insertDeck(Deck.builder()
                        .id(id)
                        .userId(context.userId())
                        .name("Root")
                        .rootId(id)
                        .depth(1)
                        .contentType("deck")
                        .schedulerType("sm2")
                        .schedulerVersion(1)
                        .generation(1)
                        .siblingPosition(0)
                        .createdAt(now)
                        .updatedAt(now)
                        .serverVersion(versions.next(context))
                        .lastDeviceId(context.deviceId())
                        .build());
            });
        }

        @Bean
        SyncCommandHandler testReject() {
            return new SyncCommandHandler("TEST_REJECT", (context, payload) -> {
                throw new BusinessException(ErrorCode.DECK_TREE_CYCLE);
            });
        }
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private CurrentUserProvider currentUserProvider;

    private UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    @Test
    void appliesACommandOnceAndReportsTheUsersLatestVersion() throws Exception {
        Map<String, Object> op = command("TEST_CREATE", Map.of("id", UUID.randomUUID()));

        push(op).andExpect(jsonPath("$.results[0].status").value("applied"))
                .andExpect(jsonPath("$.results[0].serverVersion").value(1));
        push(op).andExpect(jsonPath("$.results[0].serverVersion").value(1));
        mockMvc.perform(get("/api/v1/sync/changes").param("since", "0"))
                .andExpect(jsonPath("$.changes", hasSize(1)));
    }

    @Test
    void aRejectionListsTheAffectedEntitiesTheUserOwnsAndTheBatchGoesOn() throws Exception {
        UUID mine = UUID.randomUUID();
        push(command("TEST_CREATE", Map.of("id", mine)));
        UUID owner = user;
        user = UUID.randomUUID();
        UUID theirs = UUID.randomUUID();
        push(command("TEST_CREATE", Map.of("id", theirs)));
        user = owner;
        UUID unknown = UUID.randomUUID();

        Map<String, Object> reject = new LinkedHashMap<>(command("TEST_REJECT", Map.of()));
        reject.put("affected", List.of(affected(mine), affected(theirs), affected(unknown)));
        push(reject, command("TEST_CREATE", Map.of("id", UUID.randomUUID())))
                .andExpect(jsonPath("$.results[0].status").value("rejected"))
                .andExpect(jsonPath("$.results[0].code").value("DECK_TREE_CYCLE"))
                .andExpect(jsonPath("$.results[0].current", hasSize(2)))
                .andExpect(jsonPath("$.results[0].current[0].entityId").value(mine.toString()))
                .andExpect(jsonPath("$.results[0].current[0].row.name").value("Root"))
                .andExpect(jsonPath("$.results[0].current[1].entityId").value(unknown.toString()))
                .andExpect(jsonPath("$.results[0].current[1].deleted").value(true))
                .andExpect(jsonPath("$.results[0].current[1].serverVersion").value(0))
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void malformedOperationsAreRejectedOneByOneNeverTheWholePush() throws Exception {
        Map<String, Object> oldShape = new LinkedHashMap<>();
        oldShape.put("opId", UUID.randomUUID());
        oldShape.put("entityType", "deck");
        oldShape.put("entityId", UUID.randomUUID());
        oldShape.put("op", "upsert");
        oldShape.put("row", Map.of("name", "x"));
        Map<String, Object> unknownKind = new LinkedHashMap<>(command("TEST_CREATE", Map.of()));
        unknownKind.put("kind", "spaceship");
        Map<String, Object> unknownType = command("SPACESHIP", Map.of());
        Map<String, Object> unknownGroup = new LinkedHashMap<>();
        unknownGroup.put("opId", UUID.randomUUID());
        unknownGroup.put("kind", "patch");
        unknownGroup.put("entityType", "deck");
        unknownGroup.put("entityId", UUID.randomUUID());
        unknownGroup.put("group", "warp_drive");
        unknownGroup.put("fields", Map.of());
        Map<String, Object> badPayload = command("TEST_CREATE", Map.of("id", "not-a-uuid"));

        push(oldShape, unknownKind, unknownType, unknownGroup, badPayload)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[1].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[2].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[3].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[3].current", hasSize(1)))
                .andExpect(jsonPath("$.results[4].code").value("VALIDATION_FAILED"));
    }

    private ResultActions push(Map<?, ?>... operations) throws Exception {
        Map<String, Object> body = Map.of("deviceId", UUID.randomUUID(), "operations", List.of(operations));
        return mockMvc.perform(post(PUSH)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    private static Map<String, Object> command(String type, Map<String, Object> payload) {
        Map<String, Object> op = new LinkedHashMap<>();
        op.put("opId", UUID.randomUUID());
        op.put("kind", "command");
        op.put("type", type);
        op.put("payload", payload);
        return op;
    }

    private static Map<String, Object> affected(UUID id) {
        return Map.of("entityType", "deck", "entityId", id);
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B test -Dtest=SyncProtocolIT`
Expected: compilation FAILS (`SyncCommandHandler`, `ChangeVersions`, `PayloadReader`, `DeckMapper` do not exist).

- [ ] **Step 3: Replace the operation and result shapes**

`sync/dto/request/AffectedEntity.java`:

```java
package com.memox.sync.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** An entity a command changed in the client's local store; the server returns its copy on a rejection. */
public record AffectedEntity(@NotBlank String entityType, @NotNull UUID entityId) {}
```

`sync/dto/request/SyncOperation.java` (replaces the file; delete `SyncOperationType.java`):

```java
package com.memox.sync.dto.request;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import lombok.Builder;

/**
 * One outbox entry (API-A2 spec §4.1). {@code kind} is {@value #COMMAND} (with {@code type} and {@code payload}) or
 * {@value #PATCH} (with {@code entityType}, {@code entityId}, {@code group} and {@code fields}). Everything except
 * {@code opId} is checked per operation by the service, so one malformed operation never fails the whole push.
 */
@Builder
public record SyncOperation(
        @NotNull UUID opId,
        String kind,
        String type,
        String entityType,
        UUID entityId,
        String group,
        JsonNode payload,
        JsonNode fields,
        @Size(max = SyncOperation.MAX_AFFECTED) List<@Valid @NotNull AffectedEntity> affected) {

    public static final String COMMAND = "command";
    public static final String PATCH = "patch";
    public static final int MAX_AFFECTED = 1000;
}
```

`sync/dto/response/SyncChange.java`:

```java
package com.memox.sync.dto.response;

import java.util.UUID;

/** One entity's state after {@code serverVersion}; {@code row} is null for a tombstone. */
public record SyncChange(String entityType, UUID entityId, long serverVersion, boolean deleted, Object row) {

    /** An id the server has never stored: the client deletes its local row. */
    public static SyncChange absent(String entityType, UUID entityId) {
        return new SyncChange(entityType, entityId, 0L, true, null);
    }
}
```

`sync/dto/response/OperationResult.java`:

```java
package com.memox.sync.dto.response;

import java.util.List;
import java.util.UUID;

/**
 * The outcome of one operation. {@code serverVersion} is set when applied; {@code code} and {@code current} (the
 * server's copy of every affected entity the user owns) when rejected.
 */
public record OperationResult(
        UUID opId, OperationStatus status, Long serverVersion, String code, List<SyncChange> current) {

    public static OperationResult applied(UUID opId, long serverVersion) {
        return new OperationResult(opId, OperationStatus.APPLIED, serverVersion, null, null);
    }

    public static OperationResult rejected(UUID opId, String code, List<SyncChange> current) {
        return new OperationResult(opId, OperationStatus.REJECTED, null, code, List.copyOf(current));
    }
}
```

- [ ] **Step 4: Add the protocol contracts and helpers**

`sync/service/WriteContext.java`:

```java
package com.memox.sync.service;

import java.util.UUID;

/** Who writes: the owner from {@code CurrentUserProvider} and the device that sent the write, kept for diagnostics. */
public record WriteContext(UUID userId, UUID deviceId) {

    /** The device recorded for a REST write that sends no {@code X-Device-Id}. */
    public static final UUID REST_DEVICE = new UUID(0L, 0L);

    public static final String DEVICE_HEADER = "X-Device-Id";
    public static final String IDEMPOTENCY_HEADER = "Idempotency-Key";

    /** A REST write: the current user and the optional device header. */
    public static WriteContext rest(UUID userId, UUID deviceId) {
        return new WriteContext(userId, deviceId == null ? REST_DEVICE : deviceId);
    }
}
```

`sync/service/SyncCommandHandler.java`:

```java
package com.memox.sync.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.function.BiConsumer;

/**
 * Runs one command {@code type} by reading its payload into the request DTO the REST route binds and calling the
 * same service method (API-A2 spec D2). Called inside the operation's transaction; reject by throwing
 * {@code BusinessException}.
 */
public record SyncCommandHandler(String type, BiConsumer<WriteContext, JsonNode> body) {}
```

`sync/service/SyncPatchHandler.java`:

```java
package com.memox.sync.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.UUID;

/** Applies one field group of one entity type, validated by that entity's service (API-A2 spec §5). */
public record SyncPatchHandler(String entityType, String group, Applier applier) {

    @FunctionalInterface
    public interface Applier {
        void apply(WriteContext context, UUID entityId, JsonNode fields);
    }
}
```

`sync/service/EntityReader.java`:

```java
package com.memox.sync.service;

import com.memox.sync.dto.response.SyncChange;
import java.util.List;
import java.util.UUID;

/** Reads one synced entity type for the change feed and for rejections. One implementation per synced table. */
public interface EntityReader {

    String entityType();

    /**
     * The owner's copy (a tombstone when purged), {@link SyncChange#absent} when the id was never stored, or
     * {@code null} when another user owns it, so a rejection never leaks it.
     */
    SyncChange current(UUID userId, UUID entityId);

    /** Changes with {@code server_version > since}, ascending, at most {@code limit}. */
    List<SyncChange> changesSince(UUID userId, long since, int limit);
}
```

`sync/service/PayloadReader.java`:

```java
package com.memox.sync.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import jakarta.validation.Validator;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Reads a command payload or patch fields into a request DTO with the same Bean Validation as a REST body. */
@Component
@RequiredArgsConstructor
public class PayloadReader {

    private final ObjectMapper objectMapper;
    private final Validator validator;

    public <T> T read(JsonNode json, Class<T> type) {
        if (json == null || !json.isObject()) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        T value;
        try {
            value = objectMapper.treeToValue(json, type);
        } catch (JsonProcessingException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        if (value == null || !validator.validate(value).isEmpty()) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        return value;
    }

    /** A required UUID field of a payload, such as the {@code deckId} a REST route takes from its path. */
    public UUID id(JsonNode json, String field) {
        JsonNode node = json == null ? null : json.get(field);
        if (node == null || !node.isTextual()) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        try {
            return UUID.fromString(node.asText());
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }
}
```

`sync/service/ChangeVersions.java`:

```java
package com.memox.sync.service;

import com.memox.sync.mapper.SyncVersionMapper;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The per-user lock and version counter every write goes through, REST and sync alike (API-A2 spec §4.3). */
@Component
@RequiredArgsConstructor
public class ChangeVersions {

    private final SyncVersionMapper syncVersionMapper;

    /** Serializes this user's writes until the transaction ends; re-entrant within one transaction. */
    public void lock(WriteContext context) {
        syncVersionMapper.lockUser(context.userId());
    }

    public long next(WriteContext context) {
        return syncVersionMapper.allocate(context.userId(), 1);
    }

    /** Reserves {@code count} (at least 1) consecutive versions and returns the first. */
    public long block(WriteContext context, int count) {
        return syncVersionMapper.allocate(context.userId(), count) - count + 1;
    }

    public long latest(UUID userId) {
        Long version = syncVersionMapper.current(userId);
        return version == null ? 0L : version;
    }
}
```

- [ ] **Step 5: Rename the mappers and keep only what reading needs**

Rename `DeckSyncMapper.java` to `DeckMapper.java` (interface `DeckMapper`) and `DeckSyncMapper.xml` to `DeckMapper.xml` (namespace `com.memox.deck.mapper.DeckMapper`). Delete `upsertDeck` and `tombstoneSubtree` from both. Add `insertDeck`, used by the test handler now and by `DeckServiceImpl` from Task 2:

```java
    void insertDeck(Deck deck);
```

```xml
    <insert id="insertDeck">
        INSERT INTO deck (<include refid="deckColumns"/>)
        VALUES (#{id}, #{userId}, #{name}, #{parentId}, #{rootId}, #{depth}, #{contentType}, #{schedulerType},
                #{schedulerVersion}, #{schedulerConfig}, #{studyConfig}, #{generation}, #{firstAnsweredAt},
                #{sourceTemplateId}, #{sourceTemplateVersion}, #{deleteBatchId}, #{siblingPosition}, #{createdAt},
                #{updatedAt}, #{serverVersion}, #{lastDeviceId}, NULL)
    </insert>
```

Rename `DeleteBatchSyncMapper.java` to `DeleteBatchMapper.java` and its XML to `DeleteBatchMapper.xml` (namespace `com.memox.trash.mapper.DeleteBatchMapper`). Replace `upsertDeleteBatch` with a plain insert. `tombstoneDeleteBatch` gains `deviceId` and keeps its shape:

```java
    void insertDeleteBatch(DeleteBatch batch);
```

```xml
    <insert id="insertDeleteBatch">
        INSERT INTO delete_batch (<include refid="columns"/>)
        VALUES (#{id}, #{userId}, #{itemType}, #{rootItemId}, #{deletedAt}, #{serverVersion}, #{lastDeviceId}, NULL)
    </insert>
```

- [ ] **Step 6: Replace the row handlers with readers**

Delete `DeckSyncHandler.java` and `DeleteBatchSyncHandler.java`. Create `deck/service/impl/DeckReader.java`:

```java
package com.memox.deck.service.impl;

import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.service.EntityReader;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The {@code deck} rows of the change feed; {@code rootId}, {@code depth} and {@code contentType} are the server's. */
@Component
@RequiredArgsConstructor
public class DeckReader implements EntityReader {

    public static final String ENTITY_TYPE = "deck";

    private final DeckMapper deckMapper;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        Deck deck = deckMapper.findDeckById(entityId);
        if (deck == null) {
            return SyncChange.absent(ENTITY_TYPE, entityId);
        }
        return deck.getUserId().equals(userId) ? toChange(deck) : null;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deckMapper.findChangesSince(userId, since, limit).stream()
                .map(DeckReader::toChange)
                .toList();
    }

    static SyncChange toChange(Deck deck) {
        boolean deleted = deck.getDeletedAt() != null;
        DeckSyncRow row = deleted
                ? null
                : DeckSyncRow.builder()
                        .id(deck.getId())
                        .name(deck.getName())
                        .parentId(deck.getParentId())
                        .rootId(deck.getRootId())
                        .depth(deck.getDepth())
                        .contentType(deck.getContentType())
                        .schedulerType(deck.getSchedulerType())
                        .schedulerVersion(deck.getSchedulerVersion())
                        .schedulerConfig(deck.getSchedulerConfig())
                        .studyConfig(deck.getStudyConfig())
                        .generation(deck.getGeneration())
                        .firstAnsweredAt(deck.getFirstAnsweredAt())
                        .sourceTemplateId(deck.getSourceTemplateId())
                        .sourceTemplateVersion(deck.getSourceTemplateVersion())
                        .deleteBatchId(deck.getDeleteBatchId())
                        .siblingPosition(deck.getSiblingPosition())
                        .createdAt(deck.getCreatedAt())
                        .updatedAt(deck.getUpdatedAt())
                        .build();
        return new SyncChange(ENTITY_TYPE, deck.getId(), deck.getServerVersion(), deleted, row);
    }
}
```

`trash/service/impl/DeleteBatchReader.java`:

```java
package com.memox.trash.service.impl;

import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.service.EntityReader;
import com.memox.trash.dto.DeleteBatchSyncRow;
import com.memox.trash.mapper.DeleteBatchMapper;
import com.memox.trash.model.DeleteBatch;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The {@code delete_batch} rows of the change feed; an undone batch is a tombstone. */
@Component
@RequiredArgsConstructor
public class DeleteBatchReader implements EntityReader {

    public static final String ENTITY_TYPE = "delete_batch";

    private final DeleteBatchMapper deleteBatchMapper;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(entityId);
        if (batch == null) {
            return SyncChange.absent(ENTITY_TYPE, entityId);
        }
        return batch.getUserId().equals(userId) ? toChange(batch) : null;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deleteBatchMapper.findChangesSince(userId, since, limit).stream()
                .map(DeleteBatchReader::toChange)
                .toList();
    }

    private static SyncChange toChange(DeleteBatch batch) {
        boolean deleted = batch.getTombstonedAt() != null;
        DeleteBatchSyncRow row = deleted
                ? null
                : DeleteBatchSyncRow.builder()
                        .id(batch.getId())
                        .itemType(batch.getItemType())
                        .rootItemId(batch.getRootItemId())
                        .deletedAt(batch.getDeletedAt())
                        .build();
        return new SyncChange(ENTITY_TYPE, batch.getId(), batch.getServerVersion(), deleted, row);
    }
}
```

- [ ] **Step 7: Rewrite the applier and the service**

`sync/service/impl/SyncOperationApplier.java`:

```java
package com.memox.sync.service.impl;

import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import java.util.UUID;
import java.util.function.Consumer;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Applies one operation in its own transaction, so a rejection rolls back only that operation (spec §4.1). */
@Component
@RequiredArgsConstructor
class SyncOperationApplier {

    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final ChangeVersions changeVersions;

    /** @return the user's latest version once the write is done */
    @Transactional
    public long apply(WriteContext context, UUID opId, Consumer<WriteContext> write) {
        changeVersions.lock(context);
        write.accept(context);
        long version = changeVersions.latest(context.userId());
        syncAppliedOpMapper.insert(context.userId(), opId, version);
        return version;
    }
}
```

`sync/service/impl/SyncServiceImpl.java`:

```java
package com.memox.sync.service.impl;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.dto.request.AffectedEntity;
import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.OperationResult;
import com.memox.sync.dto.response.PushResponse;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.EntityReader;
import com.memox.sync.service.SyncCommandHandler;
import com.memox.sync.service.SyncPatchHandler;
import com.memox.sync.service.SyncService;
import com.memox.sync.service.WriteContext;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class SyncServiceImpl implements SyncService {

    private final CurrentUserProvider currentUserProvider;
    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final SyncOperationApplier syncOperationApplier;
    private final Map<String, SyncCommandHandler> commands;
    private final Map<String, SyncPatchHandler> patches;
    private final Map<String, EntityReader> readers;

    public SyncServiceImpl(
            CurrentUserProvider currentUserProvider,
            SyncAppliedOpMapper syncAppliedOpMapper,
            SyncOperationApplier syncOperationApplier,
            ObjectProvider<SyncCommandHandler> commands,
            ObjectProvider<SyncPatchHandler> patches,
            ObjectProvider<EntityReader> readers) {
        this.currentUserProvider = currentUserProvider;
        this.syncAppliedOpMapper = syncAppliedOpMapper;
        this.syncOperationApplier = syncOperationApplier;
        // ObjectProvider, not List: a slice may register no handler of a kind yet.
        this.commands = commands.orderedStream()
                .collect(Collectors.toUnmodifiableMap(SyncCommandHandler::type, Function.identity()));
        this.patches = patches.orderedStream()
                .collect(Collectors.toUnmodifiableMap(
                        handler -> patchKey(handler.entityType(), handler.group()), Function.identity()));
        this.readers = readers.orderedStream()
                .collect(Collectors.toUnmodifiableMap(EntityReader::entityType, Function.identity()));
    }

    @Override
    public PushResponse push(PushRequest request) {
        WriteContext context = new WriteContext(currentUserProvider.currentUserId(), request.deviceId());
        List<OperationResult> results = request.operations().stream()
                .map(operation -> pushOne(context, operation))
                .toList();
        return new PushResponse(results);
    }

    @Override
    public ChangesResponse changesSince(long since, int limit) {
        UUID userId = currentUserProvider.currentUserId();
        List<SyncChange> merged = readers.values().stream()
                .flatMap(reader -> reader.changesSince(userId, since, limit + 1).stream())
                .sorted(Comparator.comparingLong(SyncChange::serverVersion))
                .toList();
        boolean hasMore = merged.size() > limit;
        List<SyncChange> page = hasMore ? merged.subList(0, limit) : merged;
        long nextSince = page.isEmpty() ? since : page.get(page.size() - 1).serverVersion();
        return new ChangesResponse(page, nextSince, hasMore);
    }

    private OperationResult pushOne(WriteContext context, SyncOperation operation) {
        UUID userId = context.userId();
        Long alreadyApplied = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
        if (alreadyApplied != null) {
            return OperationResult.applied(operation.opId(), alreadyApplied);
        }
        try {
            Consumer<WriteContext> write = resolve(operation);
            return OperationResult.applied(
                    operation.opId(), syncOperationApplier.apply(context, operation.opId(), write));
        } catch (BusinessException e) {
            return rejected(userId, operation, e.getErrorCode());
        } catch (DataIntegrityViolationException e) {
            Long appliedMeanwhile = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
            if (appliedMeanwhile != null) {
                return OperationResult.applied(operation.opId(), appliedMeanwhile);
            }
            log.warn("Sync operation {} violated a constraint", operation.opId(), e);
            return rejected(userId, operation, ErrorCode.CONFLICT);
        }
    }

    private Consumer<WriteContext> resolve(SyncOperation operation) {
        if (SyncOperation.COMMAND.equals(operation.kind())) {
            SyncCommandHandler handler = operation.type() == null ? null : commands.get(operation.type());
            if (handler == null) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return context -> handler.body().accept(context, operation.payload());
        }
        if (SyncOperation.PATCH.equals(operation.kind())) {
            SyncPatchHandler handler = patches.get(patchKey(operation.entityType(), operation.group()));
            if (handler == null || operation.entityId() == null) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return context -> handler.applier().apply(context, operation.entityId(), operation.fields());
        }
        throw new BusinessException(ErrorCode.VALIDATION_FAILED);
    }

    private OperationResult rejected(UUID userId, SyncOperation operation, ErrorCode code) {
        Set<AffectedEntity> targets = new LinkedHashSet<>();
        if (SyncOperation.PATCH.equals(operation.kind())
                && operation.entityType() != null
                && operation.entityId() != null) {
            targets.add(new AffectedEntity(operation.entityType(), operation.entityId()));
        }
        if (operation.affected() != null) {
            targets.addAll(operation.affected());
        }
        List<SyncChange> current = targets.stream()
                .map(target -> {
                    EntityReader reader = readers.get(target.entityType());
                    return reader == null ? null : reader.current(userId, target.entityId());
                })
                .filter(Objects::nonNull)
                .toList();
        return OperationResult.rejected(operation.opId(), code.name(), current);
    }

    private static String patchKey(String entityType, String group) {
        return entityType + "/" + group;
    }
}
```

Update `sync/service/package-info.java` to say: "The sync protocol: command and patch handlers, entity readers, and the per-user lock and versions."

- [ ] **Step 8: Swap the error code**

In `ErrorCode.java`, delete `SYNC_ENTITY_UNSUPPORTED(HttpStatus.BAD_REQUEST)`. In `messages.properties`, delete the `error.SYNC_ENTITY_UNSUPPORTED` line.

- [ ] **Step 9: Delete the retired tests, then run the new one**

```bash
git rm src/test/java/com/memox/deck/service/impl/DeckSyncHandlerIT.java \
  src/test/java/com/memox/trash/service/impl/DeleteBatchSyncHandlerIT.java \
  src/test/java/com/memox/sync/service/impl/SyncOperationApplierConcurrencyIT.java \
  src/test/java/com/memox/sync/SyncApiIT.java
./mvnw -B test -Dtest=SyncProtocolIT
```

Expected: PASS, 3 tests.

- [ ] **Step 10: Run the whole test suite, format, commit**

Run: `./mvnw -B test` (expected: PASS). Then run `./mvnw -B spotless:apply`.

```bash
git add -A src
git commit -m "feat(api): command protocol — command/patch operations, entity readers, row sync retired (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: DeckService — create, rename, study options

**Files:**
- Create: `main/java/com/memox/common/util/TextRules.java`, `test/java/com/memox/common/util/TextRulesTest.java`
- Create: `main/java/com/memox/deck/model/DeckContentTypes.java`
- Create: `main/java/com/memox/deck/dto/request/{CreateRootDeckRequest,CreateSubDeckRequest,RenameDeckRequest,StudyOptionsRequest}.java`
- Create: `main/java/com/memox/deck/service/DeckService.java`, `main/java/com/memox/deck/service/impl/DeckServiceImpl.java`, `main/java/com/memox/deck/service/impl/DeckSyncCommands.java`
- Modify: `main/java/com/memox/deck/mapper/DeckMapper.java`, `main/resources/mapper/deck/DeckMapper.xml`
- Modify: `main/java/com/memox/common/exception/ErrorCode.java`, `main/resources/messages.properties`
- Test: `test/java/com/memox/deck/service/impl/DeckServiceImplIT.java`

**Interfaces:**
- Consumes: `WriteContext`, `ChangeVersions`, `PayloadReader`, `SyncCommandHandler`, `SyncPatchHandler` (Task 1).
- Produces:
  - `DeckService`, with `createRootDeck(WriteContext, CreateRootDeckRequest)`, `createSubDeck(WriteContext, UUID parentId, CreateSubDeckRequest)`, `renameDeck(WriteContext, UUID deckId, RenameDeckRequest)`, `updateStudyOptions(WriteContext, UUID deckId, StudyOptionsRequest)` and `refreshContentType(WriteContext, UUID deckId)`, all `void`;
  - `DeckContentTypes.UNSET`, `CARD`, `DECK`;
  - `DeckServiceImpl.MAX_DEPTH = 10`;
  - `TextRules.stored(String)`, `required(String, int)`, `optional(String, int)`;
  - `DeckMapper.nextSiblingPosition(UUID userId, UUID parentId)`, `updateName`, `updateStudyConfig`, `updateContentType`, `deriveContentType(UUID id)`.

- [ ] **Step 1: Write the failing `TextRules` test**

```java
package com.memox.common.util;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.common.exception.BusinessException;
import org.junit.jupiter.api.Test;

class TextRulesTest {

    @Test
    void storedStripsAndComposesToNfc() {
        assertThat(TextRules.stored("  Café ")).isEqualTo("Café");
        assertThat(TextRules.stored(null)).isNull();
    }

    @Test
    void requiredRejectsBlankAndTooLongAfterNormalizing() {
        assertThat(TextRules.required(" a ", 1)).isEqualTo("a");
        assertThat(TextRules.required("é", 1)).isEqualTo("é");
        assertThatThrownBy(() -> TextRules.required("   ", 5)).isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> TextRules.required("abc", 2)).isInstanceOf(BusinessException.class);
    }

    @Test
    void optionalTurnsBlankIntoNull() {
        assertThat(TextRules.optional("  ", 5)).isNull();
        assertThat(TextRules.optional(null, 5)).isNull();
        assertThat(TextRules.optional(" x ", 5)).isEqualTo("x");
        assertThatThrownBy(() -> TextRules.optional("abcdef", 5)).isInstanceOf(BusinessException.class);
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B test -Dtest=TextRulesTest`
Expected: compilation FAILS (`TextRules` does not exist).

- [ ] **Step 3: Implement `TextRules`**

```java
package com.memox.common.util;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import java.text.Normalizer;
import org.apache.commons.lang3.StringUtils;

/**
 * The stored form of user text (BE-C5): stripped, then NFC. Lengths count UTF-16 units, as Dart's
 * {@code String.length} does, so the server and the app accept the same strings.
 */
public final class TextRules {

    private TextRules() {}

    public static String stored(String value) {
        return value == null ? null : Normalizer.normalize(value.strip(), Normalizer.Form.NFC);
    }

    public static String required(String value, int maxLength) {
        String stored = stored(value);
        if (StringUtils.isEmpty(stored) || stored.length() > maxLength) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        return stored;
    }

    /** {@code null} when blank: an optional field has one empty form (schema.md, card). */
    public static String optional(String value, int maxLength) {
        String stored = stored(value);
        if (StringUtils.isEmpty(stored)) {
            return null;
        }
        if (stored.length() > maxLength) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        return stored;
    }
}
```

Run: `./mvnw -B test -Dtest=TextRulesTest`. Expected: PASS.

- [ ] **Step 4: Write the failing deck service tests**

`test/java/com/memox/deck/service/impl/DeckServiceImplIT.java`. Tasks 3 and 4 add more tests to this class.

```java
package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import java.util.UUID;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class DeckServiceImplIT {

    @Autowired
    DeckService deckService;

    @Autowired
    DeckMapper deckMapper;

    final WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());

    UUID root(String scheduler) {
        UUID id = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(id, "Root", scheduler));
        return id;
    }

    UUID child(UUID parent) {
        UUID id = UUID.randomUUID();
        deckService.createSubDeck(ctx, parent, new CreateSubDeckRequest(id, "Child"));
        return id;
    }

    Deck deck(UUID id) {
        return deckMapper.findDeckById(id);
    }

    static void rejects(ThrowingCallable call, ErrorCode code) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(code);
    }

    @Test
    void createRootDeckSetsTheSchedulerVersionGenerationAndAppendsAfterTheLastRoot() {
        UUID first = root("sm2");
        UUID second = root("eight_box");

        assertThat(deck(first).getSchedulerVersion()).isEqualTo(1);
        assertThat(deck(first).getGeneration()).isEqualTo(1);
        assertThat(deck(first).getContentType()).isEqualTo("deck");
        assertThat(deck(first).getRootId()).isEqualTo(first);
        assertThat(deck(second).getSiblingPosition()).isEqualTo(deck(first).getSiblingPosition() + 1);
    }

    @Test
    void createSubDeckIsUnsetAndTurnsAnUnsetParentIntoADeckParent_BR_DECK_006_008() {
        UUID root = root("sm2");
        UUID a = child(root);
        long parentVersionBefore = deck(a).getServerVersion();

        UUID b = child(a);

        assertThat(deck(b).getContentType()).isEqualTo("unset");
        assertThat(deck(b).getRootId()).isEqualTo(root);
        assertThat(deck(b).getDepth()).isEqualTo(3);
        assertThat(deck(a).getContentType()).isEqualTo("deck");
        assertThat(deck(a).getServerVersion()).isGreaterThan(parentVersionBefore);
    }

    @Test
    void createSubDeckRefusesACardParentAndTheEleventhLevel_BR_DECK_001_009() {
        UUID parent = root("sm2");
        for (int level = 2; level <= 10; level++) {
            parent = child(parent);
        }
        UUID tenth = parent;
        rejects(() -> child(tenth), ErrorCode.DECK_TREE_TOO_DEEP);

        UUID root = root("sm2");
        UUID cardDeck = child(root);
        deckMapper.updateContentType(ctx.userId(), cardDeck, "card", 999_999L, ctx.deviceId(), deck(root).getUpdatedAt());
        rejects(() -> child(cardDeck), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
    }

    @Test
    void createSubDeckRefusesAMissingOrForeignParentAsMissing() {
        rejects(() -> child(UUID.randomUUID()), ErrorCode.DECK_PARENT_MISSING);
        UUID theirs = UUID.randomUUID();
        deckService.createRootDeck(
                new WriteContext(UUID.randomUUID(), ctx.deviceId()), new CreateRootDeckRequest(theirs, "T", "sm2"));
        rejects(() -> child(theirs), ErrorCode.DECK_PARENT_MISSING);
    }

    @Test
    void anIdAlreadyTakenIsAConflictAndAnotherUsersIdIsNotRevealed() {
        UUID mine = root("sm2");
        rejects(() -> deckService.createRootDeck(ctx, new CreateRootDeckRequest(mine, "Again", "sm2")),
                ErrorCode.CONFLICT);
        rejects(() -> deckService.createRootDeck(
                        new WriteContext(UUID.randomUUID(), ctx.deviceId()),
                        new CreateRootDeckRequest(mine, "Stolen", "sm2")),
                ErrorCode.SYNC_ENTITY_CONFLICT);
    }

    @Test
    void renameStoresTheNfcStrippedNameAndRejectsBlankOrTooLong_BR_DECK_020() {
        UUID root = root("sm2");

        deckService.renameDeck(ctx, root, new RenameDeckRequest("  Café  "));

        assertThat(deck(root).getName()).isEqualTo("Café");
        rejects(() -> deckService.renameDeck(ctx, root, new RenameDeckRequest("  ")), ErrorCode.VALIDATION_FAILED);
        rejects(() -> deckService.renameDeck(ctx, root, new RenameDeckRequest("x".repeat(201))),
                ErrorCode.VALIDATION_FAILED);
        rejects(() -> deckService.renameDeck(ctx, UUID.randomUUID(), new RenameDeckRequest("x")),
                ErrorCode.DECK_NOT_FOUND);
    }

    @Test
    void studyOptionsAreRootOnlyValidJsonAndNullRestoresDefaults_BR_STUDY_056() {
        UUID root = root("sm2");
        UUID sub = child(root);

        deckService.updateStudyOptions(ctx, root, new StudyOptionsRequest("{\"cardLimit\":20}"));
        assertThat(deck(root).getStudyConfig()).isEqualTo("{\"cardLimit\":20}");
        deckService.updateStudyOptions(ctx, root, new StudyOptionsRequest(null));
        assertThat(deck(root).getStudyConfig()).isNull();

        rejects(() -> deckService.updateStudyOptions(ctx, sub, new StudyOptionsRequest("{}")),
                ErrorCode.DECK_ROOT_REQUIRED);
        rejects(() -> deckService.updateStudyOptions(ctx, root, new StudyOptionsRequest("{not json")),
                ErrorCode.VALIDATION_FAILED);
    }
}
```

- [ ] **Step 5: Run them to verify they fail**

Run: `./mvnw -B test -Dtest=DeckServiceImplIT`
Expected: compilation FAILS (`DeckService` and the request DTOs do not exist).

- [ ] **Step 6: Add error codes**

In `ErrorCode.java`, after `SYNC_ENTITY_CONFLICT(HttpStatus.CONFLICT)`, add the following. Phase 2 codes are included now so the enum changes once.

```java
    DECK_NOT_FOUND(HttpStatus.NOT_FOUND),
    CARD_NOT_FOUND(HttpStatus.NOT_FOUND),
    BATCH_NOT_FOUND(HttpStatus.NOT_FOUND),
    DECK_CONTENT_TYPE_MISMATCH(HttpStatus.CONFLICT),
    DECK_SCHEDULER_MISMATCH(HttpStatus.CONFLICT),
    DECK_IN_TRASH(HttpStatus.CONFLICT),
    CARD_IN_TRASH(HttpStatus.CONFLICT),
    CARD_MOVE_CROSS_ROOT(HttpStatus.CONFLICT),
    DECK_ROOT_REQUIRED(HttpStatus.BAD_REQUEST);
```

In `messages.properties`:

```properties
error.DECK_NOT_FOUND=The deck does not exist.
error.CARD_NOT_FOUND=The card does not exist.
error.BATCH_NOT_FOUND=There is nothing to undo for this deletion.
error.DECK_CONTENT_TYPE_MISMATCH=This deck holds another kind of item: a deck holds either cards or decks.
error.DECK_SCHEDULER_MISMATCH=The two decks use a different scheduler or learning progress; reset progress first.
error.DECK_IN_TRASH=The deck is in the Trash.
error.CARD_IN_TRASH=The card is in the Trash.
error.CARD_MOVE_CROSS_ROOT=Cards can move only between decks of the same top-level deck.
error.DECK_ROOT_REQUIRED=Only a top-level deck has this setting.
```

- [ ] **Step 7: Add the request DTOs and the content-type constants**

`deck/model/DeckContentTypes.java`:

```java
package com.memox.deck.model;

/** Stored values of {@code deck.content_type} (schema.md), derived by the server (BR-DECK-015). */
public final class DeckContentTypes {

    public static final String UNSET = "unset";
    public static final String CARD = "card";
    public static final String DECK = "deck";

    private DeckContentTypes() {}
}
```

`deck/dto/request/CreateRootDeckRequest.java`:

```java
package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.util.UUID;

/** {@code CREATE_ROOT_DECK} payload and {@code POST /api/v1/decks} body. Name rules are checked after NFC. */
public record CreateRootDeckRequest(
        @NotNull UUID id, @NotNull String name, @NotNull @Pattern(regexp = "eight_box|sm2") String schedulerType) {}
```

`deck/dto/request/CreateSubDeckRequest.java`:

```java
package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code CREATE_SUB_DECK} payload (with {@code parentId}) and {@code POST /decks/{parentId}/sub-decks} body. */
public record CreateSubDeckRequest(@NotNull UUID id, @NotNull String name) {}
```

`deck/dto/request/RenameDeckRequest.java`:

```java
package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;

/** {@code RENAME_DECK} payload (with {@code deckId}) and {@code PATCH /decks/{id}} body. */
public record RenameDeckRequest(@NotNull String name) {}
```

`deck/dto/request/StudyOptionsRequest.java`:

```java
package com.memox.deck.dto.request;

/** Patch {@code deck/study_options} fields: JSON text of the root's options, or {@code null} for the defaults. */
public record StudyOptionsRequest(String studyConfig) {}
```

- [ ] **Step 8: Add the mapper statements**

In `DeckMapper.java`:

```java
    int nextSiblingPosition(@Param("userId") UUID userId, @Param("parentId") UUID parentId);

    int updateName(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("name") String name,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int updateStudyConfig(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("studyConfig") String studyConfig,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int updateContentType(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("contentType") String contentType,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** What the deck's direct children make it: children sharing its own batch count, so Trash keeps its shape. */
    String deriveContentType(@Param("id") UUID id);
```

In `DeckMapper.xml`:

```xml
    <sql id="sameParent">
        <choose>
            <when test="parentId == null">parent_id IS NULL</when>
            <otherwise>parent_id = #{parentId}</otherwise>
        </choose>
    </sql>
    <!-- The end of the sibling group, rows in Trash included, so an undo gets its old place back (app trash D9). -->
    <select id="nextSiblingPosition" resultType="int">
        SELECT COALESCE(MAX(sibling_position) + 1, 0) FROM deck
        WHERE user_id = #{userId} AND <include refid="sameParent"/> AND deleted_at IS NULL
    </select>
    <update id="updateName">
        UPDATE deck SET name = #{name}, updated_at = #{now}, server_version = #{version}, last_device_id = #{deviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <update id="updateStudyConfig">
        UPDATE deck SET study_config = #{studyConfig}, updated_at = #{now}, server_version = #{version},
                        last_device_id = #{deviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <update id="updateContentType">
        UPDATE deck SET content_type = #{contentType}, updated_at = #{now}, server_version = #{version},
                        last_device_id = #{deviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <select id="deriveContentType" resultType="string">
        SELECT CASE
            WHEN EXISTS (SELECT 1 FROM deck c WHERE c.parent_id = p.id AND c.deleted_at IS NULL
                         AND c.delete_batch_id IS NOT DISTINCT FROM p.delete_batch_id) THEN 'deck'
            ELSE 'unset' END
        FROM deck p WHERE p.id = #{id}
    </select>
```

- [ ] **Step 9: Implement `DeckService` and `DeckServiceImpl`**

`deck/service/DeckService.java`:

```java
package com.memox.deck.service;

import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.sync.service.WriteContext;
import java.util.UUID;

/** Deck operations, shared by REST and sync commands (API-A2 spec §5). Every method is one transaction. */
public interface DeckService {

    void createRootDeck(WriteContext context, CreateRootDeckRequest request);

    void createSubDeck(WriteContext context, UUID parentId, CreateSubDeckRequest request);

    void renameDeck(WriteContext context, UUID deckId, RenameDeckRequest request);

    void updateStudyOptions(WriteContext context, UUID deckId, StudyOptionsRequest request);

    /** Re-derives a sub-deck's content type from its children (BR-DECK-015); for services writing children. */
    void refreshContentType(WriteContext context, UUID deckId);
}
```

`deck/service/impl/DeckServiceImpl.java`:

```java
package com.memox.deck.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.util.TextRules;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckContentTypes;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DeckServiceImpl implements DeckService {

    static final int MAX_DEPTH = 10;
    static final int NAME_MAX_LENGTH = 200;
    private static final int ROOT_DEPTH = 1;
    private static final int FIRST_GENERATION = 1;
    /** The algorithm versions Dart ships (EightBoxScheduler.version, Sm2Scheduler.version); API-B5 owns them. */
    private static final Map<String, Integer> SCHEDULER_VERSIONS = Map.of("eight_box", 1, "sm2", 1);

    private final DeckMapper deckMapper;
    private final ChangeVersions changeVersions;
    private final ObjectMapper objectMapper;
    private final Clock clock;

    @Override
    @Transactional
    public void createRootDeck(WriteContext context, CreateRootDeckRequest request) {
        changeVersions.lock(context);
        requireNewId(context, request.id());
        String name = TextRules.required(request.name(), NAME_MAX_LENGTH);
        Instant now = clock.instant();
        deckMapper.insertDeck(Deck.builder()
                .id(request.id())
                .userId(context.userId())
                .name(name)
                .rootId(request.id())
                .depth(ROOT_DEPTH)
                .contentType(DeckContentTypes.DECK)
                .schedulerType(request.schedulerType())
                .schedulerVersion(SCHEDULER_VERSIONS.get(request.schedulerType()))
                .generation(FIRST_GENERATION)
                .siblingPosition(deckMapper.nextSiblingPosition(context.userId(), null))
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
    }

    @Override
    @Transactional
    public void createSubDeck(WriteContext context, UUID parentId, CreateSubDeckRequest request) {
        changeVersions.lock(context);
        requireNewId(context, request.id());
        Deck parent = parentOrMissing(context, parentId);
        if (DeckContentTypes.CARD.equals(parent.getContentType())) {
            throw new BusinessException(ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        }
        if (parent.getDepth() + 1 > MAX_DEPTH) {
            throw new BusinessException(ErrorCode.DECK_TREE_TOO_DEEP);
        }
        String name = TextRules.required(request.name(), NAME_MAX_LENGTH);
        Instant now = clock.instant();
        deckMapper.insertDeck(Deck.builder()
                .id(request.id())
                .userId(context.userId())
                .name(name)
                .parentId(parent.getId())
                .rootId(parent.getRootId())
                .depth(parent.getDepth() + 1)
                .contentType(DeckContentTypes.UNSET)
                // A parent in Trash takes its new child along (API-A2 spec D4).
                .deleteBatchId(parent.getDeleteBatchId())
                .siblingPosition(deckMapper.nextSiblingPosition(context.userId(), parent.getId()))
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
        refreshContentType(context, parent.getId());
    }

    @Override
    @Transactional
    public void renameDeck(WriteContext context, UUID deckId, RenameDeckRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        String name = TextRules.required(request.name(), NAME_MAX_LENGTH);
        deckMapper.updateName(
                context.userId(), deck.getId(), name, changeVersions.next(context), context.deviceId(), clock.instant());
    }

    @Override
    @Transactional
    public void updateStudyOptions(WriteContext context, UUID deckId, StudyOptionsRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        if (deck.getParentId() != null) {
            throw new BusinessException(ErrorCode.DECK_ROOT_REQUIRED);
        }
        requireJsonOrNull(request.studyConfig());
        deckMapper.updateStudyConfig(
                context.userId(),
                deck.getId(),
                request.studyConfig(),
                changeVersions.next(context),
                context.deviceId(),
                clock.instant());
    }

    @Override
    @Transactional
    public void refreshContentType(WriteContext context, UUID deckId) {
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null || deck.getParentId() == null) {
            return;
        }
        String derived = deckMapper.deriveContentType(deckId);
        if (!derived.equals(deck.getContentType())) {
            deckMapper.updateContentType(
                    context.userId(), deckId, derived, changeVersions.next(context), context.deviceId(), clock.instant());
        }
    }

    /** A new client id: the owner's own row is a replay gone wrong, another user's is never revealed. */
    private void requireNewId(WriteContext context, UUID id) {
        Deck existing = deckMapper.findDeckById(id);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }

    /** The owner's un-purged deck, in Trash or not; a missing, purged or foreign parent reads as missing. */
    Deck parentOrMissing(WriteContext context, UUID parentId) {
        Deck parent = deckMapper.findDeckById(parentId);
        if (parent == null || !parent.getUserId().equals(context.userId()) || parent.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        return parent;
    }

    /** The owner's active deck: missing or purged is not found, foreign is a conflict, in Trash is refused. */
    Deck activeDeck(WriteContext context, UUID deckId) {
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null || deck.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_NOT_FOUND);
        }
        if (!deck.getUserId().equals(context.userId())) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        if (deck.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        return deck;
    }

    private void requireJsonOrNull(String value) {
        if (value == null) {
            return;
        }
        try {
            objectMapper.readTree(value);
        } catch (JsonProcessingException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }
}
```

- [ ] **Step 10: Register the deck commands**

`deck/service/impl/DeckSyncCommands.java`. Tasks 3 and 4 add more beans here.

```java
package com.memox.deck.service.impl;

import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.PayloadReader;
import com.memox.sync.service.SyncCommandHandler;
import com.memox.sync.service.SyncPatchHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Deck commands and patches of the sync protocol: each reads its payload and calls {@link DeckService}. */
@Configuration(proxyBeanMethods = false)
class DeckSyncCommands {

    @Bean
    SyncCommandHandler createRootDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "CREATE_ROOT_DECK",
                (context, payload) -> decks.createRootDeck(context, payloads.read(payload, CreateRootDeckRequest.class)));
    }

    @Bean
    SyncCommandHandler createSubDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "CREATE_SUB_DECK",
                (context, payload) -> decks.createSubDeck(
                        context,
                        payloads.id(payload, "parentId"),
                        payloads.read(payload, CreateSubDeckRequest.class)));
    }

    @Bean
    SyncCommandHandler renameDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "RENAME_DECK",
                (context, payload) -> decks.renameDeck(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, RenameDeckRequest.class)));
    }

    @Bean
    SyncPatchHandler deckStudyOptionsPatch(DeckService decks, PayloadReader payloads) {
        return new SyncPatchHandler(
                DeckReader.ENTITY_TYPE,
                "study_options",
                (context, deckId, fields) ->
                        decks.updateStudyOptions(context, deckId, payloads.read(fields, StudyOptionsRequest.class)));
    }
}
```

- [ ] **Step 11: Run the tests**

Run: `./mvnw -B test -Dtest='DeckServiceImplIT,TextRulesTest,SyncProtocolIT'`
Expected: PASS.

- [ ] **Step 12: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): DeckService — create, rename, study options, derived content type (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Move and reorder decks

**Files:**
- Create: `main/java/com/memox/deck/dto/request/{MoveDeckRequest,ReorderDeckRequest}.java`, `main/java/com/memox/deck/enums/DeckPlacement.java`, `main/java/com/memox/deck/model/DeckPosition.java`
- Modify: `DeckService.java`, `DeckServiceImpl.java`, `DeckSyncCommands.java`, `DeckMapper.java`, `DeckMapper.xml`
- Test: `DeckServiceImplIT.java` (append); `test/java/com/memox/deck/service/impl/DeckMoveConcurrencyIT.java`

**Interfaces:**
- Consumes: `DeckServiceImpl.activeDeck`, `parentOrMissing`, `refreshContentType`, `MAX_DEPTH` (Task 2).
- Produces:
  - `DeckService.moveDeck(WriteContext, UUID deckId, MoveDeckRequest)` and `reorderDeck(WriteContext, UUID deckId, ReorderDeckRequest)`;
  - `DeckMapper.updatePlacement`, `findActiveSiblings(UUID userId, UUID parentId)` and `updateSiblingPositions(UUID userId, List<DeckPosition>, UUID deviceId, Instant now)`;
  - `updateSubtreePlacement` gains `now`.

- [ ] **Step 1: Append the failing tests to `DeckServiceImplIT`**

Add the imports `com.memox.deck.dto.request.MoveDeckRequest`, `com.memox.deck.dto.request.ReorderDeckRequest`, `com.memox.deck.enums.DeckPlacement` and `java.util.Comparator`, then:

```java
    @Test
    void moveRewritesTheSubtreeAndBothParentsContentType_BR_DECK_015_018() {
        UUID rootA = root("sm2");
        UUID oldParent = child(rootA);
        UUID x = child(oldParent);
        UUID y = child(x);
        UUID newParent = child(rootA);
        long before = deck(y).getServerVersion();

        deckService.moveDeck(ctx, x, new MoveDeckRequest(newParent));

        assertThat(deck(x).getParentId()).isEqualTo(newParent);
        assertThat(deck(x).getDepth()).isEqualTo(3);
        assertThat(deck(y).getDepth()).isEqualTo(4);
        assertThat(deck(y).getServerVersion()).isGreaterThan(before);
        assertThat(deck(oldParent).getContentType()).isEqualTo("unset");
        assertThat(deck(newParent).getContentType()).isEqualTo("deck");
    }

    @Test
    void moveRefusesACycleACardTargetAndTooDeep_BR_DECK_001_010_017() {
        UUID root = root("sm2");
        UUID x = child(root);
        UUID y = child(x);
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(y)), ErrorCode.DECK_TREE_CYCLE);
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(x)), ErrorCode.DECK_TREE_CYCLE);

        UUID cardDeck = child(root);
        deckMapper.updateContentType(ctx.userId(), cardDeck, "card", 999_998L, ctx.deviceId(), deck(root).getUpdatedAt());
        rejects(() -> deckService.moveDeck(ctx, y, new MoveDeckRequest(cardDeck)), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);

        UUID deep = root("sm2");
        for (int level = 2; level <= 9; level++) {
            deep = child(deep);
        }
        UUID ninth = deep;
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(ninth)), ErrorCode.DECK_TREE_TOO_DEEP);
    }

    @Test
    void moveAcrossRootsNeedsTheSameSchedulerAndGeneration_BR_SRS_006() {
        UUID sm2 = root("sm2");
        UUID other = root("sm2");
        UUID eightBox = root("eight_box");
        UUID x = child(sm2);

        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(eightBox)), ErrorCode.DECK_SCHEDULER_MISMATCH);
        deckService.moveDeck(ctx, x, new MoveDeckRequest(other));
        assertThat(deck(x).getRootId()).isEqualTo(other);
    }

    @Test
    void aRootOrASameParentMoveIsNotAMove() {
        UUID root = root("sm2");
        UUID x = child(root);
        UUID target = child(root);
        rejects(() -> deckService.moveDeck(ctx, root, new MoveDeckRequest(target)), ErrorCode.VALIDATION_FAILED);
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(root)), ErrorCode.VALIDATION_FAILED);
    }

    @Test
    void reorderPlacesTheDeckNextToItsAnchorAndBumpsOnlyMovedRows_UC_DECK_006() {
        UUID root = root("sm2");
        UUID a = child(root);
        UUID b = child(root);
        UUID c = child(root);
        long aVersion = deck(a).getServerVersion();

        deckService.reorderDeck(ctx, c, new ReorderDeckRequest(a, DeckPlacement.BEFORE));

        List<UUID> order = java.util.stream.Stream.of(a, b, c)
                .map(this::deck)
                .sorted(Comparator.comparing(Deck::getSiblingPosition))
                .map(Deck::getId)
                .toList();
        assertThat(order).containsExactly(c, a, b);
        assertThat(deck(a).getServerVersion()).isGreaterThan(aVersion);
        rejects(() -> deckService.reorderDeck(ctx, c, new ReorderDeckRequest(root, DeckPlacement.AFTER)),
                ErrorCode.VALIDATION_FAILED);
    }
```

Also add the import `java.util.List`.

`test/java/com/memox/deck/service/impl/DeckMoveConcurrencyIT.java` replaces the retired applier concurrency test:

```java
package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;

import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.MoveDeckRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Two devices move X under Y and Y under X at once. Each move is acyclic alone; together they would form a cycle.
 * The per-user lock serializes them, so the second sees the first and is rejected.
 */
@SpringBootTest
@Import(TestcontainersConfiguration.class)
class DeckMoveConcurrencyIT {

    @Autowired
    DeckService deckService;

    @Autowired
    DeckMapper deckMapper;

    @Autowired
    TransactionTemplate transactionTemplate;

    @Test
    void concurrentCrossMovesNeverFormACycle() throws Exception {
        WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());
        UUID root = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(root, "Root", "sm2"));
        deckService.createSubDeck(ctx, root, new CreateSubDeckRequest(x, "X"));
        deckService.createSubDeck(ctx, root, new CreateSubDeckRequest(y, "Y"));

        CountDownLatch firstApplied = new CountDownLatch(1);
        CountDownLatch secondDone = new CountDownLatch(1);
        CompletableFuture<Void> first =
                CompletableFuture.runAsync(() -> transactionTemplate.executeWithoutResult(status -> {
                    deckService.moveDeck(ctx, x, new MoveDeckRequest(y));
                    firstApplied.countDown();
                    awaitQuietly(secondDone);
                }));
        firstApplied.await(10, TimeUnit.SECONDS);
        CompletableFuture<ErrorCode> second = CompletableFuture.supplyAsync(() -> {
            try {
                deckService.moveDeck(ctx, y, new MoveDeckRequest(x));
                return null;
            } catch (BusinessException e) {
                return e.getErrorCode();
            } finally {
                secondDone.countDown();
            }
        });

        first.get(20, TimeUnit.SECONDS);
        assertThat(second.get(20, TimeUnit.SECONDS)).isEqualTo(ErrorCode.DECK_TREE_CYCLE);
        assertThat(deckMapper.findDeckById(y).getParentId()).isEqualTo(root);
    }

    /** Holds the first transaction open briefly; the second move blocks on the user lock meanwhile. */
    private static void awaitQuietly(CountDownLatch latch) {
        try {
            latch.await(3, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest='DeckServiceImplIT,DeckMoveConcurrencyIT'`
Expected: compilation FAILS (`MoveDeckRequest`, `ReorderDeckRequest` and `DeckPlacement` do not exist).

- [ ] **Step 3: Add the DTOs, enum and position model**

`deck/enums/DeckPlacement.java`:

```java
package com.memox.deck.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

/** Where a reordered deck goes relative to its anchor sibling (UC-DECK-006). */
public enum DeckPlacement {
    @JsonProperty("before")
    BEFORE,
    @JsonProperty("after")
    AFTER
}
```

`deck/dto/request/MoveDeckRequest.java`:

```java
package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code MOVE_DECK} payload (with {@code deckId}) and {@code POST /decks/{id}/move} body. */
public record MoveDeckRequest(@NotNull UUID targetParentId) {}
```

`deck/dto/request/ReorderDeckRequest.java`:

```java
package com.memox.deck.dto.request;

import com.memox.deck.enums.DeckPlacement;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code REORDER_DECK} payload (with {@code deckId}) and {@code POST /decks/{id}/reorder} body. */
public record ReorderDeckRequest(@NotNull UUID anchorId, @NotNull DeckPlacement placement) {}
```

`deck/model/DeckPosition.java`:

```java
package com.memox.deck.model;

import java.util.UUID;

/** A sibling's new position and the version that records it. */
public record DeckPosition(UUID id, int siblingPosition, long serverVersion) {}
```

- [ ] **Step 4: Add the mapper statements**

`DeckMapper.java`: replace the `updateSubtreePlacement` signature, adding `now`, and add:

```java
    int updateSubtreePlacement(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("rootId") UUID rootId,
            @Param("depth") int depth,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int updatePlacement(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("parentId") UUID parentId,
            @Param("rootId") UUID rootId,
            @Param("depth") int depth,
            @Param("siblingPosition") int siblingPosition,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** Active siblings under {@code parentId} ({@code null}: the user's roots), by position then id. */
    List<Deck> findActiveSiblings(@Param("userId") UUID userId, @Param("parentId") UUID parentId);

    int updateSiblingPositions(
            @Param("userId") UUID userId,
            @Param("positions") List<DeckPosition> positions,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);
```

`DeckMapper.xml`: in `updateSubtreePlacement`, add `updated_at = #{now},` after `SET`. Add:

```xml
    <update id="updatePlacement">
        UPDATE deck SET parent_id = #{parentId}, root_id = #{rootId}, depth = #{depth},
                        sibling_position = #{siblingPosition}, updated_at = #{now}, server_version = #{version},
                        last_device_id = #{deviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <select id="findActiveSiblings" resultType="com.memox.deck.model.Deck">
        SELECT <include refid="deckColumns"/> FROM deck
        WHERE user_id = #{userId} AND <include refid="sameParent"/>
          AND deleted_at IS NULL AND delete_batch_id IS NULL
        ORDER BY sibling_position, id
    </select>
    <update id="updateSiblingPositions">
        UPDATE deck
        SET sibling_position = v.position, server_version = v.version, updated_at = #{now},
            last_device_id = #{deviceId}
        FROM (VALUES
            <foreach collection="positions" item="p" separator=",">
                (CAST(#{p.id} AS uuid), CAST(#{p.siblingPosition} AS integer), CAST(#{p.serverVersion} AS bigint))
            </foreach>
        ) AS v(id, position, version)
        WHERE deck.id = v.id AND deck.user_id = #{userId}
    </update>
```

- [ ] **Step 5: Implement move and reorder**

Add to `DeckService`:

```java
    void moveDeck(WriteContext context, UUID deckId, MoveDeckRequest request);

    void reorderDeck(WriteContext context, UUID deckId, ReorderDeckRequest request);
```

Add to `DeckServiceImpl`. The imports needed are `MoveDeckRequest`, `ReorderDeckRequest`, `DeckPlacement`, `DeckPosition`, `DeckSubtreeNode`, `java.util.ArrayList`, `java.util.List` and `java.util.Objects`.

```java
    @Override
    @Transactional
    public void moveDeck(WriteContext context, UUID deckId, MoveDeckRequest request) {
        changeVersions.lock(context);
        Deck moving = activeDeck(context, deckId);
        UUID oldParentId = moving.getParentId();
        // A root owns its scheduler: making it a child, or a child a root, is not a move (UC-DECK-005 A2).
        if (oldParentId == null || oldParentId.equals(request.targetParentId())) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        Deck target = parentOrMissing(context, request.targetParentId());
        List<DeckSubtreeNode> subtree = deckMapper.findLiveSubtree(context.userId(), moving.getId());
        requireNoCycle(target.getId(), moving.getId(), subtree);
        if (target.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        requirePlaceableUnder(target, moving, subtree);

        int depth = target.getDepth() + 1;
        Instant now = clock.instant();
        deckMapper.updatePlacement(
                context.userId(),
                moving.getId(),
                target.getId(),
                target.getRootId(),
                depth,
                deckMapper.nextSiblingPosition(context.userId(), target.getId()),
                changeVersions.next(context),
                context.deviceId(),
                now);
        rewriteDescendants(context, moving.getId(), target.getRootId(), depth, subtree.size() - 1, now);
        refreshContentType(context, oldParentId);
        refreshContentType(context, target.getId());
    }

    @Override
    @Transactional
    public void reorderDeck(WriteContext context, UUID deckId, ReorderDeckRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        Deck anchor = activeDeck(context, request.anchorId());
        if (deck.getId().equals(anchor.getId()) || !Objects.equals(deck.getParentId(), anchor.getParentId())) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        List<Deck> siblings = deckMapper.findActiveSiblings(context.userId(), deck.getParentId());
        List<UUID> order = new ArrayList<>(
                siblings.stream().map(Deck::getId).filter(id -> !id.equals(deckId)).toList());
        int anchorIndex = order.indexOf(anchor.getId());
        order.add(request.placement() == DeckPlacement.BEFORE ? anchorIndex : anchorIndex + 1, deckId);

        List<UUID> moved = new ArrayList<>();
        for (int position = 0; position < order.size(); position++) {
            UUID id = order.get(position);
            Deck sibling = siblings.stream().filter(s -> s.getId().equals(id)).findFirst().orElseThrow();
            if (sibling.getSiblingPosition() != position) {
                moved.add(id);
            }
        }
        if (moved.isEmpty()) {
            return;
        }
        long firstVersion = changeVersions.block(context, moved.size());
        List<DeckPosition> positions = new ArrayList<>();
        for (int i = 0; i < moved.size(); i++) {
            positions.add(new DeckPosition(moved.get(i), order.indexOf(moved.get(i)), firstVersion + i));
        }
        deckMapper.updateSiblingPositions(context.userId(), positions, context.deviceId(), clock.instant());
    }

    /** The UC-DECK-005 checks after the cycle check: content type, scheduler and generation, depth. */
    private void requirePlaceableUnder(Deck target, Deck moving, List<DeckSubtreeNode> subtree) {
        if (DeckContentTypes.CARD.equals(target.getContentType())) {
            throw new BusinessException(ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        }
        Deck movingRoot = deckMapper.findDeckById(moving.getRootId());
        Deck targetRoot = deckMapper.findDeckById(target.getRootId());
        if (!Objects.equals(movingRoot.getSchedulerType(), targetRoot.getSchedulerType())
                || !Objects.equals(movingRoot.getGeneration(), targetRoot.getGeneration())) {
            throw new BusinessException(ErrorCode.DECK_SCHEDULER_MISMATCH);
        }
        int height = subtree.stream().mapToInt(DeckSubtreeNode::getRel).max().orElse(0) + 1;
        if (target.getDepth() + height > MAX_DEPTH) {
            throw new BusinessException(ErrorCode.DECK_TREE_TOO_DEEP);
        }
    }

    /** Descendants follow their top's new root and depth, one version each, Trash included (BR-DECK-018). */
    private void rewriteDescendants(
            WriteContext context, UUID topId, UUID rootId, int topDepth, int descendants, Instant now) {
        if (descendants <= 0) {
            return;
        }
        deckMapper.updateSubtreePlacement(
                context.userId(),
                topId,
                rootId,
                topDepth,
                changeVersions.block(context, descendants),
                context.deviceId(),
                now);
    }

    private static void requireNoCycle(UUID targetId, UUID movingId, List<DeckSubtreeNode> subtree) {
        boolean inside = targetId.equals(movingId)
                || subtree.stream().anyMatch(node -> node.getId().equals(targetId));
        if (inside) {
            throw new BusinessException(ErrorCode.DECK_TREE_CYCLE);
        }
    }
```

- [ ] **Step 6: Register the commands**

Add to `DeckSyncCommands`, importing `MoveDeckRequest` and `ReorderDeckRequest`:

```java
    @Bean
    SyncCommandHandler moveDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "MOVE_DECK",
                (context, payload) -> decks.moveDeck(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, MoveDeckRequest.class)));
    }

    @Bean
    SyncCommandHandler reorderDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "REORDER_DECK",
                (context, payload) -> decks.reorderDeck(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, ReorderDeckRequest.class)));
    }
```

- [ ] **Step 7: Run the tests**

Run: `./mvnw -B test -Dtest='DeckServiceImplIT,DeckMoveConcurrencyIT'`
Expected: PASS.

- [ ] **Step 8: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): move and reorder decks with server-side tree rules (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Delete a deck into Trash, undo, and creates under a deck in Trash

**Files:**
- Create: `main/java/com/memox/deck/dto/request/DeleteDeckRequest.java`
- Modify: `DeckService.java`, `DeckServiceImpl.java`, `DeckSyncCommands.java`, `DeckMapper.java`, `DeckMapper.xml`
- Test: `DeckServiceImplIT.java` (append)

**Interfaces:**
- Consumes: `DeleteBatchMapper.insertDeleteBatch`, `findDeleteBatchById`, `tombstoneDeleteBatch(UUID id, long serverVersion, UUID deviceId)` (Task 1).
- Produces:
  - `DeckService.deleteDeck(WriteContext, UUID deckId, DeleteDeckRequest)` and `undoDeckDeletion(WriteContext, UUID batchId)`;
  - `DeckMapper.findActiveSubtree`, `markActiveSubtree`, `countInBatch` and `restoreBatch`;
  - `DeckServiceImpl.ownedBatch(WriteContext, UUID batchId, String itemType)`, package-visible. Task 8's card undo checks its batch inline, since the two live in different packages.

- [ ] **Step 1: Append the failing tests**

Add the imports `com.memox.deck.dto.request.DeleteDeckRequest`, `com.memox.trash.mapper.DeleteBatchMapper` and `java.time.Instant`, plus `@Autowired DeleteBatchMapper deleteBatchMapper;`, then:

```java
    static final Instant DELETED_AT = Instant.parse("2026-09-27T02:00:00Z");

    UUID delete(UUID deckId) {
        UUID batch = UUID.randomUUID();
        deckService.deleteDeck(ctx, deckId, new DeleteDeckRequest(batch, DELETED_AT));
        return batch;
    }

    @Test
    void deleteMarksTheActiveSubtreeInOneBatchAndUnsetsAnEmptiedParent_BR_DECK_022_TRASH_003_005() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID x = child(parent);
        UUID y = child(x);

        UUID batch = delete(x);

        assertThat(deck(x).getDeleteBatchId()).isEqualTo(batch);
        assertThat(deck(y).getDeleteBatchId()).isEqualTo(batch);
        assertThat(deck(parent).getContentType()).isEqualTo("unset");
        assertThat(deleteBatchMapper.findDeleteBatchById(batch).getDeletedAt()).isEqualTo(DELETED_AT);
        assertThat(deleteBatchMapper.findDeleteBatchById(batch).getRootItemId()).isEqualTo(x);
        rejects(() -> deckService.renameDeck(ctx, x, new RenameDeckRequest("n")), ErrorCode.DECK_IN_TRASH);
    }

    @Test
    void anInnerDeckAlreadyInTrashKeepsItsOwnBatch_BR_TRASH_003() {
        UUID root = root("sm2");
        UUID x = child(root);
        UUID y = child(x);
        UUID inner = delete(y);

        UUID outer = delete(x);

        assertThat(deck(y).getDeleteBatchId()).isEqualTo(inner);
        assertThat(deck(x).getDeleteBatchId()).isEqualTo(outer);
    }

    @Test
    void undoRestoresExactlyTheBatchAndTombstonesIt_BR_TRASH_008() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID x = child(parent);
        UUID y = child(x);
        UUID batch = delete(x);

        deckService.undoDeckDeletion(ctx, batch);

        assertThat(deck(x).getDeleteBatchId()).isNull();
        assertThat(deck(y).getDeleteBatchId()).isNull();
        assertThat(deck(parent).getContentType()).isEqualTo("deck");
        assertThat(deleteBatchMapper.findDeleteBatchById(batch).getTombstonedAt()).isNotNull();
        rejects(() -> deckService.undoDeckDeletion(ctx, batch), ErrorCode.BATCH_NOT_FOUND);
    }

    @Test
    void undoIsRefusedWhenTheOldParentIsNowInTrash() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID x = child(parent);
        UUID inner = delete(x);
        delete(parent);

        rejects(() -> deckService.undoDeckDeletion(ctx, inner), ErrorCode.DECK_IN_TRASH);
    }

    @Test
    void aSubDeckCreatedUnderADeckInTrashJoinsItsBatchAndReturnsWithIt_D4() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID batch = delete(parent);

        UUID late = child(parent);

        assertThat(deck(late).getDeleteBatchId()).isEqualTo(batch);
        assertThat(deck(parent).getContentType()).isEqualTo("deck");
        deckService.undoDeckDeletion(ctx, batch);
        assertThat(deck(late).getDeleteBatchId()).isNull();
        assertThat(deck(parent).getContentType()).isEqualTo("deck");
    }

    @Test
    void aMoveIntoADeckInTrashIsRefused() {
        UUID root = root("sm2");
        UUID target = child(root);
        UUID x = child(root);
        delete(target);

        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(target)), ErrorCode.DECK_IN_TRASH);
    }
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest=DeckServiceImplIT`
Expected: compilation FAILS (`DeleteDeckRequest` does not exist).

- [ ] **Step 3: Add the DTO**

```java
package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

/**
 * {@code DELETE_DECK} payload (with {@code deckId}) and {@code DELETE /decks/{id}} body. {@code batchId} is the
 * client's id for the Trash batch; {@code deletedAt} starts the retention (BR-TRASH-009).
 */
public record DeleteDeckRequest(@NotNull UUID batchId, @NotNull Instant deletedAt) {}
```

- [ ] **Step 4: Add the mapper statements**

`DeckMapper.java`:

```java
    /** The active subtree under {@code id}, itself included at {@code rel = 0}; decks in Trash stop the walk. */
    List<DeckSubtreeNode> findActiveSubtree(@Param("userId") UUID userId, @Param("id") UUID id);

    int markActiveSubtree(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("batchId") UUID batchId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int countInBatch(@Param("userId") UUID userId, @Param("batchId") UUID batchId);

    int restoreBatch(
            @Param("userId") UUID userId,
            @Param("batchId") UUID batchId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);
```

`DeckMapper.xml`:

```xml
    <!-- Active decks under #{id}: a deck in Trash keeps its own batch, and so does everything under it. -->
    <sql id="activeSubtree">
        WITH RECURSIVE sub AS (
            SELECT id, 0 AS rel FROM deck
            WHERE id = #{id} AND user_id = #{userId} AND deleted_at IS NULL AND delete_batch_id IS NULL
            UNION
            SELECT d.id, sub.rel + 1 FROM deck d JOIN sub ON d.parent_id = sub.id
            WHERE d.user_id = #{userId} AND d.deleted_at IS NULL AND d.delete_batch_id IS NULL AND sub.rel &lt; 10
        )
    </sql>
    <select id="findActiveSubtree" resultType="com.memox.deck.model.DeckSubtreeNode">
        <include refid="activeSubtree"/>
        SELECT id, rel FROM sub ORDER BY rel, id
    </select>
    <update id="markActiveSubtree">
        <include refid="activeSubtree"/>,
        numbered AS (SELECT id, ROW_NUMBER() OVER (ORDER BY rel, id) AS rn FROM sub)
        UPDATE deck
        SET delete_batch_id = #{batchId}, server_version = #{firstVersion} + numbered.rn - 1,
            updated_at = #{now}, last_device_id = #{deviceId}
        FROM numbered
        WHERE deck.id = numbered.id
    </update>
    <select id="countInBatch" resultType="int">
        SELECT count(*) FROM deck WHERE user_id = #{userId} AND delete_batch_id = #{batchId} AND deleted_at IS NULL
    </select>
    <update id="restoreBatch">
        WITH numbered AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY depth, id) AS rn FROM deck
            WHERE user_id = #{userId} AND delete_batch_id = #{batchId} AND deleted_at IS NULL
        )
        UPDATE deck
        SET delete_batch_id = NULL, server_version = #{firstVersion} + numbered.rn - 1,
            updated_at = #{now}, last_device_id = #{deviceId}
        FROM numbered
        WHERE deck.id = numbered.id
    </update>
```

- [ ] **Step 5: Implement delete and undo**

Add to `DeckService`:

```java
    void deleteDeck(WriteContext context, UUID deckId, DeleteDeckRequest request);

    void undoDeckDeletion(WriteContext context, UUID batchId);
```

Add to `DeckServiceImpl`:
- a constructor field `private final DeleteBatchMapper deleteBatchMapper;` (placed after `deckMapper`; `@RequiredArgsConstructor` picks it up);
- the imports `DeleteDeckRequest`, `com.memox.trash.mapper.DeleteBatchMapper` and `com.memox.trash.model.DeleteBatch`;
- a constant `static final String BATCH_ITEM_DECK = "deck";`;
- the methods below.

```java
    @Override
    @Transactional
    public void deleteDeck(WriteContext context, UUID deckId, DeleteDeckRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        requireNewBatch(context, request.batchId());
        deleteBatchMapper.insertDeleteBatch(DeleteBatch.builder()
                .id(request.batchId())
                .userId(context.userId())
                .itemType(BATCH_ITEM_DECK)
                .rootItemId(deck.getId())
                .deletedAt(request.deletedAt())
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
        int rows = deckMapper.findActiveSubtree(context.userId(), deck.getId()).size();
        deckMapper.markActiveSubtree(
                context.userId(),
                deck.getId(),
                request.batchId(),
                changeVersions.block(context, rows),
                context.deviceId(),
                clock.instant());
        if (deck.getParentId() != null) {
            refreshContentType(context, deck.getParentId());
        }
    }

    @Override
    @Transactional
    public void undoDeckDeletion(WriteContext context, UUID batchId) {
        changeVersions.lock(context);
        DeleteBatch batch = ownedBatch(context, batchId, BATCH_ITEM_DECK);
        Deck item = deckMapper.findDeckById(batch.getRootItemId());
        if (item == null || item.getDeletedAt() != null || !batchId.equals(item.getDeleteBatchId())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        Deck parent = null;
        List<DeckSubtreeNode> subtree = deckMapper.findLiveSubtree(context.userId(), item.getId());
        if (item.getParentId() != null) {
            parent = parentOrMissing(context, item.getParentId());
            if (parent.getDeleteBatchId() != null) {
                throw new BusinessException(ErrorCode.DECK_IN_TRASH);
            }
            requirePlaceableUnder(parent, item, subtree);
        }
        Instant now = clock.instant();
        int rows = deckMapper.countInBatch(context.userId(), batchId);
        deckMapper.restoreBatch(
                context.userId(), batchId, changeVersions.block(context, rows), context.deviceId(), now);
        if (parent != null) {
            // Back to its old place under a parent that may have moved meanwhile (BR-TRASH-008).
            int depth = parent.getDepth() + 1;
            deckMapper.updatePlacement(
                    context.userId(),
                    item.getId(),
                    parent.getId(),
                    parent.getRootId(),
                    depth,
                    item.getSiblingPosition(),
                    changeVersions.next(context),
                    context.deviceId(),
                    now);
            rewriteDescendants(context, item.getId(), parent.getRootId(), depth, subtree.size() - 1, now);
            refreshContentType(context, parent.getId());
        }
        deleteBatchMapper.tombstoneDeleteBatch(batchId, changeVersions.next(context), context.deviceId());
    }

    /** The owner's live batch of {@code itemType}; anything else has nothing to undo. */
    DeleteBatch ownedBatch(WriteContext context, UUID batchId, String itemType) {
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(batchId);
        if (batch == null
                || !batch.getUserId().equals(context.userId())
                || batch.getTombstonedAt() != null
                || !itemType.equals(batch.getItemType())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        return batch;
    }

    private void requireNewBatch(WriteContext context, UUID batchId) {
        DeleteBatch existing = deleteBatchMapper.findDeleteBatchById(batchId);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }
```

- [ ] **Step 6: Register the commands**

Add to `DeckSyncCommands`, importing `DeleteDeckRequest`:

```java
    @Bean
    SyncCommandHandler deleteDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "DELETE_DECK",
                (context, payload) -> decks.deleteDeck(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, DeleteDeckRequest.class)));
    }

    @Bean
    SyncCommandHandler undoDeckDeletionCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "UNDO_DECK_DELETION",
                (context, payload) -> decks.undoDeckDeletion(context, payloads.id(payload, "batchId")));
    }
```

- [ ] **Step 7: Run the tests**

Run: `./mvnw -B test -Dtest=DeckServiceImplIT`
Expected: PASS.

- [ ] **Step 8: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): delete decks into Trash, undo, creates follow a parent in Trash (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: End-to-end sync with deck commands; phase 1 gate

**Files:**
- Create: `test/java/com/memox/sync/SyncApiIT.java`
- Modify: `memox-api-services/README.md` (Base → Sync bullet)
- Modify: `docs/superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md` (plan-time rulings, see Step 4)

**Interfaces:**
- Consumes: the push and pull endpoints and every deck command (Tasks 1–4).

- [ ] **Step 1: Write the end-to-end test**

```java
package com.memox.sync;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class SyncApiIT {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockitoBean
    CurrentUserProvider currentUserProvider;

    UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    @Test
    void aMoveReachesTheFeedWithBothParentsAndTheSubtree() throws Exception {
        UUID root = UUID.randomUUID();
        UUID from = UUID.randomUUID();
        UUID to = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", from, "parentId", root, "name", "From")),
                command("CREATE_SUB_DECK", Map.of("id", to, "parentId", root, "name", "To")),
                command("CREATE_SUB_DECK", Map.of("id", x, "parentId", from, "name", "X")),
                command("CREATE_SUB_DECK", Map.of("id", y, "parentId", x, "name", "Y")));
        long cursor = readJson(changes(0)).get("nextSince").asLong();

        push(command("MOVE_DECK", Map.of("deckId", x, "targetParentId", to)))
                .andExpect(jsonPath("$.results[0].status").value("applied"));

        JsonNode page = readJson(changes(cursor));
        Set<String> changed = new HashSet<>();
        page.get("changes").forEach(change -> changed.add(change.get("entityId").asText()));
        assertThat(changed).contains(from.toString(), to.toString(), x.toString(), y.toString());
    }

    @Test
    void aRejectedMoveReturnsTheAffectedDeckAndTheBatchGoesOn() throws Exception {
        UUID root = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", x, "parentId", root, "name", "X")),
                command("CREATE_SUB_DECK", Map.of("id", y, "parentId", x, "name", "Y")));

        Map<String, Object> cycle = new LinkedHashMap<>(command("MOVE_DECK", Map.of("deckId", x, "targetParentId", y)));
        cycle.put("affected", List.of(Map.of("entityType", "deck", "entityId", x)));
        push(cycle, command("RENAME_DECK", Map.of("deckId", root, "name", "Renamed")))
                .andExpect(jsonPath("$.results[0].code").value("DECK_TREE_CYCLE"))
                .andExpect(jsonPath("$.results[0].current[0].row.parentId").value(root.toString()))
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void theOldRowShapeFromTheAppIsRejectedPerOperation() throws Exception {
        Map<String, Object> old = new LinkedHashMap<>();
        old.put("opId", UUID.randomUUID());
        old.put("entityType", "deck");
        old.put("entityId", UUID.randomUUID());
        old.put("op", "upsert");
        old.put("row", Map.of("name", "Old"));
        UUID root = UUID.randomUUID();

        push(old, command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")))
                .andExpect(jsonPath("$.results[0].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void aStudyOptionsPatchIsAppliedAndItsTargetReturnedOnRejection() throws Exception {
        UUID root = UUID.randomUUID();
        UUID sub = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", sub, "parentId", root, "name", "Sub")));

        push(patch(root, Map.of("studyConfig", "{\"cardLimit\":5}")), patch(sub, Map.of("studyConfig", "{}")))
                .andExpect(jsonPath("$.results[0].status").value("applied"))
                .andExpect(jsonPath("$.results[1].code").value("DECK_ROOT_REQUIRED"))
                .andExpect(jsonPath("$.results[1].current[0].entityId").value(sub.toString()));
    }

    @Test
    void usersNeverSeeEachOthersDecks() throws Exception {
        UUID root = UUID.randomUUID();
        push(command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Mine", "schedulerType", "sm2")));

        user = UUID.randomUUID();
        Map<String, Object> steal = new LinkedHashMap<>(command("RENAME_DECK", Map.of("deckId", root, "name", "X")));
        steal.put("affected", List.of(Map.of("entityType", "deck", "entityId", root)));
        push(steal)
                .andExpect(jsonPath("$.results[0].code").value("SYNC_ENTITY_CONFLICT"))
                .andExpect(jsonPath("$.results[0].current", hasSize(0)));
        changes(0).andExpect(jsonPath("$.changes", hasSize(0)));
    }

    @Test
    void aSubtreeMoveIsPagedWithoutLosingRows() throws Exception {
        UUID rootA = UUID.randomUUID();
        UUID from = UUID.randomUUID();
        UUID to = UUID.randomUUID();
        List<Map<String, Object>> ops = new ArrayList<>();
        ops.add(command("CREATE_ROOT_DECK", Map.of("id", rootA, "name", "A", "schedulerType", "sm2")));
        ops.add(command("CREATE_SUB_DECK", Map.of("id", from, "parentId", rootA, "name", "From")));
        ops.add(command("CREATE_SUB_DECK", Map.of("id", to, "parentId", rootA, "name", "To")));
        for (int i = 0; i < 4; i++) {
            ops.add(command("CREATE_SUB_DECK", Map.of("id", UUID.randomUUID(), "parentId", from, "name", "C" + i)));
        }
        UUID x = UUID.randomUUID();
        ops.add(command("CREATE_SUB_DECK", Map.of("id", x, "parentId", from, "name", "X")));
        push(ops.toArray(Map[]::new));
        long cursor = readJson(changes(0)).get("nextSince").asLong();

        push(command("MOVE_DECK", Map.of("deckId", from, "targetParentId", to)));

        Set<String> seen = new HashSet<>();
        boolean hasMore = true;
        while (hasMore) {
            JsonNode page = readJson(mockMvc.perform(
                    get("/api/v1/sync/changes").param("since", String.valueOf(cursor)).param("limit", "2")));
            page.get("changes").forEach(change -> seen.add(change.get("entityId").asText()));
            cursor = page.get("nextSince").asLong();
            hasMore = page.get("hasMore").asBoolean();
        }
        assertThat(seen).contains(from.toString(), to.toString(), x.toString());
        assertThat(seen).hasSize(7);
    }

    private ResultActions push(Map<?, ?>... operations) throws Exception {
        Map<String, Object> body = Map.of("deviceId", UUID.randomUUID(), "operations", List.of(operations));
        return mockMvc.perform(post("/api/v1/sync/push")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    private ResultActions changes(long since) throws Exception {
        return mockMvc.perform(get("/api/v1/sync/changes").param("since", String.valueOf(since)));
    }

    private JsonNode readJson(ResultActions result) throws Exception {
        return objectMapper.readTree(result.andReturn().getResponse().getContentAsString());
    }

    private static Map<String, Object> command(String type, Map<String, Object> payload) {
        Map<String, Object> op = new LinkedHashMap<>();
        op.put("opId", UUID.randomUUID());
        op.put("kind", "command");
        op.put("type", type);
        op.put("payload", payload);
        return op;
    }

    private static Map<String, Object> patch(UUID deckId, Map<String, Object> fields) {
        Map<String, Object> op = new LinkedHashMap<>();
        op.put("opId", UUID.randomUUID());
        op.put("kind", "patch");
        op.put("entityType", "deck");
        op.put("entityId", deckId);
        op.put("group", "study_options");
        op.put("fields", fields);
        return op;
    }
}
```

The subtree test expects exactly 7 changed rows: `from` itself, its five descendants (`C0`–`C3`, `X`), and `to`, whose content type turns from `unset` to `deck`. `rootA` is the old parent but a root, so it keeps `deck` and does not change.

- [ ] **Step 2: Run it**

Run: `./mvnw -B test -Dtest=SyncApiIT`
Expected: PASS. A failure here is a real protocol bug. Fix it in the task that owns the failing code, not in this test.

- [ ] **Step 3: Update the README**

In `memox-api-services/README.md`, replace the **Sync (ADR-013)** bullet under "Base" with:

```markdown
- **Sync (ADR-013, ADR-014):** `POST /api/v1/sync/push` applies a batch of
  operations idempotently (`opId`), each in its own transaction. An operation is
  a `command` (`type` + `payload`, run by the same service method as the REST
  route) or a `patch` (`entityType` + `entityId` + `group` + `fields`). The
  result is `applied` with the user's latest version, or `rejected` with `current`:
  the server's copy of each entity in `affected` that the user owns.
  `GET /api/v1/sync/changes?since=&limit=` pages the user's changes by
  `serverVersion`. A feature adds `SyncCommandHandler`/`SyncPatchHandler` beans
  and one `EntityReader`; every write takes `ChangeVersions.lock` and gives each
  changed row its own version. The owner always comes from
  `CurrentUserProvider` (a dev user until login, `MEMOX_DEV_USER_ID`).
```

- [ ] **Step 4: Record the plan-time rulings in the spec**

Append this section to `docs/superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md`:

```markdown
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
```

- [ ] **Step 5: Run the phase gate**

Run: `./mvnw -B verify`
Expected: BUILD SUCCESS, with coverage ≥ 80%. If coverage falls short, add the missing service-branch test in Tasks 2–4's test class. Do not lower the gate.

- [ ] **Step 6: Commit**

```bash
./mvnw -B spotless:apply
git add -A src ../docs README.md
git commit -m "test(api): end-to-end deck command sync; README and spec rulings (API-A2 phase 1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Phase 1 is mergeable here. Merging it now or with the later phases is the owner's choice at execution time.

---

## Phase 2 — Card

### Task 6: Card table, mapper, reader, card-aware content type

**Files:**
- Create: `main/resources/db/migration/V4__card.sql`
- Create: `main/java/com/memox/card/model/Card.java`, `main/java/com/memox/card/dto/CardSyncRow.java`, `main/java/com/memox/card/mapper/CardMapper.java`, `main/resources/mapper/card/CardMapper.xml`, `main/java/com/memox/card/service/impl/CardReader.java`
- Modify: `main/resources/mapper/deck/DeckMapper.xml` (`deriveContentType`)
- Test: `test/java/com/memox/card/mapper/CardMapperIT.java`

**Interfaces:**
- Produces:
  - `Card` model;
  - `CardMapper`, with `findCardById`, `insertCard`, `findChangesSince`, `updateContent`, `updateFlag`, `moveCards`, `markCards`, `markCardsInDeckBatch`, `countCardsInDeckBatch`, `restoreCardBatch` and `countInBatch`. The write statements are defined here and used in Tasks 7–8;
  - `CardReader.ENTITY_TYPE = "card"`.

- [ ] **Step 1: Write the failing mapper test**

```java
package com.memox.card.mapper;

import static org.assertj.core.api.Assertions.assertThat;

import com.memox.TestcontainersConfiguration;
import com.memox.card.model.Card;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class CardMapperIT {

    @Autowired
    CardMapper cardMapper;

    @Autowired
    DeckMapper deckMapper;

    @Autowired
    DeckService deckService;

    @Test
    void aStoredCardMakesItsDeckDeriveCardAndReachesTheFeed() {
        WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());
        UUID root = UUID.randomUUID();
        UUID sub = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(root, "Root", "sm2"));
        deckService.createSubDeck(ctx, root, new CreateSubDeckRequest(sub, "Sub"));
        Instant now = Instant.parse("2026-09-27T01:00:00Z");
        UUID id = UUID.randomUUID();

        cardMapper.insertCard(Card.builder()
                .id(id)
                .userId(ctx.userId())
                .deckId(sub)
                .front("犬")
                .back("dog")
                .flagged(false)
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(10_000L)
                .lastDeviceId(ctx.deviceId())
                .build());

        assertThat(cardMapper.findCardById(id).getBack()).isEqualTo("dog");
        assertThat(deckMapper.deriveContentType(sub)).isEqualTo("card");
        assertThat(cardMapper.findChangesSince(ctx.userId(), 9_999L, 10)).extracting(Card::getId).containsExactly(id);
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest=CardMapperIT`
Expected: compilation FAILS (`CardMapper` and `Card` do not exist).

- [ ] **Step 3: Write the migration**

`V4__card.sql`:

```sql
-- API-A2 spec §3. Card content only: tags are API-B2, the schedule API-B5. Lengths mirror BR-CARD-001..003;
-- the service enforces them in UTF-16 units after NFC, the CHECKs are the database's safety net.
CREATE TABLE card (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    deck_id uuid NOT NULL REFERENCES deck (id),
    front text NOT NULL CHECK (char_length(front) BETWEEN 1 AND 60),
    back text NOT NULL CHECK (char_length(back) BETWEEN 1 AND 240),
    example text NULL CHECK (example IS NULL OR char_length(example) BETWEEN 1 AND 240),
    hint text NULL CHECK (hint IS NULL OR char_length(hint) BETWEEN 1 AND 240),
    pronunciation text NULL CHECK (pronunciation IS NULL OR char_length(pronunciation) BETWEEN 1 AND 240),
    is_flagged boolean NOT NULL DEFAULT false,
    delete_batch_id uuid NULL REFERENCES delete_batch (id),
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    server_version bigint NOT NULL,
    last_device_id uuid NOT NULL,
    deleted_at timestamptz NULL
);
CREATE UNIQUE INDEX uq_card_user_version ON card (user_id, server_version);
CREATE INDEX idx_card_deck ON card (deck_id);
CREATE INDEX idx_card_delete_batch ON card (delete_batch_id);

-- Rows written by the retired row sync are not re-checked; every new write is (spec §3).
ALTER TABLE deck ADD CONSTRAINT fk_deck_delete_batch
    FOREIGN KEY (delete_batch_id) REFERENCES delete_batch (id) NOT VALID;
```

- [ ] **Step 4: Add the model, wire row, mapper and reader**

`card/model/Card.java`:

```java
package com.memox.card.model;

import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** A server {@code card} row. */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Card {
    private UUID id;
    private UUID userId;
    private UUID deckId;
    private String front;
    private String back;
    private String example;
    private String hint;
    private String pronunciation;
    private boolean flagged;
    private UUID deleteBatchId;
    private Instant createdAt;
    private Instant updatedAt;
    private Long serverVersion;
    private UUID lastDeviceId;
    private Instant deletedAt;
}
```

`card/dto/CardSyncRow.java`:

```java
package com.memox.card.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A card on the sync wire. The app computes its own folded columns (BE-C5); {@code isFlagged} is Drift's 0/1. */
@Builder
public record CardSyncRow(
        UUID id,
        UUID deckId,
        String front,
        String back,
        String example,
        String hint,
        String pronunciation,
        boolean isFlagged,
        UUID deleteBatchId,
        Instant createdAt,
        Instant updatedAt) {}
```

`card/mapper/CardMapper.java`:

```java
package com.memox.card.mapper;

import com.memox.card.model.Card;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CardMapper {

    /** Any user's row, purged included: the caller checks ownership. */
    Card findCardById(@Param("id") UUID id);

    List<Card> findCardsByIds(@Param("ids") List<UUID> ids);

    void insertCard(Card card);

    List<Card> findChangesSince(@Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);

    int updateContent(Card card);

    int updateFlag(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("flagged") boolean flagged,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** Moves {@code ids} to {@code deckId}, one version each from {@code firstVersion}, in id order. */
    int moveCards(
            @Param("userId") UUID userId,
            @Param("ids") List<UUID> ids,
            @Param("deckId") UUID deckId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int markCard(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("batchId") UUID batchId,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** Active cards whose deck is in {@code batchId}. */
    int countCardsInDeckBatch(@Param("userId") UUID userId, @Param("batchId") UUID batchId);

    int markCardsInDeckBatch(
            @Param("userId") UUID userId,
            @Param("batchId") UUID batchId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int countInBatch(@Param("userId") UUID userId, @Param("batchId") UUID batchId);

    int restoreCardBatch(
            @Param("userId") UUID userId,
            @Param("batchId") UUID batchId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);
}
```

`mapper/card/CardMapper.xml`:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.memox.card.mapper.CardMapper">
    <sql id="cardColumns">
        id, user_id, deck_id, front, back, example, hint, pronunciation, is_flagged AS flagged, delete_batch_id,
        created_at, updated_at, server_version, last_device_id, deleted_at
    </sql>
    <select id="findCardById" resultType="com.memox.card.model.Card">
        SELECT <include refid="cardColumns"/> FROM card WHERE id = #{id}
    </select>
    <select id="findCardsByIds" resultType="com.memox.card.model.Card">
        SELECT <include refid="cardColumns"/> FROM card
        WHERE id IN <foreach collection="ids" item="id" open="(" separator="," close=")">#{id}</foreach>
        ORDER BY id
    </select>
    <insert id="insertCard">
        INSERT INTO card (id, user_id, deck_id, front, back, example, hint, pronunciation, is_flagged,
                          delete_batch_id, created_at, updated_at, server_version, last_device_id, deleted_at)
        VALUES (#{id}, #{userId}, #{deckId}, #{front}, #{back}, #{example}, #{hint}, #{pronunciation}, #{flagged},
                #{deleteBatchId}, #{createdAt}, #{updatedAt}, #{serverVersion}, #{lastDeviceId}, NULL)
    </insert>
    <select id="findChangesSince" resultType="com.memox.card.model.Card">
        SELECT <include refid="cardColumns"/> FROM card
        WHERE user_id = #{userId} AND server_version &gt; #{since}
        ORDER BY server_version
        LIMIT #{limit}
    </select>
    <update id="updateContent">
        UPDATE card SET front = #{front}, back = #{back}, example = #{example}, hint = #{hint},
                        pronunciation = #{pronunciation}, updated_at = #{updatedAt},
                        server_version = #{serverVersion}, last_device_id = #{lastDeviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <update id="updateFlag">
        UPDATE card SET is_flagged = #{flagged}, updated_at = #{now}, server_version = #{version},
                        last_device_id = #{deviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <update id="moveCards">
        WITH numbered AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM card
            WHERE user_id = #{userId}
              AND id IN <foreach collection="ids" item="id" open="(" separator="," close=")">#{id}</foreach>
        )
        UPDATE card SET deck_id = #{deckId}, server_version = #{firstVersion} + numbered.rn - 1,
                        updated_at = #{now}, last_device_id = #{deviceId}
        FROM numbered
        WHERE card.id = numbered.id
    </update>
    <update id="markCard">
        UPDATE card SET delete_batch_id = #{batchId}, updated_at = #{now}, server_version = #{version},
                        last_device_id = #{deviceId}
        WHERE id = #{id} AND user_id = #{userId}
    </update>
    <sql id="activeCardsInDeckBatch">
        FROM card c JOIN deck d ON d.id = c.deck_id
        WHERE c.user_id = #{userId} AND d.delete_batch_id = #{batchId}
          AND c.delete_batch_id IS NULL AND c.deleted_at IS NULL
    </sql>
    <select id="countCardsInDeckBatch" resultType="int">
        SELECT count(*) <include refid="activeCardsInDeckBatch"/>
    </select>
    <update id="markCardsInDeckBatch">
        WITH numbered AS (
            SELECT c.id, ROW_NUMBER() OVER (ORDER BY c.id) AS rn <include refid="activeCardsInDeckBatch"/>
        )
        UPDATE card SET delete_batch_id = #{batchId}, server_version = #{firstVersion} + numbered.rn - 1,
                        updated_at = #{now}, last_device_id = #{deviceId}
        FROM numbered
        WHERE card.id = numbered.id
    </update>
    <select id="countInBatch" resultType="int">
        SELECT count(*) FROM card WHERE user_id = #{userId} AND delete_batch_id = #{batchId} AND deleted_at IS NULL
    </select>
    <update id="restoreCardBatch">
        WITH numbered AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM card
            WHERE user_id = #{userId} AND delete_batch_id = #{batchId} AND deleted_at IS NULL
        )
        UPDATE card SET delete_batch_id = NULL, server_version = #{firstVersion} + numbered.rn - 1,
                        updated_at = #{now}, last_device_id = #{deviceId}
        FROM numbered
        WHERE card.id = numbered.id
    </update>
</mapper>
```

`card/service/impl/CardReader.java`:

```java
package com.memox.card.service.impl;

import com.memox.card.dto.CardSyncRow;
import com.memox.card.mapper.CardMapper;
import com.memox.card.model.Card;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.service.EntityReader;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The {@code card} rows of the change feed. */
@Component
@RequiredArgsConstructor
public class CardReader implements EntityReader {

    public static final String ENTITY_TYPE = "card";

    private final CardMapper cardMapper;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        Card card = cardMapper.findCardById(entityId);
        if (card == null) {
            return SyncChange.absent(ENTITY_TYPE, entityId);
        }
        return card.getUserId().equals(userId) ? toChange(card) : null;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return cardMapper.findChangesSince(userId, since, limit).stream()
                .map(CardReader::toChange)
                .toList();
    }

    private static SyncChange toChange(Card card) {
        boolean deleted = card.getDeletedAt() != null;
        CardSyncRow row = deleted
                ? null
                : CardSyncRow.builder()
                        .id(card.getId())
                        .deckId(card.getDeckId())
                        .front(card.getFront())
                        .back(card.getBack())
                        .example(card.getExample())
                        .hint(card.getHint())
                        .pronunciation(card.getPronunciation())
                        .isFlagged(card.isFlagged())
                        .deleteBatchId(card.getDeleteBatchId())
                        .createdAt(card.getCreatedAt())
                        .updatedAt(card.getUpdatedAt())
                        .build();
        return new SyncChange(ENTITY_TYPE, card.getId(), card.getServerVersion(), deleted, row);
    }
}
```

In `DeckMapper.xml`, replace `deriveContentType` with the card-aware version:

```xml
    <select id="deriveContentType" resultType="string">
        SELECT CASE
            WHEN EXISTS (SELECT 1 FROM deck c WHERE c.parent_id = p.id AND c.deleted_at IS NULL
                         AND c.delete_batch_id IS NOT DISTINCT FROM p.delete_batch_id) THEN 'deck'
            WHEN EXISTS (SELECT 1 FROM card c WHERE c.deck_id = p.id AND c.deleted_at IS NULL
                         AND c.delete_batch_id IS NOT DISTINCT FROM p.delete_batch_id) THEN 'card'
            ELSE 'unset' END
        FROM deck p WHERE p.id = #{id}
    </select>
```

- [ ] **Step 5: Run the tests**

Run: `./mvnw -B test -Dtest='CardMapperIT,DeckServiceImplIT,SchemaIT'`
Expected: PASS.

- [ ] **Step 6: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): card table, mapper and change feed; content type counts cards (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: CardService — create, content, flag, create under a deck in Trash

**Files:**
- Create: `main/java/com/memox/card/dto/request/{CreateCardRequest,CardContentRequest,CardFlagRequest}.java`
- Create: `main/java/com/memox/card/service/CardService.java`, `main/java/com/memox/card/service/impl/CardServiceImpl.java`, `main/java/com/memox/card/service/impl/CardSyncCommands.java`
- Test: `test/java/com/memox/card/service/impl/CardServiceImplIT.java`

**Interfaces:**
- Consumes: `DeckService.refreshContentType`, `DeckMapper.findDeckById` and `CardMapper` (Tasks 2 and 6).
- Produces:
  - `CardService`, with `createCard(WriteContext, UUID deckId, CreateCardRequest)`, `updateContent(WriteContext, UUID cardId, CardContentRequest)` and `updateFlag(WriteContext, UUID cardId, CardFlagRequest)`;
  - `CardServiceImpl.activeCard(WriteContext, UUID)`.

- [ ] **Step 1: Write the failing tests**

```java
package com.memox.card.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.mapper.CardMapper;
import com.memox.card.model.Card;
import com.memox.card.service.CardService;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.DeleteDeckRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import java.time.Instant;
import java.util.UUID;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class CardServiceImplIT {

    static final Instant DELETED_AT = Instant.parse("2026-09-27T02:00:00Z");

    @Autowired
    CardService cardService;

    @Autowired
    DeckService deckService;

    @Autowired
    CardMapper cardMapper;

    @Autowired
    DeckMapper deckMapper;

    final WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());

    UUID root() {
        UUID id = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(id, "Root", "sm2"));
        return id;
    }

    UUID sub(UUID parent) {
        UUID id = UUID.randomUUID();
        deckService.createSubDeck(ctx, parent, new CreateSubDeckRequest(id, "Sub"));
        return id;
    }

    UUID card(UUID deck) {
        UUID id = UUID.randomUUID();
        cardService.createCard(ctx, deck, new CreateCardRequest(id, "犬", "dog", null, null, null));
        return id;
    }

    Card stored(UUID id) {
        return cardMapper.findCardById(id);
    }

    String contentType(UUID deckId) {
        return deckMapper.findDeckById(deckId).getContentType();
    }

    static void rejects(ThrowingCallable call, ErrorCode code) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(code);
    }

    @Test
    void createCardTurnsAnUnsetDeckIntoACardDeckAndStoresNfcText_BR_DECK_008_CARD_001() {
        UUID deck = sub(root());
        UUID id = UUID.randomUUID();

        cardService.createCard(ctx, deck, new CreateCardRequest(id, " café ", "coffee", "  ", null, "ka-fe"));

        assertThat(stored(id).getFront()).isEqualTo("café");
        assertThat(stored(id).getExample()).isNull();
        assertThat(stored(id).getPronunciation()).isEqualTo("ka-fe");
        assertThat(contentType(deck)).isEqualTo("card");
    }

    @Test
    void createCardRefusesARootADeckParentAndTooLongText_BR_DECK_004_010_CARD_002() {
        UUID root = root();
        UUID parent = sub(root);
        sub(parent);

        rejects(() -> card(root), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        rejects(() -> card(parent), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        UUID deck = sub(root);
        rejects(() -> cardService.createCard(
                        ctx, deck, new CreateCardRequest(UUID.randomUUID(), "x".repeat(61), "b", null, null, null)),
                ErrorCode.VALIDATION_FAILED);
        rejects(() -> card(UUID.randomUUID()), ErrorCode.DECK_PARENT_MISSING);
    }

    @Test
    void aCardCreatedInADeckInTrashJoinsItsBatch_D4() {
        UUID root = root();
        UUID deck = sub(root);
        UUID batch = UUID.randomUUID();
        deckService.deleteDeck(ctx, deck, new DeleteDeckRequest(batch, DELETED_AT));

        UUID late = card(deck);

        assertThat(stored(late).getDeleteBatchId()).isEqualTo(batch);
        assertThat(contentType(deck)).isEqualTo("card");
    }

    @Test
    void contentAndFlagPatchesKeepTheCardAndItsDeck_BR_CARD_005_009() {
        UUID deck = sub(root());
        UUID id = card(deck);

        cardService.updateContent(ctx, id, new CardContentRequest("猫", "cat", "a cat", "meow", null));
        cardService.updateFlag(ctx, id, new CardFlagRequest(true));

        assertThat(stored(id).getFront()).isEqualTo("猫");
        assertThat(stored(id).getHint()).isEqualTo("meow");
        assertThat(stored(id).isFlagged()).isTrue();
        assertThat(stored(id).getDeckId()).isEqualTo(deck);
        rejects(() -> cardService.updateFlag(ctx, UUID.randomUUID(), new CardFlagRequest(true)),
                ErrorCode.CARD_NOT_FOUND);
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest=CardServiceImplIT`
Expected: compilation FAILS (`CardService` does not exist).

- [ ] **Step 3: Add the DTOs**

```java
package com.memox.card.dto.request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code CREATE_CARD} payload (with {@code deckId}) and {@code POST /decks/{id}/cards} body. */
public record CreateCardRequest(
        @NotNull UUID id,
        @NotNull String front,
        @NotNull String back,
        String example,
        String hint,
        String pronunciation) {}
```

```java
package com.memox.card.dto.request;

import jakarta.validation.constraints.NotNull;

/** Patch {@code card/content} fields and {@code PATCH /cards/{id}} body; blank optional fields become null. */
public record CardContentRequest(
        @NotNull String front, @NotNull String back, String example, String hint, String pronunciation) {}
```

```java
package com.memox.card.dto.request;

import jakarta.validation.constraints.NotNull;

/** Patch {@code card/flag} fields and {@code PUT /cards/{id}/flag} body (BR-CARD-009). */
public record CardFlagRequest(@NotNull Boolean isFlagged) {}
```

- [ ] **Step 4: Implement the service**

`card/service/CardService.java`:

```java
package com.memox.card.service;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.sync.service.WriteContext;
import java.util.UUID;

/** Card operations, shared by REST and sync commands (API-A2 spec §5). Every method is one transaction. */
public interface CardService {

    void createCard(WriteContext context, UUID deckId, CreateCardRequest request);

    void updateContent(WriteContext context, UUID cardId, CardContentRequest request);

    void updateFlag(WriteContext context, UUID cardId, CardFlagRequest request);
}
```

`card/service/impl/CardServiceImpl.java`:

```java
package com.memox.card.service.impl;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.mapper.CardMapper;
import com.memox.card.model.Card;
import com.memox.card.service.CardService;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.util.TextRules;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckContentTypes;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CardServiceImpl implements CardService {

    static final int FRONT_MAX_LENGTH = 60;
    static final int BACK_MAX_LENGTH = 240;
    static final int EXTRA_MAX_LENGTH = 240;

    private final CardMapper cardMapper;
    private final DeckMapper deckMapper;
    private final DeckService deckService;
    private final ChangeVersions changeVersions;
    private final Clock clock;

    @Override
    @Transactional
    public void createCard(WriteContext context, UUID deckId, CreateCardRequest request) {
        changeVersions.lock(context);
        requireNewId(context, request.id());
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null || !deck.getUserId().equals(context.userId()) || deck.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        requireCardHolder(deck);
        Instant now = clock.instant();
        cardMapper.insertCard(Card.builder()
                .id(request.id())
                .userId(context.userId())
                .deckId(deck.getId())
                .front(TextRules.required(request.front(), FRONT_MAX_LENGTH))
                .back(TextRules.required(request.back(), BACK_MAX_LENGTH))
                .example(TextRules.optional(request.example(), EXTRA_MAX_LENGTH))
                .hint(TextRules.optional(request.hint(), EXTRA_MAX_LENGTH))
                .pronunciation(TextRules.optional(request.pronunciation(), EXTRA_MAX_LENGTH))
                // A deck in Trash takes its new card along (API-A2 spec D4).
                .deleteBatchId(deck.getDeleteBatchId())
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
        deckService.refreshContentType(context, deck.getId());
    }

    @Override
    @Transactional
    public void updateContent(WriteContext context, UUID cardId, CardContentRequest request) {
        changeVersions.lock(context);
        Card card = activeCard(context, cardId);
        card.setFront(TextRules.required(request.front(), FRONT_MAX_LENGTH));
        card.setBack(TextRules.required(request.back(), BACK_MAX_LENGTH));
        card.setExample(TextRules.optional(request.example(), EXTRA_MAX_LENGTH));
        card.setHint(TextRules.optional(request.hint(), EXTRA_MAX_LENGTH));
        card.setPronunciation(TextRules.optional(request.pronunciation(), EXTRA_MAX_LENGTH));
        card.setUpdatedAt(clock.instant());
        card.setServerVersion(changeVersions.next(context));
        card.setLastDeviceId(context.deviceId());
        cardMapper.updateContent(card);
    }

    @Override
    @Transactional
    public void updateFlag(WriteContext context, UUID cardId, CardFlagRequest request) {
        changeVersions.lock(context);
        Card card = activeCard(context, cardId);
        cardMapper.updateFlag(
                context.userId(),
                card.getId(),
                request.isFlagged(),
                changeVersions.next(context),
                context.deviceId(),
                clock.instant());
    }

    /** A sub-deck that holds cards or nothing yet (BR-DECK-004, BR-DECK-010). */
    static void requireCardHolder(Deck deck) {
        if (deck.getParentId() == null || DeckContentTypes.DECK.equals(deck.getContentType())) {
            throw new BusinessException(ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        }
    }

    /** The owner's active card: missing or purged is not found, foreign is a conflict, in Trash is refused. */
    Card activeCard(WriteContext context, UUID cardId) {
        Card card = cardMapper.findCardById(cardId);
        if (card == null || card.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.CARD_NOT_FOUND);
        }
        if (!card.getUserId().equals(context.userId())) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        if (card.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.CARD_IN_TRASH);
        }
        return card;
    }

    private void requireNewId(WriteContext context, UUID id) {
        Card existing = cardMapper.findCardById(id);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }
}
```

`updateContent` fills a mutable model with setters. That is the model's MyBatis contract (`@Setter`) applied to a row read from the database, not the construction of a new object, so it is outside the `@Builder` rule.

- [ ] **Step 5: Register the commands and patches**

`card/service/impl/CardSyncCommands.java`:

```java
package com.memox.card.service.impl;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.service.CardService;
import com.memox.sync.service.PayloadReader;
import com.memox.sync.service.SyncCommandHandler;
import com.memox.sync.service.SyncPatchHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Card commands and patches of the sync protocol: each reads its payload and calls {@link CardService}. */
@Configuration(proxyBeanMethods = false)
class CardSyncCommands {

    @Bean
    SyncCommandHandler createCardCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "CREATE_CARD",
                (context, payload) -> cards.createCard(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, CreateCardRequest.class)));
    }

    @Bean
    SyncPatchHandler cardContentPatch(CardService cards, PayloadReader payloads) {
        return new SyncPatchHandler(
                CardReader.ENTITY_TYPE,
                "content",
                (context, cardId, fields) ->
                        cards.updateContent(context, cardId, payloads.read(fields, CardContentRequest.class)));
    }

    @Bean
    SyncPatchHandler cardFlagPatch(CardService cards, PayloadReader payloads) {
        return new SyncPatchHandler(
                CardReader.ENTITY_TYPE,
                "flag",
                (context, cardId, fields) ->
                        cards.updateFlag(context, cardId, payloads.read(fields, CardFlagRequest.class)));
    }
}
```

- [ ] **Step 6: Run the tests**

Run: `./mvnw -B test -Dtest=CardServiceImplIT`
Expected: PASS.

- [ ] **Step 7: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): CardService — create, content and flag patches, create under a deck in Trash (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Move and delete cards, undo; deck delete and undo carry cards; phase 2 gate

**Files:**
- Create: `main/java/com/memox/card/dto/request/{MoveCardsRequest,DeleteCardsRequest}.java`
- Modify: `CardService.java`, `CardServiceImpl.java`, `CardSyncCommands.java`, `DeckServiceImpl.java`
- Test: `CardServiceImplIT.java` (append), `SyncApiIT.java` (append)

**Interfaces:**
- Consumes: the `CardMapper` statements (Task 6), `DeleteBatchMapper`, and `DeckServiceImpl.deleteDeck`/`undoDeckDeletion` (Task 4).
- Produces: `CardService.moveCards(WriteContext, MoveCardsRequest)`, `deleteCards(WriteContext, DeleteCardsRequest)` and `undoCardDeletion(WriteContext, UUID batchId)`.

- [ ] **Step 1: Append the failing tests to `CardServiceImplIT`**

Add the imports `com.memox.card.dto.request.MoveCardsRequest`, `com.memox.card.dto.request.DeleteCardsRequest` and `java.util.List`, then:

```java
    @Test
    void moveCardsBetweenSubDecksOfOneRootUpdatesBothContentTypes_BR_CARD_010() {
        UUID root = root();
        UUID from = sub(root);
        UUID to = sub(root);
        UUID a = card(from);
        UUID b = card(from);

        cardService.moveCards(ctx, new MoveCardsRequest(List.of(a, b), to));

        assertThat(stored(a).getDeckId()).isEqualTo(to);
        assertThat(contentType(from)).isEqualTo("unset");
        assertThat(contentType(to)).isEqualTo("card");
    }

    @Test
    void moveCardsIsAllOrNothingAndStaysInOneRoot_BR_CARD_010_011() {
        UUID root = root();
        UUID from = sub(root);
        UUID a = card(from);
        UUID otherRootDeck = sub(root());
        UUID deckParent = sub(root);
        sub(deckParent);

        rejects(() -> cardService.moveCards(ctx, new MoveCardsRequest(List.of(a), otherRootDeck)),
                ErrorCode.CARD_MOVE_CROSS_ROOT);
        rejects(() -> cardService.moveCards(ctx, new MoveCardsRequest(List.of(a), deckParent)),
                ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        rejects(() -> cardService.moveCards(ctx, new MoveCardsRequest(List.of(a, UUID.randomUUID()), sub(root))),
                ErrorCode.CARD_NOT_FOUND);
        assertThat(stored(a).getDeckId()).isEqualTo(from);
    }

    @Test
    void deleteCardsMakesOneBatchPerCardAndUndoRestoresOne_BR_TRASH_001_008() {
        UUID deck = sub(root());
        UUID a = card(deck);
        UUID b = card(deck);
        UUID batchA = UUID.randomUUID();
        UUID batchB = UUID.randomUUID();

        cardService.deleteCards(ctx, new DeleteCardsRequest(
                List.of(new DeleteCardsRequest.Item(a, batchA), new DeleteCardsRequest.Item(b, batchB)), DELETED_AT));

        assertThat(stored(a).getDeleteBatchId()).isEqualTo(batchA);
        assertThat(contentType(deck)).isEqualTo("unset");
        cardService.undoCardDeletion(ctx, batchA);
        assertThat(stored(a).getDeleteBatchId()).isNull();
        assertThat(stored(b).getDeleteBatchId()).isEqualTo(batchB);
        assertThat(contentType(deck)).isEqualTo("card");
        rejects(() -> cardService.undoCardDeletion(ctx, batchA), ErrorCode.BATCH_NOT_FOUND);
    }

    @Test
    void deletingADeckTakesItsCardsAndUndoBringsThemBack_BR_DECK_022() {
        UUID root = root();
        UUID deck = sub(root);
        UUID a = card(deck);
        UUID batch = UUID.randomUUID();

        deckService.deleteDeck(ctx, deck, new DeleteDeckRequest(batch, DELETED_AT));
        assertThat(stored(a).getDeleteBatchId()).isEqualTo(batch);
        rejects(() -> cardService.updateFlag(ctx, a, new CardFlagRequest(true)), ErrorCode.CARD_IN_TRASH);

        deckService.undoDeckDeletion(ctx, batch);
        assertThat(stored(a).getDeleteBatchId()).isNull();
        assertThat(contentType(deck)).isEqualTo("card");
    }

    @Test
    void aCardDeletedAloneKeepsItsOwnBatchWhenItsDeckIsDeletedLater_BR_TRASH_003() {
        UUID deck = sub(root());
        UUID a = card(deck);
        UUID own = UUID.randomUUID();
        cardService.deleteCards(ctx, new DeleteCardsRequest(List.of(new DeleteCardsRequest.Item(a, own)), DELETED_AT));

        deckService.deleteDeck(ctx, deck, new DeleteDeckRequest(UUID.randomUUID(), DELETED_AT));

        assertThat(stored(a).getDeleteBatchId()).isEqualTo(own);
    }
```

Append to `SyncApiIT`:

```java
    @Test
    void aCardCreatedOfflineUnderADeletedDeckIsKeptInTheDecksBatch() throws Exception {
        UUID root = UUID.randomUUID();
        UUID deck = UUID.randomUUID();
        UUID batch = UUID.randomUUID();
        UUID card = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", deck, "parentId", root, "name", "Deck")),
                command("DELETE_DECK", Map.of("deckId", deck, "batchId", batch, "deletedAt", "2026-09-27T02:00:00Z")));

        push(command("CREATE_CARD", Map.of("id", card, "deckId", deck, "front", "犬", "back", "dog")))
                .andExpect(jsonPath("$.results[0].status").value("applied"));

        JsonNode feed = readJson(changes(0));
        JsonNode cardChange = null;
        for (JsonNode change : feed.get("changes")) {
            if (change.get("entityId").asText().equals(card.toString())) {
                cardChange = change;
            }
        }
        assertThat(cardChange).isNotNull();
        assertThat(cardChange.get("row").get("deleteBatchId").asText()).isEqualTo(batch.toString());
    }
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest='CardServiceImplIT,SyncApiIT'`
Expected: compilation FAILS (`MoveCardsRequest` and `DeleteCardsRequest` do not exist).

- [ ] **Step 3: Add the DTOs**

```java
package com.memox.card.dto.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/** {@code MOVE_CARDS} payload and {@code POST /cards/move} body; all or nothing (BR-CARD-011). */
public record MoveCardsRequest(
        @NotEmpty @Size(max = MoveCardsRequest.MAX_CARDS) List<@NotNull UUID> cardIds, @NotNull UUID targetDeckId) {

    public static final int MAX_CARDS = 1000;
}
```

```java
package com.memox.card.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** {@code DELETE_CARDS} payload and {@code POST /cards/delete} body: one client batch id per card (BR-TRASH-001). */
public record DeleteCardsRequest(
        @NotEmpty @Size(max = DeleteCardsRequest.MAX_CARDS) List<@Valid @NotNull Item> items,
        @NotNull Instant deletedAt) {

    public static final int MAX_CARDS = 1000;

    public record Item(@NotNull UUID cardId, @NotNull UUID batchId) {}
}
```

- [ ] **Step 4: Implement the card operations**

Add to `CardService`:

```java
    void moveCards(WriteContext context, MoveCardsRequest request);

    void deleteCards(WriteContext context, DeleteCardsRequest request);

    void undoCardDeletion(WriteContext context, UUID batchId);
```

Add to `CardServiceImpl`:
- a constructor field `private final DeleteBatchMapper deleteBatchMapper;`;
- the imports `MoveCardsRequest`, `DeleteCardsRequest`, `com.memox.trash.mapper.DeleteBatchMapper`, `com.memox.trash.model.DeleteBatch`, `java.util.LinkedHashSet`, `java.util.List`, `java.util.Objects` and `java.util.Set`;
- a constant `static final String BATCH_ITEM_CARD = "card";`;
- the methods below.

```java
    @Override
    @Transactional
    public void moveCards(WriteContext context, MoveCardsRequest request) {
        changeVersions.lock(context);
        List<UUID> ids = request.cardIds().stream().distinct().sorted().toList();
        List<Card> cards = ids.stream().map(id -> activeCard(context, id)).toList();
        Deck target = deckMapper.findDeckById(request.targetDeckId());
        if (target == null || !target.getUserId().equals(context.userId()) || target.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_NOT_FOUND);
        }
        if (target.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        requireCardHolder(target);
        Set<UUID> sources = new LinkedHashSet<>();
        for (Card card : cards) {
            Deck source = deckMapper.findDeckById(card.getDeckId());
            if (!Objects.equals(source.getRootId(), target.getRootId())) {
                throw new BusinessException(ErrorCode.CARD_MOVE_CROSS_ROOT);
            }
            sources.add(source.getId());
        }
        cardMapper.moveCards(
                context.userId(),
                ids,
                target.getId(),
                changeVersions.block(context, ids.size()),
                context.deviceId(),
                clock.instant());
        sources.forEach(deckId -> deckService.refreshContentType(context, deckId));
        deckService.refreshContentType(context, target.getId());
    }

    @Override
    @Transactional
    public void deleteCards(WriteContext context, DeleteCardsRequest request) {
        changeVersions.lock(context);
        Set<UUID> decks = new LinkedHashSet<>();
        Instant now = clock.instant();
        for (DeleteCardsRequest.Item item : request.items()) {
            Card card = activeCard(context, item.cardId());
            requireNewBatch(context, item.batchId());
            deleteBatchMapper.insertDeleteBatch(DeleteBatch.builder()
                    .id(item.batchId())
                    .userId(context.userId())
                    .itemType(BATCH_ITEM_CARD)
                    .rootItemId(card.getId())
                    .deletedAt(request.deletedAt())
                    .serverVersion(changeVersions.next(context))
                    .lastDeviceId(context.deviceId())
                    .build());
            cardMapper.markCard(
                    context.userId(), card.getId(), item.batchId(), changeVersions.next(context), context.deviceId(), now);
            decks.add(card.getDeckId());
        }
        decks.forEach(deckId -> deckService.refreshContentType(context, deckId));
    }

    @Override
    @Transactional
    public void undoCardDeletion(WriteContext context, UUID batchId) {
        changeVersions.lock(context);
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(batchId);
        if (batch == null
                || !batch.getUserId().equals(context.userId())
                || batch.getTombstonedAt() != null
                || !BATCH_ITEM_CARD.equals(batch.getItemType())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        Card card = cardMapper.findCardById(batch.getRootItemId());
        if (card == null || card.getDeletedAt() != null || !batchId.equals(card.getDeleteBatchId())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        Deck deck = deckMapper.findDeckById(card.getDeckId());
        if (deck == null || deck.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        if (deck.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        requireCardHolder(deck);
        cardMapper.restoreCardBatch(
                context.userId(), batchId, changeVersions.block(context, 1), context.deviceId(), clock.instant());
        deckService.refreshContentType(context, deck.getId());
        deleteBatchMapper.tombstoneDeleteBatch(batchId, changeVersions.next(context), context.deviceId());
    }

    private void requireNewBatch(WriteContext context, UUID batchId) {
        DeleteBatch existing = deleteBatchMapper.findDeleteBatchById(batchId);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }
```

- [ ] **Step 5: Make deck delete and undo carry cards**

In `DeckServiceImpl`, add the constructor field `private final CardMapper cardMapper;` (import `com.memox.card.mapper.CardMapper`).

In `deleteDeck`, right after `deckMapper.markActiveSubtree(...)`:

```java
        int cards = cardMapper.countCardsInDeckBatch(context.userId(), request.batchId());
        if (cards > 0) {
            cardMapper.markCardsInDeckBatch(
                    context.userId(),
                    request.batchId(),
                    changeVersions.block(context, cards),
                    context.deviceId(),
                    clock.instant());
        }
```

In `undoDeckDeletion`, right after `deckMapper.restoreBatch(...)`:

```java
        int cards = cardMapper.countInBatch(context.userId(), batchId);
        if (cards > 0) {
            cardMapper.restoreCardBatch(
                    context.userId(), batchId, changeVersions.block(context, cards), context.deviceId(), now);
        }
```

- [ ] **Step 6: Register the commands**

Add to `CardSyncCommands`, importing `MoveCardsRequest` and `DeleteCardsRequest`:

```java
    @Bean
    SyncCommandHandler moveCardsCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "MOVE_CARDS",
                (context, payload) -> cards.moveCards(context, payloads.read(payload, MoveCardsRequest.class)));
    }

    @Bean
    SyncCommandHandler deleteCardsCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "DELETE_CARDS",
                (context, payload) -> cards.deleteCards(context, payloads.read(payload, DeleteCardsRequest.class)));
    }

    @Bean
    SyncCommandHandler undoCardDeletionCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "UNDO_CARD_DELETION",
                (context, payload) -> cards.undoCardDeletion(context, payloads.id(payload, "batchId")));
    }
```

- [ ] **Step 7: Run the phase gate**

Run: `./mvnw -B verify`
Expected: BUILD SUCCESS, with coverage ≥ 80%.

- [ ] **Step 8: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): move and delete cards, undo; deck deletion carries its cards (API-A2 phase 2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Phase 2 is mergeable here.

---

## Phase 3 — REST

### Task 9: REST foundations and deck write routes

**Files:**
- Create: `main/java/com/memox/sync/service/IdempotencyService.java`, `main/java/com/memox/sync/service/impl/IdempotencyServiceImpl.java`
- Create: `main/java/com/memox/deck/dto/response/DeckResponse.java`, `main/java/com/memox/deck/controller/DeckController.java`
- Modify: `DeckService.java` and `DeckServiceImpl.java` (add `getDeck`)
- Test: `test/java/com/memox/deck/controller/DeckControllerIT.java`

**Interfaces:**
- Consumes: `DeckService` (Tasks 2–4), `SyncAppliedOpMapper`, `ChangeVersions`.
- Produces:
  - `IdempotencyService.runOnce(UUID userId, UUID key, Runnable write)`: runs `write` once per key, and always when `key` is `null`;
  - `WriteContext.rest(UUID userId, UUID deviceIdOrNull)`, with `WriteContext.DEVICE_HEADER` and `IDEMPOTENCY_HEADER` (added to the Task 1 record);
  - `DeckService.getDeck(UUID userId, UUID deckId)` → `DeckResponse` (active only, else `DECK_NOT_FOUND`).

- [ ] **Step 1: Write the failing REST tests**

```java
package com.memox.deck.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class DeckControllerIT {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    DeckMapper deckMapper;

    @MockitoBean
    CurrentUserProvider currentUserProvider;

    UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, Object body) throws Exception {
        return request.contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(body));
    }

    UUID createRoot() throws Exception {
        UUID id = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/decks"), Map.of("id", id, "name", "Root", "schedulerType", "sm2")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(jsonPath("$.contentType").value("deck"));
        return id;
    }

    UUID createSub(UUID parent) throws Exception {
        UUID id = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/decks/{id}/sub-decks", parent), Map.of("id", id, "name", "Sub")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.parentId").value(parent.toString()));
        return id;
    }

    @Test
    void deckWriteRoutesApplyTheSameRulesAsSyncCommands() throws Exception {
        UUID root = createRoot();
        UUID a = createSub(root);
        UUID b = createSub(root);
        UUID x = createSub(a);

        mockMvc.perform(json(patch("/api/v1/decks/{id}", x), Map.of("name", " Renamed ")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Renamed"));
        mockMvc.perform(json(post("/api/v1/decks/{id}/move", x), Map.of("targetParentId", b)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.parentId").value(b.toString()));
        mockMvc.perform(json(post("/api/v1/decks/{id}/reorder", b), Map.of("anchorId", a, "placement", "before")))
                .andExpect(status().isOk());
        mockMvc.perform(json(put("/api/v1/decks/{id}/study-options", root), Map.of("studyConfig", "{}")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.studyConfig").value("{}"));
        mockMvc.perform(json(post("/api/v1/decks/{id}/move", a), Map.of("targetParentId", a)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DECK_TREE_CYCLE"));
        mockMvc.perform(json(delete("/api/v1/decks/{id}", b),
                        Map.of("batchId", UUID.randomUUID(), "deletedAt", "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());
        mockMvc.perform(json(patch("/api/v1/decks/{id}", UUID.randomUUID()), Map.of("name", "x")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
    }

    @Test
    void anIdempotencyKeyReplayWritesNothingAndAnswersLikeTheFirstTime() throws Exception {
        UUID root = createRoot();
        UUID key = UUID.randomUUID();

        mockMvc.perform(json(patch("/api/v1/decks/{id}", root), Map.of("name", "First")).header("Idempotency-Key", key))
                .andExpect(status().isOk());
        long version = deckMapper.findDeckById(root).getServerVersion();
        mockMvc.perform(json(patch("/api/v1/decks/{id}", root), Map.of("name", "Second")).header("Idempotency-Key", key))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("First"));

        assertThat(deckMapper.findDeckById(root).getServerVersion()).isEqualTo(version);
    }

    @Test
    void aRestWriteAndASyncCommandLeaveTheSameRow() throws Exception {
        UUID viaRest = createRoot();
        mockMvc.perform(json(patch("/api/v1/decks/{id}", viaRest), Map.of("name", "Same")))
                .andExpect(status().isOk());

        UUID viaSync = UUID.randomUUID();
        Map<String, Object> create = new LinkedHashMap<>();
        create.put("opId", UUID.randomUUID());
        create.put("kind", "command");
        create.put("type", "CREATE_ROOT_DECK");
        create.put("payload", Map.of("id", viaSync, "name", "Root", "schedulerType", "sm2"));
        Map<String, Object> rename = new LinkedHashMap<>();
        rename.put("opId", UUID.randomUUID());
        rename.put("kind", "command");
        rename.put("type", "RENAME_DECK");
        rename.put("payload", Map.of("deckId", viaSync, "name", "Same"));
        mockMvc.perform(json(post("/api/v1/sync/push"),
                        Map.of("deviceId", UUID.randomUUID(), "operations", List.of(create, rename))))
                .andExpect(status().isOk());

        Deck rest = deckMapper.findDeckById(viaRest);
        Deck sync = deckMapper.findDeckById(viaSync);
        assertThat(sync.getName()).isEqualTo(rest.getName());
        assertThat(sync.getContentType()).isEqualTo(rest.getContentType());
        assertThat(sync.getSchedulerVersion()).isEqualTo(rest.getSchedulerVersion());
        assertThat(sync.getGeneration()).isEqualTo(rest.getGeneration());
        assertThat(sync.getDepth()).isEqualTo(rest.getDepth());
    }

    @Test
    void theDeviceHeaderIsRecordedAndItsAbsenceUsesTheRestDevice() throws Exception {
        UUID root = createRoot();
        assertThat(deckMapper.findDeckById(root).getLastDeviceId()).isEqualTo(new UUID(0L, 0L));

        UUID device = UUID.randomUUID();
        mockMvc.perform(json(patch("/api/v1/decks/{id}", root), Map.of("name", "N")).header("X-Device-Id", device))
                .andExpect(status().isOk());
        assertThat(deckMapper.findDeckById(root).getLastDeviceId()).isEqualTo(device);
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest=DeckControllerIT`
Expected: FAIL with 404 on `POST /api/v1/decks` (no controller yet).

- [ ] **Step 3: Implement idempotency and the REST write context**

`sync/service/IdempotencyService.java`:

```java
package com.memox.sync.service;

import java.util.UUID;

/** Runs a REST write at most once per {@code Idempotency-Key}, in the write's own transaction (API-A2 spec D7). */
public interface IdempotencyService {

    /** Runs {@code write} unless {@code key} was recorded for the user; a {@code null} key always runs it. */
    void runOnce(UUID userId, UUID key, Runnable write);
}
```

`sync/service/impl/IdempotencyServiceImpl.java`:

```java
package com.memox.sync.service.impl;

import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.IdempotencyService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class IdempotencyServiceImpl implements IdempotencyService {

    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final ChangeVersions changeVersions;

    @Override
    @Transactional
    public void runOnce(UUID userId, UUID key, Runnable write) {
        if (key == null) {
            write.run();
            return;
        }
        if (syncAppliedOpMapper.findServerVersion(userId, key) != null) {
            return;
        }
        write.run();
        syncAppliedOpMapper.insert(userId, key, changeVersions.latest(userId));
    }
}
```

Add `DEVICE_HEADER`, `IDEMPOTENCY_HEADER` and `rest(...)` to `WriteContext` (the full record is in Task 1, Step 4, which already shows them; add them now if Task 1 was built without them).

The write takes the user lock itself, so a concurrent replay with the same key waits for the lock inside `write.run()`. It could still pass the `findServerVersion` check before the first request commits. The second insert then hits `sync_applied_op`'s primary key and the request fails with a `409 CONFLICT` from `GlobalExceptionHandler`, and nothing is written twice. That is acceptable for a retry.

- [ ] **Step 4: Add `DeckResponse` and `getDeck`**

`deck/dto/response/DeckResponse.java`:

```java
package com.memox.deck.dto.response;

import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A deck as REST clients see it; {@code rootId}, {@code depth} and {@code contentType} are the server's. */
@Builder
public record DeckResponse(
        UUID id,
        UUID parentId,
        UUID rootId,
        int depth,
        String name,
        String contentType,
        String schedulerType,
        Integer schedulerVersion,
        Integer generation,
        String studyConfig,
        int siblingPosition,
        Instant createdAt,
        Instant updatedAt) {}
```

Add to `DeckService`:

```java
    /** The user's active deck. */
    DeckResponse getDeck(UUID userId, UUID deckId);
```

Add to `DeckServiceImpl`:

```java
    @Override
    @Transactional(readOnly = true)
    public DeckResponse getDeck(UUID userId, UUID deckId) {
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null
                || !deck.getUserId().equals(userId)
                || deck.getDeletedAt() != null
                || deck.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_NOT_FOUND);
        }
        return toResponse(deck);
    }

    static DeckResponse toResponse(Deck deck) {
        return DeckResponse.builder()
                .id(deck.getId())
                .parentId(deck.getParentId())
                .rootId(deck.getRootId())
                .depth(deck.getDepth())
                .name(deck.getName())
                .contentType(deck.getContentType())
                .schedulerType(deck.getSchedulerType())
                .schedulerVersion(deck.getSchedulerVersion())
                .generation(deck.getGeneration())
                .studyConfig(deck.getStudyConfig())
                .siblingPosition(deck.getSiblingPosition())
                .createdAt(deck.getCreatedAt())
                .updatedAt(deck.getUpdatedAt())
                .build();
    }
```

- [ ] **Step 5: Implement `DeckController` (write routes)**

```java
package com.memox.deck.controller;

import com.memox.common.security.CurrentUserProvider;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.DeleteDeckRequest;
import com.memox.deck.dto.request.MoveDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.ReorderDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.dto.response.DeckResponse;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Deck routes (API-A2 spec §6); each calls the service method its sync command calls. */
@RestController
@RequestMapping("/api/v1/decks")
@RequiredArgsConstructor
public class DeckController {

    private final DeckService deckService;
    private final IdempotencyService idempotencyService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DeckResponse createRoot(
            @Valid @RequestBody CreateRootDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.createRootDeck(context, request));
        return deckService.getDeck(context.userId(), request.id());
    }

    @PostMapping("/{id}/sub-decks")
    @ResponseStatus(HttpStatus.CREATED)
    public DeckResponse createSub(
            @PathVariable UUID id,
            @Valid @RequestBody CreateSubDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.createSubDeck(context, id, request));
        return deckService.getDeck(context.userId(), request.id());
    }

    @PatchMapping("/{id}")
    public DeckResponse rename(
            @PathVariable UUID id,
            @Valid @RequestBody RenameDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.renameDeck(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @PostMapping("/{id}/move")
    public DeckResponse move(
            @PathVariable UUID id,
            @Valid @RequestBody MoveDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.moveDeck(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @PostMapping("/{id}/reorder")
    public DeckResponse reorder(
            @PathVariable UUID id,
            @Valid @RequestBody ReorderDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.reorderDeck(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @PutMapping("/{id}/study-options")
    public DeckResponse studyOptions(
            @PathVariable UUID id,
            @Valid @RequestBody StudyOptionsRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.updateStudyOptions(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @PathVariable UUID id,
            @Valid @RequestBody DeleteDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.deleteDeck(context, id, request));
    }
}
```

- [ ] **Step 6: Run the tests**

Run: `./mvnw -B test -Dtest=DeckControllerIT`
Expected: PASS.

- [ ] **Step 7: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): deck REST write routes, Idempotency-Key and X-Device-Id (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Card and undo routes

**Files:**
- Create: `main/java/com/memox/card/dto/response/CardResponse.java`, `main/java/com/memox/card/controller/CardController.java`
- Create: `main/java/com/memox/trash/service/TrashService.java`, `main/java/com/memox/trash/service/impl/TrashServiceImpl.java`, `main/java/com/memox/trash/controller/TrashController.java`
- Modify: `CardService.java` and `CardServiceImpl.java` (add `getCard`)
- Test: `test/java/com/memox/card/controller/CardControllerIT.java`

**Interfaces:**
- Consumes: `CardService` (Tasks 7–8), `DeckService.undoDeckDeletion`, `IdempotencyService`, `WriteContext.rest` (Task 9).
- Produces:
  - `CardService.getCard(UUID userId, UUID cardId)` → `CardResponse`;
  - `TrashService.undo(WriteContext, UUID batchId)`, which dispatches by the batch's `item_type`.

- [ ] **Step 1: Write the failing REST tests**

```java
package com.memox.card.controller;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class CardControllerIT {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockitoBean
    CurrentUserProvider currentUserProvider;

    UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, Object body) throws Exception {
        return request.contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(body));
    }

    UUID deck(UUID parent) throws Exception {
        UUID id = UUID.randomUUID();
        if (parent == null) {
            mockMvc.perform(json(post("/api/v1/decks"), Map.of("id", id, "name", "Root", "schedulerType", "sm2")))
                    .andExpect(status().isCreated());
        } else {
            mockMvc.perform(json(post("/api/v1/decks/{id}/sub-decks", parent), Map.of("id", id, "name", "Sub")))
                    .andExpect(status().isCreated());
        }
        return id;
    }

    UUID card(UUID deckId) throws Exception {
        UUID id = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/decks/{id}/cards", deckId), Map.of("id", id, "front", "犬", "back", "dog")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.deckId").value(deckId.toString()));
        return id;
    }

    @Test
    void cardRoutesEditMoveDeleteAndUndo() throws Exception {
        UUID root = deck(null);
        UUID from = deck(root);
        UUID to = deck(root);
        UUID id = card(from);

        mockMvc.perform(json(patch("/api/v1/cards/{id}", id), Map.of("front", "猫", "back", "cat")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.front").value("猫"));
        mockMvc.perform(json(put("/api/v1/cards/{id}/flag", id), Map.of("isFlagged", true)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isFlagged").value(true));
        mockMvc.perform(json(post("/api/v1/cards/move"), Map.of("cardIds", List.of(id), "targetDeckId", to)))
                .andExpect(status().isNoContent());

        UUID batch = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/cards/delete"),
                        Map.of("items", List.of(Map.of("cardId", id, "batchId", batch)),
                                "deletedAt", "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());
        mockMvc.perform(post("/api/v1/trash/batches/{id}/undo", batch)).andExpect(status().isNoContent());
        mockMvc.perform(post("/api/v1/trash/batches/{id}/undo", batch))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BATCH_NOT_FOUND"));
    }

    @Test
    void undoOfADeckBatchGoesThroughTheSameRoute() throws Exception {
        UUID root = deck(null);
        UUID sub = deck(root);
        card(sub);
        UUID batch = UUID.randomUUID();
        mockMvc.perform(json(delete("/api/v1/decks/{id}", sub),
                        Map.of("batchId", batch, "deletedAt", "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());

        mockMvc.perform(post("/api/v1/trash/batches/{id}/undo", batch)).andExpect(status().isNoContent());
    }

    @Test
    void aCardOnARootIsAConflict() throws Exception {
        UUID root = deck(null);
        mockMvc.perform(json(post("/api/v1/decks/{id}/cards", root),
                        Map.of("id", UUID.randomUUID(), "front", "a", "back", "b")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DECK_CONTENT_TYPE_MISMATCH"));
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest=CardControllerIT`
Expected: FAIL with 404 on `POST /api/v1/decks/{id}/cards`.

- [ ] **Step 3: Add `CardResponse` and `getCard`**

```java
package com.memox.card.dto.response;

import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A card as REST clients see it. */
@Builder
public record CardResponse(
        UUID id,
        UUID deckId,
        String front,
        String back,
        String example,
        String hint,
        String pronunciation,
        boolean isFlagged,
        Instant createdAt,
        Instant updatedAt) {}
```

Add to `CardService`: `CardResponse getCard(UUID userId, UUID cardId);`. Add to `CardServiceImpl`:

```java
    @Override
    @Transactional(readOnly = true)
    public CardResponse getCard(UUID userId, UUID cardId) {
        Card card = cardMapper.findCardById(cardId);
        if (card == null
                || !card.getUserId().equals(userId)
                || card.getDeletedAt() != null
                || card.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.CARD_NOT_FOUND);
        }
        return toResponse(card);
    }

    static CardResponse toResponse(Card card) {
        return CardResponse.builder()
                .id(card.getId())
                .deckId(card.getDeckId())
                .front(card.getFront())
                .back(card.getBack())
                .example(card.getExample())
                .hint(card.getHint())
                .pronunciation(card.getPronunciation())
                .isFlagged(card.isFlagged())
                .createdAt(card.getCreatedAt())
                .updatedAt(card.getUpdatedAt())
                .build();
    }
```

- [ ] **Step 4: Add the undo dispatcher**

`trash/service/TrashService.java`:

```java
package com.memox.trash.service;

import com.memox.sync.service.WriteContext;
import java.util.UUID;

/** Trash operations reached by batch id. */
public interface TrashService {

    /** Undoes a deck or a card batch, by the batch's item type (BR-TRASH-008). */
    void undo(WriteContext context, UUID batchId);
}
```

`trash/service/impl/TrashServiceImpl.java`:

```java
package com.memox.trash.service.impl;

import com.memox.card.service.CardService;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import com.memox.trash.mapper.DeleteBatchMapper;
import com.memox.trash.model.DeleteBatch;
import com.memox.trash.service.TrashService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TrashServiceImpl implements TrashService {

    private static final String DECK = "deck";

    private final DeleteBatchMapper deleteBatchMapper;
    private final DeckService deckService;
    private final CardService cardService;

    @Override
    @Transactional
    public void undo(WriteContext context, UUID batchId) {
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(batchId);
        if (batch == null || !batch.getUserId().equals(context.userId())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        if (DECK.equals(batch.getItemType())) {
            deckService.undoDeckDeletion(context, batchId);
            return;
        }
        cardService.undoCardDeletion(context, batchId);
    }
}
```

- [ ] **Step 5: Add the controllers**

`card/controller/CardController.java`:

```java
package com.memox.card.controller;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.dto.request.DeleteCardsRequest;
import com.memox.card.dto.request.MoveCardsRequest;
import com.memox.card.dto.response.CardResponse;
import com.memox.card.service.CardService;
import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Card routes (API-A2 spec §6); each calls the service method its sync command calls. */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class CardController {

    private final CardService cardService;
    private final IdempotencyService idempotencyService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/decks/{deckId}/cards")
    @ResponseStatus(HttpStatus.CREATED)
    public CardResponse create(
            @PathVariable UUID deckId,
            @Valid @RequestBody CreateCardRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.createCard(context, deckId, request));
        return cardService.getCard(context.userId(), request.id());
    }

    @PatchMapping("/cards/{id}")
    public CardResponse updateContent(
            @PathVariable UUID id,
            @Valid @RequestBody CardContentRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.updateContent(context, id, request));
        return cardService.getCard(context.userId(), id);
    }

    @PutMapping("/cards/{id}/flag")
    public CardResponse updateFlag(
            @PathVariable UUID id,
            @Valid @RequestBody CardFlagRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.updateFlag(context, id, request));
        return cardService.getCard(context.userId(), id);
    }

    @PostMapping("/cards/move")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void move(
            @Valid @RequestBody MoveCardsRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.moveCards(context, request));
    }

    @PostMapping("/cards/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @Valid @RequestBody DeleteCardsRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.deleteCards(context, request));
    }
}
```

The spec's table says "other writes return 200 with the changed resource". `MOVE_CARDS` changes several cards, so there is no single resource to return, and `204` is used. Record this ruling in Task 11, Step 5.

`trash/controller/TrashController.java`:

```java
package com.memox.trash.controller;

import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import com.memox.trash.service.TrashService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Trash routes: undo a batch (BR-TRASH-008). Restore and purge are API-B3. */
@RestController
@RequestMapping("/api/v1/trash")
@RequiredArgsConstructor
public class TrashController {

    private final TrashService trashService;
    private final IdempotencyService idempotencyService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/batches/{batchId}/undo")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void undo(
            @PathVariable UUID batchId,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> trashService.undo(context, batchId));
    }
}
```

- [ ] **Step 6: Run the tests**

Run: `./mvnw -B test -Dtest='CardControllerIT,DeckControllerIT'`
Expected: PASS.

- [ ] **Step 7: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src
git commit -m "feat(api): card and Trash undo REST routes (API-A2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: The four reads, docs, WBS; phase 3 gate

**Files:**
- Create: `main/java/com/memox/deck/enums/DeckSortField.java`, `main/java/com/memox/deck/dto/request/DeckListQuery.java`, `main/java/com/memox/card/enums/CardSortField.java`, `main/java/com/memox/card/dto/request/CardListQuery.java`
- Modify: `DeckService`/`DeckServiceImpl` (`listDecks`), `CardService`/`CardServiceImpl` (`listCards`), `DeckMapper` + XML, `CardMapper` + XML, `DeckController`, `CardController`
- Test: `DeckControllerIT.java`, `CardControllerIT.java` (append)
- Modify: the API-A2 spec (§10 rulings), `memox-api-services/README.md`, `docs/wbs_API.md`

**Interfaces:**
- Produces:
  - `DeckService.listDecks(UUID userId, DeckListQuery)` → `PagingResponse<DeckResponse>`;
  - `CardService.listCards(UUID userId, UUID deckId, CardListQuery)` → `PagingResponse<CardResponse>`;
  - `GET /api/v1/decks?parentId=&page=&size=`, `GET /api/v1/decks/{id}`, `GET /api/v1/decks/{id}/cards?page=&size=` and `GET /api/v1/cards/{id}`.

- [ ] **Step 1: Append the failing read tests**

To `DeckControllerIT`, adding the import `static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get`:

```java
    @Test
    void readsListALevelInOrderAndHideTrash() throws Exception {
        UUID root = createRoot();
        UUID a = createSub(root);
        UUID b = createSub(root);
        mockMvc.perform(json(delete("/api/v1/decks/{id}", b),
                        Map.of("batchId", UUID.randomUUID(), "deletedAt", "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/decks").param("parentId", root.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].id").value(a.toString()))
                .andExpect(jsonPath("$.totalItems").value(1));
        mockMvc.perform(get("/api/v1/decks"))
                .andExpect(jsonPath("$.items[0].id").value(root.toString()));
        mockMvc.perform(get("/api/v1/decks/{id}", a)).andExpect(jsonPath("$.name").value("Sub"));
        mockMvc.perform(get("/api/v1/decks/{id}", b)).andExpect(status().isNotFound());
        user = UUID.randomUUID();
        mockMvc.perform(get("/api/v1/decks/{id}", a)).andExpect(status().isNotFound());
    }
```

To `CardControllerIT`, adding the import `static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get`:

```java
    @Test
    void readsPageADecksActiveCards() throws Exception {
        UUID sub = deck(deck(null));
        UUID first = card(sub);
        card(sub);
        card(sub);

        mockMvc.perform(get("/api/v1/decks/{id}/cards", sub).param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.totalItems").value(3))
                .andExpect(jsonPath("$.hasNext").value(true));
        mockMvc.perform(get("/api/v1/cards/{id}", first)).andExpect(jsonPath("$.back").value("dog"));
        mockMvc.perform(get("/api/v1/cards/{id}", UUID.randomUUID())).andExpect(status().isNotFound());
    }
```

- [ ] **Step 2: Run to verify failure**

Run: `./mvnw -B test -Dtest='DeckControllerIT,CardControllerIT'`
Expected: FAIL, because the GET routes return `405` (method not allowed on the POST mapping).

- [ ] **Step 3: Add the queries and sort enums**

`deck/enums/DeckSortField.java`:

```java
package com.memox.deck.enums;

/** Deck lists have one order: manual position, then id (BR-SRS-007). */
public enum DeckSortField {
    POSITION
}
```

`deck/dto/request/DeckListQuery.java`:

```java
package com.memox.deck.dto.request;

import com.memox.common.PageQuery;
import com.memox.deck.enums.DeckSortField;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** {@code GET /api/v1/decks}: a level's active decks; no {@code parentId} lists the roots. */
@Getter
@Setter
public class DeckListQuery extends PageQuery<DeckSortField> {
    private UUID parentId;
}
```

`card/enums/CardSortField.java`:

```java
package com.memox.card.enums;

/** Card lists have one order here: creation time, then id. Richer sorts come with API-B7. */
public enum CardSortField {
    CREATED
}
```

`card/dto/request/CardListQuery.java`:

```java
package com.memox.card.dto.request;

import com.memox.card.enums.CardSortField;
import com.memox.common.PageQuery;

/** {@code GET /api/v1/decks/{id}/cards}: the deck's active cards. */
public class CardListQuery extends PageQuery<CardSortField> {}
```

- [ ] **Step 4: Add the mapper statements, service methods and routes**

`DeckMapper.java`:

```java
    List<Deck> findActivePage(
            @Param("userId") UUID userId,
            @Param("parentId") UUID parentId,
            @Param("limit") int limit,
            @Param("offset") long offset);

    long countActive(@Param("userId") UUID userId, @Param("parentId") UUID parentId);
```

`DeckMapper.xml`:

```xml
    <select id="findActivePage" resultType="com.memox.deck.model.Deck">
        SELECT <include refid="deckColumns"/> FROM deck
        WHERE user_id = #{userId} AND <include refid="sameParent"/>
          AND deleted_at IS NULL AND delete_batch_id IS NULL
        ORDER BY sibling_position, id
        LIMIT #{limit} OFFSET #{offset}
    </select>
    <select id="countActive" resultType="long">
        SELECT count(*) FROM deck
        WHERE user_id = #{userId} AND <include refid="sameParent"/>
          AND deleted_at IS NULL AND delete_batch_id IS NULL
    </select>
```

`CardMapper.java`:

```java
    List<Card> findActivePage(
            @Param("userId") UUID userId,
            @Param("deckId") UUID deckId,
            @Param("limit") int limit,
            @Param("offset") long offset);

    long countActive(@Param("userId") UUID userId, @Param("deckId") UUID deckId);
```

`CardMapper.xml`:

```xml
    <select id="findActivePage" resultType="com.memox.card.model.Card">
        SELECT <include refid="cardColumns"/> FROM card
        WHERE user_id = #{userId} AND deck_id = #{deckId} AND deleted_at IS NULL AND delete_batch_id IS NULL
        ORDER BY created_at, id
        LIMIT #{limit} OFFSET #{offset}
    </select>
    <select id="countActive" resultType="long">
        SELECT count(*) FROM card
        WHERE user_id = #{userId} AND deck_id = #{deckId} AND deleted_at IS NULL AND delete_batch_id IS NULL
    </select>
```

`DeckService` gains `PagingResponse<DeckResponse> listDecks(UUID userId, DeckListQuery query);`. The implementation in `DeckServiceImpl`:

```java
    @Override
    @Transactional(readOnly = true)
    public PagingResponse<DeckResponse> listDecks(UUID userId, DeckListQuery query) {
        List<DeckResponse> items = deckMapper
                .findActivePage(userId, query.getParentId(), query.getSize(), query.offset())
                .stream()
                .map(DeckServiceImpl::toResponse)
                .toList();
        return PagingResponse.of(items, query, deckMapper.countActive(userId, query.getParentId()));
    }
```

`CardService` gains `PagingResponse<CardResponse> listCards(UUID userId, UUID deckId, CardListQuery query);`. The implementation in `CardServiceImpl`:

```java
    @Override
    @Transactional(readOnly = true)
    public PagingResponse<CardResponse> listCards(UUID userId, UUID deckId, CardListQuery query) {
        List<CardResponse> items = cardMapper.findActivePage(userId, deckId, query.getSize(), query.offset()).stream()
                .map(CardServiceImpl::toResponse)
                .toList();
        return PagingResponse.of(items, query, cardMapper.countActive(userId, deckId));
    }
```

Add to `DeckController`, importing `DeckListQuery`, `com.memox.common.PagingResponse` and `org.springframework.web.bind.annotation.GetMapping`:

```java
    @GetMapping
    public PagingResponse<DeckResponse> list(@Valid DeckListQuery query) {
        return deckService.listDecks(currentUserProvider.currentUserId(), query);
    }

    @GetMapping("/{id}")
    public DeckResponse get(@PathVariable UUID id) {
        return deckService.getDeck(currentUserProvider.currentUserId(), id);
    }
```

Add to `CardController`, importing `CardListQuery`, `PagingResponse` and `GetMapping`:

```java
    @GetMapping("/decks/{deckId}/cards")
    public PagingResponse<CardResponse> list(@PathVariable UUID deckId, @Valid CardListQuery query) {
        return cardService.listCards(currentUserProvider.currentUserId(), deckId, query);
    }

    @GetMapping("/cards/{id}")
    public CardResponse get(@PathVariable UUID id) {
        return cardService.getCard(currentUserProvider.currentUserId(), id);
    }
```

- [ ] **Step 5: Docs and WBS**

1. Append to §10 of the API-A2 spec:

   ```markdown
   - `POST /api/v1/cards/move` answers `204`: it changes several cards, so there
     is no single resource to return.
   - Deck lists order by `sibling_position, id`, and card lists by
     `created_at, id`; their sort enums have that one constant until API-B7.
   ```

2. In `memox-api-services/README.md`, add after the Sync bullet:

   ```markdown
   - **REST (ADR-014):** `/api/v1/decks`, `/api/v1/decks/{id}/cards`,
     `/api/v1/cards` and `/api/v1/trash/batches/{id}/undo` call the same service
     methods as the sync commands. Writes take an optional `X-Device-Id` and an
     optional `Idempotency-Key` (a UUID; a replay writes nothing and returns the
     current state).
   ```

3. In `docs/wbs_API.md`, set API-A2 to `xong` once merged, with the PR link in Bằng chứng and `—` in Việc tiếp theo. Add an update line under "Ngữ cảnh cập nhật". This step runs in the commit that merges the last phase.

- [ ] **Step 6: Run the phase gate**

Run: `./mvnw -B verify`
Expected: BUILD SUCCESS, with coverage ≥ 80%. Also run `python tools/docs/check.py` from the repo root. Expected: 0 errors.

- [ ] **Step 7: Format and commit**

```bash
./mvnw -B spotless:apply
git add -A src README.md ../docs
git commit -m "feat(api): basic deck and card reads; docs and WBS (API-A2 phase 3)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
