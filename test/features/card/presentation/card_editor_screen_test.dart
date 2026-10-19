import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_edit_summary_widget.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/presentation/providers/create_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import 'package:memox/shared/widgets/mx_dot_overline.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';
import '../../../support/forui_expect.dart';

import 'package:forui/forui.dart';

import 'support/card_editor_host.dart';
import 'support/words_deck.dart';
import 'support/failing_card_writes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

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
    tester.widget<MxButton>(editorFooterButton(label)).onPressed != null;

/// Counts the edits it passes on to [_cards].
final class _CountingEdits implements CardRepository {
  _CountingEdits(this._cards);

  final CardRepository _cards;
  var edits = 0;

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) {
    edits++;
    return _cards.editCard(cardId: cardId, draft: draft, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('Save waits for a front and a back', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));

    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
    expect(find.text(_en.cardCaptionRequired), findsOneWidget);
    await tester.enterText(editorField(0), 'bap');
    await tester.enterText(editorField(1), 'rice');
    await tester.pump();

    expect(_isEnabled(tester, _en.cardSaveCard), isTrue);
    expect(find.text(_en.cardCaptionKeepAdding), findsOneWidget);
  });

  libraryTest('Save adds the card, clears the form and refocuses (RF1)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(0), 'bap');
    await tester.enterText(editorField(1), 'rice');
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(editorField(2), 'food');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 1);
    expect(find.text(_en.cardAddedToast), findsOneWidget);
    expect(find.text('bap'), findsNothing);
    expect(
      tester.widget<EditableText>(editorField(0)).focusNode.hasFocus,
      isTrue,
    );

    // Saved, so leaving asks nothing.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsNothing);
  });

  libraryTest('a double tap on Save adds one card', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(0), 'bap');
    await tester.enterText(editorField(1), 'rice');
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveCard));
    await tester.tap(editorFooterButton(_en.cardSaveCard), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
  });

  libraryTest('errors show as the person types (ruling P4a-L2)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(1), 'x');
    await tester.enterText(editorField(1), '');
    await tester.enterText(
      editorField(0),
      'a' * (CardDraft.maxFrontLength + 1),
    );
    // ForUI's field eases its message in.
    await tester.pumpAndSettle();

    expect(find.text(_en.cardBackBlank), findsOneWidget);
    expect(find.text(_en.cardFrontTooLong), findsOneWidget);
    expect(find.text(_en.cardCaptionFix), findsOneWidget);
    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
  });

  libraryTest('Add details opens the optional fields', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    expect(find.text(_en.cardExampleHint), findsNothing);

    await tester.tap(find.byType(CardAddDetailsWidget));
    await tester.pump();
    for (final hint in [
      _en.cardExampleHint,
      _en.cardHintHint,
      _en.cardPronunciationHint,
    ]) {
      expect(find.text(hint), findsOneWidget);
    }
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('Back on a changed form asks; Keep editing keeps it (RF2)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(0), 'bap');
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
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(
      tester,
      env,
      createEditor(deckId),
      overrides: [
        createCardUseCaseProvider.overrideWithValue(
          CreateCardUseCase(FailingCardWrites()),
        ),
      ],
    );
    await tester.enterText(editorField(0), 'bap');
    await tester.enterText(editorField(1), 'rice');
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSaveFailedTitle), findsOneWidget);
    expect(editorFooterButton(_en.cardRetrySave), findsOneWidget);
    expect(find.text('bap'), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('a deck that now holds decks refuses with a warning banner', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await env.decks.sub(deckId, 'Verbs');
    await tester.enterText(editorField(0), 'bap');
    await tester.enterText(editorField(1), 'rice');
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDeckRejectsTitle), findsOneWidget);
    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('edit starts from the card, flags in the app bar, saves', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice', tagNames: ['food']),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();

    expect(find.text('bap'), findsOneWidget);
    expect(find.textContaining(_en.cardSummaryAnswers(0)), findsOneWidget);
    // The status is the badge screen 10 shows, not a word in the line
    // (audit 2026-10-19, G6).
    expect(
      find.descendant(
        of: find.byType(CardEditSummaryWidget),
        matching: find.byType(MxStatusBadge),
      ),
      findsOneWidget,
    );
    // Beside the badge the due date wraps rather than cut (final review F6).
    final row = find.ancestor(
      of: find.byType(MxStatusBadge),
      matching: find.byType(MxListRow),
    );
    expect(tester.widget<MxListRow>(row).titleMaxLines, 2);
    await tester.tap(byControlLabel(_en.cardFlagLabel));
    await tester.enterText(editorField(1), 'cooked rice');
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveChanges));
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
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(editorField(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.text(_en.cardBackToDeck), findsOneWidget);
    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
      ),
      0,
    );
  });

  libraryTest('the editor holds Hangul and meets the guidelines (RF5)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(0), List.filled(4, '한국어 단어').join(' '));
    await tester.pump();

    expect(find.text(_en.cardFieldCount(27, 60)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('the flag toggle reports its state under one stable name, '
      'never a label that contradicts it (ruling P4a-L6; audit 2026-10-17)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(byControlLabel(_en.cardFlagLabel)),
      isSemantics(hasToggledState: true, isToggled: false),
    );

    await tester.tap(byControlLabel(_en.cardFlagLabel));
    await tester.pump();
    expect(
      tester.getSemantics(byControlLabel(_en.cardFlagLabel)),
      isSemantics(hasToggledState: true, isToggled: true),
    );
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a tag typed but not added still asks before leaving', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(editorField(2), 'food');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);
  });

  libraryTest('a double tap on Save changes writes once', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(deckId);
    final counting = _CountingEdits(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      editEditor(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(counting)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(editorField(1), 'changed');
    await tester.pump();
    await tester.tap(editorFooterButton(_en.cardSaveChanges));
    await tester.tap(
      editorFooterButton(_en.cardSaveChanges),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(counting.edits, 1);
  });

  libraryTest('a 60-character term wraps and stays in view', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(0), 'a' * 60);
    await tester.pump();

    final term = tester.renderObject<RenderBox>(editorField(0));
    final role = tester.element(editorField(0)).texts.body;
    expect(term.size.height, greaterThan(role.fontSize! * role.height!));
    expect(tester.takeException(), isNull);
  });

  libraryTest('Cancel and Save share the footer 1 : 1, outline first '
      '(DEV-169)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));

    final pair = tester.widget<MxActionPair>(find.byType(MxActionPair));
    expect(pair.leadingFlex, pair.trailingFlex);
    expect(pair.leading!.tone, MxButtonTone.outline);
    expect(pair.leading!.label, _en.commonCancel);
    Size size(String label) =>
        tester.getSize(find.widgetWithText(MxButton, label));
    expect(size(_en.commonCancel).width, size(_en.cardSaveCard).width);
  });

  libraryTest('the front and back of a card sit on the form field\'s box '
      '(DEV-169)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.enterText(editorField(0), 'gamsahamnida');
    await tester.enterText(editorField(1), 'thank you');
    await tester.pump();

    final box = tester
        .element(find.byType(FTextField).first)
        .dimens
        .sizeControl;
    expect(fieldBoxSize(tester, find.byType(FTextField).at(0)).height, box);
    expect(fieldBoxSize(tester, find.byType(FTextField).at(1)).height, box);
  });

  libraryTest('the editor saves from the footer only and marks the required '
      'fields without a separate legend (critique 2026-09-30)', (
    tester,
    env,
  ) async {
    final deckId = await seedWordsDeck(env);
    await pumpLibraryScreen(tester, env, createEditor(deckId));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MxButton, _en.cardSave), findsNothing);
    expect(find.widgetWithText(MxButton, _en.cardSaveCard), findsOneWidget);
    expect(find.byType(MxDotOverline), findsNothing);
    expect(find.text(_en.cardRequiredLegend), findsNWidgets(2));
  });

  libraryTest('leaving an edited card names what was edited (kit 09 '
      'discard)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(editorField(0), 'bab');
    await tester.enterText(editorField(1), 'cooked rice');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.text(
        _en.cardDiscardEditedBody(
          _en.cardEditedPair(_en.cardEditedTerm, _en.cardEditedMeaning),
        ),
      ),
      findsOneWidget,
    );
  });

  libraryTest('an edited card missing its back asks for the missing field '
      '(kit 09 validation)', (tester, env) async {
    final deckId = await seedWordsDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, editEditor(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(editorField(1), '');
    await tester.pump();

    expect(find.text(_en.cardCaptionAddMissing), findsOneWidget);
  });
}
