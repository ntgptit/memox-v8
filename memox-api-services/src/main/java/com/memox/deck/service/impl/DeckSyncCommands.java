package com.memox.deck.service.impl;

import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.PayloadReader;
import com.memox.sync.service.SyncCommandHandler;
import com.memox.sync.service.SyncPatchHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Deck commands and patches of the sync protocol: each reads its payload and calls {@link DeckService}. */
@Configuration(proxyBeanMethods = false)
class DeckSyncCommands {

    @Bean
    SyncCommandHandler createRootDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "CREATE_ROOT_DECK",
                (context, payload) ->
                        decks.createRootDeck(context, payloads.read(payload, CreateRootDeckRequest.class)));
    }

    @Bean
    SyncCommandHandler createSubDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "CREATE_SUB_DECK",
                (context, payload) -> decks.createSubDeck(
                        context, payloads.id(payload, "parentId"), payloads.read(payload, CreateSubDeckRequest.class)));
    }

    @Bean
    SyncCommandHandler renameDeckCommand(DeckService decks, PayloadReader payloads) {
        return new SyncCommandHandler(
                "RENAME_DECK",
                (context, payload) -> decks.renameDeck(
                        context, payloads.id(payload, "deckId"), payloads.read(payload, RenameDeckRequest.class)));
    }

    @Bean
    SyncPatchHandler deckStudyOptionsPatch(DeckService decks, PayloadReader payloads) {
        return new SyncPatchHandler(
                DeckReader.ENTITY_TYPE,
                "study_options",
                (context, deckId, fields) ->
                        decks.updateStudyOptions(context, deckId, payloads.read(fields, StudyOptionsRequest.class)));
    }
}
