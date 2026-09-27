package com.memox.sync.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.memox.sync.dto.response.SyncChange;
import java.util.List;
import java.util.UUID;

/**
 * How one entity type is synced. One implementation per synced table (deck now; card, tags and review log next), so
 * the protocol code never changes when a type is added. Called inside the applier's transaction; reject by throwing
 * {@code BusinessException}.
 */
public interface SyncEntityHandler {

    String entityType();

    /** @return the entity's new {@code server_version} */
    long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode row);

    /** @return the entity's tombstone {@code server_version} */
    long delete(UUID userId, UUID deviceId, UUID entityId);

    /** Changes with {@code server_version > since}, ascending, at most {@code limit}. */
    List<SyncChange> changesSince(UUID userId, long since, int limit);

    /** The server's copy, or {@code null} when the entity is unknown to this user. */
    SyncChange current(UUID userId, UUID entityId);
}
