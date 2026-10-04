import 'package:flutter/material.dart';

/// A stepper's value: the title role with tabular figures, so the buttons
/// stay put as the digits change.
TextStyle? mxStepperValueStyle(TextTheme texts) => texts.titleLarge?.copyWith(
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
);

/// The ground a chosen segment is raised to inside a muted tray: white on the
/// light tray, the highest container on the dark one (in dark the low
/// containers are darker, so the lowest would read as sunken).
Color mxRaisedInTray(ColorScheme colors) => colors.brightness == Brightness.dark
    ? colors.surfaceContainerHighest
    : colors.surfaceContainerLowest;
