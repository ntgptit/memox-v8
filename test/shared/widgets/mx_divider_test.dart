import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_divider.dart';

import '../../support/widget_harness.dart';

Rect _line(WidgetTester tester) => tester.getRect(
  find.descendant(
    of: find.byType(MxDivider),
    matching: find.byType(ColoredBox),
  ),
);

void main() {
  testWidgets('the line is a hairline in the border colour, at the content '
      'edge by default', (tester) async {
    await pumpMx(tester, const MxDivider());
    final context = tester.element(find.byType(MxDivider));
    final screen = tester.getRect(find.byType(MxDivider));

    final line = _line(tester);
    expect(line.height, context.hairline);
    expect(line.left - screen.left, context.dimens.space16);
    expect(screen.right - line.right, context.dimens.space16);
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(MxDivider),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, context.colors.border);
  });

  testWidgets('an inset moves both ends in', (tester) async {
    await pumpMx(tester, const MxDivider(inset: 24));
    final screen = tester.getRect(find.byType(MxDivider));

    final line = _line(tester);
    expect(line.left - screen.left, 24);
    expect(screen.right - line.right, 24);
  });
}
