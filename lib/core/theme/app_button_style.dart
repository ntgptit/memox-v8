import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The ButtonStyle every text-labelled control shares: the Mx widgets and the
/// theme's Material buttons (spec §4.6). It has one fill and
/// one foreground for every state; dimming a disabled control is the caller's 0.38
/// Opacity. It also sets the state layers (hover, focus, pressed), the 2dp
/// focus ring 2dp outside the control's edge ("Flashcard Color Tokens" §6),
/// and a painted [height] inside a 48 touch area.
ButtonStyle appButtonStyle({
  required Color? fill,
  required Color foreground,
  required BorderSide edge,
  required Color focusColor,
  required double height,
  required double radius,
  required double padding,
  required TextStyle label,
}) {
  final focusRing = appFocusRing(focusColor);
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(fill),
    foregroundColor: WidgetStatePropertyAll(foreground),
    overlayColor: appStateLayer(foreground),
    side: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focusRing : edge,
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: padding)),
    minimumSize: WidgetStatePropertyAll(Size(0, height)),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    textStyle: WidgetStatePropertyAll(label),
  );
}

/// The focus ring every control shares: [color] at the focus width, its
/// inner edge [AppStroke.focusOffset] outside the control's own edge.
BorderSide appFocusRing(Color color) => BorderSide(
  color: color,
  width: AppStroke.focus,
  strokeAlign: _focusRingAlign,
);

/// A stroke's alignment is in half its width from the edge: the ring's
/// centre sits the offset plus half the width outside.
const double _focusRingAlign = 1 + 2 * AppStroke.focusOffset / AppStroke.focus;

/// The Material 3 state layer in [foreground]: pressed, then focused, then
/// hovered.
WidgetStateProperty<Color?> appStateLayer(Color foreground) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return foreground.withValues(alpha: AppOpacity.pressed);
      }
      if (states.contains(WidgetState.focused)) {
        return foreground.withValues(alpha: AppOpacity.focus);
      }
      if (states.contains(WidgetState.hovered)) {
        return foreground.withValues(alpha: AppOpacity.hover);
      }
      return null;
    });
