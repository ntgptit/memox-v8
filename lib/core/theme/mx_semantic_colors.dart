import 'package:flutter/material.dart';

/// MemoX product colours that Material has no honest role for
/// (02-theme-binding MEMOX_SEMANTIC_COLOR, BIND_NOW only).
///
/// Holds exactly the semantics a V3 component paints. Aliases resolve to
/// their ColorScheme role, derived colours live in MxDerivedColors, and the
/// PRESERVE_ONLY semantics (success, mastery-fixed…) get no field until a
/// component consumes them; streak is bound since the flag mark (library
/// alignment phase E). Green means mastery, never tertiary.
@immutable
final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.mastery,
    required this.warning,
    required this.onWarning,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.errorFill,
    required this.onErrorFill,
    required this.streak,
    required this.onStreak,
  });

  static const MxSemanticColors light = MxSemanticColors(
    mastery: Color(0xFF1F8A5B),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF3A2A00),
    statusNew: Color(0xFF8C95B8),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFF5265F5),
    statusMastered: Color(0xFF1F8A5B),
    errorFill: Color(0xFFDC2D4E),
    onErrorFill: Color(0xFFFFFFFF),
    streak: Color(0xFFF97316),
    onStreak: Color(0xFFFFFFFF),
  );

  static const MxSemanticColors dark = MxSemanticColors(
    mastery: Color(0xFF6FE0BD),
    warning: Color(0xFFFFC658),
    onWarning: Color(0xFF2A1E00),
    statusNew: Color(0xFF6B75A3),
    statusLearning: Color(0xFFFFC658),
    statusReviewing: Color(0xFF8B9AFF),
    statusMastered: Color(0xFF6FE0BD),
    errorFill: Color(0xFFB0485C),
    onErrorFill: Color(0xFFFFFFFF),
    streak: Color(0xFFFFAE6E),
    onStreak: Color(0xFFFFFFFF),
  );

  /// Mastery and progress green.
  final Color mastery;
  final Color warning;

  /// Ink on a warning fill.
  final Color onWarning;
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;

  /// Solid destructive button fill.
  final Color errorFill;

  /// Label on [errorFill].
  final Color onErrorFill;

  /// The streak accent (a flagged card, E-O2); as a glyph it reads in
  /// MxDerivedColors.streakInk.
  final Color streak;

  /// Ink on a [streak] fill.
  final Color onStreak;

  @override
  MxSemanticColors copyWith({
    Color? mastery,
    Color? warning,
    Color? onWarning,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? errorFill,
    Color? onErrorFill,
    Color? streak,
    Color? onStreak,
  }) => MxSemanticColors(
    mastery: mastery ?? this.mastery,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    statusNew: statusNew ?? this.statusNew,
    statusLearning: statusLearning ?? this.statusLearning,
    statusReviewing: statusReviewing ?? this.statusReviewing,
    statusMastered: statusMastered ?? this.statusMastered,
    errorFill: errorFill ?? this.errorFill,
    onErrorFill: onErrorFill ?? this.onErrorFill,
    streak: streak ?? this.streak,
    onStreak: onStreak ?? this.onStreak,
  );

  @override
  MxSemanticColors lerp(
    covariant ThemeExtension<MxSemanticColors>? other,
    double t,
  ) {
    if (other is! MxSemanticColors) return this;

    return MxSemanticColors(
      mastery: Color.lerp(mastery, other.mastery, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      statusNew: Color.lerp(statusNew, other.statusNew, t)!,
      statusLearning: Color.lerp(statusLearning, other.statusLearning, t)!,
      statusReviewing: Color.lerp(statusReviewing, other.statusReviewing, t)!,
      statusMastered: Color.lerp(statusMastered, other.statusMastered, t)!,
      errorFill: Color.lerp(errorFill, other.errorFill, t)!,
      onErrorFill: Color.lerp(onErrorFill, other.onErrorFill, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      onStreak: Color.lerp(onStreak, other.onStreak, t)!,
    );
  }
}
