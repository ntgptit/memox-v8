package com.memox.sync.service.impl;

import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class IdempotencyServiceImpl implements IdempotencyService {

    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final ChangeVersions changeVersions;

    @Override
    @Transactional
    public void runOnce(UUID userId, UUID key, Runnable write) {
        if (key == null) {
            write.run();
            return;
        }
        // Lock before the check: a concurrent replay waits for the first request and then sees its key.
        changeVersions.lock(new WriteContext(userId, WriteContext.REST_DEVICE));
        if (syncAppliedOpMapper.findServerVersion(userId, key) != null) {
            return;
        }
        write.run();
        syncAppliedOpMapper.insert(userId, key, changeVersions.latest(userId));
    }
}
