/// Where the account keeps its short-lived secrets (auth spec §4, O13): A's
/// refresh-token backup and the claim token, one pair per operation. Never
/// Drift, never a log.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<Set<String>> keys();
}

const _prefix = 'account.';

/// A's refresh token, kept while switching to B (#20, ruling 4).
String backupSecretKey(String opId) => '${_prefix}backup.$opId';

/// The one-time token that lets B claim A's data (#20).
String claimSecretKey(String opId) => '${_prefix}claim.$opId';

/// At start: every account secret that is not [keepOpId]'s goes (auth spec
/// §4). Keys of anything else are left alone.
Future<void> purgeAccountSecrets(
  SecretStore secrets, {
  String? keepOpId,
}) async {
  for (final key in await secrets.keys()) {
    if (!key.startsWith(_prefix)) continue;
    if (keepOpId != null && key.endsWith('.$keepOpId')) continue;
    await secrets.delete(key);
  }
}
