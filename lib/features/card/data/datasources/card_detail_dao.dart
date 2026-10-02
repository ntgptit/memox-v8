import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'card_detail_dao.g.dart';

/// The reads of one card (`card_queries.drift`). They write nothing
/// (BR-CARD-013).
@DriftAccessor(
  include: {'package:memox/core/database/queries/card_queries.drift'},
)
final class CardDetailDao extends DatabaseAccessor<AppDatabase>
    with _$CardDetailDaoMixin {
  CardDetailDao(super.attachedDatabase);

  /// The card, its schedule row and its tags; empty once the card is gone or
  /// in the Trash. Emits again when any of them changes.
  Stream<List<CardDetailResult>> watchDetail(String cardId) =>
      cardDetail(cardId).watch();

  /// Up to [limit] log rows after [afterAnsweredAt], [afterId], newest first,
  /// in one statement. Empty when the card is not active; one row with a
  /// null log when it has no answer there.
  Future<List<CardHistoryRow>> historyRows(
    String cardId, {
    required DateTime? afterAnsweredAt,
    required String? afterId,
    required int limit,
  }) => cardHistoryPage(afterAnsweredAt, afterId, cardId, limit).get();

  /// The decks of the source's tree, candidates marked (BR-CARD-010).
  Stream<List<CardMoveTargetRow>> watchMoveTargetRows(String sourceDeckId) =>
      cardMoveTargets(sourceDeckId, null).watch();

  /// The decks of [rootId]'s tree, candidates marked: where cards of that
  /// root may go back (BR-TRASH-006).
  Future<List<CardMoveTargetRow>> restoreTargetRows(String rootId) =>
      cardMoveTargets(null, rootId).get();
}
