import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

// Dark, on ForUI (ADR-026): accent text, focus rings, fills, edges and tints
// keep primary; an accent icon or glyph and the label on the accent tint are
// the accent mark, as bright as text (owner rulings 2026-10-17).
void main() {
  final scheme = appDarkColors;
  final ink = scheme.primary;
  final mark = scheme.extension<MxStatusColors>().accentMark;

  Future<void> pumpDark(WidgetTester tester, Widget child) =>
      pumpMx(tester, child, brightness: Brightness.dark);

  Color? textColorOf(WidgetTester tester, String text) =>
      textColor(tester, find.text(text));

  testWidgets(
    'MxButton: the primary fill keeps primary under its foreground, and every '
    'focus ring is the theme ring in primary',
    (tester) async {
      await pumpDark(
        tester,
        Column(
          children: [
            MxButton(
              label: 'Outline',
              tone: MxButtonTone.outline,
              onPressed: () {},
            ),
            MxButton(label: 'Fill', onPressed: () {}),
          ],
        ),
      );
      final fill = find.widgetWithText(MxButton, 'Fill');
      expect(paintedDecoration(tester, fill).color, scheme.primary);
      expect(textColorOf(tester, 'Fill'), scheme.primaryForeground);

      useKeyboardFocusHighlight();
      final ring = forUiTheme(tester, fill).style.focusedOutlineStyle;
      expect(ring.color, scheme.primary);
      for (final label in ['Outline', 'Fill']) {
        await tabTo(tester, find.text(label));
        expect(
          focusRingRender(tester),
          paintsFocusRing(scheme.primary, width: ring.width),
        );
      }
    },
  );

  testWidgets('MxBadge: a tinted primary badge reads the accent mark', (
    tester,
  ) async {
    await pumpDark(tester, const MxBadge(label: '23 due'));
    expect(textColorOf(tester, '23 due'), mark);
  });

  testWidgets('MxStatusBadge: the reviewing label and dot are the accent '
      'mark; the fill keeps the primary tint', (tester) async {
    await pumpDark(
      tester,
      const MxStatusBadge(status: MxCardStatus.reviewing, label: 'Reviewing'),
    );
    expect(textColorOf(tester, 'Reviewing'), mark);
    final dot = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('mx-status-dot')),
    );
    expect((dot.decoration as BoxDecoration).color, mark);
  });

  test('MxBadge: a solid badge is primary only (D5)', () {
    expect(
      () => MxBadge(label: 'x', tone: MxBadgeTone.mastery, isSolid: true),
      throwsAssertionError,
    );
  });

  testWidgets('MxActionSheetCommandRow: a non-destructive glyph is the '
      'accent mark', (tester) async {
    await pumpDark(
      tester,
      MxActionSheetCommandRow(
        icon: AppIcons.restore,
        label: 'Restore…',
        onTap: () {},
      ),
    );
    // The verb stays in the foreground; the glyph is the ink.
    expect(textColorOf(tester, 'Restore…'), scheme.foreground);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.restore)).color, mark);
  });

  testWidgets('MxWorkloadBreakdownLine: the today term is the accent', (
    tester,
  ) async {
    await pumpDark(
      tester,
      const MxWorkloadBreakdownLine(
        overdueCount: 0,
        todayCount: 3,
        newCount: 0,
        overdueLabel: _count,
        todayLabel: _today,
        newLabel: _count,
        fallback: 'none',
      ),
    );
    TextSpan? span;
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      rich.text.visitChildren((child) {
        if (child is TextSpan && child.text == '3 today') span = child;
        return span == null;
      });
    }
    expect(span?.style?.color, ink);
  });

  testWidgets('MxSearchField: the focused search glyph is the accent mark', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpDark(
      tester,
      MxSearchField(
        controller: controller,
        hintText: 'Search',
        clearLabel: 'Clear',
      ),
    );
    await tester.tap(find.byType(FTextField));
    await tester.pump();
    expect(tester.widget<Icon>(find.byIcon(AppIcons.search)).color, mark);
  });

  testWidgets(
    'MxEmptyState: the primary glyph is the accent mark; its tile tint '
    'stays primary',
    (tester) async {
      await pumpDark(
        tester,
        const MxEmptyState(icon: AppIcons.library, title: 'Empty'),
      );
      expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, mark);
    },
  );

  testWidgets('MxStatTile: the primary emphasis reads in the accent', (
    tester,
  ) async {
    await pumpDark(
      tester,
      const MxStatTile(
        value: '20',
        label: 'Reviewed',
        emphasis: MxStatTileEmphasis.primary,
      ),
    );
    expect(textColorOf(tester, '20'), ink);
  });

  testWidgets(
    'MxIconTile: the tinted glyph is the accent mark without a seed',
    (tester) async {
      await pumpDark(tester, const MxIconTile(icon: AppIcons.library));
      expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, mark);
    },
  );

  testWidgets('MxStudyTopBar: the badge text is the accent mark', (
    tester,
  ) async {
    await pumpDark(
      tester,
      MxStudyTopBar(
        modeLabel: 'Match',
        current: 1,
        total: 5,
        counterLabel: '1 / 5',
        closeLabel: 'Close',
        onClose: () {},
      ),
    );
    expect(textColorOf(tester, 'MATCH'), mark);
  });

  testWidgets(
    'MxSpinner: the glyph is the accent mark unless a colour is given',
    (tester) async {
      Color? glyph() => spinnerIconTheme(tester, find.byType(MxSpinner)).color;
      await pumpDark(tester, const MxSpinner());
      expect(glyph(), mark);
      await pumpDark(tester, MxSpinner(color: scheme.primaryForeground));
      expect(glyph(), scheme.primaryForeground);
    },
  );
}

String _count(int count) => '$count';

String _today(int count) => '$count today';
