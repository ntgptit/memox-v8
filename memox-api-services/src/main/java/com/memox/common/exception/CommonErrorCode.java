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
