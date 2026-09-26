import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

/// A path as a person reads it, so two paths compare by their names.
String _shown(List<DeckPathEntry> path) =>
    [for (final step in path) step.name].join(' / ');

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  Future<void> trash(String deckId) => db.customStatement(
    "UPDATE deck SET delete_batch_id = 'batch' WHERE id = ?",
    [deckId],
  );

  group('watchDeck', () {
    test('gives the deck, the root scheduler, the lock, the options and the breadcrumb', () async {
      final root = await repo.root('Korean', SchedulerType.sm2);
      final branch = await repo.sub(root.id, 'Vocabulary');
      final leaf = await repo.sub(branch.id, 'Academic words');

      final view = (await repo.watchDeck(leaf.id).first)!;

      expect(view.deck.name, 'Academic words');
      expect(
        (view.schedulerType, view.isSchedulerLocked),
        (SchedulerType.sm2, false),
      );
      expect(view.createOptions, {
        DeckCreateOption.deck,
        DeckCreateOption.card,
      });
      expect(_shown(view.breadcrumb), 'Korean / Vocabulary');
      expect((await repo.watchDeck(root.id).first)!.breadcrumb, isEmpty);
    });

    test(
      'the scheduler is locked once the root has an answer (BR-SRS-003)',
      () async {
        final root = await repo.root('Korean');
        final leaf = await repo.sub(root.id, 'Nouns');
        final views = <DeckView?>[];
        final subscription = repo.watchDeck(leaf.id).listen(views.add);
        await pumpEventQueue();

        await db.customUpdate(
          'UPDATE deck SET first_answered_at = 1 WHERE id = ?',
          variables: [Variable<String>(root.id)],
          updates: {db.deck},
        );
        await pumpEventQueue();

        expect(
          [for (final view in views) view!.isSchedulerLocked],
          [false, true],
        );
        await subscription.cancel();
      },
    );

    test('emits null once the deck is gone or in the Trash', () async {
      final root = await repo.root('Korean');
      final leaf = await repo.sub(root.id, 'Nouns');
      final other = await repo.sub(root.id, 'Verbs');
      final views = <DeckView?>[];
      final subscription = repo.watchDeck(leaf.id).listen(views.add);
      await pumpEventQueue();

      await repo.deleteDeck(deckId: leaf.id);
      await pumpEventQueue();
      await trash(other.id);

      expect(views.last, isNull);
      expect(await repo.watchDeck(other.id).first, isNull);
      await subscription.cancel();
    });
  });

  group('watchMoveTargets (UC-DECK-005)', () {
    test(
      'offers every deck the move rules allow, with its path, in tree order',
      () async {
        final korean = await repo.root('Korean');
        final grammar = await repo.sub(korean.id, 'Grammar');
        final moving = await repo.sub(grammar.id, 'Particles');
        await repo.sub(moving.id, 'Inside the moving deck');
        await repo.sub(korean.id, 'Vocabulary');
        final cards = await repo.sub(korean.id, 'Holds cards');
        await insertCard(db, id: 'c', deckId: cards.id);
        final japanese = await repo.root('Japanese');
        await repo.sub(japanese.id, 'Kana');
        final sm2 = await repo.root('Spanish', SchedulerType.sm2);
        await repo.sub(sm2.id, 'Verbs');

        final targets = await repo.watchMoveTargets(moving.id).first;

        expect(
          [for (final target in targets) (target.name, _shown(target.path))],
          [
            ('Korean', ''),
            ('Vocabulary', 'Korean'),
            ('Japanese', ''),
            ('Kana', 'Japanese'),
          ],
        );
      },
    );

    test('leaves out a root of another generation and a target too deep for the subtree', () async {
      final korean = await repo.root('Korean');
      final moving = await repo.sub(korean.id, 'Moving');
      await repo.sub(moving.id, 'Child');
      var deep = await repo.root('Deep');
      for (var level = 2; level <= 9; level++) {
        deep = await repo.sub(deep.id, 'Level $level');
      }
      final reset = await repo.root('Reset');
      await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
        reset.id,
      ]);

      final targets = await repo.watchMoveTargets(moving.id).first;

      final names = [for (final target in targets) target.name];
      expect(names, contains('Level 8'), reason: 'depth 8 + height 2 = 10');
      expect(
        names,
        isNot(contains('Level 9')),
        reason: 'depth 9 + height 2 = 11',
      );
      expect(names, isNot(contains('Reset')));
    });

    test(
      'a root deck, a missing deck and a deck in the Trash have no target',
      () async {
        final korean = await repo.root('Korean');
        final leaf = await repo.sub(korean.id, 'Nouns');
        await repo.root('Japanese');
        await trash(leaf.id);

        expect(await repo.watchMoveTargets(korean.id).first, isEmpty);
        expect(await repo.watchMoveTargets('missing').first, isEmpty);
        expect(await repo.watchMoveTargets(leaf.id).first, isEmpty);
      },
    );
  });

  test('a target carries the deck id', () async {
    final korean = await repo.root('Korean');
    final moving = await repo.sub(korean.id, 'Moving');
    final other = await repo.sub(korean.id, 'Other');

    final List<DeckMoveTarget> targets = await repo
        .watchMoveTargets(moving.id)
        .first;

    expect([for (final target in targets) target.id], [other.id]);
  });
}
