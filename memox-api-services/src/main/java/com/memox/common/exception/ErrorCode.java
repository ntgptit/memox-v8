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
