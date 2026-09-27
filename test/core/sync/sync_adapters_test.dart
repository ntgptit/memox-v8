import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDatabase();
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, study_config, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, '{\"cardLimit\":5}', 0, 0, 0), "
      "('D', 'd', 'R', 'R', 2, 'card', NULL, NULL, NULL, NULL, 0, 0, 0)",
    );
  });
  tearDown(() => db.close());

  test('a card from the server gets its folded columns and version', () async {
    await CardSyncAdapter(db).upsertFromServer({
      'id': 'k1',
      'deckId': 'D',
      'front': 'CÔNG',
      'back': 'Work',
      'isFlagged': true,
      'createdAt': '2026-09-28T00:00:00Z',
      'updatedAt': '2026-09-28T00:00:00Z',
    }, 7);

    final card = await (db.select(
      db.card,
    )..where((c) => c.id.equals('k1'))).getSingle();
    expect(card.frontFolded, 'công');
    expect(card.backFolded, 'work');
    expect(card.isFlagged, 1);
    expect(card.serverVersion, 7);
  });

  test('patch fields are read at push time', () async {
    await CardSyncAdapter(db).upsertFromServer({
      'id': 'k1',
      'deckId': 'D',
      'front': 'a',
      'back': 'b',
      'createdAt': '2026-09-28T00:00:00Z',
      'updatedAt': '2026-09-28T00:00:00Z',
    }, 1);

    expect(await CardSyncAdapter(db).readPatch('k1', 'flag'), {
      'isFlagged': false,
    });
    expect(await CardSyncAdapter(db).readPatch('k1', 'content'), {
      'front': 'a',
      'back': 'b',
      'example': null,
      'hint': null,
      'pronunciation': null,
    });
    expect(await DeckSyncAdapter(db).readPatch('R', 'study_options'), {
      'studyConfig': '{"cardLimit":5}',
    });
    expect(await CardSyncAdapter(db).readPatch('gone', 'flag'), isNull);
  });
}
