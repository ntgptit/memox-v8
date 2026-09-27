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
