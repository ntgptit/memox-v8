package com.memox.common.type_handler;

import java.time.Instant;
import java.util.UUID;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * Test-only mapper that sends values through PostgreSQL and back.
 */
@Mapper
public interface BaseRoundTripMapper {

	UUID echoUuid(@Param("value") UUID value);

	String storedStatusCode(@Param("value") SampleStatus value);

	SampleStatus statusFromCode(@Param("code") String code);

	Instant echoInstant(@Param("value") Instant value);

	String instantAsUtcText(@Param("value") Instant value);

}
