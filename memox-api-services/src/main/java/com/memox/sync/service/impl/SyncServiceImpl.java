package com.memox.sync.service.impl;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.dto.request.AffectedEntity;
import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.OperationResult;
import com.memox.sync.dto.response.PushResponse;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncAppliedOpMapper;
import com.memox.sync.service.EntityReader;
import com.memox.sync.service.SyncCommandHandler;
import com.memox.sync.service.SyncPatchHandler;
import com.memox.sync.service.SyncService;
import com.memox.sync.service.WriteContext;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class SyncServiceImpl implements SyncService {

    private final CurrentUserProvider currentUserProvider;
    private final SyncAppliedOpMapper syncAppliedOpMapper;
    private final SyncOperationApplier syncOperationApplier;
    private final Map<String, SyncCommandHandler> commands;
    private final Map<String, SyncPatchHandler> patches;
    private final Map<String, EntityReader> readers;

    public SyncServiceImpl(
            CurrentUserProvider currentUserProvider,
            SyncAppliedOpMapper syncAppliedOpMapper,
            SyncOperationApplier syncOperationApplier,
            ObjectProvider<SyncCommandHandler> commands,
            ObjectProvider<SyncPatchHandler> patches,
            ObjectProvider<EntityReader> readers) {
        this.currentUserProvider = currentUserProvider;
        this.syncAppliedOpMapper = syncAppliedOpMapper;
        this.syncOperationApplier = syncOperationApplier;
        // ObjectProvider, not List: a slice may register no handler of a kind yet.
        this.commands = commands.orderedStream()
                .collect(Collectors.toUnmodifiableMap(SyncCommandHandler::type, Function.identity()));
        this.patches = patches.orderedStream()
                .collect(Collectors.toUnmodifiableMap(
                        handler -> patchKey(handler.entityType(), handler.group()), Function.identity()));
        this.readers = readers.orderedStream()
                .collect(Collectors.toUnmodifiableMap(EntityReader::entityType, Function.identity()));
    }

    @Override
    public PushResponse push(PushRequest request) {
        WriteContext context = new WriteContext(currentUserProvider.currentUserId(), request.deviceId());
        List<OperationResult> results = request.operations().stream()
                .map(operation -> pushOne(context, operation))
                .toList();
        return new PushResponse(results);
    }

    @Override
    public ChangesResponse changesSince(long since, int limit) {
        UUID userId = currentUserProvider.currentUserId();
        List<SyncChange> merged = readers.values().stream()
                .flatMap(reader -> reader.changesSince(userId, since, limit + 1).stream())
                .sorted(Comparator.comparingLong(SyncChange::serverVersion))
                .toList();
        boolean hasMore = merged.size() > limit;
        List<SyncChange> page = hasMore ? merged.subList(0, limit) : merged;
        long nextSince = page.isEmpty() ? since : page.get(page.size() - 1).serverVersion();
        return new ChangesResponse(page, nextSince, hasMore);
    }

    private OperationResult pushOne(WriteContext context, SyncOperation operation) {
        UUID userId = context.userId();
        Long alreadyApplied = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
        if (alreadyApplied != null) {
            return OperationResult.applied(operation.opId(), alreadyApplied);
        }
        try {
            Consumer<WriteContext> write = resolve(operation);
            return OperationResult.applied(
                    operation.opId(), syncOperationApplier.apply(context, operation.opId(), write));
        } catch (BusinessException e) {
            return rejected(userId, operation, e.getErrorCode());
        } catch (DataIntegrityViolationException e) {
            Long appliedMeanwhile = syncAppliedOpMapper.findServerVersion(userId, operation.opId());
            if (appliedMeanwhile != null) {
                return OperationResult.applied(operation.opId(), appliedMeanwhile);
            }
            log.warn("Sync operation {} violated a constraint", operation.opId(), e);
            return rejected(userId, operation, ErrorCode.CONFLICT);
        }
    }

    private Consumer<WriteContext> resolve(SyncOperation operation) {
        if (SyncOperation.COMMAND.equals(operation.kind())) {
            SyncCommandHandler handler = operation.type() == null ? null : commands.get(operation.type());
            if (handler == null) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return context -> handler.body().accept(context, operation.payload());
        }
        if (SyncOperation.PATCH.equals(operation.kind())) {
            SyncPatchHandler handler = patches.get(patchKey(operation.entityType(), operation.group()));
            if (handler == null || operation.entityId() == null) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return context -> handler.applier().apply(context, operation.entityId(), operation.fields());
        }
        throw new BusinessException(ErrorCode.VALIDATION_FAILED);
    }

    private OperationResult rejected(UUID userId, SyncOperation operation, ErrorCode code) {
        Set<AffectedEntity> targets = new LinkedHashSet<>();
        if (SyncOperation.PATCH.equals(operation.kind())
                && operation.entityType() != null
                && operation.entityId() != null) {
            targets.add(new AffectedEntity(operation.entityType(), operation.entityId()));
        }
        if (operation.affected() != null) {
            targets.addAll(operation.affected());
        }
        List<SyncChange> current = targets.stream()
                .map(target -> {
                    EntityReader reader = readers.get(target.entityType());
                    return reader == null ? null : reader.current(userId, target.entityId());
                })
                .filter(Objects::nonNull)
                .toList();
        return OperationResult.rejected(operation.opId(), code.name(), current);
    }

    private static String patchKey(String entityType, String group) {
        return entityType + "/" + group;
    }
}
