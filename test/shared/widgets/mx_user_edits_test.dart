import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

// MxUserEdits through the field that uses it: onChanged hears the person's
// edits, once each, and never the text or selection the code sets.
void main() {
  Future<({TextEditingController controller, List<String> heard})> pump(
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final heard = <String>[];
    await pumpMx(
      tester,
      MxTextField(label: 'Front', controller: controller, onChanged: heard.add),
    );
    return (controller: controller, heard: heard);
  }

  testWidgets('typing, pasting and deleting each report once', (tester) async {
    final field = await pump(tester);

    await tester.enterText(find.byType(EditableText), 'ab');
    await tester.pump();
    // A paste arrives as one edit of the whole text.
    await tester.enterText(find.byType(EditableText), 'ab pasted');
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'ab');
    await tester.pump();

    expect(field.heard, ['ab', 'ab pasted', 'ab']);
  });

  testWidgets('text, a selection or a clear set by the code report nothing', (
    tester,
  ) async {
    final field = await pump(tester);

    field.controller.text = 'set by code';
    await tester.pump();
    field.controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    field.controller.clear();
    await tester.pump();

    expect(field.heard, isEmpty);
  });

  testWidgets('an edit after the code set the text still reports once', (
    tester,
  ) async {
    final field = await pump(tester);

    field.controller.text = 'abc';
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'abcd');
    await tester.pump();

    expect(field.heard, ['abcd']);
  });

  // The code field's formatters keep digits and cap the length; the edit is
  // reported as they leave it, once.
  testWidgets('a formatter that rewrites an edit reports the result once', (
    tester,
  ) async {
    final heard = <String>[];
    await pumpMx(
      tester,
      MxCodeField(
        field: MxTextField(
          label: 'Code',
          variant: MxTextFieldVariant.code,
          onChanged: heard.add,
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '12a3456789');
    await tester.pump();

    expect(heard, ['123456']);
  });
}
