import 'package:memox/core/logging/log_entry.dart';

/// Keeps every entry a logger hands it, for assertions.
final class RecordingLogSink implements LogSink {
  final entries = <LogEntry>[];

  Iterable<String> get events => entries.map((e) => e.event);

  @override
  void write(LogEntry entry) => entries.add(entry);

  @override
  Future<void> flush() async {}
}
