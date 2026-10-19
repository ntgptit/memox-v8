import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

import '../../support/widget_harness.dart';

const _tileKey = ValueKey('mx-command-tile');

Widget _width(Widget child) => SizedBox(width: 344, child: child);

BoxDecoration _tile(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byKey(_tileKey)).decoration
        as BoxDecoration;

void main() {
  final colors = appLightColors;

  testWidgets(
    'a 30 tile at the primary tint, 16 glyph, item-title verb; 48 target',
    (tester) async {
      await pumpMx(
        tester,
        _width(
          MxActionSheetCommandRow(
            icon: AppIcons.edit,
            label: 'Rename',
            subtitle: 'Change the deck name',
            onTap: () {},
          ),
        ),
      );
      final row = tester.getTopLeft(find.byType(MxActionSheetCommandRow));

      expect(tester.getSize(find.byKey(_tileKey)), const Size.square(30));
      expect(tester.getTopLeft(find.byKey(_tileKey)).dx - row.dx, 9);
      expect(_tile(tester).color, colors.primary.tintOver(colors.background));
      expect(
        _tile(tester).borderRadius,
        tester.element(find.byKey(_tileKey)).radii.sm,
      );
      final glyph = tester.widget<Icon>(find.byIcon(AppIcons.edit));
      expect((glyph.size, glyph.color), (16, colors.primary));
      expect(
        tester.widget<Text>(find.text('Rename')).style!.fontSize,
        tester.element(find.text('Rename')).texts.itemTitle.fontSize,
      );
      expect(tester.getTopLeft(find.text('Rename')).dx - row.dx, 52);
      await expectAccessibleTargets(tester);
    },
  );

  testWidgets('M3 list item heights: 56 for a verb, 72 with a subtitle', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.edit,
          label: 'Rename',
          onTap: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(MxActionSheetCommandRow)).height, 56);

    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.edit,
          label: 'Rename',
          subtitle: 'Change the deck name',
          onTap: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(MxActionSheetCommandRow)).height, 72);
  });

  testWidgets('destructive: danger-soft tile, error glyph and verb', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.delete,
          label: 'Delete',
          isDestructive: true,
          onTap: () {},
        ),
      ),
    );

    expect(_tile(tester).color, colors.error.tintOver(colors.background));
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.delete)).color,
      colors.error,
    );
    expect(tester.widget<Text>(find.text('Delete')).style!.color, colors.error);
  });

  testWidgets('chevron only when it opens a surface; one tap, one call', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.folder,
          label: 'Move',
          hasChevron: true,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.folder,
          label: 'Move',
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });

  testWidgets('announced as one button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.edit,
          label: 'Rename',
          subtitle: 'Change the deck name',
          onTap: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Rename')),
      isSemantics(label: 'Rename\nChange the deck name', isButton: true),
    );
    handle.dispose();
  });

  testWidgets('M3F-17: a disabled command is dimmed, announced disabled with '
      'no tap action, and inert', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxActionSheetCommandRow(
        icon: AppIcons.play,
        label: 'Study this deck',
        onTap: () => taps++,
        isEnabled: false,
      ),
    );
    // A disabled command ignores pointers: the tap is meant to miss.
    await tester.tap(find.text('Study this deck'), warnIfMissed: false);

    expect(taps, 0);
    expect(find.byType(Opacity), findsWidgets);
    expect(
      tester.getSemantics(find.text('Study this deck')),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a long subtitle keeps two lines', (tester) async {
    const warning =
        'Renaming onto an existing name merges the two tags into one, '
        'and every card keeps a single copy.';
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.edit,
          label: 'Rename',
          subtitle: warning,
          onTap: () {},
        ),
      ),
    );

    expect(tester.widget<Text>(find.text(warning)).maxLines, 2);
  });
}
