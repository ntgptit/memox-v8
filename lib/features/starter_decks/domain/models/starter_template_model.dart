import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A starter template (BR-STARTER-001, BR-STARTER-002): content bundled with
/// the app that becomes the person's own deck tree only when they add it.
final class StarterTemplate {
  const StarterTemplate({
    required this.templateId,
    required this.version,
    required this.locale,
    required this.title,
    required this.contentSource,
    required this.frontLanguage,
    required this.backLanguage,
    required this.suggestedScheduler,
    required this.decks,
  });

  /// Stable across app versions (BR-STARTER-002).
  final String templateId;

  /// Grows when the content changes; a copy records the one it was made from
  /// (BR-STARTER-004).
  final int version;

  /// The language of the template's own text: its title and deck names.
  final String locale;

  /// The name the copy's root takes.
  final String title;

  /// Where the content comes from; the fixtures say "Development fixture"
  /// (BR-STARTER-010).
  final String contentSource;

  /// BCP 47 tags of the two sides of every card.
  final String frontLanguage;
  final String backLanguage;

  /// Only a suggestion: the person picks the scheduler (BR-STARTER-004).
  final SchedulerType suggestedScheduler;

  /// The root's sub-decks, in order.
  final List<StarterDeck> decks;

  /// Every card of the tree.
  int get cardCount => decks.fold(0, (sum, deck) => sum + deck.cardCount);

  /// Every deck under the root.
  int get subDeckCount => decks.fold(0, (sum, deck) => sum + deck.deckCount);
}

/// A deck of a template: it holds sub-decks or cards, never both (spec D6).
final class StarterDeck {
  const StarterDeck({
    required this.name,
    this.decks = const [],
    this.cards = const [],
  });

  final String name;
  final List<StarterDeck> decks;
  final List<StarterCard> cards;

  /// The cards of this deck and of every deck under it.
  int get cardCount =>
      cards.length + decks.fold(0, (sum, deck) => sum + deck.cardCount);

  /// This deck and every deck under it.
  int get deckCount => 1 + decks.fold(0, (sum, deck) => sum + deck.deckCount);
}

/// A card of a template; it passes the card rules (BR-CARD-001…BR-CARD-003).
final class StarterCard {
  const StarterCard({
    required this.front,
    required this.back,
    this.example,
    this.hint,
    this.pronunciation,
  });

  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;
}
