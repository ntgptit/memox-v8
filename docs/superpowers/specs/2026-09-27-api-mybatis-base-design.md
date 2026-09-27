# memox-api-services — MyBatis and the common base

Status: approved 2026-09-27 · Path: architectural

## 1. Intent

`memox-api-services/` has a package skeleton but no persistence and no shared
code. Before the first feature endpoint, the project needs MyBatis wired to
PostgreSQL and a small `com.memox.common` base that every feature reuses: one
error format, one paging contract, enum and UUID mapping, and UTC time.

No feature package (`card`, `deck`, …) is touched.

Success means:

- `./mvnw verify` passes: unit tests plus integration tests against a real
  PostgreSQL started by Testcontainers;
- a mapper XML under `resources/mapper/**` is loaded, and UUID, code enums and
  `Instant` round-trip through PostgreSQL unchanged;
- every error response is an RFC 9457 `application/problem+json` body that
  carries a `code`, and none exposes a stack trace, SQL or class name;
- a feature can add a paged list endpoint, an error code, or a code enum
  without writing any new shared class.

## 2. Decisions

| Topic | Decision | Why |
|---|---|---|
| Error body | Spring `ProblemDetail` (RFC 9457), plus the properties `code` and, for validation, `errors` | Native to Spring 6; no custom envelope to maintain |
| Paging | `PageQuery<TSort>`, `SortSpec<TSort>`, `SortDirection`, `PagingResponse<T>` in the base now | Deck, card and search lists all need it |
| Test database | Testcontainers PostgreSQL; H2 removed | Same engine as production (CTE, window functions, `uuid`, `timestamptz`) |
| Primary keys | `java.util.UUID` in Java, native `uuid` column in PostgreSQL | ADR-007: keys are client-generated UUIDs; the native type is 16 bytes and indexes well. The API carries the canonical string form |
| Time | `Instant` in Java, `timestamptz` columns, JVM and Jackson in UTC | ADR-008: every datetime is stored in UTC |
| PostgreSQL | `postgres:18-alpine`, pinned in `compose.yaml` and in tests | `latest` makes dev and test drift |

## 3. Dependencies (`pom.xml`)

| Change | Artifact | Version |
|---|---|---|
| add | `org.mybatis.spring.boot:mybatis-spring-boot-starter` | 3.0.5 (the Boot 3 line; 4.x targets Boot 4) |
| add (test) | `org.mybatis.spring.boot:mybatis-spring-boot-starter-test` | 3.0.5 |
| add | `org.apache.commons:commons-lang3` | managed; `commons-lang3.version` raised to 3.20.0, because Boot 3.5.16 manages 3.17.0, which predates the CVE-2025-48924 fix |
| add | `org.apache.commons:commons-collections4` | 4.6.0 (not managed by Boot) |
| add (test) | `org.springframework.boot:spring-boot-testcontainers`, `org.testcontainers:postgresql`, `org.testcontainers:junit-jupiter` | managed by Boot |
| remove | `com.h2database:h2` | no remaining use |

## 4. Configuration (`application.yml`)

```yaml
spring:
  application:
    name: memox-api-services
  jackson:
    time-zone: UTC
  mvc:
    problemdetails:
      enabled: true

mybatis:
  mapper-locations: classpath:mapper/**/*.xml
  type-handlers-package: com.memox.common.type_handler
  configuration:
    map-underscore-to-camel-case: true
    default-statement-timeout: 30
```

- The datasource comes from `compose.yaml` through `spring-boot-docker-compose`
  in dev, and from `@ServiceConnection` in tests. No credentials in the yml.
- `MemoxApiServicesApplication.main` calls `TimeZone.setDefault(UTC)` before
  starting, so any `LocalDateTime` that slips in is still UTC.
- No `@MapperScan`: the starter registers every `@Mapper` interface under the
  application package.

## 5. Base code (`com.memox.common`)

### 5.1 Paging (`common`)

- `SortDirection { ASC, DESC }`.
- `SortSpec<TSort extends Enum<TSort>>`: `field` (`@NotNull`), `direction`
  (default `ASC`).
- `PageQuery<TSort extends Enum<TSort>>`: `page` (default 0, `@Min(0)`),
  `size` (default `DEFAULT_PAGE_SIZE` = 20, `@Min(1)`,
  `@Max(MAX_PAGE_SIZE)` = 100), `search` (`@Size(max = 200)`), `sorts`
  (`@Valid`, may be empty). `offset()` returns `(long) page * size` for SQL.
  A class with getters and setters, so feature search requests extend it and
  bind from query parameters.
- `PagingResponse<T>`: `items`, `page`, `size`, `totalItems`, `totalPages`,
  `hasNext`, `hasPrevious`. Built only through
  `PagingResponse.of(List<T> items, PageQuery<?> query, long totalItems)`,
  which derives the last four fields.
- The mapping from a sort enum to a SQL column stays in each feature
  (whitelisted `${}`), as the review skill requires.

### 5.2 Errors (`common.exception`)

- `ErrorCode` interface: `String code()`, `HttpStatus status()`. Feature
  enums implement it, for example `DeckErrorCode.DECK_NOT_FOUND`.
- `CommonErrorCode` enum, limited to what the handler below produces:
  `VALIDATION_FAILED` (400), `BAD_REQUEST` (400), `NOT_FOUND` (404),
  `METHOD_NOT_ALLOWED` (405), `DATA_CONFLICT` (409),
  `UNSUPPORTED_MEDIA_TYPE` (415), `INTERNAL_ERROR` (500). Its codes equal
  the constant names. Security errors (401, 403) are raised in filters,
  before the advice, and belong to the security spec.
- `BusinessException extends RuntimeException`: holds an `ErrorCode` and a
  client-safe `detail` message. It is the only exception class; the HTTP
  status comes from the code.
- `GlobalExceptionHandler extends ResponseEntityExceptionHandler`
  (`@RestControllerAdvice`):

| Exception | Status | `code` | Body extras |
|---|---|---|---|
| `BusinessException` | from its `ErrorCode` | from its `ErrorCode` | `detail` = the exception's detail |
| `MethodArgumentNotValidException`, `HandlerMethodValidationException` | 400 | `VALIDATION_FAILED` | `errors: [{field, message}]` |
| `ConstraintViolationException` | 400 | `VALIDATION_FAILED` | `errors: [{field, message}]` |
| `DataIntegrityViolationException` (includes `DuplicateKeyException`) | 409 | `DATA_CONFLICT` | generic detail; the cause is logged at `WARN`, never returned |
| any other Spring MVC exception handled by the parent | parent's status | the `CommonErrorCode` with that status (404, 405, 415); otherwise `BAD_REQUEST` for 4xx and `INTERNAL_ERROR` for 5xx | added in `handleExceptionInternal` |
| `Exception` | 500 | `INTERNAL_ERROR` | generic detail; logged at `ERROR` with the exception |

### 5.3 Type handlers (`common.type_handler`)

- `CodeEnum`: `String getCode()`; a feature enum with a database code
  implements it.
- `BaseEnumTypeHandler<E extends Enum<E> & CodeEnum> extends BaseTypeHandler<E>`:
  the constructor takes `Class<E>` and builds a code → constant map. It
  writes `getCode()` as a string and reads the string back. `NULL` maps to
  `null`, and an unknown code throws `IllegalArgumentException` naming the
  enum and the code. Each feature enum gets a one-line subclass with
  `@MappedTypes(TheEnum.class)` in `common.type_handler`, the only package
  `type-handlers-package` scans.
- `UuidTypeHandler extends BaseTypeHandler<UUID>`, `@MappedTypes(UUID.class)`,
  `@MappedJdbcTypes(value = JdbcType.OTHER, includeNullJdbcType = true)`:
  `setObject(i, uuid)` and `getObject(column, UUID.class)`, which the
  PostgreSQL driver maps to the `uuid` type.
- MyBatis's package scan skips the abstract `BaseEnumTypeHandler`.

### 5.4 Configuration (`common.config`)

- `TimeConfig`: a `Clock` bean, `Clock.systemUTC()`. Code that needs "now"
  injects the `Clock`, so it stays UTC and testable.
- Spring Security is out of scope (section 7).

## 6. Tests

| Test | Kind | Covers |
|---|---|---|
| `BaseEnumTypeHandlerTest` | unit, Mockito on JDBC | enum → DB, DB → enum, `NULL`, unknown code |
| `PageQueryTest` | unit, Bean Validation | defaults, `page < 0`, `size` 0 and above max, `offset()` |
| `PagingResponseTest` | unit | `totalPages`, `hasNext` and `hasPrevious` on the first, middle, last and empty pages |
| `GlobalExceptionHandlerTest` | `@WebMvcTest` with a test-only controller, security filters off | each row of the 5.2 table: status, `application/problem+json`, `code`, `errors`, no leaked SQL or stack trace |
| `MyBatisBaseIT` | `@MybatisTest` + Testcontainers PostgreSQL 18 | a test-only mapper and its XML under `src/test/resources/mapper/` are loaded; `UUID`, a code enum and `Instant` round-trip unchanged |
| `MemoxApiServicesApplicationTests` | `@SpringBootTest` + the shared `TestcontainersConfiguration` | the full context starts, Flyway included |

`TestcontainersConfiguration` (test root) declares one
`@ServiceConnection PostgreSQLContainer<?>` bean on `postgres:18-alpine`.
From now on the gate `./mvnw verify` needs a running Docker.

## 7. Out of scope

- **Spring Security.** The starter is on the classpath, so every endpoint is
  locked behind a generated password. Authentication needs its own spec.
- **Flyway `V1`.** The first table belongs to the first feature.
- **Feature code** in any feature package, and `common.util`, which stays empty.
- **Renaming the compose database, user and password** (`mydatabase`,
  `myuser`).

## 8. Documentation

`memox-api-services/README.md` gains a short "Base" section: the error
format, the paging contract, how a feature adds an `ErrorCode` or a code
enum, the `uuid`/`timestamptz` column rules, and that the gate needs Docker.
