import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/text_theme.g.dart';

import 'token_source.dart';

final _slotPattern = RegExp(r'\(Flutter (\w+)\)');

TextStyle? _slot(TextTheme theme, String name) => switch (name) {
  'displayMedium' => theme.displayMedium,
  'displaySmall' => theme.displaySmall,
  'headlineSmall' => theme.headlineSmall,
  'titleLarge' => theme.titleLarge,
  'titleMedium' => theme.titleMedium,
  'titleSmall' => theme.titleSmall,
  'bodyLarge' => theme.bodyLarge,
  'bodyMedium' => theme.bodyMedium,
  'bodySmall' => theme.bodySmall,
  'labelLarge' => theme.labelLarge,
  'labelMedium' => theme.labelMedium,
  'labelSmall' => theme.labelSmall,
  _ => throw ArgumentError(name),
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
]; // fmt: skip

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bound = AppTypography.bind(
    Typography.material2021(platform: TargetPlatform.android).englishLike,
  );
  final groups = ((tokensJson['type'] as Map)['groups'] as List)
      .cast<Map<String, dynamic>>();
  final styles = [
    for (final group in groups)
      ...(group['styles'] as List).cast<Map<String, dynamic>>(),
  ];

  test('the JSON defines twelve roles', () => expect(styles, hasLength(12)));

  for (final style in styles) {
    final slot = _slotPattern.firstMatch(style['usage'] as String)!.group(1)!;
    test('${style['name']} is bound to $slot exactly', () {
      final actual = _slot(bound, slot)!;
      final size = tokenNumber(style['fontSize'] as String);
      final line = tokenNumber(style['lineHeight'] as String);
      expect(actual.fontSize, size);
      expect(actual.height, closeTo(line / size, 1e-9));
      expect(
        actual.fontWeight,
        FontWeight.values[(style['fontWeight'] as int) ~/ 100 - 1],
      );
      expect(
        actual.letterSpacing,
        tokenNumber(style['letterSpacing'] as String),
      );
      expect(actual.fontFamily, kFontFamily);
      expect(actual.fontFamilyFallback, kFontFamilyFallback);
    });
  }

  test('the family and its fallback are the first two of the JSON stack', () {
    final stack =
        ((tokensJson['type'] as Map)['families'] as Map)['sans'] as String;
    expect(stack, startsWith('"Be Vietnam Pro", "Noto Sans KR"'));
    expect(kFontFamily, 'BeVietnamPro');
    expect(kFontFamilyFallback, ['NotoSansKR']);
  });

  test('only the stat role uses tabular figures', () {
    expect(
      bound.displayMedium!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(bound.bodyMedium!.fontFeatures, isNull);
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
    'BeVietnamPro-Regular.ttf',
    'BeVietnamPro-Medium.ttf',
    'BeVietnamPro-SemiBold.ttf',
    'NotoSansKR-Variable.ttf',
  ]) {
    test('the font asset $asset is bundled', () async {
      final data = await rootBundle.load('assets/fonts/$asset');
      expect(data.lengthInBytes, greaterThan(0));
    });
  }
}
