import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_env.dart';

/// What the server holds, read with the service role (spec 2026-10-05 §6):
/// every row checks the server, not only the device.
class ServerProbe {
  ServerProbe(LocalEnv env)
    : _client = localClient(env, key: env.serviceRoleKey);

  final SupabaseClient _client;

  Future<User?> _user(String id) async {
    try {
      return (await _client.auth.admin.getUserById(id)).user;
    } on AuthException catch (error) {
      if (error.statusCode == '404') return null;
      rethrow;
    }
  }

  Future<bool> userExists(String id) async => await _user(id) != null;

  Future<String?> emailOf(String id) async => (await _user(id))?.email;

  /// The live decks of [userId]: neither tombstoned nor in the trash.
  Future<Set<String>> deckNames(String userId) async {
    final rows = await _deckRows(userId);
    return {for (final row in rows) row['name']! as String};
  }

  /// The same rows as a list, so a duplicate shows.
  Future<List<String>> deckNameList(String userId) async => [
    for (final row in await _deckRows(userId)) row['name']! as String,
  ];

  Future<List<Map<String, dynamic>>> _deckRows(String userId) => _client
      .from('deck')
      .select('name')
      .eq('user_id', userId)
      .isFilter('deleted_at', null)
      .isFilter('delete_batch_id', null);

  Future<void> makeAdmin(String userId) =>
      _client.from('profiles').update({'role': 'admin'}).eq('id', userId);

  /// [userId] becomes the local stack's one admin: earlier runs leave admins
  /// behind, and D10 needs the last one.
  Future<void> onlyAdmin(String userId) async {
    await _client
        .from('profiles')
        .update({'role': 'user'})
        .eq('role', 'admin')
        .neq('id', userId);
    await makeAdmin(userId);
  }

  /// Revokes every session of the token's user (D8).
  Future<void> signOutEverywhere(String accessToken) =>
      _client.auth.admin.signOut(accessToken, scope: SignOutScope.global);

  void close() => _client.dispose();
}
