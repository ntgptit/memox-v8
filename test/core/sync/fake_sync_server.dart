import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';

/// An in-memory server with the wire semantics the coordinator relies on:
/// idempotent op ids, one version per write, tombstones, rejections by rule.
class FakeSyncServer implements SyncApi {
  final _rows = <String, SyncChangeModel>{};
  final _applied = <String, int>{};
  var _version = 0;
  var pushCalls = 0;

  /// Entity keys (`type/id`) whose next upsert is rejected with this code.
  final rejectNext = <String, String>{};

  /// Runs inside push, after the request is read: simulates an edit made on
  /// the device while the request is in flight.
  Future<void> Function()? duringPush;

  SyncChangeModel? row(String type, String id) => _rows['$type/$id'];

  void seed(String type, String id, Map<String, Object?>? row) {
    _version++;
    _rows['$type/$id'] = SyncChangeModel(
      entityType: type,
      entityId: id,
      serverVersion: _version,
      isDeleted: row == null,
      row: row,
    );
  }

  @override
  Future<PushResponseModel> push(PushRequestModel request) async {
    pushCalls++;
    await duringPush?.call();
    final results = <OperationResultModel>[];
    for (final op in request.operations) {
      final key = '${op.entityType}/${op.entityId}';
      final already = _applied[op.opId];
      if (already != null) {
        results.add(_applied_(op.opId, already));
        continue;
      }
      final rejection = rejectNext.remove(key);
      if (rejection != null) {
        results.add(
          OperationResultModel(
            opId: op.opId,
            status: 'rejected',
            serverVersion: null,
            code: rejection,
            current: _rows[key],
          ),
        );
        continue;
      }
      seed(op.entityType, op.entityId, op.op == 'delete' ? null : op.row);
      _applied[op.opId] = _version;
      results.add(_applied_(op.opId, _version));
    }
    return PushResponseModel(results: results);
  }

  @override
  Future<ChangesResponseModel> changes(int since, int limit) async {
    final sorted = _rows.values.where((c) => c.serverVersion > since).toList()
      ..sort((a, b) => a.serverVersion.compareTo(b.serverVersion));
    final page = sorted.take(limit).toList();
    return ChangesResponseModel(
      changes: page,
      nextSince: page.isEmpty ? since : page.last.serverVersion,
      hasMore: sorted.length > limit,
    );
  }

  static OperationResultModel _applied_(String opId, int version) =>
      OperationResultModel(
        opId: opId,
        status: 'applied',
        serverVersion: version,
        code: null,
        current: null,
      );
}
