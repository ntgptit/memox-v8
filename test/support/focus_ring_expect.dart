import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Makes the focus highlight show on a keyboard-less test host; resets it at
/// the end of the test.
void useKeyboardFocusHighlight() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// The element whose [Focus] node holds primary focus, as a finder.
Finder get _focused => find.byElementPredicate(
  (element) => element == FocusManager.instance.primaryFocus?.context,
  description: 'the element holding primary focus',
);

/// Presses Tab until the primary focus encloses [target], at most [limit]
/// times. Fails when the traversal never reaches it.
Future<void> tabTo(WidgetTester tester, Finder target, {int limit = 12}) async {
  for (var i = 0; i < limit; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    if (find.descendant(of: _focused, matching: target).evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Tab never moved focus onto $target in $limit presses');
}

/// The render object of the element holding primary focus: what a focus
/// ring on that control is painted through.
RenderObject focusedRender(WidgetTester tester) =>
    tester.renderObject(_focused);

/// Paints a ring of [color] and [width]: a stroked path, rect or rounded
/// rect, or a filled double rounded rect (how `Border.all` paints on a
/// rounded box, outer minus inner).
PaintPattern paintsFocusRing(Color color, {double width = 2}) =>
    paints..something((name, arguments) {
      final paint = arguments.whereType<Paint>().firstOrNull;
      if (paint == null || paint.color.toARGB32() != color.toARGB32()) {
        return false;
      }
      if (name == #drawDRRect) {
        final outer = arguments[0] as RRect;
        final inner = arguments[1] as RRect;
        return (outer.width - inner.width - 2 * width).abs() < 0.01;
      }
      return paint.style == PaintingStyle.stroke &&
          (paint.strokeWidth - width).abs() < 0.01;
    });
