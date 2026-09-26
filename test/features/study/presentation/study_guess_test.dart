import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Screen 18, Guess: BR-STUDY-037, BR-STUDY-040, BR-STUDY-041,
// BR-STUDY-042, BR-STUDY-063; FE-A6 P3 rulings G1–G3, C1–C4, C6.

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// ST-01 is served first; its meaning is "apple".
Future<String> _guess(LibraryEnv env) =>
    openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.guess);

String _option(String letter, String meaning) =>
    _en.studyGuessOption(letter, meaning);

/// The letter the option [meaning] was drawn under.
String _letterOf(WidgetTester tester, String meaning) {
  final label = tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((node) => node.properties.label)
      .whereType<String>()
      .firstWhere((label) => label.endsWith(': $meaning'));
  return label.substring('Option '.length, 'Option '.length + 1);
}

void main() {
  libraryTest('the term is asked under "What is this?" with five lettered '
      'options (BR-STUDY-037)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text(_en.studyGuessPrompt.toUpperCase()), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
    for (final letter in ['A', 'B', 'C', 'D', 'E']) {
      expect(find.text(letter), findsOneWidget);
    }
    for (final meaning in ['apple', 'banana', 'cherry', 'date', 'elder']) {
      expect(find.text(meaning), findsOneWidget);
    }
  });

  libraryTest('the right pick shows as correct, is announced, and the next '
      'question follows after 1.2 s (G1, G2, C3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final letter = _letterOf(tester, 'apple');

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        _en.studyGuessOptionRight(_option(letter, 'apple')),
      ),
      findsOneWidget,
    );
    expect(tester.takeAnnouncements().map((a) => a.message), [
      _en.studyGuessAnnounceRight,
    ]);
    expect(find.text(_en.studyGuessHintAnswered), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('term 2'), findsOneWidget);
    handle.dispose();
  });

  libraryTest('a wrong pick marks it wrong and the right one correct, fades '
      'the rest, and a tap continues early (G1, C1, C3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final right = _letterOf(tester, 'apple');
    final wrong = _letterOf(tester, 'banana');

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        _en.studyGuessOptionWrong(_option(wrong, 'banana')),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(_en.studyGuessOptionRight(_option(right, 'apple'))),
      findsOneWidget,
    );
    final cherry = tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.text('cherry'),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(cherry.opacity, AppOpacity.disabled);
    expect(tester.takeAnnouncements().map((a) => a.message), [
      _en.studyGuessAnnounceWrong('apple'),
    ]);

    await tester.tap(find.text('term 1'));
    await tester.pumpAndSettle();

    expect(find.text('term 2'), findsOneWidget);
    handle.dispose();
  });

  libraryTest('a second tap while the turn is held writes nothing '
      '(BR-STUDY-042)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('cherry'));
    await tester.pump();

    expect(await turnKindsOf(env.db, 'ST-01'), hasLength(1));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
  });

  libraryTest('with TalkBack on nothing advances by itself; Next does (C6)', (
    tester,
    env,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('term 1'), findsOneWidget);
    await tester.tap(find.text(_en.studyGuessNext));
    await tester.pumpAndSettle();

    expect(find.text('term 2'), findsOneWidget);
  });

  libraryTest('at twice the text size nothing overflows and each option is '
      'at least 48 tall (C4)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id), textScale: 2);

    expect(tester.takeException(), isNull);
    final row = find.ancestor(
      of: find.text('apple'),
      matching: find.byType(GestureDetector),
    );
    expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
  });

  testWidgets('a blocked question shows the notice, and Close ends the '
      'session (BR-STUDY-040, G3, C2)', (tester) async {
    final env = LibraryEnv(
      openTestDatabase(interceptor: ThinMeaningSource(4)),
      FakeDayClock(libraryToday),
    );
    try {
      final id = await _guess(env);
      await pumpLibraryScreen(tester, env, _screen(id));

      expect(find.text(_en.studyGuessBlockedTitle), findsOneWidget);
      expect(find.text('apple'), findsNothing);

      await tester.tap(find.text(_en.studySessionClose));
      await tester.pumpAndSettle();

      expect(
        (await sessionOf(env.db, id)).read<String>('end_reason'),
        'user_exit',
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await env.db.close();
    }
  });

  libraryTest('the context line names the round and the first-pick rule '
      '(M3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(
      find.bySemanticsLabel(
        _en.studyContextFirstPick(
          _en.studyContextRound(
            _en.studyContextReview(
              'Lesson',
              _en.studyKindReview,
              _en.cardModeGuess,
            ),
            1,
          ),
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
