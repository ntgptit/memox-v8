import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The local Supabase stack tools/supabase/run_auth_it.sh started (spec
/// 2026-10-05 §7). A missing value fails the run by name, never skips it.
class LocalEnv {
  const LocalEnv._({
    required this.apiUrl,
    required this.publishableKey,
    required this.serviceRoleKey,
    required this.mailpitUrl,
  });

  factory LocalEnv.fromMap(Map<String, String> vars) {
    String need(String name) {
      final value = vars[name];
      if (value == null || value.isEmpty) {
        throw StateError('$name is not set: run tools/supabase/run_auth_it.sh');
      }
      return value;
    }

    return LocalEnv._(
      apiUrl: Uri.parse(need('MEMOX_IT_API_URL')),
      publishableKey: need('MEMOX_IT_PUBLISHABLE_KEY'),
      serviceRoleKey: need('MEMOX_IT_SERVICE_ROLE_KEY'),
      mailpitUrl: Uri.parse(need('MEMOX_IT_MAILPIT_URL')),
    );
  }

  factory LocalEnv.read() => LocalEnv.fromMap(Platform.environment);

  final Uri apiUrl;
  final String publishableKey;
  final String serviceRoleKey;
  final Uri mailpitUrl;
}

final _random = Random.secure();

/// An address no earlier run used, so tests share nothing and nothing is
/// cleaned up (spec §4).
String freshEmail() {
  final hex = List.generate(
    12,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  return 'it-$hex@example.com';
}

/// A client on the local stack, with the app's PKCE flow; its storage, like
/// the session's, lives in memory. [key] defaults to the publishable key.
SupabaseClient localClient(
  LocalEnv env, {
  String? key,
  http.Client? httpClient,
}) => SupabaseClient(
  env.apiUrl.toString(),
  key ?? env.publishableKey,
  httpClient: httpClient,
  authOptions: AuthClientOptions(
    autoRefreshToken: false,
    pkceAsyncStorage: _MemoryStorage(),
  ),
);

class _MemoryStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async => _values.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _values[key] = value;
}
