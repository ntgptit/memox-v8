import 'package:flutter/material.dart';

/// Every MemoX colour Material has no role for (spec 2026-10-10 §5): status
/// and semantic fills, the text tokens, the edges and tracks, and the soft
/// grounds with their borders and text. Each is a literal per theme; nothing
/// here is derived. Soft grounds are light in both themes (spec D4). Green
/// means mastery or success, never decoration.
@immutable
final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.mastery,
    required this.onMastery,
    required this.success,
    required this.warning,
    required this.onWarning,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.errorFill,
    required this.onErrorFill,
    required this.streak,
    required this.primaryText,
    required this.masteryText,
    required this.learningText,
    required this.warningText,
    required this.focusRing,
    required this.border,
    required this.primaryTrack,
    required this.neutralTrack,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.successSoft,
    required this.successBorder,
    required this.onSuccessSoft,
    required this.learningSoft,
    required this.learningBorder,
    required this.onLearningSoft,
    required this.warningSoft,
    required this.warningBorder,
    required this.onWarningSoft,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.onDangerSoft,
    required this.neutralSoft,
    required this.onNeutralSoft,
    required this.onSoft,
  });

  static const MxSemanticColors light = MxSemanticColors(
    mastery: Color(0xFF18AE79),
    onMastery: Color(0xFFFFFFFF),
    success: Color(0xFF12815A),
    warning: Color(0xFFFFCD1F),
    onWarning: Color(0xFF282E3E),
    statusNew: Color(0xFF939BB4),
    statusLearning: Color(0xFFFF983A),
    statusReviewing: Color(0xFF4255FF),
    statusMastered: Color(0xFF18AE79),
    errorFill: Color(0xFFB00020),
    onErrorFill: Color(0xFFFFFFFF),
    streak: Color(0xFFF6406C),
    primaryText: Color(0xFF4255FF),
    masteryText: Color(0xFF12815A),
    learningText: Color(0xFFCC4E00),
    warningText: Color(0xFF997700),
    focusRing: Color(0xFFA8B1FF),
    border: Color(0xFFEDEFF4),
    primaryTrack: Color(0xFFDBDFFF),
    neutralTrack: Color(0xFF939BB4),
    primarySoft: Color(0xFFEDEFFF),
    onPrimarySoft: Color(0xFF4255FF),
    successSoft: Color(0xFFE6FCF4),
    successBorder: Color(0xFF98F1D1),
    onSuccessSoft: Color(0xFF12815A),
    learningSoft: Color(0xFFFFF6EF),
    learningBorder: Color(0xFFFFC38C),
    onLearningSoft: Color(0xFFCC4E00),
    warningSoft: Color(0xFFFFEDAB),
    warningBorder: Color(0xFFFFDC62),
    onWarningSoft: Color(0xFF997700),
    dangerSoft: Color(0xFFFFE8D8),
    dangerBorder: Color(0xFFFFC38C),
    onDangerSoft: Color(0xFFB00020),
    neutralSoft: Color(0xFFEDEFFF),
    onNeutralSoft: Color(0xFF2E3856),
    onSoft: Color(0xFF282E3E),
  );

  static const MxSemanticColors dark = MxSemanticColors(
    mastery: Color(0xFF18AE79),
    onMastery: Color(0xFFFFFFFF),
    success: Color(0xFF59E8B5),
    warning: Color(0xFFFFCD1F),
    onWarning: Color(0xFF282E3E),
    statusNew: Color(0xFF586380),
    statusLearning: Color(0xFFFF983A),
    statusReviewing: Color(0xFF4255FF),
    statusMastered: Color(0xFF18AE79),
    errorFill: Color(0xFFB00020),
    onErrorFill: Color(0xFFFFFFFF),
    streak: Color(0xFFF6406C),
    primaryText: Color(0xFF7583FF),
    masteryText: Color(0xFF59E8B5),
    learningText: Color(0xFFFF983A),
    warningText: Color(0xFFFFCD1F),
    focusRing: Color(0xFFA8B1FF),
    border: Color(0xFF282E3E),
    primaryTrack: Color(0xFFDBDFFF),
    neutralTrack: Color(0xFF939BB4),
    primarySoft: Color(0xFFEDEFFF),
    onPrimarySoft: Color(0xFF4255FF),
    successSoft: Color(0xFFE6FCF4),
    successBorder: Color(0xFF98F1D1),
    onSuccessSoft: Color(0xFF12815A),
    learningSoft: Color(0xFFFFF6EF),
    learningBorder: Color(0xFFFFC38C),
    onLearningSoft: Color(0xFFCC4E00),
    warningSoft: Color(0xFFFFEDAB),
    warningBorder: Color(0xFFFFDC62),
    onWarningSoft: Color(0xFF997700),
    dangerSoft: Color(0xFFFFE8D8),
    dangerBorder: Color(0xFFFFC38C),
    onDangerSoft: Color(0xFFB00020),
    neutralSoft: Color(0xFF586380),
    onNeutralSoft: Color(0xFFF6F7FB),
    onSoft: Color(0xFF282E3E),
  );

  /// Mastery and progress green: the fill of a mastered band and a progress bar.
  final Color mastery;

  /// Glyph on a [mastery] fill, such as a done import step.
  final Color onMastery;

  /// A right answer or a finished session (FE-A6 D14); text-safe on a plain
  /// ground. Its own role, never [mastery], though both read as progress.
  final Color success;

  /// The warning fill.
  final Color warning;

  /// Text on a [warning] fill.
  final Color onWarning;

  /// The new status dot and fill.
  final Color statusNew;

  /// The learning status dot and fill.
  final Color statusLearning;

  /// The reviewing status dot and fill.
  final Color statusReviewing;

  /// The mastered status dot and fill.
  final Color statusMastered;

  /// Solid destructive button fill.
  final Color errorFill;

  /// Label on [errorFill].
  final Color onErrorFill;

  /// The current streak's accent: the flame on Progress (FE-A9 D7).
  final Color streak;

  /// Primary as text and glyph (links, outline and text buttons, the selected
  /// destination), never a fill.
  final Color primaryText;

  /// Mastery as text: a mastered status label, a ramp label.
  final Color masteryText;

  /// Learning as text.
  final Color learningText;

  /// Warning as text and glyph on a plain ground.
  final Color warningText;

  /// The 2dp focus ring of every control.
  final Color focusRing;

  /// The 1px hairline of cards, sections, dividers and chrome.
  final Color border;

  /// A toggle's track when on.
  final Color primaryTrack;

  /// A toggle's track when off.
  final Color neutralTrack;

  /// The primary soft ground.
  final Color primarySoft;

  /// Text and glyphs on [primarySoft].
  final Color onPrimarySoft;

  /// The success soft ground.
  final Color successSoft;

  /// The edge of [successSoft].
  final Color successBorder;

  /// Text and glyphs on [successSoft].
  final Color onSuccessSoft;

  /// The learning soft ground.
  final Color learningSoft;

  /// The edge of [learningSoft].
  final Color learningBorder;

  /// Text and glyphs on [learningSoft].
  final Color onLearningSoft;

  /// The warning soft ground.
  final Color warningSoft;

  /// The edge of [warningSoft].
  final Color warningBorder;

  /// Text and glyphs on [warningSoft].
  final Color onWarningSoft;

  /// The danger soft ground.
  final Color dangerSoft;

  /// The edge of [dangerSoft]: the reference names none, so it borrows the
  /// peach edge of the learning family.
  final Color dangerBorder;

  /// Text and glyphs on [dangerSoft].
  final Color onDangerSoft;

  /// The neutral soft ground (a count badge, the new status pill).
  final Color neutralSoft;

  /// Text on [neutralSoft].
  final Color onNeutralSoft;

  /// Body text on any soft ground.
  final Color onSoft;

  @override
  MxSemanticColors copyWith({
    Color? mastery,
    Color? onMastery,
    Color? success,
    Color? warning,
    Color? onWarning,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? errorFill,
    Color? onErrorFill,
    Color? streak,
    Color? primaryText,
    Color? masteryText,
    Color? learningText,
    Color? warningText,
    Color? focusRing,
    Color? border,
    Color? primaryTrack,
    Color? neutralTrack,
    Color? primarySoft,
    Color? onPrimarySoft,
    Color? successSoft,
    Color? successBorder,
    Color? onSuccessSoft,
    Color? learningSoft,
    Color? learningBorder,
    Color? onLearningSoft,
    Color? warningSoft,
    Color? warningBorder,
    Color? onWarningSoft,
    Color? dangerSoft,
    Color? dangerBorder,
    Color? onDangerSoft,
    Color? neutralSoft,
    Color? onNeutralSoft,
    Color? onSoft,
  }) => MxSemanticColors(
    mastery: mastery ?? this.mastery,
    onMastery: onMastery ?? this.onMastery,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    statusNew: statusNew ?? this.statusNew,
    statusLearning: statusLearning ?? this.statusLearning,
    statusReviewing: statusReviewing ?? this.statusReviewing,
    statusMastered: statusMastered ?? this.statusMastered,
    errorFill: errorFill ?? this.errorFill,
    onErrorFill: onErrorFill ?? this.onErrorFill,
    streak: streak ?? this.streak,
    primaryText: primaryText ?? this.primaryText,
    masteryText: masteryText ?? this.masteryText,
    learningText: learningText ?? this.learningText,
    warningText: warningText ?? this.warningText,
    focusRing: focusRing ?? this.focusRing,
    border: border ?? this.border,
    primaryTrack: primaryTrack ?? this.primaryTrack,
    neutralTrack: neutralTrack ?? this.neutralTrack,
    primarySoft: primarySoft ?? this.primarySoft,
    onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
    successSoft: successSoft ?? this.successSoft,
    successBorder: successBorder ?? this.successBorder,
    onSuccessSoft: onSuccessSoft ?? this.onSuccessSoft,
    learningSoft: learningSoft ?? this.learningSoft,
    learningBorder: learningBorder ?? this.learningBorder,
    onLearningSoft: onLearningSoft ?? this.onLearningSoft,
    warningSoft: warningSoft ?? this.warningSoft,
    warningBorder: warningBorder ?? this.warningBorder,
    onWarningSoft: onWarningSoft ?? this.onWarningSoft,
    dangerSoft: dangerSoft ?? this.dangerSoft,
    dangerBorder: dangerBorder ?? this.dangerBorder,
    onDangerSoft: onDangerSoft ?? this.onDangerSoft,
    neutralSoft: neutralSoft ?? this.neutralSoft,
    onNeutralSoft: onNeutralSoft ?? this.onNeutralSoft,
    onSoft: onSoft ?? this.onSoft,
  );

  @override
  MxSemanticColors lerp(
    covariant ThemeExtension<MxSemanticColors>? other,
    double t,
  ) {
    if (other is! MxSemanticColors) return this;

    return MxSemanticColors(
      mastery: Color.lerp(mastery, other.mastery, t)!,
      onMastery: Color.lerp(onMastery, other.onMastery, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      statusNew: Color.lerp(statusNew, other.statusNew, t)!,
      statusLearning: Color.lerp(statusLearning, other.statusLearning, t)!,
      statusReviewing: Color.lerp(statusReviewing, other.statusReviewing, t)!,
      statusMastered: Color.lerp(statusMastered, other.statusMastered, t)!,
      errorFill: Color.lerp(errorFill, other.errorFill, t)!,
      onErrorFill: Color.lerp(onErrorFill, other.onErrorFill, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      masteryText: Color.lerp(masteryText, other.masteryText, t)!,
      learningText: Color.lerp(learningText, other.learningText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryTrack: Color.lerp(primaryTrack, other.primaryTrack, t)!,
      neutralTrack: Color.lerp(neutralTrack, other.neutralTrack, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimarySoft: Color.lerp(onPrimarySoft, other.onPrimarySoft, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      onSuccessSoft: Color.lerp(onSuccessSoft, other.onSuccessSoft, t)!,
      learningSoft: Color.lerp(learningSoft, other.learningSoft, t)!,
      learningBorder: Color.lerp(learningBorder, other.learningBorder, t)!,
      onLearningSoft: Color.lerp(onLearningSoft, other.onLearningSoft, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      onWarningSoft: Color.lerp(onWarningSoft, other.onWarningSoft, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      onDangerSoft: Color.lerp(onDangerSoft, other.onDangerSoft, t)!,
      neutralSoft: Color.lerp(neutralSoft, other.neutralSoft, t)!,
      onNeutralSoft: Color.lerp(onNeutralSoft, other.onNeutralSoft, t)!,
      onSoft: Color.lerp(onSoft, other.onSoft, t)!,
    );
  }
}
