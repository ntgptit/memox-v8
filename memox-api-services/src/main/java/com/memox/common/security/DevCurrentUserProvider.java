package com.memox.common.security;

import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Every request is the one dev user until login exists (ADR-013). */
@Component
@RequiredArgsConstructor
public class DevCurrentUserProvider implements CurrentUserProvider {

    private final MemoxProperties properties;

    @Override
    public UUID currentUserId() {
        return properties.devUserId();
    }
}
