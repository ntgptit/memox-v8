import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import '../../../support/library_harness.dart';
import 'support/import_screen_helpers.dart';
import 'support/words_deck.dart';

// Screen 11's source step picks a file from its "Choose a file" card; the
// empty state below carries no second button (critique 2026-10-02, F9).

final _en = lookupAppLocalizations(const Locale('en'));

Future<int Function()> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  ImportPickedFile? file,
}) async {
  final deck = await seedWordsDeck(env);
  var picks = 0;
  await pumpLibraryScreen(
    tester,
    env,
    CardImportScreen(
      deckId: deck.id,
      deckContext: importDeckContext,
      onClose: () {},
      onViewCards: () {},
    ),
    overrides: [
      importFilePickerProvider.overrideWithValue(() async {
        picks++;
        return file;
      }),
    ],
  );
  return () => picks;
}

void main() {
  libraryTest('the empty state has no button; the selected file card opens '
      'the picker', (tester, env) async {
    final picks = await _pump(tester, env, file: importFile('a,b'));

    expect(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.byType(MxButton),
      ),
      findsNothing,
    );
    await tapImportLabel(tester, _en.importSourceFile);

    expect(picks(), 1);
    expect(find.text('vocab.csv'), findsOneWidget);
  });

  libraryTest('from Paste, the file card switches to file and opens the '
      'picker; a cancelled picker leaves file chosen with no source', (
    tester,
    env,
  ) async {
    final picks = await _pump(tester, env);
    await tapImportLabel(tester, _en.importSourcePaste);
    await tester.enterText(find.byType(EditableText), 'a,b');
    await tester.pumpAndSettle();

    await tapImportLabel(tester, _en.importSourceFile);

    expect(picks(), 1);
    expect(find.text(_en.importPickTitle), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
  });
}
