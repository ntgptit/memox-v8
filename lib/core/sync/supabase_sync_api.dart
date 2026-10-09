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
/// Each RPC is bounded by [timeout]: a request the network never answers
/// fails as a `TimeoutException`, a network failure, so a run cannot hang
/// the scheduler and the `pause()` of an account transition (DEV-186).
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi({
    required SessionGuard ensureSession,
    required RpcCall rpc,
    Duration timeout = rpcTimeout,
  }) : _ensureSession = ensureSession,
       _rpc = rpc,
       _timeout = timeout;

  /// Long enough for a push of one batch or a pull of one page on a slow
  /// link (app deck-sync spec §5).
  static const rpcTimeout = Duration(seconds: 30);

  final SessionGuard _ensureSession;
  final RpcCall _rpc;
  final Duration _timeout;

  @override
  Future<PushResponseModel> push(PushRequestModel request) async {
    await _ensureSession();
    final json = await _call('sync_push', {'request': request.toJson()});
    return PushResponseModel.fromJson(json! as Map<String, Object?>);
  }

  @override
  Future<ChangesResponseModel> changes(int since, int limit) async {
    await _ensureSession();
    final json = await _call('sync_changes', {
      'since': since,
      'max_rows': limit,
    });
    return ChangesResponseModel.fromJson(json! as Map<String, Object?>);
  }

  Future<Object?> _call(String function, Map<String, Object?> params) =>
      _rpc(function, params).timeout(_timeout);
}

/// A sync call with no session: the account has not signed in yet (auth
/// spec R2). Sync runs only once the account is confirmed, so this is a
/// bug, not a state.
final class SyncSessionMissing implements Exception {
  const SyncSessionMissing();

  @override
  String toString() => 'SyncSessionMissing: no session to sync with';
}
