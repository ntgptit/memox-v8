package com.memox.sync.dto.response;

import java.util.List;

public record ChangesResponse(List<SyncChange> changes, long nextSince, boolean hasMore) {}
