import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/migrations/nfc_text_migration.dart';

import '../../support/test_database.dart';

// BE-C5: the v4 → v5 step reads the library a page at a time, so a large
// library upgrades in bounded memory (PR #112 review), and every page is
// normalised, the last partial one included.

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'every card is normalised when the library spans several pages',
    () async {
      await db.customStatement(
        'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
        'scheduler_type, scheduler_version, generation, sibling_position, '
        "created_at, updated_at) VALUES ('R', 'R', NULL, 'R', 1, 'deck', "
        "'eight_box', 1, 1, 0, 0, 0)",
      );
      await db.customStatement(
        'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
        "sibling_position, created_at, updated_at) VALUES ('L', 'Công', "
        "'R', 'R', 2, 'card', 0, 0, 0)",
      );
      for (var i = 0; i < 5; i++) {
        await db.customStatement(
          'INSERT INTO card (id, deck_id, front, back, front_folded, '
          "back_folded, created_at, updated_at) VALUES (?, 'L', 'công', "
          "'b', 'công', 'b', 0, 0)",
          ['c$i'],
        );
      }

      await normalizeStoredText(db, pageSize: 2);

      final rows = await db
          .customSelect('SELECT DISTINCT front, front_folded FROM card')
          .get();
      expect(
        [for (final row in rows) row.data],
        [
          {'front': 'công', 'front_folded': 'công'},
        ],
      );
      final deck = await db
          .customSelect("SELECT name FROM deck WHERE id = 'L'")
          .getSingle();
      expect(deck.read<String>('name'), 'Công');
    },
  );
}
