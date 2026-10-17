import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

/// The one way UI code reads the theme: the ForUI theme in scope (ADR-025).
/// A feature reads these and never imports ForUI for them.
extension ThemeContext on BuildContext {
  /// ForUI's colour roles.
  FColors get colors => FTheme.of(this).colors;

  /// The text roles, each a step of ForUI's type scale.
  MxTextRoles get texts => MxTextRoles(FTheme.of(this).typography);

  /// The success, warning and info colours ForUI has no role for.
  MxStatusColors get status =>
      _require(() => FTheme.of(this).colors.extension<MxStatusColors>());

  /// The app's spacing, margins, breakpoints and layout sizes.
  AppDimens get dimens =>
      _require(() => FTheme.of(this).extension<AppDimens>());

  /// ForUI's corner radii.
  FBorderRadius get radii => FTheme.of(this).style.borderRadius;

  /// ForUI's border width, the one hairline.
  double get hairline => FTheme.of(this).style.borderWidth;
}

/// [read]'s extension, or a message that names the fix: a theme built outside
/// `core/theme/app_theme.dart` lacks the app's extensions.
T _require<T>(T Function() read) {
  try {
    return read();
  } on TypeError {
    throw StateError(
      '$T is missing from the FTheme in scope. Wrap the tree in an FTheme '
      'built by buildLightTheme() or buildDarkTheme() from '
      'core/theme/app_theme.dart.',
    );
  }
}
