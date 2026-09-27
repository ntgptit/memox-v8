package com.memox.sync.service;

import java.util.UUID;

/** Who writes: the owner from {@code CurrentUserProvider} and the device that sent the write, kept for diagnostics. */
public record WriteContext(UUID userId, UUID deviceId) {

    /** The device recorded for a REST write that sends no {@code X-Device-Id}. */
    public static final UUID REST_DEVICE = new UUID(0L, 0L);

    public static final String DEVICE_HEADER = "X-Device-Id";
    public static final String IDEMPOTENCY_HEADER = "Idempotency-Key";

    /** A REST write: the current user and the optional device header. */
    public static WriteContext rest(UUID userId, UUID deviceId) {
        return new WriteContext(userId, deviceId == null ? REST_DEVICE : deviceId);
    }
}
