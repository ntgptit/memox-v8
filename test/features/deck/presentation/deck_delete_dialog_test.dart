import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/usecases/delete_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/deck_deletion_summary_provider.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/get_deck_deletion_summary_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// Longer than the dialog's exit, so a pop that was not held would be gone.
const _exit = Duration(milliseconds: 500);

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showDeleteDeckDialog(context, deck: deck),
    ),
  ),
);

/// Opens the dialog over [deck], its delete behind the returned hold.
Future<WriteHold> _open(
  WidgetTester tester,
  LibraryEnv env,
  DeckEntity deck, {
  List<Override> overrides = const [],
}) async {
  final hold = WriteHold();
  await pumpLibraryScreen(
    tester,
    env,
    _host(deck),
    overrides: [
      deleteDeckUseCaseProvider.overrideWithValue(
        DeleteDeckUseCase(HeldDecks(env.decks, hold)),
      ),
      ...overrides,
    ],
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return hold;
}

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

void main() {
  libraryTest('a failed summary read says so in a warning banner with Retry; '
      'Cancel stays live and the confirm waits for the count (final fix 6)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    var reads = 0;
    await _open(
      tester,
      env,
      korean,
      overrides: [
        deckDeletionSummaryProvider(korean.id).overrideWith((ref) async {
          if (++reads == 1) throw WriteHold.failure;
          return ref.watch(getDeckDeletionSummaryUseCaseProvider)(
            deckId: korean.id,
          );
        }),
      ],
    );

    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    var actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.onConfirm, isNull);
    expect(actions.onCancel, isNotNull);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.deckDeleteNote), findsOneWidget);
    actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.onConfirm, isNotNull);
    expect(reads, 2);
  });

  libraryTest('Back, a scrim tap and Cancel wait for the move; its toast with '
      'Undo then arrives (SP2b 2.26)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await _open(tester, env, korean);
    await tester.tap(find.text(_en.deckDelete));
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
    expect(find.text(_en.deckTrashedToast('Korean', 0, 0)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);
  });

  libraryTest('a failed move keeps the dialog with a warning banner, and Move '
      'to Trash is the retry (SP2b 2.27)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await _open(tester, env, korean);
    hold
      ..open()
      ..failNext();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(hold.calls, 2);
    expect(find.text(_en.deckTrashedToast('Korean', 0, 0)), findsOneWidget);
  });

  libraryTest('a write that throws a non-Failure is reported and releases the '
      'dialog (SP2b 2.26)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await _open(tester, env, korean);
    hold
      ..open()
      ..failNext(StateError('boom'));
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<StateError>());
    expect(_banner(_en.failureUnknown), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });
}
