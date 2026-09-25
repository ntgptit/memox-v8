import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';

import '../support/deck_fixtures.dart';
import '../support/test_database.dart';

// Progress spec D8: the change stream the read models share. The Study tab's
// stream tests prove its listen-first order (Study Home spec D7).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
  });
  tearDown(() => db.close());

  test('fires once when listened to, before any write', () async {
    var firings = 0;
    final subscription = tableChanges(db, [db.deck]).listen((_) => firings++);
    await pumpEventQueue();

    expect(firings, 1);
    await subscription.cancel();
  });

  test('a transaction that writes its tables twice fires once', () async {
    await decks.root('Korean');
    await decks.root('English');
    var firings = 0;
    final subscription = tableChanges(db, [db.deck]).listen((_) => firings++);
    await pumpEventQueue();

    await db.transaction(() async {
      for (final name in ['Korean', 'English']) {
        await db.customUpdate(
          'UPDATE deck SET name = ? WHERE name = ?',
          variables: [Variable<String>('$name 2'), Variable<String>(name)],
          updates: {db.deck},
        );
      }
    });
    await pumpEventQueue();

    expect(firings, 2);
    await subscription.cancel();
  });

  test('a write to another table fires nothing', () async {
    var firings = 0;
    final subscription = tableChanges(db, [db.card]).listen((_) => firings++);
    await pumpEventQueue();

    await decks.root('Korean');
    await pumpEventQueue();

    expect(firings, 1);
    await subscription.cancel();
  });

  test('a cancelled stream fires no more', () async {
    var firings = 0;
    final subscription = tableChanges(db, [db.deck]).listen((_) => firings++);
    await pumpEventQueue();
    await subscription.cancel();

    await decks.root('Korean');
    await pumpEventQueue();

    expect(firings, 1);
  });
}
