import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

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
  testWidgets('three steps: 28/8/16, 36/12/20, 44/12/20', (tester) async {
    for (final (size, box, radius, glyph) in [
      (MxIconTileSize.small, 28.0, 8.0, 16.0),
      (MxIconTileSize.medium, 36.0, 12.0, 20.0),
      (MxIconTileSize.large, 44.0, 12.0, 20.0),
    ]) {
      await pumpMx(tester, MxIconTile(icon: AppIcons.folder, size: size));

      expect(tester.getSize(find.byType(MxIconTile)), Size.square(box));
      expect(_tile(tester).borderRadius, BorderRadius.circular(radius));
      expect(tester.widget<Icon>(find.byType(Icon)).size, glyph);
    }
  });

  testWidgets('default: primary at 10% light and 16% dark, primary glyph', (
    tester,
  ) async {
    final light = AppColorSchemes.light.primary;
    await pumpMx(tester, const MxIconTile(icon: AppIcons.folder));
    expect(_tile(tester).color, light.withValues(alpha: 0.10));
    expect(tester.widget<Icon>(find.byType(Icon)).color, light);

    await pumpMx(
      tester,
      const MxIconTile(icon: AppIcons.folder),
      brightness: Brightness.dark,
    );
    // The theme animates from light when the same app re-pumps dark.
    await tester.pumpAndSettle();
    expect(
      _tile(tester).color,
      AppColorSchemes.dark.primary.withValues(alpha: 0.16),
    );
  });

  testWidgets('seeded: the seed at 12% with a seed glyph', (tester) async {
    await pumpMx(tester, const MxIconTile(icon: AppIcons.folder, seed: _seed));

    expect(_tile(tester).color, _seed.withValues(alpha: 0.12));
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
}
