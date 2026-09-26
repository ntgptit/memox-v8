import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../support/widget_harness.dart';

MxWorkloadBreakdownLine _line({
  int overdue = 3,
  int today = 5,
  int fresh = 2,
  String? suffix,
}) => MxWorkloadBreakdownLine(
  overdueCount: overdue,
  todayCount: today,
  newCount: fresh,
  overdueLabel: (n) => '$n overdue',
  todayLabel: (n) => '$n today',
  newLabel: (n) => '$n new',
  fallback: 'Nothing due',
  suffix: suffix,
);

TextSpan _root(WidgetTester tester) =>
    tester
            .widget<Text>(
              find.descendant(
                of: find.byType(MxWorkloadBreakdownLine),
                matching: find.byType(Text),
              ),
            )
            .textSpan!
        as TextSpan;

String _plain(WidgetTester tester) => _root(tester).toPlainText();

TextStyle? _termStyle(WidgetTester tester, String term) =>
    _root(tester).children!
        .whereType<TextSpan>()
        .firstWhere((span) => span.text == term)
        .style;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(scheme, semantic);

  testWidgets('all three terms in order, each in its colour, at 600', (
    tester,
  ) async {
    await pumpMx(tester, _line());

    expect(_plain(tester), '3 overdue · 5 today · 2 new');
    expect(_termStyle(tester, '3 overdue')!.color, derived.warningInk);
    expect(
      _termStyle(tester, '5 today')!.color,
      MxDerivedColors.primaryInkOf(scheme),
    );
    expect(_termStyle(tester, '2 new')!.color, derived.statusNewInk);
    expect(_termStyle(tester, '2 new')!.fontWeight, FontWeight.w600);
    expect(_root(tester).style!.fontWeight, FontWeight.w400);
    expect(_root(tester).style!.color, scheme.onSurfaceVariant);
  });

  testWidgets('a zero term drops with its separator (RF4)', (tester) async {
    for (final (overdue, today, fresh, expected) in [
      (0, 5, 2, '5 today · 2 new'),
      (3, 0, 2, '3 overdue · 2 new'),
      (3, 5, 0, '3 overdue · 5 today'),
      (0, 0, 2, '2 new'),
    ]) {
      await pumpMx(tester, _line(overdue: overdue, today: today, fresh: fresh));

      expect(_plain(tester), expected);
    }
  });

  testWidgets('nothing due is the fallback; a suffix follows the terms', (
    tester,
  ) async {
    await pumpMx(tester, _line(overdue: 0, today: 0, fresh: 0));
    expect(_plain(tester), 'Nothing due');

    await pumpMx(tester, _line(suffix: 'across 4 decks'));
    expect(_plain(tester), '3 overdue · 5 today · 2 new across 4 decks');
  });

  testWidgets('one 18 line with an ellipsis', (tester) async {
    await pumpMx(tester, SizedBox(width: 120, child: _line()));
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(MxWorkloadBreakdownLine),
        matching: find.byType(Text),
      ),
    );

    expect((text.maxLines, text.overflow), (1, TextOverflow.ellipsis));
    expect(tester.getSize(find.byType(MxWorkloadBreakdownLine)).height, 18);
  });

  test('a negative count asserts', () {
    expect(() => _line(overdue: -1), throwsAssertionError);
  });
}
