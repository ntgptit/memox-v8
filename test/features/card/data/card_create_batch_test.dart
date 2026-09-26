import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRANSFER-001 step 7: an import writes its rows through createCards,
// the batch form of a card create (BR-TRANSFER-001, BR-TRANSFER-004,
// BR-TRANSFER-005; transfer spec §7, D11).

DateTime _now() => DateTime(2026, 9, 26, 10);

List<CardDraft> _drafts(int count) => [
  for (var i = 1; i <= count; i++) CardDraft(front: 'w$i', back: 'm$i'),
];

Matcher _refused(CardRejection reason) =>
    isA<Rejected<List<String>, CardRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

/// Fails the schedule rows of a batch, after its cards are inserted.
final class _FailingSchedules implements ScheduleRepository {
  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) async => throw StateError('schedule rows not written');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;

  CardRepositoryImpl cardsWith(ScheduleRepository schedules) =>
      CardRepositoryImpl(
        db,
        schedules,
        TagRepositoryImpl(db, now: _now),
        now: _now,
      );

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = cardsWith(ScheduleRepositoryImpl(db, now: _now));
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());

  Future<List<QueryRow>> cardRows() => db
      .customSelect(
        'SELECT id, front, created_at FROM card ORDER BY created_at, id',
      )
      .get();

  test('the drafts become cards in their order: ids ascend with the list and '
      'every card shares one created_at (transfer spec D11)', () async {
    final result = await cards.createCards(
      deckId: leaf.id,
      drafts: _drafts(12),
    );

    final ids = (result as Ok<List<String>, CardRejection>).value;
    expect(ids, hasLength(12));
    expect(ids, [...ids]..sort());
    final rows = await cardRows();
    expect(
      [for (final row in rows) row.read<String>('front')],
      [for (var i = 1; i <= 12; i++) 'w$i'],
    );
    expect([for (final row in rows) row.read<String>('id')], ids);
    expect(
      {for (final row in rows) row.read<DateTime>('created_at')},
      {_now()},
    );
  });

  test('each card has one schedule row of its root, and tags reused or '
      'created by folded name (BR-TRANSFER-004)', () async {
    final sm2 = await decks.root('s', SchedulerType.sm2);
    final sm2Leaf = await decks.sub(sm2.id, 'l');
    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      sm2.id,
    ]);

    await cards.createCards(
      deckId: sm2Leaf.id,
      drafts: const [
        CardDraft(front: 'a', back: '1', tagNames: ['Noun']),
        CardDraft(front: 'b', back: '2', tagNames: ['noun', 'verb']),
      ],
    );

    final schedules = await db
        .customSelect(
          'SELECT scheduler_type, generation, learned_at, due_at '
          'FROM card_schedule',
        )
        .get();
    expect(schedules, hasLength(2));
    for (final row in schedules) {
      expect(row.read<String>('scheduler_type'), 'sm2');
      expect(row.read<int>('generation'), 2);
      expect(row.data['learned_at'], isNull);
      expect(row.data['due_at'], isNull);
    }
    final links = await db
        .customSelect(
          'SELECT c.front, t.name FROM card_tags ct '
          'JOIN card c ON c.id = ct.card_id JOIN tags t ON t.id = ct.tag_id '
          'ORDER BY c.front, t.name_folded',
        )
        .get();
    expect(
      [
        for (final row in links)
          '${row.read<String>('front')}:${row.read<String>('name')}',
      ],
      ['a:Noun', 'b:Noun', 'b:verb'],
    );
  });

  test('an unset deck becomes a deck of cards with the first card written, '
      'and an empty list changes nothing (BR-TRANSFER-005)', () async {
    final before = await totalChanges(db);

    expect(
      await cards.createCards(deckId: leaf.id, drafts: const []),
      isA<Ok<List<String>, CardRejection>>().having(
        (ok) => ok.value,
        'ids',
        isEmpty,
      ),
    );
    expect(await totalChanges(db), before);
    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.unset);

    await cards.createCards(deckId: leaf.id, drafts: _drafts(2));

    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.card);
  });

  test('the deck is checked even for an empty list: gone, in the Trash, a '
      'root or holding sub-decks (BR-TRANSFER-001)', () async {
    final mid = await decks.sub(root.id, 'mid');
    await decks.sub(mid.id, 'inner');
    final trashed = await decks.sub(root.id, 't');
    await trashDeckRows(db, trashed.id);
    final before = await totalChanges(db);

    for (final (deckId, reason) in [
      ('missing', CardRejection.notFound),
      (trashed.id, CardRejection.notFound),
      (root.id, CardRejection.notACardContainer),
      (mid.id, CardRejection.notACardContainer),
    ]) {
      for (final drafts in [const <CardDraft>[], _drafts(1)]) {
        expect(
          await cards.createCards(deckId: deckId, drafts: drafts),
          _refused(reason),
          reason: '$deckId with ${drafts.length} drafts',
        );
      }
    }
    expect(await totalChanges(db), before);
  });

  test('one draft the card rules refuse refuses the batch, which writes '
      'nothing (BR-TRANSFER-002)', () async {
    final before = await totalChanges(db);

    final result = await cards.createCards(
      deckId: leaf.id,
      drafts: [
        ..._drafts(2),
        const CardDraft(front: 'x', back: ' '),
      ],
    );

    expect(result, _refused(CardRejection.blankContent));
    expect(await totalChanges(db), before);
  });

  test('schedule rows that cannot be written roll the whole batch back '
      '(BR-TRANSFER-004)', () async {
    await expectLater(
      cardsWith(_FailingSchedules())
          .createCards(deckId: leaf.id, drafts: _drafts(3)),
      throwsA(anything),
    );

    expect(await cardRows(), isEmpty);
    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.unset);
  });
}
