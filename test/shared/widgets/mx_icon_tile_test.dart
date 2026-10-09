import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import '../../support/widget_harness.dart';

const _childKey = ValueKey('tile-child');

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

  for (final brightness in Brightness.values) {
    final isLight = brightness == Brightness.light;
    final colors = isLight ? AppColorSchemes.light : AppColorSchemes.dark;
    final semantic = isLight ? MxSemanticColors.light : MxSemanticColors.dark;
    // Per tone: (tile ground, glyph).
    final roles = <MxIconTileTone, (Color, Color)>{
      MxIconTileTone.tinted: (
        colors.primaryContainer,
        semantic.primaryForeground,
      ),
      MxIconTileTone.primary: (colors.primary, colors.onPrimary),
      MxIconTileTone.mastery: (semantic.masteryContainer, semantic.mastery),
      MxIconTileTone.warning: (semantic.warning, semantic.onWarning),
      MxIconTileTone.success: (semantic.successContainer, semantic.success),
      MxIconTileTone.caution: (semantic.warningContainer, semantic.warning),
      MxIconTileTone.danger: (colors.errorContainer, colors.error),
      MxIconTileTone.streak: (colors.surfaceContainerHigh, semantic.streak),
      MxIconTileTone.neutral: (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
      ),
    };
    for (final MapEntry(key: tone, value: (fill, glyph)) in roles.entries) {
      testWidgets('${tone.name}, ${brightness.name}: the role pair', (
        tester,
      ) async {
        await pumpMx(
          tester,
          MxIconTile(icon: AppIcons.check, tone: tone),
          brightness: brightness,
        );
        // The theme change animates.
        await tester.pumpAndSettle();

        expect(_tile(tester).color, fill);
        expect(tester.widget<Icon>(find.byIcon(AppIcons.check)).color, glyph);
      });
    }
  }
}
