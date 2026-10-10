import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Surface treatments shared by more than one component contract.
abstract final class AppDecorations {
  /// The Card surface: the card ground at radius 12, the one radius of every
  /// in-flow surface, with the border hairline in both themes (Day's card
  /// and page are both white, plan R2) and the whisper shadow where the
  /// theme casts one.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: semantic.border, width: AppStroke.hairline),
    boxShadow: AppShadows.whisper(scheme),
  );

  /// The answer face of a study card (kit StudyFaceCard role answer, screen
  /// 16a): the low ground with the hairline, flat, so it reads as recessed
  /// under the raised prompt.
  static BoxDecoration recessedCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => raisedCard(
    scheme,
    semantic,
  ).copyWith(color: scheme.surfaceContainerLow, boxShadow: const []);

  /// The hero Card: the primary container with the hairline.
  static BoxDecoration heroCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => raisedCard(scheme, semantic).copyWith(color: scheme.primaryContainer);

  /// The warning Card, for a state that asks for care such as a locked
  /// review algorithm (screen 02, owner decision D-O1): the warning soft
  /// ground, light in both themes, edged in its border.
  static BoxDecoration warningCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _soft(scheme, semantic, semantic.warningSoft, semantic.warningBorder);

  /// The success Card, for a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _soft(scheme, semantic, semantic.successSoft, semantic.successBorder);

  /// The danger Card, for a session stopped by an error.
  static BoxDecoration dangerCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _soft(scheme, semantic, semantic.dangerSoft, semantic.dangerBorder);

  static BoxDecoration _soft(
    ColorScheme scheme,
    MxSemanticColors semantic,
    Color ground,
    Color edge,
  ) => raisedCard(scheme, semantic).copyWith(
    color: ground,
    border: Border.all(color: edge, width: AppStroke.hairline),
  );

  /// The toned surface of a guess option and a match tile (screens 17 and
  /// 18): idle on the card ground with the hairline, selected in primary,
  /// right on the success soft ground and wrong on the danger soft ground
  /// (FE-A6 P3; a right outcome is success, never mastery — spec D14).
  /// [isRecessed] gives an idle tile the answer face's low ground (Match's
  /// meanings, critique 2026-09-30 part 3c-2, R3); the other tones keep
  /// their surfaces.
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone, {
    bool isRecessed = false,
  }) {
    final (Color fill, Color edge) = switch (tone) {
      StudyChoiceTone.idle => (
        isRecessed ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        semantic.border,
      ),
      StudyChoiceTone.selected => (scheme.primary, scheme.primary),
      StudyChoiceTone.right => (semantic.successSoft, semantic.successBorder),
      StudyChoiceTone.wrong => (semantic.dangerSoft, semantic.dangerBorder),
    };
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: edge, width: AppStroke.hairline),
    );
  }

  /// The text and glyph colour on a [studyChoice] surface.
  static Color studyChoiceForeground(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone,
  ) => switch (tone) {
    StudyChoiceTone.idle => scheme.onSurface,
    StudyChoiceTone.selected => scheme.onPrimary,
    StudyChoiceTone.right => semantic.onSuccessSoft,
    StudyChoiceTone.wrong => semantic.onDangerSoft,
  };
}

/// The states of a study choice surface (screens 17 and 18).
enum StudyChoiceTone { idle, selected, right, wrong }
