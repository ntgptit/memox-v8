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
  static const double _optionTitleTracking = -0.1;
  static const double _optionDescriptionHeight = 1.45;
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

  /// FilterChip count: 12/700 tabular, in the chip's ink at its opacity.
  TextStyle chipCount(Color ink) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(fontFeatures: _tabular, color: ink);

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

  /// OptionRow title: 14/600, -0.1.
  TextStyle get optionTitle => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _optionTitleTracking, color: _scheme.onSurface);

  /// OptionRow description: the caption role at line-height 1.45 (I5).
  TextStyle get optionDescription => _texts.labelSmall!.copyWith(
    height: _optionDescriptionHeight,
    color: _scheme.onSurfaceVariant,
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
