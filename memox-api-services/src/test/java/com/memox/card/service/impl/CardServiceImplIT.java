package com.memox.card.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
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
}
