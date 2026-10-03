import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

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

/// An edit that waits until the test lets it through.
final class _HeldEdits implements CardRepository {
  _HeldEdits(this._cards, {this.then});

  final CardRepository _cards;

  /// What the edit ends with; null lets it through to the real repository.
  final Future<Outcome<void, CardRejection>> Function()? then;
  final release = Completer<void>();

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
    DateTime? now,
  }) async {
    await release.future;
    if (then != null) return then!();
    return _cards.editCard(
      cardId: cardId,
      draft: draft,
      expectedUpdatedAt: expectedUpdatedAt,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A card detail the test feeds by hand.
final class _ScriptedDetail implements CardRepository {
  _ScriptedDetail(this._stream);

  final Stream<CardDetail?> _stream;

  @override
  Stream<CardDetail?> watchDetail(String cardId) => _stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<String> _backOf(LibraryEnv env, String cardId) async =>
    (await env.db
            .customSelect(
              'SELECT back FROM card WHERE id = ?',
              variables: [Variable<String>(cardId)],
            )
            .getSingle())
        .read<String>('back');

/// The other device's save, a day after the editor opened.
Future<void> _otherDeviceSaves(LibraryEnv env, String cardId) =>
    env.cards.editCard(
      cardId: cardId,
      draft: const CardDraft(front: 'bap', back: 'theirs'),
      now: DateTime.now().add(const Duration(days: 1)),
    );

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

  libraryTest('while a kept draft is on offer, new typing is not autosaved '
      'until the banner is answered (D8)', (tester, env) async {
    final deckId = await _words(env);
    const seeded = CardDraft(front: 'bap', back: 'rice');
    await _drafts(env).save(CardDraftKey.create(deckId), seeded);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsOneWidget);

    await tester.enterText(_field(0), 'mul');
    await tester.pump(_pause);

    final kept = await _drafts(env).read(CardDraftKey.create(deckId));
    expect(kept!.sameContentAs(seeded), isTrue);
  });

  libraryTest('a draft kept for one deck is not offered when creating in '
      'another (2.14)', (tester, env) async {
    final deckA = await _words(env);
    final deckB = (await env.decks.sub(
      (await env.decks.root('Japanese')).id,
      'Words',
    )).id;
    await _drafts(env).save(
      CardDraftKey.create(deckA),
      const CardDraft(front: 'bap', back: 'rice'),
    );

    await pumpLibraryScreen(tester, env, _create(deckB));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect((await _drafts(env).read(CardDraftKey.create(deckA)))?.front, 'bap');
  });

  libraryTest('a deck that rejects the card keeps the draft, says so, and '
      'offers the text back next time (2.15)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await env.decks.sub(deckId, 'Verbs');
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    // Save before the pause ends: the refusal itself writes the draft.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDeckRejectsTitle), findsOneWidget);
    expect(find.text(_en.cardDeckRejectsBody), findsOneWidget);
    final kept = await _drafts(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));

    // Leaving asks nothing: the text is already safe.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsNothing);

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
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
          .onPressed,
      isNotNull,
    );

    // A fresh editor, not the same state again.
    await tester.pumpWidget(const SizedBox());
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsOneWidget);
  });

  libraryTest('Cancel, close and Back are held while a save is in flight '
      '(2.16)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final held = _HeldEdits(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pump();

    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
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
    expect(find.text(_en.cardDiscardTitle), findsNothing);

    held.release.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(_en.cardDiscardTitle), findsNothing);
  });

  /// Opens the editor on a card whose edit ends with [then], saves, and lets
  /// it end.
  Future<void> saveEndingWith(
    WidgetTester tester,
    LibraryEnv env,
    Future<Outcome<void, CardRejection>> Function() then,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final held = _HeldEdits(env.cards, then: then);
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
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

    expect(find.text(_en.cardEditorGoneTitle), findsOneWidget);
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
    expect(find.text(_en.cardDiscardTitle), findsNothing);
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
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
          .onPressed,
      isNotNull,
    );
  });

  libraryTest('a deleted card: a danger banner, Save off, the draft kept, '
      'leaving asks nothing (2.17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardEditorGoneTitle), findsOneWidget);
    expect(find.text(_en.cardEditorGoneBody), findsOneWidget);
    expect(_text(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNull,
    );
    // Written at once, not after the pause.
    expect(
      (await _drafts(env).read(CardDraftKey.edit(card.id)))?.back,
      'changed',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardTitle), findsNothing);
  });

  libraryTest('a read error after the form opened keeps it, with a warning '
      'that never says deleted (2.17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    // The real card, then whatever the test adds: the Drift stream is torn
    // down with the tree, as in the app.
    late final StreamSubscription<CardDetail?> real;
    late final StreamController<CardDetail?> source;
    source = StreamController<CardDetail?>(
      onListen: () => real = env.cards
          .watchDetail(card.id)
          .listen((detail) => source.add(detail)),
      onCancel: () => real.cancel(),
    );
    addTearDown(source.close);
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_ScriptedDetail(source.stream)),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');

    source.addError(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardEditorStaleTitle), findsOneWidget);
    expect(find.text(_en.cardEditorGoneTitle), findsNothing);
    expect(_text(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNotNull,
    );
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('Save over a version another device saved asks first; Keep '
      'mine saves over it (2.18)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();

    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardChangedTitle), findsOneWidget);
    expect(await _backOf(env, card.id), 'theirs');

    await tester.tap(find.text(_en.cardKeepMine));
    await tester.pumpAndSettle();
    expect(await _backOf(env, card.id), 'mine');
  });

  libraryTest('Use theirs reloads the card, drops the edits and the draft '
      '(2.18)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'mine');
    await tester.pump(_pause);
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.cardUseTheirs));
    await tester.pumpAndSettle();

    expect(_text(tester, 1), 'theirs');
    expect(await _backOf(env, card.id), 'theirs');
    expect(await _drafts(env).read(CardDraftKey.edit(card.id)), isNull);
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNull,
    );
  });

  libraryTest('dismissing the dialog without a choice writes nothing and '
      'keeps the edits (2.18)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardChangedTitle), findsNothing);
    expect(_text(tester, 1), 'mine');
    expect(await _backOf(env, card.id), 'theirs');
  });

  libraryTest('a card that comes back is saveable again and the deleted '
      'banner goes (2.17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    late final StreamSubscription<CardDetail?> real;
    late final StreamController<CardDetail?> source;
    source = StreamController<CardDetail?>(
      onListen: () => real = env.cards
          .watchDetail(card.id)
          .listen((detail) => source.add(detail)),
      onCancel: () => real.cancel(),
    );
    addTearDown(source.close);
    // Save finds the card missing (_isGone) before the stream says so.
    final held = _HeldEdits(
      env.cards,
      then: () async => const Rejected(CardRejection.notFound),
    );
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_ScriptedDetail(source.stream)),
        ),
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');
    final present = (await tester.runAsync(
      () => env.cards.watchDetail(card.id).first,
    ))!;
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pump();
    held.release.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text(_en.cardEditorGoneTitle), findsOneWidget);

    source.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text(_en.cardEditorGoneTitle), findsOneWidget);
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNull,
    );

    source.add(present);
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardEditorGoneTitle), findsNothing);
    expect(_text(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNotNull,
    );
  });
}
