import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// The nine BIND_NOW MEMOX_SEMANTIC_COLOR entries, light then dark.
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'mastery': ((c) => c.mastery, 0xFF1F8A5B, 0xFF6FE0BD),
  'warning': ((c) => c.warning, 0xFFF59E0B, 0xFFFFC658),
  'onWarning': ((c) => c.onWarning, 0xFF3A2A00, 0xFF2A1E00),
  'statusNew': ((c) => c.statusNew, 0xFF8C95B8, 0xFF6B75A3),
  'statusLearning': ((c) => c.statusLearning, 0xFFF59E0B, 0xFFFFC658),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF5265F5, 0xFF8B9AFF),
  'statusMastered': ((c) => c.statusMastered, 0xFF1F8A5B, 0xFF6FE0BD),
  'errorFill': ((c) => c.errorFill, 0xFFDC2D4E, 0xFFB0485C),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF),
};

void main() {
  for (final MapEntry(key: name, value: (read, light, dark))
      in _expected.entries) {
    test('$name is the V3 value in both themes', () {
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

  test('streak is the kit accent in both themes (E-O2)', () {
    expect(MxSemanticColors.light.streak, const Color(0xFFF97316));
    expect(MxSemanticColors.dark.streak, const Color(0xFFFFAE6E));
    expect(MxSemanticColors.light.onStreak, const Color(0xFFFFFFFF));
    expect(MxSemanticColors.dark.onStreak, const Color(0xFFFFFFFF));
  });
}
