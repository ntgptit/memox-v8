package com.memox.sync.service;

import com.memox.sync.mapper.SyncVersionMapper;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The per-user lock and version counter every write goes through, REST and sync alike (API-A2 spec §4.3). */
@Component
@RequiredArgsConstructor
public class ChangeVersions {

    private final SyncVersionMapper syncVersionMapper;

    /** Serializes this user's writes until the transaction ends; re-entrant within one transaction. */
    public void lock(WriteContext context) {
        syncVersionMapper.lockUser(context.userId());
    }

    public long next(WriteContext context) {
        return syncVersionMapper.allocate(context.userId(), 1);
    }

    /** Reserves {@code count} (at least 1) consecutive versions and returns the first. */
    public long block(WriteContext context, int count) {
        return syncVersionMapper.allocate(context.userId(), count) - count + 1;
    }

    public long latest(UUID userId) {
        Long version = syncVersionMapper.current(userId);
        return version == null ? 0L : version;
    }
}
