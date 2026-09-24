import 'dart:math';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';

import 'invariant_queries.dart';

// The study repositories and the reads the study tests check them with.

/// The study entry repository over [db], reading the options through the
/// real settings repository and the time from [now], and shuffling with a
/// seeded source, so every order a test sees repeats.
StudyEntryRepositoryImpl studyEntryRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
}) => StudyEntryRepositoryImpl(
  db,
  SettingsRepositoryImpl(db, now: now),
  now: now,
  random: Random(seed),
);

/// No invariant query of schema.md returns a row, and at most one session
/// of the app is open (spec D2).
Future<void> expectStudyInvariants(AppDatabase db) async {
  for (final MapEntry(key: number, value: query) in invariantQueries.entries) {
    expect(
      await db.customSelect(query).get(),
      isEmpty,
      reason: 'invariant $number: ${invariantSummaries[number]}',
    );
  }
  final open = await db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_session WHERE status = 'in_progress'",
      )
      .getSingle();
  expect(open.read<int>('n'), lessThanOrEqualTo(1), reason: 'spec D2');
}

Future<QueryRow> sessionOf(AppDatabase db, String sessionId) => db
    .customSelect(
      'SELECT * FROM study_session WHERE id = ?',
      variables: [Variable(sessionId)],
    )
    .getSingle();

/// The cards of [sessionId]'s rows in [mode] and [round], in serving order.
Future<List<String>> queueOf(
  AppDatabase db,
  String sessionId,
  String mode, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id FROM study_queue_items '
            'WHERE session_id = ? AND mode = ? AND round = ? ORDER BY position',
            variables: [Variable(sessionId), Variable(mode), Variable(round)],
          )
          .get())
    row.read<String>('card_id'),
];

/// The modes [sessionId] has rows in, in the order of the chain.
Future<List<String>> modesOf(AppDatabase db, String sessionId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT mode FROM study_queue_items WHERE session_id = ? '
            'GROUP BY mode ORDER BY MIN(rowid)',
            variables: [Variable(sessionId)],
          )
          .get())
    row.read<String>('mode'),
];
