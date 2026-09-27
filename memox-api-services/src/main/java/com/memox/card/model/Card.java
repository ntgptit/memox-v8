package com.memox.card.model;

import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** A server {@code card} row. */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Card {
    private UUID id;
    private UUID userId;
    private UUID deckId;
    private String front;
    private String back;
    private String example;
    private String hint;
    private String pronunciation;
    private boolean flagged;
    private UUID deleteBatchId;
    private Instant createdAt;
    private Instant updatedAt;
    private Long serverVersion;
    private UUID lastDeviceId;
    private Instant deletedAt;
}
