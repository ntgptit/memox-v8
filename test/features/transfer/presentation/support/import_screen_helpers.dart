import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';

import '../../../../support/library_harness.dart';
import '../../../../support/widget_harness.dart';

/// A `vocab.csv` the fake picker hands to the import screen.
ImportPickedFile importFile(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget importDeckContext(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

/// How many cards the database holds.
Future<int> cardsWritten(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');

/// The import screen on the real backend; the picker returns [file].
Future<void> pumpImportScreen(
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
    deckContext: importDeckContext,
    onClose: onClose ?? () {},
    onViewCards: onViewCards ?? () {},
  ),
  overrides: [importFilePickerProvider.overrideWithValue(() async => file)],
);

/// Taps the last widget that reads [label], then settles.
Future<void> tapImportLabel(WidgetTester tester, String label) async {
  await tapVisible(tester, find.text(label).last);
  await tester.pumpAndSettle();
}
