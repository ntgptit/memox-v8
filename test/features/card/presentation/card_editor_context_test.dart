import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// The deck context header of the card editor: the path to the deck and the
// operation, named once.
void main() {
  libraryTest('the deck context names the path once, ending in the deck and '
      'the operation (critique 2026-09-30)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: DeckContextHeaderWidget(
          deckId: words.id,
          currentLabel: _en.cardAddTitle,
        ),
      ),
    );

    for (final crumb in [_en.navLibrary, 'Korean', 'Words', _en.cardAddTitle]) {
      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.text(crumb),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Words'), findsOneWidget);
  });

  libraryTest('the deck context holds its place while the deck loads', (
    tester,
    env,
  ) async {
    final pending = StreamController<Outcome<DeckView, DeckRejection>>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: DeckContextHeaderWidget(
          deckId: 'words',
          currentLabel: _en.cardAddTitle,
        ),
      ),
      overrides: [
        deckViewProvider('words').overrideWith((ref) => pending.stream),
      ],
    );

    expect(find.byType(MxSkeleton), findsWidgets);
    expect(find.byType(MxBreadcrumb), findsNothing);
  });
}
