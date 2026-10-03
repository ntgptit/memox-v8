import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import 'card_import_controller_harness.dart';

// The import wizard's steps over the real repositories and a fake picker
// (UC-TRANSFER-001, IT-NAV-012 step 4).
//
// The steps: source, mapping, preview and Back.

void main() {
  useImportFixture();

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
      expect(await countCards(db), 1);
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

    picked = pickedFile('deck.apkg', 'x');
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
    picked = pickedFile('vocab.csv', 'term,meaning\na,b\n');
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
}
