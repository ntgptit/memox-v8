import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// A move and a tag that die on a bug, not a Failure (ADR-016).
final class _BrokenActions extends CardActionsController {
  @override
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, TagRejection>> addTag({
    required Set<String> cardIds,
    required String tagName,
  }) async => throw heldBug();
}

/// Cards whose save and older history pages die on a bug.
final class _BrokenCards implements CardRepository {
  _BrokenCards(this._real);

  final CardRepository _real;

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) async => throw heldBug();

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    if (after != null) throw heldBug();
    return _real.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// Korean › Words: annyeong; Korean › Verbs: the target of a move.
Future<String> _seedWords(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await env.decks.sub(korean.id, 'Verbs');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  return words.id;
}

/// Picks the one card and opens its bulk command [label].
Future<void> _bulk(WidgetTester tester, String label) async {
  await tester.longPress(find.text('annyeong'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _footerSave(String label) => find.widgetWithText(MxButton, label);

// LIB-6: a held write that meets a bug releases its flow, says so as an
// unknown failure and reports the bug (runHeld). The delete dialog's
// own test is in card_bulk_actions_test.dart.
void main() {
  libraryTest('a move that dies on a bug releases the sheet (UC-CARD-001 A5)', (
    tester,
    env,
  ) async {
    final words = await _seedWords(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(words),
      overrides: [
        cardActionsControllerProvider.overrideWith(_BrokenActions.new),
      ],
    );
    await _bulk(tester, _en.cardMove);
    await tester.tap(
      find.descendant(
        of: find.byType(MxDeckPickerSheet),
        matching: find.text('Korean › Verbs'),
      ),
    );
    await tester.pump();

    expectBugReported(tester);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
  });

  libraryTest('a tag that dies on a bug releases the dialog (UC-CARD-001 A8)', (
    tester,
    env,
  ) async {
    final words = await _seedWords(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(words),
      overrides: [
        cardActionsControllerProvider.overrideWith(_BrokenActions.new),
      ],
    );
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText), 'greetings');
    await tester.tap(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.cardTagConfirm),
      ),
    );
    await tester.pump();

    expectBugReported(tester);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });

  libraryTest('a save that dies on a bug leaves the editor saying so, with '
      'its controls back (Ruling P4a-L3)', (tester, env) async {
    final words = await _seedWords(env);
    final card = await env.cards.card(words);
    await pumpLibraryScreen(
      tester,
      env,
      CardEditorScreen.edit(
        cardId: card.id,
        deckContext: (deckId, label) =>
            DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
      ),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(
          EditCardUseCase(_BrokenCards(env.cards)),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expectBugReported(tester);
    expect(find.text(_en.cardSaveChangesFailedTitle), findsOneWidget);
    expect(_footerSave(_en.cardRetrySave), findsOneWidget);
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardRetrySave)).onPressed,
      isNotNull,
    );
    final back = find.byWidgetPredicate(
      (widget) =>
          widget is MxIconButton && widget.semanticLabel == _en.commonBack,
    );
    expect(tester.widget<MxIconButton>(back).onPressed, isNotNull);
  });

  libraryTest('an older history page that dies on a bug offers Retry, not a '
      'spinner for good (UC-CARD-002 E4)', (tester, env) async {
    await _seedWords(env);
    for (var i = 0; i <= ReviewHistoryPage.size; i++) {
      await logReview(
        env.db,
        id: 'r$i',
        cardId: 'new1',
        at: DateTime(2026, 9, 1, 8).add(Duration(minutes: i)),
      );
    }
    final container = libraryContainer(
      env,
      overrides: [
        loadCardHistoryPageUseCaseProvider.overrideWithValue(
          LoadCardHistoryPageUseCase(_BrokenCards(env.cards)),
        ),
      ],
    );
    final provider = cardHistoryControllerProvider('new1');
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    await container.read(provider.notifier).loadMore();

    expectBugReported(tester);
    final view = container.read(provider).requireValue;
    expect(view.hasMoreFailed, isTrue);
    expect(view.isLoadingMore, isFalse);
    expect(view.entries, hasLength(ReviewHistoryPage.size));
  });
}
