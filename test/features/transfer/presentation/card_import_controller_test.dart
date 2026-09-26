import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/commit_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The import wizard's steps over the real repositories and a fake picker
// (UC-TRANSFER-001, IT-NAV-012 step 4).

DateTime _now() => DateTime(2026, 9, 26);

ImportPickedFile _file(String name, String text) =>
    (name: name, bytes: Uint8List.fromList(utf8.encode(text)));

/// Throws on the commit, the way a full disk does (E5), until [isBroken]
/// turns false; holds the commit open while [hold] is pending.
final class _BrokenImport implements CardRepository {
  _BrokenImport(this._cards);

  final CardRepository _cards;
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

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late DeckEntity root;
  late DeckEntity leaf;
  ImportPickedFile? picked;

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    picked = _file(
      'vocab.csv',
      'front,back,tags\nmenu,thực đơn,food\nbill,,\n',
    );
  });
  tearDown(() => db.close());

  ProviderContainer container({CardRepository Function(CardRepository)? wrap}) {
    final cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    final result = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(() async => picked),
        if (wrap != null)
          commitImportUseCaseProvider.overrideWithValue(
            CommitImportUseCase(wrap(cards)),
          ),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  CardImportDraft draftOf(ProviderContainer c) =>
      c.read(cardImportControllerProvider(leaf.id)) as CardImportDraft;

  test(
    'a file goes through the four steps and ends on a summary (steps 1–8)',
    () async {
      final c = container();
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

      await wizard.chooseFile();
      expect(draftOf(c).fileName, 'vocab.csv');
      expect(draftOf(c).step, CardImportStep.source);

      await wizard.readSource();
      expect(draftOf(c).step, CardImportStep.columns);
      expect(draftOf(c).mapping.isComplete, isTrue);

      await wizard.previewRows();
      expect(draftOf(c).step, CardImportStep.preview);
      expect(draftOf(c).willWrite, 1);

      await wizard.commit();
      final done =
          c.read(cardImportControllerProvider(leaf.id)) as CardImportDone;
      expect(done.summary.kind, ImportSummaryKind.partial);
      expect(await _count(db), 1);
    },
  );

  test(
    'a second tap while the picker is open does not open it again',
    () async {
      final pending = Completer<ImportPickedFile?>();
      var opened = 0;
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          importFilePickerProvider.overrideWithValue(() {
            opened++;
            return pending.future;
          }),
        ],
      );
      addTearDown(c.dispose);
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

      final first = wizard.chooseFile();
      final second = wizard.chooseFile();
      pending.complete(picked);
      await Future.wait([first, second]);

      expect(opened, 1);
      expect((draftOf(c).fileName, draftOf(c).isBusy), ('vocab.csv', false));
    },
  );

  test('a cancelled picker keeps the source chosen before (A5)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();

    picked = null;
    await wizard.chooseFile();

    expect(draftOf(c).fileName, 'vocab.csv');
  });

  test('a file that is not CSV, TSV or XLSX, or not UTF-8, is refused at step 1 (E1)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

    picked = _file('deck.apkg', 'x');
    await wizard.chooseFile();
    expect(draftOf(c).problem, TransferRejection.unreadableFile);

    picked = (
      name: 'latin.csv',
      bytes: Uint8List.fromList([0x63, 0xE9, 0x2C, 0x62]),
    );
    await wizard.chooseFile();
    await wizard.readSource();
    expect(
      (draftOf(c).step, draftOf(c).problem),
      (CardImportStep.source, TransferRejection.badEncoding),
    );
  });

  test('pasted text is a source once it holds something (A1)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

    wizard
      ..chooseSourceKind(CardImportSourceKind.paste)
      ..pasteText('   ');
    expect(draftOf(c).source, isNull);

    wizard.pasteText('front\tback\na\tb');
    await wizard.readSource();
    expect(draftOf(c).table!.rows.last, ['a', 'b']);
  });

  test('an unmapped back stops the preview, and mapping it lets it through (BR-TRANSFER-002)', () async {
    picked = _file('vocab.csv', 'term,meaning\na,b\n');
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();

    await wizard.previewRows();
    expect(draftOf(c).problem, TransferRejection.mappingIncomplete);

    wizard
      ..assignColumn(0, TransferField.front)
      ..assignColumn(1, TransferField.back);
    await wizard.previewRows();
    expect(draftOf(c).step, CardImportStep.preview);
  });

  test('Back steps back one step and keeps what it held; at step 1 it closes (IT-NAV-012)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    wizard.assignColumn(2, null);
    await wizard.previewRows();

    expect(wizard.stepBack(), isTrue);
    expect(draftOf(c).step, CardImportStep.columns);
    expect(draftOf(c).mapping.columnOf(TransferField.front), 0);
    expect(draftOf(c).mapping.columnOf(TransferField.tags), isNull);
    expect(wizard.stepBack(), isTrue);
    expect(
      (draftOf(c).step, draftOf(c).fileName),
      (CardImportStep.source, 'vocab.csv'),
    );
    expect(wizard.stepBack(), isFalse);
  });

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
    expect(await _count(db), 2);
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
      expect(await _count(db), 0);

      broken.isBroken = false;
      await wizard.retry();
      expect(
        c.read(cardImportControllerProvider(leaf.id)),
        isA<CardImportDone>(),
      );
    },
  );

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

Future<int> _count(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');
