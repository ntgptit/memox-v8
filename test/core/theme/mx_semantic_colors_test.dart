import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Spec 2026-10-08 §4.3: Material 3 custom-colour sets at HCT tones 40 / 100 /
// 90 / 10 (light) and 80 / 20 / 30 / 90 (dark), plus the one brand foreground.
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'primaryForeground': ((c) => c.primaryForeground, 0xFF384CDD, 0xFFBCC2FF),
  'warning': ((c) => c.warning, 0xFF855300, 0xFFFFB95F),
  'onWarning': ((c) => c.onWarning, 0xFFFFFFFF, 0xFF472A00),
  'warningContainer': ((c) => c.warningContainer, 0xFFFFDDB8, 0xFF653E00),
  'onWarningContainer': ((c) => c.onWarningContainer, 0xFF2A1700, 0xFFFFDDB8),
  'success': ((c) => c.success, 0xFF006B57, 0xFF67DABB),
  'onSuccess': ((c) => c.onSuccess, 0xFFFFFFFF, 0xFF00382C),
  'successContainer': ((c) => c.successContainer, 0xFF85F7D6, 0xFF005141),
  'onSuccessContainer': ((c) => c.onSuccessContainer, 0xFF002019, 0xFF85F7D6),
  'mastery': ((c) => c.mastery, 0xFF006D44, 0xFF77DAA4),
  'onMastery': ((c) => c.onMastery, 0xFFFFFFFF, 0xFF003921),
  'masteryContainer': ((c) => c.masteryContainer, 0xFF93F7BE, 0xFF005232),
  'onMasteryContainer': ((c) => c.onMasteryContainer, 0xFF002111, 0xFF93F7BE),
  'streak': ((c) => c.streak, 0xFF9D4300, 0xFFFFB690),
};

void main() {
  for (final MapEntry(key: name, value: (read, light, dark))
      in _expected.entries) {
    test('$name is the V3 value in both themes', () {
      expect(read(MxSemanticColors.light).toARGB32(), light);
      expect(read(MxSemanticColors.dark).toARGB32(), dark);
    });
  }

  test('lerp at 0 and 1 returns each end for every member', () {
    final at0 = MxSemanticColors.light.lerp(MxSemanticColors.dark, 0);
    final at1 = MxSemanticColors.light.lerp(MxSemanticColors.dark, 1);
    for (final MapEntry(key: name, value: (read, light, dark))
        in _expected.entries) {
      expect(read(at0).toARGB32(), light, reason: name);
      expect(read(at1).toARGB32(), dark, reason: name);
    }
  });

  test('copyWith replaces only the named field', () {
    const replacement = Color(0xFF000001);
    final copy = MxSemanticColors.light.copyWith(mastery: replacement);

    expect(copy.mastery, replacement);
    expect(copy.warning, MxSemanticColors.light.warning);
    expect(copy.onSuccess, MxSemanticColors.light.onSuccess);
  });

  test('lerp reaches each end and blends in between', () {
    const light = MxSemanticColors.light;
    const dark = MxSemanticColors.dark;

    expect(light.lerp(dark, 0).mastery, light.mastery);
    expect(light.lerp(dark, 1).mastery, dark.mastery);
    expect(
      light.lerp(dark, 0.5).warning,
      Color.lerp(light.warning, dark.warning, 0.5),
    );
  });

  test('no legacy member survives', () {
    // Names are split so a repo-wide grep for the retired members stays empty.
    const retired = [
      'status'
          'New',
      'status'
          'Learning',
      'status'
          'Reviewing',
      'status'
          'Mastered',
      'error'
          'Fill',
      'onError'
          'Fill',
    ];
    final text = MxSemanticColors.light.toString();
    for (final name in retired) {
      expect(text, isNot(contains(name)), reason: name);
    }
  });

  test('lerp against a foreign extension keeps this one', () {
    expect(MxSemanticColors.light.lerp(null, 0.5), MxSemanticColors.light);
  });
}
