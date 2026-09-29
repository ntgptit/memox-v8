import 'dart:developer' as developer;

import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/sync/sync_failure.dart';

/// Pushes the log buffer to Supabase, oldest first, [batch] at a time, and
/// deletes what the server accepted (spec §3). A network error leaves every
/// row and propagates, so its scheduler backs off. A call the server refuses
/// whole (too large, a value it cannot store) is halved until the refused row
/// is alone, and that row is dropped: one bad row must not hold back every
/// later log. A second refused row before any push succeeds means the RPC
/// itself is failing, so that error propagates and the rows stay. It never logs through the logger: a failed push would otherwise
/// feed the buffer it is emptying.
final class LogShipper {
  LogShipper(this._db, this._api, {this.batch = 500});

  final LogDatabase _db;
  final LogApi _api;
  final int batch;

  Future<void> runOnce() async {
    var size = batch;
    var droppedSinceSuccess = false;
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
        if (droppedSinceSuccess) rethrow;
        droppedSinceSuccess = true;
        developer.log(
          'Log row ${entries.single.id} refused by the server; dropped: $error',
          name: 'memox.logging',
        );
        await _db.deleteIds({entries.single.id});
        continue;
      }
      await _db.deleteIds(accepted);
      droppedSinceSuccess = false;
      // A short batch was the last; a partial acceptance would resend the
      // same rows, so it waits for the next run.
      if (entries.length < size || accepted.length < entries.length) return;
    }
  }
}
