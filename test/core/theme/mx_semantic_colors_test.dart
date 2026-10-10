import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Every MxSemanticColors token (spec 2026-10-10 §5), Day then Night.
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'mastery': ((c) => c.mastery, 0xFF18AE79, 0xFF18AE79),
  'onMastery': ((c) => c.onMastery, 0xFFFFFFFF, 0xFFFFFFFF),
  'success': ((c) => c.success, 0xFF12815A, 0xFF59E8B5),
  'warning': ((c) => c.warning, 0xFFFFCD1F, 0xFFFFCD1F),
  'onWarning': ((c) => c.onWarning, 0xFF282E3E, 0xFF282E3E),
  'statusNew': ((c) => c.statusNew, 0xFF939BB4, 0xFF586380),
  'statusLearning': ((c) => c.statusLearning, 0xFFFF983A, 0xFFFF983A),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF4255FF, 0xFF4255FF),
  'statusMastered': ((c) => c.statusMastered, 0xFF18AE79, 0xFF18AE79),
  'errorFill': ((c) => c.errorFill, 0xFFB00020, 0xFFB00020),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF),
  'streak': ((c) => c.streak, 0xFFF6406C, 0xFFF6406C),
  'primaryText': ((c) => c.primaryText, 0xFF4255FF, 0xFF7583FF),
  'masteryText': ((c) => c.masteryText, 0xFF12815A, 0xFF59E8B5),
  'learningText': ((c) => c.learningText, 0xFFCC4E00, 0xFFFF983A),
  'warningText': ((c) => c.warningText, 0xFF997700, 0xFFFFCD1F),
  'focusRing': ((c) => c.focusRing, 0xFFA8B1FF, 0xFFA8B1FF),
  'border': ((c) => c.border, 0xFFEDEFF4, 0xFF282E3E),
  'primaryTrack': ((c) => c.primaryTrack, 0xFFDBDFFF, 0xFFDBDFFF),
  'neutralTrack': ((c) => c.neutralTrack, 0xFF939BB4, 0xFF939BB4),
  'primarySoft': ((c) => c.primarySoft, 0xFFEDEFFF, 0xFFEDEFFF),
  'onPrimarySoft': ((c) => c.onPrimarySoft, 0xFF4255FF, 0xFF4255FF),
  'successSoft': ((c) => c.successSoft, 0xFFE6FCF4, 0xFFE6FCF4),
  'successBorder': ((c) => c.successBorder, 0xFF98F1D1, 0xFF98F1D1),
  'onSuccessSoft': ((c) => c.onSuccessSoft, 0xFF12815A, 0xFF12815A),
  'learningSoft': ((c) => c.learningSoft, 0xFFFFF6EF, 0xFFFFF6EF),
  'learningBorder': ((c) => c.learningBorder, 0xFFFFC38C, 0xFFFFC38C),
  'onLearningSoft': ((c) => c.onLearningSoft, 0xFFCC4E00, 0xFFCC4E00),
  'warningSoft': ((c) => c.warningSoft, 0xFFFFEDAB, 0xFFFFEDAB),
  'warningBorder': ((c) => c.warningBorder, 0xFFFFDC62, 0xFFFFDC62),
  'onWarningSoft': ((c) => c.onWarningSoft, 0xFF997700, 0xFF997700),
  'dangerSoft': ((c) => c.dangerSoft, 0xFFFFE8D8, 0xFFFFE8D8),
  'dangerBorder': ((c) => c.dangerBorder, 0xFFFFC38C, 0xFFFFC38C),
  'onDangerSoft': ((c) => c.onDangerSoft, 0xFFB00020, 0xFFB00020),
  'neutralSoft': ((c) => c.neutralSoft, 0xFFEDEFFF, 0xFF586380),
  'onNeutralSoft': ((c) => c.onNeutralSoft, 0xFF2E3856, 0xFFF6F7FB),
  'onSoft': ((c) => c.onSoft, 0xFF282E3E, 0xFF282E3E),
};

void main() {
  for (final MapEntry(key: name, value: (read, light, dark))
      in _expected.entries) {
    test('$name is the Indigo value in both themes', () {
      expect(read(MxSemanticColors.light).toARGB32(), light);
      expect(read(MxSemanticColors.dark).toARGB32(), dark);
    });
  }

  test('copyWith replaces only the named field', () {
    const replacement = Color(0xFF000001);
    final copy = MxSemanticColors.light.copyWith(mastery: replacement);

    expect(copy.mastery, replacement);
    expect(copy.warning, MxSemanticColors.light.warning);
    expect(copy.onErrorFill, MxSemanticColors.light.onErrorFill);
    expect(copy.primaryText, MxSemanticColors.light.primaryText);
  });

  test('lerp reaches each end and blends in between', () {
    const light = MxSemanticColors.light;
    const dark = MxSemanticColors.dark;

    expect(light.lerp(dark, 0).mastery, light.mastery);
    expect(light.lerp(dark, 1).mastery, dark.mastery);
    expect(
      light.lerp(dark, 0.5).statusNew,
      Color.lerp(light.statusNew, dark.statusNew, 0.5),
    );
  });

  test('lerp against a foreign extension keeps this one', () {
    expect(MxSemanticColors.light.lerp(null, 0.5), MxSemanticColors.light);
  });
}
