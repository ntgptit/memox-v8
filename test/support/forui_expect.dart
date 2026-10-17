import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as mu;
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

/// The render object that paints the focus ring of the control holding
/// primary focus: ForUI draws the ring from the [FFocusedOutline] around the
/// control, not from the focused node itself. Pair it with `paintsFocusRing`.
RenderObject focusRingRender(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus!.context!;
  final outline = find.ancestor(
    of: find.byElementPredicate((element) => element == focused),
    matching: find.byType(FFocusedOutline),
  );
  return tester.renderObject(outline.first);
}

/// The ForUI button named [label] by its semantics label: the icon buttons,
/// FABs and steppers carry their name there and no longer wrap a Material
/// `Tooltip`, so `find.byTooltip` finds none of them. [label] is the exact
/// name, or a [RegExp] the name must match.
Finder byControlLabel(Pattern label) => find.byWidgetPredicate((widget) {
  if (widget is! FButton) return false;
  final name = widget.semanticsLabel;
  if (name == null) return false;
  return label is String ? name == label : label.allMatches(name).isNotEmpty;
}, description: 'FButton named $label');

/// The box a ForUI text field paints for its input: the decorator inside
/// [field], without the label above it or the supporting row below it.
Finder fieldBox(Finder field) =>
    find.descendant(of: field, matching: find.byType(mu.InputDecorator)).first;

/// The size of [fieldBox].
Size fieldBoxSize(WidgetTester tester, Finder field) =>
    tester.getSize(fieldBox(field));

/// Expects the painted text [label] to read in ForUI's form-field label
/// style: a field's label is set by ForUI's label, not by its own `TextStyle`,
/// so the style it reads is the ambient one.
void expectForUiFieldLabel(WidgetTester tester, Finder label) {
  final ambient = DefaultTextStyle.of(tester.element(label)).style;
  final expected = forUiTheme(
    tester,
    label,
  ).style.formFieldStyle.labelTextStyle.resolve({});
  expect(
    (ambient.color, ambient.fontSize, ambient.fontWeight, ambient.fontFamily),
    (
      expected.color,
      expected.fontSize,
      expected.fontWeight,
      expected.fontFamily,
    ),
    reason: 'the field label reads in ForUI\'s form-field label style',
  );
}

/// The icon theme ForUI's circular progress draws the spinner glyph with
/// (its size and ink), first under [spinner] (an MxSpinner).
IconThemeData spinnerIconTheme(WidgetTester tester, Finder spinner) => tester
    .widget<IconTheme>(
      find
          .descendant(
            of: find.descendant(
              of: spinner,
              matching: find.byType(FCircularProgress),
            ),
            matching: find.byType(IconTheme),
          )
          .first,
    )
    .data;
