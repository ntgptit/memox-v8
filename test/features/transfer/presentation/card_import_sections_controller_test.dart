import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The wizard over a file split by * rows (spec 2026-10-08 U3, U4, U6,
// UC-TRANSFER-001 E9), on the real repositories.

DateTime _now() => DateTime(2026, 10, 8);

const _sheet = 'Term,Meaning\n*Part 1,\na,b\n*New,\nc,d\n';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late DeckEntity root;
  late DeckEntity part;

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    root = await decks.root('Korean');
    part = await decks.sub(root.id, 'Part 1');
  });
  tearDown(() => db.close());

  ProviderContainer container({String sheet = _sheet}) {
    final result = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(
          () async => (
            name: 'vocab.csv',
            bytes: Uint8List.fromList(utf8.encode(sheet)),
          ),
        ),
      ],
    );
    addTearDown(result.dispose);
    result.listen(cardImportControllerProvider(root.id), (_, _) {});
    return result;
  }

  CardImportState stateOf(ProviderContainer c) =>
      c.read(cardImportControllerProvider(root.id));

  CardImportDraft draftOf(ProviderContainer c) => stateOf(c) as CardImportDraft;

  /// Pick, read, map Term and Meaning, preview.
  Future<CardImportController> toPreview(ProviderContainer c) async {
    final wizard = c.read(cardImportControllerProvider(root.id).notifier);
    await wizard.chooseFile();
    await wizard.readSource();
    wizard
      ..assignColumn(0, TransferField.front)
      ..assignColumn(1, TransferField.back);
    await wizard.previewRows(defaultDeckName: 'Uncategorized');
    return wizard;
  }

  test(
    'a clash must be chosen; then Import writes both decks (U3, U6)',
    () async {
      final c = container();
      final wizard = await toPreview(c);

      expect((draftOf(c).preview!.undecided, draftOf(c).canCommit), (1, false));
      await wizard.commit();
      expect(stateOf(c), isA<CardImportDraft>());

      wizard.chooseSection(0, ImportSectionChoice.addToExisting);
      expect(draftOf(c).canCommit, isTrue);

      await wizard.commit();
      final done = stateOf(c) as CardImportDone;
      expect(
        [for (final d in done.summary.decks) (d.name, d.isNew)],
        [('Part 1', false), ('New', true)],
      );
    },
  );

  test('changing the mapping clears the choices; the default name stays '
      '(Review Focus 2)', () async {
    final c = container();
    final wizard = await toPreview(c);
    wizard
      ..chooseSection(0, ImportSectionChoice.addToExisting)
      ..renameDefaultDeck('Misc');

    expect(wizard.stepBack(), isTrue);
    wizard.setHasHeaderRow(hasHeaderRow: true);
    await wizard.previewRows(defaultDeckName: 'Uncategorized');

    expect(draftOf(c).sectionChoices, isEmpty);
    expect(draftOf(c).defaultDeckName, 'Misc');
  });

  test(
    'a chosen deck that moved shows the problem on the preview (E9)',
    () async {
      final c = container();
      final wizard = await toPreview(c);
      wizard.chooseSection(0, ImportSectionChoice.addToExisting);
      await decks.moveDeck(
        deckId: part.id,
        newParentId: (await decks.root('Other')).id,
      );

      await wizard.commit();

      expect(
        (draftOf(c).step, draftOf(c).problem),
        (CardImportStep.preview, TransferRejection.sectionTargetChanged),
      );
    },
  );

  test('renaming the default deck clears its choice and finds its new clash '
      '(U4)', () async {
    await decks.sub(root.id, 'Uncategorized');
    final c = container(sheet: 'Term,Meaning\nloose,x\n*New,\na,b\n');
    final wizard = await toPreview(c);
    expect(draftOf(c).preview!.undecided, 1);

    wizard
      ..chooseSection(0, ImportSectionChoice.addToExisting)
      ..renameDefaultDeck('Misc');
    expect(draftOf(c).sectionChoices, isEmpty);
    expect(draftOf(c).preview!.undecided, 0);

    wizard.renameDefaultDeck('uncategorized');
    expect(draftOf(c).preview!.undecided, 1);
  });

  test(
    'one choice decides every clash; a row still overrides it (C2)',
    () async {
      await decks.sub(root.id, 'New');
      final c = container();
      final wizard = await toPreview(c);
      expect(draftOf(c).preview!.undecided, 2);

      wizard.chooseAllSections(ImportSectionChoice.addToExisting);
      expect(draftOf(c).preview!.undecided, 0);
      expect(draftOf(c).sectionChoices, {
        0: ImportSectionChoice.addToExisting,
        1: ImportSectionChoice.addToExisting,
      });

      wizard.chooseSection(1, ImportSectionChoice.createNew);
      expect(draftOf(c).sectionChoices[1], ImportSectionChoice.createNew);
    },
  );
}
