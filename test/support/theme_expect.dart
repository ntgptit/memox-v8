import 'package:flutter/material.dart';

/// The accent colour of [scheme]: `primary` in light, `primaryFixedDim` in
/// dark, as `ThemeRules.accentColor` resolves it.
Color accentOf(ColorScheme scheme) => switch (scheme.brightness) {
  Brightness.light => scheme.primary,
  Brightness.dark => scheme.primaryFixedDim,
};
