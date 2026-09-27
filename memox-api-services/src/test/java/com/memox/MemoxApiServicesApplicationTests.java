package com.memox;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
class MemoxApiServicesApplicationTests {

	@Autowired
	private Clock clock;

	@Test
	void contextLoadsWithUtcClock() {
		assertThat(clock.getZone()).isEqualTo(ZoneOffset.UTC);
	}

}
