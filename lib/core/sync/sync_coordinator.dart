import 'dart:developer';

import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:memox/core/sync/sync_store.dart';

/// One sync run: push the outbox, then pull the server's changes (app
/// deck-sync spec §5).
class SyncCoordinator {
  SyncCoordinator({
    required this._api,
    required this._store,
    required List<EntitySyncAdapter> adapters,
    this._now = DateTime.now,
  }) : _adapters = {for (final a in adapters) a.entityType: a};

  static const pushBatchSize = 100;
  static const pullPageSize = 500;
  static const _upsert = 'upsert';
  static const _delete = 'delete';

  final SyncApi _api;
  final SyncStore _store;
  final Map<String, EntitySyncAdapter> _adapters;
  final DateTime Function() _now;

  Future<void> runOnce() async {
    final deviceId = await _store.deviceId();
    await _push(deviceId);
    await _pull();
  }

  /// Try again (sync status spec §4): each refused entity goes back to the
  /// outbox, as an upsert while it exists locally and as a delete once it
  /// is gone. The records stay until the next push answers.
  Future<void> requeueRejected() => _store.inTransaction(() async {
    for (final rejection in await _store.rejections()) {
      final adapter = _adapters[rejection.entityType];
      if (adapter == null) continue;
      final exists = await adapter.readRow(rejection.entityId) != null;
      await _store.enqueue(
        rejection.entityType,
        rejection.entityId,
        exists ? _upsert : _delete,
        _now(),
      );
    }
  });

  Future<void> _push(String deviceId) async {
    while (true) {
      final batch = await _store.pendingBatch(
        _adapters.keys.toSet(),
        pushBatchSize,
      );
      if (batch.isEmpty) {
        return;
      }
      final operations = <SyncOperationModel>[];
      for (final entry in batch) {
        final row = entry.op == _upsert
            ? await _adapters[entry.entityType]!.readRow(entry.entityId)
            : null;
        operations.add(
          SyncOperationModel(
            opId: entry.opId,
            entityType: entry.entityType,
            entityId: entry.entityId,
            op: row == null ? _delete : _upsert,
            row: row,
          ),
        );
      }
      final PushResponseModel response;
      try {
        response = await _api.push(
          PushRequestModel(deviceId: deviceId, operations: operations),
        );
      } catch (_) {
        await _store.recordFailedAttempt(batch.map((e) => e.opId));
        rethrow;
      }
      final sent = {for (final e in batch) e.opId: e};
      await _store.applyingRemote(() async {
        for (final result in response.results) {
          final entry = sent[result.opId];
          // A later local write replaced this op id: the newer state is
          // pending, so neither the ack nor the server copy may touch it.
          if (entry == null || !await _store.isPending(result.opId)) {
            continue;
          }
          final adapter = _adapters[entry.entityType]!;
          if (result.isApplied) {
            await adapter.markAcknowledged(
              entry.entityId,
              result.serverVersion!,
            );
            await _store.clearRejection(entry.entityType, entry.entityId);
          } else if (result.current == null) {
            // The server never saw this row: keep it (and its cards) rather
            // than delete data that exists nowhere else, and list it on
            // screen 27 (sync status spec §4).
            log(
              'Sync rejected ${entry.entityType}/${entry.entityId}: ${result.code}',
            );
            await _store.recordRejection(
              entry.entityType,
              entry.entityId,
              result.code ?? 'UNKNOWN',
              _now(),
            );
          } else {
            await _applyServerCopy(adapter, entry.entityId, result.current);
          }
          await _store.removeIfUnchanged(result.opId);
        }
      });
      if (batch.length < pushBatchSize) {
        return;
      }
    }
  }

  Future<void> _pull() async {
    var since = await _store.since();
    while (true) {
      final page = await _api.changes(since, pullPageSize);
      await _store.applyingRemote(deferForeignKeys: true, () async {
        final pending = await _store.pendingKeys();
        for (final change in page.changes) {
          final adapter = _adapters[change.entityType];
          if (adapter == null ||
              pending.contains('${change.entityType}/${change.entityId}')) {
            continue;
          }
          await _applyServerCopy(adapter, change.entityId, change);
        }
        await _store.setSince(page.nextSince);
      });
      since = page.nextSince;
      if (!page.hasMore) {
        return;
      }
    }
  }

  static Future<void> _applyServerCopy(
    EntitySyncAdapter adapter,
    String entityId,
    SyncChangeModel? copy,
  ) {
    if (copy == null || copy.isDeleted) {
      return adapter.deleteFromServer(entityId);
    }
    return adapter.upsertFromServer(copy.row!, copy.serverVersion);
  }
}
