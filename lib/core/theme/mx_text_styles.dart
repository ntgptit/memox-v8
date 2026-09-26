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

  /// Line box for a single line that ellipsizes user content. An ellipsized
  /// line clips at its box, and stacked Vietnamese marks (Ẳ, Ổ, Ỗ) rise above
  /// the font's ascent: below 1.5 the box cuts them, and Ổ reads as Ố
  /// (measured in the golden container; FE-C2).
  static const double _singleLineHeight = 1.5;
  static const double _emptyBodyHeight = 1.55;
  static const double _rowTitleTracking = -0.1;
  static const double _rowDescriptionHeight = 1.45;
  static const double _overlineTracking = 0.6;
  static const double _pillHeight = 1;
  static const double _noteHeight = 1.5;
  static const double _workloadHeight = 1.5;
  static const double _donutLabelSize = 9;
  static const double _compactTitleTracking = -0.2;
  static const double _bannerHeight = 1.55;
  static const double _snackbarHeight = 1.4;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];
  static const double _termTracking = -0.4;
  static const double _badgeTracking = 1.2;
  static const double _countTracking = 0.2;
  static const double _termHeight = 1.25;
  static const double _termLongSize = 18;
  static const double _fieldBodyHeight = 1.45;
  static const double _studyTermSize = 32;
  static const double _studyTermTracking = -0.5;
  static const double _studyTermHeight = 1.15;
  static const double _studyMeaningSize = 24;
  static const double _studyMeaningTracking = -0.3;
  static const double _hintTracking = 0.3;
  static const double _summaryTitleSize = 24;
  static const double _summaryTitleTracking = -0.4;
  static const double _factValueSize = 16;
  static const double _statValueHeight = 1.1;
  static const double _buttonDetailHeight = 1.2;
  static const double _optionSize = 16;
  static const double _optionTracking = -0.1;
  static const double _choiceHeight = 1.25;

  /// Button label: 14/600, 0.1 tracking (regular, small, study action).
  TextStyle get buttonLabel => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _labelTracking);

  /// Button label on the compact and chip sizes: 12/600, 0.1 tracking.
  TextStyle get buttonLabelSmall =>
      _texts.labelSmall!.copyWith(letterSpacing: _labelTracking);

  /// A button's second line, such as the interval a grade gives (screen
  /// 16a): 12/500 tabular. Built without the role's colour, so the button's
  /// ink reaches it through DefaultTextStyle.
  TextStyle get buttonDetail {
    final base = AppTypography.withWeight(_texts.labelSmall!, FontWeight.w500);
    return TextStyle(
      fontFamily: base.fontFamily,
      fontFamilyFallback: base.fontFamilyFallback,
      fontSize: base.fontSize,
      fontWeight: base.fontWeight,
      fontVariations: base.fontVariations,
      letterSpacing: base.letterSpacing,
      height: _buttonDetailHeight,
      fontFeatures: _tabular,
    );
  }

  /// App-bar content title (deck and card names): 16/700, -0.3.
  TextStyle get contentTitle => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _titleTracking, color: _scheme.onSurface);

  /// App-bar screen title: 24/700, -0.5, at the single-line height rather
  /// than the headline's 1.2.
  TextStyle get screenTitle => _texts.headlineSmall!.copyWith(
    height: _singleLineHeight,
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
  TextStyle studyBadge(Color accent) =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w700).copyWith(
        letterSpacing: _badgeTracking,
        // It ellipsizes at large text, so it keeps the single-line height
        // (UI-base §9 row 102; FE-A6 P3 T1).
        height: _singleLineHeight,
        color: accent,
      );

  /// StudyTopBar n / total counter: 12/600, tabular numerals.
  TextStyle get counter => _texts.labelSmall!.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    color: _scheme.onSurfaceVariant,
  );

  /// The import step tracker's label (kit 11): 12/600, onSurface once the
  /// step is reached, onSurfaceVariant before.
  TextStyle stepLabel({required bool isReached}) => _texts.labelSmall!.copyWith(
    color: isReached ? _scheme.onSurface : _scheme.onSurfaceVariant,
  );

  /// The number on an import step's dot (kit 11): the counter in [ink].
  TextStyle stepNumber(Color ink) => counter.copyWith(color: ink);

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

  /// Card editor term (kit 08/09 Front): 24/700 at 1.25, -0.4 tracking.
  TextStyle get fieldTerm => _texts.headlineSmall!.copyWith(
    height: _termHeight,
    letterSpacing: _termTracking,
    color: _scheme.onSurface,
  );

  /// A term past 30 characters: 18/700, so it still fits the box (kit).
  TextStyle get fieldTermLong =>
      AppTypography.withWeight(
        _texts.bodyLarge!.copyWith(fontSize: _termLongSize),
        FontWeight.w700,
      ).copyWith(
        height: _termHeight,
        letterSpacing: _termTracking,
        color: _scheme.onSurface,
      );

  /// A disclosure's label (kit card editor "Add details"): 12/600 primary.
  TextStyle get disclosureLabel =>
      _texts.labelSmall!.copyWith(color: _scheme.primary);

  /// The term's placeholder: 16/500, onSurfaceVariant.
  TextStyle get fieldTermHint =>
      _texts.bodyLarge!.copyWith(color: _scheme.onSurfaceVariant);

  /// Card editor meaning (kit Back): 16/500 at 1.45.
  TextStyle get fieldMeaning => _texts.bodyLarge!.copyWith(
    height: _fieldBodyHeight,
    color: _scheme.onSurface,
  );

  /// An optional detail's value (kit OptionalField): 14/400 at 1.45.
  TextStyle get fieldDetail => _texts.bodyMedium!.copyWith(
    height: _fieldBodyHeight,
    color: _scheme.onSurface,
  );

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

  /// The matched part of a search hit's name (screen 04): the list row
  /// title, bold, in primary, so it sits on the title's line unchanged.
  TextStyle get rowTitleMatch => AppTypography.withWeight(
    listRowTitle,
    FontWeight.w700,
  ).copyWith(color: _scheme.primary);

  /// Row description (OptionRow, SettingsRow sub): the caption role at
  /// line-height 1.45 (I5, S5).
  TextStyle get rowDescription => _texts.labelSmall!.copyWith(
    height: _rowDescriptionHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// ListRow title: the row title at the single-line height, so every row in
  /// a list is one height.
  TextStyle get listRowTitle => rowTitle.copyWith(height: _singleLineHeight);

  /// ListRow and ActionSheetCommandRow sub-line: the caption role in
  /// onSurfaceVariant (S5), at the single-line height.
  TextStyle get rowSubtitle =>
      footerCaption.copyWith(height: _singleLineHeight);

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

  /// A stat's figure (StatTile): the headline role at 700, tabular, tight
  /// line box, in the ink the tile's emphasis picks (FE-A6 D17).
  TextStyle statValue(Color ink) => AppTypography.withWeight(
    _texts.headlineSmall!,
    FontWeight.w700,
  ).copyWith(height: _statValueHeight, fontFeatures: _tabular, color: ink);

  /// A stat's label: the overline. The widget upper-cases it.
  TextStyle get statLabel => overline;

  /// A card row's status label (screen 07): the overline's 12/700 and 0.6
  /// tracking, in its status ink. The widget upper-cases the text.
  TextStyle statusLabel(Color ink) => overline.copyWith(color: ink);

  /// A card field's "Required" marker: the overline in primary (kit 08).
  TextStyle get requiredMarker => overline.copyWith(color: _scheme.primary);

  /// A card field's count (kit FieldHeader): the counter at 0.2 tracking, in
  /// error past the limit.
  TextStyle fieldCount({required bool isOver}) => counter.copyWith(
    letterSpacing: _countTracking,
    color: isOver ? _scheme.error : null,
  );

  /// A removable tag's label: the tag label in primary, on its tint.
  TextStyle get removableTagLabel => tagLabel.copyWith(color: _scheme.primary);

  /// Badge and StatusBadge label: 12/700 tabular at line-height 1, with the
  /// label's 0.1 tracking (S4).
  TextStyle badgeLabel(Color ink) =>
      chipCount(ink).copyWith(height: _pillHeight);

  /// TagChip label: 12/600, 0.1 tracking (S4), at the single-line height, not
  /// the contract's 1: an ellipsized tag clips to its text box.
  TextStyle get tagLabel => _texts.labelSmall!.copyWith(
    height: _singleLineHeight,
    letterSpacing: _labelTracking,
    color: _scheme.onSurfaceVariant,
  );

  /// Note text: the caption role at line-height 1.5 (S5).
  TextStyle get noteText => _texts.labelSmall!.copyWith(
    height: _noteHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// Note text carrying a status in [ink], such as the Study Entry's
  /// overdue note in the warning ink (screen 14): the note role at 600.
  TextStyle statusNote(Color ink) =>
      AppTypography.withWeight(noteText, FontWeight.w600).copyWith(color: ink);

  /// A study card's term (kit Browse): 32/700 at 1.15, -0.5 tracking. It
  /// wraps and never ellipsizes (FE-A6 D19).
  TextStyle get studyTerm =>
      AppTypography.withWeight(
        _texts.headlineSmall!.copyWith(fontSize: _studyTermSize),
        FontWeight.w700,
      ).copyWith(
        height: _studyTermHeight,
        letterSpacing: _studyTermTracking,
        color: _scheme.onSurface,
      );

  /// A study card's meaning (kit Browse): 24/600, -0.3 tracking.
  TextStyle get studyMeaning => AppTypography.withWeight(
    _texts.headlineSmall!.copyWith(fontSize: _studyMeaningSize),
    FontWeight.w600,
  ).copyWith(letterSpacing: _studyMeaningTracking, color: _scheme.onSurface);

  /// A study card's pronunciation and example: 14/400 at 1.5, variant ink.
  TextStyle get studyDetail => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w400,
  ).copyWith(height: _noteHeight, color: _scheme.onSurfaceVariant);

  /// A session's footer hint (kit SessionFooterHint): 12/400, 0.3 tracking.
  TextStyle get sessionHint => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w400,
  ).copyWith(letterSpacing: _hintTracking, color: _scheme.onSurfaceVariant);

  /// The session summary's title (kit SessionStatusHero): 24/700 at 1.15.
  TextStyle get summaryTitle =>
      AppTypography.withWeight(
        _texts.headlineSmall!.copyWith(fontSize: _summaryTitleSize),
        FontWeight.w700,
      ).copyWith(
        height: _studyTermHeight,
        letterSpacing: _summaryTitleTracking,
        color: _scheme.onSurface,
      );

  /// The bold run of the summary's body, such as "20 cards" (kit).
  TextStyle get summaryBodyStrong => AppTypography.withWeight(
    emptyBody,
    FontWeight.w700,
  ).copyWith(color: _scheme.onSurface);

  /// A summary fact's value (kit ResultRow): 16/700 tabular, in [ink].
  TextStyle factValue(Color ink) => AppTypography.withWeight(
    _texts.bodyLarge!.copyWith(fontSize: _factValueSize),
    FontWeight.w700,
  ).copyWith(fontFeatures: _tabular, color: ink);

  /// A guess option's meaning (kit GuessScreen): 16/500 at 1.25, -0.1
  /// tracking, in its tone's [ink] (FE-A6 P3).
  TextStyle studyOption(Color ink) => AppTypography.withWeight(
    _texts.bodyLarge!.copyWith(fontSize: _optionSize),
    FontWeight.w500,
  ).copyWith(height: _choiceHeight, letterSpacing: _optionTracking, color: ink);

  /// A guess option's letter badge: 12/700 at height 1, in [ink].
  TextStyle studyOptionLetter(Color ink) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(height: 1, letterSpacing: 0, color: ink);

  /// A match term tile (kit MatchScreen): 18/700 at 1.25, -0.4, in [ink].
  TextStyle matchTerm(Color ink) => AppTypography.withWeight(
    _texts.bodyLarge!.copyWith(fontSize: _termLongSize),
    FontWeight.w700,
  ).copyWith(height: _choiceHeight, letterSpacing: _termTracking, color: ink);

  /// A match meaning tile: 14/600 at 1.25, in [ink].
  TextStyle matchMeaning(Color ink) => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(height: _choiceHeight, letterSpacing: 0, color: ink);

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

  /// Compact title (ErrorState, DeckPickerSheet head, Dialog): 16/700, -0.2.
  TextStyle get compactTitle => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _compactTitleTracking, color: _scheme.onSurface);

  /// Dialog body: 14 in onSurface (O5).
  TextStyle get dialogBody =>
      _texts.bodyMedium!.copyWith(color: _scheme.onSurface);

  /// InlineBanner title: 12/700 at line-height 1.55, onSurface.
  TextStyle get bannerTitle => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(height: _bannerHeight, color: _scheme.onSurface);

  /// InlineBanner message: the caption role at 1.55 (I5, O6). It is the
  /// onSurface lead without a title, and the onSurfaceVariant detail under
  /// one.
  TextStyle bannerMessage({required bool isLead}) =>
      _texts.labelSmall!.copyWith(
        height: _bannerHeight,
        color: isLead ? _scheme.onSurface : _scheme.onSurfaceVariant,
      );

  /// Snackbar message: 14 at line-height 1.4 on the inverse surface.
  TextStyle get snackbarMessage => _texts.bodyMedium!.copyWith(
    height: _snackbarHeight,
    color: _scheme.onInverseSurface,
  );

  /// Snackbar action: 14/700 in inversePrimary.
  TextStyle get snackbarAction => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w700,
  ).copyWith(color: _scheme.inversePrimary);

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
