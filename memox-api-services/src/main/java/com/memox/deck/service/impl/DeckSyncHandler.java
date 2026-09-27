package com.memox.deck.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.dto.DeckSyncRow;
import com.memox.deck.mapper.DeckSyncMapper;
import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckSubtreeNode;
import com.memox.sync.dto.response.SyncChange;
import com.memox.sync.mapper.SyncVersionMapper;
import com.memox.sync.service.SyncEntityHandler;
import jakarta.validation.Validator;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Syncs {@code deck}. The server derives {@code root_id} and {@code depth} from {@code parent_id} and rewrites a moved
 * subtree itself, so the order in which a client's per-row operations arrive does not matter (spec §5).
 */
@Component
@RequiredArgsConstructor
public class DeckSyncHandler implements SyncEntityHandler {

    public static final String ENTITY_TYPE = "deck";

    static final int MAX_DEPTH = 10;

    private static final int ROOT_DEPTH = 1;

    private final DeckSyncMapper deckSyncMapper;
    private final SyncVersionMapper syncVersionMapper;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    @Override
    public String entityType() {
        return ENTITY_TYPE;
    }

    @Override
    public long upsert(UUID userId, UUID deviceId, UUID entityId, JsonNode rowJson) {
        DeckSyncRow row = parse(rowJson, entityId);
        Deck existing = ownedOrNull(userId, entityId);

        List<DeckSubtreeNode> subtree = existing == null ? List.of() : deckSyncMapper.findLiveSubtree(userId, entityId);
        Deck parent = row.parentId() == null ? null : liveParent(userId, row.parentId());
        requireNoCycle(row.parentId(), entityId, subtree);

        UUID rootId = parent == null ? entityId : parent.getRootId();
        int depth = parent == null ? ROOT_DEPTH : parent.getDepth() + 1;
        int height = subtree.stream().mapToInt(DeckSubtreeNode::getRel).max().orElse(0);
        if (depth + height > MAX_DEPTH) {
            throw new BusinessException(ErrorCode.DECK_TREE_TOO_DEEP);
        }

        boolean placementChanged =
                existing != null && (!Objects.equals(existing.getRootId(), rootId) || existing.getDepth() != depth);
        // A tombstoned deck has no live subtree, so there are no descendants to rewrite when it is resurrected.
        int descendants = placementChanged ? Math.max(0, subtree.size() - 1) : 0;
        long lastVersion = syncVersionMapper.allocate(userId, 1 + descendants);
        long version = lastVersion - descendants;

        deckSyncMapper.upsertDeck(toModel(row, userId, deviceId, rootId, depth, version));
        if (descendants > 0) {
            deckSyncMapper.updateSubtreePlacement(userId, entityId, rootId, depth, version + 1, deviceId);
        }
        return version;
    }

    @Override
    public long delete(UUID userId, UUID deviceId, UUID entityId) {
        Deck existing = ownedOrNull(userId, entityId);
        if (existing == null) {
            Long current = syncVersionMapper.current(userId);
            return current == null ? 0L : current;
        }
        if (existing.getDeletedAt() != null) {
            return existing.getServerVersion();
        }
        int rows = deckSyncMapper.findLiveSubtree(userId, entityId).size();
        long lastVersion = syncVersionMapper.allocate(userId, rows);
        long firstVersion = lastVersion - rows + 1;
        deckSyncMapper.tombstoneSubtree(userId, entityId, firstVersion, deviceId);
        return firstVersion;
    }

    @Override
    public List<SyncChange> changesSince(UUID userId, long since, int limit) {
        return deckSyncMapper.findChangesSince(userId, since, limit).stream()
                .map(this::toChange)
                .toList();
    }

    @Override
    public SyncChange current(UUID userId, UUID entityId) {
        Deck deck = deckSyncMapper.findDeckById(entityId);
        if (deck == null || !deck.getUserId().equals(userId)) {
            return null;
        }
        return toChange(deck);
    }

    private DeckSyncRow parse(JsonNode rowJson, UUID entityId) {
        try {
            DeckSyncRow row = objectMapper.treeToValue(rowJson, DeckSyncRow.class);
            if (row == null
                    || !entityId.equals(row.id())
                    || !validator.validate(row).isEmpty()) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            requireJsonOrNull(row.schedulerConfig());
            requireJsonOrNull(row.studyConfig());
            boolean rootShape = row.parentId() == null
                    ? "deck".equals(row.contentType())
                            && row.schedulerType() != null
                            && row.schedulerVersion() != null
                            && row.generation() != null
                    : row.schedulerType() == null
                            && row.schedulerVersion() == null
                            && row.generation() == null
                            && row.schedulerConfig() == null
                            && row.studyConfig() == null;
            if (!rootShape) {
                throw new BusinessException(ErrorCode.VALIDATION_FAILED);
            }
            return row;
        } catch (JsonProcessingException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }

    /** Config columns hold JSON that other devices parse; refuse anything else. */
    private void requireJsonOrNull(String value) throws JsonProcessingException {
        if (value != null) {
            objectMapper.readTree(value);
        }
    }

    /** The row if this user owns it; {@code null} if unknown; rejects another user's id. */
    private Deck ownedOrNull(UUID userId, UUID entityId) {
        Deck deck = deckSyncMapper.findDeckById(entityId);
        if (deck != null && !deck.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.SYNC_ENTITY_CONFLICT);
        }
        return deck;
    }

    private Deck liveParent(UUID userId, UUID parentId) {
        Deck parent = deckSyncMapper.findDeckById(parentId);
        if (parent == null || !parent.getUserId().equals(userId) || parent.getDeletedAt() != null) {
            throw new BusinessException(ErrorCode.DECK_PARENT_MISSING);
        }
        return parent;
    }

    private static void requireNoCycle(UUID parentId, UUID entityId, List<DeckSubtreeNode> subtree) {
        if (parentId == null) {
            return;
        }
        boolean parentInsideSubtree = parentId.equals(entityId)
                || subtree.stream().anyMatch(node -> node.getId().equals(parentId));
        if (parentInsideSubtree) {
            throw new BusinessException(ErrorCode.DECK_TREE_CYCLE);
        }
    }

    private static Deck toModel(DeckSyncRow row, UUID userId, UUID deviceId, UUID rootId, int depth, long version) {
        return Deck.builder()
                .id(row.id())
                .userId(userId)
                .name(row.name())
                .parentId(row.parentId())
                .rootId(rootId)
                .depth(depth)
                .contentType(row.contentType())
                .schedulerType(row.schedulerType())
                .schedulerVersion(row.schedulerVersion())
                .schedulerConfig(row.schedulerConfig())
                .studyConfig(row.studyConfig())
                .generation(row.generation())
                .firstAnsweredAt(row.firstAnsweredAt())
                .sourceTemplateId(row.sourceTemplateId())
                .sourceTemplateVersion(row.sourceTemplateVersion())
                .deleteBatchId(row.deleteBatchId())
                .siblingPosition(row.siblingPosition())
                .createdAt(row.createdAt())
                .updatedAt(row.updatedAt())
                .serverVersion(version)
                .lastDeviceId(deviceId)
                .build();
    }

    private SyncChange toChange(Deck deck) {
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
