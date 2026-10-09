import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

part 'review_log_sync_dao.g.dart';

/// Syncs `review_log`, the append-only study history (library and study sync
/// spec §3.3). A pulled review is inserted if absent; the table forbids
/// updates and the server never tombstones a review, so acknowledgements and
/// deletes do nothing (plan R15).
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/sync_review_log_queries.drift',
  },
)
class ReviewLogSyncDao extends DatabaseAccessor<AppDatabase>
    with _$ReviewLogSyncDaoMixin, EntitySyncAdapter {
  ReviewLogSyncDao(super.attachedDatabase);

  static const type = 'review_log';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final r = await syncReviewLogRow(id).getSingleOrNull();
    if (r == null) {
      return null;
    }
    return {
      'id': r.id,
      'cardId': r.cardId,
      'sessionId': r.sessionId,
      'schedulerType': r.schedulerType,
      'generation': r.generation,
      'kind': r.kind,
      'mode': r.mode,
      'outcomeReason': r.outcomeReason,
      'comparisonVersion': r.comparisonVersion,
      'usedHint': r.usedHint,
      'direction': r.direction,
      'action': r.action,
      'answeredAt': _time(r.answeredAt),
      'nextDueAt': _time(r.nextDueAt),
      'previousBox': r.previousBox,
      'nextBox': r.nextBox,
      'previousEaseFactor': r.previousEaseFactor,
      'nextEaseFactor': r.nextEaseFactor,
      'previousIntervalDays': r.previousIntervalDays,
      'nextIntervalDays': r.nextIntervalDays,
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      insertSyncedReviewLog(
        ReviewLogCompanion.insert(
          id: row['id'] as String,
          cardId: row['cardId'] as String,
          sessionId: row['sessionId'] as String,
          schedulerType: row['schedulerType'] as String,
          generation: row['generation'] as int,
          kind: row['kind'] as String,
          mode: row['mode'] as String,
          outcomeReason: Value(row['outcomeReason'] as String?),
          comparisonVersion: Value(row['comparisonVersion'] as int?),
          usedHint: Value(row['usedHint'] as int?),
          direction: Value(row['direction'] as String?),
          action: row['action'] as String,
          answeredAt: fromWireTime(row['answeredAt'])!,
          nextDueAt: Value(fromWireTime(row['nextDueAt'])),
          previousBox: Value(row['previousBox'] as int?),
          nextBox: Value(row['nextBox'] as int?),
          previousEaseFactor: Value(
            (row['previousEaseFactor'] as num?)?.toDouble(),
          ),
          nextEaseFactor: Value((row['nextEaseFactor'] as num?)?.toDouble()),
          previousIntervalDays: Value(row['previousIntervalDays'] as int?),
          nextIntervalDays: Value(row['nextIntervalDays'] as int?),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) async {}

  @override
  Future<void> markAcknowledged(String id, int serverVersion) async {}

  /// Drift stores whole seconds; the wire drops the fraction so a round trip
  /// is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
