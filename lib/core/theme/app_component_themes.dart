import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// The component themes of the surfaces Flutter draws on its own — pickers,
/// their dialogs and their buttons — where DESIGN.md states something
/// Material 3's scheme-driven default does not (spec 2026-10-04-sp3a §5.2).
/// The cursor, the selection handles and the spinner keep Material's
/// default, `primary`, which holds its contrast floor itself (D18). Each
/// `Mx*` that mirrors a Material component adds its theme here when it is
/// built, with a parity test.
abstract final class AppComponentThemes {
  /// Dialogs float: the sheet ground and the 20 radius.
  static DialogThemeData dialog(ColorScheme scheme) => DialogThemeData(
    backgroundColor: scheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
  );

  static DatePickerThemeData datePicker(ColorScheme scheme) =>
      DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );

  static TimePickerThemeData timePicker(ColorScheme scheme) =>
      TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );

  /// The quiet action of a system dialog: DESIGN.md's text tone of
  /// MxButton, a `primary` label with no fill and no edge.
  static TextButtonThemeData textButton(
    ColorScheme scheme,
    MxTextStyles styles,
  ) => TextButtonThemeData(
    style: appButtonStyle(
      ink: scheme.primary,
      focusRing: scheme.primary,
      label: styles.buttonLabel,
    ),
  );
}
