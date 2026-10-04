import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// A chip's ground, content and edge for its state (DESIGN.md, Inputs):
/// a filter chip rests on `surface-container-lowest` with an
/// `outline-variant` edge and fills `primary` when selected; a chip trigger
/// is a ghost with an `outline-variant` edge, tinted `primary-container`
/// while what it opens is in force.
({Color? fill, Color content, BorderSide edge}) mxChipColors({
  required ColorScheme colors,
  required bool isSelected,
  required bool isGhost,
}) {
  if (isSelected && !isGhost) {
    return (
      fill: colors.primary,
      content: colors.onPrimary,
      edge: BorderSide.none,
    );
  }
  if (isSelected) {
    return (
      fill: colors.primaryContainer,
      content: colors.onPrimaryContainer,
      edge: BorderSide.none,
    );
  }
  return (
    fill: isGhost ? null : colors.surfaceContainerLowest,
    content: colors.onSurface,
    edge: BorderSide(color: colors.outlineVariant, width: AppStroke.hairline),
  );
}
