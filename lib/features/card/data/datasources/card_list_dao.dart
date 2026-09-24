import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';

/// The card list read model (UC-CARD-001): a window, the filter counts, the
/// deck's display states and the window's tags. Every filtered read goes through
/// [_predicate], so the list, its counts and Select all never disagree about
/// which cards a query lets through (BR-CARD-012).
final class CardListDao {
  CardListDao(this._db);

  final AppDatabase _db;

  Card get _card => _db.card;
  CardScheduleTable get _schedule => _db.cardSchedule;

  /// Up to [limit] cards with their schedule rows, in [query]'s order.
  Future<List<(CardRow, CardSchedule)>> window({
    required String deckId,
    required CardListQuery query,
    required int limit,
    required DateTime now,
  }) async {
    final select =
        _db.select(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..where(_predicate(deckId: deckId, query: query, now: now))
          ..orderBy(_order(query.sort))
          ..limit(limit);
    return [
      for (final row in await select.get())
        (row.readTable(_card), row.readTable(_schedule)),
    ];
  }

  /// All, Due, New and Flagged under [searchTerm], whatever the filter, in
  /// one statement (IT-ORG-005).
  Future<({int all, int due, int newCards, int flagged})> counts({
    required String deckId,
    required String searchTerm,
    required DateTime now,
  }) async {
    final all = countAll();
    final due = countAll(filter: _passes(CardListFilter.due, now));
    final newCards = countAll(filter: _passes(CardListFilter.newCards, now));
    final flagged = countAll(filter: _passes(CardListFilter.flagged, now));
    final select =
        _db.selectOnly(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..addColumns([all, due, newCards, flagged])
          ..where(_inDeck(deckId, searchTerm));
    final row = await select.getSingle();
    return (
      all: row.read(all)!,
      due: row.read(due)!,
      newCards: row.read(newCards)!,
      flagged: row.read(flagged)!,
    );
  }

  /// BR-CARD-012: every card [query] lets through, not only a window.
  Future<Set<String>> ids({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) async {
    final select =
        _db.selectOnly(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..addColumns([_card.id])
          ..where(_predicate(deckId: deckId, query: query, now: now));
    return {for (final row in await select.get()) row.read(_card.id)!};
  }

  /// The schedule rows of every active card of [deckId], outside any search
  /// or filter, for the display-state counts (BR-CARD-008).
  Future<List<CardSchedule>> activeSchedules(String deckId) {
    final select = _db.select(_schedule).join([
      innerJoin(_card, _card.id.equalsExp(_schedule.cardId)),
    ])..where(_card.deckId.equals(deckId) & _card.deleteBatchId.isNull());
    return select.map((row) => row.readTable(_schedule)).get();
  }

  /// The tags of [cardIds] in one statement, each card's by folded name then
  /// id (BR-TAG-001). No statement for no card.
  Future<Map<String, List<Tag>>> tagsOf(List<String> cardIds) async {
    if (cardIds.isEmpty) return const {};
    final links = _db.cardTags;
    final tags = _db.tags;
    final select =
        _db.select(links).join([
            innerJoin(tags, tags.id.equalsExp(links.tagId)),
          ])
          ..where(links.cardId.isIn(cardIds))
          ..orderBy([
            OrderingTerm.asc(tags.nameFolded),
            OrderingTerm.asc(tags.id),
          ]);
    final byCard = <String, List<Tag>>{};
    for (final row in await select.get()) {
      byCard
          .putIfAbsent(row.readTable(links).cardId, () => [])
          .add(row.readTable(tags));
    }
    return byCard;
  }

  /// Fires after every write to a table the list reads: cards, schedules,
  /// and the tags on cards. A transaction fires once.
  Stream<void> changes() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_card, _schedule, _db.cardTags, _db.tags]),
  );

  /// The one place that says which cards a query lets through: the active
  /// cards of [deckId], under the search, through the filter. A tag filter
  /// (BR-TAG-004) is one more term here.
  Expression<bool> _predicate({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) => _inDeck(deckId, query.searchTerm) & _passes(query.filter, now);

  /// The search matches the folded term inside a folded side with `instr`,
  /// so `%` and `_` are plain characters and nothing needs escaping.
  Expression<bool> _inDeck(String deckId, String searchTerm) {
    final inDeck = _card.deckId.equals(deckId) & _card.deleteBatchId.isNull();
    final term = foldText(searchTerm);
    if (term.isEmpty) return inDeck;
    return inDeck &
        (_holds(_card.frontFolded, term) | _holds(_card.backFolded, term));
  }

  Expression<bool> _passes(CardListFilter filter, DateTime now) =>
      switch (filter) {
        CardListFilter.all => const Constant(true),
        CardListFilter.due =>
          _schedule.learnedAt.isNotNull() &
              _schedule.dueAt.isSmallerOrEqualValue(now),
        CardListFilter.newCards => _schedule.learnedAt.isNull(),
        CardListFilter.flagged => _card.isFlagged.equals(1),
      };

  List<OrderingTerm> _order(CardListSort sort) => switch (sort) {
    CardListSort.newest => [
      OrderingTerm.desc(_card.createdAt),
      OrderingTerm.desc(_card.id),
    ],
    CardListSort.dueFirst => [
      OrderingTerm.asc(_schedule.learnedAt.isNull()),
      OrderingTerm.asc(_schedule.dueAt),
      OrderingTerm.desc(_card.createdAt),
      OrderingTerm.desc(_card.id),
    ],
  };
}

Expression<bool> _holds(Expression<String> folded, String term) =>
    FunctionCallExpression<int>('instr', [
      folded,
      Variable<String>(term),
    ]).isBiggerThanValue(0);
