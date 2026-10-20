import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as mu;
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _field = find.byType(FTextField);

/// The decoration the field paints: its own, with the theme's defaults.
mu.InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<mu.InputDecorator>(find.byType(mu.InputDecorator)).decoration;

/// The outlined edge the decorator takes in [states].
Color _edgeIn(WidgetTester tester, Set<mu.WidgetState> states) =>
    ((_decoration(tester).border! as mu.WidgetStateProperty<mu.InputBorder>)
                .resolve(states)
            as mu.OutlineInputBorder)
        .borderSide
        .color;

/// The colour the painted [text] reads in: the ambient style over it.
Color? _inkOf(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  return widget.style?.color ??
      DefaultTextStyle.of(tester.element(find.text(text))).style.color;
}

/// The painted label, the supporting row, the disabled state, the caret and
/// the autofocus of [MxTextField] (DEV-372).
void main() {
  final colors = appLightColors;

  testWidgets('disabled: the ForUI disabled values once, no wrapper dimming '
      'the edge a second time (DEV-372 R2)', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(
          isEnabled: false,
          label: 'Name',
          hintText: 'Deck',
          supportingText: 'Shown on the card',
          counter: '0 / 60',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(of: _field, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
    expect(
      _edgeIn(tester, {mu.WidgetState.disabled}),
      colors.disable(colors.border),
    );
    expect(_inkOf(tester, 'Name'), colors.disable(colors.foreground));
    expect(
      _inkOf(tester, 'Shown on the card'),
      colors.disable(colors.mutedForeground),
    );
    expect(_inkOf(tester, '0 / 60'), colors.disable(colors.mutedForeground));
    expect(_inkOf(tester, 'Deck'), colors.disable(colors.mutedForeground));
  });

  testWidgets('the painted label sits above the field in ForUI\'s label '
      'style', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(label: 'Deck name')),
    );

    final label = find.text('Deck name');
    expect(label, findsOneWidget);
    expectForUiFieldLabel(tester, label);
    expect(
      tester.getTopLeft(fieldBox(_field)).dy - tester.getBottomLeft(label).dy,
      forUiTheme(
        tester,
        _field,
      ).textFieldStyles.lg.labelPadding.resolve(TextDirection.ltr).bottom,
    );
    // The label starts on the field's edge.
    expect(tester.getTopLeft(label).dx, tester.getTopLeft(fieldBox(_field)).dx);
  });

  testWidgets('the field keeps the label as its name for TalkBack, painted '
      'once', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(label: 'Deck name')),
    );

    expect(
      tester.getSemantics(find.byType(EditableText)).label,
      contains('Deck name'),
    );
    // Painted once for TalkBack: a node carries it, not the Text.
    expect(find.bySemanticsLabel('Deck name'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an error turns the painted label to the error colour', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(label: 'Deck name', errorText: 'Required'),
      ),
    );
    await tester.pumpAndSettle();

    expect(_inkOf(tester, 'Deck name'), colors.error);
  });

  testWidgets('a bare study field and a code field paint no label', (
    tester,
  ) async {
    for (final variant in [MxTextFieldVariant.study, MxTextFieldVariant.code]) {
      await pumpMx(
        tester,
        SizedBox(
          width: 300,
          child: MxTextField(label: 'Answer', variant: variant),
        ),
      );
      expect(find.text('Answer'), findsNothing, reason: variant.name);
    }
  });

  testWidgets('a label can carry a leading glyph and a trailing marker', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(
          label: 'Front',
          labelLeading: Icon(Icons.star, key: Key('lead')),
          labelTrailing: Text('Required'),
        ),
      ),
    );

    final label = tester.getTopLeft(find.text('Front'));
    expect(
      tester.getTopLeft(find.byKey(const Key('lead'))).dx,
      lessThan(label.dx),
    );
    expect(tester.getTopLeft(find.text('Required')).dx, greaterThan(label.dx));
  });

  testWidgets('supporting text sits under the field in ForUI\'s description '
      'style, a caption as the error is; an error takes its place', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(supportingText: 'Shown on the card'),
      ),
    );
    final text = find.text('Shown on the card');
    final style = forUiTheme(tester, _field).textFieldStyles.lg;

    expect(_inkOf(tester, 'Shown on the card'), colors.mutedForeground);
    expect(
      DefaultTextStyle.of(tester.element(text)).style.fontSize,
      style.descriptionTextStyle.resolve({}).fontSize,
    );
    final caption = tester.element(text).texts.caption;
    expect(
      (
        style.descriptionTextStyle.resolve({}).fontSize,
        style.descriptionTextStyle.resolve({}).fontWeight,
      ),
      (caption.fontSize, caption.fontWeight),
    );
    expect(tester.getTopLeft(text).dx, tester.getTopLeft(fieldBox(_field)).dx);
    expect(
      tester.getTopLeft(text).dy - tester.getBottomLeft(fieldBox(_field)).dy,
      style.descriptionPadding.resolve(TextDirection.ltr).top,
    );

    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(
          supportingText: 'Shown on the card',
          errorText: 'Required',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shown on the card'), findsNothing);
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('the counter ends the supporting row, beside the message, and '
      'is the error colour in error', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(supportingText: 'Hint', counter: '3 / 60'),
      ),
    );
    final box = fieldBox(_field);
    final counter = find.text('3 / 60');

    expect(_inkOf(tester, '3 / 60'), colors.mutedForeground);
    expect(tester.getTopRight(counter).dx, tester.getTopRight(box).dx);
    expect(
      tester.getTopLeft(counter).dy,
      tester.getTopLeft(find.text('Hint')).dy,
    );

    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(counter: '61 / 60', errorText: 'Too long'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Too long'), findsOneWidget);
    // In error the counter stays a caption, the message's size.
    expect(
      DefaultTextStyle.of(tester.element(find.text('61 / 60'))).style.fontSize,
      tester.element(find.text('Too long')).texts.caption.fontSize,
    );
    expect(
      tester.getTopRight(find.text('61 / 60')).dx,
      tester.getTopRight(fieldBox(_field)).dx,
    );
  });

  testWidgets('a field first built disabled takes its autofocus once '
      'enabled', (tester) async {
    Future<void> pump({required bool isEnabled}) => pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(isEnabled: isEnabled, isAutofocused: true),
      ),
    );
    await pump(isEnabled: false);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );

    await pump(isEnabled: true);
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('the caret is the primary, as the style sets it', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).cursorColor,
      colors.primary,
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).cursorColor,
      forUiTheme(tester, _field).textFieldStyles.lg.cursorColor,
    );
  });
}
