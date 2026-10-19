import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_result_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import 'support/import_screen_helpers.dart';

// The result of an import split by * rows lists the decks it wrote to and
// leads back to the deck (spec 2026-10-08 U8).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _importInto(
  WidgetTester tester,
  LibraryEnv env,
  String deckId,
  String csv,
) async {
  await pumpImportScreen(tester, env, deckId, file: importFile(csv));
  await tapImportLabel(tester, _en.importSourceFile);
  await tapImportLabel(tester, _en.importReadAction);
  await tapImportLabel(tester, _en.importPreviewAction);
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
    await tapImportLabel(tester, _en.importCommitAction(1));

    expect(find.widgetWithText(MxButton, _en.importBackToDeck), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.importViewCards), findsNothing);

    final words = await env.decks.sub(root.id, 'Words');
    await _importInto(tester, env, words.id, 'front,back\nbul,fire\n');
    await tapImportLabel(tester, _en.importCommitAction(1));

    expect(find.widgetWithText(MxButton, _en.importViewCards), findsOneWidget);
  });
}
