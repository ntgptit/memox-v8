package com.memox.sync.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum OperationStatus {
    @JsonProperty("applied")
    APPLIED,
    @JsonProperty("rejected")
    REJECTED
}
