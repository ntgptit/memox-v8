package com.memox.sync.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.function.BiConsumer;

/**
 * Runs one command {@code type} by reading its payload into the request DTO the REST route binds and calling the
 * same service method (API-A2 spec D2). Called inside the operation's transaction; reject by throwing
 * {@code BusinessException}.
 */
public record SyncCommandHandler(String type, BiConsumer<WriteContext, JsonNode> body) {}
