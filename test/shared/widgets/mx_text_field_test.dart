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

  testWidgets('multiline starts at 40 and grows with the text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(controller: controller, isMultiline: true),
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
}
