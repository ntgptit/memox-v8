import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

/// Rows changed since the database opened: a refused write leaves it as it
/// was.
Future<int> totalChanges(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle())
        .read<int>('n');

/// The rows of [table].
Future<int> rowCount(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

/// The study sessions of the database, open or not: a flow that must leave
/// none behind checks it at 0.
Future<int> studySessionCount(AppDatabase db) => rowCount(db, 'study_session');

/// SQLite finds the file sound and no foreign key dangles, which a migration
/// or a bulk write must leave true.
Future<void> expectIntegrity(AppDatabase db) async {
  final integrity = await db.customSelect('PRAGMA integrity_check').get();
  expect([for (final row in integrity) row.data.values.single], ['ok']);
  expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
}

AppDatabase openTestDatabase({QueryInterceptor? interceptor}) {
  final executor = NativeDatabase.memory();
  return AppDatabase(
    interceptor == null ? executor : executor.interceptWith(interceptor),
  );
}

/// Counts the SELECT statements the database runs, for the reads the spec
/// allows one statement (§11).
final class SelectCounter extends QueryInterceptor {
  int selects = 0;

  /// Every SELECT run, in order, for a test that checks a statement's shape.
  final statements = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects++;
    statements.add(statement);
    return super.runSelect(executor, statement, args);
  }
}

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (a search, progress or study read that fails).
final class FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

/// Fails every UPDATE the way a full disk or a broken constraint does, for
/// the error flows of a write.
final class FailingUpdates extends QueryInterceptor {
  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => throw SqliteException(
    extendedResultCode: 19,
    message: 'constraint failed',
  );
}

/// Cuts the meaning source of a `guess` question to its first [keep] rows
/// while [keep] is set, the way the fault injector of
/// S-STUDY-GUESS-BLOCKED-V2 does, with the database untouched.
final class ThinMeaningSource extends QueryInterceptor {
  ThinMeaningSource(this.keep);

  int? keep;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    final kept = keep;
    if (kept == null || !statement.contains('AS meaning_folded')) return rows;
    return rows.take(kept).toList();
  }
}
