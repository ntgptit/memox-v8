import 'dart:async';
import 'dart:developer' as developer;

import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_config.dart';
import 'package:memox/core/logging/log_entry.dart';

/// Queues entries in memory and writes them to the log buffer in batches:
/// every [flushEvery], at [flushAt] entries, or on [flush] (spec §3). A
/// warning or an error is written at once: it is what a crash right after it
/// must not take along. A failed write keeps the batch, never logs itself, and
/// backs off: until a write succeeds, only a timer (doubling up to
/// [maxBackoff]) or an explicit [flush] retries, never the next log call.
final class BufferSink implements LogSink {
  BufferSink(
    this._db, {
    this.flushEvery = const Duration(seconds: 2),
    this.flushAt = 50,
    this.maxQueued = 5000,
    this.maxBackoff = const Duration(minutes: 1),
    this.config = const LogConfig(),
  });

  final LogDatabase _db;
  final Duration flushEvery;
  final int flushAt;

  /// While the store keeps failing, the queue stops growing here; the oldest
  /// entries go first.
  final int maxQueued;
  final Duration maxBackoff;
  final LogConfig config;

  final _queue = <LogEntry>[];
  Timer? _timer;
  Future<void>? _writing;
  var _failures = 0;

  Duration get _delay {
    if (_failures == 0) return flushEvery;
    final delay = flushEvery * (1 << (_failures - 1).clamp(0, 16));
    return delay > maxBackoff ? maxBackoff : delay;
  }

  @override
  void write(LogEntry entry) {
    if (entry.level.index < config.persistMinLevel.index) return;
    _queue.add(entry);
    if (_queue.length > maxQueued) {
      _queue.removeRange(0, _queue.length - maxQueued);
    }
    final urgent =
        _queue.length >= flushAt || entry.level.index >= LogLevel.warning.index;
    if (urgent && _failures == 0) {
      unawaited(flush());
      return;
    }
    _timer ??= Timer(_delay, () => unawaited(flush()));
  }

  @override
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    // One write at a time: a flush during a write waits, then takes the rest.
    while (_writing != null) {
      await _writing;
    }
    if (_queue.isEmpty) return;
    final batch = [..._queue];
    _queue.clear();
    final writing = _write(batch);
    _writing = writing;
    try {
      await writing;
    } finally {
      _writing = null;
    }
  }

  Future<void> _write(List<LogEntry> batch) async {
    try {
      await _db.insertAll(batch);
      _failures = 0;
    } on Object catch (error) {
      _queue.insertAll(0, batch);
      _failures++;
      _timer?.cancel();
      _timer = Timer(_delay, () => unawaited(flush()));
      developer.log('Log buffer write failed: $error', name: 'memox.logging');
    }
  }

  void dispose() => _timer?.cancel();
}
