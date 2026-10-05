import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

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
      expect(find.byKey(MxCodeField.slotKey(i)), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(MxCodeField.slotKey(1)),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byKey(MxCodeField.slotKey(0))).width, 48);
    expect(
      tester.getSize(find.byKey(MxCodeField.slotKey(0))).height,
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
        of: find.byKey(MxCodeField.slotKey(5)),
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
                            of: find.byKey(MxCodeField.slotKey(i)),
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
        isAutofocused: true,
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

  testWidgets('a wrong code keeps the next-slot cue: every slot in error, '
      'the next one still 2 wide', (tester) async {
    Border edgeOf(int i) =>
        (tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.byKey(MxCodeField.slotKey(i)),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .border!
            as Border;

    await pumpMx(
      tester,
      const MxTextField(
        variant: MxTextFieldVariant.code,
        isAutofocused: true,
        errorText: 'Wrong',
      ),
    );
    await tester.pump();

    expect(edgeOf(0).top.color, scheme.error);
    expect(edgeOf(0).top.width, 2);
    expect(edgeOf(1).top.color, scheme.error);
    expect(edgeOf(1).top.width, 1);
  });

  testWidgets('a read-only code keeps its digits at full ink', (tester) async {
    final controller = TextEditingController(text: '123456');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        isReadOnly: true,
      ),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(
      find.ancestor(
        of: find.byKey(MxCodeField.slotKey(0)),
        matching: find.byWidgetPredicate(
          (w) => w is Opacity && w.opacity == AppOpacity.disabled,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('a tap on a slot focuses the code', (tester) async {
    await pumpMx(tester, const MxTextField(variant: MxTextFieldVariant.code));

    // The hidden field covers the slots and takes the tap itself.
    await tester.tap(find.byKey(MxCodeField.slotKey(4)), warnIfMissed: false);
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
      tester.getSize(find.byKey(MxCodeField.slotKey(0))).width,
      lessThan(48),
    );
  });

  testWidgets('TalkBack reads the code field once, by its label, and not '
      'each painted digit', (tester) async {
    final controller = TextEditingController(text: '4');
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        label: 'Code, 6 digits',
        variant: MxTextFieldVariant.code,
      ),
    );

    expect(find.bySemanticsLabel('Code, 6 digits'), findsOneWidget);
    expect(find.bySemanticsLabel('4'), findsNothing);
    handle.dispose();
  });

  testWidgets('a tap on the first slot keeps the caret after the last digit', (
    tester,
  ) async {
    final controller = TextEditingController(text: '123456');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    await tester.tap(find.byKey(MxCodeField.slotKey(0)), warnIfMissed: false);
    await tester.pump();

    expect(controller.selection, const TextSelection.collapsed(offset: 6));
  });

  testWidgets('Backspace after a tap on the first slot deletes the last '
      'digit', (tester) async {
    final controller = TextEditingController(text: '123456');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    await tester.tap(find.byKey(MxCodeField.slotKey(0)), warnIfMissed: false);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(controller.text, '12345');
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

  testWidgets('pasting a code after typed digits replaces them, not mixes '
      '(final review F3)', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '123987654',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );
    await tester.pump();

    expect(controller.text, '987654');
  });

  testWidgets('typing digits one at a time still stops at six', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '123459',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    await tester.pump();

    expect(controller.text, '123459');
  });

  testWidgets('MxCodeField draws the code variant only (final review F4)', (
    tester,
  ) async {
    await pumpMx(tester, const MxCodeField(field: MxTextField(label: 'Name')));

    expect(tester.takeException(), isA<AssertionError>());
  });
}
