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
