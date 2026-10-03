import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';

// Screen 24: the notification permission read on open and on resume
// (BR-REMINDER-011 amended; SP2b 2.34, 2.36).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('on, then blocked in system settings: the hint and the warning '
      'say so, and nothing stored changes (2.34)', (tester, env) async {
    final s = await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
    final writes = s.store.writes;

    s.platform.permission = ReminderPermission.denied;
    await resumeReminderApp(tester);

    expect(find.text(_en.reminderRevokedHint), findsOneWidget);
    expect(find.text(_en.reminderOnHint), findsNothing);
    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderRevokedBody), findsOneWidget);
    expect(find.text(_en.reminderOpenSystemSettings), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isTrue);
    expect(
      s.store.writes,
      writes,
      reason: 'the stored reminder is not changed',
    );
    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(1),
      reason: 'BR-REMINDER-011: reading never asks',
    );
  });

  libraryTest('allowed again: the warning and the hint go, the reminder was '
      'never touched (2.34)', (tester, env) async {
    final s = await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    s.platform.permission = ReminderPermission.denied;
    await resumeReminderApp(tester);
    expect(find.text(_en.reminderRevokedBody), findsOneWidget);

    s.platform.permission = ReminderPermission.granted;
    await resumeReminderApp(tester);

    expect(find.text(_en.reminderRevokedBody), findsNothing);
    expect(find.text(_en.reminderRevokedHint), findsNothing);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('off with the permission blocked: no warning, the reminder is '
      'not on (2.34)', (tester, env) async {
    await pumpReminderScreen(
      tester,
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );

    expect(find.text(_en.reminderOffHint), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.reminderRevokedBody), findsNothing);
  });

  libraryTest('turning on from a fresh install reads no false warning: the '
      'read from before the person allowed is not trusted (2.34)', (
    tester,
    env,
  ) async {
    final platform = FakeReminderPlatform()
      ..notifications = ReminderPermission.denied;
    await pumpReminderScreen(tester, env, platform: platform);

    await tapReminderToggle(tester);

    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.text(_en.reminderRevokedHint), findsNothing);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('Open system settings on the revoked warning opens them and '
      'writes nothing (2.34)', (tester, env) async {
    final s = await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    s.platform.permission = ReminderPermission.denied;
    await resumeReminderApp(tester);
    final writes = s.store.writes;

    await tester.tap(find.text(_en.reminderOpenSystemSettings));
    await settleReminderScreen(tester);

    expect(s.platform.calls.last, PlatformCall.openSettings);
    expect(s.store.writes, writes);
    expect(find.text(_en.reminderRevokedBody), findsOneWidget);
  });
}
