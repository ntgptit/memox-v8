import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_result_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// The result of an import split by * rows lists the decks it wrote to and
// leads back to the deck (spec 2026-10-08 U8).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _importInto(
  WidgetTester tester,
  LibraryEnv env,
  String deckId,
  String csv,
) async {
  await pumpLibraryScreen(
    tester,
    env,
    CardImportScreen(
      deckId: deckId,
      deckContext: (id, label) =>
          DeckContextHeaderWidget(deckId: id, currentLabel: label),
      onClose: () {},
      onViewCards: () {},
    ),
    overrides: [
      importFilePickerProvider.overrideWithValue(
        () async =>
            (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(csv))),
      ),
    ],
  );
  await _tap(tester, _en.importSourceFile);
  await _tap(tester, _en.importReadAction);
  await _tap(tester, _en.importPreviewAction);
}

void main() {
  libraryTest('the result lists each deck with New or Existing and its '
      'cards', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: SingleChildScrollView(
          child: ImportResultWidget(
            state: CardImportDone(
              ImportSummary(
                written: 3,
                blank: 0,
                skipped: [],
                decks: [
                  ImportDeckResult(name: 'Part 1', isNew: false, written: 2),
                  ImportDeckResult(name: 'Idioms', isNew: true, written: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(_en.importDecksHeader.toUpperCase()), findsOneWidget);
    expect(find.text('Part 1'), findsOneWidget);
    expect(find.text(_en.importDeckExisting), findsOneWidget);
    expect(find.text(_en.importDeckNew), findsOneWidget);
    expect(find.text(_en.importDeckCards(2)), findsOneWidget);
  });

  libraryTest('a sectioned import leads back to the deck; a flat one to its '
      'cards', (tester, env) async {
    final root = await env.decks.root('Korean');
    await _importInto(
      tester,
      env,
      root.id,
      'front,back\n*Part 1,\nmul,water\n',
    );
    await _tap(tester, _en.importCommitAction(1));

    expect(find.widgetWithText(MxButton, _en.importBackToDeck), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.importViewCards), findsNothing);

    final words = await env.decks.sub(root.id, 'Words');
    await _importInto(tester, env, words.id, 'front,back\nbul,fire\n');
    await _tap(tester, _en.importCommitAction(1));

    expect(find.widgetWithText(MxButton, _en.importViewCards), findsOneWidget);
  });
}
