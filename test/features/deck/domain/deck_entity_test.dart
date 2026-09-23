import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
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
  });

  group('checkCreateSubDeck', () {
    test('depth 10 is the deepest a sub-deck may be created at', () {
      final result = DeckEntity.checkCreateSubDeck(parentDepth: 10);
      expect(_reasonOf(result), DeckRejection.depthExceeded);
    });
    test('depth 9 may still get a child at depth 10', () {
      expect(DeckEntity.checkCreateSubDeck(parentDepth: 9), isA<_Allowed>());
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
    }) => DeckEntity.checkMove(
      movingId: movingId,
      targetParentId: targetParentId,
      targetAncestorIds: targetAncestorIds,
      targetDepth: targetDepth,
      subtreeHeight: subtreeHeight,
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

    test('a same-root, in-depth move is accepted', () {
      expect(move(), isA<_Allowed>());
    });
  });
}
