package com.memox.sync.service;

import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.PushResponse;

/** The sync protocol of ADR-013 for the current user. */
public interface SyncService {

    PushResponse push(PushRequest request);

    ChangesResponse changesSince(long since, int limit);
}
