import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';
import 'study_session_screen_harness.dart';

// The session route's screen when its exit or its deck is lost: UC-STUDY-001
// E2, E4 and the summary kept over a lost deck (2.51).

/// A session stopped to its summary, then its deck sent to the Trash: the
/// summary is on screen when the deck is lost (2.51).
Future<void> _summaryOverLostDeck(
  WidgetTester tester,
  LibraryEnv env,
  String id, {
  required ValueChanged<String> onDone,
  required ValueChanged<String?> onLeave,
}) async {
  await pumpSessionScreen(tester, env, id, onDone: onDone, onLeave: onLeave);
  await swipeLeft(tester);
  await tester.tap(find.byTooltip(studyEn.studySessionClose));
  await tester.pumpAndSettle();
  await tester.tap(find.text(studyEn.studyExitStop));
  await tester.pumpAndSettle();
  expect(find.text(studyEn.summaryLeftEarly), findsOneWidget);
  expect(find.widgetWithText(MxButton, studyEn.studyThisDeck), findsOneWidget);

  final session = await sessionOf(env.db, id);
  await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('a deck lost while the exit dialog is open leaves when the '
      'dialog closes, once, with a message (2.07)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    final left = <String?>[];
    await pumpSessionScreen(tester, env, id, onLeave: left.add);

    await tester.tap(find.byTooltip(studyEn.studySessionClose));
    await tester.pumpAndSettle();
    final session = await sessionOf(env.db, id);
    await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
    await tester.pumpAndSettle();
    // The dialog is a route over this one: the leave waits for it.
    expect(find.text(studyEn.studyExitTitle), findsOneWidget);
    expect(left, isEmpty);

    await tester.tap(find.text(studyEn.studyExitKeep));
    await tester.pumpAndSettle();

    expect(left, [null]);
    expect(find.text(studyEn.studyEntryDeckGone), findsOneWidget);
  });

  libraryTest('a Stop confirmed after the deck was lost leaves and writes no '
      'abandon (2.07)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    // An abandon that was written would fail and show the Stop toast.
    env.sessions.isAbandonFailing = true;
    final left = <String?>[];
    await pumpSessionScreen(tester, env, id, onLeave: left.add);

    await tester.tap(find.byTooltip(studyEn.studySessionClose));
    await tester.pumpAndSettle();
    final session = await sessionOf(env.db, id);
    await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(studyEn.studyExitStop));
    await tester.pumpAndSettle();

    expect(left, [null]);
    expect(find.text(studyEn.studyStopFailed), findsNothing);
  });

  libraryTest('a Stop that fails says so in a toast and the session stays '
      'open (2.08)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    env.sessions.isAbandonFailing = true;
    await pumpSessionScreen(tester, env, id);

    await tester.tap(find.byTooltip(studyEn.studySessionClose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(studyEn.studyExitStop));
    await tester.pumpAndSettle();

    expect(find.text(studyEn.studyStopFailed), findsOneWidget);
    expect((await sessionOf(env.db, id)).read<String>('status'), 'in_progress');
    expect(find.byType(MxStudyTopBar), findsOneWidget);
  });

  libraryTest('✕ twice opens one exit dialog, never two (2.08)', (
    tester,
    env,
  ) async {
    final id = await seedSession(env, ['a', 'b']);
    await pumpSessionScreen(tester, env, id);
    final close = find.byTooltip(studyEn.studySessionClose);

    await tester.tap(close);
    await tester.tap(close, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(studyEn.studyExitTitle), findsOneWidget);

    await tester.tap(find.text(studyEn.studyExitKeep));
    await tester.pumpAndSettle();
    // A second dialog would still be there under the first.
    expect(find.text(studyEn.studyExitTitle), findsNothing);
  });

  libraryTest('a summary on screen stays when its deck is lost: Study this '
      'deck goes, Done still leaves for the Library (2.51)', (
    tester,
    env,
  ) async {
    final id = await seedSession(env, ['a', 'b']);
    final left = <String?>[];
    final done = <String>[];
    await _summaryOverLostDeck(
      tester,
      env,
      id,
      onDone: done.add,
      onLeave: left.add,
    );

    expect(find.text(studyEn.summaryLeftEarly), findsOneWidget);
    expect(find.widgetWithText(MxButton, studyEn.studyThisDeck), findsNothing);
    expect(find.text(studyEn.studyEntryDeckGone), findsNothing);
    expect(left, isEmpty);

    await tester.tap(find.widgetWithText(MxButton, studyEn.summaryDone));
    await tester.pumpAndSettle();
    expect(left, [null]);
    expect(done, isEmpty);
  });

  libraryTest('system Back on a summary kept over a lost deck is Done '
      '(2.51)', (tester, env) async {
    final id = await seedSession(env, ['a', 'b']);
    final left = <String?>[];
    await _summaryOverLostDeck(
      tester,
      env,
      id,
      onDone: (_) {},
      onLeave: left.add,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(studyEn.studyExitTitle), findsNothing);
    expect(left, [null]);
  });
}
