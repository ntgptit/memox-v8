package com.memox.card.dto;

import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A card on the sync wire. The app computes its own folded columns (BE-C5); {@code isFlagged} is Drift's 0/1. */
@Builder
public record CardSyncRow(
        UUID id,
        UUID deckId,
        String front,
        String back,
        String example,
        String hint,
        String pronunciation,
        boolean isFlagged,
        UUID deleteBatchId,
        Instant createdAt,
        Instant updatedAt) {}
