import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';
import 'package:memox/shared/widgets/mx_term_flow.dart';

import '../../support/term_line.dart';
import '../../support/widget_harness.dart';

const _line = '3 overdue · 2 today · 4 new · 12 scheduled';

/// Where each child of the flow landed: its rect, whether it is a dot and
/// whether it is painted.
List<({Rect rect, bool isDot, bool isShown})> _placed(WidgetTester tester) {
  final flow = tester.allRenderObjects.whereType<RenderTermFlow>().single;
  final origin = flow.localToGlobal(Offset.zero);
  final out = <({Rect rect, bool isDot, bool isShown})>[];
  var child = flow.firstChild;
  while (child != null) {
    final data = child.parentData! as TermFlowParentData;
    final text = child is RenderParagraph ? child.text.toPlainText() : '';
    out.add((
      rect: (origin + data.offset) & child.size,
      isDot: text.trim() == '·' || text == ' · ',
      isShown: data.isShown,
    ));
    child = data.nextSibling;
  }
  return out;
}

/// The painted children grouped by line, each line in reading order.
List<List<({Rect rect, bool isDot, bool isShown})>> _lines(
  WidgetTester tester,
) {
  final shown = _placed(tester).where((child) => child.isShown).toList();
  final lines = <double, List<({Rect rect, bool isDot, bool isShown})>>{};
  for (final child in shown) {
    final key = lines.keys.firstWhere(
      (top) =>
          child.rect.center.dy > top - 2 &&
          child.rect.center.dy < top + child.rect.height,
      orElse: () => child.rect.top,
    );
    lines.putIfAbsent(key, () => []).add(child);
  }
  return [
    for (final line in lines.values)
      line..sort((a, b) => a.rect.left.compareTo(b.rect.left)),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  Widget line, {
  double width = 328,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) => pumpMx(
  tester,
  Directionality(
    textDirection: direction,
    child: SizedBox(width: width, child: line),
  ),
  textScale: textScale,
);

void main() {
  // Spec W1: whatever the width or the text scale, a line never starts or
  // ends on a dot, and nothing runs past the width.
  for (final textScale in [1.0, 1.3]) {
    testWidgets('no dot at either end of a line, at any width (scale '
        '$textScale)', (tester) async {
      var maxLines = 0;
      for (var width = 360.0; width >= 70; width -= 10) {
        await _pump(
          tester,
          MxTermLine.text(_line),
          width: width,
          textScale: textScale,
        );
        final lines = _lines(tester);
        maxLines = lines.length > maxLines ? lines.length : maxLines;
        for (final line in lines) {
          expect(line.first.isDot, isFalse, reason: 'width $width starts');
          expect(line.last.isDot, isFalse, reason: 'width $width ends');
        }
        final terms = _placed(tester).where((child) => !child.isDot);
        expect(terms.length, 4, reason: 'every term is laid out');
        final box = tester.getRect(find.byType(MxTermLine));
        expect(box.width, lessThanOrEqualTo(width + 0.5));
        for (final child in _placed(tester).where((c) => c.isShown)) {
          expect(child.rect.right, lessThanOrEqualTo(box.right + 0.5));
        }
        expect(tester.takeException(), isNull);
      }
      expect(maxLines, greaterThan(2), reason: 'the widths reach a wrap');
    });
  }

  // Final review I1: at a width that holds two terms and their dot within
  // a hair, the second term keeps its one-line width instead of breaking.
  testWidgets('a term that just fits after its dot never breaks inside', (
    tester,
  ) async {
    await _pump(tester, MxTermLine.text('3 overdue · 4 new'), width: 400);
    final placed = _placed(tester);
    final exact = placed.last.rect.right - placed.first.rect.left;
    for (final slack in [-0.009, -0.005, -0.001, 0, 0.001]) {
      await _pump(
        tester,
        MxTermLine.text('3 overdue · 4 new'),
        width: exact + slack,
      );
      expectTermLineRule(tester, find.byType(MxTermLine));
      expect(_lines(tester), hasLength(1), reason: 'slack $slack');
    }
  });

  testWidgets('capped at two lines, the term past the cap ends the last '
      'line in an ellipsis, the rest is not drawn, and the line is read '
      'whole', (tester) async {
    final handle = tester.ensureSemantics();
    const line =
        'Tiếng Hàn TOPIK I · Từ vựng sơ cấp · Learning · Stage 1 of 3 · '
        'Match · Round 2';
    await _pump(tester, MxTermLine.text(line, maxLines: 2), width: 200);
    expect(_lines(tester), hasLength(2));
    expect(isTermLineCut(tester, find.byType(MxTermLine)), isTrue);
    expectTermLineRule(tester, find.byType(MxTermLine));
    expect(find.bySemanticsLabel(line), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Room for all of it: nothing is cut.
    await _pump(tester, MxTermLine.text(line, maxLines: 2), width: 600);
    expect(isTermLineCut(tester, find.byType(MxTermLine)), isFalse);
    handle.dispose();
  });

  testWidgets('a line takes its tones from the theme, light and dark', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpMx(
        tester,
        const MxTermLine(
          terms: [
            MxTerm('3 overdue', tone: MxTermTone.warning),
            MxTerm('4 new'),
          ],
        ),
        brightness: brightness,
      );
      final context = tester.element(find.byType(MxTermLine));
      Color? ink(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      expect(ink('3 overdue'), context.status.warning, reason: '$brightness');
      expect(
        ink('4 new'),
        context.colors.mutedForeground,
        reason: '$brightness',
      );
    }
  });

  testWidgets('a line that fits keeps every dot', (tester) async {
    await _pump(tester, MxTermLine.text('3 overdue · 2 today'));
    expect(_lines(tester), hasLength(1));
    expect(_placed(tester).map((child) => child.isShown), everyElement(true));
  });

  testWidgets('a term wider than the line takes a line of its own and wraps '
      'at its own spaces', (tester) async {
    await _pump(
      tester,
      MxTermLine.text(
        'Tiếng Hàn TOPIK I Từ vựng chủ đề gia đình và trường học · 12 cards',
      ),
      width: 120,
    );
    final terms = _placed(tester).where((child) => !child.isDot).toList();
    expect(terms.first.rect.width, lessThanOrEqualTo(120));
    expect(terms.first.rect.height, greaterThan(terms.last.rect.height));
    expect(terms.last.rect.top, greaterThanOrEqualTo(terms.first.rect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a line with no dot is one term that wraps as text does', (
    tester,
  ) async {
    await _pump(
      tester,
      MxTermLine.text('Nothing due. Review opens once cards are due.'),
      width: 120,
    );
    expect(_placed(tester), hasLength(1));
    expect(
      find.text('Nothing due. Review opens once cards are due.'),
      findsOneWidget,
    );
  });

  testWidgets('a lead is followed by its gap, not a dot: a word gap in the '
      "line's style, a wider one after a label", (tester) async {
    for (final (lead, gap) in [
      (const MxTermLead.plain('Card-days:'), 4.0),
      (const MxTermLead.label('Add details'), 8.0),
    ]) {
      await _pump(
        tester,
        MxTermLine(
          lead: lead,
          terms: const [MxTerm('3 learning'), MxTerm('5 reviewing')],
        ),
      );
      final placed = _placed(tester);
      expect(placed[1].rect.left - placed[0].rect.right, closeTo(gap, 0.01));
      expect(placed.where((child) => child.isDot), hasLength(1));
    }
  });

  testWidgets('a trail follows the last term after a word gap, and moves '
      'to the next line whole', (tester) async {
    const line = MxTermLine(
      terms: [MxTerm('5 overdue'), MxTerm('5 today')],
      trail: 'across 3 decks',
    );
    await _pump(tester, line);
    var placed = _placed(tester);
    expect(placed.last.rect.left - placed[2].rect.right, closeTo(4, 0.01));

    await _pump(tester, line, width: 150);
    placed = _placed(tester);
    expect(placed.last.rect.left, placed.first.rect.left);
    expect(placed.last.rect.top, greaterThan(placed.first.rect.top));
  });

  testWidgets('a centred line sits in the middle of its width', (tester) async {
    await _pump(
      tester,
      MxTermLine.text('3 overdue · 2 today', align: MxTermLineAlign.center),
    );
    final line = _lines(tester).single;
    final box = tester.getRect(find.byType(MxTermLine));
    expect(
      line.first.rect.left - box.left,
      closeTo(box.right - line.last.rect.right, 0.5),
    );
  });

  testWidgets('right to left, the first term is at the right', (tester) async {
    await _pump(
      tester,
      MxTermLine.text('3 overdue · 2 today'),
      direction: TextDirection.rtl,
    );
    final placed = _placed(tester);
    expect(placed.first.rect.left, greaterThan(placed.last.rect.left));
  });

  testWidgets('it reads as one node: the whole line, or its own label; the '
      'lead and trail read with it, the glyphs say nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const MxTermLine(
        lead: MxTermLead.plain('Due:'),
        terms: [
          MxTerm('3 overdue', glyph: AppIcons.overdue),
          MxTerm('2 today', glyph: AppIcons.dueNow),
        ],
        trail: 'across 2 decks',
      ),
    );
    expect(
      find.bySemanticsLabel('Due: 3 overdue · 2 today across 2 decks'),
      findsOneWidget,
    );

    await _pump(
      tester,
      MxTermLine.text('3 · 4', semanticsLabel: 'three of four'),
    );
    expect(find.bySemanticsLabel('three of four'), findsOneWidget);
    expect(find.bySemanticsLabel('3 · 4'), findsNothing);
    handle.dispose();
  });
}
