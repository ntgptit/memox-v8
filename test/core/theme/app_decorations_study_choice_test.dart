import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Screens 17 and 18's toned surface (FE-A6 P3, ruling C1: a right outcome is
// success, never mastery — spec D14).
void main() {
  for (final (theme, scheme, semantic) in [
    ('Day', AppColorSchemes.light, MxSemanticColors.light),
    ('Night', AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    BoxDecoration of(StudyChoiceTone tone) =>
        AppDecorations.studyChoice(scheme, semantic, tone);

    Color foregroundOf(StudyChoiceTone tone) =>
        AppDecorations.studyChoiceForeground(scheme, semantic, tone);

    Color edgeOf(StudyChoiceTone tone) =>
        (of(tone).border! as Border).top.color;

    test('each tone paints its ground and edge in $theme', () {
      expect(of(StudyChoiceTone.idle).color, scheme.surfaceContainerLowest);
      expect(edgeOf(StudyChoiceTone.idle), semantic.border);
      expect(
        AppDecorations.studyChoice(
          scheme,
          semantic,
          StudyChoiceTone.idle,
          isRecessed: true,
        ).color,
        scheme.surfaceContainerLow,
      );
      expect(of(StudyChoiceTone.selected).color, scheme.primary);
      expect(of(StudyChoiceTone.right).color, semantic.successSoft);
      expect(edgeOf(StudyChoiceTone.right), semantic.successBorder);
      expect(of(StudyChoiceTone.wrong).color, semantic.dangerSoft);
      expect(edgeOf(StudyChoiceTone.wrong), semantic.dangerBorder);
    });

    test('each tone has its foreground in $theme; right is success, never '
        'mastery', () {
      expect(foregroundOf(StudyChoiceTone.idle), scheme.onSurface);
      expect(foregroundOf(StudyChoiceTone.selected), scheme.onPrimary);
      expect(foregroundOf(StudyChoiceTone.right), semantic.onSuccessSoft);
      expect(foregroundOf(StudyChoiceTone.right), isNot(semantic.mastery));
      expect(foregroundOf(StudyChoiceTone.wrong), semantic.onDangerSoft);
    });
  }
}
