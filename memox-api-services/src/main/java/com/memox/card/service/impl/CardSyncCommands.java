package com.memox.card.service.impl;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.dto.request.DeleteCardsRequest;
import com.memox.card.dto.request.MoveCardsRequest;
import com.memox.card.service.CardService;
import com.memox.sync.service.PayloadReader;
import com.memox.sync.service.SyncCommandHandler;
import com.memox.sync.service.SyncPatchHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Card commands and patches of the sync protocol: each reads its payload and calls {@link CardService}. */
@Configuration(proxyBeanMethods = false)
class CardSyncCommands {

    @Bean
    SyncCommandHandler createCardCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "CREATE_CARD",
                (context, payload) -> cards.createCard(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, CreateCardRequest.class)));
    }

    @Bean
    SyncPatchHandler cardContentPatch(CardService cards, PayloadReader payloads) {
        return new SyncPatchHandler(
                CardReader.ENTITY_TYPE,
                "content",
                (context, cardId, fields) ->
                        cards.updateContent(context, cardId, payloads.read(fields, CardContentRequest.class)));
    }

    @Bean
    SyncPatchHandler cardFlagPatch(CardService cards, PayloadReader payloads) {
        return new SyncPatchHandler(
                CardReader.ENTITY_TYPE,
                "flag",
                (context, cardId, fields) ->
                        cards.updateFlag(context, cardId, payloads.read(fields, CardFlagRequest.class)));
    }

    @Bean
    SyncCommandHandler moveCardsCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "MOVE_CARDS",
                (context, payload) -> cards.moveCards(context, payloads.read(payload, MoveCardsRequest.class)));
    }

    @Bean
    SyncCommandHandler deleteCardsCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "DELETE_CARDS",
                (context, payload) -> cards.deleteCards(context, payloads.read(payload, DeleteCardsRequest.class)));
    }

    @Bean
    SyncCommandHandler undoCardDeletionCommand(CardService cards, PayloadReader payloads) {
        return new SyncCommandHandler(
                "UNDO_CARD_DELETION",
                (context, payload) -> cards.undoCardDeletion(context, payloads.id(payload, "batchId")));
    }
}
