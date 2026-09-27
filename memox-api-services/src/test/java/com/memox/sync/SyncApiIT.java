package com.memox.sync;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class SyncApiIT {

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

    @Test
    void aMoveReachesTheFeedWithBothParentsAndTheSubtree() throws Exception {
        UUID root = UUID.randomUUID();
        UUID from = UUID.randomUUID();
        UUID to = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", from, "parentId", root, "name", "From")),
                command("CREATE_SUB_DECK", Map.of("id", to, "parentId", root, "name", "To")),
                command("CREATE_SUB_DECK", Map.of("id", x, "parentId", from, "name", "X")),
                command("CREATE_SUB_DECK", Map.of("id", y, "parentId", x, "name", "Y")));
        long cursor = readJson(changes(0)).get("nextSince").asLong();

        push(command("MOVE_DECK", Map.of("deckId", x, "targetParentId", to)))
                .andExpect(jsonPath("$.results[0].status").value("applied"));

        JsonNode page = readJson(changes(cursor));
        Set<String> changed = new HashSet<>();
        page.get("changes").forEach(change -> changed.add(change.get("entityId").asText()));
        assertThat(changed).contains(from.toString(), to.toString(), x.toString(), y.toString());
    }

    @Test
    void aRejectedMoveReturnsTheAffectedDeckAndTheBatchGoesOn() throws Exception {
        UUID root = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        UUID y = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", x, "parentId", root, "name", "X")),
                command("CREATE_SUB_DECK", Map.of("id", y, "parentId", x, "name", "Y")));

        Map<String, Object> cycle = new LinkedHashMap<>(command("MOVE_DECK", Map.of("deckId", x, "targetParentId", y)));
        cycle.put("affected", List.of(Map.of("entityType", "deck", "entityId", x)));
        push(cycle, command("RENAME_DECK", Map.of("deckId", root, "name", "Renamed")))
                .andExpect(jsonPath("$.results[0].code").value("DECK_TREE_CYCLE"))
                .andExpect(jsonPath("$.results[0].current[0].row.parentId").value(root.toString()))
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void theOldRowShapeFromTheAppIsRejectedPerOperation() throws Exception {
        Map<String, Object> old = new LinkedHashMap<>();
        old.put("opId", UUID.randomUUID());
        old.put("entityType", "deck");
        old.put("entityId", UUID.randomUUID());
        old.put("op", "upsert");
        old.put("row", Map.of("name", "Old"));
        UUID root = UUID.randomUUID();

        push(old, command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")))
                .andExpect(jsonPath("$.results[0].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void aStudyOptionsPatchIsAppliedAndItsTargetReturnedOnRejection() throws Exception {
        UUID root = UUID.randomUUID();
        UUID sub = UUID.randomUUID();
        push(
                command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Root", "schedulerType", "sm2")),
                command("CREATE_SUB_DECK", Map.of("id", sub, "parentId", root, "name", "Sub")));

        push(patch(root, Map.of("studyConfig", "{\"cardLimit\":5}")), patch(sub, Map.of("studyConfig", "{}")))
                .andExpect(jsonPath("$.results[0].status").value("applied"))
                .andExpect(jsonPath("$.results[1].code").value("DECK_ROOT_REQUIRED"))
                .andExpect(jsonPath("$.results[1].current[0].entityId").value(sub.toString()));
    }

    @Test
    void usersNeverSeeEachOthersDecks() throws Exception {
        UUID root = UUID.randomUUID();
        push(command("CREATE_ROOT_DECK", Map.of("id", root, "name", "Mine", "schedulerType", "sm2")));

        user = UUID.randomUUID();
        Map<String, Object> steal = new LinkedHashMap<>(command("RENAME_DECK", Map.of("deckId", root, "name", "X")));
        steal.put("affected", List.of(Map.of("entityType", "deck", "entityId", root)));
        push(steal)
                .andExpect(jsonPath("$.results[0].code").value("SYNC_ENTITY_CONFLICT"))
                .andExpect(jsonPath("$.results[0].current", hasSize(0)));
        changes(0).andExpect(jsonPath("$.changes", hasSize(0)));
    }

    @Test
    void aSubtreeMoveIsPagedWithoutLosingRows() throws Exception {
        UUID rootA = UUID.randomUUID();
        UUID from = UUID.randomUUID();
        UUID to = UUID.randomUUID();
        List<Map<String, Object>> ops = new ArrayList<>();
        ops.add(command("CREATE_ROOT_DECK", Map.of("id", rootA, "name", "A", "schedulerType", "sm2")));
        ops.add(command("CREATE_SUB_DECK", Map.of("id", from, "parentId", rootA, "name", "From")));
        ops.add(command("CREATE_SUB_DECK", Map.of("id", to, "parentId", rootA, "name", "To")));
        for (int i = 0; i < 4; i++) {
            ops.add(command("CREATE_SUB_DECK", Map.of("id", UUID.randomUUID(), "parentId", from, "name", "C" + i)));
        }
        UUID x = UUID.randomUUID();
        ops.add(command("CREATE_SUB_DECK", Map.of("id", x, "parentId", from, "name", "X")));
        push(ops.toArray(Map[]::new));
        long cursor = readJson(changes(0)).get("nextSince").asLong();

        push(command("MOVE_DECK", Map.of("deckId", from, "targetParentId", to)));

        Set<String> seen = new HashSet<>();
        boolean hasMore = true;
        while (hasMore) {
            JsonNode page = readJson(mockMvc.perform(get("/api/v1/sync/changes")
                    .param("since", String.valueOf(cursor))
                    .param("limit", "2")));
            page.get("changes")
                    .forEach(change -> seen.add(change.get("entityId").asText()));
            cursor = page.get("nextSince").asLong();
            hasMore = page.get("hasMore").asBoolean();
        }
        assertThat(seen).contains(from.toString(), to.toString(), x.toString());
        assertThat(seen).hasSize(7);
    }

    private ResultActions push(Map<?, ?>... operations) throws Exception {
        Map<String, Object> body = Map.of("deviceId", UUID.randomUUID(), "operations", List.of(operations));
        return mockMvc.perform(post("/api/v1/sync/push")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    private ResultActions changes(long since) throws Exception {
        return mockMvc.perform(get("/api/v1/sync/changes").param("since", String.valueOf(since)));
    }

    private JsonNode readJson(ResultActions result) throws Exception {
        return objectMapper.readTree(result.andReturn().getResponse().getContentAsString());
    }

    private static Map<String, Object> command(String type, Map<String, Object> payload) {
        Map<String, Object> op = new LinkedHashMap<>();
        op.put("opId", UUID.randomUUID());
        op.put("kind", "command");
        op.put("type", type);
        op.put("payload", payload);
        return op;
    }

    private static Map<String, Object> patch(UUID deckId, Map<String, Object> fields) {
        Map<String, Object> op = new LinkedHashMap<>();
        op.put("opId", UUID.randomUUID());
        op.put("kind", "patch");
        op.put("entityType", "deck");
        op.put("entityId", deckId);
        op.put("group", "study_options");
        op.put("fields", fields);
        return op;
    }
}
