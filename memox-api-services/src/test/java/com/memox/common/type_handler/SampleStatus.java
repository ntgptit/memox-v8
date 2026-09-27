package com.memox.common.type_handler;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Test-only code enum.
 */
@Getter
@RequiredArgsConstructor
public enum SampleStatus implements CodeEnum {
    ACTIVE("A"),

    INACTIVE("I");

    private final String code;
}
