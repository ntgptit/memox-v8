package com.memox.deck.service;

import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.MoveDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.ReorderDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.sync.service.WriteContext;
import java.util.UUID;

/** Deck operations, shared by REST and sync commands (API-A2 spec §5). Every method is one transaction. */
public interface DeckService {

    void createRootDeck(WriteContext context, CreateRootDeckRequest request);

    void createSubDeck(WriteContext context, UUID parentId, CreateSubDeckRequest request);

    void renameDeck(WriteContext context, UUID deckId, RenameDeckRequest request);

    void updateStudyOptions(WriteContext context, UUID deckId, StudyOptionsRequest request);

    /** Re-derives a sub-deck's content type from its children (BR-DECK-015); for services writing children. */
    void refreshContentType(WriteContext context, UUID deckId);

    void moveDeck(WriteContext context, UUID deckId, MoveDeckRequest request);

    void reorderDeck(WriteContext context, UUID deckId, ReorderDeckRequest request);
}
