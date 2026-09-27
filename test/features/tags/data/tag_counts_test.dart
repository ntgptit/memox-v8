import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 steps 1-3 and 6: every tag of the library with the active cards
// carrying it, in the library or in one deck (BR-TAG-003, BR-TAG-010; tag
// management spec §5).

List<(String, int)> _rows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;

  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 26));
    await insertTagDecks(db);
  });
  tearDown(() => db.close());

  Future<List<(String, int)>> catalog([String searchTerm = '']) async =>
      _rows(await tags.watchTagCounts(searchTerm: searchTerm).first);

  test('the catalog lists every tag by its folded name, each with its active '
      'cards, one with none at 0 (UC-TAG-001 step 1, BR-TAG-003)', () async {
    for (final id in ['c1', 'c2', 'c3']) {
      await insertTagCard(db, id);
    }
    await insertTag(db, 't1', 'TOPIK I', cardIds: ['c1', 'c2']);
    await insertTag(db, 't2', 'bài 12', cardIds: ['c3']);
    await insertTag(db, 't3', 'động từ', cardIds: ['c1']);
    await insertTag(db, 't4', 'tạm');

    // By `name_folded`, code point by code point: `topik i` before `tạm`,
    // and `đ` after every ASCII letter. By the stored name `TOPIK I` would
    // come first.
    expect(await catalog(), [
      ('bài 12', 1),
      ('TOPIK I', 2),
      ('tạm', 0),
      ('động từ', 1),
    ]);
  });

  test('a card in the Trash counts for no tag, and counts again once it is '
      'back (BR-TAG-010)', () async {
    await insertTagCard(db, 'c1');
    await insertTagCard(db, 'c2');
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2']);
    final seen = <List<(String, int)>>[];
    final subscription = tags.watchTagCounts().listen(
      (counts) => seen.add(_rows(counts)),
    );
    await pumpEventQueue();
    expect(seen.last, [('noun', 2)]);

    await setCardBatch(db, 'c1', 'b1');
    await pumpEventQueue();
    expect(seen.last, [('noun', 1)]);

    await setCardBatch(db, 'c1', null);
    await pumpEventQueue();
    expect(seen.last, [('noun', 2)]);
    await subscription.cancel();
  });

  test('the search keeps the tags whose folded name holds the folded term: '
      'ĐỘNG TỪ finds động từ, dong tu finds nothing, a blank term finds every '
      'tag (UC-TAG-001 step 3, BR-TAG-003, BR-TAG-011)', () async {
    await insertTag(db, 't1', 'động từ');
    await insertTag(db, 't2', 'danh từ');

    expect(await catalog('ĐỘNG TỪ'), [('động từ', 0)]);
    expect(await catalog('  từ '), [('danh từ', 0), ('động từ', 0)]);
    expect(await catalog('dong tu'), isEmpty);
    expect(await catalog('   '), [('danh từ', 0), ('động từ', 0)]);
  });

  test('% and _ in a search term are plain characters (BR-TAG-003)', () async {
    await insertTag(db, 't1', '100%');
    await insertTag(db, 't2', '1000');
    await insertTag(db, 't3', 'a_b');
    await insertTag(db, 't4', 'axb');

    expect(await catalog('%'), [('100%', 0)]);
    expect(await catalog('_'), [('a_b', 0)]);
  });

  test("in a deck every tag is listed, each with that deck's active cards, "
      '0 included (UC-TAG-001 step 6; tag management spec D3)', () async {
    await insertTagCard(db, 'c1');
    await insertTagCard(db, 'c2', deckId: 'other');
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2']);
    await insertTag(db, 't2', 'verb', cardIds: ['c2']);

    Future<List<(String, int)>> inDeck(String deckId) async =>
        _rows(await tags.watchTagCounts(deckId: deckId).first);

    expect(await inDeck('leaf'), [('noun', 1), ('verb', 0)]);
    expect(await inDeck('other'), [('noun', 1), ('verb', 1)]);
  });

  test(
    'a tag of another profile is not listed (tag management spec D13)',
    () async {
      await insertTag(db, 't1', 'mine');
      await insertTag(db, 't2', 'theirs', ownerId: 'someone');

      expect(await catalog(), [('mine', 0)]);
    },
  );

  test('the counts of a deck follow the tags, their links and the cards: a '
      'new tag, then a card moved out (BR-TAG-003)', () async {
    await insertTagCard(db, 'c1');
    final seen = <List<(String, int)>>[];
    final subscription = tags
        .watchTagCounts(deckId: 'leaf')
        .listen((counts) => seen.add(_rows(counts)));
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await pumpEventQueue();
    expect(seen.last, [('noun', 1)]);

    await setCardDeck(db, 'c1', 'other');
    await pumpEventQueue();
    expect(seen.last, [('noun', 0)]);
    await subscription.cancel();
  });
}
