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

    /**
     * Serializes this user's sync writes until the transaction ends, so a subtree read and the write that follows it
     * cannot interleave with another device's operation (for example two cross moves forming a cycle).
     */
    void lockUser(@Param("userId") UUID userId);
}
