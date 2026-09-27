package com.memox.card.dto.request;

import jakarta.validation.constraints.NotNull;

/** Patch {@code card/content} fields and {@code PATCH /cards/{id}} body; blank optional fields become null. */
public record CardContentRequest(
        @NotNull String front, @NotNull String back, String example, String hint, String pronunciation) {}
