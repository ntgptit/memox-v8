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

/// The log push has no session of its own yet: sync signs in.
final class LogSessionMissing implements Exception {
  const LogSessionMissing();

  @override
  String toString() => 'LogSessionMissing: sync has not signed in yet';
}

/// A guard that lets the push go only on a session sync already has. The log
/// never signs in itself: two anonymous sign-ins racing on a first run would
/// leave sync's rows under one user and later ones under another.
SessionGuard existingSessionOnly(bool Function() hasSession) => () async {
  if (!hasSession()) throw const LogSessionMissing();
};
