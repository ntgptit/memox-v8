package com.memox.card.dto.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/** {@code MOVE_CARDS} payload and {@code POST /cards/move} body; all or nothing (BR-CARD-011). */
public record MoveCardsRequest(
        @NotEmpty @Size(max = MoveCardsRequest.MAX_CARDS) List<@NotNull UUID> cardIds,
        @NotNull UUID targetDeckId) {

    public static final int MAX_CARDS = 1000;
}
