import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/mx_harness.dart';

OutlineInputBorder _enabledEdge(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!.enabledBorder!
        as OutlineInputBorder;

/// The height the fill and the edge are painted at: one line of the field's
/// style plus its padding. An outer `constraints` box would make the widget
/// taller than this without growing the paint, so none may be set.
double _paintedHeight(WidgetTester tester) {
  final TextField field = tester.widget(find.byType(TextField));
  final InputDecoration decoration = field.decoration!;
  expect(decoration.constraints, isNull);
  final EdgeInsets padding = decoration.contentPadding! as EdgeInsets;
  final TextStyle style = field.style!;
  return padding.vertical + style.fontSize! * style.height!;
}

void main() {
  testWidgets('form: 52 tall on the muted fill with an outline-variant edge', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(controller: TextEditingController()),
      ),
    );
    expect(tester.getSize(find.byType(TextField)).height, AppSize.field);
    expect(_paintedHeight(tester), AppSize.field);
    expect(_enabledEdge(tester).borderSide.color, s.outlineVariant);
  });

  testWidgets('an error turns the edge to error and shows its message', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Name',
          message: 'Enter a name',
        ),
      ),
    );
    expect(_enabledEdge(tester).borderSide.color, s.error);
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(find.text('Enter a name'), findsOneWidget);
  });

  testWidgets('a warning keeps the edge and shows its message', (tester) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          message: 'Close to the limit',
          messageTone: MxFieldMessageTone.warning,
        ),
      ),
    );
    expect(_enabledEdge(tester).borderSide.color, s.outlineVariant);
  });

  testWidgets('the label and the Required mark sit above the field', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Term',
          requiredText: 'Required',
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.text('Term')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('detail and meaning grow with their text', (tester) async {
    final controller = TextEditingController(text: 'one');
    await pumpMx(
      tester,
      SizedBox(
        width: 240,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.meaning,
        ),
      ),
    );
    expect(_paintedHeight(tester), AppSize.fieldMeaning);
    final double short = tester.getSize(find.byType(TextField)).height;
    controller.text = List.filled(12, 'a meaning that wraps').join(' ');
    await tester.pump();
    expect(
      tester.getSize(find.byType(InputDecorator)).height,
      greaterThan(short),
    );
  });

  testWidgets('code takes six digits only, centred', (tester) async {
    final controller = TextEditingController();
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.code,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '12a34567');
    expect(controller.text, '123456');
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.textAlign, TextAlign.center);
    expect(field.keyboardType, TextInputType.number);
  });

  testWidgets('study is bare: no fill and no edge', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          variant: MxTextFieldVariant.study,
        ),
      ),
    );
    final InputDecoration decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
  });
}
