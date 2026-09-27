package com.memox.deck.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.card.mapper.CardMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.util.TextRules;
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
import com.memox.deck.model.DeckContentTypes;
import com.memox.deck.model.DeckPosition;
import com.memox.deck.model.DeckSubtreeNode;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.WriteContext;
import com.memox.trash.mapper.DeleteBatchMapper;
import com.memox.trash.model.DeleteBatch;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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
    static final String BATCH_ITEM_DECK = "deck";
    /** The algorithm versions Dart ships (EightBoxScheduler.version, Sm2Scheduler.version); API-B5 owns them. */
    private static final Map<String, Integer> SCHEDULER_VERSIONS = Map.of("eight_box", 1, "sm2", 1);

    private final DeckMapper deckMapper;
    private final DeleteBatchMapper deleteBatchMapper;
    private final CardMapper cardMapper;
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

    @Override
    @Transactional
    public void moveDeck(WriteContext context, UUID deckId, MoveDeckRequest request) {
        changeVersions.lock(context);
        Deck moving = activeDeck(context, deckId);
        UUID oldParentId = moving.getParentId();
        // A root owns its scheduler: making it a child, or a child a root, is not a move (UC-DECK-005 A2).
        if (oldParentId == null || oldParentId.equals(request.targetParentId())) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        Deck target = parentOrMissing(context, request.targetParentId());
        List<DeckSubtreeNode> subtree = deckMapper.findLiveSubtree(context.userId(), moving.getId());
        requireNoCycle(target.getId(), moving.getId(), subtree);
        if (target.getDeleteBatchId() != null) {
            throw new BusinessException(ErrorCode.DECK_IN_TRASH);
        }
        requirePlaceableUnder(target, moving, subtree);

        int depth = target.getDepth() + 1;
        Instant now = clock.instant();
        deckMapper.updatePlacement(
                context.userId(),
                moving.getId(),
                target.getId(),
                target.getRootId(),
                depth,
                deckMapper.nextSiblingPosition(context.userId(), target.getId()),
                changeVersions.next(context),
                context.deviceId(),
                now);
        rewriteDescendants(context, moving.getId(), target.getRootId(), depth, subtree.size() - 1, now);
        refreshContentType(context, oldParentId);
        refreshContentType(context, target.getId());
    }

    @Override
    @Transactional
    public void reorderDeck(WriteContext context, UUID deckId, ReorderDeckRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        Deck anchor = activeDeck(context, request.anchorId());
        if (deck.getId().equals(anchor.getId()) || !Objects.equals(deck.getParentId(), anchor.getParentId())) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        List<Deck> siblings = deckMapper.findActiveSiblings(context.userId(), deck.getParentId());
        List<UUID> order = new ArrayList<>(siblings.stream()
                .map(Deck::getId)
                .filter(id -> !id.equals(deckId))
                .toList());
        int anchorIndex = order.indexOf(anchor.getId());
        order.add(request.placement() == DeckPlacement.BEFORE ? anchorIndex : anchorIndex + 1, deckId);

        List<UUID> moved = new ArrayList<>();
        for (int position = 0; position < order.size(); position++) {
            UUID id = order.get(position);
            Deck sibling = siblings.stream()
                    .filter(s -> s.getId().equals(id))
                    .findFirst()
                    .orElseThrow();
            if (sibling.getSiblingPosition() != position) {
                moved.add(id);
            }
        }
        if (moved.isEmpty()) {
            return;
        }
        long firstVersion = changeVersions.block(context, moved.size());
        List<DeckPosition> positions = new ArrayList<>();
        for (int i = 0; i < moved.size(); i++) {
            positions.add(new DeckPosition(moved.get(i), order.indexOf(moved.get(i)), firstVersion + i));
        }
        deckMapper.updateSiblingPositions(context.userId(), positions, context.deviceId(), clock.instant());
    }

    /** The UC-DECK-005 checks after the cycle check: content type, scheduler and generation, depth. */
    private void requirePlaceableUnder(Deck target, Deck moving, List<DeckSubtreeNode> subtree) {
        if (DeckContentTypes.CARD.equals(target.getContentType())) {
            throw new BusinessException(ErrorCode.DECK_CONTENT_TYPE_MISMATCH);
        }
        Deck movingRoot = deckMapper.findDeckById(moving.getRootId());
        Deck targetRoot = deckMapper.findDeckById(target.getRootId());
        if (!Objects.equals(movingRoot.getSchedulerType(), targetRoot.getSchedulerType())
                || !Objects.equals(movingRoot.getGeneration(), targetRoot.getGeneration())) {
            throw new BusinessException(ErrorCode.DECK_SCHEDULER_MISMATCH);
        }
        int height = subtree.stream().mapToInt(DeckSubtreeNode::getRel).max().orElse(0) + 1;
        if (target.getDepth() + height > MAX_DEPTH) {
            throw new BusinessException(ErrorCode.DECK_TREE_TOO_DEEP);
        }
    }

    /** Descendants follow their top's new root and depth, one version each, Trash included (BR-DECK-018). */
    private void rewriteDescendants(
            WriteContext context, UUID topId, UUID rootId, int topDepth, int descendants, Instant now) {
        if (descendants <= 0) {
            return;
        }
        deckMapper.updateSubtreePlacement(
                context.userId(),
                topId,
                rootId,
                topDepth,
                changeVersions.block(context, descendants),
                context.deviceId(),
                now);
    }

    private static void requireNoCycle(UUID targetId, UUID movingId, List<DeckSubtreeNode> subtree) {
        boolean inside = targetId.equals(movingId)
                || subtree.stream().anyMatch(node -> node.getId().equals(targetId));
        if (inside) {
            throw new BusinessException(ErrorCode.DECK_TREE_CYCLE);
        }
    }

    @Override
    @Transactional
    public void deleteDeck(WriteContext context, UUID deckId, DeleteDeckRequest request) {
        changeVersions.lock(context);
        Deck deck = activeDeck(context, deckId);
        requireNewBatch(context, request.batchId());
        deleteBatchMapper.insertDeleteBatch(DeleteBatch.builder()
                .id(request.batchId())
                .userId(context.userId())
                .itemType(BATCH_ITEM_DECK)
                .rootItemId(deck.getId())
                .deletedAt(request.deletedAt())
                .serverVersion(changeVersions.next(context))
                .lastDeviceId(context.deviceId())
                .build());
        int rows = deckMapper.findActiveSubtree(context.userId(), deck.getId()).size();
        deckMapper.markActiveSubtree(
                context.userId(),
                deck.getId(),
                request.batchId(),
                changeVersions.block(context, rows),
                context.deviceId(),
                clock.instant());
        int cards = cardMapper.countCardsInDeckBatch(context.userId(), request.batchId());
        if (cards > 0) {
            cardMapper.markCardsInDeckBatch(
                    context.userId(),
                    request.batchId(),
                    changeVersions.block(context, cards),
                    context.deviceId(),
                    clock.instant());
        }
        if (deck.getParentId() != null) {
            refreshContentType(context, deck.getParentId());
        }
    }

    @Override
    @Transactional
    public void undoDeckDeletion(WriteContext context, UUID batchId) {
        changeVersions.lock(context);
        DeleteBatch batch = ownedBatch(context, batchId, BATCH_ITEM_DECK);
        Deck item = deckMapper.findDeckById(batch.getRootItemId());
        if (item == null || item.getDeletedAt() != null || !batchId.equals(item.getDeleteBatchId())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        Deck parent = null;
        List<DeckSubtreeNode> subtree = deckMapper.findLiveSubtree(context.userId(), item.getId());
        if (item.getParentId() != null) {
            parent = parentOrMissing(context, item.getParentId());
            if (parent.getDeleteBatchId() != null) {
                throw new BusinessException(ErrorCode.DECK_IN_TRASH);
            }
            requirePlaceableUnder(parent, item, subtree);
        }
        Instant now = clock.instant();
        int rows = deckMapper.countInBatch(context.userId(), batchId);
        deckMapper.restoreBatch(
                context.userId(), batchId, changeVersions.block(context, rows), context.deviceId(), now);
        int cards = cardMapper.countInBatch(context.userId(), batchId);
        if (cards > 0) {
            cardMapper.restoreCardBatch(
                    context.userId(), batchId, changeVersions.block(context, cards), context.deviceId(), now);
        }
        if (parent != null) {
            // Back to its old place under a parent that may have moved meanwhile (BR-TRASH-008).
            int depth = parent.getDepth() + 1;
            deckMapper.updatePlacement(
                    context.userId(),
                    item.getId(),
                    parent.getId(),
                    parent.getRootId(),
                    depth,
                    item.getSiblingPosition(),
                    changeVersions.next(context),
                    context.deviceId(),
                    now);
            rewriteDescendants(context, item.getId(), parent.getRootId(), depth, subtree.size() - 1, now);
            refreshContentType(context, parent.getId());
        }
        deleteBatchMapper.tombstoneDeleteBatch(batchId, changeVersions.next(context), context.deviceId());
    }

    /** The owner's live batch of {@code itemType}; anything else has nothing to undo. */
    DeleteBatch ownedBatch(WriteContext context, UUID batchId, String itemType) {
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(batchId);
        if (batch == null
                || !batch.getUserId().equals(context.userId())
                || batch.getTombstonedAt() != null
                || !itemType.equals(batch.getItemType())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        return batch;
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
