import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';

import '../../../support/forui_expect.dart' show byControlLabel;
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import 'support/study_screen_helpers.dart';

// Screen 19, Recall (UC-STUDY-007): BR-STUDY-031 to BR-STUDY-036, BR-STUDY-063,
// BR-STUDY-065, BR-STUDY-066; spec D5, D12; FE-A6 P4 rulings R1–R3, V2–V5.
// A Recall screen is never pumped with pumpAndSettle: its clock would run
// out.

final _en = lookupAppLocalizations(const Locale('en'));

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

Future<void> _lifecycle(
  WidgetTester tester,
  List<AppLifecycleState> states,
) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await pumpThreeFrames(tester);
}

// footerHintIcon reads the footer hint's glyph (critique 2026-10-02, F7).

void main() {
  libraryTest('the term shows, the meaning is hidden, and the clock counts '
      'down from 20 (19 countingDown)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

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
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await pumpThreeFrames(tester);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text(_en.studyRecallCaptionRevealed), findsOneWidget);
    expect(find.textContaining(_en.studyRecallHintRevealed), findsOneWidget);
    expect(await _rowOf(env.db, id), (15000, true));

    // No timeout after a reveal.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('15s / 20s'), findsOneWidget);

    await tester.tap(find.text(_en.studyRecallRemembered));
    await pumpThreeFrames(tester);
    expect(find.text('term 2'), findsOneWidget);
    expect(await _logOf(env.db), ('remembered', null));
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the reveal is announced: the focused button goes, the meaning '
      'is read (TalkBack)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await pumpThreeFrames(tester);

    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyRecallAnnounceRevealed('apple')),
    );
    handle.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the clock stops while the exit dialog asks, and Keep going '
      'takes it up where it stopped (BR-STUDY-036)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(byControlLabel(_en.studySessionClose));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_en.studyExitTitle), findsOneWidget);
    // Longer than the turn: without the pause it would time out behind the
    // dialog.
    await tester.pump(const Duration(seconds: 30));
    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(_en.studyRecallCaptionTimedOut), findsNothing);
    expect(find.text('15s / 20s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('12s / 20s'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('Forgot records a wrong answer and moves on', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await pumpThreeFrames(tester);
    expect(footerHintIcon(tester), AppIcons.info);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyRecallForgot));
    await pumpThreeFrames(tester);

    expect(find.text('term 2'), findsOneWidget);
    expect(await _logOf(env.db), ('forgotten', null));
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('at zero the turn counts as forgot, is announced, and waits for '
      'Continue (R2, BR-STUDY-033, BR-STUDY-066)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    expect(footerHintIcon(tester), AppIcons.info);

    await tester.pump(const Duration(seconds: 20));
    // The clock ends on the first frame past its 20 s.
    await tester.pump(const Duration(milliseconds: 16));
    await pumpThreeFrames(tester);
    expect(find.text(_en.studyRecallCaptionTimedOut), findsOneWidget);
    expect(find.text(_en.studyRecallTagTimedOut.toUpperCase()), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.textContaining(_en.studyRecallHintTimedOut), findsOneWidget);
    expect(footerHintIcon(tester), AppIcons.repeat);
    expect(await _logOf(env.db), ('forgotten', 'timeout'));
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyRecallAnnounceTimedOut('apple')),
    );

    // Held until Continue (spec D5).
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('term 1'), findsOneWidget);
    await tester.tap(find.text(_en.studyContinue));
    await pumpThreeFrames(tester);
    expect(find.text('term 2'), findsOneWidget);
    handle.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the clock stops in the background and saves its time; it '
      'resumes where it stopped (D12, BR-STUDY-036)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
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
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

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
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
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
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.pump(const Duration(seconds: 3));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(await _rowOf(env.db, id), (17000, false));
  });

  libraryTest('the top bar is Indigo, as in every mode (critique 2026-09-30 '
      'part 3c-2, R8)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expectIndigoTopBar(tester, StudyMode.recall);
  });

  libraryTest('the self-check labels show whole at normal size (Impeccable '
      'after P4)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await pumpThreeFrames(tester);

    for (final label in [_en.studyRecallForgot, _en.studyRecallRemembered]) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
        reason: label,
      );
    }
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a double tap on Show the meaning answers nothing: Forgot and '
      'Remembered settle first (critique 2026-09-30 part 3c-2, R1)', (
    tester,
    env,
  ) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await pumpThreeFrames(tester);
    await tester.tap(find.text(_en.studyRecallRemembered), warnIfMissed: false);
    await pumpThreeFrames(tester);

    expect(
      await env.db.customSelect('SELECT id FROM review_log').get(),
      isEmpty,
    );
    expect(find.text('apple'), findsOneWidget);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyRecallRemembered));
    await pumpThreeFrames(tester);
    expect(find.text('term 2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a tap in the instant the clock runs out does not skip the '
      'timed-out turn (Review Focus 2)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await tester.pump(const Duration(seconds: 21));
    await pumpThreeFrames(tester);
    await tester.tap(find.text(_en.studyContinue), warnIfMissed: false);
    await pumpThreeFrames(tester);

    expect(find.text(_en.studyRecallCaptionTimedOut), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
  });
}
