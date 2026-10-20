import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';
import 'package:memox/shared/widgets/mx_term_flow.dart';

import '../../support/widget_harness.dart';

MxWorkloadBreakdownLine _line({
  int overdue = 3,
  int today = 5,
  int fresh = 2,
  int scheduledCount = 0,
  bool hasScheduledLabel = false,
  String fallback = 'Nothing due',
  String? suffix,
  bool hasIcons = false,
  bool? canWrap,
}) => MxWorkloadBreakdownLine(
  overdueCount: overdue,
  todayCount: today,
  newCount: fresh,
  scheduledCount: scheduledCount,
  overdueLabel: (n) => '$n overdue',
  todayLabel: (n) => '$n today',
  newLabel: (n) => '$n new',
  scheduledLabel: hasScheduledLabel ? (n) => '$n scheduled' : null,
  fallback: fallback,
  suffix: suffix,
  hasIcons: hasIcons,
  canWrap: canWrap ?? hasIcons,
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

MxTermLine _termLine(WidgetTester tester) => tester.widget<MxTermLine>(
  find.descendant(
    of: find.byType(MxWorkloadBreakdownLine),
    matching: find.byType(MxTermLine),
  ),
);

TextStyle? _termStyle(WidgetTester tester, String term) =>
    _root(tester).children!
        .whereType<TextSpan>()
        .firstWhere((span) => span.text == term)
        .style;

TextStyle _label(WidgetTester tester) =>
    tester.element(find.byType(MxWorkloadBreakdownLine)).texts.body;

/// One line of the breakdown: one line of the body role, as the engine lays
/// it out (13 at 1.5 sets a whole-pixel line, not 19.5).
double _lineHeight(WidgetTester tester) {
  final role = tester.element(find.byType(MxWorkloadBreakdownLine)).texts.body;
  final painter = TextPainter(
    text: TextSpan(text: 'x', style: role),
    textDirection: TextDirection.ltr,
  )..layout();
  addTearDown(painter.dispose);
  return painter.height;
}

void main() {
  final colors = appLightColors;
  const mx = MxStatusColors.light;

  testWidgets('all three terms in order, each in its colour', (tester) async {
    await pumpMx(tester, _line());

    expect(_plain(tester), '3 overdue · 5 today · 2 new');
    expect(_termStyle(tester, '3 overdue')!.color, mx.warning);
    expect(_termStyle(tester, '5 today')!.color, colors.primary);
    expect(_termStyle(tester, '2 new')!.color, colors.mutedForeground);
    // Every term, coloured or muted, sets in the body role's one weight.
    final weight = _label(tester).fontWeight;
    expect(_termStyle(tester, '3 overdue')!.fontWeight, weight);
    expect(_termStyle(tester, '2 new')!.fontWeight, weight);
    expect(_root(tester).style!.fontWeight, weight);
    expect(_root(tester).style!.color, colors.mutedForeground);
  });

  testWidgets('the line sets as a row\'s metadata line, body at 13 and 400, '
      'below the row title (type scale spec 2026-10-20)', (tester) async {
    await pumpMx(tester, _line());

    expect(_root(tester).style!.fontSize, 13);
    expect(_root(tester).style!.fontWeight, FontWeight.w400);
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

  testWidgets('one line with an ellipsis', (tester) async {
    await pumpMx(tester, SizedBox(width: 120, child: _line()));
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(MxWorkloadBreakdownLine),
        matching: find.byType(Text),
      ),
    );

    expect((text.maxLines, text.overflow), (1, TextOverflow.ellipsis));
    expect(
      tester.getSize(find.byType(MxWorkloadBreakdownLine)).height,
      _lineHeight(tester),
    );
  });

  test('a negative count asserts', () {
    expect(() => _line(overdue: -1), throwsAssertionError);
  });

  testWidgets('a fourth, muted Scheduled term follows New when a label is '
      'given, and only then (BR-STUDY-068, FE-A8 S1)', (tester) async {
    await pumpMx(tester, _line(scheduledCount: 4, hasScheduledLabel: true));

    expect(_plain(tester), '3 overdue · 5 today · 2 new · 4 scheduled');
    expect(_termStyle(tester, '4 scheduled')!.color, colors.mutedForeground);

    await pumpMx(tester, _line(scheduledCount: 4));
    expect(_plain(tester), '3 overdue · 5 today · 2 new');
  });

  // With only scheduled cards the line still says nothing is due, then the
  // scheduled term (critique 2026-09-30 part 3b review: the canWrap = false
  // case).
  // The Wrap Rule (spec W1): a wrapping fallback is a line of terms too,
  // split like the counts it stands in for; a one-line row keeps one text.
  for (final canWrap in [true, false]) {
    testWidgets('the fallback is ${canWrap ? '' : 'not '}split into terms '
        'when the line ${canWrap ? 'wraps' : 'keeps one line'}', (
      tester,
    ) async {
      await pumpMx(
        tester,
        _line(
          overdue: 0,
          today: 0,
          fresh: 0,
          scheduledCount: 3,
          hasScheduledLabel: true,
          fallback: '12 cards · nothing due',
          canWrap: canWrap,
        ),
      );

      if (canWrap) {
        expect(
          [for (final term in _termLine(tester).terms) term.text],
          ['12 cards', 'nothing due', '3 scheduled'],
        );
        return;
      }
      expect(_plain(tester), '12 cards · nothing due · 3 scheduled');
    });
  }

  testWidgets('a hero line wraps instead of cutting its suffix (FE-A8, kit '
      'hero)', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 160,
        child: _line(
          overdue: 1100,
          today: 160,
          fresh: 7400,
          suffix: 'across 4 decks',
          canWrap: true,
        ),
      ),
    );

    expect(_termLine(tester).trail, 'across 4 decks');
    expect(find.text('across 4 decks'), findsOneWidget);
    expect(
      tester.getSize(find.byType(MxWorkloadBreakdownLine)).height,
      greaterThan(_lineHeight(tester)),
      reason: 'it wraps',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('with glyphs a zero term drops and the order holds; with no '
      'term left the fallback is the line (Study home spec H1)', (
    tester,
  ) async {
    await pumpMx(tester, _line(overdue: 0, today: 0, fresh: 2, hasIcons: true));
    expect(find.text('2 new'), findsOneWidget);
    expect(find.textContaining('0 '), findsNothing);
    expect(find.byIcon(AppIcons.newCards), findsOneWidget);
    expect(find.byIcon(AppIcons.overdue), findsNothing);

    await pumpMx(tester, _line(overdue: 0, today: 0, fresh: 0, hasIcons: true));
    expect(find.text('Nothing due'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets(
    'with icons each term leads with its own glyph in its foreground, on '
    'the same line, and is read as its words only (BR-STUDY-076)',
    (tester) async {
      await pumpMx(tester, SizedBox(width: 320, child: _line(hasIcons: true)));

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
        (AppIcons.overdue, mx.warning),
        (AppIcons.dueNow, mx.accentMark),
        (AppIcons.newCards, colors.mutedForeground),
      ]);
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(MxWorkloadBreakdownLine),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, '3 overdue · 5 today · 2 new');
      expect(semantics.excludeSemantics, isTrue);
      expect(
        tester.getSize(find.byType(MxWorkloadBreakdownLine)).height,
        _lineHeight(tester),
      );
    },
  );

  testWidgets('a plain line draws no icon', (tester) async {
    await pumpMx(tester, _line());

    expect(find.byType(Icon), findsNothing);
    expect(_plain(tester), '3 overdue · 5 today · 2 new');
  });

  testWidgets('a wrapping statement keeps each glyph with its words, the '
      'glyph centred on them (BR-STUDY-076)', (tester) async {
    await pumpMx(tester, SizedBox(width: 90, child: _line(hasIcons: true)));

    final line = find.byType(MxWorkloadBreakdownLine);
    expect(
      tester.getSize(line).height,
      greaterThan(_lineHeight(tester)),
      reason: 'it wraps',
    );
    for (final (glyph, words) in [
      (AppIcons.overdue, '3 overdue'),
      (AppIcons.dueNow, '5 today'),
      (AppIcons.newCards, '2 new'),
    ]) {
      final icon = find.descendant(of: line, matching: find.byIcon(glyph));
      final text = find.descendant(
        of: line,
        matching: find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText() == words,
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

  testWidgets('a wrapping line, with glyphs or without, never breaks inside '
      'a term and never leaves a dot at a line edge (spec W1)', (tester) async {
    const terms = ['3 overdue', '5 today', '2 new'];
    // From the width where the widest term fits on one line.
    for (final hasIcons in [false, true]) {
      for (var width = 96.0; width <= 200; width += 2) {
        await pumpMx(
          tester,
          SizedBox(
            width: width,
            child: _line(canWrap: true, hasIcons: hasIcons),
          ),
        );
        final line = find.byType(MxWorkloadBreakdownLine);
        Finder term(String words) =>
            find.descendant(of: line, matching: find.text(words));
        for (final words in terms) {
          expect(
            tester.getSize(term(words)).height,
            _lineHeight(tester),
            reason: '$words at $width',
          );
        }
        final rows = {
          for (final words in terms) tester.getTopLeft(term(words)).dy,
        };
        final flow = tester.allRenderObjects.whereType<RenderTermFlow>().single;
        var shown = 0;
        flow.visitChildren((child) {
          final data = (child as RenderBox).parentData! as TermFlowParentData;
          if (data.isShown) shown++;
        });
        // Two dots join three terms; each line break hides one.
        expect(
          shown,
          terms.length + 2 - (rows.length - 1),
          reason: 'at $width',
        );
      }
    }
  });
}
