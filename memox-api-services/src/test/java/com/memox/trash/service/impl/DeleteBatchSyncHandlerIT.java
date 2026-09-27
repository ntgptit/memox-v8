package com.memox.trash.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.service.impl.DeckSyncHandler;
import com.memox.sync.dto.response.SyncChange;
import com.memox.trash.dto.DeleteBatchSyncRow;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class DeleteBatchSyncHandlerIT {

    private static final Instant T = Instant.parse("2026-09-27T01:00:00Z");
    private static final UUID DEVICE = UUID.randomUUID();

    @Autowired
    private DeleteBatchSyncHandler handler;

    @Autowired
    private DeckSyncHandler deckHandler;

    @Autowired
    private ObjectMapper objectMapper;

    private final UUID user = UUID.randomUUID();

    @Test
    void storesAndReturnsABatch() {
        UUID id = UUID.randomUUID();
        UUID root = UUID.randomUUID();

        long version = handler.upsert(
                user,
                DEVICE,
                id,
                objectMapper.valueToTree(DeleteBatchSyncRow.builder()
                        .id(id)
                        .itemType("deck")
                        .rootItemId(root)
                        .deletedAt(T)
                        .build()));

        SyncChange current = handler.current(user, id);
        assertThat(current.serverVersion()).isEqualTo(version);
        assertThat(((DeleteBatchSyncRow) current.row()).deletedAt()).isEqualTo(T);
        assertThat(handler.changesSince(user, version - 1, 10))
                .extracting(SyncChange::entityId)
                .containsExactly(id);
    }

    @Test
    void deleteTombstonesTheBatchAndIsIdempotent() {
        UUID id = UUID.randomUUID();
        handler.upsert(
                user,
                DEVICE,
                id,
                objectMapper.valueToTree(DeleteBatchSyncRow.builder()
                        .id(id)
                        .itemType("card")
                        .rootItemId(UUID.randomUUID())
                        .deletedAt(T)
                        .build()));

        long first = handler.delete(user, DEVICE, id);

        assertThat(handler.current(user, id).deleted()).isTrue();
        assertThat(handler.delete(user, DEVICE, id)).isEqualTo(first);
    }

    @Test
    void rejectsAnotherUsersBatchAndABadItemType() {
        UUID id = UUID.randomUUID();
        handler.upsert(
                user,
                DEVICE,
                id,
                objectMapper.valueToTree(DeleteBatchSyncRow.builder()
                        .id(id)
                        .itemType("deck")
                        .rootItemId(UUID.randomUUID())
                        .deletedAt(T)
                        .build()));

        assertThatThrownBy(() -> handler.upsert(
                        UUID.randomUUID(),
                        DEVICE,
                        id,
                        objectMapper.valueToTree(DeleteBatchSyncRow.builder()
                                .id(id)
                                .itemType("deck")
                                .rootItemId(UUID.randomUUID())
                                .deletedAt(T)
                                .build())))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.SYNC_ENTITY_CONFLICT);
        UUID other = UUID.randomUUID();
        assertThatThrownBy(() -> handler.upsert(
                        user,
                        DEVICE,
                        other,
                        objectMapper.valueToTree(DeleteBatchSyncRow.builder()
                                .id(other)
                                .itemType("tag")
                                .rootItemId(UUID.randomUUID())
                                .deletedAt(T)
                                .build())))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.VALIDATION_FAILED);
    }

    @Test
    void refusesADeckRowTheLocalChecksWouldRefuse() {
        UUID root = UUID.randomUUID();
        // A root without generation and scheduler_version breaks the app's CHECKs (deck.drift).
        DeckSyncRow bad = DeckSyncRow.builder()
                .id(root)
                .name("R")
                .contentType("deck")
                .schedulerType("sm2")
                .siblingPosition(0)
                .createdAt(T)
                .updatedAt(T)
                .build();

        assertThatThrownBy(() -> deckHandler.upsert(user, DEVICE, root, objectMapper.valueToTree(bad)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.VALIDATION_FAILED);
    }
}
