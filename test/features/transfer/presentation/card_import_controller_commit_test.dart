import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_limits_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/read_import_source_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import 'card_import_controller_harness.dart';

// The import wizard's steps over the real repositories and a fake picker
// (UC-TRANSFER-001, IT-NAV-012 step 4).
//
// The commit: duplicates, refusals and failures.

/// Throws on the commit, the way a full disk does (E5), until [isBroken]
/// turns false; holds the commit open while [hold] is pending.
final class _BrokenImport implements CardTransferRepository {
  _BrokenImport(this._cards);

  final CardTransferRepository _cards;
  var isBroken = true;
  Completer<void>? hold;

  @override
  Future<Set<({String front, String back})>> foldedPairs(String deckId) =>
      _cards.foldedPairs(deckId);

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) async {
    await hold?.future;
    if (isBroken) throw const UnknownDatabaseFailure(cause: 'disk full');
    return _cards.importCards(
      deckId: deckId,
      drafts: drafts,
      includeDuplicates: includeDuplicates,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Throws on the duplicate read, the way a locked database does.
final class _BrokenDeckRead implements CardTransferRepository {
  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async =>
      throw const UnknownDatabaseFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Throws on the read, as a codec or an isolate that died does.
final class _ExplodingFiles implements TransferFileRepository {
  @override
  Future<Outcome<SourceTable, TransferRejection>> read(
    TransferSource source, {
    int? sheetIndex,
  }) async => throw StateError('codec exploded');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Throws a bug the card feature never types on the commit, until
/// [isBroken] turns false; then it writes through [_inner].
final class _ThrowingImport implements CardTransferRepository {
  _ThrowingImport(this._inner);

  final CardTransferRepository _inner;
  var isBroken = true;

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) async {
    if (isBroken) throw StateError('writer exploded');
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

void main() {
  useImportFixture();

  test(
    'Back does nothing while the cards are written (IT-NAV-012 step 5)',
    () async {
      late _BrokenImport held;
      final c = container(
        wrap: (cards) => held = _BrokenImport(cards)
          ..isBroken = false
          ..hold = Completer<void>(),
      );
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();

      final writing = wizard.commit();
      await pumpEventQueue();
      expect(draftOf(c).step, CardImportStep.importing);
      expect(wizard.stepBack(), isTrue);
      expect(draftOf(c).step, CardImportStep.importing);

      held.hold!.complete();
      await writing;
      expect(
        c.read(cardImportControllerProvider(leaf.id)),
        isA<CardImportDone>(),
      );
    },
  );

  test('Include duplicates writes them as new cards (A4)', () async {
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

    wizard.setIncludingDuplicates(isIncluding: true);
    expect(draftOf(c).willWrite, 1);
    await wizard.commit();

    final done =
        c.read(cardImportControllerProvider(leaf.id)) as CardImportDone;
    expect(done.summary.written, 1);
    expect(await countCards(db), 2);
  });

  test(
    'a deck that gained sub-decks refuses the commit: the rejects result (E4)',
    () async {
      final c = container();
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();
      await decks.sub(leaf.id, 'child');

      await wizard.commit();

      final failed =
          c.read(cardImportControllerProvider(leaf.id)) as CardImportFailed;
      expect(failed.isTargetRejected, isTrue);
    },
  );

  test(
    'a write that fails keeps the preview, and Try again commits it again (E5)',
    () async {
      late _BrokenImport broken;
      final c = container(wrap: (cards) => broken = _BrokenImport(cards));
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();

      await wizard.commit();
      final failed =
          c.read(cardImportControllerProvider(leaf.id)) as CardImportFailed;
      expect(
        (failed.isTargetRejected, failed.draft.step),
        (false, CardImportStep.preview),
      );
      expect(await countCards(db), 0);

      broken.isBroken = false;
      await wizard.retry();
      expect(
        c.read(cardImportControllerProvider(leaf.id)),
        isA<CardImportDone>(),
      );
    },
  );

  test('a preview whose deck read throws sets a typed problem and frees the '
      'wizard (SP2a 2.22)', () async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(() async => picked),
        previewImportUseCaseProvider.overrideWithValue(
          PreviewImportUseCase(_BrokenDeckRead()),
        ),
      ],
    );
    addTearDown(c.dispose);
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();

    await wizard.previewRows();

    expect(draftOf(c).step, CardImportStep.columns);
    expect(draftOf(c).problem, TransferRejection.previewFailed);
    expect(draftOf(c).isBusy, isFalse);
  });

  test(
    'a read that throws is unreadable, not a stuck spinner (SP2a 2.22)',
    () async {
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          importFilePickerProvider.overrideWithValue(() async => picked),
          readImportSourceUseCaseProvider.overrideWithValue(
            ReadImportSourceUseCase(_ExplodingFiles()),
          ),
        ],
      );
      addTearDown(c.dispose);
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();

      await wizard.readSource();

      expect(draftOf(c).step, CardImportStep.source);
      expect(draftOf(c).problem, TransferRejection.unreadableFile);
      expect(draftOf(c).isBusy, isFalse);
    },
  );

  test('a source over the cap is refused at step 1 with its own reason '
      '(SP2a 2.23)', () async {
    picked = (name: 'big.csv', bytes: Uint8List(TransferLimits.maxBytes + 1));
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();

    await wizard.readSource();

    expect(draftOf(c).step, CardImportStep.source);
    expect(draftOf(c).problem, TransferRejection.tooLarge);
    expect(draftOf(c).isBusy, isFalse);
  });

  test(
    'the header toggle follows what the first row names (SP2a 2.24)',
    () async {
      final c = container();
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

      picked = pickedFile('vocab.csv', 'front,back\nmenu,thực đơn\n');
      await wizard.chooseFile();
      await wizard.readSource();
      expect(draftOf(c).hasHeaderRow, isTrue);

      picked = pickedFile('vocab.csv', 'menu,thực đơn\nbill,hóa đơn\n');
      await wizard.chooseFile();
      await wizard.readSource();
      expect(draftOf(c).hasHeaderRow, isFalse);
      expect(draftOf(c).table!.rows.first, ['menu', 'thực đơn']);
    },
  );

  test('a commit that throws something that is not a Failure frees the '
      'wizard on the failed result (SP2a 2.25)', () async {
    late _ThrowingImport writer;
    final c = container(wrap: (cards) => writer = _ThrowingImport(cards));
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    await wizard.previewRows();

    await wizard.commit();

    final failed =
        c.read(cardImportControllerProvider(leaf.id)) as CardImportFailed;
    expect(failed.isTargetRejected, isFalse);
    expect(failed.draft.isBusy, isFalse);
    expect(failed.draft.step, CardImportStep.preview);
    expect(await countCards(db), 0);

    // The failure was the writer's, not the preview's: Try again writes it.
    writer.isBroken = false;
    await wizard.retry();

    expect(
      c.read(cardImportControllerProvider(leaf.id)),
      isA<CardImportDone>(),
    );
    expect(await countCards(db), 1);
  });
}
