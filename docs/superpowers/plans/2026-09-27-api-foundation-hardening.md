# memox-api-services Foundation Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the four foundation gaps in `memox-api-services`: a CI and quality gate, request IDs in logs and error bodies, a pinned JSON and OpenAPI contract, and the written "reuse the base first" conventions.

**Architecture:** Build plugins (Spotless with palantir, JaCoCo, Enforcer) bound to `verify`, plus a new `api` job in `ci.yml`. A `RequestIdFilter` in `common.config` feeds the MDC, which both the log pattern and `GlobalExceptionHandler` read. `OpenApiConfig` in `common.config` documents the error body. Skill and README edits carry the conventions.

**Tech Stack:** Java 17, Spring Boot 3.5.16, springdoc 2.9.1, Spotless 3.10.3, palantir-java-format 2.99.0, JaCoCo 0.8.15, maven-enforcer-plugin 3.5.0 (Boot-managed), GitHub Actions, Python `unittest`.

**Spec:** `docs/superpowers/specs/2026-09-27-api-foundation-hardening-design.md`

## Global Constraints

- Maven commands run from `memox-api-services/` (`./mvnw`; `.\mvnw.cmd` in PowerShell). The gate is `./mvnw -B verify`, and it needs Docker.
- From Task 1 on, Java code follows palantir-java-format: 4-space indentation, 120 columns. Run `./mvnw spotless:apply` before every commit that touches Java.
- Versions: Spotless 3.10.3, palantir-java-format 2.99.0, JaCoCo 0.8.15, `actions/setup-java@v6`, Temurin 17.
- Coverage: bundle `LINE` `COVEREDRATIO` ≥ `0.80`.
- Request ID: header `X-Request-ID`, MDC key `requestId`, accepted pattern `[A-Za-z0-9._-]{1,64}`, error-body property `requestId`.
- JSON: Boot defaults, with nulls written, ISO-8601 UTC instants, enums by name and unknown properties ignored. Do not add Jackson configuration.
- OpenAPI: title `MemoX API`, version `v1`, schema name `ProblemDetail`, and every operation gets a `default` response with `application/problem+json`. Docs are switched by `${API_DOCS_ENABLED:true}`.
- Test probe endpoints live under `/probe/**`, never `/test/**`: `GlobalExceptionHandlerTests` owns `/test/**`, and a full-context test scans every test controller.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- A client sends an `X-Request-ID` carrying CR/LF or a space, trying to forge a log line. The ID must be replaced, never logged. The test is in Task 2.
- A request fails inside the controller. The error body's `requestId` must equal the response header, so a user can quote it. The test is in Task 2.
- The MDC leaks between requests on a pooled thread. It must be empty after every request. The test is in Task 2.
- Production sets `API_DOCS_ENABLED=false`, and `/v3/api-docs` must then stop answering. The test is in Task 3.
- A formatting-only or coverage-only regression must fail `./mvnw verify` (and so CI), not pass silently. Tested in Task 1 by running the gate on unformatted code and watching it fail.

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `memox-api-services/pom.xml` | 1 | Spotless, JaCoCo, Enforcer |
| `memox-api-services/lombok.config` | 1 | mark Lombok code as generated, for JaCoCo |
| every `memox-api-services/src/**/*.java` | 1 | one-off reformat, in its own commit |
| `.github/workflows/ci.yml` | 1 | `api` job; `CI gate` needs it |
| `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | 1 | contract test for the `api` job |
| `CLAUDE.md` | 1 | gate bullet: `spotless:apply` |
| `src/main/java/com/memox/common/config/RequestIdFilter.java` | 2 | request ID, MDC, request log line |
| `src/main/java/com/memox/common/exception/GlobalExceptionHandler.java` | 2 | `requestId` on every error body |
| `src/main/resources/application.yml` | 2, 3 | correlation pattern; springdoc switch |
| `src/test/java/com/memox/common/config/WebProbeController.java` | 2 | test-only `/probe/**` endpoints |
| `src/test/java/com/memox/common/config/RequestIdFilterTest.java` | 2 | filter behaviour and log line |
| `src/main/java/com/memox/common/config/OpenApiConfig.java` | 3 | API info, `ProblemDetail` schema, `default` responses |
| `src/test/java/com/memox/common/config/OpenApiDocsTest.java` | 3 | api-docs content |
| `src/test/java/com/memox/common/config/OpenApiDocsDisabledTest.java` | 3 | kill switch |
| `src/test/java/com/memox/common/JsonContractTest.java` | 3 | JSON contract pin |
| `.claude/skills/spring-boot-mybatis-review/{SKILL.md,references/conventions.md,references/mybatis-sql.md}` (and the global copy) | 4 | conventions |
| `memox-api-services/README.md` | 1–4 | gate line, Base bullets, contract row, Foundation section |

(Paths starting with `src/` are under `memox-api-services/`.)

---

### Task 1: Quality gate and CI job

**Files:**
- Modify: `memox-api-services/pom.xml`
- Create: `memox-api-services/lombok.config`
- Modify (reformat only): every `memox-api-services/src/**/*.java`
- Modify: `.github/workflows/ci.yml`
- Test: `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`
- Modify: `CLAUDE.md`, `memox-api-services/README.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `./mvnw -B verify` fails on unformatted code, on coverage below 0.80 and on the wrong toolchain; `./mvnw spotless:apply` fixes the format; the `api` CI job.

- [ ] **Step 1: Write the failing CI contract test**

In `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`, inside `class WorkflowContractTest`, directly after the method `test_the_goldens_job_compares_the_pictures_and_counts_them`, add:

```python
    def test_the_api_job_runs_the_maven_gate(self) -> None:
        """The backend is checked on every run: unit and integration tests
        against PostgreSQL, format and coverage, all behind `./mvnw verify`."""
        _, jobs = self._workflow()
        self.assertIn("api", jobs, "no job verifies memox-api-services")
        api = jobs["api"]
        self.assertIn("working-directory: memox-api-services", api)
        self.assertIn("./mvnw -B verify", api)
```

- [ ] **Step 2: Run it to verify it fails**

Run (repo root): `python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p test_ci_tooling.py -k WorkflowContractTest -v`
Expected: `test_the_api_job_runs_the_maven_gate ... FAIL` with `no job verifies memox-api-services`; the other `WorkflowContractTest` tests pass.

- [ ] **Step 3: Add the `api` job and make `CI gate` need it**

In `.github/workflows/ci.yml`, insert directly before the line `  ci-gate:`:

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

      # Unit tests, integration tests against PostgreSQL in Testcontainers
      # (the runner has Docker), format, coverage and the build enforcer.
      - name: verify
        run: ./mvnw -B verify

```

and change `    needs: [gate, goldens]` to `    needs: [gate, goldens, api]`.

- [ ] **Step 4: Run the contract tests to verify they pass**

Run: `python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p test_ci_tooling.py -k WorkflowContractTest -v`
Expected: every `WorkflowContractTest` test `ok`, including `test_ci_gate_judges_every_other_job_whatever_happened_to_it` and `test_the_api_job_runs_the_maven_gate`.

- [ ] **Step 5: Add the quality plugins**

In `memox-api-services/pom.xml`, in `<properties>` after `<commons-lang3.version>3.20.0</commons-lang3.version>`, add:

```xml
		<spotless.version>3.10.3</spotless.version>
		<palantir-java-format.version>2.99.0</palantir-java-format.version>
		<jacoco-maven-plugin.version>0.8.15</jacoco-maven-plugin.version>
		<jacoco.line-coverage.minimum>0.80</jacoco.line-coverage.minimum>
```

In `<build><plugins>`, directly after the `maven-failsafe-plugin` plugin, add. The order is deliberate: inside `verify`, failsafe's check runs first, then coverage, then format.

```xml
			<plugin>
				<groupId>org.jacoco</groupId>
				<artifactId>jacoco-maven-plugin</artifactId>
				<version>${jacoco-maven-plugin.version}</version>
				<executions>
					<!-- Sets argLine; surefire and failsafe both append to target/jacoco.exec. -->
					<execution>
						<id>prepare-agent</id>
						<goals>
							<goal>prepare-agent</goal>
						</goals>
					</execution>
					<execution>
						<id>report</id>
						<phase>verify</phase>
						<goals>
							<goal>report</goal>
						</goals>
					</execution>
					<execution>
						<id>check</id>
						<phase>verify</phase>
						<goals>
							<goal>check</goal>
						</goals>
						<configuration>
							<rules>
								<rule>
									<element>BUNDLE</element>
									<limits>
										<limit>
											<counter>LINE</counter>
											<value>COVEREDRATIO</value>
											<minimum>${jacoco.line-coverage.minimum}</minimum>
										</limit>
									</limits>
								</rule>
							</rules>
						</configuration>
					</execution>
				</executions>
			</plugin>
			<plugin>
				<groupId>com.diffplug.spotless</groupId>
				<artifactId>spotless-maven-plugin</artifactId>
				<version>${spotless.version}</version>
				<configuration>
					<java>
						<palantirJavaFormat>
							<version>${palantir-java-format.version}</version>
						</palantirJavaFormat>
						<removeUnusedImports/>
					</java>
				</configuration>
				<executions>
					<!-- At verify, not validate: ./mvnw test stays fast while coding; the gate still fails. -->
					<execution>
						<id>spotless-check</id>
						<phase>verify</phase>
						<goals>
							<goal>check</goal>
						</goals>
					</execution>
				</executions>
			</plugin>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-enforcer-plugin</artifactId>
				<executions>
					<execution>
						<id>enforce</id>
						<goals>
							<goal>enforce</goal>
						</goals>
						<configuration>
							<rules>
								<requireJavaVersion>
									<version>[17,)</version>
								</requireJavaVersion>
								<requireMavenVersion>
									<version>[3.9,)</version>
								</requireMavenVersion>
								<banDuplicatePomDependencyVersions/>
							</rules>
						</configuration>
					</execution>
				</executions>
			</plugin>
```

Create `memox-api-services/lombok.config`:

```
config.stopBubbling = true
# JaCoCo skips @lombok.Generated code, so getters and setters do not count against coverage.
lombok.addLombokGeneratedAnnotation = true
```

- [ ] **Step 6: Run the gate to watch the format check fail**

Run: `./mvnw -B verify > target-verify.log 2>&1; tail -20 target-verify.log`, then delete `target-verify.log`.
Expected: the tests pass and `BUILD FAILURE` with `spotless-maven-plugin:3.10.3:check (spotless-check)` and "The following files had format violations". The existing code is tab-indented, so this proves an unformatted change fails the gate.

- [ ] **Step 7: Reformat everything, in a commit of its own**

Run: `./mvnw -B spotless:apply`
Then: `git diff --stat -- memox-api-services/src | tail -1` (only `.java` files) and commit **only** the Java files:

```bash
git add memox-api-services/src
git commit -m "style(api): reformat with palantir-java-format

Formatting only, produced by ./mvnw spotless:apply; no behaviour change.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 8: Run the full gate to verify it passes**

Run: `./mvnw -B clean verify > target-verify.log 2>&1; grep -E "Tests run: [0-9]+, F[^-]*$|All coverage checks|Coverage checks have not been met|BUILD" target-verify.log`, then read the line coverage in `target/site/jacoco/index.html`: `grep -o 'Total[^%]*%[^%]*%' target/site/jacoco/index.html`.
Expected: surefire `Tests run: 38`, failsafe `Tests run: 5`, `All coverage checks have been met.`, `BUILD SUCCESS`. If coverage is below 0.80, stop and report the measured value: do **not** lower the threshold on your own, because the owner chose it.

- [ ] **Step 9: Document the format command**

In `CLAUDE.md`, change the bullet

```
- **Gate:** `./mvnw verify` from `memox-api-services/` (`mvnw.cmd verify` in
  PowerShell). The Flutter gates (`dod_check.sh`, `flutter test`) do not cover
  it, and it does not cover the app.
```

to

```
- **Gate:** `./mvnw verify` from `memox-api-services/` (`mvnw.cmd verify` in
  PowerShell): tests, format (palantir-java-format; fix with
  `./mvnw spotless:apply`) and line coverage ≥ 80%. CI runs it in the `api`
  job. The Flutter gates (`dod_check.sh`, `flutter test`) do not cover it, and
  it does not cover the app.
```

In `memox-api-services/README.md`, directly after the fenced block containing `./mvnw verify` (near the top), add:

```markdown
The gate also checks the format (palantir-java-format; fix it with
`./mvnw spotless:apply`) and line coverage of at least 80% (JaCoCo). CI runs
it in the `api` job.
```

- [ ] **Step 10: Commit**

```bash
git add memox-api-services/pom.xml memox-api-services/lombok.config .github/workflows/ci.yml .claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py CLAUDE.md memox-api-services/README.md
git commit -m "build(api): format, coverage and enforcer in the gate; api job in CI

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Request ID in logs and error bodies

**Files:**
- Create: `src/main/java/com/memox/common/config/RequestIdFilter.java`
- Modify: `src/main/java/com/memox/common/exception/GlobalExceptionHandler.java`
- Modify: `src/main/resources/application.yml`
- Test: `src/test/java/com/memox/common/config/WebProbeController.java`
- Test: `src/test/java/com/memox/common/config/RequestIdFilterTest.java`
- Modify: `memox-api-services/README.md`

**Interfaces:**
- Consumes: Task 1's formatter; `com.memox.TestcontainersConfiguration`; `BusinessException(ErrorCode)` and `ErrorCode.CONFLICT` (from #100).
- Produces: `RequestIdFilter.REQUEST_ID_HEADER = "X-Request-ID"`, `RequestIdFilter.REQUEST_ID_MDC_KEY = "requestId"`; test controller `WebProbeController` with `GET /probe/ping` → `"pong"` and `GET /probe/conflict` → `BusinessException(ErrorCode.CONFLICT)`; error bodies gain `requestId`.

- [ ] **Step 1: Write the probe controller and the failing test**

Create `src/test/java/com/memox/common/config/WebProbeController.java`:

```java
package com.memox.common.config;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Test-only endpoints for the full-context web tests. The paths stay under {@code /probe} because component scanning
 * puts this controller in every full-context test.
 */
@RestController
@RequestMapping("/probe")
public class WebProbeController {

    @GetMapping("/ping")
    public String ping() {
        return "pong";
    }

    @GetMapping("/conflict")
    public void conflict() {
        throw new BusinessException(ErrorCode.CONFLICT);
    }
}
```

Create `src/test/java/com/memox/common/config/RequestIdFilterTest.java`:

```java
package com.memox.common.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.memox.TestcontainersConfiguration;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@WithMockUser
@Import(TestcontainersConfiguration.class)
@ExtendWith(OutputCaptureExtension.class)
class RequestIdFilterTest {

    private static final Pattern UUID_PATTERN =
            Pattern.compile("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}");

    @Autowired
    private MockMvc mockMvc;

    @Test
    void missingHeaderGetsAGeneratedUuid() throws Exception {
        String id = mockMvc.perform(get("/probe/ping"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getHeader(RequestIdFilter.REQUEST_ID_HEADER);

        assertThat(id).matches(UUID_PATTERN);
    }

    @Test
    void validInboundIdIsEchoed() throws Exception {
        mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, "client-42_a.B"))
                .andExpect(header().string(RequestIdFilter.REQUEST_ID_HEADER, "client-42_a.B"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"has space", "forged\r\nINFO fake line", "semi;colon", ""})
    void unsafeInboundIdIsReplaced(String inbound) throws Exception {
        String id = mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, inbound))
                .andReturn()
                .getResponse()
                .getHeader(RequestIdFilter.REQUEST_ID_HEADER);

        assertThat(id).matches(UUID_PATTERN);
    }

    @Test
    void tooLongInboundIdIsReplaced() throws Exception {
        String id = mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, "a".repeat(65)))
                .andReturn()
                .getResponse()
                .getHeader(RequestIdFilter.REQUEST_ID_HEADER);

        assertThat(id).matches(UUID_PATTERN);
    }

    @Test
    void errorBodyCarriesTheRequestId() throws Exception {
        mockMvc.perform(get("/probe/conflict").header(RequestIdFilter.REQUEST_ID_HEADER, "req-conflict-1"))
                .andExpect(status().isConflict())
                .andExpect(header().string(RequestIdFilter.REQUEST_ID_HEADER, "req-conflict-1"))
                .andExpect(jsonPath("$.requestId").value("req-conflict-1"));
    }

    @Test
    void requestLogLineCarriesTheIdAndTheMdcIsClearedAfterwards(CapturedOutput output) throws Exception {
        mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, "req-log-1"));

        assertThat(output.getOut()).contains("[req-log-1] ").contains("GET /probe/ping -> 200 in ");
        assertThat(MDC.get(RequestIdFilter.REQUEST_ID_MDC_KEY)).isNull();
    }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B test -Dtest=RequestIdFilterTest`
Expected: COMPILATION ERROR, `cannot find symbol: variable RequestIdFilter` (or `class RequestIdFilter`).

- [ ] **Step 3: Implement the filter**

Create `src/main/java/com/memox/common/config/RequestIdFilter.java`:

```java
package com.memox.common.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Gives every request an ID, in the MDC (so every log line carries it), in the response header and in error bodies,
 * and logs one line per request. Runs before Spring Security so that its log lines carry the ID too.
 */
@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {

    public static final String REQUEST_ID_HEADER = "X-Request-ID";

    public static final String REQUEST_ID_MDC_KEY = "requestId";

    /** No CR, LF or spaces: an inbound ID must not be able to forge a log line. */
    private static final Pattern ACCEPTED_REQUEST_ID = Pattern.compile("[A-Za-z0-9._-]{1,64}");

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String requestId = requestIdOf(request);
        long startNanos = System.nanoTime();
        MDC.put(REQUEST_ID_MDC_KEY, requestId);
        response.setHeader(REQUEST_ID_HEADER, requestId);
        try {
            chain.doFilter(request, response);
        } finally {
            long durationMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startNanos);
            log.info(
                    "{} {} -> {} in {} ms",
                    request.getMethod(),
                    request.getRequestURI(),
                    response.getStatus(),
                    durationMillis);
            MDC.remove(REQUEST_ID_MDC_KEY);
        }
    }

    private static String requestIdOf(HttpServletRequest request) {
        String inbound = request.getHeader(REQUEST_ID_HEADER);
        if (inbound != null && ACCEPTED_REQUEST_ID.matcher(inbound).matches()) {
            return inbound;
        }
        return UUID.randomUUID().toString();
    }
}
```

In `src/main/resources/application.yml`, add at the end:

```yaml

logging:
  pattern:
    # Boot's default console and file patterns include this slot; see RequestIdFilter.
    correlation: "[%X{requestId:-}] "
```

In `GlobalExceptionHandler.java`, add the import `import com.memox.common.config.RequestIdFilter;` and `import org.slf4j.MDC;`, add the constant next to `ERRORS_PROPERTY`:

```java
    private static final String REQUEST_ID_PROPERTY = "requestId";
```

and in `handleExceptionInternal`, directly after the line `problem.setProperty(CODE_PROPERTY, code.name());`, add:

```java
        String requestId = MDC.get(RequestIdFilter.REQUEST_ID_MDC_KEY);
        if (requestId != null) {
            problem.setProperty(REQUEST_ID_PROPERTY, requestId);
        }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `./mvnw -B spotless:apply && ./mvnw -B test -Dtest='RequestIdFilterTest,GlobalExceptionHandlerTests'`
Expected: `RequestIdFilterTest` `Tests run: 9, Failures: 0, Errors: 0` and `GlobalExceptionHandlerTests` `Tests run: 10, Failures: 0, Errors: 0`. If only `requestLogLineCarriesTheIdAndTheMdcIsClearedAfterwards` fails on the `[req-log-1] ` prefix, the correlation slot is not in this Boot version's default pattern. Replace the `logging.pattern.correlation` entry with `logging.pattern.level: "%5p [%X{requestId:-}]"`, re-run, and ledger the ruling.

- [ ] **Step 5: Document**

In `memox-api-services/README.md`, in the `## Base` section, add a bullet after the **Errors** bullet:

```markdown
- **Request ID:** every request gets an `X-Request-ID` (the client's own, if
  it matches `[A-Za-z0-9._-]{1,64}`, otherwise a new UUID). It is echoed in the
  response header, prefixed to every log line as `[id]`, and returned as
  `requestId` in every error body. One `INFO` line per request logs method,
  path, status and duration.
```

In the folder-contract table, change the `common/config` row's allowed contents from `` `@Configuration`, security, OpenAPI, MyBatis settings `` to `` `@Configuration`, servlet filters, security, OpenAPI, MyBatis settings ``.

- [ ] **Step 6: Commit**

```bash
git add memox-api-services/src/main/java/com/memox/common/config/RequestIdFilter.java memox-api-services/src/main/java/com/memox/common/exception/GlobalExceptionHandler.java memox-api-services/src/main/resources/application.yml memox-api-services/src/test/java/com/memox/common/config memox-api-services/README.md
git commit -m "feat(api): request ID in the MDC, response header, error body and a request log line

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: JSON contract and OpenAPI document

**Files:**
- Test: `src/test/java/com/memox/common/JsonContractTest.java`
- Create: `src/main/java/com/memox/common/config/OpenApiConfig.java`
- Modify: `src/main/resources/application.yml`
- Test: `src/test/java/com/memox/common/config/OpenApiDocsTest.java`
- Test: `src/test/java/com/memox/common/config/OpenApiDocsDisabledTest.java`
- Modify: `memox-api-services/README.md`

**Interfaces:**
- Consumes: Task 2's `WebProbeController` (`GET /probe/ping`); `com.memox.common.type_handler.SampleStatus` (test enum, `ACTIVE("A")`); `TestcontainersConfiguration`.
- Produces: `OpenApiConfig` beans `memoxOpenApi()` (`OpenAPI`) and `problemDetailResponses()` (`OpenApiCustomizer`); constant `OpenApiConfig.PROBLEM_DETAIL_SCHEMA = "ProblemDetail"`.

- [ ] **Step 1: Pin the JSON contract**

Create `src/test/java/com/memox/common/JsonContractTest.java`:

```java
package com.memox.common;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.type_handler.SampleStatus;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.json.JsonTest;

/**
 * Pins the JSON contract the Flutter client relies on. These are Boot's defaults plus {@code spring.jackson.time-zone:
 * UTC}; a failure here means a configuration change broke the API contract.
 */
@JsonTest
class JsonContractTest {

    record Sample(Instant at, String nickname, SampleStatus status, UUID id) {}

    record Named(String name) {}

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void writesIsoUtcInstantsNullsEnumNamesAndCanonicalUuids() throws Exception {
        Sample sample = new Sample(
                Instant.parse("2026-09-27T01:02:03Z"),
                null,
                SampleStatus.ACTIVE,
                UUID.fromString("0F8FAD5B-D9CB-469F-A165-70867728950E"));

        assertThat(objectMapper.writeValueAsString(sample))
                .isEqualTo("{\"at\":\"2026-09-27T01:02:03Z\",\"nickname\":null,\"status\":\"ACTIVE\","
                        + "\"id\":\"0f8fad5b-d9cb-469f-a165-70867728950e\"}");
    }

    @Test
    void ignoresUnknownProperties() throws Exception {
        Named named = objectMapper.readValue("{\"name\":\"deck\",\"addedByANewerClient\":1}", Named.class);

        assertThat(named.name()).isEqualTo("deck");
    }
}
```

- [ ] **Step 2: Run it (characterization: it passes first time)**

Run: `./mvnw -B test -Dtest=JsonContractTest`
Expected: `Tests run: 2, Failures: 0, Errors: 0`. This test pins the existing Boot defaults, as the spec decided ("no configuration"), so there is no RED step. To prove it can fail, temporarily add `spring.jackson.default-property-inclusion: non_null` to `application.yml`, re-run and watch `writesIsoUtcInstantsNullsEnumNamesAndCanonicalUuids` FAIL, then remove the line.

- [ ] **Step 3: Write the failing OpenAPI tests**

Create `src/test/java/com/memox/common/config/OpenApiDocsTest.java`:

```java
package com.memox.common.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.memox.TestcontainersConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@WithMockUser
@Import(TestcontainersConfiguration.class)
class OpenApiDocsTest {

    private static final String PROBLEM_REF = "#/components/schemas/ProblemDetail";

    @Autowired
    private MockMvc mockMvc;

    @Test
    void documentsTheApiAndTheErrorBody() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.info.title").value("MemoX API"))
                .andExpect(jsonPath("$.info.version").value("v1"))
                .andExpect(jsonPath("$.components.schemas.ProblemDetail.properties.code.type")
                        .value("string"))
                .andExpect(jsonPath("$.components.schemas.ProblemDetail.properties.requestId.type")
                        .value("string"))
                .andExpect(jsonPath("$.components.schemas.ProblemDetail.properties.errors.type")
                        .value("array"));
    }

    @Test
    void everyOperationDocumentsTheProblemResponse() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(jsonPath("$.paths['/probe/ping'].get.responses.default.content['application/problem+json']"
                                + ".schema.$ref")
                        .value(PROBLEM_REF));
    }
}
```

Create `src/test/java/com/memox/common/config/OpenApiDocsDisabledTest.java`:

```java
package com.memox.common.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.memox.TestcontainersConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

/** Production sets API_DOCS_ENABLED=false; the docs must then be gone. */
@SpringBootTest(properties = "API_DOCS_ENABLED=false")
@AutoConfigureMockMvc
@WithMockUser
@Import(TestcontainersConfiguration.class)
class OpenApiDocsDisabledTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void apiDocsAreNotServed() throws Exception {
        mockMvc.perform(get("/v3/api-docs")).andExpect(status().isNotFound());
    }
}
```

- [ ] **Step 4: Run them to verify they fail**

Run: `./mvnw -B test -Dtest='OpenApiDocsTest,OpenApiDocsDisabledTest'`
Expected: `documentsTheApiAndTheErrorBody` FAILS on `$.info.title` (springdoc's default title is "OpenAPI definition"); `everyOperationDocumentsTheProblemResponse` FAILS (no `default` response); `apiDocsAreNotServed` FAILS with status 200 (the switch does not exist yet).

- [ ] **Step 5: Implement**

Create `src/main/java/com/memox/common/config/OpenApiConfig.java`:

```java
package com.memox.common.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.ArraySchema;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.IntegerSchema;
import io.swagger.v3.oas.models.media.ObjectSchema;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;

/**
 * The OpenAPI document: API info, and the RFC 9457 error body that {@code GlobalExceptionHandler} returns, as every
 * operation's {@code default} response.
 */
@Configuration(proxyBeanMethods = false)
public class OpenApiConfig {

    public static final String PROBLEM_DETAIL_SCHEMA = "ProblemDetail";

    private static final String API_TITLE = "MemoX API";

    private static final String API_VERSION = "v1";

    private static final String DEFAULT_RESPONSE = "default";

    private static final String SCHEMA_REF_PREFIX = "#/components/schemas/";

    @Bean
    public OpenAPI memoxOpenApi() {
        return new OpenAPI().info(new Info().title(API_TITLE).version(API_VERSION));
    }

    @Bean
    public OpenApiCustomizer problemDetailResponses() {
        return openApi -> {
            if (openApi.getComponents() == null) {
                openApi.setComponents(new Components());
            }
            openApi.getComponents().addSchemas(PROBLEM_DETAIL_SCHEMA, problemDetailSchema());
            if (openApi.getPaths() == null) {
                return;
            }
            openApi.getPaths().values().stream()
                    .flatMap(pathItem -> pathItem.readOperations().stream())
                    .filter(operation -> operation.getResponses() != null)
                    .forEach(operation -> operation.getResponses().addApiResponse(DEFAULT_RESPONSE, problemResponse()));
        };
    }

    private static ApiResponse problemResponse() {
        Schema<?> reference = new Schema<>().$ref(SCHEMA_REF_PREFIX + PROBLEM_DETAIL_SCHEMA);
        io.swagger.v3.oas.models.media.MediaType problemJson =
                new io.swagger.v3.oas.models.media.MediaType().schema(reference);
        return new ApiResponse()
                .description("Error (RFC 9457)")
                .content(new Content().addMediaType(MediaType.APPLICATION_PROBLEM_JSON_VALUE, problemJson));
    }

    private static Schema<?> problemDetailSchema() {
        Schema<?> violation = new ObjectSchema()
                .addProperty("field", new StringSchema())
                .addProperty("message", new StringSchema());
        return new ObjectSchema()
                .addProperty("type", new StringSchema().format("uri"))
                .addProperty("title", new StringSchema())
                .addProperty("status", new IntegerSchema())
                .addProperty("detail", new StringSchema())
                .addProperty("instance", new StringSchema().format("uri"))
                .addProperty("code", new StringSchema())
                .addProperty("requestId", new StringSchema())
                .addProperty("errors", new ArraySchema().items(violation));
    }
}
```

In `src/main/resources/application.yml`, add at the end:

```yaml

springdoc:
  # Production sets API_DOCS_ENABLED=false.
  api-docs:
    enabled: ${API_DOCS_ENABLED:true}
  swagger-ui:
    enabled: ${API_DOCS_ENABLED:true}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `./mvnw -B spotless:apply && ./mvnw -B test -Dtest='JsonContractTest,OpenApiDocsTest,OpenApiDocsDisabledTest'`
Expected: `Tests run: 5, Failures: 0, Errors: 0`, `BUILD SUCCESS`.

- [ ] **Step 7: Document**

In `memox-api-services/README.md`, in the `## Base` section, add after the **Request ID** bullet:

```markdown
- **JSON contract:** Boot's defaults, pinned by `JsonContractTest`. Instants
  are ISO-8601 UTC strings (`"2026-09-27T01:02:03Z"`), null fields are written
  as `null`, enums by constant name (never their DB code), UUIDs as lowercase
  strings, and unknown request properties are ignored.
- **OpenAPI:** `/v3/api-docs` and `/swagger-ui.html` document every endpoint,
  with the error body as each operation's `default` response. Set
  `API_DOCS_ENABLED=false` to turn both off (production).
```

- [ ] **Step 8: Commit**

```bash
git add memox-api-services/src/test/java/com/memox/common/JsonContractTest.java memox-api-services/src/main/java/com/memox/common/config/OpenApiConfig.java memox-api-services/src/main/resources/application.yml memox-api-services/src/test/java/com/memox/common/config/OpenApiDocsTest.java memox-api-services/src/test/java/com/memox/common/config/OpenApiDocsDisabledTest.java memox-api-services/README.md
git commit -m "feat(api): pin the JSON contract; OpenAPI info, error schema and a docs switch

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Conventions in the review skill and the README

**Files:**
- Modify: `.claude/skills/spring-boot-mybatis-review/SKILL.md`, `.claude/skills/spring-boot-mybatis-review/references/conventions.md`, `.claude/skills/spring-boot-mybatis-review/references/mybatis-sql.md`
- Modify: the global copy `~/.claude/skills/spring-boot-mybatis-review/` (copied, not committed)
- Modify: `memox-api-services/README.md`
- Scratch (not committed): `<scratchpad>/skill-test/`, where `<scratchpad>` is the session's scratchpad directory (outside the repo)

**Interfaces:**
- Consumes: the README `## Base` section from Tasks 2–3.
- Produces: the skill's first review question; the README `## Foundation` section.

- [ ] **Step 1: Save the current skill and write the test fixture**

```bash
SCR="<scratchpad>/skill-test"; mkdir -p "$SCR/old-skill"
cp -r .claude/skills/spring-boot-mybatis-review/. "$SCR/old-skill/"
```

Create `$SCR/fixture.md`:

````markdown
# PR: deck list endpoint (memox-api-services)

The repo README (excerpt) says:

> ## Base
> - **Errors:** throw `new BusinessException(ErrorCode.SOME_CODE)`; every error response is RFC 9457 with a `code`, built by `GlobalExceptionHandler`.
> - **Paging:** a list endpoint takes a request that extends `PageQuery<TheSortEnum>` and returns `PagingResponse.of(items, query, totalItems)`.

## deck/dto/response/DeckPage.java
```java
@Getter
@AllArgsConstructor
public class DeckPage {
    private List<DeckResponse> content;
    private int pageNumber;
    private int pageSize;
    private long total;
}
```

## deck/controller/DeckController.java
```java
@RestController
@RequestMapping("/api/v1/decks")
@RequiredArgsConstructor
public class DeckController {

    private final DeckService deckService;

    @GetMapping
    public ResponseEntity<?> list(@RequestParam(defaultValue = "0") int pageNumber,
                                  @RequestParam(defaultValue = "20") int pageSize,
                                  @RequestParam(defaultValue = "NAME") DeckSortField sort) {
        try {
            return ResponseEntity.ok(deckService.findDecks(pageNumber, pageSize, sort));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "invalid paging"));
        }
    }
}
```

## deck/service/impl/DeckServiceImpl.java
```java
@Override
@Transactional(readOnly = true)
public DeckPage findDecks(int pageNumber, int pageSize, DeckSortField sort) {
    if (pageSize > 100) {
        throw new IllegalArgumentException("pageSize");
    }
    long offset = (long) pageNumber * pageSize;
    return new DeckPage(deckMapper.findDecks(sort, offset, pageSize), pageNumber, pageSize, deckMapper.countDecks());
}
```
````

- [ ] **Step 2: Baseline, with the current skill**

Dispatch a fresh `general-purpose` subagent: "Review the PR in `$SCR/fixture.md` using the skill at `$SCR/old-skill/` (read SKILL.md, then references as needed). Read no other files and use no other skill. Reply in Vietnamese; list findings with severity." Record whether it (a) names the duplication of the base paging contract (`PageQuery`/`PagingResponse`) as a finding and (b) names the controller `try/catch` returning `ResponseEntity` as duplicating `GlobalExceptionHandler`. Expected: at least one of (a) or (b) is missing, or it is not graded as re-implementing the base. If the baseline already flags both as base duplication, ledger `Ruling: baseline already flags base duplication — the skill edit is kept as documentation of the rule — cost: none`.

- [ ] **Step 3: Edit the skill**

In `.claude/skills/spring-boot-mybatis-review/SKILL.md`, replace the line

```markdown
Read the flow end to end first: Controller → Request DTO → Service → ServiceImpl → Mapper → Mapper XML → TypeHandler → DB → Response DTO.
```

with

```markdown
First question, before anything else: **does this change re-implement something the base already provides?** If the project documents its base (for example a README "Base" or "Foundation" section, or a `common` package), read it first. A feature's own paging DTO, error envelope, `try/catch` returning `ResponseEntity`, request-ID handling or string/collection helper is a finding: MEDIUM, or HIGH when it duplicates exception handling or pagination (two behaviours for the same concern). The fix is always "use the base", never "extend the duplicate".

Then read the flow end to end: Controller → Request DTO → Service → ServiceImpl → Mapper → Mapper XML → TypeHandler → DB → Response DTO.
```

In the same file, in the severity table's 🟠 HIGH row, append `, duplicating the base's exception handling or pagination` before the closing ` |`; in the 🟡 MEDIUM row, append `, re-implementing another base facility, scattered @Value instead of @ConfigurationProperties` before the closing ` |`.

In `.claude/skills/spring-boot-mybatis-review/references/conventions.md`, at the end of section `## 7. Exceptions and REST`, add:

```markdown

External configuration is read through one `@ConfigurationProperties` record per concern
(`@ConfigurationProperties(prefix = "payment.api") record PaymentApiProperties(URI url, Duration timeout)`),
injected where needed. Flag `@Value("${...}")` scattered across services: it is untyped and hard to test.
```

In `.claude/skills/spring-boot-mybatis-review/references/mybatis-sql.md`, at the end of section `## 1. Mapper responsibility`, add:

```markdown

Do not set `mybatis.type-aliases-package` to the whole application package: MyBatis aliases by simple class
name, and two classes with the same simple name in different features stop the application from starting.
Use fully qualified names in mapper XML.
```

- [ ] **Step 4: Re-run with the new skill**

Dispatch a fresh `general-purpose` subagent with the same prompt, pointing at `.claude/skills/spring-boot-mybatis-review/` instead of `$SCR/old-skill/`.
Expected: it flags both (a) and (b) as re-implementing the base, at MEDIUM or HIGH, with "use `PageQuery`/`PagingResponse`" and "throw `BusinessException`/let `GlobalExceptionHandler` answer" as fixes. If it does not, tighten the wording in Step 3 once, re-run, and ledger what changed.

- [ ] **Step 5: Sync the global copy**

```bash
rm -rf ~/.claude/skills/spring-boot-mybatis-review
cp -r .claude/skills/spring-boot-mybatis-review ~/.claude/skills/spring-boot-mybatis-review
diff -r .claude/skills/spring-boot-mybatis-review ~/.claude/skills/spring-boot-mybatis-review && echo IDENTICAL
```

Expected: `IDENTICAL`.

- [ ] **Step 6: Add the Foundation section to the README**

In `memox-api-services/README.md`, insert directly before `## Folder contract`:

```markdown
## Foundation

Before adding anything to a feature, check the Base section above: a feature
never re-implements paging, error bodies, exception handling, request IDs,
type handlers or string/collection helpers (Apache Commons first). The review
skill `spring-boot-mybatis-review` flags it.

Deliberately not built yet, each with the event that triggers it:

| Deferred | Trigger |
|---|---|
| Authentication, `CurrentUserProvider` (UUID user id, ADR-007) | the auth spec (ADR-001: one user type) |
| Auditing columns | the first table, designed with the sync protocol: an offline-first client may own `updated_at` |
| `commons-csv` | the `transfer` API |
| Spring profiles, production config | the first deployment |
| HTTP client convention | the first external integration |
| `@IntegrationTest` meta-annotation, shared fixtures | the second integration test |
| Revisit the single `ErrorCode` enum | about 50 constants |

```

- [ ] **Step 7: Run the full gate**

Run: `./mvnw -B clean verify > target-verify.log 2>&1; grep -E "Tests run: [0-9]+, F[^-]*$|All coverage checks|BUILD" target-verify.log`, then delete `target-verify.log`.
Expected: surefire `Tests run: 52` (38 + 9 + 5), failsafe `Tests run: 5`, `All coverage checks have been met.`, `BUILD SUCCESS`. Also: `python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p test_ci_tooling.py -k WorkflowContractTest` → `OK`.

- [ ] **Step 8: Commit**

```bash
git add .claude/skills/spring-boot-mybatis-review memox-api-services/README.md
git commit -m "docs(api): reuse-the-base-first review rule, @ConfigurationProperties, type-alias warning, Foundation section

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
