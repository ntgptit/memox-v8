import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';

/// Component type treatments: the overrides of the nearest V3 role that a
/// widget contract states (spec §4.3). They live in the theme so shared
/// widgets never build or restyle a TextStyle.
@immutable
final class MxTextStyles {
  const MxTextStyles(this._texts, this._scheme);

  final TextTheme _texts;
  final ColorScheme _scheme;

  static const double _labelTracking = 0.1;
  static const double _titleTracking = -0.3;
  static const double _screenTitleTracking = -0.5;
  static const double _emptyBodyHeight = 1.55;
  static const double _rowTitleTracking = -0.1;
  static const double _rowDescriptionHeight = 1.45;
  static const double _listRowTitleHeight = 1.35;
  static const double _overlineTracking = 0.6;
  static const double _pillHeight = 1;
  static const double _noteHeight = 1.5;
  static const double _workloadHeight = 1.5;
  static const double _donutLabelSize = 9;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Button label: 14/600, 0.1 tracking (regular, small, study action).
  TextStyle get buttonLabel => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _labelTracking);

  /// Button label on the compact and chip sizes: 12/600, 0.1 tracking.
  TextStyle get buttonLabelSmall =>
      _texts.labelSmall!.copyWith(letterSpacing: _labelTracking);

  /// App-bar content title (deck and card names): 16/700, -0.3.
  TextStyle get contentTitle => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _titleTracking, color: _scheme.onSurface);

  /// App-bar screen title: 24/700, -0.5.
  TextStyle get screenTitle => _texts.headlineSmall!.copyWith(
    letterSpacing: _screenTitleTracking,
    color: _scheme.onSurface,
  );

  /// EmptyState title: 20/700, -0.3.
  TextStyle get emptyTitle => _texts.titleLarge!.copyWith(
    letterSpacing: _titleTracking,
    color: _scheme.onSurface,
  );

  /// Compact EmptyState title: 16/700, -0.3.
  TextStyle get emptyTitleCompact => contentTitle;

  /// EmptyState body: 14 at line-height 1.55.
  TextStyle get emptyBody => _texts.bodyMedium!.copyWith(
    height: _emptyBodyHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// Tappable breadcrumb level: 12/500, 0.1 tracking.
  TextStyle get breadcrumbAncestor => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w500,
  ).copyWith(letterSpacing: _labelTracking, color: _scheme.onSurfaceVariant);

  /// The level the user is on: 12/700, 0.1 tracking.
  TextStyle get breadcrumbCurrent => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _labelTracking, color: _scheme.onSurface);

  /// StudyTopBar mode badge: 12/700, 1.2 tracking, in the caller's accent.
  TextStyle studyBadge(Color accent) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(color: accent);

  /// StudyTopBar n / total counter: 12/600, tabular numerals.
  TextStyle get counter => _texts.labelSmall!.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    color: _scheme.onSurfaceVariant,
  );

  /// BottomNav label: 12/600, primary on the current destination.
  TextStyle navLabel({required bool isSelected}) => _texts.labelSmall!.copyWith(
    color: isSelected ? _scheme.primary : _scheme.onSurfaceVariant,
  );

  /// FooterBar caption under the actions: 12, onSurfaceVariant.
  TextStyle get footerCaption =>
      _texts.labelSmall!.copyWith(color: _scheme.onSurfaceVariant);

  /// FilterChip count: 12/700 tabular, in the chip's ink at its opacity, with
  /// the label's 0.1 tracking so the pair reads as one line.
  TextStyle chipCount(Color ink) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _labelTracking, fontFeatures: _tabular, color: ink);

  /// FieldMessage line: the caption role in the tone's ink.
  TextStyle fieldMessage(Color ink) => _texts.labelSmall!.copyWith(color: ink);

  /// TextField placeholder: 14, onSurfaceVariant.
  TextStyle get inputHint =>
      _texts.bodyMedium!.copyWith(color: _scheme.onSurfaceVariant);

  /// SearchField value: 16/400.
  TextStyle get searchValue => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w400,
  ).copyWith(color: _scheme.onSurface);

  /// SearchField placeholder: the value style in onSurfaceVariant.
  TextStyle get searchHint =>
      searchValue.copyWith(color: _scheme.onSurfaceVariant);

  /// Row title (OptionRow, ActionSheetCommandRow): 14/600, -0.1.
  TextStyle get rowTitle => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _rowTitleTracking, color: _scheme.onSurface);

  /// Row description (OptionRow, SettingsRow sub): the caption role at
  /// line-height 1.45 (I5, S5).
  TextStyle get rowDescription => _texts.labelSmall!.copyWith(
    height: _rowDescriptionHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// ListRow title: the row title at line-height 1.35, so every row in a list
  /// is one height.
  TextStyle get listRowTitle => rowTitle.copyWith(height: _listRowTitleHeight);

  /// ListRow and ActionSheetCommandRow sub-line: the caption role in
  /// onSurfaceVariant (S5).
  TextStyle get rowSubtitle => footerCaption;

  /// SettingsRow label: 16/600, -0.1.
  TextStyle get settingsLabel => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _rowTitleTracking, color: _scheme.onSurface);

  /// ActionSheetCommandRow verb: the row title, error when destructive.
  TextStyle commandLabel({required bool isDestructive}) => rowTitle.copyWith(
    color: isDestructive ? _scheme.error : _scheme.onSurface,
  );

  /// Overline (Section, ListSectionHeader): 12/700, 0.6 tracking,
  /// onSurfaceVariant. Tabular, so a trailing static count lines up. The
  /// widget upper-cases the text.
  TextStyle get overline =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w700).copyWith(
        letterSpacing: _overlineTracking,
        fontFeatures: _tabular,
        color: _scheme.onSurfaceVariant,
      );

  /// Badge and StatusBadge label: 12/700 tabular at line-height 1, with the
  /// label's 0.1 tracking (S4).
  TextStyle badgeLabel(Color ink) =>
      chipCount(ink).copyWith(height: _pillHeight);

  /// TagChip label: 12/600, 0.1 tracking (S4). It keeps the caption's 1.4
  /// line-height, not the contract's 1: an ellipsized tag clips to its text
  /// box, and a 12px box cuts the descenders.
  TextStyle get tagLabel => _texts.labelSmall!.copyWith(
    letterSpacing: _labelTracking,
    color: _scheme.onSurfaceVariant,
  );

  /// Note text: the caption role at line-height 1.5 (S5).
  TextStyle get noteText => _texts.labelSmall!.copyWith(
    height: _noteHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// WorkloadBreakdownLine connectives and fallback: 12/400 tabular, 0.1
  /// tracking (S4), line-height 1.5 for the 18 band.
  TextStyle get workloadText =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w400).copyWith(
        height: _workloadHeight,
        letterSpacing: _labelTracking,
        fontFeatures: _tabular,
        color: _scheme.onSurfaceVariant,
      );

  /// WorkloadBreakdownLine term: the connective style at 600 in its colour.
  TextStyle workloadTerm(Color ink) => AppTypography.withWeight(
    workloadText,
    FontWeight.w600,
  ).copyWith(color: ink);

  /// MasteryDonut label: 9/700 at line-height 1, 0.1 tracking (S4), in the
  /// arc colour. Below the 12 floor as the contract states (row 8).
  TextStyle donutLabel(Color ink) =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w700).copyWith(
        fontSize: _donutLabelSize,
        height: _pillHeight,
        letterSpacing: _labelTracking,
        color: ink,
      );

  /// SegmentedTray label: the caption role, onSurface when selected (I5).
  TextStyle trayLabel({required bool isSelected}) =>
      _texts.labelSmall!.copyWith(
        color: isSelected ? _scheme.onSurface : _scheme.onSurfaceVariant,
      );

  /// Stepper value: 16/700 tabular, error when invalid.
  TextStyle stepperValue({required bool isInvalid}) =>
      AppTypography.withWeight(_texts.bodyLarge!, FontWeight.w700).copyWith(
        fontFeatures: _tabular,
        color: isInvalid ? _scheme.error : _scheme.onSurface,
      );
}
