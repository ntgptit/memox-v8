import 'dart:developer' as developer;

import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/sync/sync_failure.dart';

/// Pushes the log buffer to Supabase, oldest first, [batch] at a time, and
/// deletes what the server accepted (spec §3). A network error leaves every
/// row and propagates, so its scheduler backs off. A call the server refuses
/// whole (too large, a value it cannot store) is halved until the refused row
/// is alone. That row is dropped only when the row after it goes through,
/// which proves the fault is the row's: a failing RPC refuses both, and then
/// the error propagates and every row stays, however often the scheduler
/// retries. It never logs through the logger: a failed push would otherwise
/// feed the buffer it is emptying.
final class LogShipper {
  LogShipper(this._db, this._api, {this.batch = 500});

  final LogDatabase _db;
  final LogApi _api;
  final int batch;

  Future<void> runOnce() async {
    var size = batch;
    while (true) {
      final entries = await _db.oldest(size);
      if (entries.isEmpty) return;
      final Set<String> accepted;
      try {
        accepted = await _api.push(entries);
      } on Object catch (error) {
        if (classifySyncFailure(error) != SyncFailureKind.server) rethrow;
        if (entries.length > 1) {
          size = (entries.length + 1) ~/ 2;
          continue;
        }
        if (!await _dropIfProven(entries.single, error)) rethrow;
        continue;
      }
      await _db.deleteIds(accepted);
      // A short batch was the last; a partial acceptance would resend the
      // same rows, so it waits for the next run.
      if (entries.length < size || accepted.length < entries.length) return;
    }
  }

  /// Pushes the row after [refused]; when it goes through, [refused] was the
  /// fault and is dropped. False when there is no next row, so nothing proves
  /// the RPC works. A failing probe propagates its own error.
  Future<bool> _dropIfProven(LogEntry refused, Object error) async {
    final next = await _db.oldest(2);
    if (next.length < 2) return false;
    await _db.deleteIds(await _api.push([next.last]));
    await _db.deleteIds({refused.id});
    developer.log(
      'Log row ${refused.id} refused by the server; dropped: $error',
      name: 'memox.logging',
    );
    return true;
  }
}
