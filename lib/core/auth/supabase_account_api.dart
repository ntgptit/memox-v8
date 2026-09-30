import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/network/supabase_client.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AccountApi] over Supabase RPC. Its errors leave through
/// [classifyAuthError].
class SupabaseAccountApi implements AccountApi {
  SupabaseAccountApi({required this._rpc, required this._refreshSession});

  /// On the client main.dart initialized.
  factory SupabaseAccountApi.instance() => SupabaseAccountApi(
    rpc: supabaseRpc,
    refreshSession: () async {
      await Supabase.instance.client.auth.refreshSession();
    },
  );

  final RpcCall _rpc;
  final Future<void> Function() _refreshSession;

  @override
  Future<AccountUser> me() async {
    final json = (await _call('me', const {}))! as Map<String, Object?>;
    return AccountUser(
      id: json['id']! as String,
      email: json['email'] as String?,
      isAnonymous: json['isAnonymous'] == true,
      role: AccountRole.parse(json['role'] as String?),
    );
  }

  @override
  Future<String> claimBegin() async =>
      (await _call('account_claim_begin', const {}))! as String;

  @override
  Future<void> merge(String token, String operationId) =>
      _call('account_merge', {'p_token': token, 'p_operation_id': operationId});

  @override
  Future<void> mergeAck(String operationId) =>
      _call('account_merge_ack', {'p_operation_id': operationId});

  @override
  Future<void> deleteAccount() => _call('account_delete', const {});

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    try {
      return await _callRefreshingOnce(function, params);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(classifyAuthError(error), stackTrace);
    }
  }

  Future<Object?> _callRefreshingOnce(
    String function,
    Map<String, Object?> params,
  ) async {
    try {
      return await _rpc(function, params);
    } on Object catch (error) {
      if (!isExpiredJwt(error)) rethrow;
      await _refreshSession();
      return _rpc(function, params);
    }
  }
}
