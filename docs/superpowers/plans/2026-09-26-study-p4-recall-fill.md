# Study P4 — Recall (19), Fill (20), `eight_box` end to end — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `eight_box` decks run end to end from the app: Learn (browse → match → guess → recall → fill) and all four review modes. Screens 19 and 20 are built, and the "built modes" set and its "Coming soon" branches are deleted.

**Architecture:** Two new mode bodies go in the session route's exhaustive switch. Both are presentational, and every write goes through the session controller (D4).

- **The controller** gains three commands, each over a new use-case provider: reveal a recall answer, save the recall time, show a fill hint.
- **Recall** runs its clock in the widget, on an `AnimationController`. It saves the time left on pause and on dispose, never per tick (D12). At zero it answers `timedOut` and holds the turn until Continue (D5).
- **Fill** answers with a hold. A right answer releases at once; a wrong one stays held until Continue.
- **The session screen** is split first, so it has room for the new modes.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, Drift (in-memory in tests), `flutter gen-l10n`.

**Spec:**
- [2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md): D4, D5, D12, D14, D19, §3.
- Roadmap and its rulings: [2026-09-26-study-chain-roadmap.md](2026-09-26-study-chain-roadmap.md) (R1–R3, F1–F4; approved by the owner).
- Screens:
  - [19-study-recall.md](../../shared/ui/screen-handoff/19-study-recall.md);
  - [20-study-fill.md](../../shared/ui/screen-handoff/20-study-fill.md);
  - [14-study-entry.md](../../shared/ui/screen-handoff/14-study-entry.md);
  - 16's [shared section](../../shared/ui/screen-handoff/16-study-browse.md#shared-by-the-session-screens).
- Pre-plan critique: `.impeccable/critique/2026-09-26T14-13-13Z__docs-shared-ui-screen-handoff-19-study-recall-md.md`.

**Rulings added by the pre-plan critique** (ledgered at Task 1; recorded in the handoffs at Task 9):

- **V1 (P0):** Fill's struck-through wrong answer uses the `error` ink, as Guess's wrong option does (`StudyChoiceTone.wrong`). The kit's `rating-again` token does not exist in V8.
- **V2:** the turn clock is a neutral signal: `onSurfaceVariant` fill on the progress track, and `warning` (fill) / `warningInk` (caption) only once timed out. Mastery stays on the top bar's accent alone (R3). This is a deviation on 19.
- **V3:** the 20-second clock is fixed by BR-STUDY-031. It weighs on TalkBack users, but changing it is a business rule change, **flagged to the owner in the final report, not made here**. The clock is one semantics node, its caption with "{n} seconds left" as its value. It is never announced per tick. A timeout is announced: "Time is up. Counted as forgot. The meaning is {meaning}."
- **V4 = F2:** Check is disabled while the trimmed answer is empty, through `MxButton`'s own disabled state.
- **V6:** with the keyboard open, the shell's Scaffold resizes the body above it, so the CTA row and footer stay visible; the faces scroll inside (D19).
- **V7:** the Fill field autofocuses. IME Done checks, and does nothing on an empty trimmed answer. A wrong answer drops focus and closes the keyboard.
- **V8 (not adopted):** no extra announcement when a turn resumes with little time left; the clock's value reads the seconds. Cost if wrong: a TalkBack user learns the time left only by reaching the clock.
- **V9:** under Remove animations the clock's fill steps once a second instead of draining, and faces swap with no fade. The time itself runs the same.
- **V10 = F3:** the wrong tag reads "Wrong · comes back next round", on the card as well as in copy.
- **R3, refined:** Recall and Fill pass `context.semanticColors.mastery` through `MxStudyTopBar.accent`. The slot exists for this, and the gallery already shows it; no new API.

## Global Constraints

- `study` imports only `study_mode`, `srs`, `settings`, `card`; `presentation/` never imports `data/`; `app/` composes.
- Presentation files end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
- Every user-facing string is an ARB key in `app_en.arb` and `app_vi.arb`, including semantics labels and announcements.
- No `ref.read` in a `build()` body; `if (!ref.mounted) return;` after every await in a controller.
- Booleans read as predicates (`is…`, `has…`, `can…`, `should…`); no source file over 400 physical lines (the guard caps logical lines at 500; the repo keeps 400).
- Styling and shared widgets:
  - Features pass no `TextStyle`, radius or padding to shared widgets, and never restyle text. New roles go in `MxTextStyles`; the field variant goes in `MxTextField` (flutter-theme-design).
  - No raw Material buttons or `InkWell` in features; no `Icon(color:)` (use `IconTheme`).
  - No literal `Duration` outside `const` declarations.
- Mode widgets never call a use case; they call the controller through callbacks from the screen (D4).
- The typed Fill answer lives only in widget state and the one `FillAnswer` sent; it is never persisted (BR-STUDY-027).
- Tests never read the wall clock (`libraryToday`); cards live in a sub-deck leaf.
- Goldens run on Linux (`TZ=UTC`), with Latin/Vietnamese text only. A Recall screen is never pumped with `pumpAndSettle`: its clock would run out.

## Review Focus

1. **The clock does not count background time** (BR-STUDY-036). It stops on any non-resumed lifecycle state, saves on `paused`, and resumes from where it stopped: without the stop, a resumed ticker jumps by the time spent away. Pinned in Task 6.
2. **The clock stops at once when Show the meaning is tapped,** so a timeout cannot fire behind a reveal in flight, and a second tap writes nothing. Pinned in Task 6.
3. **A Recall turn resumed after a reveal opens revealed,** with its clock stopped at the saved time and Forgot/Remembered offered (BR-STUDY-036, BR-STUDY-065). Pinned in Task 6.
4. **A right Fill answer shows no feedback frame and the next turn follows at once.** A wrong one is held, and its typed text is struck through beside the correct term (BR-STUDY-063, BR-STUDY-064). Pinned in Task 7.
5. **Show hint appears only for a card that has a hint and has not shown it** (BR-STUDY-028); a card without one has no button. Pinned in Task 7.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/study/presentation/states/session_context_state.dart` | create | the context line (from the screen) |
| `lib/features/study/presentation/widgets/sections/study_session_error_widget.dart` | create | E5 page and the loading page (from the screen) |
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | 19, 20 strings; the coming-soon keys removed (Task 8) |
| `lib/core/theme/mx_text_styles.dart` | modify | `studyPassage`, `fillAnswer(ink, isStruck)` |
| `lib/shared/widgets/mx_text_field.dart` | modify | `MxTextFieldVariant.study` (F1) |
| `lib/features/study/presentation/providers/{reveal_recall_answer,save_recall_time,show_fill_hint}_use_case_provider.dart` | create | use-case providers |
| `lib/features/study/presentation/controllers/study_session_controller.dart` | modify | `revealRecall`, `saveRecallTime`, `showFillHint` |
| `lib/features/study/presentation/widgets/support/study_appearing_widget.dart` | create | hidden bar → content (from 16a) |
| `lib/features/study/presentation/widgets/support/study_cta_row_widget.dart` | create | kit StudyCtaRow |
| `lib/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart` | create | the turn clock |
| `lib/features/study/presentation/widgets/sections/study_recall_widget.dart` | create | 19 |
| `lib/features/study/presentation/widgets/sections/study_fill_widget.dart` | create | 20 |
| `lib/features/study/presentation/screens/study_session_screen.dart` | modify | the mode switch, holds, accent |
| `lib/features/study/presentation/states/study_entry_offer_state.dart` and entry widgets | modify | `builtStudyModes` and "Coming soon" removed |
| `lib/features/study/presentation/widgets/sections/study_mode_not_built_widget.dart` | delete | |
| tests, goldens, companions, docs | create/modify | proofs and records |

---

### Task 1: Split the session screen

Pure refactor; no behaviour change. First ledger the V-rulings above as `Task 1: Ruling: pre-plan critique V1–V10 and R3 refined, as the plan's header states — cost if wrong: see each`.

**Files:** Create `states/session_context_state.dart`, `widgets/sections/study_session_error_widget.dart`; modify `screens/study_session_screen.dart`.

**Interfaces — Produces:**
- `String sessionContextOf(AppLocalizations l10n, StudySessionView view, String mode)`: the body of today's `_contextOf`, unchanged.
- `StudySessionErrorWidget({required VoidCallback onClose, required VoidCallback onRetry})`: today's `_errorPage`.
- `StudySessionLoadingWidget()`: today's `_LoadingPage`.

- [ ] **Step 1:** Move the code; the screen calls the three. Run `flutter test test/features/study test/visual_audit` — Expected: all pass, unchanged count.
- [ ] **Step 2:** Guard — Expected: clean. Commit: `refactor(study): split the session screen's context line and fallback pages out (FE-A6 P4)`.

---

### Task 2: Strings

**Files:** Modify `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`. Put the session keys after `studyMatchAnnounceRight`, each with `@key` description "Screen handoff 19|20 (FE-A6 P4): …".

| Key | English | Vietnamese | Placeholders |
|---|---|---|---|
| `studyRecallCaptionCounting` | `Time to recall` | `Thời gian nhớ lại` | |
| `studyRecallCaptionRevealed` | `Revealed with time left` | `Đã mở khi còn thời gian` | |
| `studyRecallCaptionTimedOut` | `Time is up` | `Hết giờ` | |
| `studyRecallClock` | `{seconds}s / {total}s` | `{seconds}s / {total}s` | seconds int, total int |
| `studyRecallClockValue` | `{seconds, plural, =1{1 second left} other{{seconds} seconds left}}` | `còn {seconds} giây` | seconds int |
| `studyRecallShowMeaning` | `Show the meaning` | `Hiện nghĩa` | |
| `studyRecallForgot` | `Forgot` | `Quên` | |
| `studyRecallRemembered` | `Remembered` | `Nhớ` | |
| `studyContinue` | `Continue` | `Tiếp tục` | |
| `studyRecallTagTimedOut` | `Counted as forgot` | `Tính là quên` | |
| `studyRecallHintCounting` | `Recall the meaning before the time runs out` | `Nhớ lại nghĩa trước khi hết giờ` | |
| `studyRecallHintRevealed` | `Be honest — the next card follows automatically` | `Hãy trung thực — thẻ tiếp theo sẽ tự hiện` | |
| `studyRecallHintTimedOut` | `This card comes back in a later round` | `Thẻ này sẽ quay lại ở vòng sau` | |
| `studyRecallAnnounceTimedOut` | `Time is up. Counted as forgot. The meaning is {meaning}.` | `Hết giờ. Tính là quên. Nghĩa là {meaning}.` | meaning String |
| `studyFillField` | `Your answer` | `Câu trả lời của bạn` | |
| `studyFillShowHint` | `Show hint` | `Xem gợi ý` | |
| `studyFillCheck` | `Check` | `Kiểm tra` | |
| `studyFillHintRow` | `Hint: {hint}` | `Gợi ý: {hint}` | hint String |
| `studyFillTagWrong` | `Wrong · comes back next round` | `Sai · quay lại ở vòng sau` | |
| `studyFillTyped` | `You typed {typed}` | `Bạn đã nhập {typed}` | typed String |
| `studyFillHintInput` | `Type the term for this meaning, then check` | `Nhập thuật ngữ cho nghĩa này rồi kiểm tra` | |
| `studyFillHintUsed` | `Using the hint is noted; it changes nothing` | `Việc xem gợi ý được ghi lại, không ảnh hưởng kết quả` | |
| `studyFillHintWrong` | `Case and spaces are ignored, accents are not` | `Không phân biệt hoa thường và khoảng trắng, nhưng phân biệt dấu` | |
| `studyFillAnnounceWrong` | `Wrong. The answer is {term}.` | `Sai. Đáp án là {term}.` | term String |

- [ ] **Step 1:** Add the keys (en with `@` metadata, vi values only), then run `flutter gen-l10n`. Expected: no warnings.
- [ ] **Step 2:** Commit: `feat(l10n): Recall and Fill strings (FE-A6 P4)`.

---

### Task 3: Text roles and the study field (F1)

Read `.claude/skills/flutter-theme-design/SKILL.md` first.

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/shared/widgets/mx_text_field.dart`.
- Test: `test/core/theme/mx_text_styles_study_test.dart`, `test/shared/widgets/mx_text_field_test.dart`.

**Interfaces — Produces:**
- `MxTextStyles.studyPassage`: 16/400 at 1.55, `onSurface`. Used for Recall's meaning and Fill's prompt (the kit sets 16 on Recall and 14 on Fill; one role, ruled at 16 for legibility).
- `MxTextStyles.fillAnswer(Color ink, {required bool isStruck})`: 24/700, −0.3 tracking, in `ink`. When `isStruck`, it adds a line-through in `ink`, 1 thick.
- `MxTextFieldVariant.study`: a bare field (kit Fill answer).
  - No fill, no edge in any state, zero content padding, centred text.
  - The value is `studyTerm`; there is no hint text.
  - One line: `TextInputType.text`, `maxLines: 1`.

- [ ] **Step 1: Failing tests.**

```dart
// mx_text_styles_study_test.dart (add)
test('the study passage and the fill answer roles (FE-A6 P4)', () {
  final styles = MxTextStyles.of(AppTheme.light());  // same accessor the file's other tests use
  expect(styles.studyPassage.fontSize, 16);
  expect(styles.studyPassage.height, 1.55);
  final struck = styles.fillAnswer(Colors.red, isStruck: true);
  expect(struck.fontSize, 24);
  expect(struck.fontWeight, FontWeight.w700);
  expect(struck.decoration, TextDecoration.lineThrough);
  expect(styles.fillAnswer(Colors.red, isStruck: false).decoration, isNot(TextDecoration.lineThrough));
});

// mx_text_field_test.dart (add)
testWidgets('the study variant is bare: no fill, no edge, centred, one line (F1)', (tester) async {
  await pumpMx(tester, const MxTextField(variant: MxTextFieldVariant.study, label: 'Answer'));
  final field = tester.widget<TextField>(find.byType(TextField));
  expect(field.decoration!.filled, isFalse);
  expect(field.decoration!.border, InputBorder.none);
  expect(field.decoration!.focusedBorder, InputBorder.none);
  expect(field.textAlign, TextAlign.center);
  expect(field.maxLines, 1);
});
```

(Use the accessor and pump helper those files already use.)

- [ ] **Step 2:** Run the two tests. Expected: FAIL (`studyPassage` not defined; `study` not a variant).
- [ ] **Step 3:** Implement.
  - Add the roles, with named constants for 1.55, 24 and −0.3.
  - Add the variant to the geometry switch: floor `AppSize.touchTarget`, horizontal 0, vertical 0, radius `AppRadius.md`, not multiline.
  - In `_field`:
    - the study variant sets `filled: false`, `border`/`enabledBorder`/`focusedBorder`/`disabledBorder: InputBorder.none` and `contentPadding: EdgeInsets.zero`;
    - it passes `textAlign: TextAlign.center` (other variants keep start);
    - `_valueStyle` returns `studyTerm`.
- [ ] **Step 4:** Run both test files and `test/shared/widgets/shared_widgets_golden_test.dart --tags golden`. Expected: PASS, no golden moved.
- [ ] **Step 5:** Commit: `feat(theme): study passage and fill answer roles; MxTextField study variant (FE-A6 P4 F1)`.

---

### Task 4: Controller commands (R1)

**Files:**
- Create: `presentation/providers/reveal_recall_answer_use_case_provider.dart`, `save_recall_time_use_case_provider.dart`, `show_fill_hint_use_case_provider.dart`, each in the `abandon_study_session_use_case_provider.dart` pattern.
- Modify: `controllers/study_session_controller.dart`.
- Test: `test/features/study/presentation/study_session_controller_test.dart`.

**Interfaces — Produces:**
- `Future<void> revealRecall(StudyItem item, int remainingMs)`: a busy-guarded write, like `answer`. The stream shows the result. A refusal, a busy database or any failure leaves the turn as it was (`StudyTurnState()`), and the button can be tapped again.
- `Future<void> saveRecallTime(StudyItem item, int remainingMs)`: not busy-guarded and not busy-setting, since it runs in the background. It is skipped while a write runs. Failures are swallowed: the next save or the turn's answer supersedes it.
- `Future<void> showFillHint(StudyItem item)`: busy-guarded, like `revealRecall`.
- All three clamp `remainingMs` to `0..recallTurnMs` before calling the use case, whose range check throws.

- [ ] **Step 1: Failing tests** (in the file's setUp harness; use `openReview(…, StudyMode.recall)` / `StudyMode.fill` on `insertFiveDue` cards, as `openFiveDueReview` does).

```dart
test('revealing a recall answer stops its time and shows it revealed (R1, BR-STUDY-065)', () async {
  final id = await recallReview();                 // helper: insertFiveDue + open recall review
  final item = (await served(id)).currentItem!;
  await controller(id).revealRecall(item, 12000);
  final after = (await served(id)).currentItem!;
  expect(after.isRevealed, isTrue);
  expect(after.remainingMs, 12000);
  expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
});

test('saving recall time keeps the smaller time and never marks the controller busy (D12)', () async {
  final id = await recallReview();
  final item = (await served(id)).currentItem!;
  final saving = controller(id).saveRecallTime(item, 15000);
  expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
  await saving;
  expect((await served(id)).currentItem!.remainingMs, 15000);
});

test('a time outside 0..20000 is clamped, not thrown (R1)', () async {
  final id = await recallReview();
  final item = (await served(id)).currentItem!;
  await controller(id).saveRecallTime(item, -5);
  expect((await served(id)).currentItem!.remainingMs, 0);
});

test('showing a fill hint marks it shown (BR-STUDY-028)', () async {
  final id = await fillReview();
  final item = (await served(id)).currentItem!;
  await controller(id).showFillHint(item);
  expect((await served(id)).currentItem!.isHintShown, isTrue);
});

test('a reveal while a write runs is dropped (BR-STUDY-004)', () async {
  // As the existing "a second command while a write runs is dropped" test:
  // gate the repository, start answer(), then revealRecall() → no reveal.
});
```

- [ ] **Step 2:** Run them. Expected: FAIL (methods not defined).
- [ ] **Step 3:** Implement the providers (`dart run build_runner build --delete-conflicting-outputs`) and the three methods.
- [ ] **Step 4:** Run `flutter test test/features/study/presentation/study_session_controller_test.dart`. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(study): the session controller reveals, saves recall time and shows a fill hint (FE-A6 P4 R1)`.

---

### Task 5: Study support widgets

**Files:**
- Create:
  - `widgets/support/study_appearing_widget.dart`: `StudyAppearingWidget({required bool isShown, required Widget child})`, which moves 16a's `_Appearing` and `_HiddenBar` here unchanged;
  - `widgets/support/study_cta_row_widget.dart`;
  - `widgets/support/recall_countdown_bar_widget.dart`.
- Modify: `widgets/sections/study_self_assess_widget.dart`, which uses `StudyAppearingWidget`.
- Test: `test/features/study/presentation/study_support_widgets_test.dart` (new).

**Interfaces — Produces:**
- `StudyCtaRowWidget({required List<Widget> children})` (kit StudyCtaRow):
  - a centred row, padded `gutter` on the sides and `gutter` on top;
  - two children each take `Expanded` capped at 160 wide;
  - one child keeps its own width;
  - at text scale ≥ 1.3 they stack full width, as `StudyGradeRowWidget` does.
- `RecallCountdownBarWidget({required String caption, required int remainingMs, required bool isTimedOut})`:
  - a caption row: the caption on the left, `studyRecallClock(seconds, 20)` on the right, both `statusLabel(ink)`;
  - a 6-tall rounded track (`MasteryRamp.track`) with a fill of `remainingMs / recallTurnMs`;
  - ink is `onSurfaceVariant`, or `warningInk` once timed out;
  - fill is `onSurfaceVariant`, or `semanticColors.warning` once timed out (V2);
  - seconds are `(remainingMs / 1000).ceil()`;
  - under Remove animations the fill uses `seconds * 1000 / recallTurnMs` (V9);
  - one `Semantics(container: true, label: caption, value: studyRecallClockValue(seconds), excludeSemantics: true)` (V3/V5).

- [ ] **Step 1: Failing tests.**

```dart
testWidgets('the clock reads its caption and seconds left as one node, and the fill is the time left (V3, V5)', (tester) async {
  await pumpMx(tester, const RecallCountdownBarWidget(caption: 'Time to recall', remainingMs: 13400, isTimedOut: false));
  expect(find.text('14s / 20s'), findsOneWidget);
  final node = tester.getSemantics(find.byType(RecallCountdownBarWidget));
  expect(node.label, 'Time to recall');
  expect(node.value, '14 seconds left');
  final fill = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
  expect(fill.widthFactor, closeTo(13400 / 20000, 1e-9));
});

testWidgets('under Remove animations the fill steps by whole seconds (V9)', (tester) async {
  await pumpMx(tester, const RecallCountdownBarWidget(caption: 'c', remainingMs: 13400, isTimedOut: false), disableAnimations: true);
  final fill = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
  expect(fill.widthFactor, 14000 / 20000);
});

testWidgets('two CTAs share the row; at 1.3x they stack', (tester) async { /* two MxButtons: same y at 1x, different y at 1.3x */ });
```

(Use the pump helper the shared widget tests use; if it has no `disableAnimations`, wrap in `MediaQuery(data: …copyWith(disableAnimations: true))`.)

- [ ] **Step 2:** Run. Expected: FAIL (types not defined).
- [ ] **Step 3:** Implement. Then run `flutter test test/features/study` (16a still passes with the moved widget).
- [ ] **Step 4:** Commit: `feat(study): CTA row, turn clock, and the shared hidden-face reveal (FE-A6 P4)`.

---

### Task 6: Recall 19 (R1–R3)

**Files:**
- Create: `widgets/sections/study_recall_widget.dart`.
- Modify: `screens/study_session_screen.dart` (the recall branch; `accent: mastery` for recall and fill; the reveal, save-time and timeout callbacks).
- Test: `test/features/study/presentation/study_recall_test.dart` (new).

**Interfaces:**
- Consumes: `revealRecall`, `saveRecallTime`, `answer(…, shouldHoldFeedback: true)`, `release`, `StudyAppearingWidget`, `StudyCtaRowWidget`, `RecallCountdownBarWidget`, `studyPassage`.
- Produces: `StudyRecallWidget({required StudyItem item, required TurnResult? result, required bool isBusy, required ValueChanged<int> onReveal, required ValueChanged<int> onSaveTime, required ValueChanged<RecallOutcome> onAnswer, required VoidCallback onTimeUp, required VoidCallback onContinue})`.
  - The screen keys it `'recall#${item.cardId}#${item.answersInSession}'`.
  - `onTimeUp` answers `RecallAnswer(timedOut)` with a hold.
  - `onAnswer` answers `RecallAnswer(outcome)` with no hold.

**Behaviour:**
- **The clock** is an `AnimationController(duration: recallTurnMs ms)` with `value = remaining / recallTurnMs`, where `remaining = item.remainingMs ?? recallTurnMs`.
  - It starts with `reverse()` when the item is neither revealed nor answered. At `dismissed` it calls `onTimeUp` once.
  - `remainingMs` is `(value * recallTurnMs).round()`.
- **Lifecycle:** an `AppLifecycleListener(onStateChange:)`. On any state other than `resumed` it stops the clock, and on `paused` it also calls `onSaveTime(remaining)`. On `resumed` it calls `reverse()` again if the clock is still running.
- **dispose:** if the clock is still running (not revealed, timed out or answered), it calls `onSaveTime(remaining)`, then disposes the controller and the listener.
- **Show the meaning:**
  - stops the clock at once and calls `onReveal(remaining)`;
  - the widget shows revealed only when `item.isRevealed` (after commit);
  - while `isBusy` the button is disabled.
- **States:**
  - timedOut: `result != null`, or the clock reached 0 and the answer is in flight (`isBusy`); Continue waits for `result`;
  - revealed: `item.isRevealed`;
  - otherwise countingDown.
- **Faces:**
  - the term face (`studyBrowseTerm`): `StudyWholeWordTextWidget(item.front, style: studyTerm)`;
  - the answer face (`isAnswer`, label `studyBrowseMeaning`): `StudyAppearingWidget(isShown: revealed || timedOut, child: Text(item.back, studyPassage))`, with the `studyRecallTagTimedOut` tag below it in `statusLabel(warningInk)`, upper-cased, when timed out.
- **CTA and hint by state:**

  | State | CTA | Footer hint (`AppIcons.check`) |
  |---|---|---|
  | countingDown | one `MxButton(studyRecallShowMeaning, size: study)` | `studyRecallHintCounting` |
  | revealed | Forgot (`tone: outline`) and Remembered (primary) | `studyRecallHintRevealed` |
  | timedOut | Continue | `studyRecallHintTimedOut` |

- **Announcements:** when `result` first arrives, announce `studyRecallAnnounceTimedOut(item.back)`.
- **Screen:**
  - recall and fill pass `accent: context.semanticColors.mastery` to `MxStudyTopBar` (R3);
  - `result` is `turn.held?.item.cardId == item.cardId ? turn.held?.result : null`.

- [ ] **Step 1: Failing tests** (`openFiveDueReview(…, StudyMode.recall)`; `pumpLibraryScreen`; never `pumpAndSettle`).

```dart
libraryTest('the term shows, the meaning is hidden, and the clock counts down from 20 (19 countingDown)', …
  expect(find.text('term 1'), findsOneWidget);
  expect(find.text('apple'), findsNothing);
  expect(find.text('20s / 20s'), findsOneWidget);
  await tester.pump(const Duration(seconds: 6));
  expect(find.text('14s / 20s'), findsOneWidget);
  expect(find.text(_en.studyRecallHintCounting), findsOneWidget);

libraryTest('Show the meaning reveals with time left and stops the clock; Remembered moves on at once (R2, BR-STUDY-065)', …
  await tester.pump(const Duration(seconds: 5));
  await tester.tap(find.text(_en.studyRecallShowMeaning)); await tester.pump(); await tester.pump();
  expect(find.text('apple'), findsOneWidget);
  expect(find.text(_en.studyRecallCaptionRevealed), findsOneWidget);
  await tester.pump(const Duration(seconds: 30));        // no timeout after a reveal
  expect(find.text('15s / 20s'), findsOneWidget);
  expect(await revealedTimeOf(env.db, id), 15000);     // SQL on the queue row
  await tester.tap(find.text(_en.studyRecallRemembered)); await tester.pump(); await tester.pump();
  expect(find.text('term 2'), findsOneWidget);          // no hold

libraryTest('Forgot records a wrong answer and moves on', … outcomeOf(first turn) == wrong

libraryTest('at zero the turn counts as forgot, is announced, and waits for Continue (R2, BR-STUDY-033, BR-STUDY-066)', …
  tester.ensureSemantics();
  await tester.pump(const Duration(seconds: 20)); await tester.pump(); await tester.pump();
  expect(find.text(_en.studyRecallCaptionTimedOut), findsOneWidget);
  expect(find.text(_en.studyRecallTagTimedOut.toUpperCase()), findsOneWidget);
  expect(find.text('apple'), findsOneWidget);
  expect(tester.takeAnnouncements().map((a) => a.message), contains(_en.studyRecallAnnounceTimedOut('apple')));
  await tester.pump(const Duration(seconds: 10));
  expect(find.text('term 1'), findsOneWidget);          // held
  await tester.tap(find.text(_en.studyContinue)); await tester.pump(); await tester.pump();
  expect(find.text('term 2'), findsOneWidget);

libraryTest('the clock stops in the background and saves its time; it resumes where it stopped (D12, BR-STUDY-036)', …
  await tester.pump(const Duration(seconds: 4));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump(); await tester.pump();
  expect(await savedTimeOf(env.db, id), 16000);
  await tester.pump(const Duration(seconds: 60));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump(); await tester.pump(const Duration(seconds: 1));
  expect(find.text('15s / 20s'), findsOneWidget);

libraryTest('a turn resumed with saved time starts from it', … UPDATE the queue row's remaining time to 7000 via SQL before pumping → '7s / 20s'

libraryTest('a turn resumed after a reveal opens revealed, clock stopped, and asks Forgot or Remembered (BR-STUDY-036)', … reveal through the repository first (sessions.revealRecallAnswer(remainingMs: 9000)) → '9s / 20s', 'apple', Forgot and Remembered shown; pump 30 s → still no timeout

libraryTest('closing the screen mid-turn saves the time left (D12)', … pump 3 s, pumpWidget(SizedBox) → savedTimeOf == 17000

libraryTest('the top bar carries the mastery accent (R3)', … tester.widget<MxStudyTopBar>(…).accent == semantic mastery

libraryTest('at twice the text size nothing overflows (C4)', … textScale: 2; takeException isNull; reveal and check again
```

(`revealedTimeOf` and `savedTimeOf` read the served queue row's remaining-time column. Use the column name `study_queue_row` / `remaining_ms` as the Drift table declares it; check `lib/core/database/`.)

- [ ] **Step 2:** Run. Expected: FAIL (`StudyModeNotBuiltWidget` is shown for recall).
- [ ] **Step 3:** Implement the widget and the screen branch.
- [ ] **Step 4:** Run `flutter test test/features/study`. Expected: PASS, except the P1c test that expects `StudyModeNotBuiltWidget` for Recall. Rewrite that test to "past Match and Guess, Recall's clock shows" and ledger it.
- [ ] **Step 5:** Commit: `feat(study): screen 19, Recall (FE-A6 P4)`.

---

### Task 7: Fill 20 (F1–F4)

**Files:**
- Create: `widgets/sections/study_fill_widget.dart`.
- Modify: `screens/study_session_screen.dart`.
- Test: `test/features/study/presentation/study_fill_test.dart` (new).

**Interfaces — Produces:** `StudyFillWidget({required StudyItem item, required TurnResult? result, required bool isBusy, required ValueChanged<String> onCheck, required VoidCallback onShowHint, required VoidCallback onContinue})`.
- The screen keys it `'fill#${item.cardId}#${item.answersInSession}'`.
- `onCheck` answers `FillAnswer(typed)` with a hold. `onShowHint` calls `showFillHint`.

**Behaviour:**
- **The field:** a local `TextEditingController` and a `FocusNode`, disposed with the widget.
- **The prompt face** (`studyBrowseMeaning`): `Text(item.back, studyPassage)`.
- **The answer face** (`isAnswer`, `studyBrowseTerm`):
  - input:
    - the hint row, when `item.isHintShown && item.hint != null`: `IconTheme(onSurfaceVariant, xs)` with `AppIcons.hint` and `Text(hint, sessionHint)`, one node `studyFillHintRow(hint)`;
    - below it, `MxTextField(variant: study, label: studyFillField, autofocus via focusNode.requestFocus post-frame, textInputAction: done, onSubmitted: _check)`;
  - wrong:
    - the typed text in `fillAnswer(error, isStruck: true)`, with semantics `studyFillTyped(typed)`;
    - `item.front` in `fillAnswer(onSurface, isStruck: false)`;
    - `studyFillTagWrong` in `statusLabel(warningInk)`, upper-cased.
- **Check:**
  - enabled only when `trim().isNotEmpty && !isBusy && result == null`;
  - Done with an empty trimmed answer does nothing (V7);
  - `_check` stores `_typed = controller.text` and calls `onCheck(_typed)`.
- **Results:**
  - `result?.isCorrect == true`: `addPostFrameCallback(onContinue)`, so the next turn follows with no feedback frame (F3);
  - wrong: unfocus, announce `studyFillAnnounceWrong(item.front)`, and hold for Continue.
- **CTA and hint by state:**

  | State | CTA | Footer hint (`AppIcons.edit`) |
  |---|---|---|
  | input | "Show hint" (`tone: outline`, `icon: AppIcons.hint`) when `item.hint != null && !item.isHintShown`, and Check | `studyFillHintInput` |
  | hint | Check | `studyFillHintUsed` |
  | wrong | Continue | `studyFillHintWrong` |

- [ ] **Step 1: Failing tests** (`openFiveDueReview(…, StudyMode.fill)`; card 1 has back 'apple', front 'term 1', hint 'hint 1').

```dart
libraryTest('the meaning asks, the field takes the term, and Check waits for text (20 input, F2)', …
  expect(find.text('apple'), findsOneWidget);
  expect(button(_en.studyFillCheck).onPressed, isNull);
  await tester.enterText(find.byType(TextField), '   ');
  await tester.pump();
  expect(button(_en.studyFillCheck).onPressed, isNull);
  await tester.testTextInput.receiveAction(TextInputAction.done); await tester.pump();
  expect(await turnsOf(env.db, id), isEmpty);

libraryTest('a right answer moves on at once, with no feedback frame (F3, BR-STUDY-064)', …
  await tester.enterText(find.byType(TextField), ' Term 1 ');   // case and outer spaces ignored
  await tester.tap(find.text(_en.studyFillCheck)); await tester.pump(); await tester.pump(); await tester.pump();
  expect(find.text('banana'), findsOneWidget);                   // next card's meaning
  expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsNothing);

libraryTest('IME Done checks (F2)', … enterText 'term 1'; receiveAction(done) → next card

libraryTest('a wrong answer is struck through beside the right term, announced, and waits for Continue (F3, BR-STUDY-059)', …
  tester.ensureSemantics();
  await tester.enterText(find.byType(TextField), 'term 9');
  await tester.tap(find.text(_en.studyFillCheck)); await tester.pump(); await tester.pump();
  final struck = tester.widget<Text>(find.text('term 9'));
  expect(struck.style!.decoration, TextDecoration.lineThrough);
  expect(find.text('term 1'), findsOneWidget);
  expect(find.text(_en.studyFillTagWrong.toUpperCase()), findsOneWidget);
  expect(find.byType(TextField), findsNothing);
  expect(tester.takeAnnouncements().map((a) => a.message), contains(_en.studyFillAnnounceWrong('term 1')));
  await tester.tap(find.text(_en.studyContinue)); await tester.pump(); await tester.pump();
  expect(find.text('banana'), findsOneWidget);

libraryTest('accents count: "term 1" does not match "tèrm 1" (BR-STUDY-026)', … wrong state

libraryTest('Show hint shows the card's hint once and keeps what was typed (F4, BR-STUDY-028)', …
  await tester.enterText(find.byType(TextField), 'ter');
  await tester.tap(find.text(_en.studyFillShowHint)); await tester.pump(); await tester.pump();
  expect(find.text('hint 1'), findsOneWidget);
  expect(find.text(_en.studyFillShowHint), findsNothing);
  expect(find.text(_en.studyFillHintUsed), findsOneWidget);
  expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'ter');

libraryTest('a card with no hint offers no Show hint (F4)', … UPDATE card SET hint = NULL WHERE id = 'ST-01' → findsNothing

libraryTest('the top bar carries the mastery accent (R3)', …
libraryTest('at twice the text size with a long meaning nothing overflows (C4, V6)', … UPDATE card SET back = <200-char meaning> → no exception; Check reachable (hitTestable)
```

- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `flutter test test/features/study`. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(study): screen 20, Fill (FE-A6 P4)`.

---

### Task 8: Every mode is built: the set and "Coming soon" go (spec §3)

**Files:**
- Modify: `states/study_entry_offer_state.dart`, `widgets/sections/study_entry_review_widget.dart`, `study_entry_learn_widget.dart`, `screens/study_session_screen.dart`, `lib/l10n/app_{en,vi}.arb`.
- Delete: `widgets/sections/study_mode_not_built_widget.dart`.
- Tests:
  - `test/features/study/presentation/study_entry_offer_state_test.dart`;
  - `study_session_screen_test.dart`;
  - entry tests that assert "Coming soon";
  - entry goldens (eight_box now offers Learn).

**Interfaces — Produces:**
- `studyEntryOfferOf(StudyEntry entry, {StudyMode? picked})`.
- `ReviewOfferStatus { available, unavailable }`.
- `StudyEntryOffer` loses `isLearnComingSoon`; `canLearn` becomes `hasNew`; `canContinue` becomes `resumable != null`.
- `studyComingSoon`, `studyModeNotBuiltTitle` and `studyModeNotBuiltBody` are removed from both ARB files.

- [ ] **Step 1: Failing test.**

```dart
test('eight_box offers Learn now that every stage is built (P4, BR-MODE-004)', () {
  final offer = studyEntryOfferOf(_entry(reviews: [_mode(StudyMode.recall)]));
  expect(offer.canLearn, isTrue);
  expect(offer.reviewTarget?.mode, StudyMode.recall);
});
```

- [ ] **Step 2:** Run. Expected: FAIL (`canLearn` false: recall and fill are not in the set).
- [ ] **Step 3:** Remove the set, the `built` parameter, `comingSoon`, `isLearnComingSoon` and the not-built widget with its keys.
  - Rewrite the offer tests that pass `built:`. Their subject ("nothing built" and "only when every stage is built") no longer exists: ledger each rewrite or removal.
  - Grep `test/` for `studyComingSoon`, `isLearnComingSoon`, `builtStudyModes` and `StudyModeNotBuiltWidget` until none is left.
  - `flutter gen-l10n`.
- [ ] **Step 4:** Run `flutter test` (the whole suite; entry and library tests move). Expected: PASS.
- [ ] **Step 5:** Commit: `feat(study): every study mode is built; the built set and Coming soon go (FE-A6 P4, spec §3)`.

---

### Task 9: Goldens, visual audit, records

**Files:**
- Create: `test/features/study/presentation/study_recall_fill_golden_test.dart`.
- Modify:
  - `test/visual_audit/screens/features/study/screens/study_session_screen_visual_audit_test.dart`;
  - handoffs 19, 20, 14 and the index;
  - `docs/wbs_FE.md` (or the WBS file P3 edited);
  - the spec's §3 P4 row.

- [ ] **Step 1: Goldens,** light and dark:
  - `study_recall_counting` (pump 6 s), `study_recall_revealed`, `study_recall_timed_out`, `study_recall_large_text` (2x, counting);
  - `study_fill_input` (typed "term"), `study_fill_hint`, `study_fill_wrong`, `study_fill_large_text`.
  - Use a local `shoot` that pumps with `pump()` (never `pumpAndSettle`, since the Recall clock would run out), then `pump(AppDurations.standard)` for the reveal fade.
  - `TZ=UTC flutter test --tags golden --update-goldens` on this file, then view every image against the kit's `img/19-study-recall/*` and `img/20-study-fill/*`.
  - Also regenerate the entry goldens Task 8 moved, and view them.
- [ ] **Step 2: Visual audit companions:** "screen 19, Recall revealed" and "screen 20, Fill answered wrong", in the file's pattern: a fresh tree per pump, and no `pumpAndSettle` for Recall.
- [ ] **Step 3: Records.**
  - Handoffs 19 and 20:
    - Built notes and goldens;
    - Deviations (V1, V2, and 20's kit tag "this round");
    - an Accessibility section (V3/V5, V7, V9, announcements, the 20 s clock flag).
  - 14: eight_box Learn offered; "Coming soon" gone.
  - Index rows 19 and 20 → built (P4); row 14 notes P4.
  - WBS FE-A6: next is P5.
  - Spec §3: the P4 row points to this plan.
- [ ] **Step 4: Gate:** `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `TZ=UTC flutter test --tags golden`. Expected: both green.
- [ ] **Step 5:** Commit: `test(study): Recall and Fill goldens and visual audit; P4 records (FE-A6)`.
