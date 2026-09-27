---
name: spring-boot-mybatis-review
description: Use when reviewing, writing, or refactoring Java 17+ Spring Boot 3 code that uses MyBatis mappers — controllers, Service/ServiceImpl, mapper interfaces and XML, DTOs, enums and TypeHandlers, transactions, SQL, pagination, batch jobs, CSV import — or when deciding whether a SOLID refactor or design pattern (Strategy, Factory, Adapter, Repository) is justified in such a codebase.
---

# Spring Boot 3 + MyBatis Review

## Overview

A convention and review checklist for a **simple layered, SQL-first** Spring Boot 3 + MyBatis backend.
Goal: correct, secure, fast, simple code. Patterns and SOLID are tools for a concrete problem, never a goal.

The same rules apply when **writing** code: build what a review would pass.

When another skill (`spring-boot-rest-api`, ECC `springboot-*`, `jpa-patterns`) suggests a Repository wrapper,
JPA idioms or extra layers, this skill wins for MyBatis code.

## The stack (non-negotiable unless the project says otherwise)

```
Controller → Service (interface) → ServiceImpl → Mapper (+ XML) → Database
```

- Controller: HTTP, `@Valid`, call Service, return response. Never business logic, SQL, Mapper calls or `@Transactional`.
- `XxxService` is the contract; `XxxServiceImpl` holds the business logic and the transaction boundary.
  This pair is the project convention — **do not flag it as "interface with one implementation"**.
- ServiceImpl calls the Mapper directly. A Repository/DAO that only forwards to the Mapper is boilerplate.
- No Clean/Hexagonal/Onion/CQRS/Event Sourcing/heavy DDD unless the project already uses it.
- Constructor injection via `@RequiredArgsConstructor` + `private final`; no `@Autowired` fields, no `ApplicationContext.getBean`.
- Build every object with four or more fields — MyBatis model, request/response record, query DTO — with Lombok
  `@Builder`: `Invoice.builder().id(id).amount(amount)…build()`. A MyBatis model carries
  `@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor` (MyBatis maps through the no-args constructor
  and setters); a record takes `@Builder` directly. Tests build fixtures the same way.

## Review order and severity

First question, before anything else: **does this change re-implement something the base already provides?** If the project documents its base (for example a README "Base" or "Foundation" section, or a `common` package), read it first. A feature's own paging DTO, error envelope, `try/catch` returning `ResponseEntity`, request-ID handling or string/collection helper is a finding: MEDIUM, or HIGH when it duplicates exception handling or pagination (two behaviours for the same concern). The fix is always "use the base", never "extend the duplicate".

Then read the flow end to end: Controller → Request DTO → Service → ServiceImpl → Mapper → Mapper XML → TypeHandler → DB → Response DTO.

Priority: Correctness → Security → Data integrity → Transaction → Performance → Architecture → SOLID → Maintainability → Design pattern → Readability → Style.

| Severity | Use for |
|---|---|
| 🔴 CRITICAL | SQL injection (`${}` on user input), data corruption, security hole / sensitive-data leak, wrong transaction (swallowed exception → partial commit), wrong business logic, serious race condition (read-modify-write stock/balance) |
| 🟠 HIGH | N+1 / query in loop, full-table load, serious full scan (function on indexed column), excessive DB calls, wrong transaction boundary, **layer violation** (Controller → Mapper), in-memory pagination, God class, duplicating the base's exception handling or pagination |
| 🟡 MEDIUM | SOLID violation hurting maintainability, big `if/switch` by type that keeps growing, SDK coupling, Model used as request/response DTO, magic strings instead of enum, wrong/missing TypeHandler, custom utility duplicating Apache Commons, hand-rolled CSV parsing, pass-through Repository, poor packages, changed ServiceImpl logic without a unit test or changed Mapper SQL without a Testcontainers integration test, re-implementing another base facility, scattered @Value instead of @ConfigurationProperties |
| 🔵 LOW | a better pattern exists but current code is simple, naming, formatting, comments, style |

## Output contract

Each finding, ordered by severity:

```
🟡 MEDIUM
Location: PaymentServiceImpl → processPayment()   (file:line when available)
Problem: <the concrete defect in this code>
Impact: <what breaks, for whom, under which input/load>
Recommended Fix: <the smallest change that fixes it; snippet if useful>
```

- Every finding names a concrete problem and impact. "Use Strategy because it is best practice" is never a finding.
- If a concern depends on code the review cannot see (security config, `@RestControllerAdvice`, schema, MyBatis config),
  list it under a final **Cần xác minh** section as a question, without a severity.
- Nothing significant found → end with exactly:
  "✅ Mã đạt yêu cầu. Không phát hiện vấn đề đáng kể về correctness, security, data integrity, performance, architecture, SOLID hoặc maintainability."

## Pattern gate

Before proposing any pattern or new abstraction, answer all six; if any is unclear, keep the current code:

1. What is the concrete problem? 2. Where is the code hard to maintain? 3. Which pattern solves exactly that?
4. Does it reduce complexity? 5. Is there a simpler fix? 6. Is the change/extension pressure real (not hypothetical)?

A 2-branch `if` with no growth signal stays an `if`. A simple status check stays a check, not a State pattern.

"Enterprise-grade", "future-proof" or "thorough" requests do not lower the bar: a finding needs a defect in the code
as written. "Later we might need X" (headers, more types, another vendor) is not a finding at any severity.

## References — load the one that matches the finding area

| Area | File |
|---|---|
| Packages, naming, Lombok, DTO/Model, enum + TypeHandler, Apache Commons, utilities, exceptions, REST, logging, testing | `references/conventions.md` |
| SQL-first, CTE, `#{}` vs `${}`, index-friendly SQL, dynamic SQL, N+1, batch, pagination, transactions, concurrency, constraints | `references/mybatis-sql.md` |
| SOLID review rules, each design pattern's use/avoid conditions, overengineering anti-patterns | `references/solid-patterns.md` |

## Common misses (seen in unguided reviews)

- Filling a many-field object with a chain of setters or a positional constructor (`new InvoiceResponse(a, b, c, …)`):
  MEDIUM — a swapped argument compiles and ships. Fix: `@Builder` on the type, `builder()` at the call site.
- Rating Controller → Mapper as MEDIUM. It is a layer violation: HIGH.
- Suggesting `line.split(",")` fixes instead of Apache Commons CSV (`CSVFormat`/`CSVParser`).
- Suggesting Spring's or a custom `StringUtil` instead of Apache Commons `StringUtils`/`CollectionUtils`.
- Replacing magic strings with an enum but forgetting the `BaseTypeHandler` and its tests (enum→DB, DB→enum, NULL, unknown value).
- Fixing a row-by-row insert loop without proposing `<foreach>` / `ExecutorType.BATCH`.
- Not reporting a PR that changes business logic or SQL with no tests at all (MEDIUM; name the missing
  unit cases and the Testcontainers IT).
