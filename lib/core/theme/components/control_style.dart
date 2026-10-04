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

/// A toggle's track, thumb and edge (DESIGN.md, The Selection Ladder Rule):
/// on is the Indigo Accent track with a `primary-container` thumb, off is a
/// neutral track with an `outline` thumb and edge. Never the CTA `primary`.
({Color track, Color thumb, Color? edge}) mxToggleColors(
  ColorScheme colors, {
  required bool isOn,
}) {
  if (isOn) {
    return (
      track: colors.onPrimaryContainer,
      thumb: colors.primaryContainer,
      edge: null,
    );
  }
  return (
    track: colors.surfaceContainerHighest,
    thumb: colors.outline,
    edge: colors.outline,
  );
}

/// A checkbox's box and check: checked is an Indigo Accent box with a
/// `primary-container` check; empty is an `outline` edge only.
({Color? box, Color check, Color? edge}) mxCheckboxColors(
  ColorScheme colors, {
  required bool isChecked,
}) {
  if (isChecked) {
    return (
      box: colors.onPrimaryContainer,
      check: colors.primaryContainer,
      edge: null,
    );
  }
  return (box: null, check: colors.primaryContainer, edge: colors.outline);
}
