import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The MemoX colours no Material 3 role carries (DESIGN.md "Semantic"), in
/// Material 3's pairing: a role, the content on it (`on…`), its container and
/// the content on that. Danger is the scheme's `error*`; there is no ink
/// palette (spec 2026-10-04-sp3a D18). One instance per theme; read through
/// `context.semanticColors`.
@immutable
class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.mastery,
    required this.onMastery,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.streak,
    required this.ghostBorder,
  });

  factory MxSemanticColors.from(DesignPalette palette) => MxSemanticColors(
    mastery: palette.mastery,
    onMastery: palette.onMastery,
    success: palette.success,
    onSuccess: palette.onSuccess,
    successContainer: palette.successContainer,
    onSuccessContainer: palette.onSuccessContainer,
    warning: palette.warning,
    onWarning: palette.onWarning,
    warningContainer: palette.warningContainer,
    onWarningContainer: palette.onWarningContainer,
    statusNew: palette.statusNew,
    statusLearning: palette.statusLearning,
    statusReviewing: palette.statusReviewing,
    statusMastered: palette.statusMastered,
    streak: palette.streak,
    ghostBorder: palette.ghostBorder,
  );

  static final MxSemanticColors light = MxSemanticColors.from(
    DesignPalette.light,
  );
  static final MxSemanticColors dark = MxSemanticColors.from(
    DesignPalette.dark,
  );

  /// Learning progress: a fill only, with [onMastery] on it.
  final Color mastery;
  final Color onMastery;

  /// A right answer or a finished state, as text or icon on a surface or as a fill with [onSuccess].
  final Color success;
  final Color onSuccess;

  /// The soft success ground, with [onSuccessContainer] on it.
  final Color successContainer;
  final Color onSuccessContainer;

  /// A refusal or a limit where nothing was lost, as text or icon on a surface or as a fill with [onWarning].
  final Color warning;
  final Color onWarning;

  /// The soft warning ground, with [onWarningContainer] on it.
  final Color warningContainer;
  final Color onWarningContainer;

  /// Each status is its own label, dot and fill colour.
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;

  /// The Progress flame: a fill only.
  final Color streak;

  /// The everyday 1 dp hairline: primary at 14 % (light) or 16 % (dark).
  final Color ghostBorder;

  @override
  MxSemanticColors copyWith({
    Color? mastery,
    Color? onMastery,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? streak,
    Color? ghostBorder,
  }) => MxSemanticColors(
    mastery: mastery ?? this.mastery,
    onMastery: onMastery ?? this.onMastery,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    statusNew: statusNew ?? this.statusNew,
    statusLearning: statusLearning ?? this.statusLearning,
    statusReviewing: statusReviewing ?? this.statusReviewing,
    statusMastered: statusMastered ?? this.statusMastered,
    streak: streak ?? this.streak,
    ghostBorder: ghostBorder ?? this.ghostBorder,
  );

  @override
  MxSemanticColors lerp(MxSemanticColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxSemanticColors(
      mastery: mix(mastery, other.mastery),
      onMastery: mix(onMastery, other.onMastery),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      statusNew: mix(statusNew, other.statusNew),
      statusLearning: mix(statusLearning, other.statusLearning),
      statusReviewing: mix(statusReviewing, other.statusReviewing),
      statusMastered: mix(statusMastered, other.statusMastered),
      streak: mix(streak, other.streak),
      ghostBorder: mix(ghostBorder, other.ghostBorder),
    );
  }
}
