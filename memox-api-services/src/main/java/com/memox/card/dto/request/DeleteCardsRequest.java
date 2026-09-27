package com.memox.card.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** {@code DELETE_CARDS} payload and {@code POST /cards/delete} body: one client batch id per card (BR-TRASH-001). */
public record DeleteCardsRequest(
        @NotEmpty @Size(max = DeleteCardsRequest.MAX_CARDS) List<@Valid @NotNull Item> items,
        @NotNull Instant deletedAt) {

    public static final int MAX_CARDS = 1000;

    public record Item(@NotNull UUID cardId, @NotNull UUID batchId) {}
}
