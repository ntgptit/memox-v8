package com.memox.card.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.dto.request.DeleteCardsRequest;
import com.memox.card.dto.request.MoveCardsRequest;
import com.memox.card.mapper.CardMapper;
import com.memox.card.model.Card;
import com.memox.card.service.CardService;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.DeleteDeckRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import java.time.Instant;
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
class CardServiceImplIT {

    static final Instant DELETED_AT = Instant.parse("2026-09-27T02:00:00Z");

    @Autowired
    CardService cardService;

    @Autowired
    DeckService deckService;

    @Autowired
    CardMapper cardMapper;

    @Autowired
    DeckMapper deckMapper;

    final WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());

    UUID root() {
        UUID id = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(id, "Root", "sm2"));
        return id;
    }

    UUID sub(UUID parent) {
        UUID id = UUID.randomUUID();
        deckService.createSubDeck(ctx, parent, new CreateSubDeckRequest(id, "Sub"));
        return id;
    }

    UUID card(UUID deck) {
        UUID id = UUID.randomUUID();
        cardService.createCard(ctx, deck, new CreateCardRequest(id, "犬", "dog", null, null, null));
        return id;
    }

    Card stored(UUID id) {
        return cardMapper.findCardById(id);
    }

    String contentType(UUID deckId) {
        return deckMapper.findDeckById(deckId).getContentType();
    }

    static void rejects(ThrowingCallable call, ErrorCode code) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(code);
    }

    @Test
    void createCardTurnsAnUnsetDeckIntoACardDeckAndStoresNfcText_BR_DECK_008_CARD_001() {
        UUID deck = sub(root());
        UUID id = UUID.randomUUID();

        cardService.createCard(ctx, deck, new CreateCardRequest(id, " café ", "coffee", "  ", null, "ka-fe"));

        assertThat(stored(id).getFront()).isEqualTo("café");
        assertThat(stored(id).getExample()).isNull();
        assertThat(stored(id).getPronunciation()).isEqualTo("ka-fe");
        assertThat(contentType(deck)).isEqualTo("card");
    }

    @Test
    void createCardRefusesARootADeckParentAndTooLongText_BR_DECK_004_010_CARD_002() {
        UUID root = root();
        UUID parent = sub(root);
        sub(parent);

        rejects(() -> card(root), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        rejects(() -> card(parent), ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        UUID deck = sub(root);
        rejects(
                () -> cardService.createCard(
                        ctx, deck, new CreateCardRequest(UUID.randomUUID(), "x".repeat(61), "b", null, null, null)),
                ErrorCode.VALIDATION_FAILED);
        rejects(() -> card(UUID.randomUUID()), ErrorCode.DECK_PARENT_MISSING);
    }

    @Test
    void aCardCreatedInADeckInTrashJoinsItsBatch_D4() {
        UUID root = root();
        UUID deck = sub(root);
        UUID batch = UUID.randomUUID();
        deckService.deleteDeck(ctx, deck, new DeleteDeckRequest(batch, DELETED_AT));

        UUID late = card(deck);

        assertThat(stored(late).getDeleteBatchId()).isEqualTo(batch);
        assertThat(contentType(deck)).isEqualTo("card");
    }

    @Test
    void contentAndFlagPatchesKeepTheCardAndItsDeck_BR_CARD_005_009() {
        UUID deck = sub(root());
        UUID id = card(deck);

        cardService.updateContent(ctx, id, new CardContentRequest("猫", "cat", "a cat", "meow", null));
        cardService.updateFlag(ctx, id, new CardFlagRequest(true));

        assertThat(stored(id).getFront()).isEqualTo("猫");
        assertThat(stored(id).getHint()).isEqualTo("meow");
        assertThat(stored(id).isFlagged()).isTrue();
        assertThat(stored(id).getDeckId()).isEqualTo(deck);
        rejects(
                () -> cardService.updateFlag(ctx, UUID.randomUUID(), new CardFlagRequest(true)),
                ErrorCode.CARD_NOT_FOUND);
    }

    @Test
    void moveCardsBetweenSubDecksOfOneRootUpdatesBothContentTypes_BR_CARD_010() {
        UUID root = root();
        UUID from = sub(root);
        UUID to = sub(root);
        UUID a = card(from);
        UUID b = card(from);

        cardService.moveCards(ctx, new MoveCardsRequest(List.of(a, b), to));

        assertThat(stored(a).getDeckId()).isEqualTo(to);
        assertThat(contentType(from)).isEqualTo("unset");
        assertThat(contentType(to)).isEqualTo("card");
    }

    @Test
    void moveCardsIsAllOrNothingAndStaysInOneRoot_BR_CARD_010_011() {
        UUID root = root();
        UUID from = sub(root);
        UUID a = card(from);
        UUID otherRootDeck = sub(root());
        UUID deckParent = sub(root);
        sub(deckParent);

        rejects(
                () -> cardService.moveCards(ctx, new MoveCardsRequest(List.of(a), otherRootDeck)),
                ErrorCode.CARD_MOVE_CROSS_ROOT);
        rejects(
                () -> cardService.moveCards(ctx, new MoveCardsRequest(List.of(a), deckParent)),
                ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        rejects(
                () -> cardService.moveCards(ctx, new MoveCardsRequest(List.of(a, UUID.randomUUID()), sub(root))),
                ErrorCode.CARD_NOT_FOUND);
        assertThat(stored(a).getDeckId()).isEqualTo(from);
    }

    @Test
    void deleteCardsMakesOneBatchPerCardAndUndoRestoresOne_BR_TRASH_001_008() {
        UUID deck = sub(root());
        UUID a = card(deck);
        UUID b = card(deck);
        UUID batchA = UUID.randomUUID();
        UUID batchB = UUID.randomUUID();

        cardService.deleteCards(
                ctx,
                new DeleteCardsRequest(
                        List.of(new DeleteCardsRequest.Item(a, batchA), new DeleteCardsRequest.Item(b, batchB)),
                        DELETED_AT));

        assertThat(stored(a).getDeleteBatchId()).isEqualTo(batchA);
        assertThat(contentType(deck)).isEqualTo("unset");
        cardService.undoCardDeletion(ctx, batchA);
        assertThat(stored(a).getDeleteBatchId()).isNull();
        assertThat(stored(b).getDeleteBatchId()).isEqualTo(batchB);
        assertThat(contentType(deck)).isEqualTo("card");
        rejects(() -> cardService.undoCardDeletion(ctx, batchA), ErrorCode.BATCH_NOT_FOUND);
    }

    @Test
    void deletingADeckTakesItsCardsAndUndoBringsThemBack_BR_DECK_022() {
        UUID root = root();
        UUID deck = sub(root);
        UUID a = card(deck);
        UUID batch = UUID.randomUUID();

        deckService.deleteDeck(ctx, deck, new DeleteDeckRequest(batch, DELETED_AT));
        assertThat(stored(a).getDeleteBatchId()).isEqualTo(batch);
        rejects(() -> cardService.updateFlag(ctx, a, new CardFlagRequest(true)), ErrorCode.CARD_IN_TRASH);

        deckService.undoDeckDeletion(ctx, batch);
        assertThat(stored(a).getDeleteBatchId()).isNull();
        assertThat(contentType(deck)).isEqualTo("card");
    }

    @Test
    void aCardDeletedAloneKeepsItsOwnBatchWhenItsDeckIsDeletedLater_BR_TRASH_003() {
        UUID deck = sub(root());
        UUID a = card(deck);
        UUID own = UUID.randomUUID();
        cardService.deleteCards(ctx, new DeleteCardsRequest(List.of(new DeleteCardsRequest.Item(a, own)), DELETED_AT));

        deckService.deleteDeck(ctx, deck, new DeleteDeckRequest(UUID.randomUUID(), DELETED_AT));

        assertThat(stored(a).getDeleteBatchId()).isEqualTo(own);
    }
}
