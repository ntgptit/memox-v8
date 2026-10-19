import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';
import 'package:memox/features/transfer/presentation/controllers/card_export_controller.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/held_bug_capture.dart';
import '../../../support/test_database.dart';

// A bug while the file is built or shared never leaves the sheet preparing
// for good: Export comes back with the failure note, and the bug is
// reported (closing review 2026-10-18, check similar on LIB-6).

/// The read dies on a bug, not a Failure.
final class _BuggyRead implements CardTransferRepository {
  @override
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  }) async => throw StateError('a bug');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The share sheet dies on a bug.
final class _BuggyShare implements ExportShareRepository {
  @override
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  ) async => throw StateError('a bug');
}

void main() {
  late AppDatabase db;
  late CardExportScope scope;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db);
    final root = await decks.root('r');
    final leaf = await decks.sub(root.id, 'Nhà hàng');
    await insertCard(db, id: 'a', deckId: leaf.id, front: 'menu', back: 'x');
    scope = CardExportScope.deck(
      deckId: leaf.id,
      deckName: 'Nhà hàng',
      cardCount: 1,
    );
  });
  tearDown(() => db.close());

  ({CardExportController sheet, CardExportState Function() state}) open({
    CardTransferRepository? cards,
    ExportShareRepository? share,
  }) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(
          FakeDayClock(DateTime(2026, 9, 26, 9)),
        ),
        transferFileRepositoryProvider.overrideWithValue(
          TransferFileRepositoryImpl(
            run: <Q, R>(callback, message) async => callback(message),
          ),
        ),
        exportShareRepositoryProvider.overrideWithValue(
          share ?? FakeExportShare(),
        ),
        if (cards != null)
          cardTransferRepositoryProvider.overrideWithValue(cards),
      ],
    );
    addTearDown(container.dispose);
    final provider = cardExportControllerProvider(scope);
    container.listen(provider, (_, _) {});
    return (
      sheet: container.read(provider.notifier),
      state: () => container.read(provider),
    );
  }

  test('a bug while the file is built says it could not be prepared', () async {
    final reported = captureReportedBugs();
    final (:sheet, :state) = open(cards: _BuggyRead());

    await sheet.export();

    expect(state().isPreparing, isFalse);
    expect(state().problem, CardExportProblem.prepareFailed);
    expectOneBugReported(reported);
  });

  test('a bug from the share sheet says the share failed', () async {
    final reported = captureReportedBugs();
    final (:sheet, :state) = open(share: _BuggyShare());

    await sheet.export();

    expect(state().isPreparing, isFalse);
    expect(state().problem, CardExportProblem.shareFailed);
    expectOneBugReported(reported);
  });
}
