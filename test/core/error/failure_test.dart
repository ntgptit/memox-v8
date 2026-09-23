import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('a CHECK/foreign key violation maps to ConstraintFailure', () {
    final failure = mapDatabaseError(
      sqlite3.SqliteException(
        extendedResultCode: 275,
        message: 'CHECK constraint failed: depth',
      ),
    );
    expect(failure, isA<ConstraintFailure>());
    expect(failure.cause, isNotNull);
  });

  test('SQLITE_BUSY maps to DatabaseLockedFailure', () {
    final failure = mapDatabaseError(
      sqlite3.SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      ),
    );
    expect(failure, isA<DatabaseLockedFailure>());
  });

  test(
    'anything else maps to UnknownDatabaseFailure and never leaks card content',
    () {
      final failure = mapDatabaseError(StateError('front: "私の秘密"'));
      expect(failure, isA<UnknownDatabaseFailure>());
      expect(failure.message, isNot(contains('私の秘密')));
    },
  );

  test('a Failure already mapped stays as it is', () {
    const failure = ConstraintFailure(cause: 'x');
    expect(mapDatabaseError(failure), same(failure));
  });
}
