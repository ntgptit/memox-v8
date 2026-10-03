import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' hide CardDraft;
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/trash_fixtures.dart';
import 'card_import_controller_harness.dart';

// The import wizard's steps over the real repositories and a fake picker
// (UC-TRANSFER-001, IT-NAV-012 step 4).
//
// Undo import, and starting a fresh import.

/// Holds the commit's write until [release] completes.
final class _GatedImport implements CardTransferRepository {
  _GatedImport(this._inner);

  final CardTransferRepository _inner;
  final release = Completer<void>();

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) async {
    await release.future;
    return _inner.importCards(
      deckId: deckId,
      drafts: drafts,
      includeDuplicates: includeDuplicates,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<int> countActiveCards(AppDatabase db) async =>
    (await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
            )
            .getSingle())
        .read<int>('n');

void main() {
  useImportFixture();

  test(
    'commit holds the wizard busy on the importing step before its first '
    'await, so Cancel and a second commit cannot slip in (SP2a 2.25)',
    () async {
      late _GatedImport gated;
      final c = container(wrap: (cards) => gated = _GatedImport(cards));
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();

      final commit = wizard.commit();

      // Read before any await has let the write run.
      expect(draftOf(c).step, CardImportStep.importing);
      expect(draftOf(c).isBusy, isTrue);
      await wizard.commit();
      expect(await countCards(db), 0);

      gated.release.complete();
      await commit;
      expect(
        c.read(cardImportControllerProvider(leaf.id)),
        isA<CardImportDone>(),
      );
      expect(await countCards(db), 1);
    },
  );

  Future<List<String>> importTwo(
    ProviderContainer c,
    CardImportController wizard,
  ) async {
    picked = pickedFile(
      'vocab.csv',
      'front,back\nmenu,thực đơn\nbill,hóa đơn\n',
    );
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    await wizard.previewRows();
    await wizard.commit();
    final done =
        c.read(cardImportControllerProvider(leaf.id)) as CardImportDone;
    expect(done.summary.writtenIds, hasLength(2));
    return done.summary.writtenIds;
  }

  test('Undo import moves the imported cards to the Trash, a batch each, '
      'skipping one already gone (SP2a 2.25)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    final [first, second] = await importTwo(c, wizard);
    await trashCardRow(db, first);

    final outcome = await wizard.undoImport() as Ok<BulkOutcome, CardRejection>;

    expect(outcome.value.done, {second});
    expect(outcome.value.skipped, {first});
    expect(outcome.value.batchIds, hasLength(1));
    expect(await countActiveCards(db), 0);
  });

  test('Undo import after an imported card changed still moves every one to '
      'the Trash, and each stays restorable (SP2a 2.25)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    final ids = await importTwo(c, wizard);
    await db.customStatement("UPDATE card SET front = 'edited' WHERE id = ?", [
      ids.first,
    ]);

    final outcome = await wizard.undoImport() as Ok<BulkOutcome, CardRejection>;

    expect(outcome.value.done, ids.toSet());
    expect(outcome.value.skipped, isEmpty);
    expect(await countActiveCards(db), 0);

    final restored = await CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: importNow),
      TagRepositoryImpl(db, now: importNow),
      now: importNow,
    ).restoreCards(batchIds: outcome.value.batchIds.toSet(), deckId: leaf.id);
    expect(outcome.value.batchIds, hasLength(2));
    expect(restored, isA<Ok<void, CardRejection>>());
    expect(await countActiveCards(db), 2);
  });

  test('Import another file starts a fresh step 1', () async {
    await insertCard(
      db,
      id: 'x',
      deckId: leaf.id,
      front: 'menu',
      back: 'thực đơn',
    );
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    await wizard.previewRows();
    expect(draftOf(c).willWrite, 0);

    await wizard.commit();
    expect(draftOf(c).step, CardImportStep.preview);

    wizard.startOver();
    expect(draftOf(c).source, isNull);
  });
}
