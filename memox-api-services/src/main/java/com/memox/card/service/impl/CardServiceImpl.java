package com.memox.card.service.impl;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.mapper.CardMapper;
import com.memox.card.model.Card;
import com.memox.card.service.CardService;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.util.TextRules;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckContentTypes;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CardServiceImpl implements CardService {

    static final int FRONT_MAX_LENGTH = 60;
    static final int BACK_MAX_LENGTH = 240;
    static final int EXTRA_MAX_LENGTH = 240;

    private final CardMapper cardMapper;
    private final DeckMapper deckMapper;
    private final DeckService deckService;
    private final ChangeVersions changeVersions;
    private final Clock clock;

    @Override
    @Transactional
    public void createCard(WriteContext context, UUID deckId, CreateCardRequest request) {
        changeVersions.lock(context);
        requireNewId(context, request.id());
        Deck deck = deckMapper.findDeckById(deckId);
        if (deck == null || !deck.getUserId().equals(context.userId()) || deck.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        requireCardHolder(deck);
        Instant now = clock.instant();
        cardMapper.insertCard(Card.builder()
                .id(request.id())
                .userId(context.userId())
                .deckId(deck.getId())
                .front(TextRules.required(request.front(), FRONT_MAX_LENGTH))
                .back(TextRules.required(request.back(), BACK_MAX_LENGTH))
                .example(TextRules.optional(request.example(), EXTRA_MAX_LENGTH))
                .hint(TextRules.optional(request.hint(), EXTRA_MAX_LENGTH))
                .pronunciation(TextRules.optional(request.pronunciation(), EXTRA_MAX_LENGTH))
                // A deck in Trash takes its new card along (API-A2 spec D4).
                .deleteBatchId(deck.getDeleteBatchId())
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
        deckService.refreshContentType(context, deck.getId());
    }

    @Override
    @Transactional
    public void updateContent(WriteContext context, UUID cardId, CardContentRequest request) {
        changeVersions.lock(context);
        Card card = activeCard(context, cardId);
        card.setFront(TextRules.required(request.front(), FRONT_MAX_LENGTH));
        card.setBack(TextRules.required(request.back(), BACK_MAX_LENGTH));
        card.setExample(TextRules.optional(request.example(), EXTRA_MAX_LENGTH));
        card.setHint(TextRules.optional(request.hint(), EXTRA_MAX_LENGTH));
        card.setPronunciation(TextRules.optional(request.pronunciation(), EXTRA_MAX_LENGTH));
        card.setUpdatedAt(clock.instant());
        card.setServerVersion(changeVersions.next(context));
        card.setLastDeviceId(context.deviceId());
        cardMapper.updateContent(card);
    }

    @Override
    @Transactional
    public void updateFlag(WriteContext context, UUID cardId, CardFlagRequest request) {
        changeVersions.lock(context);
        Card card = activeCard(context, cardId);
        cardMapper.updateFlag(
                context.userId(),
                card.getId(),
                request.isFlagged(),
                changeVersions.next(context),
                context.deviceId(),
                clock.instant());
    }

    /** A sub-deck that holds cards or nothing yet (BR-DECK-004, BR-DECK-010). */
    static void requireCardHolder(Deck deck) {
        if (deck.getParentId() == null || DeckContentTypes.DECK.equals(deck.getContentType())) {
            throw new BusinessException(ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        }
    }

    /** The owner's active card: missing or purged is not found, foreign is a conflict, in Trash is refused. */
    Card activeCard(WriteContext context, UUID cardId) {
        Card card = cardMapper.findCardById(cardId);
        if (card == null || card.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.CARD_NOT_FOUND);
        }
        if (!card.getUserId().equals(context.userId())) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        if (card.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.CARD_IN_TRASH);
        }
        return card;
    }

    private void requireNewId(WriteContext context, UUID id) {
        Card existing = cardMapper.findCardById(id);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }
}
