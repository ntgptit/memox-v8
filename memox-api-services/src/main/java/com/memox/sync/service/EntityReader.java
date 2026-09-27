package com.memox.sync.service;

import com.memox.sync.dto.response.SyncChange;
import java.util.List;
import java.util.UUID;

/** Reads one synced entity type for the change feed and for rejections. One implementation per synced table. */
public interface EntityReader {

    String entityType();

    /**
     * The owner's copy (a tombstone when purged), {@link SyncChange#absent} when the id was never stored, or
     * {@code null} when another user owns it, so a rejection never leaks it.
     */
    SyncChange current(UUID userId, UUID entityId);

    /** Changes with {@code server_version > since}, ascending, at most {@code limit}. */
    List<SyncChange> changesSince(UUID userId, long since, int limit);
}
