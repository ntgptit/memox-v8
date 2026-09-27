package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code MOVE_DECK} payload (with {@code deckId}) and {@code POST /decks/{id}/move} body. */
public record MoveDeckRequest(@NotNull UUID targetParentId) {}
