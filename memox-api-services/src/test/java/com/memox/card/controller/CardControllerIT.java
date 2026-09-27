package com.memox.card.controller;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class CardControllerIT {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockitoBean
    CurrentUserProvider currentUserProvider;

    UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, Object body) throws Exception {
        return request.contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(body));
    }

    UUID deck(UUID parent) throws Exception {
        UUID id = UUID.randomUUID();
        if (parent == null) {
            mockMvc.perform(json(post("/api/v1/decks"), Map.of("id", id, "name", "Root", "schedulerType", "sm2")))
                    .andExpect(status().isCreated());
        } else {
            mockMvc.perform(json(post("/api/v1/decks/{id}/sub-decks", parent), Map.of("id", id, "name", "Sub")))
                    .andExpect(status().isCreated());
        }
        return id;
    }

    UUID card(UUID deckId) throws Exception {
        UUID id = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/decks/{id}/cards", deckId), Map.of("id", id, "front", "犬", "back", "dog")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.deckId").value(deckId.toString()));
        return id;
    }

    @Test
    void cardRoutesEditMoveDeleteAndUndo() throws Exception {
        UUID root = deck(null);
        UUID from = deck(root);
        UUID to = deck(root);
        UUID id = card(from);

        mockMvc.perform(json(patch("/api/v1/cards/{id}", id), Map.of("front", "猫", "back", "cat")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.front").value("猫"));
        mockMvc.perform(json(put("/api/v1/cards/{id}/flag", id), Map.of("isFlagged", true)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isFlagged").value(true));
        mockMvc.perform(json(post("/api/v1/cards/move"), Map.of("cardIds", List.of(id), "targetDeckId", to)))
                .andExpect(status().isNoContent());

        UUID batch = UUID.randomUUID();
        mockMvc.perform(json(
                        post("/api/v1/cards/delete"),
                        Map.of(
                                "items",
                                List.of(Map.of("cardId", id, "batchId", batch)),
                                "deletedAt",
                                "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());
        mockMvc.perform(post("/api/v1/trash/batches/{id}/undo", batch)).andExpect(status().isNoContent());
        mockMvc.perform(post("/api/v1/trash/batches/{id}/undo", batch))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BATCH_NOT_FOUND"));
    }

    @Test
    void undoOfADeckBatchGoesThroughTheSameRoute() throws Exception {
        UUID root = deck(null);
        UUID sub = deck(root);
        card(sub);
        UUID batch = UUID.randomUUID();
        mockMvc.perform(json(
                        delete("/api/v1/decks/{id}", sub),
                        Map.of("batchId", batch, "deletedAt", "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());

        mockMvc.perform(post("/api/v1/trash/batches/{id}/undo", batch)).andExpect(status().isNoContent());
    }

    @Test
    void aCardOnARootIsAConflict() throws Exception {
        UUID root = deck(null);
        mockMvc.perform(json(
                        post("/api/v1/decks/{id}/cards", root),
                        Map.of("id", UUID.randomUUID(), "front", "a", "back", "b")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DECK_CONTENT_TYPE_MISMATCH"));
    }

    @Test
    void readsPageADecksActiveCards() throws Exception {
        UUID sub = deck(deck(null));
        UUID first = card(sub);
        card(sub);
        card(sub);

        mockMvc.perform(get("/api/v1/decks/{id}/cards", sub).param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.totalItems").value(3))
                .andExpect(jsonPath("$.hasNext").value(true));
        mockMvc.perform(get("/api/v1/cards/{id}", first))
                .andExpect(jsonPath("$.back").value("dog"));
        mockMvc.perform(get("/api/v1/cards/{id}", UUID.randomUUID())).andExpect(status().isNotFound());
    }
}
