import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// Screen 20, Fill (UC-STUDY-008): BR-STUDY-026 to BR-STUDY-030, BR-STUDY-059,
// BR-STUDY-063, BR-STUDY-064; FE-A6 P4 rulings F1–F4, V1, V4, V6, V7, V10.

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// ST-01 ("term 1", meaning "apple", hint "hint 1") is served first.
Future<String> _fill(LibraryEnv env) =>
    openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.fill);

MxButton _button(WidgetTester tester, String label) => tester.widget<MxButton>(
  find.ancestor(of: find.text(label), matching: find.byType(MxButton)),
);

Future<int> _loggedTurns(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT id FROM review_log').get()).length;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  libraryTest('the meaning asks, the field takes the term, and Check waits '
      'for text; Done on nothing does nothing (20 input, F2, V7)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('apple'), findsOneWidget);
    expect(find.textContaining(_en.studyFillHintInput), findsOneWidget);
    expect(_button(tester, _en.studyFillCheck).onPressed, isNull);

    await _type(tester, '   ');
    expect(_button(tester, _en.studyFillCheck).onPressed, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(await _loggedTurns(env), 0);
    expect(find.text('apple'), findsOneWidget);
  });

  libraryTest('the field has focus when the turn opens (V7)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  libraryTest('a right answer moves on at once, with no feedback frame '
      '(F3, BR-STUDY-064; case and outer spaces ignored)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, ' Term 1 ');
    await tester.tap(find.text(_en.studyFillCheck));
    await _settle(tester);

    expect(find.text('banana'), findsOneWidget);
    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsNothing);
  });

  libraryTest('IME Done checks (F2)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, 'term 1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);

    expect(find.text('banana'), findsOneWidget);
  });

  libraryTest('a wrong answer is struck through beside the right term, '
      'announced, and waits for Continue (F3, V1, V10, BR-STUDY-059)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, 'term 9');
    await tester.tap(find.text(_en.studyFillCheck));
    await _settle(tester);

    final struck = tester.widget<Text>(find.text('term 9'));
    expect(struck.style!.decoration, TextDecoration.lineThrough);
    expect(find.text('term 1'), findsOneWidget);
    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
    expect(find.textContaining(_en.studyFillHintWrong), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyFillAnnounceWrong('term 1')),
    );

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyContinue));
    await _settle(tester);
    expect(find.text('banana'), findsOneWidget);
    handle.dispose();
  });

  libraryTest('accents count: "tèrm 1" does not match "term 1" '
      '(BR-STUDY-026)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, 'tèrm 1');
    await tester.tap(find.text(_en.studyFillCheck));
    await _settle(tester);

    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
  });

  libraryTest("Show hint shows the card's hint once and keeps what was typed "
      '(F4, BR-STUDY-028)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, 'ter');
    await tester.tap(find.text(_en.studyFillShowHint));
    await _settle(tester);

    expect(find.text('hint 1'), findsOneWidget);
    expect(find.text(_en.studyFillShowHint), findsNothing);
    expect(find.textContaining(_en.studyFillHintUsed), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ter',
    );
  });

  libraryTest('a card with no hint offers no Show hint (F4)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await env.db.customStatement(
      "UPDATE card SET hint = NULL WHERE id = 'ST-01'",
    );
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text(_en.studyFillShowHint), findsNothing);
    expect(find.text(_en.studyFillCheck), findsOneWidget);
  });

  libraryTest('the top bar is Indigo, as in every mode (critique 2026-09-30 '
      'part 3c-2, R8)', (tester, env) async {
    final id = await _fill(env);
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
      matching: find.text(_en.studyMode(StudyMode.fill).toUpperCase()),
    );

    expect(fill.color, AppColorSchemes.light.primary);
    expect(
      tester.widget<Text>(chip).style?.color,
      tester.element(chip).derivedColors.primaryInk,
    );
  });

  libraryTest('a wrong answer the busy database refused shows what was typed '
      'once Retry commits it (UC-STUDY-001 E2; P4 final review)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await _type(tester, 'term 9');

    env.sessions.isLocked = true;
    await tester.tap(find.text(_en.studyFillCheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await _settle(tester);
    expect(find.text(_en.studyAnswerBusyTitle), findsOneWidget);

    env.sessions.isLocked = false;
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    final struck = tester.widget<Text>(find.text('term 9'));
    expect(struck.style!.decoration, TextDecoration.lineThrough);
    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
  });

  libraryTest('a double tap on Check does not skip the wrong answer: '
      'Continue settles first (critique 2026-09-30 part 3c-2, R1)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, 'term 9');
    await tester.tap(find.text(_en.studyFillCheck));
    await _settle(tester);
    await tester.tap(find.text(_en.studyContinue), warnIfMissed: false);
    await _settle(tester);

    expect(find.text('term 9'), findsOneWidget);
    expect(find.text('banana'), findsNothing);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyContinue));
    await _settle(tester);
    expect(find.text('banana'), findsOneWidget);
  });

  libraryTest('Show hint moves nothing: the hint line is reserved, at the '
      'study detail role (critique 2026-09-30 part 3c-2, R4)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final before = tester.getTopLeft(find.byType(TextField)).dy;
    expect(find.bySemanticsLabel(_en.studyFillHintRow('hint 1')), findsNothing);

    await tester.tap(find.text(_en.studyFillShowHint));
    await _settle(tester);

    expect(tester.getTopLeft(find.byType(TextField)).dy, before);
    expect(
      find.bySemanticsLabel(_en.studyFillHintRow('hint 1')),
      findsOneWidget,
    );
    final hint = find.text('hint 1');
    expect(
      tester.widget<Text>(hint).style,
      tester.element(hint).textStyles.studyDetail,
    );
    handle.dispose();
  });

  libraryTest('a hint that wraps is reserved whole too (R4)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await env.db.customStatement(
      "UPDATE card SET hint = 'starts with the letter t and has two "
      "syllables, the second one a number' WHERE id = 'ST-01'",
    );
    await pumpLibraryScreen(tester, env, _screen(id));
    final before = tester.getTopLeft(find.byType(TextField)).dy;

    await tester.tap(find.text(_en.studyFillShowHint));
    await _settle(tester);

    expect(tester.getTopLeft(find.byType(TextField)).dy, before);
  });

  libraryTest('a double tap on Show hint does not check a half-typed '
      'answer: Check settles first (critique 2026-09-30 part 3c-2, final '
      'review)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _type(tester, 'te');
    await tester.tap(find.text(_en.studyFillShowHint));
    await _settle(tester);
    await tester.tap(find.text(_en.studyFillCheck), warnIfMissed: false);
    await _settle(tester);

    expect(await _loggedTurns(env), 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'te',
    );
  });
}
