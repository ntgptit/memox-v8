package com.memox.common.util;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.memox.common.exception.BusinessException;
import org.junit.jupiter.api.Test;

class TextRulesTest {

    @Test
    void storedStripsAndComposesToNfc() {
        assertThat(TextRules.stored("  Café ")).isEqualTo("Café");
        assertThat(TextRules.stored(null)).isNull();
    }

    @Test
    void requiredRejectsBlankAndTooLongAfterNormalizing() {
        assertThat(TextRules.required(" a ", 1)).isEqualTo("a");
        assertThat(TextRules.required("é", 1)).isEqualTo("é");
        assertThatThrownBy(() -> TextRules.required("   ", 5)).isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> TextRules.required("abc", 2)).isInstanceOf(BusinessException.class);
    }

    @Test
    void optionalTurnsBlankIntoNull() {
        assertThat(TextRules.optional("  ", 5)).isNull();
        assertThat(TextRules.optional(null, 5)).isNull();
        assertThat(TextRules.optional(" x ", 5)).isEqualTo("x");
        assertThatThrownBy(() -> TextRules.optional("abcdef", 5)).isInstanceOf(BusinessException.class);
    }
}
