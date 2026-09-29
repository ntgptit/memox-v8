import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_api.dart';

/// Pushes the log buffer to Supabase, oldest first, [batch] at a time, and
/// deletes what the server accepted (spec §3). An error leaves every row and
/// propagates, so its scheduler backs off. It never logs through the logger:
/// a failed push would otherwise feed the buffer it is emptying.
final class LogShipper {
  LogShipper(this._db, this._api, {this.batch = 500});

  final LogDatabase _db;
  final LogApi _api;
  final int batch;

  Future<void> runOnce() async {
    while (true) {
      final entries = await _db.oldest(batch);
      if (entries.isEmpty) return;
      final accepted = await _api.push(entries);
      await _db.deleteIds(accepted);
      // A short batch was the last; a partial acceptance would resend the
      // same rows, so it waits for the next run.
      if (entries.length < batch || accepted.length < entries.length) return;
    }
  }
}
