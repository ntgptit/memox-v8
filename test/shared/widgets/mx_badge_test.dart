import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../support/widget_harness.dart';

BoxDecoration _pill(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxBadge),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

Color? _ink(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(scheme, semantic);

  testWidgets('tonal: tone @12% under a tone label; a 22 pill, 8 inset', (
    tester,
  ) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));

    expect(_pill(tester).color, scheme.primary.withValues(alpha: 0.12));
    expect(_pill(tester).borderRadius, BorderRadius.circular(999));
    expect(_ink(tester, '23 due'), scheme.primary);
    expect(tester.getSize(find.byType(MxBadge)).height, 22);
    expect(
      tester.getTopLeft(find.text('23 due')).dx -
          tester.getTopLeft(find.byType(MxBadge)).dx,
      8,
    );
  });

  testWidgets('solid: tone fill under an onPrimary label', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due', isSolid: true));

    expect(_pill(tester).color, scheme.primary);
    expect(_ink(tester, '23 due'), scheme.onPrimary);
  });

  testWidgets('each tone; a tonal warning reads in warning-ink (S3)', (
    tester,
  ) async {
    for (final (tone, fill, ink) in [
      (MxBadgeTone.mastery, semantic.mastery, semantic.mastery),
      (MxBadgeTone.danger, scheme.error, scheme.error),
      (MxBadgeTone.neutral, scheme.onSurfaceVariant, scheme.onSurfaceVariant),
      (MxBadgeTone.warning, semantic.warning, derived.warningInk),
    ]) {
      await pumpMx(tester, MxBadge(label: '4 due', tone: tone));

      expect(_pill(tester).color, fill.withValues(alpha: 0.12));
      expect(_ink(tester, '4 due'), ink);
    }
  });

  testWidgets('a 12 glyph 4 before the label; the pill grows, never clips', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxBadge(label: '12 ready', icon: AppIcons.check),
    );
    final glyph = tester.getRect(find.byIcon(AppIcons.check));
    expect(glyph.size, const Size.square(12));
    expect(glyph.left - tester.getTopLeft(find.byType(MxBadge)).dx, 8);
    expect(tester.getTopLeft(find.text('12 ready')).dx - glyph.right, 4);

    await pumpMx(tester, const MxBadge(label: '1 due'));
    final short = tester.getSize(find.byType(MxBadge)).width;
    await pumpMx(tester, const MxBadge(label: '12345 due'), textScale: 2);
    expect(tester.getSize(find.byType(MxBadge)).width, greaterThan(short));
    expect(tester.getSize(find.byType(MxBadge)).height, greaterThan(22));
    expect(tester.takeException(), isNull);
  });
}
