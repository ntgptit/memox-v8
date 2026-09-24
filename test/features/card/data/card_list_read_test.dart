import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// `Mixed due` of S-DUE (agent-execution-guide §6.2) at T0 = 2026-09-23 10:00,
// every due_at on a local midnight (BR-STUDY-074).
final _now = DateTime(2026, 9, 23, 10);

void main() {
  late SelectCounter counter;
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late TagRepositoryImpl tags;
  late DeckEntity mixed;

  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
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
  });
  tearDown(() => db.close());

  Future<CardListView> list({
    CardListQuery query = const CardListQuery(),
    int windowSize = 50,
  }) => cards
      .watchCardList(
        deckId: mixed.id,
        query: query,
        windowSize: windowSize,
        now: _now,
      )
      .first;

  List<String> ids(CardListView view) => [
    for (final item in view.items) item.id,
  ];

  test(
    'the counts of every filter, under the search only (IT-ORG-005)',
    () async {
      final all = await list();
      final searched = await list(
        query: const CardListQuery(
          filter: CardListFilter.newCards,
          searchTerm: 'từ',
        ),
      );

      expect(
        (
          all.counts.all,
          all.counts.due,
          all.counts.newCards,
          all.counts.flagged,
        ),
        (4, 2, 1, 1),
      );
      expect(
        (
          searched.counts.all,
          searched.counts.due,
          searched.counts.newCards,
          searched.counts.flagged,
        ),
        (2, 1, 1, 1),
      );
    },
  );

  test('each filter keeps its cards (IT-ORG-005)', () async {
    Future<List<String>> through(CardListFilter filter) async =>
        ids(await list(query: CardListQuery(filter: filter)));

    expect(await through(CardListFilter.due), ['review', 'begin']);
    expect(await through(CardListFilter.newCards), ['new']);
    expect(await through(CardListFilter.flagged), ['begin']);
  });

  test(
    'the search matches a folded front or back as a substring (IT-ORG-001)',
    () async {
      Future<List<String>> found(String term) async =>
          ids(await list(query: CardListQuery(searchTerm: term)));

      expect(await found('abandon'), ['new']);
      expect(await found('  NHÂN TỪ '), ['begin']);
      expect(await found('không-tồn-tại'), isEmpty);
      expect(await found('%'), isEmpty, reason: 'no LIKE wildcard');
    },
  );

  test('newest follows created_at; dueFirst puts the soonest due first and New last (IT-ORG-003)', () async {
    expect(ids(await list()), ['master', 'review', 'begin', 'new']);
    expect(
      ids(await list(query: const CardListQuery(sort: CardListSort.dueFirst))),
      ['review', 'begin', 'master', 'new'],
    );
  });

  test('each item carries its flag, due date and display status', () async {
    final items = {for (final item in (await list()).items) item.id: item};

    expect(
      [
        for (final id in ['new', 'begin', 'review', 'master'])
          items[id]!.displayStatus,
      ],
      [
        CardDisplayStatus.newCard,
        CardDisplayStatus.beginning,
        CardDisplayStatus.reviewing,
        CardDisplayStatus.mastered,
      ],
    );
    expect(
      (items['begin']!.isFlagged, items['begin']!.dueAt),
      (true, DateTime(2026, 9, 23)),
    );
    expect(
      (items['new']!.front, items['new']!.back, items['new']!.dueAt),
      ('abandon', 'từ bỏ', null),
    );
  });

  test(
    'the window holds windowSize cards and says whether more follow',
    () async {
      final first = await list(windowSize: 3);
      final whole = await list(windowSize: 4);

      expect((first.items.length, first.hasMore), (3, true));
      expect((whole.items.length, whole.hasMore), (4, false));
    },
  );

  test('a card in the Trash is left out', () async {
    await insertCard(
      db,
      id: 'trashed',
      deckId: mixed.id,
      deleteBatchId: 'batch',
    );

    final view = await list();

    expect(view.counts.all, 4);
    expect(ids(view), isNot(contains('trashed')));
  });

  test('an emission is four statements, whatever the window holds, and a change emits once', () async {
    counter.selects = 0;
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: const CardListQuery(),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();
    // The window, the filter counts, the deck's schedules, the window's tags.
    expect((views.length, counter.selects), (1, 4));

    await insertCard(db, id: 'another', deckId: mixed.id);
    await pumpEventQueue();

    expect((views.length, counter.selects), (2, 8));
    expect(views.last.counts.all, 5);
    await subscription.cancel();
  });

  test('Select all takes every card the query lets through, past the window (BR-CARD-012)', () async {
    final due = await cards.cardIdsMatching(
      deckId: mixed.id,
      query: const CardListQuery(filter: CardListFilter.due),
      now: _now,
    );
    final searched = await cards.cardIdsMatching(
      deckId: mixed.id,
      query: const CardListQuery(searchTerm: 'từ'),
      now: _now,
    );

    expect(due, {'begin', 'review'});
    expect(searched, {'new', 'begin'});
  });

  test(
    'each item carries its due label, counted from the start of today',
    () async {
      final view = await list();
      final due = {for (final item in view.items) item.id: item.due};

      expect(due, {
        'new': const CardDue.newCard(),
        'begin': const CardDue.today(),
        'review': const CardDue.overdue(1),
        'master': const CardDue.later(30),
      });
    },
  );

  test('each item carries its tags, by folded name', () async {
    await tags.attachByName(cardIds: {'begin'}, name: 'verb');
    await tags.attachByName(cardIds: {'begin'}, name: 'Adjective');

    final view = await list();
    final begin = view.items.firstWhere((item) => item.id == 'begin');
    final others = view.items.where((item) => item.id != 'begin');

    expect([for (final tag in begin.tags) tag.name], ['Adjective', 'verb']);
    expect(others.every((item) => item.tags.isEmpty), isTrue);
  });

  test('tagging a card re-emits the list with its tags', () async {
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: const CardListQuery(),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();

    await tags.attachByName(cardIds: {'new'}, name: 'verb');
    await pumpEventQueue();

    expect(views, hasLength(2));
    final tagged = views.last.items.firstWhere((item) => item.id == 'new');
    expect([for (final tag in tagged.tags) tag.name], ['verb']);
    expect(views.last.counts.all, 4);
    await subscription.cancel();
  });

  test(
    'the status counts cover the deck: one card in each display state',
    () async {
      final view = await list();

      expect(
        (
          view.statusCounts.newCards,
          view.statusCounts.beginning,
          view.statusCounts.reviewing,
          view.statusCounts.mastered,
          view.statusCounts.total,
        ),
        (1, 1, 1, 1, 4),
      );
    },
  );

  test('the status counts ignore the search and the filter', () async {
    final view = await list(
      query: const CardListQuery(
        filter: CardListFilter.flagged,
        searchTerm: 'benevolent',
      ),
    );

    expect(view.items, hasLength(1));
    expect(view.statusCounts.total, 4);
  });

  test('an empty window reads no tags', () async {
    counter.selects = 0;
    final view = await list(query: const CardListQuery(searchTerm: 'zzz'));

    expect(view.items, isEmpty);
    expect(view.statusCounts.total, 4);
    expect(counter.selects, 3);
  });
}
