import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/forui_expect.dart';
import 'support/card_editor_host.dart';
import 'support/words_deck.dart';

// Screen 09's Save in edit: it waits for a change (critique 2026-09-30 part
// 3d-1). Split from card_editor_screen_test.dart, which holds the rest of
// the editor's flows.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('create: Cancel, close and Back are held while the card saves; '
      'the save lands and says so, with no discard dialog', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(
      tester,
      env,
      CardEditorScreen.create(deckId: deckId, deckContext: editorDeckContext),
    );
    await tester.pumpAndSettle();
    await tester.enterText(editorField(0), 'bap');
    await tester.enterText(editorField(1), 'rice');
    await tester.pump();

    // Save starts the write; Cancel lands in the same instant, before the
    // write answers.
    await tester.tap(editorFooterButton(_en.cardSaveCard));
    await tester.tap(find.widgetWithText(MxButton, _en.commonCancel));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDiscardNewTitle), findsNothing);
    expect(find.text(_en.cardAddedToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  MxButton saveChanges(WidgetTester tester) =>
      tester.widget<MxButton>(editorFooterButton(_en.cardSaveChanges));

  libraryTest('edit: Save waits for a change and goes quiet when it is '
      'undone (critique 2026-09-30 part 3d-1)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();
    expect(saveChanges(tester).onPressed, isNull);

    await tester.enterText(editorField(1), 'cooked rice');
    await tester.pump();
    expect(saveChanges(tester).onPressed, isNotNull);

    await tester.enterText(editorField(1), 'rice');
    await tester.pump();
    expect(saveChanges(tester).onPressed, isNull);
  });

  libraryTest('edit: the flag alone is a change (Review Focus 3)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();

    await tester.tap(byControlLabel(_en.cardFlagLabel));
    await tester.pump();
    expect(saveChanges(tester).onPressed, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
  });

  Future<int> flagOf(LibraryEnv env, String cardId) async =>
      (await env.db
              .customSelect(
                'SELECT is_flagged FROM card WHERE id = ?',
                variables: [Variable(cardId)],
              )
              .getSingle())
          .read<int>('is_flagged');

  libraryTest('edit: a flag toggled in the editor is saved (DEV-220)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();

    await tester.tap(byControlLabel(_en.cardFlagLabel));
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await flagOf(env, card.id), 1);
  });

  libraryTest('edit: a flag set while the editor was open survives a '
      'content-only save (BR-CARD-009, DEV-220)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();
    // Another device, or the system (BR-STUDY-073), sets the flag meanwhile.
    await env.cards.setFlagged(cardIds: {card.id}, isFlagged: true);

    await tester.enterText(editorField(1), 'cooked rice');
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await flagOf(env, card.id), 1);
  });
}
