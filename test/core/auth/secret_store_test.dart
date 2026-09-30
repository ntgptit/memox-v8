import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/secret_store.dart';

import '../../support/fake_secret_store.dart';

void main() {
  test(
    "the purge keeps the current op's secrets and other apps' keys",
    () async {
      final secrets = FakeSecretStore()
        ..values.addAll({
          backupSecretKey('old'): 'r1',
          claimSecretKey('old'): 'c1',
          backupSecretKey('now'): 'r2',
          claimSecretKey('now'): 'c2',
          'other.key': 'x',
        });

      await purgeAccountSecrets(secrets, keepOpId: 'now');

      expect(secrets.values.keys.toSet(), {
        backupSecretKey('now'),
        claimSecretKey('now'),
        'other.key',
      });
    },
  );

  test('with no current op every account secret goes', () async {
    final secrets = FakeSecretStore()
      ..values.addAll({backupSecretKey('a'): 'r', 'other.key': 'x'});

    await purgeAccountSecrets(secrets);

    expect(secrets.values.keys, ['other.key']);
  });
}
