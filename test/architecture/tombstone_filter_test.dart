import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'tombstone_rules.dart';

/// The statements that read tombstones on purpose, by `file#member`, each
/// with its reason (trash spec §11). A statement that reads active content
/// gets the filter, not an entry.
const _readsTombstones = <String, String>{
  'lib/core/database/tables/srs.drift#review_log_no_delete':
      'asks whether the card row is still there, tombstone or not: only a '
      "purge's cascade may delete a review log",
  'lib/features/deck/data/datasources/deck_dao.dart#nextSiblingPosition':
      "D9: a new sibling's position counts the tombstones, so an Undo finds "
      'its place free',
  'lib/features/deck/data/datasources/deck_dao.dart#subtreeHeight':
      "D10: a subtree's height counts the tombstones that move with it",
  'lib/features/deck/data/datasources/deck_dao.dart#moveSubtree':
      'D10: the tombstones of a subtree move with it (BR-TRASH-007)',
  'lib/features/search/data/datasources/search_dao.dart#_cardHits':
      "filtered by `_live`, the search's one predicate (Search spec D8), "
      'which the scan cannot read through',
  'lib/features/search/data/datasources/search_dao.dart#deckForest':
      "filtered by `_live`, the search's one predicate (Search spec D8), "
      'which the scan cannot read through',
  'lib/features/srs/data/datasources/srs_dao.dart#replaceTreeSchedules':
      'D11: a reset or a scheduler change rewrites the schedules of the '
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
