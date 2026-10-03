import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// SP2a 2.14–2.18 (R9): the card being written survives a closed editor, a
// killed process, a refused or deleted target and a change from another
// device. The draft lives in `card_draft`, on this device only.

final _en = lookupAppLocalizations(const Locale('en'));

/// Past the 500 ms pause that starts a draft write.
const _pause = Duration(milliseconds: 600);

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _create(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: _context);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, then the tag input once opened.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder _footerSave(String label) => find.widgetWithText(MxButton, label);

String _text(WidgetTester tester, int index) =>
    tester.widget<EditableText>(_field(index)).controller.text;

CardDraftRepositoryImpl _drafts(LibraryEnv env) =>
    CardDraftRepositoryImpl(env.db);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

void main() {
  libraryTest('typing is kept in a draft once it pauses (2.14)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump(const Duration(milliseconds: 300));
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);

    await tester.pump(_pause);
    final kept = await _drafts(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));
  });

  libraryTest('a draft kept before the editor was killed is offered back, '
      'and Restore fills the form (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await _drafts(env).save(
      CardDraftKey.create(deckId),
      const CardDraft(
        front: 'bap',
        back: 'rice',
        example: 'Bap meogeoyo.',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsOneWidget);
    expect(_text(tester, 0), isEmpty);

    await tester.tap(find.widgetWithText(MxButton, _en.cardDraftRestore));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect(_text(tester, 0), 'bap');
    expect(_text(tester, 1), 'rice');
    expect(find.text('Bap meogeoyo.'), findsOneWidget);
    // The tags sit below the fold of a 360×800 screen.
    await tester.dragUntilVisible(
      find.bySemanticsLabel(_en.cardTagRemove('food')),
      find.byType(ListView),
      const Offset(0, -200),
    );
  });

  libraryTest('Discard on the banner drops the draft and keeps the form '
      'empty (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await _drafts(env).save(
      CardDraftKey.create(deckId),
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, _en.cardDiscard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect(_text(tester, 0), isEmpty);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('an edit draft is offered on its own card only; a draft equal '
      'to the card is dropped, not offered (2.14)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final other = await env.cards.card(
      deckId,
      const CardDraft(front: 'mul', back: 'water'),
    );
    await _drafts(env).save(
      CardDraftKey.edit(card.id),
      const CardDraft(front: 'bab', back: 'rice'),
    );
    await _drafts(env).save(
      CardDraftKey.edit(other.id),
      const CardDraft(front: 'mul', back: 'water'),
    );

    await pumpLibraryScreen(tester, env, _edit(other.id));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect(await _drafts(env).read(CardDraftKey.edit(other.id)), isNull);

    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.cardDraftRestore));
    await tester.pumpAndSettle();
    expect(_text(tester, 0), 'bab');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNotNull,
    );
  });

  libraryTest('Save clears the draft (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('Save changes clears an edit draft (2.14)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.edit(card.id)), isNotNull);

    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await _drafts(env).read(CardDraftKey.edit(card.id)), isNull);
  });

  libraryTest('Discard on the discard dialog clears the draft (2.14)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardDiscard));
    await tester.pumpAndSettle();

    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('an unchanged form keeps no draft: typing then undoing it '
      'drops it (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.enterText(_field(0), '');
    await tester.pump(_pause);

    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('closing the editor mid-pause still writes the draft: dispose '
      'flushes (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump(const Duration(milliseconds: 300));
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);

    final kept = await _drafts(env).read(CardDraftKey.create(deckId));
    expect(kept?.front, 'bap');
  });
}
