import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The ButtonStyle every text-labelled control shares: the Mx widgets and the
/// theme's Material buttons (spec §4.6). One fill and one ink for every
/// state; dimming a disabled control is the caller's 0.38 Opacity. The
/// pressed overlay is [pressedLayer] at AppOpacity.pressed: `shadow` for a
/// filled tone, so the label stays 4.5:1 while held, the ink otherwise
/// (spec 2026-10-08 §4.13 round 2). An Mx widget passes no [focusColor] and
/// draws its ring with MxFocusRing outside the control; a raw Material
/// button keeps the inside ring in [focusColor].
ButtonStyle appButtonStyle({
  required Color? fill,
  required Color ink,
  required BorderSide edge,
  required Color pressedLayer,
  Color? focusColor,
  required double height,
  required double radius,
  required double padding,
  required TextStyle label,
}) {
  final focusRing = focusColor == null
      ? null
      : BorderSide(color: focusColor, width: AppStroke.focus);
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(fill),
    foregroundColor: WidgetStatePropertyAll(ink),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? pressedLayer.withValues(alpha: AppOpacity.pressed)
          : null,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => focusRing != null && states.contains(WidgetState.focused)
          ? focusRing
          : edge,
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
