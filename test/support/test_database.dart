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
