import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_palette.dart';

import '../../support/theme_expect.dart';

import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../support/widget_harness.dart';

// Spec 2026-09-27 D2: in dark, primary as text, icon or focus ring reads in
// primaryInk; fills, edges and tints keep primary.
void main() {
  final scheme = darkColorScheme;
  final ink = accentOf(scheme);

  Future<void> pumpDark(WidgetTester tester, Widget child) =>
      pumpMx(tester, child, brightness: Brightness.dark);

  Color? textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets(
    'MxButton: outline foreground is the accent and every focus ring is '
    'primary; the primary fill keeps primary',
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
      ButtonStyle style(String label) => tester
          .widget<TextButton>(
            find.descendant(
              of: find.widgetWithText(MxButton, label),
              matching: find.byType(TextButton),
            ),
          )
          .style!;
      // The focus ring rides on the shape, outside the container.
      BorderSide ringOf(ButtonStyle style) =>
          (style.shape!.resolve({WidgetState.focused})! as MxFocusRingBorder)
              .ring;
      expect(style('Outline').foregroundColor!.resolve({}), ink);
      expect(ringOf(style('Outline')).color, scheme.primary);
      expect(style('Fill').backgroundColor!.resolve({}), scheme.primary);
      expect(style('Fill').foregroundColor!.resolve({}), scheme.onPrimary);
      expect(ringOf(style('Fill')).color, scheme.primary);
    },
  );

  testWidgets('MxBadge: a tinted primary badge reads the accent', (
    tester,
  ) async {
    await pumpDark(tester, const MxBadge(label: '23 due'));
    expect(textColor(tester, '23 due'), ink);
  });

  test('MxBadge: a solid badge is primary only (D5)', () {
    expect(
      () => MxBadge(label: 'x', tone: MxBadgeTone.mastery, isSolid: true),
      throwsAssertionError,
    );
  });

  testWidgets('MxActionSheetCommandRow: a non-destructive glyph inks in '
      'primaryInk', (tester) async {
    await pumpDark(
      tester,
      MxActionSheetCommandRow(
        icon: AppIcons.restore,
        label: 'Restore…',
        onTap: () {},
      ),
    );
    // The verb stays onSurface (commandLabel); the glyph is the ink.
    expect(textColor(tester, 'Restore…'), scheme.onSurface);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.restore)).color, ink);
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

  testWidgets('MxSearchField: the focused search glyph is the accent', (
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
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.widget<Icon>(find.byIcon(AppIcons.search)).color, ink);
  });

  testWidgets('MxEmptyState: the primary glyph is the accent; its tile tint '
      'stays primary', (tester) async {
    await pumpDark(
      tester,
      const MxEmptyState(icon: AppIcons.library, title: 'Empty'),
    );
    expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, ink);
  });

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
    expect(textColor(tester, '20'), ink);
  });

  testWidgets('MxIconTile: the tinted glyph is the accent without a seed', (
    tester,
  ) async {
    await pumpDark(tester, const MxIconTile(icon: AppIcons.library));
    expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, ink);
  });

  testWidgets('MxStudyTopBar: the badge text is the accent', (tester) async {
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
    expect(textColor(tester, 'MATCH'), ink);
  });

  testWidgets('MxSpinner: the arc is the accent unless a colour is given', (
    tester,
  ) async {
    RenderObject ring() => tester.renderObject(
      find
          .descendant(
            of: find.byType(MxSpinner),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    await pumpDark(tester, const MxSpinner());
    expect(ring(), paints..arc(color: ink));
    await pumpDark(tester, MxSpinner(color: scheme.onPrimary));
    expect(ring(), paints..arc(color: scheme.onPrimary));
  });
}

String _count(int count) => '$count';

String _today(int count) => '$count today';
