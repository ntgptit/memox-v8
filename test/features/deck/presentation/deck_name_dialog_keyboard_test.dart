import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/rename_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showRenameDeckDialog(context, deck: deck),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

// The Rename dialog's field declares the Done action (deck_name_dialog_widget
// .dart): the keyboard does what the Save button does, in every case.
void main() {
  libraryTest('the keyboard Done saves the new name and closes the dialog', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await _open(tester);

    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });

  libraryTest('the keyboard Done on a blank name stays in the dialog with the '
      'reason under the field, as Save does', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await _open(tester);

    await tester.enterText(find.byType(EditableText), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
    expect((await env.decks.findById(korean.id))!.name, 'Korean');
  });

  libraryTest('the keyboard Done on an emptied field stays in the dialog, as '
      'Save does', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await _open(tester);

    await tester.enterText(find.byType(EditableText), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
    expect((await env.decks.findById(korean.id))!.name, 'Korean');
  });

  libraryTest('the keyboard Done on the unchanged name closes the dialog and '
      'keeps the name, as Save does', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));

    await _open(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Korean');

    await _open(tester);
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Korean');
  });

  libraryTest('the keyboard Done while the name saves does not write twice, '
      'and the dialog is held until it lands', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final gate = Completer<void>();
    final controller = _CountingRename(gate);
    await pumpLibraryScreen(
      tester,
      env,
      _host(korean),
      overrides: [deckActionsControllerProvider.overrideWith(() => controller)],
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.renames, 1);
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isTrue);

    gate.complete();
    await tester.pumpAndSettle();

    expect(controller.renames, 1);
    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });
}

/// Counts the renames that reach the write, and holds each until [gate]
/// opens.
final class _CountingRename extends DeckActionsController {
  _CountingRename(this.gate);

  final Completer<void> gate;
  var renames = 0;

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
  }) async {
    renames++;
    // Read before the wait, as the real call does.
    final rename = ref.read(renameDeckUseCaseProvider);
    await gate.future;
    return rename(deckId: deckId, name: name);
  }
}
