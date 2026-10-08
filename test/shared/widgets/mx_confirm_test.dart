import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import '../../support/widget_harness.dart';

// showMxConfirm: the one yes/no dialog every feature asks with (SW-REV-009).

Finder _button(String label) => find.widgetWithText(MxButton, label);

/// Opens a confirm from a button and records what it completes with.
Future<List<bool>> _open(
  WidgetTester tester, {
  Widget? content,
  bool isDestructive = false,
  bool isWarning = false,
  bool canConfirm = true,
}) async {
  final results = <bool>[];
  await pumpMx(
    tester,
    Builder(
      builder: (context) => MxButton(
        label: 'Open',
        onPressed: () async => results.add(
          await showMxConfirm(
            context,
            title: 'Delete this tag?',
            body: 'No card is deleted.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
            content: content,
            isDestructive: isDestructive,
            isWarning: isWarning,
            canConfirm: canConfirm,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('the confirm completes true', (tester) async {
    final results = await _open(tester);
    expect(find.text('Delete this tag?'), findsOneWidget);
    expect(find.text('No card is deleted.'), findsOneWidget);

    await tester.tap(_button('Delete'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('Cancel, Back and the scrim each complete false, never null', (
    tester,
  ) async {
    final results = await _open(tester);
    await tester.tap(_button('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(results, [false, false, false]);
  });

  testWidgets('the tone reaches the confirm, never Cancel', (tester) async {
    await _open(tester, isDestructive: true);
    expect(
      tester.widget<MxButton>(_button('Delete')).tone,
      MxButtonTone.destructive,
    );
    expect(
      tester.widget<MxButton>(_button('Cancel')).tone,
      MxButtonTone.outline,
    );
  });

  testWidgets('a warning confirm takes the warning tone', (tester) async {
    await _open(tester, isWarning: true);
    expect(
      tester.widget<MxButton>(_button('Delete')).tone,
      MxButtonTone.warning,
    );
  });

  testWidgets('canConfirm false disables the confirm; Cancel still says no', (
    tester,
  ) async {
    final results = await _open(tester, canConfirm: false);
    expect(tester.widget<MxButton>(_button('Delete')).onPressed, isNull);

    await tester.tap(_button('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('content sits under the body', (tester) async {
    await _open(tester, content: const MxNote(text: 'Cards keep their tags.'));
    expect(
      tester.getTopLeft(find.text('Cards keep their tags.')).dy,
      greaterThan(tester.getTopLeft(find.text('No card is deleted.')).dy),
    );
  });
}
