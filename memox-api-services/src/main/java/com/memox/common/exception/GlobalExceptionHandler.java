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
