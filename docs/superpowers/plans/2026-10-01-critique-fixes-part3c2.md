# Critique 2026-09-30 part 3c-2 (session screens) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the critique's findings on the session screens 16–20: a settle guard on actions swapped in place, an inline footer hint that reserves two lines, Match accepting a meaning first with a recessed meaning column, Fill's hint at a type-scale role with its line reserved, a centred Guess blocked notice, Indigo for Recall and Fill, and a two-line context line without Guess's first-pick words.

**Architecture:** Three study-local support widgets carry the new behaviour (`StudySettleGuardWidget` new, `SessionFooterHintWidget` and `SessionContextLineWidget` changed, `StudyCentredScrollWidget` moved out of the summary). Screens 16a, 19 and 20 wrap their CTA rows in the guard. Shared code changes only by narrowing: `MxStudyTopBar` loses `accent`/`accentInk`, `MxErrorState.actionIcon` becomes nullable, and `AppDecorations.studyChoice` gains an `isRecessed` flag for the idle ground.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, ARB l10n (`flutter gen-l10n`), flutter_test with the repo's `libraryTest` / `pumpLibraryScreen` and `pumpMx` harnesses.

**Spec:** `docs/superpowers/specs/2026-10-01-critique-fixes-part3c2-design.md` (approved 2026-10-01, rulings R1–R9).

## Global Constraints

- Settle window: 400 ms after the phase changes; taps ignored; opacity eases from `AppOpacity.muted` (0.7) to 1; at full opacity at once under Remove animations, still guarded; the first build never guards (spec §3.1).
- The guard's duration is a constant of the widget (`StudySettleGuardWidget.settle`), as Guess's hold and Match's flash are; no new token in `lib/core`.
- Footer hint: glyph inline before the first line; the box is at least two lines of `sessionHint` at the current text scale; a third line grows it (Text Grows Rule) (spec §3.2).
- Match hint copy: en "Tap a term and its meaning, in either order"; vi "Chạm một thuật ngữ và nghĩa của nó, theo thứ tự nào cũng được" (spec §3.3).
- Only an **idle** meaning tile is recessed (`surfaceContainerLow`); selected, right and wrong keep today's surfaces in both columns (spec §3.3).
- Fill's card hint uses `studyDetail` (M3 body-medium, 14/400, variant ink) (spec §3.4, owner 2026-10-01).
- Guess blocked: centred when it fits, scrolls from the top when not; its button has no glyph (spec §3.5).
- Every mode's top bar is Indigo; `MxStudyTopBar` has no `accent`/`accentInk` (spec §3.6).
- Context line: `maxLines: 2`, `TextOverflow.ellipsis`, `semanticsLabel` the whole sentence; `studyContextFirstPick` removed from both ARBs (spec §3.7).
- No golden is updated on Windows; goldens regenerate only in the Linux container with `TZ=UTC`.
- Every commit message ends with the two trailer lines:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01WHcLQhgp72txzYGsDLm7JX`.
- Code, identifiers and commits in English; no model identifiers in any file.

## Review Focus

1. A device with the system "Remove animations" switch on: `AnimationController` shortens its duration under the platform flag unless told not to, so the guard would collapse to a few ms; a reasonable person still expects the 400 ms guard. Pinned in Task 1 with `FakeAccessibilityFeatures(disableAnimations: true)`.
2. Recall's clock running out while the finger is on Show meaning: the swap to Continue is not a tap, but a tap landing in that instant must not advance. Pinned in Task 1 (Recall timeout test).
3. Match with a meaning selected, then a wrong term: the pair is answered on the **term's** card, both tapped tiles flash wrong, and the selection clears. Pinned in Task 3.
4. Text scale 2.0: the footer hint's reserve grows with the scale, and a hint wrapping to three lines grows past it without clipping. Pinned in Task 2.
5. Guess blocked at text scale 2.0 on the 360×800 test view: the notice scrolls from the top with no overflow. Pinned in Task 5.

---

### Task 1: Settle guard (R1) on 16a, 19 and 20

**Files:**
- Create: `lib/features/study/presentation/widgets/support/study_settle_guard_widget.dart`
- Modify: `lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart` (the `StudyCtaRowWidget` in `build`)
- Modify: `lib/features/study/presentation/widgets/sections/study_recall_widget.dart` (the `StudyCtaRowWidget` in `build`)
- Modify: `lib/features/study/presentation/widgets/sections/study_fill_widget.dart` (the `ListenableBuilder` around `StudyCtaRowWidget`)
- Create: `test/features/study/presentation/study_settle_guard_test.dart`
- Modify: `test/features/study/presentation/study_self_assess_test.dart`, `study_recall_test.dart`, `study_fill_test.dart`

**Interfaces:**
- Produces: `class StudySettleGuardWidget extends StatefulWidget { const StudySettleGuardWidget({Key? key, required Object phase, required Widget child}); static const Duration settle; }`

- [ ] **Step 1: Write the failing widget tests**

`test/features/study/presentation/study_settle_guard_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/widget_harness.dart';

// Critique 2026-09-30 part 3c-2, R1: an action swapped in place under the
// finger takes no tap for 400 ms.

Widget _guarded(Object phase, VoidCallback onTap, {bool isStill = false}) =>
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: isStill),
        child: StudySettleGuardWidget(
          phase: phase,
          child: MxButton(label: 'Go', onPressed: onTap),
        ),
      ),
    );

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(StudySettleGuardWidget),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('the first build takes a tap at once', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++));

    await tester.tap(find.text('Go'));

    expect(taps, 1);
    expect(_opacity(tester), 1);
  });

  testWidgets('after a swap the row takes no tap for 400 ms and eases in '
      'from muted, then takes one', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++));
    await pumpMx(tester, _guarded(true, () => taps++));
    await tester.pump(const Duration(milliseconds: 100));

    expect(_opacity(tester), inExclusiveRange(AppOpacity.muted, 1));
    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
    expect(_opacity(tester), 1);
  });

  testWidgets('under Remove animations the row shows at full opacity and is '
      'still guarded', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++, isStill: true));
    await pumpMx(tester, _guarded(true, () => taps++, isStill: true));
    await tester.pump(const Duration(milliseconds: 100));

    expect(_opacity(tester), 1);
    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('the platform Remove animations flag does not shorten the '
      'guard (Review Focus 1)', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++));
    await pumpMx(tester, _guarded(true, () => taps++));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('the same phase rebuilt is not a swap', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(true, () => taps++));
    await pumpMx(tester, _guarded(true, () => taps++));

    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_settle_guard_test.dart`
Expected: FAIL to compile: `study_settle_guard_widget.dart` does not exist.

- [ ] **Step 3: Write the widget**

`lib/features/study/presentation/widgets/support/study_settle_guard_widget.dart`:

```dart
import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';

/// A session screen's actions after an in-place swap (critique 2026-09-30
/// part 3c-2, R1): when [phase] changes, the row takes no tap for [settle]
/// while it eases from the muted opacity to full, so the second tap of a
/// double tap never lands on the button that replaced the first. Under
/// Remove animations it shows at full opacity at once and is still guarded.
/// The first build is not a swap.
class StudySettleGuardWidget extends StatefulWidget {
  const StudySettleGuardWidget({
    super.key,
    required this.phase,
    required this.child,
  });

  /// What the row shows; a new value is a swap.
  final Object phase;
  final Widget child;

  /// How long a swapped row ignores taps.
  static const Duration settle = Duration(milliseconds: 400);

  @override
  State<StudySettleGuardWidget> createState() => _StudySettleGuardWidgetState();
}

class _StudySettleGuardWidgetState extends State<StudySettleGuardWidget>
    with SingleTickerProviderStateMixin {
  // Preserve: the platform's Remove animations flag would shorten the guard
  // itself, not only its fade.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: StudySettleGuardWidget.settle,
    animationBehavior: AnimationBehavior.preserve,
    value: 1,
  );

  @override
  void didUpdateWidget(StudySettleGuardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase == widget.phase) return;
    unawaited(_settle.forward(from: 0));
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStill = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _settle,
      builder: (context, child) => IgnorePointer(
        ignoring: _settle.isAnimating,
        child: Opacity(
          opacity: isStill
              ? 1
              : lerpDouble(
                  AppOpacity.muted,
                  1,
                  Easing.standard.transform(_settle.value),
                )!,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
```

- [ ] **Step 4: Run the widget tests**

Run: `flutter test test/features/study/presentation/study_settle_guard_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Write the failing screen tests**

Append to `test/features/study/presentation/study_self_assess_test.dart` (inside `main`):

```dart
  libraryTest('a double tap on Show answer grades nothing: the grades settle '
      'first (critique 2026-09-30 part 3c-2, R1)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pump();
    await tester.tap(find.text(_en.cardActionGood), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await turnKindsOf(env.db, 'R1'), isEmpty);
    expect(find.text(_en.cardActionGood), findsOneWidget);

    await tester.tap(find.text(_en.cardActionGood));
    await tester.pumpAndSettle();
    expect(await turnKindsOf(env.db, 'R1'), ['scheduled']);
  });
```

Append to `test/features/study/presentation/study_recall_test.dart` (inside `main`; it needs `import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';`):

```dart
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
```

Append to `test/features/study/presentation/study_fill_test.dart` (inside `main`; same import):

```dart
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
```

- [ ] **Step 6: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_self_assess_test.dart test/features/study/presentation/study_recall_test.dart test/features/study/presentation/study_fill_test.dart --plain-name "R1"`
Expected: the three R1 tests FAIL (the second tap commits a grade, a turn, or Continue). The Review Focus 2 test may pass already if the timeout's rebuild lands after the tap; it stays as a pin.

- [ ] **Step 7: Wrap the three CTA rows**

In `study_self_assess_widget.dart`, import the guard and replace `StudyCtaRowWidget(children: [...])` with:

```dart
        StudySettleGuardWidget(
          phase: _isRevealed,
          child: StudyCtaRowWidget(
            children: [
              if (_isRevealed)
                StudyGradeRowWidget(
                  intervals: widget.intervals,
                  isBusy: widget.isBusy,
                  onGrade: widget.onGrade,
                )
              else
                MxButton(
                  label: l10n.studySelfAssessShowAnswer,
                  size: MxButtonSize.study,
                  onPressed: _reveal,
                ),
            ],
          ),
        ),
```

In `study_recall_widget.dart`, import the guard and replace `StudyCtaRowWidget(children: _actions(isTimedOut, isRevealed)),` with:

```dart
        StudySettleGuardWidget(
          phase: (isTimedOut, isRevealed),
          child: StudyCtaRowWidget(children: _actions(isTimedOut, isRevealed)),
        ),
```

In `study_fill_widget.dart`, import the guard and wrap the `ListenableBuilder`:

```dart
        StudySettleGuardWidget(
          phase: _isWrong,
          child: ListenableBuilder(
            listenable: _answer,
            builder: (context, _) => StudyCtaRowWidget(
              // children unchanged
            ),
          ),
        ),
```

Add one sentence to each widget's class doc: `Its actions settle after a swap (critique 2026-09-30 part 3c-2, R1).`

- [ ] **Step 8: Run the study tests and fix the taps the guard now ignores**

Run: `flutter test --exclude-tags golden test/features/study test/visual_audit/screens/features/study test/integration 2>&1 | tail -40`
Expected: the R1 tests PASS. Existing tests that tap a swapped button (Forgot, Remembered, Continue after a wrong Fill or a Recall timeout) with no time passing since the swap now FAIL. For each, insert `await tester.pump(StudySettleGuardWidget.settle);` right before that tap, and nothing else; ledger the list of edited tests as one ruling. Tests that reach the swap through `pumpAndSettle` need no change. Re-run until green.

- [ ] **Step 9: Commit**

```bash
git add lib/features/study/presentation/widgets test/features/study test/visual_audit test/integration
git commit -m "feat(study): actions swapped in place settle 400 ms before a tap (3c-2 R1)"
```

---

### Task 2: Footer hint, inline glyph and a two-line reserve (R6)

**Files:**
- Modify: `lib/features/study/presentation/widgets/support/session_footer_hint_widget.dart`
- Modify: `test/features/study/presentation/study_support_widgets_test.dart`
- Modify (finders only): `test/features/study/presentation/study_guess_test.dart:82`, `study_recall_test.dart:82,101,143`, `study_match_test.dart:68,119,130`, `study_browse_test.dart:102`, `study_fill_test.dart:57,123,159`, `test/visual_audit/screens/features/study/screens/study_session_screen_visual_audit_test.dart:134,162,223`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `SessionFooterHintWidget({required IconData icon, required String text})`, unchanged API; its `Text` is now `Text.rich`, so `find.text(hint)` no longer matches and tests use `find.textContaining(hint)`.

- [ ] **Step 1: Write the failing tests**

In `study_support_widgets_test.dart`, replace the test `'the footer hint wraps, never cut'` with:

```dart
  libraryTest('the footer hint wraps, never cut, its glyph inline on the '
      'first line (critique 2026-09-30 part 3c-2, R6)', (tester, env) async {
    const text =
        'Swipe left for next, right to look back · nothing is graded here';
    await pumpLibraryScreen(
      tester,
      env,
      _host(const SessionFooterHintWidget(icon: AppIcons.check, text: text)),
    );
    final hint = tester.widget<Text>(find.textContaining(text));

    expect((hint.maxLines, hint.overflow), (null, null));
    expect(hint.semanticsLabel, text);
    expect(
      find.descendant(
        of: find.byType(RichText),
        matching: find.byIcon(AppIcons.check),
      ),
      findsOneWidget,
    );
  });

  libraryTest('a one-line and a two-line hint take the same height, so the '
      'CTA stands still (critique 2026-09-30 part 3c-2, R6)', (
    tester,
    env,
  ) async {
    Future<double> heightOf(String text, {double textScale = 1}) async {
      await pumpLibraryScreen(
        tester,
        env,
        _host(SessionFooterHintWidget(icon: AppIcons.check, text: text)),
        textScale: textScale,
      );
      return tester.getSize(find.byType(SessionFooterHintWidget)).height;
    }

    const short = 'Tap to flip';
    const long =
        'Swipe left for next, right to look back · nothing is graded here';
    const threeLines =
        'Swipe left for next, right to look back · nothing is graded here, '
        'and nothing you do on this screen changes when a card comes back';

    expect(await heightOf(short), await heightOf(long));
    expect(await heightOf(threeLines), greaterThan(await heightOf(long)));
    // Review Focus 4: the reserve follows the text scale.
    expect(
      await heightOf(short, textScale: 2),
      greaterThan(await heightOf(short)),
    );
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_support_widgets_test.dart --plain-name "R6"`
Expected: FAIL: the first finds no glyph inside a `RichText`; the second's short and long heights differ.

- [ ] **Step 3: Rewrite the widget**

`session_footer_hint_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

/// The centred glyph and caption stating a turn's rule (kit
/// SessionFooterHint). Study-local, not shared. The glyph sits inline before
/// the first line and wraps with the text, and the hint always reserves two
/// lines, so the CTA above it stands in one place in every mode (critique
/// 2026-09-30 part 3c-2, R6); a third line still grows it. It steps aside
/// while the keyboard is up so the answer field keeps the room.
class SessionFooterHintWidget extends StatelessWidget {
  const SessionFooterHintWidget({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  static const int _reservedLines = 2;

  @override
  Widget build(BuildContext context) {
    if (MxAppShell.isTypingOf(context)) {
      return const SizedBox.shrink();
    }
    final style = context.textStyles.sessionHint;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        style.height!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.control,
        AppSpacing.gutter,
        AppSpacing.gutter,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: lineHeight * _reservedLines),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.control,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        color: style.color,
                        size: AppIconSize.inline,
                      ),
                      child: ExcludeSemantics(child: Icon(icon)),
                    ),
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
            semanticsLabel: text,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Move the hint finders to `find.textContaining`**

In each file and line listed under **Files**, change `find.text(_en.<hint key>)` to `find.textContaining(_en.<hint key>)`; no other edit. Then run `grep -rn "find.text(_en.study[A-Za-z]*Hint" test` and confirm it prints nothing.

- [ ] **Step 5: Run the study tests**

Run: `flutter test --exclude-tags golden test/features/study test/visual_audit/screens/features/study 2>&1 | tail -5`
Expected: PASS. Goldens are excluded here; they regenerate in Task 8.

- [ ] **Step 6: Commit**

```bash
git add lib/features/study/presentation/widgets/support/session_footer_hint_widget.dart test
git commit -m "feat(study): footer hint glyph inline, two lines reserved (3c-2 R6)"
```

---

### Task 3: Match, meaning first and a recessed meaning column (R3, BR-STUDY-062)

**Files:**
- Modify: `lib/core/theme/app_decorations.dart:98-121` (`studyChoice`)
- Modify: `lib/features/study/presentation/widgets/support/study_choice_widget.dart`
- Modify: `lib/features/study/presentation/widgets/sections/study_match_widget.dart`
- Modify: `lib/l10n/app_en.arb` (`studyMatchHint`), `lib/l10n/app_vi.arb` (`studyMatchHint`)
- Modify: `test/features/study/presentation/study_match_test.dart`

**Interfaces:**
- Produces: `AppDecorations.studyChoice(ColorScheme scheme, MxDerivedColors derived, StudyChoiceTone tone, {bool isRecessed = false})`; `StudyChoiceWidget(..., bool isRecessed = false)`.

- [ ] **Step 1: Write the failing tests**

In `study_match_test.dart`, add near `_tile`:

```dart
Color? _groundOf(WidgetTester tester, String text) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.ancestor(
                          of: find.text(text),
                          matching: find.byType(StudyChoiceWidget),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color;
```

Replace the test `'a meaning with no term selected does nothing; a second term re-selects (M1)'` with:

```dart
  libraryTest('a meaning first, then its term: the pair is matched and '
      'answered on the term (BR-STUDY-062; critique 2026-09-30 part 3c-2, '
      'R3)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.selected);

    await tester.tap(find.text('term 1'));
    await tester.pump();
    await tester.pump();

    expect(_tile(tester, 'term 1').tone, StudyChoiceTone.right);
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.right);
    expect(await turnKindsOf(env.db, 'ST-01'), isNotEmpty);
  });

  libraryTest('a tile of the same column moves the selection, on either '
      'side (R3)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.tap(find.text('banana'));
    await tester.pump();
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'banana').tone, StudyChoiceTone.selected);

    await tester.tap(find.text('term 1'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('term 3'));
    await tester.pump();
    await tester.tap(find.text('term 4'));
    await tester.pump();
    expect(_tile(tester, 'term 3').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'term 4').tone, StudyChoiceTone.selected);
  });

  libraryTest('a meaning, then the wrong term: both flash wrong, the turn is '
      "the term's, and nothing stays selected (Review Focus 3)", (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.tap(find.text('term 2'));
    await tester.pump();
    await tester.pump();

    expect(_tile(tester, 'term 2').tone, StudyChoiceTone.wrong);
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.wrong);
    expect(await turnKindsOf(env.db, 'ST-02'), isNotEmpty);
    expect(await turnKindsOf(env.db, 'ST-01'), isEmpty);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'term 2').tone, StudyChoiceTone.idle);
  });

  libraryTest('idle meanings are recessed, idle terms raised (R3)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final scheme = Theme.of(tester.element(find.text('apple'))).colorScheme;

    expect(_groundOf(tester, 'apple'), scheme.surfaceContainerLow);
    expect(_groundOf(tester, 'term 1'), scheme.surfaceContainerLowest);
  });
```

If `turnKindsOf` and the fixture card ids differ from `ST-01`/`ST-02` for term 1/term 2, read `openFiveDueReview` in `test/support/study_entry_fixtures.dart` and use its ids; ledger the correction.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_match_test.dart`
Expected: the four new tests FAIL (a meaning tap leaves the tile idle; the meaning ground is `surfaceContainerLowest`).

- [ ] **Step 3: Recessed idle ground**

In `app_decorations.dart`, change `studyChoice`:

```dart
  /// A study choice surface. [isRecessed] gives an idle tile the answer
  /// face's recessed ground (Match's meanings, critique 2026-09-30 part
  /// 3c-2, R3); the other tones keep their own surfaces.
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxDerivedColors derived,
    StudyChoiceTone tone, {
    bool isRecessed = false,
  }) {
    final raised = scheme.surfaceContainerLowest;
    final (Color fill, Color edge) = switch (tone) {
      StudyChoiceTone.idle => (
        isRecessed ? scheme.surfaceContainerLow : raised,
        derived.ghostBorder,
      ),
      // the selected, right and wrong arms unchanged
    };
    // return unchanged
  }
```

Keep the doc comment that already sits above `studyChoice` and merge the sentence in. In `study_choice_widget.dart` add the field:

```dart
  /// An idle tile on the recessed ground (Match's meanings).
  final bool isRecessed;
```

with `this.isRecessed = false,` in the constructor, and pass it: `AppDecorations.studyChoice(colors, derived, tone, isRecessed: isRecessed)`.

- [ ] **Step 4: Either side first**

In `study_match_widget.dart`, replace `_selectedTerm`, `_tapTerm` and `_tapMeaning` with:

```dart
  String? _selectedTerm;
  String? _selectedMeaning;
```

```dart
  /// Either side may come first; the pair is answered on the term's card
  /// whichever did (BR-STUDY-062; critique 2026-09-30 part 3c-2, R3).
  void _tapTerm(MatchTile term) {
    if (!_canTap || term.isMatched) return;
    final meaning = _selectedMeaning;
    if (meaning == null) {
      setState(() => _selectedTerm = term.cardId);
      return;
    }
    _pairUp(term.cardId, meaning);
  }

  void _tapMeaning(MatchTile meaning) {
    if (!_canTap || meaning.isMatched) return;
    final term = _selectedTerm;
    if (term == null) {
      setState(() => _selectedMeaning = meaning.cardId);
      return;
    }
    _pairUp(term, meaning.cardId);
  }

  void _pairUp(String termCardId, String meaningCardId) {
    setState(() {
      _selectedTerm = null;
      _selectedMeaning = null;
    });
    widget.onPair(termCardId, meaningCardId);
  }
```

In `_meaning`, pass `isSelected: meaning.cardId == _selectedMeaning,` to `_toneOf`. In `_Tile.build`, pass `isRecessed: !isTerm,` to `StudyChoiceWidget`. Update the class doc's "Tap a term, then a meaning;" to "Tap a term and a meaning, in either order;".

- [ ] **Step 5: The hint copy**

`app_en.arb`: `"studyMatchHint": "Tap a term and its meaning, in either order",`
`app_vi.arb`: `"studyMatchHint": "Chạm một thuật ngữ và nghĩa của nó, theo thứ tự nào cũng được",`
Run: `flutter gen-l10n`

- [ ] **Step 6: Run the Match tests and the theme tests**

Run: `flutter test test/features/study/presentation/study_match_test.dart test/core/theme test/features/study/presentation/study_support_widgets_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/core/theme/app_decorations.dart lib/features/study lib/l10n test/features/study
git commit -m "fix(study): Match takes a meaning first, meanings recessed (3c-2 R3, BR-STUDY-062)"
```

---

### Task 4: Fill's hint, a type-scale role and a reserved line (R4)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_fill_widget.dart` (the answer face's `Column` and `_HintRow`)
- Modify: `test/features/study/presentation/study_fill_test.dart`

**Interfaces:** none shared.

- [ ] **Step 1: Write the failing tests**

Append to `study_fill_test.dart` (it needs `import 'package:memox/core/theme/theme_context.dart';`):

```dart
  libraryTest('Show hint moves nothing: the hint line is reserved, at the '
      'study detail role (critique 2026-09-30 part 3c-2, R4)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final id = await _fill(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final before = tester.getTopLeft(find.byType(TextField)).dy;
    expect(
      find.bySemanticsLabel(_en.studyFillHintRow('hint 1')),
      findsNothing,
    );

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
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_fill_test.dart --plain-name "R4"`
Expected: FAIL: the field moves down after Show hint; the style is `sessionHint`.

- [ ] **Step 3: Reserve the row and change its role**

In the answer face's `Column` children, replace `if (isHintShown) _HintRow(hint: hint),` with:

```dart
                              // Laid out from the start, so showing it moves
                              // nothing (critique 2026-09-30 part 3c-2, R4).
                              if (hint != null)
                                Visibility(
                                  visible: isHintShown,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: _HintRow(hint: hint),
                                ),
```

In `_HintRow`, change `style: context.textStyles.sessionHint,` to `style: context.textStyles.studyDetail,` and update its doc to `/// The card's hint, shown on request (BR-STUDY-028), at the study detail role (M3 body-medium; 3c-2 R4).`

- [ ] **Step 4: Run the Fill tests**

Run: `flutter test test/features/study/presentation/study_fill_test.dart`
Expected: PASS. The existing `"Show hint shows the card's hint once"` test still finds `'hint 1'` once after the tap.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/widgets/sections/study_fill_widget.dart test/features/study/presentation/study_fill_test.dart
git commit -m "fix(study): Fill's hint reserved at the study detail role (3c-2 R4)"
```

---

### Task 5: Guess blocked, centred and with one glyph less (R5)

**Files:**
- Create: `lib/features/study/presentation/widgets/support/study_centred_scroll_widget.dart`
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_widget.dart` (delete `_CentredScroll`, use the new widget)
- Modify: `lib/features/study/presentation/widgets/sections/study_guess_widget.dart:110-124`
- Modify: `lib/shared/widgets/mx_error_state.dart:13,23,43,95` (`actionIcon` nullable)
- Modify: `test/features/study/presentation/study_guess_test.dart`, `test/shared/widgets/mx_error_state_test.dart`

**Interfaces:**
- Produces: `class StudyCentredScrollWidget extends StatelessWidget { const StudyCentredScrollWidget({Key? key, required List<Widget> children}); }`; `MxErrorState({..., IconData? actionIcon = AppIcons.retry})` where null draws no glyph.

- [ ] **Step 1: Write the failing tests**

In `test/shared/widgets/mx_error_state_test.dart`, add (match the file's harness, `pumpMx`):

```dart
  testWidgets('a null actionIcon draws the action with no glyph (critique '
      '2026-09-30 part 3c-2, R5)', (tester) async {
    await pumpMx(
      tester,
      MxErrorState(
        title: 'Stuck',
        body: 'Nothing to ask',
        retryLabel: 'Close the session',
        onRetry: () {},
        actionIcon: null,
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(MxButton, 'Close the session'),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });
```

In `study_guess_test.dart`, inside the blocked test after the `find.byIcon(AppIcons.retry)` expectation, add:

```dart
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
```

and add a second blocked test (copy the blocked test's `LibraryEnv` setup and `try/finally`):

```dart
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
```

Add the imports the new lines need: `study_guess_widget.dart` and `app_spacing.dart`.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/shared/widgets/mx_error_state_test.dart test/features/study/presentation/study_guess_test.dart`
Expected: FAIL to compile (`actionIcon: null` on a non-nullable parameter); after Step 3's first edit the Guess test FAILS on the centre (the notice sits at the top) and on the glyph.

- [ ] **Step 3: Nullable action glyph**

In `mx_error_state.dart`: the field becomes `final IconData? actionIcon;`, the constructor keeps `this.actionIcon = AppIcons.retry,`, and the doc line reads `/// [actionIcon] swaps Retry's glyph when the action is not a retry; null draws none.` The `MxButton(icon: actionIcon, ...)` call needs no change, as `MxButton.icon` is nullable.

- [ ] **Step 4: Move the centred scroll**

Create `study_centred_scroll_widget.dart` with the body of the summary's `_CentredScroll`, made public:

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// A session's lone moment: centred between the bars when it fits,
/// scrolled from the top when it does not (critique 2026-09-30 part 3c-1,
/// R4; part 3c-2, R5). Study-local: the summary and Guess's blocked notice
/// use it.
class StudyCentredScrollWidget extends StatelessWidget {
  const StudyCentredScrollWidget({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.gutter,
          end: AppSpacing.gutter,
          bottom: AppSpacing.section + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              constraints.maxHeight - AppSpacing.section - bottomInset,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
```

In `session_summary_widget.dart`, delete `_CentredScroll` and its doc, replace `_CentredScroll(` with `StudyCentredScrollWidget(`, import the new file, and drop `dart:math` if nothing else uses it.

- [ ] **Step 5: The blocked notice**

In `study_guess_widget.dart`, replace the blocked branch's return with:

```dart
      return StudyCentredScrollWidget(
        children: [
          MxErrorState(
            title: l10n.studyGuessBlockedTitle,
            body: l10n.studyGuessBlockedBody,
            icon: AppIcons.close,
            retryLabel: l10n.studySessionClose,
            onRetry: widget.onClose,
            // The top bar and the notice already show a ×
            // (critique 2026-09-30 part 3c-2, R5).
            actionIcon: null,
          ),
        ],
      );
```

Drop the `mx_screen_scroll.dart` import if unused.

- [ ] **Step 6: Run the tests**

Run: `flutter test test/shared/widgets/mx_error_state_test.dart test/features/study/presentation/study_guess_test.dart test/features/study/presentation/session_summary_test.dart`
Expected: PASS. If the centre check misses by more than 1 because `MxErrorState` pads itself asymmetrically, compare the centre of its first `Column` instead and ledger the ruling.

- [ ] **Step 7: Commit**

```bash
git add lib/features/study lib/shared/widgets/mx_error_state.dart test
git commit -m "fix(study): Guess blocked notice centred, Close without a glyph (3c-2 R5)"
```

---

### Task 6: Indigo in every mode; `MxStudyTopBar` loses its accent (R8)

**Files:**
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart:297-307`
- Modify: `lib/shared/widgets/mx_study_top_bar.dart`
- Modify: `lib/app/gallery/gallery_chrome_section.dart:56-65`
- Modify: `test/shared/widgets/mx_study_top_bar_test.dart`, `test/shared/widgets/primary_ink_widgets_test.dart:166-182`, `test/shared/widgets/shared_widgets_golden_test.dart:198-206`
- Modify: `test/features/study/presentation/study_recall_test.dart:237-248`, `test/features/study/presentation/study_fill_test.dart:180-191`

**Interfaces:**
- Produces: `MxStudyTopBar({required String modeLabel, required int current, required int total, required String counterLabel, required String closeLabel, required VoidCallback onClose})` — no `accent`, no `accentInk`.

- [ ] **Step 1: Write the failing screen tests**

In `study_recall_test.dart`, replace `'the top bar carries the mastery accent (R3)'` with (imports: `app_color_schemes.dart`, `theme_context.dart`; drop `mx_semantic_colors.dart` if unused):

```dart
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
```

In `study_fill_test.dart`, the same test with `_fill(env)` and `StudyMode.fill`. If `studyMode` is an extension on `AppLocalizations` that the tests cannot reach, find the chip with `find.textContaining(RegExp('^[A-Z ]+\$'))` scoped to the bar's badge, and ledger it.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_recall_test.dart test/features/study/presentation/study_fill_test.dart --plain-name "R8"`
Expected: FAIL: the fill is the mastery green.

- [ ] **Step 3: Remove the accent**

In `study_session_screen.dart`, delete the comment and the `accent:` and `accentInk:` arguments (lines 298–307).

In `mx_study_top_bar.dart`: delete the `accent` and `accentInk` constructor parameters, fields and docs; in `build`, use

```dart
    final accentColor = colors.primary;
    // The badge text is ink: primaryInk on the primary tint.
    final accentInk = context.derivedColors.primaryInk;
```

and change the class doc's second sentence to `Indigo in every mode (critique 2026-09-30 part 3c-2, R8): the badge, its tint and the fill.`

In `gallery_chrome_section.dart`, delete the two accent lines from the Recall sample; the sample stays as the full-track bar.

- [ ] **Step 4: Fix the shared tests**

- `mx_study_top_bar_test.dart`: `_bar` drops its `accent` parameter and argument; the test `'accent defaults to primary and follows the caller'` becomes `'the fill is primary'` and keeps only its first expectation (`AppColorSchemes.light.primary`); drop the `mx_semantic_colors.dart` import if unused.
- `primary_ink_widgets_test.dart`: the `MxStudyTopBar` test becomes `'MxStudyTopBar: the badge text is primaryInk'`, with `bar()` taking no accent and only the first `pumpDark` and expectation kept.
- `shared_widgets_golden_test.dart`: delete `accent: MxSemanticColors.light.mastery,` from the Recall bar; drop the import if unused.

- [ ] **Step 5: Run the tests and analyze**

Run: `flutter analyze lib test && flutter test --exclude-tags golden test/shared/widgets test/features/study test/app`
Expected: `No issues found!` and PASS.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat(study): Recall and Fill take Indigo; MxStudyTopBar drops its accent (3c-2 R8)"
```

---

### Task 7: Context line, two lines at most, no first-pick words (R9)

**Files:**
- Modify: `lib/features/study/presentation/widgets/support/session_context_line_widget.dart`
- Modify: `lib/features/study/presentation/states/session_context_state.dart:7-10,39-46`
- Modify: `lib/l10n/app_en.arb` (delete `studyContextFirstPick` and `@studyContextFirstPick`), `lib/l10n/app_vi.arb` (delete `studyContextFirstPick`)
- Modify: `test/features/study/presentation/study_support_widgets_test.dart:130-145`, `test/features/study/presentation/study_guess_test.dart:230-248`

**Interfaces:** none shared.

- [ ] **Step 1: Write the failing tests**

In `study_support_widgets_test.dart`, replace `'the context line wraps, never cut, and is heard whole'` with:

```dart
  libraryTest('the context line holds two lines at most, ends in an '
      'ellipsis, and is heard whole (critique 2026-09-30 part 3c-2, R9)', (
    tester,
    env,
  ) async {
    const text =
        'Tiếng Hàn TOPIK I · Từ vựng sơ cấp · Learning · Stage 1 of 3 · Match';
    await pumpLibraryScreen(
      tester,
      env,
      _host(SessionContextLineWidget(text: text, shown: text.toUpperCase())),
    );
    final line = tester.widget<Text>(find.text(text.toUpperCase()));

    expect((line.maxLines, line.overflow), (2, TextOverflow.ellipsis));
    expect(line.semanticsLabel, text);
  });
```

In `study_guess_test.dart`, replace `'the context line names the round and the first-pick rule (M3)'` with:

```dart
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
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_support_widgets_test.dart test/features/study/presentation/study_guess_test.dart --plain-name "R9"`
Expected: FAIL: `maxLines` is null; the Guess line still carries "first pick counts".

- [ ] **Step 3: Implement**

In `session_context_line_widget.dart`, add to the `Text`:

```dart
      maxLines: _maxLines,
      overflow: TextOverflow.ellipsis,
```

with `static const int _maxLines = 2;` on the class, and its doc's last sentence reads `Two lines at most (critique 2026-09-30 part 3c-2, R9): a long deck name ends in an ellipsis on screen and is read whole by a screen reader.`

In `session_context_state.dart`, the doc's first sentences become `The session's context line: deck and kind (a learning session adds its stage); a round-based stage adds its round. Guess's first-pick rule is its footer's (critique 2026-09-30 part 3c-2, R9).` and the tail of `_contextOf` becomes:

```dart
  if (!view.currentMode.handler.usesRounds) return base;
  return l10n.studyContextRound(base, view.currentRound ?? 1);
```

Drop the `study_mode.dart` import if nothing else uses it. Delete the ARB entries, then run `flutter gen-l10n` and `grep -rn studyContextFirstPick lib test docs` (expected: nothing in `lib` or `test`).

- [ ] **Step 4: Run the tests**

Run: `flutter test --exclude-tags golden test/features/study`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "fix(study): context line two lines at most, Guess without first-pick words (3c-2 R9)"
```

---

### Task 8: Records, goldens and the gate

**Files:**
- Modify: `DESIGN.md` (Study-specific section, `MxStudyTopBar` in Navigation)
- Modify: `docs/shared/ui/screen-handoff/16-study-browse.md`, `16a-study-self-assess.md`, `17-study-match.md`, `18-study-guess.md`, `19-study-recall.md`, `20-study-fill.md`
- Modify: `docs/wbs_FE.md` (new row FE-D14 after FE-D13)
- Modify: `test/**/goldens/*.png` (regenerated)

- [ ] **Step 1: DESIGN.md**

- In `### Study-specific`, the `StudyCtaRow` bullet gains a last sentence: `An action swapped in place under the finger (Show answer to the grades, Show meaning to Forgot · Remembered, Check to Continue) settles for 400 ms, easing in from \`AppOpacity.muted\`, before it takes a tap (critique 2026-09-30 part 3c-2).`
- The `MxOutcomeTile` bullet's "and the recessed answer face." becomes `and the recessed answer face, whose ground Match's idle meaning tiles share while its terms stay raised (part 3c-2).`
- Add a bullet after `StudyCtaRow`: `- **SessionFooterHint**: the glyph sits inline before the first line and wraps with the text; the hint reserves two lines, so the CTA above it stands in one place in every mode (critique 2026-09-30 part 3c-2).`
- In `### Navigation`, `**MxStudyTopBar** (close, mode badge, thin progress; the session context line under it names deck, kind, stage and round, never the mode again)` becomes `**MxStudyTopBar** (close, mode badge, thin progress, Indigo in every mode; the session context line under it names deck, kind, stage and round in two lines at most, never the mode again; critique 2026-09-30 part 3c-2)`.

- [ ] **Step 2: Detail files**

Under `## Rulings` of each, append one line:

- 16: `- **Critique 2026-09-30 part 3c-2 (spec \`2026-10-01-critique-fixes-part3c2-design.md\`):** the footer hint's glyph sits inline and the hint reserves two lines (R6); the bar is Indigo in every mode (R8); the context line holds two lines at most (R9).` Also, in `## Shared by the session screens`, replace "tinted with the bar's accent (primary by default; Recall and Fill pass the mastery colour instead — no BR found for that choice, ruled below)" with "tinted with the bar's Indigo, in every mode (critique 2026-09-30 part 3c-2, R8)".
- 16a: `- **Critique 2026-09-30 part 3c-2:** the grades settle for 400 ms after Show answer (R1); they keep their rounded rectangles, as they judge rather than act (R7).`
- 17: `- **Critique 2026-09-30 part 3c-2:** a meaning may be tapped first, as BR-STUDY-062 requires; idle meanings sit on the recessed ground; hint "Tap a term and its meaning, in either order" (R3).` Update the hint in `## Copy` to the same text.
- 18: `- **Critique 2026-09-30 part 3c-2:** the hold stays 1200 ms or until a tap (R2); the blocked notice is centred and its Close has no glyph (R5); the context line drops "first pick counts", which the footer states (R9).` Remove the first-pick words from any context-line copy in the file.
- 19: `- **Critique 2026-09-30 part 3c-2:** Forgot · Remembered and the timed-out Continue settle for 400 ms (R1); the bar is Indigo (R8).` Replace the Layout row's "Mastery accent (ruled in 16)." with "Indigo, as every mode (3c-2 R8)." and line 46's "the top bar keeps the mastery accent" with "the top bar is Indigo (3c-2 R8)".
- 20: `- **Critique 2026-09-30 part 3c-2:** Continue after a wrong answer settles for 400 ms (R1); the card's hint is the study detail role with its line reserved (R4); the bar is Indigo (R8).` Replace "Mastery accent (ruled in 16)." with "Indigo, as every mode (3c-2 R8)."

Then run `grep -n -i "mastery accent" docs/shared/ui/screen-handoff/1[6-9]*.md docs/shared/ui/screen-handoff/20-*.md` and expect nothing.

- [ ] **Step 3: WBS**

After the FE-D13 row in `docs/wbs_FE.md` add:

```
| FE-D14 | Critique 2026-09-30 phần 3c-2: settle guard 400 ms khi nút đổi tại chỗ (16a, 19, 20), footer hint icon liền dòng và giữ chỗ 2 dòng, Match chạm nghĩa trước (BR-STUDY-062) và cột nghĩa nền lõm, hint của Fill ở vai studyDetail và giữ chỗ, Guess bị chặn canh giữa, Recall/Fill màu Indigo (`MxStudyTopBar` bỏ accent), context line tối đa 2 dòng | đang làm | FE-D13 | S | [spec](superpowers/specs/2026-10-01-critique-fixes-part3c2-design.md) và [plan](superpowers/plans/2026-10-01-critique-fixes-part3c2.md) | — |
```

- [ ] **Step 4: Check the docs and commit**

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`

```bash
git add DESIGN.md docs
git commit -m "docs: record critique 2026-09-30 part 3c-2"
```

- [ ] **Step 5: Regenerate the goldens (Linux container)**

`S` is this plan's workspace (`S=$(.claude/skills/subagent-driven-development/scripts/sdd-workspace docs/superpowers/plans/2026-10-01-critique-fixes-part3c2.md)`).

Run: `TZ=UTC flutter test --tags golden --update-goldens > "$S/3c2-gu.log" 2>&1; tail -1 "$S/3c2-gu.log"; git status --short | grep goldens | wc -l`
Expected: the run ends `All tests passed!`; changed goldens include every session screen (the footer hint), the Recall and Fill bars, Match, Guess blocked, Fill's hint and `mx_study_top_bar`. Look at a strip of the changed session goldens before committing; anything that is not one of these causes is a finding to debug, not to commit.

- [ ] **Step 6: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > "$S/3c2-dod.log" 2>&1; echo $?; grep -E "All tests passed|Some tests failed" "$S/3c2-dod.log" | tail -1; TZ=UTC flutter test --tags golden 2>&1 | tail -1`
Expected: exit 0, `All tests passed!`, and the golden run passes.

- [ ] **Step 7: Commit the goldens**

```bash
git add test
git commit -m "test(goldens): regenerate for part 3c-2 session screens"
```
