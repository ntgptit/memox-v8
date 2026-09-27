# memox-api-services — foundation hardening

Status: approved 2026-09-27 · Path: architectural

## 1. Intent

The owner reviewed an outside proposal for an "application foundation": build
every cross-feature concern once so that a feature only adds its DTOs,
controller, service, mapper and SQL. Most of that proposal already exists on
`master` (PRs #97–#101). The review found three real gaps and one documentation
gap, and this spec closes all four:

1. The API is not checked by CI at all. `ci.yml` only runs Flutter jobs, and
   the project has no formatter, coverage gate or build enforcer.
2. Requests cannot be traced: logs carry no request ID and there is no
   per-request log line.
3. The JSON contract and the OpenAPI document are implicit. Nothing pins how
   dates, nulls and enums serialize, and the docs neither describe the error
   body nor can be switched off.
4. The "reuse the base first" rule and the other foundation conventions exist
   only in conversation.

Success means:

- the `CI gate` check fails when the API build, its tests, its format or its
  coverage fails;
- every log line written while serving a request, and every error body,
  carries that request's ID;
- the JSON shape of dates, nulls and enums is pinned by a test, and
  `/v3/api-docs` describes the error body and can be turned off by an
  environment variable;
- a reviewer using `spring-boot-mybatis-review` flags a feature that
  re-implements something the base provides.

Out of scope, with their triggers (section 6.2): authentication and
`CurrentUserProvider`, auditing columns, `commons-csv`, Spring profiles,
an HTTP client, shared integration-test annotations.

## 2. Decisions

| Topic | Decision | Why |
|---|---|---|
| Delivery | One spec, one plan with four independent tasks, one PR | Four small pieces; fewer review rounds |
| Formatter | Spotless 3.10.3 with palantir-java-format 2.99.0 and `removeUnusedImports` | Owner's choice. Verified on JDK 17: `check` runs, `apply` fixes, the result compiles and re-checks clean |
| Format phase | `spotless:check` bound to `verify` | `./mvnw test` stays fast while coding; the gate still fails on unformatted code |
| Reformat | All existing Java code is reformatted once, in a commit that contains nothing else | Keeps behavioural diffs reviewable |
| Coverage | JaCoCo 0.8.15, one agent for unit and integration tests, `check` at `verify`, bundle line ratio ≥ 0.80 | Owner's choice |
| Enforcer | `maven-enforcer-plugin` (managed by Boot, 3.5.0): Java ≥ 17, Maven ≥ 3.9, no duplicate dependency declarations | Cheap guard against a wrong toolchain |
| CI | New job `api`: `actions/setup-java@v6` (Temurin 17, Maven cache), `./mvnw -B verify` in `memox-api-services/`; `CI gate` needs it | The runner has Docker, so Testcontainers runs |
| JSON nulls | Keep Boot's default: null fields are written | Owner's choice; an explicit contract for the Dart models |
| Request ID | `X-Request-ID` header; MDC key `requestId`; also a `requestId` property on every error body | Lets the client quote the ID when reporting a failure |

## 3. CI and quality gate

### 3.1 `pom.xml`

- `spotless-maven-plugin` 3.10.3, `<java><palantirJavaFormat><version>2.99.0</version></palantirJavaFormat><removeUnusedImports/></java>`,
  with execution `check` at phase `verify`.
- `jacoco-maven-plugin` 0.8.15 with three executions:
  - `prepare-agent`, which sets `argLine`; surefire and failsafe both pick it
    up and append to one `jacoco.exec`;
  - `report` at `verify`;
  - `check` at `verify`: `BUNDLE`, `LINE`, `COVEREDRATIO`, minimum `0.80`.
- `lombok.config` at the project root with
  `lombok.addLombokGeneratedAnnotation = true`, so JaCoCo ignores the
  getters, setters and constructors Lombok generates.
- `maven-enforcer-plugin` (version from the Boot parent), execution `enforce`
  with `requireJavaVersion [17,)`, `requireMavenVersion [3.9,)`,
  `banDuplicatePomDependencyVersions`.
- Order inside `verify`: failsafe's `verify`, then `jacoco:check`, then
  `spotless:check`. Any failure fails the build.

### 3.2 `ci.yml`

```yaml
  api:
    name: api
    runs-on: ubuntu-latest
    timeout-minutes: 20
    defaults:
      run:
        working-directory: memox-api-services
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '17'
          cache: maven
      - name: verify
        run: ./mvnw -B verify
```

`ci-gate` changes to `needs: [gate, goldens, api]`. `WorkflowContractTest`
already requires `CI gate` to need every other job. A new test,
`test_the_api_job_runs_the_maven_gate`, requires the `api` job to contain
`./mvnw -B verify` and `working-directory: memox-api-services`.

### 3.3 Docs

CLAUDE.md's "Gate" bullet and the README gain one line each: fix the format
with `./mvnw spotless:apply`.

## 4. Request ID and request log

`common.config.RequestIdFilter extends OncePerRequestFilter`, registered at
`Ordered.HIGHEST_PRECEDENCE` so that it runs before Spring Security:

1. Read `X-Request-ID`. Keep it if it matches `[A-Za-z0-9._-]{1,64}`;
   otherwise, including when it is absent, use a new `UUID`. The pattern
   stops log injection: no CR, LF or spaces reach a log line.
2. `MDC.put("requestId", id)` and set the `X-Request-ID` response header.
3. Run the chain. In `finally`, log one line at `INFO`
   (`"{} {} -> {} in {} ms"`: method, URI without the query string, status,
   duration) and `MDC.remove("requestId")`.

`application.yml` adds `logging.pattern.correlation: "[%X{requestId:-}] "`,
which Boot 3.5's default console and file patterns include.
`RequestIdLoggingTest` proves it. If it fails, set `logging.pattern.level`
to `"%5p [%X{requestId:-}]"` instead.

`GlobalExceptionHandler.handleExceptionInternal` adds the property
`requestId` (the MDC value) to every `ProblemDetail`, when the MDC holds one.

Constants (`REQUEST_ID_HEADER`, `REQUEST_ID_MDC_KEY`, the pattern) live on
`RequestIdFilter`; the handler reads the MDC key from there. The filter lives
in `common.config`, whose README contract row gains "servlet filters".

## 5. JSON contract and OpenAPI

### 5.1 Jackson

No configuration beyond the existing `spring.jackson.time-zone: UTC`. The
contract, pinned by `JsonContractTest` (`@JsonTest`):

| Value | JSON |
|---|---|
| `Instant.parse("2026-09-27T01:02:03Z")` | `"2026-09-27T01:02:03Z"` |
| a `null` field | written as `null` |
| an enum | its constant name, never its DB code |
| `UUID` | canonical lowercase string |
| an unknown property in a request body | ignored (Boot default) |

The README's "Base" section states the same table.

### 5.2 OpenAPI

- `common.config.OpenApiConfig`: an `OpenAPI` bean with `Info` (title
  "MemoX API", version `v1`), plus an `OpenApiCustomizer` bean. The
  customizer registers the `ProblemDetail` schema, adding the `code`,
  `errors` and `requestId` properties. It then gives every operation a
  `default` response with content `application/problem+json` referencing
  that schema.
- `application.yml`: `springdoc.api-docs.enabled: ${API_DOCS_ENABLED:true}`
  and `springdoc.swagger-ui.enabled: ${API_DOCS_ENABLED:true}`.

## 6. Conventions (documentation only)

### 6.1 Skill `spring-boot-mybatis-review`

The skill has two copies that must stay identical: the repo copy under
`.claude/skills/` and the global copy under `~/.claude/skills/`. It changes
as follows:

- `SKILL.md`, review order: a first question, "Does this change re-implement
  something the base already provides? If the project documents its base, for
  example a README 'Base' or 'Foundation' section, check it before reviewing
  anything else." Re-implementing the base is a MEDIUM finding; duplicating
  exception handling or pagination is HIGH.
- `references/conventions.md`: `@ConfigurationProperties` records instead of
  scattered `@Value`.
- `references/mybatis-sql.md`: do not set `type-aliases-package` to the whole
  application package, because two classes with the same simple name stop
  the application from starting; use fully qualified names in mapper XML.

The `ErrorCode` watch point (reconsider the single enum once it passes about
50 constants) is specific to this repo, so it goes in the README, not the
skill.

Per `superpowers:writing-skills`, the skill edit is verified by a micro-test.
A fresh reviewer reviews a sample PR in which a feature ships its own paging
DTO and a `try/catch` returning `ResponseEntity` next to an existing base.
The test runs once with the old skill and once with the new, and it passes
when only the new skill flags the duplication.

### 6.2 README "Foundation" section

It lists what the base provides, with a pointer to each class, and what is
deliberately deferred:

| Deferred | Trigger |
|---|---|
| Authentication, `CurrentUserProvider` (UUID user id, ADR-007) | the auth spec (ADR-001: one user type) |
| Auditing columns | the first table, designed with the sync protocol: an offline-first client may own `updated_at` |
| `commons-csv` | the `transfer` API |
| Spring profiles, prod config | the first deployment |
| HTTP client convention | the first external integration |
| `@IntegrationTest`, shared fixtures | the second integration test |
| Revisit the single `ErrorCode` enum | about 50 constants |

## 7. Tests

| Test | Covers |
|---|---|
| `RequestIdFilterTest` (MockMvc on a probe controller, `@WithMockUser`) | a missing header yields a UUID in the response header; a valid inbound ID is echoed; an ID with CR/LF, spaces or 65+ characters is replaced; an error body carries `requestId` equal to the header |
| `RequestIdLoggingTest` (`@SpringBootTest` + `OutputCaptureExtension`) | the request log line and the correlation prefix contain the ID; the MDC is empty after the request |
| `JsonContractTest` (`@JsonTest`) | each row of the 5.1 table |
| `OpenApiDocsTest` (`@SpringBootTest` + MockMvc, `@WithMockUser`) | `/v3/api-docs` has the `ProblemDetail` schema with `code`, `errors` and `requestId`, and a probe operation's `default` response references it |
| `test_the_api_job_runs_the_maven_gate` (Python) | the CI job runs the Maven gate |
| Gate | `./mvnw -B clean verify` passes with format check, enforcer and coverage ≥ 80% |
