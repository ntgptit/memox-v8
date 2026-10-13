import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Component type treatments ("Flashcard Color Tokens" §3.3, ADR-022).
///
/// Each style is exactly one of the twelve TextTheme roles, its size, line
/// height, weight and tracking untouched; only the colour is the
/// component's. They live in the theme so shared widgets never build or
/// restyle a TextStyle.
@immutable
final class MxTextStyles {
  const MxTextStyles(this._texts, this._scheme, this._semantic);

  final TextTheme _texts;
  final ColorScheme _scheme;
  final MxSemanticColors _semantic;

  /// Primary as text: never the primary fill.
  Color get _primaryText => _semantic.primaryText;

  static const String _codeFamily = 'monospace';
  static const List<String> _codeFallback = ['Menlo', 'Courier New'];

  // The twelve roles.
  TextStyle get _termRole => _texts.displaySmall!;
  TextStyle get _tileTermRole => _texts.headlineSmall!;
  TextStyle get _statRole => _texts.displayMedium!;
  TextStyle get _sectionRole => _texts.titleLarge!;
  TextStyle get _cardTitleRole => _texts.titleMedium!;
  TextStyle get _itemRole => _texts.titleSmall!;
  TextStyle get _contentRole => _texts.bodyLarge!;
  TextStyle get _bodyRole => _texts.bodyMedium!;
  TextStyle get _tileBodyRole => _texts.bodySmall!;
  TextStyle get _buttonRole => _texts.labelLarge!;
  TextStyle get _metaRole => _texts.labelMedium!;
  TextStyle get _navRole => _texts.labelSmall!;

  /// Button label at every size: labelLarge.
  TextStyle get buttonLabel => _buttonRole;

  /// Button label on the small, compact and chip sizes: labelLarge (one
  /// label style for every button).
  TextStyle get buttonLabelSmall => _buttonRole;

  /// A button's second line, such as the interval a grade gives (screen
  /// 16a): labelMedium. Built without the role's colour, so the button's
  /// foreground reaches it through DefaultTextStyle.
  TextStyle get buttonDetail => TextStyle(
    fontFamily: _metaRole.fontFamily,
    fontFamilyFallback: _metaRole.fontFamilyFallback,
    fontSize: _metaRole.fontSize,
    fontWeight: _metaRole.fontWeight,
    fontVariations: _metaRole.fontVariations,
    letterSpacing: _metaRole.letterSpacing,
    height: _metaRole.height,
  );

  /// App-bar content title (deck and card names): titleMedium.
  TextStyle get contentTitle =>
      _cardTitleRole.copyWith(color: _scheme.onSurface);

  /// App-bar screen title: titleLarge.
  TextStyle get screenTitle => _sectionRole.copyWith(color: _scheme.onSurface);

  /// EmptyState title: titleMedium.
  TextStyle get emptyTitle => _cardTitleRole.copyWith(color: _scheme.onSurface);

  /// Compact EmptyState title: titleSmall.
  TextStyle get emptyTitleCompact => _itemRole.copyWith(color: _scheme.onSurface);

  /// EmptyState body: bodyMedium.
  TextStyle get emptyBody =>
      _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// The part of a lead the reader must check, such as the address a code
  /// went to: titleSmall in on-surface.
  TextStyle get emptyBodyStrong => _itemRole.copyWith(color: _scheme.onSurface);

  /// Tappable breadcrumb level: labelMedium.
  TextStyle get breadcrumbAncestor =>
      _metaRole.copyWith(color: _scheme.onSurfaceVariant);

  /// The level the user is on: titleSmall.
  TextStyle get breadcrumbCurrent => _itemRole.copyWith(color: _scheme.onSurface);

  /// StudyTopBar mode badge: labelSmall in the caller's accent.
  TextStyle studyBadge(Color accent) => _navRole.copyWith(color: accent);

  /// StudyTopBar n / total counter: labelSmall.
  TextStyle get counter => _navRole.copyWith(color: _scheme.onSurfaceVariant);

  /// The import step tracker's label (kit 11): labelSmall, onSurface once the
  /// step is reached, onSurfaceVariant before.
  TextStyle stepLabel({required bool isReached}) => _navRole.copyWith(
    color: isReached ? _scheme.onSurface : _scheme.onSurfaceVariant,
  );

  /// A day bar's label (kit 22): labelSmall, onSurface on the current day,
  /// onSurfaceVariant on the rest.
  TextStyle dayLabel({required bool isCurrent}) => _navRole.copyWith(
    color: isCurrent ? _scheme.onSurface : _scheme.onSurfaceVariant,
  );

  /// The number on an import step's dot (kit 11): the counter in [foreground].
  TextStyle stepNumber(Color foreground) => counter.copyWith(color: foreground);

  /// BottomNav and NavRail label: labelSmall, onSurface on the current
  /// destination, onSurfaceVariant on the rest.
  TextStyle navLabel({required bool isSelected}) => _navRole.copyWith(
    color: isSelected ? _scheme.onSurface : _scheme.onSurfaceVariant,
  );

  /// FooterBar caption under the actions: labelSmall.
  TextStyle get footerCaption =>
      _navRole.copyWith(color: _scheme.onSurfaceVariant);

  /// FilterChip count: labelSmall in the chip's foreground.
  TextStyle chipCount(Color foreground) => _navRole.copyWith(color: foreground);

  /// FieldMessage line: labelSmall in the tone's foreground.
  TextStyle fieldMessage(Color foreground) =>
      _navRole.copyWith(color: foreground);

  /// TextField placeholder: bodyMedium.
  TextStyle get inputHint =>
      _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// A disclosure's label (kit card editor "Add details"): labelMedium in
  /// primaryText.
  TextStyle get disclosureLabel => _metaRole.copyWith(color: _primaryText);

  /// A code slot's digit: displaySmall.
  TextStyle get fieldCode => _termRole.copyWith(color: _scheme.onSurface);

  /// SearchField value: labelMedium.
  TextStyle get searchValue => _metaRole.copyWith(color: _scheme.onSurface);

  /// SearchField placeholder: labelMedium in onSurfaceVariant.
  TextStyle get searchHint =>
      _metaRole.copyWith(color: _scheme.onSurfaceVariant);

  /// Row title (OptionRow, ActionSheetCommandRow): titleSmall.
  TextStyle get rowTitle => _itemRole.copyWith(color: _scheme.onSurface);

  /// The matched part of a search hit's name (screen 04): titleSmall in
  /// primaryText, so it sits on the title's line unchanged.
  TextStyle get rowTitleMatch => _itemRole.copyWith(color: _primaryText);

  /// Row description (OptionRow, SettingsRow sub): bodyMedium.
  TextStyle get rowDescription =>
      _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// ListRow title: titleSmall.
  TextStyle get listRowTitle => _itemRole.copyWith(color: _scheme.onSurface);

  /// ListRow and ActionSheetCommandRow sub-line: bodyMedium.
  TextStyle get rowSubtitle =>
      _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// SettingsRow label: titleSmall.
  TextStyle get settingsLabel => _itemRole.copyWith(color: _scheme.onSurface);

  /// ActionSheetCommandRow verb: the row title, error when destructive.
  TextStyle commandLabel({required bool isDestructive}) => rowTitle.copyWith(
    color: isDestructive ? _scheme.error : _scheme.onSurface,
  );

  /// Section label, the overline that introduces a list or settings group:
  /// labelSmall in onSurface. The widget upper-cases the text.
  TextStyle get overline => _navRole.copyWith(color: _scheme.onSurface);

  /// Eyebrow, the context line above a big title or number: labelSmall in
  /// onSurfaceVariant. The caller upper-cases the app's own words, never
  /// user data.
  TextStyle get eyebrow => _navRole.copyWith(color: _scheme.onSurfaceVariant);

  /// Field label, naming an input or a read-only field: labelMedium.
  TextStyle get fieldLabel => _metaRole.copyWith(color: _scheme.onSurface);

  /// A stat's figure (StatTile): displayMedium, in the foreground the tile's
  /// emphasis picks (FE-A6 D17).
  TextStyle statValue(Color foreground) => _statRole.copyWith(color: foreground);

  /// A stat's label: the eyebrow. The widget upper-cases it.
  TextStyle get statLabel => eyebrow;

  /// A card row's status label (screen 07): labelSmall in its status
  /// foreground. The widget upper-cases the text.
  TextStyle statusLabel(Color foreground) =>
      _navRole.copyWith(color: foreground);

  /// A field's "Required" caption: bodyMedium in primaryText.
  TextStyle get requiredMarker => _bodyRole.copyWith(color: _primaryText);

  /// A card field's count (kit FieldHeader): the counter, in error past the
  /// limit.
  TextStyle fieldCount({required bool isOver}) =>
      counter.copyWith(color: isOver ? _scheme.error : null);

  /// A card history move ("Box 4 → 5"): bodyMedium in the outcome's
  /// foreground (DEV-170).
  TextStyle historyMove(Color foreground) =>
      _bodyRole.copyWith(color: foreground);

  /// How long ago an answer was, over its date: labelSmall in on-surface
  /// (DEV-170).
  TextStyle get historyAgo => _navRole.copyWith(color: _scheme.onSurface);

  /// A removable tag's label: labelSmall on the primary soft ground.
  TextStyle get removableTagLabel =>
      _navRole.copyWith(color: _semantic.onPrimarySoft);

  /// Badge and StatusBadge label: labelSmall in [foreground].
  TextStyle badgeLabel(Color foreground) => _navRole.copyWith(color: foreground);

  /// TagChip label: labelSmall.
  TextStyle get tagLabel => _navRole.copyWith(color: _scheme.onSurfaceVariant);

  /// Code, a stack trace or JSON (Monitoring, owner 2026-09-29): bodyMedium
  /// in the system monospace. It sets no `wght` axis: a system face has none.
  TextStyle get code => _bodyRole.copyWith(
    fontFamily: _codeFamily,
    fontFamilyFallback: _codeFallback,
    fontVariations: const <FontVariation>[],
    color: _scheme.onSurface,
  );

  /// Note text: bodyMedium.
  TextStyle get noteText => _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// Note text carrying a status in [foreground], such as the Study Entry's
  /// overdue note in the warning foreground (screen 14): bodyMedium.
  TextStyle statusNote(Color foreground) =>
      _bodyRole.copyWith(color: foreground);

  /// A study card's term: displaySmall. It wraps and never ellipsizes
  /// (FE-A6 D19).
  TextStyle get studyTerm => _termRole.copyWith(color: _scheme.onSurface);

  /// A study card's meaning: bodyLarge.
  TextStyle get studyMeaning => _contentRole.copyWith(color: _scheme.onSurface);

  /// A study card's pronunciation and example: bodyMedium.
  TextStyle get studyDetail =>
      _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// A session's footer hint (kit SessionFooterHint): bodyMedium.
  TextStyle get sessionHint =>
      _bodyRole.copyWith(color: _scheme.onSurfaceVariant);

  /// The session summary's title (kit SessionStatusHero): titleMedium.
  TextStyle get summaryTitle =>
      _cardTitleRole.copyWith(color: _scheme.onSurface);

  /// The strong run of the summary's body, such as "20 cards": titleSmall.
  TextStyle get summaryBodyStrong =>
      _itemRole.copyWith(color: _scheme.onSurface);

  /// A caption run in [foreground], such as a Progress row's learning and
  /// reviewing counts (kit 22): labelSmall.
  TextStyle captionIn(Color foreground) => _navRole.copyWith(color: foreground);

  /// A summary fact's value (kit ResultRow): titleMedium, a key number in a
  /// compact stat, in [foreground].
  TextStyle factValue(Color foreground) =>
      _cardTitleRole.copyWith(color: foreground);

  /// A guess option's meaning (GuessScreen): bodySmall in its tone's
  /// [foreground].
  TextStyle studyOption(Color foreground) =>
      _tileBodyRole.copyWith(color: foreground);

  /// A guess option's letter badge: labelSmall in [foreground].
  TextStyle studyOptionLetter(Color foreground) =>
      _navRole.copyWith(color: foreground);

  /// A match term tile (MatchScreen): headlineSmall in [foreground].
  TextStyle matchTerm(Color foreground) =>
      _tileTermRole.copyWith(color: foreground);

  /// A match meaning tile: bodySmall in [foreground].
  TextStyle matchMeaning(Color foreground) =>
      _tileBodyRole.copyWith(color: foreground);

  /// A study face's running text (Recall's meaning, Fill's prompt):
  /// bodyLarge.
  TextStyle get studyPassage => _contentRole.copyWith(color: _scheme.onSurface);

  /// A checked Fill answer: displaySmall, the term role, in [foreground]; the
  /// typed answer is struck through in its own foreground when [isStruck].
  TextStyle fillAnswer(Color foreground, {required bool isStruck}) =>
      _termRole.copyWith(
        color: foreground,
        decoration: isStruck ? TextDecoration.lineThrough : null,
        decorationColor: isStruck ? foreground : null,
      );

  /// WorkloadBreakdownLine connectives and fallback: labelMedium.
  TextStyle get workloadText =>
      _metaRole.copyWith(color: _scheme.onSurfaceVariant);

  /// WorkloadBreakdownLine term: labelMedium in its colour.
  TextStyle workloadTerm(Color foreground) =>
      _metaRole.copyWith(color: foreground);

  /// MasteryDonut label: labelSmall, the 12 floor, in the arc colour.
  TextStyle donutLabel(Color foreground) => _navRole.copyWith(color: foreground);

  /// Compact title (ErrorState, DeckPickerSheet head, Dialog): titleSmall.
  TextStyle get compactTitle => _itemRole.copyWith(color: _scheme.onSurface);

  /// Dialog body: bodyMedium in onSurface (O5).
  TextStyle get dialogBody => _bodyRole.copyWith(color: _scheme.onSurface);

  /// InlineBanner title: labelMedium in onSurface; the banner recolours it
  /// with its tone's foreground.
  TextStyle get bannerTitle => _metaRole.copyWith(color: _scheme.onSurface);

  /// InlineBanner message: labelMedium, the onSurface lead without a title,
  /// and the onSurfaceVariant detail under one.
  TextStyle bannerMessage({required bool isLead}) => _metaRole.copyWith(
    color: isLead ? _scheme.onSurface : _scheme.onSurfaceVariant,
  );

  /// Snackbar message: bodyMedium on the inverse surface.
  TextStyle get snackbarMessage =>
      _bodyRole.copyWith(color: _scheme.onInverseSurface);

  /// Snackbar action: labelLarge in inversePrimary.
  TextStyle get snackbarAction =>
      _buttonRole.copyWith(color: _scheme.inversePrimary);

  /// SegmentedTray label: labelSmall, onSurface when selected (I5).
  TextStyle trayLabel({required bool isSelected}) => _navRole.copyWith(
    color: isSelected ? _scheme.onSurface : _scheme.onSurfaceVariant,
  );

  /// Stepper value: titleMedium, a key number, in error when invalid.
  TextStyle stepperValue({required bool isInvalid}) => _cardTitleRole.copyWith(
    color: isInvalid ? _scheme.error : _scheme.onSurface,
  );
}
