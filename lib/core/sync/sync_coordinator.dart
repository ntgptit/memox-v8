import 'package:memox/core/logging/app_logger.dart';
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
    this._pullLimit = pullPageSize,
    this._logger,
  }) : _adapters = {for (final a in adapters) a.entityType: a};

  static const pushBatchSize = 100;
  static const pullPageSize = 500;
  static const _upsert = 'upsert';
  static const _delete = 'delete';

  final SyncApi _api;
  final SyncStore _store;
  final Map<String, EntitySyncAdapter> _adapters;
  final DateTime Function() _now;
  final int _pullLimit;
  final AppLogger? _logger;

  AppLogger get _log => _logger ?? appLogger;

  Future<void> runOnce() async {
    final deviceId = await _store.deviceId();
    final watch = Stopwatch()..start();
    final pushed = await _push(deviceId);
    _log.info(
      'sync.push',
      category: LogCategory.sync,
      context: {'operations': pushed, 'duration_ms': watch.elapsedMilliseconds},
    );
    watch.reset();
    final pulled = await _pull();
    _log.info(
      'sync.pull',
      category: LogCategory.sync,
      context: {'changes': pulled, 'duration_ms': watch.elapsedMilliseconds},
    );
  }

  /// Pushes until the outbox is empty (auth spec #19, #39).
  Future<void> pushAll() async {
    await _push(await _store.deviceId());
  }

  /// The account's whole library, from version 0 (auth spec #28).
  Future<void> pullAll() async {
    await _store.setSince(0);
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

  /// The number of operations sent.
  Future<int> _push(String deviceId) async {
    var pushed = 0;
    while (true) {
      final batch = await _store.pendingBatch(
        _adapters.keys.toList(),
        pushBatchSize,
      );
      if (batch.isEmpty) {
        return pushed;
      }
      pushed += batch.length;
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
            _log.warning(
              'sync.rejected',
              category: LogCategory.sync,
              message:
                  '${entry.entityType}/${entry.entityId} refused: '
                  '${result.code}',
              context: {
                'entityType': entry.entityType,
                'entityId': entry.entityId,
                'code': result.code,
                'opId': result.opId,
              },
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
        return pushed;
      }
    }
  }

  /// Every page is fetched first, then applied in one transaction with keys
  /// checked at commit: a child may come pages before its parent (spec §4.2).
  /// A set of adapters other than the last pull's starts from 0, so a type
  /// this build adds gets the rows the server already holds (spec §4.1).
  /// The number of changes fetched.
  Future<int> _pull() async {
    final types = (_adapters.keys.toList()..sort()).join(',');
    var since = await _store.pullEntityTypes() == types
        ? await _store.since()
        : 0;
    final changes = <SyncChangeModel>[];
    while (true) {
      final page = await _api.changes(since, _pullLimit);
      changes.addAll(page.changes);
      since = page.nextSince;
      if (!page.hasMore) {
        break;
      }
    }
    await _store.applyingRemote(deferForeignKeys: true, () async {
      for (final change in changes) {
        final adapter = _adapters[change.entityType];
        // Asked per change: a tag merge earlier in this pull may have queued
        // a card that a later change would overwrite (tag sync plan R7).
        if (adapter == null ||
            await _store.isPendingEntity(change.entityType, change.entityId)) {
          continue;
        }
        await _applyServerCopy(adapter, change.entityId, change);
      }
      for (final adapter in _adapters.values) {
        await adapter.afterPull();
      }
      await _store.setSince(since);
      await _store.setPullEntityTypes(types);
    });
    return changes.length;
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
