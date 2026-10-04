import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';

/// What an icon-only action means (flutter-theme-design §19).
enum MxIconButtonTone {
  /// A quiet tool: `on-surface-variant`.
  standard,

  /// An indigo action: `primary`.
  accent,

  /// An action that destroys: `error`.
  destructive,
}

/// A 20dp glyph in a 36dp round ink box with a 48dp hit (DESIGN.md, Actions);
/// `AppTheme`'s icon button slot and `MxIconButton` share it.
ButtonStyle mxIconButtonStyle({
  required ColorScheme colors,
  MxIconButtonTone tone = MxIconButtonTone.standard,
}) {
  final Color content = switch (tone) {
    MxIconButtonTone.standard => colors.onSurfaceVariant,
    MxIconButtonTone.accent => colors.primary,
    MxIconButtonTone.destructive => colors.error,
  };
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll<Color>(content),
    iconColor: WidgetStatePropertyAll<Color>(content),
    backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    overlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.pressed)
          ? content.withValues(alpha: AppOpacity.pressed)
          : Colors.transparent,
    ),
    iconSize: const WidgetStatePropertyAll<double>(AppIconSize.medium),
    fixedSize: const WidgetStatePropertyAll<Size>(
      Size.square(AppSize.iconButton),
    ),
    minimumSize: const WidgetStatePropertyAll<Size>(
      Size.square(AppSize.iconButton),
    ),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
    shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
  );
}
