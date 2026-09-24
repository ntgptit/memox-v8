import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// Opens sessions on a deck (UC-STUDY-001 steps 3–5, UC-STUDY-003). Every
/// write is one transaction, which the settings reads it makes join: the
/// rules read the rows as they are at the moment of writing, and a
/// refusal writes nothing.
final class StudyEntryRepositoryImpl implements StudyEntryRepository {
  StudyEntryRepositoryImpl(
    this._db,
    this._settings, {
    DateTime Function()? now,
    Random? random,
  }) : _dao = StudySessionDao(_db),
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  final AppDatabase _db;
  final SettingsRepository _settings;
  final StudySessionDao _dao;
  final StudyQueueDao _queue;
  final DateTime Function() _now;

  /// Every shuffle and draw of a session (BR-STUDY-022, BR-STUDY-057).
  final Random _random;

  @override
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final scope = await _scope(deckId);
      if (scope == null) return const Rejected(StudyRejection.notFound);
      final (root, options) = scope;
      final candidates = _factsOf(await _dao.newCards(deckId));
      if (candidates.isEmpty) {
        return const Rejected(StudyRejection.nothingToLearn);
      }

      final cards = newCardsToLearn(candidates, options, _random);
      final queues = learningQueues(
        SchedulerType.fromCode(root.schedulerType!),
        cards,
        distinctMeaningCount: await _meaningsOf(root, cards),
        random: _random,
      );
      return Ok(
        await _open(
          deckId: deckId,
          root: root,
          kind: SessionKind.learning,
          cardLimit: options.cardLimit,
          queues: queues,
          at: at,
        ),
      );
    });
  }

  @override
  Future<Outcome<String, StudyRejection>> openReviewSession({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final scope = await _scope(deckId);
      if (scope == null) return const Rejected(StudyRejection.notFound);
      final (root, options) = scope;
      final due = _factsOf(await _dao.dueCards(deckId, at));
      final cards = due.take(options.cardLimit).toList();
      final planned = reviewQueue(
        SchedulerType.fromCode(root.schedulerType!),
        mode,
        direction: direction,
        dueCards: cards,
        distinctMeaningCount: await _meaningsOf(root, cards),
        random: _random,
      );
      switch (planned) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: final queue):
          return Ok(
            await _open(
              deckId: deckId,
              root: root,
              kind: SessionKind.reviewing,
              cardLimit: options.cardLimit,
              queues: [queue],
              direction: direction,
              at: at,
            ),
          );
      }
    });
  }

  /// The root of [deckId] and the options it studies with; null when the
  /// deck is gone or in the Trash.
  Future<(Deck, StudyOptions)?> _scope(String deckId) async {
    final deck = await _dao.deckRow(deckId);
    final options = await _settings.studyOptionsOf(deckId: deckId);
    if (deck == null || options == null) return null;
    final root = await _dao.deckRow(deck.rootId);
    if (root == null) return null;
    return (root, options.options);
  }

  /// The distinct meanings the `guess` stage can draw from (spec D5).
  Future<int> _meaningsOf(Deck root, List<StudyCardFacts> cards) => _dao
      .distinctMeaningCount(root.id, [for (final card in cards) card.cardId]);

  /// Closes the app's open session (spec D2), then writes the new session
  /// and round 1 of its [queues], the first of which it starts in, with the
  /// session's [direction] choice and each row's own direction (BR-MODE-015).
  Future<String> _open({
    required String deckId,
    required Deck root,
    required SessionKind kind,
    required int cardLimit,
    required List<StageQueue> queues,
    required DateTime at,
    DirectionChoice? direction,
  }) async {
    await _dao.closeOpenSessions(now: at, startOfToday: startOfLocalDay(at));
    final id = newId();
    await _dao.insertSession(
      StudySessionCompanion.insert(
        id: id,
        deckId: deckId,
        rootId: root.id,
        generation: root.generation!,
        sessionKind: kind.name,
        currentMode: queues.first.mode.code,
        status: SessionStatus.inProgress.code,
        cardLimit: Value(cardLimit),
        direction: Value(direction?.code),
        startedAt: at,
      ),
    );
    for (final queue in queues) {
      await _queue.insertFirstRound(
        id,
        queue.mode.code,
        queue.cardIds,
        directions: queue.directions
            ?.map((direction) => direction.code)
            .toList(),
      );
    }
    return id;
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

/// The cards [rows] name, as the study modes read them.
List<StudyCardFacts> _factsOf(List<StudyCardRow> rows) => [
  for (final row in rows)
    StudyCardFacts(cardId: row.cardId, hasExample: row.hasExample),
];
