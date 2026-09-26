import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/disable_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 A2, E4 and E6: turning the reminder off saves it off
// first, then cancels what is pending (reminders spec D13).

DateTime _t0() => DateTime(2026, 9, 26, 9);

final _pendingAt = DateTime(2026, 9, 26, 20);

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  setUp(() async {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
    platform = FakeReminderPlatform()..pending = _pendingAt;
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1200),
    );
  });
  tearDown(() => db.close());

  DisableReminderUseCase disable() =>
      DisableReminderUseCase(settings, platform);

  test('turning it off saves it off, keeps its time and cancels what is '
      'pending, asking for no permission (UC-REMINDER-001 A2)', () async {
    final result = await disable()();

    expect(result, isA<Ok<void, ReminderRejection>>());
    final stored = (await settings.reminderSnapshot()).reminder;
    expect(stored.isEnabled, isFalse);
    expect(stored.minuteOfDay, 1200);
    expect(platform.pending, isNull);
    expect(platform.calls, [PlatformCall.capability, PlatformCall.cancel]);
  });

  test('a cancel the platform refuses comes back as couldNotCancel with the '
      'reminder already off (UC-REMINDER-001 E6)', () async {
    platform.refusing.add(PlatformCall.cancel);

    final result = await disable()();

    expect(
      result,
      isA<Rejected<void, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotCancel,
      ),
    );
    expect((await settings.reminderSnapshot()).reminder.isEnabled, isFalse);
    expect(platform.pending, _pendingAt);
  });

  test(
    'trying again writes nothing and cancels (UC-REMINDER-001 E6)',
    () async {
      platform.refusing.add(PlatformCall.cancel);
      await disable()();
      platform.refusing.clear();
      final before = await totalChanges(db);

      final retry = await disable()();

      expect(retry, isA<Ok<void, ReminderRejection>>());
      expect(await totalChanges(db), before);
      expect(platform.pending, isNull);
    },
  );

  test('a save that fails leaves as its Failure and cancels nothing: the '
      'reminder is still on and still pending (UC-REMINDER-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    await failing.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1 WHERE id = 1',
    );
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      DisableReminderUseCase(broken, platform)(),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(platform.calls, isNot(contains(PlatformCall.cancel)));
    expect(platform.pending, _pendingAt);
    expect((await broken.reminderSnapshot()).reminder.isEnabled, isTrue);
  });

  test('on a platform without reminders it is saved off and nothing else is '
      'asked (BR-REMINDER-012)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;

    expect(await disable()(), isA<Ok<void, ReminderRejection>>());
    expect((await settings.reminderSnapshot()).reminder.isEnabled, isFalse);
    expect(platform.calls, [PlatformCall.capability]);
  });
}
