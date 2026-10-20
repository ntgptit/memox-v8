import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// The [MxTermLine] that reads [line] ("3 overdue · 2 today"), or one whose
/// line holds it when [isContaining].
Finder findTermLine(String line, {bool isContaining = false}) =>
    find.byWidgetPredicate(
      (widget) =>
          widget is MxTermLine &&
          (isContaining ? widget.spoken.contains(line) : widget.spoken == line),
      description: 'MxTermLine "$line"',
    );

/// Expects the one [MxTermLine] under [finder] to keep The Wrap Rule (spec
/// W1): no dot starts or ends a line, and a term breaks only when it is
/// wider than the whole line.
void expectTermLineRule(WidgetTester tester, Finder finder) {
  final line = find.descendant(
    of: finder,
    matching: find.byType(MxTermLine),
    matchRoot: true,
  );
  // MxTermLine is a Semantics over its flow.
  final flow =
      (tester.renderObject(line) as RenderProxyBox).child! as RenderTermFlow;
  bool isDot(RenderBox box) =>
      box is RenderParagraph && box.text.toPlainText().trim() == '·';
  // Children centre on their line, so one line shares one centre.
  final lines = <double, List<({RenderBox box, Rect rect})>>{};
  flow.visitChildren((child) {
    final box = child as RenderBox;
    final data = box.parentData! as TermFlowParentData;
    if (!data.isShown) return;
    final rect = data.offset & box.size;
    lines.putIfAbsent(rect.center.dy.roundToDouble(), () => []).add((
      box: box,
      rect: rect,
    ));
    final natural = box.getMaxIntrinsicWidth(double.infinity);
    if (isDot(box) || natural > flow.size.width) return;
    expect(
      box.size.height,
      lessThanOrEqualTo(box.getMinIntrinsicHeight(double.infinity) + 0.5),
      reason: 'a term that fits a line breaks inside it',
    );
  });
  for (final row in lines.values) {
    row.sort((a, b) => a.rect.left.compareTo(b.rect.left));
    expect(isDot(row.first.box), isFalse, reason: 'a line starts on a dot');
    expect(isDot(row.last.box), isFalse, reason: 'a line ends on a dot');
  }
}
