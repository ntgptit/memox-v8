import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck the cards of a selection may move to (UC-CARD-001 A5, BR-CARD-010).
final class CardMoveTarget {
  const CardMoveTarget({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;

  /// The decks from the root down to this deck's parent, so two decks of the
  /// same name tell apart (BR-DECK-021).
  final List<DeckPathEntry> path;
}
