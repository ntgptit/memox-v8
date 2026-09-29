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

  test('a watch reports a database error as its Failure', () async {
    final watch = Stream<int>.error(
      sqlite3.SqliteException(extendedResultCode: 5, message: 'locked'),
    ).mapDatabaseErrors();

    await expectLater(watch, emitsError(isA<DatabaseLockedFailure>()));
  });

  group('guardDatabase', () {
    test('a value passes through', () async {
      expect(await guardDatabase(() async => 7), 7);
    });

    test('a database error leaves as its Failure, with the original '
        'stack', () async {
      late StackTrace thrownAt;
      Future<int> body() async {
        try {
          throw sqlite3.SqliteException(
            extendedResultCode: 5,
            message: 'database is locked',
          );
        } on Object catch (_, stack) {
          thrownAt = stack;
          rethrow;
        }
      }

      Object? caught;
      StackTrace? caughtAt;
      try {
        await guardDatabase(body);
      } on Object catch (error, stack) {
        caught = error;
        caughtAt = stack;
      }
      expect(caught, isA<DatabaseLockedFailure>());
      expect(caughtAt.toString(), thrownAt.toString());
    });

    test('a throw before the first await is mapped too', () async {
      Future<int> body() => throw StateError('sync');
      await expectLater(
        guardDatabase(body),
        throwsA(isA<UnknownDatabaseFailure>()),
      );
    });

    test('a Failure thrown inside leaves as it is', () async {
      const refusal = ConstraintFailure(cause: 'x');
      await expectLater(
        guardDatabase<int>(() async => throw refusal),
        throwsA(same(refusal)),
      );
    });
  });
}
