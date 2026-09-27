package com.memox.common.util;

import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import java.text.Normalizer;
import org.apache.commons.lang3.StringUtils;

/**
 * The stored form of user text (BE-C5): stripped, then NFC. Lengths count UTF-16 units, as Dart's
 * {@code String.length} does, so the server and the app accept the same strings.
 */
public final class TextRules {

    private TextRules() {}

    public static String stored(String value) {
        return value == null ? null : Normalizer.normalize(value.strip(), Normalizer.Form.NFC);
    }

    public static String required(String value, int maxLength) {
        String stored = stored(value);
        if (StringUtils.isEmpty(stored) || stored.length() > maxLength) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        return stored;
    }

    /** {@code null} when blank: an optional field has one empty form (schema.md, card). */
    public static String optional(String value, int maxLength) {
        String stored = stored(value);
        if (StringUtils.isEmpty(stored)) {
            return null;
        }
        if (stored.length() > maxLength) {
            throw new BusinessException(ErrorCode.VALIDATION_FAILED);
        }
        return stored;
    }
}
