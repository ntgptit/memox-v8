import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/reconcile_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 A5: the pending reminder brought in line with the stored
// one, at app start and after a reset (BR-REMINDER-009, BR-REMINDER-010;
// reminders spec D15).

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 26, 9));
    platform = FakeReminderPlatform();
    clock = FakeDayClock(DateTime(2026, 9, 26, 19));
  });
  tearDown(() => db.close());

  ReconcileReminderUseCase reconcile() =>
      ReconcileReminderUseCase(settings, platform, clock);

  test('a reminder that is on is pending once at its next time, however many '
      'times reconcile runs, and the permission is never asked '
      '(BR-REMINDER-010, BR-REMINDER-011, UC-REMINDER-001 A5)', () async {
    await settings.saveReminder(reminder: _on2000);

    final first = await reconcile()();
    final second = await reconcile()();

    for (final result in [first, second]) {
      expect(
        result,
        isA<Ok<DateTime?, ReminderRejection>>().having(
          (ok) => ok.value,
          'nextAt',
          DateTime(2026, 9, 26, 20),
        ),
      );
    }
    expect(platform.pending, DateTime(2026, 9, 26, 20));
    expect(platform.calls, isNot(contains(PlatformCall.requestPermission)));
  });

  test('a day that already had its digest is scheduled for tomorrow '
      '(BR-REMINDER-004)', () async {
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1320),
    );
    await settings.recordReminderDelivered(at: DateTime(2026, 9, 26, 20, 1));
    clock.current = DateTime(2026, 9, 26, 21);

    await reconcile()();

    expect(platform.pending, DateTime(2026, 9, 27, 22));
  });

  test('a reminder that is off cancels what is pending: a leftover of a '
      'reset or of UC-REMINDER-001 E6 (BR-REMINDER-009, spec D15)', () async {
    await settings.saveReminder(reminder: _on2000);
    await reconcile()();
    expect(platform.pending, isNotNull);

    await settings.resetToDefaults();
    final result = await reconcile()();

    expect(result, isA<Ok<DateTime?, ReminderRejection>>());
    expect((result as Ok<DateTime?, ReminderRejection>).value, isNull);
    expect(platform.pending, isNull);
  });

  test('an unsupported platform is asked nothing but its capability '
      '(BR-REMINDER-012)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;
    await settings.saveReminder(reminder: _on2000);

    final result = await reconcile()();

    expect((result as Ok<DateTime?, ReminderRejection>).value, isNull);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('a refusal of the platform comes back as its reason '
      '(UC-REMINDER-001 E3, E6)', () async {
    platform.refusing.addAll({PlatformCall.schedule, PlatformCall.cancel});
    await settings.saveReminder(reminder: _on2000);

    final scheduling = await reconcile()();
    await settings.resetToDefaults();
    final cancelling = await reconcile()();

    expect(
      scheduling,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotSchedule,
      ),
    );
    expect(
      cancelling,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotCancel,
      ),
    );
  });

  test('a settings read that fails leaves as its Failure', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(reconcile()(), throwsA(isA<UnknownDatabaseFailure>()));
  });
}
