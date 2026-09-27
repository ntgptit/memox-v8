package com.memox.sync.mapper;

import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** Operations already applied, for push idempotency (spec §4.1). */
@Mapper
public interface SyncAppliedOpMapper {

    Long findServerVersion(@Param("userId") UUID userId, @Param("opId") UUID opId);

    void insert(@Param("userId") UUID userId, @Param("opId") UUID opId, @Param("serverVersion") long serverVersion);
}
