package com.memox.deck.mapper;

import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckSubtreeNode;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DeckSyncMapper {

    /** Any user's row, tombstones included: the caller checks ownership. */
    Deck findDeckById(@Param("id") UUID id);

    /** The live subtree under {@code id}, the deck itself included at {@code rel = 0}. */
    List<DeckSubtreeNode> findLiveSubtree(@Param("userId") UUID userId, @Param("id") UUID id);

    void upsertDeck(Deck deck);

    /** Rewrites placement of the subtree's descendants, one version per row starting at {@code firstVersion}. */
    int updateSubtreePlacement(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("rootId") UUID rootId,
            @Param("depth") int depth,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId);

    /** Tombstones the live subtree, the deck itself included, one version per row starting at {@code firstVersion}. */
    int tombstoneSubtree(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId);

    List<Deck> findChangesSince(@Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);
}
