import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Screens 17 and 18's toned surface ("Flashcard Color Tokens" §6; FE-A6 P3,
// ruling C1: a right outcome is success, never mastery — spec D14).
void main() {
  for (final (theme, scheme, semantic) in [
    ('light', AppColorSchemes.light, MxSemanticColors.light),
    ('dark', AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    BoxDecoration of(StudyChoiceTone tone) =>
        AppDecorations.studyChoice(scheme, semantic, tone);

    Color foregroundOf(StudyChoiceTone tone) =>
        AppDecorations.studyChoiceForeground(scheme, semantic, tone);

    Color edgeOf(StudyChoiceTone tone) =>
        (of(tone).border! as Border).top.color;

    test('each tone paints its ground and edge in $theme', () {
      expect(of(StudyChoiceTone.idle).color, semantic.cardSurface);
      // The idle edge is its own ground: the tile keeps one size in every
      // tone and shows no edge.
      expect(edgeOf(StudyChoiceTone.idle), semantic.cardSurface);
      final recessed = AppDecorations.studyChoice(
        scheme,
        semantic,
        StudyChoiceTone.idle,
        isRecessed: true,
      );
      expect(recessed.color, scheme.surfaceContainerLow);
      expect((recessed.border! as Border).top.color, recessed.color);
      expect(of(StudyChoiceTone.selected).color, semantic.primarySoft);
      expect(edgeOf(StudyChoiceTone.selected), scheme.primary);
      expect(of(StudyChoiceTone.right).color, semantic.successSoft);
      expect(edgeOf(StudyChoiceTone.right), semantic.successBorder);
      expect(of(StudyChoiceTone.wrong).color, semantic.dangerSoft);
      expect(edgeOf(StudyChoiceTone.wrong), semantic.dangerBorder);
    });

    test('each tone has its foreground in $theme; right is success, never '
        'mastery', () {
      expect(foregroundOf(StudyChoiceTone.idle), scheme.onSurface);
      expect(foregroundOf(StudyChoiceTone.selected), semantic.onPrimarySoft);
      expect(foregroundOf(StudyChoiceTone.right), semantic.onSuccessSoft);
      expect(foregroundOf(StudyChoiceTone.right), isNot(semantic.mastery));
      expect(foregroundOf(StudyChoiceTone.wrong), semantic.onDangerSoft);
    });
  }
}
