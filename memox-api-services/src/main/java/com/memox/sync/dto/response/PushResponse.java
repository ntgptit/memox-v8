package com.memox.sync.dto.response;

import java.util.List;

public record PushResponse(List<OperationResult> results) {}
