import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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

  testWidgets('tonal: primaryContainer under onPrimaryContainer; a 22 pill, '
      '8 inset', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));

    expect(_pill(tester).color, scheme.primaryContainer);
    expect(_pill(tester).borderRadius, BorderRadius.circular(999));
    expect(_ink(tester, '23 due'), scheme.onPrimaryContainer);
    expect(tester.getSize(find.byType(MxBadge)).height, 22);
    expect(
      tester.getTopLeft(find.text('23 due')).dx -
          tester.getTopLeft(find.byType(MxBadge)).dx,
      8,
    );
  });

  for (final brightness in Brightness.values) {
    final isLight = brightness == Brightness.light;
    final colors = isLight ? AppColorSchemes.light : AppColorSchemes.dark;
    final semantic = isLight ? MxSemanticColors.light : MxSemanticColors.dark;
    // Per tone: (tonal ground, tonal label), (solid fill, solid label).
    final roles = <MxBadgeTone, ((Color, Color), (Color, Color))>{
      MxBadgeTone.primary: (
        (colors.primaryContainer, colors.onPrimaryContainer),
        (colors.primary, colors.onPrimary),
      ),
      MxBadgeTone.mastery: (
        (semantic.masteryContainer, semantic.onMasteryContainer),
        (semantic.mastery, semantic.onMastery),
      ),
      MxBadgeTone.success: (
        (semantic.successContainer, semantic.onSuccessContainer),
        (semantic.success, semantic.onSuccess),
      ),
      MxBadgeTone.warning: (
        (semantic.warningContainer, semantic.onWarningContainer),
        (semantic.warning, semantic.onWarning),
      ),
      MxBadgeTone.danger: (
        (colors.errorContainer, colors.onErrorContainer),
        (colors.error, colors.onError),
      ),
      MxBadgeTone.neutral: (
        (colors.surfaceContainerHigh, colors.onSurfaceVariant),
        (colors.onSurfaceVariant, colors.surface),
      ),
    };
    for (final MapEntry(key: tone, value: (tonal, solid)) in roles.entries) {
      for (final isSolid in [false, true]) {
        final (fill, ink) = isSolid ? solid : tonal;
        testWidgets('${tone.name} ${isSolid ? 'solid' : 'tonal'}, '
            '${brightness.name}: the role pair', (tester) async {
          await pumpMx(
            tester,
            MxBadge(label: '4 due', tone: tone, isSolid: isSolid),
            brightness: brightness,
          );
          // The theme change animates.
          await tester.pumpAndSettle();

          expect(_pill(tester).color, fill);
          expect(_ink(tester, '4 due'), ink);
        });
      }
    }
  }

  for (final brightness in Brightness.values) {
    final isLight = brightness == Brightness.light;
    final colors = isLight ? AppColorSchemes.light : AppColorSchemes.dark;
    final semantic = isLight ? MxSemanticColors.light : MxSemanticColors.dark;
    final foregrounds = <MxBadgeTone, Color>{
      MxBadgeTone.primary: semantic.primaryForeground,
      MxBadgeTone.mastery: semantic.mastery,
      MxBadgeTone.success: semantic.success,
      MxBadgeTone.warning: semantic.warning,
      MxBadgeTone.danger: colors.error,
      MxBadgeTone.neutral: colors.onSurfaceVariant,
    };
    for (final MapEntry(key: tone, value: foreground) in foregrounds.entries) {
      testWidgets('outlined ${tone.name}, ${brightness.name}: no fill, '
          'outline hairline, the tone\'s foreground', (tester) async {
        await pumpMx(
          tester,
          MxBadge(label: '4 due', tone: tone, isOutlined: true),
          brightness: brightness,
        );
        await tester.pumpAndSettle();

        final pill = _pill(tester);
        final edge = (pill.border! as Border).top;
        expect(pill.color, isNull);
        expect(edge.color, colors.outline);
        expect(edge.width, AppStroke.hairline);
        expect(_ink(tester, '4 due'), foreground);
        expect(tester.getSize(find.byType(MxBadge)).height, 22);
      });
    }
  }

  test('a badge is never solid and outlined at once', () {
    expect(
      () => MxBadge(label: 'x', isSolid: true, isOutlined: true),
      throwsAssertionError,
    );
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
}
