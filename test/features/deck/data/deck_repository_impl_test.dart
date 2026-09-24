import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test(
    'createRootDeck stores content_type deck, generation 1, own root_id',
    () async {
      final result = await repo.createRootDeck(
        name: 'Korean',
        schedulerType: SchedulerType.eightBox,
      );
      final deck = (result as Ok<DeckEntity, DeckRejection>).value;
      expect(deck.contentType, DeckContentType.deck);
      expect(deck.generation, 1);
      expect(deck.rootId, deck.id);
      expect(deck.depth, 1);
    },
  );

  test('createRootDeck rejects a blank name and writes nothing', () async {
    final result = await repo.createRootDeck(
      name: '   ',
      schedulerType: SchedulerType.eightBox,
    );
    expect(
      (result as Rejected<DeckEntity, DeckRejection>).reason,
      DeckRejection.blankName,
    );
    final count = await db
        .customSelect('SELECT COUNT(*) AS n FROM deck')
        .getSingle();
    expect(count.read<int>('n'), 0);
  });

  test('createSubDeck on a fresh root sets content_type unset', () async {
    final root = ((await repo.createRootDeck(
      name: 'r',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final sub = ((await repo.createSubDeck(
      parentId: root.id,
      name: 's',
    )) as Ok<DeckEntity, DeckRejection>).value;
    expect(sub.contentType, DeckContentType.unset);
    expect(sub.rootId, root.id);
    expect(sub.depth, 2);
  });

  test('creating a deck at depth 10 is rejected before any write', () async {
    var parentId = ((await repo.createRootDeck(
      name: 'r',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value.id;
    for (var d = 2; d <= 10; d++) {
      parentId = ((await repo.createSubDeck(
        parentId: parentId,
        name: 'd$d',
      )) as Ok<DeckEntity, DeckRejection>).value.id;
    }
    final r = await repo.createSubDeck(parentId: parentId, name: 'too deep');
    expect(
      (r as Rejected<DeckEntity, DeckRejection>).reason,
      DeckRejection.depthExceeded,
    );
  });

  test(
    'emptying a sub-deck resets content_type to unset in the same transaction',
    () async {
      final root = ((await repo.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final sub = ((await repo.createSubDeck(
        parentId: root.id,
        name: 's',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await repo.createSubDeck(
        parentId: sub.id,
        name: 'l',
      )) as Ok<DeckEntity, DeckRejection>).value;

      await repo.deleteDeck(deckId: leaf.id);

      final refreshed = await repo.findById(sub.id);
      expect(refreshed!.contentType, DeckContentType.unset);
    },
  );

  test(
    'moving a deck onto its own descendant is rejected and changes nothing',
    () async {
      final root = ((await repo.createRootDeck(
        name: 'r',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final a = ((await repo.createSubDeck(
        parentId: root.id,
        name: 'a',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final b = ((await repo.createSubDeck(
        parentId: a.id,
        name: 'b',
      )) as Ok<DeckEntity, DeckRejection>).value;

      final result = await repo.moveDeck(deckId: a.id, newParentId: b.id);
      expect(
        (result as Rejected<void, DeckRejection>).reason,
        DeckRejection.movingIntoOwnSubtree,
      );
      expect((await repo.findById(a.id))!.parentId, root.id);
    },
  );

  test(
    'moving a subtree updates root_id and depth for every descendant',
    () async {
      final rootA = ((await repo.createRootDeck(
        name: 'a',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final rootB = ((await repo.createRootDeck(
        name: 'b',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final branch = ((await repo.createSubDeck(
        parentId: rootA.id,
        name: 'branch',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final leaf = ((await repo.createSubDeck(
        parentId: branch.id,
        name: 'leaf',
      )) as Ok<DeckEntity, DeckRejection>).value;

      final result = await repo.moveDeck(
        deckId: branch.id,
        newParentId: rootB.id,
      );
      expect(result, isA<Ok<void, DeckRejection>>());

      final movedBranch = await repo.findById(branch.id);
      final movedLeaf = await repo.findById(leaf.id);
      expect(movedBranch!.rootId, rootB.id);
      expect(movedBranch.depth, 2);
      expect(movedLeaf!.rootId, rootB.id);
      expect(movedLeaf.depth, 3);
    },
  );

  test(
    'moving a subtree under a root with a different scheduler is blocked',
    () async {
      final rootA = ((await repo.createRootDeck(
        name: 'a',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final rootB = ((await repo.createRootDeck(
        name: 'b',
        schedulerType: SchedulerType.sm2,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final branch = ((await repo.createSubDeck(
        parentId: rootA.id,
        name: 'branch',
      )) as Ok<DeckEntity, DeckRejection>).value;

      final result = await repo.moveDeck(
        deckId: branch.id,
        newParentId: rootB.id,
      );
      expect(
        (result as Rejected<void, DeckRejection>).reason,
        DeckRejection.subtreeSchedulerMismatch,
      );
    },
  );

  test('a root deck cannot move', () async {
    final rootA = ((await repo.createRootDeck(
      name: 'a',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(
      name: 'b',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;

    final result = await repo.moveDeck(deckId: rootA.id, newParentId: rootB.id);
    expect(
      (result as Rejected<void, DeckRejection>).reason,
      DeckRejection.rootCannotMove,
    );
  });

  test(
    'a new deck goes to the end of its sibling group (BR-SRS-007)',
    () async {
      final rootA = ((await repo.createRootDeck(
        name: 'a',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final rootB = ((await repo.createRootDeck(
        name: 'b',
        schedulerType: SchedulerType.eightBox,
      )) as Ok<DeckEntity, DeckRejection>).value;
      final first = ((await repo.createSubDeck(
        parentId: rootA.id,
        name: 'first',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final second = ((await repo.createSubDeck(
        parentId: rootA.id,
        name: 'second',
      )) as Ok<DeckEntity, DeckRejection>).value;
      await repo.deleteDeck(deckId: first.id);
      final third = ((await repo.createSubDeck(
        parentId: rootA.id,
        name: 'third',
      )) as Ok<DeckEntity, DeckRejection>).value;
      final onlyUnderB = ((await repo.createSubDeck(
        parentId: rootB.id,
        name: 'only',
      )) as Ok<DeckEntity, DeckRejection>).value;

      expect(
        [rootA.siblingPosition, rootB.siblingPosition],
        [0, 1],
        reason: 'roots share the NULL-parent group',
      );
      expect([first.siblingPosition, second.siblingPosition], [0, 1]);
      expect(
        third.siblingPosition,
        2,
        reason:
            'the end is the largest position plus one, not the sibling count',
      );
      expect(
        onlyUnderB.siblingPosition,
        0,
        reason: 'each parent numbers its own group',
      );
    },
  );

  test('a moved deck goes to the end of its new sibling group', () async {
    final rootA = ((await repo.createRootDeck(
      name: 'a',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final rootB = ((await repo.createRootDeck(
      name: 'b',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final branch = ((await repo.createSubDeck(
      parentId: rootA.id,
      name: 'branch',
    )) as Ok<DeckEntity, DeckRejection>).value;
    final gone = ((await repo.createSubDeck(
      parentId: rootB.id,
      name: 'gone',
    )) as Ok<DeckEntity, DeckRejection>).value;
    final kept = ((await repo.createSubDeck(
      parentId: rootB.id,
      name: 'kept',
    )) as Ok<DeckEntity, DeckRejection>).value;
    await repo.deleteDeck(deckId: gone.id);

    final result = await repo.moveDeck(
      deckId: branch.id,
      newParentId: rootB.id,
    );

    expect(result, isA<Ok<void, DeckRejection>>());
    expect(
      (await repo.findById(branch.id))!.siblingPosition,
      kept.siblingPosition + 1,
    );
  });

  // Rules the plan's prose sets for Task 7 without a test of their own.

  Future<DeckEntity> root(
    String name, [
    SchedulerType type = SchedulerType.eightBox,
  ]) async => ((await repo.createRootDeck(
    name: name,
    schedulerType: type,
  )) as Ok<DeckEntity, DeckRejection>).value;

  Future<DeckEntity> sub(String parentId, String name) async =>
      ((await repo.createSubDeck(
        parentId: parentId,
        name: name,
      )) as Ok<DeckEntity, DeckRejection>).value;

  Future<void> holdACard(String deckId) async {
    await db.customStatement(
      "UPDATE deck SET content_type = 'card' WHERE id = ?",
      [deckId],
    );
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('card', ?, 'f', 'b', 0, 0)",
      [deckId],
    );
  }

  test('createRootDeck stores the trimmed name, the scheduler code and its version', () async {
    final deck = await root('  Korean  ', SchedulerType.sm2);
    expect(deck.name, 'Korean');
    final row = await db
        .customSelect(
          'SELECT scheduler_type, scheduler_version FROM deck WHERE id = ?',
          variables: [Variable(deck.id)],
        )
        .getSingle();
    expect(row.read<String>('scheduler_type'), 'sm2');
    expect(row.read<int>('scheduler_version'), 1);
  });

  test('a sub-deck makes its unset parent a deck of decks (BR-DECK-006, BR-DECK-007)', () async {
    final r = await root('r');
    final branch = await sub(r.id, 'branch');
    await sub(branch.id, 'leaf');
    expect((await repo.findById(branch.id))!.contentType, DeckContentType.deck);
    expect(
      (await repo.findById(r.id))!.contentType,
      DeckContentType.deck,
      reason: 'a root stays a deck of decks',
    );
  });

  test('a deck that holds cards refuses a sub-deck (BR-DECK-009)', () async {
    final r = await root('r');
    final leaf = await sub(r.id, 'leaf');
    await holdACard(leaf.id);

    final result = await repo.createSubDeck(parentId: leaf.id, name: 'x');
    expect(
      (result as Rejected<DeckEntity, DeckRejection>).reason,
      DeckRejection.notADeckContainer,
    );
  });

  test(
    'a deck cannot move under a deck that holds cards (BR-DECK-009)',
    () async {
      final r = await root('r');
      final leaf = await sub(r.id, 'leaf');
      final other = await sub(r.id, 'other');
      await holdACard(leaf.id);

      final result = await repo.moveDeck(
        deckId: other.id,
        newParentId: leaf.id,
      );
      expect(
        (result as Rejected<void, DeckRejection>).reason,
        DeckRejection.notADeckContainer,
      );
      expect((await repo.findById(other.id))!.parentId, r.id);
    },
  );

  test('a move empties the old parent to unset and makes an unset target a deck of decks', () async {
    final r = await root('r');
    final from = await sub(r.id, 'from');
    final moving = await sub(from.id, 'moving');
    final to = await sub(r.id, 'to');

    expect(
      await repo.moveDeck(deckId: moving.id, newParentId: to.id),
      isA<Ok<void, DeckRejection>>(),
    );

    expect((await repo.findById(from.id))!.contentType, DeckContentType.unset);
    expect((await repo.findById(to.id))!.contentType, DeckContentType.deck);
  });

  test('a missing parent, deck or target answers notFound', () async {
    final r = await root('r');
    expect(
      ((await repo.createSubDeck(
        parentId: 'missing',
        name: 'x',
      )) as Rejected<DeckEntity, DeckRejection>).reason,
      DeckRejection.notFound,
    );
    expect(
      ((await repo.deleteDeck(
        deckId: 'missing',
      )) as Rejected<void, DeckRejection>).reason,
      DeckRejection.notFound,
    );
    expect(
      ((await repo.moveDeck(
        deckId: 'missing',
        newParentId: r.id,
      )) as Rejected<void, DeckRejection>).reason,
      DeckRejection.notFound,
    );
  });
}
