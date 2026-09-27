# memox-api-services Deck Sync Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build rollout step 2 of the sync spec: the server side of deck synchronization. It covers the Flyway schema, identity through `CurrentUserProvider`, per-user versions, idempotent `POST /api/v1/sync/push` and paged `GET /api/v1/sync/changes`, with the deck-tree rules enforced by the server.

**Architecture:**
- A new `sync` package owns the protocol: controller, `SyncService`/`SyncServiceImpl`, a per-operation transactional applier, the version and applied-op mappers, and a `SyncEntityHandler` strategy interface. Card, tags and review log will add handlers later.
- The `deck` package implements `DeckSyncHandler` with its MyBatis mapper.
- The server treats `root_id` and `depth` as derived: it computes them from `parent_id` and rewrites the subtree on a move.
- Every changed row gets its own `server_version`, allocated in one block per operation.

**Tech Stack:** Java 17, Spring Boot 3.5.16, MyBatis 3.5.19, PostgreSQL 18, Flyway 11, Jackson, JUnit 5, Testcontainers.

**Spec:** `docs/superpowers/specs/2026-09-27-server-sync-design.md` (ADR-013). This plan also amends it; see Task 5.

## Global Constraints

- Maven commands run from `memox-api-services/`. The gate is `./mvnw -B verify` (Docker required). Run `./mvnw -B spotless:apply` before each commit.
- Wire format (spec §4):
  - push body `{deviceId, operations[{opId, entityType, entityId, op: "upsert"|"delete", row}]}`, at most 100 operations;
  - per-operation result `{opId, status: "applied"|"rejected", serverVersion, code, current}`;
  - changes response `{changes[{entityType, entityId, serverVersion, deleted, row}], nextSince, hasMore}`, with `limit` from 1 to 500 and a default of 500.
- Entity type string: `deck`.
- Sync rows mirror Drift's columns in camelCase and keep Drift's stored values for `contentType` (`unset|card|deck`) and `schedulerType` (`eight_box|sm2`). They are row data, not domain enums.
- Server-derived columns: `rootId` and `depth` sent by a client are ignored.
- Deck depth limit: 10 (BR-DECK-001).
- Rejection codes (added to `ErrorCode`, text in `messages.properties`): `DECK_TREE_CYCLE`, `DECK_TREE_TOO_DEEP`, `DECK_PARENT_MISSING`, `SYNC_ENTITY_CONFLICT` (all 409), `SYNC_ENTITY_UNSUPPORTED` (400). Row validation failures use `VALIDATION_FAILED`.
- The owner always comes from `CurrentUserProvider`. A client never sends `userId`. The dev user id is the property `memox.dev-user-id`, default `00000000-0000-0000-0000-000000000001`.
- Every server query filters on `user_id`.
- Probe and test endpoints stay under `/probe/**`.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- A client moves deck X under its own descendant Y (a cycle across devices). The operation must be rejected with `DECK_TREE_CYCLE` and the server's copy returned; the tree must never contain a cycle. The test is in Task 3.
- The descendants of a moved deck arrive before the moved deck, or never arrive at all. Their `rootId` and `depth` must still be right, because the server derives them. The test is in Task 3.
- A subtree move touches more rows than the pull page size. No change may be skipped between pages, which needs one version per row. The test is in Task 4.
- User B pushes an id that belongs to user A. A's row must stay untouched (`SYNC_ENTITY_CONFLICT`), and B's pull must never return A's rows. The test is in Task 4.
- The same operation is pushed twice, for example after a timeout. The second push must answer `applied` with the original version and change nothing. The test is in Task 4.

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `src/main/resources/db/migration/V1__deck_and_sync.sql` | 1 | tables `deck`, `user_sync_version`, `sync_applied_op` |
| `src/main/java/com/memox/common/security/{CurrentUserProvider,DevCurrentUserProvider,MemoxProperties,package-info}.java` | 1 | identity |
| `src/main/java/com/memox/MemoxApiServicesApplication.java` | 1 | `@ConfigurationPropertiesScan` |
| `src/main/resources/application.yml`, `messages.properties`, `common/exception/ErrorCode.java` | 1 | property, error codes |
| `src/test/java/com/memox/common/security/DevCurrentUserProviderTest.java`, `src/test/java/com/memox/SchemaIT.java` | 1 | tests |
| `src/main/java/com/memox/sync/mapper/{SyncVersionMapper,SyncAppliedOpMapper}.java` + XML | 2 | versions, idempotency |
| `src/test/java/com/memox/sync/mapper/SyncMappersIT.java` | 2 | tests |
| `src/main/java/com/memox/sync/service/SyncEntityHandler.java`, `sync/dto/response/SyncChange.java` | 3 | strategy contract |
| `src/main/java/com/memox/deck/{model/Deck,model/DeckSubtreeNode,dto/DeckSyncRow,mapper/DeckSyncMapper,service/impl/DeckSyncHandler}.java` + XML | 3 | deck sync |
| `src/test/java/com/memox/deck/service/impl/DeckSyncHandlerIT.java` | 3 | tests |
| `src/main/java/com/memox/sync/{controller/SyncController,service/SyncService,service/impl/SyncServiceImpl,service/impl/SyncOperationApplier}.java`, `sync/dto/**` | 4 | protocol |
| `src/test/java/com/memox/sync/SyncApiIT.java` | 4 | end-to-end tests |
| spec §4–§5, §8; `memox-api-services/README.md` | 5 | amendments, docs |

(Paths starting with `src/` are under `memox-api-services/`. `deck/dto/DeckSyncRow` sits directly in `dto/`, because it is neither a request nor a response: it is a row on the wire in both directions.)

---

### Task 1: Schema, identity and error codes

**Files:** see the file map for Task 1.

**Interfaces:**
- Produces:
  - `interface CurrentUserProvider { UUID currentUserId(); }`;
  - `DevCurrentUserProvider`, a `@Component`;
  - `record MemoxProperties(UUID devUserId)`, bound from the `memox` prefix;
  - tables `deck`, `user_sync_version`, `sync_applied_op`;
  - `ErrorCode` constants `DECK_TREE_CYCLE`, `DECK_TREE_TOO_DEEP`, `DECK_PARENT_MISSING`, `SYNC_ENTITY_CONFLICT`, `SYNC_ENTITY_UNSUPPORTED`.

- [ ] **Step 1: Write the failing tests**

`src/test/java/com/memox/common/security/DevCurrentUserProviderTest.java`:

```java
package com.memox.common.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class DevCurrentUserProviderTest {

    @Test
    void returnsTheConfiguredDevUser() {
        UUID devUser = UUID.fromString("00000000-0000-0000-0000-000000000042");

        assertThat(new DevCurrentUserProvider(new MemoxProperties(devUser)).currentUserId())
                .isEqualTo(devUser);
    }
}
```

`src/test/java/com/memox/SchemaIT.java`:

```java
package com.memox;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.JdbcTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/** Flyway V1 creates the sync schema and its constraints hold. */
@JdbcTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class SchemaIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse(TestcontainersConfiguration.POSTGRES_IMAGE));

    private static final String INSERT_ROOT = "INSERT INTO deck (id, user_id, name, parent_id, root_id, depth,"
            + " content_type, scheduler_type, sibling_position, created_at, updated_at, server_version,"
            + " last_device_id) VALUES (?, ?, 'Root', NULL, ?, ?, ?, ?, 0, now(), now(), 1, ?)";

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void createsTheSyncTables() {
        assertThat(jdbc.queryForList(
                        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'", String.class))
                .contains("deck", "user_sync_version", "sync_applied_op");
    }

    @Test
    void acceptsAValidRoot() {
        UUID id = UUID.randomUUID();

        jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 1, "deck", "sm2", UUID.randomUUID());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM deck WHERE id = ?", Integer.class, id))
                .isOne();
    }

    @Test
    void rejectsDepthAboveTen() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() -> jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 11, "deck", "sm2", UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void rejectsARootWithoutScheduler() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() -> jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 1, "deck", null, UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void rejectsAnUnknownContentType() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() -> jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 1, "folder", "sm2", UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `./mvnw -B test -Dtest=DevCurrentUserProviderTest` → COMPILATION ERROR (`cannot find symbol: class DevCurrentUserProvider`).
Then run: `./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=SchemaIT`. The build still fails to compile because of the first test, which is expected. After Step 3 both tests must run.

- [ ] **Step 3: Implement**

`src/main/resources/db/migration/V1__deck_and_sync.sql`:

```sql
-- ADR-013 / server-sync spec §7. Ids are client-generated UUIDs (ADR-007); times are UTC (ADR-008).

CREATE TABLE user_sync_version (
    user_id uuid PRIMARY KEY,
    version bigint NOT NULL
);

CREATE TABLE sync_applied_op (
    user_id uuid NOT NULL,
    op_id uuid NOT NULL,
    server_version bigint NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, op_id)
);

CREATE TABLE deck (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    name text NOT NULL,
    parent_id uuid NULL REFERENCES deck (id),
    root_id uuid NOT NULL,
    depth integer NOT NULL CHECK (depth BETWEEN 1 AND 10),
    content_type text NOT NULL CHECK (content_type IN ('unset', 'card', 'deck')),
    scheduler_type text NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
    scheduler_version integer NULL,
    scheduler_config text NULL,
    study_config text NULL,
    generation integer NULL,
    first_answered_at timestamptz NULL,
    source_template_id text NULL,
    source_template_version integer NULL,
    delete_batch_id uuid NULL,
    sibling_position integer NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    server_version bigint NOT NULL,
    last_device_id uuid NOT NULL,
    deleted_at timestamptz NULL,
    -- A root holds decks and owns the scheduler; a child has neither (schema.md: deck).
    CONSTRAINT deck_root_shape CHECK (
        (parent_id IS NULL AND content_type = 'deck' AND scheduler_type IS NOT NULL)
        OR (parent_id IS NOT NULL AND scheduler_type IS NULL))
);

CREATE INDEX idx_deck_user_version ON deck (user_id, server_version);
CREATE INDEX idx_deck_parent ON deck (parent_id);
```

`src/main/java/com/memox/common/security/package-info.java`:

```java
/**
 * Who is calling: {@link com.memox.common.security.CurrentUserProvider}. A dev user until the auth spec (ADR-013).
 */
package com.memox.common.security;
```

`src/main/java/com/memox/common/security/CurrentUserProvider.java`:

```java
package com.memox.common.security;

import java.util.UUID;

/**
 * The authenticated user. Services take the owner of every row from here, never from the request (ADR-013). The auth
 * spec replaces the dev implementation with a JWT-backed one.
 */
public interface CurrentUserProvider {

    UUID currentUserId();
}
```

`src/main/java/com/memox/common/security/MemoxProperties.java`:

```java
package com.memox.common.security;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/** Application properties under {@code memox}. */
@Validated
@ConfigurationProperties(prefix = "memox")
public record MemoxProperties(@NotNull UUID devUserId) {}
```

`src/main/java/com/memox/common/security/DevCurrentUserProvider.java`:

```java
package com.memox.common.security;

import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Every request is the one dev user until login exists (ADR-013). */
@Component
@RequiredArgsConstructor
public class DevCurrentUserProvider implements CurrentUserProvider {

    private final MemoxProperties properties;

    @Override
    public UUID currentUserId() {
        return properties.devUserId();
    }
}
```

In `MemoxApiServicesApplication.java`, add `@ConfigurationPropertiesScan` under `@SpringBootApplication`, together with its import `org.springframework.boot.context.properties.ConfigurationPropertiesScan`.

In `application.yml`, append:

```yaml

memox:
  # The owner of every row until the auth spec (ADR-013).
  dev-user-id: ${MEMOX_DEV_USER_ID:00000000-0000-0000-0000-000000000001}
```

In `ErrorCode.java`, replace `    VALIDATION_FAILED(HttpStatus.BAD_REQUEST);` with:

```java
    VALIDATION_FAILED(HttpStatus.BAD_REQUEST),

    DECK_TREE_CYCLE(HttpStatus.CONFLICT),
    DECK_TREE_TOO_DEEP(HttpStatus.CONFLICT),
    DECK_PARENT_MISSING(HttpStatus.CONFLICT),

    SYNC_ENTITY_CONFLICT(HttpStatus.CONFLICT),
    SYNC_ENTITY_UNSUPPORTED(HttpStatus.BAD_REQUEST);
```

Append to `messages.properties`:

```properties
error.DECK_TREE_CYCLE=A deck cannot be moved inside itself or one of its sub-decks.
error.DECK_TREE_TOO_DEEP=Decks can be nested at most 10 levels deep.
error.DECK_PARENT_MISSING=The parent deck does not exist or was deleted.
error.SYNC_ENTITY_CONFLICT=This item belongs to another account.
error.SYNC_ENTITY_UNSUPPORTED=This kind of item cannot be synchronized yet.
```

- [ ] **Step 4: Run to verify they pass**

Run: `./mvnw -B spotless:apply && ./mvnw -B test -Dtest='DevCurrentUserProviderTest,MemoxApiServicesApplicationTests,GlobalExceptionHandlerTests' && ./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=SchemaIT`
Expected: unit tests `Tests run: 12, Failures: 0`, where the context test proves Flyway V1 applies; `SchemaIT` `Tests run: 5, Failures: 0`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services/src memox-api-services/pom.xml
git commit -m "feat(api): deck and sync schema (Flyway V1), dev CurrentUserProvider, sync error codes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Per-user versions and applied operations

**Files:**
- Create: `src/main/java/com/memox/sync/mapper/SyncVersionMapper.java`, `src/main/resources/mapper/sync/SyncVersionMapper.xml`
- Create: `src/main/java/com/memox/sync/mapper/SyncAppliedOpMapper.java`, `src/main/resources/mapper/sync/SyncAppliedOpMapper.xml`
- Test: `src/test/java/com/memox/sync/mapper/SyncMappersIT.java`

**Interfaces:**
- Consumes: Task 1 tables.
- Produces:
  - `SyncVersionMapper.allocate(UUID userId, int count) → long`: the **last** version of a block of `count` new versions; the first is `last - count + 1`.
  - `SyncVersionMapper.current(UUID userId) → Long`: `null` when the user has never written.
  - `SyncAppliedOpMapper.findServerVersion(UUID userId, UUID opId) → Long` (null when not applied).
  - `SyncAppliedOpMapper.insert(UUID userId, UUID opId, long serverVersion)`.

- [ ] **Step 1: Write the failing test**

`src/test/java/com/memox/sync/mapper/SyncMappersIT.java`:

```java
package com.memox.sync.mapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mybatis.spring.boot.test.autoconfigure.MybatisTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DuplicateKeyException;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@MybatisTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class SyncMappersIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse(TestcontainersConfiguration.POSTGRES_IMAGE));

    @Autowired
    private SyncVersionMapper versions;

    @Autowired
    private SyncAppliedOpMapper appliedOps;

    @Test
    void allocatesConsecutiveBlocksPerUser() {
        UUID user = UUID.randomUUID();
        UUID other = UUID.randomUUID();

        assertThat(versions.current(user)).isNull();
        assertThat(versions.allocate(user, 1)).isEqualTo(1L);
        assertThat(versions.allocate(user, 3)).isEqualTo(4L);
        assertThat(versions.allocate(other, 2)).isEqualTo(2L);
        assertThat(versions.current(user)).isEqualTo(4L);
    }

    @Test
    void remembersAppliedOperationsPerUser() {
        UUID user = UUID.randomUUID();
        UUID op = UUID.randomUUID();

        assertThat(appliedOps.findServerVersion(user, op)).isNull();
        appliedOps.insert(user, op, 7L);

        assertThat(appliedOps.findServerVersion(user, op)).isEqualTo(7L);
        assertThat(appliedOps.findServerVersion(UUID.randomUUID(), op)).isNull();
        assertThatThrownBy(() -> appliedOps.insert(user, op, 8L)).isInstanceOf(DuplicateKeyException.class);
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=SyncMappersIT`
Expected: COMPILATION ERROR, `cannot find symbol: class SyncVersionMapper`.

- [ ] **Step 3: Implement**

`src/main/java/com/memox/sync/mapper/SyncVersionMapper.java`:

```java
package com.memox.sync.mapper;

import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** The per-user change counter behind {@code server_version}. */
@Mapper
public interface SyncVersionMapper {

    /**
     * Reserves {@code count} consecutive versions and returns the last. The row lock is held until the transaction
     * commits, so versions follow commit order for each user.
     */
    long allocate(@Param("userId") UUID userId, @Param("count") int count);

    Long current(@Param("userId") UUID userId);
}
```

`src/main/resources/mapper/sync/SyncVersionMapper.xml`:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.memox.sync.mapper.SyncVersionMapper">

    <select id="allocate" resultType="long" flushCache="true">
        INSERT INTO user_sync_version (user_id, version)
        VALUES (#{userId}, #{count})
        ON CONFLICT (user_id) DO UPDATE SET version = user_sync_version.version + #{count}
        RETURNING version
    </select>

    <select id="current" resultType="java.lang.Long">
        SELECT version FROM user_sync_version WHERE user_id = #{userId}
    </select>
</mapper>
```

`src/main/java/com/memox/sync/mapper/SyncAppliedOpMapper.java`:

```java
package com.memox.sync.mapper;

import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** Operations already applied, for push idempotency (spec §4.1). */
@Mapper
public interface SyncAppliedOpMapper {

    Long findServerVersion(@Param("userId") UUID userId, @Param("opId") UUID opId);

    void insert(@Param("userId") UUID userId, @Param("opId") UUID opId, @Param("serverVersion") long serverVersion);
}
```

`src/main/resources/mapper/sync/SyncAppliedOpMapper.xml`:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.memox.sync.mapper.SyncAppliedOpMapper">

    <select id="findServerVersion" resultType="java.lang.Long">
        SELECT server_version FROM sync_applied_op WHERE user_id = #{userId} AND op_id = #{opId}
    </select>

    <insert id="insert">
        INSERT INTO sync_applied_op (user_id, op_id, server_version)
        VALUES (#{userId}, #{opId}, #{serverVersion})
    </insert>
</mapper>
```

- [ ] **Step 4: Run to verify it passes**

Run: `./mvnw -B spotless:apply && ./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=SyncMappersIT`
Expected: `Tests run: 2, Failures: 0, Errors: 0`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services/src
git commit -m "feat(api): per-user sync versions and applied-operation log

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Deck sync handler with server-derived tree placement

**Files:**
- Create: `src/main/java/com/memox/sync/service/SyncEntityHandler.java`, `src/main/java/com/memox/sync/dto/response/SyncChange.java`
- Create: `src/main/java/com/memox/deck/model/Deck.java`, `src/main/java/com/memox/deck/model/DeckSubtreeNode.java`, `src/main/java/com/memox/deck/dto/DeckSyncRow.java`
- Create: `src/main/java/com/memox/deck/mapper/DeckSyncMapper.java`, `src/main/resources/mapper/deck/DeckSyncMapper.xml`
- Create: `src/main/java/com/memox/deck/service/impl/DeckSyncHandler.java`
- Test: `src/test/java/com/memox/deck/service/impl/DeckSyncHandlerIT.java`

**Interfaces:**
- Consumes: Task 2 `SyncVersionMapper.allocate(UUID, int)`; Task 1 `ErrorCode` constants; `BusinessException(ErrorCode)`.
- Produces:
  - `interface SyncEntityHandler { String entityType(); long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode row); long delete(UUID userId, UUID deviceId, UUID entityId); List<SyncChange> changesSince(UUID userId, long since, int limit); SyncChange current(UUID userId, UUID entityId); }`.
    - `upsert` and `delete` throw `BusinessException` to reject, and return the entity's `server_version`.
    - `current` returns `null` when the entity is unknown, or when it belongs to another user.
  - `record SyncChange(String entityType, UUID entityId, long serverVersion, boolean deleted, Object row)`; `row` is `null` when `deleted` is true.
  - `DeckSyncHandler.ENTITY_TYPE = "deck"`.

- [ ] **Step 1: Write the failing test**

`src/test/java/com/memox/deck/service/impl/DeckSyncHandlerIT.java`:

```java
package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.sync.dto.response.SyncChange;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class DeckSyncHandlerIT {

    private static final Instant T = Instant.parse("2026-09-27T01:00:00Z");

    private static final UUID DEVICE = UUID.randomUUID();

    @Autowired
    private DeckSyncHandler handler;

    @Autowired
    private ObjectMapper objectMapper;

    private final UUID user = UUID.randomUUID();

    @Test
    void storesARootWithDerivedRootIdAndDepth() {
        UUID root = UUID.randomUUID();

        long version = handler.upsert(user, DEVICE, root, row(root, null, "deck", "sm2", UUID.randomUUID(), 99));

        DeckSyncRow stored = currentRow(root);
        assertThat(version).isPositive();
        assertThat(stored.rootId()).isEqualTo(root);
        assertThat(stored.depth()).isEqualTo(1);
    }

    @Test
    void derivesAChildsPlacementFromItsParentIgnoringTheClient() {
        UUID root = createRoot();
        UUID child = UUID.randomUUID();

        handler.upsert(user, DEVICE, child, row(child, root, "unset", null, UUID.randomUUID(), 7));

        assertThat(currentRow(child).rootId()).isEqualTo(root);
        assertThat(currentRow(child).depth()).isEqualTo(2);
    }

    @Test
    void movingADeckRewritesItsSubtreeWithOneVersionPerRow() {
        UUID rootA = createRoot();
        UUID rootB = createRoot();
        UUID x = createChild(rootA);
        UUID y = createChild(x);

        long moved = handler.upsert(user, DEVICE, x, row(x, rootB, "deck", null, rootA, 2));

        assertThat(currentRow(x).rootId()).isEqualTo(rootB);
        assertThat(currentRow(y).rootId()).isEqualTo(rootB);
        assertThat(currentRow(y).depth()).isEqualTo(3);
        assertThat(handler.current(user, y).serverVersion()).isEqualTo(moved + 1);
    }

    @Test
    void rejectsACycle() {
        UUID root = createRoot();
        UUID x = createChild(root);
        UUID y = createChild(x);

        assertThatThrownBy(() -> handler.upsert(user, DEVICE, x, row(x, y, "deck", null, root, 3)))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_TREE_CYCLE);
        assertThat(currentRow(x).rootId()).isEqualTo(root);
    }

    @Test
    void rejectsAMoveDeeperThanTenLevels() {
        UUID parent = createRoot();
        for (int level = 2; level <= 9; level++) {
            parent = createChild(parent);
        }
        UUID otherRoot = createRoot();
        UUID a = createChild(otherRoot);
        createChild(a);
        UUID finalParent = parent;

        assertThatThrownBy(() -> handler.upsert(user, DEVICE, a, row(a, finalParent, "deck", null, otherRoot, 2)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_TREE_TOO_DEEP);
    }

    @Test
    void rejectsAMissingOrDeletedParent() {
        UUID orphan = UUID.randomUUID();
        UUID root = createRoot();
        handler.delete(user, DEVICE, root);

        assertThatThrownBy(() -> handler.upsert(user, DEVICE, orphan, row(orphan, UUID.randomUUID(), "unset", null, orphan, 2)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_PARENT_MISSING);
        assertThatThrownBy(() -> handler.upsert(user, DEVICE, orphan, row(orphan, root, "unset", null, root, 2)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_PARENT_MISSING);
    }

    @Test
    void refusesToTouchAnotherUsersDeck() {
        UUID root = createRoot();

        assertThatThrownBy(() -> handler.upsert(UUID.randomUUID(), DEVICE, root, row(root, null, "deck", "sm2", root, 1)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.SYNC_ENTITY_CONFLICT);
        assertThat(handler.current(UUID.randomUUID(), root)).isNull();
    }

    @Test
    void deleteTombstonesTheSubtree() {
        UUID root = createRoot();
        UUID child = createChild(root);

        handler.delete(user, DEVICE, root);

        assertThat(handler.current(user, root).deleted()).isTrue();
        assertThat(handler.current(user, child).deleted()).isTrue();
        assertThat(handler.current(user, child).row()).isNull();
    }

    @Test
    void changesComeInVersionOrderAfterTheCursor() {
        UUID root = createRoot();
        long cursor = handler.current(user, root).serverVersion();
        UUID child = createChild(root);
        handler.delete(user, DEVICE, child);

        List<SyncChange> changes = handler.changesSince(user, cursor, 10);

        assertThat(changes).extracting(SyncChange::entityId).containsExactly(child);
        assertThat(changes.get(0).deleted()).isTrue();
        assertThat(handler.changesSince(user, 0, 10)).extracting(SyncChange::serverVersion).isSorted();
    }

    private UUID createRoot() {
        UUID id = UUID.randomUUID();
        handler.upsert(user, DEVICE, id, row(id, null, "deck", "sm2", id, 1));
        return id;
    }

    private UUID createChild(UUID parent) {
        UUID id = UUID.randomUUID();
        handler.upsert(user, DEVICE, id, row(id, parent, "deck", null, parent, 2));
        return id;
    }

    private DeckSyncRow currentRow(UUID id) {
        return (DeckSyncRow) handler.current(user, id).row();
    }

    /** {@code clientRootId} and {@code clientDepth} are deliberately wrong: the server must ignore them. */
    private JsonNode row(UUID id, UUID parentId, String contentType, String schedulerType, UUID clientRootId, int clientDepth) {
        DeckSyncRow row = new DeckSyncRow(id, "Deck " + id, parentId, clientRootId, clientDepth, contentType,
                schedulerType, schedulerType == null ? null : 1, null, null, schedulerType == null ? null : 1, null,
                null, null, null, 0, T, T);
        return objectMapper.valueToTree(row);
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B test -Dtest=DeckSyncHandlerIT`
(The name ends in `IT`, but a `-Dtest` filter runs it under surefire, which is fine for a focused run.)
Expected: COMPILATION ERROR, `cannot find symbol: class DeckSyncHandler`.

- [ ] **Step 3: Implement**

`src/main/java/com/memox/sync/dto/response/SyncChange.java`:

```java
package com.memox.sync.dto.response;

import java.util.UUID;

/** One entity's state after {@code serverVersion}; {@code row} is null for a tombstone. */
public record SyncChange(String entityType, UUID entityId, long serverVersion, boolean deleted, Object row) {}
```

`src/main/java/com/memox/sync/service/SyncEntityHandler.java`:

```java
package com.memox.sync.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.memox.sync.dto.response.SyncChange;
import java.util.List;
import java.util.UUID;

/**
 * How one entity type is synced. One implementation per synced table (deck now; card, tags and review log next), so
 * the protocol code never changes when a type is added. Called inside the applier's transaction; reject by throwing
 * {@code BusinessException}.
 */
public interface SyncEntityHandler {

    String entityType();

    /** @return the entity's new {@code server_version} */
    long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode row);

    /** @return the entity's tombstone {@code server_version} */
    long delete(UUID userId, UUID deviceId, UUID entityId);

    /** Changes with {@code server_version > since}, ascending, at most {@code limit}. */
    List<SyncChange> changesSince(UUID userId, long since, int limit);

    /** The server's copy, or {@code null} when the entity is unknown to this user. */
    SyncChange current(UUID userId, UUID entityId);
}
```

`src/main/java/com/memox/deck/dto/DeckSyncRow.java`:

```java
package com.memox.deck.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import java.time.Instant;
import java.util.UUID;

/**
 * A deck row on the sync wire, mirroring Drift's {@code deck} columns and stored values. {@code rootId} and
 * {@code depth} are derived by the server: ignored on push, authoritative on pull.
 */
public record DeckSyncRow(
        @NotNull UUID id,
        @NotBlank String name,
        UUID parentId,
        UUID rootId,
        Integer depth,
        @NotNull @Pattern(regexp = "unset|card|deck") String contentType,
        @Pattern(regexp = "eight_box|sm2") String schedulerType,
        Integer schedulerVersion,
        String schedulerConfig,
        String studyConfig,
        Integer generation,
        Instant firstAnsweredAt,
        String sourceTemplateId,
        Integer sourceTemplateVersion,
        UUID deleteBatchId,
        @NotNull @PositiveOrZero Integer siblingPosition,
        @NotNull Instant createdAt,
        @NotNull Instant updatedAt) {}
```

`src/main/java/com/memox/deck/model/Deck.java`:

```java
package com.memox.deck.model;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** A server {@code deck} row. */
@Getter
@Setter
public class Deck {

    private UUID id;
    private UUID userId;
    private String name;
    private UUID parentId;
    private UUID rootId;
    private Integer depth;
    private String contentType;
    private String schedulerType;
    private Integer schedulerVersion;
    private String schedulerConfig;
    private String studyConfig;
    private Integer generation;
    private Instant firstAnsweredAt;
    private String sourceTemplateId;
    private Integer sourceTemplateVersion;
    private UUID deleteBatchId;
    private Integer siblingPosition;
    private Instant createdAt;
    private Instant updatedAt;
    private Long serverVersion;
    private UUID lastDeviceId;
    private Instant deletedAt;
}
```

`src/main/java/com/memox/deck/model/DeckSubtreeNode.java`:

```java
package com.memox.deck.model;

import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** A live deck in a subtree and its distance below the subtree's top ({@code 0} for the top itself). */
@Getter
@Setter
public class DeckSubtreeNode {

    private UUID id;
    private int rel;
}
```

`src/main/java/com/memox/deck/mapper/DeckSyncMapper.java`:

```java
package com.memox.deck.mapper;

import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckSubtreeNode;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DeckSyncMapper {

    /** Any user's row, tombstones included: the caller checks ownership. */
    Deck findDeckById(@Param("id") UUID id);

    /** The live subtree under {@code id}, the deck itself included at {@code rel = 0}. */
    List<DeckSubtreeNode> findLiveSubtree(@Param("userId") UUID userId, @Param("id") UUID id);

    void upsertDeck(Deck deck);

    /** Rewrites placement of the subtree's descendants, one version per row starting at {@code firstVersion}. */
    int updateSubtreePlacement(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("rootId") UUID rootId,
            @Param("depth") int depth,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId);

    /** Tombstones the live subtree, the deck itself included, one version per row starting at {@code firstVersion}. */
    int tombstoneSubtree(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId);

    List<Deck> findChangesSince(@Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);
}
```

`src/main/resources/mapper/deck/DeckSyncMapper.xml`:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.memox.deck.mapper.DeckSyncMapper">

    <sql id="deckColumns">
        id, user_id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version,
        scheduler_config, study_config, generation, first_answered_at, source_template_id,
        source_template_version, delete_batch_id, sibling_position, created_at, updated_at, server_version,
        last_device_id, deleted_at
    </sql>

    <!-- Cycle-safe: UNION drops a revisited (id, rel) pair, and rel is capped at the depth limit. -->
    <sql id="liveSubtree">
        WITH RECURSIVE sub AS (
            SELECT id, 0 AS rel FROM deck WHERE id = #{id} AND user_id = #{userId} AND deleted_at IS NULL
            UNION
            SELECT d.id, sub.rel + 1 FROM deck d JOIN sub ON d.parent_id = sub.id
            WHERE d.user_id = #{userId} AND d.deleted_at IS NULL AND sub.rel &lt; 10
        )
    </sql>

    <select id="findDeckById" resultType="com.memox.deck.model.Deck">
        SELECT <include refid="deckColumns"/> FROM deck WHERE id = #{id}
    </select>

    <select id="findLiveSubtree" resultType="com.memox.deck.model.DeckSubtreeNode">
        <include refid="liveSubtree"/>
        SELECT id, rel FROM sub ORDER BY rel, id
    </select>

    <insert id="upsertDeck">
        INSERT INTO deck (<include refid="deckColumns"/>)
        VALUES (#{id}, #{userId}, #{name}, #{parentId}, #{rootId}, #{depth}, #{contentType}, #{schedulerType},
                #{schedulerVersion}, #{schedulerConfig}, #{studyConfig}, #{generation}, #{firstAnsweredAt},
                #{sourceTemplateId}, #{sourceTemplateVersion}, #{deleteBatchId}, #{siblingPosition}, #{createdAt},
                #{updatedAt}, #{serverVersion}, #{lastDeviceId}, NULL)
        ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, root_id = EXCLUDED.root_id,
            depth = EXCLUDED.depth, content_type = EXCLUDED.content_type,
            scheduler_type = EXCLUDED.scheduler_type, scheduler_version = EXCLUDED.scheduler_version,
            scheduler_config = EXCLUDED.scheduler_config, study_config = EXCLUDED.study_config,
            generation = EXCLUDED.generation, first_answered_at = EXCLUDED.first_answered_at,
            source_template_id = EXCLUDED.source_template_id,
            source_template_version = EXCLUDED.source_template_version,
            delete_batch_id = EXCLUDED.delete_batch_id, sibling_position = EXCLUDED.sibling_position,
            created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at,
            server_version = EXCLUDED.server_version, last_device_id = EXCLUDED.last_device_id,
            deleted_at = NULL
        WHERE deck.user_id = EXCLUDED.user_id
    </insert>

    <update id="updateSubtreePlacement">
        <include refid="liveSubtree"/>,
        numbered AS (SELECT id, rel, ROW_NUMBER() OVER (ORDER BY rel, id) AS rn FROM sub WHERE rel &gt; 0)
        UPDATE deck
        SET root_id = #{rootId}, depth = #{depth} + numbered.rel,
            server_version = #{firstVersion} + numbered.rn - 1, last_device_id = #{deviceId}
        FROM numbered
        WHERE deck.id = numbered.id
    </update>

    <update id="tombstoneSubtree">
        <include refid="liveSubtree"/>,
        numbered AS (SELECT id, ROW_NUMBER() OVER (ORDER BY rel, id) AS rn FROM sub)
        UPDATE deck
        SET deleted_at = now(), server_version = #{firstVersion} + numbered.rn - 1, last_device_id = #{deviceId}
        FROM numbered
        WHERE deck.id = numbered.id
    </update>

    <select id="findChangesSince" resultType="com.memox.deck.model.Deck">
        SELECT <include refid="deckColumns"/> FROM deck
        WHERE user_id = #{userId} AND server_version &gt; #{since}
        ORDER BY server_version
        LIMIT #{limit}
    </select>
</mapper>
```

`src/main/java/com/memox/deck/service/impl/DeckSyncHandler.java`:

```java
package com.memox.deck.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.mapper.DeckSyncMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckSubtreeNode;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncVersionMapper;
import com.memox.sync.service.SyncEntityHandler;
import jakarta.validation.Validator;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Syncs {@code deck}. The server derives {@code root_id} and {@code depth} from {@code parent_id} and rewrites a moved
 * subtree itself, so the order in which a client's per-row operations arrive does not matter (spec §5).
 */
@Component
@RequiredArgsConstructor
public class DeckSyncHandler implements SyncEntityHandler {

    public static final String ENTITY_TYPE = "deck";

    static final int MAX_DEPTH = 10;

    private static final int ROOT_DEPTH = 1;

    private final DeckSyncMapper deckSyncMapper;
    private final SyncVersionMapper syncVersionMapper;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode rowJson) {
        DeckSyncRow row = parse(rowJson, entityId);
        Deck existing = ownedOrNull(userId, entityId);

        List<DeckSubtreeNode> subtree = existing == null ? List.of() : deckSyncMapper.findLiveSubtree(userId, entityId);
        Deck parent = row.parentId() == null ? null : liveParent(userId, row.parentId());
        requireNoCycle(row.parentId(), entityId, subtree);

        UUID rootId = parent == null ? entityId : parent.getRootId();
        int depth = parent == null ? ROOT_DEPTH : parent.getDepth() + 1;
        int height = subtree.stream().mapToInt(DeckSubtreeNode::getRel).max().orElse(0);
        if (depth + height > MAX_DEPTH) {
            throw new BusinessException(ErrorCode.DECK_TREE_TOO_DEEP);
        }

        boolean placementChanged = existing != null
                && (!Objects.equals(existing.getRootId(), rootId) || existing.getDepth() != depth);
        int descendants = placementChanged ? subtree.size() - 1 : 0;
        long lastVersion = syncVersionMapper.allocate(userId, 1 + descendants);
        long version = lastVersion - descendants;

        deckSyncMapper.upsertDeck(toModel(row, userId, deviceId, rootId, depth, version));
        if (descendants > 0) {
            deckSyncMapper.updateSubtreePlacement(userId, entityId, rootId, depth, version + 1, deviceId);
        }
        return version;
    }

    @Override
    public long delete(UUID userId, UUID deviceId, UUID entityId) {
        Deck existing = ownedOrNull(userId, entityId);
        if (existing == null) {
            Long current = syncVersionMapper.current(userId);
            return current == null ? 0L : current;
        }
        if (existing.getDeletedAt() != null) {
            return existing.getServerVersion();
        }
        int rows = deckSyncMapper.findLiveSubtree(userId, entityId).size();
        long lastVersion = syncVersionMapper.allocate(userId, rows);
        long firstVersion = lastVersion - rows + 1;
        deckSyncMapper.tombstoneSubtree(userId, entityId, firstVersion, deviceId);
        return firstVersion;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deckSyncMapper.findChangesSince(userId, since, limit).stream()
                .map(this::toChange)
                .toList();
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        Deck deck = deckSyncMapper.findDeckById(entityId);
        if (deck == null || !deck.getUserId().equals(userId)) {
            return null;
        }
        return toChange(deck);
    }

    private DeckSyncRow parse(JsonNode rowJson, UUID entityId) {
        try {
            DeckSyncRow row = objectMapper.treeToValue(rowJson, DeckSyncRow.class);
            if (row == null || !entityId.equals(row.id()) || !validator.validate(row).isEmpty()) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            boolean rootShape = row.parentId() == null
                    ? "deck".equals(row.contentType()) && row.schedulerType() != null
                    : row.schedulerType() == null;
            if (!rootShape) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return row;
        } catch (JsonProcessingException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }

    /** The row if this user owns it; {@code null} if unknown; rejects another user's id. */
    private Deck ownedOrNull(UUID userId, UUID entityId) {
        Deck deck = deckSyncMapper.findDeckById(entityId);
        if (deck != null && !deck.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        return deck;
    }

    private Deck liveParent(UUID userId, UUID parentId) {
        Deck parent = deckSyncMapper.findDeckById(parentId);
        if (parent == null || !parent.getUserId().equals(userId) || parent.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        return parent;
    }

    private static void requireNoCycle(UUID parentId, UUID entityId, List<DeckSubtreeNode> subtree) {
        if (parentId == null) {
            return;
        }
        boolean parentInsideSubtree =
                parentId.equals(entityId) || subtree.stream().anyMatch(node -> node.getId().equals(parentId));
        if (parentInsideSubtree) {
            throw new BusinessException(ErrorCode.DECK_TREE_CYCLE);
        }
    }

    private static Deck toModel(DeckSyncRow row, UUID userId, UUID deviceId, UUID rootId, int depth, long version) {
        Deck deck = new Deck();
        deck.setId(row.id());
        deck.setUserId(userId);
        deck.setName(row.name());
        deck.setParentId(row.parentId());
        deck.setRootId(rootId);
        deck.setDepth(depth);
        deck.setContentType(row.contentType());
        deck.setSchedulerType(row.schedulerType());
        deck.setSchedulerVersion(row.schedulerVersion());
        deck.setSchedulerConfig(row.schedulerConfig());
        deck.setStudyConfig(row.studyConfig());
        deck.setGeneration(row.generation());
        deck.setFirstAnsweredAt(row.firstAnsweredAt());
        deck.setSourceTemplateId(row.sourceTemplateId());
        deck.setSourceTemplateVersion(row.sourceTemplateVersion());
        deck.setDeleteBatchId(row.deleteBatchId());
        deck.setSiblingPosition(row.siblingPosition());
        deck.setCreatedAt(row.createdAt());
        deck.setUpdatedAt(row.updatedAt());
        deck.setServerVersion(version);
        deck.setLastDeviceId(deviceId);
        return deck;
    }

    private SyncChange toChange(Deck deck) {
        boolean deleted = deck.getDeletedAt() != null;
        DeckSyncRow row = deleted
                ? null
                : new DeckSyncRow(
                        deck.getId(),
                        deck.getName(),
                        deck.getParentId(),
                        deck.getRootId(),
                        deck.getDepth(),
                        deck.getContentType(),
                        deck.getSchedulerType(),
                        deck.getSchedulerVersion(),
                        deck.getSchedulerConfig(),
                        deck.getStudyConfig(),
                        deck.getGeneration(),
                        deck.getFirstAnsweredAt(),
                        deck.getSourceTemplateId(),
                        deck.getSourceTemplateVersion(),
                        deck.getDeleteBatchId(),
                        deck.getSiblingPosition(),
                        deck.getCreatedAt(),
                        deck.getUpdatedAt());
        return new SyncChange(ENTITY_TYPE, deck.getId(), deck.getServerVersion(), deleted, row);
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `./mvnw -B spotless:apply && ./mvnw -B test -Dtest=DeckSyncHandlerIT`
Expected: `Tests run: 9, Failures: 0, Errors: 0`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services/src
git commit -m "feat(api): deck sync handler with server-derived tree placement, cycle and depth checks, subtree tombstones

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Push and changes endpoints

**Files:**
- Create: `src/main/java/com/memox/sync/dto/request/{PushRequest,SyncOperation,SyncOperationType}.java`
- Create: `src/main/java/com/memox/sync/dto/response/{PushResponse,OperationResult,OperationStatus,ChangesResponse}.java`
- Create: `src/main/java/com/memox/sync/service/SyncService.java`, `src/main/java/com/memox/sync/service/impl/{SyncServiceImpl,SyncOperationApplier}.java`
- Create: `src/main/java/com/memox/sync/controller/SyncController.java`
- Test: `src/test/java/com/memox/sync/SyncApiIT.java`

**Interfaces:**
- Consumes:
  - Task 1 `CurrentUserProvider.currentUserId()`;
  - Task 2 `SyncAppliedOpMapper`;
  - Task 3 `SyncEntityHandler` (every bean), `SyncChange`, `DeckSyncHandler.ENTITY_TYPE`.
- Produces:
  - `POST /api/v1/sync/push` → `PushResponse(List<OperationResult> results)`;
  - `GET /api/v1/sync/changes?since=&limit=` → `ChangesResponse(List<SyncChange> changes, long nextSince, boolean hasMore)`.

- [ ] **Step 1: Write the failing test**

`src/test/java/com/memox/sync/SyncApiIT.java`:

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
import com.memox.common.security.CurrentUserProvider;
import java.util.ArrayList;
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
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class SyncApiIT {

    private static final String PUSH = "/api/v1/sync/push";
    private static final String CHANGES = "/api/v1/sync/changes";
    private static final String T = "2026-09-27T01:00:00Z";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private CurrentUserProvider currentUserProvider;

    private final UUID device = UUID.randomUUID();
    private UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    @Test
    void pushingTheSameOperationTwiceAppliesItOnce() throws Exception {
        UUID root = UUID.randomUUID();
        Map<String, Object> op = upsert(UUID.randomUUID(), rootRow(root, "First"));

        long version = versionOf(push(op));
        push(op)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("applied"))
                .andExpect(jsonPath("$.results[0].serverVersion").value(version));
        changes(0).andExpect(jsonPath("$.changes", hasSize(1)));
    }

    @Test
    void aRejectedOperationReturnsTheServersCopyAndTheBatchGoesOn() throws Exception {
        UUID root = UUID.randomUUID();
        UUID child = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), rootRow(root, "Root")), upsert(UUID.randomUUID(), childRow(child, root)));

        UUID other = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), childRow(root, child)), upsert(UUID.randomUUID(), rootRow(other, "Other")))
                .andExpect(jsonPath("$.results[0].status").value("rejected"))
                .andExpect(jsonPath("$.results[0].code").value("DECK_TREE_CYCLE"))
                .andExpect(jsonPath("$.results[0].current.row.parentId").doesNotExist())
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void anUnknownEntityTypeIsRejectedWithoutCurrent() throws Exception {
        Map<String, Object> op = new LinkedHashMap<>(upsert(UUID.randomUUID(), rootRow(UUID.randomUUID(), "X")));
        op.put("entityType", "spaceship");

        push(op)
                .andExpect(jsonPath("$.results[0].status").value("rejected"))
                .andExpect(jsonPath("$.results[0].code").value("SYNC_ENTITY_UNSUPPORTED"))
                .andExpect(jsonPath("$.results[0].current").doesNotExist());
    }

    @Test
    void usersNeverSeeOrOverwriteEachOthersData() throws Exception {
        UUID root = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), rootRow(root, "Mine")));
        UUID owner = user;

        user = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), rootRow(root, "Stolen")))
                .andExpect(jsonPath("$.results[0].code").value("SYNC_ENTITY_CONFLICT"))
                .andExpect(jsonPath("$.results[0].current").doesNotExist());
        changes(0).andExpect(jsonPath("$.changes", hasSize(0)));

        user = owner;
        changes(0).andExpect(jsonPath("$.changes[0].row.name").value("Mine"));
    }

    @Test
    void aSubtreeMoveIsPagedWithoutLosingRows() throws Exception {
        UUID rootA = UUID.randomUUID();
        UUID rootB = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        List<Map<String, Object>> ops = new ArrayList<>();
        ops.add(upsert(UUID.randomUUID(), rootRow(rootA, "A")));
        ops.add(upsert(UUID.randomUUID(), rootRow(rootB, "B")));
        ops.add(upsert(UUID.randomUUID(), childRow(x, rootA)));
        for (int i = 0; i < 4; i++) {
            ops.add(upsert(UUID.randomUUID(), childRow(UUID.randomUUID(), x)));
        }
        push(ops.toArray(Map[]::new));
        long cursor = objectMapper
                .readTree(changes(0).andReturn().getResponse().getContentAsString())
                .get("nextSince")
                .asLong();

        push(upsert(UUID.randomUUID(), childRow(x, rootB)));

        List<String> seen = new ArrayList<>();
        boolean hasMore = true;
        while (hasMore) {
            var page = objectMapper.readTree(mockMvc.perform(get(CHANGES).param("since", String.valueOf(cursor)).param("limit", "2"))
                    .andReturn().getResponse().getContentAsString());
            page.get("changes").forEach(change -> seen.add(change.get("entityId").asText()));
            cursor = page.get("nextSince").asLong();
            hasMore = page.get("hasMore").asBoolean();
        }
        org.assertj.core.api.Assertions.assertThat(seen).hasSize(5).contains(x.toString());
    }

    @Test
    void rejectsAnOversizedBatchAndAnOutOfRangeLimit() throws Exception {
        Map<String, Object>[] ops = new Map[101];
        for (int i = 0; i < ops.length; i++) {
            ops[i] = upsert(UUID.randomUUID(), rootRow(UUID.randomUUID(), "N" + i));
        }
        push(ops).andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mockMvc.perform(get(CHANGES).param("since", "0").param("limit", "501"))
                .andExpect(status().isBadRequest());
    }

    @SafeVarargs
    private ResultActions push(Map<String, Object>... operations) throws Exception {
        Map<String, Object> body = Map.of("deviceId", device, "operations", List.of(operations));
        return mockMvc.perform(post(PUSH).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(body)));
    }

    private ResultActions changes(long since) throws Exception {
        return mockMvc.perform(get(CHANGES).param("since", String.valueOf(since)));
    }

    private long versionOf(ResultActions result) throws Exception {
        return objectMapper
                .readTree(result.andReturn().getResponse().getContentAsString())
                .at("/results/0/serverVersion")
                .asLong();
    }

    private static Map<String, Object> upsert(UUID opId, Map<String, Object> row) {
        return Map.of("opId", opId, "entityType", "deck", "entityId", row.get("id"), "op", "upsert", "row", row);
    }

    private static Map<String, Object> rootRow(UUID id, String name) {
        Map<String, Object> row = baseRow(id, name);
        row.put("contentType", "deck");
        row.put("schedulerType", "sm2");
        return row;
    }

    private static Map<String, Object> childRow(UUID id, UUID parentId) {
        Map<String, Object> row = baseRow(id, "Child " + id);
        row.put("parentId", parentId);
        row.put("contentType", "deck");
        return row;
    }

    private static Map<String, Object> baseRow(UUID id, String name) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", id);
        row.put("name", name);
        row.put("siblingPosition", 0);
        row.put("createdAt", T);
        row.put("updatedAt", T);
        return row;
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=SyncApiIT`
Expected: every test FAILS with status 404 on `/api/v1/sync/push`, because there is no controller yet.

- [ ] **Step 3: Implement**

`src/main/java/com/memox/sync/dto/request/SyncOperationType.java`:

```java
package com.memox.sync.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;

/** Wire values are lowercase: {@code upsert}, {@code delete} (spec §4.1). */
public enum SyncOperationType {
    @JsonProperty("upsert")
    UPSERT,
    @JsonProperty("delete")
    DELETE
}
```

`src/main/java/com/memox/sync/dto/request/SyncOperation.java`:

```java
package com.memox.sync.dto.request;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** One outbox entry. {@code opId} is the idempotency key; {@code row} is required for upserts. */
public record SyncOperation(
        @NotNull UUID opId,
        @NotBlank String entityType,
        @NotNull UUID entityId,
        @NotNull SyncOperationType op,
        JsonNode row) {}
```

`src/main/java/com/memox/sync/dto/request/PushRequest.java`:

```java
package com.memox.sync.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

public record PushRequest(
        @NotNull UUID deviceId,
        @NotEmpty @Size(max = PushRequest.MAX_OPERATIONS) List<@Valid @NotNull SyncOperation> operations) {

    public static final int MAX_OPERATIONS = 100;
}
```

`src/main/java/com/memox/sync/dto/response/OperationStatus.java`:

```java
package com.memox.sync.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum OperationStatus {
    @JsonProperty("applied")
    APPLIED,
    @JsonProperty("rejected")
    REJECTED
}
```

`src/main/java/com/memox/sync/dto/response/OperationResult.java`:

```java
package com.memox.sync.dto.response;

import java.util.UUID;

/**
 * The outcome of one operation. {@code serverVersion} is set when applied; {@code code} and {@code current} (the
 * server's copy, null when unknown) when rejected.
 */
public record OperationResult(UUID opId, OperationStatus status, Long serverVersion, String code, SyncChange current) {

    public static OperationResult applied(UUID opId, long serverVersion) {
        return new OperationResult(opId, OperationStatus.APPLIED, serverVersion, null, null);
    }

    public static OperationResult rejected(UUID opId, String code, SyncChange current) {
        return new OperationResult(opId, OperationStatus.REJECTED, null, code, current);
    }
}
```

`src/main/java/com/memox/sync/dto/response/PushResponse.java`:

```java
package com.memox.sync.dto.response;

import java.util.List;

public record PushResponse(List<OperationResult> results) {}
```

`src/main/java/com/memox/sync/dto/response/ChangesResponse.java`:

```java
package com.memox.sync.dto.response;

import java.util.List;

public record ChangesResponse(List<SyncChange> changes, long nextSince, boolean hasMore) {}
```

`src/main/java/com/memox/sync/service/SyncService.java`:

```java
package com.memox.sync.service;

import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.PushResponse;

/** The sync protocol of ADR-013 for the current user. */
public interface SyncService {

    PushResponse push(PushRequest request);

    ChangesResponse changesSince(long since, int limit);
}
```

`src/main/java/com/memox/sync/service/impl/SyncOperationApplier.java`:

```java
package com.memox.sync.service.impl;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.request.SyncOperationType;
import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.SyncEntityHandler;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Applies one operation in its own transaction, so a rejection rolls back only that operation (spec §4.1). */
@Component
@RequiredArgsConstructor
class SyncOperationApplier {

    private final SyncAppliedOpMapper syncAppliedOpMapper;

    @Transactional
    public long apply(UUID userId, UUID deviceId, SyncOperation operation, SyncEntityHandler handler) {
        long serverVersion;
        if (operation.op() == SyncOperationType.DELETE) {
            serverVersion = handler.delete(userId, deviceId, operation.entityId());
        } else {
            if (operation.row() == null) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            serverVersion = handler.upsert(userId, deviceId, operation.entityId(), operation.row());
        }
        syncAppliedOpMapper.insert(userId, operation.opId(), serverVersion);
        return serverVersion;
    }
}
```

`src/main/java/com/memox/sync/service/impl/SyncServiceImpl.java`:

```java
package com.memox.sync.service.impl;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.OperationResult;
import com.memox.sync.dto.response.PushResponse;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.SyncEntityHandler;
import com.memox.sync.service.SyncService;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class SyncServiceImpl implements SyncService {

    private final CurrentUserProvider currentUserProvider;
    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final SyncOperationApplier syncOperationApplier;
    private final Map<String, SyncEntityHandler> handlers;

    public SyncServiceImpl(
            CurrentUserProvider currentUserProvider,
            SyncAppliedOpMapper syncAppliedOpMapper,
            SyncOperationApplier syncOperationApplier,
            List<SyncEntityHandler> handlers) {
        this.currentUserProvider = currentUserProvider;
        this.syncAppliedOpMapper = syncAppliedOpMapper;
        this.syncOperationApplier = syncOperationApplier;
        this.handlers = handlers.stream()
                .collect(Collectors.toUnmodifiableMap(SyncEntityHandler::entityType, Function.identity()));
    }

    @Override
    public PushResponse push(PushRequest request) {
        UUID userId = currentUserProvider.currentUserId();
        List<OperationResult> results = request.operations().stream()
                .map(operation -> pushOne(userId, request.deviceId(), operation))
                .toList();
        return new PushResponse(results);
    }

    @Override
    public ChangesResponse changesSince(long since, int limit) {
        UUID userId = currentUserProvider.currentUserId();
        List<SyncChange> merged = handlers.values().stream()
                .flatMap(handler -> handler.changesSince(userId, since, limit + 1).stream())
                .sorted(Comparator.comparingLong(SyncChange::serverVersion))
                .toList();
        boolean hasMore = merged.size() > limit;
        List<SyncChange> page = hasMore ? merged.subList(0, limit) : merged;
        long nextSince = page.isEmpty() ? since : page.get(page.size() - 1).serverVersion();
        return new ChangesResponse(page, nextSince, hasMore);
    }

    private OperationResult pushOne(UUID userId, UUID deviceId, SyncOperation operation) {
        Long alreadyApplied = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
        if (alreadyApplied != null) {
            return OperationResult.applied(operation.opId(), alreadyApplied);
        }
        SyncEntityHandler handler = handlers.get(operation.entityType());
        if (handler == null) {
            return OperationResult.rejected(operation.opId(), ErrorCode.SYNC_ENTITY_UNSUPPORTED.name(), null);
        }
        try {
            return OperationResult.applied(
                    operation.opId(), syncOperationApplier.apply(userId, deviceId, operation, handler));
        } catch (BusinessException e) {
            return rejected(userId, operation, handler, e.getErrorCode());
        } catch (DataIntegrityViolationException e) {
            Long appliedMeanwhile = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
            if (appliedMeanwhile != null) {
                return OperationResult.applied(operation.opId(), appliedMeanwhile);
            }
            log.warn("Sync operation {} violated a constraint", operation.opId(), e);
            return rejected(userId, operation, handler, ErrorCode.CONFLICT);
        }
    }

    private static OperationResult rejected(
            UUID userId, SyncOperation operation, SyncEntityHandler handler, ErrorCode code) {
        return OperationResult.rejected(operation.opId(), code.name(), handler.current(userId, operation.entityId()));
    }
}
```

`src/main/java/com/memox/sync/controller/SyncController.java`:

```java
package com.memox.sync.controller;

import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.PushResponse;
import com.memox.sync.service.SyncService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Server-sync protocol (ADR-013, spec §4). */
@RestController
@RequestMapping("/api/v1/sync")
@RequiredArgsConstructor
public class SyncController {

    static final int MAX_CHANGES = 500;

    private final SyncService syncService;

    @PostMapping("/push")
    public PushResponse push(@Valid @RequestBody PushRequest request) {
        return syncService.push(request);
    }

    @GetMapping("/changes")
    public ChangesResponse changes(
            @RequestParam @Min(0) long since,
            @RequestParam(defaultValue = "" + MAX_CHANGES) @Min(1) @Max(MAX_CHANGES) int limit) {
        return syncService.changesSince(since, limit);
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `./mvnw -B spotless:apply && ./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=SyncApiIT`
Expected: `Tests run: 6, Failures: 0, Errors: 0`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services/src
git commit -m "feat(api): sync push and changes endpoints with per-operation transactions and idempotency

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Spec amendments, docs and the full gate

**Files:**
- Modify: `docs/superpowers/specs/2026-09-27-server-sync-design.md`
- Modify: `memox-api-services/README.md`

- [ ] **Step 1: Amend the spec**

In §5, replace the "deck tree" row with:

```markdown
| deck tree | `root_id` and `depth` are **server-derived**: the server ignores the client's values, computes them from `parent_id`, and on a move rewrites the whole live subtree in the same transaction, so a client's per-row operations may arrive in any order. It rejects a cycle (`DECK_TREE_CYCLE`), a subtree that would pass 10 levels (`DECK_TREE_TOO_DEEP`), and a missing, deleted or foreign parent (`DECK_PARENT_MISSING`). The root shape (a root holds decks and owns the scheduler) is validated as `VALIDATION_FAILED` |
```

In §4.2, after the bullet starting with "`serverVersion` is a per-user sequence", add:

```markdown
- **One version per changed row.** A move or delete that touches a subtree allocates a block of versions, one per row, so a page boundary never splits the rows of one version and no change is skipped.
```

In §4.3, after the bullet "The outbox keeps at most one entry per `(entity_type, entity_id)`…", add:

```markdown
- A replaced entry keeps its original `created_at`, and push order is `created_at`. A parent created before its child is therefore always pushed first, even if the parent was edited later; otherwise the child would be rejected with `DECK_PARENT_MISSING`.
```

In §3, after the `CurrentUserProvider` bullet, add: `A user id sent by another user for an existing id is rejected with SYNC_ENTITY_CONFLICT and the other user's copy is never returned.`

- [ ] **Step 2: Document the API in the README**

In `memox-api-services/README.md`:

- In the package tree, add a line `├── sync/                       sync protocol (ADR-013)` directly above `└── common/`.
- In the `## Base` section, add after the **OpenAPI** bullet:

```markdown
- **Sync (ADR-013):** `POST /api/v1/sync/push` applies a batch of client
  operations idempotently (`opId`), each in its own transaction, and returns one
  `applied`/`rejected` result per operation (a rejection carries the server's
  copy as `current`). `GET /api/v1/sync/changes?since=&limit=` pages the user's
  changes by `serverVersion`. A synced table implements `SyncEntityHandler`;
  the owner always comes from `CurrentUserProvider` (a dev user until login,
  `MEMOX_DEV_USER_ID`).
```

- In the folder-contract table, add a row after `common/util`:

```markdown
| `common/security` | Who is calling | `CurrentUserProvider` and its implementations, security properties | feature logic | The owner of every row comes from here, never from a request. |
```

- [ ] **Step 3: Run the full gate**

Run: `./mvnw -B clean verify > ../verify.log 2>&1; grep -E "Tests run: [0-9]+, F[^-]*$|coverage checks|BUILD" ../verify.log`, then delete `../verify.log`; also `cd .. && python tools/docs/check.py | tail -1`.
Expected: surefire `Tests run: 57, Failures: 0` (56 + 1 `DevCurrentUserProviderTest`); failsafe `Tests run: 27, Failures: 0` (5 + 5 `SchemaIT` + 2 `SyncMappersIT` + 9 `DeckSyncHandlerIT` + 6 `SyncApiIT`); `All coverage checks have been met.`; `BUILD SUCCESS`; docs `PASS`.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-09-27-server-sync-design.md memox-api-services/README.md
git commit -m "docs: server-derived deck placement, one version per row, outbox order; sync API in the README

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
