import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/watch_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 step 1: what the reminder screen shows, from the stored
// reminder and the platform's capability (reminders spec §9).

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 26, 9));
  });
  tearDown(() => db.close());

  test('the screen shows the stored reminder, again after every save, and '
      'watching asks nothing of the platform but its capability '
      '(UC-REMINDER-001 step 1, BR-REMINDER-011)', () async {
    final platform = FakeReminderPlatform();
    final seen = <(ReminderCapability, bool, int)>[];
    final subscription = WatchReminderUseCase(settings, platform)().listen(
      (status) => seen.add((
        status.capability,
        status.reminder.isEnabled,
        status.reminder.minuteOfDay,
      )),
    );
    await pumpEventQueue();

    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 480),
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen, [
      (ReminderCapability.supported, false, 1200),
      (ReminderCapability.supported, true, 480),
    ]);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('an unsupported platform is shown as such, even over a reminder '
      'stored as on (BR-REMINDER-012, UC-REMINDER-001 E2)', () async {
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1200),
    );
    final platform = FakeReminderPlatform(
      capabilityValue: ReminderCapability.unsupported,
    );

    final status = await WatchReminderUseCase(settings, platform)().first;

    expect(status.capability, ReminderCapability.unsupported);
    expect(status.reminder.isEnabled, isTrue);
  });

  test('a settings read that fails reaches the stream as its Failure, never '
      'as made-up values (UC-REMINDER-001 E7)', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(
      WatchReminderUseCase(settings, FakeReminderPlatform())().first,
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });
}
