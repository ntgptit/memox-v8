package com.memox.common.exception;

import lombok.Getter;

/**
 * A rule violation the client can act on. Thrown by services; {@link GlobalExceptionHandler} turns it into the
 * error body with the code's HTTP status and message.
 */
@Getter
public class BusinessException extends RuntimeException {

	private final ErrorCode errorCode;

	public BusinessException(ErrorCode errorCode) {
		super(errorCode.name());
		this.errorCode = errorCode;
	}

}
