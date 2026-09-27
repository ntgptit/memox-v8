package com.memox.deck.dto.response;

import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A deck as REST clients see it; {@code rootId}, {@code depth} and {@code contentType} are the server's. */
@Builder
public record DeckResponse(
        UUID id,
        UUID parentId,
        UUID rootId,
        int depth,
        String name,
        String contentType,
        String schedulerType,
        Integer schedulerVersion,
        Integer generation,
        String studyConfig,
        int siblingPosition,
        Instant createdAt,
        Instant updatedAt) {}
