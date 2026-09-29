import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:uuid/uuid.dart';

export 'package:memox/core/logging/log_entry.dart'
    show LogCategory, LogLevel, LogStamp;

/// The one way the app logs (ADR-018). Installed once at start; code with no
/// `Ref` — the Drift tracer, `main`, a background isolate — reads it through
/// [appLogger].
final class AppLogger {
  AppLogger({
    required List<LogSink> sinks,
    DateTime Function()? now,
    this.stamp = const LogStamp(),
  }) : _sinks = List.unmodifiable(sinks),
       _now = now ?? DateTime.now;

  final List<LogSink> _sinks;
  final DateTime Function() _now;
  final LogStamp stamp;

  /// A warning or error repeated inside this window is counted, not written.
  static const stormWindow = Duration(seconds: 5);

  /// Past this many keys, the ones whose window is over are forgotten (their
  /// suppressed count with them).
  static const _maxStormKeys = 256;

  final _storms = <(String, String?, String?), _Storm>{};

  @visibleForTesting
  int get dedupeKeysForTest => _storms.length;

  @visibleForTesting
  List<LogSink> get sinks => _sinks;

  static const _uuid = Uuid();
  static AppLogger _installed = AppLogger(sinks: const [ConsoleSink()]);

  /// Makes [logger] the one [appLogger] returns.
  static void install(AppLogger logger) => _installed = logger;

  void debug(
    String event, {
    LogCategory category = LogCategory.state,
    String? message,
    Map<String, Object?> context = const {},
  }) => _log(LogLevel.debug, event, category, message, null, null, context);

  void info(
    String event, {
    LogCategory category = LogCategory.state,
    String? message,
    Map<String, Object?> context = const {},
  }) => _log(LogLevel.info, event, category, message, null, null, context);

  void warning(
    String event, {
    LogCategory category = LogCategory.state,
    String? message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) => _log(
    LogLevel.warning,
    event,
    category,
    message,
    error,
    stackTrace,
    context,
  );

  void error(
    String event, {
    LogCategory category = LogCategory.state,
    String? message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) => _log(
    LogLevel.error,
    event,
    category,
    message,
    error,
    stackTrace,
    context,
  );

  /// Queued entries to their stores; called when the app pauses. A storm's
  /// count not yet written goes first, so a pause never loses it.
  Future<void> flush() async {
    _writeStormCounts();
    for (final sink in _sinks) {
      try {
        await sink.flush();
      } on Object catch (error) {
        developer.log('Log sink flush failed: $error', name: 'memox.logging');
      }
    }
  }

  void _log(
    LogLevel level,
    String event,
    LogCategory category,
    String? message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context,
  ) {
    final at = _now().toUtc();
    final errorType = error?.runtimeType.toString();
    final errorMessage = _storable(_describe(error));
    final key = (event, errorType, errorMessage);
    final repeated = _repeated(level, error, at, key);
    if (repeated == null) return;
    final entry = LogEntry(
      id: _uuid.v4(),
      occurredAt: at,
      level: level,
      category: category,
      event: event,
      message: _storable(message),
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: _storable(stackTrace?.toString()),
      context: {
        for (final MapEntry(:key, :value) in context.entries)
          key: _storableValue(value),
        if (repeated > 0) 'repeated': repeated,
      },
      stamp: stamp,
    );
    _storms[key]?.last = entry;
    _write(entry);
  }

  void _write(LogEntry entry) {
    for (final sink in _sinks) {
      try {
        sink.write(entry);
      } on Object catch (sinkError) {
        // A sink never logs itself: that would loop.
        developer.log('Log sink failed: $sinkError', name: 'memox.logging');
      }
    }
  }

  /// One entry per storm with a count not yet written: the last entry written
  /// again, now, with `repeated`.
  void _writeStormCounts() {
    final at = _now().toUtc();
    for (final storm in _storms.values) {
      final last = storm.last;
      if (storm.suppressed == 0 || last == null) continue;
      _write(
        LogEntry(
          id: _uuid.v4(),
          occurredAt: at,
          level: last.level,
          category: last.category,
          event: last.event,
          message: last.message,
          errorType: last.errorType,
          errorMessage: last.errorMessage,
          stackTrace: last.stackTrace,
          context: {...last.context, 'repeated': storm.suppressed},
          stamp: last.stamp,
        ),
      );
      storm.suppressed = 0;
    }
  }

  /// Error-storm dedupe: null when this warning or error repeats one written
  /// less than [stormWindow] ago (it is counted); otherwise how many it
  /// suppressed since the last one written (0 for none). Only entries that
  /// carry an error are held back: a warning without one (a slow query, a
  /// refused row) is told apart by its context, which the key does not see.
  /// The window runs from the last entry written, so a storm that never stops
  /// still shows up once per window; a clock set back ends the window.
  int? _repeated(
    LogLevel level,
    Object? error,
    DateTime at,
    (String, String?, String?) key,
  ) {
    if (level.index < LogLevel.warning.index || error == null) return 0;
    final storm = _storms[key];
    final since = storm == null ? null : at.difference(storm.writtenAt);
    if (storm != null && !since!.isNegative && since < stormWindow) {
      storm.suppressed++;
      return null;
    }
    final suppressed = storm?.suppressed ?? 0;
    if (_storms.length >= _maxStormKeys && storm == null) _forgetOldStorms(at);
    // Written again: to the back, so the cap drops the least recently written.
    _storms
      ..remove(key)
      ..[key] = _Storm(at);
    return suppressed;
  }

  void _forgetOldStorms(DateTime at) {
    _storms.removeWhere(
      (_, storm) => at.difference(storm.writtenAt) >= stormWindow,
    );
    // Every key still open: drop the least recently written, at the front.
    while (_storms.length >= _maxStormKeys) {
      _storms.remove(_storms.keys.first);
    }
  }

  static String? _describe(Object? error) {
    try {
      return switch (error) {
        null => null,
        Failure(:final cause?) => '$error cause: $cause',
        _ => error.toString(),
      };
    } on Object catch (describeError) {
      return '<toString failed: ${describeError.runtimeType}>';
    }
  }

  /// Past [_maxDepth] nesting — a context that holds itself — a value is kept
  /// as its text.
  static Object? _storableValue(Object? value, [int depth = 0]) {
    if (depth > _maxDepth && (value is List || value is Map)) {
      return _storable(value.toString());
    }
    return switch (value) {
      String() => _storable(value),
      List<Object?>() => [
        for (final item in value) _storableValue(item, depth + 1),
      ],
      Map<Object?, Object?>() => {
        for (final MapEntry(:key, :value) in value.entries)
          '$key': _storableValue(value, depth + 1),
      },
      _ => value,
    };
  }

  static const _maxDepth = 16;

  /// Postgres text and jsonb refuse NUL and a lone UTF-16 surrogate (text cut
  /// mid-emoji); one such entry would fail every push of its batch. NUL goes,
  /// a lone surrogate becomes U+FFFD.
  static String? _storable(String? text) {
    if (text == null || !_unstorable.hasMatch(text)) return text;
    return text.replaceAll('\u0000', '').replaceAll(_loneSurrogate, '\uFFFD');
  }

  static final _unstorable = RegExp(r'[\u0000\uD800-\uDFFF]');
  static final _loneSurrogate = RegExp(
    r'[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]',
  );
}

/// One warning or error, as it was last written, and how many like it came
/// since.
final class _Storm {
  _Storm(this.writtenAt);

  final DateTime writtenAt;
  int suppressed = 0;

  /// The entry written at [writtenAt], for the count a flush writes.
  LogEntry? last;
}

/// The installed logger; console-only until the app installs its own.
AppLogger get appLogger => AppLogger._installed;
