import 'dart:developer' as developer;

import 'package:memox/core/logging/log_entry.dart';

/// Every log to `dart:developer`, for the debugger and DevTools.
final class ConsoleSink implements LogSink {
  const ConsoleSink();

  static const _levels = {
    LogLevel.debug: 500,
    LogLevel.info: 800,
    LogLevel.warning: 900,
    LogLevel.error: 1000,
  };

  @override
  void write(LogEntry entry) => developer.log(
    [
      '[${entry.event}]',
      ?entry.message,
      if (entry.context.isNotEmpty) '${entry.context}',
    ].join(' '),
    name: 'memox.${entry.category.name}',
    level: _levels[entry.level]!,
    error: entry.errorMessage,
    time: entry.occurredAt,
  );

  @override
  Future<void> flush() async {}
}
