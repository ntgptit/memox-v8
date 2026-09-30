import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';

LogEntry _entry(
  String id,
  LogLevel level,
  DateTime at, {
  String? message,
  String? errorMessage,
  String? stackTrace,
}) => LogEntry(
  id: id,
  occurredAt: at,
  level: level,
  category: LogCategory.db,
  event: 'db.query',
  message: message ?? 'm $id',
  errorType: level == LogLevel.error ? 'StateError' : null,
  errorMessage: errorMessage,
  stackTrace: stackTrace,
  context: {'sql': 'SELECT ?'},
);

// ADR-018 §8, monitoring spec §4.2: the Not sent tab reads the buffer.
void main() {
  late LogDatabase db;
  final now = DateTime.utc(2026, 9, 29, 12);

  setUp(() => db = LogDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'watchPending lists the newest rows of the levels, newest first',
    () async {
      await db.insertAll([
        _entry('a', LogLevel.error, now.subtract(const Duration(minutes: 2))),
        _entry('b', LogLevel.debug, now.subtract(const Duration(minutes: 1))),
        _entry('c', LogLevel.warning, now),
      ]);

      final pending = await db
          .watchPending(levels: {LogLevel.warning, LogLevel.error})
          .first;

      expect(pending.items.map((row) => row.id), ['c', 'a']);
      expect(pending.items.last.errorType, 'StateError');
      expect(pending.items.first.level, LogLevel.warning);
    },
  );

  test(
    'the total counts every level, and a limit cuts only the list',
    () async {
      await db.insertAll([
        for (var i = 0; i < 5; i++)
          _entry('r$i', LogLevel.info, now.add(Duration(seconds: i))),
        _entry('d', LogLevel.debug, now),
      ]);

      final pending = await db
          .watchPending(levels: {LogLevel.info}, limit: 3)
          .first;

      expect(pending.items.map((row) => row.id), ['r4', 'r3', 'r2']);
      expect(pending.total, 6);
    },
  );

  test('an empty level set lists every level', () async {
    await db.insertAll([
      _entry('a', LogLevel.debug, now),
      _entry('b', LogLevel.error, now),
    ]);

    final pending = await db.watchPending(levels: {}).first;

    expect(pending.items, hasLength(2));
  });

  test('a list row carries the first 300 characters of the message and the error only', () async {
    await db.insertAll([
      _entry(
        'long',
        LogLevel.error,
        now,
        message: 'x' * 1000,
        errorMessage: 'y' * 1000,
        stackTrace: 'trace',
      ),
    ]);

    final row = (await db.watchPending(levels: {}).first).items.single;

    expect(row.message, hasLength(300));
    expect(row.errorMessage, hasLength(300));
  });

  test('watchPending emits again when the buffer changes', () async {
    final seen = <int>[];
    final sub = db
        .watchPending(levels: {})
        .listen((pending) => seen.add(pending.items.length));
    await pumpEventQueue();

    await db.insertAll([_entry('a', LogLevel.error, now)]);
    await pumpEventQueue();
    await db.deleteIds({'a'});
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, [0, 1, 0]);
  });

  test('byId returns the whole row, or null once it is gone', () async {
    await db.insertAll([
      _entry('a', LogLevel.error, now, message: 'boom', stackTrace: '#0 main'),
    ]);

    final entry = await db.byId('a');

    expect(entry!.stackTrace, '#0 main');
    expect(entry.context['sql'], 'SELECT ?');
    await db.deleteIds({'a'});
    expect(await db.byId('a'), isNull);
  });
}
