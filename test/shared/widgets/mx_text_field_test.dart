import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

/// The decoration the field paints: its own, with the theme's defaults.
InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

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

  testWidgets('detail starts at the 48 touch minimum and grows with the text', (
    tester,
  ) async {
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
    expect(tester.getSize(find.byType(TextField)).height, 48);

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

  testWidgets('edges: ghost at rest, primaryInk focused', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));

    expect(_edge(_decoration(tester).enabledBorder), ghost);
    expect(
      _edge(_decoration(tester).focusedBorder),
      MxDerivedColors.primaryInkOf(scheme),
    );
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
    (MxTextFieldVariant.detail, 48.0),
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

  testWidgets('study is bare: no fill and no edge in any state, centred, '
      'one line, in the study term role (FE-A6 P4 F1)', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(variant: MxTextFieldVariant.study, label: 'Answer'),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final decoration = _decoration(tester);
    expect(decoration.filled, isFalse);
    for (final border in [
      decoration.border,
      decoration.enabledBorder,
      decoration.focusedBorder,
      decoration.disabledBorder,
    ]) {
      expect(border, InputBorder.none);
    }
    expect(decoration.contentPadding, EdgeInsets.zero);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textAlign, TextAlign.center);
    expect(field.maxLines, 1);
    expect(field.style!.fontSize, 32);
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the code variant asks for digits and offers the one-time '
      'code', (tester) async {
    await pumpMx(
      tester,
      const MxTextField(label: 'Code', variant: MxTextFieldVariant.code),
    );
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, [AutofillHints.oneTimeCode]);
    expect(field.maxLines, 1);
    expect(field.showCursor, isFalse);
  });

  testWidgets('the code variant paints six slots, one digit in each', (
    tester,
  ) async {
    final controller = TextEditingController(text: '427');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    for (var i = 0; i < MxTextField.codeLength; i++) {
      expect(find.byKey(MxTextField.slotKey(i)), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(MxTextField.slotKey(1)),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byKey(MxTextField.slotKey(0))).width, 48);
    expect(
      tester.getSize(find.byKey(MxTextField.slotKey(0))).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('a pasted "123 456" fills six slots', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    await tester.enterText(find.byType(TextField), '123 456');
    await tester.pump();

    expect(controller.text, '123456');
    expect(
      find.descendant(
        of: find.byKey(MxTextField.slotKey(5)),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the slot that takes the next digit carries the focus edge; '
      'the rest the outline; an error edges every slot', (tester) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    Border edgeOf(int i) =>
        (tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.byKey(MxTextField.slotKey(i)),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .border!
            as Border;

    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        autofocus: true,
      ),
    );
    await tester.pump();
    expect(edgeOf(2).top.color, derived.primaryInk);
    expect(edgeOf(2).top.width, 2);
    expect(edgeOf(3).top.color, scheme.outline);

    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        errorText: 'Wrong',
      ),
    );
    expect(edgeOf(0).top.color, scheme.error);
    expect(edgeOf(5).top.color, scheme.error);
  });

  testWidgets('a tap on a slot focuses the code', (tester) async {
    await pumpMx(tester, const MxTextField(variant: MxTextFieldVariant.code));

    // The hidden field covers the slots and takes the tap itself.
    await tester.tap(find.byKey(MxTextField.slotKey(4)), warnIfMissed: false);
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('six slots fit a 288 wide column', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 288,
        child: MxTextField(variant: MxTextFieldVariant.code),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(MxTextField.slotKey(0))).width,
      lessThan(48),
    );
  });

  testWidgets('TalkBack still reads the code field by its label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxTextField(
        label: 'Code, 6 digits',
        variant: MxTextFieldVariant.code,
      ),
    );

    expect(find.bySemanticsLabel('Code, 6 digits'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the code variant keeps six digits and nothing else', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    await tester.enterText(find.byType(TextField), '12a3456789');

    expect(controller.text, '123456');
    expect(MxTextField.codeLength, 6);
  });
}
