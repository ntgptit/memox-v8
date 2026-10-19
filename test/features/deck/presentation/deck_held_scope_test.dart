import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/deck_screen_harness.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Deck writes that land, counted: a second one would write twice.
final class _CountedDeckActions extends DeckActionsController {
  final writes = <String>[];

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({required String deckId}) {
    writes.add('delete');
    return super.deleteDeck(deckId: deckId);
  }

  @override
  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
  }) {
    writes.add('move');
    return super.moveDeck(deckId: deckId, newParentId: newParentId);
  }

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) {
    writes.add('switch');
    return super.changeScheduler(
      rootDeckId: rootDeckId,
      schedulerType: schedulerType,
    );
  }

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) {
    writes.add('reset');
    return super.resetLearning(
      rootDeckId: rootDeckId,
      schedulerType: schedulerType,
    );
  }
}

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

/// Taps [label]: the toast after the write meets its bug, which is left
/// uncaught as itself, and no failure is said.
Future<void> _confirm(WidgetTester tester, String label) async {
  final uncaught = await tapKeepingUncaught(tester, find.text(label));
  expect(uncaught, [isA<FlutterError>()]);
  expect(find.text(_en.failureUnknown), findsNothing);
}

// REG-HELD-SCOPE: a bug in what follows a landed write (here the toast,
// which throws with no toast host) is not a failed write. The flow closes
// as after any landed write and never offers Retry, so nothing writes
// twice.
void main() {
  libraryTest('a delete that landed closes its dialog though its toast '
      'fails (FE-B1)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final actions = _CountedDeckActions();
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showDeleteDeckDialog(context, deck: korean)),
      overrides: [deckActionsControllerProvider.overrideWith(() => actions)],
      hasToastHost: false,
    );
    await _open(tester);
    await _confirm(tester, _en.trashMoveConfirm);

    expect(find.byType(MxDialog), findsNothing);
    expect(actions.writes, ['delete']);
  });

  libraryTest('a move that landed closes its sheet though its toast fails '
      '(UC-DECK-005)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.root('Japanese');
    final actions = _CountedDeckActions();
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showMoveDeckSheet(context, deck: words)),
      overrides: [deckActionsControllerProvider.overrideWith(() => actions)],
      hasToastHost: false,
    );
    await _open(tester);
    await _confirm(tester, 'Japanese');

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(actions.writes, ['move']);
  });

  libraryTest('a reset that landed closes its dialog though its toast fails '
      '(UC-SRS-001)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final actions = _CountedDeckActions();
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [deckActionsControllerProvider.overrideWith(() => actions)],
      hasToastHost: false,
    );
    await openResetDialog(tester);
    await _confirm(tester, _en.resetConfirm);

    expect(find.byType(MxDialog), findsNothing);
    expect(actions.writes, ['reset']);
  });

  libraryTest('a switch that landed stops spinning and offers no Retry '
      'though its toast fails (UC-DECK-002)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final actions = _CountedDeckActions();
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [deckActionsControllerProvider.overrideWith(() => actions)],
      hasToastHost: false,
    );
    // The switch runs from the row's tap, which awaits the confirm dialog.
    final uncaught = await tapKeepingUncaught(
      tester,
      find.text(_en.deckSchedulerEightBox),
    );
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(uncaught, [isA<FlutterError>()]);
    expect(find.text(_en.failureUnknown), findsNothing);

    expect(find.text(_en.algorithmSwitchFailedTitle), findsNothing);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(find.byType(MxSpinner), findsNothing);
    expect(actions.writes, ['switch']);
  });
}
