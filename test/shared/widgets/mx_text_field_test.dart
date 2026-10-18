import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as mu;
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _field = find.byType(FTextField);

/// The decoration the field paints: its own, with the theme's defaults.
mu.InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<mu.InputDecorator>(find.byType(mu.InputDecorator)).decoration;

/// The outlined edge the decorator takes in [states].
mu.OutlineInputBorder _in(WidgetTester tester, Set<mu.WidgetState> states) =>
    (_decoration(tester).border! as mu.WidgetStateProperty<mu.InputBorder>)
            .resolve(states)
        as mu.OutlineInputBorder;

Color _edge(mu.OutlineInputBorder border) => border.borderSide.color;

double _boxHeight(WidgetTester tester) => fieldBoxSize(tester, _field).height;

FTextFieldStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _field).textFieldStyles.lg;

void main() {
  final colors = appLightColors;

  testWidgets('single line is the large ForUI field tall', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')),
    );

    expect(_boxHeight(tester), _style(tester).constraints.minHeight);
    expect(_boxHeight(tester), greaterThanOrEqualTo(48));
  });

  testWidgets('detail starts at the form field\'s height and grows with the '
      'text', (tester) async {
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
    final rest = _style(tester).constraints.minHeight;
    expect(_boxHeight(tester), rest);

    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pump();
    expect(_boxHeight(tester), greaterThan(rest + 4));
  });

  testWidgets('outlined on the card ground, focused or not', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));

    expect(_decoration(tester).filled, isTrue);
    expect(_decoration(tester).fillColor, colors.card);
  });

  testWidgets('edges: border at rest, the primary focused, the disabled '
      'border disabled (DEV-166)', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    expect(_edge(_in(tester, {})), colors.border);
    expect(_edge(_in(tester, {mu.WidgetState.focused})), colors.primary);

    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(isEnabled: false)),
    );
    expect(
      _edge(_in(tester, {mu.WidgetState.disabled})),
      colors.disable(colors.border),
    );
  });

  testWidgets('every edged variant rests on the border', (tester) async {
    for (final variant in [
      MxTextFieldVariant.form,
      MxTextFieldVariant.detail,
      MxTextFieldVariant.term,
    ]) {
      await pumpMx(
        tester,
        SizedBox(width: 300, child: MxTextField(variant: variant)),
      );
      expect(_edge(_in(tester, {})), colors.border, reason: '$variant');
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
    await tester.pumpAndSettle();

    expect(_edge(_in(tester, {mu.WidgetState.error})), colors.error);
    expect(
      _edge(_in(tester, {mu.WidgetState.error, mu.WidgetState.focused})),
      colors.error,
    );
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(MxFieldMessage)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(fieldBox(_field)).dy),
    );
    expect(_boxHeight(tester), _style(tester).constraints.minHeight);
  });

  testWidgets('typing reports the value', (tester) async {
    String? typed;
    await pumpMx(
      tester,
      SizedBox(width: 300, child: MxTextField(onChanged: (v) => typed = v)),
    );
    await tester.enterText(find.byType(EditableText), 'Verbs');

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

    // The field's own node, the one TalkBack focuses, carries the name with
    // the value.
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

      expect(_boxHeight(tester), _style(tester).constraints.minHeight);
      final decoration = _decoration(tester);
      expect(decoration.fillColor, colors.card);
      final edge = _in(tester, {});
      expect(edge.borderSide.color, colors.border);
      expect(
        edge.borderRadius,
        tester.element(find.byType(EditableText)).radii.md,
      );
      final text = tester.widget<EditableText>(find.byType(EditableText));
      final content = _style(tester).contentTextStyle.resolve({});
      expect(text.style.fontSize, content.fontSize);
      expect(text.style.fontWeight, content.fontWeight);
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
    expect(
      text.style.fontSize,
      _style(tester).contentTextStyle.resolve({}).fontSize,
    );
    expect(
      _boxHeight(tester),
      greaterThan(_style(tester).constraints.minHeight),
    );
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
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(MxFieldMessage)).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byType(EditableText)).dy,
        ),
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
    final rest = _style(tester).constraints.minHeight;
    final typed = _boxHeight(tester);
    expect(typed, greaterThan(rest));

    controller.clear();
    await tester.pumpAndSettle();
    expect(_boxHeight(tester), typed);

    controller.text = 'nunchi';
    await tester.pumpAndSettle();
    expect(_boxHeight(tester), rest);
  });

  testWidgets('a long detail grows past its floor on the content padding', (
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
    expect(_boxHeight(tester), text + _style(tester).contentPadding.vertical);
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
    final rest = _boxHeight(tester);
    await tester.enterText(find.byType(EditableText), 'a' * 80);
    await tester.pump();

    expect(_boxHeight(tester), greaterThan(rest));
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

  testWidgets('a study answer gets no suggestions and no autocorrect; a form '
      'field keeps them (BR-STUDY-026, audit 2026-10-17)', (tester) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxTextField(variant: MxTextFieldVariant.study, label: 'Answer'),
          MxTextField(label: 'Name'),
        ],
      ),
    );
    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    expect(fields.first.autocorrect, isFalse);
    expect(fields.first.enableSuggestions, isFalse);
    expect(fields.last.autocorrect, isTrue);
    expect(fields.last.enableSuggestions, isTrue);
  });

  testWidgets('study is bare: no edge in any state, centred, one line, in '
      'the study term role (FE-A6 P4 F1)', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(variant: MxTextFieldVariant.study, label: 'Answer'),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    final decoration = _decoration(tester);
    final border = decoration.border! as mu.WidgetStateProperty<mu.InputBorder>;
    for (final states in [
      <mu.WidgetState>{},
      {mu.WidgetState.focused},
      {mu.WidgetState.hovered},
      {mu.WidgetState.disabled},
      {mu.WidgetState.error},
    ]) {
      expect(border.resolve(states), mu.InputBorder.none, reason: '$states');
    }
    expect(decoration.contentPadding, EdgeInsets.zero);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.textAlign, TextAlign.center);
    expect(field.maxLines, 1);
    expect(
      field.style.fontSize,
      tester.element(find.byType(EditableText)).texts.term.fontSize,
    );
    expect(tester.getSize(_field).height, greaterThanOrEqualTo(48));
  });
}
