import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
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
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/deck_screen_harness.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Deck writes that land, counted: a second one would write twice.
final class _CountedDeckActions extends DeckActionsController {
  _CountedDeckActions(this.writes);

  /// Shared across rebuilds: the provider makes a new one each time.
  final List<String> writes;

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
  }) {
    writes.add('create');
    return super.createRootDeck(name: name, schedulerType: schedulerType);
  }

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
  }) {
    writes.add('rename');
    return super.renameDeck(deckId: deckId, name: name);
  }

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

// REG-HELD-SCOPE: a bug in what follows a landed write (here the toast,
// which throws with no toast host) is not a failed write. The flow closes
// as after any landed write and never offers Retry, so nothing writes
// twice.
void main() {
  libraryTest('a delete that landed closes its dialog though its toast '
      'fails (FE-B1)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showDeleteDeckDialog(context, deck: korean)),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
      hasToastHost: false,
    );
    await _open(tester);
    await tapThroughToastBug(tester, find.text(_en.trashMoveConfirm));

    expect(find.byType(MxDialog), findsNothing);
    expect(writes, ['delete']);
  });

  libraryTest('a move that landed closes its sheet though its toast fails '
      '(UC-DECK-005)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.root('Japanese');
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showMoveDeckSheet(context, deck: words)),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
      hasToastHost: false,
    );
    await _open(tester);
    await tapThroughToastBug(tester, find.text('Japanese'));

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(writes, ['move']);
  });

  libraryTest('a reset that landed closes its dialog though its toast fails '
      '(UC-SRS-001)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
      hasToastHost: false,
    );
    await openResetDialog(tester);
    await tapThroughToastBug(tester, find.text(_en.resetConfirm));

    expect(find.byType(MxDialog), findsNothing);
    expect(writes, ['reset']);
  });

  libraryTest('a switch that landed stops spinning and offers no Retry '
      'though its toast fails (UC-DECK-002)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
      hasToastHost: false,
    );
    // The switch runs from the row's tap, which awaits the confirm dialog.
    final uncaught = await tapKeepingUncaught(
      tester,
      find.text(_en.deckSchedulerEightBox),
    );
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(uncaught, [isToastHostMissing]);

    expect(find.text(_en.algorithmSwitchFailedTitle), findsNothing);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(find.byType(MxSpinner), findsNothing);
    expect(writes, ['switch']);
  });

  // A second tap lands before the frame that draws the confirm busy: the
  // submit itself refuses it, as delete, purge and move do.
  Future<void> doubleTap(WidgetTester tester, String label) async {
    final confirm = find.text(label);
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    // The landed write's toast times out.
    await tester.pump(const Duration(seconds: 5));
  }

  libraryTest('a second tap in the same frame does not reset twice '
      '(UC-SRS-001)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
    );
    await openResetDialog(tester);
    await doubleTap(tester, _en.resetConfirm);

    expect(writes, ['reset']);
  });

  libraryTest('a second tap in the same frame does not create two decks '
      '(UC-DECK-001)', (tester, env) async {
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      _host(showCreateRootDeckDialog),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pump();
    await doubleTap(tester, _en.deckCreateConfirm);

    expect(writes, ['create']);
  });

  libraryTest('a second tap in the same frame does not rename twice '
      '(UC-DECK-004)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final writes = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      _host((context) => showRenameDeckDialog(context, deck: korean)),
      overrides: [
        deckActionsControllerProvider.overrideWith(
          () => _CountedDeckActions(writes),
        ),
      ],
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await doubleTap(tester, _en.deckRenameConfirm);

    expect(writes, ['rename']);
  });
}
