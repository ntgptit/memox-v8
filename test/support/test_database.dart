import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:memox/core/database/app_database.dart';

/// Rows changed since the database opened: a refused write leaves it as it
/// was.
Future<int> totalChanges(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle())
        .read<int>('n');

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

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects++;
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
