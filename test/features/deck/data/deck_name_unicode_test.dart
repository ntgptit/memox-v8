import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

// BE-C5: a deck name is stored in one Unicode form (local backend spec
// 2026-09-27 §4).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test('a deck name is stored in NFC on create and rename (BE-C5)', () async {
    final created = await repo.createRootDeck(
      name: 'Tie\u0302\u0301ng Vie\u0323\u0302t',
      schedulerType: SchedulerType.eightBox,
    );
    final deck = (created as Ok<DeckEntity, DeckRejection>).value;
    expect(deck.name, 'Ti\u1EBFng Vi\u1EC7t');

    await repo.renameDeck(deckId: deck.id, name: ' \u1107\u1161\u11B8 ');

    final row = await db
        .customSelect(
          'SELECT name FROM deck WHERE id = ?',
          variables: [Variable(deck.id)],
        )
        .getSingle();
    expect(row.read<String>('name'), '\uBC25');
  });
}
