import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';

import '../../../support/test_database.dart';

// BR-TRASH-009, BR-TRASH-010: a purge takes the chosen batches that still
// exist and every expired one, each once, oldest first, ties by id.
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<void> batch(String id, DateTime at) => db.customStatement(
    'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
    "VALUES (?, 'card', ?, ?)",
    [id, 'c-$id', at.millisecondsSinceEpoch ~/ 1000],
  );

  test(
    'chosen and expired batches come once, ordered by time then id',
    () async {
      final cutoff = DateTime.utc(2026, 9, 1);
      final expired = cutoff.subtract(const Duration(days: 1));
      final fresh = cutoff.add(const Duration(days: 1));
      await batch('b-expired-2', expired);
      await batch('b-expired-1', expired);
      await batch('b-fresh-chosen', fresh);
      await batch('b-fresh-left', fresh);

      final rows = await TrashDao(db).purgeCandidates(
        chosen: {'b-fresh-chosen', 'b-expired-2', 'b-gone'},
        cutoff: cutoff,
      );

      expect(
        [for (final row in rows) row.id],
        ['b-expired-1', 'b-expired-2', 'b-fresh-chosen'],
      );
    },
  );
}
