import 'package:flutter/material.dart';

/// Re-weights a style on the bundled variable font.
abstract final class AppTypography {
  /// Sets [weight] and moves the variable font's `wght` axis with it, so the
  /// style reports the weight it paints.
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(
      fontWeight: weight,
      fontVariations: <FontVariation>[
        FontVariation.weight(weight.value.toDouble()),
      ],
    );
  }
}
