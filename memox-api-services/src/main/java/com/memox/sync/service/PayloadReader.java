package com.memox.sync.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import jakarta.validation.Validator;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/** Reads a command payload or patch fields into a request DTO with the same Bean Validation as a REST body. */
@Component
@RequiredArgsConstructor
public class PayloadReader {

    private final ObjectMapper objectMapper;
    private final Validator validator;

    public <T> T read(JsonNode json, Class<T> type) {
        if (json == null || !json.isObject()) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        T value;
        try {
            value = objectMapper.treeToValue(json, type);
        } catch (JsonProcessingException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        if (value == null || !validator.validate(value).isEmpty()) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        return value;
    }

    /** A required UUID field of a payload, such as the {@code deckId} a REST route takes from its path. */
    public UUID id(JsonNode json, String field) {
        JsonNode node = json == null ? null : json.get(field);
        if (node == null || !node.isTextual()) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        try {
            return UUID.fromString(node.asText());
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
    }
}
