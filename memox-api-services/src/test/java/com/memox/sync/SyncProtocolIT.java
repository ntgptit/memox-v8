package com.memox.sync;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.TestcontainersConfiguration;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.common.security.CurrentUserProvider;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.model.Deck;
import com.memox.sync.service.ChangeVersions;
import com.memox.sync.service.PayloadReader;
import com.memox.sync.service.SyncCommandHandler;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, SyncProtocolIT.TestHandlers.class})
class SyncProtocolIT {

    private static final String PUSH = "/api/v1/sync/push";

    @TestConfiguration
    static class TestHandlers {
        @Bean
        SyncCommandHandler testCreate(DeckMapper deckMapper, ChangeVersions versions, PayloadReader payloads) {
            return new SyncCommandHandler("TEST_CREATE", (context, payload) -> {
                UUID id = payloads.id(payload, "id");
                Instant now = Instant.parse("2026-09-27T01:00:00Z");
                deckMapper.insertDeck(Deck.builder()
                        .id(id)
                        .userId(context.userId())
                        .name("Root")
                        .rootId(id)
                        .depth(1)
                        .contentType("deck")
                        .schedulerType("sm2")
                        .schedulerVersion(1)
                        .generation(1)
                        .siblingPosition(0)
                        .createdAt(now)
                        .updatedAt(now)
                        .serverVersion(versions.next(context))
                        .lastDeviceId(context.deviceId())
                        .build());
            });
        }

        @Bean
        SyncCommandHandler testReject() {
            return new SyncCommandHandler("TEST_REJECT", (context, payload) -> {
                throw new BusinessException(ErrorCode.DECK_TREE_CYCLE);
            });
        }
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private CurrentUserProvider currentUserProvider;

    private UUID user;

    @BeforeEach
    void newUser() {
        user = UUID.randomUUID();
        when(currentUserProvider.currentUserId()).thenAnswer(invocation -> user);
    }

    @Test
    void appliesACommandOnceAndReportsTheUsersLatestVersion() throws Exception {
        Map<String, Object> op = command("TEST_CREATE", Map.of("id", UUID.randomUUID()));

        push(op).andExpect(jsonPath("$.results[0].status").value("applied"))
                .andExpect(jsonPath("$.results[0].serverVersion").value(1));
        push(op).andExpect(jsonPath("$.results[0].serverVersion").value(1));
        mockMvc.perform(get("/api/v1/sync/changes").param("since", "0")).andExpect(jsonPath("$.changes", hasSize(1)));
    }

    @Test
    void aRejectionListsTheAffectedEntitiesTheUserOwnsAndTheBatchGoesOn() throws Exception {
        UUID mine = UUID.randomUUID();
        push(command("TEST_CREATE", Map.of("id", mine)));
        UUID owner = user;
        user = UUID.randomUUID();
        UUID theirs = UUID.randomUUID();
        push(command("TEST_CREATE", Map.of("id", theirs)));
        user = owner;
        UUID unknown = UUID.randomUUID();

        Map<String, Object> reject = new LinkedHashMap<>(command("TEST_REJECT", Map.of()));
        reject.put("affected", List.of(affected(mine), affected(theirs), affected(unknown)));
        push(reject, command("TEST_CREATE", Map.of("id", UUID.randomUUID())))
                .andExpect(jsonPath("$.results[0].status").value("rejected"))
                .andExpect(jsonPath("$.results[0].code").value("DECK_TREE_CYCLE"))
                .andExpect(jsonPath("$.results[0].current", hasSize(2)))
                .andExpect(jsonPath("$.results[0].current[0].entityId").value(mine.toString()))
                .andExpect(jsonPath("$.results[0].current[0].row.name").value("Root"))
                .andExpect(jsonPath("$.results[0].current[1].entityId").value(unknown.toString()))
                .andExpect(jsonPath("$.results[0].current[1].deleted").value(true))
                .andExpect(jsonPath("$.results[0].current[1].serverVersion").value(0))
                .andExpect(jsonPath("$.results[1].status").value("applied"));
    }

    @Test
    void malformedOperationsAreRejectedOneByOneNeverTheWholePush() throws Exception {
        Map<String, Object> oldShape = new LinkedHashMap<>();
        oldShape.put("opId", UUID.randomUUID());
        oldShape.put("entityType", "deck");
        oldShape.put("entityId", UUID.randomUUID());
        oldShape.put("op", "upsert");
        oldShape.put("row", Map.of("name", "x"));
        Map<String, Object> unknownKind = new LinkedHashMap<>(command("TEST_CREATE", Map.of()));
        unknownKind.put("kind", "spaceship");
        Map<String, Object> unknownType = command("SPACESHIP", Map.of());
        Map<String, Object> unknownGroup = new LinkedHashMap<>();
        unknownGroup.put("opId", UUID.randomUUID());
        unknownGroup.put("kind", "patch");
        unknownGroup.put("entityType", "deck");
        unknownGroup.put("entityId", UUID.randomUUID());
        unknownGroup.put("group", "warp_drive");
        unknownGroup.put("fields", Map.of());
        Map<String, Object> badPayload = command("TEST_CREATE", Map.of("id", "not-a-uuid"));

        push(oldShape, unknownKind, unknownType, unknownGroup, badPayload)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[1].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[2].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[3].code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.results[3].current", hasSize(1)))
                .andExpect(jsonPath("$.results[4].code").value("VALIDATION_FAILED"));
    }

    private ResultActions push(Map<?, ?>... operations) throws Exception {
        Map<String, Object> body = Map.of("deviceId", UUID.randomUUID(), "operations", List.of(operations));
        return mockMvc.perform(post(PUSH)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    private static Map<String, Object> command(String type, Map<String, Object> payload) {
        Map<String, Object> op = new LinkedHashMap<>();
        op.put("opId", UUID.randomUUID());
        op.put("kind", "command");
        op.put("type", type);
        op.put("payload", payload);
        return op;
    }

    private static Map<String, Object> affected(UUID id) {
        return Map.of("entityType", "deck", "entityId", id);
    }
}
