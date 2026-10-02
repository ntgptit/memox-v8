import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';

LogEntry _entry(String id, LogLevel level, DateTime at) => LogEntry(
  id: id,
  occurredAt: at,
  level: level,
  category: LogCategory.db,
  event: 'db.query',
  message: 'm $id',
  context: {
    'sql': 'SELECT ?',
    'args': [1],
  },
  stamp: const LogStamp(deviceId: 'd', appVersion: '8.0.0'),
);

// Spec 2026-09-29-app-logging-design.md §3: the device buffer.
void main() {
  late LogDatabase db;
  final now = DateTime.utc(2026, 9, 29, 12);

  setUp(() => db = LogDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('entries come back oldest first, whole', () async {
    await db.insertAll([
      _entry('b', LogLevel.info, now),
      _entry('a', LogLevel.error, now.subtract(const Duration(minutes: 1))),
    ]);

    final rows = await db.oldest(10);

    expect(rows.map((e) => e.id), ['a', 'b']);
    expect(
      rows.first.toJson(),
      _entry(
        'a',
        LogLevel.error,
        now.subtract(const Duration(minutes: 1)),
      ).toJson(),
    );
  });

  test(
    'deleteIds removes only those rows; a re-insert of an id is ignored',
    () async {
      await db.insertAll([
        _entry('a', LogLevel.info, now),
        _entry('b', LogLevel.info, now),
      ]);
      await db.insertAll([_entry('a', LogLevel.error, now)]);
      await db.deleteIds({'a'});

      expect((await db.oldest(10)).map((e) => e.id), ['b']);
    },
  );

  test('deleteIds with no id deletes nothing', () async {
    await db.insertAll([_entry('a', LogLevel.info, now)]);
    await db.deleteIds(const <String>{});

    expect((await db.oldest(10)).map((e) => e.id), ['a']);
  });

  test('prune: debug and info older than 7 days, warning and error older '
      'than 180 days', () async {
    await db.insertAll([
      _entry('debug-8d', LogLevel.debug, now.subtract(const Duration(days: 8))),
      _entry('info-8d', LogLevel.info, now.subtract(const Duration(days: 8))),
      _entry('info-6d', LogLevel.info, now.subtract(const Duration(days: 6))),
      _entry(
        'warn-8d',
        LogLevel.warning,
        now.subtract(const Duration(days: 8)),
      ),
      _entry(
        'error-181d',
        LogLevel.error,
        now.subtract(const Duration(days: 181)),
      ),
      _entry(
        'error-179d',
        LogLevel.error,
        now.subtract(const Duration(days: 179)),
      ),
    ]);

    await db.prune(now: now);

    expect((await db.oldest(10)).map((e) => e.id), [
      'error-179d',
      'warn-8d',
      'info-6d',
    ]);
  });

  test(
    'prune past the cap drops debug first, then info, oldest first',
    () async {
      await db.insertAll([
        _entry(
          'error-old',
          LogLevel.error,
          now.subtract(const Duration(hours: 9)),
        ),
        _entry(
          'info-old',
          LogLevel.info,
          now.subtract(const Duration(hours: 8)),
        ),
        _entry(
          'debug-old',
          LogLevel.debug,
          now.subtract(const Duration(hours: 7)),
        ),
        _entry(
          'debug-new',
          LogLevel.debug,
          now.subtract(const Duration(hours: 1)),
        ),
        _entry('info-new', LogLevel.info, now),
      ]);

      await db.prune(now: now, cap: 2);

      expect((await db.oldest(10)).map((e) => e.id), ['error-old', 'info-new']);
    },
  );

  test('a context value JSON cannot encode is stored as its text', () async {
    await db.insertAll([
      LogEntry(
        id: 'odd',
        occurredAt: now,
        level: LogLevel.error,
        category: LogCategory.state,
        event: 'state.provider_failed',
        context: {'argument': Duration.zero},
      ),
    ]);

    final row = (await db.oldest(1)).single;

    expect(row.context['argument'], Duration.zero.toString());
  });

  test('a context JSON cannot encode at all is stored as its text', () async {
    final cyclic = <String, Object?>{};
    cyclic['self'] = cyclic;

    await db.insertAll([
      LogEntry(
        id: 'cyclic',
        occurredAt: now,
        level: LogLevel.error,
        category: LogCategory.state,
        event: 'state.provider_failed',
        context: cyclic,
      ),
    ]);

    final row = (await db.oldest(1)).single;
    expect(row.context['unencodable'], isA<String>());
  });

  test('count watches the pending rows', () async {
    expect(await db.count(), 0);
    await db.insertAll([_entry('a', LogLevel.info, now)]);
    expect(await db.count(), 1);
  });
}
