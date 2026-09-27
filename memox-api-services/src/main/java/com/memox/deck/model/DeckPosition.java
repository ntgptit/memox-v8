package com.memox.deck.model;

import java.util.UUID;

/** A sibling's new position and the version that records it. */
public record DeckPosition(UUID id, int siblingPosition, long serverVersion) {}
