package com.memox.deck.dto.request;

/** Patch {@code deck/study_options} fields: JSON text of the root's options, or {@code null} for the defaults. */
public record StudyOptionsRequest(String studyConfig) {}
