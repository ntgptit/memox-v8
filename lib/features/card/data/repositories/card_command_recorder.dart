import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_outbox.dart';

/// The sync commands and patches card writes record (BE-E7 spec §4.2), inside
/// the caller's transaction and after its rows change.
final class CardCommandRecorder {
  CardCommandRecorder(AppDatabase db, {DateTime Function()? now})
    : _outbox = SyncOutboxWriter(db, now: now);

  final SyncOutboxWriter _outbox;

  /// CREATE_CARD with the card's stored values.
  Future<void> created(CardRow row) =>
      _outbox.command(SyncCommandType.createCard, {
        'id': row.id,
        'deckId': row.deckId,
        'front': row.front,
        'back': row.back,
        'example': row.example,
        'hint': row.hint,
        'pronunciation': row.pronunciation,
      }, subject: SyncEntityRef.card(row.id));

  Future<void> contentEdited(String cardId) =>
      _outbox.patch(SyncEntityType.card, cardId, SyncPatchGroup.content);

  Future<void> flagged(Set<String> cardIds) async {
    for (final cardId in cardIds) {
      await _outbox.patch(SyncEntityType.card, cardId, SyncPatchGroup.flag);
    }
  }

  Future<void> moved(Set<String> cardIds, String targetDeckId) =>
      _outbox.command(SyncCommandType.moveCards, {
        'cardIds': cardIds.toList()..sort(),
        'targetDeckId': targetDeckId,
      });

  /// DELETE_CARDS: [items] pairs each card with its own batch id.
  Future<void> deleted(List<Map<String, Object?>> items, DateTime at) =>
      _outbox.command(SyncCommandType.deleteCards, {
        'items': items,
        'deletedAt': toWireTime(at),
      });

  Future<void> undone(String batchId) => _outbox.command(
    SyncCommandType.undoCardDeletion,
    {'batchId': batchId},
    subject: SyncEntityRef.deleteBatch(batchId),
  );
}
