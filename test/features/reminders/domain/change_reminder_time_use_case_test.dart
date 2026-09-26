import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/change_reminder_time_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 A1: a new time, scheduled before it is saved while the
// reminder is on (reminders spec D13, D17).

DateTime _t0() => DateTime(2026, 9, 26, 9);

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
    platform = FakeReminderPlatform();
    clock = FakeDayClock(DateTime(2026, 9, 26, 19));
  });
  tearDown(() => db.close());

  ChangeReminderTimeUseCase change() =>
      ChangeReminderTimeUseCase(settings, platform, clock);

  Future<ReminderSettings> stored() async =>
      (await settings.reminderSnapshot()).reminder;

  test('while on, the new time is scheduled and saved, and no permission is '
      'asked (UC-REMINDER-001 A1, BR-REMINDER-009)', () async {
    await settings.saveReminder(reminder: _on2000);
    platform.pending = DateTime(2026, 9, 26, 20);

    final result = await change()(minuteOfDay: 1260);

    expect(
      result,
      isA<Ok<DateTime?, ReminderRejection>>().having(
        (ok) => ok.value,
        'nextAt',
        DateTime(2026, 9, 26, 21),
      ),
    );
    expect(platform.pending, DateTime(2026, 9, 26, 21));
    expect((await stored()).minuteOfDay, 1260);
    expect((await stored()).isEnabled, isTrue);
    expect(platform.calls, isNot(contains(PlatformCall.requestPermission)));
  });

  test('a schedule the platform refuses keeps the old time and its schedule, '
      'and writes nothing (UC-REMINDER-001 E3)', () async {
    await settings.saveReminder(reminder: _on2000);
    platform
      ..pending = DateTime(2026, 9, 26, 20)
      ..refusing.add(PlatformCall.schedule);
    final before = await totalChanges(db);

    final result = await change()(minuteOfDay: 1260);

    expect(
      result,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotSchedule,
      ),
    );
    expect(await totalChanges(db), before);
    expect((await stored()).minuteOfDay, 1200);
    expect(platform.pending, DateTime(2026, 9, 26, 20));
  });

  test('a save that fails puts the old time back on the platform and leaves '
      'as its Failure (UC-REMINDER-001 E4, spec D13)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    await failing.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1 WHERE id = 1',
    );
    final broken = SettingsRepositoryImpl(failing, now: _t0);
    platform.pending = DateTime(2026, 9, 26, 20);

    await expectLater(
      ChangeReminderTimeUseCase(broken, platform, clock)(minuteOfDay: 1260),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(platform.pending, DateTime(2026, 9, 26, 20));
    expect((await broken.reminderSnapshot()).reminder.minuteOfDay, 1200);
  });

  test('while off, only the time is saved, nothing is scheduled and '
      'Ok(null) comes back (spec D17)', () async {
    final result = await change()(minuteOfDay: 480);

    expect(result, isA<Ok<DateTime?, ReminderRejection>>());
    expect((result as Ok<DateTime?, ReminderRejection>).value, isNull);
    expect((await stored()).isEnabled, isFalse);
    expect((await stored()).minuteOfDay, 480);
    expect(platform.calls, isEmpty);
  });

  test('a minute out of range is refused before anything is read or written '
      '(BR-REMINDER-002)', () async {
    await settings.saveReminder(reminder: _on2000);
    final before = await totalChanges(db);

    final result = await change()(minuteOfDay: -1);

    expect(
      result,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.minuteOutOfRange,
      ),
    );
    expect(platform.calls, isEmpty);
    expect(await totalChanges(db), before);
  });

  test('a day that already had its digest takes the new time tomorrow '
      '(BR-REMINDER-004)', () async {
    await settings.saveReminder(reminder: _on2000);
    await settings.recordReminderDelivered(at: DateTime(2026, 9, 26, 20, 1));
    clock.current = DateTime(2026, 9, 26, 21);

    await change()(minuteOfDay: 1320);

    expect(platform.pending, DateTime(2026, 9, 27, 22));
  });
}
