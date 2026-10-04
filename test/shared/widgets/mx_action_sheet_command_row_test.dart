import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    testWidgets(
      '$name: a 24 glyph in on-surface-variant; destroying is error',
      (tester) async {
        await pumpMx(
          tester,
          MxActionSheetCommandRow(
            icon: Icons.edit,
            label: 'Rename',
            onTap: () {},
          ),
          theme: theme,
        );
        final Icon glyph = tester.widget<Icon>(find.byIcon(Icons.edit));
        expect(glyph.size, AppIconSize.large);
        expect(glyph.color, s.onSurfaceVariant);
        expect(
          tester.widget<Text>(find.text('Rename')).style?.color,
          s.onSurface,
        );
        await pumpMx(
          tester,
          MxActionSheetCommandRow(
            icon: Icons.delete,
            label: 'Delete forever',
            subtitle: 'Cannot be undone',
            isDestructive: true,
            onTap: () {},
          ),
          theme: theme,
        );
        expect(tester.widget<Icon>(find.byIcon(Icons.delete)).color, s.error);
        expect(
          tester.widget<Text>(find.text('Delete forever')).style?.color,
          s.error,
        );
        expect(
          tester.widget<Text>(find.text('Cannot be undone')).style?.color,
          s.onSurfaceVariant,
        );
      },
    );
  }

  testWidgets('a 48 button that runs its command', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var ran = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 380,
        child: MxActionSheetCommandRow(
          icon: Icons.restore,
          label: 'Restore',
          subtitle: 'Back to Library',
          onTap: () => ran++,
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxActionSheetCommandRow)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
    expect(
      tester.getSemantics(find.text('Restore')),
      isSemantics(label: 'Restore\nBack to Library', isButton: true),
    );
    await tester.tap(find.text('Restore'));
    expect(ran, 1);
    semantics.dispose();
  });

  testWidgets('the label starts 12 past its glyph, as a menu item', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 380,
        child: MxActionSheetCommandRow(
          icon: Icons.edit,
          label: 'Rename',
          onTap: () {},
        ),
      ),
    );
    expect(
      tester.getRect(find.text('Rename')).left -
          tester.getRect(find.byIcon(Icons.edit)).right,
      12,
    );
  });

  testWidgets('the label keeps one line and the subtitle two', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 380,
        child: MxActionSheetCommandRow(
          icon: Icons.tune,
          label: 'Study options for this deck and every deck inside it',
          subtitle:
              'Cards per session, new-card order, the review algorithm '
              'and the daily limits',
          onTap: () {},
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.textContaining('Study options')).maxLines,
      1,
    );
    expect(tester.widget<Text>(find.textContaining('Cards per')).maxLines, 2);
  });
}
