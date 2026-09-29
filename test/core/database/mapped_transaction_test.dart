import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/test_database.dart';

// Spec 2026-09-29-database-error-guard-design.md D2: the Future twin of a
// transaction whose error leaves as its Failure, after the rollback. A temp
// table keeps the test off the app schema.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = openTestDatabase();
    await db.customStatement('CREATE TEMP TABLE probe (x INTEGER)');
  });
  tearDown(() => db.close());

  Future<int> rows() async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM probe').getSingle())
          .read<int>('n');

  Future<void> insert() => db.customInsert('INSERT INTO probe VALUES (1)');

  test('a success commits and returns the value', () async {
    expect(
      await db.mappedTransaction(() async {
        await insert();
        return 'done';
      }),
      'done',
    );
    expect(await rows(), 1);
  });

  test('a throw rolls every write back and leaves as a Failure', () async {
    await expectLater(
      db.mappedTransaction(() async {
        await insert();
        throw StateError('boom');
      }),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(await rows(), 0);
  });
}
