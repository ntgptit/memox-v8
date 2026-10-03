import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';

import 'card_editor_draft_harness.dart';

// SP2a 2.14–2.18 (R9): the card being written survives a closed editor, a
// killed process, a refused or deleted target and a change from another
// device. The draft lives in `card_draft`, on this device only.
//
// A read error, and a card another device saved or that comes back.

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
      now: libraryToday.add(const Duration(days: 1)),
    );

void main() {
  libraryTest('a read error after the form opened keeps it, with a warning '
      'that never says deleted (2.17)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
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
      editScreen(card.id),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_ScriptedDetail(source.stream)),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'changed');

    source.addError(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
    await tester.pump();
    await tester.pump();

    expect(find.text(enL10n.cardEditorStaleTitle), findsOneWidget);
    expect(find.text(enL10n.cardEditorGoneTitle), findsNothing);
    expect(textAt(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
      isNotNull,
    );
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('Save over a version another device saved asks first; Keep '
      'mine saves over it (2.18)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();

    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardChangedTitle), findsOneWidget);
    expect(await _backOf(env, card.id), 'theirs');

    await tester.tap(find.text(enL10n.cardKeepMine));
    await tester.pumpAndSettle();
    expect(await _backOf(env, card.id), 'mine');
  });

  libraryTest('Use theirs reloads the card, drops the edits and the draft '
      '(2.18)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'mine');
    await tester.pump(draftPause);
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pumpAndSettle();

    await tester.tap(find.text(enL10n.cardUseTheirs));
    await tester.pumpAndSettle();

    expect(textAt(tester, 1), 'theirs');
    expect(await _backOf(env, card.id), 'theirs');
    expect(await draftsOf(env).read(CardDraftKey.edit(card.id)), isNull);
    expect(
      tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
      isNull,
    );
  });

  libraryTest('after Use theirs a further edit saves without the dialog '
      '(2.18)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pumpAndSettle();
    await tester.tap(find.text(enL10n.cardUseTheirs));
    await tester.pumpAndSettle();

    await tester.enterText(fieldAt(1), 'again');
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardChangedTitle), findsNothing);
    expect(await _backOf(env, card.id), 'again');
  });

  libraryTest('dismissing the dialog without a choice writes nothing and '
      'keeps the edits (2.18)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editScreen(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardChangedTitle), findsNothing);
    expect(textAt(tester, 1), 'mine');
    expect(await _backOf(env, card.id), 'theirs');
  });

  libraryTest('a card that comes back is saveable again and the deleted '
      'banner goes (2.17)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
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
    final held = HeldEdits(
      env.cards,
      then: () async => const Rejected(CardRejection.notFound),
    );
    await pumpLibraryScreen(
      tester,
      env,
      editScreen(card.id),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_ScriptedDetail(source.stream)),
        ),
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(fieldAt(1), 'changed');
    final present = (await tester.runAsync(
      () => env.cards.watchDetail(card.id).first,
    ))!;
    await tester.pump();
    await tester.tap(footerSave(enL10n.cardSaveChanges));
    await tester.pump();
    held.release.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);

    source.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);
    expect(
      tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
      isNull,
    );

    source.add(present);
    await tester.pump();
    await tester.pump();

    expect(find.text(enL10n.cardEditorGoneTitle), findsNothing);
    expect(textAt(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
      isNotNull,
    );
  });

  libraryTest(
    'a Save that finds the card missing stays gone while the card still '
    'reads as present (2.17)',
    (tester, env) async {
      final deckId = await seedWordsDeck(env);
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
      final held = HeldEdits(
        env.cards,
        then: () async => const Rejected(CardRejection.notFound),
      );
      await pumpLibraryScreen(
        tester,
        env,
        editScreen(card.id),
        overrides: [
          watchCardDetailUseCaseProvider.overrideWithValue(
            WatchCardDetailUseCase(_ScriptedDetail(source.stream)),
          ),
          editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
        ],
      );
      await tester.pumpAndSettle();
      await tester.enterText(fieldAt(1), 'changed');
      final present = (await tester.runAsync(
        () => env.cards.watchDetail(card.id).first,
      ))!;
      await tester.pump();
      await tester.tap(footerSave(enL10n.cardSaveChanges));
      await tester.pump();
      held.release.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);

      source.add(present);
      await tester.pump();
      await tester.pump();

      expect(find.text(enL10n.cardEditorGoneTitle), findsOneWidget);
      expect(
        tester.widget<MxButton>(footerSave(enL10n.cardSaveChanges)).onPressed,
        isNull,
      );
    },
  );
}
