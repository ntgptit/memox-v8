import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

ShapeDecoration _pill(WidgetTester tester) =>
    paintedDecoration(tester, find.byType(MxBadge));

Color? _ink(WidgetTester tester, String label) =>
    textColor(tester, find.text(label));

void main() {
  final colors = appLightColors;
  const mx = MxStatusColors.light;

  testWidgets(
    'tonal: the tone tinted over the surface under a tone label; a 22 pill, 8 inset',
    (tester) async {
      await pumpMx(tester, const MxBadge(label: '23 due'));

      expect(_pill(tester).color, colors.primary.tintOver(colors.background));
      expect(
        _pill(tester).shape,
        RoundedSuperellipseBorder(
          borderRadius: forUiTheme(
            tester,
            find.byType(MxBadge),
          ).style.borderRadius.pill,
        ),
      );
      expect(_ink(tester, '23 due'), colors.primary);
      expect(tester.getSize(find.byType(MxBadge)).height, 22);
      expect(
        tester.getTopLeft(find.text('23 due')).dx -
            tester.getTopLeft(find.byType(MxBadge)).dx,
        8,
      );
    },
  );

  testWidgets('solid: tone fill under an onPrimary label', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due', isSolid: true));

    expect(_pill(tester).color, colors.primary);
    expect(_ink(tester, '23 due'), colors.primaryForeground);
  });

  testWidgets('each tone; a tonal warning reads in warning text colour (S3), a '
      'tonal mastery in the mastered ink (FE-C1)', (tester) async {
    for (final (tone, fill, ink) in [
      (MxBadgeTone.mastery, mx.successFill, mx.success),
      (MxBadgeTone.danger, colors.error, colors.error),
      (MxBadgeTone.neutral, colors.mutedForeground, colors.mutedForeground),
      (MxBadgeTone.warning, mx.warningFill, mx.warning),
    ]) {
      await pumpMx(tester, MxBadge(label: '4 due', tone: tone));

      expect(_pill(tester).color, fill.tintOver(colors.background));
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
    await pumpMx(tester, const MxBadge(label: '12345 due'));
    expect(tester.getSize(find.byType(MxBadge)).width, greaterThan(short));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'success: the success tint under a success text colour label, in both '
    'themes (critique 2026-09-30 tone pass, T6)',
    (tester) async {
      await pumpMx(
        tester,
        const MxBadge(label: 'Ready · 2', tone: MxBadgeTone.success),
      );
      expect(_pill(tester).color, mx.success.tintOver(colors.background));
      expect(_ink(tester, 'Ready · 2'), mx.success);

      const darkSemantic = MxStatusColors.dark;
      await pumpMx(
        tester,
        const MxBadge(label: 'Ready · 2', tone: MxBadgeTone.success),
        brightness: Brightness.dark,
      );
      // The theme change animates.
      await tester.pumpAndSettle();
      expect(
        _pill(tester).color,
        darkSemantic.success.tintOver(appDarkColors.background),
      );
      expect(_ink(tester, 'Ready · 2'), darkSemantic.success);
    },
  );
}
