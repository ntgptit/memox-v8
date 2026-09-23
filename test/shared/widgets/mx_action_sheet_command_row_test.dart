import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

import '../../support/widget_harness.dart';

const _tileKey = ValueKey('mx-command-tile');

Widget _width(Widget child) => SizedBox(width: 344, child: child);

BoxDecoration _tile(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byKey(_tileKey)).decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a 30 tile at primary 8%, 16 glyph, 14/600 verb; 48 target', (
    tester,
  ) async {
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
    expect(_tile(tester).color, scheme.primary.withValues(alpha: 0.08));
    expect(_tile(tester).borderRadius, BorderRadius.circular(8));
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.edit));
    expect((glyph.size, glyph.color), (16, scheme.primary));
    expect(tester.widget<Text>(find.text('Rename')).style!.fontSize, 14);
    expect(tester.getTopLeft(find.text('Rename')).dx - row.dx, 52);
    await expectAccessibleTargets(tester);
  });

  testWidgets('destructive: danger-soft tile, error glyph and verb', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
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

    expect(_tile(tester).color, derived.dangerSoft);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.delete)).color,
      scheme.error,
    );
    expect(tester.widget<Text>(find.text('Delete')).style!.color, scheme.error);
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
}
