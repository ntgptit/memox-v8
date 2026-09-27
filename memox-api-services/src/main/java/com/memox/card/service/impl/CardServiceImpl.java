package com.memox.card.service.impl;

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
import com.memox.common.util.TextRules;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckContentTypes;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import com.memox.trash.mapper.DeleteBatchMapper;
import com.memox.trash.model.DeleteBatch;
import java.time.Clock;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
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
    static final String BATCH_ITEM_CARD = "card";

    private final CardMapper cardMapper;
    private final DeleteBatchMapper deleteBatchMapper;
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

    @Override
    @Transactional
    public void moveCards(WriteContext context, MoveCardsRequest request) {
        changeVersions.lock(context);
        List<UUID> ids = request.cardIds().stream().distinct().sorted().toList();
        List<Card> cards = ids.stream().map(id -> activeCard(context, id)).toList();
        Deck target = deckMapper.findDeckById(request.targetDeckId());
        if (target == null || !target.getUserId().equals(context.userId()) || target.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_NOT_FOUND);
        }
        if (target.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        requireCardHolder(target);
        Set<UUID> sources = new LinkedHashSet<>();
        for (Card card : cards) {
            Deck source = deckMapper.findDeckById(card.getDeckId());
            if (!Objects.equals(source.getRootId(), target.getRootId())) {
                throw new BusinessException(ErrorCode.CARD_MOVE_CROSS_ROOT);
            }
            sources.add(source.getId());
        }
        cardMapper.moveCards(
                context.userId(),
                ids,
                target.getId(),
                changeVersions.block(context, ids.size()),
                context.deviceId(),
                clock.instant());
        sources.forEach(deckId -> deckService.refreshContentType(context, deckId));
        deckService.refreshContentType(context, target.getId());
    }

    @Override
    @Transactional
    public void deleteCards(WriteContext context, DeleteCardsRequest request) {
        changeVersions.lock(context);
        Set<UUID> decks = new LinkedHashSet<>();
        Instant now = clock.instant();
        for (DeleteCardsRequest.Item item : request.items()) {
            Card card = activeCard(context, item.cardId());
            requireNewBatch(context, item.batchId());
            deleteBatchMapper.insertDeleteBatch(DeleteBatch.builder()
                    .id(item.batchId())
                    .userId(context.userId())
                    .itemType(BATCH_ITEM_CARD)
                    .rootItemId(card.getId())
                    .deletedAt(request.deletedAt())
                    .serverVersion(changeVersions.next(context))
                    .lastDeviceId(context.deviceId())
                    .build());
            cardMapper.markCard(
                    context.userId(),
                    card.getId(),
                    item.batchId(),
                    changeVersions.next(context),
                    context.deviceId(),
                    now);
            decks.add(card.getDeckId());
        }
        decks.forEach(deckId -> deckService.refreshContentType(context, deckId));
    }

    @Override
    @Transactional
    public void undoCardDeletion(WriteContext context, UUID batchId) {
        changeVersions.lock(context);
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(batchId);
        if (batch == null
                || !batch.getUserId().equals(context.userId())
                || batch.getTombstonedAt() != null
                || !BATCH_ITEM_CARD.equals(batch.getItemType())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        Card card = cardMapper.findCardById(batch.getRootItemId());
        if (card == null || card.getDeletedAt() != null || !batchId.equals(card.getDeleteBatchId())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        Deck deck = deckMapper.findDeckById(card.getDeckId());
        if (deck == null || deck.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        if (deck.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        requireCardHolder(deck);
        cardMapper.restoreCardBatch(
                context.userId(), batchId, changeVersions.block(context, 1), context.deviceId(), clock.instant());
        deckService.refreshContentType(context, deck.getId());
        deleteBatchMapper.tombstoneDeleteBatch(batchId, changeVersions.next(context), context.deviceId());
    }

    private void requireNewBatch(WriteContext context, UUID batchId) {
        DeleteBatch existing = deleteBatchMapper.findDeleteBatchById(batchId);
        if (existing == null) {
            return;
        }
        throw new BusinessException(
                existing.getUserId().equals(context.userId()) ? ErrorCode.CONFLICT : ErrorCode.SYNC_ENTITY_CONFLICT);
    }
}
