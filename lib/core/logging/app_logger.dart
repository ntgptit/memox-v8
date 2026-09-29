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
      message: message,
      errorType: error?.runtimeType.toString(),
      errorMessage: _describe(error),
      stackTrace: stackTrace?.toString(),
      context: context,
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

  static String? _describe(Object? error) => switch (error) {
    null => null,
    Failure(:final cause?) => '$error cause: $cause',
    _ => error.toString(),
  };
}

/// The installed logger; console-only until the app installs its own.
AppLogger get appLogger => AppLogger._installed;
