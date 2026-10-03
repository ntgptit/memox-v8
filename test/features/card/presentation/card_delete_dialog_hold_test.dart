import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/usecases/delete_cards_use_case.dart';
import 'package:memox/features/card/presentation/providers/delete_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';
import 'card_bulk_actions_harness.dart';

// Longer than the dialog's exit, so a pop that was not held would be gone.
const _exit = Duration(milliseconds: 500);

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

/// Opens screen 07's dialog over the seeded card `new1`, its delete behind
/// the returned hold.
Future<WriteHold> _open(WidgetTester tester, LibraryEnv env) async {
  await seedBulkCards(env);
  final hold = WriteHold();
  await pumpLibraryScreen(
    tester,
    env,
    Scaffold(
      body: Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () => showDeleteCardsDialog(
            context,
            cardIds: {'new1'},
            preview: (front: 'annyeong', back: 'hello'),
          ),
        ),
      ),
    ),
    overrides: [
      deleteCardsUseCaseProvider.overrideWithValue(
        DeleteCardsUseCase(HeldCards(env.cards, hold)),
      ),
    ],
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return hold;
}

void main() {
  libraryTest('Cancel, Back and a scrim tap wait for the move; the Undo toast '
      'then arrives (SP2b final 2)', (tester, env) async {
    final hold = await _open(tester, env);
    await tester.tap(find.text(enL10n.cardMoveToTrashCount(1)));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(_exit);
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(_exit);
    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNull,
    );

    hold.open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(enL10n.cardTrashedToast('annyeong')), findsOneWidget);
    expect(find.text(enL10n.commonUndo), findsOneWidget);
  });

  libraryTest('a failed move keeps the dialog with a warning banner and no '
      'toast; the confirm is the retry (SP2b final 2)', (tester, env) async {
    final hold = await _open(tester, env);
    hold
      ..open()
      ..failNext();
    await tester.tap(find.text(enL10n.cardMoveToTrashCount(1)));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(_banner(enL10n.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text(enL10n.cardMoveToTrashCount(1)));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(hold.calls, 2);
    expect(find.text(enL10n.cardTrashedToast('annyeong')), findsOneWidget);
  });

  libraryTest('a write that throws a non-Failure is reported and releases '
      'the dialog, and Retry succeeds (SP2b final 2)', (tester, env) async {
    final hold = await _open(tester, env);
    hold
      ..open()
      ..failNext(StateError('boom'));
    await tester.tap(find.text(enL10n.cardMoveToTrashCount(1)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<StateError>());
    expect(_banner(enL10n.failureUnknown), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNotNull,
    );

    await tester.tap(find.text(enL10n.cardMoveToTrashCount(1)));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(enL10n.cardTrashedToast('annyeong')), findsOneWidget);
  });
}
