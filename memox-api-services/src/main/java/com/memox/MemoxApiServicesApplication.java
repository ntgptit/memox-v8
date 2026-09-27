package com.memox;

import java.time.ZoneOffset;
import java.util.TimeZone;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class MemoxApiServicesApplication {

    public static void main(String[] args) {
        // ADR-008: every datetime is UTC, including any LocalDateTime that slips in.
        TimeZone.setDefault(TimeZone.getTimeZone(ZoneOffset.UTC));
        SpringApplication.run(MemoxApiServicesApplication.class, args);
    }
}
