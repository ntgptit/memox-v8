import 'package:flutter/material.dart';

/// Indigo Day and Indigo Night, the two themes (spec 2026-10-10 §4).
///
/// Every role is a literal. Only the *Fixed family, which Material requires
/// and MemoX never reads, is still generated from [seed].
abstract final class AppColorSchemes {
  /// The brand indigo, primary in both themes.
  static const Color seed = Color(0xFF4255FF);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _danger = Color(0xFFB00020);
  static const Color _dangerSoft = Color(0xFFFFE8D8);
  static const Color _overlay = Color(0xFF010110);
  static const Color _shadow = Color(0xFF282E3E);
  static const Color _neutral = Color(0xFF586380);
  static const Color _purple = Color(0xFF9C63FF);
  static const Color _pink = Color(0xFFFAA6FF);
  static const Color _onLight = Color(0xFF282E3E);

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed)
      .copyWith(
        primary: seed,
        onPrimary: _white,
        primaryContainer: const Color(0xFFEDEFFF),
        onPrimaryContainer: seed,
        secondary: _neutral,
        onSecondary: _white,
        secondaryContainer: const Color(0xFFEDEFF4),
        onSecondaryContainer: const Color(0xFF2E3856),
        tertiary: _purple,
        onTertiary: _white,
        tertiaryContainer: _pink,
        onTertiaryContainer: _onLight,
        error: _danger,
        onError: _white,
        errorContainer: _dangerSoft,
        onErrorContainer: _danger,
        surfaceDim: const Color(0xFFEDEFF4),
        surface: _white,
        surfaceBright: _white,
        surfaceContainerLowest: _white,
        surfaceContainerLow: const Color(0xFFF6F7FB),
        surfaceContainer: const Color(0xFFF6F7FB),
        surfaceContainerHigh: const Color(0xFFEDEFF4),
        surfaceContainerHighest: const Color(0xFFD9DDE8),
        onSurface: _onLight,
        onSurfaceVariant: _neutral,
        outline: const Color(0xFF939BB4),
        outlineVariant: const Color(0xFFD9DDE8),
        // The toast is the inverse surface: dark in Day, light in Night.
        inverseSurface: const Color(0xFF1A1D28),
        onInverseSurface: const Color(0xFFF6F7FB),
        inversePrimary: const Color(0xFFF6F7FB),
        scrim: _overlay,
        shadow: _shadow,
      );

  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: seed,
        onPrimary: _white,
        primaryContainer: const Color(0xFF14125C),
        onPrimaryContainer: const Color(0xFFEDEFFF),
        secondary: _neutral,
        onSecondary: const Color(0xFFF6F7FB),
        secondaryContainer: const Color(0xFF2E3856),
        onSecondaryContainer: const Color(0xFFD9DDE8),
        tertiary: _purple,
        onTertiary: _white,
        tertiaryContainer: _pink,
        onTertiaryContainer: _onLight,
        error: const Color(0xFFFC3C60),
        onError: _white,
        errorContainer: _dangerSoft,
        onErrorContainer: _danger,
        surfaceDim: const Color(0xFF0A092D),
        surface: const Color(0xFF0A092D),
        surfaceBright: const Color(0xFF2E3856),
        surfaceContainerLowest: const Color(0xFF202040),
        surfaceContainerLow: const Color(0xFF2E3856),
        surfaceContainer: const Color(0xFF2E3856),
        surfaceContainerHigh: const Color(0xFF282E3E),
        surfaceContainerHighest: _neutral,
        onSurface: const Color(0xFFF6F7FB),
        onSurfaceVariant: const Color(0xFFD9DDE8),
        outline: _neutral,
        outlineVariant: _neutral,
        inverseSurface: const Color(0xFFEDEFF4),
        onInverseSurface: _onLight,
        inversePrimary: _neutral,
        scrim: _overlay,
        shadow: _shadow,
      );
}
