package com.memox.sync.dto.response;

import java.util.UUID;

/** One entity's state after {@code serverVersion}; {@code row} is null for a tombstone. */
public record SyncChange(String entityType, UUID entityId, long serverVersion, boolean deleted, Object row) {

    /** An id the server has never stored: the client deletes its local row. */
    public static SyncChange absent(String entityType, UUID entityId) {
        return new SyncChange(entityType, entityId, 0L, true, null);
    }
}
