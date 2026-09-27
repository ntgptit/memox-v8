package com.memox.card.dto.response;

import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A card as REST clients see it. */
@Builder
public record CardResponse(
        UUID id,
        UUID deckId,
        String front,
        String back,
        String example,
        String hint,
        String pronunciation,
        boolean isFlagged,
        Instant createdAt,
        Instant updatedAt) {}
