package com.memox.trash.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.UUID;
import lombok.Builder;

/** A trash batch on the sync wire, mirroring Drift's {@code delete_batches}. */
@Builder
public record DeleteBatchSyncRow(
        @NotNull UUID id,
        @NotNull @Pattern(regexp = "card|deck") String itemType,
        @NotNull UUID rootItemId,
        @NotNull Instant deletedAt) {}
