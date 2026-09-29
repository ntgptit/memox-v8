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
}
