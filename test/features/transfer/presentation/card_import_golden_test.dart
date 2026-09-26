@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Kit 11's states as the app draws them, light and dark: the source, the
// mapping, a mixed preview and a partial result (spec §8.2 K1–K4).

final _en = lookupAppLocalizations(const Locale('en'));

/// Romanized fronts: the golden test font has no Hangul glyphs.
const _csv =
    'front,back,tags\n'
    'mul,water,noun\n'
    'bul,,\n'
    'sarang,love,\n'
    ',,\n'
    'mul,water,\n';

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<String> _seed(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final deck = await env.decks.sub(root.id, 'Words');
  await insertCard(
    env.db,
    id: 'x',
    deckId: deck.id,
    front: 'sarang',
    back: 'love',
  );
  return deck.id;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> pump(WidgetTester tester, LibraryEnv env, String deckId) =>
        pumpLibraryGolden(
          tester,
          env,
          CardImportScreen(
            deckId: deckId,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness,
          overrides: [
            importFilePickerProvider.overrideWithValue(
              () async => (
                name: 'words.csv',
                bytes: Uint8List.fromList(utf8.encode(_csv)),
              ),
            ),
          ],
        );

    libraryTest('import source, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await expectBoundaryGolden(tester, 'goldens/import_source_$theme.png');
      });
    });

    libraryTest('import mapping, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importPickAction);
        await _tap(tester, _en.importReadAction);
        await expectBoundaryGolden(tester, 'goldens/import_mapping_$theme.png');
      });
    });

    libraryTest('import preview, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importPickAction);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await expectBoundaryGolden(tester, 'goldens/import_preview_$theme.png');
      });
    });

    libraryTest('import partial result, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importPickAction);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await _tap(tester, _en.importCommitAction(1));
        await expectBoundaryGolden(tester, 'goldens/import_partial_$theme.png');
      });
    });
  }
}
