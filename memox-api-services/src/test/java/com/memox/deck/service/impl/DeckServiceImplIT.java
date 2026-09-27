package com.memox.deck.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
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
}
