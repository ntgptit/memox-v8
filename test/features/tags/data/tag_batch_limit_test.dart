import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/datasources/tag_dao.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/test_database.dart';

// BE-C2: a tag batch over more cards than SQLite binds in one statement
// works (local backend spec 2026-09-27 §5). Raw inserts: `tags` imports no
// feature (ADR-011 import map `tags → ∅`).

const _many = 33000;

final _ids = {for (var i = 0; i < _many; i++) 'c${'$i'.padLeft(5, '0')}'};

Future<void> _seed(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'scheduler_type, scheduler_version, generation, sibling_position, '
    "created_at, updated_at) VALUES ('r', 'r', NULL, 'r', 1, 'deck', "
    "'eight_box', 1, 1, 0, 0, 0)",
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    "sibling_position, created_at, updated_at) VALUES ('leaf', 'leaf', 'r', "
    "'r', 2, 'card', 0, 0, 0)",
  );
  await db.customStatement(
    'WITH RECURSIVE n(i) AS (SELECT 0 UNION ALL SELECT i + 1 FROM n '
    'WHERE i + 1 < ?) '
    'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
    "SELECT printf('c%05d', i), 'leaf', 'f', 'b', i, i FROM n",
    [_many],
  );
}

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;
  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 27));
    await _seed(db);
  });
  tearDown(() => db.close());

  test('attaching a tag to more cards than SQLite binds links them all, and '
      'a detach unlinks them all', () async {
    expect(
      await tags.attachByName(cardIds: _ids, name: 'Noun'),
      isA<Ok<void, TagRejection>>(),
    );
    expect(await _count(db, 'card_tags'), _many);

    final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
        .read<String>('id');
    expect(
      await tags.detach(cardIds: _ids, tagId: tagId),
      isA<Ok<void, TagRejection>>(),
    );
    expect(await _count(db, 'card_tags'), 0);
  });

  test(
    'the tag counts and live count of a large selection are read whole',
    () async {
      final dao = TagDao(db);
      await tags.attachByName(cardIds: _ids, name: 'Noun');
      await tags.attachByName(cardIds: _ids.take(10).toSet(), name: 'Verb');

      final counts = await dao.tagCounts(_ids);

      expect(counts, hasLength(_many));
      expect(counts.values.where((n) => n == 2), hasLength(10));
      expect(await dao.liveCardCount(_ids), _many);
      expect(await dao.liveCardIds({..._ids, 'gone'}), _ids);
      expect(
        await dao.cardsCarrying(_ids, (await dao.findByFoldedName('verb'))!.id),
        hasLength(10),
      );
    },
  );
}
