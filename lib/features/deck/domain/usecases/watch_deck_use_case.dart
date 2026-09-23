import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// An open deck: its content, Create options, scheduler lock and breadcrumb,
/// again on every change, and notFound once it is deleted.
final class WatchDeckUseCase {
  const WatchDeckUseCase(this._decks);

  final DeckRepository _decks;

  Stream<Outcome<DeckView, DeckRejection>> call({required String deckId}) =>
      _decks
          .watchDeck(deckId)
          .map<Outcome<DeckView, DeckRejection>>(
            (view) => switch (view) {
              final DeckView view => Ok(view),
              null => const Rejected(DeckRejection.notFound),
            },
          );
}
