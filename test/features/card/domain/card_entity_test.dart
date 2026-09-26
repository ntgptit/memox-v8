import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

void main() {
  group('checkMove (BR-CARD-010)', () {
    Outcome<void, CardRejection> check({
      bool targetIsRoot = false,
      DeckContentType targetContentType = DeckContentType.unset,
      Set<String> sourceDeckIds = const {'source'},
      Set<String> sourceRootIds = const {'root'},
    }) => CardEntity.checkMove(
      targetDeckId: 'target',
      targetRootId: 'root',
      targetIsRoot: targetIsRoot,
      targetContentType: targetContentType,
      sourceDeckIds: sourceDeckIds,
      sourceRootIds: sourceRootIds,
    );

    CardRejection reasonOf(Outcome<void, CardRejection> result) =>
        (result as Rejected<void, CardRejection>).reason;

    test(
      'a sub-deck of the same root holding cards or nothing takes the cards',
      () {
        expect(check(), isA<Ok<void, CardRejection>>());
        expect(
          check(targetContentType: DeckContentType.card),
          isA<Ok<void, CardRejection>>(),
        );
      },
    );

    test('a root or a deck of decks is refused', () {
      expect(
        reasonOf(
          check(targetIsRoot: true, targetContentType: DeckContentType.deck),
        ),
        CardRejection.targetIsRoot,
      );
      expect(
        reasonOf(check(targetContentType: DeckContentType.deck)),
        CardRejection.targetHoldsDecks,
      );
    });

    test('a card already in the target is refused', () {
      expect(
        reasonOf(check(sourceDeckIds: {'source', 'target'})),
        CardRejection.sameDeck,
      );
    });

    test('a card of another root is refused, whatever the schedulers', () {
      expect(
        reasonOf(check(sourceRootIds: {'root', 'twin'})),
        CardRejection.crossRootMove,
      );
    });
  });

  group('checkTarget (BR-CARD-010, BR-TRASH-006)', () {
    Outcome<void, CardRejection> check({
      bool targetIsRoot = false,
      DeckContentType targetContentType = DeckContentType.unset,
      Set<String> sourceRootIds = const {'root'},
    }) => CardEntity.checkTarget(
      targetRootId: 'root',
      targetIsRoot: targetIsRoot,
      targetContentType: targetContentType,
      sourceRootIds: sourceRootIds,
    );

    CardRejection reasonOf(Outcome<void, CardRejection> result) =>
        (result as Rejected<void, CardRejection>).reason;

    test(
      'a sub-deck of the cards\' root holding cards or nothing takes them',
      () {
        expect(check(), isA<Ok<void, CardRejection>>());
        expect(
          check(targetContentType: DeckContentType.card),
          isA<Ok<void, CardRejection>>(),
        );
      },
    );

    test('a root, a deck of decks and a deck of another root are refused', () {
      expect(reasonOf(check(targetIsRoot: true)), CardRejection.targetIsRoot);
      expect(
        reasonOf(check(targetContentType: DeckContentType.deck)),
        CardRejection.targetHoldsDecks,
      );
      expect(
        reasonOf(check(sourceRootIds: {'root', 'twin'})),
        CardRejection.crossRootMove,
      );
    });
  });
}
