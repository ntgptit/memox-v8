import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The MemoX colours that no Material 3 role carries (DESIGN.md "Semantic"),
/// one instance per theme (spec 2026-10-04-sp3a D10). Read through
/// `context.semanticColors`.
@immutable
class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.mastery,
    required this.onMastery,
    required this.success,
    required this.warning,
    required this.onWarning,
    required this.warningInk,
    required this.errorFill,
    required this.onErrorFill,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.streak,
  });

  factory MxSemanticColors.from(DesignPalette palette) => MxSemanticColors(
    mastery: palette.mastery,
    onMastery: palette.onMastery,
    success: palette.success,
    warning: palette.warning,
    onWarning: palette.onWarning,
    warningInk: palette.warningInk,
    errorFill: palette.errorFill,
    onErrorFill: palette.onErrorFill,
    statusNew: palette.statusNew,
    statusLearning: palette.statusLearning,
    statusReviewing: palette.statusReviewing,
    statusMastered: palette.statusMastered,
    streak: palette.streak,
  );

  static final MxSemanticColors light = MxSemanticColors.from(
    DesignPalette.light,
  );
  static final MxSemanticColors dark = MxSemanticColors.from(
    DesignPalette.dark,
  );

  final Color mastery;
  final Color onMastery;
  final Color success;
  final Color warning;
  final Color onWarning;
  final Color warningInk;
  final Color errorFill;
  final Color onErrorFill;
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;
  final Color streak;

  @override
  MxSemanticColors copyWith({
    Color? mastery,
    Color? onMastery,
    Color? success,
    Color? warning,
    Color? onWarning,
    Color? warningInk,
    Color? errorFill,
    Color? onErrorFill,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? streak,
  }) => MxSemanticColors(
    mastery: mastery ?? this.mastery,
    onMastery: onMastery ?? this.onMastery,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningInk: warningInk ?? this.warningInk,
    errorFill: errorFill ?? this.errorFill,
    onErrorFill: onErrorFill ?? this.onErrorFill,
    statusNew: statusNew ?? this.statusNew,
    statusLearning: statusLearning ?? this.statusLearning,
    statusReviewing: statusReviewing ?? this.statusReviewing,
    statusMastered: statusMastered ?? this.statusMastered,
    streak: streak ?? this.streak,
  );

  @override
  MxSemanticColors lerp(MxSemanticColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxSemanticColors(
      mastery: mix(mastery, other.mastery),
      onMastery: mix(onMastery, other.onMastery),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningInk: mix(warningInk, other.warningInk),
      errorFill: mix(errorFill, other.errorFill),
      onErrorFill: mix(onErrorFill, other.onErrorFill),
      statusNew: mix(statusNew, other.statusNew),
      statusLearning: mix(statusLearning, other.statusLearning),
      statusReviewing: mix(statusReviewing, other.statusReviewing),
      statusMastered: mix(statusMastered, other.statusMastered),
      streak: mix(streak, other.streak),
    );
  }
}
