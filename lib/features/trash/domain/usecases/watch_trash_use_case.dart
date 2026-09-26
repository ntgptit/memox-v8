import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// UC-TRASH-001 steps 3-4: the Trash, newest first, again after every
/// change. It purges nothing: the screen calls `PurgeExpiredTrashUseCase`
/// first (trash spec D13).
final class WatchTrashUseCase {
  const WatchTrashUseCase(this._trash);

  final TrashRepository _trash;

  Stream<List<TrashEntry>> call() => _trash.watchEntries();
}
