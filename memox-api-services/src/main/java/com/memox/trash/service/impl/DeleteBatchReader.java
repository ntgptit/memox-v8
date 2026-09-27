package com.memox.trash.service.impl;

import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.service.EntityReader;
import com.memox.trash.dto.DeleteBatchSyncRow;
import com.memox.trash.mapper.DeleteBatchMapper;
import com.memox.trash.model.DeleteBatch;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The {@code delete_batch} rows of the change feed; an undone batch is a tombstone. */
@Component
@RequiredArgsConstructor
public class DeleteBatchReader implements EntityReader {

    public static final String ENTITY_TYPE = "delete_batch";

    private final DeleteBatchMapper deleteBatchMapper;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(entityId);
        if (batch == null) {
            return SyncChange.absent(ENTITY_TYPE, entityId);
        }
        return batch.getUserId().equals(userId) ? toChange(batch) : null;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deleteBatchMapper.findChangesSince(userId, since, limit).stream()
                .map(DeleteBatchReader::toChange)
                .toList();
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
