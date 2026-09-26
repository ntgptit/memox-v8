import 'package:flutter/material.dart';

/// MemoX product colours that Material has no honest role for
/// (02-theme-binding MEMOX_SEMANTIC_COLOR, BIND_NOW only).
///
/// Holds exactly the nine semantics a V3 component paints. Aliases resolve to
/// their ColorScheme role, derived colours live in MxDerivedColors, and the
/// PRESERVE_ONLY semantics (streak, mastery-fixed…) get no field
/// until a component consumes them. Green means mastery, never tertiary.
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
    required this.success,
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
    success: Color(0xFF2BA88B),
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
    success: Color(0xFF6FE0BD),
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

  /// Success green: a finished session (FE-A6 spec D14). Its own role,
  /// never [mastery], though both read as progress.
  final Color success;

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
    Color? success,
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
    success: success ?? this.success,
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
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
