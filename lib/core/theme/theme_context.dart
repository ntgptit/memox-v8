import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// ponytail: keyed by the immutable ThemeData, so a theme switch resolves
// afresh and a dropped theme lets its entry go; a ThemeExtension if the
// derived set ever needs lerping.
final _derived = Expando<MxDerivedColors>('derivedColors');

/// The one way UI code reads the theme.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  MxSemanticColors get semanticColors {
    final semantic = Theme.of(this).extension<MxSemanticColors>();
    if (semantic == null) {
      throw StateError(
        'MxSemanticColors is missing from the ThemeData in scope. Build it '
        'with buildLightTheme() or buildDarkTheme() from '
        'core/theme/app_theme.dart.',
      );
    }
    return semantic;
  }

  /// Resolved once per theme (§9 row 66), not at every read.
  MxDerivedColors get derivedColors {
    final theme = Theme.of(this);
    return _derived[theme] ??= MxDerivedColors.resolve(
      theme.colorScheme,
      semanticColors,
    );
  }

  MxTextStyles get textStyles => MxTextStyles(texts, colors);

  /// The TextField hint the theme's fields carry (spec §4.6).
  TextStyle get fieldHint =>
      _themed(Theme.of(this).inputDecorationTheme.hintStyle, 'field hint');

  /// The dialog surface's shape the theme carries (spec §4.6).
  RoundedRectangleBorder get dialogShape =>
      _themed(DialogTheme.of(this).shape, 'dialog shape');

  /// The scrim behind a dialog (spec §4.6).
  Color get dialogBarrier =>
      _themed(DialogTheme.of(this).barrierColor, 'dialog scrim');

  /// The bottom sheet's shape the theme carries (spec §4.6).
  RoundedRectangleBorder get sheetShape =>
      _themed(Theme.of(this).bottomSheetTheme.shape, 'sheet shape');

  /// [value] as the MemoX theme sets it; a theme built elsewhere lacks the
  /// component themes, and says how to fix that.
  T _themed<T>(Object? value, String what) {
    if (value is T) return value;
    throw StateError(
      'The MemoX $what is missing from the ThemeData in scope. Build it with '
      'buildLightTheme() or buildDarkTheme() from core/theme/app_theme.dart.',
    );
  }
}
