import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/reminders/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// The cards due when the reminder fires, per root deck: the statement the
// Library's root level and Study Home read (reminders spec §7, D8).

final _now = DateTime(2026, 9, 26, 20);
final _startOfToday = startOfLocalDay(_now);

/// Fails the one statement the workload is read by, the way a locked or
/// broken database does, and nothing else.
final class _FailingWorkloadRead extends QueryInterceptor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('due_today_count')) {
      throw SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ReminderWorkloadRepositoryImpl workloads;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => _now);
    workloads = ReminderWorkloadRepositoryImpl(db);
  });
  tearDown(() => db.close());

  /// A learned card of [deckId] due at [dueAt].
  Future<void> learned(String deckId, String id, DateTime dueAt) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  Future<Map<String, ReminderDeckWorkload>> read() async => {
    for (final workload in await workloads.rootWorkloads(
      now: _now,
      startOfToday: _startOfToday,
    ))
      workload.name: workload,
  };

  test('a root counts the overdue and due-today cards of its whole tree, '
      'each once, and a root with none counts zero (BR-REMINDER-007, '
      'BR-STUDY-068)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    final part = await decks.sub(lesson.id, 'Part 1');
    await decks.root('Empty');
    await learned(part.id, 'o1', DateTime(2026, 9, 20));
    await learned(lesson.id, 'o2', DateTime(2026, 9, 25));
    await learned(lesson.id, 't1', _startOfToday);
    await learned(part.id, 't2', _startOfToday);
    await learned(part.id, 't3', _startOfToday);
    await learned(part.id, 'later', DateTime(2026, 9, 27));

    final roots = await read();

    expect(roots.keys, unorderedEquals(['Korean', 'Empty']));
    expect(roots['Korean']!.deckId, korean.id);
    expect(roots['Korean']!.overdueCount, 2);
    expect(roots['Korean']!.dueTodayCount, 3);
    expect(roots['Korean']!.dueCount, 5);
    expect(roots['Empty']!.dueCount, 0);
  });

  test('the overdue age is the local days since the oldest due card fell due '
      '(BR-REMINDER-006, BR-STUDY-067)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await learned(lesson.id, 'o1', DateTime(2026, 9, 20));
    await learned(lesson.id, 'o2', DateTime(2026, 9, 25));
    final today = await decks.root('Today only');
    final todayLesson = await decks.sub(today.id, 'Lesson');
    await learned(todayLesson.id, 't1', _startOfToday);

    final roots = await read();

    expect(roots['Korean']!.overdueDays, 6);
    expect(roots['Today only']!.overdueDays, 0);
  });

  test('a card still being learned is never due, and a root holding only '
      'those counts zero (BR-REMINDER-003, UC-REMINDER-001 A4)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await insertCard(db, id: 'n1', deckId: lesson.id, back: 'new');

    expect((await read())['Korean']!.dueCount, 0);
  });

  test('cards in the Trash are not due, and a root in the Trash is not read '
      '(BR-TRASH-002)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await learned(lesson.id, 'kept', DateTime(2026, 9, 20));
    await learned(lesson.id, 'binned', DateTime(2026, 9, 20));
    await trashCardRow(db, 'binned');
    final old = await decks.root('Old');
    final oldLesson = await decks.sub(old.id, 'Lesson');
    await learned(oldLesson.id, 'gone', DateTime(2026, 9, 20));
    await trashDeckRows(db, old.id);

    final roots = await read();

    expect(roots.keys, ['Korean']);
    expect(roots['Korean']!.overdueCount, 1);
  });

  test('a read that fails leaves as its Failure, for the delivery to skip '
      '(UC-REMINDER-001 E5)', () async {
    final failing = AppDatabase(
      NativeDatabase.memory().interceptWith(_FailingWorkloadRead()),
    );
    addTearDown(failing.close);

    await expectLater(
      ReminderWorkloadRepositoryImpl(failing)
          .rootWorkloads(now: _now, startOfToday: _startOfToday),
      throwsA(isA<DatabaseLockedFailure>()),
    );
  });
}
