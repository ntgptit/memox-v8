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

  /// The answer face of a study card (kit StudyFaceCard role answer, screen
  /// 16a): the container-low ground with the ghost edge in both themes, and
  /// flat, so it reads as recessed under the raised prompt.
  static BoxDecoration recessedCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => raisedCard(scheme, derived).copyWith(
    color: scheme.surfaceContainerLow,
    border: Border.all(color: derived.ghostBorder, width: AppStroke.hairline),
    boxShadow: const [],
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

  /// The toned surface of a guess option and a match tile (screens 17 and
  /// 18): idle on the raised fill with the ghost edge, selected in primary,
  /// right in the success tint and wrong in the danger tint (FE-A6 P3; a
  /// right outcome is success, never mastery — spec D14).
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxDerivedColors derived,
    StudyChoiceTone tone,
  ) {
    final raised = scheme.surfaceContainerLowest;
    final (Color fill, Color edge) = switch (tone) {
      StudyChoiceTone.idle => (raised, derived.ghostBorder),
      StudyChoiceTone.selected => (scheme.primary, scheme.primary),
      StudyChoiceTone.right => (
        Color.alphaBlend(derived.successSoft, raised),
        derived.successBorder,
      ),
      StudyChoiceTone.wrong => (
        Color.alphaBlend(derived.dangerSoft, raised),
        derived.dangerBorder,
      ),
    };
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: edge, width: AppStroke.hairline),
    );
  }

  /// The ink on a [studyChoice] surface.
  static Color studyChoiceInk(
    ColorScheme scheme,
    MxDerivedColors derived,
    StudyChoiceTone tone,
  ) => switch (tone) {
    StudyChoiceTone.idle => scheme.onSurface,
    StudyChoiceTone.selected => scheme.onPrimary,
    StudyChoiceTone.right => derived.successInk,
    StudyChoiceTone.wrong => scheme.error,
  };
}

/// The states of a study choice surface (screens 17 and 18).
enum StudyChoiceTone { idle, selected, right, wrong }
