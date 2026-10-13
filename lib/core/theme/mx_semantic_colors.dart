import 'package:flutter/material.dart';

/// Every MemoX colour Material has no role for ("Flashcard Color Tokens" §2,
/// ADR-022): status and semantic fills, the text tokens, the edges and
/// tracks, the soft grounds with their borders and text, and the tonal
/// surfaces of cards, search and tiles. Each is a literal per theme; nothing
/// is derived at run time. A soft ground is its colour at 16% over the
/// theme's surface, precomputed: light in light, dark in dark. Green means
/// mastery or success, never decoration.
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
    required this.cardSurface,
    required this.searchSurface,
    required this.tileSurface,
    required this.divider,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  static const MxSemanticColors light = MxSemanticColors(
    mastery: Color(0xFF17AE79),
    onMastery: Color(0xFF003925),
    success: Color(0xFF006C49),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF613B00),
    statusNew: Color(0xFF6C7794),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFF564BCB),
    statusMastered: Color(0xFF17AE79),
    errorFill: Color(0xFFBA1A1A),
    onErrorFill: Color(0xFFFFFFFF),
    streak: Color(0xFFF59E0B),
    primaryText: Color(0xFF564BCB),
    masteryText: Color(0xFF006C49),
    learningText: Color(0xFF855300),
    warningText: Color(0xFF855300),
    focusRing: Color(0xFF564BCB),
    border: Color(0xFFBBC6E6),
    primaryTrack: Color(0xFF564BCB),
    neutralTrack: Color(0xFFE8E8E8),
    primarySoft: Color(0xFFE4E2F7),
    onPrimarySoft: Color(0xFF564BCB),
    successSoft: Color(0xFFD6E7E2),
    successBorder: Color(0xFF006C49),
    onSuccessSoft: Color(0xFF006C49),
    learningSoft: Color(0xFFEBE3D6),
    learningBorder: Color(0xFF855300),
    onLearningSoft: Color(0xFF855300),
    warningSoft: Color(0xFFEBE3D6),
    warningBorder: Color(0xFF855300),
    onWarningSoft: Color(0xFF855300),
    dangerSoft: Color(0xFFF4DADA),
    dangerBorder: Color(0xFFBA1A1A),
    onDangerSoft: Color(0xFFBA1A1A),
    neutralSoft: Color(0xFFD1DCFD),
    onNeutralSoft: Color(0xFF55607C),
    onSoft: Color(0xFF1C1B21),
    cardSurface: Color(0xFFF1F1FB),
    searchSurface: Color(0xFFF1F1FB),
    tileSurface: Color(0xFFEDF8FF),
    divider: Color(0xFFEEEEEE),
    info: Color(0xFF006684),
    infoContainer: Color(0xFF50CCFC),
    onInfoContainer: Color(0xFF00546D),
  );

  static const MxSemanticColors dark = MxSemanticColors(
    mastery: Color(0xFF17AE79),
    onMastery: Color(0xFF003925),
    success: Color(0xFF5ADDA4),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF613B00),
    statusNew: Color(0xFF8590AE),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFFC5C0FF),
    statusMastered: Color(0xFF17AE79),
    errorFill: Color(0xFFFFB4AB),
    onErrorFill: Color(0xFF690005),
    streak: Color(0xFFF59E0B),
    primaryText: Color(0xFFC5C0FF),
    masteryText: Color(0xFF5ADDA4),
    learningText: Color(0xFFFFC174),
    warningText: Color(0xFFFFC174),
    focusRing: Color(0xFF564BCB),
    border: Color(0xFF3B4661),
    primaryTrack: Color(0xFF564BCB),
    neutralTrack: Color(0xFF2D2C51),
    primarySoft: Color(0xFF28254F),
    onPrimarySoft: Color(0xFFC5C0FF),
    successSoft: Color(0xFF172A40),
    successBorder: Color(0xFF5ADDA4),
    onSuccessSoft: Color(0xFF5ADDA4),
    learningSoft: Color(0xFF312638),
    learningBorder: Color(0xFFFFC174),
    onLearningSoft: Color(0xFFFFC174),
    warningSoft: Color(0xFF312638),
    warningBorder: Color(0xFFFFC174),
    onWarningSoft: Color(0xFFFFC174),
    dangerSoft: Color(0xFF312441),
    dangerBorder: Color(0xFFFFB4AB),
    onDangerSoft: Color(0xFFFFB4AB),
    neutralSoft: Color(0xFF3B4661),
    onNeutralSoft: Color(0xFFAAB5D4),
    onSoft: Color(0xFFE5E1E9),
    cardSurface: Color(0xFF222145),
    searchSurface: Color(0xFF222145),
    tileSurface: Color(0xFF2E3953),
    divider: Color(0xFF18173B),
    info: Color(0xFFA9E3FF),
    infoContainer: Color(0xFF50CCFC),
    onInfoContainer: Color(0xFF00546D),
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

  /// The current streak's accent: the flame on Progress (FE-A9 D7), the
  /// warning container's orange.
  final Color streak;

  /// Primary as text and glyph (links, outline and text buttons): primary in
  /// light, primaryFixedDim in dark, where primary is 3.01:1. Never a fill.
  final Color primaryText;

  /// Mastery as text: a mastered status label, a ramp label.
  final Color masteryText;

  /// Learning as text.
  final Color learningText;

  /// Warning as text and glyph on a plain ground.
  final Color warningText;

  /// The 2dp focus ring of every control.
  final Color focusRing;

  /// The 1px hairline inside a card and of a control: outlineVariant.
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

  /// The danger ground: error at 16% over the surface, solid.
  final Color dangerSoft;

  /// The edge of [dangerSoft]: error.
  final Color dangerBorder;

  /// Danger text and glyphs on [dangerSoft]: error.
  final Color onDangerSoft;

  /// The neutral soft ground (a count badge, the new status pill).
  final Color neutralSoft;

  /// Text on [neutralSoft].
  final Color onNeutralSoft;

  /// Body text on any soft ground.
  final Color onSoft;

  /// The ground of every card: tonal elevation, no shadow and no edge.
  final Color cardSurface;

  /// The ground of MxSearchField, the card's tone, no shadow.
  final Color searchSurface;

  /// The ground of a deck's icon tile (DeckTile, DeckCard).
  final Color tileSurface;

  /// A rule on the page ground: the top edge of MxBottomNav, the trailing
  /// edge of MxNavRail. A rule inside a card reads [border].
  final Color divider;

  /// Information as text or glyph on a plain ground, such as the hourglass of
  /// a card waiting for Recall or Fill.
  final Color info;

  /// The information fill; a deck's glyph on [tileSurface] in dark.
  final Color infoContainer;

  /// Text on [infoContainer].
  final Color onInfoContainer;

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
    Color? cardSurface,
    Color? searchSurface,
    Color? tileSurface,
    Color? divider,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
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
    cardSurface: cardSurface ?? this.cardSurface,
    searchSurface: searchSurface ?? this.searchSurface,
    tileSurface: tileSurface ?? this.tileSurface,
    divider: divider ?? this.divider,
    info: info ?? this.info,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
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
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      searchSurface: Color.lerp(searchSurface, other.searchSurface, t)!,
      tileSurface: Color.lerp(tileSurface, other.tileSurface, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
