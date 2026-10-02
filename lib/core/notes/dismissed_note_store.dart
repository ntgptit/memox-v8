import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'dismissed_note_store.g.dart';

/// The notes dismissed on this device (`dismissed_note`, never synced;
/// `dismissed_note_queries.drift`).
@DriftAccessor(
  include: {'package:memox/core/database/queries/dismissed_note_queries.drift'},
)
class DismissedNoteStore extends DatabaseAccessor<AppDatabase>
    with _$DismissedNoteStoreMixin {
  DismissedNoteStore(super.attachedDatabase, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// The keys dismissed so far, re-read whenever one is added.
  Stream<Set<String>> watchDismissed() =>
      dismissedNoteKeys().watch().map((keys) => keys.toSet());

  /// Hides [key] from now on; dismissing it again changes nothing.
  Future<void> dismiss(String key) => insertDismissedNote(key, _now().toUtc());
}
