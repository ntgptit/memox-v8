package com.memox.sync.dto.request;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** One outbox entry. {@code opId} is the idempotency key; {@code row} is required for upserts. */
public record SyncOperation(
        @NotNull UUID opId,
        @NotBlank String entityType,
        @NotNull UUID entityId,
        @NotNull SyncOperationType op,
        JsonNode row) {}
