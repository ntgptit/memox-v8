package com.memox.trash.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncVersionMapper;
import com.memox.sync.service.SyncEntityHandler;
import com.memox.trash.dto.DeleteBatchSyncRow;
import com.memox.trash.mapper.DeleteBatchSyncMapper;
import com.memox.trash.model.DeleteBatch;
import jakarta.validation.Validator;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Syncs trash batches: whole-row upsert, tombstone on delete, no tree rules (app deck-sync spec §6). */
@Component
@RequiredArgsConstructor
public class DeleteBatchSyncHandler implements SyncEntityHandler {

    public static final String ENTITY_TYPE = "delete_batch";

    private final DeleteBatchSyncMapper deleteBatchSyncMapper;
    private final SyncVersionMapper syncVersionMapper;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode rowJson) {
        DeleteBatchSyncRow row = parse(rowJson, entityId);
        ownedOrNull(userId, entityId);
        long version = syncVersionMapper.allocate(userId, 1);
        DeleteBatch batch = DeleteBatch.builder()
                .id(row.id())
                .userId(userId)
                .itemType(row.itemType())
                .rootItemId(row.rootItemId())
                .deletedAt(row.deletedAt())
                .serverVersion(version)
                .lastDeviceId(deviceId)
                .build();
        deleteBatchSyncMapper.upsertDeleteBatch(batch);
        return version;
    }

    @Override
    public long delete(UUID userId, UUID deviceId, UUID entityId) {
        DeleteBatch existing = ownedOrNull(userId, entityId);
        if (existing == null) {
            Long current = syncVersionMapper.current(userId);
            return current == null ? 0L : current;
        }
        if (existing.getTombstonedAt() != null) {
            return existing.getServerVersion();
        }
        long version = syncVersionMapper.allocate(userId, 1);
        deleteBatchSyncMapper.tombstoneDeleteBatch(entityId, version, deviceId);
        return version;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deleteBatchSyncMapper.findChangesSince(userId, since, limit).stream()
                .map(DeleteBatchSyncHandler::toChange)
                .toList();
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        DeleteBatch batch = deleteBatchSyncMapper.findDeleteBatchById(entityId);
        if (batch == null || !batch.getUserId().equals(userId)) {
            return null;
        }
        return toChange(batch);
    }

    private DeleteBatchSyncRow parse(JsonNode rowJson, UUID entityId) {
        try {
            DeleteBatchSyncRow row = objectMapper.treeToValue(rowJson, DeleteBatchSyncRow.class);
            if (row == null
                    || !entityId.equals(row.id())
                    || !validator.validate(row).isEmpty()) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return row;
        } catch (JsonProcessingException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }

    private DeleteBatch ownedOrNull(UUID userId, UUID entityId) {
        DeleteBatch batch = deleteBatchSyncMapper.findDeleteBatchById(entityId);
        if (batch != null && !batch.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        return batch;
    }

    private static SyncChange toChange(DeleteBatch batch) {
        boolean deleted = batch.getTombstonedAt() != null;
        DeleteBatchSyncRow row = deleted
                ? null
                : DeleteBatchSyncRow.builder()
                        .id(batch.getId())
                        .itemType(batch.getItemType())
                        .rootItemId(batch.getRootItemId())
                        .deletedAt(batch.getDeletedAt())
                        .build();
        return new SyncChange(ENTITY_TYPE, batch.getId(), batch.getServerVersion(), deleted, row);
    }
}
