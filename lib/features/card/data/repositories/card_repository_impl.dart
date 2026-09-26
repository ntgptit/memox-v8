import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/datasources/card_detail_dao.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/data/mappers/card_mapper.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// Every write reads the rows its rules need and writes inside one
/// transaction, which the schedule row (BR-CARD-004) and the tag links join.
/// A refusal writes nothing.
final class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(
    this._db,
    this._schedules,
    this._tags, {
    DateTime Function()? now,
  }) : _dao = CardDao(_db),
       _listDao = CardListDao(_db),
       _detailDao = CardDetailDao(_db),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final TagRepository _tags;
  final CardDao _dao;
  final CardListDao _listDao;
  final CardDetailDao _detailDao;
  final DateTime Function() _now;

  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final contentType = DeckContentType.values.byName(deck.contentType);
      final container = DeckEntity.checkCreateCard(
        parentContentType: contentType,
      );
      if (container case Rejected()) {
        return const Rejected(CardRejection.notACardContainer);
      }

      final id = newId();
      await _dao.insertCard(id: id, deckId: deckId, draft: draft, now: at);
      await _schedules.initializeCard(cardId: id);
      await _replaceTags(id, draft, at);
      if (contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(cardEntityOf((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      if (await _dao.findRow(cardId) == null) {
        return const Rejected(CardRejection.notFound);
      }
      await _dao.updateContent(cardId, draft, at);
      await _replaceTags(cardId, draft, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok([]);
      final rows = await _dao.liveRows(cardIds);
      if (rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      // One batch per card, all at one time: each card is an item the person
      // can restore on its own (BR-TRASH-001).
      final batchIds = <String>[];
      for (final cardId in cardIds) {
        final batchId = newId();
        await _dao.moveToTrash(cardId, batchId, at);
        batchIds.add(batchId);
      }
      await _unsetEmptied({for (final row in rows) row.deckId}, at);
      for (final batchId in batchIds) {
        await _dao.closeSessionsTouching(batchId, at);
      }
      return Ok(batchIds);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      final rows = await _dao.liveRows(cardIds);
      if (rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      final target = await _dao.deckRow(targetDeckId);
      if (target == null) return const Rejected(CardRejection.targetNotFound);
      final sourceDeckIds = {for (final row in rows) row.deckId};
      final sources = await _dao.deckRows(sourceDeckIds);
      if (sources.length != sourceDeckIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      final targetContentType = DeckContentType.values.byName(
        target.contentType,
      );
      final rule = CardEntity.checkMove(
        targetDeckId: target.id,
        targetRootId: target.rootId,
        targetIsRoot: target.parentId == null,
        targetContentType: targetContentType,
        sourceDeckIds: sourceDeckIds,
        sourceRootIds: {for (final source in sources) source.rootId},
      );
      if (rule case Rejected(:final reason)) return Rejected(reason);

      await _dao.moveCards(cardIds, targetDeckId, at);
      await _unsetEmptied(sourceDeckIds, at);
      if (targetContentType == DeckContentType.unset) {
        await _dao.setDeckContentType(
          targetDeckId,
          DeckContentType.card.name,
          at,
        );
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      if ((await _dao.liveRows(cardIds)).length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      await _dao.setFlagged(cardIds, isFlagged, at);
      return const Ok(null);
    });
  }

  @override
  Stream<CardListView> watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) => _watchCardList(
    deckId: deckId,
    query: query,
    windowSize: windowSize,
    now: now,
  ).mapDatabaseErrors();

  /// Once now, then once after every write the list could see (the DAO's
  /// [CardListDao.changes]); tagging a card is such a write.
  Stream<CardListView> _watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) async* {
    Future<CardListView> read() => _readCardList(
      deckId: deckId,
      query: query,
      windowSize: windowSize,
      now: now,
    );
    yield await read();
    // yield* over asyncMap, not `await for`: an async* generator suspended
    // in `await for` over Drift's table updates never completes a cancel.
    // asyncMap keeps the reads in order, one at a time.
    yield* _listDao.changes().asyncMap((_) => read());
  }

  Future<CardListView> _readCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) async {
    final rows = await _listDao.window(
      deckId: deckId,
      query: query,
      limit: windowSize + 1,
      now: now,
    );
    final counts = await _listDao.counts(
      deckId: deckId,
      searchTerm: query.searchTerm,
      now: now,
    );
    final schedules = await _listDao.activeSchedules(deckId);
    final shown = rows.take(windowSize).toList();
    final tags = await _listDao.tagsOf([
      for (final (card, _) in shown) card.id,
    ]);
    final startOfToday = startOfLocalDay(now);
    return CardListView(
      items: [
        for (final (card, schedule) in shown)
          listItemOf(
            card,
            schedule,
            tags: tags[card.id] ?? const [],
            startOfToday: startOfToday,
          ),
      ],
      hasMore: rows.length > windowSize,
      counts: CardListCounts(
        all: counts.all,
        due: counts.due,
        newCards: counts.newCards,
        flagged: counts.flagged,
      ),
      statusCounts: statusCountsOf(schedules),
      workload: workloadOf(schedules, startOfToday),
    );
  }

  @override
  Future<Set<String>> cardIdsMatching({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) => _mapped(() => _listDao.ids(deckId: deckId, query: query, now: now));

  @override
  Stream<CardDetail?> watchDetail(String cardId) => _detailDao
      .watchDetail(cardId)
      .map((rows) => rows.isEmpty ? null : cardDetailOf(rows.single))
      .mapDatabaseErrors();

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) => _mapped(() async {
    final rows = await _detailDao.historyRows(
      cardId,
      afterAnsweredAt: after?.answeredAt,
      afterId: after?.id,
      limit: ReviewHistoryPage.size + 1,
    );
    if (rows.isEmpty) return null;
    final logs = [
      for (final row in rows)
        if (row.r case final ReviewLog log) log,
    ];
    final entries = [
      for (final log in logs.take(ReviewHistoryPage.size)) historyEntryOf(log),
    ];
    return ReviewHistoryPage(
      entries: entries,
      next: logs.length > ReviewHistoryPage.size
          ? ReviewHistoryCursor(
              answeredAt: entries.last.answeredAt,
              id: entries.last.id,
            )
          : null,
    );
  });

  @override
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) =>
      _detailDao
          .watchMoveTargetRows(sourceDeckId)
          .map(
            (rows) => candidatesInTreeOrder(
              [for (final row in rows) deckTreeNodeOf(row)],
              (node, path) =>
                  CardMoveTarget(id: node.id, name: node.name, path: path),
            ),
          )
          .mapDatabaseErrors();

  /// The draft passed [CardDraft.check], which holds the tag rules, so a
  /// refusal here is a bug: throwing rolls the whole write back.
  Future<void> _replaceTags(String cardId, CardDraft draft, DateTime at) async {
    final result = await _tags.replaceForCard(
      cardId: cardId,
      names: draft.tagNames,
      now: at,
    );
    if (result case Rejected(:final reason)) {
      throw StateError('tags refused a checked draft: $reason');
    }
  }

  /// A card deck left with no card is unset again (BR-DECK-015, invariant 29).
  Future<void> _unsetEmptied(Set<String> deckIds, DateTime at) async {
    for (final deckId in deckIds) {
      if (await _dao.holdsCards(deckId)) continue;
      await _dao.setDeckContentType(deckId, DeckContentType.unset.name, at);
    }
  }

  /// One transaction. Nothing inside catches: a throw leaves it, Drift rolls
  /// every row of the write back together, and the error leaves as
  /// `mapDatabaseError`'s [Failure].
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
