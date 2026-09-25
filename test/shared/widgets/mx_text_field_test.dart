import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

Color _edge(InputBorder? border) =>
    (border! as OutlineInputBorder).borderSide.color;

void main() {
  final scheme = AppColorSchemes.light;
  final ghost = MxDerivedColors.resolve(
    scheme,
    MxSemanticColors.light,
  ).ghostBorder;

  testWidgets('single line is 52 tall', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')),
    );

    expect(tester.getSize(find.byType(TextField)).height, 52);
  });

  testWidgets('detail starts at 40 and grows with the text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.detail,
        ),
      ),
    );
    expect(tester.getSize(find.byType(TextField)).height, 40);

    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pump();
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(60));
  });

  testWidgets('fill: surface-muted at rest, lowest when focused', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    final fill = _decoration(tester).fillColor!;

    expect(
      WidgetStateProperty.resolveAs(fill, <WidgetState>{}),
      scheme.surfaceContainerLow,
    );
    expect(
      WidgetStateProperty.resolveAs(fill, {WidgetState.focused}),
      scheme.surfaceContainerLowest,
    );
  });

  testWidgets('edges: ghost at rest, primary focused', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));

    expect(_edge(_decoration(tester).enabledBorder), ghost);
    expect(_edge(_decoration(tester).focusedBorder), scheme.primary);
  });

  testWidgets('an error colours the edge and pushes a message below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(errorText: 'Name is required'),
      ),
    );

    expect(_edge(_decoration(tester).enabledBorder), scheme.error);
    expect(_edge(_decoration(tester).focusedBorder), scheme.error);
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(MxFieldMessage)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TextField)).dy),
    );
    expect(tester.getSize(find.byType(TextField)).height, 52);
  });

  testWidgets('typing reports the value', (tester) async {
    String? typed;
    await pumpMx(
      tester,
      SizedBox(width: 300, child: MxTextField(onChanged: (v) => typed = v)),
    );
    await tester.enterText(find.byType(TextField), 'Verbs');

    expect(typed, 'Verbs');
  });

  testWidgets('disabled dims the whole field', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(isEnabled: false)),
    );

    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byType(TextField),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('2x text grows the single-line box', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(52),
    );
  });

  testWidgets('a filled field keeps its name for TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController(text: 'gamsa');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          label: 'Front',
          hintText: 'The term',
          controller: controller,
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(EditableText));
    expect(node.label, contains('Front'));
    expect(node.value, 'gamsa');
    handle.dispose();
  });

  for (final (variant, floor) in [
    (MxTextFieldVariant.form, 52.0),
    (MxTextFieldVariant.detail, 40.0),
    (MxTextFieldVariant.meaning, 76.0),
    (MxTextFieldVariant.term, 66.0),
  ]) {
    testWidgets('${variant.name}: its kit floor', (tester) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 300,
          child: MxTextField(hintText: 'x', variant: variant),
        ),
      );

      expect(tester.getSize(find.byType(TextField)).height, floor);
    });
  }

  testWidgets('the editor variants rest on the lowest fill', (tester) async {
    for (final variant in [
      MxTextFieldVariant.detail,
      MxTextFieldVariant.meaning,
      MxTextFieldVariant.term,
    ]) {
      await pumpMx(
        tester,
        SizedBox(width: 300, child: MxTextField(variant: variant)),
      );
      expect(
        WidgetStateProperty.resolveAs(
          _decoration(tester).fillColor!,
          <WidgetState>{},
        ),
        scheme.surfaceContainerLowest,
        reason: variant.name,
      );
    }
  });

  testWidgets('term: wraps, and a long term steps down to 18', (tester) async {
    final controller = TextEditingController(text: 'a' * 60);
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.term,
        ),
      ),
    );

    EditableText text() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(text().maxLines, isNull);
    expect(text().style.fontSize, 18);
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(66));

    controller.text = 'gamsa';
    await tester.pump();
    expect(text().style.fontSize, 24);
  });

  testWidgets('term: Enter moves on and adds no newline', (tester) async {
    final controller = TextEditingController(text: 'gamsa');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.term,
          textInputAction: TextInputAction.next,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(controller.text, 'gamsa');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.text,
    );
  });

  testWidgets('a message sits below any variant and pushes on', (tester) async {
    for (final variant in MxTextFieldVariant.values) {
      await pumpMx(
        tester,
        SizedBox(
          width: 300,
          child: MxTextField(variant: variant, errorText: 'Required'),
        ),
      );
      expect(
        tester.getTopLeft(find.byType(MxFieldMessage)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TextField)).dy),
        reason: variant.name,
      );
    }
  });

  testWidgets('a long hint never pads a filled or a short field', (
    tester,
  ) async {
    const hint = 'The meaning; separate several with commas';
    final controller = TextEditingController(text: 'thank you');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          hintText: hint,
          variant: MxTextFieldVariant.meaning,
        ),
      ),
    );
    expect(tester.getSize(find.byType(TextField)).height, 76);

    controller.clear();
    await tester.pump();
    // Two lines of hint fit the 76 floor inside the kit's 12 padding.
    expect(tester.getSize(find.byType(TextField)).height, 76);
  });

  testWidgets('a long meaning grows past its floor on the kit padding', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'one\ntwo\nthree\nfour');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.meaning,
        ),
      ),
    );

    final text = tester.getSize(find.byType(EditableText)).height;
    expect(tester.getSize(find.byType(TextField)).height, text + 24);
  });

  testWidgets('an editor box follows typing without a caller controller', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(variant: MxTextFieldVariant.term),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'a' * 40);
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).style.fontSize,
      18,
    );
  });

  test('only a form field takes leading and trailing slots', () {
    expect(
      () => MxTextField(
        variant: MxTextFieldVariant.meaning,
        leading: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('a form field at 2x still sits on its 52 floor', (tester) async {
    await pumpMx(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')),
      ),
    );

    // 21 of text at 2x is 42: it fits the floor, so the box stays 52.
    expect(tester.getSize(find.byType(TextField)).height, 52);
  });
}
