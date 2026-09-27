package com.memox.common.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.memox.TestcontainersConfiguration;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@WithMockUser
@Import(TestcontainersConfiguration.class)
@ExtendWith(OutputCaptureExtension.class)
class RequestIdFilterTest {

    private static final Pattern UUID_PATTERN =
            Pattern.compile("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}");

    @Autowired
    private MockMvc mockMvc;

    @Test
    void missingHeaderGetsAGeneratedUuid() throws Exception {
        String id = mockMvc.perform(get("/probe/ping"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getHeader(RequestIdFilter.REQUEST_ID_HEADER);

        assertThat(id).matches(UUID_PATTERN);
    }

    @Test
    void validInboundIdIsEchoed() throws Exception {
        mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, "client-42_a.B"))
                .andExpect(header().string(RequestIdFilter.REQUEST_ID_HEADER, "client-42_a.B"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"has space", "forged\r\nINFO fake line", "semi;colon", ""})
    void unsafeInboundIdIsReplaced(String inbound) throws Exception {
        String id = mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, inbound))
                .andReturn()
                .getResponse()
                .getHeader(RequestIdFilter.REQUEST_ID_HEADER);

        assertThat(id).matches(UUID_PATTERN);
    }

    @Test
    void tooLongInboundIdIsReplaced() throws Exception {
        String id = mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, "a".repeat(65)))
                .andReturn()
                .getResponse()
                .getHeader(RequestIdFilter.REQUEST_ID_HEADER);

        assertThat(id).matches(UUID_PATTERN);
    }

    @Test
    void errorBodyCarriesTheRequestId() throws Exception {
        mockMvc.perform(get("/probe/conflict").header(RequestIdFilter.REQUEST_ID_HEADER, "req-conflict-1"))
                .andExpect(status().isConflict())
                .andExpect(header().string(RequestIdFilter.REQUEST_ID_HEADER, "req-conflict-1"))
                .andExpect(jsonPath("$.requestId").value("req-conflict-1"));
    }

    @Test
    void requestLogLineCarriesTheIdAndTheMdcIsClearedAfterwards(CapturedOutput output) throws Exception {
        mockMvc.perform(get("/probe/ping").header(RequestIdFilter.REQUEST_ID_HEADER, "req-log-1"));

        assertThat(output.getOut()).contains("[req-log-1] ").contains("GET /probe/ping -> 200 in ");
        assertThat(MDC.get(RequestIdFilter.REQUEST_ID_MDC_KEY)).isNull();
    }
}
