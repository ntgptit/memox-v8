import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// How much a top bar's title says (DESIGN.md, MxAppBar): `screen` names a
/// destination, `content` sits over a pushed task or form whose content
/// leads.
enum MxAppBarDensity { screen, content }

/// Screen titles track tighter than the Title role (DESIGN.md, Typography ›
/// Character): a component override, not a new role.
const double _screenTitleTracking = -0.5;

/// Row titles track slightly tighter than Body Large (component override).
const double _rowTitleTracking = -0.1;

/// The top bar's ground: flat `surface` over a page that has not scrolled, so
/// the bar merges with it; one tonal step (`surface-container`, Material 3's
/// scrolled-under container) once content passes under it. Never a shadow or
/// a tint.
Color mxAppBarGround(ColorScheme colors, {required bool isScrolledUnder}) =>
    isScrolledUnder ? colors.surfaceContainer : colors.surface;

/// The bar's title in `on-surface`: the Title role for a destination, Body
/// Large over content.
TextStyle? mxAppBarTitleStyle(
  TextTheme texts,
  ColorScheme colors,
  MxAppBarDensity density,
) {
  if (density == MxAppBarDensity.content) {
    return texts.titleMedium?.apply(color: colors.onSurface);
  }
  return texts.titleLarge?.copyWith(
    color: colors.onSurface,
    letterSpacing: _screenTitleTracking,
  );
}

/// A list row's title: Body Large with the row tracking.
TextStyle? mxRowTitleStyle(TextTheme texts, ColorScheme colors) => texts
    .bodyLarge
    ?.copyWith(color: colors.onSurface, letterSpacing: _rowTitleTracking);

/// A breadcrumb place in Body: the current place in `on-surface`, the others
/// in `on-surface-variant`. A place one can go to is also underlined, so it
/// is told by more than colour.
TextStyle? mxBreadcrumbStyle(
  TextTheme texts,
  ColorScheme colors, {
  required bool isCurrent,
  required bool canOpen,
}) {
  final Color tone = isCurrent ? colors.onSurface : colors.onSurfaceVariant;
  final TextStyle? style = texts.bodyMedium?.apply(color: tone);
  if (!canOpen) {
    return style;
  }
  return style?.copyWith(
    decoration: TextDecoration.underline,
    decorationColor: tone,
  );
}

/// The `AppBarTheme` slot, so a raw bar (the placeholder shell until SP3b)
/// already looks like `MxAppBar`.
AppBarThemeData mxAppBarTheme(ColorScheme colors, TextTheme texts) =>
    AppBarThemeData(
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => mxAppBarGround(
          colors,
          isScrolledUnder: states.contains(WidgetState.scrolledUnder),
        ),
      ),
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: AppSize.appBar,
      titleSpacing: AppSpacing.gutter,
      titleTextStyle: mxAppBarTitleStyle(texts, colors, MxAppBarDensity.screen),
      iconTheme: IconThemeData(color: colors.onSurfaceVariant),
      actionsIconTheme: IconThemeData(color: colors.onSurfaceVariant),
    );

/// A command row's glyph and label: `on-surface-variant` and `on-surface`,
/// both `error` when the command destroys.
({Color glyph, Color label}) mxCommandRowColors(
  ColorScheme colors, {
  required bool isDestructive,
}) {
  if (isDestructive) {
    return (glyph: colors.error, label: colors.error);
  }
  return (glyph: colors.onSurfaceVariant, label: colors.onSurface);
}
