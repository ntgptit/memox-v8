package com.memox.sync.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** An entity a command changed in the client's local store; the server returns its copy on a rejection. */
public record AffectedEntity(
        @NotBlank String entityType, @NotNull UUID entityId) {}
