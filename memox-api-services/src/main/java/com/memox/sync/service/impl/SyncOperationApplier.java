package com.memox.sync.service.impl;

import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import java.util.UUID;
import java.util.function.Consumer;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Applies one operation in its own transaction, so a rejection rolls back only that operation (spec §4.1). */
@Component
@RequiredArgsConstructor
class SyncOperationApplier {

    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final ChangeVersions changeVersions;

    /** @return the user's latest version once the write is done */
    @Transactional
    public long apply(WriteContext context, UUID opId, Consumer<WriteContext> write) {
        changeVersions.lock(context);
        write.accept(context);
        long version = changeVersions.latest(context.userId());
        syncAppliedOpMapper.insert(context.userId(), opId, version);
        return version;
    }
}
