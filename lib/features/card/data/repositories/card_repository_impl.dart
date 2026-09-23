import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
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
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final TagRepository _tags;
  final CardDao _dao;
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
      return Ok(_toEntity((await _dao.findRow(id))!));
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
  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  }) {
    final at = _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      final rows = await _dao.liveRows(cardIds);
      if (rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      await _dao.deleteCards(cardIds);
      await _unsetEmptied({for (final row in rows) row.deckId}, at);
      return const Ok(null);
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
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

CardEntity _toEntity(CardRow row) => CardEntity(
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  isFlagged: row.isFlagged == 1,
  example: row.example,
  hint: row.hint,
  pronunciation: row.pronunciation,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);
