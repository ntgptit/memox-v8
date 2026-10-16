import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_deck_row_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// Screen 11's reasons are phrases: each dot stays with the phrase before it,
// and the phrases wrap as words (The Wrap Rule).
void main() {
  libraryTest('a blank row says why it is ignored', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: ImportPreviewRowWidget(
          row: ImportRow(rowNumber: 4, kind: ImportRowKind.blank),
        ),
      ),
    );

    expect(find.text(metaDots(_en.importRowBlank)), findsWidgets);
  });

  libraryTest('a deck with no row to write says it makes no deck', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: ImportDeckRowWidget(
          group: const ImportGroup(
            name: 'Basics',
            isDefault: false,
            destination: IntoNewDeck(),
            rows: [],
          ),
          willWrite: 0,
          onChoose: (_) {},
          onRename: (_) {},
        ),
      ),
    );

    expect(find.text(metaDots(_en.importDeckNothing)), findsOneWidget);
  });
}
