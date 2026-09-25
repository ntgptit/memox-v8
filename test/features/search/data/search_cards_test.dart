import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001: what the card group finds and how it ranks it (Search spec
// §5.2, §5.3, §6.2).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late TagRepositoryImpl tags;
  late SearchRepositoryImpl search;
  late String koreanId;
  late String lessonId;
  final now = DateTime(2026, 9, 25, 9);

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    tags = TagRepositoryImpl(db, now: () => now);
    search = SearchRepositoryImpl(db);
    koreanId = (await decks.root('Korean')).id;
    lessonId = (await decks.sub(koreanId, 'Lesson')).id;
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<LibrarySearchResults> read(String term) =>
      search.watchSearch(foldedTerm: term).first;

  List<String> ids(LibrarySearchResults results) => [
    for (final hit in results.cards) hit.cardId,
  ];

  Future<void> tag(String cardId, String name) async => expect(
    await tags.attachByName(cardIds: {cardId}, name: name),
    isA<Ok<void, TagRejection>>(),
  );

  test('a card is found by its front, its back or the name of one of its '
      'tags; never by its example, hint or pronunciation '
      '(BR-SEARCH-001)', () async {
    await insertCard(db, id: 'front', deckId: lessonId, front: 'học sinh');
    await insertCard(db, id: 'back', deckId: lessonId, back: 'học tập');
    await insertCard(db, id: 'tagged', deckId: lessonId, front: 'homework');
    await tag('tagged', 'Học');
    await insertCard(db, id: 'example', deckId: lessonId, example: 'học');
    await insertCard(db, id: 'hint', deckId: lessonId, hint: 'học');
    await CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => now),
      tags,
      now: () => now,
    ).card(
      lessonId,
      const CardDraft(front: 'e', back: 'f', pronunciation: 'học'),
    );

    expect(ids(await read('học')).toSet(), {'front', 'back', 'tagged'});
  });

  test('công nghệ finds a face written CÔNG NGHỆ, and cong does not find '
      'công: the faces are folded in Dart, accents counting '
      '(BR-SEARCH-002)', () async {
    await insertCard(db, id: 'upper', deckId: lessonId, front: 'CÔNG NGHỆ');
    await insertCard(db, id: 'accent', deckId: lessonId, front: 'công');

    expect(ids(await read('công nghệ')), ['upper']);
    expect(ids(await read('cong')), isEmpty);
  });

  test('exact first, then prefix, then contains: a card takes the best tier '
      'of its front, its back and its tags (BR-SEARCH-004)', () async {
    await insertCard(
      db,
      id: 'contains',
      deckId: lessonId,
      front: 'từ vựng học',
    );
    await insertCard(db, id: 'prefix', deckId: lessonId, back: 'học tập');
    await insertCard(db, id: 'exact', deckId: lessonId, front: 'từ vựng học');
    await tag('exact', 'Học');

    expect(
      [for (final hit in (await read('học')).cards) (hit.cardId, hit.tier)],
      [
        ('exact', SearchTier.exact),
        ('prefix', SearchTier.prefix),
        ('contains', SearchTier.contains),
      ],
    );
  });

  test('a card holding the term in its front, its back and two tags is one '
      'hit and names no tag; one found only through tags names its best '
      'one (BR-SEARCH-006; UC-SEARCH-001 step 5)', () async {
    await insertCard(
      db,
      id: 'everywhere',
      deckId: lessonId,
      front: 'học',
      back: 'học',
    );
    await tag('everywhere', 'Học');
    await tag('everywhere', 'Học tập');
    await insertCard(db, id: 'tags', deckId: lessonId, front: 'homework');
    await tag('tags', 'Học tập');
    await tag('tags', 'Học');

    expect(
      [
        for (final hit in (await read('học')).cards)
          (hit.cardId, hit.matchedTag),
      ],
      [('tags', 'Học'), ('everywhere', null)],
    );
  });

  test("a card's hit shows its faces as written and the path from the root "
      'to its deck (UC-SEARCH-001 step 5)', () async {
    await insertCard(
      db,
      id: 'c1',
      deckId: lessonId,
      front: 'Học sinh',
      back: 'student',
    );

    final hit = (await read('học')).cards.single;

    expect(
      (hit.front, hit.back, hit.deckId),
      ('Học sinh', 'student', lessonId),
    );
    expect([for (final step in hit.deckPath) step.name], ['Korean', 'Lesson']);
    expect(hit.cursor.group, SearchGroup.card);
  });

  test('a card in the Trash, and a deck in the Trash with its cards, are '
      'never found (BR-SEARCH-001; Search spec D8)', () async {
    await insertCard(db, id: 'kept', deckId: lessonId, front: 'học');
    await insertCard(
      db,
      id: 'trashed',
      deckId: lessonId,
      front: 'học',
      deleteBatchId: 'batch',
    );
    final gone = await decks.sub(koreanId, 'Gone');
    await insertCard(
      db,
      id: 'inGoneDeck',
      deckId: gone.id,
      front: 'học',
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', gone.id],
    );

    expect(ids(await read('học')), ['kept']);
  });

  test('% and _ in a term are plain characters, not wildcards '
      '(Search spec D4)', () async {
    await insertCard(db, id: 'percent', deckId: lessonId, front: '100% done');
    await insertCard(db, id: 'digits', deckId: lessonId, front: '1000 done');
    await insertCard(
      db,
      id: 'underscore',
      deckId: lessonId,
      front: 'snake_case',
    );
    await insertCard(db, id: 'space', deckId: lessonId, front: 'snake case');

    expect(ids(await read('100%')), ['percent']);
    expect(ids(await read('e_c')), ['underscore']);
  });

  test('decks and cards order their texts by one rule, code point: ｱ before '
      '𝒜 in both groups (Search spec D5)', () async {
    await decks.sub(koreanId, 'x𝒜');
    await decks.sub(koreanId, 'xｱ');
    await insertCard(db, id: 'script', deckId: lessonId, front: 'x𝒜');
    await insertCard(db, id: 'kana', deckId: lessonId, front: 'xｱ');

    final results = await read('x');

    expect([for (final hit in results.decks) hit.name], ['xｱ', 'x𝒜']);
    expect(ids(results), ['kana', 'script']);
  });
}
