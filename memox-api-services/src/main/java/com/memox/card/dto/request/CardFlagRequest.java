package com.memox.card.dto.request;

import jakarta.validation.constraints.NotNull;

/** Patch {@code card/flag} fields and {@code PUT /cards/{id}/flag} body (BR-CARD-009). */
public record CardFlagRequest(@NotNull Boolean isFlagged) {}
