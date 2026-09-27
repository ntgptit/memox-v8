package com.memox.sync.service.impl;

import static org.assertj.core.api.Assertions.assertThat;

import com.memox.TestcontainersConfiguration;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
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
 * A client retries a create with the same Idempotency-Key while the first request is still running. The retry must
 * wait for the first and then write nothing, not re-run the create and fail with CONFLICT (API-A2 spec D7).
 */
@SpringBootTest
@Import(TestcontainersConfiguration.class)
class IdempotencyServiceImplIT {

    @Autowired
    IdempotencyService idempotencyService;

    @Autowired
    DeckService deckService;

    @Autowired
    TransactionTemplate transactionTemplate;

    @Test
    void aConcurrentReplayOfTheSameKeyWaitsAndWritesNothing() throws Exception {
        WriteContext ctx = new WriteContext(UUID.randomUUID(), WriteContext.REST_DEVICE);
        UUID key = UUID.randomUUID();
        CreateRootDeckRequest create = new CreateRootDeckRequest(UUID.randomUUID(), "Root", "sm2");
        Runnable write = () -> deckService.createRootDeck(ctx, create);

        CountDownLatch firstWrote = new CountDownLatch(1);
        CountDownLatch replayStarted = new CountDownLatch(1);
        CompletableFuture<Void> first =
                CompletableFuture.runAsync(() -> transactionTemplate.executeWithoutResult(status -> {
                    idempotencyService.runOnce(ctx.userId(), key, write);
                    firstWrote.countDown();
                    awaitQuietly(replayStarted);
                }));
        firstWrote.await(10, TimeUnit.SECONDS);
        CompletableFuture<Throwable> replay = CompletableFuture.supplyAsync(() -> {
            replayStarted.countDown();
            try {
                idempotencyService.runOnce(ctx.userId(), key, write);
                return null;
            } catch (RuntimeException e) {
                return e;
            }
        });

        first.get(20, TimeUnit.SECONDS);
        assertThat(replay.get(20, TimeUnit.SECONDS)).isNull();
    }

    /** Keeps the first transaction open briefly so the replay overlaps it. */
    private static void awaitQuietly(CountDownLatch latch) {
        try {
            latch.await(3, TimeUnit.SECONDS);
            Thread.sleep(500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
