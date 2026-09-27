package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.DeleteDeckRequest;
import com.memox.deck.dto.request.MoveDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.ReorderDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.enums.DeckPlacement;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import com.memox.trash.mapper.DeleteBatchMapper;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class DeckServiceImplIT {

    @Autowired
    DeckService deckService;

    @Autowired
    DeckMapper deckMapper;

    @Autowired
    DeleteBatchMapper deleteBatchMapper;

    final WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());

    UUID root(String scheduler) {
        UUID id = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(id, "Root", scheduler));
        return id;
    }

    UUID child(UUID parent) {
        UUID id = UUID.randomUUID();
        deckService.createSubDeck(ctx, parent, new CreateSubDeckRequest(id, "Child"));
        return id;
    }

    Deck deck(UUID id) {
        return deckMapper.findDeckById(id);
    }

    static void rejects(ThrowingCallable call, ErrorCode code) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(code);
    }

    @Test
    void createRootDeckSetsTheSchedulerVersionGenerationAndAppendsAfterTheLastRoot() {
        UUID first = root("sm2");
        UUID second = root("eight_box");

        assertThat(deck(first).getSchedulerVersion()).isEqualTo(1);
        assertThat(deck(first).getGeneration()).isEqualTo(1);
        assertThat(deck(first).getContentType()).isEqualTo("deck");
        assertThat(deck(first).getRootId()).isEqualTo(first);
        assertThat(deck(second).getSiblingPosition()).isEqualTo(deck(first).getSiblingPosition() + 1);
    }

    @Test
    void createSubDeckIsUnsetAndTurnsAnUnsetParentIntoADeckParent_BR_DECK_006_008() {
        UUID root = root("sm2");
        UUID a = child(root);
        long parentVersionBefore = deck(a).getServerVersion();

        UUID b = child(a);

        assertThat(deck(b).getContentType()).isEqualTo("unset");
        assertThat(deck(b).getRootId()).isEqualTo(root);
        assertThat(deck(b).getDepth()).isEqualTo(3);
        assertThat(deck(a).getContentType()).isEqualTo("deck");
        assertThat(deck(a).getServerVersion()).isGreaterThan(parentVersionBefore);
    }

    @Test
    void createSubDeckRefusesACardParentAndTheEleventhLevel_BR_DECK_001_009() {
        UUID parent = root("sm2");
        for (int level = 2; level <= 10; level++) {
            parent = child(parent);
        }
        UUID tenth = parent;
        rejects(() -> child(tenth), ErrorCode.DECK_TREE_TOO_DEEP);

        UUID root = root("sm2");
        UUID cardDeck = child(root);
        deckMapper.updateContentType(
                ctx.userId(),
                cardDeck,
                "card",
                999_999L,
                ctx.deviceId(),
                deck(root).getUpdatedAt());
        rejects(() -> child(cardDeck), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
    }

    @Test
    void createSubDeckRefusesAMissingOrForeignParentAsMissing() {
        rejects(() -> child(UUID.randomUUID()), ErrorCode.DECK_PARENT_MISSING);
        UUID theirs = UUID.randomUUID();
        deckService.createRootDeck(
                new WriteContext(UUID.randomUUID(), ctx.deviceId()), new CreateRootDeckRequest(theirs, "T", "sm2"));
        rejects(() -> child(theirs), ErrorCode.DECK_PARENT_MISSING);
    }

    @Test
    void anIdAlreadyTakenIsAConflictAndAnotherUsersIdIsNotRevealed() {
        UUID mine = root("sm2");
        rejects(
                () -> deckService.createRootDeck(ctx, new CreateRootDeckRequest(mine, "Again", "sm2")),
                ErrorCode.CONFLICT);
        rejects(
                () -> deckService.createRootDeck(
                        new WriteContext(UUID.randomUUID(), ctx.deviceId()),
                        new CreateRootDeckRequest(mine, "Stolen", "sm2")),
                ErrorCode.SYNC_ENTITY_CONFLICT);
    }

    @Test
    void renameStoresTheNfcStrippedNameAndRejectsBlankOrTooLong_BR_DECK_020() {
        UUID root = root("sm2");

        deckService.renameDeck(ctx, root, new RenameDeckRequest("  Café  "));

        assertThat(deck(root).getName()).isEqualTo("Café");
        rejects(() -> deckService.renameDeck(ctx, root, new RenameDeckRequest("  ")), ErrorCode.VALIDATION_FAILED);
        rejects(
                () -> deckService.renameDeck(ctx, root, new RenameDeckRequest("x".repeat(201))),
                ErrorCode.VALIDATION_FAILED);
        rejects(
                () -> deckService.renameDeck(ctx, UUID.randomUUID(), new RenameDeckRequest("x")),
                ErrorCode.DECK_NOT_FOUND);
    }

    @Test
    void studyOptionsAreRootOnlyValidJsonAndNullRestoresDefaults_BR_STUDY_056() {
        UUID root = root("sm2");
        UUID sub = child(root);

        deckService.updateStudyOptions(ctx, root, new StudyOptionsRequest("{\"cardLimit\":20}"));
        assertThat(deck(root).getStudyConfig()).isEqualTo("{\"cardLimit\":20}");
        deckService.updateStudyOptions(ctx, root, new StudyOptionsRequest(null));
        assertThat(deck(root).getStudyConfig()).isNull();

        rejects(
                () -> deckService.updateStudyOptions(ctx, sub, new StudyOptionsRequest("{}")),
                ErrorCode.DECK_ROOT_REQUIRED);
        rejects(
                () -> deckService.updateStudyOptions(ctx, root, new StudyOptionsRequest("{not json")),
                ErrorCode.VALIDATION_FAILED);
    }

    @Test
    void moveRewritesTheSubtreeAndBothParentsContentType_BR_DECK_015_018() {
        UUID rootA = root("sm2");
        UUID oldParent = child(rootA);
        UUID x = child(oldParent);
        UUID y = child(x);
        UUID newParent = child(rootA);
        long before = deck(y).getServerVersion();

        deckService.moveDeck(ctx, x, new MoveDeckRequest(newParent));

        assertThat(deck(x).getParentId()).isEqualTo(newParent);
        assertThat(deck(x).getDepth()).isEqualTo(3);
        assertThat(deck(y).getDepth()).isEqualTo(4);
        assertThat(deck(y).getServerVersion()).isGreaterThan(before);
        assertThat(deck(oldParent).getContentType()).isEqualTo("unset");
        assertThat(deck(newParent).getContentType()).isEqualTo("deck");
    }

    @Test
    void moveRefusesACycleACardTargetAndTooDeep_BR_DECK_001_010_017() {
        UUID root = root("sm2");
        UUID x = child(root);
        UUID y = child(x);
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(y)), ErrorCode.DECK_TREE_CYCLE);
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(x)), ErrorCode.DECK_TREE_CYCLE);

        UUID cardDeck = child(root);
        deckMapper.updateContentType(
                ctx.userId(),
                cardDeck,
                "card",
                999_998L,
                ctx.deviceId(),
                deck(root).getUpdatedAt());
        rejects(
                () -> deckService.moveDeck(ctx, y, new MoveDeckRequest(cardDeck)),
                ErrorCode.DECK_CONTENT_TYPE_MISMATCH);

        UUID deep = root("sm2");
        for (int level = 2; level <= 9; level++) {
            deep = child(deep);
        }
        UUID ninth = deep;
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(ninth)), ErrorCode.DECK_TREE_TOO_DEEP);
    }

    @Test
    void moveAcrossRootsNeedsTheSameSchedulerAndGeneration_BR_SRS_006() {
        UUID sm2 = root("sm2");
        UUID other = root("sm2");
        UUID eightBox = root("eight_box");
        UUID x = child(sm2);

        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(eightBox)), ErrorCode.DECK_SCHEDULER_MISMATCH);
        deckService.moveDeck(ctx, x, new MoveDeckRequest(other));
        assertThat(deck(x).getRootId()).isEqualTo(other);
    }

    @Test
    void aRootOrASameParentMoveIsNotAMove() {
        UUID root = root("sm2");
        UUID x = child(root);
        UUID target = child(root);
        rejects(() -> deckService.moveDeck(ctx, root, new MoveDeckRequest(target)), ErrorCode.VALIDATION_FAILED);
        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(root)), ErrorCode.VALIDATION_FAILED);
    }

    @Test
    void reorderPlacesTheDeckNextToItsAnchorAndBumpsOnlyMovedRows_UC_DECK_006() {
        UUID root = root("sm2");
        UUID a = child(root);
        UUID b = child(root);
        UUID c = child(root);
        long aVersion = deck(a).getServerVersion();

        deckService.reorderDeck(ctx, c, new ReorderDeckRequest(a, DeckPlacement.BEFORE));

        List<UUID> order = java.util.stream.Stream.of(a, b, c)
                .map(this::deck)
                .sorted(Comparator.comparing(Deck::getSiblingPosition))
                .map(Deck::getId)
                .toList();
        assertThat(order).containsExactly(c, a, b);
        assertThat(deck(a).getServerVersion()).isGreaterThan(aVersion);
        rejects(
                () -> deckService.reorderDeck(ctx, c, new ReorderDeckRequest(root, DeckPlacement.AFTER)),
                ErrorCode.VALIDATION_FAILED);
    }

    static final Instant DELETED_AT = Instant.parse("2026-09-27T02:00:00Z");

    UUID delete(UUID deckId) {
        UUID batch = UUID.randomUUID();
        deckService.deleteDeck(ctx, deckId, new DeleteDeckRequest(batch, DELETED_AT));
        return batch;
    }

    @Test
    void deleteMarksTheActiveSubtreeInOneBatchAndUnsetsAnEmptiedParent_BR_DECK_022_TRASH_003_005() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID x = child(parent);
        UUID y = child(x);

        UUID batch = delete(x);

        assertThat(deck(x).getDeleteBatchId()).isEqualTo(batch);
        assertThat(deck(y).getDeleteBatchId()).isEqualTo(batch);
        assertThat(deck(parent).getContentType()).isEqualTo("unset");
        assertThat(deleteBatchMapper.findDeleteBatchById(batch).getDeletedAt()).isEqualTo(DELETED_AT);
        assertThat(deleteBatchMapper.findDeleteBatchById(batch).getRootItemId()).isEqualTo(x);
        rejects(() -> deckService.renameDeck(ctx, x, new RenameDeckRequest("n")), ErrorCode.DECK_IN_TRASH);
    }

    @Test
    void anInnerDeckAlreadyInTrashKeepsItsOwnBatch_BR_TRASH_003() {
        UUID root = root("sm2");
        UUID x = child(root);
        UUID y = child(x);
        UUID inner = delete(y);

        UUID outer = delete(x);

        assertThat(deck(y).getDeleteBatchId()).isEqualTo(inner);
        assertThat(deck(x).getDeleteBatchId()).isEqualTo(outer);
    }

    @Test
    void undoRestoresExactlyTheBatchAndTombstonesIt_BR_TRASH_008() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID x = child(parent);
        UUID y = child(x);
        UUID batch = delete(x);

        deckService.undoDeckDeletion(ctx, batch);

        assertThat(deck(x).getDeleteBatchId()).isNull();
        assertThat(deck(y).getDeleteBatchId()).isNull();
        assertThat(deck(parent).getContentType()).isEqualTo("deck");
        assertThat(deleteBatchMapper.findDeleteBatchById(batch).getTombstonedAt())
                .isNotNull();
        rejects(() -> deckService.undoDeckDeletion(ctx, batch), ErrorCode.BATCH_NOT_FOUND);
    }

    @Test
    void undoIsRefusedWhenTheOldParentIsNowInTrash() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID x = child(parent);
        UUID inner = delete(x);
        delete(parent);

        rejects(() -> deckService.undoDeckDeletion(ctx, inner), ErrorCode.DECK_IN_TRASH);
    }

    @Test
    void aSubDeckCreatedUnderADeckInTrashJoinsItsBatchAndReturnsWithIt_D4() {
        UUID root = root("sm2");
        UUID parent = child(root);
        UUID batch = delete(parent);

        UUID late = child(parent);

        assertThat(deck(late).getDeleteBatchId()).isEqualTo(batch);
        assertThat(deck(parent).getContentType()).isEqualTo("deck");
        deckService.undoDeckDeletion(ctx, batch);
        assertThat(deck(late).getDeleteBatchId()).isNull();
        assertThat(deck(parent).getContentType()).isEqualTo("deck");
    }

    @Test
    void aMoveIntoADeckInTrashIsRefused() {
        UUID root = root("sm2");
        UUID target = child(root);
        UUID x = child(root);
        delete(target);

        rejects(() -> deckService.moveDeck(ctx, x, new MoveDeckRequest(target)), ErrorCode.DECK_IN_TRASH);
    }
}
