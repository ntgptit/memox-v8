import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    Color? edge(BoxDecoration d) => (d.border as Border?)?.top.color;
    BoxDecoration tone(StudyChoiceTone t, {bool isRecessed = false}) =>
        AppDecorations.studyChoice(scheme, semantic, t, isRecessed: isRecessed);
    Color ink(StudyChoiceTone t) =>
        AppDecorations.studyChoiceInk(scheme, semantic, t);

    test('$name idle: raised or recessed ground with the outline edge', () {
      expect(tone(StudyChoiceTone.idle).color, scheme.surfaceContainerLowest);
      expect(edge(tone(StudyChoiceTone.idle)), scheme.outline);
      expect(
        tone(StudyChoiceTone.idle, isRecessed: true).color,
        scheme.surfaceContainerLow,
      );
      expect(ink(StudyChoiceTone.idle), scheme.onSurface);
    });

    test('$name selected: primary on primary, onPrimary ink', () {
      expect(tone(StudyChoiceTone.selected).color, scheme.primary);
      expect(ink(StudyChoiceTone.selected), scheme.onPrimary);
    });

    test('$name right / wrong: containers, no edge, on-container ink', () {
      expect(tone(StudyChoiceTone.right).color, semantic.successContainer);
      expect(edge(tone(StudyChoiceTone.right)), null);
      expect(ink(StudyChoiceTone.right), semantic.onSuccessContainer);
      expect(tone(StudyChoiceTone.wrong).color, scheme.errorContainer);
      expect(edge(tone(StudyChoiceTone.wrong)), null);
      expect(ink(StudyChoiceTone.wrong), scheme.onErrorContainer);
    });
  }
}
