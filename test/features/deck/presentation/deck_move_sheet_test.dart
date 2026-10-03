import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/usecases/move_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/move_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _exit = Duration(milliseconds: 500);

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showMoveDeckSheet(context, deck: deck),
    ),
  ),
);

/// Korean › {Words, Grammar}, the sheet open over Grammar, its move behind
/// the returned hold.
Future<({WriteHold hold, DeckEntity grammar, DeckEntity words})> _open(
  WidgetTester tester,
  LibraryEnv env,
) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final grammar = await env.decks.sub(korean.id, 'Grammar');
  final hold = WriteHold();
  await pumpLibraryScreen(
    tester,
    env,
    _host(grammar),
    overrides: [
      moveDeckUseCaseProvider.overrideWithValue(
        MoveDeckUseCase(HeldDecks(env.decks, hold)),
      ),
    ],
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (hold: hold, grammar: grammar, words: words);
}

void main() {
  libraryTest('Back, a scrim tap and Cancel wait for the move; its toast then '
      'arrives (SP2b 2.26)', (tester, env) async {
    final (:hold, :grammar, :words) = await _open(tester, env);
    await tester.tap(find.text('Korean › Words'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(_exit);
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(_exit);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
          .onPressed,
      isNull,
    );

    hold.open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
    expect((await env.decks.findById(grammar.id))!.parentId, words.id);
  });

  libraryTest('a failed move keeps the sheet with a banner; choosing again is '
      'the retry (SP2b 2.27)', (tester, env) async {
    final (:hold, :grammar, :words) = await _open(tester, env);
    hold
      ..open()
      ..failNext();
    await tester.tap(find.text('Korean › Words'));
    await tester.pumpAndSettle();

    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.failure(WriteHold.failure)),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester
          .widget<MxListRow>(find.widgetWithText(MxListRow, 'Korean › Words'))
          .isEnabled,
      isTrue,
    );

    await tester.tap(find.text('Korean › Words'));
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(hold.calls, 2);
    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
    expect((await env.decks.findById(grammar.id))!.parentId, words.id);
  });

  libraryTest('a second tap while the move runs does nothing (SP2b 2.26)', (
    tester,
    env,
  ) async {
    final (:hold, :grammar, :words) = await _open(tester, env);
    await tester.tap(find.text('Korean › Words'));
    await tester.pump();
    expect(
      tester
          .widget<MxListRow>(find.widgetWithText(MxListRow, 'Korean › Words'))
          .isEnabled,
      isFalse,
    );
    await tester.tap(find.text('Korean › Words'), warnIfMissed: false);
    await tester.pump();

    hold.open();
    await tester.pumpAndSettle();
    expect(hold.calls, 1);
    expect((await env.decks.findById(grammar.id))!.parentId, words.id);
  });
}
