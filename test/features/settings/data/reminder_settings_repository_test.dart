import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/test_database.dart';

// The daily reminder's values in the one `app_settings` row: the settings
// feature writes them for the reminders feature (reminders spec §5, D2).

DateTime _t0() => DateTime(2026, 9, 26, 9);

final _deliveredAt = DateTime(2026, 9, 26, 20, 1);

const _onAt0800 = ReminderSettings(isEnabled: true, minuteOfDay: 480);

Future<Map<String, Object?>> _row(AppDatabase db) async =>
    (await db
            .customSelect('SELECT * FROM app_settings WHERE id = 1')
            .getSingle())
        .data;

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
  });
  tearDown(() => db.close());

  test('a fresh install has the reminder off at 20:00 and nothing delivered '
      '(BR-REMINDER-001, UC-REMINDER-001 step 1)', () async {
    final current = await settings.watchAppSettings().first;
    final snapshot = await settings.reminderSnapshot();

    expect(current.reminder.isEnabled, isFalse);
    expect(current.reminder.minuteOfDay, 1200);
    expect(snapshot.reminder.isEnabled, isFalse);
    expect(snapshot.lastDeliveredAt, isNull);
    expect(snapshot.language, LanguageChoice.system);
  });

  test('saving the reminder writes both values and every watcher sees them '
      '(UC-REMINDER-001 step 3, A1)', () async {
    final seen = <(bool, int)>[];
    final subscription = settings.watchAppSettings().listen(
      (current) =>
          seen.add((current.reminder.isEnabled, current.reminder.minuteOfDay)),
    );
    await pumpEventQueue();

    final result = await settings.saveReminder(reminder: _onAt0800);
    await pumpEventQueue();
    await subscription.cancel();

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect(seen, [(false, 1200), (true, 480)]);
    final row = await _row(db);
    expect(row['reminder_enabled'], 1);
    expect(row['reminder_minute_of_day'], 480);
  });

  test('a minute out of range is refused before the database is touched '
      '(BR-REMINDER-002)', () async {
    await settings.watchAppSettings().first;
    final before = await totalChanges(db);

    final result = await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1440),
    );

    expect(
      result,
      isA<Rejected<void, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.reminderMinuteOutOfRange,
      ),
    );
    expect(await totalChanges(db), before);
  });

  test('the snapshot reads the reminder, the last delivery and the language '
      'in one statement (schema.md, reminders spec §5)', () async {
    final counter = SelectCounter();
    final counted = openTestDatabase(interceptor: counter);
    addTearDown(counted.close);
    final repository = SettingsRepositoryImpl(counted, now: _t0);
    await repository.setLanguage(language: LanguageChoice.vi);
    await repository.saveReminder(reminder: _onAt0800);
    await repository.recordReminderDelivered(at: _deliveredAt);
    counter.selects = 0;

    final snapshot = await repository.reminderSnapshot();

    expect(counter.selects, 1);
    expect(snapshot.reminder.isEnabled, isTrue);
    expect(snapshot.reminder.minuteOfDay, 480);
    expect(snapshot.lastDeliveredAt!.isAtSameMomentAs(_deliveredAt), isTrue);
    expect(snapshot.language, LanguageChoice.vi);
  });

  test(
    'recording a delivery writes that one column: the switch, the time '
    'and updated_at stay as they were (schema.md, BR-REMINDER-004)',
    () async {
      await settings.saveReminder(reminder: _onAt0800);
      final before = await _row(db);
      final changes = await totalChanges(db);

      await settings.recordReminderDelivered(at: _deliveredAt);

      final after = await _row(db);
      expect(await totalChanges(db), changes + 1);
      expect(
        {...after}..remove('reminder_last_delivered_at'),
        {...before}..remove('reminder_last_delivered_at'),
      );
      expect(before['reminder_last_delivered_at'], isNull);
      final snapshot = await settings.reminderSnapshot();
      expect(snapshot.lastDeliveredAt!.isAtSameMomentAs(_deliveredAt), isTrue);
    },
  );

  test('a snapshot of a settings row that is gone is a read failure, never '
      'made-up values (UC-REMINDER-001 E7)', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(
      settings.reminderSnapshot(),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('a failed save of the reminder leaves as a typed Failure and the stored '
      'reminder stays (UC-REMINDER-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      broken.saveReminder(reminder: _onAt0800),
      throwsA(isA<ConstraintFailure>()),
    );
    expect((await broken.watchAppSettings().first).reminder.isEnabled, isFalse);
  });
}
