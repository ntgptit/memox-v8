package com.memox.card.service.impl;

import com.memox.card.dto.CardSyncRow;
import com.memox.card.mapper.CardMapper;
import com.memox.card.model.Card;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.service.EntityReader;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The {@code card} rows of the change feed. */
@Component
@RequiredArgsConstructor
public class CardReader implements EntityReader {

    public static final String ENTITY_TYPE = "card";

    private final CardMapper cardMapper;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        Card card = cardMapper.findCardById(entityId);
        if (card == null) {
            return SyncChange.absent(ENTITY_TYPE, entityId);
        }
        return card.getUserId().equals(userId) ? toChange(card) : null;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return cardMapper.findChangesSince(userId, since, limit).stream()
                .map(CardReader::toChange)
                .toList();
    }

    private static SyncChange toChange(Card card) {
        boolean deleted = card.getDeletedAt() != null;
        CardSyncRow row = deleted
                ? null
                : CardSyncRow.builder()
                        .id(card.getId())
                        .deckId(card.getDeckId())
                        .front(card.getFront())
                        .back(card.getBack())
                        .example(card.getExample())
                        .hint(card.getHint())
                        .pronunciation(card.getPronunciation())
                        .isFlagged(card.isFlagged())
                        .deleteBatchId(card.getDeleteBatchId())
                        .createdAt(card.getCreatedAt())
                        .updatedAt(card.getUpdatedAt())
                        .build();
        return new SyncChange(ENTITY_TYPE, card.getId(), card.getServerVersion(), deleted, row);
    }
}
