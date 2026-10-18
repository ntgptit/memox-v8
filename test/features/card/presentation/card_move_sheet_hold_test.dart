import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/move_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// A held sheet shows no settling animation of its own: time moves by hand.
const _frames = Duration(milliseconds: 300);

/// A point on the scrim, above the sheet.
const _scrim = Offset(8, 8);

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// Korean › Words: annyeong, gamsa; Korean › Verbs: gada.
Future<({String words, String verbs})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final verbs = await env.decks.sub(korean.id, 'Verbs');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  await insertCard(env.db, id: 'due1', deckId: words.id, front: 'gamsa');
  await insertCard(env.db, id: 'verb1', deckId: verbs.id, front: 'gada');
  return (words: words.id, verbs: verbs.id);
}

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(MxDeckPickerSheet), matching: finder);

Future<int> _cardsIn(LibraryEnv env, String deckId) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?',
              variables: [Variable<String>(deckId)],
            )
            .getSingle())
        .read<int>('n');

// UC-CARD-001 A5: once a target deck is picked, the sheet stays until the
// move lands (card_move_sheet_widget.dart, MxBottomSheet.isHeld).
void main() {
  libraryTest('while the move writes, the sheet is held: the scrim and Back '
      'leave it open, Cancel and the targets are off; it closes when the '
      'cards have moved', (tester, env) async {
    final ids = await _seed(env);
    final gate = Completer<void>();
    final actions = _SlowMove(gate);
    await pumpLibraryScreen(
      tester,
      env,
      _section(ids.words),
      overrides: [cardActionsControllerProvider.overrideWith(() => actions)],
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('gamsa'));
    await tester.pump();
    await tester.tap(find.text(_en.cardMove));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      isFalse,
    );

    await tester.tap(_inSheet(find.text('Korean › Verbs')));
    await tester.pump(_frames);

    expect(actions.moves, 1);
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      isTrue,
    );
    final cancel = _inSheet(find.widgetWithText(MxButton, _en.commonCancel));
    expect(tester.widget<MxButton>(cancel).onPressed, isNull);
    final rows = tester.widgetList<MxListRow>(_inSheet(find.byType(MxListRow)));
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row.isEnabled, isFalse);
    }

    expect(
      tester.getTopLeft(find.byType(MxBottomSheet)).dy,
      greaterThan(_scrim.dy),
      reason: 'the tap lands on the scrim',
    );
    await tester.tapAt(_scrim);
    await tester.pump(_frames);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(_frames);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);

    unawaited(
      Navigator.of(tester.element(find.byType(MxBottomSheet))).maybePop(),
    );
    await tester.pump(_frames);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);

    // A second press of the same target does not move again.
    await tester.tap(
      _inSheet(find.text('Korean › Verbs')),
      warnIfMissed: false,
    );
    await tester.pump(_frames);
    expect(actions.moves, 1);
    expect(await _cardsIn(env, ids.verbs), 1);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(actions.moves, 1);
    expect(find.text(_en.cardMovedToast(2, 'Verbs')), findsOneWidget);
    expect(await _cardsIn(env, ids.verbs), 3);
  });
}

/// Moves only once [gate] opens, so a test can look while it writes.
final class _SlowMove extends CardActionsController {
  _SlowMove(this.gate);

  final Completer<void> gate;
  var moves = 0;

  @override
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
  }) async {
    moves++;
    // Read before the wait, as the real call does: nothing keeps this
    // controller alive across it.
    final move = ref.read(moveCardsUseCaseProvider);
    await gate.future;
    return move(cardIds: cardIds, targetDeckId: targetDeckId);
  }
}
