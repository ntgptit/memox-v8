import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/test_database.dart';

// Raw inserts: `tags` imports no feature (ADR-011 import map `tags → ∅`), so
// its tests do not either.

/// A root, a card sub-deck `leaf`, and the cards [cardIds] in it.
Future<void> _cards(AppDatabase db, List<String> cardIds) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES ('leaf', 'leaf', 'r', 'r', 2, 'card', 0, 0, 0)",
  );
  for (final id in cardIds) {
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES (?, 'leaf', 'f', 'b', 0, 0)",
      [id],
    );
  }
}

/// Gives [cardId] [count] tags named `own <cardId> <n>`.
Future<void> _tagged(AppDatabase db, String cardId, int count) async {
  for (var n = 0; n < count; n++) {
    final id = '$cardId-tag-$n';
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, ?, 0)",
      [id, 'own $cardId $n', 'own $cardId $n'],
    );
    await db.customStatement(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      [cardId, id],
    );
  }
}

Future<List<String>> _tagNamesOf(AppDatabase db, String cardId) async {
  final rows = await db
      .customSelect(
        'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
        'WHERE ct.card_id = ? ORDER BY t.name_folded',
        variables: [Variable(cardId)],
      )
      .get();
  return [for (final row in rows) row.read<String>('name')];
}

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

TagRejection? _reasonOf(Outcome<void, TagRejection> result) => switch (result) {
  Ok() => null,
  Rejected(:final reason) => reason,
};

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;
  setUp(() {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  group('attachByName', () {
    test('creates the tag once and links every card (BR-TAG-001)', () async {
      await _cards(db, ['c1', 'c2']);

      final result = await tags.attachByName(
        cardIds: {'c1', 'c2'},
        name: '  Noun ',
      );

      expect(_reasonOf(result), isNull);
      expect(await _tagNamesOf(db, 'c1'), ['Noun']);
      expect(await _tagNamesOf(db, 'c2'), ['Noun']);
      expect(await _count(db, 'tags'), 1);
    });

    test(
      'reuses the tag whose folded name matches, keeping its spelling',
      () async {
        await _cards(db, ['c1', 'c2']);
        await tags.attachByName(cardIds: {'c1'}, name: 'Động Từ');

        await tags.attachByName(cardIds: {'c2'}, name: 'động từ');

        expect(await _count(db, 'tags'), 1);
        expect(await _tagNamesOf(db, 'c2'), ['Động Từ']);
      },
    );

    test(
      'is idempotent for a card that already carries the tag (BR-CARD-011)',
      () async {
        await _cards(db, ['c1']);
        await tags.attachByName(cardIds: {'c1'}, name: 'Noun');

        final result = await tags.attachByName(cardIds: {'c1'}, name: 'noun');

        expect(_reasonOf(result), isNull);
        expect(await _count(db, 'card_tags'), 1);
      },
    );

    test('refuses a name the tag rule refuses, writing nothing', () async {
      await _cards(db, ['c1']);
      final before = await totalChanges(db);

      final result = await tags.attachByName(cardIds: {'c1'}, name: '   ');

      expect(_reasonOf(result), TagRejection.blankName);
      expect(await totalChanges(db), before);
    });

    test('one card at 10 tags refuses the whole batch, writing nothing (BR-TAG-002)', () async {
      await _cards(db, ['full', 'free']);
      await _tagged(db, 'full', 10);
      final before = await totalChanges(db);

      final result = await tags.attachByName(
        cardIds: {'full', 'free'},
        name: 'Noun',
      );

      expect(_reasonOf(result), TagRejection.tooManyTags);
      expect(await totalChanges(db), before);
      expect(await _tagNamesOf(db, 'free'), isEmpty);
    });

    test('a card that already carries the tag is not over the limit', () async {
      await _cards(db, ['full']);
      await _tagged(db, 'full', 9);
      await tags.attachByName(cardIds: {'full'}, name: 'Noun');

      final result = await tags.attachByName(cardIds: {'full'}, name: 'NOUN');

      expect(_reasonOf(result), isNull);
    });

    test('a missing card refuses the batch with notFound', () async {
      await _cards(db, ['c1']);
      final before = await totalChanges(db);

      final result = await tags.attachByName(
        cardIds: {'c1', 'gone'},
        name: 'Noun',
      );

      expect(_reasonOf(result), TagRejection.notFound);
      expect(await totalChanges(db), before);
    });
  });

  group('detach', () {
    test(
      'unlinks the tag from the cards and keeps the tag (BR-TAG-003)',
      () async {
        await _cards(db, ['c1', 'c2']);
        await tags.attachByName(cardIds: {'c1', 'c2'}, name: 'Noun');
        final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
            .read<String>('id');

        final result = await tags.detach(cardIds: {'c1', 'c2'}, tagId: tagId);

        expect(_reasonOf(result), isNull);
        expect(await _count(db, 'card_tags'), 0);
        expect(await _count(db, 'tags'), 1);
      },
    );

    test('a card without the tag is not an error', () async {
      await _cards(db, ['c1', 'c2']);
      await tags.attachByName(cardIds: {'c1'}, name: 'Noun');
      final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
          .read<String>('id');

      final result = await tags.detach(cardIds: {'c1', 'c2'}, tagId: tagId);

      expect(_reasonOf(result), isNull);
    });

    test('a missing card or tag answers notFound, writing nothing', () async {
      await _cards(db, ['c1']);
      await tags.attachByName(cardIds: {'c1'}, name: 'Noun');
      final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
          .read<String>('id');
      final before = await totalChanges(db);

      expect(
        _reasonOf(await tags.detach(cardIds: {'c1', 'gone'}, tagId: tagId)),
        TagRejection.notFound,
      );
      expect(
        _reasonOf(await tags.detach(cardIds: {'c1'}, tagId: 'gone')),
        TagRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
  });

  group('replaceForCard', () {
    test('makes the card carry exactly the names given', () async {
      await _cards(db, ['c1']);
      await tags.replaceForCard(cardId: 'c1', names: ['Noun', 'Food']);

      final result = await tags.replaceForCard(
        cardId: 'c1',
        names: ['food', 'Verb'],
      );

      expect(_reasonOf(result), isNull);
      expect(await _tagNamesOf(db, 'c1'), ['Food', 'Verb']);
      expect(
        await _count(db, 'tags'),
        3,
        reason: 'Noun stays in the catalog (BR-TAG-003)',
      );
    });

    test(
      'more than 10 distinct names answer tooManyTags, writing nothing',
      () async {
        await _cards(db, ['c1']);
        final before = await totalChanges(db);

        final result = await tags.replaceForCard(
          cardId: 'c1',
          names: [for (var n = 0; n < 11; n++) 'tag $n'],
        );

        expect(_reasonOf(result), TagRejection.tooManyTags);
        expect(await totalChanges(db), before);
      },
    );

    test('a missing card answers notFound', () async {
      final result = await tags.replaceForCard(cardId: 'gone', names: ['Noun']);
      expect(_reasonOf(result), TagRejection.notFound);
    });
  });

  test('an empty batch writes nothing', () async {
    final before = await totalChanges(db);

    final attached = await tags.attachByName(cardIds: {}, name: 'Verb');
    final detached = await tags.detach(cardIds: {}, tagId: 'no such tag');

    expect(attached, isA<Ok<void, TagRejection>>());
    expect(detached, isA<Ok<void, TagRejection>>());
    expect(await totalChanges(db), before);
  });
}
