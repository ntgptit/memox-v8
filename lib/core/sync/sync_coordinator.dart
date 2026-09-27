import 'dart:convert';
import 'dart:developer';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:memox/core/sync/sync_outbox.dart';
import 'package:memox/core/sync/sync_store.dart';

/// One sync run: push the outbox, then pull the server's changes (BE-E7 spec
/// §5).
class SyncCoordinator {
  SyncCoordinator({
    required this._api,
    required this._store,
    required List<EntitySyncAdapter> adapters,
    this.pullPageSize = 500,
  }) : _adapters = {for (final a in adapters) a.entityType: a};

  static const pushBatchSize = 100;

  /// The one code that makes an absent entity a local delete (spec D4).
  static const parentMissing = 'DECK_PARENT_MISSING';

  final int pullPageSize;
  final SyncApi _api;
  final SyncStore _store;
  final Map<String, EntitySyncAdapter> _adapters;

  Future<void> runOnce() async {
    final deviceId = await _store.deviceId();
    await push(deviceId);
    await pull();
  }

  Future<void> push(String deviceId) async {
    while (true) {
      final batch = await _store.pendingBatch(pushBatchSize);
      if (batch.isEmpty) {
        return;
      }
      final operations = <SyncOperationModel>[];
      for (final entry in batch) {
        final operation = await _operationOf(entry);
        if (operation == null) {
          // A patch whose entity is gone: nothing to send.
          await _store.remove(entry.opId);
          continue;
        }
        operations.add(operation);
      }
      if (operations.isNotEmpty) {
        await _send(deviceId, operations);
      }
      if (batch.length < pushBatchSize) {
        return;
      }
    }
  }

  Future<void> _send(
    String deviceId,
    List<SyncOperationModel> operations,
  ) async {
    final PushResponseModel response;
    try {
      response = await _api.push(
        PushRequestModel(deviceId: deviceId, operations: operations),
      );
    } catch (_) {
      await _store.recordFailedAttempt(operations.map((o) => o.opId));
      rethrow;
    }
    await _store.applyingServer(() async {
      for (final result in response.results) {
        if (!result.isApplied) {
          log('Sync rejected operation ${result.opId}: ${result.code}');
          for (final copy in result.current ?? const <SyncChangeModel>[]) {
            await _applyRejectedCopy(copy, result.code);
          }
        }
        await _store.remove(result.opId);
      }
    });
  }

  /// Every page first, then one transaction: the cursor moves only when all
  /// of them are in (spec §5).
  Future<void> pull() async {
    final since = await _store.since();
    final changes = <SyncChangeModel>[];
    var cursor = since;
    while (true) {
      final page = await _api.changes(cursor, pullPageSize);
      changes.addAll(page.changes);
      cursor = page.nextSince;
      if (!page.hasMore) {
        break;
      }
    }
    await _store.applyingServer(() async {
      final pending = await _store.pendingEntities();
      for (final change in changes) {
        final adapter = _adapters[change.entityType];
        if (adapter == null ||
            pending.contains(
              SyncEntityRef(change.entityType, change.entityId),
            )) {
          continue;
        }
        await _applyServerCopy(adapter, change);
      }
      await _store.setSince(cursor);
    });
  }

  Future<SyncOperationModel?> _operationOf(SyncOutboxEntry entry) async {
    final affected = [
      for (final item in jsonDecode(entry.affected) as List)
        item as Map<String, Object?>,
    ];
    if (entry.kind == SyncKind.command) {
      return SyncOperationModel(
        opId: entry.opId,
        kind: SyncKind.command,
        type: entry.commandType,
        payload: jsonDecode(entry.payload!) as Map<String, Object?>,
        affected: affected,
      );
    }
    final fields = await _adapters[entry.entityType]?.readPatch(
      entry.entityId!,
      entry.patchGroup!,
    );
    if (fields == null) {
      return null;
    }
    return SyncOperationModel(
      opId: entry.opId,
      kind: SyncKind.patch,
      entityType: entry.entityType,
      entityId: entry.entityId,
      group: entry.patchGroup,
      fields: fields,
      affected: affected,
    );
  }

  Future<void> _applyRejectedCopy(SyncChangeModel copy, String? code) async {
    final adapter = _adapters[copy.entityType];
    if (adapter == null) {
      return;
    }
    if (copy.isAbsent && code != parentMissing) {
      // A bug or a legacy row: keep what exists nowhere else (spec D4).
      log('Sync kept ${copy.entityType}/${copy.entityId} after $code');
      return;
    }
    await _applyServerCopy(adapter, copy);
  }

  static Future<void> _applyServerCopy(
    EntitySyncAdapter adapter,
    SyncChangeModel copy,
  ) {
    if (copy.isDeleted || copy.row == null) {
      return adapter.deleteFromServer(copy.entityId);
    }
    return adapter.upsertFromServer(copy.row!, copy.serverVersion);
  }
}
