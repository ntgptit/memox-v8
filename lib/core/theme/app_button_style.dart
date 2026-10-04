import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The one place a `ButtonStyle` is built, with every state resolved
/// explicitly (guard `no_flat_style_from`). [ink] is the label and icon
/// colour, [fill] the ground (none for a text or outline button), [edge] the
/// outline (none unless the tone has one) and [focusRing] the 2 dp ring.
/// Pressed lays [ink] over the ground at `AppOpacity.pressed`; disabled draws
/// the whole control at `AppOpacity.disabled` (DESIGN.md, MxButton).
ButtonStyle appButtonStyle({
  required Color ink,
  required Color focusRing,
  required TextStyle label,
  Color? fill,
  Color? edge,
  double minHeight = AppSize.buttonRegular,
  double radius = AppRadius.md,
  double horizontalPadding = AppSpacing.gutter,
}) {
  Color faded(Color color) =>
      color.withValues(alpha: color.a * AppOpacity.disabled);
  final transparent = ink.withValues(alpha: 0);
  return ButtonStyle(
    textStyle: WidgetStatePropertyAll(label),
    minimumSize: WidgetStatePropertyAll(Size(AppSize.touchTarget, minHeight)),
    padding: WidgetStatePropertyAll(
      EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
    ),
    tapTargetSize: MaterialTapTargetSize.padded,
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? faded(ink) : ink,
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      final ground = fill ?? transparent;
      return states.contains(WidgetState.disabled) ? faded(ground) : ground;
    }),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? ink.withValues(alpha: AppOpacity.pressed)
          : transparent,
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: focusRing, width: AppStroke.focus);
      }
      if (edge == null) return BorderSide.none;
      final color = states.contains(WidgetState.disabled) ? faded(edge) : edge;
      return BorderSide(color: color, width: AppStroke.hairline);
    }),
  );
}
