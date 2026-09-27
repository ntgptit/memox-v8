package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.sync.dto.response.SyncChange;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class DeckSyncHandlerIT {

    private static final Instant T = Instant.parse("2026-09-27T01:00:00Z");

    private static final UUID DEVICE = UUID.randomUUID();

    @Autowired
    private DeckSyncHandler handler;

    @Autowired
    private ObjectMapper objectMapper;

    private final UUID user = UUID.randomUUID();

    @Test
    void storesARootWithDerivedRootIdAndDepth() {
        UUID root = UUID.randomUUID();

        long version = handler.upsert(user, DEVICE, root, row(root, null, "deck", "sm2", UUID.randomUUID(), 99));

        DeckSyncRow stored = currentRow(root);
        assertThat(version).isPositive();
        assertThat(stored.rootId()).isEqualTo(root);
        assertThat(stored.depth()).isEqualTo(1);
    }

    @Test
    void derivesAChildsPlacementFromItsParentIgnoringTheClient() {
        UUID root = createRoot();
        UUID child = UUID.randomUUID();

        handler.upsert(user, DEVICE, child, row(child, root, "unset", null, UUID.randomUUID(), 7));

        assertThat(currentRow(child).rootId()).isEqualTo(root);
        assertThat(currentRow(child).depth()).isEqualTo(2);
    }

    @Test
    void movingADeckRewritesItsSubtreeWithOneVersionPerRow() {
        UUID rootA = createRoot();
        UUID rootB = createRoot();
        UUID x = createChild(rootA);
        UUID y = createChild(x);

        long moved = handler.upsert(user, DEVICE, x, row(x, rootB, "deck", null, rootA, 2));

        assertThat(currentRow(x).rootId()).isEqualTo(rootB);
        assertThat(currentRow(y).rootId()).isEqualTo(rootB);
        assertThat(currentRow(y).depth()).isEqualTo(3);
        assertThat(handler.current(user, y).serverVersion()).isEqualTo(moved + 1);
    }

    @Test
    void rejectsACycle() {
        UUID root = createRoot();
        UUID x = createChild(root);
        UUID y = createChild(x);

        assertThatThrownBy(() -> handler.upsert(user, DEVICE, x, row(x, y, "deck", null, root, 3)))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_TREE_CYCLE);
        assertThat(currentRow(x).rootId()).isEqualTo(root);
    }

    @Test
    void rejectsAMoveDeeperThanTenLevels() {
        UUID parent = createRoot();
        for (int level = 2; level <= 9; level++) {
            parent = createChild(parent);
        }
        UUID otherRoot = createRoot();
        UUID a = createChild(otherRoot);
        createChild(a);
        UUID finalParent = parent;

        assertThatThrownBy(() -> handler.upsert(user, DEVICE, a, row(a, finalParent, "deck", null, otherRoot, 2)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_TREE_TOO_DEEP);
    }

    @Test
    void rejectsAMissingOrDeletedParent() {
        UUID orphan = UUID.randomUUID();
        UUID root = createRoot();
        handler.delete(user, DEVICE, root);

        assertThatThrownBy(() ->
                        handler.upsert(user, DEVICE, orphan, row(orphan, UUID.randomUUID(), "unset", null, orphan, 2)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_PARENT_MISSING);
        assertThatThrownBy(() -> handler.upsert(user, DEVICE, orphan, row(orphan, root, "unset", null, root, 2)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.DECK_PARENT_MISSING);
    }

    @Test
    void refusesToTouchAnotherUsersDeck() {
        UUID root = createRoot();

        assertThatThrownBy(
                        () -> handler.upsert(UUID.randomUUID(), DEVICE, root, row(root, null, "deck", "sm2", root, 1)))
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.SYNC_ENTITY_CONFLICT);
        assertThat(handler.current(UUID.randomUUID(), root)).isNull();
    }

    @Test
    void deleteTombstonesTheSubtree() {
        UUID root = createRoot();
        UUID child = createChild(root);

        handler.delete(user, DEVICE, root);

        assertThat(handler.current(user, root).deleted()).isTrue();
        assertThat(handler.current(user, child).deleted()).isTrue();
        assertThat(handler.current(user, child).row()).isNull();
    }

    @Test
    void changesComeInVersionOrderAfterTheCursor() {
        UUID root = createRoot();
        long cursor = handler.current(user, root).serverVersion();
        UUID child = createChild(root);
        handler.delete(user, DEVICE, child);

        List<SyncChange> changes = handler.changesSince(user, cursor, 10);

        assertThat(changes).extracting(SyncChange::entityId).containsExactly(child);
        assertThat(changes.get(0).deleted()).isTrue();
        assertThat(handler.changesSince(user, 0, 10))
                .extracting(SyncChange::serverVersion)
                .isSorted();
    }

    private UUID createRoot() {
        UUID id = UUID.randomUUID();
        handler.upsert(user, DEVICE, id, row(id, null, "deck", "sm2", id, 1));
        return id;
    }

    private UUID createChild(UUID parent) {
        UUID id = UUID.randomUUID();
        handler.upsert(user, DEVICE, id, row(id, parent, "deck", null, parent, 2));
        return id;
    }

    private DeckSyncRow currentRow(UUID id) {
        return (DeckSyncRow) handler.current(user, id).row();
    }

    /** {@code clientRootId} and {@code clientDepth} are deliberately wrong: the server must ignore them. */
    private JsonNode row(
            UUID id, UUID parentId, String contentType, String schedulerType, UUID clientRootId, int clientDepth) {
        DeckSyncRow row = new DeckSyncRow(
                id,
                "Deck " + id,
                parentId,
                clientRootId,
                clientDepth,
                contentType,
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
        return objectMapper.valueToTree(row);
    }
}
