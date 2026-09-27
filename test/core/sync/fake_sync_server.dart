import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';

/// A scripted server: it records what is pushed, answers `applied` unless a
/// rejection is scripted for the operation's command type or patch group, and
/// serves a feed the test publishes.
class FakeSyncServer implements SyncApi {
  final pushed = <SyncOperationModel>[];
  final feed = <SyncChangeModel>[];
  var _version = 0;

  /// The next operation of this key (a command type, or `entityType/group`)
  /// is rejected with this code and these copies.
  final rejectNext = <String, (String, List<SyncChangeModel>)>{};

  /// The changes call with this index (0-based) throws.
  int? failChangesCall;
  var _changesCalls = 0;

  void publish(String type, String id, Map<String, Object?>? row) {
    _version++;
    feed.add(
      SyncChangeModel(
        entityType: type,
        entityId: id,
        serverVersion: _version,
        isDeleted: row == null,
        row: row,
      ),
    );
  }

  @override
  Future<PushResponseModel> push(PushRequestModel request) async {
    final results = <OperationResultModel>[];
    for (final op in request.operations) {
      pushed.add(op);
      final key = op.kind == 'command'
          ? op.type!
          : '${op.entityType}/${op.group}';
      final rejection = rejectNext.remove(key);
      results.add(
        rejection == null
            ? OperationResultModel(
                opId: op.opId,
                status: 'applied',
                serverVersion: ++_version,
                code: null,
                current: null,
              )
            : OperationResultModel(
                opId: op.opId,
                status: 'rejected',
                serverVersion: null,
                code: rejection.$1,
                current: rejection.$2,
              ),
      );
    }
    return PushResponseModel(results: results);
  }

  @override
  Future<ChangesResponseModel> changes(int since, int limit) async {
    if (_changesCalls++ == failChangesCall) {
      throw StateError('network down');
    }
    final after = feed.where((c) => c.serverVersion > since).toList();
    final page = after.take(limit).toList();
    return ChangesResponseModel(
      changes: page,
      nextSince: page.isEmpty ? since : page.last.serverVersion,
      hasMore: after.length > limit,
    );
  }
}
