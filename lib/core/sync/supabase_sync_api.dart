import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';

/// Calls a Postgres function through Supabase and returns its decoded JSON.
typedef RpcCall = Future<Object?> Function(
  String function,
  Map<String, Object?> params,
);

/// Makes sure the client holds a session before a call (anonymous sign-in).
typedef SessionGuard = Future<void> Function();

/// [SyncApi] over the Supabase RPCs `sync_push` and `sync_changes`
/// (ADR-015). Errors propagate: the scheduler backs off on any failure.
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi({required this._ensureSession, required this._rpc});

  final SessionGuard _ensureSession;
  final RpcCall _rpc;

  @override
  Future<PushResponseModel> push(PushRequestModel request) async {
    await _ensureSession();
    final json = await _rpc('sync_push', {'request': request.toJson()});
    return PushResponseModel.fromJson(json! as Map<String, Object?>);
  }

  @override
  Future<ChangesResponseModel> changes(int since, int limit) async {
    await _ensureSession();
    final json = await _rpc('sync_changes', {
      'since': since,
      'max_rows': limit,
    });
    return ChangesResponseModel.fromJson(json! as Map<String, Object?>);
  }
}

/// A sync call with no session: the account has not signed in yet (auth
/// spec R2). Sync runs only once the account is confirmed, so this is a
/// bug, not a state.
final class SyncSessionMissing implements Exception {
  const SyncSessionMissing();

  @override
  String toString() => 'SyncSessionMissing: no session to sync with';
}
