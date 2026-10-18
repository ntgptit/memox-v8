import 'package:excel/excel.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import 'support/import_screen_helpers.dart';
import 'support/words_deck.dart';

// The import screen over a workbook whose first sheet is blank and over
// files split by * rows (spec 2026-10-08 S6, U2, U3, U6, U7), on the real
// backend and a fake picker.

final _en = lookupAppLocalizations(const Locale('en'));

/// A workbook whose first sheet is blank and whose second holds rows.
ImportPickedFile _blankFirstSheet() {
  final workbook = Excel.createExcel();
  final first = workbook.getDefaultSheet()!;
  workbook['Notes'];
  workbook['Vocab']
    ..appendRow([TextCellValue('front'), TextCellValue('back')])
    ..appendRow([TextCellValue('mul'), TextCellValue('water')]);
  workbook.delete(first);
  return (name: 'vocab.xlsx', bytes: Uint8List.fromList(workbook.encode()!));
}

void main() {
  libraryTest(
    'a blank first sheet says so and keeps the sheet chip; another sheet maps (A2, S6)',
    (tester, env) async {
      final deck = await seedWordsDeck(env);
      await pumpImportScreen(tester, env, deck.id, file: _blankFirstSheet());
      await tapImportLabel(tester, _en.importSourceFile);
      await tapImportLabel(tester, _en.importReadAction);

      expect(find.text(_en.importProblemEmptyTitle), findsOneWidget);
      expect(find.text(_en.importMappingIncomplete), findsNothing);
      expect(
        tester
            .widget<MxButton>(
              find.widgetWithText(MxButton, _en.importPreviewAction),
            )
            .onPressed,
        isNull,
      );

      await tapImportLabel(tester, _en.importSheet('Notes', 1, 2));
      await tapImportLabel(tester, 'Vocab');

      expect(find.text(_en.importProblemEmptyTitle), findsNothing);
      expect(find.text(_en.importFieldFront), findsOneWidget);
    },
  );

  libraryTest(
    'a sectioned file from a root: decks first, a clash locks Import until '
    'chosen (spec 2026-10-08 U2, U3, U6)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      await env.decks.sub(root.id, 'Part 1');
      await pumpImportScreen(
        tester,
        env,
        root.id,
        file: importFile(
          'front,back\n*Part 1,\nmul,water\n*Idioms,\nbul,fire\n',
        ),
      );
      await tapImportLabel(tester, _en.importSourceFile);
      await tapImportLabel(tester, _en.importReadAction);
      await tapImportLabel(tester, _en.importPreviewAction);

      expect(find.text(_en.importDecksHeader.toUpperCase()), findsOneWidget);
      expect(find.text(_en.importCaptionChooseDecks(1)), findsOneWidget);
      MxButton commit() => tester.widget<MxButton>(
        find.widgetWithText(MxButton, _en.importCommitAction(2)),
      );
      expect(commit().onPressed, isNull);

      await tapImportLabel(tester, _en.importDeckAddToExisting);
      expect(find.text(_en.importCaptionChooseDecks(1)), findsNothing);
      expect(commit().onPressed, isNotNull);

      await tapImportLabel(tester, _en.importCommitAction(2));
      expect(await cardsWritten(env), 2);
    },
  );

  libraryTest(
    'a sectioned file into a deck of cards says so and locks Preview (E7)',
    (tester, env) async {
      final deck = await seedWordsDeck(env);
      await insertCard(env.db, id: 'c', deckId: deck.id, front: 'a');
      await pumpImportScreen(
        tester,
        env,
        deck.id,
        file: importFile('front,back\n*Part 1,\nmul,water\n'),
      );
      await tapImportLabel(tester, _en.importSourceFile);
      await tapImportLabel(tester, _en.importReadAction);
      await tapImportLabel(tester, _en.importPreviewAction);

      expect(find.text(_en.importProblemSectionsTitle), findsOneWidget);
      expect(
        tester
            .widget<MxButton>(
              find.widgetWithText(MxButton, _en.importPreviewAction),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
