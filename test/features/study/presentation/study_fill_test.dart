import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_fill_widget.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import 'support/study_screen_helpers.dart';

import 'package:forui/forui.dart';

// Screen 20, Fill (UC-STUDY-008): BR-STUDY-026 to BR-STUDY-030, BR-STUDY-059,
// BR-STUDY-063, BR-STUDY-064; FE-A6 P4 rulings F1–F4, V1, V4, V6, V7, V10.

final _en = lookupAppLocalizations(const Locale('en'));

/// ST-01 ("term 1", meaning "apple", hint "hint 1") is served first.
Future<String> _fill(LibraryEnv env) =>
    openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.fill);

MxButton _button(WidgetTester tester, String label) => tester.widget<MxButton>(
  find.ancestor(of: find.text(label), matching: find.byType(MxButton)),
);

Future<int> _loggedTurns(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT id FROM review_log').get()).length;

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(FTextField), text);
  await tester.pump();
}

void main() {
  libraryTest('the meaning asks, the field takes the term, and Check waits '
      'for text; Done on nothing does nothing (20 input, F2, V7)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expect(find.text('apple'), findsOneWidget);
    expect(find.textContaining(_en.studyFillHintInput), findsOneWidget);
    // The input hint takes the info glyph, as every mode's instruction does
    // (critique 2026-10-02 F7; audit 2026-10-17).
    expect(footerHintIcon(tester), AppIcons.info);
    expect(_button(tester, _en.studyFillCheck).onPressed, isNull);

    await _type(tester, '   ');
    expect(_button(tester, _en.studyFillCheck).onPressed, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpThreeFrames(tester);
    expect(await _loggedTurns(env), 0);
    expect(find.text('apple'), findsOneWidget);
  });

  libraryTest('the field has focus when the turn opens (V7)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  libraryTest('a right answer moves on at once, with no feedback frame '
      '(F3, BR-STUDY-064; case and outer spaces ignored)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, ' Term 1 ');
    await tester.tap(find.text(_en.studyFillCheck));
    await pumpThreeFrames(tester);

    expect(find.text('banana'), findsOneWidget);
    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('IME Done checks (F2)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, 'term 1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpThreeFrames(tester);

    expect(find.text('banana'), findsOneWidget);
  });

  test('the typed text against the term: the longest run they share, '
      'ignoring case, the rest the slip', () {
    String slip(String typed, String term) => [
      for (final (grapheme, isMatch) in typedAgainst(typed, term))
        isMatch ? '.' : grapheme,
    ].join();
    expect(slip('term 9', 'term 1'), '.....9');
    expect(slip('aple', 'apple'), '....');
    expect(slip('Applle', 'apple'), '....l.');
    expect(slip('xyz', 'apple'), 'xyz');
    expect(slip('강아지', '강아지들'), '...');
  });

  libraryTest('a wrong answer is struck through beside the right term, '
      'announced, and waits for Continue (F3, V1, V10, BR-STUDY-059)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, 'term 9');
    await tester.tap(find.text(_en.studyFillCheck));
    await pumpThreeFrames(tester);

    final struck = tester.widget<Text>(find.text('term 9'));
    expect(struck.style!.decoration, TextDecoration.lineThrough);
    // Only the slip is in the error ink (audit 2026-10-19, G6).
    final context = tester.element(find.text('term 9'));
    expect(
      [
        for (final span
            in (struck.textSpan! as TextSpan).children!.cast<TextSpan>())
          if (span.style?.color == context.colors.error) span.text,
      ],
      ['9'],
    );
    expect(find.text('term 1'), findsOneWidget);
    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
    expect(find.textContaining(_en.studyFillHintWrong), findsOneWidget);
    // The footer states the grading rule, so it takes info; the tag above
    // says the card comes back (audit 2026-10-19, G6).
    expect(footerHintIcon(tester), AppIcons.info);
    expect(find.byType(FTextField), findsNothing);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyFillAnnounceWrong('term 1')),
    );

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyContinue));
    await pumpThreeFrames(tester);
    expect(find.text('banana'), findsOneWidget);
    handle.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('accents count: "tèrm 1" does not match "term 1" '
      '(BR-STUDY-026)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, 'tèrm 1');
    await tester.tap(find.text(_en.studyFillCheck));
    await pumpThreeFrames(tester);

    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest("Show hint shows the card's hint once and keeps what was typed "
      '(F4, BR-STUDY-028)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, 'ter');
    await tester.tap(find.text(_en.studyFillShowHint));
    await pumpThreeFrames(tester);

    expect(find.text('hint 1'), findsOneWidget);
    expect(find.text(_en.studyFillShowHint), findsNothing);
    expect(find.textContaining(_en.studyFillHintUsed), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(FTextField),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'ter',
    );
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a card with no hint offers no Show hint (F4)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await env.db.customStatement(
      "UPDATE card SET hint = NULL WHERE id = 'ST-01'",
    );
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expect(find.text(_en.studyFillShowHint), findsNothing);
    expect(find.text(_en.studyFillCheck), findsOneWidget);
  });

  libraryTest('the top bar is Indigo, as in every mode (critique 2026-09-30 '
      'part 3c-2, R8)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    expectIndigoTopBar(tester, StudyMode.fill);
  });

  libraryTest('a wrong answer the busy database refused shows what was typed '
      'once Retry commits it (UC-STUDY-001 E2; P4 final review)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await _type(tester, 'term 9');

    env.sessions.isLocked = true;
    await tester.tap(find.text(_en.studyFillCheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await pumpThreeFrames(tester);
    expect(find.text(_en.studyAnswerBusyTitle), findsOneWidget);

    env.sessions.isLocked = false;
    await tester.tap(find.text(_en.commonRetry));
    await pumpThreeFrames(tester);

    final struck = tester.widget<Text>(find.text('term 9'));
    expect(struck.style!.decoration, TextDecoration.lineThrough);
    expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a double tap on Check does not skip the wrong answer: '
      'Continue settles first (critique 2026-09-30 part 3c-2, R1)', (
    tester,
    env,
  ) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, 'term 9');
    await tester.tap(find.text(_en.studyFillCheck));
    await pumpThreeFrames(tester);
    await tester.tap(find.text(_en.studyContinue), warnIfMissed: false);
    await pumpThreeFrames(tester);

    expect(find.text('term 9'), findsOneWidget);
    expect(find.text('banana'), findsNothing);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text(_en.studyContinue));
    await pumpThreeFrames(tester);
    expect(find.text('banana'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  // The hint line is reserved whole, one line or several (R4).
  for (final (name, hint) in [
    (
      'Show hint moves nothing: the hint line is reserved, at the study '
          'detail role',
      'hint 1',
    ),
    (
      'a hint that wraps is reserved whole too',
      'starts with the letter t and has two syllables, the second one a '
          'number',
    ),
  ]) {
    libraryTest('$name (critique 2026-09-30 part 3c-2, R4)', (
      tester,
      env,
    ) async {
      final handle = tester.ensureSemantics();
      final id = await _fill(env);
      await env.db.customStatement('UPDATE card SET hint = ? WHERE id = ?', [
        hint,
        'ST-01',
      ]);
      await pumpLibraryScreen(tester, env, studySessionScreen(id));
      final before = tester.getTopLeft(find.byType(FTextField)).dy;
      expect(find.bySemanticsLabel(_en.studyFillHintRow(hint)), findsNothing);

      await tester.tap(find.text(_en.studyFillShowHint));
      await pumpThreeFrames(tester);

      expect(tester.getTopLeft(find.byType(FTextField)).dy, before);
      expect(find.bySemanticsLabel(_en.studyFillHintRow(hint)), findsOneWidget);
      final shown = find.text(hint);
      expect(
        tester.widget<Text>(shown).style,
        tester
            .element(shown)
            .texts
            .body
            .copyWith(color: tester.element(shown).colors.mutedForeground),
      );
      handle.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    });
  }

  libraryTest('a double tap on Show hint does not check a half-typed '
      'answer: Check settles first (critique 2026-09-30 part 3c-2, final '
      'review)', (tester, env) async {
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));

    await _type(tester, 'te');
    await tester.tap(find.text(_en.studyFillShowHint));
    await pumpThreeFrames(tester);
    await tester.tap(find.text(_en.studyFillCheck), warnIfMissed: false);
    await pumpThreeFrames(tester);

    expect(await _loggedTurns(env), 0);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(FTextField),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'te',
    );
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('on a short phone with the keyboard open the answer field '
      'stays whole on screen (audit 2026-10-17, STUDYB-9)', (
    tester,
    env,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1
      ..viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, studySessionScreen(id));
    await tester.pump();

    final field = tester.getRect(find.byType(EditableText));
    expect(field.top, greaterThanOrEqualTo(0));
    expect(field.bottom, lessThanOrEqualTo(800 - 300));
    expect(tester.takeException(), isNull);
  });
}
