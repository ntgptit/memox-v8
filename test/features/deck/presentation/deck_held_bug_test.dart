import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/deck_reorder_harness.dart';
import '../../../support/deck_screen_harness.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Every deck write dies on a bug, not a Failure (ADR-016).
final class _BrokenDeckActions extends DeckActionsController {
  @override
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
  }) async => throw heldBug();

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
  }) async => throw heldBug();

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) async => throw heldBug();
}

final _broken = deckActionsControllerProvider.overrideWith(
  _BrokenDeckActions.new,
);

Widget _host(void Function(BuildContext context) open) => Scaffold(
  body: Builder(
    builder: (context) =>
        MxButton(label: 'Open', onPressed: () => open(context)),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// The dialog said the bug as an unknown failure, is no longer held, and
/// Back closes it.
Future<void> _expectDialogReleased(WidgetTester tester) async {
  expect(find.text(_en.failureUnknown), findsOneWidget);
  expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isFalse);
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byType(MxDialog), findsNothing);
}

// LIB-6: a held write that meets a bug releases its flow, says so as an
// unknown failure and reports the bug (runHeld).
void main() {
  libraryTest('a create that dies on a bug releases the new-deck dialog '
      '(UC-DECK-001)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(showCreateRootDeckDialog),
      overrides: [_broken],
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pump();
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pump();

    expectBugReported(tester);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isFalse);
    // Back is live again; the form is started, so it asks before it leaves.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.deckDiscardTitle), findsOneWidget);
    await tester.tap(find.text(_en.deckDiscard));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });

  libraryTest('a rename that dies on a bug releases the name dialog '
      '(UC-DECK-004)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showRenameDeckDialog(context, deck: korean)),
      overrides: [_broken],
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pump();

    expectBugReported(tester);
    await _expectDialogReleased(tester);
  });

  libraryTest('a move that dies on a bug releases the deck sheet '
      '(UC-DECK-005)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.root('Japanese');
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showMoveDeckSheet(context, deck: words)),
      overrides: [_broken],
    );
    await _open(tester);
    await tester.tap(find.text('Japanese'));
    await tester.pump();

    expectBugReported(tester);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsNothing);
  });

  libraryTest('a delete that dies on a bug releases the dialog (FE-B1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showDeleteDeckDialog(context, deck: korean)),
      overrides: [_broken],
    );
    await _open(tester);
    await tester.tap(find.text(_en.trashMoveConfirm));
    await tester.pump();

    expectBugReported(tester);
    await _expectDialogReleased(tester);
  });

  libraryTest('a reset that dies on a bug releases the dialog (UC-SRS-001 '
      'E1)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [_broken],
    );
    await openResetDialog(tester);
    await tester.tap(find.text(_en.resetConfirm));
    await tester.pump();

    expectBugReported(tester);
    await _expectDialogReleased(tester);
  });

  libraryTest('a switch that dies on a bug stops spinning and offers Retry, '
      'as a Failure does (UC-DECK-002 E2)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [_broken],
    );
    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expectBugReported(tester);
    expect(find.text(_en.algorithmSwitchFailedTitle), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.byType(MxSpinner), findsNothing);
    final eightBox = find.widgetWithText(
      MxOptionRow,
      _en.deckSchedulerEightBox,
    );
    expect(tester.widget<MxOptionRow>(eightBox).onSelected, isNotNull);
  });

  libraryTest('a drop that dies on a bug snaps back to the stored order and '
      'follows the level again (RF3)', (tester, env) async {
    final a = await env.decks.root('A');
    final b = await env.decks.root('B');
    await pumpLibraryScreen(tester, env, deckScreen(), overrides: [_broken]);
    await startReorder(tester);
    await dragPastNext(tester, 'A');

    expectBugReported(tester);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(shownOrder(tester), ['A', 'B']);

    // The level moves on by itself: the list follows it, so no drop is
    // still counted as saving.
    await env.decks.reorderDeck(
      deckId: a.id,
      anchorId: b.id,
      placement: DeckPlacement.after,
    );
    await tester.pumpAndSettle();
    expect(shownOrder(tester), ['B', 'A']);
  });
}
