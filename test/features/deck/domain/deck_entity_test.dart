import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

typedef _Check = Outcome<void, DeckRejection>;
typedef _Refused = Rejected<void, DeckRejection>;
typedef _Allowed = Ok<void, DeckRejection>;

DeckRejection _reasonOf(_Check result) => (result as _Refused).reason;

void main() {
  group('checkName', () {
    test('blank or whitespace-only name is rejected', () {
      expect(DeckEntity.checkName('   '), isA<_Refused>());
      expect(_reasonOf(DeckEntity.checkName('   ')), DeckRejection.blankName);
    });
    test('a real name is accepted', () {
      expect(DeckEntity.checkName('Korean 101'), isA<_Allowed>());
    });
    test('200 characters is the longest name (BR-DECK-020)', () {
      expect(DeckEntity.checkName('a' * 200), isA<_Allowed>());
      expect(
        _reasonOf(DeckEntity.checkName('a' * 201)),
        DeckRejection.nameTooLong,
      );
    });
    test('a character is what a person sees, not a code unit', () {
      // e + combining acute accent: one character, two code units.
      expect(DeckEntity.checkName('e\u0301' * 200), isA<_Allowed>());
      expect(
        _reasonOf(DeckEntity.checkName('e\u0301' * 201)),
        DeckRejection.nameTooLong,
      );
    });
    test('spaces around the name do not count', () {
      expect(DeckEntity.checkName(' ${'a' * 200} '), isA<_Allowed>());
    });
  });

  group('checkCreateSubDeck', () {
    test('depth 10 is the deepest a sub-deck may be created at', () {
      final result = DeckEntity.checkCreateSubDeck(
        parentDepth: 10,
        parentContentType: DeckContentType.deck,
      );
      expect(_reasonOf(result), DeckRejection.depthExceeded);
    });
    test('depth 9 may still get a child at depth 10', () {
      expect(
        DeckEntity.checkCreateSubDeck(
          parentDepth: 9,
          parentContentType: DeckContentType.deck,
        ),
        isA<_Allowed>(),
      );
    });
    test('a deck that holds cards refuses a sub-deck (BR-DECK-009)', () {
      final result = DeckEntity.checkCreateSubDeck(
        parentDepth: 2,
        parentContentType: DeckContentType.card,
      );
      expect(_reasonOf(result), DeckRejection.notADeckContainer);
    });
    test('an unset deck accepts a sub-deck', () {
      expect(
        DeckEntity.checkCreateSubDeck(
          parentDepth: 2,
          parentContentType: DeckContentType.unset,
        ),
        isA<_Allowed>(),
      );
    });
  });

  group('checkCreateCard', () {
    test('a parent already holding sub-decks refuses a card', () {
      final result = DeckEntity.checkCreateCard(
        parentContentType: DeckContentType.deck,
      );
      expect(_reasonOf(result), DeckRejection.notACardContainer);
    });
    test('unset or card-typed parent accepts a card', () {
      expect(
        DeckEntity.checkCreateCard(parentContentType: DeckContentType.unset),
        isA<_Allowed>(),
      );
      expect(
        DeckEntity.checkCreateCard(parentContentType: DeckContentType.card),
        isA<_Allowed>(),
      );
    });
  });

  group('checkMove', () {
    _Check move({
      String movingId = 'a',
      String targetParentId = 'b',
      List<String> targetAncestorIds = const ['b'],
      int targetDepth = 2,
      int subtreeHeight = 1,
      SchedulerType targetRootScheduler = SchedulerType.eightBox,
      int targetRootGeneration = 1,
      DeckContentType targetContentType = DeckContentType.deck,
    }) => DeckEntity.checkMove(
      movingId: movingId,
      targetParentId: targetParentId,
      targetAncestorIds: targetAncestorIds,
      targetDepth: targetDepth,
      subtreeHeight: subtreeHeight,
      targetContentType: targetContentType,
      movingRootScheduler: SchedulerType.eightBox,
      movingRootGeneration: 1,
      targetRootScheduler: targetRootScheduler,
      targetRootGeneration: targetRootGeneration,
    );

    // A root deck cannot move (`DeckRejection.rootCannotMove`): only the
    // repository knows a deck has no parent, so Task 7 asserts it there.

    test('moving a deck into its own descendant is rejected', () {
      final result = move(targetAncestorIds: const ['b', 'a'], targetDepth: 3);
      expect(_reasonOf(result), DeckRejection.movingIntoOwnSubtree);
    });

    test('moving onto itself is rejected', () {
      final result = move(targetParentId: 'a', targetAncestorIds: const ['a']);
      expect(_reasonOf(result), DeckRejection.movingIntoOwnSubtree);
    });

    test('moving a subtree past depth 10 is rejected', () {
      final result = move(targetDepth: 9, subtreeHeight: 2);
      expect(_reasonOf(result), DeckRejection.depthExceeded);
    });

    test(
      'moving under a root with another scheduler or generation is blocked',
      () {
        expect(
          _reasonOf(move(targetRootScheduler: SchedulerType.sm2)),
          DeckRejection.subtreeSchedulerMismatch,
        );
        expect(
          _reasonOf(move(targetRootGeneration: 2)),
          DeckRejection.subtreeSchedulerMismatch,
        );
      },
    );

    test('moving under a deck that holds cards is rejected (BR-DECK-009)', () {
      expect(
        _reasonOf(move(targetContentType: DeckContentType.card)),
        DeckRejection.notADeckContainer,
      );
    });

    test('a same-root, in-depth move is accepted', () {
      expect(move(), isA<_Allowed>());
    });
  });

  group('reorder (BR-SRS-007)', () {
    test('places the deck before or after its anchor', () {
      expect(
        DeckEntity.reorder(
          ['a', 'b', 'c'],
          movingId: 'c',
          anchorId: 'a',
          placement: DeckPlacement.before,
        ),
        ['c', 'a', 'b'],
      );
      expect(
        DeckEntity.reorder(
          ['a', 'b', 'c'],
          movingId: 'a',
          anchorId: 'c',
          placement: DeckPlacement.after,
        ),
        ['b', 'c', 'a'],
      );
    });

    test('a deck anchored on itself keeps the order', () {
      expect(
        DeckEntity.reorder(
          ['a', 'b'],
          movingId: 'a',
          anchorId: 'a',
          placement: DeckPlacement.after,
        ),
        ['a', 'b'],
      );
    });
  });

  group('createOptions (BR-DECK-005, BR-DECK-007, BR-DECK-012)', () {
    DeckEntity deck(DeckContentType type, {int depth = 2}) => DeckEntity(
      id: 'd',
      name: 'd',
      parentId: depth == 1 ? null : 'p',
      rootId: 'r',
      depth: depth,
      contentType: type,
      schedulerType: null,
      generation: null,
      firstAnsweredAt: null,
      siblingPosition: 0,
      createdAt: DateTime(2026, 9, 23),
      updatedAt: DateTime(2026, 9, 23),
    );

    test('a root and a deck of decks offer a deck, a deck of cards a card', () {
      expect(deck(DeckContentType.deck, depth: 1).createOptions, {
        DeckCreateOption.deck,
      });
      expect(deck(DeckContentType.deck).createOptions, {DeckCreateOption.deck});
      expect(deck(DeckContentType.card).createOptions, {DeckCreateOption.card});
    });

    test('an empty sub-deck offers both', () {
      expect(deck(DeckContentType.unset).createOptions, {
        DeckCreateOption.deck,
        DeckCreateOption.card,
      });
    });

    test('the deepest level offers no deck (BR-DECK-001)', () {
      expect(
        deck(DeckContentType.unset, depth: DeckEntity.maxDepth).createOptions,
        {DeckCreateOption.card},
      );
    });
  });
}
