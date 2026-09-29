import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// The admin RPCs of `public.app_log` (ADR-018 §7): `log_query`, `log_get`
/// and `log_set_status`, on the session sync already holds. It never signs
/// in: a caller with no session is not an admin.
final class MonitoringRemoteDataSource {
  MonitoringRemoteDataSource({required this._rpc, required this._hasSession});

  final RpcCall _rpc;
  final bool Function() _hasSession;

  static const _notFound = 'NOT_FOUND';

  /// The compact rows of one page, newest first.
  Future<List<Map<String, Object?>>> query(Map<String, Object?> filter) async {
    final json = await _call('log_query', {'filter': filter});
    return [
      for (final item in (json! as Map<String, Object?>)['items']! as List)
        item! as Map<String, Object?>,
    ];
  }

  /// One row whole, or null when it is gone.
  Future<Map<String, Object?>?> get(String id) =>
      _row('log_get', {'log_id': id});

  /// The row as the server now holds it, or null when it is gone.
  Future<Map<String, Object?>?> setStatus(
    String id,
    String status,
    String? note,
  ) => _row('log_set_status', {
    'log_id': id,
    'new_status': status,
    'note': note,
  });

  Future<Map<String, Object?>?> _row(
    String function,
    Map<String, Object?> params,
  ) async {
    try {
      final json = await _call(function, params);
      return json! as Map<String, Object?>;
    } on PostgrestException catch (error) {
      if (error.message == _notFound) return null;
      rethrow;
    }
  }

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    if (!_hasSession()) throw const MonitoringSessionMissing();
    return _rpc(function, params);
  }
}

/// A Monitoring call with no session behind it: the caller cannot be an
/// admin, so the server is not asked.
final class MonitoringSessionMissing implements Exception {
  const MonitoringSessionMissing();

  @override
  String toString() => 'MonitoringSessionMissing: no session';
}
