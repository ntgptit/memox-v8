package com.memox.sync.service;

import java.util.UUID;

/** Runs a REST write at most once per {@code Idempotency-Key}, in the write's own transaction (API-A2 spec D7). */
public interface IdempotencyService {

    /** Runs {@code write} unless {@code key} was recorded for the user; a {@code null} key always runs it. */
    void runOnce(UUID userId, UUID key, Runnable write);
}
