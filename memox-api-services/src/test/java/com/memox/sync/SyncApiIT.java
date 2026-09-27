package com.memox.sync;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.security.CurrentUserProvider;
import java.util.ArrayList;
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
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class SyncApiIT {

    private static final String PUSH = "/api/v1/sync/push";
    private static final String CHANGES = "/api/v1/sync/changes";
    private static final String T = "2026-09-27T01:00:00Z";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private CurrentUserProvider currentUserProvider;

    private final UUID device = UUID.randomUUID();
    private UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    @Test
    void pushingTheSameOperationTwiceAppliesItOnce() throws Exception {
        UUID root = UUID.randomUUID();
        Map<String, Object> op = upsert(UUID.randomUUID(), rootRow(root, "First"));

        long version = versionOf(push(op));
        push(op).andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("applied"))
                .andExpect(jsonPath("$.results[0].serverVersion").value(version));
        changes(0).andExpect(jsonPath("$.changes", hasSize(1)));
    }

    @Test
    void aRejectedOperationReturnsTheServersCopyAndTheBatchGoesOn() throws Exception {
        UUID root = UUID.randomUUID();
        UUID child = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), rootRow(root, "Root")), upsert(UUID.randomUUID(), childRow(child, root)));

        UUID other = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), childRow(root, child)), upsert(UUID.randomUUID(), rootRow(other, "Other")))
                .andExpect(jsonPath("$.results[0].status").value("rejected"))
                .andExpect(jsonPath("$.results[0].code").value("DECK_TREE_CYCLE"))
                .andExpect(jsonPath("$.results[0].current.row.parentId").doesNotExist())
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void anUnknownEntityTypeIsRejectedWithoutCurrent() throws Exception {
        Map<String, Object> op = new LinkedHashMap<>(upsert(UUID.randomUUID(), rootRow(UUID.randomUUID(), "X")));
        op.put("entityType", "spaceship");

        push(op).andExpect(jsonPath("$.results[0].status").value("rejected"))
                .andExpect(jsonPath("$.results[0].code").value("SYNC_ENTITY_UNSUPPORTED"))
                .andExpect(jsonPath("$.results[0].current").doesNotExist());
    }

    @Test
    void usersNeverSeeOrOverwriteEachOthersData() throws Exception {
        UUID root = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), rootRow(root, "Mine")));
        UUID owner = user;

        user = UUID.randomUUID();
        push(upsert(UUID.randomUUID(), rootRow(root, "Stolen")))
                .andExpect(jsonPath("$.results[0].code").value("SYNC_ENTITY_CONFLICT"))
                .andExpect(jsonPath("$.results[0].current").doesNotExist());
        changes(0).andExpect(jsonPath("$.changes", hasSize(0)));

        user = owner;
        changes(0).andExpect(jsonPath("$.changes[0].row.name").value("Mine"));
    }

    @Test
    void aSubtreeMoveIsPagedWithoutLosingRows() throws Exception {
        UUID rootA = UUID.randomUUID();
        UUID rootB = UUID.randomUUID();
        UUID x = UUID.randomUUID();
        List<Map<String, Object>> ops = new ArrayList<>();
        ops.add(upsert(UUID.randomUUID(), rootRow(rootA, "A")));
        ops.add(upsert(UUID.randomUUID(), rootRow(rootB, "B")));
        ops.add(upsert(UUID.randomUUID(), childRow(x, rootA)));
        for (int i = 0; i < 4; i++) {
            ops.add(upsert(UUID.randomUUID(), childRow(UUID.randomUUID(), x)));
        }
        push(ops.toArray(Map[]::new));
        long cursor = objectMapper
                .readTree(changes(0).andReturn().getResponse().getContentAsString())
                .get("nextSince")
                .asLong();

        push(upsert(UUID.randomUUID(), childRow(x, rootB)));

        List<String> seen = new ArrayList<>();
        boolean hasMore = true;
        while (hasMore) {
            var page = objectMapper.readTree(mockMvc.perform(
                            get(CHANGES).param("since", String.valueOf(cursor)).param("limit", "2"))
                    .andReturn()
                    .getResponse()
                    .getContentAsString());
            page.get("changes")
                    .forEach(change -> seen.add(change.get("entityId").asText()));
            cursor = page.get("nextSince").asLong();
            hasMore = page.get("hasMore").asBoolean();
        }
        org.assertj.core.api.Assertions.assertThat(seen).hasSize(5).contains(x.toString());
    }

    @Test
    void rejectsAnOversizedBatchAndAnOutOfRangeLimit() throws Exception {
        Map<String, Object>[] ops = new Map[101];
        for (int i = 0; i < ops.length; i++) {
            ops[i] = upsert(UUID.randomUUID(), rootRow(UUID.randomUUID(), "N" + i));
        }
        push(ops)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mockMvc.perform(get(CHANGES).param("since", "0").param("limit", "501")).andExpect(status().isBadRequest());
    }

    @SafeVarargs
    private ResultActions push(Map<String, Object>... operations) throws Exception {
        Map<String, Object> body = Map.of("deviceId", device, "operations", List.of(operations));
        return mockMvc.perform(
                post(PUSH).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(body)));
    }

    private ResultActions changes(long since) throws Exception {
        return mockMvc.perform(get(CHANGES).param("since", String.valueOf(since)));
    }

    private long versionOf(ResultActions result) throws Exception {
        return objectMapper
                .readTree(result.andReturn().getResponse().getContentAsString())
                .at("/results/0/serverVersion")
                .asLong();
    }

    private static Map<String, Object> upsert(UUID opId, Map<String, Object> row) {
        return Map.of("opId", opId, "entityType", "deck", "entityId", row.get("id"), "op", "upsert", "row", row);
    }

    private static Map<String, Object> rootRow(UUID id, String name) {
        Map<String, Object> row = baseRow(id, name);
        row.put("contentType", "deck");
        row.put("schedulerType", "sm2");
        return row;
    }

    private static Map<String, Object> childRow(UUID id, UUID parentId) {
        Map<String, Object> row = baseRow(id, "Child " + id);
        row.put("parentId", parentId);
        row.put("contentType", "deck");
        return row;
    }

    private static Map<String, Object> baseRow(UUID id, String name) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", id);
        row.put("name", name);
        row.put("siblingPosition", 0);
        row.put("createdAt", T);
        row.put("updatedAt", T);
        return row;
    }
}
