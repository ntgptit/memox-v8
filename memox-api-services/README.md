# memox-api-services

The MemoX backend API: Spring Boot 3, Java 17, MyBatis, PostgreSQL.
Conventions and the review checklist live in the repo skill
[`spring-boot-mybatis-review`](../.claude/skills/spring-boot-mybatis-review/SKILL.md).

```bash
./mvnw verify
```

The gate also checks the format (palantir-java-format; fix it with
`./mvnw spotless:apply`) and line coverage of at least 80% (JaCoCo). CI runs
it in the `api` job.

## Package layout

Packages are grouped by domain first, then by layer. Each domain package has
the same name as its Flutter folder under `lib/features/`, including the
underscores (`starter_decks`, `study_mode`), so the app and the API can be
matched one to one. This is a deliberate deviation from the Java convention of
concatenated lowercase names (`starterdecks`), which the owner decided on.
Everything shared across features lives under `common`, including
`common.type_handler`, which follows the same snake_case naming.

```
src/main/java/com/memox/
├── <feature>/                  card, deck, progress, reminders, search, settings, srs,
│   ├── controller/             starter_decks, study, study_mode, tags, transfer, trash
│   ├── service/
│   │   └── impl/
│   ├── mapper/
│   ├── dto/
│   │   ├── request/
│   │   └── response/
│   ├── model/
│   └── enums/
└── common/                     shared API types (error body, paging)
    ├── config/
    ├── exception/
    ├── type_handler/
    └── util/
src/main/resources/
├── mapper/<feature>/           MyBatis XML, one file per mapper interface
└── db/migration/               Flyway migrations
```

Every package carries a `package-info.java` that states its responsibility.
Resource folders with no files yet carry a `.gitkeep`. The owner decided to
create every feature package up front, which is a recorded exception to the
repo rule "No speculative structure". Delete a feature package that turns out
to have no API.

## Base

The shared code in `com.memox.common` that every feature reuses.

- **Errors:** throw `new BusinessException(ErrorCode.SOME_CODE)`. A feature
  adds its codes to the `ErrorCode` enum after the generic ones, and adds
  their client-facing text to `messages.properties` as `error.<NAME>`.
  Every error response is RFC 9457 `application/problem+json` with a `code`
  property; validation errors add `errors: [{field, message}]`, and a
  database constraint violation is a 409 `CONFLICT`. `GlobalExceptionHandler`
  never returns SQL, constraint names or stack traces.
- **Paging:** a list endpoint takes a request that extends
  `PageQuery<TheSortEnum>` (zero-based `page`, `size` 1–100, default 20) and
  returns `PagingResponse.of(items, query, totalItems)`. Each constant of the
  sort enum maps to a whitelisted column in the feature's mapper XML.
- **Code enums:** an enum stored as a short code implements `CodeEnum` and
  gets a one-line `BaseEnumTypeHandler` subclass with
  `@MappedTypes(TheEnum.class)` in `common.type_handler`, the only package
  MyBatis scans for handlers.
- **Columns:** primary keys are `uuid` columns mapped to `java.util.UUID`
  (ADR-007); datetimes are `timestamptz` columns mapped to `java.time.Instant`,
  in UTC (ADR-008). Code that needs "now" injects the `Clock` bean.
- **Tests:** `./mvnw verify` runs the unit tests and the `*IT` integration
  tests against PostgreSQL 18 in Testcontainers, so Docker must be running.

## Folder contract

| Folder | Responsibility | Allowed contents | Forbidden contents | Notes |
|---|---|---|---|---|
| `<feature>/controller` | HTTP delivery | `@RestController`, `@Valid` request binding, response and status | business logic, SQL, Mapper calls, `@Transactional` | Calls the feature's Service only. |
| `<feature>/service` | Use-case contract | `XxxService` interfaces | implementations, HTTP types | The interface + impl pair is the project convention. |
| `<feature>/service/impl` | Business logic | `XxxServiceImpl`, `@Transactional` boundaries | HTTP types, SQL strings | Calls Mappers directly; no Repository wrapper. |
| `<feature>/mapper` | Database access | MyBatis `@Mapper` interfaces | business logic, object-to-DTO mapping classes | Methods such as `findDeckById` or `countActiveCards`. |
| `<feature>/dto/request` | Inbound HTTP contracts | `CreateXxxRequest`, `UpdateXxxRequest` with Bean Validation | persistence models, logic | Records preferred. |
| `<feature>/dto/response` | Outbound HTTP contracts | `XxxResponse`, `XxxDetailResponse`, query-result DTOs | persistence models, sensitive fields | Never return a model directly. |
| `<feature>/model` | Database row shapes | plain classes mapped by MyBatis | HTTP annotations, `@Data` on sensitive fields | Not used as a request or response type. |
| `<feature>/enums` | Finite feature values | enums with a DB `code` | magic strings | Needs a TypeHandler when the DB value differs from the name. |
| `common` | Cross-feature building blocks | shared API error body, paging request/response | feature logic | Only what at least two features use. |
| `common/config` | Spring and MyBatis configuration | `@Configuration`, security, OpenAPI, MyBatis settings | business logic | |
| `common/exception` | Error model and mapping | business exception types, `@RestControllerAdvice` | feature logic | Never exposes stack traces or SQL. |
| `common/type_handler` | Enum ↔ DB mapping | `BaseEnumTypeHandler` and one subclass per enum | business logic | Each handler is tested: enum→DB, DB→enum, NULL, unknown value. |
| `common/util` | Project-specific helpers | stateless helpers with no library equivalent | wrappers around Java, Apache Commons or Spring utilities; feature logic | Check the Java standard API, then Apache Commons, then Spring first. |
| `resources/mapper/<feature>` | SQL | MyBatis XML | SQL built in Java strings | The namespace is the mapper interface's fully qualified name. |
| `resources/db/migration` | Schema | Flyway `V<n>__<description>.sql` | changes to a migration that has already been applied | The schema holds PK, FK, UNIQUE, NOT NULL and CHECK constraints. |

Tests mirror the main packages and are added together with the code they test.
