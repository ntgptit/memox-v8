package com.memox.common;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.type_handler.SampleStatus;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.json.JsonTest;

/**
 * Pins the JSON contract the Flutter client relies on. These are Boot's defaults plus {@code spring.jackson.time-zone:
 * UTC}; a failure here means a configuration change broke the API contract.
 */
@JsonTest
class JsonContractTest {

    record Sample(Instant at, String nickname, SampleStatus status, UUID id) {}

    record Named(String name) {}

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void writesIsoUtcInstantsNullsEnumNamesAndCanonicalUuids() throws Exception {
        Sample sample = new Sample(
                Instant.parse("2026-09-27T01:02:03Z"),
                null,
                SampleStatus.ACTIVE,
                UUID.fromString("0F8FAD5B-D9CB-469F-A165-70867728950E"));

        assertThat(objectMapper.writeValueAsString(sample))
                .isEqualTo("{\"at\":\"2026-09-27T01:02:03Z\",\"nickname\":null,\"status\":\"ACTIVE\","
                        + "\"id\":\"0f8fad5b-d9cb-469f-a165-70867728950e\"}");
    }

    @Test
    void ignoresUnknownProperties() throws Exception {
        Named named = objectMapper.readValue("{\"name\":\"deck\",\"addedByANewerClient\":1}", Named.class);

        assertThat(named.name()).isEqualTo("deck");
    }
}
