import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// A ground and the content that reads on it.
typedef ToneColors = ({Color ground, Color content});

/// What a badge says (DESIGN.md, Feedback and Status › MxBadge). Each tone
/// is its role's container under its `on-…-container`.
enum MxBadgeTone { primary, mastery, success, warning, danger, neutral }

ToneColors mxBadgeColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxBadgeTone tone,
) => switch (tone) {
  MxBadgeTone.primary => (
    ground: colors.primaryContainer,
    content: colors.onPrimaryContainer,
  ),
  MxBadgeTone.mastery => (
    ground: semantic.statusMasteredContainer,
    content: semantic.onStatusMasteredContainer,
  ),
  MxBadgeTone.success => (
    ground: semantic.successContainer,
    content: semantic.onSuccessContainer,
  ),
  MxBadgeTone.warning => (
    ground: semantic.warningContainer,
    content: semantic.onWarningContainer,
  ),
  MxBadgeTone.danger => (
    ground: colors.errorContainer,
    content: colors.onErrorContainer,
  ),
  MxBadgeTone.neutral => (
    ground: colors.surfaceContainerHigh,
    content: colors.onSurfaceVariant,
  ),
};

/// A card's learning status (DESIGN.md, Colors › Semantic › Status).
enum MxStatusBadgeKind { newCard, learning, reviewing, mastered }

/// A status's mark (its dot or bar) and its badge ground and label colour.
({Color mark, Color ground, Color content}) mxStatusColors(
  AppSemanticColors semantic,
  MxStatusBadgeKind kind,
) => switch (kind) {
  MxStatusBadgeKind.newCard => (
    mark: semantic.statusNew,
    ground: semantic.statusNewContainer,
    content: semantic.onStatusNewContainer,
  ),
  MxStatusBadgeKind.learning => (
    mark: semantic.statusLearning,
    ground: semantic.statusLearningContainer,
    content: semantic.onStatusLearningContainer,
  ),
  MxStatusBadgeKind.reviewing => (
    mark: semantic.statusReviewing,
    ground: semantic.statusReviewingContainer,
    content: semantic.onStatusReviewingContainer,
  ),
  MxStatusBadgeKind.mastered => (
    mark: semantic.statusMastered,
    ground: semantic.statusMasteredContainer,
    content: semantic.onStatusMasteredContainer,
  ),
};

/// A tag chip: read-only metadata on `surface-container-high`.
ToneColors mxTagColors(ColorScheme colors) =>
    (ground: colors.surfaceContainerHigh, content: colors.onSurfaceVariant);

/// What an icon tile says (DESIGN.md, Data Display › MxIconTile).
enum MxIconTileTone {
  /// The neutral tile beside a row: `surface-container-high`.
  tinted,

  /// The Indigo Wash: `primary-container`.
  primary,

  /// A solid warning square (a lock that refuses): `warning` under
  /// `on-warning`.
  warning,

  /// `success-container`.
  success,

  /// The soft warning ground: `warning-container`.
  caution,

  /// `error-container`.
  danger,
}

ToneColors mxIconTileColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxIconTileTone tone,
) => switch (tone) {
  MxIconTileTone.tinted => (
    ground: colors.surfaceContainerHigh,
    content: colors.onSurfaceVariant,
  ),
  MxIconTileTone.primary => (
    ground: colors.primaryContainer,
    content: colors.onPrimaryContainer,
  ),
  MxIconTileTone.warning => (
    ground: semantic.warning,
    content: semantic.onWarning,
  ),
  MxIconTileTone.success => (
    ground: semantic.successContainer,
    content: semantic.onSuccessContainer,
  ),
  MxIconTileTone.caution => (
    ground: semantic.warningContainer,
    content: semantic.onWarningContainer,
  ),
  MxIconTileTone.danger => (
    ground: colors.errorContainer,
    content: colors.onErrorContainer,
  ),
};

/// A progress fill's colour (DESIGN.md, MxLinearProgress). The generic bar
/// is `secondary`; a component that means a state (mastery, success, a
/// warning) passes that state's tone. Never `primary`: #4151C6 holds only
/// 2.35:1 on the dark track (The Contrast Floor Rule).
enum MxLinearProgressTone {
  secondary,
  newCard,
  learning,
  reviewing,
  mastered,
  success,
  warning,
  danger,
}

/// The fill and the track a progress bar is drawn in.
({Color fill, Color track}) mxProgressColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxLinearProgressTone tone,
) => (
  fill: switch (tone) {
    MxLinearProgressTone.secondary => colors.secondary,
    MxLinearProgressTone.newCard => semantic.statusNew,
    MxLinearProgressTone.learning => semantic.statusLearning,
    MxLinearProgressTone.reviewing => semantic.statusReviewing,
    MxLinearProgressTone.mastered => semantic.statusMastered,
    MxLinearProgressTone.success => semantic.success,
    MxLinearProgressTone.warning => semantic.warning,
    MxLinearProgressTone.danger => colors.error,
  },
  track: colors.surfaceContainerLow,
);
