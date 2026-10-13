import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:uuid/uuid.dart';

part 'sync_store.g.dart';

/// The outbox and sync state in Drift (app deck-sync spec §3, §5;
/// `sync_outbox_queries.drift`).
@DriftAccessor(
  include: {'package:memox/core/database/queries/sync_outbox_queries.drift'},
)
class SyncStore extends DatabaseAccessor<AppDatabase> with _$SyncStoreMixin {
  SyncStore(super.attachedDatabase);

  static const _uuid = Uuid();

  Future<String> deviceId() => transaction(() async {
    final existing = await _value(syncDeviceIdKey);
    if (existing != null) {
      return existing;
    }
    final created = _uuid.v4();
    await _put(syncDeviceIdKey, created);
    return created;
  });

  Future<int> since() async => int.parse(await _value(syncSinceKey) ?? '0');

  Future<void> setSince(int since) => _put(syncSinceKey, '$since');

  Future<String?> pullEntityTypes() => _value(syncPullEntityTypesKey);

  Future<void> setPullEntityTypes(String types) =>
      _put(syncPullEntityTypesKey, types);

  /// The entity type whose pending entries go shallower first (DEV-182); the
  /// literal `pendingDeckOutbox` filters on.
  static const _deckEntityType = 'deck';

  /// Up to [limit] pending operations of one entity type: the first of
  /// [entityTypes] (the coordinator's adapter order) that has any, first
  /// queued first, so parents go before children. A card queued before the
  /// deck it moved into still follows that deck; among decks, a shallower
  /// row goes before a deeper one, so a child pending since before its new
  /// parent was made still follows it (DEV-182). Each type is one range read
  /// of `idx_sync_outbox_type_created`, never a sort of the outbox (DEV-205).
  Future<List<SyncOutboxEntry>> pendingBatch(
    List<String> entityTypes,
    int limit,
  ) async {
    for (final entityType in entityTypes) {
      final batch = entityType == _deckEntityType
          ? await pendingDeckOutbox(limit).get()
          : await pendingOutboxOfType(entityType, limit).get();
      if (batch.isNotEmpty) {
        return batch;
      }
    }
    return const [];
  }

  Future<bool> isPendingEntity(String entityType, String entityId) =>
      isEntityPending(entityType, entityId).getSingle();

  Future<bool> isPending(String opId) => isOpPending(opId).getSingle();

  /// Removes the entry only if no later write replaced its op id.
  Future<void> removeIfUnchanged(String opId) => deleteOutboxOp(opId);

  Future<void> recordFailedAttempt(Iterable<String> opIds) =>
      countFailedAttempt(opIds.toList());

  /// Runs [body] in one transaction whose writes the capture triggers skip.
  Future<T> applyingRemote<T>(
    Future<T> Function() body, {
    bool deferForeignKeys = false,
  }) => transaction(() async {
    if (deferForeignKeys) {
      // A child may arrive before its parent; keys are checked at commit.
      await customStatement('PRAGMA defer_foreign_keys = ON');
    }
    await _put(syncApplyingRemoteKey, '1');
    try {
      return await body();
    } finally {
      await deleteSyncState(syncApplyingRemoteKey);
    }
  });

  Future<T> inTransaction<T>(Future<T> Function() body) => transaction(body);

  /// The rows whose foreign key is unmet right now, as `table#rowid->parent`
  /// (SQLite's `foreign_key_check`), for a log before a commit that would
  /// fail on them (DEV-185).
  Future<List<String>> foreignKeyViolations() async {
    final rows = await customSelect('PRAGMA foreign_key_check').get();
    return [
      for (final row in rows)
        '${row.read<String>('table')}#${row.readNullable<int>('rowid')}'
            '->${row.read<String>('parent')}',
    ];
  }

  Future<void> recordSuccess(DateTime now) =>
      _put(syncLastSuccessAtKey, _millis(now));

  Future<void> recordFailure(SyncFailureKind kind, DateTime now) =>
      transaction(() async {
        await _put(syncLastFailureAtKey, _millis(now));
        await _put(syncLastFailureKindKey, kind.name);
      });

  /// A refusal without a server copy, or one whose copy could not be applied
  /// here (spec §4, DEV-183); replaces an earlier one.
  Future<void> recordRejection(
    String entityType,
    String entityId,
    String code,
    DateTime now,
  ) => upsertSyncRejection(
    SyncRejectionCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      code: code,
      rejectedAt: now.toUtc(),
    ),
  );

  Future<void> clearRejection(String entityType, String entityId) =>
      deleteSyncRejection(entityType, entityId);

  Future<List<SyncRejectionEntry>> rejections() => allSyncRejections().get();

  /// Keep on this device (R7): the records go, the rows stay local.
  Future<void> forgetRejected() => deleteAllSyncRejections();

  /// Queues [entityId] as the capture triggers would: a new op id, and the
  /// first unsent time kept when it was already pending.
  Future<void> enqueue(
    String entityType,
    String entityId,
    String op,
    DateTime now,
  ) => enqueueOutbox(_uuid.v4(), entityType, entityId, op, now);

  /// One row read from the three tables, re-read whenever any changes.
  Stream<SyncStatus> watchStatus() => syncStatusRow(
    syncLastSuccessAtKey,
    syncLastFailureAtKey,
    syncLastFailureKindKey,
  ).watchSingle().map(_statusOf);

  static SyncStatus _statusOf(SyncStatusRow row) {
    final success = _fromMillis(row.lastSuccessAt);
    final failureAt = _fromMillis(row.lastFailureAt);
    final kind = SyncFailureKind.parse(row.lastFailureKind);
    // Inline, so failureAt and kind are promoted to non-null.
    final lastFailure =
        failureAt != null &&
            kind != null &&
            (success == null || failureAt.isAfter(success))
        ? LastSyncFailure(kind, failureAt)
        : null;
    return SyncStatus(
      lastSuccessAt: success,
      lastFailure: lastFailure,
      pendingCount: row.pendingCount,
      oldestPendingAt: row.oldestPendingAt?.toUtc(),
      rejectedCount: row.rejectedCount,
    );
  }

  static String _millis(DateTime at) => '${at.toUtc().millisecondsSinceEpoch}';

  static DateTime? _fromMillis(String? value) {
    final millis = value == null ? null : int.tryParse(value);
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  /// Fires once when listened to, then after every write to the outbox.
  Stream<void> outboxChanges() =>
      tableChanges(attachedDatabase, [attachedDatabase.syncOutbox]);

  Future<String?> _value(String key) => syncStateValue(key).getSingleOrNull();

  Future<void> _put(String key, String value) =>
      putSyncState(SyncStateCompanion.insert(name: key, value: value));

  /// How many changes wait in the outbox (auth spec §5).
  Future<int> pendingCount() => outboxCount().getSingle();

  /// Every local row queued for upload in the migrations' parents-first
  /// order, the settings row included, and the pull cursor back to 0: a new
  /// anonymous user gets the whole library (auth spec #12). A row already
  /// queued keeps its operation, so a rerun queues nothing twice (plan
  /// ruling 12). The order is the coordinator's adapter order.
  Future<void> markAllPending() => transaction(() async {
    await seedDeleteBatchOutbox();
    await seedDeckOutbox();
    await seedTagOutbox();
    await seedCardOutbox();
    await seedCardScheduleOutbox();
    await seedReviewLogOutbox();
    await seedAccountSettingsOutbox(accountSettingsEntityId, appSettingsRowId);
    await setSince(0);
  });
}
