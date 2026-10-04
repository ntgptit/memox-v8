import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// What a card means (DESIGN.md, Containers › MxCard); one tone at a time.
enum MxCardTone {
  /// The everyday card: `surface-container-lowest`, the whisper shadow in
  /// light and the `outline-variant` hairline in dark.
  raised,

  /// The screen's lead card: the Indigo Wash, `primary-container`.
  hero,

  /// A limit where nothing was lost: `warning-container`.
  warning,

  /// A finished, fine state: `success-container`.
  success,

  /// A failure the card reports: `error-container`.
  danger,

  /// A face set into the page: `surface-container-low`, flat.
  recessed,
}

/// A card's ground, the colour its content reads in, its edge and shadow.
({Color ground, Color content, BorderSide edge, List<BoxShadow> shadows})
mxCardSurface(
  ColorScheme colors,
  AppSemanticColors semantic, {
  required MxCardTone tone,
  required bool isSelected,
}) {
  final bool isDark = colors.brightness == Brightness.dark;
  final (Color ground, Color content) = switch (tone) {
    MxCardTone.raised => (colors.surfaceContainerLowest, colors.onSurface),
    MxCardTone.hero => (colors.primaryContainer, colors.onPrimaryContainer),
    MxCardTone.warning => (
      semantic.warningContainer,
      semantic.onWarningContainer,
    ),
    MxCardTone.success => (
      semantic.successContainer,
      semantic.onSuccessContainer,
    ),
    MxCardTone.danger => (colors.errorContainer, colors.onErrorContainer),
    MxCardTone.recessed => (colors.surfaceContainerLow, colors.onSurface),
  };
  final bool isRaised = tone == MxCardTone.raised;
  final AppShadow? whisper = isDark
      ? AppShadows.whisperDark
      : AppShadows.whisperLight;
  final List<BoxShadow> shadows = isRaised
      ? [?whisper?.on(colors.shadow)]
      : const <BoxShadow>[];
  BorderSide edge = BorderSide.none;
  if (isRaised && isDark) {
    edge = BorderSide(color: colors.outlineVariant, width: AppStroke.hairline);
  }
  // Chosen is the Indigo Accent edge on the card's own ground (The
  // Selection Ladder Rule), never a `primary` edge.
  if (isSelected) {
    edge = BorderSide(
      color: colors.onPrimaryContainer,
      width: AppStroke.control,
    );
  }
  return (ground: ground, content: content, edge: edge, shadows: shadows);
}

/// The overline above a section's card: the Section Label role in
/// `on-surface-variant` (the widget upper-cases the app's own words).
TextStyle? mxSectionLabelStyle(TextTheme texts, ColorScheme colors) =>
    texts.labelMedium?.apply(color: colors.onSurfaceVariant);
