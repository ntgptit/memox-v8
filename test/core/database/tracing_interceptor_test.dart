import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/database/tracing_interceptor.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/buffer_sink.dart';

import '../../support/recording_log_sink.dart';

/// Sits under the tracer and makes each statement take the next of [durations]
/// (milliseconds) on the tracer's clock, or no time once they run out.
final class _Takes extends QueryInterceptor {
  final durations = <int>[];
  int micros = 0;

  void _elapse() {
    if (durations.isNotEmpty) micros += durations.removeAt(0) * 1000;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _elapse();
    return super.runSelect(executor, statement, args);
  }
}

// Spec 2026-09-29-app-logging-design.md §3: the Drift tracer.
void main() {
  late RecordingLogSink sink;
  late AppLogger logger;

  setUp(() {
    sink = RecordingLogSink();
    logger = AppLogger(sinks: [sink]);
  });

  Future<AppDatabase> open(List<int> durations) async {
    final takes = _Takes();
    final db = AppDatabase(
      NativeDatabase.memory()
          .interceptWith(takes)
          .interceptWith(
            TracingInterceptor(logger: logger, micros: () => takes.micros),
          ),
    );
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    sink.entries.clear();
    takes.durations.addAll(durations);
    return db;
  }

  test(
    'a statement logs debug db.query with its SQL, arguments and time',
    () async {
      final db = await open([3]);

      await db
          .customSelect('SELECT ? AS n', variables: [Variable.withInt(7)])
          .get();

      final entry = sink.entries.single;
      expect(
        (entry.level, entry.category, entry.event),
        (LogLevel.debug, LogCategory.db, 'db.query'),
      );
      expect(entry.context['sql'], 'SELECT ? AS n');
      expect(entry.context['args'], [7]);
      expect(entry.context['duration_ms'], 3);
      expect(entry.context['kind'], 'select');
    },
  );

  test(
    'from 50 ms a statement is info db.slow_query, from 150 ms a warning',
    () async {
      final db = await open([60, 200]);

      await db.customSelect('SELECT 1').get();
      await db.customSelect('SELECT 2').get();

      expect(
        [for (final e in sink.entries) (e.level, e.event)],
        [(LogLevel.info, 'db.slow_query'), (LogLevel.warning, 'db.slow_query')],
      );
    },
  );

  test('a failing statement logs error db.query_failed and throws the '
      'original error', () async {
    final db = await open([1]);

    await expectLater(
      db.customSelect('SELECT * FROM missing').get(),
      throwsA(isNot(isA<Error>())),
    );

    final entry = sink.entries.single;
    expect((entry.level, entry.event), (LogLevel.error, 'db.query_failed'));
    expect(entry.errorMessage, contains('missing'));
  });

  test('a transaction logs one debug db.transaction when it commits', () async {
    final db = await open(const []);

    await db.transaction(() => db.customSelect('SELECT 1').get());

    final transactions = [
      for (final e in sink.entries)
        if (e.event == 'db.transaction') e,
    ];
    expect(transactions, hasLength(1));
    expect(transactions.single.level, LogLevel.debug);
    expect(transactions.single.context['outcome'], 'commit');
  });

  test('a log written to the buffer adds no traced statement', () async {
    final logs = LogDatabase(NativeDatabase.memory());
    addTearDown(logs.close);
    final buffer = BufferSink(logs);
    addTearDown(buffer.dispose);
    logger = AppLogger(sinks: [sink, buffer]);
    final db = await open(const []);

    await db.customSelect('SELECT 1').get();
    await buffer.flush();

    expect(sink.events, ['db.query']);
    expect(await logs.count(), 2);
  });

  test(
    'insert, update, delete, custom and batch statements log their kind',
    () async {
      final db = await open(const []);

      await db.customStatement('CREATE TEMP TABLE t (x INTEGER)');
      await db.customInsert(
        'INSERT INTO t VALUES (?)',
        variables: [Variable.withInt(1)],
      );
      await db.customUpdate('UPDATE t SET x = 2');
      await db.customUpdate('DELETE FROM t', updateKind: UpdateKind.delete);
      await db.batch((b) => b.customStatement('INSERT INTO t VALUES (?)', [3]));

      expect([
        for (final e in sink.entries) e.context['kind'],
      ], containsAllInOrder(['custom', 'insert', 'update', 'batch']));
      expect([
        for (final e in sink.entries) e.context['sql'],
      ], contains('DELETE FROM t'));
      final batch = sink.entries.lastWhere((e) => e.context['kind'] == 'batch');
      expect(batch.context['args'], [
        [3],
      ]);
    },
  );

  test('a batch of more than 50 runs keeps the arguments of the first 50 and '
      'says how many runs there were', () async {
    final db = await open(const []);
    await db.customStatement('CREATE TEMP TABLE t (x INTEGER)');
    sink.entries.clear();

    await db.batch((b) {
      for (var i = 0; i < 60; i++) {
        b.customStatement('INSERT INTO t VALUES (?)', [i]);
      }
    });

    final batch = sink.entries.singleWhere((e) => e.context['kind'] == 'batch');
    final args = batch.context['args']! as List<Object?>;
    expect(args, hasLength(50));
    expect(args.first, [0]);
    expect(args.last, [49]);
    expect(batch.context['runs'], 60);
    expect(batch.context['sql'], 'INSERT INTO t VALUES (?)');
  });

  test('a batch of 50 runs or fewer keeps every run', () async {
    final db = await open(const []);
    await db.customStatement('CREATE TEMP TABLE t (x INTEGER)');
    sink.entries.clear();

    await db.batch((b) {
      for (var i = 0; i < 50; i++) {
        b.customStatement('INSERT INTO t VALUES (?)', [i]);
      }
    });

    final batch = sink.entries.singleWhere((e) => e.context['kind'] == 'batch');
    expect(batch.context['args'], hasLength(50));
    expect(batch.context['runs'], 50);
  });

  test('a transaction measures from its start to the end of the commit, '
      'and keeps the commit call apart', () async {
    final db = await open([10, 20]);

    await db.transaction(() async {
      await db.customSelect('SELECT 1').get();
      await db.customSelect('SELECT 2').get();
    });

    final end = sink.entries.singleWhere((e) => e.event == 'db.transaction');
    expect(end.context['outcome'], 'commit');
    expect(end.context['duration_ms'], 30);
    expect(end.context['commit_ms'], 0);
  });

  test('a rolled back transaction measures from its start too', () async {
    final db = await open([15]);

    await expectLater(
      db.transaction<void>(() async {
        await db.customSelect('SELECT 1').get();
        throw StateError('abort');
      }),
      throwsStateError,
    );

    final end = sink.entries.singleWhere((e) => e.event == 'db.transaction');
    expect(end.context['outcome'], 'rollback');
    expect(end.context['duration_ms'], 15);
  });

  test('a slow commit shows in commit_ms, and in duration_ms', () async {
    final takes = _Takes();
    final db = AppDatabase(
      NativeDatabase.memory()
          .interceptWith(_SlowCommit(takes, 40))
          .interceptWith(
            TracingInterceptor(logger: logger, micros: () => takes.micros),
          ),
    );
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    sink.entries.clear();

    await db.transaction(() => db.customSelect('SELECT 1').get());

    final end = sink.entries.singleWhere((e) => e.event == 'db.transaction');
    expect(end.context['commit_ms'], 40);
    expect(end.context['duration_ms'], 40);
  });

  test('a transaction that throws logs db.transaction with rollback', () async {
    final db = await open(const []);

    await expectLater(
      db.transaction<void>(() async {
        await db.customSelect('SELECT 1').get();
        throw StateError('abort');
      }),
      throwsStateError,
    );

    final ends = [
      for (final e in sink.entries)
        if (e.event == 'db.transaction') e.context['outcome'],
    ];
    expect(ends, ['rollback']);
  });

  test(
    'the thrown error is the original one, and the log describes it',
    () async {
      final db = await open(const []);

      final thrown = await db
          .customSelect('SELECT * FROM missing')
          .get()
          .then<Object?>((_) => null, onError: (Object error) => error);

      expect(thrown, isA<SqliteException>());
      expect(sink.entries.single.errorType, thrown.runtimeType.toString());
      expect(sink.entries.single.errorMessage, thrown.toString());
    },
  );

  test('the default clock measures real time', () async {
    final db = AppDatabase(
      NativeDatabase.memory()
          .interceptWith(_Sleeps())
          .interceptWith(TracingInterceptor(logger: logger)),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    final entry = sink.entries.single;
    expect(entry.event, 'db.slow_query');
    expect(entry.context['duration_ms'], greaterThanOrEqualTo(50));
  });
}

/// Makes each commit take [ms] on the tracer's clock.
final class _SlowCommit extends QueryInterceptor {
  _SlowCommit(this._takes, this.ms);

  final _Takes _takes;
  final int ms;

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    _takes.micros += ms * 1000;
    return super.commitTransaction(inner);
  }
}

/// Takes 60 ms of wall time on every select.
final class _Sleeps extends QueryInterceptor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return super.runSelect(executor, statement, args);
  }
}
