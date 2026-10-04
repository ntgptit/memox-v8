import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_preview_digest_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// Screen 24's "What it says": the live sentence, silence, a failed read and
// the loading branch (BR-REMINDER-003, BR-REMINDER-005; critique 2026-09-30).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the preview says what the notification would say now '
      '(critique 2026-09-30 part 1)', (tester, env) async {
    // Korean > Lesson with three learned cards due before the harness day.
    await sm2Leaf(env.db, env.decks, dueCards: 3);
    await pumpReminderScreen(tester, env);
    expect(
      find.text(
        _en.reminderPreviewQuoted(
          _en.reminderBody(_en.reminderDueCards(3), 'Korean'),
        ),
      ),
      findsOneWidget,
    );
  });

  libraryTest('nothing due: the preview says the reminder stays silent', (
    tester,
    env,
  ) async {
    await pumpReminderScreen(tester, env);
    expect(find.text(_en.reminderPreviewNothingDue), findsOneWidget);
  });

  libraryTest('a failed read shows the neutral line', (tester, env) async {
    final s = await pumpReminderScreen(
      tester,
      env,
      overrides: [
        reminderPreviewDigestProvider.overrideWith(
          (ref) async => throw StateError('db'),
        ),
      ],
    );
    expect(find.text(_en.reminderPreviewNothingDue), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
    await tapReminderToggle(tester);
    expect(s.platform.calls, contains(PlatformCall.schedule));
  });

  libraryTest('while the preview loads the row keeps its place and shows no '
      'error', (tester, env) async {
    final never = Completer<ReminderDigest?>();
    await pumpReminderScreen(
      tester,
      env,
      overrides: [
        reminderPreviewDigestProvider.overrideWith((ref) => never.future),
      ],
    );
    // The section header draws its title in capitals.
    expect(find.text(_en.reminderPreviewTitle.toUpperCase()), findsOneWidget);
    expect(find.text(_en.reminderPreviewHint), findsOneWidget);
    expect(find.text(_en.reminderPreviewNothingDue), findsNothing);
    expect(find.byType(MxErrorState), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
