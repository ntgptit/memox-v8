import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:memox/core/auth/secret_store.dart';

/// [SecretStore] on the platform's secure storage (auth spec O13). The one
/// file that imports `flutter_secure_storage` (plan ruling 18).
class SecureSecretStore implements SecretStore {
  SecureSecretStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Set<String>> keys() async => (await _storage.readAll()).keys.toSet();
}
