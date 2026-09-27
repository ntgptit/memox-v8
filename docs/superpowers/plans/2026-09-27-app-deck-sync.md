# App Deck Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sync `deck` and `delete_batches` between the Flutter app's Drift database and `memox-api-services`, with no change to use cases, presentation or repositories.

**Architecture:**
- **Capture:** SQLite triggers on the two synced tables fill `sync_outbox` in the writer's own transaction.
- **Network:** a Retrofit `SyncApi` on one shared Dio.
- **Run:** a `SyncCoordinator` pushes the outbox, then pulls changes. Per-table `EntitySyncAdapter`s convert rows. Every write that applies server data happens under `sync_state.applying_remote`, which the triggers skip.
- **Scheduling:** a `SyncScheduler` runs the coordinator at start, after outbox changes (debounced), when connectivity returns, and on backoff, but only when `API_BASE_URL` is defined.
- **Server:** gains a `delete_batch` handler and the local deck CHECKs.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Riverpod 3 (`riverpod_annotation` 4), dio 5.11.1, retrofit 4.10.0 and retrofit_generator 10.2.11, json_serializable 6.14.1, connectivity_plus 7.3.1, fake_async; server Spring Boot 3.5 + MyBatis.

**Spec:** `docs/superpowers/specs/2026-09-27-app-deck-sync-design.md` (parent: `2026-09-27-server-sync-design.md`, ADR-013, ADR-012).

## Global Constraints

- **Gates:**
  - app: `flutter analyze`, `dart format --set-exit-if-changed lib test`, and `flutter test --exclude-tags golden` (on Windows; never `--update-goldens`), then `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`;
  - server: `./mvnw -B verify` in `memox-api-services/`.
- **Generated code** is not committed (`*.g.dart`). Regenerate with `dart run build_runner build --delete-conflicting-outputs`.
- **Drift schema v4.** After changing tables, run, in this order:
  - `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
  - `dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart`
  - `dart run drift_dev schema generate drift_schemas/ test/drift/generated/`
- **Import boundary:** `lib/core/**` never imports `lib/features/**`.
- **Wire format** (server spec §4):
  - entity types `deck` and `delete_batch`;
  - rows use camelCase keys, UUID strings and ISO-8601 UTC times;
  - push batch at most 100 operations; changes page 500.
- **Outbox rules:** keyed `UNIQUE(entity_type, entity_id)`; every trigger write sets a new random-UUID `op_id` and keeps `created_at`; push order is `created_at, rowid`.
- **Triggers** are skipped when `sync_state` has the key `applying_remote`.
- **Sync switch:** enabled only when `String.fromEnvironment('API_BASE_URL')` is non-empty.
- **Scheduling:** debounce 2 s; backoff from 5 s, doubling, capped at 5 min.
- **Dio timeouts:** connect 10 s, receive 20 s, send 20 s; header `X-Request-ID`.
- **Style:** no `print(` in `lib/` (use `dart:developer` `log`); no empty `catch`.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- A person edits a deck while a push of its earlier state is in flight. The acknowledgement must not drop the newer edit: its outbox entry survives and is pushed next. The test is in Task 5.
- The server rejects an operation after the person edited the row again. The server's `current` must not overwrite the newer local edit. The test is in Task 5.
- A new device pulls a child deck whose parent arrives later in the same page. The page must apply without a foreign-key failure. The test is in Task 5.
- A deck moved on the server rewrites its whole subtree. The pulled rows must not echo back into the outbox. The test is in Task 5.
- A server row the local CHECKs would refuse would jam every pull forever, so the server must refuse it at push time. The test is in Task 1.

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `memox-api-services/src/main/resources/db/migration/V3__delete_batch_and_deck_checks.sql` | 1 | `delete_batch` table; local deck CHECKs on the server |
| `memox-api-services/src/main/java/com/memox/trash/{dto/DeleteBatchSyncRow,model/DeleteBatch,mapper/DeleteBatchSyncMapper,service/impl/DeleteBatchSyncHandler}.java` + XML | 1 | delete_batch sync |
| `memox-api-services/src/test/java/com/memox/trash/service/impl/DeleteBatchSyncHandlerIT.java` | 1 | tests |
| `lib/core/database/tables/sync.drift`, `deck.drift`, `trash.drift`, `app_database.dart`, `schema_versions.dart`, `drift_schemas/drift_schema_v4.json`, `test/drift/generated/*` | 2 | schema v4, triggers, migration |
| `test/drift/migration_test.dart`, `test/core/sync/sync_triggers_test.dart` | 2 | tests |
| `docs/shared/data/schema.md` | 2 | document sync tables |
| `pubspec.yaml`, `lib/core/network/{api_config,request_id_interceptor}.dart`, `lib/core/network/di/network_providers.dart` | 3 | network |
| `lib/core/sync/{sync_api,sync_models}.dart` | 3 | Retrofit API and DTOs |
| `test/core/network/request_id_interceptor_test.dart`, `test/core/sync/sync_models_test.dart` | 3 | tests |
| `lib/core/sync/{entity_sync_adapter,deck_sync_adapter,delete_batch_sync_adapter,sync_store}.dart` | 4 | adapters and outbox/state access |
| `test/core/sync/{deck_sync_adapter_test,sync_store_test}.dart` | 4 | tests |
| `lib/core/sync/{sync_coordinator,sync_scheduler}.dart`, `lib/core/sync/di/sync_providers.dart`, `lib/main.dart` | 5 | run loop, scheduling, wiring |
| `test/core/sync/{sync_coordinator_test,sync_scheduler_test,fake_sync_server}.dart` | 5 | tests |

---

### Task 1: Server — delete_batch sync and local deck CHECKs

**Files:** see the file map for Task 1. In `memox-api-services/`, paths are relative to it.

**Interfaces:**
- Consumes: `SyncEntityHandler`, `SyncChange`, `SyncVersionMapper` (#110).
- Produces:
  - entity type `delete_batch` with row `{id, itemType, rootItemId, deletedAt}`;
  - server `deck` refuses rows that break local CHECKs, as `VALIDATION_FAILED` at push time.

- [ ] **Step 1: Write the failing tests**

`src/test/java/com/memox/trash/service/impl/DeleteBatchSyncHandlerIT.java`:

```java
package com.memox.trash.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.service.impl.DeckSyncHandler;
import com.memox.sync.dto.response.SyncChange;
import com.memox.trash.dto.DeleteBatchSyncRow;
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
class DeleteBatchSyncHandlerIT {

    private static final Instant T = Instant.parse("2026-09-27T01:00:00Z");
    private static final UUID DEVICE = UUID.randomUUID();

    @Autowired
    private DeleteBatchSyncHandler handler;

    @Autowired
    private DeckSyncHandler deckHandler;

    @Autowired
    private ObjectMapper objectMapper;

    private final UUID user = UUID.randomUUID();

    @Test
    void storesAndReturnsABatch() {
        UUID id = UUID.randomUUID();
        UUID root = UUID.randomUUID();

        long version = handler.upsert(user, DEVICE, id, objectMapper.valueToTree(new DeleteBatchSyncRow(id, "deck", root, T)));

        SyncChange current = handler.current(user, id);
        assertThat(current.serverVersion()).isEqualTo(version);
        assertThat(((DeleteBatchSyncRow) current.row()).deletedAt()).isEqualTo(T);
        assertThat(handler.changesSince(user, version - 1, 10)).extracting(SyncChange::entityId).containsExactly(id);
    }

    @Test
    void deleteTombstonesTheBatchAndIsIdempotent() {
        UUID id = UUID.randomUUID();
        handler.upsert(user, DEVICE, id, objectMapper.valueToTree(new DeleteBatchSyncRow(id, "card", UUID.randomUUID(), T)));

        long first = handler.delete(user, DEVICE, id);

        assertThat(handler.current(user, id).deleted()).isTrue();
        assertThat(handler.delete(user, DEVICE, id)).isEqualTo(first);
    }

    @Test
    void rejectsAnotherUsersBatchAndABadItemType() {
        UUID id = UUID.randomUUID();
        handler.upsert(user, DEVICE, id, objectMapper.valueToTree(new DeleteBatchSyncRow(id, "deck", UUID.randomUUID(), T)));

        assertThatThrownBy(() -> handler.upsert(UUID.randomUUID(), DEVICE, id,
                        objectMapper.valueToTree(new DeleteBatchSyncRow(id, "deck", UUID.randomUUID(), T))))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.SYNC_ENTITY_CONFLICT);
        UUID other = UUID.randomUUID();
        assertThatThrownBy(() -> handler.upsert(user, DEVICE, other,
                        objectMapper.valueToTree(new DeleteBatchSyncRow(other, "tag", UUID.randomUUID(), T))))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.VALIDATION_FAILED);
    }

    @Test
    void refusesADeckRowTheLocalChecksWouldRefuse() {
        UUID root = UUID.randomUUID();
        // A root without generation and scheduler_version breaks the app's CHECKs (deck.drift).
        DeckSyncRow bad = new DeckSyncRow(root, "R", null, null, null, "deck", "sm2", null, null, null, null, null,
                null, null, null, 0, T, T);

        assertThatThrownBy(() -> deckHandler.upsert(user, DEVICE, root, objectMapper.valueToTree(bad)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.VALIDATION_FAILED);
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run (in `memox-api-services/`): `./mvnw -B test -Dtest=DeleteBatchSyncHandlerIT`
Expected: COMPILATION ERROR, `cannot find symbol: class DeleteBatchSyncHandler`.

- [ ] **Step 3: Implement**

`src/main/resources/db/migration/V3__delete_batch_and_deck_checks.sql`:

```sql
-- App deck-sync spec §6. A trash batch; tombstoned_at is the sync tombstone, deleted_at the batch's own time.
CREATE TABLE delete_batch (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    item_type text NOT NULL CHECK (item_type IN ('card', 'deck')),
    root_item_id uuid NOT NULL,
    deleted_at timestamptz NOT NULL,
    server_version bigint NOT NULL,
    last_device_id uuid NOT NULL,
    tombstoned_at timestamptz NULL
);
CREATE UNIQUE INDEX uq_delete_batch_user_version ON delete_batch (user_id, server_version);

-- The app's deck CHECKs (deck.drift): a row the app would refuse must be refused here, or it jams every pull.
ALTER TABLE deck ADD CONSTRAINT deck_root_generation CHECK ((parent_id IS NULL) = (generation IS NOT NULL));
ALTER TABLE deck ADD CONSTRAINT deck_root_scheduler_version CHECK ((parent_id IS NULL) = (scheduler_version IS NOT NULL));
ALTER TABLE deck ADD CONSTRAINT deck_child_configs CHECK (parent_id IS NULL OR (scheduler_config IS NULL AND study_config IS NULL));
```

In `com/memox/deck/service/impl/DeckSyncHandler.java`, in `parse`, replace the `rootShape` computation with:

```java
            boolean rootShape = row.parentId() == null
                    ? "deck".equals(row.contentType())
                            && row.schedulerType() != null
                            && row.schedulerVersion() != null
                            && row.generation() != null
                    : row.schedulerType() == null
                            && row.schedulerVersion() == null
                            && row.generation() == null
                            && row.schedulerConfig() == null
                            && row.studyConfig() == null;
```

`src/main/java/com/memox/trash/dto/DeleteBatchSyncRow.java`:

```java
package com.memox.trash.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.UUID;

/** A trash batch on the sync wire, mirroring Drift's {@code delete_batches}. */
public record DeleteBatchSyncRow(
        @NotNull UUID id,
        @NotNull @Pattern(regexp = "card|deck") String itemType,
        @NotNull UUID rootItemId,
        @NotNull Instant deletedAt) {}
```

`src/main/java/com/memox/trash/dto/package-info.java`:

```java
/**
 * Trash rows on the sync wire (DeleteBatchSyncRow).
 */
package com.memox.trash.dto;
```

`src/main/java/com/memox/trash/model/DeleteBatch.java`:

```java
package com.memox.trash.model;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** A server {@code delete_batch} row. */
@Getter
@Setter
public class DeleteBatch {

    private UUID id;
    private UUID userId;
    private String itemType;
    private UUID rootItemId;
    private Instant deletedAt;
    private Long serverVersion;
    private UUID lastDeviceId;
    private Instant tombstonedAt;
}
```

`src/main/java/com/memox/trash/mapper/DeleteBatchSyncMapper.java`:

```java
package com.memox.trash.mapper;

import com.memox.trash.model.DeleteBatch;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DeleteBatchSyncMapper {

    DeleteBatch findDeleteBatchById(@Param("id") UUID id);

    void upsertDeleteBatch(DeleteBatch batch);

    void tombstoneDeleteBatch(
            @Param("id") UUID id, @Param("serverVersion") long serverVersion, @Param("deviceId") UUID deviceId);

    List<DeleteBatch> findChangesSince(
            @Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);
}
```

`src/main/resources/mapper/trash/DeleteBatchSyncMapper.xml`:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.memox.trash.mapper.DeleteBatchSyncMapper">

    <sql id="columns">
        id, user_id, item_type, root_item_id, deleted_at, server_version, last_device_id, tombstoned_at
    </sql>

    <select id="findDeleteBatchById" resultType="com.memox.trash.model.DeleteBatch">
        SELECT <include refid="columns"/> FROM delete_batch WHERE id = #{id}
    </select>

    <insert id="upsertDeleteBatch">
        INSERT INTO delete_batch (<include refid="columns"/>)
        VALUES (#{id}, #{userId}, #{itemType}, #{rootItemId}, #{deletedAt}, #{serverVersion}, #{lastDeviceId}, NULL)
        ON CONFLICT (id) DO UPDATE SET
            item_type = EXCLUDED.item_type, root_item_id = EXCLUDED.root_item_id,
            deleted_at = EXCLUDED.deleted_at, server_version = EXCLUDED.server_version,
            last_device_id = EXCLUDED.last_device_id, tombstoned_at = NULL
    </insert>

    <update id="tombstoneDeleteBatch">
        UPDATE delete_batch
        SET tombstoned_at = now(), server_version = #{serverVersion}, last_device_id = #{deviceId}
        WHERE id = #{id}
    </update>

    <select id="findChangesSince" resultType="com.memox.trash.model.DeleteBatch">
        SELECT <include refid="columns"/> FROM delete_batch
        WHERE user_id = #{userId} AND server_version &gt; #{since}
        ORDER BY server_version
        LIMIT #{limit}
    </select>
</mapper>
```

`src/main/java/com/memox/trash/service/impl/DeleteBatchSyncHandler.java`:

```java
package com.memox.trash.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncVersionMapper;
import com.memox.sync.service.SyncEntityHandler;
import com.memox.trash.dto.DeleteBatchSyncRow;
import com.memox.trash.mapper.DeleteBatchSyncMapper;
import com.memox.trash.model.DeleteBatch;
import jakarta.validation.Validator;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Syncs trash batches: whole-row upsert, tombstone on delete, no tree rules (app deck-sync spec §6). */
@Component
@RequiredArgsConstructor
public class DeleteBatchSyncHandler implements SyncEntityHandler {

    public static final String ENTITY_TYPE = "delete_batch";

    private final DeleteBatchSyncMapper deleteBatchSyncMapper;
    private final SyncVersionMapper syncVersionMapper;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode rowJson) {
        DeleteBatchSyncRow row = parse(rowJson, entityId);
        ownedOrNull(userId, entityId);
        long version = syncVersionMapper.allocate(userId, 1);
        DeleteBatch batch = new DeleteBatch();
        batch.setId(row.id());
        batch.setUserId(userId);
        batch.setItemType(row.itemType());
        batch.setRootItemId(row.rootItemId());
        batch.setDeletedAt(row.deletedAt());
        batch.setServerVersion(version);
        batch.setLastDeviceId(deviceId);
        deleteBatchSyncMapper.upsertDeleteBatch(batch);
        return version;
    }

    @Override
    public long delete(UUID userId, UUID deviceId, UUID entityId) {
        DeleteBatch existing = ownedOrNull(userId, entityId);
        if (existing == null) {
            Long current = syncVersionMapper.current(userId);
            return current == null ? 0L : current;
        }
        if (existing.getTombstonedAt() != null) {
            return existing.getServerVersion();
        }
        long version = syncVersionMapper.allocate(userId, 1);
        deleteBatchSyncMapper.tombstoneDeleteBatch(entityId, version, deviceId);
        return version;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deleteBatchSyncMapper.findChangesSince(userId, since, limit).stream()
                .map(DeleteBatchSyncHandler::toChange)
                .toList();
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        DeleteBatch batch = deleteBatchSyncMapper.findDeleteBatchById(entityId);
        if (batch == null || !batch.getUserId().equals(userId)) {
            return null;
        }
        return toChange(batch);
    }

    private DeleteBatchSyncRow parse(JsonNode rowJson, UUID entityId) {
        try {
            DeleteBatchSyncRow row = objectMapper.treeToValue(rowJson, DeleteBatchSyncRow.class);
            if (row == null || !entityId.equals(row.id()) || !validator.validate(row).isEmpty()) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return row;
        } catch (JsonProcessingException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }

    private DeleteBatch ownedOrNull(UUID userId, UUID entityId) {
        DeleteBatch batch = deleteBatchSyncMapper.findDeleteBatchById(entityId);
        if (batch != null && !batch.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        return batch;
    }

    private static SyncChange toChange(DeleteBatch batch) {
        boolean deleted = batch.getTombstonedAt() != null;
        DeleteBatchSyncRow row = deleted
                ? null
                : new DeleteBatchSyncRow(
                        batch.getId(), batch.getItemType(), batch.getRootItemId(), batch.getDeletedAt());
        return new SyncChange(ENTITY_TYPE, batch.getId(), batch.getServerVersion(), deleted, row);
    }
}
```

Also add `package-info.java` where missing for `com.memox.trash.model`, `com.memox.trash.mapper` and `com.memox.trash.service.impl`. They already exist from the scaffold (#97); leave those files as they are.

- [ ] **Step 4: Run to verify it passes, and fix existing tests**

Run: `./mvnw -B spotless:apply && ./mvnw -B test -Dtest=DeleteBatchSyncHandlerIT`
Expected: `Tests run: 4, Failures: 0`.

The stricter root shape breaks the existing deck test fixtures that build roots without `generation`/`schedulerVersion`, or children with them. Update them:
- `DeckSyncHandlerIT.row(...)` already passes `schedulerVersion = 1` and `generation = 1` for roots, and `null` for children, so it is unaffected;
- `SyncApiIT.rootRow` must also put `"schedulerVersion", 1` and `"generation", 1`;
- in `SyncOperationApplierConcurrencyIT.upsert`, roots pass `1, … 1` already.

Then run `./mvnw -B clean verify`.
Expected: surefire `Tests run: 57`, failsafe `Tests run: 35` (31 + 4), coverage met, `BUILD SUCCESS`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services
git commit -m "feat(api): delete_batch sync handler; server deck refuses rows the app's CHECKs would refuse

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Drift v4 — sync tables, server_version, triggers, migration

**Files:** `lib/core/database/tables/sync.drift` (create), `deck.drift`, `trash.drift`, `app_database.dart`, generated schema files, `test/drift/migration_test.dart`, `test/core/sync/sync_triggers_test.dart` (create), `docs/shared/data/schema.md`.

**Interfaces:**
- Produces:
  - Drift tables `syncOutbox` (data class `SyncOutboxEntry`: `opId`, `entityType`, `entityId`, `op`, `createdAt`, `attempts`) and `syncState` (`SyncStateEntry`: `key`, `value`);
  - `Deck.serverVersion` and `DeleteBatch.serverVersion` (`int?`);
  - `schemaVersion == 4`;
  - the constant `syncApplyingRemoteKey = 'applying_remote'` in `lib/core/database/tables/sync_keys.dart`.

- [ ] **Step 1: Write the failing trigger test**

`test/core/sync/sync_triggers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';

import '../../support/test_database.dart';

Future<List<Map<String, Object?>>> _outbox(AppDatabase db) async => [
  for (final row in await db
      .customSelect('SELECT * FROM sync_outbox ORDER BY created_at, rowid')
      .get())
    row.data,
];

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) "
      "VALUES (?, 'c', ?, ?, 2, 'unset', 0, 0, 0)",
      [id, parent, parent],
    );

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('an insert queues one upsert with a UUID op id', () async {
    await _root(db, 'R');

    final outbox = await _outbox(db);
    expect(outbox, hasLength(1));
    expect(outbox.single['entity_type'], 'deck');
    expect(outbox.single['entity_id'], 'R');
    expect(outbox.single['op'], 'upsert');
    expect(
      outbox.single['op_id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('a later write replaces the op id but keeps created_at and order', () async {
    await _root(db, 'R');
    await _child(db, 'C', 'R');
    final before = await _outbox(db);

    await db.customStatement("UPDATE deck SET name = 'renamed' WHERE id = 'R'");

    final after = await _outbox(db);
    expect(after.map((e) => e['entity_id']), ['R', 'C']);
    expect(after.first['op_id'], isNot(before.first['op_id']));
    expect(after.first['created_at'], before.first['created_at']);
  });

  test('a delete, cascades included, queues deletes', () async {
    await _root(db, 'R');
    await _child(db, 'C', 'R');

    await db.customStatement("DELETE FROM deck WHERE id = 'R'");

    final outbox = await _outbox(db);
    expect(
      {for (final e in outbox) e['entity_id']: e['op']},
      {'R': 'delete', 'C': 'delete'},
    );
  });

  test('delete_batches are captured too', () async {
    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
      "VALUES ('B', 'deck', 'R', 0)",
    );

    expect((await _outbox(db)).single['entity_type'], 'delete_batch');
  });

  test('writes under applying_remote are not captured', () async {
    await db.transaction(() async {
      await db.customStatement(
        'INSERT INTO sync_state (key, value) VALUES (?, ?)',
        [syncApplyingRemoteKey, '1'],
      );
      await _root(db, 'R');
      await db.customStatement(
        'DELETE FROM sync_state WHERE key = ?',
        [syncApplyingRemoteKey],
      );
    });

    expect(await _outbox(db), isEmpty);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/sync/sync_triggers_test.dart`
Expected: compilation failure, because `package:memox/core/database/tables/sync_keys.dart` does not exist.

- [ ] **Step 3: Implement the schema**

`lib/core/database/tables/sync_keys.dart`:

```dart
/// Keys of the `sync_state` table (app deck-sync spec §3).
library;

/// While this key exists, the sync triggers do not queue writes: the write
/// is data from the server, not a local change.
const syncApplyingRemoteKey = 'applying_remote';

/// This installation's id, sent with every push.
const syncDeviceIdKey = 'device_id';

/// The `serverVersion` cursor of the last applied pull page.
const syncSinceKey = 'since';
```

`lib/core/database/tables/sync.drift`:

```sql
import 'deck.drift';
import 'trash.drift';

-- App deck-sync spec §3: one pending operation per synced row. A write
-- replaces op_id (so an acknowledgement of an older push cannot remove it)
-- and keeps created_at (so a parent stays ahead of its child).
CREATE TABLE sync_outbox (
  op_id TEXT NOT NULL PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL CHECK (op IN ('upsert', 'delete')),
  created_at DATETIME NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  UNIQUE (entity_type, entity_id)
) AS SyncOutboxEntry;

CREATE TABLE sync_state (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
) AS SyncStateEntry;

-- A random version-4 UUID for op_id, written out in each trigger because
-- SQLite has no function for it.
CREATE TRIGGER deck_sync_insert AFTER INSERT ON deck
WHEN (SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'deck', new.id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;

CREATE TRIGGER deck_sync_update AFTER UPDATE ON deck
WHEN (SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'deck', new.id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;

CREATE TRIGGER deck_sync_delete AFTER DELETE ON deck
WHEN (SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'deck', old.id, 'delete', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;

CREATE TRIGGER delete_batches_sync_insert AFTER INSERT ON delete_batches
WHEN (SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'delete_batch', new.id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;

CREATE TRIGGER delete_batches_sync_update AFTER UPDATE ON delete_batches
WHEN (SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'delete_batch', new.id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;

CREATE TRIGGER delete_batches_sync_delete AFTER DELETE ON delete_batches
WHEN (SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'delete_batch', old.id, 'delete', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;
```

In `deck.drift`, add before `sibling_position`: `server_version INTEGER, -- NULL = never acknowledged by the server (ADR-013).`
In `trash.drift`, add after `owner_id TEXT, …` (add a comma to that line first): `server_version INTEGER -- NULL = never acknowledged by the server (ADR-013).`

In `app_database.dart`:
- add `'package:memox/core/database/tables/sync.drift',` after the `trash.drift` include;
- set `schemaVersion => 4`;
- add the step:

```dart
      from3To4: (m, schema) async {
        // ADR-013: sync. The outbox, its state, the acknowledged version on
        // each synced row, and the triggers that capture every local write
        // (app deck-sync spec §3). Existing rows are queued so the first sync
        // uploads the library: batches first, then decks parents-first.
        await m.createTable(schema.syncOutbox);
        await m.createTable(schema.syncState);
        await m.addColumn(schema.deck, schema.deck.serverVersion);
        await m.addColumn(schema.deleteBatches, schema.deleteBatches.serverVersion);
        await m.createTrigger(schema.deckSyncInsert);
        await m.createTrigger(schema.deckSyncUpdate);
        await m.createTrigger(schema.deckSyncDelete);
        await m.createTrigger(schema.deleteBatchesSyncInsert);
        await m.createTrigger(schema.deleteBatchesSyncUpdate);
        await m.createTrigger(schema.deleteBatchesSyncDelete);
        await customStatement(_seedOutbox('delete_batch', 'delete_batches', 'id'));
        await customStatement(_seedOutbox('deck', 'deck', 'depth, id'));
      },
```

and a top-level helper at the bottom of the file:

```dart
/// Queues every existing row of [table] for upload, in [order].
String _seedOutbox(String entityType, String table, String order) =>
    'INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at) '
    "SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || "
    "substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || "
    "substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))), "
    "'$entityType', id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER) "
    'FROM $table ORDER BY $order';
```

Then run, in order: `dart run build_runner build --delete-conflicting-outputs`, and the three `drift_dev schema` commands from Global Constraints. The last two need the generated code of the first.

- [ ] **Step 4: Extend the migration test**

In `test/drift/migration_test.dart`:
- change every `migrateAndValidate(db, 3)` to `migrateAndValidate(db, 4)`, and the test titles "schema of v3" to "schema of v4";
- add a test like the existing v2 one for `startAt(3)`;
- add a test that a v3 database with rows gets them queued:

```dart
  test('a v3 database queues its batches and decks for the first sync', () async {
    final schema = await verifier.schemaAt(3);
    for (final statement in _v1Rows.where((s) => s.startsWith('INSERT INTO deck'))) {
      schema.rawDatabase.execute(statement);
    }
    schema.rawDatabase.execute(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('B', 'deck', 'R1', 0)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    final queued = await db
        .customSelect('SELECT entity_type, entity_id FROM sync_outbox ORDER BY created_at, rowid')
        .get();
    expect(queued.first.read<String>('entity_type'), 'delete_batch');
    expect(
      queued.skip(1).map((r) => r.read<String>('entity_id')).take(2).toSet(),
      {'R', 'S'},
    );
    expect(queued, hasLength(5));
  });
```

- [ ] **Step 5: Run to verify**

Run: `flutter test test/core/sync/sync_triggers_test.dart test/drift/migration_test.dart test/database`
Expected: all pass. If `test/database/schema_test.dart` lists the expected tables or triggers, add `sync_outbox`, `sync_state` and the six triggers there, and ledger it.

- [ ] **Step 6: Document the schema**

In `docs/shared/data/schema.md`, before `## Bất biến — phải kiểm tra được bằng query`, add:

```markdown
## `sync_outbox` và `sync_state` (ADR-013)

Hàng đợi đồng bộ và trạng thái sync
([app deck-sync spec](../../superpowers/specs/2026-09-27-app-deck-sync-design.md) §3).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `op_id` | TEXT PK | UUID mới ở **mỗi** lần ghi; idempotency key khi push |
| `entity_type` | TEXT NOT NULL | `deck` \| `delete_batch` |
| `entity_id` | TEXT NOT NULL | `UNIQUE (entity_type, entity_id)`: một thao tác chờ cho mỗi hàng |
| `op` | TEXT NOT NULL | `upsert` \| `delete` |
| `created_at` | DATETIME NOT NULL | lần ghi chờ đầu tiên; giữ nguyên khi hàng được ghi lại, nên cha luôn đi trước con |
| `attempts` | INTEGER NOT NULL | số lần push lỗi |

`sync_state(key, value)` giữ `device_id`, cursor `since` và cờ tạm
`applying_remote`.

Trigger `AFTER INSERT/UPDATE/DELETE` trên `deck` và `delete_batches` ghi outbox
trong cùng transaction với mọi lần ghi, kể cả CTE, cascade và purge, trừ khi có
`applying_remote` (dữ liệu từ server). `deck.server_version` và
`delete_batches.server_version` là version server đã xác nhận; NULL là chưa
từng được xác nhận.
```

Run `python tools/docs/check.py`. Expected: `PASS`.

- [ ] **Step 7: Commit**

```bash
git add lib/core/database drift_schemas test/drift test/core/sync/sync_triggers_test.dart test/database docs/shared/data/schema.md
git commit -m "feat(sync): Drift v4 — sync outbox, sync state, server_version, capture triggers

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(`test/drift/generated/` is committed, as the earlier versions were; `*.g.dart` is not.)

---

### Task 3: Network — dependencies, ApiConfig, Dio, Retrofit SyncApi

**Files:** `pubspec.yaml`; create `lib/core/network/api_config.dart`, `lib/core/network/request_id_interceptor.dart`, `lib/core/network/di/network_providers.dart`, `lib/core/sync/sync_models.dart`, `lib/core/sync/sync_api.dart`; tests `test/core/network/request_id_interceptor_test.dart`, `test/core/sync/sync_models_test.dart`.

**Interfaces:**
- Produces:
  - `class ApiConfig { const ApiConfig(this.baseUrl); final String baseUrl; bool get isEnabled; static const environment = ApiConfig(String.fromEnvironment('API_BASE_URL')); }`;
  - providers `apiConfigProvider` (`ApiConfig`), `dioProvider` (`Dio`), `syncApiProvider` (`SyncApi`), all `keepAlive`;
  - `abstract class SyncApi { Future<PushResponseModel> push(PushRequestModel request); Future<ChangesResponseModel> changes(int since, int limit); }`;
  - models `SyncOperationModel{opId, entityType, entityId, op, row}`, `PushRequestModel{deviceId, operations}`, `SyncChangeModel{entityType, entityId, serverVersion, deleted, row}`, `OperationResultModel{opId, status, serverVersion, code, current}`, `PushResponseModel{results}`, `ChangesResponseModel{changes, nextSince, hasMore}`.

- [ ] **Step 1: Add dependencies**

Run: `flutter pub add dio retrofit connectivity_plus json_annotation dev:retrofit_generator dev:json_serializable dev:fake_async`
Expected: resolves dio 5.11.x, retrofit 4.10.x, retrofit_generator 10.2.x, connectivity_plus 7.3.x and json_serializable 6.14.x.

- [ ] **Step 2: Write the failing tests**

`test/core/sync/sync_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_models.dart';

void main() {
  test('reads a push response with a rejection carrying the server copy', () {
    final response = PushResponseModel.fromJson({
      'results': [
        {'opId': 'a', 'status': 'applied', 'serverVersion': 3, 'code': null, 'current': null},
        {
          'opId': 'b',
          'status': 'rejected',
          'serverVersion': null,
          'code': 'DECK_TREE_CYCLE',
          'current': {
            'entityType': 'deck',
            'entityId': 'x',
            'serverVersion': 2,
            'deleted': false,
            'row': {'id': 'x', 'name': 'X'},
          },
        },
      ],
    });

    expect(response.results.first.serverVersion, 3);
    expect(response.results.last.code, 'DECK_TREE_CYCLE');
    expect(response.results.last.current!.row!['name'], 'X');
  });

  test('writes a push request in the wire shape', () {
    final json = const PushRequestModel(
      deviceId: 'd',
      operations: [
        SyncOperationModel(opId: 'o', entityType: 'deck', entityId: 'x', op: 'delete', row: null),
      ],
    ).toJson();

    expect(json, {
      'deviceId': 'd',
      'operations': [
        {'opId': 'o', 'entityType': 'deck', 'entityId': 'x', 'op': 'delete', 'row': null},
      ],
    });
  });

  test('reads a changes page', () {
    final page = ChangesResponseModel.fromJson({
      'changes': [
        {'entityType': 'deck', 'entityId': 'x', 'serverVersion': 7, 'deleted': true, 'row': null},
      ],
      'nextSince': 7,
      'hasMore': false,
    });

    expect(page.changes.single.deleted, isTrue);
    expect(page.nextSince, 7);
  });
}
```

`test/core/network/request_id_interceptor_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/request_id_interceptor.dart';

void main() {
  test('every request gets its own X-Request-ID', () {
    final interceptor = RequestIdInterceptor();
    final first = RequestOptions(path: '/a');
    final second = RequestOptions(path: '/b');

    interceptor.onRequest(first, RequestInterceptorHandler());
    interceptor.onRequest(second, RequestInterceptorHandler());

    expect(first.headers[RequestIdInterceptor.header], isNotEmpty);
    expect(
      first.headers[RequestIdInterceptor.header],
      isNot(second.headers[RequestIdInterceptor.header]),
    );
  });
}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `flutter test test/core/sync/sync_models_test.dart test/core/network/request_id_interceptor_test.dart`
Expected: compilation failure (missing `sync_models.dart` and `request_id_interceptor.dart`).

- [ ] **Step 4: Implement**

`lib/core/network/api_config.dart`:

```dart
/// Where the MemoX API lives. Sync runs only when a build defines
/// `--dart-define=API_BASE_URL=…` (app deck-sync spec §2).
class ApiConfig {
  const ApiConfig(this.baseUrl);

  static const environment = ApiConfig(
    String.fromEnvironment('API_BASE_URL'),
  );

  final String baseUrl;

  bool get isEnabled => baseUrl.isNotEmpty;
}
```

`lib/core/network/request_id_interceptor.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Tags each request with an `X-Request-ID`, which the server echoes and logs,
/// so a failure can be matched with the server's log line.
class RequestIdInterceptor extends Interceptor {
  static const header = 'X-Request-ID';

  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[header] = _uuid.v4();
    handler.next(options);
  }
}
```

`lib/core/network/di/network_providers.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:memox/core/network/api_config.dart';
import 'package:memox/core/network/request_id_interceptor.dart';
import 'package:memox/core/sync/sync_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

const _connectTimeout = Duration(seconds: 10);
const _receiveTimeout = Duration(seconds: 20);
const _sendTimeout = Duration(seconds: 20);

@Riverpod(keepAlive: true)
ApiConfig apiConfig(Ref ref) => ApiConfig.environment;

/// The one HTTP client (ADR-012): every API call goes through it.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiConfigProvider).baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  )..interceptors.add(RequestIdInterceptor());
  ref.onDispose(dio.close);
  return dio;
}

@Riverpod(keepAlive: true)
SyncApi syncApi(Ref ref) => SyncApi(ref.watch(dioProvider));
```

`lib/core/sync/sync_models.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'sync_models.g.dart';

/// The sync wire format (server-sync spec §4). `row` stays a map: each
/// EntitySyncAdapter converts its own table.
@JsonSerializable()
class SyncOperationModel {
  const SyncOperationModel({
    required this.opId,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.row,
  });

  factory SyncOperationModel.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationModelFromJson(json);

  final String opId;
  final String entityType;
  final String entityId;
  final String op;
  final Map<String, dynamic>? row;

  Map<String, dynamic> toJson() => _$SyncOperationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PushRequestModel {
  const PushRequestModel({required this.deviceId, required this.operations});

  factory PushRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PushRequestModelFromJson(json);

  final String deviceId;
  final List<SyncOperationModel> operations;

  Map<String, dynamic> toJson() => _$PushRequestModelToJson(this);
}

@JsonSerializable()
class SyncChangeModel {
  const SyncChangeModel({
    required this.entityType,
    required this.entityId,
    required this.serverVersion,
    required this.deleted,
    required this.row,
  });

  factory SyncChangeModel.fromJson(Map<String, dynamic> json) =>
      _$SyncChangeModelFromJson(json);

  final String entityType;
  final String entityId;
  final int serverVersion;
  final bool deleted;
  final Map<String, dynamic>? row;

  Map<String, dynamic> toJson() => _$SyncChangeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OperationResultModel {
  const OperationResultModel({
    required this.opId,
    required this.status,
    required this.serverVersion,
    required this.code,
    required this.current,
  });

  factory OperationResultModel.fromJson(Map<String, dynamic> json) =>
      _$OperationResultModelFromJson(json);

  static const applied = 'applied';

  final String opId;
  final String status;
  final int? serverVersion;
  final String? code;
  final SyncChangeModel? current;

  bool get isApplied => status == applied;

  Map<String, dynamic> toJson() => _$OperationResultModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PushResponseModel {
  const PushResponseModel({required this.results});

  factory PushResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PushResponseModelFromJson(json);

  final List<OperationResultModel> results;

  Map<String, dynamic> toJson() => _$PushResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChangesResponseModel {
  const ChangesResponseModel({
    required this.changes,
    required this.nextSince,
    required this.hasMore,
  });

  factory ChangesResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ChangesResponseModelFromJson(json);

  final List<SyncChangeModel> changes;
  final int nextSince;
  final bool hasMore;

  Map<String, dynamic> toJson() => _$ChangesResponseModelToJson(this);
}
```

`lib/core/sync/sync_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:retrofit/retrofit.dart';

part 'sync_api.g.dart';

/// The server-sync endpoints (ADR-012: Retrofit on the shared Dio).
@RestApi()
abstract class SyncApi {
  factory SyncApi(Dio dio) = _SyncApi;

  @POST('/api/v1/sync/push')
  Future<PushResponseModel> push(@Body() PushRequestModel request);

  @GET('/api/v1/sync/changes')
  Future<ChangesResponseModel> changes(
    @Query('since') int since,
    @Query('limit') int limit,
  );
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 5: Run to verify they pass**

Run: `flutter test test/core/sync/sync_models_test.dart test/core/network/request_id_interceptor_test.dart && flutter analyze`
Expected: `All tests passed!` (4 tests); analyze reports no issues.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/network lib/core/sync/sync_models.dart lib/core/sync/sync_api.dart test/core/network test/core/sync/sync_models_test.dart
git commit -m "feat(sync): network layer — ApiConfig, shared Dio with request IDs, Retrofit SyncApi and wire models (ADR-012)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Sync store and entity adapters

**Files:** create `lib/core/sync/{entity_sync_adapter,deck_sync_adapter,delete_batch_sync_adapter,sync_store}.dart`; tests `test/core/sync/{deck_sync_adapter_test,sync_store_test}.dart`.

**Interfaces:**
- Consumes: Task 2 tables and `sync_keys.dart`.
- Produces:
  - `abstract class EntitySyncAdapter { String get entityType; Future<Map<String, Object?>?> readRow(String id); Future<void> upsertFromServer(Map<String, dynamic> row, int serverVersion); Future<void> deleteFromServer(String id); Future<void> markAcknowledged(String id, int serverVersion); }`;
  - `DeckSyncAdapter(AppDatabase)` and `DeleteBatchSyncAdapter(AppDatabase)`, whose entity types are `deck` and `delete_batch`;
  - `class SyncStore`:
    - `Future<String> deviceId()` (get-or-create) and `Future<int> since()`;
    - `Future<List<SyncOutboxEntry>> pendingBatch(Set<String> entityTypes, int limit)`;
    - `Future<bool> isPending(String opId)` and `Future<Set<String>> pendingKeys()`, whose keys are `'$type/$id'`;
    - `Future<void> removeIfUnchanged(String opId)`, `Future<void> recordFailedAttempt(Iterable<String> opIds)` and `Future<void> setSince(int since)`;
    - `Future<T> applyingRemote<T>(Future<T> Function() body, {bool deferForeignKeys = false})`;
    - `Stream<void> outboxChanges()`.

- [ ] **Step 1: Write the failing tests**

`test/core/sync/deck_sync_adapter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

Map<String, dynamic> _serverRoot(String id) => {
  'id': id,
  'name': 'From server',
  'parentId': null,
  'rootId': id,
  'depth': 1,
  'contentType': 'deck',
  'schedulerType': 'sm2',
  'schedulerVersion': 1,
  'schedulerConfig': null,
  'studyConfig': '{"cardLimit":10}',
  'generation': 2,
  'firstAnsweredAt': '2026-09-27T01:02:03Z',
  'sourceTemplateId': null,
  'sourceTemplateVersion': null,
  'deleteBatchId': null,
  'siblingPosition': 3,
  'createdAt': '2026-09-27T01:00:00Z',
  'updatedAt': '2026-09-27T01:05:00Z',
};

void main() {
  late AppDatabase db;
  late DeckSyncAdapter adapter;
  late SyncStore store;
  setUp(() {
    db = openTestDatabase();
    adapter = DeckSyncAdapter(db);
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  test('a server row round-trips through Drift in the wire shape', () async {
    await store.applyingRemote(() => adapter.upsertFromServer(_serverRoot('R'), 9));

    final row = await adapter.readRow('R');
    expect(row, _serverRoot('R'));
    final deck = await (db.select(db.deck)..where((d) => d.id.equals('R'))).getSingle();
    expect(deck.serverVersion, 9);
    // Drift returns local DateTimes; compare the instant, not the zone.
    expect(deck.firstAnsweredAt!.isAtSameMomentAs(DateTime.utc(2026, 9, 27, 1, 2, 3)), isTrue);
  });

  test('applying server data queues nothing', () async {
    await store.applyingRemote(() => adapter.upsertFromServer(_serverRoot('R'), 1));
    await store.applyingRemote(() => adapter.deleteFromServer('R'));

    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('an unknown row reads as null', () async {
    expect(await adapter.readRow('missing'), isNull);
  });
}
```

`test/core/sync/sync_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

void main() {
  late AppDatabase db;
  late SyncStore store;
  setUp(() {
    db = openTestDatabase();
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  test('the device id is created once and kept', () async {
    final first = await store.deviceId();
    expect(await store.deviceId(), first);
  });

  test('an acknowledgement removes the entry only while its op id is current', () async {
    await _root(db, 'R');
    final sent = (await store.pendingBatch({'deck'}, 10)).single.opId;
    await db.customStatement("UPDATE deck SET name = 'edited' WHERE id = 'R'");

    await store.removeIfUnchanged(sent);

    expect(await store.pendingBatch({'deck'}, 10), hasLength(1));
  });

  test('pending keys and the since cursor', () async {
    await _root(db, 'R');
    await store.setSince(42);

    expect(await store.pendingKeys(), {'deck/R'});
    expect(await store.since(), 42);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/sync/deck_sync_adapter_test.dart test/core/sync/sync_store_test.dart`
Expected: compilation failure (missing `sync_store.dart`, `deck_sync_adapter.dart`).

- [ ] **Step 3: Implement**

`lib/core/sync/entity_sync_adapter.dart`:

```dart
/// How one synced table is read for push and written from the server. The
/// coordinator never names a table (app deck-sync spec §5).
abstract class EntitySyncAdapter {
  String get entityType;

  /// The row in wire shape (camelCase keys, ISO-8601 UTC times), or null when
  /// it no longer exists.
  Future<Map<String, Object?>?> readRow(String id);

  /// Writes a server row. Called only inside `SyncStore.applyingRemote`.
  Future<void> upsertFromServer(Map<String, dynamic> row, int serverVersion);

  /// Deletes a row the server tombstoned; local cascades follow.
  Future<void> deleteFromServer(String id);

  /// Records the version the server gave to the pushed state.
  Future<void> markAcknowledged(String id, int serverVersion);
}

/// Wire time: ISO-8601 in UTC (ADR-008).
String? toWireTime(DateTime? value) => value?.toUtc().toIso8601String();

DateTime? fromWireTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();
```

`lib/core/sync/deck_sync_adapter.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

/// Syncs `deck`. The server derives rootId and depth; the pulled values are
/// written as they come.
class DeckSyncAdapter implements EntitySyncAdapter {
  DeckSyncAdapter(this._db);

  static const type = 'deck';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final deck = await (_db.select(_db.deck)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    if (deck == null) {
      return null;
    }
    return {
      'id': deck.id,
      'name': deck.name,
      'parentId': deck.parentId,
      'rootId': deck.rootId,
      'depth': deck.depth,
      'contentType': deck.contentType,
      'schedulerType': deck.schedulerType,
      'schedulerVersion': deck.schedulerVersion,
      'schedulerConfig': deck.schedulerConfig,
      'studyConfig': deck.studyConfig,
      'generation': deck.generation,
      'firstAnsweredAt': _time(deck.firstAnsweredAt),
      'sourceTemplateId': deck.sourceTemplateId,
      'sourceTemplateVersion': deck.sourceTemplateVersion,
      'deleteBatchId': deck.deleteBatchId,
      'siblingPosition': deck.siblingPosition,
      'createdAt': _time(deck.createdAt),
      'updatedAt': _time(deck.updatedAt),
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, dynamic> row, int serverVersion) =>
      _db.into(_db.deck).insertOnConflictUpdate(
        DeckCompanion.insert(
          id: row['id'] as String,
          name: row['name'] as String,
          parentId: Value(row['parentId'] as String?),
          rootId: row['rootId'] as String,
          depth: row['depth'] as int,
          contentType: Value(row['contentType'] as String),
          schedulerType: Value(row['schedulerType'] as String?),
          schedulerVersion: Value(row['schedulerVersion'] as int?),
          schedulerConfig: Value(row['schedulerConfig'] as String?),
          studyConfig: Value(row['studyConfig'] as String?),
          generation: Value(row['generation'] as int?),
          firstAnsweredAt: Value(fromWireTime(row['firstAnsweredAt'])),
          sourceTemplateId: Value(row['sourceTemplateId'] as String?),
          sourceTemplateVersion: Value(row['sourceTemplateVersion'] as int?),
          deleteBatchId: Value(row['deleteBatchId'] as String?),
          siblingPosition: row['siblingPosition'] as int,
          createdAt: fromWireTime(row['createdAt'])!,
          updatedAt: fromWireTime(row['updatedAt'])!,
          serverVersion: Value(serverVersion),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.deck)..where((d) => d.id.equals(id))).go();

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      (_db.update(_db.deck)..where((d) => d.id.equals(id))).write(
        DeckCompanion(serverVersion: Value(serverVersion)),
      );

  /// Drift stores whole seconds; the wire drops the fractional part so a
  /// round-trip is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
```

`lib/core/sync/delete_batch_sync_adapter.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

/// Syncs `delete_batches`, the trash batches that trashed decks reference.
class DeleteBatchSyncAdapter implements EntitySyncAdapter {
  DeleteBatchSyncAdapter(this._db);

  static const type = 'delete_batch';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final batch =
        await (_db.select(_db.deleteBatches)..where((b) => b.id.equals(id)))
            .getSingleOrNull();
    if (batch == null) {
      return null;
    }
    return {
      'id': batch.id,
      'itemType': batch.itemType,
      'rootItemId': batch.rootItemId,
      'deletedAt': toWireTime(
        batch.deletedAt,
      )!.replaceFirst(RegExp(r'\.\d+Z$'), 'Z'),
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, dynamic> row, int serverVersion) =>
      _db.into(_db.deleteBatches).insertOnConflictUpdate(
        DeleteBatchesCompanion.insert(
          id: row['id'] as String,
          itemType: row['itemType'] as String,
          rootItemId: row['rootItemId'] as String,
          deletedAt: fromWireTime(row['deletedAt'])!,
          serverVersion: Value(serverVersion),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.deleteBatches)..where((b) => b.id.equals(id))).go();

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      (_db.update(_db.deleteBatches)..where((b) => b.id.equals(id))).write(
        DeleteBatchesCompanion(serverVersion: Value(serverVersion)),
      );
}
```

`lib/core/sync/sync_store.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
import 'package:uuid/uuid.dart';

/// The outbox and sync state in Drift (app deck-sync spec §3, §5).
class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  Future<String> deviceId() => _db.transaction(() async {
    final existing = await _value(syncDeviceIdKey);
    if (existing != null) {
      return existing;
    }
    final created = _uuid.v4();
    await _put(syncDeviceIdKey, created);
    return created;
  });

  Future<int> since() async => int.parse(await _value(syncSinceKey) ?? '0');

  Future<void> setSince(int since) => _put(syncSinceKey, '$since');

  /// Pending operations of [entityTypes], oldest first (parents before
  /// children).
  Future<List<SyncOutboxEntry>> pendingBatch(
    Set<String> entityTypes,
    int limit,
  ) =>
      (_db.select(_db.syncOutbox)
            ..where((o) => o.entityType.isIn(entityTypes))
            ..orderBy([
              (o) => OrderingTerm(expression: o.createdAt),
              (o) => OrderingTerm(expression: const CustomExpression<int>('rowid')),
            ])
            ..limit(limit))
          .get();

  Future<bool> isPending(String opId) async =>
      await (_db.select(
        _db.syncOutbox,
      )..where((o) => o.opId.equals(opId))).getSingleOrNull() !=
      null;

  Future<Set<String>> pendingKeys() async => {
    for (final entry in await _db.select(_db.syncOutbox).get())
      '${entry.entityType}/${entry.entityId}',
  };

  /// Removes the entry only if no later write replaced its op id.
  Future<void> removeIfUnchanged(String opId) =>
      (_db.delete(_db.syncOutbox)..where((o) => o.opId.equals(opId))).go();

  Future<void> recordFailedAttempt(Iterable<String> opIds) =>
      _db.customStatement(
        'UPDATE sync_outbox SET attempts = attempts + 1 '
        'WHERE op_id IN (${List.filled(opIds.length, '?').join(', ')})',
        opIds.toList(),
      );

  /// Runs [body] in one transaction whose writes the capture triggers skip.
  Future<T> applyingRemote<T>(
    Future<T> Function() body, {
    bool deferForeignKeys = false,
  }) => _db.transaction(() async {
    if (deferForeignKeys) {
      // A child may arrive before its parent; keys are checked at commit.
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
    }
    await _put(syncApplyingRemoteKey, '1');
    try {
      return await body();
    } finally {
      await (_db.delete(
        _db.syncState,
      )..where((s) => s.key.equals(syncApplyingRemoteKey))).go();
    }
  });

  Stream<void> outboxChanges() =>
      _db.select(_db.syncOutbox).watch().map((_) {});

  Future<String?> _value(String key) async => (await (_db.select(
    _db.syncState,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _put(String key, String value) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));
}
```

- [ ] **Step 4: Run to verify they pass**

Run: `dart format lib test && flutter test test/core/sync && flutter analyze`
Expected: `All tests passed!`; no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/core/sync test/core/sync
git commit -m "feat(sync): sync store and entity adapters for deck and delete_batch

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: SyncCoordinator, SyncScheduler and wiring

**Files:** create `lib/core/sync/sync_coordinator.dart`, `lib/core/sync/sync_scheduler.dart`, `lib/core/sync/di/sync_providers.dart`; modify `lib/main.dart`; tests `test/core/sync/fake_sync_server.dart`, `test/core/sync/sync_coordinator_test.dart`, `test/core/sync/sync_scheduler_test.dart`.

**Interfaces:**
- Consumes: Tasks 3–4.
- Produces:
  - `SyncCoordinator({required SyncApi api, required SyncStore store, required List<EntitySyncAdapter> adapters})` with `Future<void> runOnce()`;
  - `SyncScheduler({required Future<void> Function() run, required Stream<void> triggers, Duration debounce, Duration minBackoff, Duration maxBackoff})` with `void start()`, `void dispose()` and `Duration backoffFor(int failures)`;
  - provider `syncSchedulerProvider` (`SyncScheduler?`, `keepAlive`), which is `null` when sync is off.

- [ ] **Step 1: Write the fake server and failing tests**

`test/core/sync/fake_sync_server.dart`:

```dart
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';

/// An in-memory server with the wire semantics the coordinator relies on:
/// idempotent op ids, one version per write, tombstones, rejections by rule.
class FakeSyncServer implements SyncApi {
  final _rows = <String, SyncChangeModel>{};
  final _applied = <String, int>{};
  var _version = 0;
  var pushCalls = 0;

  /// Entity keys (`type/id`) whose next upsert is rejected with this code.
  final rejectNext = <String, String>{};

  /// Runs inside push, after the request is read: simulates an edit made on
  /// the device while the request is in flight.
  Future<void> Function()? duringPush;

  SyncChangeModel? row(String type, String id) => _rows['$type/$id'];

  void seed(String type, String id, Map<String, dynamic>? row) {
    _version++;
    _rows['$type/$id'] = SyncChangeModel(
      entityType: type,
      entityId: id,
      serverVersion: _version,
      deleted: row == null,
      row: row,
    );
  }

  @override
  Future<PushResponseModel> push(PushRequestModel request) async {
    pushCalls++;
    await duringPush?.call();
    final results = <OperationResultModel>[];
    for (final op in request.operations) {
      final key = '${op.entityType}/${op.entityId}';
      final already = _applied[op.opId];
      if (already != null) {
        results.add(_applied_(op.opId, already));
        continue;
      }
      final rejection = rejectNext.remove(key);
      if (rejection != null) {
        results.add(
          OperationResultModel(
            opId: op.opId,
            status: 'rejected',
            serverVersion: null,
            code: rejection,
            current: _rows[key],
          ),
        );
        continue;
      }
      seed(op.entityType, op.entityId, op.op == 'delete' ? null : op.row);
      _applied[op.opId] = _version;
      results.add(_applied_(op.opId, _version));
    }
    return PushResponseModel(results: results);
  }

  @override
  Future<ChangesResponseModel> changes(int since, int limit) async {
    final sorted = _rows.values.where((c) => c.serverVersion > since).toList()
      ..sort((a, b) => a.serverVersion.compareTo(b.serverVersion));
    final page = sorted.take(limit).toList();
    return ChangesResponseModel(
      changes: page,
      nextSince: page.isEmpty ? since : page.last.serverVersion,
      hasMore: sorted.length > limit,
    );
  }

  static OperationResultModel _applied_(String opId, int version) =>
      OperationResultModel(
        opId: opId,
        status: 'applied',
        serverVersion: version,
        code: null,
        current: null,
      );
}
```

`test/core/sync/sync_coordinator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

Future<void> _root(AppDatabase db, String id, {String name = 'r'}) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES (?, ?, NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
      [id, name, id],
    );

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES (?, 'c', ?, ?, 2, 'unset', 0, 0, 0)",
      [id, parent, parent],
    );

Future<String?> _name(AppDatabase db, String id) async =>
    (await (db.select(db.deck)..where((d) => d.id.equals(id))).getSingleOrNull())
        ?.name;

class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters: [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
    );
  }

  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a deck created on one device reaches the other', () async {
    await _root(a.db, 'R', name: 'Korean');
    await _child(a.db, 'C', 'R');

    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    expect(await _name(b.db, 'R'), 'Korean');
    expect(await _name(b.db, 'C'), 'c');
    expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
    expect(await b.db.select(b.db.syncOutbox).get(), isEmpty, reason: 'pulled rows must not echo');
  });

  test('an edit made while its push is in flight survives the ack', () async {
    await _root(a.db, 'R', name: 'first');
    server.duringPush = () async {
      server.duringPush = null;
      await a.db.customStatement("UPDATE deck SET name = 'second' WHERE id = 'R'");
    };

    await a.coordinator.runOnce();
    expect(await a.db.select(a.db.syncOutbox).get(), hasLength(1));

    await a.coordinator.runOnce();
    expect(server.row('deck', 'R')!.row!['name'], 'second');
  });

  test('a rejection applies the server copy', () async {
    await _root(a.db, 'R', name: 'server name');
    await a.coordinator.runOnce();
    await a.db.customStatement("UPDATE deck SET name = 'refused' WHERE id = 'R'");
    server.rejectNext['deck/R'] = 'DECK_TREE_CYCLE';

    await a.coordinator.runOnce();

    expect(await _name(a.db, 'R'), 'server name');
    expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
  });

  test('a rejection never overwrites a newer local edit', () async {
    await _root(a.db, 'R', name: 'server name');
    await a.coordinator.runOnce();
    await a.db.customStatement("UPDATE deck SET name = 'refused' WHERE id = 'R'");
    server.rejectNext['deck/R'] = 'DECK_TREE_CYCLE';
    server.duringPush = () async {
      server.duringPush = null;
      await a.db.customStatement("UPDATE deck SET name = 'newest' WHERE id = 'R'");
    };

    await a.coordinator.runOnce();

    expect(await _name(a.db, 'R'), 'newest');
  });

  test('pull skips a row with a pending local edit', () async {
    await _root(a.db, 'R', name: 'shared');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    await b.db.customStatement("UPDATE deck SET name = 'b edit' WHERE id = 'R'");
    await a.db.customStatement("UPDATE deck SET name = 'a edit' WHERE id = 'R'");
    await a.coordinator.runOnce();

    await b.coordinator.runOnce();

    expect(await _name(b.db, 'R'), 'b edit');
    expect(server.row('deck', 'R')!.row!['name'], 'b edit');
  });

  test('a child that arrives before its parent applies', () async {
    server.seed('deck', 'C', {
      ...await _wireChild('C', 'R'),
    });
    server.seed('deck', 'R', await _wireRoot('R'));

    await b.coordinator.runOnce();

    expect(await _name(b.db, 'C'), 'c');
  });

  test('a tombstone deletes the deck and its local subtree', () async {
    await _root(a.db, 'R');
    await _child(a.db, 'C', 'R');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    await a.db.customStatement("DELETE FROM deck WHERE id = 'R'");
    await a.coordinator.runOnce();

    await b.coordinator.runOnce();

    expect(await _name(b.db, 'R'), isNull);
    expect(await _name(b.db, 'C'), isNull);
  });
}

Future<Map<String, dynamic>> _wireRoot(String id) async => {
  'id': id, 'name': 'r', 'parentId': null, 'rootId': id, 'depth': 1,
  'contentType': 'deck', 'schedulerType': 'sm2', 'schedulerVersion': 1,
  'schedulerConfig': null, 'studyConfig': null, 'generation': 1,
  'firstAnsweredAt': null, 'sourceTemplateId': null, 'sourceTemplateVersion': null,
  'deleteBatchId': null, 'siblingPosition': 0,
  'createdAt': '2026-09-27T01:00:00Z', 'updatedAt': '2026-09-27T01:00:00Z',
};

Future<Map<String, dynamic>> _wireChild(String id, String parent) async => {
  ...await _wireRoot(id),
  'name': 'c', 'parentId': parent, 'rootId': parent, 'depth': 2,
  'contentType': 'unset', 'schedulerType': null, 'schedulerVersion': null,
  'generation': null,
};
```

`test/core/sync/sync_scheduler_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_scheduler.dart';

void main() {
  test('runs at start, then once per debounced burst of triggers', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(run: () async => runs++, triggers: triggers.stream)
        ..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      triggers
        ..add(null)
        ..add(null);
      clock.elapse(const Duration(seconds: 1));
      expect(runs, 1);
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 2);

      scheduler.dispose();
      triggers.close();
    });
  });

  test('a failure retries with doubling backoff capped at five minutes', () {
    fakeAsync((clock) {
      var runs = 0;
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          throw StateError('offline');
        },
        triggers: const Stream.empty(),
      )..start();

      clock.elapse(Duration.zero);
      expect(runs, 1);
      clock.elapse(const Duration(seconds: 5));
      expect(runs, 2);
      clock.elapse(const Duration(seconds: 10));
      expect(runs, 3);
      expect(scheduler.backoffFor(20), const Duration(minutes: 5));

      scheduler.dispose();
    });
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/sync/sync_coordinator_test.dart test/core/sync/sync_scheduler_test.dart`
Expected: compilation failure (missing `sync_coordinator.dart`, `sync_scheduler.dart`).

- [ ] **Step 3: Implement**

`lib/core/sync/sync_coordinator.dart`:

```dart
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:memox/core/sync/sync_store.dart';

/// One sync run: push the outbox, then pull the server's changes (app
/// deck-sync spec §5).
class SyncCoordinator {
  SyncCoordinator({
    required SyncApi api,
    required SyncStore store,
    required List<EntitySyncAdapter> adapters,
  }) : _api = api,
       _store = store,
       _adapters = {for (final a in adapters) a.entityType: a};

  static const pushBatchSize = 100;
  static const pullPageSize = 500;
  static const _upsert = 'upsert';
  static const _delete = 'delete';

  final SyncApi _api;
  final SyncStore _store;
  final Map<String, EntitySyncAdapter> _adapters;

  Future<void> runOnce() async {
    final deviceId = await _store.deviceId();
    await _push(deviceId);
    await _pull();
  }

  Future<void> _push(String deviceId) async {
    while (true) {
      final batch = await _store.pendingBatch(
        _adapters.keys.toSet(),
        pushBatchSize,
      );
      if (batch.isEmpty) {
        return;
      }
      final operations = <SyncOperationModel>[];
      for (final entry in batch) {
        final row = entry.op == _upsert
            ? await _adapters[entry.entityType]!.readRow(entry.entityId)
            : null;
        operations.add(
          SyncOperationModel(
            opId: entry.opId,
            entityType: entry.entityType,
            entityId: entry.entityId,
            op: row == null ? _delete : _upsert,
            row: row,
          ),
        );
      }
      final PushResponseModel response;
      try {
        response = await _api.push(
          PushRequestModel(deviceId: deviceId, operations: operations),
        );
      } catch (_) {
        await _store.recordFailedAttempt(batch.map((e) => e.opId));
        rethrow;
      }
      final sent = {for (final e in batch) e.opId: e};
      await _store.applyingRemote(() async {
        for (final result in response.results) {
          final entry = sent[result.opId];
          // A later local write replaced this op id: the newer state is
          // pending, so neither the ack nor the server copy may touch it.
          if (entry == null || !await _store.isPending(result.opId)) {
            continue;
          }
          final adapter = _adapters[entry.entityType]!;
          if (result.isApplied) {
            await adapter.markAcknowledged(entry.entityId, result.serverVersion!);
          } else {
            await _applyServerCopy(adapter, entry.entityId, result.current);
          }
          await _store.removeIfUnchanged(result.opId);
        }
      });
      if (batch.length < pushBatchSize) {
        return;
      }
    }
  }

  Future<void> _pull() async {
    var since = await _store.since();
    while (true) {
      final page = await _api.changes(since, pullPageSize);
      await _store.applyingRemote(deferForeignKeys: true, () async {
        final pending = await _store.pendingKeys();
        for (final change in page.changes) {
          final adapter = _adapters[change.entityType];
          if (adapter == null ||
              pending.contains('${change.entityType}/${change.entityId}')) {
            continue;
          }
          await _applyServerCopy(adapter, change.entityId, change);
        }
        await _store.setSince(page.nextSince);
      });
      since = page.nextSince;
      if (!page.hasMore) {
        return;
      }
    }
  }

  static Future<void> _applyServerCopy(
    EntitySyncAdapter adapter,
    String entityId,
    SyncChangeModel? copy,
  ) {
    if (copy == null || copy.deleted) {
      return adapter.deleteFromServer(entityId);
    }
    return adapter.upsertFromServer(copy.row!, copy.serverVersion);
  }
}
```

`lib/core/sync/sync_scheduler.dart`:

```dart
import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

/// When a sync runs: at start, after a debounced burst of triggers, and on
/// backoff after a failure. At most one run at a time (app deck-sync spec §5).
class SyncScheduler {
  SyncScheduler({
    required Future<void> Function() run,
    required Stream<void> triggers,
    this.debounce = const Duration(seconds: 2),
    this.minBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 5),
  }) : _run = run,
       _triggers = triggers;

  final Future<void> Function() _run;
  final Stream<void> _triggers;
  final Duration debounce;
  final Duration minBackoff;
  final Duration maxBackoff;

  StreamSubscription<void>? _subscription;
  Timer? _timer;
  var _running = false;
  var _rerun = false;
  var _failures = 0;

  void start() {
    _subscription = _triggers.listen((_) => _schedule(debounce));
    _schedule(Duration.zero);
  }

  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
  }

  Duration backoffFor(int failures) {
    final factor = math.pow(2, math.min(failures - 1, 16)).toInt();
    final delay = minBackoff * factor;
    return delay > maxBackoff ? maxBackoff : delay;
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  Future<void> _tick() async {
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    try {
      await _run();
      _failures = 0;
      if (_rerun) {
        _schedule(Duration.zero);
      }
    } catch (error, stackTrace) {
      _failures++;
      log('Sync failed; retrying', error: error, stackTrace: stackTrace);
      _schedule(backoffFor(_failures));
    } finally {
      _running = false;
      _rerun = false;
    }
  }
}
```

`lib/core/sync/di/sync_providers.dart`:

```dart
import 'package:async/async.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// The running sync, or null when this build has no API_BASE_URL.
@Riverpod(keepAlive: true)
SyncScheduler? syncScheduler(Ref ref) {
  if (!ref.watch(apiConfigProvider).isEnabled) {
    return null;
  }
  final db = ref.watch(databaseProvider);
  final store = SyncStore(db);
  final coordinator = SyncCoordinator(
    api: ref.watch(syncApiProvider),
    store: store,
    adapters: [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
  );
  final online = Connectivity().onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
  final scheduler = SyncScheduler(
    run: coordinator.runOnce,
    triggers: StreamGroup.merge([store.outboxChanges().skip(1), online]),
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
}
```

If `package:async` is not a direct dependency, run `flutter pub add async` (it is already in the lockfile through Flutter).

In `lib/main.dart`, add `import 'package:memox/core/sync/di/sync_providers.dart';` and, directly after `final settings = await readStartupSettings(container);`, add:

```dart
  // ADR-013: sync starts with the app when this build has an API_BASE_URL.
  container.read(syncSchedulerProvider);
```

Run: `dart run build_runner build --delete-conflicting-outputs && dart format lib test`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/core/sync && flutter analyze`
Expected: `All tests passed!` (7 coordinator + 2 scheduler + earlier sync tests); no analyzer issues.

- [ ] **Step 5: Full app gate**

Run: `flutter test --exclude-tags golden`, then `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
Expected: all pass; `dod_check.sh` exits 0. Sync is off in tests, so no existing test or golden changes.

- [ ] **Step 6: Commit**

```bash
git add lib/core/sync lib/main.dart pubspec.yaml pubspec.lock test/core/sync
git commit -m "feat(sync): sync coordinator and scheduler — push outbox, pull changes, backoff, connectivity; started from main when API_BASE_URL is set

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
