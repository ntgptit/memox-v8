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

  test(
    'NUL and lone surrogates, which the server cannot store, are replaced',
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
    },
  );

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

  group('an error storm', () {
    late _RecordingSink sink;
    late DateTime clock;
    late AppLogger logger;

    setUp(() {
      sink = _RecordingSink();
      clock = at;
      logger = AppLogger(sinks: [sink], now: () => clock);
    });

    void tick(Duration by) => clock = clock.add(by);

    void fail([Object? error]) =>
        logger.error('sync.failed', error: error ?? StateError('down'));

    test('warnings without an error are never merged: each keeps its own '
        'context', () {
      logger
        ..warning('db.slow_query', context: {'sql': 'SELECT 1'})
        ..warning('db.slow_query', context: {'sql': 'SELECT 2'});

      expect(
        [for (final e in sink.entries) e.context['sql']],
        ['SELECT 1', 'SELECT 2'],
      );
    });

    test('a flush writes the count of a storm that stopped', () async {
      fail();
      tick(const Duration(seconds: 1));
      fail();
      fail();

      await logger.flush();

      expect(sink.entries, hasLength(2));
      expect(sink.entries.last.event, 'sync.failed');
      expect(sink.entries.last.level, LogLevel.error);
      expect(sink.entries.last.errorType, 'StateError');
      expect(sink.entries.last.context['repeated'], 2);
    });

    test('a count written by a flush is not written again', () async {
      fail();
      fail();
      await logger.flush();
      await logger.flush();
      tick(const Duration(seconds: 6));
      fail();

      expect(
        [for (final e in sink.entries) e.context['repeated']],
        [null, 1, null],
      );
    });

    test('a clock set back does not hide the next error', () {
      fail();
      tick(const Duration(hours: -2));
      fail();

      expect(sink.entries, hasLength(2));
    });

    test('the same error within 5 s is written once', () {
      fail();
      tick(const Duration(seconds: 1));
      fail();
      tick(const Duration(seconds: 3));
      fail();

      expect(sink.entries, hasLength(1));
      expect(sink.entries.single.context.containsKey('repeated'), isFalse);
    });

    test('the next one after the window is written with the count it '
        'suppressed', () {
      fail();
      tick(const Duration(seconds: 1));
      fail();
      fail();
      tick(const Duration(seconds: 4));
      fail();

      expect(sink.entries, hasLength(2));
      expect(sink.entries.last.context['repeated'], 2);
    });

    test('the window counts from the last entry written, so a steady storm '
        'still shows up every 5 s', () {
      fail();
      for (var i = 0; i < 12; i++) {
        tick(const Duration(seconds: 1));
        fail();
      }

      expect(sink.entries, hasLength(3));
      expect(sink.entries[1].context['repeated'], 4);
      expect(sink.entries[2].context['repeated'], 4);
    });

    test('a warning is deduped like an error', () {
      logger
        ..warning('db.slow_query', error: StateError('x'))
        ..warning('db.slow_query', error: StateError('x'));

      expect(sink.entries, hasLength(1));
    });

    test('a different event, error type or message is another storm', () {
      fail();
      logger
        ..error('sync.other', error: StateError('down'))
        ..error('sync.failed', error: ArgumentError('down'))
        ..error('sync.failed', error: StateError('up'));

      expect(sink.entries, hasLength(4));
    });

    test('debug and info are never deduped', () {
      logger
        ..debug('db.query')
        ..debug('db.query')
        ..info('lifecycle.resume')
        ..info('lifecycle.resume');

      expect(sink.entries, hasLength(4));
    });

    test('an entry with the same key after the count was written starts a '
        'new window', () {
      fail();
      fail();
      tick(const Duration(seconds: 6));
      fail();
      fail();

      expect(sink.entries, hasLength(2));
      tick(const Duration(seconds: 6));
      fail();
      expect(sink.entries.last.context['repeated'], 1);
    });

    test('a caller context is kept next to repeated', () {
      fail();
      fail();
      tick(const Duration(seconds: 6));
      logger.error(
        'sync.failed',
        error: StateError('down'),
        context: {'failures': 3},
      );

      expect(sink.entries.last.context, {'failures': 3, 'repeated': 1});
    });

    test('a key written again moves to the back: a busy storm is not the '
        'one dropped at the cap', () {
      fail(StateError('hot'));
      tick(const Duration(seconds: 6));
      for (var i = 0; i < 255; i++) {
        logger.error('x.$i', error: StateError('e'));
      }
      // Written again after the others: the most recently written key.
      fail(StateError('hot'));
      // The 257th key: one key must go.
      logger.error('x.255', error: StateError('e'));
      fail(StateError('hot'));

      expect(
        sink.entries.where((e) => e.errorMessage == 'Bad state: hot'),
        hasLength(2),
      );
    });

    test('keys of storms long over do not pile up', () {
      for (var i = 0; i < 1000; i++) {
        logger.error('x.$i', error: StateError('e'));
        tick(const Duration(seconds: 6));
      }

      expect(logger.dedupeKeysForTest, lessThanOrEqualTo(256));
    });
  });

  test('a network entry round-trips through JSON', () {
    final sink = _RecordingSink();
    AppLogger(
      sinks: [sink],
      now: () => at,
    ).debug('net.request', category: LogCategory.network);

    final json = sink.entries.single.toJson();

    expect(json['category'], 'network');
    expect(LogEntry.fromJson(json).category, LogCategory.network);
  });
}

final class _Unprintable {
  @override
  String toString() => throw StateError('no');
}
