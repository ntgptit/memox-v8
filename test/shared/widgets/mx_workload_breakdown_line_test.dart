import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../support/widget_harness.dart';

MxWorkloadBreakdownLine _line({
  int overdue = 3,
  int today = 5,
  int fresh = 2,
  String? suffix,
  bool shouldKeepZeroTerms = false,
  bool hasIcons = false,
}) => MxWorkloadBreakdownLine(
  overdueCount: overdue,
  todayCount: today,
  newCount: fresh,
  overdueLabel: (n) => '$n overdue',
  todayLabel: (n) => '$n today',
  newLabel: (n) => '$n new',
  fallback: 'Nothing due',
  suffix: suffix,
  shouldKeepZeroTerms: shouldKeepZeroTerms,
  hasIcons: hasIcons,
  canWrap: hasIcons,
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

  testWidgets('a fourth, muted Scheduled term follows New when a label is '
      'given, and only then (BR-STUDY-068, FE-A8 S1)', (tester) async {
    await pumpMx(
      tester,
      MxWorkloadBreakdownLine(
        overdueCount: 3,
        todayCount: 5,
        newCount: 2,
        scheduledCount: 4,
        overdueLabel: (n) => '$n overdue',
        todayLabel: (n) => '$n today',
        newLabel: (n) => '$n new',
        scheduledLabel: (n) => '$n scheduled',
        fallback: 'Nothing due',
      ),
    );

    expect(_plain(tester), '3 overdue · 5 today · 2 new · 4 scheduled');
    expect(_termStyle(tester, '4 scheduled')!.color, scheme.onSurfaceVariant);

    await pumpMx(
      tester,
      MxWorkloadBreakdownLine(
        overdueCount: 3,
        todayCount: 5,
        newCount: 2,
        scheduledCount: 4,
        overdueLabel: (n) => '$n overdue',
        todayLabel: (n) => '$n today',
        newLabel: (n) => '$n new',
        fallback: 'Nothing due',
      ),
    );
    expect(_plain(tester), '3 overdue · 5 today · 2 new');
  });

  testWidgets('a hero line wraps instead of cutting its suffix (FE-A8, kit '
      'hero)', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 160,
        child: MxWorkloadBreakdownLine(
          overdueCount: 1100,
          todayCount: 160,
          newCount: 7400,
          overdueLabel: (n) => '$n overdue',
          todayLabel: (n) => '$n today',
          newLabel: (n) => '$n new',
          fallback: 'Nothing due',
          suffix: 'across 4 decks',
          canWrap: true,
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(MxWorkloadBreakdownLine),
        matching: find.byType(Text),
      ),
    );
    expect(text.maxLines, isNull);
    expect(text.softWrap, isTrue);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('a statement keeps a zero term, muted at 400, and never falls '
      'back (BR-STUDY-076)', (tester) async {
    await pumpMx(
      tester,
      _line(overdue: 0, today: 0, fresh: 2, shouldKeepZeroTerms: true),
    );

    expect(_plain(tester), '0 overdue · 0 today · 2 new');
    for (final zero in ['0 overdue', '0 today']) {
      expect(_termStyle(tester, zero)!.color, scheme.onSurfaceVariant);
      expect(_termStyle(tester, zero)!.fontWeight, FontWeight.w400);
    }
    expect(_termStyle(tester, '2 new')!.color, derived.statusNewInk);

    await pumpMx(
      tester,
      _line(overdue: 0, today: 0, fresh: 0, shouldKeepZeroTerms: true),
    );
    expect(_plain(tester), '0 overdue · 0 today · 0 new');
  });

  testWidgets('with icons each term leads with its own glyph in its ink, on '
      'the same 18 line, and is read as its words only (BR-STUDY-076)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: _line(today: 0, shouldKeepZeroTerms: true, hasIcons: true),
      ),
    );

    final glyphs = tester
        .widgetList<Icon>(
          find.descendant(
            of: find.byType(MxWorkloadBreakdownLine),
            matching: find.byType(Icon),
          ),
        )
        .map((icon) => (icon.icon, icon.color))
        .toList();
    expect(glyphs, [
      (AppIcons.overdue, derived.warningInk),
      (AppIcons.dueNow, scheme.onSurfaceVariant),
      (AppIcons.newCards, derived.statusNewInk),
    ]);
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(MxWorkloadBreakdownLine),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.label, '3 overdue · 0 today · 2 new');
    expect(semantics.excludeSemantics, isTrue);
    expect(tester.getSize(find.byType(MxWorkloadBreakdownLine)).height, 18);
  });

  testWidgets('a plain line draws no icon', (tester) async {
    await pumpMx(tester, _line());

    expect(find.byType(Icon), findsNothing);
    expect(_plain(tester), '3 overdue · 5 today · 2 new');
  });

  testWidgets('a wrapping statement keeps each glyph with its words and its '
      'dot, the glyph centred on them (BR-STUDY-076)', (tester) async {
    await pumpMx(tester, SizedBox(width: 90, child: _line(hasIcons: true)));

    final line = find.byType(MxWorkloadBreakdownLine);
    expect(tester.getSize(line).height, greaterThan(18), reason: 'it wraps');
    for (final (glyph, words) in [
      (AppIcons.overdue, '3 overdue ·'),
      (AppIcons.dueNow, '5 today ·'),
      (AppIcons.newCards, '2 new'),
    ]) {
      final icon = find.descendant(of: line, matching: find.byIcon(glyph));
      final text = find.descendant(
        of: line,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().replaceAll(' ', ' ') == words,
        ),
      );
      expect(text, findsOneWidget, reason: words);
      expect(
        (tester.getCenter(icon).dy - tester.getCenter(text).dy).abs(),
        lessThan(1),
        reason: words,
      );
    }
  });

  testWidgets('a wrapping line without glyphs never breaks inside a term nor '
      'before its dot, at any width', (tester) async {
    // From the width where the widest term and its dot fit on one line.
    for (var width = 72.0; width <= 180; width += 2) {
      await pumpMx(
        tester,
        SizedBox(
          width: width,
          child: MxWorkloadBreakdownLine(
            overdueCount: 3,
            todayCount: 5,
            newCount: 2,
            overdueLabel: (n) => '$n overdue',
            todayLabel: (n) => '$n today',
            newLabel: (n) => '$n new',
            fallback: 'Nothing due',
            canWrap: true,
          ),
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(MxWorkloadBreakdownLine),
          matching: find.byType(RichText),
        ),
      );
      final text = paragraph.text.toPlainText();
      int lineOf(int offset) =>
          paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: offset, extentOffset: offset + 1),
              )
              .single
              .top ~/
          18;
      for (final term in ['3 overdue', '5 today', '2 new']) {
        final start = text.indexOf(term.replaceAll(' ', ' '));
        expect(start, isNot(-1), reason: '$term at $width');
        final dot = text.indexOf('·', start);
        final end = dot == -1 ? start + term.length - 1 : dot;
        expect(lineOf(end), lineOf(start), reason: '$term at $width');
      }
    }
  });
}
