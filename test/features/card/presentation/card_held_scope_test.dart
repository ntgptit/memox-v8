import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Card writes that land, counted: a second one would write twice.
final class _CountedCardActions extends CardActionsController {
  final writes = <String>[];

  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
  }) {
    writes.add('create');
    return super.createCard(deckId: deckId, draft: draft);
  }

  @override
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
  }) {
    writes.add('move');
    return super.moveCards(cardIds: cardIds, targetDeckId: targetDeckId);
  }

  @override
  Future<Outcome<void, TagRejection>> addTag({
    required Set<String> cardIds,
    required String tagName,
  }) {
    writes.add('tag');
    return super.addTag(cardIds: cardIds, tagName: tagName);
  }

  @override
  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
  }) {
    writes.add('delete');
    return super.deleteCards(cardIds: cardIds);
  }
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

/// Picks the one card and opens its bulk command [label], with every toast
/// throwing (no toast host).
Future<_CountedCardActions> _bulk(
  WidgetTester tester,
  LibraryEnv env,
  String label,
) async {
  final words = await _seedWords(env);
  final actions = _CountedCardActions();
  await pumpLibraryScreen(
    tester,
    env,
    _section(words),
    overrides: [cardActionsControllerProvider.overrideWith(() => actions)],
    hasToastHost: false,
  );
  await tester.longPress(find.text('annyeong'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  return actions;
}

/// Taps [finder]: the toast after the write meets its bug, which is left
/// uncaught as itself, and no failure is said.
Future<void> _confirm(WidgetTester tester, Finder finder) async {
  final uncaught = await tapKeepingUncaught(tester, finder);
  expect(uncaught, [isA<FlutterError>()]);
  expect(find.text(_en.failureUnknown), findsNothing);
}

// REG-HELD-SCOPE: a bug in what follows a landed write (here the toast,
// which throws with no toast host) is not a failed write. The flow closes
// as after any landed write and never offers Retry, so nothing writes
// twice.
void main() {
  libraryTest('a move that landed closes its sheet though its toast fails '
      '(UC-CARD-001 A5)', (tester, env) async {
    final actions = await _bulk(tester, env, _en.cardMove);
    await _confirm(
      tester,
      find.descendant(
        of: find.byType(MxDeckPickerSheet),
        matching: find.text('Korean › Verbs'),
      ),
    );

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(actions.writes, ['move']);
  });

  libraryTest('a tag that landed closes its dialog though its toast fails '
      '(UC-CARD-001 A8)', (tester, env) async {
    final actions = await _bulk(tester, env, _en.cardTag);
    await tester.enterText(find.byType(EditableText), 'greetings');
    await _confirm(
      tester,
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.cardTagConfirm),
      ),
    );

    expect(find.byType(MxDialog), findsNothing);
    expect(actions.writes, ['tag']);
  });

  libraryTest('a delete that landed closes its dialog though its toast fails '
      '(FE-B1)', (tester, env) async {
    final actions = await _bulk(tester, env, _en.cardDelete);
    await _confirm(
      tester,
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.trashMoveConfirm),
      ),
    );

    expect(find.byType(MxDialog), findsNothing);
    expect(actions.writes, ['delete']);
  });

  libraryTest('a new card that landed clears the form for the next and '
      'offers no Retry though its toast fails (UC-CARD-001 A4)', (
    tester,
    env,
  ) async {
    final words = await _seedWords(env);
    final actions = _CountedCardActions();
    await pumpLibraryScreen(
      tester,
      env,
      CardEditorScreen.create(
        deckId: words,
        deckContext: (deckId, label) =>
            DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
      ),
      overrides: [cardActionsControllerProvider.overrideWith(() => actions)],
      hasToastHost: false,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'bap');
    await tester.enterText(find.byType(EditableText).at(1), 'rice');
    await tester.pump();
    await _confirm(tester, find.widgetWithText(MxButton, _en.cardSaveCard));

    expect(find.text(_en.cardSaveFailedTitle), findsNothing);
    expect(find.widgetWithText(MxButton, _en.cardRetrySave), findsNothing);
    expect(find.text('bap'), findsNothing);
    expect(actions.writes, ['create']);
  });
}
