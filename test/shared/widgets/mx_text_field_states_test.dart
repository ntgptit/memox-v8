import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/field_edge_expect.dart';
import '../../support/widget_harness.dart';

/// The decoration the field paints: its own, with the theme's defaults.
InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

TextStyle _textOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

/// The painted label, the supporting row, the disabled state, the caret and
/// the autofocus of [MxTextField] (DEV-372).
void main() {
  final scheme = lightColorScheme;
  // The M3 disabled edge: onSurface at the container opacity.
  final ghost = scheme.onSurface.withValues(alpha: 0.12);

  testWidgets('disabled: the M3 values once, no wrapper dimming the edge a '
      'second time (DEV-372 R2)', (tester) async {
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

    expect(
      find.ancestor(of: find.byType(TextField), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      edgeIn(_decoration(tester), {WidgetState.disabled}).borderSide.color,
      ghost,
    );
    final content = scheme.onSurface.withValues(alpha: 0.38);
    expect(_textOf(tester, 'Name').color, content);
    expect(_textOf(tester, 'Shown on the card').color, content);
    expect(_textOf(tester, '0 / 60').color, content);
    final hint = tester.widget<Text>(find.text('Deck'));
    expect(hint.style!.color, content);
  });

  testWidgets('the painted label sits above the field, 4 clear of it, in '
      'onSurfaceVariant, and the field keeps the name for TalkBack', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(label: 'Deck name')),
    );

    final label = find.text('Deck name');
    expect(label, findsOneWidget);
    expect(_textOf(tester, 'Deck name').color, scheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.byType(TextField)).dy -
          tester.getBottomLeft(label).dy,
      4,
    );
    // The label starts on the field's text inset.
    expect(
      tester.getTopLeft(label).dx -
          tester.getTopLeft(find.byType(TextField)).dx,
      16,
    );
    expect(
      tester.getSemantics(find.byType(EditableText)).label,
      contains('Deck name'),
    );
    // Painted once for TalkBack: the field's node carries it, not the Text.
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

    expect(_textOf(tester, 'Deck name').color, scheme.error);
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

  testWidgets('supporting text sits under the field on the text inset, in '
      'bodySmall onSurfaceVariant; an error takes its place', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(supportingText: 'Shown on the card'),
      ),
    );
    final field = find.byType(TextField);
    final text = find.text('Shown on the card');

    expect(_textOf(tester, 'Shown on the card').color, scheme.onSurfaceVariant);
    expect(
      tester.widget<Text>(text).style!.fontSize,
      tester.element(text).texts.caption.fontSize,
    );
    expect(tester.getTopLeft(text).dx - tester.getTopLeft(field).dx, 16);
    expect(tester.getTopLeft(text).dy - tester.getBottomLeft(field).dy, 4);

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
    final field = find.byType(TextField);
    final counter = find.text('3 / 60');

    expect(_textOf(tester, '3 / 60').color, scheme.onSurfaceVariant);
    expect(tester.getTopRight(counter).dx, tester.getTopRight(field).dx - 16);
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
    expect(_textOf(tester, '61 / 60').color, scheme.error);
    expect(find.text('Too long'), findsOneWidget);
    expect(
      tester.getTopRight(find.text('61 / 60')).dx,
      tester.getTopRight(find.byType(TextField)).dx - 16,
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

  testWidgets('the caret is the accent, and the error colour in error', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    expect(
      tester.widget<TextField>(find.byType(TextField)).cursorColor,
      scheme.primary,
    );

    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(errorText: 'Required')),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).cursorColor,
      scheme.error,
    );
  });
}
