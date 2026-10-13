import 'package:flutter/material.dart';

/// Shadow treatments (02-theme-binding DECORATION), named by semantic.
///
/// Nothing rests on a shadow ("Flashcard Color Tokens" §4.8): cards, the
/// search field and the navigation rise by their tone. Only what floats
/// above the content casts one. Shadows are neutral, built on the scheme's
/// `shadow` role and never tinted with the brand colour.
abstract final class AppShadows {
  /// The resting shadow (`shadow-raised`): none, in both themes.
  static List<BoxShadow> whisper(ColorScheme scheme) => const [];

  /// overlay-shadow: Dialog.
  static List<BoxShadow> overlay(ColorScheme scheme) =>
      switch (scheme.brightness) {
        Brightness.light => [_shadow(scheme, dy: 12, blur: 32, alpha: 0.10)],
        Brightness.dark => [_shadow(scheme, dy: 16, blur: 40, alpha: 0.42)],
      };

  /// chrome-shadow: BottomSheet and bottom chrome, cast upward.
  static List<BoxShadow> chrome(ColorScheme scheme) =>
      switch (scheme.brightness) {
        Brightness.light => [_shadow(scheme, dy: -2, blur: 12, alpha: 0.05)],
        Brightness.dark => [_shadow(scheme, dy: -2, blur: 14, alpha: 0.36)],
      };

  /// fab-shadow: the floating action.
  static List<BoxShadow> fab(ColorScheme scheme) => switch (scheme.brightness) {
    Brightness.light => [_shadow(scheme, dy: 8, blur: 24, alpha: 0.12)],
    Brightness.dark => [_shadow(scheme, dy: 10, blur: 28, alpha: 0.5)],
  };

  static BoxShadow _shadow(
    ColorScheme scheme, {
    required double dy,
    required double blur,
    required double alpha,
  }) => BoxShadow(
    color: scheme.shadow.withValues(alpha: alpha),
    offset: Offset(0, dy),
    blurRadius: blur,
  );
}
