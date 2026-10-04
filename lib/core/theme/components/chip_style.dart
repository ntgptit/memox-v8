import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// A chip's ground, content and edge for its state (DESIGN.md, Inputs):
/// a filter chip rests on `surface-container-lowest` with a 3:1 `outline`
/// edge; a chip trigger is a ghost with the same edge. Selected or in force,
/// both turn to the tonal `primary-container` (The Selection Ladder Rule),
/// never the CTA `primary`; the selected filter chip adds a leading check.
({Color? fill, Color content, BorderSide edge}) mxChipColors({
  required ColorScheme colors,
  required bool isSelected,
  required bool isGhost,
}) {
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
    edge: BorderSide(color: colors.outline, width: AppStroke.hairline),
  );
}
