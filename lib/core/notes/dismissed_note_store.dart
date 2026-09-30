import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// The notes dismissed on this device (`dismissed_note`, never synced).
class DismissedNoteStore {
  DismissedNoteStore(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// The keys dismissed so far, re-read whenever one is added.
  Stream<Set<String>> watchDismissed() => _db
      .select(_db.dismissedNote)
      .watch()
      .map((rows) => {for (final row in rows) row.noteKey});

  /// Hides [key] from now on; dismissing it again changes nothing.
  Future<void> dismiss(String key) => _db
      .into(_db.dismissedNote)
      .insert(
        DismissedNoteCompanion.insert(
          noteKey: key,
          dismissedAt: _now().toUtc(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
}
