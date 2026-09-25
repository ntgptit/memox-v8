import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The ButtonStyle every text-labelled control shares: the Mx widgets and the
/// theme's Material buttons (spec §4.6). It has one fill and
/// one ink for every state; dimming a disabled control is the caller's 0.38
/// Opacity. It also sets the 0.12 pressed overlay, the focus ring on the
/// control's edge (ruling R5), and a painted [height] inside a 48 touch area.
ButtonStyle appButtonStyle({
  required Color? fill,
  required Color ink,
  required BorderSide edge,
  required Color focusColor,
  required double height,
  required double radius,
  required double padding,
  required TextStyle label,
}) {
  final focusRing = BorderSide(color: focusColor, width: AppStroke.focus);
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(fill),
    foregroundColor: WidgetStatePropertyAll(ink),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? ink.withValues(alpha: AppOpacity.pressed)
          : null,
    ),
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
