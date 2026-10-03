import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' hide CardDraft;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The state the card transfer tests share. A fresh database and a deck tree
// are opened in each test by [useCardTransferFixture]; the files that use it
// run one test at a time, so the state is never shared between two tests.

DateTime transferNow() => DateTime(2026, 9, 26);

late AppDatabase db;
late DeckRepositoryImpl decks;
late CardTransferRepositoryImpl cards;
late DeckEntity root;
late DeckEntity leaf;

Future<int> countRows(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

T okOf<T>(Outcome<T, CardRejection> result) =>
    (result as Ok<T, CardRejection>).value;

CardRejection reasonOf(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

/// Opens the database and the `r` > `l` deck tree before each test, and
/// closes the database after it.
void useCardTransferFixture() {
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: transferNow);
    cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: transferNow),
        TagRepositoryImpl(db, now: transferNow),
        now: transferNow,
      ),
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());
}
