package com.memox.sync.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;

/** Wire values are lowercase: {@code upsert}, {@code delete} (spec §4.1). */
public enum SyncOperationType {
    @JsonProperty("upsert")
    UPSERT,
    @JsonProperty("delete")
    DELETE
}
