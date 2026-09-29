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
  test('120 logs inside two seconds are at most three writes', () {
    fakeAsync((async) {
      final db = _CountingDatabase();
      final sink = BufferSink(db);
      for (var n = 0; n < 120; n++) {
        sink.write(_entry(n));
      }
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();

      expect(db.inserts, lessThanOrEqualTo(3));
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
