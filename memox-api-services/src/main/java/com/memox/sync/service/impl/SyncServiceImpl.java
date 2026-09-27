package com.memox.sync.service.impl;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.OperationResult;
import com.memox.sync.dto.response.PushResponse;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.SyncEntityHandler;
import com.memox.sync.service.SyncService;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class SyncServiceImpl implements SyncService {

    private final CurrentUserProvider currentUserProvider;
    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final SyncOperationApplier syncOperationApplier;
    private final Map<String, SyncEntityHandler> handlers;

    public SyncServiceImpl(
            CurrentUserProvider currentUserProvider,
            SyncAppliedOpMapper syncAppliedOpMapper,
            SyncOperationApplier syncOperationApplier,
            List<SyncEntityHandler> handlers) {
        this.currentUserProvider = currentUserProvider;
        this.syncAppliedOpMapper = syncAppliedOpMapper;
        this.syncOperationApplier = syncOperationApplier;
        this.handlers = handlers.stream()
                .collect(Collectors.toUnmodifiableMap(SyncEntityHandler::entityType, Function.identity()));
    }

    @Override
    public PushResponse push(PushRequest request) {
        UUID userId = currentUserProvider.currentUserId();
        List<OperationResult> results = request.operations().stream()
                .map(operation -> pushOne(userId, request.deviceId(), operation))
                .toList();
        return new PushResponse(results);
    }

    @Override
    public ChangesResponse changesSince(long since, int limit) {
        UUID userId = currentUserProvider.currentUserId();
        List<SyncChange> merged = handlers.values().stream()
                .flatMap(handler -> handler.changesSince(userId, since, limit + 1).stream())
                .sorted(Comparator.comparingLong(SyncChange::serverVersion))
                .toList();
        boolean hasMore = merged.size() > limit;
        List<SyncChange> page = hasMore ? merged.subList(0, limit) : merged;
        long nextSince = page.isEmpty() ? since : page.get(page.size() - 1).serverVersion();
        return new ChangesResponse(page, nextSince, hasMore);
    }

    private OperationResult pushOne(UUID userId, UUID deviceId, SyncOperation operation) {
        Long alreadyApplied = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
        if (alreadyApplied != null) {
            return OperationResult.applied(operation.opId(), alreadyApplied);
        }
        SyncEntityHandler handler = handlers.get(operation.entityType());
        if (handler == null) {
            return OperationResult.rejected(operation.opId(), ErrorCode.SYNC_ENTITY_UNSUPPORTED.name(), null);
        }
        try {
            return OperationResult.applied(
                    operation.opId(), syncOperationApplier.apply(userId, deviceId, operation, handler));
        } catch (BusinessException e) {
            return rejected(userId, operation, handler, e.getErrorCode());
        } catch (DataIntegrityViolationException e) {
            Long appliedMeanwhile = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
            if (appliedMeanwhile != null) {
                return OperationResult.applied(operation.opId(), appliedMeanwhile);
            }
            log.warn("Sync operation {} violated a constraint", operation.opId(), e);
            return rejected(userId, operation, handler, ErrorCode.CONFLICT);
        }
    }

    private static OperationResult rejected(
            UUID userId, SyncOperation operation, SyncEntityHandler handler, ErrorCode code) {
        return OperationResult.rejected(operation.opId(), code.name(), handler.current(userId, operation.entityId()));
    }
}
