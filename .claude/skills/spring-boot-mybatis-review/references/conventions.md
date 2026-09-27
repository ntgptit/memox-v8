# Conventions — structure, types, libraries

## Contents
1. Packages
2. Naming and clean code
3. Lombok
4. DTO / Model
5. Enum + TypeHandler
6. Apache Commons and utilities
7. Exceptions and REST
8. Logging
9. Testing

## 1. Packages

Package by responsibility:

```
com.company.project
├── controller
├── service
│   └── impl
├── mapper
├── dto
│   ├── request
│   └── response
├── model
├── enums
├── typehandler
├── exception
├── config
├── util
└── common
```

Large projects may package by domain first (`user/{controller,service/impl,mapper,dto,model,enums}`, `payment/...`, `common`).

Flag vague packages: `misc`, `others`, `temp`, `helper2`, `common2`, `bean`, `object`.

## 2. Naming and clean code

- Intent-revealing names: `findPaymentHistory()`, `calculateTotalAmount()`, `customerId`, `paymentStatus`.
  Flag `getData()`, `process()`, `obj`, `tmp`, `val`.
- `UserService` / `UserServiceImpl` — no ad-hoc suffixes without a documented convention.
- Mapper methods: `findUserById`, `findUsersByCondition`, `countActiveUsers`, `insertUser`, `updateUserStatus`, `existsByEmail`.
  Flag `getData`, `query`, `process`.
- Guard clause, early return, fail fast, one main responsibility per method, shallow nesting, no magic number/string.

## 3. Lombok

Prefer `@Getter`, `@Setter`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`, `@RequiredArgsConstructor`, `@Slf4j`, `@Value`.

```java
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserMapper userMapper;
}
```

`@Data` generates getter, setter, `equals`, `hashCode`, `toString`. Flag it when the class has sensitive fields
(password, card number, token, phone — `toString()` leaks them into logs) or when generated equality/mutability is wrong
for the type. Use `@Getter`/`@Setter` + `@ToString(exclude = ...)` or a record/`@Value` instead.

## 4. DTO / Model

Separate types for separate jobs:

| Kind | Example |
|---|---|
| Request DTO | `CreateUserRequest`, `UpdateUserRequest` (with Bean Validation) |
| Response DTO | `UserResponse`, `UserDetailResponse` |
| Model (DB row) | `User` |
| Query result DTO | `UserSummaryDto` |
| Enum | `UserStatus` |

One class used for HTTP request + DB + business + HTTP response is a finding: mass assignment (client sets `id`,
`status`), sensitive columns serialized to the client, schema changes breaking the API.

Object mapping: a `builder()` in ServiceImpl is enough for trivial mapping; MapStruct only when large mappings repeat.
No pile of `Converter`/`Assembler` classes for trivial mapping.

## 5. Enum + TypeHandler

Finite values are enums, never magic strings in business logic:

```java
@Getter
@RequiredArgsConstructor
public enum UserStatus {
    ACTIVE("A"),
    INACTIVE("I"),
    DELETED("D");

    private final String code;
}
```

Enum with a custom DB value → MyBatis TypeHandler:

```java
@MappedTypes(UserStatus.class)
@MappedJdbcTypes(JdbcType.VARCHAR)
public class UserStatusTypeHandler extends BaseTypeHandler<UserStatus> { ... }
```

Several enums share the same code convention → one `BaseEnumTypeHandler<T extends Enum<T>> extends BaseTypeHandler<T>`
(e.g. enums implement a `CodeEnum` interface with `getCode()`), plus thin subclasses per enum.

Required tests per handler: enum → DB, DB → enum, `NULL`, unknown value, invalid value (expected exception).

## 6. Apache Commons and utilities

Order: Java standard API → Apache Commons → Spring utilities → custom utility.

| Need | Use |
|---|---|
| Strings, objects, booleans, numbers, arrays, argument checks | Commons Lang: `StringUtils`, `ObjectUtils`, `BooleanUtils`, `NumberUtils`, `ArrayUtils`, `Validate` |
| Collections, maps | Commons Collections: `CollectionUtils`, `MapUtils`, `ListUtils`, `SetUtils`, `IterableUtils` |
| CSV | Commons CSV: `CSVFormat`, `CSVParser`, `CSVRecord`, `CSVPrinter` |

- `StringUtils.isNotBlank(value)` over `value != null && !value.trim().isEmpty()`.
- `CollectionUtils.isNotEmpty(items)` over null + size checks.
- Never parse CSV with `line.split(",")`: it breaks on quoted commas, embedded newlines, headers, BOM and empty lines.
- Flag custom `StringUtil`, `CollectionUtil`, `CsvUtil`, `CommonUtil`, `Helper` that only wrap a library.
  A custom utility is allowed only for project-specific logic.

## 7. Exceptions and REST

- No `catch (Exception e) {}` or catch-and-log without rethrow — especially inside `@Transactional` (no rollback).
- Central `@RestControllerAdvice` maps business exceptions to HTTP status + safe message; never expose stack traces,
  SQL or internal class names.
- `@RestController`; HTTP method and status follow semantics: 201 on create, 404 when not found, 400 on validation,
  409 on conflict. Never `200 OK` with an empty object for "not found".
- `@Valid` on request DTOs; validate at the trust boundary.

## 8. Logging

- `@Slf4j`; never `System.out.println()`.
- Log with context (ids, counts, operation) and the exception object: `log.error("Failed to place order {}", orderId, e)`.
- Never log sensitive data (passwords, tokens, card numbers, full entities with PII via `toString()`).

## 9. Testing

JUnit 5, Mockito, Spring Boot Test, Testcontainers.

| Level | Scope |
|---|---|
| Unit | ServiceImpl with mocked Mappers — business rules, branches, exceptions |
| Integration | Mapper → MyBatis XML → real DB via Testcontainers (engine close to production) — SQL, result mapping, TypeHandlers, constraints |

Test behaviour, not internal structure. For patterns: Strategy (type A → A, type B → B, unknown → expected error),
Factory (right implementation, unsupported type handled), State (valid transition, invalid transition, per-state behaviour).
