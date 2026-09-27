package com.memox.sync.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.UUID;

/** Applies one field group of one entity type, validated by that entity's service (API-A2 spec §5). */
public record SyncPatchHandler(String entityType, String group, Applier applier) {

    @FunctionalInterface
    public interface Applier {
        void apply(WriteContext context, UUID entityId, JsonNode fields);
    }
}
