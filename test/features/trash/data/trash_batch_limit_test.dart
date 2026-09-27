import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';

import '../../../support/test_database.dart';

// BE-C2: a purge of more chosen batches than SQLite binds in one statement
// reads each batch once, oldest first (local backend spec 2026-09-27 §5).

const _many = 33000;

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'purge candidates of a large choice are each batch once, oldest first',
    () async {
      final epoch = DateTime.utc(2026, 9, 1);
      await db.customStatement(
        'WITH RECURSIVE n(i) AS (SELECT 0 UNION ALL SELECT i + 1 FROM n '
        'WHERE i + 1 < ?) '
        'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
        "SELECT printf('b%05d', i), 'card', printf('c%05d', i), ? + i FROM n",
        [_many, epoch.millisecondsSinceEpoch ~/ 1000],
      );
      // One batch past the retention, and also chosen: it must come once.
      final old = epoch.subtract(const Duration(days: 40));
      await db.customStatement(
        'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
        "VALUES ('old', 'card', 'x', ?)",
        [old.millisecondsSinceEpoch ~/ 1000],
      );
      final chosen = {
        for (var i = 0; i < _many; i++) 'b${'$i'.padLeft(5, '0')}',
        'old',
      };

      final rows = await TrashDao(db).purgeCandidates(
        chosen: chosen,
        cutoff: epoch.subtract(const Duration(days: 30)),
      );

      expect(rows, hasLength(_many + 1));
      expect(rows.first.id, 'old');
      expect({for (final row in rows) row.id}, hasLength(_many + 1));
    },
  );
}
