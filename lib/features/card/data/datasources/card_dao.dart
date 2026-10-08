import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/core/text/stored_text.dart';

part 'card_dao.g.dart';

/// Row access for `card`, plus the reads and writes of the owning `deck` row
/// that card writes need (`card_row_queries.drift`). It returns Drift rows,
/// never domain entities, and runs inside the caller's transaction. A card
/// or deck in the Trash is out of reach of every write (spec §8).
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/card_row_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
    'package:memox/core/database/queries/delete_batch_queries.drift',
  },
)
final class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.attachedDatabase);

  Future<CardRow?> findRow(String id) => liveCardRow(id).getSingleOrNull();

  /// The active cards among [ids], read in chunks (BE-C2).
  Future<List<CardRow>> liveRows(Set<String> ids) async => [
    for (final chunk in idChunks(ids)) ...await liveCardsIn(chunk).get(),
  ];

  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The active decks among [ids], read in chunks (BE-C2).
  Future<List<Deck>> deckRows(Set<String> ids) async => [
    for (final chunk in idChunks(ids)) ...await liveDecksIn(chunk).get(),
  ];

  /// The folded faces of the live cards of [deckId] (BR-TRANSFER-003).
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async => {
    for (final row in await liveCardFacesOfDeck(deckId).get())
      (front: row.frontFolded, back: row.backFolded),
  };

  /// The live direct sub-decks of [parentId], in sibling order.
  Future<List<LiveChildDecksResult>> childDecks(String parentId) =>
      liveChildDecks(parentId).get();

  /// The folded faces of the live cards of each live direct sub-deck of
  /// [parentId] (BR-TRANSFER-003), keyed by deck id.
  Future<Map<String, Set<CardFoldedPair>>> foldedPairsUnder(
    String parentId,
  ) async {
    final byDeck = <String, Set<CardFoldedPair>>{};
    for (final row in await liveCardFacesUnder(parentId).get()) {
      (byDeck[row.deckId] ??= {}).add((
        front: row.frontFolded,
        back: row.backFolded,
      ));
    }
    return byDeck;
  }

  /// How many live cards [deckId] holds.
  Future<int> liveCount(String deckId) =>
      liveCardCountOfDeck(deckId).getSingle();

  /// The live cards of [deckId], or those among [ids], by `created_at`, then
  /// `id` (BR-TRANSFER-010). [ids] are read in chunks, and the whole set is
  /// ordered once they are all in (BE-C2).
  Future<List<CardRow>> exportRows(String deckId, Set<String>? ids) async {
    if (ids == null) return exportCardsOfDeck(deckId).get();
    final rows = [
      for (final chunk in idChunks(ids))
        ...await exportCardsIn(deckId, chunk).get(),
    ];
    // Each chunk is ordered on its own; the export's order is the whole
    // set's.
    return rows..sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  Future<void> insertCard({
    required String id,
    required String deckId,
    required CardDraft draft,
    required DateTime now,
  }) => createCard(
    _contentOf(draft).copyWith(
      id: Value(id),
      deckId: Value(deckId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );

  /// The content of [draft], never its flag: the flag is set by the person
  /// or the system on the card as it is (BR-CARD-009), not by a draft that
  /// may predate either (DEV-220).
  Future<void> updateContent(String id, CardDraft draft, DateTime now) =>
      updateLiveCard(
        _contentOf(draft)
            .copyWith(isFlagged: const Value.absent(), updatedAt: Value(now)),
        id,
      );

  /// [id] goes to the Trash as the item root of the batch [batchId]
  /// (BR-TRASH-001). The row stays as it is otherwise; only a purge deletes
  /// it, and its schedule, logs and tag links with it.
  Future<void> moveToTrash(String id, String batchId, DateTime now) async {
    await insertDeleteBatch(batchId, 'card', id, now);
    await markCardDeleted(batchId, id);
  }

  /// The card of [batchId] when the batch holds one: the card the person
  /// deleted, still marked with that batch (BR-TRASH-001). Null when the
  /// batch is gone or holds a deck.
  Future<CardRow?> itemOf(String batchId) =>
      cardOfBatch(batchId).getSingleOrNull();

  /// The roots of [deckIds], active or in the Trash: a restore checks a card
  /// against the root of its deck, which may be in the Trash (BR-TRASH-006).
  /// Read in chunks (BE-C2).
  Future<Set<String>> rootIdsOf(Set<String> deckIds) async => {
    for (final chunk in idChunks(deckIds))
      ...await deckRootsInAnyState(chunk).get(),
  };

  /// Fires once, then after every write to the decks, the cards or the
  /// batches: where the cards of a Trash selection may go follows all three
  /// (E2).
  Stream<void> restoreTargetChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.card,
    attachedDatabase.deleteBatches,
  ]);

  /// Whether [deckId] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006).
  Future<bool> isDeckInTrash(String deckId) =>
      deckIsInTrash(deckId).getSingle();

  /// [cardId] comes back from the batch [batchId] into [deckId], then the
  /// batch row goes, which the key would otherwise cascade (BR-TRASH-007).
  /// A restore stamps [updatedAt], as a move does; an Undo passes none and
  /// the card keeps its own (trash spec D9).
  Future<void> restoreFromBatch(
    String batchId,
    String cardId, {
    required String deckId,
    DateTime? updatedAt,
  }) async {
    await restoreCard(
      CardCompanion(
        deleteBatchId: const Value(null),
        deckId: Value(deckId),
        updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
      ),
      cardId,
      batchId,
    );
    await dropDeleteBatch(batchId);
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      closeSessionsTouchingBatch(now, batchId);

  /// Moves [ids] into [deckId], in chunks (BE-C2).
  Future<void> moveCards(Set<String> ids, String deckId, DateTime now) async {
    for (final chunk in idChunks(ids)) {
      await moveLiveCardsIn(deckId, now, chunk);
    }
  }

  /// Writes only the cards whose flag differs from [isFlagged], in chunks
  /// (BE-C2).
  Future<void> setFlagged(Set<String> ids, bool isFlagged, DateTime now) async {
    final flag = isFlagged ? 1 : 0;
    for (final chunk in idChunks(ids)) {
      await flagLiveCardsIn(flag, now, chunk);
    }
  }
}

/// The columns a draft sets: sides in their stored form (trimmed, NFC) with
/// their folded forms computed in Dart (schema.md), blank optional fields
/// stored as null (BE-C5).
CardCompanion _contentOf(CardDraft draft) => CardCompanion(
  front: Value(storedText(draft.front)),
  back: Value(storedText(draft.back)),
  frontFolded: Value(foldText(draft.front)),
  backFolded: Value(foldText(draft.back)),
  example: Value(storedTextOrNull(draft.example)),
  hint: Value(storedTextOrNull(draft.hint)),
  pronunciation: Value(storedTextOrNull(draft.pronunciation)),
  isFlagged: Value(draft.isFlagged ? 1 : 0),
);
