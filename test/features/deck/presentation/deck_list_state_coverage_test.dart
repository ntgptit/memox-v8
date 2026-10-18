import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_deletion_summary_provider.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_use_case_provider.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/deck_screen_harness.dart';
import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';

// The States rows of screen 01 (Deck list) whose detail file cites no
// executed test: deckEmptyTopLevel, deckMaxDepth, deckLoading, deckError,
// deleteSummaryPending and deleteSummaryFailed.

final _en = lookupAppLocalizations(const Locale('en'));

Finder _unsetButton(String label) => find.widgetWithText(MxButton, label);

Finder _newSubDeckFab() => find.byWidgetPredicate(
  (widget) => widget is MxFab && widget.semanticLabel == _en.deckCreateSub,
);

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

/// A root and one deck per level below it, down to [depth].
Future<List<DeckEntity>> _chain(LibraryEnv env, int depth) async {
  final decks = [await env.decks.root('Level 1')];
  for (var level = 2; level <= depth; level++) {
    decks.add(await env.decks.sub(decks.last.id, 'Level $level'));
  }
  return decks;
}

/// Opens the open deck's ⋮ and chooses Move to Trash.
Future<void> _openDeleteDialog(WidgetTester tester) async {
  await tester.tap(byControlLabel(_en.deckActions));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.deckDelete));
  await tester.pumpAndSettle();
}

MxSheetActions _actions(WidgetTester tester) =>
    tester.widget<MxSheetActions>(find.byType(MxSheetActions));

void main() {
  libraryTest('deckEmptyTopLevel: a top-level deck with no sub-deck says it '
      'is empty and offers a sub-deck only; no card, no Import '
      '(BR-DECK-005)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    expect(find.text(_en.deckRootEmptyTitle), findsOneWidget);
    expect(find.text(_en.deckRootEmptyBody), findsOneWidget);
    expect(_unsetButton(_en.deckNewSubDeck), findsOneWidget);
    expect(_unsetButton(_en.deckNewCard), findsNothing);
    expect(_unsetButton(_en.deckUnsetImport), findsNothing);
  });

  libraryTest('deckMaxDepth: the deck at level 9 keeps its New sub-deck FAB '
      'and a level-10 deck with no card has none (BR-DECK-001)', (
    tester,
    env,
  ) async {
    final chain = await _chain(env, DeckEntity.maxDepth);
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain[DeckEntity.maxDepth - 2].id),
    );
    expect(_newSubDeckFab(), findsOneWidget);

    await pumpLibraryScreen(tester, env, deckScreen(deckId: chain.last.id));
    expect(chain.last.depth, DeckEntity.maxDepth);
    expect(_newSubDeckFab(), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });

  libraryTest('deckMaxDepth: a level-10 deck holding a card offers no New '
      'sub-deck FAB either (BR-DECK-001)', (tester, env) async {
    final chain = await _chain(env, DeckEntity.maxDepth);
    await env.cards.card(
      chain.last.id,
      const CardDraft(front: 'mul', back: 'water'),
    );
    await pumpLibraryScreen(tester, env, deckScreen(deckId: chain.last.id));

    expect(_newSubDeckFab(), findsNothing);
  });

  libraryTest('deckLoading: an open deck whose read has not landed shows '
      'skeleton rows under the plain Library bar', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id),
      overrides: [
        deckViewProvider(korean.id).overrideWith(
          (ref) => StreamController<Outcome<DeckView, DeckRejection>>().stream,
        ),
      ],
    );

    final skeleton = tester.widget<MxSkeletonList>(find.byType(MxSkeletonList));
    expect(skeleton.semanticLabel, _en.commonLoading);
    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
  });

  libraryTest('deckError: an open deck that cannot be read says so with '
      'Retry; Retry reads it again', (tester, env) async {
    final korean = await env.decks.root('Korean');
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id),
      overrides: [
        deckViewProvider(korean.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<Outcome<DeckView, DeckRejection>>.error(
              StateError('disk I/O error'),
            );
          }
          return ref.watch(watchDeckUseCaseProvider)(deckId: korean.id);
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.deckLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.libraryLoadErrorBody), findsOneWidget);
    expect(find.textContaining('disk'), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(reads, 2);
    expect(find.byType(MxErrorState), findsNothing);
    expect(_barTitle('Korean'), findsOneWidget);
  });

  libraryTest('deleteSummaryPending: before the count is read the Move to '
      'Trash dialog has no body, no note and a disabled confirm', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id),
      overrides: [
        deckDeletionSummaryProvider(korean.id).overrideWith(
          (ref) =>
              Completer<Outcome<DeckDeletionSummary, DeckRejection>>().future,
        ),
      ],
    );
    await _openDeleteDialog(tester);

    final dialog = tester.widget<MxDialog>(find.byType(MxDialog));
    expect(dialog.title, _en.deckDeleteTitle);
    expect(dialog.body, isNull);
    expect(dialog.content, isNull);
    expect(find.text(_en.deckDeleteNote), findsNothing);
    expect(_actions(tester).confirmLabel, _en.trashMoveConfirm);
    expect(_actions(tester).onConfirm, isNull);
    expect(_actions(tester).onCancel, isNotNull);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });

  for (final (name, summary, message)
      in <
        (
          String,
          Future<Outcome<DeckDeletionSummary, DeckRejection>> Function(),
          String,
        )
      >[
        (
          'a rejection',
          () async => const Rejected(DeckRejection.notFound),
          _en.deckRejectionNotFound,
        ),
        (
          'a Failure',
          () => Future.error(const DatabaseLockedFailure(cause: 'busy')),
          _en.failure(const DatabaseLockedFailure(cause: 'busy')),
        ),
        (
          'an unexpected error',
          () => Future.error(StateError('count')),
          _en.failureUnknown,
        ),
      ]) {
    libraryTest('deleteSummaryFailed: $name says why in the dialog body; the '
        'confirm stays disabled and Cancel closes', (tester, env) async {
      final korean = await env.decks.root('Korean');
      await pumpLibraryScreen(
        tester,
        env,
        deckScreen(deckId: korean.id),
        overrides: [
          deckDeletionSummaryProvider(korean.id)
              .overrideWith((ref) => summary()),
        ],
      );
      await _openDeleteDialog(tester);

      expect(tester.widget<MxDialog>(find.byType(MxDialog)).body, message);
      expect(find.text(_en.deckDeleteNote), findsNothing);
      expect(_actions(tester).onConfirm, isNull);

      await tester.tap(find.text(_en.commonCancel));
      await tester.pumpAndSettle();
      expect(find.byType(MxDialog), findsNothing);
    });
  }
}
