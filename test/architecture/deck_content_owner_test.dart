import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'tombstone_rules.dart';

/// The writes of `deck.content_type`: the drift query that sets it, and any
/// raw statement that updates the column.
final _contentTypeWrite = RegExp(
  r'setLiveDeckContentType\s*\(|UPDATE\s+deck\s+SET[^;]*\bcontent_type\b',
  caseSensitive: false,
);

/// The files of [sources] outside the deck feature that write a deck's
/// content type (DEV-215).
List<String> contentTypeWritersOutsideDeck(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    if (path.startsWith('lib/features/') &&
        !path.startsWith('lib/features/deck/') &&
        _contentTypeWrite.hasMatch(text))
      path,
];

// BR-DECK-006..008, BR-DECK-015, BR-TRASH-005 (DEV-215): what a deck holds
// decides its content type, and the deck feature is the one owner of that
// rule; another feature that adds or removes a deck's children asks
// `DeckContentRepository.refresh`, never sets the column.
void main() {
  test('a write outside the deck feature is reported, one inside is not', () {
    expect(
      contentTypeWritersOutsideDeck({
        'lib/features/card/data/datasources/card_dao.dart': 'Future<void> set(String id) => setLiveDeckContentType(c, now, id);',
        'lib/features/deck/data/datasources/deck_dao.dart': 'Future<void> set(String id) => setLiveDeckContentType(c, now, id);',
        'lib/core/database/queries/live_row_queries.drift': 'setLiveDeckContentType(:deck_id AS TEXT):\nUPDATE deck SET content_type = :c;',
      }),
      ['lib/features/card/data/datasources/card_dao.dart'],
    );
  });

  test('the deck feature is the only writer of a deck\'s content type', () {
    expect(
      contentTypeWritersOutsideDeck(readQuerySources(Directory.current)),
      isEmpty,
    );
  });
}
