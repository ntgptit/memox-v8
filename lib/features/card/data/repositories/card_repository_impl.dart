import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// Every write reads the rows its rules need and writes inside one
/// transaction, which the schedule row joins (BR-CARD-004).
final class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(this._db, this._schedules, {DateTime Function()? now})
    : _dao = CardDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final CardDao _dao;
  final DateTime Function() _now;

  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required String front,
    required String back,
    String? example,
    String? hint,
    String? pronunciation,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final content = CardEntity.checkContent(front: front, back: back);
      if (content case Rejected(:final reason)) return Rejected(reason);
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
      await _dao.insertCard(
        id: id,
        deckId: deckId,
        front: front,
        back: back,
        example: example,
        hint: hint,
        pronunciation: pronunciation,
        now: at,
      );
      await _schedules.initializeCard(cardId: id);
      if (contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(_toEntity((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<void, CardRejection>> deleteCard({required String cardId}) {
    final at = _now();
    return _write(() async {
      final card = await _dao.findRow(cardId);
      if (card == null) return const Rejected(CardRejection.notFound);
      await _dao.deleteCard(cardId);
      // A card deck left empty is unset again (BR-DECK-015, invariant 29).
      if (!await _dao.holdsCards(card.deckId)) {
        await _dao.setDeckContentType(
          card.deckId,
          DeckContentType.unset.name,
          at,
        );
      }
      return const Ok(null);
    });
  }

  /// One transaction. Nothing inside catches: a throw leaves it, Drift rolls
  /// the card, its schedule row and the deck's content type back together,
  /// and the error leaves as `mapDatabaseError`'s [Failure].
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
