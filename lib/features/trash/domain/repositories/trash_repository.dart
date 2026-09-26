import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';

/// The Trash as its own screen reads and purges it (UC-TRASH-001). Deleting,
/// restoring and undoing belong to the owner of each item: `deck` and
/// `card` (trash spec D2).
abstract interface class TrashRepository {
  /// UC-TRASH-001 steps 3-4: every batch as an entry, newest first, again
  /// after every write to the batches, the decks or the cards. Reading purges
  /// nothing (trash spec D13).
  Stream<List<TrashEntry>> watchEntries();

  /// UC-TRASH-001 A3: [batchIds] and every expired batch go for good, oldest
  /// first, in one transaction; a batch that still holds rows of another is
  /// skipped whole (BR-TRASH-010).
  Future<PurgeReport> purge({
    required Set<String> batchIds,
    required DateTime now,
  });

  /// UC-TRASH-001 step 3 and A4: every batch deleted at or before
  /// `trashCutoff(now)` goes for good (BR-TRASH-009).
  Future<PurgeReport> purgeExpired({required DateTime now});
}
