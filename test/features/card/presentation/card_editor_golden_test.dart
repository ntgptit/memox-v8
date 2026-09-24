@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

/// Korean › Words, empty. Romanized text: the golden font has no Hangul.
Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card editor, create, $theme', (tester, env) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_create_$theme.png',
        );
      });
    });

    libraryTest('card editor, errors and tags, $theme', (tester, env) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(EditableText).at(0),
          'a' * (CardDraft.maxFrontLength + 4),
        );
        await tester.enterText(find.byType(EditableText).at(1), 'x');
        await tester.enterText(find.byType(EditableText).at(1), '');
        await tester.tap(find.text(_en.cardAddTag));
        await tester.pump();
        for (final tag in ['food', 'topik 1']) {
          await tester.enterText(find.byType(EditableText).at(2), tag);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_errors_$theme.png',
        );
      });
    });

    libraryTest('card editor, edit, $theme', (tester, env) async {
      final deckId = await _words(env);
      final card = await env.cards.card(
        deckId,
        const CardDraft(
          front: 'gamsahamnida',
          back: 'thank you',
          example: 'Dowajusyeoseo gamsahamnida.',
          pronunciation: 'gam-sa-ham-ni-da',
          isFlagged: true,
          tagNames: ['greeting', 'topik 1'],
        ),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.edit(cardId: card.id, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_edit_$theme.png',
        );
      });
    });

    libraryTest('card editor, create at text scale 2, $theme', (
      tester,
      env,
    ) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId, deckContext: _context),
          brightness,
          textScale: 2,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).at(0), 'gamsahamnida');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_create_2x_$theme.png',
        );
      });
    });
  }
}
