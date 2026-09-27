# Study P3 — Guess (18), Match (17), the review-mode pick and the top bar at large text — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `eight_box` reviews run in Match and Guess from the app: the Study Entry picks the review mode, and screens 17 and 18 answer the board and the question with their outcomes shown after commit.

**Architecture:** Two new mode bodies in the session route's exhaustive switch, both presentational, and both writing through the existing session controller (D4). The controller gains one optional `cardId` on `answer`, because a Match answer names any pending pair of the board (BR-STUDY-049). Both hold their turn (D5) to show the outcome: Guess holds 1200 ms or until tapped, and Match holds a wrong pair's 600 ms flash. The Study Entry's review list becomes a pick, owned by a small per-deck notifier that the offer reads. The shared top bar keeps a legible track at large text.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, Drift (in-memory in tests), `flutter gen-l10n`.

**Spec:** [2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) (D4, D5, D14, D19, §3). Roadmap and its rulings: [2026-09-26-study-chain-roadmap.md](2026-09-26-study-chain-roadmap.md) (G1–G3, M1–M3, E1, T1; approved by the owner). Screens: [17-study-match.md](../../shared/ui/screen-handoff/17-study-match.md), [18-study-guess.md](../../shared/ui/screen-handoff/18-study-guess.md), [14-study-entry.md](../../shared/ui/screen-handoff/14-study-entry.md), and the section of [16](../../shared/ui/screen-handoff/16-study-browse.md#shared-by-the-session-screens) shared by the session screens. Pre-plan critique: `.impeccable/critique/2026-09-26T12-26-52Z__docs-shared-ui-screen-handoff-18-study-guess-md.md`.

**Rulings added by the pre-plan critique** (recorded in Task 9):

- **C1 (P0):** the right option and a matched tile use the `success` semantic (`successSoft`, `successBorder`, `successInk`), not the kit's `mastery`. D14 keeps green for mastery only.
- **C2:** a blocked Guess question's Close ends the session as ✕ does (BR-STUDY-040: nothing is skipped and nothing advances).
- **C3:** both screens announce each outcome to TalkBack when its write commits, and every option and tile carries its state in its label.
- **C4:** the Guess options and the Match board scroll once they outgrow the screen at large text; every row and tile is at least 48 tall; 2x goldens pin this.
- **C5:** the default review mode is the first available mode (E1), not the kit frame's Recall; this is recorded as a 14 deviation.
- **C6:** with TalkBack on (`MediaQuery.accessibleNavigationOf`), Guess waits for a "Next" button instead of advancing by itself.
- **C7:** during a wrong pair's flash, the footer hint reads "Not a match — this pair comes back next round".
- **C8:** Match reads its terms first, then its meanings; each tile names its side and state.
- **T1, refined:** the mode chip is capped at 40% of the bar's width and ellipsizes, so the track keeps at least 48.

## Global Constraints

- `study` imports only `study_mode`, `srs`, `settings`, `card`; `presentation/` never imports `data/`; `app/` composes.
- Presentation files end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
- Every user-facing string is an ARB key in `app_en.arb` and `app_vi.arb`, including semantics labels and announcements.
- No `ref.read` in a `build()` body; `if (!ref.mounted) return;` after every await in a controller.
- Booleans read as predicates (`is…`, `has…`, `can…`, `should…`); no source file over 400 logical lines.
- Features pass no `Color`, `TextStyle`, radius or padding to shared widgets and never restyle text; new roles go in `MxTextStyles` and new surfaces in `AppDecorations` (flutter-theme-design). No raw Material buttons or `InkWell` in features (`GestureDetector` with `Semantics` is the pattern Browse uses); no `Icon(color:)` (use `IconTheme`).
- Mode widgets never call a use case; they call the controller through callbacks from the screen (D4).
- Tests never read the wall clock (`libraryToday`); cards live in a sub-deck leaf.
- Goldens on Linux (`TZ=UTC`), Latin/Vietnamese text only.

## Review Focus

1. A second tap on a Guess option, or on a Match tile while a write runs or a turn is held, changes nothing and writes nothing (BR-STUDY-004, BR-STUDY-042) — pinned in Tasks 5 and 6.
2. The right option is found by card id even when two options read the same (BR-STUDY-041) — pinned in Task 5 (two cards with one meaning text are not possible on a board because the question needs five distinct meanings, so the test pins it at the widget level: the right option is the one whose id is the served card's).
3. A wrong pair stays pending, and its tiles go back to idle after the flash; the board never shows a wrong pair as matched (BR-STUDY-060, BR-STUDY-062) — pinned in Task 6.
4. The last pair of a board, answered right, leads to the next board or round with nothing selected (M1) — pinned in Task 6.
5. The review pick survives the entry's count updates, and falls back to the first available mode when the picked one stops being available (E1) — pinned in Task 4.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | 17, 18, entry caption, a11y labels |
| `lib/shared/widgets/mx_study_top_bar.dart` | modify | T1 |
| `lib/core/theme/mx_text_styles.dart`, `app_decorations.dart` | modify | option and tile type roles; the study choice surface |
| `lib/features/study/presentation/controllers/study_session_controller.dart`, `states/study_turn_state.dart` | modify | `answer(…, cardId:)` |
| `lib/features/study/presentation/controllers/review_mode_pick_controller.dart`, `states/study_entry_offer_state.dart`, `widgets/sections/study_entry_{review,footer,body}_widget.dart`, `screens/study_entry_screen.dart` | create/modify | E1 |
| `lib/features/study/presentation/widgets/support/study_choice_widget.dart` | create | the tappable toned surface both screens use |
| `lib/features/study/presentation/widgets/sections/study_guess_widget.dart`, `study_match_widget.dart` | create | 18, 17 |
| `lib/features/study/presentation/widgets/support/session_context_text_widget.dart` or a helper in the screen | create | the context line with round, pairs left, first pick |
| `lib/features/study/presentation/screens/study_session_screen.dart` | modify | the mode switch, holds, announcements |
| tests, goldens, companions, docs | create/modify | proofs and records |

---

### Task 1: Strings

**Files:** Modify `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (session keys after `studyGradeNextIn`, entry keys after `studyEntryStartFailedBody`), each with an `@key` description "Screen handoff 17|18|14 (FE-A6 P3): …".

| Key | English | Vietnamese | Placeholders |
|---|---|---|---|
| `studyContextRound` | `{context} · round {round}` | `{context} · vòng {round}` | context String, round int |
| `studyContextPairsLeft` | `{context} · {count, plural, =1{1 pair left} other{{count} pairs left}}` | `{context} · còn {count} cặp` | context String, count int |
| `studyContextFirstPick` | `{context} · first pick counts` | `{context} · chỉ tính lần chọn đầu` | context String |
| `studyGuessPrompt` | `What is this?` | `Đây là gì?` | |
| `studyGuessHintIdle` | `Only your first pick counts` | `Chỉ tính lần chọn đầu tiên` | |
| `studyGuessHintAnswered` | `Answer shown — the correct option is highlighted` | `Đã hiện đáp án — lựa chọn đúng được tô sáng` | |
| `studyGuessNext` | `Next` | `Tiếp` | |
| `studyGuessOption` | `Option {letter}: {meaning}` | `Lựa chọn {letter}: {meaning}` | letter String, meaning String |
| `studyGuessOptionRight` | `{option}, correct` | `{option}, đúng` | option String |
| `studyGuessOptionWrong` | `{option}, your pick, wrong` | `{option}, bạn chọn, sai` | option String |
| `studyGuessAnnounceRight` | `Correct` | `Đúng` | |
| `studyGuessAnnounceWrong` | `Wrong. The answer is {meaning}.` | `Sai. Đáp án là {meaning}.` | meaning String |
| `studyGuessBlockedTitle` | `This question can't be shown` | `Không hiển thị được câu hỏi này` | |
| `studyGuessBlockedBody` | `Its options could not be built. Close the session; every answer so far is kept.` | `Không dựng được các lựa chọn. Hãy đóng phiên; mọi câu đã trả lời vẫn được giữ.` | |
| `studyMatchHint` | `Tap a term, then its meaning to match` | `Chạm một thuật ngữ, rồi chạm nghĩa của nó để ghép` | |
| `studyMatchHintWrong` | `Not a match — this pair comes back next round` | `Không khớp — cặp này sẽ quay lại ở vòng sau` | |
| `studyMatchTerm` | `Term: {text}` | `Thuật ngữ: {text}` | text String |
| `studyMatchMeaning` | `Meaning: {text}` | `Nghĩa: {text}` | text String |
| `studyMatchTileSelected` | `{tile}, selected` | `{tile}, đang chọn` | tile String |
| `studyMatchTileMatched` | `{tile}, matched` | `{tile}, đã ghép` | tile String |
| `studyMatchAnnounceRight` | `Matched` | `Đã ghép đúng` | |
| `studyEntryModeCaption` | `{mode} · {count, plural, =1{1 due card} other{{count} due cards}} · oldest first` | `{mode} · {count} thẻ đến hạn · cũ nhất trước` | mode String, count int |

- [ ] **Step 1:** Add the keys with the P2 script pattern (insert after the anchors, en with `@` metadata, vi values only), then run `flutter gen-l10n` — Expected: no warnings; `studyContextPairsLeft(String context, int count)` generated.
- [ ] **Step 2:** Guard — Expected: clean. Commit — `feat(l10n): Guess, Match and review-pick strings (FE-A6 P3)`.

---

### Task 2: Top bar at large text (T1), and the study choice surface

Read `.claude/skills/flutter-theme-design/SKILL.md` first.

**Files:**
- Modify: `lib/shared/widgets/mx_study_top_bar.dart`, `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/app_decorations.dart`
- Test: `test/shared/widgets/mx_study_top_bar_test.dart`, `test/core/theme/app_decorations_study_choice_test.dart` (new), the text-style test file that holds the study roles (`test/core/theme/mx_text_styles_study_test.dart`)

**Interfaces — Produces:**
- `enum StudyChoiceTone { idle, selected, right, wrong }` (in `app_decorations.dart`).
- `AppDecorations.studyChoice(ColorScheme scheme, MxDerivedColors derived, StudyChoiceTone tone)` → `BoxDecoration` with radius `AppRadius.md`:
  - idle: `surfaceContainerLowest` with the ghost edge;
  - selected: a `primary` fill with a `primary` edge;
  - right: `successSoft` over the raised fill, with `successBorder`;
  - wrong: `dangerSoft` over the raised fill, with `dangerBorder`.
- `AppDecorations.studyChoiceInk(ColorScheme scheme, MxDerivedColors derived, StudyChoiceTone tone)` → `Color`: idle `onSurface`, selected `onPrimary`, right `successInk`, wrong `error`.
- `MxTextStyles.studyOption(Color ink)` 16/500, −0.1, 1.25; `studyOptionLetter(Color ink)` 12/700, height 1; `matchTerm(Color ink)` 18/700, −0.4, 1.25; `matchMeaning(Color ink)` 14/600, 1.25.

- [ ] **Step 1: Failing tests.**

```dart
// mx_study_top_bar_test.dart
testWidgets('at 2x text the mode chip ellipsizes and the track keeps 48 '
    '(owner ruling after P2)', (tester) async {
  await pumpMx(
    tester,
    MxStudyTopBar(
      modeLabel: 'Self-assess',
      current: 1,
      total: 2,
      counterLabel: '1 / 2',
      closeLabel: 'Close',
      onClose: () {},
    ),
    textScale: 2,
  );
  final track = find.descendant(
    of: find.byType(MxStudyTopBar),
    matching: find.byType(ClipRRect),
  );
  expect(tester.getSize(track).width, greaterThanOrEqualTo(48));
  expect(tester.takeException(), isNull);
});

// app_decorations_study_choice_test.dart
test('each study choice tone paints its ground, edge and ink (C1: success, '
    'never mastery)', () {
  final scheme = AppColorSchemes.light;
  final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
  final right = AppDecorations.studyChoice(scheme, derived, StudyChoiceTone.right);
  final wrong = AppDecorations.studyChoice(scheme, derived, StudyChoiceTone.wrong);
  final selected = AppDecorations.studyChoice(scheme, derived, StudyChoiceTone.selected);

  expect((right.border! as Border).top.color, derived.successBorder);
  expect((wrong.border! as Border).top.color, derived.dangerBorder);
  expect(selected.color, scheme.primary);
  expect(
    AppDecorations.studyChoiceInk(scheme, derived, StudyChoiceTone.right),
    derived.successInk,
  );
  expect(
    AppDecorations.studyChoiceInk(scheme, derived, StudyChoiceTone.right),
    isNot(MxSemanticColors.light.mastery),
  );
});
```

Also add one style test: `matchTerm(ink)` is 18/700 with −0.4 tracking and the given ink.

- [ ] **Step 2:** Run — Expected: the top bar test fails on the track width (or the overflow) and the others fail to compile.
- [ ] **Step 3: Implement.**
  - **Top bar:** wrap the `Row` in a `LayoutBuilder`. The badge `DecoratedBox` goes inside `ConstrainedBox(constraints: BoxConstraints(maxWidth: constraints.maxWidth * _badgeShare))`, with `_badgeShare = 0.4`. Its `Text` gets `maxLines: 1, overflow: TextOverflow.ellipsis`, and the badge style keeps line height 1.5 (UI-base §9 row 102: add `height` to `studyBadge` if it is not already 1.5). The track stays `Expanded`.
  - **Decorations:** add the enum and the two functions (the right and wrong grounds are `Color.alphaBlend(soft, raised.color!)`, as `dangerCard` does).
  - **Text roles:** add the four styles, following `statusNote(Color ink)`. If `mx_text_styles.dart` goes over 400 logical lines (the guard reports it), move the study roles (`studyTerm` … `matchMeaning`) into `part 'mx_text_styles_study.dart'` as an extension on `MxTextStyles`, and keep their names.
- [ ] **Step 4:** Run the tests, the shared goldens and `test/app` — Expected: pass. Regenerate the `mx_study_top_bar` golden only if one exists and the chip's line height changed, and look at it.
- [ ] **Step 5:** Commit — `feat(theme): study top bar keeps its track at large text; study choice surface (FE-A6 P3)`.

---

### Task 3: The controller answers any pending pair

**Files:** Modify `lib/features/study/presentation/controllers/study_session_controller.dart`, `lib/features/study/presentation/states/study_turn_state.dart`. Test: `test/features/study/presentation/study_session_controller_test.dart`.

**Interfaces — Produces:** `answer(StudyItem item, StudyAnswer answer, {bool shouldHoldFeedback = false, String? cardId})`, where `cardId` defaults to `item.cardId`. `PendingAnswer` gains `final String cardId`, so `retry` resends the same pair.

- [ ] **Step 1: Failing test.** Using `insertFiveDue` (an `eight_box` root "Korean" > Lesson, five due cards) and `studyEntryRepository(db, () => _now).openReviewSession(deckId: leaf.id, mode: StudyMode.match)`, read the board with `watchSessionOnce(db, id)`. Pick the board's **second** term (not the served item) and answer `MatchAnswer(thatTerm)` with `cardId: thatTerm`. Expect that tile to be `isMatched` in the next view, and the served item unchanged. A second test locks `sessions.isLocked = true`, answers a pair with `cardId: second`, unlocks, and runs `retry()`; the same second pair is then matched.
- [ ] **Step 2:** Run — Expected: compile failure (`cardId` is not a parameter).
- [ ] **Step 3:** Implement: pass `cardId: cardId ?? item.cardId` to the use case, and store it in `PendingAnswer(item, answer, shouldHoldFeedback:, cardId:)`; `retry` passes `cardId: pending.cardId`. Update the `PendingAnswer` constructor call sites.
- [ ] **Step 4:** Run the controller tests and `test/features/study` — Expected: pass.
- [ ] **Step 5:** Commit — `feat(study): a match answer names any pending pair of the board (BR-STUDY-049)`.

---

### Task 4: The review-mode pick (E1, C5)

**Files:**
- Create: `lib/features/study/presentation/controllers/review_mode_pick_controller.dart`
- Modify: `lib/features/study/presentation/states/study_entry_offer_state.dart`, `widgets/sections/study_entry_review_widget.dart`, `study_entry_footer_widget.dart`, `study_entry_body_widget.dart`, `screens/study_entry_screen.dart`
- Test: `test/features/study/presentation/study_entry_offer_state_test.dart`, `study_entry_actions_test.dart`

**Interfaces — Produces:**
- `@riverpod class ReviewModePickController` (autoDispose family on `deckId`): `StudyMode? build(String deckId) => null;` and `void pick(StudyMode mode) => state = mode;`.
- `studyEntryOfferOf(StudyEntry entry, {Set<StudyMode> built = builtStudyModes, StudyMode? picked})`: `reviewTarget` is the available option whose mode is `picked`, else the first available one (still requiring `cardCount > 0`), else null.
- `builtStudyModes = {browse, selfAssess, match, guess}`.

- [ ] **Step 1: Failing offer tests** (replace P2's "two available review modes give no single target", which E1 supersedes):

```dart
  test('with several modes available the first is the target until one is '
      'picked (E1)', () {
    final entry = _entry(
      reviews: [_mode(StudyMode.match), _mode(StudyMode.guess)],
    );

    expect(studyEntryOfferOf(entry).reviewTarget?.mode, StudyMode.match);
    expect(
      studyEntryOfferOf(entry, picked: StudyMode.guess).reviewTarget?.mode,
      StudyMode.guess,
    );
  });

  test('a picked mode that stops being available falls back to the first '
      'available one (E1)', () {
    final entry = _entry(
      reviews: [
        _mode(StudyMode.match),
        _mode(StudyMode.guess, reason: ModeUnavailableReason.tooFewMeanings),
      ],
    );

    expect(
      studyEntryOfferOf(entry, picked: StudyMode.guess).reviewTarget?.mode,
      StudyMode.match,
    );
  });
```

  And the widget tests in `study_entry_actions_test.dart`, over `insertFiveDue(env.db, env.decks)` (five due cards and five meanings, so Match and Guess both run; Recall and Fill are still "Coming soon"):
  - The Match row is selected; the footer reads `studyEntryReviewCta(5)` with the caption `studyEntryModeCaption('Match', 5)`.
  - Tapping the Guess row selects it and the caption follows; tapping the footer opens a Guess review (`current_mode = guess`) with no direction sheet.
  - While a start runs, the rows do not change the pick.
- [ ] **Step 2:** Run — Expected: FAIL.
- [ ] **Step 3: Implement.**
  - **Offer:** the fallback chain above.
  - **Review widget:** takes `ReviewModeOption? target`, `ValueChanged<StudyMode>? onPick`, `bool isLocked`. An available row is an `MxOptionRow` with `isSelected: review.option.mode == target?.mode` and `onSelected: isLocked ? null : () => onPick(mode)`. Unavailable and coming-soon rows keep `onSelected: null`.
  - **Body:** watches `reviewModePickControllerProvider(deckId)` and passes `picked` to `studyEntryOfferOf`, and `onPick` to the pick notifier's `pick`, through a method.
  - **Footer and screen:** read the same pick to compute the offer, so the footer and the list agree.
  - **Footer caption:** `target.isDirectionRequired` (sm2) keeps `studyEntryReviewCaption(shown, due)`; otherwise `studyEntryModeCaption(l10n.studyMode(target.mode), target.cardCount)`.
  - **Constant:** `builtStudyModes` gains `match` and `guess`, and its doc says P3.
- [ ] **Step 4:** Run `test/features/study` — Expected: pass. Regenerate `study_entry_eight_box_*` (the footer and the selection now show), and look at them against `img/14-study-entry/eightBox-light.png`.
- [ ] **Step 5:** Commit — `feat(study): the entry picks the eight_box review mode (FE-A6 P3, E1)`.

---

### Task 5: Screen 18, Guess (G1–G3, C1–C4, C6)

**Files:**
- Create: `lib/features/study/presentation/widgets/support/study_choice_widget.dart`, `widgets/sections/study_guess_widget.dart`
- Modify: `screens/study_session_screen.dart`
- Test: `test/features/study/presentation/study_guess_test.dart`, and a `openReview(env, StudyMode mode)` helper in `test/support/study_entry_fixtures.dart` (over `insertFiveDue`)

**Interfaces — Produces:**
- `StudyChoiceWidget({required StudyChoiceTone tone, required Widget Function(Color ink) builder, String? semanticsLabel, bool isSelected = false, bool isFaded = false, VoidCallback? onTap})`: a `DecoratedBox` built from `AppDecorations.studyChoice`, at least `AppSize.touchTarget` tall, with `Opacity(AppOpacity.disabled)` when faded. It is a `GestureDetector` wrapped in `Semantics(button: onTap != null, selected: isSelected, label: semanticsLabel, onTap: onTap, excludeSemantics: semanticsLabel != null)`.
- `StudyGuessWidget({required StudyItem item, required String? chosenCardId, required TurnResult? result, required bool isBusy, required ValueChanged<String> onPick, required VoidCallback onContinue, required VoidCallback onClose})`.
- In the screen:
  - `_pick(StudyItem item, String optionCardId)` answers `GuessAnswer(optionCardId)` with `shouldHoldFeedback: true`, and remembers `_chosenCardId` in the state class;
  - the hold is released by `onContinue`: after 1200 ms, on a tap, or by "Next" under TalkBack.

- [ ] **Step 1: Failing widget tests** (`libraryTest`, `pumpLibraryScreen(StudySessionScreen(...))`, a Guess review over `insertFiveDue`):
  1. The prompt shows the served term under "What is this?", and five options lettered A–E show their meanings.
  2. Tap the right option (the meaning of the served card, found with `watchSessionOnce`): after `pump()` the option's label reads `studyGuessOptionRight(...)`. `tester.takeAnnouncements()` holds `studyGuessAnnounceRight`. After `pump(Duration(milliseconds: 1200))` and `pumpAndSettle`, the next card is served.
  3. Tap a wrong option: the chosen option is labelled wrong and the right one right, and the other three are faded (their `Opacity` is `AppOpacity.disabled`). The announcement is `studyGuessAnnounceWrong(rightMeaning)`. A tap anywhere continues before 1200 ms.
  4. A second tap on another option while the turn is held writes nothing (one `review_log` row for the card).
  5. With `accessibleNavigation: true` in the `MediaQuery` (pump through a `MediaQuery` override with `data.copyWith(accessibleNavigation: true)`), nothing advances after 1200 ms; "Next" advances.
  6. **Blocked (C2):** make the served question blocked in the database the way `match_guess_turns_test.dart` blocks one (read that test for the SQL that empties the options). The notice shows `studyGuessBlockedTitle`, and its Close ends the session (the summary "You left early" follows).
  7. **At 2x text** no overflow is thrown, and each option is at least 48 tall.
- [ ] **Step 2:** Run — Expected: FAIL (Guess shows the not-built body).
- [ ] **Step 3: Implement.**
  - **`StudyChoiceWidget`:** as in Interfaces.
  - **`StudyGuessWidget`:**
    - The layout is a `CustomScrollView` with a `SliverFillRemaining(hasScrollBody: false)`. It holds a `Column`: an `Expanded` prompt face (`StudyFaceCardWidget(label: studyGuessPrompt)` with `studyTerm`), then the five options with `AppSpacing.control` between them.
    - Each option row is a `StudyChoiceWidget` holding: a 28-circle letter badge (`String.fromCharCode(0x41 + index)` in `studyOptionLetter(ink)`, a 1.5 `ink` border); the meaning in `studyOption(ink)` (it wraps and never ellipsizes); and a trailing `IconTheme` check or close when the option is right or wrong.
    - **Tones** once `result != null`: the option whose `cardId == item.cardId` is `right`; the chosen one, if different, is `wrong`; the rest are idle and faded. Before the answer, every option is idle and tappable unless `isBusy`.
    - Under the options sits `SessionFooterHintWidget`: the idle or answered hint. When answered and `MediaQuery.accessibleNavigationOf(context)`, a `MxButton(label: studyGuessNext, size: study)` is drawn above the hint.
    - **Blocked** (`item.guess!.isBlocked`): an `MxErrorState(title: studyGuessBlockedTitle, body: studyGuessBlockedBody, retryLabel: studySessionClose, onRetry: onClose)`. If `MxErrorState` needs an icon other than its retry glyph, use its own variant, as the summary's save error does.
  - **Screen:** `StudyMode.guess => StudyGuessWidget(...)`:
    - `chosenCardId: _chosenCardId`;
    - `result: turn.held?.result` when `turn.held?.item.cardId == item.cardId`;
    - `onPick: (id) => _pick(item, id)`;
    - `onContinue: _release`, which calls `_controller.release()` and clears `_chosenCardId`;
    - `onClose: _abandon`.
  - **The 1200 ms timer** is owned by `StudyGuessWidget`'s state. It starts when `result` goes from null to non-null and is cancelled on dispose; it is not started under `accessibleNavigation`.
  - **The announcement** is sent from that same transition: `SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context))`.
  - **The widget's key** is `ValueKey('guess#${item.cardId}#${item.round}')`.
- [ ] **Step 4:** Run the file and `test/features/study` — Expected: pass.
- [ ] **Step 5:** Commit — `feat(study): screen 18, Guess (FE-A6 P3)`.

---

### Task 6: Screen 17, Match (M1–M3, C1, C3, C4, C7, C8)

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/study_match_widget.dart`
- Modify: `screens/study_session_screen.dart`
- Test: `test/features/study/presentation/study_match_test.dart`

**Interfaces — Produces:** `StudyMatchWidget({required MatchBoard board, required TurnResult? result, required (String, String)? heldPair, required bool isBusy, required void Function(String termCardId, String meaningCardId) onPair, required VoidCallback onSettled})`. In the screen, `_pair(item, term, meaning)` answers `MatchAnswer(meaning)` with `cardId: term` and `shouldHoldFeedback: true`, and remembers `_heldPair = (term, meaning)`. `onSettled` releases the hold and clears `_heldPair`.

- [ ] **Step 1: Failing widget tests** (a Match review over `insertFiveDue`: one board of five pairs):
  1. The board shows the five terms in the left column and the five meanings in the right, in the stored order (`view.board`), and the hint is `studyMatchHint`.
  2. Tap a term, then its meaning: after `pumpAndSettle` both tiles are matched (labels `studyMatchTileMatched`), the announcement is `studyMatchAnnounceRight`, and the context line reads 4 pairs left.
  3. Tap a term, then another pair's meaning:
     - both tiles take the wrong tone and the hint reads `studyMatchHintWrong`;
     - after `pump(Duration(milliseconds: 600))` and `pumpAndSettle`, both are idle again and unmatched;
     - the announcement is `studyMatchHintWrong`, and one `review_log` row was written for the term.
  4. A meaning tapped with no term selected does nothing; tapping a second term re-selects.
  5. Tiles do nothing while held (a tap during the flash writes nothing).
  6. Matching all five pairs leads to the next stage or round, or the summary, with no tile selected.
  7. At 2x text there is no overflow and every tile is at least 48 tall.
  8. TalkBack order: the terms come before the meanings (use `tester.semantics` traversal, or compare `getSemantics` sort keys: each tile gets `OrdinalSortKey(column * 10 + row)`).
- [ ] **Step 2:** Run — Expected: FAIL.
- [ ] **Step 3: Implement.**
  - **`StudyMatchWidget`** is stateful and holds `_selectedTerm`.
  - **Layout:** a `CustomScrollView` with a `SliverFillRemaining(hasScrollBody: false)`, holding one row per index up to `max(terms, meanings)`. Each row is an `Expanded` `Row` of two `Expanded` tiles, with `AppSpacing.control` between rows and columns and the gutter padding outside.
  - **Tile:** a `StudyChoiceWidget`. Its tone:
    - `right` when `tile.isMatched`;
    - `wrong` when it is in `heldPair` and `result?.isCorrect == false`;
    - `selected` when it is the selected term;
    - else `idle`.

    The text is a term in `matchTerm(ink)` or a meaning in `matchMeaning(ink)`; a matched tile adds a leading check in an `IconTheme`.
  - **Tile label:** `studyMatchTerm/Meaning(text)`, wrapped by `studyMatchTileSelected` or `studyMatchTileMatched`; the sort key is as in test 8.
  - **Taps:**
    - a term that is not matched selects it, unless busy or held;
    - a meaning that is not matched, with a term selected, calls `onPair(term, meaning)` and clears the selection.
  - **On `result`:**
    - when it goes from null to correct, announce `studyMatchAnnounceRight` and call `onSettled` at once;
    - when it goes to wrong, announce `studyMatchHintWrong`, swap the hint, and start a 600 ms timer that calls `onSettled`.
  - **Key:** `ValueKey('match#${item.round}#${board.terms.first.cardId}')`, so a new board starts with nothing selected.
  - **Screen:**
    - `StudyMode.match => StudyMatchWidget(board: view.board!, …)`, drawn from `_lastOpenView` while held, as P1c does;
    - `result: turn.held?.result`;
    - `heldPair: _heldPair`;
    - `onPair: (term, meaning) => _pair(item, term, meaning)`;
    - `onSettled: _release`.
- [ ] **Step 4:** Run the file and `test/features/study` — Expected: pass.
- [ ] **Step 5:** Commit — `feat(study): screen 17, Match (FE-A6 P3)`.

---

### Task 7: The context line of round modes (M3)

**Files:** Modify `lib/features/study/presentation/screens/study_session_screen.dart` (or extract `_contextOf(view)` into `widgets/support/session_context_text_widget.dart` if the screen passes 400 logical lines). Test: extend `study_guess_test.dart` and `study_match_test.dart`.

- [ ] **Step 1: Failing tests:**
  - a Guess review reads `studyContextFirstPick(studyContextRound(studyContextReview('Lesson', 'Review', 'Guess'), 1))`;
  - a Match review reads `studyContextPairsLeft(studyContextRound(…'Match'…, 1), 5)`;
  - a Browse learning session is unchanged.
- [ ] **Step 2:** Run — Expected: FAIL.
- [ ] **Step 3:** Implement `String _contextOf(AppLocalizations l10n, StudySessionView view, String mode)`:
  - the base is the P2 learning or review line;
  - if `view.currentMode.handler.usesRounds`, wrap it in `studyContextRound(base, view.currentRound ?? 1)`;
  - then Guess adds `studyContextFirstPick`, and Match adds `studyContextPairsLeft(…, unmatchedTerms)`, where `unmatchedTerms` counts the board's terms that are not matched.
- [ ] **Step 4:** Run `test/features/study` — Expected: pass.
- [ ] **Step 5:** Commit — `feat(study): round and board in the session context line (FE-A6 P3)`.

---

### Task 8: Goldens and visual audit

- [ ] Session companion: add Guess answered (wrong pick) and Match with one pair matched and one term selected. Entry companion: `eight_box` with the pick. Run `flutter test test/visual_audit` — Expected: PASS.
- [ ] Goldens (both themes, `pumpLibraryGolden`, deck "Nhà hàng" with the Latin cards of `insertFiveDue` renamed to restaurant words):
  - `study_guess_idle`, `study_guess_wrong`, `study_guess_right`, `study_guess_large_text` (2x, answered), `study_guess_blocked`;
  - `study_match_board` (one pair matched, one term selected), `study_match_wrong` (inside the flash: after the answer, pump 100 ms), `study_match_large_text`;
  - `study_entry_eight_box` (regenerated).
- [ ] Run `TZ=UTC flutter test --tags golden --update-goldens test/features/study test/shared`, then without the flag, and look at every new PNG against `img/17-study-match/default-light.png`, `img/18-study-guess/default-light.png` and `img/14-study-entry/eightBox-light.png`.
- [ ] Commit — `test(study): Guess, Match and review-pick goldens and visual audit (FE-A6 P3)`.

---

### Task 9: Records

- [ ] `17-study-match.md` and `18-study-guess.md`: a "Built (FE-A6 P3)" note each; the deviations C1 (success, not mastery), C2 and C6 (Guess), C7 and C8 (Match); an `## Accessibility` section for each (C3, C4, C8).
- [ ] `14-study-entry.md`: the eightBox state is built with the pick; the C5 deviation (the first available mode, not Recall); the caption copy.
- [ ] `16-study-browse.md` § Shared: the top bar's chip cap (T1).
- [ ] Index rows 17 and 18 → `built (P3)`; WBS FE-A6 evidence adds this plan, and next reads "Phase P4: Recall 19, Fill 20"; spec §3 P3 row: the review-mode pick and T1.
- [ ] `python3 tools/docs/generate.py && python3 tools/docs/check.py` — Expected: 0 errors. `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh` — Expected: green.
- [ ] Commit — `docs(study): P3 records — handoffs 14, 17, 18, index, WBS (FE-A6)`.
