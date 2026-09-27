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
