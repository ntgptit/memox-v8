import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import '../../support/palette_status.dart';
import '../../support/widget_harness.dart';

const _childKey = ValueKey('tile-child');
const _seed = Color(0xFF0E9F6E);

BoxDecoration _tile(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxIconTile),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets('three steps: 28 small, 36 medium, 44 large', (tester) async {
    for (final (size, box, radius, glyph) in [
      (MxIconTileSize.small, 28.0, (BuildContext c) => c.radii.sm, 16.0),
      (MxIconTileSize.medium, 36.0, (BuildContext c) => c.radii.md, 20.0),
      (MxIconTileSize.large, 44.0, (BuildContext c) => c.radii.md, 20.0),
    ]) {
      await pumpMx(tester, MxIconTile(icon: AppIcons.folder, size: size));

      expect(tester.getSize(find.byType(MxIconTile)), Size.square(box));
      expect(
        _tile(tester).borderRadius,
        radius(tester.element(find.byType(MxIconTile))),
      );
      expect(tester.widget<Icon>(find.byType(Icon)).size, glyph);
    }
  });

  testWidgets('default: the primary tinted over the page, the primary glyph', (
    tester,
  ) async {
    await pumpMx(tester, const MxIconTile(icon: AppIcons.folder));
    expect(
      _tile(tester).color,
      appLightColors.primary.tintOver(appLightColors.background),
    );
    expect(
      tester.widget<Icon>(find.byType(Icon)).color,
      appLightColors.primary,
    );

    await pumpMx(
      tester,
      const MxIconTile(icon: AppIcons.folder),
      brightness: Brightness.dark,
    );
    // The theme animates from light when the same app re-pumps dark.
    await tester.pumpAndSettle();
    expect(
      _tile(tester).color,
      appDarkColors.primary.tintOver(appDarkColors.background),
    );
  });

  testWidgets('seeded: the seed tinted over the surface with a seed glyph', (
    tester,
  ) async {
    await pumpMx(tester, const MxIconTile(icon: AppIcons.folder, seed: _seed));

    expect(_tile(tester).color, _seed.tintOver(appLightColors.background));
    expect(tester.widget<Icon>(find.byType(Icon)).color, _seed);
  });

  testWidgets('a child replaces the glyph; the tile never shrinks', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Row(
        children: [
          const MxIconTile(child: SizedBox(key: _childKey)),
          Expanded(child: Text(List.filled(60, 'word').join(' '))),
        ],
      ),
    );

    expect(find.byKey(_childKey), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.getSize(find.byType(MxIconTile)), const Size.square(28));
  });

  test('an icon or a child, not both', () {
    expect(
      () => MxIconTile(icon: AppIcons.folder, child: const SizedBox()),
      throwsAssertionError,
    );
  });

  testWidgets(
    'a solid primary tile fills with primary under an onPrimary glyph',
    (tester) async {
      await pumpMx(
        tester,
        const MxIconTile(icon: AppIcons.lockOpen, tone: MxIconTileTone.primary),
      );
      final colors = appLightColors;

      expect(_tile(tester).color, colors.primary);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.lockOpen)).color,
        colors.primaryForeground,
      );
    },
  );

  testWidgets(
    'a solid warning tile fills with warning under an onWarning glyph',
    (tester) async {
      await pumpMx(
        tester,
        const MxIconTile(icon: AppIcons.lock, tone: MxIconTileTone.warning),
      );

      expect(_tile(tester).color, lightStatus.warningFill);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.lock)).color,
        lightStatus.onWarningFill,
      );
    },
  );

  test('a seed only tints', () {
    expect(
      () => MxIconTile(
        icon: AppIcons.lock,
        tone: MxIconTileTone.primary,
        seed: _seed,
      ),
      throwsAssertionError,
    );
  });

  for (final brightness in Brightness.values) {
    for (final tone in [
      MxIconTileTone.success,
      MxIconTileTone.caution,
      MxIconTileTone.danger,
    ]) {
      testWidgets('${tone.name}, ${brightness.name}: a soft tint, and the '
          'glyph reads 3:1 on it over the surface (FE-A6 D14)', (tester) async {
        await pumpMx(
          tester,
          MxIconTile(icon: AppIcons.check, tone: tone),
          brightness: brightness,
        );
        final colors = brightness == Brightness.light
            ? appLightColors
            : appDarkColors;
        final fill = _tile(tester).color!;
        final glyph = tester.widget<Icon>(find.byIcon(AppIcons.check)).color!;

        expect(
          _ratio(fill, colors.background),
          lessThan(1.5),
          reason: 'a soft tint, not a solid fill',
        );
        expect(_ratio(glyph, fill), greaterThanOrEqualTo(3));
      });
    }
  }
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
