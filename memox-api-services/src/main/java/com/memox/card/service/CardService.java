package com.memox.card.service;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.dto.request.DeleteCardsRequest;
import com.memox.card.dto.request.MoveCardsRequest;
import com.memox.sync.service.WriteContext;
import java.util.UUID;

/** Card operations, shared by REST and sync commands (API-A2 spec §5). Every method is one transaction. */
public interface CardService {

    void createCard(WriteContext context, UUID deckId, CreateCardRequest request);

    void updateContent(WriteContext context, UUID cardId, CardContentRequest request);

    void updateFlag(WriteContext context, UUID cardId, CardFlagRequest request);

    void moveCards(WriteContext context, MoveCardsRequest request);

    void deleteCards(WriteContext context, DeleteCardsRequest request);

    void undoCardDeletion(WriteContext context, UUID batchId);
}
