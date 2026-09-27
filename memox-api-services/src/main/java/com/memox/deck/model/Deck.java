package com.memox.deck.model;

import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** A server {@code deck} row. */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Deck {

    private UUID id;
    private UUID userId;
    private String name;
    private UUID parentId;
    private UUID rootId;
    private Integer depth;
    private String contentType;
    private String schedulerType;
    private Integer schedulerVersion;
    private String schedulerConfig;
    private String studyConfig;
    private Integer generation;
    private Instant firstAnsweredAt;
    private String sourceTemplateId;
    private Integer sourceTemplateVersion;
    private UUID deleteBatchId;
    private Integer siblingPosition;
    private Instant createdAt;
    private Instant updatedAt;
    private Long serverVersion;
    private UUID lastDeviceId;
    private Instant deletedAt;
}
