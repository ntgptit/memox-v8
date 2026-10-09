import 'package:flutter/material.dart';

/// MemoX's Material 3 custom-colour sets (spec 2026-10-08 §4.3), one per
/// product semantic Material has no role for, each in M3's shape (`x`, `onX`,
/// `xContainer`, `onXContainer`) at tone 40 / 100 / 90 / 10 in light and
/// 80 / 20 / 30 / 90 in dark, plus the one brand foreground. Every value is
/// a literal measured in `test/core/theme/token_contrast_test.dart`; nothing
/// here is mixed at runtime. Green means mastery, never tertiary.
@immutable
final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.primaryForeground,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.mastery,
    required this.onMastery,
    required this.masteryContainer,
    required this.onMasteryContainer,
    required this.streak,
  });

  static const MxSemanticColors light = MxSemanticColors(
    primaryForeground: Color(0xFF384CDD),
    warning: Color(0xFF855300),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFDDB8),
    onWarningContainer: Color(0xFF2A1700),
    success: Color(0xFF006B57),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFF85F7D6),
    onSuccessContainer: Color(0xFF002019),
    mastery: Color(0xFF006D44),
    onMastery: Color(0xFFFFFFFF),
    masteryContainer: Color(0xFF93F7BE),
    onMasteryContainer: Color(0xFF002111),
    streak: Color(0xFF9D4300),
  );

  static const MxSemanticColors dark = MxSemanticColors(
    primaryForeground: Color(0xFFBCC2FF),
    warning: Color(0xFFFFB95F),
    onWarning: Color(0xFF472A00),
    warningContainer: Color(0xFF653E00),
    onWarningContainer: Color(0xFFFFDDB8),
    success: Color(0xFF67DABB),
    onSuccess: Color(0xFF00382C),
    successContainer: Color(0xFF005141),
    onSuccessContainer: Color(0xFF85F7D6),
    mastery: Color(0xFF77DAA4),
    onMastery: Color(0xFF003921),
    masteryContainer: Color(0xFF005232),
    onMasteryContainer: Color(0xFF93F7BE),
    streak: Color(0xFFFFB690),
  );

  /// The brand hue as text, icon, focus ring or selected mark on a neutral
  /// ground: indigo at tone 40 / 80, where `primary` (the brand fill, tone
  /// 49) is 4.39 / 4.11 on the page (spec §4.4, R8). Never a fill.
  final Color primaryForeground;

  /// A refusal or a limit where nothing was lost: the fill of a warning
  /// button and the glyph or text on a neutral ground.
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// A finished session, a kept outcome: its own role, never [mastery].
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Mastery and progress green.
  final Color mastery;
  final Color onMastery;
  final Color masteryContainer;
  final Color onMasteryContainer;

  /// The Progress flame (FE-A9 D7); its one consumed member.
  final Color streak;

  @override
  MxSemanticColors copyWith({
    Color? primaryForeground,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? mastery,
    Color? onMastery,
    Color? masteryContainer,
    Color? onMasteryContainer,
    Color? streak,
  }) => MxSemanticColors(
    primaryForeground: primaryForeground ?? this.primaryForeground,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    mastery: mastery ?? this.mastery,
    onMastery: onMastery ?? this.onMastery,
    masteryContainer: masteryContainer ?? this.masteryContainer,
    onMasteryContainer: onMasteryContainer ?? this.onMasteryContainer,
    streak: streak ?? this.streak,
  );

  @override
  MxSemanticColors lerp(
    covariant ThemeExtension<MxSemanticColors>? other,
    double t,
  ) {
    if (other is! MxSemanticColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxSemanticColors(
      primaryForeground: mix(primaryForeground, other.primaryForeground),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      mastery: mix(mastery, other.mastery),
      onMastery: mix(onMastery, other.onMastery),
      masteryContainer: mix(masteryContainer, other.masteryContainer),
      onMasteryContainer: mix(onMasteryContainer, other.onMasteryContainer),
      streak: mix(streak, other.streak),
    );
  }
}
