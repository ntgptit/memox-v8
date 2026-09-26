import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// BR-TRASH-009: how long a batch stays in the Trash.
const trashRetention = Duration(hours: 720);

/// The latest time a batch may have been deleted at and be expired at
/// [now]: a batch deleted at the cutoff has expired (BR-TRASH-009).
DateTime trashCutoff(DateTime now) => now.subtract(trashRetention);

/// One row of the Trash: a batch, by the item the person deleted
/// (UC-TRASH-001 steps 3-4).
sealed class TrashEntry {
  const TrashEntry({
    required this.batchId,
    required this.deletedAt,
    required this.origin,
  });

  final String batchId;
  final DateTime deletedAt;

  /// The decks the item was in, root first; empty for a root deck. It is
  /// information only: a restore asks for its target (BR-TRASH-012).
  final List<DeckPathEntry> origin;

  /// When the auto-purge takes the batch (BR-TRASH-009).
  DateTime get expiresAt => deletedAt.add(trashRetention);
}

/// A deck the person deleted, with the decks and cards of its batch.
final class TrashDeckEntry extends TrashEntry {
  const TrashDeckEntry({
    required super.batchId,
    required super.deletedAt,
    required super.origin,
    required this.deckId,
    required this.name,
    required this.isRoot,
    required this.subDeckCount,
    required this.cardCount,
  });

  final String deckId;
  final String name;

  /// A root goes back to the top level only (BR-TRASH-006).
  final bool isRoot;

  /// The decks of the batch other than [deckId], and its cards: an older
  /// tombstone inside is an entry of its own (BR-TRASH-003).
  final int subDeckCount;
  final int cardCount;
}

/// A card the person deleted.
final class TrashCardEntry extends TrashEntry {
  const TrashCardEntry({
    required super.batchId,
    required super.deletedAt,
    required super.origin,
    required this.cardId,
    required this.front,
    required this.back,
  });

  final String cardId;
  final String front;
  final String back;
}
