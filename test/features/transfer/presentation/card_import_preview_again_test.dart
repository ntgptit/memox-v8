import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

// Screen 11, sectionTargetChanged (E9): "Preview again" reads the decks
// again after one changed before Import, then clears the banner and
// unlocks Import. Before 2026-10-18 the fresh preview kept the stale
// problem, so the banner stayed and Import stayed locked.

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<void> _tap(WidgetTester tester, String label) async {
  await tapVisible(tester, find.text(label).last);
  await tester.pumpAndSettle();
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  libraryTest('sectionTargetChanged: Preview again reads the decks again, '
      'clears the banner and unlocks Import (E9)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final part = await env.decks.sub(root.id, 'Part 1');
    final other = await env.decks.root('Other');
    await pumpLibraryScreen(
      tester,
      env,
      CardImportScreen(
        deckId: root.id,
        deckContext: _context,
        onClose: () {},
        onViewCards: () {},
      ),
      overrides: [
        importFilePickerProvider.overrideWithValue(
          () async => (
            name: 'vocab.csv',
            bytes: Uint8List.fromList(
              utf8.encode(
                'front,back\n*Part 1,\nmul,water\n*Idioms,\nbul,fire\n',
              ),
            ),
          ),
        ),
      ],
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);
    await _tap(tester, _en.importDeckAddToExisting);
    await env.decks.moveDeck(deckId: part.id, newParentId: other.id);
    await _tap(tester, _en.importCommitAction(2));
    expect(find.text(_en.importProblemChangedTitle), findsOneWidget);

    await _tap(tester, _en.importPreviewAgain);

    expect(find.text(_en.importProblemChangedTitle), findsNothing);
    expect(find.text(_en.importPreviewAgain), findsNothing);
    expect(_button(tester, _en.importCommitAction(2)).onPressed, isNotNull);
  });
}
