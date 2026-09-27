package com.memox.common.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.memox.TestcontainersConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@WithMockUser
@Import(TestcontainersConfiguration.class)
class OpenApiDocsTest {

    private static final String PROBLEM_REF = "#/components/schemas/ProblemDetail";

    @Autowired
    private MockMvc mockMvc;

    @Test
    void documentsTheApiAndTheErrorBody() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.info.title").value("MemoX API"))
                .andExpect(jsonPath("$.info.version").value("v1"))
                .andExpect(jsonPath("$.components.schemas.ProblemDetail.properties.code.type")
                        .value("string"))
                .andExpect(jsonPath("$.components.schemas.ProblemDetail.properties.requestId.type")
                        .value("string"))
                .andExpect(jsonPath("$.components.schemas.ProblemDetail.properties.errors.type")
                        .value("array"));
    }

    @Test
    void everyOperationDocumentsTheProblemResponse() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(jsonPath("$.paths['/probe/ping'].get.responses.default.content['application/problem+json']"
                                + ".schema.$ref")
                        .value(PROBLEM_REF));
    }
}
