import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck whose name holds the search term (IT-DISC-006).
final class DeckSearchHit {
  const DeckSearchHit({
    required this.id,
    required this.name,
    required this.path,
    required this.contentType,
  });

  final String id;
  final String name;

  /// The decks from the root down to this deck's parent, so two decks of the
  /// same name tell apart; empty for a root.
  final List<DeckPathEntry> path;

  /// What the deck holds, so a hit can say it (screen 04).
  final DeckContentType contentType;
}
