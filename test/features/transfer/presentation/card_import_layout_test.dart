import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// Screen 11's layout: the duplicates toggle before the rows, one surface at
// the source (critique 2026-09-30 part 3d-2, E10).

final _en = lookupAppLocalizations(const Locale('en'));

ImportPickedFile _file(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  String deckId, {
  ImportPickedFile? file,
  VoidCallback? onClose,
  VoidCallback? onViewCards,
}) => pumpLibraryScreen(
  tester,
  env,
  CardImportScreen(
    deckId: deckId,
    deckContext: _context,
    onClose: onClose ?? () {},
    onViewCards: onViewCards ?? () {},
  ),
  overrides: [importFilePickerProvider.overrideWithValue(() async => file)],
);

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('the duplicates toggle comes before the rows (critique '
      '2026-09-30 part 3d-2, E10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await insertCard(
      env.db,
      id: 'x',
      deckId: deck.id,
      front: 'mul',
      back: 'water',
    );
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back\nmul,water\nbul,fire\n'),
    );
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);

    expect(
      tester.getTopLeft(find.text(_en.importIncludeDuplicates)).dy,
      lessThan(tester.getTopLeft(find.byType(ImportPreviewRowWidget).first).dy),
    );
  });

  libraryTest('the source step draws one surface and names the formats once '
      '(critique 2026-09-30 part 3d-2, E10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id);

    expect(
      find.ancestor(
        of: find.byType(MxEmptyState),
        matching: find.byType(MxCard),
      ),
      findsNothing,
    );
    expect(find.text(_en.importPickBody), findsOneWidget);
    expect(_en.importPickBody, isNot(contains('csv')));
  });
}
