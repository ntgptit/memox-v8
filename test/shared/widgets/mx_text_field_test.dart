import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_palette.dart';

import '../../support/theme_expect.dart';

import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/field_edge_expect.dart';
import '../../support/widget_harness.dart';

/// The decoration the field paints: its own, with the theme's defaults.
InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

Color _edge(OutlineInputBorder border) => border.borderSide.color;

OutlineInputBorder _in(WidgetTester tester, Set<WidgetState> states) =>
    edgeIn(_decoration(tester), states);

void main() {
  final scheme = lightColorScheme;
  // The M3 disabled edge: onSurface at the container opacity.
  final ghost = scheme.onSurface.withValues(alpha: 0.12);

  testWidgets('single line is 56 tall', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')),
    );

    expect(tester.getSize(find.byType(TextField)).height, 56);
  });

  testWidgets('detail starts at the form field\'s 56 and grows with the text', (
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
    expect(tester.getSize(find.byType(TextField)).height, 56);

    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pump();
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(60));
  });

  testWidgets('outlined, no fill: the sheet ground shows through, focused '
      'or not', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));

    expect(_decoration(tester).filled, isNot(isTrue));
    expect(_decoration(tester).fillColor, isNull);
  });

  testWidgets('edges: outline edge at rest, the accent focused, ghost '
      'disabled (DEV-166)', (tester) async {
    final rest = scheme.outline;
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    expect(_edge(_in(tester, {})), rest);
    expect(_edge(_in(tester, {WidgetState.focused})), accentOf(scheme));

    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(isEnabled: false)),
    );
    expect(_edge(_in(tester, {WidgetState.disabled})), ghost);
  });

  testWidgets('every edged variant rests on the outline', (tester) async {
    for (final variant in [
      MxTextFieldVariant.form,
      MxTextFieldVariant.detail,
      MxTextFieldVariant.term,
    ]) {
      await pumpMx(
        tester,
        SizedBox(width: 300, child: MxTextField(variant: variant)),
      );
      expect(_edge(_in(tester, {})), scheme.outline, reason: '$variant');
    }
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

    expect(_decoration(tester).error, isNotNull);
    expect(_edge(_in(tester, {WidgetState.error})), scheme.error);
    expect(
      _edge(_in(tester, {WidgetState.error, WidgetState.focused})),
      scheme.error,
    );
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(MxFieldMessage)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TextField)).dy),
    );
    expect(tester.getSize(find.byType(TextField)).height, 56);
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

  // Every boxed variant is the form field's box and type (DEV-169).
  for (final variant in [
    MxTextFieldVariant.form,
    MxTextFieldVariant.detail,
    MxTextFieldVariant.term,
  ]) {
    testWidgets('${variant.name}: the form box, edge and type', (tester) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 300,
          child: MxTextField(hintText: 'x', variant: variant),
        ),
      );

      expect(tester.getSize(find.byType(TextField)).height, 56);
      final decoration = _decoration(tester);
      expect(decoration.fillColor, isNull);
      final edge = edgeIn(decoration, {});
      expect(edge.borderSide.color, scheme.outline);
      expect(edge.borderRadius, BorderRadius.circular(12));
      final style = tester.widget<EditableText>(find.byType(EditableText));
      expect(style.style.fontSize, 16);
      expect(style.style.fontWeight, FontWeight.w400);
    });
  }

  testWidgets('term: wraps and grows, in the input role', (tester) async {
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

    final text = tester.widget<EditableText>(find.byType(EditableText));
    expect(text.maxLines, isNull);
    expect(text.style.fontSize, 16);
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(56));
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

  testWidgets('a wrapping hint holds its room only while the box is empty', (
    tester,
  ) async {
    const hint = 'A clue that jogs memory without giving the answer';
    final controller = TextEditingController(text: hint);
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          hintText: hint,
          variant: MxTextFieldVariant.detail,
        ),
      ),
    );
    final typed = tester.getSize(find.byType(TextField)).height;
    expect(typed, greaterThan(56));

    controller.clear();
    await tester.pump();
    expect(tester.getSize(find.byType(TextField)).height, typed);

    controller.text = 'nunchi';
    await tester.pump();
    expect(tester.getSize(find.byType(TextField)).height, 56);
  });

  testWidgets('a long detail grows past its floor on the 12 padding', (
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
          variant: MxTextFieldVariant.detail,
        ),
      ),
    );

    final text = tester.getSize(find.byType(EditableText)).height;
    expect(tester.getSize(find.byType(TextField)).height, text + 24);
  });

  testWidgets('a multi-line box follows typing without a caller controller', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(variant: MxTextFieldVariant.term),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'a' * 80);
    await tester.pump();

    expect(tester.getSize(find.byType(TextField)).height, greaterThan(56));
  });

  test('only a form field takes leading and trailing slots', () {
    expect(
      () => MxTextField(
        variant: MxTextFieldVariant.detail,
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
    expect(
      field.style!.fontSize,
      tester.element(find.byType(TextField)).texts.term.fontSize,
    );
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
