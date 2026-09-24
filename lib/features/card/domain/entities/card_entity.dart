import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

final class CardEntity {
  const CardEntity({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.isFlagged,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final bool isFlagged;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// BR-CARD-010: where a batch of cards may go. [sourceDeckIds] are the
  /// decks the cards sit in, [sourceRootIds] the roots of those decks. A
  /// move never crosses roots, even between two roots that happen to run the
  /// same scheduler at the same generation.
  static Outcome<void, CardRejection> checkMove({
    required String targetDeckId,
    required String targetRootId,
    required bool targetIsRoot,
    required DeckContentType targetContentType,
    required Set<String> sourceDeckIds,
    required Set<String> sourceRootIds,
  }) {
    if (targetIsRoot) return const Rejected(CardRejection.targetIsRoot);
    if (targetContentType == DeckContentType.deck) {
      return const Rejected(CardRejection.targetHoldsDecks);
    }
    if (sourceDeckIds.contains(targetDeckId)) {
      return const Rejected(CardRejection.sameDeck);
    }
    if (sourceRootIds.any((rootId) => rootId != targetRootId)) {
      return const Rejected(CardRejection.crossRootMove);
    }
    return const Ok(null);
  }
}
