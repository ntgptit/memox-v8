import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

/// The [ShapeDecoration] ForUI paints for the [FButton] (or other
/// [FTappable]-built control) under [control], in its current state: the
/// first decorated box inside it.
ShapeDecoration paintedDecoration(WidgetTester tester, Finder control) {
  final boxes = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox && widget.decoration is ShapeDecoration,
    ),
  );
  return tester.widget<DecoratedBox>(boxes.first).decoration as ShapeDecoration;
}

/// The rect ForUI's decoration actually paints under [control]: a control
/// drawn smaller than its 48 target (mxInsetDecoration) paints inside it.
Rect paintedRect(WidgetTester tester, Finder control) {
  final boxes = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox && widget.decoration is ShapeDecoration,
    ),
  );
  final box = boxes.first;
  final rect = tester.getRect(box);
  final decoration =
      tester.widget<DecoratedBox>(box).decoration as ShapeDecoration;
  return decoration.shape
      .getOuterPath(rect, textDirection: TextDirection.ltr)
      .getBounds();
}

/// The side of the border ForUI paints under [control], or none.
BorderSide paintedSide(WidgetTester tester, Finder control) {
  final painted = paintedDecoration(tester, control).shape;
  // An inset shape wraps the ForUI one.
  final shape = painted is MxInsetShapeBorder ? painted.base : painted;
  return shape is OutlinedBorder ? shape.side : BorderSide.none;
}

/// The colour the text [text] is drawn in: its own style over the ambient
/// default style.
Color? textColor(WidgetTester tester, Finder text) {
  final widget = tester.widget<Text>(text);
  final ambient = DefaultTextStyle.of(tester.element(text)).style;
  return widget.style?.color ?? ambient.color;
}

/// The colour of the icon [icon]: its own colour over the ambient icon theme.
Color? iconColor(WidgetTester tester, Finder icon) {
  final widget = tester.widget<Icon>(icon);
  return widget.color ?? IconTheme.of(tester.element(icon)).color;
}

/// The ForUI theme the widget under [finder] reads.
FThemeData forUiTheme(WidgetTester tester, Finder finder) =>
    FTheme.of(tester.element(finder));
