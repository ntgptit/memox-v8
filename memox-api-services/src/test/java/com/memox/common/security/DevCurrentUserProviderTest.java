package com.memox.common.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class DevCurrentUserProviderTest {

    @Test
    void returnsTheConfiguredDevUser() {
        UUID devUser = UUID.fromString("00000000-0000-0000-0000-000000000042");

        assertThat(new DevCurrentUserProvider(new MemoxProperties(devUser)).currentUserId())
                .isEqualTo(devUser);
    }
}
