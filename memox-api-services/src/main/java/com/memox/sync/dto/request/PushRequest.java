package com.memox.sync.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

public record PushRequest(
        @NotNull UUID deviceId,
        @NotEmpty @Size(max = PushRequest.MAX_OPERATIONS) List<@Valid @NotNull SyncOperation> operations) {

    public static final int MAX_OPERATIONS = 100;
}
