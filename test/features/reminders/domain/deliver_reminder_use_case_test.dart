import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/reminders/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_fire_report_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/reminders/domain/usecases/deliver_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 step 4, A3, A4, E5: what a fire of the reminder does. It
// reads the settings and the workload again, shows at most one digest a day
// and schedules the next fire (reminders spec §9, D12, D16).

DateTime _t0() => DateTime(2026, 9, 26, 9);

final _firedAt = DateTime(2026, 9, 26, 20, 5);
final _tomorrowAt2000 = DateTime(2026, 9, 27, 20);

/// The workload read failing the way a locked database does (E5).
final class _UnreadableWorkload implements ReminderWorkloadRepository {
  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async => throw const DatabaseLockedFailure(cause: 'locked');
}

/// Fails the one write that records a delivery, and nothing else.
final class _FailingDeliveryRecord extends QueryInterceptor {
  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('reminder_last_delivered_at')) {
      throw SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );
    }
    return super.runUpdate(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;

  Future<void> useDatabase(AppDatabase database) async {
    db = database;
    settings = SettingsRepositoryImpl(db, now: _t0);
    await settings.setLanguage(language: LanguageChoice.vi);
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1200),
    );
  }

  setUp(() async {
    platform = FakeReminderPlatform();
    clock = FakeDayClock(_firedAt);
    await useDatabase(openTestDatabase());
  });
  tearDown(() => db.close());

  DeliverReminderUseCase deliver({ReminderWorkloadRepository? workloads}) =>
      DeliverReminderUseCase(
        settings,
        workloads ?? ReminderWorkloadRepositoryImpl(db),
        platform,
        clock,
      );

  /// Korean: one overdue and one due today; English: three due today, so it
  /// would come first if today's cards were read as overdue; Empty: nothing.
  Future<void> seedDueCards() async {
    final decks = DeckRepositoryImpl(db, now: _t0);
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    await decks.root('Empty');
    Future<void> learned(String deckId, String id, DateTime dueAt) =>
        insertCard(
          db,
          id: id,
          deckId: deckId,
          back: 'meaning $id',
          learnedAt: DateTime(2026, 9, 1),
          dueAt: dueAt,
          box: 2,
        );
    await learned(lesson.id, 'k1', DateTime(2026, 9, 20));
    await learned(lesson.id, 'k2', DateTime(2026, 9, 26));
    for (final id in ['e1', 'e2', 'e3']) {
      await learned(words.id, id, DateTime(2026, 9, 26));
    }
  }

  Future<DateTime?> lastDelivery() async =>
      (await settings.reminderSnapshot()).lastDeliveredAt;

  test('at its time with cards due, it shows one digest of the most urgent '
      'root in the chosen language, records it and schedules tomorrow '
      '(UC-REMINDER-001 step 4, BR-REMINDER-004, BR-REMINDER-005)', () async {
    await seedDueCards();

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.delivered);
    expect(report.dueCount, 2);
    expect(report.otherDeckCount, 1);
    expect(report.isRecorded, isTrue);
    expect(report.nextAt, _tomorrowAt2000);
    expect(platform.shown!.deckName, 'Korean');
    expect(platform.shown!.dueCount, 2);
    expect(platform.shownIn, LanguageChoice.vi);
    expect(platform.pending, _tomorrowAt2000);
    expect((await lastDelivery())!.isAtSameMomentAs(_firedAt), isTrue);
  });

  test('with nothing due it shows nothing, records nothing and schedules '
      'tomorrow (UC-REMINDER-001 A3, A4, BR-REMINDER-003)', () async {
    final decks = DeckRepositoryImpl(db, now: _t0);
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await insertCard(db, id: 'n1', deckId: lesson.id, back: 'new');

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.nothingDue);
    expect(report.nextAt, _tomorrowAt2000);
    expect(platform.shown, isNull);
    expect(await lastDelivery(), isNull);
  });

  test('the workload is read when the reminder fires, not when it was '
      'scheduled: cards studied since leave nothing to show '
      '(BR-REMINDER-003)', () async {
    await seedDueCards();
    await db.customStatement('UPDATE card_schedule SET due_at = ?', [
      DateTime(2026, 9, 30).millisecondsSinceEpoch ~/ 1000,
    ]);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.nothingDue);
    expect(platform.shown, isNull);
  });

  test('a fire before its time shows nothing and is scheduled for the time '
      'today (spec D12)', () async {
    await seedDueCards();
    clock.current = DateTime(2026, 9, 26, 19, 30);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.beforeReminderTime);
    expect(report.nextAt, DateTime(2026, 9, 26, 20));
    expect(platform.shown, isNull);
  });

  test('a second fire on the same day shows nothing more '
      '(BR-REMINDER-004)', () async {
    await seedDueCards();
    await deliver()();
    clock.current = DateTime(2026, 9, 26, 21);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.alreadyDeliveredToday);
    expect(report.nextAt, _tomorrowAt2000);
    expect(
      platform.calls.where((call) => call == PlatformCall.show),
      hasLength(1),
    );
  });

  test('a reminder that is off shows nothing and schedules nothing: a fire '
      'left over from before (UC-REMINDER-001 E6, spec D16)', () async {
    await seedDueCards();
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1200),
    );

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.disabled);
    expect(report.nextAt, isNull);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('a workload read that fails shows nothing, keeps the day open and '
      'schedules the next fire (UC-REMINDER-001 E5)', () async {
    final report = await deliver(workloads: _UnreadableWorkload())();

    expect(report.outcome, ReminderFireOutcome.workloadUnreadable);
    expect(report.nextAt, _tomorrowAt2000);
    expect(platform.shown, isNull);
    expect(await lastDelivery(), isNull);
  });

  test('settings that cannot be read show nothing and schedule nothing: no '
      'time is known (spec D16)', () async {
    await db.customStatement('DELETE FROM app_settings');

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.settingsUnreadable);
    expect(report.nextAt, isNull);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('a digest the platform refuses is not recorded, and the next fire is '
      'still scheduled (spec D16)', () async {
    await seedDueCards();
    platform.refusing.add(PlatformCall.show);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.couldNotShow);
    expect(report.isRecorded, isFalse);
    expect(report.nextAt, _tomorrowAt2000);
    expect(await lastDelivery(), isNull);
  });

  test('a delivery that cannot be recorded is still delivered, and tomorrow '
      'is scheduled from it (spec D16)', () async {
    await db.close();
    await useDatabase(
      AppDatabase(
        NativeDatabase.memory().interceptWith(_FailingDeliveryRecord()),
      ),
    );
    await seedDueCards();

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.delivered);
    expect(report.isRecorded, isFalse);
    expect(report.nextAt, _tomorrowAt2000);
  });

  test('a platform without reminders is asked nothing more, and nothing is '
      'read (BR-REMINDER-012)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.unsupported);
    expect(platform.calls, [PlatformCall.capability]);
  });
}
