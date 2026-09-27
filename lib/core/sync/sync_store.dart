import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
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
