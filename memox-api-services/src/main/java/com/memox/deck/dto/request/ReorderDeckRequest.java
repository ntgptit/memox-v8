package com.memox.deck.dto.request;

import com.memox.deck.enums.DeckPlacement;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** {@code REORDER_DECK} payload (with {@code deckId}) and {@code POST /decks/{id}/reorder} body. */
public record ReorderDeckRequest(
        @NotNull UUID anchorId, @NotNull DeckPlacement placement) {}
