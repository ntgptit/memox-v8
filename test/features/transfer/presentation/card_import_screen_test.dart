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
import '../../../support/library_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).

final _en = lookupAppLocalizations(const Locale('en'));

ImportPickedFile _file(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<int> _cards(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');

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
  libraryTest('a file becomes cards through the four steps (IT-CARD-014)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    var viewed = 0;
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul,water,noun\nbul,fire,\n'),
      onViewCards: () => viewed++,
    );

    expect(find.text(_en.importPickTitle), findsOneWidget);
    await _tap(tester, _en.importPickAction);
    expect(find.text('vocab.csv'), findsOneWidget);

    await _tap(tester, _en.importReadAction);
    expect(find.text(_en.importHeaderToggle), findsOneWidget);
    expect(find.text(_en.importFieldFront), findsOneWidget);

    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importPreviewReady(2, 2)), findsOneWidget);

    await _tap(tester, _en.importCommitAction(2));
    expect(find.text(_en.importDoneTitle), findsOneWidget);
    expect(await _cards(env), 2);

    await _tap(tester, _en.importViewCards);
    expect(viewed, 1);
  });

  libraryTest(
    'Back steps back one step; at step 1 it closes (IT-NAV-012 step 4)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      var closed = 0;
      await _pump(
        tester,
        env,
        deck.id,
        file: _file('front,back\nmul,water\n'),
        onClose: () => closed++,
      );
      await _tap(tester, _en.importPickAction);
      await _tap(tester, _en.importReadAction);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_en.importReadAction), findsOneWidget);
      expect(closed, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, 1);
    },
  );

  libraryTest('an unmapped back locks Preview and says why (BR-TRANSFER-002)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id, file: _file('term,meaning\nmul,water\n'));
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importMappingIncomplete), findsOneWidget);
    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importHeaderToggle), findsOneWidget);
  });

  libraryTest('a Latin-1 file is refused at step 1 with guidance (E1)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: (
        name: 'latin.csv',
        bytes: Uint8List.fromList([0x63, 0xE9, 0x2C, 0x62]),
      ),
    );
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importProblemEncodingTitle), findsOneWidget);
    expect(await _cards(env), 0);
  });

  libraryTest(
    'duplicates are skipped unless included (A4); every row a duplicate locks Import (E3)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await insertCard(
        env.db,
        id: 'x',
        deckId: deck.id,
        front: 'mul',
        back: 'water',
      );
      await _pump(tester, env, deck.id, file: _file('front,back\nmul,water\n'));
      await _tap(tester, _en.importPickAction);
      await _tap(tester, _en.importReadAction);
      await _tap(tester, _en.importPreviewAction);

      expect(find.text(_en.importRowDuplicateInDeck), findsOneWidget);
      expect(find.text(_en.importCaptionPreview(0)), findsOneWidget);

      await _tap(tester, _en.importIncludeDuplicates);
      expect(find.text(_en.importCommitAction(1)), findsOneWidget);
    },
  );
}
