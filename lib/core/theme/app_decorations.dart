import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Surface treatments shared by more than one component contract.
///
/// A card rises by its tone, never by an edge or a shadow, the same in both
/// themes ("Flashcard Color Tokens" §6, §4.8): each variant is its ground at
/// radius 12 and nothing else. A rule inside a card reads `border`.
abstract final class AppDecorations {
  /// The Card surface: the card ground at radius 12.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _card(semantic.cardSurface);

  /// The answer face of a study card (kit StudyFaceCard role answer, screen
  /// 16a): the low ground, so it reads as recessed under the raised prompt.
  static BoxDecoration recessedCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _card(scheme.surfaceContainerLow);

  /// The hero Card: the primary soft ground, the accent at 16% over the
  /// surface. The spec's primaryContainer is the solid accent, which a
  /// primary button and the content's text tokens cannot sit on (owner
  /// 2026-10-13, ADR-022).
  static BoxDecoration heroCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _card(semantic.primarySoft);

  /// The warning Card, for a state that asks for care such as a locked
  /// review algorithm (screen 02, owner decision D-O1): the warning soft
  /// ground.
  static BoxDecoration warningCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _card(semantic.warningSoft);

  /// The success Card, for a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _card(semantic.successSoft);

  /// The danger Card, for a session stopped by an error.
  static BoxDecoration dangerCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _card(semantic.dangerSoft);

  static BoxDecoration _card(Color ground) => BoxDecoration(
    color: ground,
    borderRadius: BorderRadius.circular(AppRadius.md),
  );

  /// The toned surface of a guess option and a match tile (screens 17 and
  /// 18): idle on the card ground, selected on the primary soft ground,
  /// right on the success soft ground and wrong on the danger soft ground,
  /// each tone but idle edged in its border at 1dp ("Flashcard Color Tokens"
  /// §6; a right outcome is success, never mastery — spec D14). The idle
  /// edge is its own ground, so a tile keeps one size in every tone.
  /// [isRecessed] gives an idle tile the answer face's low ground (Match's
  /// meanings, critique 2026-09-30 part 3c-2, R3).
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone, {
    bool isRecessed = false,
  }) {
    final idle = isRecessed ? scheme.surfaceContainerLow : semantic.cardSurface;
    final (Color fill, Color edge) = switch (tone) {
      StudyChoiceTone.idle => (idle, idle),
      StudyChoiceTone.selected => (semantic.primarySoft, scheme.primary),
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
    StudyChoiceTone.selected => semantic.onPrimarySoft,
    StudyChoiceTone.right => semantic.onSuccessSoft,
    StudyChoiceTone.wrong => semantic.onDangerSoft,
  };
}

/// The states of a study choice surface (screens 17 and 18).
enum StudyChoiceTone { idle, selected, right, wrong }
