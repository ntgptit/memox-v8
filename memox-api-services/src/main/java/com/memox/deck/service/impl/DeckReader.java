package com.memox.deck.service.impl;

import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.service.EntityReader;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** The {@code deck} rows of the change feed; {@code rootId}, {@code depth} and {@code contentType} are the server's. */
@Component
@RequiredArgsConstructor
public class DeckReader implements EntityReader {

    public static final String ENTITY_TYPE = "deck";

    private final DeckMapper deckMapper;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        Deck deck = deckMapper.findDeckById(entityId);
        if (deck == null) {
            return SyncChange.absent(ENTITY_TYPE, entityId);
        }
        return deck.getUserId().equals(userId) ? toChange(deck) : null;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deckMapper.findChangesSince(userId, since, limit).stream()
                .map(DeckReader::toChange)
                .toList();
    }

    static SyncChange toChange(Deck deck) {
        boolean deleted = deck.getDeletedAt() != null;
        DeckSyncRow row = deleted
                ? null
                : DeckSyncRow.builder()
                        .id(deck.getId())
                        .name(deck.getName())
                        .parentId(deck.getParentId())
                        .rootId(deck.getRootId())
                        .depth(deck.getDepth())
                        .contentType(deck.getContentType())
                        .schedulerType(deck.getSchedulerType())
                        .schedulerVersion(deck.getSchedulerVersion())
                        .schedulerConfig(deck.getSchedulerConfig())
                        .studyConfig(deck.getStudyConfig())
                        .generation(deck.getGeneration())
                        .firstAnsweredAt(deck.getFirstAnsweredAt())
                        .sourceTemplateId(deck.getSourceTemplateId())
                        .sourceTemplateVersion(deck.getSourceTemplateVersion())
                        .deleteBatchId(deck.getDeleteBatchId())
                        .siblingPosition(deck.getSiblingPosition())
                        .createdAt(deck.getCreatedAt())
                        .updatedAt(deck.getUpdatedAt())
                        .build();
        return new SyncChange(ENTITY_TYPE, deck.getId(), deck.getServerVersion(), deleted, row);
    }
}
