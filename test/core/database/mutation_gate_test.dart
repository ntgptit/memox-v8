import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

// Auth spec R3 and plan Review Focus 5: while the account changes, a
// business write fails and writes nothing; sync's own path, the account's
// store and the reset still write.
void main() {
  Future<int> tagCount(AppDatabase db) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM tags').getSingle())
          .read<int>('n');

  test('a closed gate refuses a business write and writes nothing', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    db.mutationGate.close();

    await expectLater(
      db.mappedTransaction(
        () => db.customStatement(
          "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
        ),
      ),
      throwsA(isA<MutationBlockedFailure>()),
    );
    expect(await tagCount(db), 0);
    expect(
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
              .getSingle())
          .read<int>('n'),
      0,
    );
  });

  test('an open gate lets the write through', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    db.mutationGate
      ..close()
      ..open();

    await db.mappedTransaction(
      () => db.customStatement(
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
      ),
    );

    expect(await tagCount(db), 1);
  });

  test(
    "sync's own path and the account store write past a closed gate",
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      db.mutationGate.close();

      await SyncStore(db).applyingRemote(
        () => db.customStatement(
          "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
        ),
      );
      await AccountStore(db).saveLastKnown(
        const AccountUser(id: 'u', isAnonymous: true, role: AccountRole.user),
        DateTime.utc(2026, 9, 30),
      );

      expect(await tagCount(db), 1);
      expect(await AccountStore(db).lastKnown(), isNotNull);
    },
  );
}
