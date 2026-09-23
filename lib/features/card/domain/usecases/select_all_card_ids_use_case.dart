import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-CARD-012: Select all takes every card the list's query lets through,
/// not only the rows loaded on screen.
final class SelectAllCardIdsUseCase {
  const SelectAllCardIdsUseCase(this._cards, this._clock);

  final CardRepository _cards;
  final DayClock _clock;

  Future<Set<String>> call({
    required String deckId,
    required CardListQuery query,
  }) => _cards.cardIdsMatching(deckId: deckId, query: query, now: _clock.now());
}
