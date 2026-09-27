package com.memox.trash.model;

import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** A server {@code delete_batch} row. */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeleteBatch {

    private UUID id;
    private UUID userId;
    private String itemType;
    private UUID rootItemId;
    private Instant deletedAt;
    private Long serverVersion;
    private UUID lastDeviceId;
    private Instant tombstonedAt;
}
