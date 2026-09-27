package com.memox.common.security;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/** Application properties under {@code memox}. */
@Validated
@ConfigurationProperties(prefix = "memox")
public record MemoxProperties(@NotNull UUID devUserId) {}
