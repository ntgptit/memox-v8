package com.memox.sync.service.impl;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.request.SyncOperationType;
import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.mapper.SyncVersionMapper;
import com.memox.sync.service.SyncEntityHandler;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Applies one operation in its own transaction, so a rejection rolls back only that operation (spec §4.1). */
@Component
@RequiredArgsConstructor
class SyncOperationApplier {

    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final SyncVersionMapper syncVersionMapper;

    @Transactional
    public long apply(UUID userId, UUID deviceId, SyncOperation operation, SyncEntityHandler handler) {
        syncVersionMapper.lockUser(userId);
        long serverVersion;
        if (operation.op() == SyncOperationType.DELETE) {
            serverVersion = handler.delete(userId, deviceId, operation.entityId());
        } else {
            if (operation.row() == null) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            serverVersion = handler.upsert(userId, deviceId, operation.entityId(), operation.row());
        }
        syncAppliedOpMapper.insert(userId, operation.opId(), serverVersion);
        return serverVersion;
    }
}
