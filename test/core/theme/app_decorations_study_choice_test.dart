import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Screens 17 and 18's toned surface (FE-A6 P3, ruling C1: a right outcome is
// success, never mastery — spec D14).
void main() {
  final scheme = AppColorSchemes.light;
  final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);

  BoxDecoration of(StudyChoiceTone tone) =>
      AppDecorations.studyChoice(scheme, derived, tone);

  Color inkOf(StudyChoiceTone tone) =>
      AppDecorations.studyChoiceInk(scheme, derived, tone);

  test('each tone paints its ground and edge', () {
    expect(of(StudyChoiceTone.idle).color, scheme.surfaceContainerLowest);
    expect(
      (of(StudyChoiceTone.idle).border! as Border).top.color,
      derived.ghostBorder,
    );
    expect(of(StudyChoiceTone.selected).color, scheme.primary);
    expect(
      (of(StudyChoiceTone.right).border! as Border).top.color,
      derived.successBorder,
    );
    expect(
      (of(StudyChoiceTone.wrong).border! as Border).top.color,
      derived.dangerBorder,
    );
  });

  test('each tone has its ink; right is success, never mastery', () {
    expect(inkOf(StudyChoiceTone.idle), scheme.onSurface);
    expect(inkOf(StudyChoiceTone.selected), scheme.onPrimary);
    expect(inkOf(StudyChoiceTone.right), derived.successInk);
    expect(inkOf(StudyChoiceTone.right), isNot(MxSemanticColors.light.mastery));
    expect(inkOf(StudyChoiceTone.wrong), scheme.error);
  });
}
