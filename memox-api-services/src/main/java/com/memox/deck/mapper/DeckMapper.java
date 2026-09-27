package com.memox.deck.mapper;

import com.memox.deck.model.Deck;
import com.memox.deck.model.DeckSubtreeNode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DeckMapper {

    /** Any user's row, tombstones included: the caller checks ownership. */
    Deck findDeckById(@Param("id") UUID id);

    /** The live subtree under {@code id}, the deck itself included at {@code rel = 0}. */
    List<DeckSubtreeNode> findLiveSubtree(@Param("userId") UUID userId, @Param("id") UUID id);

    void insertDeck(Deck deck);

    /** Rewrites placement of the subtree's descendants, one version per row starting at {@code firstVersion}. */
    int updateSubtreePlacement(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("rootId") UUID rootId,
            @Param("depth") int depth,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId);

    List<Deck> findChangesSince(@Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);

    int nextSiblingPosition(@Param("userId") UUID userId, @Param("parentId") UUID parentId);

    int updateName(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("name") String name,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int updateStudyConfig(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("studyConfig") String studyConfig,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int updateContentType(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("contentType") String contentType,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** What the deck's direct children make it: children sharing its own batch count, so Trash keeps its shape. */
    String deriveContentType(@Param("id") UUID id);
}
