import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Every MxSemanticColors token ("Flashcard Color Tokens" §2), light then dark.
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'mastery': ((c) => c.mastery, 0xFF17AE79, 0xFF17AE79),
  'onMastery': ((c) => c.onMastery, 0xFF003925, 0xFF003925),
  'success': ((c) => c.success, 0xFF006C49, 0xFF5ADDA4),
  'warning': ((c) => c.warning, 0xFFF59E0B, 0xFFF59E0B),
  'onWarning': ((c) => c.onWarning, 0xFF613B00, 0xFF613B00),
  'statusNew': ((c) => c.statusNew, 0xFF6C7794, 0xFF8590AE),
  'statusLearning': ((c) => c.statusLearning, 0xFFF59E0B, 0xFFF59E0B),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF564BCB, 0xFFC5C0FF),
  'statusMastered': ((c) => c.statusMastered, 0xFF17AE79, 0xFF17AE79),
  'errorFill': ((c) => c.errorFill, 0xFFBA1A1A, 0xFFFFB4AB),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFF690005),
  'streak': ((c) => c.streak, 0xFFF59E0B, 0xFFF59E0B),
  'primaryText': ((c) => c.primaryText, 0xFF564BCB, 0xFFC5C0FF),
  'masteryText': ((c) => c.masteryText, 0xFF006C49, 0xFF5ADDA4),
  'learningText': ((c) => c.learningText, 0xFF855300, 0xFFFFC174),
  'warningText': ((c) => c.warningText, 0xFF855300, 0xFFFFC174),
  'focusRing': ((c) => c.focusRing, 0xFF564BCB, 0xFF564BCB),
  'border': ((c) => c.border, 0xFFBBC6E6, 0xFF3B4661),
  'primaryTrack': ((c) => c.primaryTrack, 0xFF564BCB, 0xFF564BCB),
  'neutralTrack': ((c) => c.neutralTrack, 0xFFE8E8E8, 0xFF2D2C51),
  'primarySoft': ((c) => c.primarySoft, 0xFFE4E2F7, 0xFF28254F),
  'onPrimarySoft': ((c) => c.onPrimarySoft, 0xFF564BCB, 0xFFC5C0FF),
  'successSoft': ((c) => c.successSoft, 0xFFD6E7E2, 0xFF172A40),
  'successBorder': ((c) => c.successBorder, 0xFF006C49, 0xFF5ADDA4),
  'onSuccessSoft': ((c) => c.onSuccessSoft, 0xFF006C49, 0xFF5ADDA4),
  'learningSoft': ((c) => c.learningSoft, 0xFFEBE3D6, 0xFF312638),
  'learningBorder': ((c) => c.learningBorder, 0xFF855300, 0xFFFFC174),
  'onLearningSoft': ((c) => c.onLearningSoft, 0xFF855300, 0xFFFFC174),
  'warningSoft': ((c) => c.warningSoft, 0xFFEBE3D6, 0xFF312638),
  'warningBorder': ((c) => c.warningBorder, 0xFF855300, 0xFFFFC174),
  'onWarningSoft': ((c) => c.onWarningSoft, 0xFF855300, 0xFFFFC174),
  'dangerSoft': ((c) => c.dangerSoft, 0xFFF4DADA, 0xFF312441),
  'dangerBorder': ((c) => c.dangerBorder, 0xFFBA1A1A, 0xFFFFB4AB),
  'onDangerSoft': ((c) => c.onDangerSoft, 0xFFBA1A1A, 0xFFFFB4AB),
  'neutralSoft': ((c) => c.neutralSoft, 0xFFD1DCFD, 0xFF3B4661),
  'onNeutralSoft': ((c) => c.onNeutralSoft, 0xFF55607C, 0xFFAAB5D4),
  'onSoft': ((c) => c.onSoft, 0xFF1C1B21, 0xFFE5E1E9),
  // §2.2.
  'cardSurface': ((c) => c.cardSurface, 0xFFF1F1FB, 0xFF222145),
  'searchSurface': ((c) => c.searchSurface, 0xFFF1F1FB, 0xFF222145),
  'tileSurface': ((c) => c.tileSurface, 0xFFEDF8FF, 0xFF2E3953),
  'divider': ((c) => c.divider, 0xFFEEEEEE, 0xFF18173B),
  'info': ((c) => c.info, 0xFF006684, 0xFFA9E3FF),
  'infoContainer': ((c) => c.infoContainer, 0xFF50CCFC, 0xFF50CCFC),
  'onInfoContainer': ((c) => c.onInfoContainer, 0xFF00546D, 0xFF00546D),
};

void main() {
  for (final MapEntry(key: name, value: (read, light, dark))
      in _expected.entries) {
    test('$name is the spec value in both themes', () {
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
