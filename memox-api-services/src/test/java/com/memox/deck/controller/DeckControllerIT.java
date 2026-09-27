package com.memox.deck.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import java.util.LinkedHashMap;
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
class DeckControllerIT {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    DeckMapper deckMapper;

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

    UUID createRoot() throws Exception {
        UUID id = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/decks"), Map.of("id", id, "name", "Root", "schedulerType", "sm2")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(jsonPath("$.contentType").value("deck"));
        return id;
    }

    UUID createSub(UUID parent) throws Exception {
        UUID id = UUID.randomUUID();
        mockMvc.perform(json(post("/api/v1/decks/{id}/sub-decks", parent), Map.of("id", id, "name", "Sub")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.parentId").value(parent.toString()));
        return id;
    }

    @Test
    void deckWriteRoutesApplyTheSameRulesAsSyncCommands() throws Exception {
        UUID root = createRoot();
        UUID a = createSub(root);
        UUID b = createSub(root);
        UUID x = createSub(a);

        mockMvc.perform(json(patch("/api/v1/decks/{id}", x), Map.of("name", " Renamed ")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Renamed"));
        mockMvc.perform(json(post("/api/v1/decks/{id}/move", x), Map.of("targetParentId", b)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.parentId").value(b.toString()));
        mockMvc.perform(json(post("/api/v1/decks/{id}/reorder", b), Map.of("anchorId", a, "placement", "before")))
                .andExpect(status().isOk());
        mockMvc.perform(json(put("/api/v1/decks/{id}/study-options", root), Map.of("studyConfig", "{}")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.studyConfig").value("{}"));
        mockMvc.perform(json(post("/api/v1/decks/{id}/move", a), Map.of("targetParentId", a)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DECK_TREE_CYCLE"));
        mockMvc.perform(json(
                        delete("/api/v1/decks/{id}", b),
                        Map.of("batchId", UUID.randomUUID(), "deletedAt", "2026-09-27T02:00:00Z")))
                .andExpect(status().isNoContent());
        mockMvc.perform(json(patch("/api/v1/decks/{id}", UUID.randomUUID()), Map.of("name", "x")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
    }

    @Test
    void anIdempotencyKeyReplayWritesNothingAndAnswersLikeTheFirstTime() throws Exception {
        UUID root = createRoot();
        UUID key = UUID.randomUUID();

        mockMvc.perform(json(patch("/api/v1/decks/{id}", root), Map.of("name", "First"))
                        .header("Idempotency-Key", key))
                .andExpect(status().isOk());
        long version = deckMapper.findDeckById(root).getServerVersion();
        mockMvc.perform(json(patch("/api/v1/decks/{id}", root), Map.of("name", "Second"))
                        .header("Idempotency-Key", key))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("First"));

        assertThat(deckMapper.findDeckById(root).getServerVersion()).isEqualTo(version);
    }

    @Test
    void aRestWriteAndASyncCommandLeaveTheSameRow() throws Exception {
        UUID viaRest = createRoot();
        mockMvc.perform(json(patch("/api/v1/decks/{id}", viaRest), Map.of("name", "Same")))
                .andExpect(status().isOk());

        UUID viaSync = UUID.randomUUID();
        Map<String, Object> create = new LinkedHashMap<>();
        create.put("opId", UUID.randomUUID());
        create.put("kind", "command");
        create.put("type", "CREATE_ROOT_DECK");
        create.put("payload", Map.of("id", viaSync, "name", "Root", "schedulerType", "sm2"));
        Map<String, Object> rename = new LinkedHashMap<>();
        rename.put("opId", UUID.randomUUID());
        rename.put("kind", "command");
        rename.put("type", "RENAME_DECK");
        rename.put("payload", Map.of("deckId", viaSync, "name", "Same"));
        mockMvc.perform(json(
                        post("/api/v1/sync/push"),
                        Map.of("deviceId", UUID.randomUUID(), "operations", List.of(create, rename))))
                .andExpect(status().isOk());

        Deck rest = deckMapper.findDeckById(viaRest);
        Deck sync = deckMapper.findDeckById(viaSync);
        assertThat(sync.getName()).isEqualTo(rest.getName());
        assertThat(sync.getContentType()).isEqualTo(rest.getContentType());
        assertThat(sync.getSchedulerVersion()).isEqualTo(rest.getSchedulerVersion());
        assertThat(sync.getGeneration()).isEqualTo(rest.getGeneration());
        assertThat(sync.getDepth()).isEqualTo(rest.getDepth());
    }

    @Test
    void theDeviceHeaderIsRecordedAndItsAbsenceUsesTheRestDevice() throws Exception {
        UUID root = createRoot();
        assertThat(deckMapper.findDeckById(root).getLastDeviceId()).isEqualTo(new UUID(0L, 0L));

        UUID device = UUID.randomUUID();
        mockMvc.perform(json(patch("/api/v1/decks/{id}", root), Map.of("name", "N"))
                        .header("X-Device-Id", device))
                .andExpect(status().isOk());
        assertThat(deckMapper.findDeckById(root).getLastDeviceId()).isEqualTo(device);
    }
}
