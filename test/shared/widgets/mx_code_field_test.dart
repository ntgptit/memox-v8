import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

/// The painted edge of slot [i].
Border _edgeOf(WidgetTester tester, int i) =>
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

void main() {
  final colors = appLightColors;
  const dimens = AppDimens();

  testWidgets('the code variant asks for digits and offers the one-time '
      'code', (tester) async {
    await pumpMx(
      tester,
      const MxTextField(label: 'Code', variant: MxTextFieldVariant.code),
    );
    final field = tester.widget<EditableText>(find.byType(EditableText));

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
      greaterThanOrEqualTo(dimens.sizeControl),
    );
  });

  // The code variant keeps the digits, six at most. Each case enters [typed],
  // then optionally a second editing value (a paste, or a digit typed after
  // them) as the platform would send it.
  final sanitising =
      <({String name, String typed, (String, int)? then, String expected})>[
        (
          name: 'a pasted "123 456" fills six slots',
          typed: '123 456',
          then: null,
          expected: '123456',
        ),
        (
          name: 'the code variant keeps six digits and nothing else',
          typed: '12a3456789',
          then: null,
          expected: '123456',
        ),
        (
          name:
              'pasting a code after typed digits replaces them, not mixes '
              '(final review F3)',
          typed: '123',
          then: ('123987654', 9),
          expected: '987654',
        ),
        (
          name: 'typing digits one at a time still stops at six',
          typed: '12345',
          then: ('123459', 6),
          expected: '123459',
        ),
      ];
  for (final c in sanitising) {
    testWidgets(c.name, (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpMx(
        tester,
        MxTextField(controller: controller, variant: MxTextFieldVariant.code),
      );
      await tester.enterText(find.byType(EditableText), c.typed);
      await tester.pump();
      final then = c.then;
      if (then != null) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: then.$1,
            selection: TextSelection.collapsed(offset: then.$2),
          ),
        );
        await tester.pump();
      }

      expect(controller.text, c.expected);
      expect(MxTextField.codeLength, 6);
      // The last slot paints the last digit.
      expect(
        find.descendant(
          of: find.byKey(MxCodeField.slotKey(5)),
          matching: find.text(c.expected[5]),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('the slot that takes the next digit carries the focus edge; '
      'the rest the outline edge; an error edges every slot', (tester) async {
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        isAutofocused: true,
      ),
    );
    await tester.pump();
    final hairline = tester
        .element(find.byKey(MxCodeField.slotKey(2)))
        .hairline;
    expect(_edgeOf(tester, 2).top.color, colors.primary);
    expect(_edgeOf(tester, 2).top.width, 2 * hairline);
    expect(_edgeOf(tester, 3).top.color, colors.border);
    expect(_edgeOf(tester, 3).top.width, hairline);

    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        errorText: 'Wrong',
      ),
    );
    expect(_edgeOf(tester, 0).top.color, colors.error);
    expect(_edgeOf(tester, 5).top.color, colors.error);
  });

  testWidgets('a wrong code keeps the next-slot cue: every slot in error, '
      'the next one still 2 wide', (tester) async {
    await pumpMx(
      tester,
      const MxTextField(
        variant: MxTextFieldVariant.code,
        isAutofocused: true,
        errorText: 'Wrong',
      ),
    );
    await tester.pump();

    final hairline = tester
        .element(find.byKey(MxCodeField.slotKey(0)))
        .hairline;
    expect(_edgeOf(tester, 0).top.color, colors.error);
    expect(_edgeOf(tester, 0).top.width, 2 * hairline);
    expect(_edgeOf(tester, 1).top.color, colors.error);
    expect(_edgeOf(tester, 1).top.width, hairline);
  });

  testWidgets('a read-only code keeps its digits at full strength', (
    tester,
  ) async {
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

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
    expect(
      find.ancestor(
        of: find.byKey(MxCodeField.slotKey(0)),
        matching: find.byWidgetPredicate(
          (w) => w is Opacity && w.opacity == colors.disabledOpacity,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('a disabled code takes the ForUI disabled values once: the '
      'disabled edge and digits, with no wrapper dimming them again '
      '(DEV-166, DEV-372 R2)', (tester) async {
    final controller = TextEditingController(text: '4');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        isEnabled: false,
      ),
    );
    final slot =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(MxCodeField.slotKey(0)),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect((slot.border! as Border).top.color, colors.disable(colors.border));
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(MxCodeField.slotKey(0)),
              matching: find.text('4'),
            ),
          )
          .style!
          .color,
      colors.disable(colors.foreground),
    );
    expect(
      find.ancestor(
        of: find.byKey(MxCodeField.slotKey(0)),
        matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity != 0),
      ),
      findsNothing,
    );
  });

  testWidgets('a slot has no fill: the ground shows through', (tester) async {
    await pumpMx(tester, const MxTextField(variant: MxTextFieldVariant.code));
    final slot =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(MxCodeField.slotKey(0)),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(slot.color, isNull);
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

  testWidgets('MxCodeField draws the code variant only (final review F4)', (
    tester,
  ) async {
    await pumpMx(tester, const MxCodeField(field: MxTextField(label: 'Name')));

    expect(tester.takeException(), isA<AssertionError>());
  });
}
