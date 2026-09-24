import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001: a window of a deck's cards and the filter counts, again on
/// every change and at every local midnight, when cards fall due with no
/// write (BR-STUDY-068).
final class WatchCardListUseCase {
  const WatchCardListUseCase(this._cards, this._clock);

  final CardRepository _cards;
  final DayClock _clock;

  Stream<CardListView> call({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
  }) => watchEachLocalDay(
    _clock,
    (now) => _cards.watchCardList(
      deckId: deckId,
      query: query,
      windowSize: windowSize,
      now: now,
    ),
  );
}
