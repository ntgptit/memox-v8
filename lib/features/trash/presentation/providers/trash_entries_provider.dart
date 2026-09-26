import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/providers/watch_trash_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_entries_provider.g.dart';

/// What is in the Trash, newest first (UC-TRASH-001 steps 3-4). A restore
/// or a purge drops its rows here in place.
@riverpod
Stream<List<TrashEntry>> trashEntries(Ref ref) =>
    ref.watch(watchTrashUseCaseProvider)();
