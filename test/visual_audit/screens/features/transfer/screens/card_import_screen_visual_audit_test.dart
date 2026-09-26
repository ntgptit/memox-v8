import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

void main() {
  libraryTest('screen 11, the source step', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await auditProductionScreen(
      tester,
      screen: CardImportScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        CardImportScreen(
          deckId: deck.id,
          deckContext: _context,
          onClose: () {},
          onViewCards: () {},
        ),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 11, the preview step', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    final file = (
      name: 'words.csv',
      bytes: Uint8List.fromList(utf8.encode('front,back\nmul,water\nbul,\n')),
    );
    await auditProductionScreen(
      tester,
      screen: CardImportScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          CardImportScreen(
            deckId: deck.id,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness: brightness,
          textScale: scale,
          overrides: [
            importFilePickerProvider.overrideWithValue(() async => file),
          ],
        );
        // The scope outlives a re-pump: drive the wizard only the first time.
        if (find.text(_en.importPickAction).evaluate().isEmpty) return;
        for (final label in [
          _en.importPickAction,
          _en.importReadAction,
          _en.importPreviewAction,
        ]) {
          await tester.ensureVisible(find.text(label).last);
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
