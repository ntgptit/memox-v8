import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/srs/data/datasources/srs_dao.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

// `study_session.end_reason` values (schema.md, invariant 12).
const _schedulerChanged = 'scheduler_changed';
const _schedulerReset = 'scheduler_reset';

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
  Future<Outcome<void, SrsRejection>> recordReview({
    required String cardId,
    required String sessionId,
    required Object action,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final schedule = await _dao.scheduleRow(cardId);
      final root = await _dao.rootOfCard(cardId);
      if (schedule == null || root == null) {
        return const Rejected(SrsRejection.notFound);
      }
      final type = SchedulerType.fromCode(root.schedulerType!);
      final scheduler = schedulerFor(type);
      if (!scheduler.supportedActions.contains(action)) {
        return const Rejected(SrsRejection.unsupportedAction);
      }
      final session = await _dao.sessionRow(sessionId);
      if (session == null) return const Rejected(SrsRejection.notFound);
      if (session.generation != root.generation) {
        return const Rejected(SrsRejection.staleGeneration);
      }

      final before = _stateOf(schedule);
      final (after, entry) = scheduler.next(before, action, at);
      await _dao.updateSchedule(
        cardId,
        _columnsOf(after, type: type, version: root.schedulerVersion!),
      );
      await _dao.insertReviewLog(
        _logOf(
          entry,
          cardId: cardId,
          sessionId: sessionId,
          mode: session.currentMode,
          type: type,
          generation: after.generation,
          action: action as Enum,
          at: at,
        ),
      );
      // The first card of the tree to finish learning locks its scheduler
      // (BR-SRS-003).
      final learnedNow = before.learnedAt == null && after.learnedAt != null;
      if (learnedNow && root.firstAnsweredAt == null) {
        await _dao.updateDeck(
          root.id,
          DeckCompanion(firstAnsweredAt: Value(at), updatedAt: Value(at)),
        );
      }
      return const Ok(null);
    });
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
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
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
  ReviewLogEntry entry, {
  required String cardId,
  required String sessionId,
  required String mode,
  required SchedulerType type,
  required int generation,
  required Enum action,
  required DateTime at,
}) => ReviewLogCompanion.insert(
  id: newId(),
  cardId: cardId,
  sessionId: sessionId,
  schedulerType: type.code,
  generation: generation,
  kind: entry.kind.name,
  mode: mode,
  action: action.name,
  answeredAt: at,
  nextDueAt: Value(entry.nextDueAt),
  previousBox: Value(entry.previousBox),
  nextBox: Value(entry.nextBox),
  previousEaseFactor: Value(entry.previousEaseFactor),
  nextEaseFactor: Value(entry.nextEaseFactor),
  previousIntervalDays: Value(entry.previousIntervalDays),
  nextIntervalDays: Value(entry.nextIntervalDays),
);
