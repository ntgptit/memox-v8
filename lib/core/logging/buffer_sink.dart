import 'dart:async';
import 'dart:developer' as developer;

import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_config.dart';
import 'package:memox/core/logging/log_entry.dart';

/// Queues entries in memory and writes them to the log buffer in batches:
/// every [flushEvery], at [flushAt] entries, or on [flush] (spec §3). A failed
/// write keeps the batch for the next one and never logs itself.
final class BufferSink implements LogSink {
  BufferSink(
    this._db, {
    this.flushEvery = const Duration(seconds: 2),
    this.flushAt = 50,
    this.maxQueued = 5000,
    this.config = const LogConfig(),
  });

  final LogDatabase _db;
  final Duration flushEvery;
  final int flushAt;

  /// While the store keeps failing, the queue stops growing here; the oldest
  /// entries go first.
  final int maxQueued;
  final LogConfig config;

  final _queue = <LogEntry>[];
  Timer? _timer;
  Future<void>? _writing;

  @override
  void write(LogEntry entry) {
    if (entry.level.index < config.persistMinLevel.index) return;
    _queue.add(entry);
    if (_queue.length > maxQueued) {
      _queue.removeRange(0, _queue.length - maxQueued);
    }
    if (_queue.length >= flushAt) {
      unawaited(flush());
      return;
    }
    _timer ??= Timer(flushEvery, () => unawaited(flush()));
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
    } on Object catch (error) {
      _queue.insertAll(0, batch);
      developer.log('Log buffer write failed: $error', name: 'memox.logging');
    }
  }

  void dispose() => _timer?.cancel();
}
