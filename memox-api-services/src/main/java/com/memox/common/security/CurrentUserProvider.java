package com.memox.common.security;

import java.util.UUID;

/**
 * The authenticated user. Services take the owner of every row from here, never from the request (ADR-013). The auth
 * spec replaces the dev implementation with a JWT-backed one.
 */
public interface CurrentUserProvider {

    UUID currentUserId();
}
