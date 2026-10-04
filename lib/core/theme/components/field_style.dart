import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The six text-field variants (DESIGN.md, Components › Inputs).
enum MxTextFieldVariant {
  /// One line on the muted fill, 52 tall.
  form,

  /// Grows from 48 with its text.
  detail,

  /// A card's meaning: body large, grows from 76, r20.
  meaning,

  /// A card's term: the headline role, r20.
  term,

  /// Six digits on one centred line, tabular and widely tracked.
  code,

  /// Bare: no fill and no edge, inside a study face.
  study,
}

/// The fill of a field: muted at rest, lighter while it has focus.
Color mxFieldFill(ColorScheme colors, Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? colors.surfaceContainerLowest
    : colors.surfaceContainerLow;

/// The field's edge, by state: `outline-variant`, `primary` on focus,
/// `error` while the field holds an error.
InputBorder mxFieldBorder({
  required Color color,
  required double radius,
  double width = AppStroke.hairline,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// The decoration `AppTheme` installs and every variant starts from.
InputDecorationThemeData mxInputDecorationTheme({
  required ColorScheme colors,
  required TextTheme texts,
}) {
  return InputDecorationThemeData(
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => mxFieldFill(colors, states),
    ),
    hintStyle: texts.bodyMedium?.apply(color: colors.onSurfaceVariant),
    contentPadding: mxFieldPadding(texts.bodyMedium, AppSize.field),
    enabledBorder: mxFieldBorder(
      color: colors.outlineVariant,
      radius: AppRadius.md,
    ),
    focusedBorder: mxFieldBorder(
      color: colors.primary,
      radius: AppRadius.md,
      width: AppStroke.control,
    ),
    errorBorder: mxFieldBorder(color: colors.error, radius: AppRadius.md),
    focusedErrorBorder: mxFieldBorder(
      color: colors.error,
      radius: AppRadius.md,
      width: AppStroke.control,
    ),
    disabledBorder: mxFieldBorder(
      color: colors.outlineVariant,
      radius: AppRadius.md,
    ),
    border: mxFieldBorder(color: colors.outlineVariant, radius: AppRadius.md),
  );
}

/// The padding that makes one line of [style] exactly [minHeight] tall, so
/// the fill and the edge are the height DESIGN.md names; more lines grow it.
EdgeInsets mxFieldPadding(TextStyle? style, double minHeight) {
  final double line = (style?.fontSize ?? 0) * (style?.height ?? 1);
  return EdgeInsets.symmetric(
    horizontal: AppSpacing.grouped,
    vertical: (minHeight - line) / 2,
  );
}

/// The text style a variant types in; component overrides of the nearest
/// role (DESIGN.md, "The Seven Roles Rule"), never new global styles.
TextStyle? mxFieldTextStyle(TextTheme texts, MxTextFieldVariant variant) {
  return switch (variant) {
    MxTextFieldVariant.meaning => texts.bodyLarge,
    MxTextFieldVariant.term => texts.headlineLarge,
    MxTextFieldVariant.code => texts.headlineLarge?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      letterSpacing: AppSpacing.control,
    ),
    _ => texts.bodyMedium,
  };
}

/// The radius of a variant: r20 for the card's two faces, r12 otherwise.
double mxFieldRadius(MxTextFieldVariant variant) => switch (variant) {
  MxTextFieldVariant.meaning || MxTextFieldVariant.term => AppRadius.xl,
  _ => AppRadius.md,
};

/// The minimum height a variant grows from.
double mxFieldMinHeight(MxTextFieldVariant variant) => switch (variant) {
  MxTextFieldVariant.detail => AppSize.fieldDetail,
  MxTextFieldVariant.meaning => AppSize.fieldMeaning,
  _ => AppSize.field,
};

/// The field label above a field: 600, 14, `on-surface` (DESIGN.md,
/// Typography › Field Label).
TextStyle? mxFieldLabelStyle(TextTheme texts) => texts.titleSmall;

/// The weight a "Required" mark keeps, smaller and in `primary`.
TextStyle? mxRequiredStyle(TextTheme texts, ColorScheme colors) =>
    AppTypography.withWeight(
      texts.bodySmall!.apply(color: colors.primary),
      FontWeight.w600,
    );
