import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/buffer_sink.dart';
import 'package:memox/core/logging/log_config.dart';
import 'package:memox/core/logging/log_entry.dart';

LogEntry _entry(int n, [LogLevel level = LogLevel.debug]) => LogEntry(
  id: 'id-$n',
  occurredAt: DateTime.utc(2026, 9, 29, 12, 0, n),
  level: level,
  category: LogCategory.db,
  event: 'db.query',
);

final class _CountingDatabase extends LogDatabase {
  _CountingDatabase() : super(NativeDatabase.memory());

  var inserts = 0;
  var fail = false;

  @override
  Future<void> insertAll(List<LogEntry> entries) {
    inserts++;
    if (fail) throw StateError('disk full');
    return super.insertAll(entries);
  }
}

// Spec §3: the buffer batches, so a burst is a few writes, not one per log.
void main() {
  test(
    '120 logs inside two seconds are at most three writes, and all land',
    () {
      fakeAsync((async) {
        final db = _CountingDatabase();
        final sink = BufferSink(db);
        for (var n = 0; n < 120; n++) {
          sink.write(_entry(n));
        }
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(db.inserts, inInclusiveRange(1, 3));
        int? rows;
        db.count().then((n) => rows = n);
        async.flushMicrotasks();
        expect(rows, 120);
        sink.dispose();
        db.close();
      });
    },
  );

  test(
    'a warning or an error is written at once, with what waits before it',
    () {
      fakeAsync((async) {
        final db = _CountingDatabase();
        final sink = BufferSink(db)
          ..write(_entry(1))
          ..write(_entry(2, LogLevel.error));
        async.flushMicrotasks();

        expect(db.inserts, 1);
        int? rows;
        db.count().then((n) => rows = n);
        async.flushMicrotasks();
        expect(rows, 2);
        sink.dispose();
        db.close();
      });
    },
  );

  test('a write past the cap prunes the buffer at once, oldest debug rows '
      'first (DEV-207)', () async {
    final db = _CountingDatabase();
    final sink = BufferSink(db, cap: 3);
    for (var n = 0; n < 5; n++) {
      sink.write(_entry(n));
    }
    await sink.flush();

    expect(await db.count(), 3);
    expect((await db.oldest(10)).map((e) => e.id), ['id-2', 'id-3', 'id-4']);
    sink.dispose();
    await db.close();
  });

  test('after a failed write, logging does not retry at once; the retry '
      'waits, then writes everything', () {
    fakeAsync((async) {
      final db = _CountingDatabase()..fail = true;
      final sink = BufferSink(db);
      for (var n = 0; n < 50; n++) {
        sink.write(_entry(n));
      }
      async.flushMicrotasks();
      expect(db.inserts, 1);

      for (var n = 50; n < 160; n++) {
        sink.write(_entry(n, n.isEven ? LogLevel.error : LogLevel.debug));
      }
      async.flushMicrotasks();
      expect(db.inserts, 1);

      db.fail = false;
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(db.inserts, 2);
      int? rows;
      db.count().then((n) => rows = n);
      async.flushMicrotasks();
      expect(rows, 160);
      sink.dispose();
      db.close();
    });
  });

  test('a flush writes what is queued', () async {
    final db = _CountingDatabase();
    addTearDown(db.close);
    final sink = BufferSink(db)..write(_entry(1));
    addTearDown(sink.dispose);

    await sink.flush();

    expect(await db.count(), 1);
  });

  test('entries below persistMinLevel are not kept', () async {
    final db = _CountingDatabase();
    addTearDown(db.close);
    final sink =
        BufferSink(
            db,
            config: const LogConfig(persistMinLevel: LogLevel.warning),
          )
          ..write(_entry(1))
          ..write(_entry(2, LogLevel.error));
    addTearDown(sink.dispose);

    await sink.flush();

    expect((await db.oldest(10)).map((e) => e.id), ['id-2']);
  });

  test(
    'a failed write is caught; the batch is kept for the next flush',
    () async {
      final db = _CountingDatabase()..fail = true;
      addTearDown(db.close);
      final sink = BufferSink(db)..write(_entry(1));
      addTearDown(sink.dispose);

      await expectLater(sink.flush(), completes);
      db.fail = false;
      await sink.flush();

      expect(await db.count(), 1);
    },
  );
}
