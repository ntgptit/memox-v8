import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
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
  final scheme = AppColorSchemes.dark;
  final ink = MxDerivedColors.primaryInkOf(scheme);

  Future<void> pumpDark(WidgetTester tester, Widget child) =>
      pumpMx(tester, child, brightness: Brightness.dark);

  Color? textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('MxButton: outline ink and every focus ring are primaryInk; '
      'the primary fill keeps primary', (tester) async {
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
    const focused = {WidgetState.focused};
    expect(style('Outline').foregroundColor!.resolve({}), ink);
    expect(style('Outline').side!.resolve(focused)!.color, ink);
    expect(style('Fill').backgroundColor!.resolve({}), scheme.primary);
    expect(style('Fill').foregroundColor!.resolve({}), scheme.onPrimary);
    expect(style('Fill').side!.resolve(focused)!.color, ink);
  });

  testWidgets('MxBadge: a tinted primary badge inks in primaryInk', (
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

  testWidgets('MxWorkloadBreakdownLine: the today term is primaryInk', (
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

  testWidgets('MxSearchField: the focused search glyph is primaryInk', (
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

  testWidgets('MxEmptyState: the primary glyph is primaryInk; its tile tint '
      'stays primary', (tester) async {
    await pumpDark(
      tester,
      const MxEmptyState(icon: AppIcons.library, title: 'Empty'),
    );
    expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, ink);
  });

  testWidgets('MxStatTile: the primary emphasis reads in primaryInk', (
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

  testWidgets('MxIconTile: the tinted glyph is primaryInk without a seed', (
    tester,
  ) async {
    await pumpDark(tester, const MxIconTile(icon: AppIcons.library));
    expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, ink);
  });

  testWidgets('MxStudyTopBar: the badge text is primaryInk, or the accent a '
      'caller passes', (tester) async {
    Widget bar({Color? accent}) => MxStudyTopBar(
      modeLabel: 'Match',
      current: 1,
      total: 5,
      counterLabel: '1 / 5',
      closeLabel: 'Close',
      onClose: () {},
      accent: accent,
    );
    await pumpDark(tester, bar());
    expect(textColor(tester, 'MATCH'), ink);

    const accent = Color(0xFF00AA55);
    await pumpDark(tester, bar(accent: accent));
    expect(textColor(tester, 'MATCH'), accent);
  });

  testWidgets('MxSpinner: off a fill the arc is primaryInk; on a fill it is '
      'onPrimary', (tester) async {
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
    await pumpDark(tester, const MxSpinner(isOnFill: true));
    expect(ring(), paints..arc(color: scheme.onPrimary));
  });
}

String _count(int count) => '$count';

String _today(int count) => '$count today';
