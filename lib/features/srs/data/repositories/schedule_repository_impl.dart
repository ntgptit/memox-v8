import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/srs/data/datasources/srs_dao.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

// `study_session.end_reason` values (schema.md, invariant 12).
const _schedulerChanged = 'scheduler_changed';
const _schedulerReset = 'scheduler_reset';

/// The root of a card's tree and the card's schedule.
typedef _Studied = (Deck, CardScheduleState);

/// Every method runs in one transaction, which joins the caller's when there
/// is one: the rules read the rows as they are at the moment of writing.
final class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = SrsDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SrsDao _dao;
  final DateTime Function() _now;

  /// Not mapped to a [Failure]: the contract's [StateError] must reach the
  /// caller, whose own transaction maps what leaves it.
  @override
  Future<void> initializeCard({required String cardId}) =>
      _db.transaction(() async {
        final root = await _dao.rootOfCard(cardId);
        if (root == null) throw StateError('card $cardId does not exist');
        final type = SchedulerType.fromCode(root.schedulerType!);
        final state = CardScheduleState.initial(
          type,
          generation: root.generation!,
        );
        await _dao.insertSchedule(
          _columnsOf(
            state,
            type: type,
            version: root.schedulerVersion!,
          ).copyWith(cardId: Value(cardId)),
        );
      });

  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) =>
      _write(() async {
        switch (await _studied(turn.cardId, turn.generation)) {
          case Rejected(:final reason):
            return Rejected(reason);
          case Ok(value: (final root, final before)):
            return _record(turn, root, before);
        }
      });

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      switch (await _studied(cardId, generation)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final root, final before)):
          return _complete(cardId, root, before, at);
      }
    });
  }

  Future<Outcome<void, SrsRejection>> _record(
    ReviewTurn turn,
    Deck root,
    CardScheduleState before,
  ) async {
    final type = SchedulerType.fromCode(root.schedulerType!);
    final scheduler = schedulerFor(type);
    if (!scheduler.supportedActions.contains(turn.action)) {
      return const Rejected(SrsRejection.unsupportedAction);
    }
    // A scheduled turn on a card still learning is a bug the scheduler throws
    // on, which rolls the turn back (BR-STUDY-058).
    final (after, entry) = turn.kind == ReviewKind.scheduled
        ? scheduler.next(before, turn.action, turn.answeredAt)
        : _unchanged(before, turn.kind, turn.answeredAt);
    await _dao.updateSchedule(
      turn.cardId,
      _columnsOf(after, type: type, version: root.schedulerVersion!),
    );
    await _dao.insertReviewLog(_logOf(entry, turn, type));
    return const Ok(null);
  }

  Future<Outcome<void, SrsRejection>> _complete(
    String cardId,
    Deck root,
    CardScheduleState before,
    DateTime at,
  ) async {
    // Completing a learned card again is a bug the scheduler throws on.
    final type = SchedulerType.fromCode(root.schedulerType!);
    await _dao.updateSchedule(
      cardId,
      _columnsOf(
        schedulerFor(type).learned(before, at),
        type: type,
        version: root.schedulerVersion!,
      ),
    );
    // The first card of the generation to finish learning locks the
    // scheduler (BR-SRS-003); a later one keeps that mark.
    if (root.firstAnsweredAt == null) {
      await _dao.updateDeck(
        root.id,
        DeckCompanion(firstAnsweredAt: Value(at), updatedAt: Value(at)),
      );
    }
    return const Ok(null);
  }

  /// The root and the schedule of [cardId], read inside the caller's
  /// transaction: notFound when the card is gone or in the Trash (BE-C3),
  /// staleGeneration when [generation] is not the root's (BR-SRS-026).
  Future<Outcome<_Studied, SrsRejection>> _studied(
    String cardId,
    int generation,
  ) async {
    final root = await _dao.rootOfCard(cardId);
    final schedule = await _dao.scheduleRow(cardId);
    if (root == null || schedule == null) {
      return const Rejected(SrsRejection.notFound);
    }
    if (generation != root.generation || schedule.generation != generation) {
      return const Rejected(SrsRejection.staleGeneration);
    }
    return Ok((root, _stateOf(schedule)));
  }

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) {
    final at = _now();
    return _write(() async {
      final root = await _dao.deckRow(rootDeckId);
      if (root == null) return const Rejected(SrsRejection.notFound);
      if (root.parentId != null) {
        return const Rejected(SrsRejection.notARootDeck);
      }
      final current = SchedulerType.fromCode(root.schedulerType!);
      final type = schedulerType ?? current;
      // The scheduler the root keeps keeps its version; another one starts at
      // the version this app runs, as changeScheduler does (spec D7).
      final version = type == current
          ? root.schedulerVersion!
          : schedulerFor(type).version;
      final generation = root.generation! + 1;
      await _dao.updateDeck(
        rootDeckId,
        DeckCompanion(
          schedulerType: Value(type.code),
          schedulerVersion: Value(version),
          generation: Value(generation),
          firstAnsweredAt: const Value(null),
          updatedAt: Value(at),
        ),
      );
      await _dao.replaceTreeSchedules(
        rootDeckId,
        _columnsOf(
          CardScheduleState.initial(type, generation: generation),
          type: type,
          version: version,
        ),
      );
      await _dao.invalidateOpenSessions(
        rootDeckId,
        endReason: _schedulerReset,
        now: at,
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  }) => _mapped(() async {
    final row = await _dao.resetSummaryRow(rootDeckId);
    if (row == null) return const Rejected(SrsRejection.notFound);
    final root = row.deck;
    if (root.parentId != null) return const Rejected(SrsRejection.notARootDeck);
    return Ok(
      ResetLearningSummary(
        schedulerType: SchedulerType.fromCode(root.schedulerType!),
        isSchedulerLocked: root.firstAnsweredAt != null,
        cardCount: row.cardCount,
        learnedCardCount: row.learnedCardCount,
        openSessionCount: row.openSessionCount,
      ),
    );
  });

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType newType,
  }) {
    final at = _now();
    return _write(() async {
      final root = await _dao.deckRow(rootDeckId);
      if (root == null) return const Rejected(SrsRejection.notFound);
      if (root.parentId != null) {
        return const Rejected(SrsRejection.notARootDeck);
      }
      // The scheduler the root already runs changes nothing, locked or not
      // (BR-SRS-002; foundation plan, Clarification 13).
      if (root.schedulerType == newType.code) return const Ok(null);
      if (root.firstAnsweredAt != null) {
        return const Rejected(SrsRejection.schedulerLocked);
      }

      final version = schedulerFor(newType).version;
      await _dao.updateDeck(
        rootDeckId,
        DeckCompanion(
          schedulerType: Value(newType.code),
          schedulerVersion: Value(version),
          updatedAt: Value(at),
        ),
      );
      await _dao.replaceTreeSchedules(
        rootDeckId,
        _columnsOf(
          CardScheduleState.initial(newType, generation: root.generation!),
          type: newType,
          version: version,
        ),
      );
      await _dao.invalidateOpenSessions(
        rootDeckId,
        endReason: _schedulerChanged,
        now: at,
      );
      return const Ok(null);
    });
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  /// [body], with an unexpected database error leaving as its [Failure].
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

CardScheduleState _stateOf(CardSchedule row) => CardScheduleState.fromColumns(
  type: SchedulerType.fromCode(row.schedulerType),
  generation: row.generation,
  learnedAt: row.learnedAt,
  dueAt: row.dueAt,
  lastAnsweredAt: row.lastAnsweredAt,
  answerCount: row.answerCount,
  lapseCount: row.lapseCount,
  currentBox: row.currentBox,
  easeFactor: row.easeFactor,
  intervalDays: row.intervalDays,
  repetitions: row.repetitions,
);

/// A `learning` or `relearning` turn: the schedule stays as it is but for
/// `last_answered_at`, and the log's before and after values are the same
/// (BR-SRS-017, BR-SRS-018, invariant 14).
(CardScheduleState, ReviewLogEntry) _unchanged(
  CardScheduleState state,
  ReviewKind kind,
  DateTime at,
) => (
  state.copyWith(lastAnsweredAt: at),
  ReviewLogEntry(
    kind: kind,
    previousBox: state.currentBox,
    nextBox: state.currentBox,
    previousEaseFactor: state.easeFactor,
    nextEaseFactor: state.easeFactor,
    previousIntervalDays: state.intervalDays,
    nextIntervalDays: state.intervalDays,
    nextDueAt: state.dueAt,
  ),
);

/// Every column of a `card_schedule` row but `card_id`.
CardScheduleCompanion _columnsOf(
  CardScheduleState state, {
  required SchedulerType type,
  required int version,
}) => CardScheduleCompanion(
  schedulerType: Value(type.code),
  schedulerVersion: Value(version),
  generation: Value(state.generation),
  learnedAt: Value(state.learnedAt),
  dueAt: Value(state.dueAt),
  lastAnsweredAt: Value(state.lastAnsweredAt),
  answerCount: Value(state.answerCount),
  lapseCount: Value(state.lapseCount),
  currentBox: Value(state.currentBox),
  easeFactor: Value(state.easeFactor),
  intervalDays: Value(state.intervalDays),
  repetitions: Value(state.repetitions),
);

ReviewLogCompanion _logOf(
  ReviewLogEntry entry,
  ReviewTurn turn,
  SchedulerType type,
) => ReviewLogCompanion.insert(
  id: newId(),
  cardId: turn.cardId,
  sessionId: turn.sessionId,
  schedulerType: type.code,
  generation: turn.generation,
  kind: entry.kind.name,
  mode: turn.modeCode,
  direction: Value(turn.directionCode),
  action: (turn.action as Enum).name,
  answeredAt: turn.answeredAt,
  nextDueAt: Value(entry.nextDueAt),
  previousBox: Value(entry.previousBox),
  nextBox: Value(entry.nextBox),
  previousEaseFactor: Value(entry.previousEaseFactor),
  nextEaseFactor: Value(entry.nextEaseFactor),
  previousIntervalDays: Value(entry.previousIntervalDays),
  nextIntervalDays: Value(entry.nextIntervalDays),
);
