package com.memox.common.type_handler;

import static org.assertj.core.api.Assertions.assertThat;

import com.memox.TestcontainersConfiguration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mybatis.spring.boot.test.autoconfigure.MybatisTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/**
 * Proves the MyBatis wiring against a real PostgreSQL: mapper XML under {@code mapper/**} is loaded, and the type
 * handlers in {@code common.type_handler} are registered.
 */
@MybatisTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class MyBatisBaseIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse(TestcontainersConfiguration.POSTGRES_IMAGE));

    @Autowired
    private BaseRoundTripMapper mapper;

    @Test
    void uuidRoundTripsThroughTheUuidType() {
        UUID id = UUID.fromString("0f8fad5b-d9cb-469f-a165-70867728950e");

        assertThat(mapper.echoUuid(id)).isEqualTo(id);
    }

    @Test
    void codeEnumIsStoredAsItsCode() {
        assertThat(mapper.storedStatusCode(SampleStatus.INACTIVE)).isEqualTo("I");
    }

    @Test
    void codeEnumIsReadFromItsCode() {
        assertThat(mapper.statusFromCode("A")).isEqualTo(SampleStatus.ACTIVE);
    }

    @Test
    void instantRoundTripsUnchanged() {
        Instant instant = Instant.parse("2026-09-27T01:02:03.456Z");

        assertThat(mapper.echoInstant(instant)).isEqualTo(instant);
    }

    @Test
    void instantIsStoredAsTheSameUtcMoment() {
        Instant instant = Instant.parse("2026-09-27T01:02:03Z");

        assertThat(mapper.instantAsUtcText(instant)).isEqualTo("2026-09-27T01:02:03");
    }
}
