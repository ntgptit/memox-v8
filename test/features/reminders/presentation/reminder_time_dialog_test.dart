import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';
import '../../../support/forui_expect.dart';

// Screen 24, Daily reminder: the time dialog (UC-REMINDER-001 A1).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('a typed minute outside 0–59 disables Save', (tester, env) async {
    await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    await tester.tap(find.text('20:00'));
    await settleReminderScreen(tester);

    // The minute stepper's value; a tap makes it typeable (MxStepper).
    await tester.tap(find.text('00').last);
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final save = find.widgetWithText(MxButton, _en.reminderTimeSave);
    expect(tester.widget<MxButton>(save).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('stepping after a typed hour or minute out of range clears it '
      'and Save is on again (audit 2026-10-17 SET-1)', (tester, env) async {
    await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    await tester.tap(find.text('20:00'));
    await settleReminderScreen(tester);
    final save = find.widgetWithText(MxButton, _en.reminderTimeSave);

    // The minute: type 75, then step +.
    await tester.tap(find.text('00').last);
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<MxButton>(save).onPressed, isNull);
    await tester.tap(byControlLabel(_en.reminderLaterMinute));
    await tester.pump();
    expect(tester.widget<MxButton>(save).onPressed, isNotNull);

    // The hour: type 30, then step −.
    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '30');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<MxButton>(save).onPressed, isNull);
    await tester.tap(byControlLabel(_en.reminderEarlierHour));
    await tester.pump();
    expect(tester.widget<MxButton>(save).onPressed, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the hour and minute read in two digits; a typed 7 reads 07 '
      '(critique 2026-09-30 part 3d-2, Review Focus 5)', (tester, env) async {
    await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    await tester.tap(find.text('20:00'));
    await settleReminderScreen(tester);

    expect(find.text('20'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    await tester.tap(find.text('00'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '7');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('07'), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.reminderTimeSave));
    await settleReminderScreen(tester);
    expect(find.text('20:07'), findsOneWidget);
  });
}
