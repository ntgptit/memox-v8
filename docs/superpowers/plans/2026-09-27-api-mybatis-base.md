# memox-api-services MyBatis and Common Base Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire MyBatis to PostgreSQL in `memox-api-services` and add the shared `com.memox.common` base: paging, RFC 9457 errors, enum and UUID type handlers, UTC time.

**Architecture:** Spring Boot 3.5 + `mybatis-spring-boot-starter` 3.0.5. Shared code lives only in `com.memox.common` and its subpackages; no feature package is touched. Tests run against a real PostgreSQL 18 through Testcontainers.

**Tech Stack:** Java 17, Spring Boot 3.5.16 (Spring 6.2), MyBatis 3.5.19, PostgreSQL 18, Flyway 11, Lombok, Apache Commons Lang 3, JUnit 5, Mockito, AssertJ, Testcontainers 1.21.4.

**Spec:** `docs/superpowers/specs/2026-09-27-api-mybatis-base-design.md`

## Global Constraints

- Work inside `memox-api-services/`; run every Maven command from that folder. On Windows PowerShell use `.\mvnw.cmd` instead of `./mvnw`.
- The gate is `./mvnw -B verify`; it needs a running Docker.
- Packages: `com.memox.common`, `com.memox.common.exception`, `com.memox.common.type_handler`, `com.memox.common.config` (snake_case `type_handler` is deliberate, see the README).
- Do not create or edit anything under a feature package (`card`, `deck`, …) or `common.util`.
- `mybatis-spring-boot-starter` and `mybatis-spring-boot-starter-test`: 3.0.5. `commons-lang3.version`: 3.20.0. `commons-collections4`: 4.6.0.
- PostgreSQL image: `postgres:18-alpine`, in `compose.yaml` and in tests.
- Error bodies: `ProblemDetail` with property `code`; validation errors add property `errors` = list of `{field, message}`.
- `CommonErrorCode` constants: `VALIDATION_FAILED` 400, `BAD_REQUEST` 400, `NOT_FOUND` 404, `METHOD_NOT_ALLOWED` 405, `DATA_CONFLICT` 409, `UNSUPPORTED_MEDIA_TYPE` 415, `INTERNAL_ERROR` 500.
- Paging: `page` default 0, min 0; `size` default 20, min 1, max 100; `search` max 200 characters.
- Java indentation: tabs, as in the existing `MemoxApiServicesApplication.java`.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- A page past the last page (`page=5` when there are 3 pages) returns empty `items`, `hasNext=false`, `hasPrevious=true`, and does not throw. The test is in Task 2.
- A very large `page` (`Integer.MAX_VALUE`) with `size=100` gives an `offset()` that does not overflow `int`. The test is in Task 2.
- A database or unexpected error never echoes SQL, constraint names or exception text to the client. The tests are in Task 3.
- A code enum whose constants share a code fails when its handler is built, not later as a silent wrong read. The test is in Task 4.
- On a machine whose JVM zone is not UTC (this one runs at +09:00), an `Instant` is stored and read back as the same UTC instant. The test is in Task 4.

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `memox-api-services/pom.xml` | 1 | dependencies, failsafe |
| `memox-api-services/compose.yaml` | 1 | pin `postgres:18-alpine` |
| `memox-api-services/src/main/resources/application.yml` | 1 | MyBatis, Jackson UTC, problem details |
| `src/main/java/com/memox/MemoxApiServicesApplication.java` | 1 | JVM default zone UTC |
| `src/main/java/com/memox/common/config/TimeConfig.java` | 1 | `Clock` bean |
| `src/test/java/com/memox/TestcontainersConfiguration.java` | 1 | shared PostgreSQL container bean |
| `src/test/java/com/memox/MemoxApiServicesApplicationTests.java` | 1 | full context on PostgreSQL |
| `src/main/java/com/memox/common/{SortDirection,SortSpec,PageQuery,PagingResponse}.java` | 2 | paging contract |
| `src/test/java/com/memox/common/{PageQueryTest,PagingResponseTest}.java` | 2 | paging tests |
| `src/main/java/com/memox/common/exception/{ErrorCode,CommonErrorCode,BusinessException,FieldViolation,GlobalExceptionHandler}.java` | 3 | error model and mapping |
| `src/test/java/com/memox/common/exception/{GlobalExceptionHandlerTest,ExceptionProbeController}.java` | 3 | handler tests |
| `src/main/java/com/memox/common/type_handler/{CodeEnum,BaseEnumTypeHandler,UuidTypeHandler}.java` | 4 | type handlers |
| `src/test/java/com/memox/common/type_handler/{SampleStatus,SampleStatusTypeHandler,BaseEnumTypeHandlerTest,BaseRoundTripMapper,MyBatisBaseIT}.java` | 4 | handler unit tests, round-trip IT |
| `src/test/resources/mapper/common/BaseRoundTripMapper.xml` | 4 | IT SQL |
| `memox-api-services/README.md` | 4 | "Base" section |

(Paths starting with `src/` are under `memox-api-services/`.)

---

### Task 1: Dependencies, configuration and a PostgreSQL-backed context

**Files:**
- Modify: `memox-api-services/pom.xml`
- Modify: `memox-api-services/compose.yaml`
- Modify: `memox-api-services/src/main/resources/application.yml`
- Modify: `memox-api-services/src/main/java/com/memox/MemoxApiServicesApplication.java`
- Create: `memox-api-services/src/main/java/com/memox/common/config/TimeConfig.java`
- Create: `memox-api-services/src/test/java/com/memox/TestcontainersConfiguration.java`
- Modify: `memox-api-services/src/test/java/com/memox/MemoxApiServicesApplicationTests.java`

**Interfaces:**
- Consumes: nothing.
- Produces: `com.memox.TestcontainersConfiguration` (test) with `public static final String POSTGRES_IMAGE = "postgres:18-alpine"` and a `@ServiceConnection PostgreSQLContainer<?>` bean; a `java.time.Clock` bean (UTC); MyBatis properties `mapper-locations: classpath:mapper/**/*.xml`, `type-handlers-package: com.memox.common.type_handler`.

- [ ] **Step 1: Write the failing test**

Replace `src/test/java/com/memox/MemoxApiServicesApplicationTests.java` with:

```java
package com.memox;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
class MemoxApiServicesApplicationTests {

	@Autowired
	private Clock clock;

	@Test
	void contextLoadsWithUtcClock() {
		assertThat(clock.getZone()).isEqualTo(ZoneOffset.UTC);
	}

}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B test -Dtest=MemoxApiServicesApplicationTests`
Expected: COMPILATION ERROR, `cannot find symbol: class TestcontainersConfiguration`.

- [ ] **Step 3: Update `pom.xml`**

In `<properties>`, after `<java.version>17</java.version>`, add:

```xml
		<mybatis-spring-boot.version>3.0.5</mybatis-spring-boot.version>
		<commons-collections4.version>4.6.0</commons-collections4.version>
		<!-- Boot 3.5.16 manages 3.17.0, which predates the CVE-2025-48924 fix -->
		<commons-lang3.version>3.20.0</commons-lang3.version>
```

In `<dependencies>`, directly after the `spring-boot-starter-web` dependency, add:

```xml
		<dependency>
			<groupId>org.mybatis.spring.boot</groupId>
			<artifactId>mybatis-spring-boot-starter</artifactId>
			<version>${mybatis-spring-boot.version}</version>
		</dependency>
		<dependency>
			<groupId>org.apache.commons</groupId>
			<artifactId>commons-lang3</artifactId>
		</dependency>
		<dependency>
			<groupId>org.apache.commons</groupId>
			<artifactId>commons-collections4</artifactId>
			<version>${commons-collections4.version}</version>
		</dependency>
```

Delete this block entirely:

```xml
		<dependency>
			<groupId>com.h2database</groupId>
			<artifactId>h2</artifactId>
			<scope>runtime</scope>
		</dependency>
```

Directly after the `spring-security-test` dependency, add:

```xml
		<dependency>
			<groupId>org.mybatis.spring.boot</groupId>
			<artifactId>mybatis-spring-boot-starter-test</artifactId>
			<version>${mybatis-spring-boot.version}</version>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-testcontainers</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.testcontainers</groupId>
			<artifactId>postgresql</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.testcontainers</groupId>
			<artifactId>junit-jupiter</artifactId>
			<scope>test</scope>
		</dependency>
```

In `<build><plugins>`, directly after the `spring-boot-maven-plugin` plugin, add (the Boot parent already binds its `integration-test` and `verify` goals; this runs `*IT` classes during `verify`):

```xml
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-failsafe-plugin</artifactId>
			</plugin>
```

- [ ] **Step 4: Pin PostgreSQL in `compose.yaml`**

Change `image: 'postgres:latest'` to `image: 'postgres:18-alpine'`.

- [ ] **Step 5: Replace `application.yml`**

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

- [ ] **Step 6: Set the JVM zone to UTC in `main`**

Replace `src/main/java/com/memox/MemoxApiServicesApplication.java` with:

```java
package com.memox;

import java.time.ZoneOffset;
import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MemoxApiServicesApplication {

	public static void main(String[] args) {
		// ADR-008: every datetime is UTC, including any LocalDateTime that slips in.
		TimeZone.setDefault(TimeZone.getTimeZone(ZoneOffset.UTC));
		SpringApplication.run(MemoxApiServicesApplication.class, args);
	}

}
```

- [ ] **Step 7: Add the `Clock` bean**

Create `src/main/java/com/memox/common/config/TimeConfig.java`:

```java
package com.memox.common.config;

import java.time.Clock;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * The application clock. Code that needs "now" injects this {@link Clock}, so time stays UTC (ADR-008) and tests can
 * fix it.
 */
@Configuration(proxyBeanMethods = false)
public class TimeConfig {

	@Bean
	public Clock clock() {
		return Clock.systemUTC();
	}

}
```

- [ ] **Step 8: Add the shared container**

Create `src/test/java/com/memox/TestcontainersConfiguration.java`:

```java
package com.memox;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * One PostgreSQL container for tests that load the full application context.
 */
@TestConfiguration(proxyBeanMethods = false)
public class TestcontainersConfiguration {

	public static final String POSTGRES_IMAGE = "postgres:18-alpine";

	@Bean
	@ServiceConnection
	PostgreSQLContainer<?> postgresContainer() {
		return new PostgreSQLContainer<>(DockerImageName.parse(POSTGRES_IMAGE));
	}

}
```

- [ ] **Step 9: Run the test to verify it passes**

Run: `./mvnw -B test -Dtest=MemoxApiServicesApplicationTests`
Expected: `Tests run: 1, Failures: 0, Errors: 0` and `BUILD SUCCESS`. The log shows Flyway connecting to PostgreSQL 18. A Flyway line such as "PostgreSQL 18 is newer than this version of Flyway" is a warning only. If Flyway instead **fails** on version 18, change `POSTGRES_IMAGE` and `compose.yaml` to `postgres:17-alpine`, re-run, and report the change.

- [ ] **Step 10: Commit**

```bash
git add memox-api-services/pom.xml memox-api-services/compose.yaml memox-api-services/src/main/resources/application.yml memox-api-services/src/main/java/com/memox/MemoxApiServicesApplication.java memox-api-services/src/main/java/com/memox/common/config/TimeConfig.java memox-api-services/src/test/java/com/memox/TestcontainersConfiguration.java memox-api-services/src/test/java/com/memox/MemoxApiServicesApplicationTests.java
git commit -m "build(api): wire MyBatis and PostgreSQL, UTC clock, Testcontainers context

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Paging contract

**Files:**
- Create: `src/main/java/com/memox/common/SortDirection.java`
- Create: `src/main/java/com/memox/common/SortSpec.java`
- Create: `src/main/java/com/memox/common/PageQuery.java`
- Create: `src/main/java/com/memox/common/PagingResponse.java`
- Test: `src/test/java/com/memox/common/PageQueryTest.java`
- Test: `src/test/java/com/memox/common/PagingResponseTest.java`

**Interfaces:**
- Consumes: nothing from Task 1 at compile time.
- Produces:
  - `enum SortDirection { ASC, DESC }`
  - `class SortSpec<TSort extends Enum<TSort>>`: `getField()`, `setField(TSort)`, `getDirection()`, `setDirection(SortDirection)`; no-arg and all-args constructors.
  - `class PageQuery<TSort extends Enum<TSort>>`: constants `FIRST_PAGE = 0`, `MIN_PAGE_SIZE = 1`, `DEFAULT_PAGE_SIZE = 20`, `MAX_PAGE_SIZE = 100`, `MAX_SEARCH_LENGTH = 200`; getters and setters for `int page`, `int size`, `String search`, `List<SortSpec<TSort>> sorts`; `long offset()`.
  - `final class PagingResponse<T>`: getters `getItems()`, `getPage()`, `getSize()`, `getTotalItems()`, `getTotalPages()`, `isHasNext()`, `isHasPrevious()` (JSON: `items`, `page`, `size`, `totalItems`, `totalPages`, `hasNext`, `hasPrevious`); factory `static <T> PagingResponse<T> of(List<T> items, PageQuery<?> query, long totalItems)`.

- [ ] **Step 1: Write the failing tests**

Create `src/test/java/com/memox/common/PageQueryTest.java`:

```java
package com.memox.common;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

class PageQueryTest {

	private enum TestSort {
		NAME
	}

	private static ValidatorFactory validatorFactory;

	private static Validator validator;

	@BeforeAll
	static void createValidator() {
		validatorFactory = Validation.buildDefaultValidatorFactory();
		validator = validatorFactory.getValidator();
	}

	@AfterAll
	static void closeValidator() {
		validatorFactory.close();
	}

	@Test
	void defaultsAreFirstPageOfTwentyAndValid() {
		PageQuery<TestSort> query = new PageQuery<>();

		assertThat(query.getPage()).isZero();
		assertThat(query.getSize()).isEqualTo(PageQuery.DEFAULT_PAGE_SIZE);
		assertThat(query.getSorts()).isEmpty();
		assertThat(query.offset()).isZero();
		assertThat(validator.validate(query)).isEmpty();
	}

	@Test
	void negativePageIsRejected() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setPage(-1);

		assertThat(violatedPaths(query)).containsExactly("page");
	}

	@Test
	void sizeBelowMinimumIsRejected() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setSize(0);

		assertThat(violatedPaths(query)).containsExactly("size");
	}

	@Test
	void sizeAboveMaximumIsRejected() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setSize(PageQuery.MAX_PAGE_SIZE + 1);

		assertThat(violatedPaths(query)).containsExactly("size");
	}

	@Test
	void maximumSizeIsAccepted() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setSize(PageQuery.MAX_PAGE_SIZE);

		assertThat(validator.validate(query)).isEmpty();
	}

	@Test
	void tooLongSearchIsRejected() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setSearch("x".repeat(PageQuery.MAX_SEARCH_LENGTH + 1));

		assertThat(violatedPaths(query)).containsExactly("search");
	}

	@Test
	void sortWithoutFieldIsRejected() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setSorts(List.of(new SortSpec<>(null, SortDirection.DESC)));

		assertThat(violatedPaths(query)).containsExactly("sorts[0].field");
	}

	@Test
	void offsetIsPageTimesSize() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setPage(3);
		query.setSize(20);

		assertThat(query.offset()).isEqualTo(60L);
	}

	@Test
	void offsetDoesNotOverflowOnHugePage() {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setPage(Integer.MAX_VALUE);
		query.setSize(PageQuery.MAX_PAGE_SIZE);

		assertThat(query.offset()).isEqualTo(214_748_364_700L);
	}

	private Set<String> violatedPaths(PageQuery<TestSort> query) {
		return validator.validate(query)
			.stream()
			.map(ConstraintViolation::getPropertyPath)
			.map(Object::toString)
			.collect(Collectors.toSet());
	}

}
```

Create `src/test/java/com/memox/common/PagingResponseTest.java`:

```java
package com.memox.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;

class PagingResponseTest {

	private enum TestSort {
		NAME
	}

	@Test
	void firstPageHasNextButNoPrevious() {
		PagingResponse<String> response = PagingResponse.of(List.of("a", "b"), query(0, 20), 45);

		assertThat(response.getItems()).containsExactly("a", "b");
		assertThat(response.getPage()).isZero();
		assertThat(response.getSize()).isEqualTo(20);
		assertThat(response.getTotalItems()).isEqualTo(45);
		assertThat(response.getTotalPages()).isEqualTo(3);
		assertThat(response.isHasNext()).isTrue();
		assertThat(response.isHasPrevious()).isFalse();
	}

	@Test
	void middlePageHasBothNeighbours() {
		PagingResponse<String> response = PagingResponse.of(List.of("x"), query(1, 20), 45);

		assertThat(response.isHasNext()).isTrue();
		assertThat(response.isHasPrevious()).isTrue();
	}

	@Test
	void lastPageHasNoNext() {
		PagingResponse<String> response = PagingResponse.of(List.of("x"), query(2, 20), 45);

		assertThat(response.isHasNext()).isFalse();
		assertThat(response.isHasPrevious()).isTrue();
	}

	@Test
	void exactMultipleHasNoExtraPage() {
		PagingResponse<String> response = PagingResponse.of(List.of("x"), query(1, 20), 40);

		assertThat(response.getTotalPages()).isEqualTo(2);
		assertThat(response.isHasNext()).isFalse();
	}

	@Test
	void emptyResultHasNoPages() {
		PagingResponse<String> response = PagingResponse.of(List.of(), query(0, 20), 0);

		assertThat(response.getItems()).isEmpty();
		assertThat(response.getTotalPages()).isZero();
		assertThat(response.isHasNext()).isFalse();
		assertThat(response.isHasPrevious()).isFalse();
	}

	@Test
	void pagePastTheEndIsEmptyAndPointsBack() {
		PagingResponse<String> response = PagingResponse.of(List.of(), query(5, 20), 45);

		assertThat(response.getItems()).isEmpty();
		assertThat(response.getTotalPages()).isEqualTo(3);
		assertThat(response.isHasNext()).isFalse();
		assertThat(response.isHasPrevious()).isTrue();
	}

	@Test
	void negativeTotalIsRejected() {
		assertThatThrownBy(() -> PagingResponse.of(List.of(), query(0, 20), -1))
			.isInstanceOf(IllegalArgumentException.class);
	}

	private PageQuery<TestSort> query(int page, int size) {
		PageQuery<TestSort> query = new PageQuery<>();
		query.setPage(page);
		query.setSize(size);
		return query;
	}

}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `./mvnw -B test -Dtest='PageQueryTest,PagingResponseTest'`
Expected: COMPILATION ERROR, `cannot find symbol: class PageQuery`.

- [ ] **Step 3: Implement the contract**

Create `src/main/java/com/memox/common/SortDirection.java`:

```java
package com.memox.common;

/**
 * Direction of one sort entry in a {@link PageQuery}.
 */
public enum SortDirection {

	ASC,

	DESC

}
```

Create `src/main/java/com/memox/common/SortSpec.java`:

```java
package com.memox.common;

import jakarta.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * One sort entry. {@code TSort} is a feature enum whose constants each map to a whitelisted SQL column in that
 * feature's mapper.
 *
 * @param <TSort> the feature's sort-field enum
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SortSpec<TSort extends Enum<TSort>> {

	@NotNull
	private TSort field;

	@NotNull
	private SortDirection direction = SortDirection.ASC;

}
```

Create `src/main/java/com/memox/common/PageQuery.java`:

```java
package com.memox.common;

import java.util.ArrayList;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import lombok.Getter;
import lombok.Setter;

/**
 * The shared paged-list request. A feature search request extends it with its own filters and its own sort enum, for
 * example {@code DeckSearchRequest extends PageQuery<DeckSortField>}. Pages are zero-based.
 *
 * @param <TSort> the feature's sort-field enum
 */
@Getter
@Setter
public class PageQuery<TSort extends Enum<TSort>> {

	public static final int FIRST_PAGE = 0;

	public static final int MIN_PAGE_SIZE = 1;

	public static final int DEFAULT_PAGE_SIZE = 20;

	public static final int MAX_PAGE_SIZE = 100;

	public static final int MAX_SEARCH_LENGTH = 200;

	@Min(FIRST_PAGE)
	private int page = FIRST_PAGE;

	@Min(MIN_PAGE_SIZE)
	@Max(MAX_PAGE_SIZE)
	private int size = DEFAULT_PAGE_SIZE;

	@Size(max = MAX_SEARCH_LENGTH)
	private String search;

	@Valid
	private List<SortSpec<TSort>> sorts = new ArrayList<>();

	/**
	 * The SQL {@code OFFSET} for this page, as a {@code long} so a huge page number cannot overflow.
	 */
	public long offset() {
		return (long) page * size;
	}

}
```

Create `src/main/java/com/memox/common/PagingResponse.java`:

```java
package com.memox.common;

import java.util.List;
import java.util.Objects;

import org.apache.commons.lang3.Validate;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * The shared paged-list response. Build it only through {@link #of(List, PageQuery, long)}, which derives the page
 * counts.
 *
 * @param <T> the item type
 */
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public final class PagingResponse<T> {

	private final List<T> items;

	private final int page;

	private final int size;

	private final long totalItems;

	private final int totalPages;

	private final boolean hasNext;

	private final boolean hasPrevious;

	public static <T> PagingResponse<T> of(List<T> items, PageQuery<?> query, long totalItems) {
		Objects.requireNonNull(items, "items");
		Objects.requireNonNull(query, "query");
		Validate.isTrue(totalItems >= 0, "totalItems must not be negative: %d", totalItems);

		int page = query.getPage();
		int size = query.getSize();
		int totalPages = Math.toIntExact((totalItems + size - 1) / size);
		boolean hasNext = page + 1L < totalPages;
		boolean hasPrevious = page > PageQuery.FIRST_PAGE;
		return new PagingResponse<>(List.copyOf(items), page, size, totalItems, totalPages, hasNext, hasPrevious);
	}

}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `./mvnw -B test -Dtest='PageQueryTest,PagingResponseTest'`
Expected: `Tests run: 16, Failures: 0, Errors: 0`, `BUILD SUCCESS`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services/src/main/java/com/memox/common/SortDirection.java memox-api-services/src/main/java/com/memox/common/SortSpec.java memox-api-services/src/main/java/com/memox/common/PageQuery.java memox-api-services/src/main/java/com/memox/common/PagingResponse.java memox-api-services/src/test/java/com/memox/common/PageQueryTest.java memox-api-services/src/test/java/com/memox/common/PagingResponseTest.java
git commit -m "feat(api): shared paging contract

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Error model and RFC 9457 mapping

**Files:**
- Create: `src/main/java/com/memox/common/exception/ErrorCode.java`
- Create: `src/main/java/com/memox/common/exception/CommonErrorCode.java`
- Create: `src/main/java/com/memox/common/exception/BusinessException.java`
- Create: `src/main/java/com/memox/common/exception/FieldViolation.java`
- Create: `src/main/java/com/memox/common/exception/GlobalExceptionHandler.java`
- Test: `src/test/java/com/memox/common/exception/ExceptionProbeController.java`
- Test: `src/test/java/com/memox/common/exception/GlobalExceptionHandlerTest.java`

**Interfaces:**
- Consumes: nothing from Tasks 1–2.
- Produces:
  - `interface ErrorCode { String code(); HttpStatus status(); }`
  - `enum CommonErrorCode implements ErrorCode` with the Global Constraints constants and `static CommonErrorCode fromStatus(HttpStatusCode status)`.
  - `class BusinessException extends RuntimeException`: `BusinessException(ErrorCode errorCode, String detail)`, `getErrorCode()`, `getDetail()`.
  - `record FieldViolation(String field, String message)`.
  - `GlobalExceptionHandler` constants `CODE_PROPERTY = "code"`, `ERRORS_PROPERTY = "errors"`.

- [ ] **Step 1: Write the probe controller and the failing test**

Create `src/test/java/com/memox/common/exception/ExceptionProbeController.java`:

```java
package com.memox.common.exception;

import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Valid;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Test-only endpoints that raise each exception {@link GlobalExceptionHandler} maps.
 */
@RestController
@RequestMapping("/probe")
class ExceptionProbeController {

	static final String LEAKED_SQL = "SELECT secret FROM users";

	static final String LEAKED_CONSTRAINT = "deck_pkey";

	enum ProbeErrorCode implements ErrorCode {

		PROBE_NOT_FOUND;

		@Override
		public String code() {
			return name();
		}

		@Override
		public HttpStatus status() {
			return HttpStatus.NOT_FOUND;
		}

	}

	record ProbeRequest(@NotBlank String name) {
	}

	@GetMapping("/business")
	void business() {
		throw new BusinessException(ProbeErrorCode.PROBE_NOT_FOUND, "Probe 42 was not found.");
	}

	@PostMapping("/body")
	void body(@Valid @RequestBody ProbeRequest request) {
	}

	@GetMapping("/param")
	void param(@RequestParam @Min(1) int size) {
	}

	@GetMapping("/constraint")
	void constraint() {
		try (ValidatorFactory factory = Validation.buildDefaultValidatorFactory()) {
			Validator validator = factory.getValidator();
			throw new ConstraintViolationException(validator.validate(new ProbeRequest("")));
		}
	}

	@GetMapping("/conflict")
	void conflict() {
		throw new DuplicateKeyException("duplicate key value violates unique constraint \"" + LEAKED_CONSTRAINT + "\"");
	}

	@GetMapping("/boom")
	void boom() {
		throw new IllegalStateException(LEAKED_SQL);
	}

}
```

Create `src/test/java/com/memox/common/exception/GlobalExceptionHandlerTest.java`:

```java
package com.memox.common.exception;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@WebMvcTest(controllers = ExceptionProbeController.class)
@AutoConfigureMockMvc(addFilters = false)
class GlobalExceptionHandlerTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void businessExceptionUsesItsCodeAndStatus() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/business")), 404, "PROBE_NOT_FOUND")
			.andExpect(jsonPath("$.detail").value("Probe 42 was not found."))
			.andExpect(jsonPath("$.instance").value("/probe/business"));
	}

	@Test
	void invalidBodyListsFieldErrors() throws Exception {
		expectProblem(mockMvc.perform(post("/probe/body").contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"\"}")),
				400, "VALIDATION_FAILED")
			.andExpect(jsonPath("$.errors[0].field").value("name"))
			.andExpect(jsonPath("$.errors[0].message").isNotEmpty());
	}

	@Test
	void invalidRequestParamListsParameterErrors() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/param").param("size", "0")), 400, "VALIDATION_FAILED")
			.andExpect(jsonPath("$.errors[0].field").value("size"));
	}

	@Test
	void constraintViolationListsFieldErrors() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/constraint")), 400, "VALIDATION_FAILED")
			.andExpect(jsonPath("$.errors[0].field").value("name"));
	}

	@Test
	void malformedJsonIsBadRequest() throws Exception {
		expectProblem(mockMvc.perform(post("/probe/body").contentType(MediaType.APPLICATION_JSON).content("{")), 400,
				"BAD_REQUEST");
	}

	@Test
	void wrongMethodIsMethodNotAllowed() throws Exception {
		expectProblem(mockMvc.perform(delete("/probe/business")), 405, "METHOD_NOT_ALLOWED");
	}

	@Test
	void wrongContentTypeIsUnsupportedMediaType() throws Exception {
		expectProblem(mockMvc.perform(post("/probe/body").contentType(MediaType.TEXT_PLAIN).content("name")), 415,
				"UNSUPPORTED_MEDIA_TYPE");
	}

	@Test
	void unknownPathIsNotFound() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/does-not-exist")), 404, "NOT_FOUND");
	}

	@Test
	void dataIntegrityViolationIsConflictWithoutDatabaseDetails() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/conflict")), 409, "DATA_CONFLICT")
			.andExpect(content().string(not(containsString(ExceptionProbeController.LEAKED_CONSTRAINT))));
	}

	@Test
	void unexpectedExceptionIsInternalErrorWithoutLeakingIt() throws Exception {
		expectProblem(mockMvc.perform(get("/probe/boom")), 500, "INTERNAL_ERROR")
			.andExpect(content().string(not(containsString(ExceptionProbeController.LEAKED_SQL))))
			.andExpect(content().string(not(containsString("IllegalStateException"))));
	}

	private ResultActions expectProblem(ResultActions result, int status, String code) throws Exception {
		return result.andExpect(status().is(status))
			.andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
			.andExpect(jsonPath("$.status").value(status))
			.andExpect(jsonPath("$.code").value(code));
	}

}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./mvnw -B test -Dtest=GlobalExceptionHandlerTest`
Expected: COMPILATION ERROR, `cannot find symbol: class ErrorCode`.

- [ ] **Step 3: Implement the error model**

Create `src/main/java/com/memox/common/exception/ErrorCode.java`:

```java
package com.memox.common.exception;

import org.springframework.http.HttpStatus;

/**
 * A stable, client-facing error code and the HTTP status it maps to. Each feature declares its own enum, for example
 * {@code DeckErrorCode.DECK_NOT_FOUND}.
 */
public interface ErrorCode {

	String code();

	HttpStatus status();

}
```

Create `src/main/java/com/memox/common/exception/CommonErrorCode.java`:

```java
package com.memox.common.exception;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

import lombok.RequiredArgsConstructor;

/**
 * Error codes produced by {@link GlobalExceptionHandler} itself. Each code equals the constant name.
 */
@RequiredArgsConstructor
public enum CommonErrorCode implements ErrorCode {

	VALIDATION_FAILED(HttpStatus.BAD_REQUEST),

	BAD_REQUEST(HttpStatus.BAD_REQUEST),

	NOT_FOUND(HttpStatus.NOT_FOUND),

	METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED),

	DATA_CONFLICT(HttpStatus.CONFLICT),

	UNSUPPORTED_MEDIA_TYPE(HttpStatus.UNSUPPORTED_MEDIA_TYPE),

	INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR);

	private static final Map<Integer, CommonErrorCode> BY_FRAMEWORK_STATUS = Map.of(
			HttpStatus.NOT_FOUND.value(), NOT_FOUND,
			HttpStatus.METHOD_NOT_ALLOWED.value(), METHOD_NOT_ALLOWED,
			HttpStatus.UNSUPPORTED_MEDIA_TYPE.value(), UNSUPPORTED_MEDIA_TYPE);

	private final HttpStatus status;

	@Override
	public String code() {
		return name();
	}

	@Override
	public HttpStatus status() {
		return status;
	}

	/**
	 * The code for an error Spring MVC raised with the given status: an exact match, otherwise {@link #BAD_REQUEST}
	 * for 4xx and {@link #INTERNAL_ERROR} for everything else.
	 */
	public static CommonErrorCode fromStatus(HttpStatusCode status) {
		CommonErrorCode exact = BY_FRAMEWORK_STATUS.get(status.value());
		if (exact != null) {
			return exact;
		}
		if (status.is4xxClientError()) {
			return BAD_REQUEST;
		}
		return INTERNAL_ERROR;
	}

}
```

Create `src/main/java/com/memox/common/exception/BusinessException.java`:

```java
package com.memox.common.exception;

import lombok.Getter;

/**
 * The one exception for expected business failures. The HTTP status comes from the {@link ErrorCode}; the detail
 * must be safe to show to the client.
 */
@Getter
public class BusinessException extends RuntimeException {

	private static final long serialVersionUID = 1L;

	private final transient ErrorCode errorCode;

	private final String detail;

	public BusinessException(ErrorCode errorCode, String detail) {
		super(errorCode.code() + ": " + detail);
		this.errorCode = errorCode;
		this.detail = detail;
	}

}
```

Create `src/main/java/com/memox/common/exception/FieldViolation.java`:

```java
package com.memox.common.exception;

/**
 * One entry of the {@code errors} property on a {@code VALIDATION_FAILED} problem.
 */
public record FieldViolation(String field, String message) {
}
```

Create `src/main/java/com/memox/common/exception/GlobalExceptionHandler.java`:

```java
package com.memox.common.exception;

import java.util.List;
import java.util.Map;

import jakarta.validation.ConstraintViolationException;

import org.springframework.context.MessageSourceResolvable;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.validation.method.ParameterValidationResult;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import lombok.extern.slf4j.Slf4j;

/**
 * Maps every exception to an RFC 9457 {@link ProblemDetail} that carries a {@code code}. Never returns stack traces,
 * SQL, constraint names or exception class names.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

	public static final String CODE_PROPERTY = "code";

	public static final String ERRORS_PROPERTY = "errors";

	private static final String VALIDATION_DETAIL = "Request validation failed.";

	private static final String DATA_CONFLICT_DETAIL = "The request conflicts with existing data.";

	private static final String INTERNAL_ERROR_DETAIL = "An unexpected error occurred.";

	@ExceptionHandler(BusinessException.class)
	public ProblemDetail handleBusiness(BusinessException ex) {
		return problem(ex.getErrorCode(), ex.getDetail());
	}

	@ExceptionHandler(ConstraintViolationException.class)
	public ProblemDetail handleConstraintViolation(ConstraintViolationException ex) {
		List<FieldViolation> violations = ex.getConstraintViolations()
			.stream()
			.map(violation -> new FieldViolation(violation.getPropertyPath().toString(), violation.getMessage()))
			.toList();
		return validationProblem(violations);
	}

	@ExceptionHandler(DataIntegrityViolationException.class)
	public ProblemDetail handleDataIntegrity(DataIntegrityViolationException ex) {
		log.warn("Data integrity violation", ex);
		return problem(CommonErrorCode.DATA_CONFLICT, DATA_CONFLICT_DETAIL);
	}

	@ExceptionHandler(Exception.class)
	public ProblemDetail handleUnexpected(Exception ex) {
		log.error("Unhandled exception", ex);
		return problem(CommonErrorCode.INTERNAL_ERROR, INTERNAL_ERROR_DETAIL);
	}

	@Override
	protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
			HttpHeaders headers, HttpStatusCode status, WebRequest request) {
		List<FieldViolation> violations = ex.getBindingResult()
			.getFieldErrors()
			.stream()
			.map(error -> new FieldViolation(error.getField(), error.getDefaultMessage()))
			.toList();
		return handleExceptionInternal(ex, validationProblem(violations), headers, status, request);
	}

	@Override
	protected ResponseEntity<Object> handleHandlerMethodValidationException(HandlerMethodValidationException ex,
			HttpHeaders headers, HttpStatusCode status, WebRequest request) {
		List<FieldViolation> violations = ex.getParameterValidationResults()
			.stream()
			.flatMap(result -> result.getResolvableErrors()
				.stream()
				.map(error -> new FieldViolation(fieldName(result, error), error.getDefaultMessage())))
			.toList();
		return handleExceptionInternal(ex, validationProblem(violations), headers, status, request);
	}

	@Override
	protected ResponseEntity<Object> handleExceptionInternal(Exception ex, Object body, HttpHeaders headers,
			HttpStatusCode statusCode, WebRequest request) {
		ResponseEntity<Object> response = super.handleExceptionInternal(ex, body, headers, statusCode, request);
		if (response != null && response.getBody() instanceof ProblemDetail problem && lacksCode(problem)) {
			problem.setProperty(CODE_PROPERTY, CommonErrorCode.fromStatus(response.getStatusCode()).code());
		}
		return response;
	}

	private static String fieldName(ParameterValidationResult result, MessageSourceResolvable error) {
		if (error instanceof FieldError fieldError) {
			return fieldError.getField();
		}
		return result.getMethodParameter().getParameterName();
	}

	private static boolean lacksCode(ProblemDetail problem) {
		Map<String, Object> properties = problem.getProperties();
		return properties == null || !properties.containsKey(CODE_PROPERTY);
	}

	private static ProblemDetail validationProblem(List<FieldViolation> violations) {
		ProblemDetail problem = problem(CommonErrorCode.VALIDATION_FAILED, VALIDATION_DETAIL);
		problem.setProperty(ERRORS_PROPERTY, violations);
		return problem;
	}

	private static ProblemDetail problem(ErrorCode errorCode, String detail) {
		ProblemDetail problem = ProblemDetail.forStatusAndDetail(errorCode.status(), detail);
		problem.setProperty(CODE_PROPERTY, errorCode.code());
		return problem;
	}

}
```

If `getParameterValidationResults()` does not compile on the Spring version resolved by Boot 3.5.16, use `getAllValidationResults()` instead; both return `List<ParameterValidationResult>`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `./mvnw -B test -Dtest=GlobalExceptionHandlerTest`
Expected: `Tests run: 10, Failures: 0, Errors: 0`, `BUILD SUCCESS`.

- [ ] **Step 5: Commit**

```bash
git add memox-api-services/src/main/java/com/memox/common/exception memox-api-services/src/test/java/com/memox/common/exception
git commit -m "feat(api): RFC 9457 error model and global exception handler

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Type handlers, MyBatis round-trip and README

**Files:**
- Create: `src/main/java/com/memox/common/type_handler/CodeEnum.java`
- Create: `src/main/java/com/memox/common/type_handler/BaseEnumTypeHandler.java`
- Create: `src/main/java/com/memox/common/type_handler/UuidTypeHandler.java`
- Test: `src/test/java/com/memox/common/type_handler/SampleStatus.java`
- Test: `src/test/java/com/memox/common/type_handler/SampleStatusTypeHandler.java`
- Test: `src/test/java/com/memox/common/type_handler/BaseEnumTypeHandlerTest.java`
- Test: `src/test/java/com/memox/common/type_handler/BaseRoundTripMapper.java`
- Test: `src/test/resources/mapper/common/BaseRoundTripMapper.xml`
- Test: `src/test/java/com/memox/common/type_handler/MyBatisBaseIT.java`
- Modify: `memox-api-services/README.md`

**Interfaces:**
- Consumes: Task 1's `TestcontainersConfiguration.POSTGRES_IMAGE`, `mybatis.mapper-locations`, `mybatis.type-handlers-package`, and the failsafe plugin.
- Produces:
  - `interface CodeEnum { String getCode(); }`
  - `abstract class BaseEnumTypeHandler<E extends Enum<E> & CodeEnum> extends BaseTypeHandler<E>` with `protected BaseEnumTypeHandler(Class<E> enumType)`.
  - `class UuidTypeHandler extends BaseTypeHandler<UUID>`.

- [ ] **Step 1: Write the test enum, its handler and the failing unit test**

Create `src/test/java/com/memox/common/type_handler/SampleStatus.java`:

```java
package com.memox.common.type_handler;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Test-only code enum.
 */
@Getter
@RequiredArgsConstructor
public enum SampleStatus implements CodeEnum {

	ACTIVE("A"),

	INACTIVE("I");

	private final String code;

}
```

Create `src/test/java/com/memox/common/type_handler/SampleStatusTypeHandler.java`:

```java
package com.memox.common.type_handler;

import org.apache.ibatis.type.MappedTypes;

/**
 * Test-only handler; lives in {@code common.type_handler}, so the package scan registers it like a real one.
 */
@MappedTypes(SampleStatus.class)
public class SampleStatusTypeHandler extends BaseEnumTypeHandler<SampleStatus> {

	public SampleStatusTypeHandler() {
		super(SampleStatus.class);
	}

}
```

Create `src/test/java/com/memox/common/type_handler/BaseEnumTypeHandlerTest.java`:

```java
package com.memox.common.type_handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import org.apache.ibatis.type.JdbcType;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

class BaseEnumTypeHandlerTest {

	private static final String COLUMN = "status";

	private final SampleStatusTypeHandler handler = new SampleStatusTypeHandler();

	@Getter
	@RequiredArgsConstructor
	private enum DuplicateCode implements CodeEnum {

		FIRST("X"),

		SECOND("X");

		private final String code;

	}

	@Test
	void writesTheCodeNotTheName() throws Exception {
		PreparedStatement statement = mock(PreparedStatement.class);

		handler.setParameter(statement, 1, SampleStatus.ACTIVE, null);

		verify(statement).setString(1, "A");
	}

	@Test
	void writesNullAsSqlNull() throws Exception {
		PreparedStatement statement = mock(PreparedStatement.class);

		handler.setParameter(statement, 1, null, JdbcType.VARCHAR);

		verify(statement).setNull(1, Types.VARCHAR);
	}

	@Test
	void readsTheConstantForItsCodeByColumnName() throws Exception {
		ResultSet resultSet = mock(ResultSet.class);
		when(resultSet.getString(COLUMN)).thenReturn("I");

		assertThat(handler.getResult(resultSet, COLUMN)).isEqualTo(SampleStatus.INACTIVE);
	}

	@Test
	void readsTheConstantForItsCodeByColumnIndex() throws Exception {
		ResultSet resultSet = mock(ResultSet.class);
		when(resultSet.getString(1)).thenReturn("A");

		assertThat(handler.getResult(resultSet, 1)).isEqualTo(SampleStatus.ACTIVE);
	}

	@Test
	void readsTheConstantFromACallableStatement() throws Exception {
		CallableStatement statement = mock(CallableStatement.class);
		when(statement.getString(2)).thenReturn("A");

		assertThat(handler.getResult(statement, 2)).isEqualTo(SampleStatus.ACTIVE);
	}

	@Test
	void readsSqlNullAsNull() throws Exception {
		ResultSet resultSet = mock(ResultSet.class);
		when(resultSet.getString(COLUMN)).thenReturn(null);

		assertThat(handler.getResult(resultSet, COLUMN)).isNull();
	}

	@ParameterizedTest
	@ValueSource(strings = { "X", "a", "ACTIVE", "" })
	void rejectsAnUnknownCodeNamingTheEnum(String storedCode) throws Exception {
		ResultSet resultSet = mock(ResultSet.class);
		when(resultSet.getString(COLUMN)).thenReturn(storedCode);

		assertThatThrownBy(() -> handler.getResult(resultSet, COLUMN))
			.hasRootCauseInstanceOf(IllegalArgumentException.class)
			.hasRootCauseMessage("Unknown SampleStatus code: '" + storedCode + "'");
	}

	@Test
	void rejectsAnEnumWithDuplicateCodesWhenBuilt() {
		// Anonymous on purpose: MyBatis's handler package scan skips anonymous classes, so this deliberately broken
		// handler never reaches the MyBatisBaseIT context.
		assertThatThrownBy(() -> new BaseEnumTypeHandler<DuplicateCode>(DuplicateCode.class) {
		}).isInstanceOf(IllegalStateException.class);
	}

}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./mvnw -B test -Dtest=BaseEnumTypeHandlerTest`
Expected: COMPILATION ERROR, `cannot find symbol: class CodeEnum`.

- [ ] **Step 3: Implement the enum handler**

Create `src/main/java/com/memox/common/type_handler/CodeEnum.java`:

```java
package com.memox.common.type_handler;

/**
 * An enum stored in the database by a short code instead of its name. Give each such enum a one-line
 * {@link BaseEnumTypeHandler} subclass in this package, annotated {@code @MappedTypes(TheEnum.class)}.
 */
public interface CodeEnum {

	String getCode();

}
```

Create `src/main/java/com/memox/common/type_handler/BaseEnumTypeHandler.java`:

```java
package com.memox.common.type_handler;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;

/**
 * Maps a {@link CodeEnum} to and from its database code. An unknown code fails loudly instead of reading as
 * {@code null}, and an enum whose constants share a code fails when the handler is built.
 *
 * @param <E> the enum type
 */
public abstract class BaseEnumTypeHandler<E extends Enum<E> & CodeEnum> extends BaseTypeHandler<E> {

	private final Class<E> enumType;

	private final Map<String, E> constantsByCode;

	protected BaseEnumTypeHandler(Class<E> enumType) {
		this.enumType = enumType;
		this.constantsByCode = Arrays.stream(enumType.getEnumConstants())
			.collect(Collectors.toUnmodifiableMap(E::getCode, Function.identity()));
	}

	@Override
	public void setNonNullParameter(PreparedStatement ps, int i, E parameter, JdbcType jdbcType) throws SQLException {
		ps.setString(i, parameter.getCode());
	}

	@Override
	public E getNullableResult(ResultSet rs, String columnName) throws SQLException {
		return toConstant(rs.getString(columnName));
	}

	@Override
	public E getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
		return toConstant(rs.getString(columnIndex));
	}

	@Override
	public E getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
		return toConstant(cs.getString(columnIndex));
	}

	private E toConstant(String code) {
		if (code == null) {
			return null;
		}
		E constant = constantsByCode.get(code);
		if (constant == null) {
			throw new IllegalArgumentException("Unknown " + enumType.getSimpleName() + " code: '" + code + "'");
		}
		return constant;
	}

}
```

- [ ] **Step 4: Run the unit test to verify it passes**

Run: `./mvnw -B test -Dtest=BaseEnumTypeHandlerTest`
Expected: `Tests run: 11, Failures: 0, Errors: 0`, `BUILD SUCCESS`.

- [ ] **Step 5: Write the round-trip mapper and the failing IT**

Create `src/test/java/com/memox/common/type_handler/BaseRoundTripMapper.java`:

```java
package com.memox.common.type_handler;

import java.time.Instant;
import java.util.UUID;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * Test-only mapper that sends values through PostgreSQL and back.
 */
@Mapper
public interface BaseRoundTripMapper {

	UUID echoUuid(@Param("value") UUID value);

	String storedStatusCode(@Param("value") SampleStatus value);

	SampleStatus statusFromCode(@Param("code") String code);

	Instant echoInstant(@Param("value") Instant value);

	String instantAsUtcText(@Param("value") Instant value);

}
```

Create `src/test/resources/mapper/common/BaseRoundTripMapper.xml`:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
	PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
	"https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.memox.common.type_handler.BaseRoundTripMapper">

	<select id="echoUuid" resultType="java.util.UUID">
		SELECT CAST(#{value} AS uuid)
	</select>

	<select id="storedStatusCode" resultType="java.lang.String">
		SELECT CAST(#{value} AS varchar)
	</select>

	<select id="statusFromCode" resultType="com.memox.common.type_handler.SampleStatus">
		SELECT CAST(#{code} AS varchar)
	</select>

	<select id="echoInstant" resultType="java.time.Instant">
		SELECT CAST(#{value} AS timestamptz)
	</select>

	<select id="instantAsUtcText" resultType="java.lang.String">
		SELECT to_char(CAST(#{value} AS timestamptz) AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS')
	</select>

</mapper>
```

Create `src/test/java/com/memox/common/type_handler/MyBatisBaseIT.java`:

```java
package com.memox.common.type_handler;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.mybatis.spring.boot.test.autoconfigure.MybatisTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import com.memox.TestcontainersConfiguration;

/**
 * Proves the MyBatis wiring against a real PostgreSQL: mapper XML under {@code mapper/**} is loaded, and the type
 * handlers in {@code common.type_handler} are registered.
 */
@MybatisTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class MyBatisBaseIT {

	@Container
	@ServiceConnection
	static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>(
			DockerImageName.parse(TestcontainersConfiguration.POSTGRES_IMAGE));

	@Autowired
	private BaseRoundTripMapper mapper;

	@Test
	void uuidRoundTripsThroughTheUuidType() {
		UUID id = UUID.fromString("0f8fad5b-d9cb-469f-a165-70867728950e");

		assertThat(mapper.echoUuid(id)).isEqualTo(id);
	}

	@Test
	void codeEnumIsStoredAsItsCode() {
		assertThat(mapper.storedStatusCode(SampleStatus.INACTIVE)).isEqualTo("I");
	}

	@Test
	void codeEnumIsReadFromItsCode() {
		assertThat(mapper.statusFromCode("A")).isEqualTo(SampleStatus.ACTIVE);
	}

	@Test
	void instantRoundTripsUnchanged() {
		Instant instant = Instant.parse("2026-09-27T01:02:03.456Z");

		assertThat(mapper.echoInstant(instant)).isEqualTo(instant);
	}

	@Test
	void instantIsStoredAsTheSameUtcMoment() {
		Instant instant = Instant.parse("2026-09-27T01:02:03Z");

		assertThat(mapper.instantAsUtcText(instant)).isEqualTo("2026-09-27T01:02:03");
	}

}
```

- [ ] **Step 6: Run the IT to verify it fails**

Run: `./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=MyBatisBaseIT`
Expected: FAIL. `uuidRoundTripsThroughTheUuidType` errors, because MyBatis has no handler for `java.util.UUID` yet.

- [ ] **Step 7: Implement the UUID handler**

Create `src/main/java/com/memox/common/type_handler/UuidTypeHandler.java`:

```java
package com.memox.common.type_handler;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

/**
 * Maps {@link UUID} to PostgreSQL's native {@code uuid} column (ADR-007: primary keys are client-generated UUIDs).
 */
@MappedTypes(UUID.class)
@MappedJdbcTypes(value = JdbcType.OTHER, includeNullJdbcType = true)
public class UuidTypeHandler extends BaseTypeHandler<UUID> {

	@Override
	public void setNonNullParameter(PreparedStatement ps, int i, UUID parameter, JdbcType jdbcType)
			throws SQLException {
		ps.setObject(i, parameter);
	}

	@Override
	public UUID getNullableResult(ResultSet rs, String columnName) throws SQLException {
		return rs.getObject(columnName, UUID.class);
	}

	@Override
	public UUID getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
		return rs.getObject(columnIndex, UUID.class);
	}

	@Override
	public UUID getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
		return cs.getObject(columnIndex, UUID.class);
	}

}
```

- [ ] **Step 8: Run the IT to verify it passes**

Run: `./mvnw -B verify -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dit.test=MyBatisBaseIT`
Expected: `Tests run: 5, Failures: 0, Errors: 0` for `MyBatisBaseIT`, `BUILD SUCCESS`.

- [ ] **Step 9: Document the base in the README**

In `memox-api-services/README.md`, insert this section directly before `## Folder contract`:

```markdown
## Base

The shared code in `com.memox.common` that every feature reuses.

- **Errors:** throw `BusinessException(errorCode, detail)`, where `errorCode`
  comes from the feature's own enum implementing `ErrorCode`, for example
  `DeckErrorCode.DECK_NOT_FOUND`. Every error response is RFC 9457
  `application/problem+json` with a `code` property; validation errors add
  `errors: [{field, message}]`. `GlobalExceptionHandler` never returns SQL,
  constraint names or stack traces.
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
```

- [ ] **Step 10: Run the full gate**

Run: `./mvnw -B clean verify`
Expected: surefire `Tests run: 38, Failures: 0, Errors: 0` (1 + 16 + 10 + 11), failsafe `Tests run: 5, Failures: 0, Errors: 0`, `BUILD SUCCESS`.

- [ ] **Step 11: Commit**

```bash
git add memox-api-services/src/main/java/com/memox/common/type_handler memox-api-services/src/test/java/com/memox/common/type_handler memox-api-services/src/test/resources/mapper/common memox-api-services/README.md
git commit -m "feat(api): code-enum and UUID type handlers, MyBatis round-trip IT, base docs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
