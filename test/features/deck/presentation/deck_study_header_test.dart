import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the title names the deck; the breadcrumb runs from the '
      'Library to the deck (FE-A6 D16)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final lesson = await env.decks.sub(korean.id, 'Lesson');
    await pumpLibraryScreen(
      tester,
      env,
      // The breadcrumb's ink needs a Material, as the screen's shell gives.
      Material(
        child: Column(
          children: [
            DeckStudyHeaderWidget(
              deckId: lesson.id,
              part: DeckStudyHeaderPart.title,
            ),
            DeckStudyHeaderWidget(
              deckId: lesson.id,
              part: DeckStudyHeaderPart.breadcrumb,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Lesson'), findsNWidgets(2));
    expect(find.text(_en.navLibrary), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);
  });

  libraryTest('a deck that is gone draws nothing: the entry says so', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Material(
        child: DeckStudyHeaderWidget(
          deckId: 'missing',
          part: DeckStudyHeaderPart.breadcrumb,
        ),
      ),
    );

    expect(find.text(_en.navLibrary), findsNothing);
  });
}
