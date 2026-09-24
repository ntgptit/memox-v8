import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:memox/features/card/presentation/providers/create_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _create(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: _context);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, then the tag input once opened; the optional fields sit
/// between them once "Add details" is open.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder _footerSave(String label) => find.widgetWithText(MxButton, label);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

Future<int> _count(
  LibraryEnv env,
  String sql, [
  List<String> args = const [],
]) async =>
    (await env.db
            .customSelect(
              sql,
              variables: [for (final arg in args) Variable<String>(arg)],
            )
            .getSingle())
        .read<int>('n');

bool _isEnabled(WidgetTester tester, String label) =>
    tester.widget<MxButton>(_footerSave(label)).onPressed != null;

/// Cards whose create fails the first way a real database can.
final class _FailingCards implements CardRepository {
  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('Save waits for a front and a back', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));

    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
    expect(find.text(_en.cardCaptionRequired), findsOneWidget);
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();

    expect(_isEnabled(tester, _en.cardSaveCard), isTrue);
    expect(find.text(_en.cardCaptionKeepAdding), findsOneWidget);
  });

  libraryTest('Save adds the card, clears the form and refocuses (RF1)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(_field(2), 'food');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 1);
    expect(find.text(_en.cardAddedToast), findsOneWidget);
    expect(find.text('bap'), findsNothing);
    expect(tester.widget<EditableText>(_field(0)).focusNode.hasFocus, isTrue);

    // Saved, so leaving asks nothing.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsNothing);
  });

  libraryTest('a double tap on Save adds one card', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.tap(_footerSave(_en.cardSaveCard), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
  });

  libraryTest('errors show as the person types (ruling P4a-L2)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(1), 'x');
    await tester.enterText(_field(1), '');
    await tester.enterText(_field(0), 'a' * (CardDraft.maxFrontLength + 1));
    await tester.pump();

    expect(find.text(_en.cardBackBlank), findsOneWidget);
    expect(find.text(_en.cardFrontTooLong), findsOneWidget);
    expect(find.text(_en.cardCaptionFix), findsOneWidget);
    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
  });

  libraryTest('Add details opens the optional fields', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    expect(find.text(_en.cardExampleHint), findsNothing);

    await tester.tap(find.text(_en.cardAddDetails));
    await tester.pump();
    for (final hint in [
      _en.cardExampleHint,
      _en.cardHintHint,
      _en.cardPronunciationHint,
    ]) {
      expect(find.text(hint), findsOneWidget);
    }
  });

  libraryTest('Back on a changed form asks; Keep editing keeps it (RF2)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);
    await tester.tap(find.text(_en.cardKeepEditing));
    await tester.pumpAndSettle();
    expect(find.text('bap'), findsOneWidget);
  });

  libraryTest('a failed save keeps the form and offers Retry save (RF4)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(
      tester,
      env,
      _create(deckId),
      overrides: [
        createCardUseCaseProvider.overrideWithValue(
          CreateCardUseCase(_FailingCards()),
        ),
      ],
    );
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSaveFailedTitle), findsOneWidget);
    expect(_footerSave(_en.cardRetrySave), findsOneWidget);
    expect(find.text('bap'), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('a deck that now holds decks refuses with a warning banner', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await env.decks.sub(deckId, 'Verbs');
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDeckRejectsTitle), findsOneWidget);
    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('edit starts from the card, flags in the app bar, saves', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice', tagNames: ['food']),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();

    expect(find.text('bap'), findsOneWidget);
    expect(find.textContaining(_en.cardSummaryAnswers(0)), findsOneWidget);
    await tester.tap(find.byTooltip(_en.cardFlagLabel));
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE back = ? AND is_flagged',
        ['cooked rice'],
      ),
      1,
    );
    // The tags sit below the fold of a 360×800 screen.
    await tester.dragUntilVisible(
      find.bySemanticsLabel(_en.cardTagRemove('food')),
      find.byType(ListView),
      const Offset(0, -200),
    );
  });

  libraryTest('a card deleted while editing shows it is gone (RF3)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.text(_en.cardBackToDeck), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('the editor holds Hangul at 2x and meets the guidelines (RF5)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId), textScale: 2);
    await tester.enterText(_field(0), List.filled(4, '한국어 단어').join(' '));
    await tester.pump();

    expect(find.text(_en.cardFieldCount(27, 60)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('the flag toggle reports its state (ruling P4a-L6)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byTooltip(_en.cardFlagLabel)),
      isSemantics(hasToggledState: true, isToggled: false),
    );

    await tester.tap(find.byTooltip(_en.cardFlagLabel));
    await tester.pump();
    expect(
      tester.getSemantics(find.byTooltip(_en.cardFlagClear)),
      isSemantics(hasToggledState: true, isToggled: true),
    );
  });

  libraryTest('a tag typed but not added still asks before leaving', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(_field(2), 'food');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);
  });
}
