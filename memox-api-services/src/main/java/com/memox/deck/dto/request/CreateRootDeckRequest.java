package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.util.UUID;

/** {@code CREATE_ROOT_DECK} payload and {@code POST /api/v1/decks} body. Name rules are checked after NFC. */
public record CreateRootDeckRequest(
        @NotNull UUID id,
        @NotNull String name,
        @NotNull @Pattern(regexp = "eight_box|sm2") String schedulerType) {}
