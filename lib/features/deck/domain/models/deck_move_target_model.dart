import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck a move may pick (UC-DECK-005).
final class DeckMoveTarget {
  const DeckMoveTarget({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;

  /// The decks from the root down to this deck's parent; empty for a root.
  final List<DeckPathEntry> path;
}
