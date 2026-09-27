package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

/**
 * {@code DELETE_DECK} payload (with {@code deckId}) and {@code DELETE /decks/{id}} body. {@code batchId} is the
 * client's id for the Trash batch; {@code deletedAt} starts the retention (BR-TRASH-009).
 */
public record DeleteDeckRequest(
        @NotNull UUID batchId, @NotNull Instant deletedAt) {}
