import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

import 'card_editor_draft_harness.dart';

// SP2a 2.14–2.18 (R9): the card being written survives a closed editor, a
// killed process, a refused or deleted target and a change from another
// device. The draft lives in `card_draft`, on this device only.
//
// A save that is held, refused or fails, and a card that is gone.

void main() {
  libraryTest('a deck that rejects the card keeps the draft, says so, and '
      'offers the text back next time (2.15)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await env.decks.sub(deckId, 'Verbs');
    await tester.enterText(fieldAt(0), 'bap');
    await tester.enterText(fieldAt(1), 'rice');
    // Save before the pause ends: the refusal itself writes the draft.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(footerSave(enL10n.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardDeckRejectsTitle), findsOneWidget);
    expect(find.text(enL10n.cardDeckRejectsBody), findsOneWidget);
    final kept = await draftsOf(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));

    // Leaving asks nothing: the text is already safe.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDiscardNewTitle), findsNothing);

    // A refusal releases the hold: the controls work again.
    expect(
      tester
          .widget<MxIconButton>(
            find.widgetWithIcon(MxIconButton, AppIcons.close),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, enL10n.commonCancel))
          .onPressed,
      isNotNull,
    );

    // A fresh editor, not the same state again.
    await tester.pumpWidget(const SizedBox());
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDraftTitle), findsOneWidget);
  });

  libraryTest('a deck that is gone says the text is kept on this phone, and '
      'it is (D10)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createScreen(deckId));
    await tester.enterText(fieldAt(0), 'bap');
    await tester.enterText(fieldAt(1), 'rice');
    await env.decks.deleteDeck(deckId: deckId);
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardDeckGoneTitle), findsOneWidget);
    expect(find.text(enL10n.cardDeckGoneBody), findsOneWidget);
    expect(enL10n.cardDeckGoneBody, contains('kept on this phone'));
    final kept = await draftsOf(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));
  });

  libraryTest('Cancel, close and Back are held while a save is in flight '
      '(2.16)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final held = HeldEdits(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      editScreen(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'cooked rice');
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pump();

    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, enL10n.commonCancel))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<MxIconButton>(
            find.widgetWithIcon(MxIconButton, AppIcons.back),
          )
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    // The save spinner never settles: a frame is all Back needs.
    await tester.pump();
    expect(find.text(enL10n.cardDiscardTitle), findsNothing);

    held.release.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(enL10n.cardDiscardTitle), findsNothing);
  });

  /// Opens the editor on a card whose edit ends with [then], saves, and lets
  /// it end.
  Future<void> saveEndingWith(
    WidgetTester tester,
    LibraryEnv env,
    Future<Outcome<void, CardRejection>> Function() then,
  ) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final held = HeldEdits(env.cards, then: then);
    await pumpLibraryScreen(
      tester,
      env,
      editScreen(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'cooked rice');
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pump();
    held.release.complete();
    await tester.pump();
    await tester.pump();
  }

  libraryTest('a card deleted while saving releases the hold: Back and the '
      'leading button work on the gone state (2.16)', (tester, env) async {
    await saveEndingWith(
      tester,
      env,
      () async => const Rejected(CardRejection.notFound),
    );
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);
    expect(
      tester
          .widget<MxIconButton>(
            find.widgetWithIcon(MxIconButton, AppIcons.back),
          )
          .onPressed,
      isNotNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Not held, not asked: an edited form would otherwise raise the dialog.
    expect(find.text(enL10n.cardDiscardTitle), findsNothing);
  });

  libraryTest('a save that throws something unexpected releases the hold '
      '(2.16)', (tester, env) async {
    await saveEndingWith(tester, env, () async => throw StateError('boom'));
    // The error is not swallowed: the framework sees it.
    expect(tester.takeException(), isA<StateError>());
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<MxIconButton>(
            find.widgetWithIcon(MxIconButton, AppIcons.back),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, enL10n.commonCancel))
          .onPressed,
      isNotNull,
    );
  });

  libraryTest('a deleted card: a danger banner, Save off, the draft kept, '
      'leaving asks nothing (2.17)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);
    expect(find.text(enL10n.cardEditorGoneBody), findsOneWidget);
    expect(textAt(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
      isNull,
    );
    // Written at once, not after the pause.
    expect(
      (await draftsOf(env).read(CardDraftKey.edit(card.id)))?.back,
      'changed',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDiscardTitle), findsNothing);
  });

  libraryTest('a draft on offer survives the card going gone: the form is '
      'untouched, so nothing replaces it (2.15)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await draftsOf(env).save(
      CardDraftKey.edit(card.id),
      const CardDraft(front: 'bap', back: 'earlier text'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.cardDraftTitle), findsOneWidget);

    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();
    await tester.pump(draftPause);

    expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);
    expect(find.text(enL10n.cardDraftTitle), findsOneWidget);
    expect(
      (await draftsOf(env).read(CardDraftKey.edit(card.id)))?.back,
      'earlier text',
    );
  });
}
