package com.memox.sync.service.impl;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.service.impl.DeckSyncHandler;
import com.memox.sync.dto.request.SyncOperation;
import com.memox.sync.dto.request.SyncOperationType;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Two devices of one user move X under Y and Y under X at the same time. Each move is acyclic on its own; together
 * they would form a cycle. Operations of one user must be serialized so the second sees the first and is rejected.
 */
@SpringBootTest
@Import(TestcontainersConfiguration.class)
class SyncOperationApplierConcurrencyIT {

    private static final Instant T = Instant.parse("2026-09-27T01:00:00Z");

    @Autowired
    private SyncOperationApplier applier;

    @Autowired
    private DeckSyncHandler handler;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void concurrentCrossMovesNeverFormACycle() throws Exception {
        UUID user = UUID.randomUUID();
        UUID device = UUID.randomUUID();
        UUID root = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        applier.apply(user, device, upsert(root, null, "sm2"), handler);
        applier.apply(user, device, upsert(x, root, null), handler);
        applier.apply(user, device, upsert(y, root, null), handler);

        CountDownLatch firstApplied = new CountDownLatch(1);
        CountDownLatch secondDone = new CountDownLatch(1);
        CompletableFuture<Void> first =
                CompletableFuture.runAsync(() -> transactionTemplate.executeWithoutResult(status -> {
                    applier.apply(user, device, upsert(x, y, null), handler);
                    firstApplied.countDown();
                    awaitQuietly(secondDone, 3);
                }));
        firstApplied.await(10, TimeUnit.SECONDS);
        CompletableFuture<ErrorCode> second = CompletableFuture.supplyAsync(() -> {
            try {
                applier.apply(user, device, upsert(y, x, null), handler);
                return null;
            } catch (BusinessException e) {
                return e.getErrorCode();
            } finally {
                secondDone.countDown();
            }
        });

        first.get(20, TimeUnit.SECONDS);
        assertThat(second.get(20, TimeUnit.SECONDS)).isEqualTo(ErrorCode.DECK_TREE_CYCLE);
        assertThat(((DeckSyncRow) handler.current(user, y).row()).parentId()).isEqualTo(root);
    }

    private SyncOperation upsert(UUID id, UUID parentId, String schedulerType) {
        DeckSyncRow row = new DeckSyncRow(
                id,
                "Deck " + id,
                parentId,
                null,
                null,
                "deck",
                schedulerType,
                schedulerType == null ? null : 1,
                null,
                null,
                schedulerType == null ? null : 1,
                null,
                null,
                null,
                null,
                0,
                T,
                T);
        return new SyncOperation(
                UUID.randomUUID(),
                DeckSyncHandler.ENTITY_TYPE,
                id,
                SyncOperationType.UPSERT,
                objectMapper.valueToTree(row));
    }

    private static void awaitQuietly(CountDownLatch latch, int seconds) {
        try {
            latch.await(seconds, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
