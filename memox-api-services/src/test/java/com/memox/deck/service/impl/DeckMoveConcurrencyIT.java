package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;

import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.MoveDeckRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.service.DeckService;
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
 * Two devices move X under Y and Y under X at once. Each move is acyclic alone; together they would form a cycle.
 * The per-user lock serializes them, so the second sees the first and is rejected.
 */
@SpringBootTest
@Import(TestcontainersConfiguration.class)
class DeckMoveConcurrencyIT {

    @Autowired
    DeckService deckService;

    @Autowired
    DeckMapper deckMapper;

    @Autowired
    TransactionTemplate transactionTemplate;

    @Test
    void concurrentCrossMovesNeverFormACycle() throws Exception {
        WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());
        UUID root = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(root, "Root", "sm2"));
        deckService.createSubDeck(ctx, root, new CreateSubDeckRequest(x, "X"));
        deckService.createSubDeck(ctx, root, new CreateSubDeckRequest(y, "Y"));

        CountDownLatch firstApplied = new CountDownLatch(1);
        CountDownLatch secondDone = new CountDownLatch(1);
        CompletableFuture<Void> first =
                CompletableFuture.runAsync(() -> transactionTemplate.executeWithoutResult(status -> {
                    deckService.moveDeck(ctx, x, new MoveDeckRequest(y));
                    firstApplied.countDown();
                    awaitQuietly(secondDone);
                }));
        firstApplied.await(10, TimeUnit.SECONDS);
        CompletableFuture<ErrorCode> second = CompletableFuture.supplyAsync(() -> {
            try {
                deckService.moveDeck(ctx, y, new MoveDeckRequest(x));
                return null;
            } catch (BusinessException e) {
                return e.getErrorCode();
            } finally {
                secondDone.countDown();
            }
        });

        first.get(20, TimeUnit.SECONDS);
        assertThat(second.get(20, TimeUnit.SECONDS)).isEqualTo(ErrorCode.DECK_TREE_CYCLE);
        assertThat(deckMapper.findDeckById(y).getParentId()).isEqualTo(root);
    }

    /** Holds the first transaction open briefly; the second move blocks on the user lock meanwhile. */
    private static void awaitQuietly(CountDownLatch latch) {
        try {
            latch.await(3, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
