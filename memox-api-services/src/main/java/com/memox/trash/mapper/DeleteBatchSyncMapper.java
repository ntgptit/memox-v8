package com.memox.trash.mapper;

import com.memox.trash.model.DeleteBatch;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DeleteBatchSyncMapper {

    DeleteBatch findDeleteBatchById(@Param("id") UUID id);

    void upsertDeleteBatch(DeleteBatch batch);

    void tombstoneDeleteBatch(
            @Param("id") UUID id, @Param("serverVersion") long serverVersion, @Param("deviceId") UUID deviceId);

    List<DeleteBatch> findChangesSince(
            @Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);
}
