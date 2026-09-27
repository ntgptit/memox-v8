package com.memox.deck.enums;

import com.fasterxml.jackson.annotation.JsonProperty;

/** Where a reordered deck goes relative to its anchor sibling (UC-DECK-006). */
public enum DeckPlacement {
    @JsonProperty("before")
    BEFORE,
    @JsonProperty("after")
    AFTER
}
