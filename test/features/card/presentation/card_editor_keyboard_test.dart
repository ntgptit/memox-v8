import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// Audit P1: the editor gives the keyboard the room its header took.

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

void main() {
  libraryTest('the deck path steps aside while typing and comes back after '
      '(audit P1)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final deckId = (await env.decks.sub(korean.id, 'Words')).id;
    await pumpLibraryScreen(
      tester,
      env,
      CardEditorScreen.create(deckId: deckId, deckContext: _context),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxBreadcrumb), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });
}
