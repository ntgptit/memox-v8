import 'package:memox/core/network/remote_error.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';

/// The admin RPCs of roles (auth spec §2): `role_list` and `role_set`, on
/// the session sync already holds. It never signs in: a caller with no
/// session is not an admin (users spec U4).
final class UserRoleRemoteDataSource {
  UserRoleRemoteDataSource({required this._rpc, required this._hasSession});

  final RpcCall _rpc;
  final bool Function() _hasSession;

  static const _notFound = 'NOT_FOUND';

  /// One page: `{items: [...], next}`.
  Future<Map<String, Object?>> list(String query, String? after) async =>
      (await _call('role_list', {'p_query': query, 'p_after': after}))!
          as Map<String, Object?>;

  /// The role the server now holds, or null when the user is gone.
  Future<String?> set(String userId, String role) async {
    try {
      final json =
          (await _call('role_set', {'p_user': userId, 'p_role': role}))!
              as Map<String, Object?>;
      return json['role']! as String;
    } on Object catch (error) {
      if (rpcErrorCode(error) == _notFound) return null;
      rethrow;
    }
  }

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    if (!_hasSession()) throw const UserRoleSessionMissing();
    return _rpc(function, params);
  }
}

/// A role call with no session behind it: the caller cannot be an admin, so
/// the server is not asked.
final class UserRoleSessionMissing implements Exception {
  const UserRoleSessionMissing();

  @override
  String toString() => 'UserRoleSessionMissing: no session';
}
