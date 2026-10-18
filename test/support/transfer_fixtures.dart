import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';

import 'deck_fixtures.dart';
import 'test_database.dart';

// The transfer use-case tests run over the real repositories on one fixed
// clock; this is their shared setup.

/// The clock the transfer use-case tests share.
DateTime transferNow() => DateTime(2026, 9, 26);

/// The value of an accepted result.
T transferOk<T>(Outcome<T, TransferRejection> result) =>
    (result as Ok<T, TransferRejection>).value;

/// The reason of a refused result.
TransferRejection transferReason(Outcome<Object?, TransferRejection> result) =>
    (result as Rejected<Object?, TransferRejection>).reason;

/// An empty database, the real card-transfer repository over it, the deck
/// `r` and its child `Nhà hàng`.
typedef TransferWorld = ({
  AppDatabase db,
  DeckRepositoryImpl decks,
  CardTransferRepositoryImpl cards,
  DeckEntity root,
  DeckEntity leaf,
});

Future<TransferWorld> openTransferWorld() async {
  final db = openTestDatabase();
  final decks = DeckRepositoryImpl(db, now: transferNow);
  final cards = CardTransferRepositoryImpl(
    db,
    CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: transferNow),
      TagRepositoryImpl(db, now: transferNow),
      DeckTreeDataSource(db),
      now: transferNow,
    ),
    decks,
  );
  final root = await decks.root('r');
  final leaf = await decks.sub(root.id, 'Nhà hàng');
  return (db: db, decks: decks, cards: cards, root: root, leaf: leaf);
}
