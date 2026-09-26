import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 step 4 and A1: a rename is planned, then written behind the
// merge guard (BR-TAG-006, BR-TAG-007, BR-TAG-009; tag management spec §6).

Matcher _refused<T>(TagRejection reason) => isA<Rejected<T, TagRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

Matcher _plans(Matcher plan) => isA<Ok<TagRenamePlan, TagRejection>>().having(
  (ok) => ok.value,
  'value',
  plan,
);

Matcher _mergesInto(
  String id,
  String name, {
  required int cardCount,
  required int mergedCardCount,
}) => _plans(
  isA<TagRenameMerge>()
      .having(
        (merge) => (merge.target.id, merge.target.name, merge.target.cardCount),
        'target',
        (id, name, cardCount),
      )
      .having(
        (merge) => merge.mergedCardCount,
        'mergedCardCount',
        mergedCardCount,
      ),
);

final _ok = isA<Ok<void, TagRejection>>();

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
    for (final id in ['c1', 'c2', 'c3', 'c4']) {
      await insertTagCard(db, id);
    }
  });
  tearDown(() => db.close());

  test('a name that trims to the stored one is unchanged: planned, and '
      'written as nothing (tag management spec §6)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    final before = await totalChanges(db);

    expect(
      await tags.planRename(tagId: 't1', name: '  noun '),
      _plans(isA<TagRenameUnchanged>()),
    );
    expect(await tags.renameTag(tagId: 't1', name: '  noun '), _ok);
    expect(await totalChanges(db), before);
  });

  test('a case-only change renames the tag in place: same id, same links '
      '(BR-TAG-006)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2']);

    expect(
      await tags.planRename(tagId: 't1', name: 'Noun'),
      _plans(isA<TagRenameRename>()),
    );
    expect(await tags.renameTag(tagId: 't1', name: ' Noun '), _ok);

    expect(await tagRowsOf(db), [('t1', 'Noun', 'noun')]);
    expect(await linksOf(db), ['c1:t1', 'c2:t1']);
  });

  test('a diacritic makes a new name: hoc renamed Học folds to học '
      '(BR-TAG-001, BR-SEARCH-002)', () async {
    await insertTag(db, 't1', 'hoc', cardIds: ['c1']);

    expect(
      await tags.planRename(tagId: 't1', name: 'Học'),
      _plans(isA<TagRenameRename>()),
    );
    expect(await tags.renameTag(tagId: 't1', name: 'Học'), _ok);

    expect(await tagRowsOf(db), [('t1', 'Học', 'học')]);
    expect(await linksOf(db), ['c1:t1']);
  });

  test('a name another tag folds to plans a merge into it: the target with '
      'its active cards, and the active cards of both, once each '
      '(BR-TAG-007; tag management spec D6)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1', 'c2', 'c3']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2', 'c3', 'c4']);
    await setCardBatch(db, 'c3', 'b3');

    expect(
      await tags.planRename(tagId: 't1', name: ' VERB '),
      _mergesInto('t2', 'Verb', cardCount: 2, mergedCardCount: 3),
    );
  });

  test('the plan and the write refuse a bad name before a gone tag, and '
      'write nothing (BR-TAG-001; tag management spec §6)', () async {
    await insertTag(db, 't1', 'noun');
    final before = await totalChanges(db);

    for (final (tagId, name, reason) in [
      ('t1', '   ', TagRejection.blankName),
      ('t1', 'x' * 51, TagRejection.nameTooLong),
      ('t1', 'a\tb', TagRejection.controlCharacter),
      ('missing', '', TagRejection.blankName),
      ('missing', 'verb', TagRejection.notFound),
    ]) {
      expect(
        await tags.planRename(tagId: tagId, name: name),
        _refused<TagRenamePlan>(reason),
      );
      expect(
        await tags.renameTag(tagId: tagId, name: name),
        _refused<void>(reason),
      );
    }
    expect(await totalChanges(db), before);
  });

  test('a confirmed merge moves the links of active and trashed cards to '
      'the target, once per card, deletes the source and leaves the target '
      'as it was; a trashed card that carried both comes back carrying the '
      'target once (BR-TAG-007, BR-TAG-010)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1', 'c2', 'c3']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2', 'c3', 'c4']);
    await setCardBatch(db, 'c3', 'b3');

    expect(
      await tags.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      _ok,
    );

    expect(await tagRowsOf(db), [('t2', 'Verb', 'verb')]);
    expect(await linksOf(db), ['c1:t2', 'c2:t2', 'c3:t2', 'c4:t2']);
    await setCardBatch(db, 'c3', null);
    expect(_rows(await tags.watchTagCounts().first), [('Verb', 4)]);
  });

  test('a merge never takes a card past 10 tags: one carrying both among 10 '
      'keeps 9, one carrying the source among 10 trades it for the target '
      '(BR-TAG-002)', () async {
    for (var index = 0; index < 8; index++) {
      await insertTag(db, 'f$index', 'filler $index', cardIds: ['c1', 'c2']);
    }
    await insertTag(db, 'f8', 'filler 8', cardIds: ['c2']);
    await insertTag(db, 't1', 'verbs', cardIds: ['c1', 'c2']);
    await insertTag(db, 't2', 'verb', cardIds: ['c1']);

    expect(
      await tags.renameTag(tagId: 't1', name: 'VERB', mergeIntoTagId: 't2'),
      _ok,
    );

    final links = await linksOf(db);
    expect(links.where((link) => link.startsWith('c1:')), [
      for (var index = 0; index < 8; index++) 'c1:f$index',
      'c1:t2',
    ]);
    expect(links.where((link) => link.startsWith('c2:')), [
      for (var index = 0; index < 9; index++) 'c2:f$index',
      'c2:t2',
    ]);
  });

  test('the plan said rename, then the card editor made a tag with that '
      'name: the write is mergeNotConfirmed and writes nothing (tag '
      'management spec D5)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1']);
    expect(
      await tags.planRename(tagId: 't1', name: 'verb'),
      _plans(isA<TagRenameRename>()),
    );
    await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
    final before = await totalChanges(db);

    expect(
      await tags.renameTag(tagId: 't1', name: 'verb'),
      _refused<void>(TagRejection.mergeNotConfirmed),
    );
    expect(await totalChanges(db), before);
  });

  test(
    'a merge confirmed into another tag than the one the name folds to '
    'is mergeNotConfirmed and writes nothing (tag management spec D5)',
    () async {
      await insertTag(db, 't1', 'verbs', cardIds: ['c1']);
      await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
      await insertTag(db, 't3', 'noun', cardIds: ['c3']);
      final before = await totalChanges(db);

      expect(
        await tags.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't3'),
        _refused<void>(TagRejection.mergeNotConfirmed),
      );
      expect(await totalChanges(db), before);
    },
  );

  test('a confirmed merge whose target is gone renames the tag in place '
      '(tag management spec D8)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
    await db.customUpdate(
      "DELETE FROM tags WHERE id = 't2'",
      updates: {db.tags, db.cardTags},
    );

    expect(
      await tags.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      _ok,
    );

    expect(await tagRowsOf(db), [('t1', 'verb', 'verb')]);
    expect(await linksOf(db), ['c1:t1']);
  });

  test('a merge that fails after moving the links leaves both tags and '
      'every link as they were (UC-TAG-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingTagDelete());
    addTearDown(failing.close);
    final broken = TagRepositoryImpl(failing);
    await insertTagDecks(failing);
    for (final id in ['c1', 'c2']) {
      await insertTagCard(failing, id);
    }
    await insertTag(failing, 't1', 'verbs', cardIds: ['c1', 'c2']);
    await insertTag(failing, 't2', 'Verb', cardIds: ['c2']);

    await expectLater(
      broken.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    expect(await tagRowsOf(failing), [
      ('t1', 'verbs', 'verbs'),
      ('t2', 'Verb', 'verb'),
    ]);
    expect(await linksOf(failing), ['c1:t1', 'c2:t1', 'c2:t2']);
  });

  test("another profile's tag is not renamed, and its name is not a clash "
      '(tag management spec D13)', () async {
    await insertTag(db, 't1', 'verbs');
    await insertTag(db, 'x1', 'theirs', ownerId: 'someone');
    await insertTag(db, 'x2', 'verb', ownerId: 'someone');
    final before = await totalChanges(db);

    expect(
      await tags.planRename(tagId: 'x1', name: 'mine'),
      _refused<TagRenamePlan>(TagRejection.notFound),
    );
    expect(
      await tags.renameTag(tagId: 'x1', name: 'mine'),
      _refused<void>(TagRejection.notFound),
    );
    expect(await totalChanges(db), before);
    expect(
      await tags.planRename(tagId: 't1', name: 'verb'),
      _plans(isA<TagRenameRename>()),
    );
  });

  test('a rename and a merge write tags and card_tags and nothing else '
      '(BR-TAG-009)', () async {
    await insertStudiedCard(db);
    await setCardBatch(db, 'c1', 'b1');
    await insertTag(db, 't1', 'noun', cardIds: ['s-card', 'c1']);
    await insertTag(db, 't2', 'Verb', cardIds: ['s-card']);
    await insertTag(db, 't3', 'verbs', cardIds: ['s-card', 'c1', 'c2']);
    final before = await rowsOutsideTags(db);

    expect(await tags.renameTag(tagId: 't1', name: 'Noun'), _ok);
    expect(
      await tags.renameTag(tagId: 't3', name: 'verb', mergeIntoTagId: 't2'),
      _ok,
    );

    expect(await rowsOutsideTags(db), before);
  });

  test('the catalog follows a rename and a merge (BR-TAG-003)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
    await insertTag(db, 't3', 'verbs', cardIds: ['c1', 'c2']);
    final seen = <List<(String, int)>>[];
    final subscription = tags.watchTagCounts().listen(
      (counts) => seen.add(_rows(counts)),
    );
    await pumpEventQueue();
    expect(seen.last, [('noun', 1), ('Verb', 1), ('verbs', 2)]);

    await tags.renameTag(tagId: 't1', name: 'Noun');
    await pumpEventQueue();
    expect(seen.last, [('Noun', 1), ('Verb', 1), ('verbs', 2)]);

    await tags.renameTag(tagId: 't3', name: 'verb', mergeIntoTagId: 't2');
    await pumpEventQueue();
    expect(seen.last, [('Noun', 1), ('Verb', 2)]);
    await subscription.cancel();
  });
}
