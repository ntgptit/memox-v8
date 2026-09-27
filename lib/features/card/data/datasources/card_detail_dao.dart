import 'package:memox/core/database/app_database.dart';

/// The reads of one card (`card_queries.drift`). They write nothing
/// (BR-CARD-013).
final class CardDetailDao {
  CardDetailDao(this._db);

  final AppDatabase _db;

  /// The card, its schedule row and its tags; empty once the card is gone or
  /// in the Trash. Emits again when any of them changes.
  Stream<List<CardDetailResult>> watchDetail(String cardId) =>
      _db.cardDetail(cardId).watch();

  /// Up to [limit] log rows after [afterAnsweredAt], [afterId], newest first,
  /// in one statement. Empty when the card is not active; one row with a
  /// null log when it has no answer there.
  Future<List<CardHistoryRow>> historyRows(
    String cardId, {
    required DateTime? afterAnsweredAt,
    required String? afterId,
    required int limit,
  }) => _db.cardHistoryPage(afterAnsweredAt, afterId, cardId, limit).get();

  /// The decks of the source's tree, candidates marked (BR-CARD-010).
  Stream<List<DeckForestRow>> watchMoveTargetRows(String sourceDeckId) =>
      _db.cardMoveTargets(sourceDeckId, null).watch();

  /// The decks of [rootId]'s tree, candidates marked: where cards of that
  /// root may go back (BR-TRASH-006).
  Future<List<DeckForestRow>> restoreTargetRows(String rootId) =>
      _db.cardMoveTargets(null, rootId).get();
}
