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

import '../../../support/forui_expect.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

import 'package:forui/forui.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showRenameDeckDialog(context, deck: deck),
    ),
  ),
);

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  libraryTest('rename starts from the current name and saves the new one', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);

    expect(find.text('Korean'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });

  libraryTest('while the name saves, the dialog is held, Cancel is off and '
      'the confirm spins (M3 B2: every async confirm)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final gate = Completer<void>();
    await pumpLibraryScreen(
      tester,
      env,
      _host(korean),
      overrides: [
        deckActionsControllerProvider.overrideWith(() => _SlowRename(gate)),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pump();

    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isTrue);
    MxButton button(String label) => tester.widget<MxButton>(
      find
          .ancestor(of: find.text(label), matching: find.byType(MxButton))
          .first,
    );
    expect(button(_en.commonCancel).onPressed, isNull);
    expect(button(_en.deckRenameConfirm).isLoading, isTrue);

    gate.complete();
    await tester.pumpAndSettle();
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });

  libraryTest('the name field paints its label once, above the box', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);

    expect(find.text(_en.deckNameHint), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text(_en.deckNameHint)).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(fieldBox(find.byType(FTextField))).dy,
      ),
    );
  });

  libraryTest('a blank name stays in the dialog, under the field', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);
    await tester.enterText(find.byType(EditableText), '   ');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
  });

  libraryTest('a deck gone meanwhile closes the dialog and says so (P2-L10)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);
    await env.decks.deleteDeck(deckId: korean.id);
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.deckRejectionNotFound), findsOneWidget);
  });
}

/// Renames only once [gate] opens, so a test can look while it writes.
final class _SlowRename extends DeckActionsController {
  _SlowRename(this.gate);

  final Completer<void> gate;

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
  }) async {
    // Read before the wait, as the real call does.
    final rename = ref.read(renameDeckUseCaseProvider);
    await gate.future;
    return rename(deckId: deckId, name: name);
  }
}
