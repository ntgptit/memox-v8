import 'dart:convert';

import 'package:memox/core/database/app_database.dart' show SyncOutboxEntry;
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

  /// The code of a refused row whose server copy this device could not
  /// hold (DEV-183): it stays as it is, listed on screen 27, until a pull
  /// brings a copy that applies or the person decides (sync status spec R3,
  /// R7).
  static const localApplyFailed = 'LOCAL_APPLY_FAILED';

  /// The code of a pulled change this device could not hold (DEV-185): the
  /// row stays as it is, listed on screen 27; Try again sends nothing for
  /// it, and the next pull of the row that applies clears it.
  static const pullApplyFailed = 'PULL_APPLY_FAILED';

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
      // Nothing of this device's to send: the server's copy is what could
      // not be held, and only a pull of it can settle that (DEV-185).
      if (rejection.code == pullApplyFailed) continue;
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
        // An upsert sends the row as it is now, or goes as a delete once
        // the row is gone; a delete sends what the trigger kept for the
        // server (the purged batch and the acknowledged version, spec §4.1).
        final current = entry.op == _upsert
            ? await _adapters[entry.entityType]!.readRow(entry.entityId)
            : null;
        final isDelete = entry.op == _delete || current == null;
        operations.add(
          SyncOperationModel(
            opId: entry.opId,
            entityType: entry.entityType,
            entityId: entry.entityId,
            op: isDelete ? _delete : _upsert,
            row: isDelete ? _payloadOf(entry) : current,
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
            await _applyRefusedCopy(adapter, entry, result.current!);
          }
          await _store.removeIfUnchanged(result.opId);
        }
      });
      if (batch.length < pushBatchSize) {
        return pushed;
      }
    }
  }

  /// The server's copy of a refused row, inside a savepoint of its own: a
  /// copy this device cannot hold yet (its parent not pulled, a constraint
  /// the local rows break) fails only this entity. The row stays as it is
  /// and is listed as [localApplyFailed]; the pull that follows brings the
  /// parent and clears the listing once a copy applies (DEV-183).
  Future<void> _applyRefusedCopy(
    EntitySyncAdapter adapter,
    SyncOutboxEntry entry,
    SyncChangeModel copy,
  ) async {
    try {
      await _store.inTransaction(
        () => _applyServerCopy(adapter, entry.entityId, copy),
      );
      await _store.clearRejection(entry.entityType, entry.entityId);
    } catch (error, stackTrace) {
      _log.warning(
        'sync.apply_failed',
        category: LogCategory.sync,
        message:
            '${entry.entityType}/${entry.entityId}: the server copy cannot '
            'be applied here yet',
        error: error,
        stackTrace: stackTrace,
        context: {
          'entityType': entry.entityType,
          'entityId': entry.entityId,
          'serverVersion': copy.serverVersion,
        },
      );
      await _store.recordRejection(
        entry.entityType,
        entry.entityId,
        localApplyFailed,
        _now(),
      );
    }
  }

  /// One transaction, open before the first page: each page is applied as
  /// it arrives, so the pull holds one page at a time (DEV-206), and keys
  /// are checked at commit, so a child may come pages before its parent
  /// (spec §4.2). A set of adapters other than the last pull's starts from
  /// 0, so a type this build adds gets the rows the server already holds
  /// (spec §4.1). The number of changes fetched.
  Future<int> _pull() async {
    final types = (_adapters.keys.toList()..sort()).join(',');
    var since = await _store.pullEntityTypes() == types
        ? await _store.since()
        : 0;
    var fetched = 0;
    var applied = 0;
    await _store.applyingRemote(deferForeignKeys: true, () async {
      // A row listed as refused is cleared once the server's copy of it
      // applies here (DEV-183); read once, so a pull with nothing listed
      // costs nothing more.
      final listed = {
        for (final r in await _store.rejections())
          '${r.entityType}/${r.entityId}',
      };
      while (true) {
        final page = await _api.changes(since, _pullLimit);
        fetched += page.changes.length;
        for (final change in page.changes) {
          final adapter = _adapters[change.entityType];
          // Asked per change: a tag merge earlier in this pull may have
          // queued a card that a later change would overwrite (tag sync
          // plan R7).
          if (adapter == null ||
              await _store.isPendingEntity(
                change.entityType,
                change.entityId,
              )) {
            continue;
          }
          if (!await _applyPulledChange(adapter, change)) {
            continue;
          }
          applied++;
          if (listed.contains('${change.entityType}/${change.entityId}')) {
            await _store.clearRejection(change.entityType, change.entityId);
          }
        }
        since = page.nextSince;
        if (!page.hasMore) {
          break;
        }
      }
      // Nothing applied, nothing to finish: the common pull after a local
      // write has no page to scan the library for (DEV-210).
      if (applied > 0) {
        for (final adapter in _adapters.values) {
          await adapter.afterPull();
        }
        await _logForeignKeyViolations();
      }
      await _store.setSince(since);
      await _store.setPullEntityTypes(types);
    });
    return fetched;
  }

  /// A pulled change inside a savepoint of its own: one this device cannot
  /// hold (a constraint the server does not mirror) fails alone, listed as
  /// [pullApplyFailed], and the pull goes on (DEV-185). True when applied.
  Future<bool> _applyPulledChange(
    EntitySyncAdapter adapter,
    SyncChangeModel change,
  ) async {
    try {
      await _store.inTransaction(
        () => _applyServerCopy(adapter, change.entityId, change),
      );
      return true;
    } catch (error, stackTrace) {
      _log.warning(
        'sync.pull_apply_failed',
        category: LogCategory.sync,
        message:
            '${change.entityType}/${change.entityId}: the change cannot be '
            'applied here',
        error: error,
        stackTrace: stackTrace,
        context: {
          'entityType': change.entityType,
          'entityId': change.entityId,
          'serverVersion': change.serverVersion,
        },
      );
      await _store.recordRejection(
        change.entityType,
        change.entityId,
        pullApplyFailed,
        _now(),
      );
      return false;
    }
  }

  /// Keys are checked at commit (spec §4.2); a violation there rolls the
  /// pull back with an error that names no row, so the rows are logged
  /// first (DEV-185).
  Future<void> _logForeignKeyViolations() async {
    final violations = await _store.foreignKeyViolations();
    if (violations.isEmpty) return;
    _log.warning(
      'sync.pull_foreign_keys',
      category: LogCategory.sync,
      message: 'the pull leaves rows whose parent is missing; it rolls back',
      context: {
        'count': violations.length,
        'violations': violations.take(10).toList(),
      },
    );
  }

  static Map<String, Object?>? _payloadOf(SyncOutboxEntry entry) {
    final payload = entry.payload;
    if (payload == null) {
      return null;
    }
    return jsonDecode(payload) as Map<String, Object?>;
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
