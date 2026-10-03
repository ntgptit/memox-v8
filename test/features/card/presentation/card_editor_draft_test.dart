import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

import 'card_editor_draft_harness.dart';

// SP2a 2.14–2.18 (R9): the card being written survives a closed editor, a
// killed process, a refused or deleted target and a change from another
// device. The draft lives in `card_draft`, on this device only.
//
// What is kept, offered back, restored, discarded and cleared.

void main() {
  libraryTest('typing is kept in a draft once it pauses (2.14)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.enterText(fieldAt(0), 'bap');
    await tester.enterText(fieldAt(1), 'rice');
    await tester.pump(const Duration(milliseconds: 300));
    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNull);

    await tester.pump(draftPause);
    final kept = await draftsOf(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));
  });

  libraryTest('a draft kept before the editor was killed is offered back, '
      'and Restore fills the form (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await draftsOf(env).save(
      CardDraftKey.create(deckId),
      const CardDraft(
        front: 'bap',
        back: 'rice',
        example: 'Bap meogeoyo.',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardDraftTitle), findsOneWidget);
    expect(textAt(tester, 0), isEmpty);

    await tester.tap(find.widgetWithText(MxButton, enL10n.cardDraftRestore));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardDraftTitle), findsNothing);
    expect(textAt(tester, 0), 'bap');
    expect(textAt(tester, 1), 'rice');
    expect(find.text('Bap meogeoyo.'), findsOneWidget);
    // The tags sit below the fold of a 360×800 screen.
    await tester.dragUntilVisible(
      find.bySemanticsLabel(enL10n.cardTagRemove('food')),
      find.byType(ListView),
      const Offset(0, -200),
    );
  });

  libraryTest('Discard on the banner drops the draft and keeps the form '
      'empty (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await draftsOf(env).save(
      CardDraftKey.create(deckId),
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, enL10n.cardDiscard));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardDraftTitle), findsNothing);
    expect(textAt(tester, 0), isEmpty);
    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('an edit draft is offered on its own card only; a draft equal '
      'to the card is dropped, not offered (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final other = await env.cards.card(
      deckId,
      const CardDraft(front: 'mul', back: 'water'),
    );
    await draftsOf(env).save(
      CardDraftKey.edit(card.id),
      const CardDraft(front: 'bab', back: 'rice'),
    );
    await draftsOf(env).save(
      CardDraftKey.edit(other.id),
      const CardDraft(front: 'mul', back: 'water'),
    );

    await pumpLibraryScreen(tester, env, editScreen(other.id));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDraftTitle), findsNothing);
    expect(await draftsOf(env).read(CardDraftKey.edit(other.id)), isNull);

    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDraftTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, enL10n.cardDraftRestore));
    await tester.pumpAndSettle();
    expect(textAt(tester, 0), 'bab');
    expect(
      tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
      isNotNull,
    );
  });

  libraryTest('Save clears the draft (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.enterText(fieldAt(0), 'bap');
    await tester.enterText(fieldAt(1), 'rice');
    await tester.pump(draftPause);
    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.tap(footerSave(enL10n.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('Save changes clears an edit draft (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'cooked rice');
    await tester.pump(draftPause);
    expect(await draftsOf(env).read(CardDraftKey.edit(card.id)), isNotNull);

    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await draftsOf(env).read(CardDraftKey.edit(card.id)), isNull);
  });

  libraryTest('Discard on the discard dialog clears the draft (2.14)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.enterText(fieldAt(0), 'bap');
    await tester.pump(draftPause);
    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(enL10n.cardDiscard));
    await tester.pumpAndSettle();

    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('an unchanged form keeps no draft: typing then undoing it '
      'drops it (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.enterText(fieldAt(0), 'bap');
    await tester.pump(draftPause);
    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.enterText(fieldAt(0), '');
    await tester.pump(draftPause);

    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('closing the editor mid-pause still writes the draft: dispose '
      'flushes (2.14)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.enterText(fieldAt(0), 'bap');
    await tester.pump(const Duration(milliseconds: 300));
    expect(await draftsOf(env).read(CardDraftKey.create(deckId)), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);

    final kept = await draftsOf(env).read(CardDraftKey.create(deckId));
    expect(kept?.front, 'bap');
  });

  libraryTest('while a kept draft is on offer, new typing is not autosaved '
      'until the banner is answered (D8)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    const seeded = CardDraft(front: 'bap', back: 'rice');
    await draftsOf(env).save(CardDraftKey.create(deckId), seeded);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDraftTitle), findsOneWidget);

    await tester.enterText(fieldAt(0), 'mul');
    await tester.pump(draftPause);

    final kept = await draftsOf(env).read(CardDraftKey.create(deckId));
    expect(kept!.sameContentAs(seeded), isTrue);
  });

  libraryTest('a draft kept for one deck is not offered when creating in '
      'another (2.14)', (tester, env) async {
    final deckA = await seedWordsDeck(env);
    final deckB = (await env.decks.sub(
      (await env.decks.root('Japanese')).id,
      'Words',
    )).id;
    await draftsOf(env).save(
      CardDraftKey.create(deckA),
      const CardDraft(front: 'bap', back: 'rice'),
    );

    await pumpLibraryScreen(tester, env, createScreen(deckB));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardDraftTitle), findsNothing);
    expect(
      (await draftsOf(env).read(CardDraftKey.create(deckA)))?.front,
      'bap',
    );
  });
}
