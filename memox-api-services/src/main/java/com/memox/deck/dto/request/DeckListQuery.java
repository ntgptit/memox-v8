package com.memox.deck.dto.request;

import com.memox.common.PageQuery;
import com.memox.deck.enums.DeckSortField;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** {@code GET /api/v1/decks}: a level's active decks; no {@code parentId} lists the roots. */
@Getter
@Setter
public class DeckListQuery extends PageQuery<DeckSortField> {
    private UUID parentId;
}
