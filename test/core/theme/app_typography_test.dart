import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';

// (slot, size, weight, height, letterSpacing) for the seven V3 roles.
final _roles =
    <
      String,
      (TextStyle? Function(TextTheme), double, FontWeight, double, double)
    >{
      'stat → displayMedium': (
        (t) => t.displayMedium,
        40,
        FontWeight.w600,
        1.0,
        -0.64,
      ),
      'display → displaySmall': (
        (t) => t.displaySmall,
        32,
        FontWeight.w800,
        1.1,
        -0.64,
      ),
      'headline → headlineSmall': (
        (t) => t.headlineSmall,
        24,
        FontWeight.w700,
        1.2,
        -0.64,
      ),
      'title → titleLarge': (
        (t) => t.titleLarge,
        20,
        FontWeight.w700,
        1.2,
        -0.64,
      ),
      'body large → bodyLarge': (
        (t) => t.bodyLarge,
        16,
        FontWeight.w500,
        1.5,
        0,
      ),
      'body → bodyMedium': ((t) => t.bodyMedium, 14, FontWeight.w400, 1.5, 0),
      'caption → labelSmall': (
        (t) => t.labelSmall,
        12,
        FontWeight.w600,
        1.4,
        0,
      ),
    };

List<TextStyle?> _allSlots(TextTheme t) => [
  t.displayLarge,
  t.displayMedium,
  t.displaySmall,
  t.headlineLarge,
  t.headlineMedium,
  t.headlineSmall,
  t.titleLarge,
  t.titleMedium,
  t.titleSmall,
  t.bodyLarge,
  t.bodyMedium,
  t.bodySmall,
  t.labelLarge,
  t.labelMedium,
  t.labelSmall,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bound = AppTypography.bind(
    Typography.material2021(platform: TargetPlatform.android).englishLike,
  );

  for (final MapEntry(key: name, value: (read, size, weight, height, spacing))
      in _roles.entries) {
    test('$name is ${size.toInt()}/${weight.value}/$height/$spacing', () {
      final style = read(bound)!;
      expect(style.fontFamily, AppTypography.fontFamily);
      expect(style.fontSize, size);
      expect(style.fontWeight, weight);
      expect(style.height, height);
      expect(style.letterSpacing, spacing);
    });
  }

  test('the stat role uses tabular figures', () {
    expect(
      bound.displayMedium!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('every slot moves the wght axis with its weight', () {
    for (final style in _allSlots(bound)) {
      final weight = style!.fontWeight ?? FontWeight.w400;
      expect(
        style.fontVariations,
        contains(FontVariation.weight(weight.value.toDouble())),
        reason: '$style',
      );
    }
  });

  test('withWeight sets fontWeight and the wght axis together', () {
    final style = AppTypography.withWeight(const TextStyle(), FontWeight.w700);

    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontVariations, [const FontVariation.weight(700)]);
  });

  test('the font asset is bundled', () async {
    final data = await rootBundle.load(
      'assets/fonts/PlusJakartaSans-Variable.ttf',
    );
    expect(data.lengthInBytes, greaterThan(0));
  });
}
