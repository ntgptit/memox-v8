package com.memox.sync.dto.response;

import java.util.UUID;

/**
 * The outcome of one operation. {@code serverVersion} is set when applied; {@code code} and {@code current} (the
 * server's copy, null when unknown) when rejected.
 */
public record OperationResult(UUID opId, OperationStatus status, Long serverVersion, String code, SyncChange current) {

    public static OperationResult applied(UUID opId, long serverVersion) {
        return new OperationResult(opId, OperationStatus.APPLIED, serverVersion, null, null);
    }

    public static OperationResult rejected(UUID opId, String code, SyncChange current) {
        return new OperationResult(opId, OperationStatus.REJECTED, null, code, current);
    }
}
