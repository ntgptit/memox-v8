import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final scale = AppTypography.build(appLightColors);
  final roles = MxTextRoles(scale);
  final named = <String, TextStyle>{
    'figure': roles.figure,
    'term': roles.term,
    'termCompact': roles.termCompact,
    'screenTitle': roles.screenTitle,
    'sectionTitle': roles.sectionTitle,
    'itemTitle': roles.itemTitle,
    'content': roles.content,
    'body': roles.body,
    'caption': roles.caption,
    'button': roles.button,
    'label': roles.label,
    'meta': roles.meta,
  };
  final steps = [
    scale.body.xs3,
    scale.body.xs2,
    scale.body.xs,
    scale.body.sm,
    scale.body.md,
    scale.body.lg,
    scale.body.xl,
    scale.body.xl2,
  ];

  test('the scale is scale A in Be Vietnam Pro, Noto Sans KR behind it', () {
    expect(
      [for (final step in steps) step.fontSize],
      [10, 12, 13, 15, 16, 18, 20, 26],
    );
    for (final step in steps) {
      expect(step.fontFamily, 'BeVietnamPro');
      expect(step.fontFamilyFallback, ['NotoSansKR']);
      expect(step.color, appLightColors.foreground);
    }
  });

  test('a text step keeps a line height that does not clip stacked '
      'Vietnamese diacritics', () {
    for (final step in steps) {
      final minimum = step.fontSize! <= 16 ? 1.5 : 1.3;
      expect(step.height, greaterThanOrEqualTo(minimum), reason: '$step');
    }
  });

  for (final MapEntry(key: name, value: style) in named.entries) {
    test('$name is a step of the scale at a bundled weight, its wght axis '
        'moved with it', () {
      expect(
        steps.map((step) => step.fontSize),
        contains(style.fontSize),
        reason: name,
      );
      final weight = style.fontWeight!;
      expect([
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
      ], contains(weight));
      expect(style.fontVariations, [
        FontVariation.weight(weight.value.toDouble()),
      ]);
    });
  }

  test('only the figure role uses tabular figures', () {
    for (final MapEntry(key: name, value: style) in named.entries) {
      final isTabular =
          style.fontFeatures?.contains(const FontFeature.tabularFigures()) ??
          false;
      expect(isTabular, name == 'figure', reason: name);
    }
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
