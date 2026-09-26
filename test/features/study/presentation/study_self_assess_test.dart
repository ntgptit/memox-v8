import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';

// Screen 16a, Self-assess: BR-MODE-006, BR-MODE-011, BR-MODE-014,
// BR-STUDY-004, BR-STUDY-005; FE-A6 D11b.

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

Future<void> _reveal(WidgetTester tester) async {
  await tester.tap(find.text(_en.studySelfAssessShowAnswer));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('the prompt shows first, the answer waits for Show answer, and '
      'revealing writes nothing (IT-MODE-012, BR-MODE-006)', (
    tester,
    env,
  ) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('meaning 1'), findsNothing);
    expect(find.text(_en.cardActionGood), findsNothing);

    await _reveal(tester);

    expect(find.text('meaning 1'), findsOneWidget);
    expect(find.text('example 1'), findsOneWidget);
    expect(find.text(_en.studySelfAssessShowAnswer), findsNothing);
    expect(await turnKindsOf(env.db, 'R1'), isEmpty);
  });

  libraryTest('tapping the prompt card reveals, as Show answer does', (
    tester,
    env,
  ) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('term 1'));
    await tester.pumpAndSettle();

    expect(find.text('meaning 1'), findsOneWidget);
  });

  libraryTest('a scheduled turn shows each grade with its interval, and '
      'reads "Good, next in 6 days" (16a)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    await _reveal(tester);

    expect(find.text('1d'), findsOneWidget);
    expect(find.text('6d'), findsNWidgets(3));
    expect(
      find.bySemanticsLabel(
        _en.studyGradeNextIn(_en.cardActionGood, _en.studyIntervalDaysLong(6)),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  libraryTest('Good records one scheduled turn and the next card follows, '
      'unrevealed', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    await _reveal(tester);

    await tester.tap(find.text(_en.cardActionGood));
    await tester.pumpAndSettle();

    expect(await turnKindsOf(env.db, 'R1'), ['scheduled']);
    expect(find.text('term 2'), findsOneWidget);
    expect(find.text('meaning 2'), findsNothing);
  });

  libraryTest('a double tap on a grade records one turn (IT-MODE-012, '
      'BR-STUDY-004)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    await _reveal(tester);

    await tester.tap(find.text(_en.cardActionGood));
    await tester.tap(find.text(_en.cardActionGood), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await turnKindsOf(env.db, 'R1'), ['scheduled']);
  });

  libraryTest('after Again the card comes back as a relearning turn, with no '
      'interval and never "0d" (BR-STUDY-005, 16a)', (tester, env) async {
    final id = await openSelfAssessReview(
      env.db,
      env.decks,
      libraryToday,
      cards: 1,
    );
    await pumpLibraryScreen(tester, env, _screen(id));
    await _reveal(tester);
    await tester.tap(find.text(_en.cardActionAgain));
    await tester.pumpAndSettle();

    // The only card of the queue comes back at its end (BR-STUDY-005).
    expect(find.text('term 1'), findsOneWidget);
    await _reveal(tester);

    expect(find.text(_en.cardActionGood), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+(d|mo|y)$')), findsNothing);
  });

  libraryTest('a meaning-first card prompts with the meaning; the term and '
      'the example wait for the reveal (BR-MODE-014)', (tester, env) async {
    final id = await openSelfAssessReview(
      env.db,
      env.decks,
      libraryToday,
      cards: 1,
      direction: DirectionChoice.meaningToKorean,
    );
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('meaning 1'), findsOneWidget);
    expect(find.text('term 1'), findsNothing);
    expect(find.text('example 1'), findsNothing);

    await _reveal(tester);

    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('example 1'), findsOneWidget);
  });

  libraryTest('a review names its kind and mode in the context line (16a, '
      'plan R1)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(
      find.bySemanticsLabel(
        _en.studyContextReview(
          'Lesson',
          _en.studyKindReview,
          _en.cardModeSelfAssess,
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  libraryTest('at twice the text size the grades become a 2 × 2 grid, each '
      'at least 48 tall (16a)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id), textScale: 2);
    await _reveal(tester);

    final again = tester.getRect(
      find.widgetWithText(MxButton, _en.cardActionAgain),
    );
    final good = tester.getRect(
      find.widgetWithText(MxButton, _en.cardActionGood),
    );
    expect(good.top, greaterThan(again.bottom - 1));
    expect(again.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  libraryTest('at twice the text size a face label never covers the face '
      '(FE-A6 D19)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    const long = 'to eat and drink, or to share a meal with friends';
    await env.db.customStatement(
      "UPDATE card SET back = '$long' WHERE id = 'R1'",
    );
    await pumpLibraryScreen(tester, env, _screen(id), textScale: 2);
    await _reveal(tester);

    final term = find.text(_en.studyBrowseTerm.toUpperCase());
    final meaning = find.text(_en.studyBrowseMeaning.toUpperCase());
    expect(
      tester.getRect(term).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('term 1')).top),
    );
    expect(
      tester.getRect(meaning).bottom,
      lessThanOrEqualTo(tester.getRect(find.text(long)).top),
    );
  });

  libraryTest('with Remove animations on, the answer appears at once', (
    tester,
    env,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pump();

    expect(find.text('meaning 1'), findsOneWidget);
  });
}
