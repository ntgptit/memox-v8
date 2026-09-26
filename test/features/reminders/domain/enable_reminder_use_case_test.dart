import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/enable_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 steps 2-3 and E1-E4: turning the reminder on asks for the
// permission only then, and schedules before it saves, so that "on" is
// never stored without a pending reminder (reminders spec D13, D14).

DateTime _t0() => DateTime(2026, 9, 26, 9);

Matcher _refused(ReminderRejection reason) =>
    isA<Rejected<DateTime, ReminderRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

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

  EnableReminderUseCase enable() =>
      EnableReminderUseCase(settings, platform, clock);

  Future<bool> storedOn() async =>
      (await settings.reminderSnapshot()).reminder.isEnabled;

  test('turning it on asks for the permission, schedules the next time and '
      'saves it on (UC-REMINDER-001 steps 2-3, BR-REMINDER-011)', () async {
    final result = await enable()(minuteOfDay: 1200);

    expect(
      result,
      isA<Ok<DateTime, ReminderRejection>>().having(
        (ok) => ok.value,
        'nextAt',
        DateTime(2026, 9, 26, 20),
      ),
    );
    expect(platform.calls, [
      PlatformCall.capability,
      PlatformCall.requestPermission,
      PlatformCall.schedule,
    ]);
    expect(platform.pending, DateTime(2026, 9, 26, 20));
    final stored = (await settings.reminderSnapshot()).reminder;
    expect(stored.isEnabled, isTrue);
    expect(stored.minuteOfDay, 1200);
  });

  test(
    'two taps on the switch at once both succeed and leave the reminder '
    'on and pending once, with nothing taken back (BR-REMINDER-010)',
    () async {
      final results = await Future.wait([
        enable()(minuteOfDay: 1200),
        enable()(minuteOfDay: 1200),
      ]);

      for (final result in results) {
        expect(result, isA<Ok<DateTime, ReminderRejection>>());
      }
      expect(platform.pending, DateTime(2026, 9, 26, 20));
      expect(platform.calls, isNot(contains(PlatformCall.cancel)));
      expect(await storedOn(), isTrue);
    },
  );

  test('a minute out of range is refused before anything is asked or written '
      '(BR-REMINDER-002)', () async {
    await settings.reminderSnapshot();
    final before = await totalChanges(db);

    expect(
      await enable()(minuteOfDay: 1440),
      _refused(ReminderRejection.minuteOutOfRange),
    );
    expect(platform.calls, isEmpty);
    expect(await totalChanges(db), before);
  });

  test('an unsupported platform is refused without asking for the '
      'permission (BR-REMINDER-012, UC-REMINDER-001 E2)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;

    expect(
      await enable()(minuteOfDay: 1200),
      _refused(ReminderRejection.unsupported),
    );
    expect(platform.calls, [PlatformCall.capability]);
    expect(await storedOn(), isFalse);
  });

  test('a denied permission leaves the reminder off with nothing scheduled, '
      'asked once (BR-REMINDER-011, UC-REMINDER-001 E1)', () async {
    platform.permission = ReminderPermission.denied;

    expect(
      await enable()(minuteOfDay: 1200),
      _refused(ReminderRejection.permissionDenied),
    );
    expect(
      platform.calls.where((call) => call == PlatformCall.requestPermission),
      hasLength(1),
    );
    expect(platform.pending, isNull);
    expect(await storedOn(), isFalse);
  });

  test('a schedule the platform refuses leaves the reminder off and writes '
      'nothing (UC-REMINDER-001 E3, spec D13)', () async {
    platform.refusing.add(PlatformCall.schedule);
    await settings.reminderSnapshot();
    final before = await totalChanges(db);

    expect(
      await enable()(minuteOfDay: 1200),
      _refused(ReminderRejection.couldNotSchedule),
    );
    expect(await totalChanges(db), before);
    expect(await storedOn(), isFalse);
  });

  test('a save that fails takes the schedule back and leaves as its Failure, '
      'the reminder still off (UC-REMINDER-001 E4, spec D13)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      EnableReminderUseCase(broken, platform, clock)(minuteOfDay: 1200),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(platform.calls.last, PlatformCall.cancel);
    expect(platform.pending, isNull);
    expect((await broken.reminderSnapshot()).reminder.isEnabled, isFalse);
  });

  test('a day that already had its digest is scheduled for tomorrow '
      '(BR-REMINDER-004)', () async {
    await settings.recordReminderDelivered(at: DateTime(2026, 9, 26, 18, 1));

    await enable()(minuteOfDay: 1200);

    expect(platform.pending, DateTime(2026, 9, 27, 20));
  });
}
