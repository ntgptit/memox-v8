package com.memox.card.dto.request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code CREATE_CARD} payload (with {@code deckId}) and {@code POST /decks/{id}/cards} body. */
public record CreateCardRequest(
        @NotNull UUID id,
        @NotNull String front,
        @NotNull String back,
        String example,
        String hint,
        String pronunciation) {}
