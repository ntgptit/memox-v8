import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
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

  testWidgets('tonal: the primary soft ground under its on-soft label; a 22 '
      'pill, 8 inset', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));

    expect(_pill(tester).color, semantic.primarySoft);
    expect(_pill(tester).borderRadius, BorderRadius.circular(999));
    expect(_ink(tester, '23 due'), semantic.onPrimarySoft);
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

  testWidgets('each tone sits on its soft ground with its on-soft label', (
    tester,
  ) async {
    for (final (tone, ground, foreground) in [
      (MxBadgeTone.mastery, semantic.successSoft, semantic.onSuccessSoft),
      (MxBadgeTone.danger, semantic.dangerSoft, semantic.onDangerSoft),
      (MxBadgeTone.neutral, semantic.neutralSoft, semantic.onNeutralSoft),
      (MxBadgeTone.warning, semantic.warningSoft, semantic.onWarningSoft),
    ]) {
      await pumpMx(tester, MxBadge(label: '4 due', tone: tone));

      expect(_pill(tester).color, ground);
      expect(_ink(tester, '4 due'), foreground);
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
    await pumpMx(tester, const MxBadge(label: '12345 due'));
    expect(tester.getSize(find.byType(MxBadge)).width, greaterThan(short));
    expect(tester.takeException(), isNull);
  });

  testWidgets('success: the success soft ground under its on-soft label, '
      'light in both themes (spec 2026-10-10 D4)', (tester) async {
    await pumpMx(
      tester,
      const MxBadge(label: 'Ready · 2', tone: MxBadgeTone.success),
    );
    expect(_pill(tester).color, semantic.successSoft);
    expect(_ink(tester, 'Ready · 2'), semantic.onSuccessSoft);

    final darkSemantic = MxSemanticColors.dark;
    await pumpMx(
      tester,
      const MxBadge(label: 'Ready · 2', tone: MxBadgeTone.success),
      brightness: Brightness.dark,
    );
    // The theme change animates.
    await tester.pumpAndSettle();
    expect(_pill(tester).color, darkSemantic.successSoft);
    expect(_ink(tester, 'Ready · 2'), darkSemantic.onSuccessSoft);
  });
}
