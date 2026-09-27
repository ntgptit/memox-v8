# memox-api-services

The MemoX backend API: Spring Boot 3, Java 17, MyBatis, PostgreSQL.
Conventions and the review checklist live in the repo skill
[`spring-boot-mybatis-review`](../.claude/skills/spring-boot-mybatis-review/SKILL.md).

```bash
./mvnw verify
```

## Package layout

Packages are grouped by domain first, then by layer. Each domain package has
the same name as its Flutter folder under `lib/features/`, including the
underscores (`starter_decks`, `study_mode`), so the app and the API can be
matched one to one. This is a deliberate deviation from the Java convention of
concatenated lowercase names (`starterdecks`), which the owner decided on.

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
├── common/
├── config/
├── exception/
└── typehandler/
src/main/resources/
├── mapper/<feature>/           MyBatis XML, one file per mapper interface
└── db/migration/               Flyway migrations
```

Every package carries a `package-info.java` that states its responsibility.
Resource folders with no files yet carry a `.gitkeep`. The owner decided to
create every feature package up front, which is a recorded exception to the
repo rule "No speculative structure". Delete a feature package that turns out
to have no API.

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
| `config` | Spring and MyBatis configuration | `@Configuration`, security, OpenAPI, MyBatis settings | business logic | |
| `exception` | Error model and mapping | business exception types, `@RestControllerAdvice` | feature logic | Never exposes stack traces or SQL. |
| `typehandler` | Enum ↔ DB mapping | `BaseEnumTypeHandler` and one subclass per enum | business logic | Each handler is tested: enum→DB, DB→enum, NULL, unknown value. |
| `resources/mapper/<feature>` | SQL | MyBatis XML | SQL built in Java strings | The namespace is the mapper interface's fully qualified name. |
| `resources/db/migration` | Schema | Flyway `V<n>__<description>.sql` | changes to a migration that has already been applied | The schema holds PK, FK, UNIQUE, NOT NULL and CHECK constraints. |

No `util` package: use the Java standard API, then Apache Commons, then Spring.
Add project-specific helpers only when no library provides them. Tests mirror
the main packages and are added together with the code they test.
