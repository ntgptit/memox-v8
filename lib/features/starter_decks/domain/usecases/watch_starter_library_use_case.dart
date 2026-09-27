import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

/// UC-STARTER-001 steps 4-5: the templates bundled with the app, each with
/// whether it is already in the library, again after every change.
final class WatchStarterLibraryUseCase {
  const WatchStarterLibraryUseCase(this._library);

  final StarterLibraryRepository _library;

  Stream<List<StarterLibraryEntry>> call() => _library.watchLibrary();
}
