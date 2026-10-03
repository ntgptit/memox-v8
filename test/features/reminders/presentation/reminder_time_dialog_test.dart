import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

import '../../../support/library_harness.dart';

// Screen 24's time dialog (UC-REMINDER-001 A1; SP2b 2.35).

final _en = lookupAppLocalizations(const Locale('en'));

/// The dialog open on 20:00 over a page with one button.
Future<void> _open(WidgetTester tester, LibraryEnv env) async {
  await pumpLibraryScreen(
    tester,
    env,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => unawaited(
              showReminderTimeDialog(context, minuteOfDay: 20 * 60),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Taps the stepper that shows [shown], types [text] and presses Done.
Future<void> _type(WidgetTester tester, String shown, String text) async {
  await tester.tap(find.text(shown));
  await tester.pump();
  await tester.enterText(find.byType(EditableText), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

MxButton _save(WidgetTester tester) => tester.widget<MxButton>(
  find.widgetWithText(MxButton, _en.reminderTimeSave),
);

void main() {
  libraryTest('a typed hour of 24 says why Save is off, and a step clears it', (
    tester,
    env,
  ) async {
    await _open(tester, env);
    await _type(tester, '20', '24');

    expect(find.text(_en.reminderHourRange), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await tester.tap(find.byTooltip(_en.reminderEarlierHour));
    await tester.pump();

    expect(find.text(_en.reminderHourRange), findsNothing);
    expect(_save(tester).onPressed, isNotNull);
    expect(find.text('19:00'), findsOneWidget);
  });

  libraryTest('a typed minute of 75 says why Save is off, and a step clears '
      'it', (tester, env) async {
    await _open(tester, env);
    await _type(tester, '00', '75');

    expect(find.text(_en.reminderMinuteRange), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await tester.tap(find.byTooltip(_en.reminderLaterMinute));
    await tester.pump();

    expect(find.text(_en.reminderMinuteRange), findsNothing);
    expect(_save(tester).onPressed, isNotNull);
    expect(find.text('20:01'), findsOneWidget);
  });

  libraryTest('typing a valid value after a wrong one clears the line', (
    tester,
    env,
  ) async {
    await _open(tester, env);
    await _type(tester, '20', '24');
    expect(find.byType(MxFieldMessage), findsOneWidget);

    await _type(tester, '20', '7');

    expect(find.byType(MxFieldMessage), findsNothing);
    expect(find.text('07:00'), findsOneWidget);
    expect(_save(tester).onPressed, isNotNull);
  });

  libraryTest('both wrong: each stepper has its own line, and one step clears '
      'only its own', (tester, env) async {
    await _open(tester, env);
    await _type(tester, '20', '24');
    await _type(tester, '00', '75');
    expect(find.byType(MxFieldMessage), findsNWidgets(2));

    await tester.tap(find.byTooltip(_en.reminderEarlierHour));
    await tester.pump();

    expect(find.text(_en.reminderHourRange), findsNothing);
    expect(find.text(_en.reminderMinuteRange), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });
}
