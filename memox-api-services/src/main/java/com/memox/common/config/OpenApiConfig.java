package com.memox.common.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.ArraySchema;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.IntegerSchema;
import io.swagger.v3.oas.models.media.ObjectSchema;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;

/**
 * The OpenAPI document: API info, and the RFC 9457 error body that {@code GlobalExceptionHandler} returns, as every
 * operation's {@code default} response.
 */
@Configuration(proxyBeanMethods = false)
public class OpenApiConfig {

    public static final String PROBLEM_DETAIL_SCHEMA = "ProblemDetail";

    private static final String API_TITLE = "MemoX API";

    private static final String API_VERSION = "v1";

    private static final String DEFAULT_RESPONSE = "default";

    private static final String SCHEMA_REF_PREFIX = "#/components/schemas/";

    @Bean
    public OpenAPI memoxOpenApi() {
        return new OpenAPI().info(new Info().title(API_TITLE).version(API_VERSION));
    }

    @Bean
    public OpenApiCustomizer problemDetailResponses() {
        return openApi -> {
            if (openApi.getComponents() == null) {
                openApi.setComponents(new Components());
            }
            openApi.getComponents().addSchemas(PROBLEM_DETAIL_SCHEMA, problemDetailSchema());
            if (openApi.getPaths() == null) {
                return;
            }
            openApi.getPaths().values().stream()
                    .flatMap(pathItem -> pathItem.readOperations().stream())
                    .filter(operation -> operation.getResponses() != null)
                    .forEach(operation -> operation.getResponses().addApiResponse(DEFAULT_RESPONSE, problemResponse()));
        };
    }

    private static ApiResponse problemResponse() {
        Schema<?> reference = new Schema<>().$ref(SCHEMA_REF_PREFIX + PROBLEM_DETAIL_SCHEMA);
        io.swagger.v3.oas.models.media.MediaType problemJson =
                new io.swagger.v3.oas.models.media.MediaType().schema(reference);
        return new ApiResponse()
                .description("Error (RFC 9457)")
                .content(new Content().addMediaType(MediaType.APPLICATION_PROBLEM_JSON_VALUE, problemJson));
    }

    private static Schema<?> problemDetailSchema() {
        Schema<?> violation =
                new ObjectSchema().addProperty("field", new StringSchema()).addProperty("message", new StringSchema());
        return new ObjectSchema()
                .addProperty("type", new StringSchema().format("uri"))
                .addProperty("title", new StringSchema())
                .addProperty("status", new IntegerSchema())
                .addProperty("detail", new StringSchema())
                .addProperty("instance", new StringSchema().format("uri"))
                .addProperty("code", new StringSchema())
                .addProperty("requestId", new StringSchema())
                .addProperty("errors", new ArraySchema().items(violation));
    }
}
