import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the deck action sheet opens the Study entry, and the tab bar '
      'stays (spec D1, D10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await env.decks.sub(root.id, 'Lesson');
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(_en.deckActions));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(MxActionSheetCommandRow, _en.deckStudy),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest("the card list summary's Study this deck opens the entry "
      '(spec D10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final words = await env.decks.sub(root.id, 'Words');
    await insertCard(env.db, id: 'c1', deckId: words.id);
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Words'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.cardStudyThisDeck));
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
  });

  libraryTest('the session route covers the tab bar (spec D2)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c1', deckId: root.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: root.id,
      rootId: root.id,
      startedAt: libraryToday,
    );
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c1',
      position: 0,
    );
    await pumpMemoxApp(tester, env);

    GoRouter.of(tester.element(find.byType(MxBottomNav)))
        .push<void>(AppRoutes.studySession('s'));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
  });
}
