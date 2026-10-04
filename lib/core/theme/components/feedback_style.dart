import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// How bad an inline banner's news is (DESIGN.md, Feedback and Status).
enum MxInlineBannerTone { warning, danger }

/// A banner's container ground, its edge and the `on-` role its glyph,
/// title and message read in.
({Color ground, Color edge, Color content}) mxBannerColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxInlineBannerTone tone,
) => switch (tone) {
  MxInlineBannerTone.warning => (
    ground: semantic.warningContainer,
    edge: semantic.warning,
    content: semantic.onWarningContainer,
  ),
  MxInlineBannerTone.danger => (
    ground: colors.errorContainer,
    edge: colors.error,
    content: colors.onErrorContainer,
  ),
};

/// A banner's bold title: Body at 700 in the banner's content colour.
TextStyle? mxBannerTitleStyle(TextTheme texts, Color content) {
  final TextStyle? body = texts.bodyMedium;
  if (body == null) {
    return null;
  }
  return AppTypography.withWeight(body.apply(color: content), FontWeight.w700);
}

/// What an empty state's tile says (DESIGN.md, MxEmptyState).
enum MxEmptyStateTone { primary, neutral, success, warning, danger }

ToneColors mxEmptyTileColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxEmptyStateTone tone,
) => switch (tone) {
  MxEmptyStateTone.primary => (
    ground: colors.primaryContainer,
    content: colors.onPrimaryContainer,
  ),
  MxEmptyStateTone.neutral => (
    ground: colors.surfaceContainerHigh,
    content: colors.onSurfaceVariant,
  ),
  MxEmptyStateTone.success => (
    ground: semantic.successContainer,
    content: semantic.onSuccessContainer,
  ),
  MxEmptyStateTone.warning => (
    ground: semantic.warningContainer,
    content: semantic.onWarningContainer,
  ),
  MxEmptyStateTone.danger => (
    ground: colors.errorContainer,
    content: colors.onErrorContainer,
  ),
};
