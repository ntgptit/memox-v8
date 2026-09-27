package com.memox.common.config;

import java.time.Clock;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * The application clock. Code that needs "now" injects this {@link Clock}, so time stays UTC (ADR-008) and tests can
 * fix it.
 */
@Configuration(proxyBeanMethods = false)
public class TimeConfig {

	@Bean
	public Clock clock() {
		return Clock.systemUTC();
	}

}
