import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_guess_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import 'support/study_screen_helpers.dart';

// Screen 18, Guess (UC-STUDY-006): BR-STUDY-037, BR-STUDY-040, BR-STUDY-041,
// BR-STUDY-042, BR-STUDY-063; FE-A6 P3 rulings G1–G3, C1–C4, C6.

final _en = lookupAppLocalizations(const Locale('en'));

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

/// [body] over a guess session whose meaning source is one short of filling
/// the options, so its first question is blocked (BR-STUDY-040).
Future<void> _withBlockedGuess(
  WidgetTester tester,
  Future<void> Function(LibraryEnv env, String id) body,
) async {
  final env = LibraryEnv(
    openTestDatabase(interceptor: ThinMeaningSource(4)),
    FakeDayClock(libraryToday),
  );
  try {
    await body(env, await _guess(env));
  } finally {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await env.db.close();
  }
}

void main() {
  libraryTest('the term is asked under "What is this?" with five lettered '
      'options (BR-STUDY-037)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expect(find.text(_en.studyGuessPrompt.toUpperCase()), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
    expect(footerHintIcon(tester), AppIcons.info);
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
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
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
    expect(find.textContaining(_en.studyGuessHintAnswered), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('term 2'), findsOneWidget);
    handle.dispose();
  });

  libraryTest('a wrong pick marks it wrong and the right one correct, fades '
      'the rest, and a tap continues early (G1, C1, C3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    final right = _letterOf(tester, 'apple');
    final wrong = _letterOf(tester, 'banana');

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.pump();
    expect(footerHintIcon(tester), AppIcons.info);

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
    expect(cherry.opacity, const AppDimens().opacityMuted);
    expect(tester.takeAnnouncements().map((a) => a.message), [
      _en.studyGuessAnnounceWrong('apple'),
    ]);

    await tester.tap(find.text('term 1'));
    await tester.pumpAndSettle();

    expect(find.text('term 2'), findsOneWidget);
    handle.dispose();
  });

  libraryTest('an answer a busy database kept stays the first pick: the '
      'options wait for Retry, which saves it (BR-STUDY-041 first pick; '
      'audit 2026-10-17)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _guess(env);
    env.sessions.isLocked = true;
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    final other = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((node) => node.properties.label)
        .whereType<String>()
        .firstWhere(
          (label) => label.startsWith('Option ') && !label.endsWith(': apple'),
        )
        .split(': ')
        .last;

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(_en.studyAnswerBusyTitle), findsOneWidget);
    await tester.tap(find.text(other), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.takeAnnouncements();

    env.sessions.isLocked = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyGuessAnnounceRight),
    );
    handle.dispose();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  libraryTest('a second tap while the turn is held writes nothing '
      '(BR-STUDY-042)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

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
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('term 1'), findsOneWidget);
    await tester.tap(find.text(_en.studyGuessNext));
    await tester.pumpAndSettle();

    expect(find.text('term 2'), findsOneWidget);
  });

  libraryTest('nothing overflows and each option is '
      'at least 48 tall (C4)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expect(tester.takeException(), isNull);
    final row = find.ancestor(
      of: find.text('apple'),
      matching: find.byType(GestureDetector),
    );
    expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
  });

  libraryTest('at normal size no fade is drawn', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('a blocked question shows the notice, and Close ends the '
      'session (BR-STUDY-040, G3, C2)', (tester) async {
    await _withBlockedGuess(tester, (env, id) async {
      await pumpLibraryScreen(tester, env, studySessionScreen(id));

      expect(find.text(_en.studyGuessBlockedTitle), findsOneWidget);
      // M3-D6: Close is the error state's own action.
      expect(
        find.descendant(
          of: find.byType(MxErrorState),
          matching: find.widgetWithText(MxButton, _en.studySessionClose),
        ),
        findsOneWidget,
      );
      expect(find.text('apple'), findsNothing);
      // Close ends the session; it is not a retry.
      expect(find.byIcon(AppIcons.retry), findsNothing);
      // Critique 2026-09-30 part 3c-2, R5: centred, and Close has no glyph.
      final body = tester.getRect(find.byType(StudyGuessWidget));
      expect(
        tester.getCenter(find.byType(MxErrorState)).dy,
        closeTo(body.center.dy - const AppDimens().space24 / 2, 1),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(MxButton, _en.studySessionClose),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );

      await tester.tap(find.text(_en.studySessionClose));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.studyExitStop));
      await tester.pumpAndSettle();

      expect(
        (await sessionOf(env.db, id)).read<String>('end_reason'),
        'user_exit',
      );
    });
  });

  for (final (locale, name) in [
    (
      const Locale('en'),
      'the context line names the round, not the first-pick '
          'rule, which the footer states (critique 2026-09-30 part 3c-2, R9)',
    ),
    (
      const Locale('vi'),
      'the context line names the round in Vietnamese too (R9)',
    ),
  ]) {
    libraryTest(name, (tester, env) async {
      final handle = tester.ensureSemantics();
      final l10n = lookupAppLocalizations(locale);
      final id = await _guess(env);
      await pumpLibraryScreen(
        tester,
        env,
        studySessionScreen(id),
        locale: locale,
      );
      final round = l10n.studyContextRound(
        l10n.studyContextReview('Lesson', l10n.studyKindReview),
        1,
      );

      expect(find.bySemanticsLabel(round), findsOneWidget);
      expect(find.textContaining(l10n.studyGuessHintIdle), findsOneWidget);
      handle.dispose();
    });
  }

  testWidgets('at text scale 2 the blocked notice scrolls from the top and '
      'nothing overflows (Review Focus 5)', (tester) async {
    await _withBlockedGuess(tester, (env, id) async {
      await pumpLibraryScreen(
        tester,
        env,
        studySessionScreen(id),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.ancestor(
          of: find.byType(MxErrorState),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
    });
  });
}
