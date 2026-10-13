import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

import '../support/test_database.dart';

// DEV-208: the Progress statements read review_log through
// idx_review_log_answered (schema 14): the week and the month are a range of
// answered_at, never a scan of the history, and the streak probes one day at
// a time. The plan is pinned on a fresh database, with no statistics, so a
// device that never ran ANALYZE gets the same plan.

/// Keeps every SELECT the database runs, as it ran: the statements the plan
/// is read for are the DAO's own, not a copy of their SQL.
final class _SelectRecorder extends QueryInterceptor {
  final statements = <(String, List<Object?>)>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements.add((statement, args));
    return super.runSelect(executor, statement, args);
  }
}

/// The lines of `EXPLAIN QUERY PLAN` for every SELECT [read] runs, one
/// plan per statement.
Future<List<String>> _plansOf(
  AppDatabase db,
  _SelectRecorder recorder,
  Future<void> Function() read,
) async {
  recorder.statements.clear();
  await read();
  final recorded = recorder.statements.toList();
  final plans = <String>[];
  for (final (statement, args) in recorded) {
    final rows = await db
        .customSelect(
          'EXPLAIN QUERY PLAN $statement',
          variables: [for (final arg in args) Variable(arg)],
        )
        .get();
    plans.add(rows.map((row) => row.data.values.join(' ')).join('\n'));
  }
  return plans;
}

void main() {
  late AppDatabase db;
  late ProgressDao dao;
  late _SelectRecorder recorder;
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  setUp(() {
    recorder = _SelectRecorder();
    db = openTestDatabase(interceptor: recorder);
    dao = ProgressDao(db);
  });
  tearDown(() => db.close());

  test('the week and the root level read the range of answered_at through '
      'idx_review_log_answered, with no scan of review_log', () async {
    final plans = [
      ...await _plansOf(db, recorder, () => dao.weekActivity(days)),
      ...await _plansOf(db, recorder, () => dao.rootLevel(days)),
    ];

    expect(plans, hasLength(2));
    for (final plan in plans) {
      expect(plan, contains('USING INDEX idx_review_log_answered'));
      expect(plan, isNot(contains('SCAN r')));
    }
  });
}
