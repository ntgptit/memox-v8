package com.memox.deck.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.util.TextRules;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckContentTypes;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DeckServiceImpl implements DeckService {

    static final int MAX_DEPTH = 10;
    static final int NAME_MAX_LENGTH = 200;
    private static final int ROOT_DEPTH = 1;
    private static final int FIRST_GENERATION = 1;
    /** The algorithm versions Dart ships (EightBoxScheduler.version, Sm2Scheduler.version); API-B5 owns them. */
    private static final Map<String, Integer> SCHEDULER_VERSIONS = Map.of("eight_box", 1, "sm2", 1);

    private final DeckMapper deckMapper;
    private final ChangeVersions changeVersions;
    private final ObjectMapper objectMapper;
    private final Clock clock;

    @Override
    @Transactional
    public void createRootDeck(WriteContext context, CreateRootDeckRequest request) {
        changeVersions.lock(context);
        requireNewId(context, request.id());
        String name = TextRules.required(request.name(), NAME_MAX_LENGTH);
        Instant now = clock.instant();
        deckMapper.insertDeck(Deck.builder()
                .id(request.id())
                .userId(context.userId())
                .name(name)
                .rootId(request.id())
                .depth(ROOT_DEPTH)
                .contentType(DeckContentTypes.DECK)
                .schedulerType(request.schedulerType())
                .schedulerVersion(SCHEDULER_VERSIONS.get(request.schedulerType()))
                .generation(FIRST_GENERATION)
                .siblingPosition(deckMapper.nextSiblingPosition(context.userId(), null))
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
    }

    @Override
    @Transactional
    public void createSubDeck(WriteContext context, UUID parentId, CreateSubDeckRequest request) {
        changeVersions.lock(context);
        requireNewId(context, request.id());
        Deck parent = parentOrMissing(context, parentId);
        if (DeckContentTypes.CARD.equals(parent.getContentType())) {
            throw new BusinessException(ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        }
        if (parent.getDepth() + 1 > MAX_DEPTH) {
            throw new BusinessException(ErrorCode.DECK_TREE_TOO_DEEP);
        }
        String name = TextRules.required(request.name(), NAME_MAX_LENGTH);
        Instant now = clock.instant();
        deckMapper.insertDeck(Deck.builder()
                .id(request.id())
                .userId(context.userId())
                .name(name)
                .parentId(parent.getId())
                .rootId(parent.getRootId())
                .depth(parent.getDepth() + 1)
                .contentType(DeckContentTypes.UNSET)
                // A parent in Trash takes its new child along (API-A2 spec D4).
                .deleteBatchId(parent.getDeleteBatchId())
                .siblingPosition(deckMapper.nextSiblingPosition(context.userId(), parent.getId()))
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
        refreshContentType(context, parent.getId());
    }

    @Override
    @Transactional
    public void renameDeck(WriteContext context, UUID deckId, RenameDeckRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        String name = TextRules.required(request.name(), NAME_MAX_LENGTH);
        deckMapper.updateName(
                context.userId(),
                deck.getId(),
                name,
                changeVersions.next(context),
                context.deviceId(),
                clock.instant());
    }

    @Override
    @Transactional
    public void updateStudyOptions(WriteContext context, UUID deckId, StudyOptionsRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        if (deck.getParentId() != null) {
            throw new BusinessException(ErrorCode.DECK_ROOT_REQUIRED);
        }
        requireJsonOrNull(request.studyConfig());
        deckMapper.updateStudyConfig(
                context.userId(),
                deck.getId(),
                request.studyConfig(),
                changeVersions.next(context),
                context.deviceId(),
                clock.instant());
    }

    @Override
    @Transactional
    public void refreshContentType(WriteContext context, UUID deckId) {
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null || deck.getParentId() == null) {
            return;
        }
        String derived = deckMapper.deriveContentType(deckId);
        if (!derived.equals(deck.getContentType())) {
            deckMapper.updateContentType(
                    context.userId(),
                    deckId,
                    derived,
                    changeVersions.next(context),
                    context.deviceId(),
                    clock.instant());
        }
    }

    /** A new client id: the owner's own row is a replay gone wrong, another user's is never revealed. */
    private void requireNewId(WriteContext context, UUID id) {
        Deck existing = deckMapper.findDeckById(id);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }

    /** The owner's un-purged deck, in Trash or not; a missing, purged or foreign parent reads as missing. */
    Deck parentOrMissing(WriteContext context, UUID parentId) {
        Deck parent = deckMapper.findDeckById(parentId);
        if (parent == null || !parent.getUserId().equals(context.userId()) || parent.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        return parent;
    }

    /** The owner's active deck: missing or purged is not found, foreign is a conflict, in Trash is refused. */
    Deck activeDeck(WriteContext context, UUID deckId) {
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null || deck.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_NOT_FOUND);
        }
        if (!deck.getUserId().equals(context.userId())) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        if (deck.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        return deck;
    }

    private void requireJsonOrNull(String value) {
        if (value == null) {
            return;
        }
        try {
            objectMapper.readTree(value);
        } catch (JsonProcessingException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }
}
