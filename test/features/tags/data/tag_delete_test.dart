import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 step 5: deleting a tag removes its links and its row, and no
// card (BR-TAG-008, BR-TAG-009; tag management spec §7).

final _ok = isA<Ok<void, TagRejection>>();

Matcher _refused(TagRejection reason) => isA<Rejected<void, TagRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

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
    for (final id in ['c1', 'c2', 'c3']) {
      await insertTagCard(db, id);
    }
  });
  tearDown(() => db.close());

  Future<List<String>> cardIds() async => [
    for (final row
        in await db.customSelect('SELECT id FROM card ORDER BY id').get())
      row.read<String>('id'),
  ];

  test('a delete removes the tag and its links, those of a card in the Trash '
      'included, and every card stays (BR-TAG-008, BR-TAG-010)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2', 'c3']);
    await insertTag(db, 't2', 'verb', cardIds: ['c1']);
    await setCardBatch(db, 'c3', 'b3');

    expect(await tags.deleteTag(tagId: 't1'), _ok);

    expect(await tagRowsOf(db), [('t2', 'verb', 'verb')]);
    expect(await linksOf(db), ['c1:t2']);
    expect(await cardIds(), ['c1', 'c2', 'c3']);
  });

  test(
    'a tag whose only card is in the Trash counts 0 and deletes like any '
    'other: the card comes back without it (BR-TAG-008, BR-TAG-010)',
    () async {
      await insertTag(db, 't1', 'old', cardIds: ['c3']);
      await setCardBatch(db, 'c3', 'b3');
      expect(_rows(await tags.watchTagCounts().first), [('old', 0)]);

      expect(await tags.deleteTag(tagId: 't1'), _ok);
      await setCardBatch(db, 'c3', null);

      expect(await linksOf(db), isEmpty);
      expect(await tags.watchTagCounts().first, isEmpty);
    },
  );

  test("a tag that is gone, or another profile's, is notFound and nothing "
      'is written (tag management spec D13)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await insertTag(db, 'x1', 'theirs', ownerId: 'someone');
    final before = await totalChanges(db);

    expect(
      await tags.deleteTag(tagId: 'missing'),
      _refused(TagRejection.notFound),
    );
    expect(await tags.deleteTag(tagId: 'x1'), _refused(TagRejection.notFound));
    expect(await totalChanges(db), before);
  });

  test('a delete that fails leaves the tag and its links as they were '
      '(UC-TAG-001 E5)', () async {
    final failing = openTestDatabase(interceptor: FailingTagDelete());
    addTearDown(failing.close);
    final broken = TagRepositoryImpl(failing);
    await insertTagDecks(failing);
    await insertTagCard(failing, 'c1');
    await insertTag(failing, 't1', 'noun', cardIds: ['c1']);

    await expectLater(
      broken.deleteTag(tagId: 't1'),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    expect(await tagRowsOf(failing), [('t1', 'noun', 'noun')]);
    expect(await linksOf(failing), ['c1:t1']);
  });

  test(
    'a delete writes tags and card_tags and nothing else (BR-TAG-009)',
    () async {
      await insertStudiedCard(db);
      await setCardBatch(db, 'c1', 'b1');
      await insertTag(db, 't1', 'noun', cardIds: ['s-card', 'c1', 'c2']);
      final before = await rowsOutsideTags(db);

      expect(await tags.deleteTag(tagId: 't1'), _ok);

      expect(await rowsOutsideTags(db), before);
    },
  );

  test(
    'the catalog and the counts of a deck follow a delete (BR-TAG-003)',
    () async {
      await insertTag(db, 't1', 'noun', cardIds: ['c1']);
      await insertTag(db, 't2', 'verb', cardIds: ['c1', 'c2']);
      final catalog = <List<(String, int)>>[];
      final inDeck = <List<(String, int)>>[];
      final subscriptions = [
        tags.watchTagCounts().listen((counts) => catalog.add(_rows(counts))),
        tags
            .watchTagCounts(deckId: 'leaf')
            .listen((counts) => inDeck.add(_rows(counts))),
      ];
      await pumpEventQueue();
      expect(catalog.last, [('noun', 1), ('verb', 2)]);

      await tags.deleteTag(tagId: 't2');
      await pumpEventQueue();
      expect(catalog.last, [('noun', 1)]);
      expect(inDeck.last, [('noun', 1)]);
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
}
