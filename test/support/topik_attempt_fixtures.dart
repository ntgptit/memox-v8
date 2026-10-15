import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart'
    show AppDatabase, TopikAttemptAnswerRow, TopikAttemptRow;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';

/// Test helpers for the TOPIK attempt store.

/// The value of an [Ok]; fails the test on a refusal.
T topikOk<T>(Outcome<T, TopikRejection> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('rejected: $reason'),
};

/// The reason of a [Rejected]; fails the test on an [Ok].
TopikRejection topikReason(Outcome<Object?, TopikRejection> outcome) =>
    switch (outcome) {
      Ok() => fail('expected a rejection'),
      Rejected(:final reason) => reason,
    };

/// The answer rows of attempt [id] in question order.
Future<List<TopikAttemptAnswerRow>> topikAnswerRows(
  AppDatabase db,
  String id,
) =>
    (db.select(db.topikAttemptAnswer)
          ..where((a) => a.attemptId.equals(id))
          ..orderBy([(a) => OrderingTerm(expression: a.questionNo)]))
        .get();

/// The row of attempt [id], or null once it is gone.
Future<TopikAttemptRow?> topikAttemptRow(AppDatabase db, String id) =>
    (db.select(
      db.topikAttempt,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
