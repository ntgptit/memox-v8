import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'tombstone_rules.dart';

/// The statements that read tombstones on purpose, by `file#member`, each
/// with its reason (trash spec §11). A statement that reads active content
/// gets the filter, not an entry.
const _readsTombstones = <String, String>{
  'lib/core/database/queries/sync_deck_queries.drift#syncDeckRow':
      'sync uploads a deck in any state: a deck in the Trash carries its '
      'delete_batch_id to the server (ADR-013)',
  'lib/core/database/queries/sync_deck_queries.drift#deleteSyncedDeck':
      'a deck the server tombstoned goes in any state, in the Trash too '
      '(ADR-013)',
  'lib/core/database/queries/sync_deck_queries.drift#acknowledgeDeck':
      'the server acknowledges a pushed deck in any state, a deck in the '
      'Trash too (ADR-013)',
  'lib/core/database/tables/sync.drift#card_tags_sync_delete':
      'a link change queues its card in any state, a card in the Trash too; '
      'the check only keeps a card delete from turning into an upsert (SB-S3)',
  'lib/core/database/queries/sync_card_schedule_queries.drift#syncRootSchedulerOf':
      "the order of spec §3.4 compares against the card's root in any state "
      '(SB-S4)',
  'lib/core/database/queries/sync_card_queries.drift#syncCardRow':
      'sync uploads a card in any state: a card in the Trash carries its '
      'delete_batch_id to the server (SB-S2)',
  'lib/core/database/queries/sync_card_queries.drift#ensureCardSchedules':
      'every card has a schedule row, a card in the Trash too, as a local '
      'card keeps its row when trashed (BR-CARD-004, SB-S2)',
  'lib/core/database/queries/sync_outbox_queries.drift#seedDeckOutbox':
      'a new anonymous user uploads every deck, a deck in the Trash too, '
      'with its delete_batch_id (auth spec #12)',
  'lib/core/database/queries/sync_outbox_queries.drift#seedCardOutbox':
      'a new anonymous user uploads every card, a card in the Trash too, '
      'with its delete_batch_id (auth spec #12)',
  'lib/core/database/queries/sync_card_queries.drift#deleteSyncedCard':
      'a card the server tombstoned goes in any state, in the Trash too '
      '(SB-S2)',
  'lib/core/database/queries/sync_card_queries.drift#acknowledgeCard':
      'the server acknowledges a pushed card in any state, a card in the '
      'Trash too (SB-S2)',
  'lib/core/database/migrations/nfc_text_migration.dart#_normalizeDecks':
      'migration v4 → v5 puts every stored name in NFC, a deck in the Trash '
      'too, since a restore brings it back (BE-C5)',
  'lib/core/database/migrations/nfc_text_migration.dart#_normalizeCards':
      'migration v4 → v5 puts every stored face in NFC, a card in the Trash '
      'too, since a restore brings it back (BE-C5)',
  'lib/core/database/queries/trash_queries.drift#trashDeckForest':
      'the origin of an entry walks decks in the Trash too (BR-TRASH-012)',
  'lib/core/database/queries/trash_queries.drift#trashBlockersOf':
      "a purge looks for anything left in a batch's decks, in the Trash or "
      'not (BR-TRASH-010)',
  'lib/core/database/tables/srs.drift#review_log_no_delete':
      'asks whether the card row is still there, tombstone or not: only a '
      "purge's cascade may delete a review log",
  'lib/core/database/queries/card_row_queries.drift#deckRootsInAnyState':
      'a restore checks a card against the root of its deck, which may be in '
      'the Trash (BR-TRASH-006)',
  'lib/core/database/queries/deck_row_queries.drift#nextSiblingPositionUnder':
      "D9: a new sibling's position counts the tombstones, so an Undo finds "
      'its place free',
  'lib/core/database/queries/deck_row_queries.drift#deckSubtreeHeight':
      "D10: a subtree's height counts the tombstones that move with it",
  'lib/core/database/queries/deck_row_queries.drift#reRootDeckSubtree':
      'D10: the tombstones of a subtree move with it (BR-TRASH-007)',
  'lib/core/database/queries/deck_row_queries.drift#deckInAnyState':
      "a restore checks its item against the item's own root, which may be "
      'in the Trash too (BR-TRASH-006)',
  'lib/core/database/queries/srs_queries.drift#deleteTreeSchedules':
      'trash spec D11: a reset or a scheduler change rewrites the schedules of the '
      "tree's tombstones too",
  'lib/core/database/queries/srs_queries.drift#insertTreeSchedules':
      'trash spec D11: a reset or a scheduler change rewrites the schedules of the '
      "tree's tombstones too",
};

/// BR-TRASH-002 over the real `lib/`. Each rule is proven on planted sources
/// in `tombstone_rules_test.dart`.
void main() {
  final sources = readQuerySources(Directory.current);

  test('every read of card or deck leaves the tombstones out, or says why '
      'it reads them (BR-TRASH-002)', () {
    expect(tombstoneViolations(sources, _readsTombstones), isEmpty);
  });

  test('every entry of the allowlist still excuses a statement', () {
    expect(staleAllowlistEntries(sources, _readsTombstones), isEmpty);
  });
}
