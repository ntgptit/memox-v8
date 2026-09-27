package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;

/** {@code RENAME_DECK} payload (with {@code deckId}) and {@code PATCH /decks/{id}} body. */
public record RenameDeckRequest(@NotNull String name) {}
