import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' hide CardDraft;
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

import '../../../support/test_database.dart';

// R9: the card being written is kept on this device, per key, never synced
// and never logged.

void main() {
  late AppDatabase db;
  late CardDraftRepositoryImpl drafts;
  var clock = DateTime.utc(2026, 10, 3, 9);

  setUp(() {
    db = openTestDatabase();
    clock = DateTime.utc(2026, 10, 3, 9);
    drafts = CardDraftRepositoryImpl(db, now: () => clock);
  });
  tearDown(() => db.close());

  const hangul = CardDraft(
    front: '밥',
    back: 'Cơm',
    example: 'Tôi ăn cơm.',
    pronunciation: 'bap',
    isFlagged: true,
    tagNames: ['món ăn', 'topik 1'],
  );
  final deckKey = CardDraftKey.create('deck-1');

  Future<int> count() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM card_draft')
              .getSingle())
          .read<int>('n');

  test('nothing is kept at first', () async {
    expect(await drafts.read(deckKey), isNull);
  });

  test('a draft reads back as it was saved, Hangul, null fields and tags '
      'included', () async {
    await drafts.save(deckKey, hangul);

    final kept = await drafts.read(deckKey);
    expect(kept!.sameContentAs(hangul), isTrue);
    expect(kept.hint, isNull);
    expect(kept.tagNames, ['món ăn', 'topik 1']);
  });

  test('saving again replaces the draft of that key', () async {
    await drafts.save(deckKey, hangul);
    await drafts.save(deckKey, const CardDraft(front: 'a', back: 'b'));

    expect(await count(), 1);
    final kept = await drafts.read(deckKey);
    expect((kept!.front, kept.back, kept.isFlagged), ('a', 'b', false));
  });

  test('each key keeps its own draft', () async {
    final editKey = CardDraftKey.edit('card-1');
    await drafts.save(deckKey, const CardDraft(front: 'new', back: 'n'));
    await drafts.save(editKey, const CardDraft(front: 'edit', back: 'e'));

    expect((await drafts.read(deckKey))!.front, 'new');
    expect((await drafts.read(editKey))!.front, 'edit');
  });

  test('clear drops one key; clearing a missing one changes nothing', () async {
    final editKey = CardDraftKey.edit('card-1');
    await drafts.save(deckKey, hangul);
    await drafts.save(editKey, hangul);

    await drafts.clear(deckKey);
    await drafts.clear(deckKey);

    expect(await drafts.read(deckKey), isNull);
    expect(await drafts.read(editKey), isNotNull);
  });

  test('a draft older than 30 days goes with the next save', () async {
    await drafts.save(CardDraftKey.edit('old'), hangul);
    clock = clock.add(const Duration(days: 29));
    await drafts.save(CardDraftKey.create('a'), hangul);
    expect(await drafts.read(CardDraftKey.edit('old')), isNotNull);

    clock = clock.add(const Duration(days: 2));
    await drafts.save(CardDraftKey.create('b'), hangul);

    expect(await drafts.read(CardDraftKey.edit('old')), isNull);
    expect(await drafts.read(CardDraftKey.create('a')), isNotNull);
    expect(await drafts.read(CardDraftKey.create('b')), isNotNull);
  });

  test('a row nothing in the app wrote reads as no draft', () async {
    await db.customStatement(
      "INSERT INTO card_draft (draft_key, front, back, extras, tags, updated_at) "
      "VALUES ('create:x', 'f', 'b', 'not json', '[]', 0)",
    );

    expect(await drafts.read('create:x'), isNull);
  });

  test('drafts never sync: saving queues nothing', () async {
    await drafts.save(deckKey, hangul);

    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });
}
