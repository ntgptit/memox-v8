import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/card_due_sql.dart';
import 'package:memox/core/database/card_status_sql.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';

part 'card_list_dao.g.dart';

/// The card list read model (UC-CARD-001): a window, the filter counts, the
/// deck's display states and the window's tags (`card_list_queries.drift`).
/// Every filtered read takes [_predicate] and the tag clause of its query,
/// so the list, its counts and Select all never disagree about which cards a
/// query lets through (BR-CARD-012).
@DriftAccessor(
  include: {'package:memox/core/database/queries/card_list_queries.drift'},
)
final class CardListDao extends DatabaseAccessor<AppDatabase>
    with _$CardListDaoMixin {
  CardListDao(super.attachedDatabase);

  /// Up to [limit] cards with their schedule rows, in [query]'s order.
  Future<List<(CardRow, CardSchedule)>> window({
    required String deckId,
    required CardListQuery query,
    required int limit,
    required DateTime now,
  }) async {
    final tagIds = query.tagIds.toList();
    final rows = await cardListWindow(
      (c, s) => _predicate(c, s, deckId: deckId, query: query, now: now),
      tagIds.length,
      tagIds,
      (c, s) => OrderBy(_order(c, s, query.sort)),
      limit,
    ).get();
    return [for (final row in rows) (row.c, row.s)];
  }

  /// All, Due, New and Flagged under [searchTerm] and [tagIds], whatever the
  /// filter, in one statement (IT-ORG-005, BR-TAG-004).
  Future<({int all, int due, int newCards, int flagged})> counts({
    required String deckId,
    required String searchTerm,
    required Set<String> tagIds,
    required DateTime now,
  }) async {
    final tags = tagIds.toList();
    final row = await cardListCounts(
      (c, s) => _passes(c, s, CardListFilter.due, now),
      (c, s) => _passes(c, s, CardListFilter.newCards, now),
      (c, s) => _passes(c, s, CardListFilter.flagged, now),
      (c, s) => _inDeck(c, deckId, searchTerm),
      tags.length,
      tags,
    ).getSingle();
    return (
      all: row.allCount,
      due: row.dueCount,
      newCards: row.newCount,
      flagged: row.flaggedCount,
    );
  }

  /// BR-CARD-012: every card [query] lets through, not only a window.
  Future<Set<String>> ids({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) async {
    final tagIds = query.tagIds.toList();
    return (await cardListIds(
      (c, s) => _predicate(c, s, deckId: deckId, query: query, now: now),
      tagIds.length,
      tagIds,
    ).get()).toSet();
  }

  /// The display-state counts (BR-CARD-008) and the workload (BR-STUDY-068)
  /// of every active card of [deckId], outside any search or filter, in one
  /// statement (DEV-211): the list never reads the deck's schedule rows.
  Future<DeckStatusCountsRow> statusCounts(
    String deckId, {
    required DateTime now,
    required DateTime startOfToday,
  }) => deckStatusCounts(
    (s, c) => CardDueSql.isNew(s),
    (s, c) => CardStatusSql.isBeginning(s),
    (s, c) => CardStatusSql.isReviewing(s),
    (s, c) => CardStatusSql.isMastered(s),
    (s, c) => CardDueSql.isOverdue(s, startOfToday),
    (s, c) => CardDueSql.isDueToday(s, now: now, startOfToday: startOfToday),
    deckId,
  ).getSingle();

  /// The tags of [cardIds], each card's by folded name then id (BR-TAG-001).
  /// One statement per chunk of cards (BE-C2): a card's tags all come from
  /// its own chunk, so each list keeps its order. No statement for no card.
  Future<Map<String, List<Tag>>> tagsOf(List<String> cardIds) async {
    if (cardIds.isEmpty) return const {};
    final byCard = <String, List<Tag>>{};
    for (final chunk in idChunks(cardIds)) {
      for (final row in await cardTagsIn(chunk).get()) {
        byCard.putIfAbsent(row.cardId, () => []).add(row.t);
      }
    }
    return byCard;
  }

  /// Fires after every write to a table the list reads: cards, schedules,
  /// and the tags on cards. A transaction fires once.
  Stream<void> changes() => attachedDatabase.tableUpdates(
    TableUpdateQuery.onAllTables([
      attachedDatabase.card,
      attachedDatabase.cardSchedule,
      attachedDatabase.cardTags,
      attachedDatabase.tags,
    ]),
  );

  /// The one Dart place that says which cards a query lets through: the
  /// cards of [deckId], under the search, through the filter. The Trash
  /// filter and the tag clause are its query's (BR-TRASH-002, BR-TAG-004).
  Expression<bool> _predicate(
    Card c,
    CardScheduleTable s, {
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) => _inDeck(c, deckId, query.searchTerm) & _passes(c, s, query.filter, now);

  /// The search matches the folded term inside a folded side with `instr`,
  /// so `%` and `_` are plain characters and nothing needs escaping.
  Expression<bool> _inDeck(Card c, String deckId, String searchTerm) {
    final inDeck = c.deckId.equals(deckId);
    final term = foldText(searchTerm);
    if (term.isEmpty) return inDeck;
    return inDeck & (_holds(c.frontFolded, term) | _holds(c.backFolded, term));
  }

  Expression<bool> _passes(
    Card c,
    CardScheduleTable s,
    CardListFilter filter,
    DateTime now,
  ) => switch (filter) {
    CardListFilter.all => const Constant(true),
    CardListFilter.due => CardDueSql.isDue(s, now),
    CardListFilter.newCards => CardDueSql.isNew(s),
    CardListFilter.flagged => c.isFlagged.equals(1),
  };

  List<OrderingTerm> _order(Card c, CardScheduleTable s, CardListSort sort) =>
      switch (sort) {
        CardListSort.newest => [
          OrderingTerm.desc(c.createdAt),
          OrderingTerm.desc(c.id),
        ],
        CardListSort.dueFirst => [
          OrderingTerm.asc(s.learnedAt.isNull()),
          OrderingTerm.asc(s.dueAt),
          OrderingTerm.desc(c.createdAt),
          OrderingTerm.desc(c.id),
        ],
      };
}

Expression<bool> _holds(Expression<String> folded, String term) =>
    FunctionCallExpression<int>('instr', [
      folded,
      Variable<String>(term),
    ]).isBiggerThanValue(0);
