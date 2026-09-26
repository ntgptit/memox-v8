import 'package:flutter/material.dart';

/// Tokyo Pure Light and Tokyo Nebula, the two V3 themes (01-foundations.md).
///
/// Each scheme is seeded from [seed] and then given every role V3 defines. The
/// roles V3 leaves open (the *Fixed family) keep the seed-generated value:
/// that is the handoff's REPO_PRESERVED disposition, and no V3 colour is
/// invented for them. Both themes use the same seed so the Fixed family, which
/// M3 defines as theme-independent, stays the same in both.
abstract final class AppColorSchemes {
  /// The V3 light primary, the brand indigo.
  static const Color seed = Color(0xFF5265F5);

  // The one intentionally invariant pair (02-theme-binding.md).
  static const Color _inverseSurface = Color(0xFF34395D);
  static const Color _onInverseSurface = Color(0xFFE8EAFC);

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed)
      .copyWith(
        primary: seed,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFE0E5FE),
        onPrimaryContainer: const Color(0xFF1A2580),
        secondary: const Color(0xFF6E7CD9),
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFE3E6F7),
        onSecondaryContainer: const Color(0xFF262E6E),
        tertiary: const Color(0xFF8B6FF5),
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: const Color(0xFFEBE3FE),
        onTertiaryContainer: const Color(0xFF33177E),
        error: const Color(0xFFDC2D4E),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFFBDDE3),
        onErrorContainer: const Color(0xFF7A0A23),
        surfaceDim: const Color(0xFFDAE0EF),
        surface: const Color(0xFFF7F9FE),
        surfaceBright: const Color(0xFFFFFFFF),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFF1F4FB),
        surfaceContainer: const Color(0xFFE9EDF7),
        surfaceContainerHigh: const Color(0xFFE2E7F3),
        surfaceContainerHighest: const Color(0xFFDAE0EF),
        onSurface: const Color(0xFF0F1638),
        onSurfaceVariant: const Color(0xFF4A5278),
        outline: const Color(0xFF7C85AB),
        outlineVariant: const Color(0xFFC5CBE3),
        inverseSurface: _inverseSurface,
        onInverseSurface: _onInverseSurface,
        inversePrimary: const Color(0xFF8B9AFF),
        scrim: const Color(0xFF0A0E27),
        shadow: const Color(0xFF0F1638),
      );

  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        // The brand indigo in both themes (spec 2026-09-27 D1; kit: #8B9AFF).
        // Primary text and icons read in MxDerivedColors.primaryInk instead.
        primary: seed,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFF2D346A),
        onPrimaryContainer: const Color(0xFFD9DFFF),
        secondary: const Color(0xFF9DA8E8),
        onSecondary: const Color(0xFF1A2150),
        secondaryContainer: const Color(0xFF343C78),
        onSecondaryContainer: const Color(0xFFDDE2FB),
        tertiary: const Color(0xFFB5A0FF),
        onTertiary: const Color(0xFF240B63),
        tertiaryContainer: const Color(0xFF443078),
        onTertiaryContainer: const Color(0xFFE6DCFF),
        error: const Color(0xFFFF8FA3),
        onError: const Color(0xFF52061B),
        errorContainer: const Color(0xFF7A2036),
        onErrorContainer: const Color(0xFFFFD9DF),
        surfaceDim: const Color(0xFF060925),
        surface: const Color(0xFF0A0E27),
        surfaceBright: const Color(0xFF232B5A),
        surfaceContainerLowest: const Color(0xFF131A3A),
        surfaceContainerLow: const Color(0xFF1B2249),
        surfaceContainer: const Color(0xFF232B5A),
        surfaceContainerHigh: const Color(0xFF2C356E),
        surfaceContainerHighest: const Color(0xFF353D7E),
        onSurface: const Color(0xFFE4E8FA),
        onSurfaceVariant: const Color(0xFFA4ACD0),
        outline: const Color(0xFF5A6BAE),
        outlineVariant: const Color(0xFF2A3267),
        inverseSurface: _inverseSurface,
        onInverseSurface: _onInverseSurface,
        inversePrimary: seed,
        scrim: const Color(0xFF000000),
        shadow: const Color(0xFF000000),
      );
}
