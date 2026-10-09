import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../support/widget_harness.dart';

// Spec 2026-10-08 §4.1: the brand as text, glyph or ring is
// primaryForeground, in both themes; fills and edges keep primary. The
// badge and the icon tile still read the derived ink until Task 13 moves
// them.
void main() {
  final scheme = AppColorSchemes.dark;
  // The derived ink the badge and the icon tile still read (Task 13).
  final ink = MxDerivedColors.primaryInkOf(scheme);

  Future<void> pumpDark(WidgetTester tester, Widget child) =>
      pumpMx(tester, child, brightness: Brightness.dark);

  /// Runs [body] in each theme with that theme's schemes.
  Future<void> inBothThemes(
    WidgetTester tester,
    Future<void> Function(Brightness, ColorScheme, MxSemanticColors) body,
  ) async {
    for (final brightness in Brightness.values) {
      final isLight = brightness == Brightness.light;
      await body(
        brightness,
        isLight ? AppColorSchemes.light : AppColorSchemes.dark,
        isLight ? MxSemanticColors.light : MxSemanticColors.dark,
      );
    }
  }

  Color? textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('MxButton: outline and text ink are primaryForeground; the '
      'primary fill keeps primary and its ring is the shared one', (
    tester,
  ) async {
    await inBothThemes(tester, (brightness, colors, semantic) async {
      await pumpMx(
        tester,
        Column(
          children: [
            MxButton(
              label: 'Outline',
              tone: MxButtonTone.outline,
              onPressed: () {},
            ),
            MxButton(label: 'Text', tone: MxButtonTone.text, onPressed: () {}),
            MxButton(label: 'Fill', onPressed: () {}),
          ],
        ),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      ButtonStyle style(String label) => tester
          .widget<TextButton>(
            find.descendant(
              of: find.widgetWithText(MxButton, label),
              matching: find.byType(TextButton),
            ),
          )
          .style!;
      const focused = {WidgetState.focused};
      expect(
        style('Outline').foregroundColor!.resolve({}),
        semantic.primaryForeground,
      );
      expect(
        style('Text').foregroundColor!.resolve({}),
        semantic.primaryForeground,
      );
      expect(style('Fill').backgroundColor!.resolve({}), colors.primary);
      expect(style('Fill').foregroundColor!.resolve({}), colors.onPrimary);
      // No Material ring: MxFocusRing draws it outside the control.
      expect(style('Fill').side!.resolve(focused), BorderSide.none);
      expect(style('Outline').side!.resolve(focused)!.color, colors.outline);
      expect(find.byType(MxFocusRing), findsNWidgets(3));
    });
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

  testWidgets('MxActionSheetCommandRow: a non-destructive glyph and verb ink '
      'in primaryForeground', (tester) async {
    await pumpDark(
      tester,
      MxActionSheetCommandRow(
        icon: AppIcons.restore,
        label: 'Restore…',
        onTap: () {},
      ),
    );
    expect(
      textColor(tester, 'Restore…'),
      MxSemanticColors.dark.primaryForeground,
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.restore)).color,
      MxSemanticColors.dark.primaryForeground,
    );
  });

  testWidgets('MxWorkloadBreakdownLine: the today term is primaryForeground', (
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
    expect(span?.style?.color, MxSemanticColors.dark.primaryForeground);
  });

  testWidgets('MxSearchField: the focused search glyph is primaryForeground', (
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
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.search)).color,
      MxSemanticColors.dark.primaryForeground,
    );
  });

  testWidgets('MxEmptyState: the primary glyph is primaryForeground on its '
      'primaryContainer tile', (tester) async {
    await pumpDark(
      tester,
      const MxEmptyState(icon: AppIcons.library, title: 'Empty'),
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.library)).color,
      MxSemanticColors.dark.primaryForeground,
    );
  });

  testWidgets('MxStatTile: the primary emphasis reads in primaryForeground', (
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
    expect(textColor(tester, '20'), MxSemanticColors.dark.primaryForeground);
  });

  testWidgets('MxIconTile: the tinted glyph is primaryInk without a seed', (
    tester,
  ) async {
    await pumpDark(tester, const MxIconTile(icon: AppIcons.library));
    expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, ink);
  });

  testWidgets('MxStudyTopBar: the badge text is onPrimaryContainer', (
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
    expect(textColor(tester, 'MATCH'), scheme.onPrimaryContainer);
  });

  testWidgets(
    'MxSpinner: off a fill the arc is primaryForeground; on a fill it is '
    'onPrimary',
    (tester) async {
      RenderObject ring() => tester.renderObject(
        find
            .descendant(
              of: find.byType(MxSpinner),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      await pumpDark(tester, const MxSpinner());
      expect(
        ring(),
        paints..arc(color: MxSemanticColors.dark.primaryForeground),
      );
      await pumpDark(tester, const MxSpinner(isOnFill: true));
      expect(ring(), paints..arc(color: AppColorSchemes.dark.onPrimary));
    },
  );
}

String _count(int count) => '$count';

String _today(int count) => '$count today';
