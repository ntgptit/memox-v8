import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/schedule_progress.dart';
import 'package:memox/core/sync/sync_store.dart';

part 'card_schedule_sync_adapter.g.dart';

/// Syncs `card_schedule` as a row keyed by its card (library and study sync
/// spec §3.4, ADR-017). A pulled schedule replaces the local one unless the
/// local one has progressed further; then the local row stays and is queued
/// again, so every device converges on the most advanced schedule. The server
/// never tombstones a schedule and the row keeps no server version, so
/// acknowledgements and deletes do nothing (plan R15).
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/sync_card_schedule_queries.drift',
  },
)
class CardScheduleSyncAdapter extends DatabaseAccessor<AppDatabase>
    with _$CardScheduleSyncAdapterMixin, EntitySyncAdapter {
  CardScheduleSyncAdapter(
    super.attachedDatabase,
    this._store, {
    this._now = DateTime.now,
  });

  static const type = 'card_schedule';
  static const _upsert = 'upsert';

  final SyncStore _store;
  final DateTime Function() _now;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final s = await _row(id);
    if (s == null) {
      return null;
    }
    return {
      'cardId': s.cardId,
      'schedulerType': s.schedulerType,
      'schedulerVersion': s.schedulerVersion,
      'generation': s.generation,
      'learnedAt': _time(s.learnedAt),
      'dueAt': _time(s.dueAt),
      'lastAnsweredAt': _time(s.lastAnsweredAt),
      'answerCount': s.answerCount,
      'lapseCount': s.lapseCount,
      'currentBox': s.currentBox,
      'easeFactor': s.easeFactor,
      'intervalDays': s.intervalDays,
      'repetitions': s.repetitions,
    };
  }

  @override
  Future<void> upsertFromServer(
    Map<String, Object?> row,
    int serverVersion,
  ) async {
    final cardId = row['cardId'] as String;
    final pulled = _companionOf(cardId, row);
    final local = await _row(cardId);
    if (local != null &&
        compareScheduleProgress(
              _progressOf(local),
              _progressOfCompanion(pulled),
              rootSchedulerType: await _rootSchedulerType(cardId),
            ) >
            0) {
      await _store.enqueue(type, cardId, _upsert, _now());
      return;
    }
    await upsertSyncedCardSchedule(pulled);
  }

  @override
  Future<void> deleteFromServer(String id) async {}

  @override
  Future<void> markAcknowledged(String id, int serverVersion) async {}

  Future<CardSchedule?> _row(String cardId) =>
      syncCardScheduleRow(cardId).getSingleOrNull();

  /// The scheduler of the card's root, the card and its decks in any state:
  /// the order of spec §3.4 compares against it. Null when not local.
  Future<String?> _rootSchedulerType(String cardId) =>
      syncRootSchedulerOf(cardId).getSingleOrNull();

  static CardScheduleCompanion _companionOf(
    String cardId,
    Map<String, Object?> row,
  ) => CardScheduleCompanion.insert(
    cardId: cardId,
    schedulerType: row['schedulerType'] as String,
    schedulerVersion: row['schedulerVersion'] as int,
    generation: row['generation'] as int,
    learnedAt: Value(fromWireTime(row['learnedAt'])),
    dueAt: Value(fromWireTime(row['dueAt'])),
    lastAnsweredAt: Value(fromWireTime(row['lastAnsweredAt'])),
    answerCount: Value(row['answerCount'] as int),
    lapseCount: Value(row['lapseCount'] as int),
    currentBox: Value(row['currentBox'] as int?),
    easeFactor: Value((row['easeFactor'] as num?)?.toDouble()),
    intervalDays: Value(row['intervalDays'] as int?),
    repetitions: Value(row['repetitions'] as int?),
  );

  static ScheduleProgress _progressOf(CardSchedule s) => (
    generation: s.generation,
    schedulerType: s.schedulerType,
    lastAnsweredAt: s.lastAnsweredAt,
    learnedAt: s.learnedAt,
    answerCount: s.answerCount,
  );

  static ScheduleProgress _progressOfCompanion(CardScheduleCompanion s) => (
    generation: s.generation.value,
    schedulerType: s.schedulerType.value,
    lastAnsweredAt: s.lastAnsweredAt.value,
    learnedAt: s.learnedAt.value,
    answerCount: s.answerCount.value,
  );

  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
