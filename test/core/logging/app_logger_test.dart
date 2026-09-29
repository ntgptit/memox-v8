import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';

final class _RecordingSink implements LogSink {
  final entries = <LogEntry>[];

  @override
  void write(LogEntry entry) => entries.add(entry);

  @override
  Future<void> flush() async {}
}

final class _ThrowingSink implements LogSink {
  @override
  void write(LogEntry entry) => throw StateError('sink broke');

  @override
  Future<void> flush() async {}
}

// ADR-018, spec 2026-09-29-app-logging-design.md §2–3.
void main() {
  final at = DateTime.utc(2026, 9, 29, 8, 30);
  const stamp = LogStamp(
    deviceId: 'device-1',
    appVersion: '8.0.0',
    buildNumber: '42',
    platform: 'android',
    osVersion: '16',
  );

  test('an error hands every sink one entry with the error, its cause and '
      'the stack', () {
    final a = _RecordingSink();
    final b = _RecordingSink();
    final logger = AppLogger(sinks: [a, b], now: () => at, stamp: stamp);
    final stack = StackTrace.current;

    logger.error(
      'db.query_failed',
      category: LogCategory.db,
      message: 'insert card "私の秘密"',
      error: const ConstraintFailure(cause: 'CHECK failed'),
      stackTrace: stack,
      context: {'deckId': 'd1'},
    );

    expect(a.entries, hasLength(1));
    expect(b.entries.single, same(a.entries.single));
    final entry = a.entries.single;
    expect(entry.level, LogLevel.error);
    expect(entry.category, LogCategory.db);
    expect(entry.event, 'db.query_failed');
    expect(entry.message, 'insert card "私の秘密"');
    expect(entry.errorType, 'ConstraintFailure');
    expect(entry.errorMessage, contains('CHECK failed'));
    expect(entry.stackTrace, stack.toString());
    expect(entry.context, {'deckId': 'd1'});
    expect(entry.occurredAt, at);
    expect(entry.deviceId, 'device-1');
    expect(entry.appVersion, '8.0.0');
  });

  test('each entry gets its own id, in UTC', () {
    final sink = _RecordingSink();
    final logger = AppLogger(
      sinks: [sink],
      now: () => DateTime(2026, 9, 29, 8),
    );

    logger
      ..info('nav.push')
      ..debug('db.query');

    expect(sink.entries.map((e) => e.id).toSet(), hasLength(2));
    expect(sink.entries.first.occurredAt.isUtc, isTrue);
    expect(sink.entries.last.level, LogLevel.debug);
  });

  test('a sink that throws never throws from the call, and the others still '
      'receive the entry', () {
    final after = _RecordingSink();
    final logger = AppLogger(sinks: [_ThrowingSink(), after], now: () => at);

    expect(() => logger.warning('sync.rejected'), returnsNormally);
    expect(after.entries, hasLength(1));
  });

  test('before install, appLogger writes to the console only and works', () {
    expect(() => appLogger.info('lifecycle.start'), returnsNormally);
  });

  test('install replaces appLogger', () {
    final sink = _RecordingSink();
    final previous = appLogger;
    addTearDown(() => AppLogger.install(previous));
    AppLogger.install(AppLogger(sinks: [sink], now: () => at));

    appLogger.info('lifecycle.start');

    expect(sink.entries.single.event, 'lifecycle.start');
  });

  test('an entry round-trips through JSON, context included', () {
    final sink = _RecordingSink();
    AppLogger(sinks: [sink], now: () => at, stamp: stamp).warning(
      'db.slow_query',
      category: LogCategory.db,
      message: 'slow',
      context: {
        'sql': 'SELECT 1',
        'args': [1, 'a'],
        'duration_ms': 200,
      },
    );
    final entry = sink.entries.single;

    final copy = LogEntry.fromJson(entry.toJson());

    expect(copy.toJson(), entry.toJson());
    expect(copy.context['args'], [1, 'a']);
  });

  test('NUL and lone surrogates, which the server cannot store, are replaced',
      () {
    final sink = _RecordingSink();
    final logger = AppLogger(sinks: [sink], now: () => at);
    final halfEmoji = '😀'.substring(0, 1);

    logger.info(
      'db.query',
      message: 'a\u0000b$halfEmoji',
      context: {
        'args': ['x\u0000', halfEmoji, 7],
        'nested': {'k': 'ok😀'},
      },
    );

    final entry = sink.entries.single;
    expect(entry.message, 'ab\uFFFD');
    expect(entry.context['args'], ['x', '\uFFFD', 7]);
    expect(entry.context['nested'], {'k': 'ok😀'});
  });

  test('a context that holds itself still logs', () {
    final sink = _RecordingSink();
    final logger = AppLogger(sinks: [sink], now: () => at);
    final cyclic = <String, Object?>{};
    cyclic['self'] = cyclic;

    logger.info('state.x', context: {'value': cyclic});

    expect(sink.entries, hasLength(1));
  });

  test('an error whose toString throws still logs', () {
    final sink = _RecordingSink();
    final logger = AppLogger(sinks: [sink], now: () => at);

    logger.error('state.provider_failed', error: _Unprintable());

    expect(sink.entries.single.errorType, '_Unprintable');
  });
}

final class _Unprintable {
  @override
  String toString() => throw StateError('no');
}
