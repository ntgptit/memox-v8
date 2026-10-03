import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).
//
// What the import screen tests share: the pump, the fakes and the counts.

final enL10n = lookupAppLocalizations(const Locale('en'));

ImportPickedFile csvFile(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget deckContextHeader(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<void> pumpImport(
  WidgetTester tester,
  LibraryEnv env,
  String deckId, {
  ImportPickedFile? file,
  VoidCallback? onClose,
  VoidCallback? onViewCards,
  List<Override> overrides = const [],
}) => pumpLibraryScreen(
  tester,
  env,
  CardImportScreen(
    deckId: deckId,
    deckContext: deckContextHeader,
    onClose: onClose ?? () {},
    onViewCards: onViewCards ?? () {},
  ),
  overrides: [
    importFilePickerProvider.overrideWithValue(() async => file),
    ...overrides,
  ],
);

Future<void> tapLabel(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
