package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code CREATE_SUB_DECK} payload (with {@code parentId}) and {@code POST /decks/{parentId}/sub-decks} body. */
public record CreateSubDeckRequest(
        @NotNull UUID id, @NotNull String name) {}
