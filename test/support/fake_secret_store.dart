import 'package:memox/core/auth/secret_store.dart';

/// Secure Storage in memory. [onCall] runs before every call, so a crash test
/// can stop the flow at any step.
class FakeSecretStore implements SecretStore {
  final values = <String, String>{};
  void Function()? onCall;

  @override
  Future<String?> read(String key) async {
    onCall?.call();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    onCall?.call();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    onCall?.call();
    values.remove(key);
  }

  @override
  Future<Set<String>> keys() async => values.keys.toSet();
}
