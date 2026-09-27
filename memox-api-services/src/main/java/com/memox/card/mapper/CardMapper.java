package com.memox.card.mapper;

import com.memox.card.model.Card;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CardMapper {

    /** Any user's row, purged included: the caller checks ownership. */
    Card findCardById(@Param("id") UUID id);

    List<Card> findCardsByIds(@Param("ids") List<UUID> ids);

    void insertCard(Card card);

    List<Card> findChangesSince(@Param("userId") UUID userId, @Param("since") long since, @Param("limit") int limit);

    int updateContent(Card card);

    int updateFlag(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("flagged") boolean flagged,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** Moves {@code ids} to {@code deckId}, one version each from {@code firstVersion}, in id order. */
    int moveCards(
            @Param("userId") UUID userId,
            @Param("ids") List<UUID> ids,
            @Param("deckId") UUID deckId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int markCard(
            @Param("userId") UUID userId,
            @Param("id") UUID id,
            @Param("batchId") UUID batchId,
            @Param("version") long version,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    /** Active cards whose deck is in {@code batchId}. */
    int countCardsInDeckBatch(@Param("userId") UUID userId, @Param("batchId") UUID batchId);

    int markCardsInDeckBatch(
            @Param("userId") UUID userId,
            @Param("batchId") UUID batchId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);

    int countInBatch(@Param("userId") UUID userId, @Param("batchId") UUID batchId);

    int restoreCardBatch(
            @Param("userId") UUID userId,
            @Param("batchId") UUID batchId,
            @Param("firstVersion") long firstVersion,
            @Param("deviceId") UUID deviceId,
            @Param("now") Instant now);
}
