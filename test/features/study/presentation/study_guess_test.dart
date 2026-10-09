import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_guess_widget.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Screen 18, Guess (UC-STUDY-006): BR-STUDY-037, BR-STUDY-040, BR-STUDY-041,
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

/// Tabs through the screen and checks that every choice's outside focus ring
/// lies inside the scroll viewport, the first and the last choice included
/// (task 14.3: the columns leave the ring its room).
Future<void> _expectRingsInViewport(WidgetTester tester) async {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  final choices = find.byType(StudyChoiceWidget);
  final viewport = tester.getRect(find.byType(CustomScrollView).first);
  final ringed = <Rect>{};
  final ring = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
  );
  for (var i = 0; i < 40; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (ring.evaluate().isEmpty) continue;
    final painter =
        tester.widget<CustomPaint>(ring).foregroundPainter!
            as MxFocusRingPainter;
    expect(painter.placement, MxFocusRingPlacement.outside);
    final rect = tester.getRect(ring);
    ringed.add(rect);
    // The stroke reaches the gap plus the stroke past the card.
    final painted = rect.inflate(StudyChoiceWidget.ringRoom);
    expect(painted.top, greaterThanOrEqualTo(viewport.top));
    expect(painted.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(painted.left, greaterThanOrEqualTo(viewport.left));
    expect(painted.right, lessThanOrEqualTo(viewport.right));
  }
  expect(ringed.length, choices.evaluate().length);
}

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

/// The footer hint's glyph (critique 2026-10-02, F7).
IconData _hintIcon(WidgetTester tester) => tester
    .widget<SessionFooterHintWidget>(find.byType(SessionFooterHintWidget))
    .icon;

void main() {
  libraryTest('every option\'s outside focus ring fits inside the scroll '
      'viewport, the last option included (task 14.3)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _expectRingsInViewport(tester);
  });

  libraryTest('the term is asked under "What is this?" with five lettered '
      'options (BR-STUDY-037)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text(_en.studyGuessPrompt.toUpperCase()), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
    expect(_hintIcon(tester), AppIcons.info);
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
    await pumpLibraryScreen(tester, env, _screen(id));
    final right = _letterOf(tester, 'apple');
    final wrong = _letterOf(tester, 'banana');

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.pump();
    expect(_hintIcon(tester), AppIcons.info);

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
    expect(cherry.opacity, AppOpacity.muted);
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

  libraryTest('nothing overflows and each option is '
      'at least 48 tall (C4)', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(tester.takeException(), isNull);
    final row = find.ancestor(
      of: find.text('apple'),
      matching: find.byType(GestureDetector),
    );
    expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
  });

  libraryTest('at normal size no fade is drawn', (tester, env) async {
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
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
        closeTo(body.center.dy - AppSpacing.section / 2, 1),
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
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await env.db.close();
    }
  });

  libraryTest('the context line names the round, not the first-pick rule, '
      'which the footer states (critique 2026-09-30 part 3c-2, R9)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final id = await _guess(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final round = _en.studyContextRound(
      _en.studyContextReview('Lesson', _en.studyKindReview),
      1,
    );

    expect(find.bySemanticsLabel(round), findsOneWidget);
    expect(find.textContaining(_en.studyGuessHintIdle), findsOneWidget);
    handle.dispose();
  });

  libraryTest('in Vietnamese too (R9)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final vi = lookupAppLocalizations(const Locale('vi'));
    final id = await _guess(env);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(id),
      locale: const Locale('vi'),
    );

    expect(
      find.bySemanticsLabel(
        vi.studyContextRound(
          vi.studyContextReview('Lesson', vi.studyKindReview),
          1,
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('at text scale 2 the blocked notice scrolls from the top and '
      'nothing overflows (Review Focus 5)', (tester) async {
    final env = LibraryEnv(
      openTestDatabase(interceptor: ThinMeaningSource(4)),
      FakeDayClock(libraryToday),
    );
    try {
      final id = await _guess(env);
      await pumpLibraryScreen(tester, env, _screen(id), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(
        find.ancestor(
          of: find.byType(MxErrorState),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await env.db.close();
    }
  });
}
