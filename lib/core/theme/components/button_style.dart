import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// What a button means (DESIGN.md, Components › Actions).
enum MxButtonTone {
  /// The one action of a decision: `primary` under `on-primary`.
  primary,

  /// A neutral alternative: `surface-container` under `on-surface`.
  secondary,

  /// A lesser alternative with an `outline` edge and an
  /// `on-primary-container` label.
  outline,

  /// The quiet action beside a decision's fill: no fill, no edge.
  text,

  /// An action that destroys: `error` under `on-error`.
  destructive,

  /// A destructive action that is not the decision: `error-container`.
  dangerSoft,

  /// A refusal or limit where nothing is lost: `warning` under `on-warning`.
  warning,

  /// The action on an inverse surface (a snackbar's Undo): no fill, an
  /// `inverse-primary` label.
  inverse,
}

/// A button's geometry; the caller never passes a size or a padding.
enum MxButtonSize {
  regular(AppSize.buttonRegular, AppSpacing.gutter, AppRadius.md),
  small(AppSize.buttonSmall, AppSpacing.gutter, AppRadius.md),
  compact(AppSize.buttonCompact, AppSpacing.grouped, AppRadius.sm),
  chip(AppSize.buttonChip, AppSpacing.grouped, AppRadius.full),
  study(AppSize.buttonRegular, AppSize.buttonStudyPadding, AppRadius.full);

  const MxButtonSize(this.height, this.horizontalPadding, this.radius);

  /// The painted height; the hit area is never under 48.
  final double height;
  final double horizontalPadding;
  final double radius;

  /// Regular labels wrap to two lines; every other size keeps one.
  int get maxLines => this == MxButtonSize.regular ? 2 : 1;

  /// Compact and chip buttons use the small label (DESIGN.md, Typography).
  bool get usesSmallLabel =>
      this == MxButtonSize.compact || this == MxButtonSize.chip;
}

/// The single source of every button's look: `AppTheme` fills the filled,
/// outlined and text button slots from it, and `MxButton` passes it, so a
/// raw button and an `MxButton` of the same tone cannot differ.
ButtonStyle mxButtonStyle({
  required ColorScheme colors,
  required AppSemanticColors semantic,
  required TextTheme texts,
  required MxButtonTone tone,
  MxButtonSize size = MxButtonSize.regular,
}) {
  final (Color fill, Color content) = switch (tone) {
    MxButtonTone.primary => (colors.primary, colors.onPrimary),
    MxButtonTone.secondary => (colors.surfaceContainer, colors.onSurface),
    MxButtonTone.outline => (Colors.transparent, colors.onPrimaryContainer),
    MxButtonTone.text => (Colors.transparent, colors.onPrimaryContainer),
    MxButtonTone.destructive => (colors.error, colors.onError),
    MxButtonTone.dangerSoft => (colors.errorContainer, colors.onErrorContainer),
    MxButtonTone.warning => (semantic.warning, semantic.onWarning),
    MxButtonTone.inverse => (Colors.transparent, colors.inversePrimary),
  };
  final BorderSide edge = tone == MxButtonTone.outline
      ? BorderSide(color: colors.outline, width: AppStroke.hairline)
      : BorderSide.none;
  final OutlinedBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(size.radius),
    side: edge,
  );
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(fill),
    foregroundColor: WidgetStatePropertyAll<Color>(content),
    iconColor: WidgetStatePropertyAll<Color>(content),
    overlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.pressed)
          ? content.withValues(alpha: AppOpacity.pressed)
          : Colors.transparent,
    ),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    elevation: const WidgetStatePropertyAll<double>(0),
    textStyle: WidgetStatePropertyAll<TextStyle?>(
      size.usesSmallLabel ? texts.labelSmall : texts.labelLarge,
    ),
    iconSize: const WidgetStatePropertyAll<double>(AppIconSize.small),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: size == MxButtonSize.regular ? AppSpacing.micro : 0,
      ),
    ),
    minimumSize: WidgetStatePropertyAll<Size>(Size(0, size.height)),
    shape: WidgetStatePropertyAll<OutlinedBorder>(shape),
    side: WidgetStatePropertyAll<BorderSide>(edge),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    alignment: Alignment.center,
  );
}

/// Whether [label] fits one line of a regular button [width] wide at the
/// reader's text scale; footers that share a row stack when it does not.
bool mxCanButtonLabelFit({
  required TextTheme texts,
  required String label,
  required double width,
  required TextScaler textScaler,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: label, style: texts.labelLarge),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final bool canFit =
      painter.width <= width - 2 * MxButtonSize.regular.horizontalPadding;
  painter.dispose();
  return canFit;
}
