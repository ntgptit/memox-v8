package com.memox.common.exception;

/**
 * One entry of the {@code errors} property on a {@code VALIDATION_FAILED} problem.
 */
public record FieldViolation(String field, String message) {
}
