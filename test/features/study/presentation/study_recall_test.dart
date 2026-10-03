import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// Screen 19, Recall: BR-STUDY-031 to BR-STUDY-036, BR-STUDY-063,
// BR-STUDY-065, BR-STUDY-066; spec D5, D12; FE-A6 P4 rulings R1–R3, V2–V5.
// A Recall screen is never pumped with pumpAndSettle: its clock would run
// out.

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// ST-01 ("term 1", meaning "apple") is served first.
Future<String> _recall(LibraryEnv env) =>
    openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);

/// The served ST-01 row's stored time left and reveal flag.
Future<(int?, bool)> _rowOf(AppDatabase db, String id) async {
  final row = await db
      .customSelect(
        "SELECT remaining_ms, is_revealed FROM study_queue_items "
        "WHERE session_id = ? AND card_id = 'ST-01'",
        variables: [Variable.withString(id)],
      )
      .getSingle();
  return (row.read<int?>('remaining_ms'), row.read<int>('is_revealed') == 1);
}

/// ST-01's logged action and reason, once answered.
Future<(String, String?)> _logOf(AppDatabase db) async {
  final row = await db
      .customSelect(
        "SELECT action, outcome_reason FROM review_log WHERE card_id = 'ST-01'",
      )
      .getSingle();
  return (row.read<String>('action'), row.read<String?>('outcome_reason'));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _lifecycle(
  WidgetTester tester,
  List<AppLifecycleState> states,
) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await _settle(tester);
}

/// The footer hint's glyph (critique 2026-10-02, F7).
IconData _hintIcon(WidgetTester tester) => tester
    .widget<SessionFooterHintWidget>(find.byType(SessionFooterHintWidget))
    .icon;

/// Records the haptic kinds the platform channel receives (audit Platform).
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  libraryTest('the term shows, the meaning is hidden, and the clock counts '
      'down from 20 (19 countingDown)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('apple'), findsNothing);
    expect(find.text('20s / 20s'), findsOneWidget);
    expect(find.text(_en.studyRecallCaptionCounting), findsOneWidget);
    expect(find.textContaining(_en.studyRecallHintCounting), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(find.text('14s / 20s'), findsOneWidget);
  });

  libraryTest('Show the meaning reveals with the time left and stops the '
      'clock; Remembered moves on at once (R2, BR-STUDY-065)', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text(_en.studyRecallCaptionRevealed), findsOneWidget);
    expect(find.textContaining(_en.studyRecallHintRevealed), findsOneWidget);
    expect(await _rowOf(env.db, id), (15000, true));

    // No timeout after a reveal.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('15s / 20s'), findsOneWidget);

    await tester.tap(find.text(_en.studyRecallRemembered));
    await _settle(tester);
    expect(find.text('term 2'), findsOneWidget);
    expect(await _logOf(env.db), ('remembered', null));
  });

  libraryTest('Forgot records a wrong answer and moves on', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);
    expect(_hintIcon(tester), AppIcons.info);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyRecallForgot));
    await _settle(tester);

    expect(find.text('term 2'), findsOneWidget);
    expect(await _logOf(env.db), ('forgotten', null));
  });

  libraryTest('at zero the turn counts as forgot, is announced, and waits for '
      'Continue (R2, BR-STUDY-033, BR-STUDY-066)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    expect(_hintIcon(tester), AppIcons.info);

    await tester.pump(const Duration(seconds: 20));
    // The clock ends on the first frame past its 20 s.
    await tester.pump(const Duration(milliseconds: 16));
    await _settle(tester);
    expect(find.text(_en.studyRecallCaptionTimedOut), findsOneWidget);
    expect(find.text(_en.studyRecallTagTimedOut.toUpperCase()), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.textContaining(_en.studyRecallHintTimedOut), findsOneWidget);
    expect(_hintIcon(tester), AppIcons.repeat);
    expect(await _logOf(env.db), ('forgotten', 'timeout'));
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyRecallAnnounceTimedOut('apple')),
    );

    // Held until Continue (spec D5).
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('term 1'), findsOneWidget);
    await tester.tap(find.text(_en.studyContinue));
    await _settle(tester);
    expect(find.text('term 2'), findsOneWidget);
    handle.dispose();
  });

  libraryTest('the clock stops in the background and saves its time; it '
      'resumes where it stopped (D12, BR-STUDY-036)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 4));

    await _lifecycle(tester, const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    expect(await _rowOf(env.db, id), (16000, false));

    await tester.pump(const Duration(seconds: 60));
    await _lifecycle(tester, const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('15s / 20s'), findsOneWidget);
  });

  libraryTest('a turn resumed with saved time starts from it (BR-STUDY-036)', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await env.db.customStatement(
      "UPDATE study_queue_items SET remaining_ms = 7000 "
      "WHERE card_id = 'ST-01'",
    );
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('7s / 20s'), findsOneWidget);
  });

  libraryTest('a turn resumed after a reveal opens revealed, its clock '
      'stopped, and asks Forgot or Remembered (BR-STUDY-036)', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await env.db.customStatement(
      "UPDATE study_queue_items SET remaining_ms = 9000, is_revealed = 1 "
      "WHERE card_id = 'ST-01'",
    );
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 30));

    expect(find.text('9s / 20s'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text(_en.studyRecallForgot), findsOneWidget);
    expect(find.text(_en.studyRecallRemembered), findsOneWidget);
    // Critique 2026-09-30: an honest grade; neither answer is the loud one.
    for (final label in [_en.studyRecallForgot, _en.studyRecallRemembered]) {
      expect(
        tester.widget<MxButton>(find.widgetWithText(MxButton, label)).tone,
        MxButtonTone.secondary,
        reason: label,
      );
    }
  });

  libraryTest('closing the screen mid-turn saves the time left (D12)', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 3));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(await _rowOf(env.db, id), (17000, false));
  });

  libraryTest('the top bar is Indigo, as in every mode (critique 2026-09-30 '
      'part 3c-2, R8)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final bar = find.byType(MxStudyTopBar);
    final fill = tester.widget<ColoredBox>(
      find.descendant(
        of: find.descendant(
          of: bar,
          matching: find.byType(FractionallySizedBox),
        ),
        matching: find.byType(ColoredBox),
      ),
    );
    final chip = find.descendant(
      of: bar,
      matching: find.text(_en.studyMode(StudyMode.recall).toUpperCase()),
    );

    expect(fill.color, AppColorSchemes.light.primary);
    expect(
      tester.widget<Text>(chip).style?.color,
      tester.element(chip).derivedColors.primaryInk,
    );
  });

  libraryTest('the self-check labels show whole at normal size (Impeccable '
      'after P4)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);

    for (final label in [_en.studyRecallForgot, _en.studyRecallRemembered]) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
        reason: label,
      );
    }
  });

  libraryTest('a double tap on Show the meaning answers nothing: Forgot and '
      'Remembered settle first (critique 2026-09-30 part 3c-2, R1)', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);
    await tester.tap(find.text(_en.studyRecallRemembered), warnIfMissed: false);
    await _settle(tester);

    expect(
      await env.db.customSelect('SELECT id FROM review_log').get(),
      isEmpty,
    );
    expect(find.text('apple'), findsOneWidget);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyRecallRemembered));
    await _settle(tester);
    expect(find.text('term 2'), findsOneWidget);
  });

  libraryTest('a tap in the instant the clock runs out does not skip the '
      'timed-out turn (Review Focus 2)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.pump(const Duration(seconds: 21));
    await _settle(tester);
    await tester.tap(find.text(_en.studyContinue), warnIfMissed: false);
    await _settle(tester);

    expect(find.text(_en.studyRecallCaptionTimedOut), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
  });

  libraryTest('a grade gives a light tick (audit Platform)', (
    tester,
    env,
  ) async {
    final haptics = _recordHaptics(tester);
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);
    // The settle guard takes no tap until the row has settled.
    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyRecallRemembered));
    await _settle(tester);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  libraryTest('the clock stops under the exit dialog and runs on when it '
      'closes: the turn never times out unseen (2.11)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('15s / 20s'), findsOneWidget);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_en.studyExitTitle), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('15s / 20s'), findsOneWidget);
    // The time left was kept when the clock stopped.
    expect(await _rowOf(env.db, id), (15000, false));

    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('14s / 20s'), findsOneWidget);
  });

  libraryTest('a resume from the background does not restart the clock '
      'while the exit dialog is open (2.11)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _lifecycle(tester, const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('15s / 20s'), findsOneWidget);
  });

  libraryTest('a reveal that fails says so in the banner; the next tap '
      'works and clears it (2.12)', (tester, env) async {
    final id = await _recall(env);
    env.sessions.isRevealFailing = true;
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);
    // The failure lands after the write starts (the fixture's timer).
    await tester.pump(const Duration(milliseconds: 1));
    await _settle(tester);

    expect(find.text(_en.studyRevealFailedTitle), findsOneWidget);
    expect(find.text(_en.studyRevealFailedBody), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(find.text('apple'), findsNothing);

    env.sessions.isRevealFailing = false;
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);

    expect(find.text(_en.studyRevealFailedTitle), findsNothing);
    expect(find.text('apple'), findsOneWidget);
  });
}
