# Study P2 — Self-check (16a), Study Entry actions (14) and the direction sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `sm2` decks become studyable from the app: the Study Entry starts a learning session (Browse → Self-check), a review (after the direction sheet) or continues today's session, and screen 16a grades each card with Again · Hard · Good · Easy and the interval each would give.

**Architecture:** One read-only backend addition, `PreviewSelfAssessIntervalsUseCase` (spec D11b), runs the same `SrsScheduler.next` the write runs on the card's stored schedule, and answers null for any turn that is not `scheduled`. The session screen's mode switch gains `StudySelfAssessWidget`, a presentational body that reveals locally (no write) and grades through the existing session controller (D4). The Study Entry gains one `@riverpod` start controller per deck that owns Learn, Review and Continue, drops a second start while one runs (BR-STUDY-004), and maps each outcome to the kit's `starting` / `refused` / `startFailed` states; the screen draws them and navigates through a callback `app/` supplies. `builtStudyModes` grows to `{browse, selfAssess}` (spec §3), which is what makes `sm2` Learn and Review offered.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, go_router, Drift (in-memory in tests), `flutter gen-l10n`, `intl`.

**Spec:** [docs/superpowers/specs/2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) — D4, D5, D11 (b), D13, D19, §3 (P2 row). Screens: [14-study-entry.md](../../shared/ui/screen-handoff/14-study-entry.md) (resume, starting, refused, startFailed, the Direction sheet), [16a-study-self-assess.md](../../shared/ui/screen-handoff/16a-study-self-assess.md). UC-STUDY-001 (steps 3–5, A3b), UC-STUDY-003. Built on [P1a](2026-09-26-study-p1a-foundations.md), [P1b](2026-09-26-study-p1b-entry.md), [P1c](2026-09-26-study-p1c-session.md).

**Plan-time rulings** (each recorded in Task 10 in the handoff it touches):

- **R1 — the mode's name.** 16a's brief calls the badge "Self-check"; the kit's resume banner writes "Review · Self-assess · 12 of 20 cards", and the app already names the mode `cardModeSelfAssess` ("Self-assess") on the card screens. The kit wins (CLAUDE.md precedence): one name, "Self-assess", in the top bar, the context line and the resume banner.
- **R2 — the answer card is always laid out.** 16a says the answer card is "hidden until revealed … the prompt stays in place". Kit 19 (the anatomy 16a builds from) keeps the recessed answer face in place with a placeholder bar before the reveal. Built as kit 19: the prompt never moves, and the answer fades in inside its face.
- **R3 — saving draws no spinner.** 16a: "the grade row is locked on the tapped grade, with no spinner under 300 ms". A local write is well under 300 ms; the row absorbs taps while the write runs and draws no change. A write slower than that shows nothing extra (recorded as a 16a deviation, not built).
- **R4 — the preview loads with the card.** The preview is read when the card is served, not when it is revealed, so the grade row appears with its intervals already there; no placeholder is drawn.
- **R5 — refused keeps the footer live.** The kit draws `refused` with the footer disabled. The counts are already up to date when the banner shows, so the footer is rebuilt from them and stays usable (a disabled footer would strand the person on a screen whose action may still exist). The banner stays until the next start.
- **R6 — "Starting…" is the footer's caption.** `MxButton` shows a spinner in place of its label while loading; "Starting…" moves to the footer caption line, so both the kit's glyph and its words stay.
- **R7 — the direction sheet closes on Start review.** 14 says "Start review … locks the sheet while the session opens". The sheet returns the choice and closes; the entry's footer shows `starting`, and `startFailed`'s "Try again" repeats the review with the same direction. One place owns the starting state.
- **R8 — the SM-2 review caption.** The kit's caption "Term first · 20 of 40 due · oldest first" names a direction the entry no longer asks (the sheet does, UC-STUDY-003). The caption is "{shown} of {due} due · oldest first".
- **R9 — refusal copy.** The kit writes one refusal ("Nothing is due any more."). A start can also meet no new cards, a mode that no longer runs, or a session that can no longer be continued; each gets its own title over one body shape.
- **R10 — eight_box stays read-only in P2.** Its review modes (match, guess, recall, fill) are not built, so it offers neither Learn nor Review: no footer, no mode selection. Picking among several built review modes arrives with P3, the first phase with two built `eight_box` review modes.

## Global Constraints

- `study` imports only `study_mode`, `srs`, `settings`, `card` (`test/architecture/boundary_rules.dart`); `presentation/` never imports `data/`; `app/` composes and routes.
- Presentation files end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
- Every user-facing string is an ARB key in `app_en.arb` and `app_vi.arb`; no interpolated literal in a widget (guard `no_literal_user_string`).
- No `ref.read` in a `build()` body, even inside a closure (guard `no_ref_read_in_build`): read in a method. After every `await` in a controller, `if (!ref.mounted) return …;` before touching `state` (guard `state_write_after_await_requires_mounted`).
- Booleans read as predicates: `is…`, `has…`, `can…`, `should…` (guard `boolean_reads_as_predicate`).
- No source file over 400 logical lines (guard `no_large_source_file`).
- Features pass no `Color`, `TextStyle`, radius or padding to shared widgets and never restyle text with `copyWith`; a missing role is added to `MxTextStyles` / the shared widget under `flutter-theme-design`. No raw Material buttons or `InkWell` in features (guard `no_raw_button`, `no_raw_widget`): a shape `MxButton` cannot draw is added to `MxButton`.
- Mode widgets never call a use case; they call the session controller (D4). A read provider may be watched by the session screen and its result passed down.
- The preview must never fork the SM-2 formula: it calls `SrsScheduler.next` (16a, D11).
- Tests never read the wall clock (guard `no_real_clock_in_test`): the harness's `FakeDayClock`, `libraryToday` = 2026-09-24 09:00.
- Every test tree seeds cards in a sub-deck leaf of a root (BR-DECK-004), except where an existing test already seeds a root.
- Goldens on Linux only (`TZ=UTC`); Hangul renders as boxes in the test fonts, so golden seeds use Latin/Vietnamese text.

## Review Focus

1. A double tap on a grade records one turn, never two (BR-STUDY-004) — pinned in Task 5 (`grades twice → one review_log row`).
2. A relearning turn (a card back after Again) shows no interval and never "0d"; the same card's first turn did (BR-SRS-016, 16a) — pinned in Task 3 (use case) and Task 5 (widget).
3. Learn, Review or Continue tapped twice, or two of them in a row, opens one session (BR-STUDY-004) — pinned in Task 7 (`a second start while one runs is dropped`).
4. Closing the direction sheet without Start review writes nothing and leaves the entry as it was (BR-STUDY-020) — pinned in Task 8.
5. A meaning-first card prompts with the meaning, hides the term and the example until the reveal; a mixed review asks each card its own way (BR-MODE-014, BR-MODE-015) — pinned in Task 5.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | 16a, entry actions, sheet, banners |
| `lib/shared/widgets/mx_button.dart`, `mx_card.dart`, `lib/core/theme/mx_text_styles.dart`, `app_decorations.dart` | modify | `MxButton.detail` and `dangerSoft` tone; `MxCard.isRecessed`; `buttonDetail` role |
| `lib/app/gallery/…` | modify | the new button and card variants in the gallery |
| `lib/features/srs/domain/repositories/schedule_repository.dart`, `data/repositories/schedule_repository_impl.dart` | modify | `scheduleOf`, the stored schedule of a card |
| `lib/features/srs/domain/models/interval_preview_model.dart` | create | `nextIntervalsOf`, the pure preview |
| `lib/features/study/domain/usecases/preview_self_assess_intervals_use_case.dart` | create | D11b |
| `lib/features/study/presentation/providers/{preview_self_assess_intervals_use_case,self_assess_preview,open_learning_session_use_case,open_review_session_use_case}_provider.dart` | create | providers |
| `lib/features/study/presentation/states/interval_span_state.dart` | create | how an interval reads (pure) |
| `lib/features/study/presentation/widgets/support/{study_face_card,study_grade_row}_widget.dart` | create | 16a's pieces |
| `lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart` | create | screen 16a |
| `lib/features/study/presentation/screens/study_session_screen.dart` | modify | mode switch, review context line, the preview |
| `lib/features/study/presentation/states/study_entry_offer_state.dart` | modify | built modes, review target, footer action |
| `lib/features/study/presentation/states/study_start_state.dart`, `controllers/study_entry_controller.dart` | create | the entry's starts |
| `lib/features/study/presentation/widgets/sections/study_entry_{footer,resume,banner}_widget.dart`, `widgets/overlays/study_direction_sheet_widget.dart` | create | 14's actions and the sheet |
| `lib/features/study/presentation/screens/study_entry_screen.dart`, `widgets/sections/study_entry_{body,learn}_widget.dart` | modify | wiring |
| `lib/app/router/app_router.dart` | modify | `onOpenSession` |
| `test/support/study_entry_fixtures.dart`, `library_harness.dart` | create/modify | a failing entry store; the entry on the fake day |
| tests, goldens, companions, docs | create/modify | proofs and records |

---

### Task 1: Strings

**Files:** Modify `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`.

Each key gets an `@key` with `"description": "Screen handoff 14|16a (FE-A6 P2): …"` naming where it shows, and `placeholders` typed as listed. Keys go next to their P1 neighbours (`studyEntry*` after `studyEntryErrorBody`, `study*` session keys after `studySessionStaleToast`).

**Interfaces — Produces** (`context.l10n`; keys exactly as named):

| Key | English | Vietnamese | Placeholders |
|---|---|---|---|
| `studyKindReview` | `Review` | `Ôn tập` | |
| `studyContextReview` | `{deck} · {kind} · {mode}` | `{deck} · {kind} · {mode}` | deck String, kind String, mode String |
| `studySelfAssessShowAnswer` | `Show answer` | `Hiện đáp án` | |
| `studySelfAssessHintPrompt` | `Recall the answer, then show it` | `Nhớ lại đáp án rồi hãy mở` | |
| `studySelfAssessHintGrade` | `Be honest — grade how well you remembered` | `Thành thật nhé — chấm mức bạn nhớ được` | |
| `studyIntervalDays` | `{days}d` | `{days} ngày` | days int |
| `studyIntervalMonths` | `{months}mo` | `{months} tháng` | months int |
| `studyIntervalYears` | `{years}y` | `{years} năm` | years String |
| `studyIntervalDaysLong` | `{days, plural, =1{1 day} other{{days} days}}` | `{days} ngày` | days int |
| `studyIntervalMonthsLong` | `{months, plural, =1{1 month} other{{months} months}}` | `{months} tháng` | months int |
| `studyIntervalYearsLong` | `{years, select, 1{1 year} other{{years} years}}` | `{years} năm` | years String |
| `studyGradeNextIn` | `{grade}, next in {interval}` | `{grade}, lần tới sau {interval}` | grade String, interval String |
| `studyEntryStart` | `Starting…` | `Đang bắt đầu…` | |
| `studyEntryLearnCta` | `{count, plural, =1{Learn 1 new card} other{Learn {count} new cards}}` | `Học {count} thẻ mới` | count int |
| `studyEntryReviewCta` | `{count, plural, =1{Review 1 due card} other{Review {count} due cards}}` | `Ôn {count} thẻ đến hạn` | count int |
| `studyEntryReviewInstead` | `Start a new review instead` | `Bắt đầu lượt ôn mới` | |
| `studyEntryTryAgain` | `Try again` | `Thử lại` | |
| `studyEntryReviewCaption` | `{shown} of {due} due · oldest first` | `{shown}/{due} thẻ đến hạn · cũ nhất trước` | shown int, due int |
| `studyEntryNothingDueCaption` | `Nothing is due — review is available once cards come due.` | `Chưa có thẻ đến hạn — có thể ôn khi thẻ đến hạn.` | |
| `studyEntryResumeOverline` | `Session from today` | `Phiên hôm nay` | |
| `studyEntryResumeLine` | `{kind} · {mode} · {done} of {total} cards` | `{kind} · {mode} · {done}/{total} thẻ` | kind String, mode String, done int, total int |
| `studyEntryResumeLineNoProgress` | `{kind} · {mode}` | `{kind} · {mode}` | kind String, mode String |
| `studyEntryResumeBody` | `Continue where you stopped, or start something new — that ends this one and keeps its answers.` | `Tiếp tục từ chỗ bạn dừng, hoặc bắt đầu phiên mới — phiên này sẽ kết thúc và giữ các câu đã trả lời.` | |
| `studyEntryContinue` | `Continue` | `Tiếp tục` | |
| `studyEntryRefusedDueTitle` | `Nothing is due any more.` | `Không còn thẻ đến hạn.` | |
| `studyEntryRefusedDueBody` | `The due cards were reviewed from another session or deleted since this screen was opened. Counts are up to date now.` | `Các thẻ đến hạn đã được ôn ở phiên khác hoặc đã bị xoá sau khi mở màn hình này. Số liệu giờ đã được cập nhật.` | |
| `studyEntryRefusedNewTitle` | `No new cards left to learn.` | `Không còn thẻ mới để học.` | |
| `studyEntryRefusedNewBody` | `They were learned in another session or deleted since this screen was opened. Counts are up to date now.` | `Các thẻ đã được học ở phiên khác hoặc đã bị xoá sau khi mở màn hình này. Số liệu giờ đã được cập nhật.` | |
| `studyEntryRefusedModeTitle` | `This mode can't run on the due cards any more.` | `Chế độ này không còn chạy được trên các thẻ đến hạn.` | |
| `studyEntryRefusedModeBody` | `The due cards changed since this screen was opened. Counts are up to date now.` | `Các thẻ đến hạn đã thay đổi sau khi mở màn hình này. Số liệu giờ đã được cập nhật.` | |
| `studyEntryRefusedSessionTitle` | `That session can't be continued.` | `Không thể tiếp tục phiên đó.` | |
| `studyEntryRefusedSessionBody` | `It ended since this screen was opened, and its answers are kept. Start a new one below.` | `Phiên đã kết thúc sau khi mở màn hình này, các câu đã trả lời vẫn được giữ. Hãy bắt đầu phiên mới bên dưới.` | |
| `studyEntryStartFailedTitle` | `Couldn't start the session.` | `Không bắt đầu được phiên.` | |
| `studyEntryStartFailedBody` | `Nothing was written. Try again.` | `Chưa có gì được ghi. Hãy thử lại.` | |
| `studyDirectionTitle` | `Review · question direction` | `Ôn tập · chiều hỏi` | |
| `studyDirectionTermFirst` | `Term first` | `Thuật ngữ trước` | |
| `studyDirectionTermFirstBody` | `See the term, recall the meaning` | `Nhìn thuật ngữ, nhớ lại nghĩa` | |
| `studyDirectionMeaningFirst` | `Meaning first` | `Nghĩa trước` | |
| `studyDirectionMeaningFirstBody` | `See the meaning, recall the term` | `Nhìn nghĩa, nhớ lại thuật ngữ` | |
| `studyDirectionMixed` | `Mixed` | `Trộn` | |
| `studyDirectionMixedBody` | `Half each way, evenly split` | `Mỗi chiều một nửa, chia đều` | |
| `studyDirectionNote` | `SM-2 has one review mode: reveal, then grade yourself again · hard · good · easy. The direction cannot change once the session starts.` | `SM-2 có một chế độ ôn: mở đáp án rồi tự chấm lại · khó · tốt · dễ. Không thể đổi chiều hỏi khi phiên đã bắt đầu.` | |
| `studyDirectionStart` | `Start review` | `Bắt đầu ôn` | |

- [ ] **Step 1:** Add the keys to both ARB files (en with descriptions and placeholders, vi values only, as the P1 keys are).
- [ ] **Step 2:** Run `flutter gen-l10n` — Expected: no warnings; `lib/l10n/generated/app_localizations.dart` has `studyEntryReviewCta(int count)` and `studyIntervalYearsLong(String years)`.
- [ ] **Step 3:** Run `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` — Expected: no new i18n findings (key parity en/vi).
- [ ] **Step 4:** Commit — `feat(l10n): self-check, entry actions and direction sheet strings (FE-A6 P2)`.

---

### Task 2: `MxButton` detail line and soft-danger tone; `MxCard` recessed face

Read `.claude/skills/flutter-theme-design/SKILL.md` first: the theme slot and the widget change together, with the widget test and the gallery.

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/app_decorations.dart`, `lib/shared/widgets/mx_button.dart`, `lib/shared/widgets/mx_card.dart`, the gallery page that lists `MxButton` and `MxCard` (`grep -rn "MxButtonTone.destructive" lib/app/gallery`)
- Test: `test/shared/widgets/mx_button_test.dart`, `test/shared/widgets/mx_card_test.dart`, their goldens

**Interfaces — Produces:**
- `MxTextStyles.buttonDetail` — 12/500 tabular at line-height 1.2, no colour (it takes the button's ink through `DefaultTextStyle`).
- `MxButton({…, String? detail})` — a second line under the label in `buttonDetail`; drawn only on `regular`, `small` and `study` sizes (assert). The semantics label stays `label` unless the caller wraps it (Task 5 does).
- `MxButtonTone.dangerSoft` — fill `derivedColors.dangerSoft`, ink `colors.error`, edge `derivedColors.dangerBorder` hairline: the soft danger tint `MxInlineBanner` and `MxCard.isDanger` already draw (FE-A6 D14). The solid `destructive` tone stays the destructive action's.
- `MxCard({…, bool isRecessed = false})` — `AppDecorations.recessedCard`: `surfaceContainerLow` ground, the ghost edge in both themes, no shadow (kit `StudyFaceCard role="answer"`). Counts in the one-tone assert.

- [ ] **Step 1: Write the failing tests** (append to the existing files, reusing their pump helpers):

```dart
// mx_button_test.dart
testWidgets('a detail line sits under the label, in the button ink', (
  tester,
) async {
  await pumpWidgetInTheme(
    tester,
    const MxButton(
      label: 'Good',
      detail: '6d',
      tone: MxButtonTone.secondary,
      onPressed: _noop,
    ),
  );
  final label = tester.getRect(find.text('Good'));
  final detail = tester.getRect(find.text('6d'));
  expect(detail.top, greaterThanOrEqualTo(label.bottom));
  final style = DefaultTextStyle.of(tester.element(find.text('6d'))).style;
  expect(
    tester.widget<Text>(find.text('6d')).style,
    tester.element(find.text('6d')).textStyles.buttonDetail,
  );
  expect(style.color, tester.element(find.text('6d')).colors.onSurface);
});

testWidgets('dangerSoft paints the soft danger tint with the error ink', (
  tester,
) async {
  await pumpWidgetInTheme(
    tester,
    const MxButton(
      label: 'Again',
      tone: MxButtonTone.dangerSoft,
      onPressed: _noop,
    ),
  );
  final context = tester.element(find.text('Again'));
  final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
  expect(
    style.backgroundColor!.resolve({}),
    context.derivedColors.dangerSoft,
  );
  expect(style.foregroundColor!.resolve({}), context.colors.error);
  expect(
    (style.shape!.resolve({})! as RoundedRectangleBorder).side.color,
    context.derivedColors.dangerBorder,
  );
});

testWidgets('at twice the text size the detail line still fits a 48 target',
    (tester) async {
  await pumpWidgetInTheme(
    tester,
    const MxButton(label: 'Good', detail: '6d', onPressed: _noop),
    textScale: 2,
  );
  expect(tester.getSize(find.byType(MxButton)).height, greaterThanOrEqualTo(48));
  expect(tester.takeException(), isNull);
});

// mx_card_test.dart
testWidgets('a recessed card is the answer face: container-low, no shadow',
    (tester) async {
  await pumpWidgetInTheme(
    tester,
    const MxCard(isRecessed: true, child: SizedBox(height: 40)),
  );
  final context = tester.element(find.byType(MxCard));
  final material = tester.widget<Material>(
    find.descendant(of: find.byType(MxCard), matching: find.byType(Material)),
  );
  expect(material.color, context.colors.surfaceContainerLow);
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(MxCard), matching: find.byType(DecoratedBox)).first,
  );
  expect((box.decoration as BoxDecoration).boxShadow, isNull);
});
```

Use the helper names these files already use (`pumpWidgetInTheme` stands for whichever they define; `_noop` is a top-level `void _noop() {}`). Adjust how the style is read to the file's existing assertions if it already reads `TextButton.style` another way.

- [ ] **Step 2:** Run `flutter test test/shared/widgets/mx_button_test.dart test/shared/widgets/mx_card_test.dart` — Expected: FAIL (`detail`, `dangerSoft`, `isRecessed` undefined).
- [ ] **Step 3: Implement.**

`mx_text_styles.dart` (next to `buttonLabelSmall`; keep the file's constants block style):

```dart
  static const double _buttonDetailHeight = 1.2;

  /// A button's second line, such as a grade's next interval (screen 16a):
  /// 12/500 tabular. No colour: it takes the button's ink.
  TextStyle get buttonDetail =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w500).copyWith(
        height: _buttonDetailHeight,
        fontFeatures: _tabular,
        color: null,
      );
```

If `labelSmall` carries a colour in the theme, `copyWith(color: null)` does not clear it: build it as `TextStyle(inherit: true, fontSize: …, …)` from the labelSmall values instead, so `DefaultTextStyle`'s ink wins. The test in Step 1 asserts the resolved colour, so either form must pass it. If `mx_text_styles.dart` goes over 400 logical lines, move the study roles (`studyTerm` … `factValue`) into a `part` or an extension file `mx_text_styles_study.dart` the way the file's own tests were split in P1a.

`app_decorations.dart` (next to `raisedCard`):

```dart
  /// The answer face of a study card (kit StudyFaceCard role answer): the
  /// container-low ground and the ghost edge, flat in both themes.
  static BoxDecoration recessedCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLow,
    borderRadius: raisedCard(scheme, derived).borderRadius,
    border: Border.all(color: derived.ghostBorder, width: AppStroke.hairline),
  );
```

`mx_card.dart`: add `this.isRecessed = false` with the doc `/// The answer face of a study card: the container-low ground, flat (kit StudyFaceCard, screen 16a).`, include it in the one-tone assert, and add the case `(_, _, _, _, true) => AppDecorations.recessedCard(context.colors, context.derivedColors),` to the switch (widen the record to five fields).

`mx_button.dart`:

```dart
enum MxButtonTone { primary, secondary, outline, destructive, dangerSoft }
```

In `_paintFor`:

```dart
      MxButtonTone.dangerSoft => (
        fill: context.derivedColors.dangerSoft,
        ink: colors.error,
        edge: BorderSide(
          color: context.derivedColors.dangerBorder,
          width: AppStroke.hairline,
        ),
      ),
```

Add the field and constructor parameter:

```dart
    this.detail,
  }) : assert(
         detail == null ||
             size == MxButtonSize.regular ||
             size == MxButtonSize.small ||
             size == MxButtonSize.study,
         'a detail line needs a regular, small or study button',
       );

  /// A second line under the label, in the button ink, such as the interval a
  /// grade gives (screen 16a).
  final String? detail;
```

In `_content`, when `detail != null`, the `text` becomes:

```dart
    final detail = this.detail;
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: geometry.canWrap ? _maxWrappedLines : 1,
      softWrap: geometry.canWrap,
    );
    final text = detail == null
        ? labelText
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              labelText,
              Text(detail, textAlign: TextAlign.center, style: _detailStyle),
            ],
          );
```

where `_detailStyle` is read in `build` (`context.textStyles.buttonDetail`) and passed into `_content` (it is a method without a context today: add a `TextStyle detailStyle` parameter). The button's height is the geometry's minimum; `appButtonStyle` must let it grow for two lines — if it fixes `fixedSize`/`maximumSize`, change the minimum-size-only path for the `detail` case (`minimumSize: Size(0, geometry.height)`), so the large-text test passes. The spinner path keeps the width through `Visibility.maintain` as today. `isOnFill` for the spinner stays false for `dangerSoft`.

Gallery: add a "dangerSoft" button and a "Good / 6d" detail button beside the existing tone row, and a recessed card beside the hero card.

- [ ] **Step 4:** Run the two test files — Expected: PASS. Run `TZ=UTC flutter test --tags golden --update-goldens test/shared/widgets/mx_button_test.dart test/shared/widgets/mx_card_test.dart` only if those files have goldens that include every tone (then add the new tone/variant to the golden's row), and look at the new PNGs.
- [ ] **Step 5:** Run `flutter analyze` and the guard — Expected: clean.
- [ ] **Step 6:** Commit — `feat(theme): MxButton detail line and dangerSoft tone, MxCard recessed face (FE-A6 P2)`.

---

### Task 3: The interval preview (spec D11b)

**Files:**
- Create: `lib/features/srs/domain/models/interval_preview_model.dart`, `lib/features/study/domain/usecases/preview_self_assess_intervals_use_case.dart`, `lib/features/study/presentation/providers/preview_self_assess_intervals_use_case_provider.dart`, `lib/features/study/presentation/providers/self_assess_preview_provider.dart`
- Modify: `lib/features/srs/domain/repositories/schedule_repository.dart`, `lib/features/srs/data/repositories/schedule_repository_impl.dart`
- Test: `test/features/srs/domain/interval_preview_model_test.dart`, `test/features/srs/data/schedule_of_test.dart`, `test/features/study/domain/preview_self_assess_intervals_use_case_test.dart`

**Interfaces — Produces:**
- `Map<Object, int> nextIntervalsOf(SrsScheduler scheduler, CardScheduleState state, DateTime now)` — action → next interval in days, in `supportedActions` order.
- `ScheduleRepository.scheduleOf({required String cardId})` → `Future<(SchedulerType, CardScheduleState)?>` — null when the card is gone or in the Trash.
- `PreviewSelfAssessIntervalsUseCase(ScheduleRepository schedules, DayClock clock)`; `Future<Map<Object, int>?> call({required SessionKind kind, required String cardId, required int round, required int answersInSession})` — null unless the turn is `scheduled` and the card is learned.
- `previewSelfAssessIntervalsUseCaseProvider`; `selfAssessPreviewProvider({required SessionKind kind, required String cardId, required int round, required int answersInSession})` → `Future<Map<Object, int>?>` (autoDispose family).

- [ ] **Step 1: Write the failing tests.**

`test/features/srs/domain/interval_preview_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/interval_preview_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

// FE-A6 D11b: the preview is the write's own formula (handoff 16a).

void main() {
  final now = DateTime(2026, 9, 24, 9);
  final state = CardScheduleState.sm2(
    generation: 1,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
    lastAnsweredAt: DateTime(2026, 9, 14),
    answerCount: 3,
    lapseCount: 0,
    easeFactor: 2.5,
    intervalDays: 10,
    repetitions: 2,
  );

  test('each action gives what next would give, in supportedActions order',
      () {
    final preview = nextIntervalsOf(sm2Scheduler, state, now);

    expect(preview.keys, sm2Scheduler.supportedActions);
    for (final action in sm2Scheduler.supportedActions) {
      expect(
        preview[action],
        sm2Scheduler.next(state, action, now).$2.nextIntervalDays,
      );
    }
    expect(preview, {
      Sm2Action.again: 1,
      Sm2Action.hard: 24,
      Sm2Action.good: 25,
      Sm2Action.easy: 26,
    });
  });
}
```

(Check `CardScheduleState.sm2`'s named parameters against `card_schedule_state_model.dart` and use them exactly; the values are ease 2.5, interval 10, repetitions 2.)

`test/features/srs/data/schedule_of_test.dart` — with `openTestDatabase()`, `DeckRepositoryImpl`, a sm2 root and a `Lesson` leaf, `insertCard(… learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 20), intervalDays: 6)`:

```dart
  test('the stored schedule of a card, with its scheduler', () async {
    final schedule = await ScheduleRepositoryImpl(db).scheduleOf(cardId: 'c1');

    expect(schedule, isNotNull);
    final (type, state) = schedule!;
    expect(type, SchedulerType.sm2);
    expect(state.intervalDays, 6);
    expect(state.learnedAt, DateTime(2026, 9, 1));
  });

  test('none for a card in the Trash or gone', () async {
    await insertCard(db, id: 't1', deckId: leaf.id, deleteBatchId: 'b1');

    expect(await ScheduleRepositoryImpl(db).scheduleOf(cardId: 't1'), isNull);
    expect(await ScheduleRepositoryImpl(db).scheduleOf(cardId: 'nope'), isNull);
  });
```

`test/features/study/domain/preview_self_assess_intervals_use_case_test.dart` — same database setup, a sm2 learned card `c1` (interval 6, the fixture's ease 2.5, repetitions 1) and a new card `n1`; `useCase = PreviewSelfAssessIntervalsUseCase(ScheduleRepositoryImpl(db), FakeDayClock(DateTime(2026, 9, 24, 9)))`:

```dart
  test("a review's first turn previews each grade (16a)", () async {
    final preview = await useCase(
      kind: SessionKind.reviewing,
      cardId: 'c1',
      round: 1,
      answersInSession: 0,
    );

    expect(preview, {
      Sm2Action.again: 1,
      Sm2Action.hard: 6,
      Sm2Action.good: 6,
      Sm2Action.easy: 6,
    });
  });

  test('a relearning turn previews nothing: the schedule does not move '
      '(BR-SRS-016, BR-SRS-017)', () async {
    expect(
      await useCase(
        kind: SessionKind.reviewing,
        cardId: 'c1',
        round: 1,
        answersInSession: 1,
      ),
      isNull,
    );
  });

  test('a learning turn previews nothing: the card is not scheduled yet',
      () async {
    expect(
      await useCase(
        kind: SessionKind.learning,
        cardId: 'n1',
        round: 1,
        answersInSession: 0,
      ),
      isNull,
    );
  });

  test('a card gone meanwhile previews nothing', () async {
    expect(
      await useCase(
        kind: SessionKind.reviewing,
        cardId: 'gone',
        round: 1,
        answersInSession: 0,
      ),
      isNull,
    );
  });
```

- [ ] **Step 2:** Run the three files — Expected: FAIL (undefined names).
- [ ] **Step 3: Implement.**

`interval_preview_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';

/// What each action of [scheduler] would set [state]'s interval to if the
/// card were answered at [now]: the write's own `next`, so the preview and
/// the write cannot fork (FE-A6 D11, handoff 16a). Keyed by action, in
/// `supportedActions` order; nothing is written.
Map<Object, int> nextIntervalsOf(
  SrsScheduler scheduler,
  CardScheduleState state,
  DateTime now,
) => {
  for (final action in scheduler.supportedActions)
    if (scheduler.next(state, action, now).$2.nextIntervalDays
        case final days?)
      action: days,
};
```

`schedule_repository.dart` (after `recordTurn`):

```dart
  /// The stored schedule of [cardId] and the scheduler it runs under, for a
  /// read-only preview (FE-A6 D11); null when the card is gone or in the
  /// Trash. It writes nothing.
  Future<(SchedulerType, CardScheduleState)?> scheduleOf({
    required String cardId,
  });
```

`schedule_repository_impl.dart`:

```dart
  @override
  Future<(SchedulerType, CardScheduleState)?> scheduleOf({
    required String cardId,
  }) async {
    try {
      final root = await _dao.rootOfCard(cardId);
      final schedule = await _dao.scheduleRow(cardId);
      if (root == null || schedule == null) return null;
      return (SchedulerType.fromCode(schedule.schedulerType), _stateOf(schedule));
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
```

`preview_self_assess_intervals_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/srs/domain/models/interval_preview_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// Screen 16a's interval preview (FE-A6 D11): on a `scheduled` turn, the
/// interval each grade would give the card; null on a learning or
/// relearning turn, whose answer moves no schedule (BR-SRS-016, BR-SRS-017),
/// and for a card gone meanwhile. Read-only.
final class PreviewSelfAssessIntervalsUseCase {
  const PreviewSelfAssessIntervalsUseCase(this._schedules, this._clock);

  final ScheduleRepository _schedules;
  final DayClock _clock;

  Future<Map<Object, int>?> call({
    required SessionKind kind,
    required String cardId,
    required int round,
    required int answersInSession,
  }) async {
    final turn = turnKindOf(
      kind,
      round: round,
      answersInSession: answersInSession,
    );
    if (turn != ReviewKind.scheduled) return null;
    final stored = await _schedules.scheduleOf(cardId: cardId);
    if (stored == null) return null;
    final (type, state) = stored;
    // A scheduled turn on a card still learning is a bug the write refuses
    // (BR-STUDY-058); the preview shows nothing rather than throw.
    if (state.learnedAt == null) return null;
    return nextIntervalsOf(schedulerFor(type), state, _clock.now());
  }
}
```

`preview_self_assess_intervals_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/preview_self_assess_intervals_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preview_self_assess_intervals_use_case_provider.g.dart';

@riverpod
PreviewSelfAssessIntervalsUseCase previewSelfAssessIntervalsUseCase(Ref ref) =>
    PreviewSelfAssessIntervalsUseCase(
      ref.watch(scheduleRepositoryProvider),
      ref.watch(dayClockProvider),
    );
```

`self_assess_preview_provider.dart`:

```dart
import 'package:memox/features/study/presentation/providers/preview_self_assess_intervals_use_case_provider.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'self_assess_preview_provider.g.dart';

/// The interval preview of one turn of screen 16a (FE-A6 D11), read when the
/// card is served so the grades show it at the reveal (plan R4).
@riverpod
Future<Map<Object, int>?> selfAssessPreview(
  Ref ref, {
  required SessionKind kind,
  required String cardId,
  required int round,
  required int answersInSession,
}) => ref.watch(previewSelfAssessIntervalsUseCaseProvider)(
  kind: kind,
  cardId: cardId,
  round: round,
  answersInSession: answersInSession,
);
```

- [ ] **Step 4:** `dart run build_runner build --delete-conflicting-outputs`, then run the three test files — Expected: PASS. Run `flutter test test/features/srs test/features/card test/features/deck` — Expected: PASS (the `noSuchMethod` fakes of `ScheduleRepository` still compile).
- [ ] **Step 5:** Commit — `feat(study): read-only self-assess interval preview (FE-A6 D11b)`.

---

### Task 4: How an interval reads (pure)

**Files:**
- Create: `lib/features/study/presentation/states/interval_span_state.dart`
- Modify: `lib/features/study/presentation/widgets/support/study_labels_widget.dart`
- Test: `test/features/study/presentation/interval_span_state_test.dart`

**Interfaces — Produces:**
- `sealed class IntervalSpan`; `DaySpan(int days)`, `MonthSpan(int months)`, `YearSpan(double years)`; `IntervalSpan intervalSpanOf(int days)`.
- `StudyLabels.studyIntervalShort(IntervalSpan span, String localeName)` / `studyIntervalLong(IntervalSpan span, String localeName)`, and `StudyLabels.studyGrade(Sm2Action action)` (the `cardAction*` keys).

- [ ] **Step 1: Write the failing test:**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/study/presentation/states/interval_span_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

// Handoff 16a, Interval preview: under 30 days in days, under a year in
// months (days / 30, rounded), from a year in years (one decimal, ".0"
// dropped).

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('the three bands and their edges', () {
    expect(intervalSpanOf(1), const DaySpan(1));
    expect(intervalSpanOf(29), const DaySpan(29));
    expect(intervalSpanOf(30), const MonthSpan(1));
    expect(intervalSpanOf(44), const MonthSpan(1));
    expect(intervalSpanOf(45), const MonthSpan(2));
    expect(intervalSpanOf(364), const MonthSpan(12));
    expect(intervalSpanOf(365), const YearSpan(1));
    expect(intervalSpanOf(548), const YearSpan(1.5));
  });

  test('short and spoken forms, with the locale decimal', () {
    expect(en.studyIntervalShort(const DaySpan(6), 'en'), '6d');
    expect(en.studyIntervalShort(const MonthSpan(2), 'en'), '2mo');
    expect(en.studyIntervalShort(const YearSpan(1), 'en'), '1y');
    expect(en.studyIntervalShort(const YearSpan(1.5), 'en'), '1.5y');
    expect(vi.studyIntervalShort(const YearSpan(1.5), 'vi'), '1,5 năm');
    expect(en.studyIntervalLong(const DaySpan(1), 'en'), '1 day');
    expect(en.studyIntervalLong(const DaySpan(6), 'en'), '6 days');
    expect(en.studyIntervalLong(const MonthSpan(1), 'en'), '1 month');
    expect(en.studyIntervalLong(const YearSpan(1), 'en'), '1 year');
    expect(en.studyIntervalLong(const YearSpan(2.5), 'en'), '2.5 years');
  });

  test('the grades are the card screens’ action names', () {
    expect(
      [for (final action in Sm2Action.values) en.studyGrade(action)],
      ['Again', 'Hard', 'Good', 'Easy'],
    );
  });
}
```

- [ ] **Step 2:** Run it — Expected: FAIL.
- [ ] **Step 3: Implement** `interval_span_state.dart`:

```dart
/// How a next interval reads on a grade (handoff 16a).
sealed class IntervalSpan {
  const IntervalSpan();
}

final class DaySpan extends IntervalSpan {
  const DaySpan(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is DaySpan && other.days == days;

  @override
  int get hashCode => days.hashCode;
}

final class MonthSpan extends IntervalSpan {
  const MonthSpan(this.months);

  final int months;

  @override
  bool operator ==(Object other) =>
      other is MonthSpan && other.months == months;

  @override
  int get hashCode => months.hashCode;
}

/// Whole and half years alike, to one decimal.
final class YearSpan extends IntervalSpan {
  const YearSpan(this.years);

  final double years;

  @override
  bool operator ==(Object other) => other is YearSpan && other.years == years;

  @override
  int get hashCode => years.hashCode;
}

const int _daysInMonth = 30;
const int _daysInYear = 365;
const int _tenths = 10;

/// Under 30 days in days; under a year in months, days / 30 rounded; from a
/// year in years to one decimal (handoff 16a).
IntervalSpan intervalSpanOf(int days) {
  if (days < _daysInMonth) return DaySpan(days);
  if (days < _daysInYear) return MonthSpan((days / _daysInMonth).round());
  return YearSpan((days * _tenths / _daysInYear).round() / _tenths);
}
```

In `study_labels_widget.dart` add (imports `package:intl/intl.dart`, the span state and `review_action_model.dart`):

```dart
  /// A grade's name: the card screens' action names (BR-MODE-011).
  String studyGrade(Sm2Action action) => switch (action) {
    Sm2Action.again => cardActionAgain,
    Sm2Action.hard => cardActionHard,
    Sm2Action.good => cardActionGood,
    Sm2Action.easy => cardActionEasy,
  };

  /// "6d", "2mo", "1.5y" under a grade (handoff 16a).
  String studyIntervalShort(IntervalSpan span, String localeName) =>
      switch (span) {
        DaySpan(:final days) => studyIntervalDays(days),
        MonthSpan(:final months) => studyIntervalMonths(months),
        YearSpan(:final years) => studyIntervalYears(
          _years(years, localeName),
        ),
      };

  /// What TalkBack says: "6 days", "1 year" (handoff 16a).
  String studyIntervalLong(IntervalSpan span, String localeName) =>
      switch (span) {
        DaySpan(:final days) => studyIntervalDaysLong(days),
        MonthSpan(:final months) => studyIntervalMonthsLong(months),
        YearSpan(:final years) => studyIntervalYearsLong(
          _years(years, localeName),
        ),
      };
```

and a private top-level helper in the same file:

```dart
const String _yearPattern = '0.#';

String _years(double years, String localeName) =>
    NumberFormat(_yearPattern, localeName).format(years);
```

- [ ] **Step 4:** Run the test — Expected: PASS.
- [ ] **Step 5:** Commit — `feat(study): how a grade's interval reads (handoff 16a)`.

---

### Task 5: Screen 16a, Self-assess

**Files:**
- Create: `lib/features/study/presentation/widgets/support/study_face_card_widget.dart`, `lib/features/study/presentation/widgets/support/study_grade_row_widget.dart`, `lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart`
- Test: `test/features/study/presentation/study_self_assess_test.dart`, `test/support/study_fixtures.dart` (a `reviewing` helper, see Step 1)

**Interfaces:**
- Consumes: `selfAssessPreviewProvider` (Task 3), `intervalSpanOf`, `StudyLabels.studyGrade/studyIntervalShort/studyIntervalLong` (Task 4), `MxButton.detail`, `MxButtonTone.dangerSoft`, `MxCard.isRecessed` (Task 2), `StudySessionController.answer(StudyItem, StudyAnswer, {bool shouldHoldFeedback})` (P1c).
- Produces:
  - `StudyFaceCardWidget({required String label, required Widget child, bool isAnswer = false, VoidCallback? onTap})` — a face that grows (`Expanded` is the caller's), corner overline label, centred scrollable content, recessed when `isAnswer`; `onTap` with `excludeFromSemantics: true` (the button is the accessible path).
  - `StudyGradeRowWidget({required Map<Object, int>? intervals, required bool isBusy, required ValueChanged<Sm2Action> onGrade})`.
  - `StudySelfAssessWidget({required StudyItem item, required Map<Object, int>? intervals, required bool isBusy, required ValueChanged<Sm2Action> onGrade})` — keyed by the screen with `ValueKey('${item.cardId}#${item.answersInSession}')`, so each turn starts unrevealed.

- [ ] **Step 1: Write the failing tests** in `test/features/study/presentation/study_self_assess_test.dart`. Add to `test/support/study_fixtures.dart`:

```dart
/// A sm2 root `Korean` with a leaf `Lesson` holding [cards] learned cards
/// `R1`… due before [libraryDay] (their fronts `term N`, backs `meaning N`,
/// examples `example N`), and a review of them in self_assess asked
/// [direction]. Returns the session id.
Future<String> openSelfAssessReview(
  AppDatabase db,
  DeckRepository decks,
  DateTime now, {
  int cards = 2,
  DirectionChoice direction = DirectionChoice.koreanToMeaning,
}) async {
  final root = await decks.root('Korean', SchedulerType.sm2);
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 1; i <= cards; i++) {
    await insertCard(
      db,
      id: 'R$i',
      deckId: leaf.id,
      front: 'term $i',
      back: 'meaning $i',
      example: 'example $i',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 10 + i),
      intervalDays: 6,
    );
  }
  await lockScheduler(db, root.id);
  final opened = await studyEntryRepository(db, () => now).openReviewSession(
    deckId: leaf.id,
    mode: StudyMode.selfAssess,
    direction: direction,
  );
  return (opened as Ok<String, StudyRejection>).value;
}
```

(If `study_fixtures.dart` goes over 400 logical lines with it, put it in the new `test/support/study_entry_fixtures.dart` that Task 7 creates, and create that file here.)

The tests pump `StudySessionScreen(sessionId: id, onDone: (_) {}, onStudyDeck: (_) {}, onLeave: (_) {})` with `pumpLibraryScreen` and `openSelfAssessReview(env.db, env.decks, libraryToday)`:

```dart
  libraryTest('the prompt shows first, the answer waits for Show answer, and '
      'revealing writes nothing (BR-MODE-006)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('meaning 1'), findsNothing);
    expect(find.text(_en.studySelfAssessShowAnswer), findsOneWidget);
    expect(find.text(_en.cardActionGood), findsNothing);

    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    expect(find.text('meaning 1'), findsOneWidget);
    expect(find.text('example 1'), findsOneWidget);
    expect(find.text(_en.studySelfAssessShowAnswer), findsNothing);
    expect(await turnKindsOf(env.db, 'R1'), isEmpty);
  });

  libraryTest('tapping the prompt card reveals, as Show answer does', (
    tester,
    env,
  ) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('term 1'));
    await tester.pumpAndSettle();

    expect(find.text('meaning 1'), findsOneWidget);
  });

  libraryTest('a scheduled turn shows each grade with its interval, and '
      'reads "Good, next in 6 days" (16a)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    expect(find.text('1d'), findsOneWidget);
    expect(find.text('6d'), findsNWidgets(3));
    expect(
      find.bySemanticsLabel(
        _en.studyGradeNextIn(_en.cardActionGood, _en.studyIntervalDaysLong(6)),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  libraryTest('Good records one scheduled turn and the next card follows, '
      'unrevealed', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.cardActionGood));
    await tester.pumpAndSettle();

    expect(await turnKindsOf(env.db, 'R1'), ['scheduled']);
    expect(find.text('term 2'), findsOneWidget);
    expect(find.text('meaning 2'), findsNothing);
  });

  libraryTest('a double tap on a grade records one turn (BR-STUDY-004)', (
    tester,
    env,
  ) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.cardActionGood));
    await tester.tap(find.text(_en.cardActionGood), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await turnKindsOf(env.db, 'R1'), ['scheduled']);
  });

  libraryTest('after Again the card comes back as a relearning turn, with no '
      'interval and never "0d" (BR-STUDY-005, 16a)', (tester, env) async {
    final id = await openSelfAssessReview(
      env.db,
      env.decks,
      libraryToday,
      cards: 1,
    );
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardActionAgain));
    await tester.pumpAndSettle();

    // The only card of the queue comes back at its end (BR-STUDY-005).
    expect(find.text('term 1'), findsOneWidget);
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardActionGood), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+(d|mo|y)$')), findsNothing);
  });

  libraryTest('a meaning-first card prompts with the meaning; the term and '
      'the example wait for the reveal (BR-MODE-014)', (tester, env) async {
    final id = await openSelfAssessReview(
      env.db,
      env.decks,
      libraryToday,
      cards: 1,
      direction: DirectionChoice.meaningToKorean,
    );
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.text('meaning 1'), findsOneWidget);
    expect(find.text('term 1'), findsNothing);
    expect(find.text('example 1'), findsNothing);

    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('example 1'), findsOneWidget);
  });

  libraryTest('a review names its kind and mode in the context line (16a, '
      'plan R1)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(
      find.bySemanticsLabel(
        _en.studyContextReview('Lesson', _en.studyKindReview, _en.cardModeSelfAssess),
      ),
      findsOneWidget,
    );
  });

  libraryTest('at twice the text size the grades become a 2 × 2 grid, each '
      'at least 48 tall (16a)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id), textScale: 2);
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();

    final again = tester.getRect(find.widgetWithText(MxButton, _en.cardActionAgain));
    final good = tester.getRect(find.widgetWithText(MxButton, _en.cardActionGood));
    expect(good.top, greaterThan(again.bottom - 1));
    expect(again.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  libraryTest('with Remove animations on, the answer appears at once', (
    tester,
    env,
  ) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(tester, env, _screen(id));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();

    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pump();

    expect(find.text('meaning 1'), findsOneWidget);
  });
```

The deck name in the context line is the session's deck (`Lesson`, the leaf the review opened on); read `view.deckName` in the existing Browse context-line test if it differs. Use the `_screen`, `_en` helpers as `study_session_screen_test.dart` defines them.

- [ ] **Step 2:** Run the file — Expected: FAIL (Self-assess still draws `StudyModeNotBuiltWidget`).
- [ ] **Step 3: Implement.**

`study_face_card_widget.dart`:

```dart
/// One face of the card under study (kit StudyFaceCard): the label in the
/// corner, the content centred, and a recessed ground when it is the answer.
/// It shows the whole face: it scrolls, never ellipsizes (FE-A6 D19). A tap
/// on it is a shortcut only; the screen's button is the accessible path.
class StudyFaceCardWidget extends StatelessWidget {
  const StudyFaceCardWidget({
    super.key,
    required this.label,
    required this.child,
    this.isAnswer = false,
    this.onTap,
  });

  final String label;
  final Widget child;
  final bool isAnswer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = MxCard(
      isFullBleed: true,
      isRecessed: isAnswer,
      child: Stack(
        children: [
          Positioned(
            top: AppSpacing.gutter,
            left: AppSpacing.card,
            child: Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: context.textStyles.overline,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.major,
                AppSpacing.gutter,
                AppSpacing.gutter,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
```

`study_grade_row_widget.dart`:

```dart
/// Screen 16a's grades, Again · Hard · Good · Easy (sm2's supportedActions,
/// BR-STUDY-009), each with the interval it would give on a scheduled turn.
/// Again is tinted with the soft danger; the other three share the tonal
/// treatment, and the label always names the grade. At large text the row
/// becomes a 2 × 2 grid (16a). While a write runs it takes no tap
/// (BR-STUDY-004, plan R3).
class StudyGradeRowWidget extends StatelessWidget {
  const StudyGradeRowWidget({
    super.key,
    required this.intervals,
    required this.isBusy,
    required this.onGrade,
  });

  /// Action → next interval in days; null on a turn without a preview.
  final Map<Object, int>? intervals;
  final bool isBusy;
  final ValueChanged<Sm2Action> onGrade;

  /// From this text scale on, four grades no longer fit one row.
  static const double _gridTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final action in Sm2Action.values) _button(context, action),
    ];
    final isGrid =
        MediaQuery.textScalerOf(context).scale(1) >= _gridTextScale;
    final grid = isGrid
        ? Column(
            spacing: AppSpacing.control,
            children: [
              Row(
                spacing: AppSpacing.control,
                children: [Expanded(child: buttons[0]), Expanded(child: buttons[1])],
              ),
              Row(
                spacing: AppSpacing.control,
                children: [Expanded(child: buttons[2]), Expanded(child: buttons[3])],
              ),
            ],
          )
        : Row(
            spacing: AppSpacing.control,
            children: [for (final button in buttons) Expanded(child: button)],
          );
    return AbsorbPointer(absorbing: isBusy, child: grid);
  }

  Widget _button(BuildContext context, Sm2Action action) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final grade = l10n.studyGrade(action);
    final days = intervals?[action];
    final span = days == null ? null : intervalSpanOf(days);
    return Semantics(
      label: span == null
          ? grade
          : l10n.studyGradeNextIn(grade, l10n.studyIntervalLong(span, locale)),
      button: true,
      excludeSemantics: true,
      child: MxButton(
        label: grade,
        detail: span == null ? null : l10n.studyIntervalShort(span, locale),
        tone: action == Sm2Action.again
            ? MxButtonTone.dangerSoft
            : MxButtonTone.secondary,
        isBlock: true,
        onPressed: () => onGrade(action),
      ),
    );
  }
}
```

Check that `Sm2Action.values` equals `sm2Scheduler.supportedActions` in order (Task 4's grade test and this row's order); if `AppSpacing.control` is not 8, use the spacing token that is 8 (16a: "8 between the grades").

`study_self_assess_widget.dart`:

```dart
/// Screen 16a, Self-assess: the prompt, the answer once revealed, then the
/// four grades (BR-MODE-006, BR-MODE-011). Revealing writes nothing; one
/// grade commits the turn with no confirm (16a). The side asked comes from
/// the card's row (BR-MODE-014); a learning session's card asks term first.
class StudySelfAssessWidget extends StatefulWidget {
  const StudySelfAssessWidget({
    super.key,
    required this.item,
    required this.intervals,
    required this.isBusy,
    required this.onGrade,
  });

  final StudyItem item;

  /// The preview of this turn; null while it loads and on a turn without one.
  final Map<Object, int>? intervals;
  final bool isBusy;
  final ValueChanged<Sm2Action> onGrade;

  @override
  State<StudySelfAssessWidget> createState() => _StudySelfAssessWidgetState();
}

class _StudySelfAssessWidgetState extends State<StudySelfAssessWidget> {
  var _isRevealed = false;

  void _reveal() => setState(() => _isRevealed = true);

  bool get _isMeaningFirst =>
      widget.item.direction == QuestionDirection.meaningToKorean;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final termFace = StudyFaceCardWidget(
      label: l10n.studyBrowseTerm,
      isAnswer: _isMeaningFirst,
      onTap: _isMeaningFirst || _isRevealed ? null : _reveal,
      child: _TermFace(item: widget.item, isShown: !_isMeaningFirst || _isRevealed),
    );
    final meaningFace = StudyFaceCardWidget(
      label: l10n.studyBrowseMeaning,
      isAnswer: !_isMeaningFirst,
      onTap: !_isMeaningFirst || _isRevealed ? null : _reveal,
      child: _MeaningFace(
        item: widget.item,
        isShown: _isMeaningFirst || _isRevealed,
        hasExample: _isRevealed,
      ),
    );
    final (prompt, answer) = _isMeaningFirst
        ? (meaningFace, termFace)
        : (termFace, meaningFace);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.control,
              children: [Expanded(child: prompt), Expanded(child: answer)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.gutter,
            AppSpacing.gutter,
            0,
          ),
          child: _isRevealed
              ? StudyGradeRowWidget(
                  intervals: widget.intervals,
                  isBusy: widget.isBusy,
                  onGrade: widget.onGrade,
                )
              : MxButton(
                  label: l10n.studySelfAssessShowAnswer,
                  size: MxButtonSize.study,
                  onPressed: _reveal,
                ),
        ),
        SessionFooterHintWidget(
          icon: AppIcons.check,
          text: _isRevealed
              ? l10n.studySelfAssessHintGrade
              : l10n.studySelfAssessHintPrompt,
        ),
      ],
    );
  }
}
```

and the two private faces in the same file. A face hidden before the reveal draws the kit's placeholder bar (`MxSkeleton(width: 140)` without the pulse, `ExcludeSemantics`); a face that appears fades and slides in (`AnimatedSwitcher`, `AppDurations.standard`, `Easing.standard`, a `FadeTransition` over a `SlideTransition` from `Offset(0, 0.04)`), with `Duration.zero` under `MediaQuery.disableAnimationsOf(context)`:

```dart
class _TermFace extends StatelessWidget {
  const _TermFace({required this.item, required this.isShown});

  final StudyItem item;
  final bool isShown;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final pronunciation = item.pronunciation;
    return _Appearing(
      isShown: isShown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          Text(item.front, textAlign: TextAlign.center, style: styles.studyTerm),
          if (pronunciation != null)
            Text(
              pronunciation,
              textAlign: TextAlign.center,
              style: styles.studyDetail,
            ),
        ],
      ),
    );
  }
}

class _MeaningFace extends StatelessWidget {
  const _MeaningFace({
    required this.item,
    required this.isShown,
    required this.hasExample,
  });

  final StudyItem item;
  final bool isShown;

  /// The example names the term, so it waits for the reveal whichever side
  /// asks (BR-MODE-014).
  final bool hasExample;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final example = item.example;
    return _Appearing(
      isShown: isShown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          Text(item.back, textAlign: TextAlign.center, style: styles.studyMeaning),
          if (hasExample && example != null)
            Text(example, textAlign: TextAlign.center, style: styles.studyDetail),
        ],
      ),
    );
  }
}

/// The placeholder until [isShown], then [child] fading in (16a Motion).
class _Appearing extends StatelessWidget {
  const _Appearing({required this.isShown, required this.child});

  final bool isShown;
  final Widget child;

  static const double _placeholderWidth = 140;
  static const Offset _rise = Offset(0, 0.04);

  @override
  Widget build(BuildContext context) {
    final isStill = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: isStill ? Duration.zero : AppDurations.standard,
      switchInCurve: Easing.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: _rise, end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: isShown
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : const ExcludeSemantics(
              key: ValueKey(false),
              child: MxSkeleton(width: _placeholderWidth),
            ),
    );
  }
}
```

If `MxSkeleton` needs an `MxSkeletonPulse` ancestor to paint, wrap it in the pulse only when not `isStill`, or use the static form it offers — read `mx_skeleton.dart` first. Focus after the reveal (16a: "focus moves to the answer card"): after `_reveal`, `SemanticsService.announce` is not used; instead wrap the answer face in `Semantics(sortKey: …)` is not needed — `Show answer` disappears and the answer face is the next node; TalkBack moves on to it. Record that in 16a's Built note.

`study_session_screen.dart`:

- Replace the `if (view.kind == SessionKind.learning)` context line with both kinds:

```dart
          SessionContextLineWidget(
            text: switch (view.kind) {
              SessionKind.learning => l10n.studyContextLearning(
                view.deckName,
                l10n.studyKindLearning,
                view.currentStageIndex + 1,
                view.stages.length,
                mode,
              ),
              SessionKind.reviewing => l10n.studyContextReview(
                view.deckName,
                l10n.studyKindReview,
                mode,
              ),
            },
          ),
```

- In `_modeBody`, take `StudyMode.selfAssess` out of the not-built arm:

```dart
    StudyMode.selfAssess => StudySelfAssessWidget(
      key: ValueKey('${item.cardId}#${item.answersInSession}'),
      item: item,
      intervals: _previewOf(view, item),
      isBusy: turn.isBusy,
      onGrade: (action) => _grade(item, action),
    ),
```

with, in the state class,

```dart
  void _grade(StudyItem item, Sm2Action action) =>
      unawaited(_controller.answer(item, SelfAssessAnswer(action)));

  /// Watched while the card is served, so the grades have it at the reveal
  /// (plan R4). A failed read shows no interval.
  Map<Object, int>? _previewOf(StudySessionView view, StudyItem item) => ref
      .watch(
        selfAssessPreviewProvider(
          kind: view.kind,
          cardId: item.cardId,
          round: item.round,
          answersInSession: item.answersInSession,
        ),
      )
      .value;
```

(`ref.watch` in a method called from `build` is allowed; the guard only bans `ref.read` there.)

If `study_session_screen.dart` passes 400 logical lines, move `_errorPage` and `_LoadingPage` into `widgets/sections/study_session_error_widget.dart`.

- [ ] **Step 4:** Run `flutter test test/features/study/presentation/study_self_assess_test.dart test/features/study/presentation/study_session_screen_test.dart test/features/study/presentation/study_browse_test.dart` — Expected: PASS (Browse's context line is unchanged).
- [ ] **Step 5:** Commit — `feat(study): screen 16a, Self-assess with the interval preview (FE-A6 P2)`.

---

### Task 6: What the entry offers in P2

**Files:**
- Modify: `lib/features/study/presentation/states/study_entry_offer_state.dart`
- Test: `test/features/study/presentation/study_entry_offer_state_test.dart`

**Interfaces — Produces:**
- `builtStudyModes = {StudyMode.browse, StudyMode.selfAssess}`.
- `StudyEntryOffer.reviewTarget` (`ReviewModeOption?`) — the review the footer starts: the one available review mode, when exactly one is available (R10); null otherwise.
- `enum EntryFooterAction { review, learn }`; `EntryFooterAction? entryFooterActionOf(StudyEntryOffer offer)` — review when `reviewTarget != null`, else learn when `canLearn`, else null.

- [ ] **Step 1: Write the failing tests** (append; `_entry` and `_mode` exist):

```dart
  test('P2 builds Browse and Self-assess: an sm2 deck offers Learn and its '
      'one review (spec §3)', () {
    final offer = studyEntryOfferOf(
      _entry(
        type: SchedulerType.sm2,
        reviews: [_mode(StudyMode.selfAssess)],
      ),
    );

    expect(offer.canLearn, isTrue);
    expect(offer.reviewTarget?.mode, StudyMode.selfAssess);
    expect(entryFooterActionOf(offer), EntryFooterAction.review);
  });

  test('with nothing due the footer learns; with nothing new either it is '
      'not drawn', () {
    final onlyNew = studyEntryOfferOf(
      _entry(type: SchedulerType.sm2, due: 0),
    );
    final nothing = studyEntryOfferOf(
      _entry(type: SchedulerType.sm2, fresh: 0, due: 0),
    );

    expect(onlyNew.reviewTarget, isNull);
    expect(entryFooterActionOf(onlyNew), EntryFooterAction.learn);
    expect(entryFooterActionOf(nothing), isNull);
  });

  test('eight_box offers nothing yet: no built review mode, Learn coming soon '
      '(plan R10)', () {
    final offer = studyEntryOfferOf(
      _entry(reviews: [_mode(StudyMode.match), _mode(StudyMode.recall)]),
    );

    expect(offer.reviewTarget, isNull);
    expect(offer.isLearnComingSoon, isTrue);
    expect(entryFooterActionOf(offer), isNull);
  });

  test('two available review modes give no single target (picking one comes '
      'with P3)', () {
    final offer = studyEntryOfferOf(
      _entry(reviews: [_mode(StudyMode.match), _mode(StudyMode.recall)]),
      built: {StudyMode.match, StudyMode.recall},
    );

    expect(offer.reviewTarget, isNull);
  });

  test('an unavailable self-assess review is no target', () {
    final offer = studyEntryOfferOf(
      _entry(
        type: SchedulerType.sm2,
        reviews: [
          _mode(StudyMode.selfAssess, reason: ModeUnavailableReason.tooFewPairs),
        ],
      ),
    );

    expect(offer.reviewTarget, isNull);
  });
```

Update the first test ("with nothing built…") to pass `built: const {}` explicitly, since the default set now builds Self-assess.

- [ ] **Step 2:** Run the file — Expected: FAIL.
- [ ] **Step 3: Implement.** Change the set and its doc (`Browse (P1c) and Self-assess (P2)`), add the field with its doc (`/// The review the footer starts: the one available review mode (BR-STUDY-055); null with none or, until P3 adds the pick, more than one (plan R10).`), and compute it in `studyEntryOfferOf`:

```dart
  final reviews = [
    for (final option in entry.reviewModes)
      ReviewOffer(option: option, status: _statusOf(option, built)),
  ];
  final available = [
    for (final review in reviews)
      if (review.status == ReviewOfferStatus.available) review.option,
  ];
  …
    reviews: reviews,
    reviewTarget: available.length == 1 ? available.single : null,
```

and below it:

```dart
/// The footer's one action (screen 14): a review when there is one to start,
/// else Learn; null when neither can run, and the footer is not drawn.
enum EntryFooterAction { review, learn }

EntryFooterAction? entryFooterActionOf(StudyEntryOffer offer) {
  if (offer.reviewTarget != null) return EntryFooterAction.review;
  if (offer.canLearn) return EntryFooterAction.learn;
  return null;
}
```

- [ ] **Step 4:** Run the file — Expected: PASS. Run `flutter test test/features/study/presentation/study_entry_screen_test.dart` — Expected: the SM-2 test "Learn is coming soon" now FAILS (Learn is offered): rename it to "SM-2 lists no review modes on the entry; Learn is offered" and assert `find.widgetWithText(MxButton, _en.studyEntryLearn)` instead of the Coming soon badge. Everything else PASS.
- [ ] **Step 5:** Commit — `feat(study): the entry offers Self-assess (FE-A6 P2)`.

---

### Task 7: The entry's starts (controller)

**Files:**
- Create: `lib/features/study/presentation/states/study_start_state.dart`, `lib/features/study/presentation/controllers/study_entry_controller.dart`, `lib/features/study/presentation/providers/open_learning_session_use_case_provider.dart`, `lib/features/study/presentation/providers/open_review_session_use_case_provider.dart`, `test/support/study_entry_fixtures.dart`
- Modify: `test/support/library_harness.dart`
- Test: `test/features/study/presentation/study_entry_controller_test.dart`

**Interfaces — Produces:**

```dart
/// What a start asked for, kept so Try again repeats it (screen 14).
sealed class StudyStart { const StudyStart(); }
final class LearnStart extends StudyStart { const LearnStart(); }
final class ReviewStart extends StudyStart {
  const ReviewStart({required this.mode, this.direction});
  final StudyMode mode;
  final DirectionChoice? direction;
}
final class ContinueStart extends StudyStart {
  const ContinueStart(this.sessionId);
  final String sessionId;
}

enum StudyStartStatus { idle, starting, refused, failed }

final class StudyStartState {
  const StudyStartState({this.status = StudyStartStatus.idle, this.refusal, this.lastStart});
  final StudyStartStatus status;
  final StudyRejection? refusal;   // refused only
  final StudyStart? lastStart;     // refused and failed
  bool get isStarting => status == StudyStartStatus.starting;
}
```

- `StudyEntryController.build(String deckId)` → `StudyStartState()`; `Future<String?> start(StudyStart start)` answers the session to open, or null; `Future<String?> retry()` repeats `lastStart`.
- `openLearningSessionUseCaseProvider`, `openReviewSessionUseCaseProvider` (from `studyEntryRepositoryProvider`).
- `FailingEntries implements StudyEntryRepository` (forwards; `isFailing` makes both opens throw `UnknownDatabaseFailure(cause: 'test')`; `opened` counts the opens that reached the store). `LibraryEnv.entries` is one, on the fake day, and the harness overrides `studyEntryRepositoryProvider` with it.

- [ ] **Step 1: Fixture and harness.** `test/support/study_entry_fixtures.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The app's entry store; a test sets [isFailing] to make an opening fail as
/// a broken write does (screen 14 startFailed), and reads [opened].
final class FailingEntries implements StudyEntryRepository {
  FailingEntries(this._inner);

  final StudyEntryRepository _inner;
  var isFailing = false;

  /// The openings that reached the store.
  var opened = 0;

  @override
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  }) {
    opened++;
    if (isFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.openLearningSession(deckId: deckId, now: now);
  }

  @override
  Future<Outcome<String, StudyRejection>> openReviewSession({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
    DateTime? now,
  }) {
    opened++;
    if (isFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.openReviewSession(
      deckId: deckId,
      mode: mode,
      direction: direction,
      now: now,
    );
  }

  @override
  Stream<StudyEntry?> watchEntry({
    required String deckId,
    required DateTime now,
  }) => _inner.watchEntry(deckId: deckId, now: now);
}
```

In `library_harness.dart`: `LibraryEnv` gains `entries = FailingEntries(studyEntryRepository(db, clock.now))` (field doc: `/// The app's entry store, on the fake day; a test fails its openings (screen 14 startFailed).`), and `_backend` adds `studyEntryRepositoryProvider.overrideWithValue(env.entries),` with the comment `// Openings run on the fake day, as the session store does.` Run `flutter test test/features/study test/features/deck` — Expected: PASS (the entry reads the same data; only the clock of its writes moved).

- [ ] **Step 2: Write the failing tests** in `study_entry_controller_test.dart`, over `libraryContainer(env)` (a `libraryTest` that never pumps, or a plain `test` with `LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday))` and its tear-down as `libraryTest` does it):

```dart
  test('Learn opens a learning session and answers its id', () async {
    final leaf = await sm2Leaf(env, newCards: 2);
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);

    final id = await controller.start(const LearnStart());

    expect(id, isNotNull);
    expect((await sessionOf(env.db, id!)).read<String>('kind'), 'learning');
    expect(container.read(studyEntryControllerProvider(leaf)).status, StudyStartStatus.idle);
  });

  test('Review opens a self-assess review in the chosen direction', () async {
    final leaf = await sm2Leaf(env, dueCards: 2);
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);

    final id = await controller.start(
      const ReviewStart(
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.meaningToKorean,
      ),
    );

    final session = await sessionOf(env.db, id!);
    expect(session.read<String>('direction'), 'meaning_to_korean');
  });

  test('a second start while one runs is dropped (BR-STUDY-004)', () async {
    final leaf = await sm2Leaf(env, newCards: 2, dueCards: 2);
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);

    final first = controller.start(const LearnStart());
    final second = await controller.start(
      const ReviewStart(mode: StudyMode.selfAssess, direction: DirectionChoice.mixed),
    );
    await first;

    expect(second, isNull);
    expect(env.entries.opened, 1);
  });

  test('nothing left to review is refused, with its reason, and remembered '
      'for Try again', () async {
    final leaf = await sm2Leaf(env, newCards: 1);
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);

    final id = await controller.start(
      const ReviewStart(mode: StudyMode.selfAssess, direction: DirectionChoice.mixed),
    );

    final state = container.read(studyEntryControllerProvider(leaf));
    expect(id, isNull);
    expect(state.status, StudyStartStatus.refused);
    expect(state.refusal, StudyRejection.nothingDue);
  });

  test('a failed write is startFailed; Try again repeats the same start',
      () async {
    final leaf = await sm2Leaf(env, dueCards: 1);
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);
    env.entries.isFailing = true;

    expect(
      await controller.start(
        const ReviewStart(
          mode: StudyMode.selfAssess,
          direction: DirectionChoice.meaningToKorean,
        ),
      ),
      isNull,
    );
    expect(
      container.read(studyEntryControllerProvider(leaf)).status,
      StudyStartStatus.failed,
    );

    env.entries.isFailing = false;
    final id = await controller.retry();

    expect((await sessionOf(env.db, id!)).read<String>('direction'), 'meaning_to_korean');
  });

  test('Continue resumes the session and answers its id (UC-STUDY-001 A3b)',
      () async {
    final leaf = await sm2Leaf(env, newCards: 1);
    final opened = await env.entries.openLearningSession(deckId: leaf);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);

    expect(await controller.start(ContinueStart(sessionId)), sessionId);
  });

  test('Continue on a session that ended meanwhile is refused', () async {
    final leaf = await sm2Leaf(env, newCards: 1);
    final opened = await env.entries.openLearningSession(deckId: leaf);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    await env.sessions.abandonSession(sessionId: sessionId);
    final controller = container.read(studyEntryControllerProvider(leaf).notifier);

    expect(await controller.start(ContinueStart(sessionId)), isNull);
    final state = container.read(studyEntryControllerProvider(leaf));
    expect(state.status, StudyStartStatus.refused);
    expect(state.refusal, StudyRejection.sessionClosed);
  });
```

(`resumeSession` refuses an ended session as `sessionClosed` through `_live`, `study_session_repository_impl.dart`.)

with a local helper

```dart
  /// A sm2 root `Korean` > `Lesson` with [newCards] new and [dueCards]
  /// learned cards due before today. Returns the leaf's id.
  Future<String> sm2Leaf(LibraryEnv env, {int newCards = 0, int dueCards = 0}) async {
    final root = await env.decks.root('Korean', SchedulerType.sm2);
    final leaf = await env.decks.sub(root.id, 'Lesson');
    for (var i = 0; i < newCards; i++) {
      await insertCard(env.db, id: 'n$i', deckId: leaf.id, back: 'new $i');
    }
    for (var i = 0; i < dueCards; i++) {
      await insertCard(
        env.db,
        id: 'd$i',
        deckId: leaf.id,
        back: 'due $i',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
      );
    }
    if (dueCards > 0) await lockScheduler(env.db, root.id);
    return leaf.id;
  }
```

and `container.listen(studyEntryControllerProvider(leaf), (_, _) {})` before the first `read` in each test, so the autoDispose controller lives through the await (as the P1c controller tests do). `sessionOf` comes from `study_fixtures.dart`; check its column names (`kind`, `direction`) against `study_session` in `lib/core/database/`.

- [ ] **Step 3:** Run the file — Expected: FAIL (undefined names).
- [ ] **Step 4: Implement.** The two use-case providers follow `resume_study_session_use_case_provider.dart` exactly (`OpenLearningSessionUseCase(ref.watch(studyEntryRepositoryProvider))`, same for review). `study_start_state.dart` is the Interfaces block above with docs (`StudyStartStatus.refused`: `/// The store refused: the cards or the session changed since the screen opened (screen 14 refused).`; `failed`: `/// The write failed; nothing was saved (BR-STUDY-018, screen 14 startFailed).`). `study_entry_controller.dart`:

```dart
/// The Study Entry's starts (UC-STUDY-001 steps 3–5, A3b; UC-STUDY-003):
/// Learn, Review and Continue. One runs at a time (BR-STUDY-004); a refusal
/// and a failed write each leave their state for the screen, and Try again
/// repeats the last start. It answers the session to open; navigating is
/// the screen's.
@riverpod
class StudyEntryController extends _$StudyEntryController {
  /// A refusal that means the cards or the session changed meanwhile; any
  /// other refusal is a start the UI should not have made, and shows as a
  /// failed start (nothing was written either way).
  static const Set<StudyRejection> _changedMeanwhile = {
    StudyRejection.nothingToLearn,
    StudyRejection.nothingDue,
    StudyRejection.modeUnavailable,
    StudyRejection.notFound,
    StudyRejection.sessionClosed,
    StudyRejection.sessionExpired,
    StudyRejection.staleGeneration,
  };

  @override
  StudyStartState build(String deckId) => const StudyStartState();

  Future<String?> start(StudyStart start) async {
    if (state.isStarting) return null;
    state = StudyStartState(status: StudyStartStatus.starting, lastStart: start);
    try {
      final outcome = await _run(start);
      if (!ref.mounted) return null;
      switch (outcome) {
        case Ok(:final value):
          state = const StudyStartState();
          return value;
        case Rejected(:final reason):
          state = _changedMeanwhile.contains(reason)
              ? StudyStartState(
                  status: StudyStartStatus.refused,
                  refusal: reason,
                  lastStart: start,
                )
              : StudyStartState(status: StudyStartStatus.failed, lastStart: start);
          return null;
      }
    } on Failure {
      if (!ref.mounted) return null;
      state = StudyStartState(status: StudyStartStatus.failed, lastStart: start);
      return null;
    }
  }

  /// Try again: the last start, as it was asked.
  Future<String?> retry() async {
    final last = state.lastStart;
    if (last == null) return null;
    return start(last);
  }

  Future<Outcome<String, StudyRejection>> _run(StudyStart start) =>
      switch (start) {
        LearnStart() => ref.read(openLearningSessionUseCaseProvider)(
          deckId: deckId,
        ),
        ReviewStart(:final mode, :final direction) =>
          ref.read(openReviewSessionUseCaseProvider)(
            deckId: deckId,
            mode: mode,
            direction: direction,
          ),
        ContinueStart(:final sessionId) => _continue(sessionId),
      };

  Future<Outcome<String, StudyRejection>> _continue(String sessionId) async =>
      switch (await ref.read(resumeStudySessionUseCaseProvider)(
        sessionId: sessionId,
      )) {
        Ok() => Ok(sessionId),
        Rejected(:final reason) => Rejected(reason),
      };
}
```

- [ ] **Step 5:** `dart run build_runner build --delete-conflicting-outputs`; run the file — Expected: PASS. Run the guard — Expected: no `state_write_after_await_requires_mounted` finding.
- [ ] **Step 6:** Commit — `feat(study): the Study Entry's starts — Learn, Review, Continue (FE-A6 P2)`.

---

### Task 8: Screen 14's actions and the direction sheet

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/study_entry_footer_widget.dart`, `study_entry_resume_widget.dart`, `study_entry_banner_widget.dart`, `lib/features/study/presentation/widgets/overlays/study_direction_sheet_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_entry_screen.dart`, `widgets/sections/study_entry_body_widget.dart`, `widgets/sections/study_entry_learn_widget.dart`, `lib/app/router/app_router.dart`
- Test: `test/features/study/presentation/study_entry_actions_test.dart` (new, so `study_entry_screen_test.dart` stays under 400 lines); update `_screen` in `study_entry_screen_test.dart` and `study_entry_golden_test.dart`

**Interfaces:**
- Consumes: `studyEntryControllerProvider`, `StudyStart…`, `StudyStartState` (Task 7), `reviewTarget`, `entryFooterActionOf` (Task 6).
- Produces:
  - `StudyEntryScreen({…, required ValueChanged<String> onOpenSession})`.
  - `Future<DirectionChoice?> showStudyDirectionSheet(BuildContext context)` — the choice on Start review; null when dismissed.
  - `StudyEntryFooterWidget({required String deckId, required StudyEntry entry, required VoidCallback onReview, required VoidCallback onLearn, required VoidCallback onRetry})`.
  - `StudyEntryResumeWidget({required ResumableSession session, required bool isLocked, required VoidCallback onContinue})`.
  - `StudyEntryBannerWidget({required StudyStartState start})` — draws nothing unless refused or failed.

- [ ] **Step 1: Write the failing tests** in `study_entry_actions_test.dart` (same `_en`, and `_screen(deckId, {ValueChanged<String>? onOpen})` passing `onOpenSession: onOpen ?? (_) {}`; `sm2Leaf` as in Task 7, moved to `test/support/study_entry_fixtures.dart` so both files share it):

```dart
  libraryTest('Learn on the row opens a learning session (BR-STUDY-051)', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env, newCards: 2);
    String? opened;
    await pumpLibraryScreen(tester, env, _screen(leaf, onOpen: (id) => opened = id));

    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryLearn));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect((await sessionOf(env.db, opened!)).read<String>('kind'), 'learning');
  });

  libraryTest('with only new cards the footer is "Learn 2 new cards" with '
      'the nothing-due caption (kit onlyNew)', (tester, env) async {
    final leaf = await sm2Leaf(env, newCards: 2);
    await pumpLibraryScreen(tester, env, _screen(leaf));

    expect(find.widgetWithText(MxButton, _en.studyEntryLearnCta(2)), findsOneWidget);
    expect(find.text(_en.studyEntryNothingDueCaption), findsOneWidget);
  });

  libraryTest('Review opens the direction sheet, Term first chosen; Start '
      'review opens the review in that direction (UC-STUDY-003)', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env, dueCards: 3);
    String? opened;
    await pumpLibraryScreen(tester, env, _screen(leaf, onOpen: (id) => opened = id));
    expect(find.text(_en.studyEntryReviewCaption(3, 3)), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryReviewCta(3)));
    await tester.pumpAndSettle();

    final termFirst = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.studyDirectionTermFirst),
    );
    expect(termFirst.isSelected, isTrue);
    expect(find.text(_en.studyDirectionNote), findsOneWidget);

    await tester.tap(find.text(_en.studyDirectionMeaningFirst));
    await tester.pump();
    await tester.tap(find.widgetWithText(MxButton, _en.studyDirectionStart));
    await tester.pumpAndSettle();

    expect(
      (await sessionOf(env.db, opened!)).read<String>('direction'),
      'meaning_to_korean',
    );
  });

  libraryTest('closing the sheet without Start review writes nothing '
      '(BR-STUDY-020)', (tester, env) async {
    final leaf = await sm2Leaf(env, dueCards: 1);
    String? opened;
    await pumpLibraryScreen(tester, env, _screen(leaf, onOpen: (id) => opened = id));
    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryReviewCta(1)));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();

    expect(opened, isNull);
    expect(env.entries.opened, 0);
    expect(find.widgetWithText(MxButton, _en.studyEntryReviewCta(1)), findsOneWidget);
  });

  libraryTest('a failed start says so and Try again starts it again '
      '(screen 14 startFailed)', (tester, env) async {
    final leaf = await sm2Leaf(env, newCards: 1);
    String? opened;
    await pumpLibraryScreen(tester, env, _screen(leaf, onOpen: (id) => opened = id));
    env.entries.isFailing = true;

    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryLearnCta(1)));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyEntryStartFailedTitle), findsOneWidget);
    expect(opened, isNull);

    env.entries.isFailing = false;
    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryTryAgain));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
  });

  libraryTest('a start the counts no longer allow is refused with the warning '
      'banner; the footer follows the new counts (plan R5)', (tester, env) async {
    final leaf = await sm2Leaf(env, newCards: 1, dueCards: 1);
    await pumpLibraryScreen(tester, env, _screen(leaf));
    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryReviewCta(1)));
    await tester.pumpAndSettle();
    // The due card is reviewed elsewhere while the sheet is open.
    await env.db.customUpdate(
      "UPDATE card_schedule SET due_at = ? WHERE card_id = 'd0'",
      variables: [Variable<DateTime>(DateTime(2026, 10, 1))],
      updates: {env.db.cardSchedule},
    );
    await tester.tap(find.widgetWithText(MxButton, _en.studyDirectionStart));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyEntryRefusedDueTitle), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.studyEntryLearnCta(1)), findsOneWidget);
  });

  libraryTest("today's open session shows the resume banner; Continue opens "
      'it and the footer offers a new review instead (kit resume)', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env, newCards: 2, dueCards: 1);
    final started = await env.entries.openLearningSession(deckId: leaf);
    final sessionId = (started as Ok<String, StudyRejection>).value;
    String? opened;
    await pumpLibraryScreen(tester, env, _screen(leaf, onOpen: (id) => opened = id));

    expect(find.text(_en.studyEntryResumeOverline.toUpperCase()), findsOneWidget);
    expect(
      find.text(_en.studyEntryResumeLine(
        _en.studyKindLearning, _en.cardModeBrowse, 0, 2,
      )),
      findsOneWidget,
    );
    expect(find.widgetWithText(MxButton, _en.studyEntryReviewInstead), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryContinue));
    await tester.pumpAndSettle();

    expect(opened, sessionId);
  });

  libraryTest('while a session opens every action is locked and the footer '
      'says Starting… (BR-STUDY-004, kit starting)', (tester, env) async {
    final leaf = await sm2Leaf(env, newCards: 1, dueCards: 1);
    final gate = Completer<void>();
    env.entries.gate = gate.future;
    await pumpLibraryScreen(tester, env, _screen(leaf));

    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryLearn));
    await tester.pump();

    expect(find.text(_en.studyEntryStart), findsOneWidget);
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, _en.studyEntryLearn)).onPressed,
      isNull,
    );
    expect(
      tester.widget<MxButton>(find.byType(MxButton).last).isLoading,
      isTrue,
    );
    gate.complete();
    await tester.pumpAndSettle();
  });
```

The last test needs `FailingEntries.gate` (`Future<void>? gate;` awaited at the top of both opens before forwarding): add it in this task with the doc `/// When set, an opening waits for it: the screen's starting state.` Read the resume line's counts from what `ResumableSession.progress` reports for a fresh learning session (Browse round 1: 0 of 2) and adjust the expected numbers if the read model counts differently; the assertion is that the banner shows the kind, mode and counts the read model gives.

- [ ] **Step 2:** Run the file — Expected: FAIL.
- [ ] **Step 3: Implement.**

`study_direction_sheet_widget.dart`:

```dart
/// UC-STUDY-003: an sm2 review asks its direction once, here, before it
/// opens (BR-MODE-013, BR-MODE-017). Term first is chosen at first
/// (recommended). Start review answers the choice and closes the sheet (plan
/// R7); closing it any other way answers null and writes nothing
/// (BR-STUDY-020).
Future<DirectionChoice?> showStudyDirectionSheet(BuildContext context) =>
    showMxBottomSheet<DirectionChoice>(
      context,
      builder: (_) => const StudyDirectionSheetWidget(),
    );

class StudyDirectionSheetWidget extends StatefulWidget {
  const StudyDirectionSheetWidget({super.key});

  @override
  State<StudyDirectionSheetWidget> createState() =>
      _StudyDirectionSheetWidgetState();
}

class _StudyDirectionSheetWidgetState extends State<StudyDirectionSheetWidget> {
  var _choice = DirectionChoice.koreanToMeaning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const choices = DirectionChoice.values;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(l10n.studyDirectionTitle, style: context.textStyles.compactTitle),
      ),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.studyDirectionStart,
              icon: AppIcons.play,
              isBlock: true,
              onPressed: () => Navigator.of(context).pop(_choice),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, choice) in choices.indexed)
            MxOptionRow(
              title: _title(l10n, choice),
              description: _body(l10n, choice),
              isSelected: choice == _choice,
              onSelected: () => setState(() => _choice = choice),
              hasDivider: index < choices.length - 1,
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: MxNote(text: l10n.studyDirectionNote),
          ),
        ],
      ),
    );
  }

  static String _title(AppLocalizations l10n, DirectionChoice choice) =>
      switch (choice) {
        DirectionChoice.koreanToMeaning => l10n.studyDirectionTermFirst,
        DirectionChoice.meaningToKorean => l10n.studyDirectionMeaningFirst,
        DirectionChoice.mixed => l10n.studyDirectionMixed,
      };

  static String _body(AppLocalizations l10n, DirectionChoice choice) =>
      switch (choice) {
        DirectionChoice.koreanToMeaning => l10n.studyDirectionTermFirstBody,
        DirectionChoice.meaningToKorean => l10n.studyDirectionMeaningFirstBody,
        DirectionChoice.mixed => l10n.studyDirectionMixedBody,
      };
}
```

Read how `MxSheetActions.custom` lays out its children (a `Row`?) and whether other custom footers wrap them in `Expanded`; follow that.

`study_entry_banner_widget.dart`:

```dart
/// Screen 14's inline banners: refused (warning) when the cards or the
/// session changed since the screen opened, startFailed (danger) when the
/// write failed and nothing was saved (BR-STUDY-018). Nothing otherwise.
class StudyEntryBannerWidget extends StatelessWidget {
  const StudyEntryBannerWidget({super.key, required this.start});

  final StudyStartState start;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (start.status) {
      StudyStartStatus.failed => MxInlineBanner(
        tone: MxBannerTone.danger,
        title: l10n.studyEntryStartFailedTitle,
        message: l10n.studyEntryStartFailedBody,
      ),
      StudyStartStatus.refused => switch (start.refusal) {
        StudyRejection.nothingDue => MxInlineBanner(
          tone: MxBannerTone.warning,
          title: l10n.studyEntryRefusedDueTitle,
          message: l10n.studyEntryRefusedDueBody,
        ),
        StudyRejection.nothingToLearn => MxInlineBanner(
          tone: MxBannerTone.warning,
          title: l10n.studyEntryRefusedNewTitle,
          message: l10n.studyEntryRefusedNewBody,
        ),
        StudyRejection.modeUnavailable => MxInlineBanner(
          tone: MxBannerTone.warning,
          title: l10n.studyEntryRefusedModeTitle,
          message: l10n.studyEntryRefusedModeBody,
        ),
        _ => MxInlineBanner(
          tone: MxBannerTone.warning,
          title: l10n.studyEntryRefusedSessionTitle,
          message: l10n.studyEntryRefusedSessionBody,
        ),
      },
      StudyStartStatus.idle || StudyStartStatus.starting => const SizedBox.shrink(),
    };
  }
}
```

(`notFound` on the deck makes the screen leave with its toast, as P1b does; on a Continue it means the session is gone, which the last arm covers.)

`study_entry_resume_widget.dart`:

```dart
/// Screen 14's resume banner (UC-STUDY-001 A3b, BR-STUDY-072): today's open
/// session of this deck, and the choice to take it up. The dot is
/// decorative, in the primary ink (UI-base ledger row 28: no streak tone).
class StudyEntryResumeWidget extends StatelessWidget {
  const StudyEntryResumeWidget({
    super.key,
    required this.session,
    required this.isLocked,
    required this.onContinue,
  });

  final ResumableSession session;

  /// A start is running: Continue is locked (BR-STUDY-004).
  final bool isLocked;
  final VoidCallback onContinue;

  static const double _dotSize = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final kind = switch (session.kind) {
      SessionKind.learning => l10n.studyKindLearning,
      SessionKind.reviewing => l10n.studyKindReview,
    };
    final mode = l10n.studyMode(session.mode);
    final progress = session.progress;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.micro,
        children: [
          Row(
            spacing: AppSpacing.micro,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: _dotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Text(
                l10n.studyEntryResumeOverline.toUpperCase(),
                semanticsLabel: l10n.studyEntryResumeOverline,
                style: styles.overline,
              ),
            ],
          ),
          Text(
            progress == null
                ? l10n.studyEntryResumeLineNoProgress(kind, mode)
                : l10n.studyEntryResumeLine(kind, mode, progress.completed, progress.total),
            style: styles.rowTitle,
          ),
          Text(l10n.studyEntryResumeBody, style: styles.noteText),
          const SizedBox(height: AppSpacing.micro),
          MxButton(
            label: l10n.studyEntryContinue,
            icon: AppIcons.play,
            isBlock: true,
            onPressed: isLocked ? null : onContinue,
          ),
        ],
      ),
    );
  }
}
```

Use the row-title role the entry's Learn row already uses (`grep -n "TextStyle get rowTitle\|compactTitle" lib/core/theme/mx_text_styles.dart`); `BoxDecoration(color:)` on a decorative dot is the pattern Browse's hairline uses (`ColoredBox`) — if the guard flags it, add a `MxDot` to `lib/shared/widgets` under `flutter-theme-design` instead.

`study_entry_footer_widget.dart`:

```dart
/// Screen 14's footer: one block action with its caption (kit), or nothing
/// when the entry offers no start. While a session opens the button spins
/// and the caption says so (BR-STUDY-004, plan R6); after a failed write it
/// is Try again.
class StudyEntryFooterWidget extends ConsumerWidget {
  const StudyEntryFooterWidget({
    super.key,
    required this.deckId,
    required this.entry,
    required this.onReview,
    required this.onLearn,
    required this.onRetry,
  });

  final String deckId;
  final StudyEntry entry;
  final VoidCallback onReview;
  final VoidCallback onLearn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final start = ref.watch(studyEntryControllerProvider(deckId));
    final offer = studyEntryOfferOf(entry);
    final action = entryFooterActionOf(offer);
    if (start.status == StudyStartStatus.failed) {
      return MxFooterBar(
        child: MxButton(
          label: l10n.studyEntryTryAgain,
          icon: AppIcons.retry,
          isBlock: true,
          onPressed: onRetry,
        ),
      );
    }
    if (action == null) return const SizedBox.shrink();
    final target = offer.reviewTarget;
    final (label, icon, caption, onPressed) = switch (action) {
      EntryFooterAction.review => (
        entry.resumable == null
            ? l10n.studyEntryReviewCta(target!.cardCount)
            : l10n.studyEntryReviewInstead,
        AppIcons.play,
        l10n.studyEntryReviewCaption(target!.cardCount, entry.dueCardCount),
        onReview,
      ),
      EntryFooterAction.learn => (
        l10n.studyEntryLearnCta(offer.learnShown),
        AppIcons.starterDecks,
        entry.dueCardCount == 0 ? l10n.studyEntryNothingDueCaption : null,
        onLearn,
      ),
    };
    return MxFooterBar(
      caption: start.isStarting ? l10n.studyEntryStart : caption,
      child: MxButton(
        label: label,
        icon: icon,
        isBlock: true,
        isLoading: start.isStarting,
        onPressed: onPressed,
      ),
    );
  }
}
```

(The `!` on `target` holds because `EntryFooterAction.review` means `reviewTarget != null`; bind it once with a `final target = offer.reviewTarget!;` inside the review arm if the analyzer prefers.)

`study_entry_screen.dart`: add `required this.onOpenSession` (`/// Opens the session a start answered; composed by app/.`). The shell gets `footer:` from a `switch` on `ref.watch(studyEntryProvider(deckId))`: `AsyncData(value: Ok(:final value)) => StudyEntryFooterWidget(deckId: deckId, entry: value, onReview: () => _review(context, ref, value), onLearn: () => _start(context, ref, const LearnStart()), onRetry: () => _retry(context, ref))`, else `null`. Methods:

```dart
  Future<void> _start(BuildContext context, WidgetRef ref, StudyStart start) =>
      _open(context, ref.read(studyEntryControllerProvider(deckId).notifier).start(start));

  Future<void> _retry(BuildContext context, WidgetRef ref) =>
      _open(context, ref.read(studyEntryControllerProvider(deckId).notifier).retry());

  /// An sm2 review asks its direction first (UC-STUDY-003); a dismissed
  /// sheet starts nothing (BR-STUDY-020).
  Future<void> _review(BuildContext context, WidgetRef ref, StudyEntry entry) async {
    final target = studyEntryOfferOf(entry).reviewTarget;
    if (target == null) return;
    DirectionChoice? direction;
    if (target.isDirectionRequired) {
      direction = await showStudyDirectionSheet(context);
      if (direction == null || !context.mounted) return;
    }
    await _start(context, ref, ReviewStart(mode: target.mode, direction: direction));
  }

  Future<void> _open(BuildContext context, Future<String?> started) async {
    final sessionId = await started;
    if (sessionId == null || !context.mounted) return;
    onOpenSession(sessionId);
  }
```

(Call them as `() => unawaited(_start(…))` in the callbacks.)

`study_entry_body_widget.dart`: under the hero, when `entry.resumable != null && offer.canContinue`, a `StudyEntryResumeWidget(session: entry.resumable!, isLocked: start.isStarting, onContinue: …)` — the body becomes the place that watches `studyEntryControllerProvider(deckId)`; it takes `onLearn` and `onContinue(String sessionId)` from the screen (same `_start` path with `ContinueStart`). After the Learn row and the review list, `StudyEntryBannerWidget(start: start)` with `AppSpacing.grouped` above it. `StudyEntryLearnWidget.onLearn` becomes required-nullable as it is and receives `start.isStarting ? null : onLearn`.

`app_router.dart`: `_studyEntry` takes the context:

```dart
StudyEntryScreen _studyEntry(BuildContext context, String deckId) => StudyEntryScreen(
  deckId: deckId,
  title: …as today…,
  breadcrumb: …as today…,
  onOpenSession: (sessionId) => context.go(AppRoutes.studySession(sessionId)),
);
```

and its builder passes `context`. In the two existing test helpers `_screen` add `onOpenSession: (_) {}`.

- [ ] **Step 4:** Run `flutter test test/features/study test/app` — Expected: PASS.
- [ ] **Step 5:** Run `flutter analyze` and the guard — Expected: clean. Run `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` — Expected: PASS.
- [ ] **Step 6:** Commit — `feat(study): screen 14's Learn, Review, Continue and the direction sheet (FE-A6 P2, FE-A7)`.

---

### Task 9: Goldens and visual audit

**Files:**
- Create: `test/visual_audit/screens/features/study/overlays/study_direction_sheet_visual_audit_test.dart` (follow the nearest existing overlay companion; `grep -rln "Sheet" test/visual_audit/screens`), goldens
- Modify: `test/visual_audit/screens/features/study/screens/study_session_screen_visual_audit_test.dart`, `study_entry_screen_visual_audit_test.dart`, `test/features/study/presentation/study_entry_golden_test.dart`, `study_session_golden_test.dart`

- [ ] **Step 1: Companions.** Session companion: a third `libraryTest` auditing a self-assess review after the reveal (two cards, Latin text). Entry companion: the resume state (an open learning session) and the refused state. The direction sheet: its own companion opened from the entry's Review. Run `flutter test test/visual_audit` — Expected: PASS, including `screen_audit_coverage_test.dart`.
- [ ] **Step 2: Goldens** (tag `golden`, both brightnesses, `pumpLibraryGolden`, deck "Động từ" with Vietnamese/Latin cards):
  - entry: `study_entry_sm2` and `study_entry_only_new` regenerate (Learn button and footer now drawn — look at both against `img/14-study-entry/sm2-light.png`, `onlyNew-light.png`); new `study_entry_resume`, `study_entry_starting` (the gate of Task 8), `study_entry_refused`, `study_entry_start_failed`, `study_direction_sheet`.
  - session: `study_self_assess_prompt` (front `ăn uống`, back `to eat and drink`, pronunciation `an uong`, example `Tôi ăn sáng lúc 7 giờ.`), `study_self_assess_revealed` (with intervals), `study_self_assess_relearning` (after Again, revealed, no intervals), `study_self_assess_meaning_first`, `study_self_assess_large_text` (text scale 2, revealed: the 2 × 2 grid).
  - Run `TZ=UTC flutter test --tags golden --update-goldens test/features/study`, then `TZ=UTC flutter test --tags golden` — Expected: every golden passes; `git status` shows only the new files and the two regenerated entry goldens (and Task 2's button/card goldens, if regenerated there).
  - Open each new PNG and compare it with the kit frames (entry) and with 16/19's frames (self-assess, which has no kit frame: 16a).
- [ ] **Step 3:** Commit — `test(study): self-assess, entry actions and direction sheet goldens and visual audit (FE-A6 P2)`.

---

### Task 10: Records

- [ ] `docs/shared/ui/screen-handoff/14-study-entry.md`: replace the "Built so far (FE-A6 P1b)" paragraph with "Built (FE-A6 P2)": all nine states on `sm2`; `eight_box` stays read-only until its modes are built (R10). Deviations table: R5 (refused keeps the footer live), R6 ("Starting…" in the caption), R7 (the sheet closes on Start review), R8 (the review caption without the direction), R9 (four refusal titles), and the Learn button's glyph (`starterDecks`, the sparkles of the kit). Copy: add the new refusal lines and the footer captions.
- [ ] `16a-study-self-assess.md`: a "Built (FE-A6 P2)" note — the preview is `PreviewSelfAssessIntervalsUseCase` (answers the "Open for FE-A6 planning" item and remove it), the face card and grade row, the footer hints, focus moving to the answer face as the next node after Show answer disappears; deviations R1 (the name), R2 (the answer face always laid out), R3 (no spinner), R4 (preview loads with the card); goldens listed.
- [ ] `docs/shared/ui/design-handoff/`: the `MxButton` entry gains `detail` and the `dangerSoft` tone, `MxCard` gains `isRecessed` (find the files with `grep -rln "MxButtonTone\|isDanger" docs/shared/ui/design-handoff`).
- [ ] Index rows 14 → `built (P2)` and 16a → `built (P2)`; `docs/wbs_FE.md`: FE-A6 evidence adds this plan, next "Phase P3: Guess 18, Match 17"; FE-A7 → `xong` with this plan as evidence (the direction sheet is its whole scope; check FE-A7's row text first and keep its format).
- [ ] Spec: §3's P2 row gains "Study entry's actions (Learn, Review, Continue; starting, refused, startFailed; resume)", since P1 left them to P2.
- [ ] `python3 tools/docs/generate.py && python3 tools/docs/check.py` — Expected: 0 errors.
- [ ] `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `TZ=UTC flutter test --tags golden` — Expected: green.
- [ ] Commit — `docs(study): P2 records — handoffs 14 and 16a, index, WBS (FE-A6, FE-A7)`.
