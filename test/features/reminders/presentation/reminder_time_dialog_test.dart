import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';
import '../../../support/forui_expect.dart';

// Screen 24, Daily reminder: the time dialog (UC-REMINDER-001 A1).

final _en = lookupAppLocalizations(const Locale('en'));

// Opens the time dialog from the Daily reminder screen.
Future<void> _openTimeDialog(WidgetTester tester, LibraryEnv env) async {
  await pumpReminderScreen(tester, env);
  await tapReminderToggle(tester);
  await tester.tap(find.text('20:00'));
  await settleReminderScreen(tester);
}

// Taps a stepper's value to make it typeable (MxStepper), types [text] and
// confirms it with the keyboard's done action.
Future<void> _typeIntoStepper(
  WidgetTester tester,
  Finder value,
  String text,
) async {
  await tester.tap(value);
  await tester.pump();
  await tester.enterText(find.byType(EditableText).last, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  libraryTest('stepping after a typed hour or minute out of range clears it '
      'and Save is on again (audit 2026-10-17 SET-1)', (tester, env) async {
    await _openTimeDialog(tester, env);
    final save = find.widgetWithText(MxButton, _en.reminderTimeSave);

    // The minute: type 75, then step +. A typed minute outside 0–59 disables
    // Save.
    await _typeIntoStepper(tester, find.text('00').last, '75');
    expect(tester.widget<MxButton>(save).onPressed, isNull);
    await tester.tap(byControlLabel(_en.reminderLaterMinute));
    await tester.pump();
    expect(tester.widget<MxButton>(save).onPressed, isNotNull);

    // The hour: type 30, then step −.
    await _typeIntoStepper(tester, find.text('20'), '30');
    expect(tester.widget<MxButton>(save).onPressed, isNull);
    await tester.tap(byControlLabel(_en.reminderEarlierHour));
    await tester.pump();
    expect(tester.widget<MxButton>(save).onPressed, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the hour and minute read in two digits; a typed 7 reads 07 '
      '(critique 2026-09-30 part 3d-2, Review Focus 5)', (tester, env) async {
    await _openTimeDialog(tester, env);

    expect(find.text('20'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    await _typeIntoStepper(tester, find.text('00'), '7');
    expect(find.text('07'), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.reminderTimeSave));
    await settleReminderScreen(tester);
    expect(find.text('20:07'), findsOneWidget);
  });
}
