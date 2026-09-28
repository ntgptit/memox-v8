import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:uuid/uuid.dart';

/// The outbox and sync state in Drift (app deck-sync spec §3, §5).
class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  Future<String> deviceId() => _db.transaction(() async {
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

  /// Pending operations of [entityTypes], oldest first (parents before
  /// children).
  Future<List<SyncOutboxEntry>> pendingBatch(
    Set<String> entityTypes,
    int limit,
  ) =>
      (_db.select(_db.syncOutbox)
            ..where((o) => o.entityType.isIn(entityTypes))
            ..orderBy([
              (o) => OrderingTerm(expression: o.createdAt),
              (o) => OrderingTerm(
                expression: const CustomExpression<int>('rowid'),
              ),
            ])
            ..limit(limit))
          .get();

  Future<bool> isPending(String opId) async =>
      await (_db.select(
        _db.syncOutbox,
      )..where((o) => o.opId.equals(opId))).getSingleOrNull() !=
      null;

  Future<Set<String>> pendingKeys() async => {
    for (final entry in await _db.select(_db.syncOutbox).get())
      '${entry.entityType}/${entry.entityId}',
  };

  /// Removes the entry only if no later write replaced its op id.
  Future<void> removeIfUnchanged(String opId) =>
      (_db.delete(_db.syncOutbox)..where((o) => o.opId.equals(opId))).go();

  Future<void> recordFailedAttempt(Iterable<String> opIds) =>
      _db.customStatement(
        'UPDATE sync_outbox SET attempts = attempts + 1 '
        'WHERE op_id IN (${List.filled(opIds.length, '?').join(', ')})',
        opIds.toList(),
      );

  /// Runs [body] in one transaction whose writes the capture triggers skip.
  Future<T> applyingRemote<T>(
    Future<T> Function() body, {
    bool deferForeignKeys = false,
  }) => _db.transaction(() async {
    if (deferForeignKeys) {
      // A child may arrive before its parent; keys are checked at commit.
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
    }
    await _put(syncApplyingRemoteKey, '1');
    try {
      return await body();
    } finally {
      await (_db.delete(
        _db.syncState,
      )..where((s) => s.name.equals(syncApplyingRemoteKey))).go();
    }
  });

  Future<T> inTransaction<T>(Future<T> Function() body) =>
      _db.transaction(body);

  Future<void> recordSuccess(DateTime now) =>
      _put(syncLastSuccessAtKey, _millis(now));

  Future<void> recordFailure(SyncFailureKind kind, DateTime now) =>
      _db.transaction(() async {
        await _put(syncLastFailureAtKey, _millis(now));
        await _put(syncLastFailureKindKey, kind.name);
      });

  /// A refusal without a server copy (spec §4); replaces an earlier one.
  Future<void> recordRejection(
    String entityType,
    String entityId,
    String code,
    DateTime now,
  ) => _db
      .into(_db.syncRejection)
      .insertOnConflictUpdate(
        SyncRejectionCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          code: code,
          rejectedAt: now.toUtc(),
        ),
      );

  Future<void> clearRejection(String entityType, String entityId) =>
      (_db.delete(_db.syncRejection)..where(
            (r) =>
                r.entityType.equals(entityType) & r.entityId.equals(entityId),
          ))
          .go();

  Future<List<SyncRejectionEntry>> rejections() =>
      (_db.select(_db.syncRejection)..orderBy([
            (r) => OrderingTerm(expression: r.entityType),
            (r) => OrderingTerm(expression: r.entityId),
          ]))
          .get();

  /// Keep on this device (R7): the records go, the rows stay local.
  Future<void> forgetRejected() => _db.delete(_db.syncRejection).go();

  /// Queues [entityId] as the capture triggers would: a new op id, and the
  /// first unsent time kept when it was already pending.
  Future<void> enqueue(
    String entityType,
    String entityId,
    String op,
    DateTime now,
  ) => _db.customStatement(
    'INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at) '
    'VALUES (?, ?, ?, ?, ?) '
    'ON CONFLICT (entity_type, entity_id) DO UPDATE SET '
    'op_id = excluded.op_id, op = excluded.op',
    [
      _uuid.v4(),
      entityType,
      entityId,
      op,
      now.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
    ],
  );

  /// One row read from the three tables, re-read whenever any changes.
  Stream<SyncStatus> watchStatus() => _db
      .customSelect(
        'SELECT '
        "(SELECT value FROM sync_state WHERE name = '$syncLastSuccessAtKey') "
        'AS last_success_at, '
        "(SELECT value FROM sync_state WHERE name = '$syncLastFailureAtKey') "
        'AS last_failure_at, '
        "(SELECT value FROM sync_state WHERE name = '$syncLastFailureKindKey') "
        'AS last_failure_kind, '
        '(SELECT COUNT(*) FROM sync_outbox) AS pending_count, '
        '(SELECT MIN(created_at) FROM sync_outbox) AS oldest_pending_at, '
        '(SELECT COUNT(*) FROM sync_rejection) AS rejected_count',
        readsFrom: {_db.syncState, _db.syncOutbox, _db.syncRejection},
      )
      .watchSingle()
      .map(_statusOf);

  static SyncStatus _statusOf(QueryRow row) {
    final success = _fromMillis(row.readNullable<String>('last_success_at'));
    final failureAt = _fromMillis(row.readNullable<String>('last_failure_at'));
    final kind = SyncFailureKind.parse(
      row.readNullable<String>('last_failure_kind'),
    );
    // Inline, so failureAt and kind are promoted to non-null.
    final lastFailure =
        failureAt != null &&
            kind != null &&
            (success == null || failureAt.isAfter(success))
        ? LastSyncFailure(kind, failureAt)
        : null;
    final oldest = row.readNullable<int>('oldest_pending_at');
    return SyncStatus(
      lastSuccessAt: success,
      lastFailure: lastFailure,
      pendingCount: row.read<int>('pending_count'),
      oldestPendingAt: oldest == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              oldest * Duration.millisecondsPerSecond,
              isUtc: true,
            ),
      rejectedCount: row.read<int>('rejected_count'),
    );
  }

  static String _millis(DateTime at) => '${at.toUtc().millisecondsSinceEpoch}';

  static DateTime? _fromMillis(String? value) {
    final millis = value == null ? null : int.tryParse(value);
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  Stream<void> outboxChanges() =>
      _db.select(_db.syncOutbox).watch().map((_) {});

  Future<String?> _value(String key) async => (await (_db.select(
    _db.syncState,
  )..where((s) => s.name.equals(key))).getSingleOrNull())?.value;

  Future<void> _put(String key, String value) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(name: key, value: value),
      );
}
