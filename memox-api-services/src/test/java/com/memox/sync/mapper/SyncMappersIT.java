package com.memox.sync.mapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.TestcontainersConfiguration;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mybatis.spring.boot.test.autoconfigure.MybatisTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DuplicateKeyException;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@MybatisTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class SyncMappersIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse(TestcontainersConfiguration.POSTGRES_IMAGE));

    @Autowired
    private SyncVersionMapper versions;

    @Autowired
    private SyncAppliedOpMapper appliedOps;

    @Test
    void allocatesConsecutiveBlocksPerUser() {
        UUID user = UUID.randomUUID();
        UUID other = UUID.randomUUID();

        assertThat(versions.current(user)).isNull();
        assertThat(versions.allocate(user, 1)).isEqualTo(1L);
        assertThat(versions.allocate(user, 3)).isEqualTo(4L);
        assertThat(versions.allocate(other, 2)).isEqualTo(2L);
        assertThat(versions.current(user)).isEqualTo(4L);
    }

    @Test
    void remembersAppliedOperationsPerUser() {
        UUID user = UUID.randomUUID();
        UUID op = UUID.randomUUID();

        assertThat(appliedOps.findServerVersion(user, op)).isNull();
        appliedOps.insert(user, op, 7L);

        assertThat(appliedOps.findServerVersion(user, op)).isEqualTo(7L);
        assertThat(appliedOps.findServerVersion(UUID.randomUUID(), op)).isNull();
        assertThatThrownBy(() -> appliedOps.insert(user, op, 8L)).isInstanceOf(DuplicateKeyException.class);
    }
}
