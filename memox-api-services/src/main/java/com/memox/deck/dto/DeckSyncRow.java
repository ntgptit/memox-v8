package com.memox.deck.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/**
 * A deck row on the sync wire, mirroring Drift's {@code deck} columns and stored values. {@code rootId} and
 * {@code depth} are derived by the server: ignored on push, authoritative on pull.
 */
@Builder
public record DeckSyncRow(
        @NotNull UUID id,
        @NotBlank String name,
        UUID parentId,
        UUID rootId,
        Integer depth,
        @NotNull @Pattern(regexp = "unset|card|deck") String contentType,
        @Pattern(regexp = "eight_box|sm2") String schedulerType,
        Integer schedulerVersion,
        String schedulerConfig,
        String studyConfig,
        Integer generation,
        Instant firstAnsweredAt,
        String sourceTemplateId,
        Integer sourceTemplateVersion,
        UUID deleteBatchId,
        @NotNull @PositiveOrZero Integer siblingPosition,
        @NotNull Instant createdAt,
        @NotNull Instant updatedAt) {}
