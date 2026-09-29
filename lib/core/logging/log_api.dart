import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';

/// `public.log_push` (ADR-018 §3), on the same session and RPC call as sync.
final class LogApi {
  LogApi({required this._ensureSession, required this._rpc});

  final SessionGuard _ensureSession;
  final RpcCall _rpc;

  /// Sends [entries]; returns the ids the server now holds.
  Future<Set<String>> push(List<LogEntry> entries) async {
    await _ensureSession();
    final json = await _rpc('log_push', {
      'entries': [for (final entry in entries) entry.toJson()],
    });
    final accepted = (json! as Map<String, Object?>)['accepted']! as List;
    return {for (final id in accepted) id! as String};
  }
}
