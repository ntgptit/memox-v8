package com.memox.card.dto.request;

import com.memox.card.enums.CardSortField;
import com.memox.common.PageQuery;

/** {@code GET /api/v1/decks/{id}/cards}: the deck's active cards. */
public class CardListQuery extends PageQuery<CardSortField> {}
