package com.memox.sync.dto.request;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import lombok.Builder;

/**
 * One outbox entry (API-A2 spec §4.1). {@code kind} is {@value #COMMAND} (with {@code type} and {@code payload}) or
 * {@value #PATCH} (with {@code entityType}, {@code entityId}, {@code group} and {@code fields}). Everything except
 * {@code opId} is checked per operation by the service, so one malformed operation never fails the whole push.
 */
@Builder
public record SyncOperation(
        @NotNull UUID opId,
        String kind,
        String type,
        String entityType,
        UUID entityId,
        String group,
        JsonNode payload,
        JsonNode fields,
        @Size(max = SyncOperation.MAX_AFFECTED) List<@Valid @NotNull AffectedEntity> affected) {

    public static final String COMMAND = "command";
    public static final String PATCH = "patch";
    public static final int MAX_AFFECTED = 1000;
}
