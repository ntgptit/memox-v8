import 'dart:developer' as developer;

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

  /// Queued entries to their stores; called when the app pauses.
  Future<void> flush() async {
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
    final entry = LogEntry(
      id: _uuid.v4(),
      occurredAt: _now().toUtc(),
      level: level,
      category: category,
      event: event,
      message: _storable(message),
      errorType: error?.runtimeType.toString(),
      errorMessage: _storable(_describe(error)),
      stackTrace: _storable(stackTrace?.toString()),
      context: {
        for (final MapEntry(:key, :value) in context.entries)
          key: _storableValue(value),
      },
      stamp: stamp,
    );
    for (final sink in _sinks) {
      try {
        sink.write(entry);
      } on Object catch (sinkError) {
        // A sink never logs itself: that would loop.
        developer.log('Log sink failed: $sinkError', name: 'memox.logging');
      }
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

/// The installed logger; console-only until the app installs its own.
AppLogger get appLogger => AppLogger._installed;
