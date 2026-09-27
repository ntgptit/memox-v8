package com.memox;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.JdbcTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/** Flyway V1 creates the sync schema and its constraints hold. */
@JdbcTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class SchemaIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse(TestcontainersConfiguration.POSTGRES_IMAGE));

    private static final String INSERT_ROOT = "INSERT INTO deck (id, user_id, name, parent_id, root_id, depth,"
            + " content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at,"
            + " updated_at, server_version, last_device_id)"
            + " VALUES (?, ?, 'Root', NULL, ?, ?, ?, ?, 1, 1, 0, now(), now(), 1, ?)";

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void createsTheSyncTables() {
        assertThat(jdbc.queryForList(
                        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'", String.class))
                .contains("deck", "user_sync_version", "sync_applied_op");
    }

    @Test
    void acceptsAValidRoot() {
        UUID id = UUID.randomUUID();

        jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 1, "deck", "sm2", UUID.randomUUID());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM deck WHERE id = ?", Integer.class, id))
                .isOne();
    }

    @Test
    void rejectsTwoRowsWithTheSameVersionForOneUser() {
        UUID user = UUID.randomUUID();
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();
        jdbc.update(INSERT_ROOT, first, user, first, 1, "deck", "sm2", UUID.randomUUID());

        assertThatThrownBy(() -> jdbc.update(INSERT_ROOT, second, user, second, 1, "deck", "sm2", UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void rejectsDepthAboveTen() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(
                        () -> jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 11, "deck", "sm2", UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void rejectsARootWithoutScheduler() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(
                        () -> jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 1, "deck", null, UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void rejectsAnUnknownContentType() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() ->
                        jdbc.update(INSERT_ROOT, id, UUID.randomUUID(), id, 1, "folder", "sm2", UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
