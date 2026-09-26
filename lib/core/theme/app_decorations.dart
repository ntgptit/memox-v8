import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';

/// Surface treatments shared by more than one component contract.
abstract final class AppDecorations {
  /// The Card surface: surface-raised fill and radius 20; the whisper shadow
  /// in light and a 1px ghost border in dark, which has no shadow.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: scheme.brightness == Brightness.dark
        ? Border.all(color: derived.ghostBorder, width: AppStroke.hairline)
        : null,
    boxShadow: AppShadows.whisper(scheme),
  );

  /// The tinted hero Card: the surface-hero fill, with the ghost edge in both
  /// themes, because a borderless hero dissolves into the light page.
  static BoxDecoration heroCard(ColorScheme scheme, MxDerivedColors derived) =>
      raisedCard(scheme, derived).copyWith(
        color: derived.surfaceHero,
        border: Border.all(
          color: derived.ghostBorder,
          width: AppStroke.hairline,
        ),
      );

  /// The warning Card: the warning-soft ground over the raised fill, edged
  /// with the warning border, for a state that asks for care such as a
  /// locked review algorithm (screen 02, owner decision D-O1).
  static BoxDecoration warningCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) {
    final raised = raisedCard(scheme, derived);
    return raised.copyWith(
      color: Color.alphaBlend(derived.warningSoft, raised.color!),
      border: Border.all(
        color: derived.warningBorder,
        width: AppStroke.hairline,
      ),
    );
  }

  /// The success Card: the success-soft ground over the raised fill, edged
  /// with the success border, for a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) {
    final raised = raisedCard(scheme, derived);
    return raised.copyWith(
      color: Color.alphaBlend(derived.successSoft, raised.color!),
      border: Border.all(
        color: derived.successBorder,
        width: AppStroke.hairline,
      ),
    );
  }

  /// The danger Card: the danger-soft ground over the raised fill, edged
  /// with the destructive border, for a session stopped by an error.
  static BoxDecoration dangerCard(ColorScheme scheme, MxDerivedColors derived) {
    final raised = raisedCard(scheme, derived);
    return raised.copyWith(
      color: Color.alphaBlend(derived.dangerSoft, raised.color!),
      border: Border.all(
        color: derived.dangerBorder,
        width: AppStroke.hairline,
      ),
    );
  }
}
