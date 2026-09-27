package com.memox.common.exception;

import java.util.Arrays;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

/**
 * API error codes. The name is the {@code code} field of the error body; the client-facing text lives in
 * {@code messages.properties} under {@code error.<NAME>}. Generic codes come first so that
 * {@link #fromStatus(HttpStatusCode)} picks them over feature codes that share a status.
 */
@Getter
@RequiredArgsConstructor
public enum ErrorCode {
    BAD_REQUEST(HttpStatus.BAD_REQUEST),
    FORBIDDEN(HttpStatus.FORBIDDEN),
    NOT_FOUND(HttpStatus.NOT_FOUND),
    METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED),
    NOT_ACCEPTABLE(HttpStatus.NOT_ACCEPTABLE),
    CONFLICT(HttpStatus.CONFLICT),
    PAYLOAD_TOO_LARGE(HttpStatus.PAYLOAD_TOO_LARGE),
    UNSUPPORTED_MEDIA_TYPE(HttpStatus.UNSUPPORTED_MEDIA_TYPE),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR),
    SERVICE_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE),

    VALIDATION_FAILED(HttpStatus.BAD_REQUEST),

    DECK_TREE_CYCLE(HttpStatus.CONFLICT),
    DECK_TREE_TOO_DEEP(HttpStatus.CONFLICT),
    DECK_PARENT_MISSING(HttpStatus.CONFLICT),

    SYNC_ENTITY_CONFLICT(HttpStatus.CONFLICT);

    private static final String MESSAGE_KEY_PREFIX = "error.";

    private final HttpStatus status;

    public String getMessageKey() {
        return MESSAGE_KEY_PREFIX + name();
    }

    /** The generic code for a status raised by Spring MVC itself, such as 405 for an unsupported method. */
    public static ErrorCode fromStatus(HttpStatusCode status) {
        return Arrays.stream(values())
                .filter(code -> code.status.value() == status.value())
                .findFirst()
                .orElse(status.is4xxClientError() ? BAD_REQUEST : INTERNAL_ERROR);
    }
}
