package com.memox.common.exception;

import jakarta.validation.ConstraintViolationException;
import java.util.List;
import java.util.Locale;
import java.util.stream.Stream;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSourceResolvable;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.validation.method.ParameterValidationResult;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * Maps every exception that leaves a controller to an RFC 9457 {@link ProblemDetail} with an extra {@code code}
 * property, plus {@code errors} for invalid fields. The {@code detail} text always comes from
 * {@code messages.properties}, so no exception message, stack trace or SQL reaches the client.
 * <p>
 * Spring MVC's own exceptions (405, 415, malformed JSON, ...) are handled by {@link ResponseEntityExceptionHandler};
 * every path funnels through {@link #handleExceptionInternal}.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final String CODE_PROPERTY = "code";
    private static final String ERRORS_PROPERTY = "errors";

    @ExceptionHandler(BusinessException.class)
    ResponseEntity<Object> handleBusiness(BusinessException ex, WebRequest request) {
        return handleExceptionInternal(
                ex, null, new HttpHeaders(), ex.getErrorCode().getStatus(), request);
    }

    /** Without this, the catch-all below would turn a method-security denial into a 500. */
    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<Object> handleAccessDenied(AccessDeniedException ex, WebRequest request) {
        return handleExceptionInternal(ex, null, new HttpHeaders(), HttpStatus.FORBIDDEN, request);
    }

    /** A service-level {@code @Validated} check; same response as an invalid request body. */
    @ExceptionHandler(ConstraintViolationException.class)
    ResponseEntity<Object> handleConstraintViolation(ConstraintViolationException ex, WebRequest request) {
        return handleExceptionInternal(ex, null, new HttpHeaders(), HttpStatus.BAD_REQUEST, request);
    }

    /** A unique, foreign-key or check constraint rejected the write; neither the SQL nor the constraint is returned. */
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<Object> handleDataIntegrity(DataIntegrityViolationException ex, WebRequest request) {
        return handleExceptionInternal(ex, null, new HttpHeaders(), HttpStatus.CONFLICT, request);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<Object> handleUnexpected(Exception ex, WebRequest request) {
        return handleExceptionInternal(ex, null, new HttpHeaders(), HttpStatus.INTERNAL_SERVER_ERROR, request);
    }

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex, @Nullable Object body, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        ErrorCode code = errorCodeOf(ex, status);
        Locale locale = LocaleContextHolder.getLocale();
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                status, getMessageSource().getMessage(code.getMessageKey(), null, locale));
        problem.setProperty(CODE_PROPERTY, code.name());
        if (isValidationFailure(ex)) {
            problem.setProperty(ERRORS_PROPERTY, violationsOf(ex, locale));
        }
        logFailure(ex, status, code, request);
        return super.handleExceptionInternal(ex, problem, headers, status, request);
    }

    private static ErrorCode errorCodeOf(Exception ex, HttpStatusCode status) {
        if (ex instanceof BusinessException business) {
            return business.getErrorCode();
        }
        if (isValidationFailure(ex)) {
            return ErrorCode.VALIDATION_FAILED;
        }
        return ErrorCode.fromStatus(status);
    }

    private static boolean isValidationFailure(Exception ex) {
        return ex instanceof BindException
                || ex instanceof HandlerMethodValidationException
                || ex instanceof ConstraintViolationException;
    }

    // ponytail: field and parameter errors only; add class-level errors when a request needs them
    private List<FieldViolation> violationsOf(Exception ex, Locale locale) {
        if (ex instanceof BindException bind) {
            return bind.getFieldErrors().stream()
                    .map(error -> new FieldViolation(
                            error.getField(), getMessageSource().getMessage(error, locale)))
                    .toList();
        }
        if (ex instanceof HandlerMethodValidationException methodValidation) {
            return methodValidation.getParameterValidationResults().stream()
                    .flatMap(result -> violationsOf(result, locale))
                    .toList();
        }
        return ((ConstraintViolationException) ex)
                .getConstraintViolations().stream()
                        .map(violation ->
                                new FieldViolation(violation.getPropertyPath().toString(), violation.getMessage()))
                        .toList();
    }

    private Stream<FieldViolation> violationsOf(ParameterValidationResult result, Locale locale) {
        return result.getResolvableErrors().stream()
                .map(error -> new FieldViolation(
                        fieldOf(result, error), getMessageSource().getMessage(error, locale)));
    }

    private static String fieldOf(ParameterValidationResult result, MessageSourceResolvable error) {
        if (error instanceof FieldError fieldError) {
            return fieldError.getField();
        }
        return result.getMethodParameter().getParameterName();
    }

    /**
     * 5xx is logged with its stack trace. 4xx is logged without the exception message, which can carry rejected
     * field values such as passwords.
     */
    private static void logFailure(Exception ex, HttpStatusCode status, ErrorCode code, WebRequest request) {
        if (status.is5xxServerError()) {
            log.error("Request {} failed: code={}", request.getDescription(false), code, ex);
            return;
        }
        log.warn(
                "Request {} rejected: code={}, exception={}",
                request.getDescription(false),
                code,
                ex.getClass().getSimpleName());
    }

    public record FieldViolation(String field, String message) {}
}
