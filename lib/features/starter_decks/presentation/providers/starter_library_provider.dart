import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/providers/watch_starter_library_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'starter_library_provider.g.dart';

/// Screen 03's templates, each with whether it is in the library
/// (UC-STARTER-001 steps 4-5). An add flips "In library" in place.
@riverpod
Stream<List<StarterLibraryEntry>> starterLibrary(Ref ref) =>
    ref.watch(watchStarterLibraryUseCaseProvider)();
