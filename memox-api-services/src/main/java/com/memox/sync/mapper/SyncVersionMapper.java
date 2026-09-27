package com.memox.sync.mapper;

import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** The per-user change counter behind {@code server_version}. */
@Mapper
public interface SyncVersionMapper {

    /**
     * Reserves {@code count} consecutive versions and returns the last. The row lock is held until the transaction
     * commits, so versions follow commit order for each user.
     */
    long allocate(@Param("userId") UUID userId, @Param("count") int count);

    Long current(@Param("userId") UUID userId);
}
