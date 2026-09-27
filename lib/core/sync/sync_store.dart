import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_outbox.dart';
import 'package:uuid/uuid.dart';

/// The outbox and sync state in Drift (BE-E7 spec §3, §5).
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

  /// Pending entries in push order.
  Future<List<SyncOutboxEntry>> pendingBatch(int limit) =>
      (_db.select(_db.syncOutbox)
            ..orderBy([(o) => OrderingTerm(expression: o.seq)])
            ..limit(limit))
          .get();

  /// Removes the entry with this op id; a patch recorded again since the push
  /// has a new op id and stays.
  Future<void> remove(String opId) =>
      (_db.delete(_db.syncOutbox)..where((o) => o.opId.equals(opId))).go();

  Future<void> recordFailedAttempt(Iterable<String> opIds) =>
      _db.customStatement(
        'UPDATE sync_outbox SET attempts = attempts + 1 '
        'WHERE op_id IN (${List.filled(opIds.length, '?').join(', ')})',
        opIds.toList(),
      );

  /// Entities a pull must not overwrite yet: every patch target and every id
  /// in a command's `affected` (BE-E7 spec §5).
  Future<Set<SyncEntityRef>> pendingEntities() async {
    final pending = <SyncEntityRef>{};
    for (final entry in await _db.select(_db.syncOutbox).get()) {
      if (entry.kind == SyncKind.patch) {
        pending.add(SyncEntityRef(entry.entityType!, entry.entityId!));
      }
      for (final item in jsonDecode(entry.affected) as List) {
        pending.add(SyncEntityRef.fromJson(item as Map<String, Object?>));
      }
    }
    return pending;
  }

  /// Runs [body] in one transaction for rows that come from the server: a
  /// child may arrive before its parent, so keys are checked at commit, and
  /// the ids these writes change are not a local write's `affected`.
  Future<T> applyingServer<T>(Future<T> Function() body) =>
      _db.transaction(() async {
        await _db.customStatement('PRAGMA defer_foreign_keys = ON');
        try {
          return await body();
        } finally {
          await _db.customStatement('DELETE FROM sync_changed');
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
