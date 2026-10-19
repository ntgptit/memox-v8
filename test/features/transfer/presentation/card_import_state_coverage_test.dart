import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

// The States rows of screen 11 (Card import) whose detail file cites no
// executed test: sectionsRefused at level 10 (E8) and sectionTargetChanged
// (E9), end to end on the real backend and a fake picker.

final _en = lookupAppLocalizations(const Locale('en'));

ImportPickedFile _file(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  String deckId,
  ImportPickedFile file,
) => pumpLibraryScreen(
  tester,
  env,
  CardImportScreen(
    deckId: deckId,
    deckContext: _context,
    onClose: () {},
    onViewCards: () {},
  ),
  overrides: [importFilePickerProvider.overrideWithValue(() async => file)],
);

Future<void> _tap(WidgetTester tester, String label) async {
  await tapVisible(tester, find.text(label).last);
  await tester.pumpAndSettle();
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

/// Picks the file, reads it and asks for the preview.
Future<void> _toPreview(WidgetTester tester) async {
  await _tap(tester, _en.importSourceFile);
  await _tap(tester, _en.importReadAction);
  await _tap(tester, _en.importPreviewAction);
}

void main() {
  libraryTest('sectionsRefused: a sectioned file into a deck at level 10 says '
      'so in a warning banner at Columns and locks Preview (E8, U7)', (
    tester,
    env,
  ) async {
    var deck = await env.decks.root('Level 1');
    for (var level = 2; level <= DeckEntity.maxDepth; level++) {
      deck = await env.decks.sub(deck.id, 'Level $level');
    }
    await _pump(
      tester,
      env,
      deck.id,
      _file('front,back\n*Part 1,\nmul,water\n'),
    );
    await _toPreview(tester);

    expect(find.text(_en.importProblemDepthTitle), findsOneWidget);
    expect(find.text(_en.importProblemDepthBody), findsOneWidget);
    expect(
      tester
          .widgetList<MxInlineBanner>(find.byType(MxInlineBanner))
          .map((banner) => banner.tone),
      contains(MxBannerTone.warning),
    );
    expect(_button(tester, _en.importPreviewAction).onPressed, isNull);
    expect(find.text(_en.importPreviewAgain), findsNothing);
  });

  libraryTest('sectionTargetChanged: a deck chosen for Add to existing that '
      'moved before Import is a warning banner with Preview again (E9)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final part = await env.decks.sub(root.id, 'Part 1');
    final other = await env.decks.root('Other');
    await _pump(
      tester,
      env,
      root.id,
      _file('front,back\n*Part 1,\nmul,water\n*Idioms,\nbul,fire\n'),
    );
    await _toPreview(tester);
    await _tap(tester, _en.importDeckAddToExisting);
    expect(_button(tester, _en.importCommitAction(2)).onPressed, isNotNull);

    await env.decks.moveDeck(deckId: part.id, newParentId: other.id);
    await _tap(tester, _en.importCommitAction(2));

    expect(find.text(_en.importProblemChangedTitle), findsOneWidget);
    expect(find.text(_en.importProblemChangedBody), findsOneWidget);
    expect(
      tester
          .widgetList<MxInlineBanner>(find.byType(MxInlineBanner))
          .map((banner) => banner.tone),
      contains(MxBannerTone.warning),
    );
    expect(_button(tester, _en.importCommitAction(2)).onPressed, isNull);
    expect(find.text(_en.importPreviewAgain), findsOneWidget);
  });
}
