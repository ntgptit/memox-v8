import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late SelectCounter counter;
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late TagRepositoryImpl tags;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    DateTime now() => DateTime(2026, 9, 23);
    decks = DeckRepositoryImpl(db, now: now);
    tags = TagRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      tags,
      now: now,
    );
    root = await decks.root('Korean');
    leaf = await decks.sub(root.id, 'Nouns');
  });
  tearDown(() => db.close());

  /// A review_log row as the study flow writes it; [at] orders the history.
  Future<void> logAnswer(
    String cardId,
    String id,
    DateTime at, {
    int generation = 1,
  }) => db.customStatement(
    'INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, '
    'kind, mode, "action", answered_at, next_due_at, previous_box, next_box) '
    "VALUES (?, ?, 's', 'eight_box', ?, 'scheduled', 'recall', 'remembered', ?, ?, 2, 3)",
    [
      id,
      cardId,
      generation,
      at.millisecondsSinceEpoch ~/ 1000,
      at.millisecondsSinceEpoch ~/ 1000 + 86400,
    ],
  );

  group('watchDetail (BR-CARD-014)', () {
    test(
      'gives the content, the flag, the tags by folded name and the schedule',
      () async {
        final card = await cards.card(
          leaf.id,
          const CardDraft(
            front: '사과',
            back: 'apple',
            example: 'An apple a day',
            isFlagged: true,
            tagNames: ['fruit', 'Apple'],
          ),
        );

        final detail = (await cards.watchDetail(card.id).first)!;

        expect(
          (detail.card.front, detail.card.example, detail.card.isFlagged),
          ('사과', 'An apple a day', true),
        );
        expect([for (final tag in detail.tags) tag.name], ['Apple', 'fruit']);
        expect(
          (
            detail.schedulerType,
            detail.schedule.currentBox,
            detail.displayStatus,
          ),
          (SchedulerType.eightBox, 1, CardDisplayStatus.newCard),
        );
      },
    );

    test(
      'emits again when a tag, the schedule row or the content changes',
      () async {
        final card = await cards.card(leaf.id);
        final details = <CardDetail?>[];
        final subscription = cards.watchDetail(card.id).listen(details.add);
        await pumpEventQueue();

        await tags.attachByName(cardIds: {card.id}, name: 'verb');
        await pumpEventQueue();
        await db.customUpdate(
          'UPDATE card_schedule SET learned_at = 1, due_at = 2, current_box = 5 WHERE card_id = ?',
          variables: [Variable(card.id)],
          updates: {db.cardSchedule},
        );
        await pumpEventQueue();
        await cards.editCard(
          cardId: card.id,
          draft: const CardDraft(
            front: 'new',
            back: 'back',
            tagNames: ['verb'],
          ),
        );
        await pumpEventQueue();

        expect(
          [for (final detail in details) detail!.tags.length],
          [0, 1, 1, 1],
        );
        expect(details[2]!.displayStatus, CardDisplayStatus.reviewing);
        expect(details.last!.card.front, 'new');
        await subscription.cancel();
      },
    );

    test('emits null once the card is deleted, and a card in the Trash is not shown (BR-CARD-019)', () async {
      final card = await cards.card(leaf.id);
      final trashed = await cards.card(leaf.id);
      await db.customStatement(
        "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
        [trashed.id],
      );
      final details = <CardDetail?>[];
      final subscription = cards.watchDetail(card.id).listen(details.add);
      await pumpEventQueue();

      await cards.deleteCards(cardIds: {card.id});
      await pumpEventQueue();

      expect((details.first != null, details.last), (true, null));
      expect(await cards.watchDetail(trashed.id).first, isNull);
      await subscription.cancel();
    });
  });

  group('historyPage (BR-CARD-015..018)', () {
    test('pages of 50, newest first, each in one statement', () async {
      final card = await cards.card(leaf.id);
      final start = DateTime(2026, 1, 1);
      for (var i = 0; i < 120; i++) {
        await logAnswer(
          card.id,
          'log-${i.toString().padLeft(3, '0')}',
          start.add(Duration(hours: i)),
        );
      }

      counter.selects = 0;
      final first = (await cards.historyPage(cardId: card.id))!;
      expect(counter.selects, 1);
      final second = (await cards.historyPage(
        cardId: card.id,
        after: first.next,
      ))!;
      final third = (await cards.historyPage(
        cardId: card.id,
        after: second.next,
      ))!;

      expect(
        (first.entries.length, second.entries.length, third.entries.length),
        (50, 50, 20),
      );
      expect(
        (first.entries.first.id, third.entries.last.id),
        ('log-119', 'log-000'),
      );
      expect(third.next, isNull);
    });

    test(
      'an answer logged while paging neither repeats a row nor skips one',
      () async {
        final card = await cards.card(leaf.id);
        final start = DateTime(2026, 1, 1);
        for (var i = 0; i < 60; i++) {
          await logAnswer(
            card.id,
            'log-${i.toString().padLeft(3, '0')}',
            start.add(Duration(hours: i)),
          );
        }

        final first = (await cards.historyPage(cardId: card.id))!;
        await logAnswer(card.id, 'log-new', DateTime(2026, 6, 1));
        final second = (await cards.historyPage(
          cardId: card.id,
          after: first.next,
        ))!;

        final seen = [
          for (final entry in [...first.entries, ...second.entries]) entry.id,
        ];
        expect(seen.toSet().length, 60);
        expect(seen, isNot(contains('log-new')));
      },
    );

    test('answers in the same second cross a page boundary without a repeat or a gap', () async {
      final card = await cards.card(leaf.id);
      for (var i = 0; i < 55; i++) {
        final id = 'log-${i.toString().padLeft(3, '0')}';
        await logAnswer(card.id, id, DateTime(2026, 1, 1, 12));
      }

      final first = (await cards.historyPage(cardId: card.id))!;
      final second = (await cards.historyPage(
        cardId: card.id,
        after: first.next,
      ))!;

      final ids = [
        for (final entry in [...first.entries, ...second.entries]) entry.id,
      ];
      expect(
        (ids.length, ids.toSet().length, ids.first, second.next),
        (55, 55, 'log-054', null),
      );
    });

    test('an entry carries the stored values of its row (BR-CARD-016, BR-CARD-017)', () async {
      final card = await cards.card(leaf.id);
      await logAnswer(card.id, 'old', DateTime(2026, 1, 1), generation: 1);
      await logAnswer(card.id, 'recent', DateTime(2026, 2, 1), generation: 2);

      final page = (await cards.historyPage(cardId: card.id))!;

      final [recent, old] = page.entries;
      expect((recent.generation, old.generation), (2, 1));
      expect(
        (recent.kind, recent.mode, recent.action),
        (ReviewKind.scheduled, 'recall', EightBoxAction.remembered),
      );
      expect(
        (recent.previousBox, recent.nextBox, recent.previousEaseFactor),
        (2, 3, null),
      );
      expect(
        (recent.answeredAt, recent.nextDueAt),
        (DateTime(2026, 2, 1), DateTime(2026, 2, 2)),
      );
      expect((recent.isTimedOut, recent.usedHint), (false, null));
    });

    test(
      'a card with no answer has an empty page; a missing card has none',
      () async {
        final card = await cards.card(leaf.id);

        final page = (await cards.historyPage(cardId: card.id))!;

        expect(page.entries, isEmpty);
        expect(page.next, isNull);
        expect(await cards.historyPage(cardId: 'missing'), isNull);
      },
    );

    test(
      'reading the detail and the history writes nothing (BR-CARD-013)',
      () async {
        final card = await cards.card(leaf.id);
        await logAnswer(card.id, 'log', DateTime(2026, 1, 1));
        final before = await totalChanges(db);

        await cards.watchDetail(card.id).first;
        await cards.historyPage(cardId: card.id);

        expect(await totalChanges(db), before);
      },
    );
  });

  test('card move targets are the other card decks of the root, with their paths (BR-CARD-010)', () async {
    final verbs = await decks.sub(root.id, 'Verbs');
    final branch = await decks.sub(root.id, 'Grammar');
    final particles = await decks.sub(branch.id, 'Particles');
    await cards.card(particles.id);
    await cards.card(leaf.id);
    final trashed = await decks.sub(root.id, 'Trashed');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [trashed.id],
    );
    final other = await decks.root('Twin');
    await decks.sub(other.id, 'Twin leaf');

    final targets = await cards.watchMoveTargets(leaf.id).first;

    expect(
      [
        for (final target in targets)
          (
            target.name,
            [for (final step in target.path) step.name].join(' / '),
          ),
      ],
      [('Verbs', 'Korean'), ('Particles', 'Korean / Grammar')],
    );
    expect(targets.first.id, verbs.id);
  });
}
