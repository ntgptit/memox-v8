import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:memox/features/transfer/presentation/controllers/card_export_controller.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/test_database.dart';

// The export sheet's states over the real card repository, the real
// encoders run inline, and a fake share sheet (UC-TRANSFER-002).

/// The encoders run inline, and each write waits for [hold] when it is set.
final class _HeldFiles implements TransferFileRepository {
  final _inner = TransferFileRepositoryImpl(
    run: <Q, R>(callback, message) async => callback(message),
  );
  Completer<void>? hold;

  @override
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  ) async {
    await hold?.future;
    return _inner.write(rows, format);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Throws on the read, the way a locked database does (E3), until
/// [isBroken] turns false.
final class _BrokenRead implements CardTransferRepository {
  _BrokenRead(this._cards);

  final CardTransferRepository _cards;
  var isBroken = true;

  @override
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  }) async {
    if (isBroken) throw const UnknownDatabaseFailure(cause: 'locked');
    return _cards.exportSnapshot(deckId: deckId, cardIds: cardIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckEntity leaf;
  late FakeExportShare share;
  late _HeldFiles files;
  late CardExportScope wholeDeck;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db);
    final root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    await insertCard(db, id: 'a', deckId: leaf.id, front: 'menu', back: 'x');
    await insertCard(db, id: 'b', deckId: leaf.id, front: 'bill', back: 'y');
    share = FakeExportShare();
    files = _HeldFiles();
    wholeDeck = CardExportScope.deck(
      deckId: leaf.id,
      deckName: 'Nhà hàng',
      cardCount: 2,
    );
  });
  tearDown(() => db.close());

  ProviderContainer container({
    CardTransferRepository Function(CardTransferRepository)? wrap,
  }) {
    final cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(db, ScheduleRepositoryImpl(db), TagRepositoryImpl(db)),
    );
    final result = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(
          FakeDayClock(DateTime(2026, 9, 26, 9)),
        ),
        transferFileRepositoryProvider.overrideWithValue(files),
        exportShareRepositoryProvider.overrideWithValue(share),
        if (wrap != null)
          cardTransferRepositoryProvider.overrideWithValue(wrap(cards)),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  ({CardExportController sheet, CardExportState Function() state}) open(
    ProviderContainer c,
    CardExportScope scope,
  ) {
    final provider = cardExportControllerProvider(scope);
    c.listen(provider, (_, _) {});
    return (sheet: c.read(provider.notifier), state: () => c.read(provider));
  }

  test(
    'the whole deck is handed over as a CSV named for the deck and today',
    () async {
      final (:sheet, :state) = open(container(), wholeDeck);
      expect(state().format, TransferFormat.csv);

      await sheet.export();

      expect(state().isHandedOver, isTrue);
      expect(share.shared.single.fileName, 'Nhà-hàng-2026-09-26.csv');
    },
  );

  test('the chosen format is the one written (A2)', () async {
    final (:sheet, :state) = open(container(), wholeDeck);

    sheet.chooseFormat(TransferFormat.xlsx);
    await sheet.export();

    expect(share.shared.single.format, TransferFormat.xlsx);
    expect(share.shared.single.fileName, endsWith('.xlsx'));
  });

  test(
    'closing the share sheet is a cancel: the sheet is as it was (A3)',
    () async {
      share.answer = const Ok(ExportShareResult.dismissed);
      final (:sheet, :state) = open(container(), wholeDeck);
      sheet.chooseFormat(TransferFormat.tsv);

      await sheet.export();

      expect(
        (state().format, state().isPreparing, state().problem),
        (TransferFormat.tsv, false, null),
      );
      expect(state().isHandedOver, isFalse);
    },
  );

  test(
    'no share target is final; a share error can be tried again (E1, E2)',
    () async {
      share.answer = const Rejected(TransferRejection.shareUnavailable);
      final (:sheet, :state) = open(container(), wholeDeck);
      await sheet.export();
      expect(state().problem, CardExportProblem.noShareTarget);
      expect(state().canExport, isFalse);

      share.answer = const Rejected(TransferRejection.shareFailed);
      final retry = open(container(), wholeDeck);
      await retry.sheet.export();
      expect(retry.state().problem, CardExportProblem.shareFailed);
      expect(retry.state().canExport, isTrue);

      share.answer = const Ok(ExportShareResult.shared);
      await retry.sheet.export();
      expect(retry.state().isHandedOver, isTrue);
    },
  );

  test('a selection with a card gone meanwhile exports nothing (E6)', () async {
    final (:sheet, :state) = open(
      container(),
      CardExportScope.selection(deckId: leaf.id, ids: {'a', 'gone'}),
    );

    await sheet.export();

    expect(state().problem, CardExportProblem.staleSelection);
    expect(share.shared, isEmpty);
  });

  test(
    'a scope of no card opens on nothing to export and never builds (E5)',
    () async {
      final (:sheet, :state) = open(
        container(),
        CardExportScope.deck(
          deckId: leaf.id,
          deckName: 'Nhà hàng',
          cardCount: 0,
        ),
      );
      expect(state().problem, CardExportProblem.nothingToExport);

      await sheet.export();

      expect(share.shared, isEmpty);
    },
  );

  test('a read that fails says so and Try again builds again (E3)', () async {
    late _BrokenRead broken;
    final (:sheet, :state) = open(
      container(wrap: (cards) => broken = _BrokenRead(cards)),
      wholeDeck,
    );

    await sheet.export();
    expect(state().problem, CardExportProblem.prepareFailed);
    expect(share.shared, isEmpty);

    broken.isBroken = false;
    await sheet.export();
    expect(state().isHandedOver, isTrue);
  });

  test(
    'a second tap while the file is prepared makes no second file (A4)',
    () async {
      files.hold = Completer<void>();
      final (:sheet, :state) = open(container(), wholeDeck);

      final first = sheet.export();
      await pumpEventQueue();
      expect(state().isPreparing, isTrue);
      final second = sheet.export();
      files.hold!.complete();
      await Future.wait([first, second]);

      expect(share.shared, hasLength(1));
    },
  );

  test('closing the sheet while the file is prepared shares nothing', () async {
    files.hold = Completer<void>();
    final c = container();
    final provider = cardExportControllerProvider(wholeDeck);
    final open = c.listen(provider, (_, _) {});
    final writing = c.read(provider.notifier).export();
    await pumpEventQueue();

    open.close();
    await pumpEventQueue();
    files.hold!.complete();
    await writing;

    expect(share.shared, isEmpty);
  });
}
