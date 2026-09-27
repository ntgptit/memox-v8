import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 steps 7-8 and A4 (BE-C4): the card list filtered by tags, an OR
// between them that ANDs with the status filter and the search, shared by
// the window, the counts and Select all (BR-TAG-004; tag management spec
// §8). `Mixed due` of S-DUE at T0 = 2026-09-23 10:00, as in
// card_list_read_test.dart.
final _now = DateTime(2026, 9, 23, 10);

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late TagRepositoryImpl tags;
  late DeckEntity mixed;
  late Map<String, String> tagIds;

  setUp(() async {
    db = openTestDatabase();
    DateTime clock() => DateTime(2026, 9, 1);
    final decks = DeckRepositoryImpl(db, now: clock);
    tags = TagRepositoryImpl(db, now: clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock),
      tags,
      now: clock,
    );
    final root = await decks.root('Due library');
    mixed = await decks.sub(root.id, 'Mixed due');
    await insertCard(
      db,
      id: 'new',
      deckId: mixed.id,
      front: 'abandon',
      back: 'từ bỏ',
      createdAt: DateTime(2026, 9, 1),
    );
    await insertCard(
      db,
      id: 'begin',
      deckId: mixed.id,
      front: 'benevolent',
      back: 'nhân từ',
      isFlagged: true,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 23),
      box: 2,
      createdAt: DateTime(2026, 9, 2),
    );
    await insertCard(
      db,
      id: 'review',
      deckId: mixed.id,
      front: 'candid',
      back: 'thẳng thắn',
      learnedAt: DateTime(2026, 9, 10),
      dueAt: DateTime(2026, 9, 22),
      box: 5,
      createdAt: DateTime(2026, 9, 3),
    );
    await insertCard(
      db,
      id: 'master',
      deckId: mixed.id,
      front: 'diligent',
      back: 'chăm chỉ',
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 23),
      box: 8,
      createdAt: DateTime(2026, 9, 4),
    );
    await tags.attachByName(cardIds: {'new', 'begin'}, name: 'verb');
    await tags.attachByName(cardIds: {'begin', 'review'}, name: 'noun');
    await tags.attachByName(cardIds: {'begin'}, name: 'adj');
    await tags.attachByName(cardIds: {'master'}, name: 'rare');
    tagIds = {
      for (final count in await tags.watchTagCounts().first)
        count.name: count.id,
    };
  });
  tearDown(() => db.close());

  CardListQuery tagged(
    Set<String> names, {
    CardListFilter filter = CardListFilter.all,
    String searchTerm = '',
  }) => CardListQuery(
    filter: filter,
    searchTerm: searchTerm,
    tagIds: {for (final name in names) tagIds[name] ?? name},
  );

  Future<CardListView> list(CardListQuery query, {int windowSize = 50}) => cards
      .watchCardList(
        deckId: mixed.id,
        query: query,
        windowSize: windowSize,
        now: _now,
      )
      .first;

  Future<List<String>> shown(CardListQuery query) async => [
    for (final item in (await list(query)).items) item.id,
  ];

  (int, int, int, int) countsOf(CardListView view) => (
    view.counts.all,
    view.counts.due,
    view.counts.newCards,
    view.counts.flagged,
  );

  Future<Set<String>> selectAll(CardListQuery query) =>
      cards.cardIdsMatching(deckId: mixed.id, query: query, now: _now);

  test('the selected tags are an OR: a card carrying any of them passes '
      '(BR-TAG-004)', () async {
    expect(await shown(tagged({'verb'})), ['begin', 'new']);
    expect(await shown(tagged({'verb', 'noun'})), ['review', 'begin', 'new']);
  });

  test('the tags AND with each status filter and with the search '
      '(BR-TAG-004)', () async {
    expect(await shown(tagged({'verb', 'noun'}, filter: CardListFilter.due)), [
      'review',
      'begin',
    ]);
    expect(
      await shown(tagged({'verb', 'noun'}, filter: CardListFilter.newCards)),
      ['new'],
    );
    expect(
      await shown(tagged({'verb', 'noun'}, filter: CardListFilter.flagged)),
      ['begin'],
    );
    expect(await shown(tagged({'noun'}, searchTerm: 'TỪ')), ['begin']);
  });

  test('a card carrying three selected tags appears once, counts once and '
      'takes one place in the window (BR-TAG-004)', () async {
    final query = tagged({'verb', 'noun', 'adj'});
    final first = await list(query, windowSize: 2);
    final whole = await list(query, windowSize: 3);

    expect([for (final item in first.items) item.id], ['review', 'begin']);
    expect(first.hasMore, isTrue);
    expect(
      [for (final item in whole.items) item.id],
      ['review', 'begin', 'new'],
    );
    expect(whole.hasMore, isFalse);
    expect(countsOf(whole), (3, 2, 1, 1));
  });

  test('the counts follow the tags; the status counts and the workload stay '
      'the deck\'s (tag management spec D10)', () async {
    final view = await list(tagged({'noun'}));

    expect(countsOf(view), (2, 2, 0, 1));
    expect(view.statusCounts.total, 4);
    expect(
      (view.workload.overdue, view.workload.today, view.workload.newCards),
      (1, 1, 1),
    );
  });

  test('Select all takes exactly the cards the list shows (BR-CARD-012, '
      'BR-TAG-004)', () async {
    expect(await selectAll(tagged({'verb', 'noun', 'adj'})), {
      'review',
      'begin',
      'new',
    });
    expect(
      await selectAll(tagged({'verb', 'noun'}, filter: CardListFilter.due)),
      {'review', 'begin'},
    );
  });

  test('no selected tag is the identity: the list, the counts and Select all '
      'as without the filter (BR-TAG-004)', () async {
    final view = await list(const CardListQuery(tagIds: {}));

    expect(
      [for (final item in view.items) item.id],
      ['master', 'review', 'begin', 'new'],
    );
    expect(countsOf(view), (4, 2, 1, 1));
    expect(await selectAll(const CardListQuery(tagIds: {})), {
      'master',
      'review',
      'begin',
      'new',
    });
  });

  test('a tag id that no longer exists matches no card, and a card in the '
      'Trash never passes (BR-TAG-010; tag management spec D10)', () async {
    await insertCard(
      db,
      id: 'trashed',
      deckId: mixed.id,
      deleteBatchId: 'batch',
    );
    await db.customInsert(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      variables: [
        const Variable<String>('trashed'),
        Variable<String>(tagIds['rare']!),
      ],
      updates: {db.cardTags},
    );

    final gone = await list(tagged({'missing'}));
    expect(gone.items, isEmpty);
    expect(countsOf(gone), (0, 0, 0, 0));
    expect(await selectAll(tagged({'missing'})), isEmpty);
    expect(await shown(tagged({'rare'})), ['master']);
    expect(await selectAll(tagged({'rare'})), {'master'});
  });

  test('a list filtered by a tag that is merged away matches nothing, and the '
      "deck's tag list no longer offers it (tag management spec §9)", () async {
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: tagged({'noun'}),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();
    expect([for (final item in views.last.items) item.id], ['review', 'begin']);

    await tags.renameTag(
      tagId: tagIds['noun']!,
      name: 'VERB',
      mergeIntoTagId: tagIds['verb'],
    );
    await pumpEventQueue();

    expect(views.last.items, isEmpty);
    expect(views.last.counts.all, 0);
    expect(
      [
        for (final count in await tags.watchTagCounts(deckId: mixed.id).first)
          count.name,
      ],
      ['adj', 'rare', 'verb'],
    );
    await subscription.cancel();
  });
}
