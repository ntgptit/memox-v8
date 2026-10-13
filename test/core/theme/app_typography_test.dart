import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';

// (slot, size, weight, line height, letterSpacing) for the twelve roles of
// "Flashcard Color Tokens" §3.2; height is line / size.
final _roles =
    <
      String,
      (TextStyle? Function(TextTheme), double, FontWeight, double, double)
    >{
      'display-term → displaySmall': (
        (t) => t.displaySmall,
        24,
        FontWeight.w400,
        32,
        0,
      ),
      'term-tile → headlineSmall': (
        (t) => t.headlineSmall,
        20,
        FontWeight.w400,
        28,
        0,
      ),
      'display-stat → displayMedium': (
        (t) => t.displayMedium,
        28,
        FontWeight.w500,
        36,
        0,
      ),
      'title-section → titleLarge': (
        (t) => t.titleLarge,
        20,
        FontWeight.w600,
        28,
        0,
      ),
      'title-card → titleMedium': (
        (t) => t.titleMedium,
        18,
        FontWeight.w500,
        24,
        0.15,
      ),
      'title-item → titleSmall': (
        (t) => t.titleSmall,
        14,
        FontWeight.w500,
        20,
        0.1,
      ),
      'body-content → bodyLarge': (
        (t) => t.bodyLarge,
        16,
        FontWeight.w400,
        24,
        0,
      ),
      'body → bodyMedium': ((t) => t.bodyMedium, 14, FontWeight.w400, 20, 0.25),
      'body-tile → bodySmall': ((t) => t.bodySmall, 13, FontWeight.w400, 16, 0),
      'label-button → labelLarge': (
        (t) => t.labelLarge,
        14,
        FontWeight.w400,
        20,
        0.1,
      ),
      'label-meta → labelMedium': (
        (t) => t.labelMedium,
        14,
        FontWeight.w400,
        20,
        0.5,
      ),
      'label-nav → labelSmall': (
        (t) => t.labelSmall,
        12,
        FontWeight.w500,
        16,
        0.5,
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

  for (final MapEntry(key: name, value: (read, size, weight, line, spacing))
      in _roles.entries) {
    test(
      '$name is ${size.toInt()}/${line.toInt()}/${weight.value}/$spacing',
      () {
        final style = read(bound)!;
        expect(style.fontFamily, AppTypography.fontFamily);
        expect(style.fontFamilyFallback, AppTypography.fontFamilyFallback);
        expect(style.fontSize, size);
        expect(style.fontWeight, weight);
        expect(style.height, closeTo(line / size, 1e-9));
        expect(style.letterSpacing, spacing);
      },
    );
  }

  test('only the stat role uses tabular figures', () {
    expect(bound.displayMedium!.fontFeatures, const [
      FontFeature.tabularFigures(),
    ]);
    for (final MapEntry(key: name, value: (read, _, _, _, _))
        in _roles.entries) {
      if (name.endsWith('displayMedium')) continue;
      expect(read(bound)!.fontFeatures ?? const [], isEmpty, reason: name);
    }
  });

  test('every slot is in the family with its fallback', () {
    for (final style in _allSlots(bound)) {
      expect(style!.fontFamily, 'BeVietnamPro');
      expect(style.fontFamilyFallback, ['NotoSansKR']);
    }
  });

  test('nothing is below 12', () {
    for (final MapEntry(key: name, value: (read, _, _, _, _))
        in _roles.entries) {
      expect(read(bound)!.fontSize, greaterThanOrEqualTo(12), reason: name);
    }
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

  for (final asset in [
    'assets/fonts/BeVietnamPro-Regular.ttf',
    'assets/fonts/BeVietnamPro-Medium.ttf',
    'assets/fonts/BeVietnamPro-SemiBold.ttf',
    'assets/fonts/NotoSansKR-Variable.ttf',
  ]) {
    test('$asset is bundled', () async {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0));
    });
  }
}
