# TOPIK screen 37 (attempt) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A person takes a TOPIK test in Practice mode: one question per page under its group's instruction, passage or audio, picks and changes answers that save at once, moves by Previous, Next or the question grid, leaves and comes back without losing anything, and submits, confirming when questions are blank (UC-TOPIK-003, BR-TOPIK-010…017, -019; spec §5, §8, §13.6). Plan 6b of Phase 2 (§13.9 item 6), epic DEV-394.

**Architecture:**
- `StudyChoiceWidget` moves to `lib/shared/widgets/mx_choice_tile.dart` as `MxChoiceTile`. This is the owner's brief of 2026-10-15; the study goldens must not change.
- In `lib/features/topik/presentation/`:
  - A stream provider of the attempt view.
  - `TopikAttemptController`, which holds the event-driven question clock (§13.6) and guards the submit.
  - `TopikAudioController`, over the plan-5 player.
  - The section widgets: two panes, group pane, audio bar, question pane, footer.
  - Two overlays: the question grid sheet and the speed sheet.
  - `TopikAttemptScreen`.
- `lib/app/router/topik_routes.dart` adds `/study/topik/attempt/:attemptId` on the root navigator.

**Tech Stack:**
- Flutter 3.47.5 and Riverpod 3 codegen.
- go_router 18.
- `intl` `NumberFormat`.
- The `Mx*` shared widgets.
- The plan-5 audio repository.
- The golden harness (`test/support/library_harness.dart`).

**Spec:**
- `docs/superpowers/specs/2026-10-15-topik-practice-design.md` §5, §8, §13.6, §13.8, §13.10.
- Detail file `docs/shared/ui/screen-handoff/37-topik-attempt.md`.
- Rules BR-TOPIK-010…017 and -019; UC-TOPIK-003.
- The pre-plan critique `critique-37.md` (findings F1–F14, adopted below).

## Global Constraints

- **File and code rules:**
  - Every presentation file ends `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
  - No `ref.read` in `build`. No `BuildContext` or `WidgetRef` in a controller.
  - A `mounted` / `ref.mounted` check before any state write after an await.
- **Shared widgets and the guard:**
  - No raw `InkWell`, `Slider`, bare `Icon` or Material button in feature code.
  - A tappable cell is an `MxRowInk`; a glyph is an `MxIconButton`.
- **Copy:**
  - Every new key goes in `app_en.arb`, with `"@key"` holding its `placeholders` first and its `description` last, and in `app_vi.arb`. Then run `flutter gen-l10n`.
  - Korean content is never localized.
  - Failure copy is local-first.
- **One primary per decision (One Accent):** Next or Submit in the footer is the one primary; the grid opener is outline (F1).
- **The Content Gate Rule:** the footer and the grid exist only while answering. Close stays in every state (F8).
- **Time comes from `dayClockProvider`:** the controller adds `now − since` to the current question on every answer, move, background transition and exit (spec §5.4). Tests move a `FakeDayClock`.
- **Audio** is never played on its own. A group's clip loads when its bar appears, and another group's clip pauses the previous one (spec §5.5; the plan-5 repository does the pausing).
- **`MxChoiceTile` keeps `StudyChoiceWidget`'s pixels:** `run_goldens.sh` without `--update` passes for every `study_*` golden after Task 1.
- **Goldens:** English, light and dark, 1080×2400 at 3x, through `pumpLibraryGolden` + `expectBoundaryGolden`, run only by `run_goldens.sh`. Every new or changed golden goes on the `golden-compare` page.
- **The summary route is plan 6c:** Submit replaces the attempt with `/study/topik/attempt/:id/summary`, which lands on `RouteNotFoundScreen` until 6c. No content ships yet, so no one reaches it before then.
- **Commits** name DEV-394 and end with the session's attribution lines.

## Review Focus

1. **The question clock** (BR-TOPIK-015): time goes to the question that was current, adds up when the person returns to it, does not run while the app is in the background, and is written on exit (Task 2).
2. **Double submit** (BR-TOPIK-014): a second tap on Submit, Back while submitting, and any answer after it do nothing. A refused submit lets the person go on (Tasks 2, 5).
3. **A write that fails** (UC-TOPIK-003 E4): the option is not shown as chosen, a snackbar says so, and nothing else changes (Task 5).
4. **The attempt gone or the content changed** (UC-TOPIK-003 E2, BR-TOPIK-019):
   - attemptMissing when the attempt is deleted or the account is switched while the screen is open;
   - contentMissing offers Delete;
   - a deep link to a submitted attempt offers its Summary (Tasks 2, 5).
5. **Audio across questions** (BR-TOPIK-017): the clip stays as it is between the questions of one group; a failed load shows Retry, and answering still works (Tasks 3, 5).

---

### Task 1: `MxChoiceTile` (promote `StudyChoiceWidget`)

**Files:**
- Move: `lib/features/study/presentation/widgets/support/study_choice_widget.dart` → `lib/shared/widgets/mx_choice_tile.dart`
- Modify:
  - `lib/features/study/presentation/widgets/sections/study_guess_widget.dart`
  - `lib/features/study/presentation/widgets/sections/study_match_widget.dart`
  - `test/features/study/presentation/study_match_test.dart`
  - `test/features/study/presentation/study_support_widgets_test.dart`
  - `lib/app/gallery/gallery_inputs_section.dart`
  - `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb` (gallery copy)
  - `docs/shared/design/m3-adoption-ledger.md`
- Test:
  - `test/shared/widgets/mx_choice_tile_test.dart`
  - `test/shared/widgets/input_widgets_golden_test.dart` (goldens `mx_choice_tile_{light,dark}.png`)

**Interfaces:**
- Produces:
  - `enum MxChoiceTone { idle, selected, right, wrong }`
  - `class MxChoiceTile` with the same constructor as `StudyChoiceWidget`: `tone`, `builder`, `semanticsLabel`, `padding`, `isSelected`, `isFaded`, `isRecessed`, `sortKey`, `onTap`.

- [ ] **Step 1: Write the shared widget's tests (they fail: the file does not exist)**

`test/shared/widgets/mx_choice_tile_test.dart`:

```dart
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: brightness == Brightness.light
          ? buildLightTheme()
          : buildDarkTheme(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );

MxChoiceTile _tile({
  MxChoiceTone tone = MxChoiceTone.idle,
  bool isSelected = false,
  VoidCallback? onTap,
}) => MxChoiceTile(
  tone: tone,
  isSelected: isSelected,
  semanticsLabel: 'Option 1, 보기 1',
  padding: const EdgeInsets.all(16),
  onTap: onTap,
  builder: (foreground) => Text('① 보기 1', style: TextStyle(color: foreground)),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxChoiceTile),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

// The study choice surface, shared (TOPIK spec §13.10): Guess, Match and the
// TOPIK attempt's options.
void main() {
  testWidgets('one node: its label, a button, selected, and its tap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(_tile(isSelected: true, onTap: () => taps++)),
    );

    final node = tester.getSemantics(find.byType(MxChoiceTile));
    final flags = node.getSemanticsData().flagsCollection;
    expect(node.label, 'Option 1, 보기 1');
    expect(flags.isButton, isTrue);
    expect(flags.isSelected, Tristate.isTrue);
    await tester.tap(find.byType(MxChoiceTile));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('without a tap it is inert and not a button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_tile()));

    final node = tester.getSemantics(find.byType(MxChoiceTile));
    expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('at least a control tall, whatever its content', (tester) async {
    await tester.pumpWidget(
      _host(
        MxChoiceTile(
          tone: MxChoiceTone.idle,
          semanticsLabel: 'a',
          builder: (_) => const SizedBox(height: 4),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MxChoiceTile)).height,
      greaterThanOrEqualTo(const AppDimens().sizeControl),
    );
  });

  testWidgets('selected is the primary fill with the content on primary', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_tile(tone: MxChoiceTone.selected)));
    await tester.pumpAndSettle();

    final colors = buildLightTheme().colorScheme;
    expect(_decoration(tester).color, colors.primary);
    final text = tester.widget<Text>(find.text('① 보기 1'));
    expect(text.style?.color, colors.onPrimary);
  });

  testWidgets('idle is the card ground with the content on surface', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_tile()));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('① 보기 1'));
    expect(text.style?.color, buildLightTheme().colorScheme.onSurface);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_choice_tile_test.dart`
Expected: FAIL to compile, because `package:memox/shared/widgets/mx_choice_tile.dart` does not exist.

- [ ] **Step 2: Move and rename**

```bash
git mv lib/features/study/presentation/widgets/support/study_choice_widget.dart lib/shared/widgets/mx_choice_tile.dart
rg -l 'StudyChoiceWidget|StudyChoiceTone|study_choice_widget' lib test | xargs sed -i \
  -e 's/StudyChoiceWidget/MxChoiceTile/g' \
  -e 's/StudyChoiceTone/MxChoiceTone/g' \
  -e 's#package:memox/features/study/presentation/widgets/support/study_choice_widget.dart#package:memox/shared/widgets/mx_choice_tile.dart#g'
```

Then replace the class comment in `lib/shared/widgets/mx_choice_tile.dart` (the lines from `/// How a choice reads` through `/// state in one semantics node, and fades when it is out of play.`) with:

```dart
/// How a choice reads: untouched, picked, answered right or wrong.
enum MxChoiceTone { idle, selected, right, wrong }

/// A toned, tappable answer surface: a Guess option (screen 18), a Match
/// tile (screen 17), a TOPIK option (screen 37, idle and selected only,
/// BR-TOPIK-016). It is at least a control tall, carries its label and state
/// in one semantics node, and fades when it is out of play. Promoted from
/// the study feature when TOPIK became its second user (owner brief
/// 2026-10-15); its look did not change.
```

The test file renamed by `sed` keeps its asserts; the study tests now import the shared file.

- [ ] **Step 3: Run the moved and new tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_choice_tile_test.dart test/features/study/presentation/study_match_test.dart test/features/study/presentation/study_support_widgets_test.dart test/features/study/presentation/study_guess_test.dart`
Expected: PASS.

- [ ] **Step 4: Goldens of the shared widget, and the study goldens unchanged**

Append to `test/shared/widgets/input_widgets_golden_test.dart`, inside `main()` after the `MxSlider` test, and add `import 'package:memox/shared/widgets/mx_choice_tile.dart';`:

```dart
  testWidgets('MxChoiceTile: idle, selected, right, wrong, faded', (
    tester,
  ) async {
    Widget tile(MxChoiceTone tone, String text, {bool isFaded = false}) =>
        MxChoiceTile(
          tone: tone,
          isFaded: isFaded,
          semanticsLabel: text,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () {},
          builder: (foreground) => Text(
            text,
            style: TextStyle(color: foreground, fontSize: 16),
          ),
        );
    await expectThemedGoldens(
      tester,
      'mx_choice_tile',
      SizedBox(
        width: 320,
        child: Column(
          spacing: 8,
          children: [
            tile(MxChoiceTone.idle, '① 보기 1'),
            tile(MxChoiceTone.selected, '② 보기 2'),
            tile(MxChoiceTone.right, '③ 보기 3'),
            tile(MxChoiceTone.wrong, '④ 보기 4'),
            tile(MxChoiceTone.idle, '보기', isFaded: true),
          ],
        ),
      ),
    );
  });
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then `git status --short -- '*.png'`
Expected: only `test/shared/widgets/goldens/mx_choice_tile_light.png` and `mx_choice_tile_dark.png` are new; no `study_*` golden changed. A changed study golden is a regression: undo it and find why before going on.

- [ ] **Step 5: Gallery entry and ledger row**

1. Add to `lib/l10n/app_en.arb` and `app_vi.arb`, after `gallerySeekBar`:
   - `galleryChoiceIdle`: en "An option", vi "Một phương án", description "Gallery: an idle MxChoiceTile."
   - `galleryChoiceSelected`: en "The chosen option", vi "Phương án đã chọn", description "Gallery: a selected MxChoiceTile."

   Then run `flutter gen-l10n`.

2. In `lib/app/gallery/gallery_inputs_section.dart`, add `import 'package:memox/shared/widgets/mx_choice_tile.dart';`. Right after the `MxSlider(...)` child, add:

```dart
      for (final (index, label) in [
        context.l10n.galleryChoiceIdle,
        context.l10n.galleryChoiceSelected,
      ].indexed)
        MxChoiceTile(
          tone: index == _choice ? MxChoiceTone.selected : MxChoiceTone.idle,
          isSelected: index == _choice,
          semanticsLabel: label,
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space16,
            vertical: context.dimens.space12,
          ),
          onTap: () => setState(() => _choice = index),
          builder: (foreground) => Text(
            label,
            style: context.texts.bodyLarge?.copyWith(color: foreground),
          ),
        ),
```

   with a state field `var _choice = 1;` beside `_seekPosition`.

3. In `docs/shared/design/m3-adoption-ledger.md`, add after the `| MxSlider |` row of the component table:

```markdown
| MxChoiceTile | `mx_choice_tile.dart` | Selection | single choice (idle, selected; study adds right, wrong) | rest, pressed (no ripple: a toned surface), selected, faded, inert | none (`cardSurface`, `primary`, `success`, `error`, `MxTintBase` tints) | Guess (18), Match (17), TOPIK attempt (37) | not an M3 component: the study choice surface of DESIGN.md (Study-specific) | PASS (tones, node, inert, size) |  | T:mx_choice_tile_test.dart::one node: its label, a button, selected, and its tap; ::without a tap it is inert and not a button; ::at least a control tall, whatever its content; ::selected is the primary fill with the content on primary; ::idle is the card ground with the content on surface; G:mx_choice_tile_light.png, mx_choice_tile_dark.png; study_guess_*, study_match_* unchanged | none |
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/gallery_test.dart test/shared/widgets/mx_choice_tile_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A lib/shared/widgets/mx_choice_tile.dart lib/features/study lib/app/gallery lib/l10n test/shared test/features/study docs/shared/design/m3-adoption-ledger.md
git commit -m "refactor(shared): DEV-394 MxChoiceTile, the study choice surface promoted for TOPIK"
```

---
### Task 2: Copy, the attempt view, providers and the attempt controller

**Files:**
- Modify:
  - `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`
  - `lib/features/topik/domain/models/topik_views_model.dart`
  - `lib/features/topik/presentation/widgets/support/topik_labels_widget.dart`
- Create, all in `lib/features/topik/presentation/providers/`:
  - `watch_topik_attempt_use_case_provider.dart`
  - `topik_attempt_provider.dart`
  - `answer_topik_question_use_case_provider.dart`
  - `move_topik_question_use_case_provider.dart`
  - `record_topik_time_use_case_provider.dart`
  - `submit_topik_attempt_use_case_provider.dart`
- Create: `lib/features/topik/presentation/controllers/topik_attempt_controller.dart`
- Test:
  - `test/features/topik/domain/topik_use_cases_test.dart` (one test added)
  - `test/features/topik/presentation/topik_labels_test.dart` (one test added)
  - `test/features/topik/presentation/topik_attempt_controller_test.dart`

**Interfaces:**
- Consumes:
  - `WatchTopikAttemptUseCase`, `AnswerTopikQuestionUseCase`, `MoveTopikQuestionUseCase`, `RecordTopikTimeUseCase`, `SubmitTopikAttemptUseCase` (plan 4).
  - `deleteTopikAttemptUseCaseProvider` (plan 6a).
- Produces:
  - `TopikAttemptView.isContentMissing` (bool).
  - The providers:
    - `topikAttemptProvider(String attemptId)` → `Stream<TopikAttemptView?>`
    - `answerTopikQuestionUseCaseProvider`, `moveTopikQuestionUseCaseProvider`, `recordTopikTimeUseCaseProvider`, `submitTopikAttemptUseCaseProvider`
  - `topikAttemptControllerProvider(String attemptId)`. Its state is a `bool` (a submit runs or ran). Its methods:
    - `answer({required int questionNo, required int selectedIdx})` → `Future<Outcome<void, TopikRejection>?>`
    - `move(int toQuestionNo)` → `Future<Outcome<void, TopikRejection>?>`
    - `pause()`, `resume()`, `leave()`
    - `submit(String testId)` → `Future<Outcome<TopikAttempt, TopikRejection>?>`
    - `delete()` → `Future<Outcome<void, TopikRejection>?>`
  - Top-level functions `topikClockText(int ms)` and `topikCircled(int idx)`; on `TopikLabels`, `topikSpeedText(double speed)`.
  - The l10n keys below.

- [ ] **Step 1: Add the copy**

```bash
python3 - <<'EOF'
import json
S = {"type": "String"}
I = {"type": "int"}
KEYS = [
 ("topikClose", "Close", "Đóng", "Screen 37: leaves the attempt; nothing is lost (BR-TOPIK-010).", None),
 ("topikShowScript", "Show script", "Hiện lời thoại", "Screen 37: shows a listening group's script and its translation.", None),
 ("topikHideScript", "Hide script", "Ẩn lời thoại", "Screen 37: hides the script again.", None),
 ("topikShowPassage", "Show passage", "Hiện phần đề", "Screen 37: expands the group pane.", None),
 ("topikHidePassage", "Hide passage", "Ẩn phần đề", "Screen 37: collapses the group pane to its instruction.", None),
 ("topikPlay", "Play", "Phát", "Screen 37: the audio bar's play button.", None),
 ("topikPause", "Pause", "Tạm dừng", "Screen 37: the audio bar's pause button.", None),
 ("topikAudioPosition", "Audio position", "Vị trí âm thanh", "Screen 37: the seek bar's label.", None),
 ("topikClockOfTotal", "{position} / {length}", "{position} / {length}", "Screen 37: where the audio is, of its length, as 0:42 / 1:33.", {"position": S, "length": S}),
 ("topikSpeed", "{speed}×", "{speed}×", "Screen 37: a playback speed, as 1× or 0.75×.", {"speed": S}),
 ("topikPlaybackSpeed", "Playback speed", "Tốc độ phát", "Screen 37: the speed sheet's title and the speed chip's label.", None),
 ("topikAudioFailed", "Couldn't play this audio", "Không phát được âm thanh này", "Screen 37: the audio banner's title (BR-TOPIK-017).", None),
 ("topikAudioFailedBody", "Your answers are safe.", "Câu trả lời của bạn vẫn an toàn.", "Screen 37: the audio banner says first that nothing was lost.", None),
 ("topikPrevious", "Previous", "Câu trước", "Screen 37: the previous question.", None),
 ("topikNext", "Next", "Câu sau", "Screen 37: the next question.", None),
 ("topikQuestions", "Questions", "Danh sách câu", "Screen 37: opens the question grid, and the grid sheet's title.", None),
 ("topikSubmit", "Submit", "Nộp bài", "Screen 37: submits the attempt (BR-TOPIK-013).", None),
 ("topikQuestionAnswered", "Question {no}, answered", "Câu {no}, đã trả lời", "Screen 37: a grid cell to TalkBack.", {"no": I}),
 ("topikQuestionBlank", "Question {no}, not answered", "Câu {no}, chưa trả lời", "Screen 37: a grid cell to TalkBack.", {"no": I}),
 ("topikQuestionStem", "{no}. {stem}", "{no}. {stem}", "Screen 37: the real question number, then its Korean stem.", {"no": I, "stem": S}),
 ("topikOptionLabel", "Option {number}, {text}", "Phương án {number}, {text}", "Screen 37: an option to TalkBack; selected is said by its state.", {"number": I, "text": S}),
 ("topikUnansweredTitle", "{count, plural, =1{1 question unanswered} other{{count} questions unanswered}}", "Còn {count} câu chưa trả lời", "Screen 37: the submit confirm's title (BR-TOPIK-014).", {"count": I}),
 ("topikUnansweredBody", "Unanswered questions score 0. Submit anyway?", "Câu chưa trả lời được 0 điểm. Vẫn nộp bài?", "Screen 37: the submit confirm's body.", None),
 ("topikKeepAnswering", "Keep answering", "Làm tiếp", "Screen 37: the submit confirm's cancel.", None),
 ("topikBackToTest", "Back to the test", "Về đề thi", "Screen 37: leaves an attempt that is gone.", None),
 ("topikContentChangedTitle", "This test changed and can't be continued", "Đề này đã thay đổi, không làm tiếp được", "Screen 37: the attempt's test is gone or changed (BR-TOPIK-019).", None),
 ("topikSubmittedTitle", "This attempt was submitted", "Lượt làm này đã nộp", "Screen 37: a link to an attempt already submitted.", None),
 ("topikSeeSummary", "See summary", "Xem tổng kết", "Screen 37: opens a submitted attempt's summary.", None),
 ("topikChoiceNotSaved", "Your choice wasn't saved. Try again.", "Chưa lưu được lựa chọn. Thử lại nhé.", "Screen 37: an answer the database refused (UC-TOPIK-003 E4).", None),
 ("topikPicture", "Picture", "Hình", "Screen 37: a passage or option picture to TalkBack.", None),
 ("topikLoadingAttempt", "Loading the attempt", "Đang tải lượt làm", "Screen 37: what the skeleton is.", None),
 ("topikAttemptErrorTitle", "Couldn't load this attempt", "Không tải được lượt làm này", "Screen 37: load error title.", None),
]
for lang in ("en", "vi"):
    path = f"lib/l10n/app_{lang}.arb"
    data = json.load(open(path))
    out = {}
    for key, value in data.items():
        out[key] = value
        if key == ("@topikRefused" if lang == "en" else "topikRefused"):
            for name, en, vi, description, placeholders in KEYS:
                out[name] = en if lang == "en" else vi
                if lang == "en":
                    meta = {}
                    if placeholders:
                        meta["placeholders"] = placeholders
                    meta["description"] = description
                    out["@" + name] = meta
    json.dump(out, open(path, "w"), ensure_ascii=False, indent=2)
    open(path, "a").write("\n")
EOF
flutter gen-l10n
```

Expected: `flutter gen-l10n` prints no error; `rg -c '"topik' lib/l10n/app_vi.arb` grows by 32.

- [ ] **Step 2: Write the failing tests for the view, the labels and the controller**

Add to `test/features/topik/domain/topik_use_cases_test.dart` (and `import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';`), inside `main()`:

```dart
  test('the attempt view says when its content is missing (BR-TOPIK-019)', () async {
    final attempt = topikOk(
      await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
    );
    final watch = WatchTopikAttemptUseCase(catalog, attempts);

    final view = (await watch(attempt.id).first)!;
    expect(view.isContentMissing, isFalse);
    // The test's questions are no longer the attempt's (a content change the
    // validator lets through would show this way).
    final fewer = TopikAttemptView(
      detail: TopikAttemptDetail(
        attempt: view.detail.attempt,
        answers: view.detail.answers.skip(1).toList(),
      ),
      test: view.test,
    );
    expect(fewer.isContentMissing, isTrue);
    catalog.tests = [];
    expect((await watch(attempt.id).first)!.isContentMissing, isTrue);
  });
```

Add to `test/features/topik/presentation/topik_labels_test.dart`, inside `main()`:

```dart
  test('audio clock, speed and option numbers (screen 37)', () {
    expect(topikClockText(0), '0:00');
    expect(topikClockText(42999), '0:42');
    expect(topikClockText(93000), '1:33');
    expect(en.topikSpeedText(1), '1');
    expect(en.topikSpeedText(0.75), '0.75');
    expect(vi.topikSpeedText(1.25), '1,25');
    expect([for (var idx = 1; idx <= 4; idx++) topikCircled(idx)].join(), '①②③④');
  });
```

`test/features/topik/presentation/topik_attempt_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_attempt_controller.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 37's clock and submit guard (spec §5.4, §13.6; BR-TOPIK-014, -015).
void main() {
  final test0 = topikTestFixture();
  late LibraryEnv env;
  late TopikAttemptRepositoryImpl store;

  setUp(() {
    env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    store = TopikAttemptRepositoryImpl(env.db, now: env.clock.now);
  });
  tearDown(() => env.db.close());

  Future<TopikAttempt> open() async =>
      topikOk(await store.start(test0, now: libraryToday));

  ({ProviderContainer container, TopikAttemptController controller}) control(
    String attemptId, {
    bool hasContent = true,
  }) {
    final container = libraryContainer(
      env,
      overrides: topikContentOverrides(hasContent ? [test0] : []),
    );
    final provider = topikAttemptControllerProvider(attemptId);
    container.listen(provider, (_, _) {});
    return (container: container, controller: container.read(provider.notifier));
  }

  Future<Map<int, int>> times(String attemptId) async {
    final detail = (await store.watchAttempt(attemptId).first)!;
    return {
      for (final answer in detail.answers)
        if (answer.timeSpentMs > 0) answer.questionNo: answer.timeSpentMs,
    };
  }

  void wait(int seconds) =>
      env.clock.current = env.clock.current.add(Duration(seconds: seconds));

  test('time goes to the question that was current, adds up when the person '
      'returns, and stops in the background (BR-TOPIK-015)', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    wait(5);
    await controller.answer(questionNo: 1, selectedIdx: 2);
    wait(3);
    await controller.move(2);
    wait(4);
    await controller.pause();
    wait(600);
    controller.resume();
    wait(2);
    await controller.move(1);
    wait(1);
    await controller.leave();

    expect(await times(attempt.id), {1: 9000, 2: 6000});
    expect((await store.watchAttempt(attempt.id).first)!.attempt.totalTimeMs, 15000);
  });

  test('a pause while paused writes nothing more', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    wait(2);
    await controller.pause();
    wait(30);
    await controller.pause();
    await controller.leave();

    expect(await times(attempt.id), {1: 2000});
  });

  test('a second submit, and every answer after one, is ignored '
      '(BR-TOPIK-014)', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    final first = controller.submit(test0.testId);
    expect(await controller.submit(test0.testId), isNull);
    expect(topikOk((await first)!).isCompleted, isTrue);
    expect(await controller.answer(questionNo: 1, selectedIdx: 1), isNull);
    expect(await controller.move(2), isNull);
  });

  test('a refused submit lets the person go on', () async {
    final attempt = await open();
    final controlled = control(attempt.id, hasContent: false);

    final outcome = await controlled.controller.submit(test0.testId);
    expect(topikReason(outcome!), TopikRejection.testUnavailable);
    expect(controlled.container.read(topikAttemptControllerProvider(attempt.id)), isFalse);
    topikOk(
      (await controlled.controller.answer(questionNo: 1, selectedIdx: 3))!,
    );
  });

  test('delete removes the attempt', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    topikOk((await controller.delete())!);
    expect(await store.watchAttempt(attempt.id).first, isNull);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_use_cases_test.dart test/features/topik/presentation/topik_labels_test.dart test/features/topik/presentation/topik_attempt_controller_test.dart`
Expected: FAIL to compile (`isContentMissing`, `topikClockText`, `topikAttemptControllerProvider` undefined).

- [ ] **Step 3: The view's content check**

In `lib/features/topik/domain/models/topik_views_model.dart`, inside `TopikAttemptView` after `final TopikTest? test;`:

```dart
  /// The attempt cannot go on: its test is gone, or no longer has exactly the
  /// attempt's questions (BR-TOPIK-019; the store refuses its submit then).
  bool get isContentMissing {
    final current = test;
    if (current == null) return true;
    final stored = {for (final answer in detail.answers) answer.questionNo};
    final numbers = {for (final question in current.questions) question.no};
    return stored.length != numbers.length || !stored.containsAll(numbers);
  }
```

- [ ] **Step 4: Labels**

In `lib/features/topik/presentation/widgets/support/topik_labels_widget.dart`, inside `extension TopikLabels` after `topikDateTime`:

```dart
  /// A playback speed with no trailing zero, in the UI language: "1",
  /// "0.75" ("0,75" in Vietnamese).
  String topikSpeedText(double speed) =>
      NumberFormat('0.##', localeName).format(speed);
```

and at the end of the file:

```dart
/// An audio position as minutes and seconds, "1:33" (spec §5.5); the
/// seconds are cut, not rounded, so the clock never runs ahead.
String topikClockText(int ms) {
  final seconds = ms ~/ Duration.millisecondsPerSecond;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  final rest = seconds % Duration.secondsPerMinute;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

/// "①" to "④", the option numbers of the paper (spec §6.4).
String topikCircled(int idx) => String.fromCharCode(_circledZero + idx);

/// The code point before "①".
const int _circledZero = 0x245F;
```

- [ ] **Step 5: Providers**

`lib/features/topik/presentation/providers/watch_topik_attempt_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_attempt_use_case_provider.g.dart';

@riverpod
WatchTopikAttemptUseCase watchTopikAttemptUseCase(Ref ref) =>
    WatchTopikAttemptUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

`lib/features/topik/presentation/providers/topik_attempt_provider.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_attempt_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_attempt_provider.g.dart';

/// Screen 37's data: the attempt with its answers and its test; null once
/// the attempt is gone (deleted, or the account switched).
@riverpod
Stream<TopikAttemptView?> topikAttempt(Ref ref, String attemptId) =>
    ref.watch(watchTopikAttemptUseCaseProvider)(attemptId);
```

`lib/features/topik/presentation/providers/answer_topik_question_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/answer_topik_question_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'answer_topik_question_use_case_provider.g.dart';

@riverpod
AnswerTopikQuestionUseCase answerTopikQuestionUseCase(Ref ref) =>
    AnswerTopikQuestionUseCase(ref.watch(topikAttemptRepositoryProvider));
```

`lib/features/topik/presentation/providers/move_topik_question_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/move_topik_question_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'move_topik_question_use_case_provider.g.dart';

@riverpod
MoveTopikQuestionUseCase moveTopikQuestionUseCase(Ref ref) =>
    MoveTopikQuestionUseCase(ref.watch(topikAttemptRepositoryProvider));
```

`lib/features/topik/presentation/providers/record_topik_time_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/record_topik_time_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_topik_time_use_case_provider.g.dart';

@riverpod
RecordTopikTimeUseCase recordTopikTimeUseCase(Ref ref) =>
    RecordTopikTimeUseCase(ref.watch(topikAttemptRepositoryProvider));
```

`lib/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_topik_attempt_use_case_provider.g.dart';

@riverpod
SubmitTopikAttemptUseCase submitTopikAttemptUseCase(Ref ref) =>
    SubmitTopikAttemptUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

- [ ] **Step 6: The controller**

`lib/features/topik/presentation/controllers/topik_attempt_controller.dart`:

```dart
import 'dart:math';

import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/providers/answer_topik_question_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/move_topik_question_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/record_topik_time_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_attempt_controller.g.dart';

/// Screen 37's commands and its question clock (spec §5.4, §13.6).
///
/// Time is not ticked. The moment the current question became current is
/// kept, and the time since is added to that question on the next answer,
/// move, pause or exit. While paused (the app in the background) none
/// accrues.
///
/// The state is whether a submit runs or has run: a second tap, and every
/// command after it, is ignored (BR-TOPIK-014). A database `Failure` is
/// thrown through; the screen says so.
@riverpod
class TopikAttemptController extends _$TopikAttemptController {
  /// When the current question's time started; null while paused.
  DateTime? _since;

  @override
  bool build(String attemptId) {
    _since = ref.watch(dayClockProvider).now();
    return false;
  }

  /// Saves [selectedIdx] for [questionNo], which becomes current. Null
  /// once a submit runs.
  Future<Outcome<void, TopikRejection>?> answer({
    required int questionNo,
    required int selectedIdx,
  }) async {
    if (state) return null;
    return ref.read(answerTopikQuestionUseCaseProvider)(
      attemptId: attemptId,
      questionNo: questionNo,
      selectedIdx: selectedIdx,
      elapsedMs: _lap(),
    );
  }

  /// Makes [toQuestionNo] current. Null once a submit runs.
  Future<Outcome<void, TopikRejection>?> move(int toQuestionNo) async {
    if (state) return null;
    return ref.read(moveTopikQuestionUseCaseProvider)(
      attemptId: attemptId,
      toQuestionNo: toQuestionNo,
      elapsedMs: _lap(),
    );
  }

  /// The app went to the background, or the screen goes: the time so far
  /// is written, and none accrues until [resume].
  Future<void> pause() async {
    if (state || _since == null) return;
    final elapsedMs = _lap();
    _since = null;
    await ref.read(recordTopikTimeUseCaseProvider)(
      attemptId: attemptId,
      elapsedMs: elapsedMs,
    );
  }

  /// The app is back: the current question's time runs again.
  void resume() {
    if (state) return;
    _since ??= ref.read(dayClockProvider).now();
  }

  /// The screen goes (Close, Back, another route): as [pause].
  Future<void> leave() => pause();

  /// Scores and closes the attempt (BR-TOPIK-013). Null when a submit
  /// already runs or ran; a refusal or a failure lets the person go on.
  Future<Outcome<TopikAttempt, TopikRejection>?> submit(String testId) async {
    if (state) return null;
    state = true;
    final elapsedMs = _lap();
    _since = null;
    var isDone = false;
    try {
      final outcome = await ref.read(submitTopikAttemptUseCaseProvider)(
        attemptId: attemptId,
        testId: testId,
        elapsedMs: elapsedMs,
      );
      isDone = outcome is Ok;
      return outcome;
    } finally {
      if (!isDone && ref.mounted) {
        state = false;
        _since = ref.read(dayClockProvider).now();
      }
    }
  }

  /// Deletes the attempt whose content is gone (BR-TOPIK-019).
  Future<Outcome<void, TopikRejection>?> delete() async {
    if (state) return null;
    return ref.read(deleteTopikAttemptUseCaseProvider)(attemptId);
  }

  /// The time since the last event, and a new start from now.
  int _lap() {
    final since = _since;
    if (since == null) return 0;
    final now = ref.read(dayClockProvider).now();
    _since = now;
    return max(0, now.difference(since).inMilliseconds);
  }
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: it writes the six `.g.dart` files and `topik_attempt_controller.g.dart`.

- [ ] **Step 7: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_use_cases_test.dart test/features/topik/presentation/topik_labels_test.dart test/features/topik/presentation/topik_attempt_controller_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n lib/features/topik test/features/topik
git commit -m "feat(topik): DEV-394 screen 37's copy, providers and question clock"
```

---
### Task 3: The audio controller, the audio bar and the speed sheet

**Files:**
- Create:
  - `lib/features/topik/presentation/controllers/topik_audio_controller.dart`
  - `lib/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart`
  - `lib/features/topik/presentation/widgets/overlays/topik_speed_sheet_widget.dart`
- Modify: `test/support/topik_fakes.dart` (a fake player)
- Test:
  - `test/features/topik/presentation/topik_audio_controller_test.dart`
  - `test/features/topik/presentation/topik_audio_bar_test.dart`

**Interfaces:**
- Consumes:
  - `topikAudioRepositoryProvider`, `TopikAudioRepository`, `TopikAudioState`, `TopikAudioClip`, `topikAudioSpeeds` (plan 5).
  - `topikClockText`, `TopikLabels.topikSpeedText` (Task 2).
- Produces:
  - `topikAudioControllerProvider`, whose state is `AsyncValue<TopikAudioState>`. Its methods: `show(TopikAudioClip)`, `retry()`, `toggle()`, `seek(int)`, `setSpeed(double)`.
  - `TopikAudioBarWidget({required TopikAudioClip clip})`.
  - `showTopikSpeedSheet(BuildContext, {required double selected})` → `Future<double?>`.
  - In `test/support/topik_fakes.dart`: `FakeTopikAudioRepository([TopikAudioState initial])` with `calls`, `failsLoads` and `emit`.

- [ ] **Step 1: The fake player**

Append to `test/support/topik_fakes.dart`, and add these imports: `dart:async`, `package:memox/features/topik/domain/models/topik_audio_model.dart` and `package:memox/features/topik/domain/repositories/topik_audio_repository.dart`.

```dart
/// A player a test drives: each command is logged in [calls] and moves the
/// state at once. A load is ready at the clip's start, or fails while
/// [failsLoads].
final class FakeTopikAudioRepository implements TopikAudioRepository {
  FakeTopikAudioRepository([this._state = TopikAudioState.initial]);

  TopikAudioState _state;
  final _states = StreamController<TopikAudioState>.broadcast();
  final calls = <String>[];
  var failsLoads = false;

  @override
  TopikAudioState get state => _state;

  @override
  Stream<TopikAudioState> watchState() => Stream.multi((listener) {
    listener.add(_state);
    final changes = _states.stream.listen(listener.add);
    listener.onCancel = changes.cancel;
  });

  /// Moves the player to [next], as the plugin would.
  void emit(TopikAudioState next) {
    _state = next;
    _states.add(next);
  }

  @override
  Future<void> load(TopikAudioClip clip) async {
    calls.add('load ${clip.startMs}');
    emit(
      TopikAudioState(
        status: failsLoads ? TopikAudioStatus.failed : TopikAudioStatus.ready,
        clip: clip,
        positionMs: 0,
        speed: _state.speed,
      ),
    );
  }

  @override
  Future<void> play() async {
    calls.add('play');
    emit(_state.copyWith(status: TopikAudioStatus.playing));
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    emit(_state.copyWith(status: TopikAudioStatus.ready));
  }

  @override
  Future<void> seek(int positionMs) async {
    calls.add('seek $positionMs');
    emit(_state.copyWith(positionMs: positionMs));
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add('speed $speed');
    emit(_state.copyWith(speed: speed));
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    emit(_state.copyWith(status: TopikAudioStatus.ready, positionMs: 0));
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}
```

- [ ] **Step 2: Write the failing tests**

`test/features/topik/presentation/topik_audio_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_audio_controller.dart';

import '../../../support/topik_fakes.dart';

const _first = TopikAudioClip(asset: 'a.mp3', startMs: 0, endMs: 30000);
const _second = TopikAudioClip(asset: 'a.mp3', startMs: 30000, endMs: 60000);

// Screen 37's player (spec §5.5): a clip loads when its group shows, never
// plays on its own, and a failed one loads again on Retry (BR-TOPIK-017).
void main() {
  late FakeTopikAudioRepository player;
  late TopikAudioController audio;

  setUp(() {
    player = FakeTopikAudioRepository();
    final container = ProviderContainer(
      overrides: [topikAudioRepositoryProvider.overrideWithValue(player)],
    );
    addTearDown(container.dispose);
    container.listen(topikAudioControllerProvider, (_, _) {});
    audio = container.read(topikAudioControllerProvider.notifier);
  });

  test('a group loads its clip once and does not play it', () async {
    await audio.show(_first);
    await audio.show(_first);
    await audio.show(_second);

    expect(player.calls, ['load 0', 'load 30000']);
    expect(player.state.isPlaying, isFalse);
  });

  test('a failed clip loads again when shown or retried', () async {
    player.failsLoads = true;
    await audio.show(_first);
    player.failsLoads = false;
    await audio.retry();
    await audio.show(_first);

    expect(player.calls, ['load 0', 'load 0']);
    expect(player.state.status, TopikAudioStatus.ready);
  });

  test('toggle plays, then pauses; seek and speed go to the player', () async {
    await audio.show(_first);
    await audio.toggle();
    await audio.toggle();
    await audio.seek(12000);
    await audio.setSpeed(1.5);

    expect(player.calls, [
      'load 0',
      'play',
      'pause',
      'seek 12000',
      'speed 1.5',
    ]);
  });
}
```

`test/features/topik/presentation/topik_audio_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_fakes.dart';

const _clip = TopikAudioClip(asset: 'a.mp3', startMs: 0, endMs: 30000);

// The audio bar of screen 37 (detail file 37, BR-TOPIK-017).
void main() {
  Future<FakeTopikAudioRepository> pump(
    WidgetTester tester,
    LibraryEnv env, {
    bool failsLoads = false,
  }) async {
    final player = FakeTopikAudioRepository()..failsLoads = failsLoads;
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(body: TopikAudioBarWidget(clip: _clip)),
      overrides: [topikAudioRepositoryProvider.overrideWithValue(player)],
    );
    await tester.pumpAndSettle();
    return player;
  }

  libraryTest('loads its clip and waits: no autoplay', (tester, env) async {
    final player = await pump(tester, env);

    expect(player.calls, ['load 0']);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('0:00 / 0:30'), findsOneWidget);
  });

  libraryTest('play, then pause; the time follows the player', (
    tester,
    env,
  ) async {
    final player = await pump(tester, env);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);
    player.emit(player.state.copyWith(positionMs: 12500));
    await tester.pump();
    expect(find.text('0:12 / 0:30'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(player.calls, ['load 0', 'play', 'pause']);
  });

  libraryTest('the speed sheet sets the speed', (tester, env) async {
    final player = await pump(tester, env);

    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();
    expect(find.text('Playback speed'), findsOneWidget);
    await tester.tap(find.text('1.5×'));
    await tester.pumpAndSettle();

    expect(player.calls.last, 'speed 1.5');
    expect(find.text('1.5×'), findsOneWidget);
  });

  libraryTest('a clip that fails is a warning; Retry loads it again', (
    tester,
    env,
  ) async {
    final player = await pump(tester, env, failsLoads: true);

    expect(find.text("Couldn't play this audio"), findsOneWidget);
    expect(find.text('Your answers are safe.'), findsOneWidget);
    player.failsLoads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't play this audio"), findsNothing);
    expect(player.calls, ['load 0', 'load 0']);
  });

  libraryTest('the seek bar says where it is, of how long', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, env);

    final node = tester.getSemantics(find.bySemanticsLabel('Audio position'));
    expect(node.value, '0:00 / 0:30');
    handle.dispose();
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_audio_controller_test.dart test/features/topik/presentation/topik_audio_bar_test.dart`
Expected: FAIL to compile (`topik_audio_controller.dart` and `topik_audio_bar_widget.dart` are missing).

- [ ] **Step 3: The controller**

`lib/features/topik/presentation/controllers/topik_audio_controller.dart`:

```dart
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_audio_controller.g.dart';

/// Screen 37's player (spec §5.5, §13.8), one per attempt screen; its state
/// is the player's. A group's clip loads when its bar shows and is never
/// played on its own; loading another group's clip pauses the previous one
/// (the repository does that).
@riverpod
class TopikAudioController extends _$TopikAudioController {
  @override
  Stream<TopikAudioState> build() =>
      ref.watch(topikAudioRepositoryProvider).watchState();

  TopikAudioRepository get _player => ref.read(topikAudioRepositoryProvider);

  /// Loads [clip], unless it is the clip already loaded and not failed:
  /// moving between the questions of one group keeps the audio as it is.
  Future<void> show(TopikAudioClip clip) async {
    final current = _player.state;
    final isLoaded =
        current.clip == clip && current.status != TopikAudioStatus.failed;
    if (isLoaded) return;
    await _player.load(clip);
  }

  /// Loads the current clip again after it failed (BR-TOPIK-017).
  Future<void> retry() async {
    final clip = _player.state.clip;
    if (clip == null) return;
    await _player.load(clip);
  }

  Future<void> toggle() =>
      _player.state.isPlaying ? _player.pause() : _player.play();

  Future<void> seek(int positionMs) => _player.seek(positionMs);

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
}
```

- [ ] **Step 4: The speed sheet**

`lib/features/topik/presentation/widgets/overlays/topik_speed_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// The four playback speeds (spec §5.5, D7); the pick closes the sheet.
/// Null when dismissed.
Future<double?> showTopikSpeedSheet(
  BuildContext context, {
  required double selected,
}) => showMxBottomSheet<double>(
  context,
  builder: (sheetContext) => TopikSpeedSheetWidget(selected: selected),
);

class TopikSpeedSheetWidget extends StatelessWidget {
  const TopikSpeedSheetWidget({super.key, required this.selected});

  final double selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      title: l10n.topikPlaybackSpeed,
      child: MxDividedColumn(
        children: [
          for (final speed in topikAudioSpeeds)
            MxOptionRow(
              title: l10n.topikSpeed(l10n.topikSpeedText(speed)),
              isSelected: speed == selected,
              onSelected: () => Navigator.of(context).pop(speed),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: The audio bar**

`lib/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_audio_controller.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_speed_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

/// A listening group's player (spec §5.5, detail file 37): play or pause, a
/// seek bar over the group's clip, "0:42 / 1:33", and the speed. It loads
/// its clip when it shows and never plays on its own; it stays as it is
/// between the questions of one group (BR-TOPIK-017). A clip that fails is
/// a warning with Retry, and the answers are untouched.
class TopikAudioBarWidget extends ConsumerStatefulWidget {
  const TopikAudioBarWidget({super.key, required this.clip});

  final TopikAudioClip clip;

  @override
  ConsumerState<TopikAudioBarWidget> createState() =>
      _TopikAudioBarWidgetState();
}

class _TopikAudioBarWidgetState extends ConsumerState<TopikAudioBarWidget> {
  /// Where a drag holds the handle, in ms of the clip; null shows where the
  /// player is.
  double? _dragMs;

  TopikAudioController get _audio =>
      ref.read(topikAudioControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    unawaited(_audio.show(widget.clip));
  }

  @override
  void didUpdateWidget(TopikAudioBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip != widget.clip) unawaited(_audio.show(widget.clip));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final audio =
        ref.watch(topikAudioControllerProvider).value ??
        TopikAudioState.initial;
    final isOwn = audio.clip == widget.clip;
    if (isOwn && audio.status == TopikAudioStatus.failed) {
      return MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.topikAudioFailed,
        message: l10n.topikAudioFailedBody,
        hasBottomMargin: false,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            size: MxButtonSize.small,
            onPressed: () => unawaited(_audio.retry()),
          ),
        ],
      );
    }
    final isReady =
        isOwn &&
        audio.status != TopikAudioStatus.idle &&
        audio.status != TopikAudioStatus.loading;
    final isPlaying = isOwn && audio.isPlaying;
    final lengthMs = widget.clip.lengthMs;
    final positionMs = _dragMs ?? (isOwn ? audio.positionMs : 0).toDouble();
    String timeOf(double ms) => l10n.topikClockOfTotal(
      topikClockText(ms.round()),
      topikClockText(lengthMs),
    );
    return Row(
      spacing: context.dimens.space4,
      children: [
        MxIconButton(
          icon: isPlaying ? AppIcons.pause : AppIcons.study,
          semanticLabel: isPlaying ? l10n.topikPause : l10n.topikPlay,
          onPressed: isReady ? () => unawaited(_audio.toggle()) : null,
        ),
        Expanded(
          child: MxSlider(
            value: positionMs,
            max: isReady ? lengthMs.toDouble() : 0,
            onChanged: (ms) => setState(() => _dragMs = ms),
            onChangeEnd: _seek,
            semanticLabel: l10n.topikAudioPosition,
            semanticFormatter: timeOf,
          ),
        ),
        Text(
          timeOf(positionMs),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        MxChipTrigger(
          label: l10n.topikSpeed(l10n.topikSpeedText(audio.speed)),
          onPressed: () => unawaited(_pickSpeed(audio.speed)),
        ),
      ],
    );
  }

  void _seek(double ms) {
    setState(() => _dragMs = null);
    unawaited(_audio.seek(ms.round()));
  }

  Future<void> _pickSpeed(double current) async {
    final speed = await showTopikSpeedSheet(context, selected: current);
    if (speed == null || !mounted) return;
    await _audio.setSpeed(speed);
  }
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`, then `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_audio_controller_test.dart test/features/topik/presentation/topik_audio_bar_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/topik test/support/topik_fakes.dart test/features/topik
git commit -m "feat(topik): DEV-394 the listening bar of screen 37 over the plan-5 player"
```

---
### Task 4: The panes, the question, the footer and the question grid

**Files:**
- Create, in `lib/features/topik/presentation/widgets/`:
  - `sections/topik_two_pane_widget.dart`
  - `sections/topik_group_pane_widget.dart`
  - `sections/topik_question_pane_widget.dart`
  - `sections/topik_attempt_footer_widget.dart`
  - `overlays/topik_question_grid_sheet_widget.dart`
- Modify: `lib/features/topik/presentation/widgets/support/topik_labels_widget.dart` (`topikText`)
- Test: `test/features/topik/presentation/topik_attempt_widgets_test.dart`

**Interfaces:**
- Consumes:
  - `MxChoiceTile` (Task 1).
  - `TopikAudioBarWidget`, `FakeTopikAudioRepository` (Task 3).
  - `topikCircled`, the l10n keys (Task 2).
- Produces:
  - `TopikTwoPaneWidget({Widget? top, required Widget bottom})`.
  - `TopikGroupPaneWidget`, taking `group`, `TopikAudioClip? audio`, `isCollapsed`, `isScriptShown`, `onToggleCollapsed`, `onToggleScript`.
  - `TopikQuestionPaneWidget`, taking `question`, `int? selectedIdx`, `ValueChanged<int>? onPick`.
  - `TopikAttemptFooterWidget`, taking:
    - `VoidCallback? onPrevious` (null on the first question);
    - `VoidCallback? onNext` (null on the last question, which shows Submit);
    - `required VoidCallback onQuestions`;
    - `required VoidCallback onSubmit`;
    - `required bool isSubmitting`.
  - `showTopikQuestionGrid(BuildContext, {required List<int> questionNos, required Set<int> answered, required int current})` → `Future<TopikGridPick?>`, with `sealed class TopikGridPick`, `TopikGridQuestion(int no)` and `TopikGridSubmit()`.
  - `TopikLabels.topikText(TopikText)`.

- [ ] **Step 1: Write the failing tests**

`test/features/topik/presentation/topik_attempt_widgets_test.dart`:

```dart
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_question_grid_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_attempt_footer_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

const _clip = TopikAudioClip(asset: 'a.mp3', startMs: 0, endMs: 30000);

// Screen 37's parts (detail file 37; critique F1, F5, F7, F12).
void main() {
  final reading = topikTestFixture();
  final listening = topikTestFixture(section: TopikSection.listening);

  Future<void> host(
    WidgetTester tester,
    LibraryEnv env,
    Widget child, {
    FakeTopikAudioRepository? player,
  }) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: child),
      overrides: [
        topikAudioRepositoryProvider.overrideWithValue(
          player ?? FakeTopikAudioRepository(),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  libraryTest('two panes: the material takes at most half, the question '
      'the rest', (tester, env) async {
    await host(
      tester,
      env,
      const TopikTwoPaneWidget(
        top: SingleChildScrollView(child: SizedBox(height: 2000)),
        bottom: SizedBox.expand(key: ValueKey('bottom')),
      ),
    );

    expect(tester.getSize(find.byType(SingleChildScrollView)).height, 400);
    expect(tester.getSize(find.byKey(const ValueKey('bottom'))).height, 400);
  });

  libraryTest('no shared material: the question takes the whole body', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      const TopikTwoPaneWidget(
        top: null,
        bottom: SizedBox.expand(key: ValueKey('bottom')),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('bottom'))).height, 800);
  });

  libraryTest('the question: its real number, four options; a pick reports '
      'its number; only idle and selected (BR-TOPIK-016)', (tester, env) async {
    final question = reading.questions.first;
    final picks = <int>[];
    await host(
      tester,
      env,
      TopikQuestionPaneWidget(
        question: question,
        selectedIdx: 3,
        onPick: picks.add,
      ),
    );

    expect(find.text('1. ${question.stemKo}'), findsOneWidget);
    final tiles = tester.widgetList<MxChoiceTile>(find.byType(MxChoiceTile));
    expect([for (final tile in tiles) tile.tone], [
      MxChoiceTone.idle,
      MxChoiceTone.idle,
      MxChoiceTone.selected,
      MxChoiceTone.idle,
    ]);
    expect(tiles.elementAt(1).semanticsLabel, 'Option 2, 보기 2');
    await tester.tap(find.text('② 보기 2'));
    expect(picks, [2]);
  });

  libraryTest('the question is inert while held', (tester, env) async {
    await host(
      tester,
      env,
      TopikQuestionPaneWidget(
        question: reading.questions.first,
        selectedIdx: null,
        onPick: null,
      ),
    );

    final tiles = tester.widgetList<MxChoiceTile>(find.byType(MxChoiceTile));
    expect(tiles.every((tile) => tile.onTap == null), isTrue);
  });

  libraryTest('the group pane: instruction, passage; collapsed it keeps the '
      'instruction on one line', (tester, env) async {
    final group = reading.groups.first;
    var isCollapsed = false;
    await host(
      tester,
      env,
      StatefulBuilder(
        builder: (context, setState) => TopikGroupPaneWidget(
          group: group,
          audio: null,
          isCollapsed: isCollapsed,
          isScriptShown: false,
          onToggleCollapsed: () => setState(() => isCollapsed = !isCollapsed),
          onToggleScript: () {},
        ),
      ),
    );

    expect(find.text(group.instructionKo), findsOneWidget);
    expect(find.text(group.passage!.textKo!), findsOneWidget);
    await tester.tap(find.text('Hide passage'));
    await tester.pumpAndSettle();
    expect(find.text(group.passage!.textKo!), findsNothing);
    expect(
      tester.widget<Text>(find.text(group.instructionKo)).maxLines,
      1,
    );
    expect(find.text('Show passage'), findsOneWidget);
  });

  libraryTest('a listening group: the audio stays when collapsed; the script '
      'shows with its translation in the UI language', (tester, env) async {
    final group = listening.groups.first;
    await host(
      tester,
      env,
      TopikGroupPaneWidget(
        group: group,
        audio: _clip,
        isCollapsed: false,
        isScriptShown: true,
        onToggleCollapsed: () {},
        onToggleScript: () {},
      ),
    );
    expect(find.byType(TopikAudioBarWidget), findsOneWidget);
    expect(find.text(group.script!), findsOneWidget);
    expect(find.text('Hello.'), findsOneWidget);
    expect(find.text('Hide script'), findsOneWidget);

    await host(
      tester,
      env,
      TopikGroupPaneWidget(
        group: group,
        audio: _clip,
        isCollapsed: true,
        isScriptShown: true,
        onToggleCollapsed: () {},
        onToggleScript: () {},
      ),
    );
    expect(find.byType(TopikAudioBarWidget), findsOneWidget);
    expect(find.text(group.script!), findsNothing);
  });

  libraryTest('the footer: Previous is off on the first question; the last '
      'question submits; one primary (critique F1)', (tester, env) async {
    var submits = 0;
    await host(
      tester,
      env,
      TopikAttemptFooterWidget(
        onPrevious: null,
        onNext: null,
        onQuestions: () {},
        onSubmit: () => submits++,
        isSubmitting: false,
      ),
    );

    final previous = tester.widget<MxIconButton>(find.byType(MxIconButton));
    expect(previous.semanticLabel, 'Previous');
    expect(previous.onPressed, isNull);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Submit'));
    expect(submits, 1);
    expect(find.text('Questions'), findsOneWidget);
  });

  libraryTest('the grid: a cell per question that says if it is answered, '
      'the current one selected; a tap goes there, Submit submits', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final picks = <TopikGridPick?>[];
    await host(
      tester,
      env,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => picks.add(
            await showTopikQuestionGrid(
              context,
              questionNos: const [1, 2, 3],
              answered: const {2},
              current: 1,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 2, answered'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 3, not answered'), findsOneWidget);
    final current = tester.getSemantics(
      find.bySemanticsLabel('Question 1, not answered'),
    );
    expect(
      current.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect((picks.single! as TopikGridQuestion).no, 3);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(picks.last, isA<TopikGridSubmit>());
    handle.dispose();
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_attempt_widgets_test.dart`
Expected: FAIL to compile (the widget files are missing).

- [ ] **Step 2: `topikText`**

In `topik_labels_widget.dart`, add `import 'package:memox/features/topik/domain/models/topik_text_model.dart';`. Then add inside `extension TopikLabels`:

```dart
  /// A translation of the content in the UI language (Korean is never
  /// translated: this is the content's own vi or en text).
  String topikText(TopikText text) =>
      localeName.startsWith('vi') ? text.vi : text.en;
```

- [ ] **Step 3: The two panes**

`lib/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Screen 37's body (owner brief 2026-10-15): the group's material on top,
/// at most half the height and scrolling on its own, the question below
/// taking the rest. A question with no shared material has no top pane.
class TopikTwoPaneWidget extends StatelessWidget {
  const TopikTwoPaneWidget({super.key, required this.top, required this.bottom});

  final Widget? top;
  final Widget bottom;

  /// The share of the body the top pane may take.
  static const double _topShare = 0.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top case final material?)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * _topShare,
            ),
            child: material,
          ),
        Expanded(child: bottom),
      ],
    ),
  );
}
```

- [ ] **Step 4: The group pane**

`lib/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// A group's shared material (detail file 37, critique F5, F12):
/// - its instruction;
/// - for listening, the audio bar;
/// - the passage or its picture;
/// - for a group with a script, the toggle, then the script and its
///   translation once the current question is answered or by the toggle
///   (spec §5.5, D15).
///
/// It sits on the recessed ground and scrolls on its own. Collapsed, it keeps
/// the instruction on one line and the audio bar, so the audio is never lost
/// to a collapse.
class TopikGroupPaneWidget extends StatelessWidget {
  const TopikGroupPaneWidget({
    super.key,
    required this.group,
    required this.audio,
    required this.isCollapsed,
    required this.isScriptShown,
    required this.onToggleCollapsed,
    required this.onToggleScript,
  });

  final TopikQuestionGroup group;

  /// The group's clip; null for a group without audio.
  final TopikAudioClip? audio;
  final bool isCollapsed;
  final bool isScriptShown;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onToggleScript;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final ground = context.colors.surfaceContainerLow;
    final hasMaterial = group.passage != null || group.script != null;
    return MxTintBase(
      color: ground,
      child: ColoredBox(
        color: ground,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenMargin,
            vertical: dimens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: dimens.space12,
            children: [
              Row(
                spacing: dimens.space8,
                children: [
                  Expanded(
                    child: Text(
                      group.instructionKo,
                      maxLines: isCollapsed ? 1 : null,
                      overflow: isCollapsed ? TextOverflow.ellipsis : null,
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (hasMaterial)
                    MxButton(
                      label: isCollapsed
                          ? l10n.topikShowPassage
                          : l10n.topikHidePassage,
                      tone: MxButtonTone.text,
                      size: MxButtonSize.small,
                      onPressed: onToggleCollapsed,
                    ),
                ],
              ),
              if (audio case final clip?) TopikAudioBarWidget(clip: clip),
              if (!isCollapsed) ..._material(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _material(BuildContext context) {
    final l10n = context.l10n;
    final passage = group.passage;
    final script = group.script;
    final translation = group.scriptTranslation;
    return [
      if (passage?.textKo case final text?)
        Text(text, style: context.texts.bodyLarge),
      if (passage?.image case final image?)
        Image.asset(
          image,
          fit: BoxFit.contain,
          semanticLabel: l10n.topikPicture,
        ),
      if (script != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxButton(
            label: isScriptShown ? l10n.topikHideScript : l10n.topikShowScript,
            tone: MxButtonTone.text,
            size: MxButtonSize.small,
            onPressed: onToggleScript,
          ),
        ),
      if (script != null && isScriptShown) ...[
        Text(script, style: context.texts.bodyMedium),
        if (translation != null)
          Text(
            l10n.topikText(translation),
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    ];
  }
}
```

- [ ] **Step 5: The question pane**

`lib/features/topik/presentation/widgets/sections/topik_question_pane_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The current question (detail file 37, critique F3): "{no}. {stem}", then
/// its options ①–④ as choice tiles, idle or selected only. Nothing says
/// right or wrong before submit (BR-TOPIK-016, D15). [onPick] null holds
/// the options (submitting).
class TopikQuestionPaneWidget extends StatelessWidget {
  const TopikQuestionPaneWidget({
    super.key,
    required this.question,
    required this.selectedIdx,
    required this.onPick,
  });

  final TopikQuestion question;
  final int? selectedIdx;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxScreenScroll(
      children: [
        SizedBox(height: dimens.space16),
        Text(
          l10n.topikQuestionStem(question.no, question.stemKo),
          style: context.texts.bodyLarge,
        ),
        SizedBox(height: dimens.space16),
        for (final option in question.options) ...[
          _option(context, option),
          SizedBox(height: dimens.space8),
        ],
      ],
    );
  }

  Widget _option(BuildContext context, TopikOption option) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final isSelected = option.idx == selectedIdx;
    final pick = onPick;
    return MxChoiceTile(
      tone: isSelected ? MxChoiceTone.selected : MxChoiceTone.idle,
      isSelected: isSelected,
      semanticsLabel: l10n.topikOptionLabel(
        option.idx,
        option.textKo ?? l10n.topikPicture,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space16,
        vertical: dimens.space12,
      ),
      onTap: pick == null ? null : () => pick(option.idx),
      builder: (foreground) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: dimens.space8,
        children: [
          Text(
            [topikCircled(option.idx), ?option.textKo].join(' '),
            style: context.texts.bodyLarge?.copyWith(color: foreground),
          ),
          if (option.image case final image?)
            Image.asset(image, fit: BoxFit.contain, excludeFromSemantics: true),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: The footer**

`lib/features/topik/presentation/widgets/sections/topik_attempt_footer_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Screen 37's footer (critique F1):
/// - Previous is a glyph, so three actions fit 360 dp;
/// - "Questions" (outline) takes the room left and opens the grid;
/// - Next, which is Submit on the last question ([onNext] null), is the one
///   primary (The One Accent Rule).
///
/// While submitting, Submit spins and the rest is off (BR-TOPIK-014).
class TopikAttemptFooterWidget extends StatelessWidget {
  const TopikAttemptFooterWidget({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onQuestions,
    required this.onSubmit,
    required this.isSubmitting,
  });

  /// Null on the first question.
  final VoidCallback? onPrevious;

  /// Null on the last question, where the primary action is Submit.
  final VoidCallback? onNext;
  final VoidCallback onQuestions;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final next = onNext;
    return MxFooterBar(
      child: Row(
        spacing: context.dimens.space8,
        children: [
          MxIconButton(
            icon: AppIcons.back,
            semanticLabel: l10n.topikPrevious,
            onPressed: isSubmitting ? null : onPrevious,
          ),
          Expanded(
            child: MxButton(
              label: l10n.topikQuestions,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: isSubmitting ? null : onQuestions,
            ),
          ),
          if (next == null)
            MxButton(
              label: l10n.topikSubmit,
              isLoading: isSubmitting,
              onPressed: onSubmit,
            )
          else
            MxButton(
              label: l10n.topikNext,
              onPressed: isSubmitting ? null : next,
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: The question grid**

`lib/features/topik/presentation/widgets/overlays/topik_question_grid_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// What the question grid closed with.
sealed class TopikGridPick {
  const TopikGridPick();
}

/// Go to question [no].
final class TopikGridQuestion extends TopikGridPick {
  const TopikGridQuestion(this.no);

  final int no;
}

/// Submit the attempt.
final class TopikGridSubmit extends TopikGridPick {
  const TopikGridSubmit();
}

/// Screen 37's question grid (detail file 37, critique F7): one cell per
/// question with its real number, and Submit at the foot. Null when
/// dismissed.
Future<TopikGridPick?> showTopikQuestionGrid(
  BuildContext context, {
  required List<int> questionNos,
  required Set<int> answered,
  required int current,
}) => showMxBottomSheet<TopikGridPick>(
  context,
  builder: (sheetContext) => TopikQuestionGridSheetWidget(
    questionNos: questionNos,
    answered: answered,
    current: current,
  ),
);

class TopikQuestionGridSheetWidget extends StatelessWidget {
  const TopikQuestionGridSheetWidget({
    super.key,
    required this.questionNos,
    required this.answered,
    required this.current,
  });

  final List<int> questionNos;
  final Set<int> answered;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxBottomSheet(
      title: l10n.topikQuestions,
      footer: MxSheetActions.single(
        label: l10n.topikSubmit,
        onPressed: () => Navigator.of(context).pop(const TopikGridSubmit()),
        isInSheet: true,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dimens.space24,
          0,
          dimens.space24,
          dimens.space16,
        ),
        child: Wrap(
          spacing: dimens.space8,
          runSpacing: dimens.space8,
          children: [
            for (final no in questionNos)
              _GridCell(
                no: no,
                isAnswered: answered.contains(no),
                isCurrent: no == current,
                onTap: () => Navigator.of(context).pop(TopikGridQuestion(no)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A question's cell: a control square; answered in the accent tinted over
/// the sheet, blank neutral, the current one with a primary edge. One
/// TalkBack node with its state, selected when current.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.no,
    required this.isAnswered,
    required this.isCurrent,
    required this.onTap,
  });

  final int no;
  final bool isAnswered;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final colors = context.colors;
    final radius = BorderRadius.circular(dimens.radiusSm);
    final accent = context.accentColor;
    return MxRowInk(
      onTap: onTap,
      isSelected: isCurrent,
      borderRadius: radius,
      child: Semantics(
        label: isAnswered
            ? l10n.topikQuestionAnswered(no)
            : l10n.topikQuestionBlank(no),
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: dimens.sizeControl,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isAnswered
                  ? accent.tintOver(MxTintBase.of(context))
                  : colors.surfaceContainerHighest,
              borderRadius: radius,
              border: isCurrent
                  ? Border.all(
                      color: colors.primary,
                      width: dimens.strokeControl,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '$no',
                style: context.texts.labelLarge?.copyWith(
                  color: isAnswered ? accent : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_attempt_widgets_test.dart`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/features/topik test/features/topik
git commit -m "feat(topik): DEV-394 screen 37's panes, question, footer and grid"
```

---
### Task 5: Screen 37 and its route

**Files:**
- Create: `lib/features/topik/presentation/screens/topik_attempt_screen.dart`
- Modify:
  - `lib/app/router/app_routes.dart`
  - `lib/app/router/topik_routes.dart`
  - `lib/app/router/app_router.dart`
- Test:
  - `test/features/topik/presentation/topik_attempt_screen_test.dart`
  - `test/app/topik_routes_test.dart` (two tests added)

**Interfaces:**
- Consumes:
  - `topikAttemptProvider`, `topikAttemptControllerProvider` (Task 2).
  - `TopikAudioBarWidget` (Task 3).
  - The Task 4 widgets.
  - `showTopikDeleteDialog` (plan 6a).
- Produces:
  - `TopikAttemptScreen({required String attemptId, required VoidCallback onClose, required ValueChanged<String> onSubmitted})`.
  - `AppRoutes.topikAttemptIdParam` and `AppRoutes.topikAttemptChild`.
  - `topikRoute(GlobalKey<NavigatorState> rootNavigator)`.

- [ ] **Step 1: Write the failing screen tests**

`test/features/topik/presentation/topik_attempt_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/usecases/answer_topik_question_use_case.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/answer_topik_question_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_attempt_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

/// The attempt store with an answer that fails, as a locked database does.
final class _FailingAnswer implements TopikAttemptRepository {
  @override
  Future<Outcome<void, TopikRejection>> answer({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
    DateTime? now,
  }) async => throw const DatabaseLockedFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A submit that waits for [release].
final class _HeldSubmit implements SubmitTopikAttemptUseCase {
  _HeldSubmit(this._real);

  final SubmitTopikAttemptUseCase _real;
  final release = Completer<void>();
  var calls = 0;

  @override
  Future<Outcome<TopikAttempt, TopikRejection>> call({
    required String attemptId,
    required String testId,
    required int elapsedMs,
  }) async {
    calls++;
    await release.future;
    return _real(attemptId: attemptId, testId: testId, elapsedMs: elapsedMs);
  }
}

final class _Exits {
  var closes = 0;
  final submitted = <String>[];
}

// Screen 37 (UC-TOPIK-003; BR-TOPIK-010…017, -019): each test is a row of
// detail file 37's Transitions table.
void main() {
  final reading = topikTestFixture();
  final listening = topikTestFixture(section: TopikSection.listening);

  Future<TopikAttempt> seed(
    LibraryEnv env,
    TopikTest test, {
    int? currentNo,
    Map<int, int> answers = const {},
  }) async {
    final store = TopikAttemptRepositoryImpl(env.db);
    final attempt = topikOk(await store.start(test, now: libraryToday));
    for (final MapEntry(key: no, value: idx) in answers.entries) {
      topikOk(
        await store.answer(
          attemptId: attempt.id,
          questionNo: no,
          selectedIdx: idx,
          elapsedMs: 0,
          now: libraryToday,
        ),
      );
    }
    if (currentNo != null) {
      topikOk(
        await store.move(
          attemptId: attempt.id,
          toQuestionNo: currentNo,
          elapsedMs: 0,
          now: libraryToday,
        ),
      );
    }
    return attempt;
  }

  Future<_Exits> pump(
    WidgetTester tester,
    LibraryEnv env,
    String attemptId, {
    TopikTest? test,
    List<TopikTest>? catalog,
    FakeTopikAudioRepository? player,
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
  }) async {
    final exits = _Exits();
    await pumpLibraryScreen(
      tester,
      env,
      TopikAttemptScreen(
        attemptId: attemptId,
        onClose: () => exits.closes++,
        onSubmitted: exits.submitted.add,
      ),
      locale: locale,
      overrides: [
        ...topikContentOverrides(catalog ?? [test ?? reading]),
        topikAudioRepositoryProvider.overrideWithValue(
          player ?? FakeTopikAudioRepository(),
        ),
        ...overrides,
      ],
    );
    await tester.pumpAndSettle();
    return exits;
  }

  Future<TopikAttemptDetail> stored(WidgetTester tester, LibraryEnv env, String id) async =>
      (await tester.runAsync(
        () => TopikAttemptRepositoryImpl(env.db).watchAttempt(id).first,
      ))!;

  MxChoiceTile tile(WidgetTester tester, String text) => tester.widget(
    find.ancestor(of: find.text(text), matching: find.byType(MxChoiceTile)),
  );

  void wait(LibraryEnv env, int seconds) =>
      env.clock.current = env.clock.current.add(Duration(seconds: seconds));

  libraryTest('opens at the attempt\'s current question, with the real '
      'numbers (BR-TOPIK-010, -011, -001)', (tester, env) async {
    final attempt = await seed(env, reading, currentNo: 3);
    await pump(tester, env, attempt.id);

    expect(find.text('3. ${reading.questions[2].stemKo}'), findsOneWidget);
    expect(find.text('3 / 50'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
  });

  libraryTest('a pick is saved at once and shows only as chosen '
      '(BR-TOPIK-012, -016)', (tester, env) async {
    final attempt = await seed(env, reading);
    await pump(tester, env, attempt.id);

    await tester.tap(find.text('② 보기 2'));
    await tester.pumpAndSettle();
    expect(tile(tester, '② 보기 2').tone, MxChoiceTone.selected);
    await tester.tap(find.text('④ 보기 4'));
    await tester.pumpAndSettle();
    expect(tile(tester, '② 보기 2').tone, MxChoiceTone.idle);
    expect(tile(tester, '④ 보기 4').tone, MxChoiceTone.selected);
    final answer = (await stored(tester, env, attempt.id)).answers.first;
    expect(answer.selectedIdx, 4);
  });

  libraryTest('Next, Previous and a grid cell move; the time of the question '
      'left is written (BR-TOPIK-015)', (tester, env) async {
    final attempt = await seed(env, reading);
    await pump(tester, env, attempt.id);

    wait(env, 7);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 50'), findsOneWidget);
    wait(env, 4);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 50'), findsOneWidget);
    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('10 / 50'), findsOneWidget);

    final times = {
      for (final answer in (await stored(tester, env, attempt.id)).answers)
        if (answer.timeSpentMs > 0) answer.questionNo: answer.timeSpentMs,
    };
    expect(times, {1: 7000, 2: 4000});
  });

  libraryTest('in the background no time runs (BR-TOPIK-015)', (
    tester,
    env,
  ) async {
    final attempt = await seed(env, reading);
    await pump(tester, env, attempt.id);

    wait(env, 3);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    wait(env, 600);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    wait(env, 2);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final first = (await stored(tester, env, attempt.id)).answers.first;
    expect(first.timeSpentMs, 5000);
  });

  libraryTest('Close leaves with nothing lost: the attempt stays in progress '
      'with its answer and its time (BR-TOPIK-010)', (tester, env) async {
    final attempt = await seed(env, reading);
    final exits = await pump(tester, env, attempt.id);

    await tester.tap(find.text('① 보기 1'));
    await tester.pumpAndSettle();
    wait(env, 5);
    await tester.tap(find.byTooltip('Close'));
    expect(exits.closes, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final detail = await stored(tester, env, attempt.id);
    expect(detail.attempt.isCompleted, isFalse);
    expect(detail.answers.first.selectedIdx, 1);
    expect(detail.answers.first.timeSpentMs, 5000);
  });

  libraryTest('Submit with blanks asks; Keep answering stays; Submit '
      'submits and opens the summary (BR-TOPIK-013, -014)', (
    tester,
    env,
  ) async {
    final attempt = await seed(env, reading, currentNo: 50, answers: {1: 1});
    final exits = await pump(tester, env, attempt.id);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('49 questions unanswered'), findsOneWidget);
    await tester.tap(find.text('Keep answering'));
    await tester.pumpAndSettle();
    expect(exits.submitted, isEmpty);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').last);
    await tester.pumpAndSettle();
    expect(exits.submitted, [attempt.id]);
    expect((await stored(tester, env, attempt.id)).attempt.isCompleted, isTrue);
  });

  libraryTest('with every question answered, Submit does not ask', (
    tester,
    env,
  ) async {
    final attempt = await seed(
      env,
      reading,
      currentNo: 50,
      answers: {for (final question in reading.questions) question.no: 1},
    );
    final exits = await pump(tester, env, attempt.id);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(exits.submitted, [attempt.id]);
  });

  libraryTest('while submitting, a second tap and Back do nothing '
      '(BR-TOPIK-014)', (tester, env) async {
    final attempt = await seed(
      env,
      reading,
      currentNo: 50,
      answers: {for (final question in reading.questions) question.no: 2},
    );
    late _HeldSubmit held;
    final exits = await pump(
      tester,
      env,
      attempt.id,
      overrides: [
        submitTopikAttemptUseCaseProvider.overrideWith(
          (ref) => held = _HeldSubmit(
            SubmitTopikAttemptUseCase(
              FakeTopikContentRepository([reading]),
              TopikAttemptRepositoryImpl(env.db),
            ),
          ),
        ),
      ],
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    await tester.tap(find.byType(MxSpinner), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(held.calls, 1);
    expect(find.byType(TopikAttemptScreen), findsOneWidget);

    held.release.complete();
    await tester.pumpAndSettle();
    expect(exits.submitted, [attempt.id]);
  });

  libraryTest('a choice that is not saved says so and is not shown as '
      'chosen (UC-TOPIK-003 E4)', (tester, env) async {
    final attempt = await seed(env, reading);
    await pump(
      tester,
      env,
      attempt.id,
      overrides: [
        answerTopikQuestionUseCaseProvider.overrideWith(
          (ref) => AnswerTopikQuestionUseCase(_FailingAnswer()),
        ),
      ],
    );

    await tester.tap(find.text('③ 보기 3'));
    await tester.pumpAndSettle();
    expect(find.text("Your choice wasn't saved. Try again."), findsOneWidget);
    expect(tile(tester, '③ 보기 3').tone, MxChoiceTone.idle);
  });

  libraryTest('listening: the group loads its clip, never plays it, and '
      'keeps it across its questions; another group loads its own '
      '(BR-TOPIK-017)', (tester, env) async {
    final attempt = await seed(env, listening, currentNo: 48);
    final player = FakeTopikAudioRepository();
    await pump(tester, env, attempt.id, test: listening, player: player);

    expect(player.calls, hasLength(1));
    expect(player.state.isPlaying, isFalse);
    // 48 → 49: another group, its own clip.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(player.calls, hasLength(2));
    // 49 → 50: the same group, the clip as it is.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(player.calls, hasLength(2));
    expect(player.state.isPlaying, isFalse);
  });

  libraryTest('audio that fails is a warning; answering still works '
      '(BR-TOPIK-017)', (tester, env) async {
    final attempt = await seed(env, listening);
    final player = FakeTopikAudioRepository()..failsLoads = true;
    await pump(tester, env, attempt.id, test: listening, player: player);

    expect(find.text("Couldn't play this audio"), findsOneWidget);
    await tester.tap(find.text('② 보기 2'));
    await tester.pumpAndSettle();
    expect(tile(tester, '② 보기 2').tone, MxChoiceTone.selected);
  });

  libraryTest('the script shows once the question is answered, or by its '
      'toggle (spec §5.5, D15)', (tester, env) async {
    final attempt = await seed(env, listening);
    await pump(tester, env, attempt.id, test: listening);
    final script = listening.groups.first.script!;

    expect(find.text(script), findsNothing);
    await tester.tap(find.text('Show script'));
    await tester.pumpAndSettle();
    expect(find.text(script), findsOneWidget);
    await tester.tap(find.text('Hide script'));
    await tester.pumpAndSettle();
    expect(find.text(script), findsNothing);
    await tester.tap(find.text('① 보기 1'));
    await tester.pumpAndSettle();
    expect(find.text(script), findsNothing, reason: 'hidden by the person');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('② 보기 2'));
    await tester.pumpAndSettle();
    expect(find.text(listening.groups[1].script!), findsOneWidget);
  });

  libraryTest('the attempt deleted elsewhere: missing, and Back to the test '
      'leaves (UC-TOPIK-003 E2)', (tester, env) async {
    final attempt = await seed(env, reading);
    final exits = await pump(tester, env, attempt.id);

    await TopikAttemptRepositoryImpl(env.db).delete(attempt.id);
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Back to the test'));
    expect(exits.closes, 1);
  });

  libraryTest('the test changed: the attempt offers Delete, which leaves '
      '(BR-TOPIK-019)', (tester, env) async {
    final attempt = await seed(env, reading);
    final exits = await pump(tester, env, attempt.id, catalog: const []);

    expect(
      find.text("This test changed and can't be continued"),
      findsOneWidget,
    );
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Delete attempt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(exits.closes, 1);
    expect(
      await tester.runAsync(
        () => TopikAttemptRepositoryImpl(env.db).watchAttempt(attempt.id).first,
      ),
      isNull,
    );
  });

  libraryTest('a link to a submitted attempt offers its summary', (
    tester,
    env,
  ) async {
    final done = await topikSeedCompleted(env, reading, startedAt: libraryToday);
    final exits = await pump(tester, env, done.id);

    expect(find.text('This attempt was submitted'), findsOneWidget);
    await tester.tap(find.text('See summary'));
    expect(exits.submitted, [done.id]);
  });

  libraryTest('a read that fails: Retry reads again; Close stays', (
    tester,
    env,
  ) async {
    final attempt = await seed(env, reading);
    var reads = 0;
    await pump(
      tester,
      env,
      attempt.id,
      overrides: [
        topikAttemptProvider(attempt.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikAttemptView?>.error(StateError('read'));
          }
          return Stream.value(null);
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });

  libraryTest('in Vietnamese: the same question, relabelled; the Korean '
      'stays (UC-TOPIK-003 A4)', (tester, env) async {
    final attempt = await seed(env, reading, currentNo: 2);
    await pump(tester, env, attempt.id, locale: const Locale('vi'));

    expect(find.text('2. ${reading.questions[1].stemKo}'), findsOneWidget);
    expect(find.text('Câu sau'), findsOneWidget);
    expect(find.text('② 보기 2'), findsOneWidget);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_attempt_screen_test.dart`
Expected: FAIL to compile (`topik_attempt_screen.dart` is missing).

- [ ] **Step 2: The screen**

`lib/features/topik/presentation/screens/topik_attempt_screen.dart`:

```dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_attempt_controller.dart';
import 'package:memox/features/topik/presentation/providers/topik_attempt_provider.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_attempt_dialogs_widget.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_question_grid_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_attempt_footer_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Screen 37 (UC-TOPIK-003): one question per page under its group's
/// material, in Practice mode.
///
/// - A pick is saved at once and shows only as chosen (BR-TOPIK-012, -016).
/// - Previous, Next and the grid move (BR-TOPIK-015).
/// - Submit asks when questions are blank (BR-TOPIK-014).
/// - Leaving loses nothing (BR-TOPIK-010).
///
/// The question clock lives in [TopikAttemptController]; this screen pauses
/// and resumes it with the app, and writes it when it goes. Where Close and
/// a submit lead, `app/` decides.
class TopikAttemptScreen extends ConsumerStatefulWidget {
  const TopikAttemptScreen({
    super.key,
    required this.attemptId,
    required this.onClose,
    required this.onSubmitted,
  });

  final String attemptId;

  /// Leaves: Close, and the way out of the states with nothing to answer.
  final VoidCallback onClose;

  /// The attempt was submitted: its summary (38) replaces this screen.
  final ValueChanged<String> onSubmitted;

  @override
  ConsumerState<TopikAttemptScreen> createState() => _TopikAttemptScreenState();
}

class _TopikAttemptScreenState extends ConsumerState<TopikAttemptScreen> {
  late final TopikAttemptController _controller;
  late final AppLifecycleListener _lifecycle;

  /// The group pane shows its instruction alone (critique F5).
  var _isCollapsed = false;

  /// The person's own show or hide of a group's script, by group; without
  /// one, the script shows once the current question is answered (D15).
  final _scriptChoice = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _controller = ref.read(
      topikAttemptControllerProvider(widget.attemptId).notifier,
    );
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    // The screen goes (Close, Back, a route on top that replaces it): the
    // current question keeps its time (BR-TOPIK-015).
    unawaited(_controller.leave());
    super.dispose();
  }

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.resume();
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        unawaited(_controller.pause());
      case AppLifecycleState.inactive:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attemptProvider = topikAttemptProvider(widget.attemptId);
    final async = ref.watch(attemptProvider);
    final isSubmitting = ref.watch(
      topikAttemptControllerProvider(widget.attemptId),
    );
    return switch (async) {
      AsyncError(:final error, :final isLoading) => _plain(
        MxErrorState(
          title: l10n.topikAttemptErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(attemptProvider),
          isRetrying: isLoading,
        ),
      ),
      AsyncData(value: null) => _plain(
        // Deleted elsewhere or the account changed (UC-TOPIK-003 E2): a gone
        // item, not an error.
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.topikAttemptMissing,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToTest,
          onAction: widget.onClose,
        ),
      ),
      AsyncValue(:final value?)
          when value.detail.attempt.isCompleted && !isSubmitting =>
        _plain(
          MxEmptyState(
            icon: AppIcons.check,
            title: l10n.topikSubmittedTitle,
            tone: MxEmptyStateTone.neutral,
            actionLabel: l10n.topikSeeSummary,
            onAction: () => widget.onSubmitted(widget.attemptId),
          ),
        ),
      AsyncValue(:final value?) when value.isContentMissing => _plain(
        MxEmptyState(
          icon: AppIcons.alert,
          title: l10n.topikContentChangedTitle,
          tone: MxEmptyStateTone.warning,
          actionLabel: l10n.topikDeleteAttempt,
          onAction: () => unawaited(_delete()),
        ),
      ),
      AsyncValue(:final value?) => _answering(value, isSubmitting),
      _ => _plain(
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingAttempt),
        ),
      ),
    };
  }

  /// A state with nothing to answer: the plain bar with Close, and [body]
  /// (The Content Gate Rule: no footer, no grid; critique F8).
  Widget _plain(Widget body) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.topikPractice,
        leading: MxIconButton(
          icon: AppIcons.close,
          semanticLabel: l10n.topikClose,
          onPressed: widget.onClose,
        ),
      ),
      body: MxScreenScroll(children: [body]),
    );
  }

  Widget _answering(TopikAttemptView view, bool isSubmitting) {
    final l10n = context.l10n;
    final test = view.test!;
    final questions = test.questions;
    final attempt = view.detail.attempt;
    final index = max(
      0,
      questions.indexWhere((q) => q.no == attempt.currentQuestionNo),
    );
    final question = questions[index];
    final group = test.groups.firstWhere((g) => g.groupId == question.groupId);
    final selected = {
      for (final answer in view.detail.answers)
        if (answer.selectedIdx case final idx?) answer.questionNo: idx,
    };
    final isScriptShown =
        _scriptChoice[group.groupId] ?? selected.containsKey(question.no);
    return PopScope(
      // Back while submitting does nothing (BR-TOPIK-014).
      canPop: !isSubmitting,
      child: MxAppShell(
        isSession: true,
        hasOwnAppBarGround: true,
        appBar: MxStudyTopBar(
          modeLabel: l10n.topikPractice,
          // The track is the position, as the counter (critique F2).
          current: index + 1,
          total: questions.length,
          counterLabel: l10n.topikOfTotal(question.no, questions.last.no),
          closeLabel: l10n.topikClose,
          onClose: isSubmitting ? () {} : widget.onClose,
        ),
        body: TopikTwoPaneWidget(
          top: TopikGroupPaneWidget(
            key: ValueKey(group.groupId),
            group: group,
            audio: _clipOf(test, group),
            isCollapsed: _isCollapsed,
            isScriptShown: isScriptShown,
            onToggleCollapsed: () =>
                setState(() => _isCollapsed = !_isCollapsed),
            onToggleScript: () =>
                setState(() => _scriptChoice[group.groupId] = !isScriptShown),
          ),
          bottom: TopikQuestionPaneWidget(
            key: ValueKey(question.no),
            question: question,
            selectedIdx: selected[question.no],
            onPick: isSubmitting
                ? null
                : (idx) => unawaited(_answer(question.no, idx)),
          ),
        ),
        footer: TopikAttemptFooterWidget(
          onPrevious: index == 0
              ? null
              : () => unawaited(_move(questions[index - 1].no)),
          onNext: index == questions.length - 1
              ? null
              : () => unawaited(_move(questions[index + 1].no)),
          onQuestions: () => unawaited(
            _openGrid(view, [for (final q in questions) q.no], selected),
          ),
          onSubmit: () => unawaited(_submit(view, selected.length)),
          isSubmitting: isSubmitting,
        ),
      ),
    );
  }

  /// The group's clip of its section's audio file; null without either.
  static TopikAudioClip? _clipOf(TopikTest test, TopikQuestionGroup group) {
    final asset = test.audioAsset;
    final audio = group.audio;
    if (asset == null || audio == null) return null;
    return TopikAudioClip(
      asset: asset,
      startMs: audio.startMs,
      endMs: audio.endMs,
    );
  }

  Future<void> _answer(int questionNo, int idx) => _command(
    () => _controller.answer(questionNo: questionNo, selectedIdx: idx),
    failureMessage: context.l10n.topikChoiceNotSaved,
  );

  Future<void> _move(int questionNo) =>
      _command(() => _controller.move(questionNo));

  Future<void> _openGrid(
    TopikAttemptView view,
    List<int> questionNos,
    Map<int, int> selected,
  ) async {
    final current = view.detail.attempt.currentQuestionNo;
    final pick = await showTopikQuestionGrid(
      context,
      questionNos: questionNos,
      answered: selected.keys.toSet(),
      current: current,
    );
    if (!mounted) return;
    switch (pick) {
      case TopikGridQuestion(:final no) when no != current:
        await _move(no);
      case TopikGridSubmit():
        await _submit(view, selected.length);
      case TopikGridQuestion() || null:
        return;
    }
  }

  Future<void> _submit(TopikAttemptView view, int answeredCount) async {
    final l10n = context.l10n;
    final blanks = view.detail.answers.length - answeredCount;
    if (blanks > 0) {
      final isSure = await showMxConfirm(
        context,
        title: l10n.topikUnansweredTitle(blanks),
        body: l10n.topikUnansweredBody,
        cancelLabel: l10n.topikKeepAnswering,
        confirmLabel: l10n.topikSubmit,
      );
      if (!isSure || !mounted) return;
    }
    await _command(
      () => _controller.submit(view.detail.attempt.testId),
      onDone: (_) => widget.onSubmitted(widget.attemptId),
    );
  }

  Future<void> _delete() async {
    if (!await showTopikDeleteDialog(context) || !mounted) return;
    await _command(_controller.delete, onDone: (_) => widget.onClose());
  }

  /// Runs a command. A refusal is a snackbar naming it, except for an
  /// attempt already gone, which the screen shows. A database failure is
  /// [failureMessage], or the failure's own words; nothing was lost
  /// (UC-TOPIK-003 E4).
  Future<void> _command<T>(
    Future<Outcome<T, TopikRejection>?> Function() command, {
    void Function(T value)? onDone,
    String? failureMessage,
  }) async {
    try {
      final outcome = await command();
      if (!mounted || outcome == null) return;
      switch (outcome) {
        case Ok(:final value):
          onDone?.call(value);
        case Rejected(reason: TopikRejection.notFound):
          return;
        case Rejected(:final reason):
          showMxSnackbar(
            context,
            message: context.l10n.topikRejectionMessage(reason),
          );
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      showMxSnackbar(
        context,
        message: failureMessage ?? context.l10n.failure(failure),
      );
    }
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_attempt_screen_test.dart`
Expected: PASS.

- [ ] **Step 3: The route**

1. In `lib/app/router/app_routes.dart`, before `static String topikAttempt(`, add:

```dart
  /// The path parameter that names an attempt.
  static const String topikAttemptIdParam = 'attemptId';

  /// An attempt (screen 37), relative to [topik]; on the root navigator.
  static const String topikAttemptChild = 'attempt/:$topikAttemptIdParam';
```

2. In `lib/app/router/topik_routes.dart`:
   - add `import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';` (the file already imports `package:flutter/widgets.dart`);
   - change the signature to `GoRoute topikRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(`;
   - insert this route first in `routes: [` (before `topikTestChild`):

```dart
    // A full-screen task above the shell (spec §8): no tab bar.
    GoRoute(
      path: AppRoutes.topikAttemptChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) => TopikAttemptScreen(
        attemptId: state.pathParameters[AppRoutes.topikAttemptIdParam]!,
        onClose: () => _leave(context),
        onSubmitted: (id) =>
            unawaited(context.pushReplacement(AppRoutes.topikSummary(id))),
      ),
    ),
```

   and at the end of the file:

```dart
/// Back to where the attempt was opened from, or TOPIK home when it was
/// opened alone.
void _leave(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.topik);
```

3. In `lib/app/router/app_router.dart`, replace `routes: [topikRoute()],` with `routes: [topikRoute(rootNavigator)],`.

- [ ] **Step 4: Route tests**

Add to `test/app/topik_routes_test.dart` these imports, where missing:
- `package:memox/features/topik/presentation/screens/topik_attempt_screen.dart`
- `package:memox/features/topik/domain/models/topik_level_model.dart`
- `package:memox/features/topik/domain/models/topik_section_model.dart`
- `package:memox/features/topik/di/topik_audio_repository_provider.dart`
- `../support/topik_fakes.dart`

Then add:

```dart
  libraryTest('an attempt opens full screen above the tab bar, and Close '
      'returns to the test (spec §8)', (tester, env) async {
    final tests = topikScreenTests();
    final test96 = tests.firstWhere(
      (t) =>
          t.level == TopikLevel.topik2 &&
          t.round == 96 &&
          t.section == TopikSection.reading,
    );
    await topikSeedInProgress(env, test96, startedAt: libraryToday);
    await pumpMemoxApp(tester, env, overrides: topikContentOverrides(tests));
    await _go(tester, AppRoutes.topikTest(test96.testId));

    await _tap(tester, find.text('#1'));
    expect(find.byType(TopikAttemptScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    await _tap(tester, find.byTooltip(_en.topikClose));
    expect(find.byType(TopikTestDetailScreen), findsOneWidget);
  });

  libraryTest('a deep link to an attempt opens it; Close lands on TOPIK', (
    tester,
    env,
  ) async {
    final tests = topikScreenTests();
    final attempt = await topikSeedInProgress(
      env,
      tests.last,
      startedAt: libraryToday,
    );
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...topikContentOverrides(tests),
        topikAudioRepositoryProvider.overrideWithValue(
          FakeTopikAudioRepository(),
        ),
      ],
    );
    await _go(tester, AppRoutes.topikAttempt(attempt.id));

    expect(find.byType(TopikAttemptScreen), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.topikClose));
    expect(find.byType(TopikHomeScreen), findsOneWidget);
  });
```


Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/topik_routes_test.dart test/features/topik/presentation/topik_attempt_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/router lib/features/topik test/app/topik_routes_test.dart test/features/topik
git commit -m "feat(topik): DEV-394 screen 37, the attempt, on the root navigator"
```

---
### Task 6: Goldens, the visual audit, and the detail file as built

**Files:**
- Create:
  - `test/features/topik/presentation/topik_attempt_golden_test.dart` (its goldens are `goldens/topik_attempt_*_{light,dark}.png`)
  - `test/visual_audit/screens/features/topik/screens/topik_attempt_screen_visual_audit_test.dart`
- Modify:
  - `docs/shared/ui/screen-handoff/37-topik-attempt.md`
  - `docs/shared/ui/screen-handoff/00-index.md`
  - `docs/_generated/traceability.md` (generated)

- [ ] **Step 1: The goldens**

`test/features/topik/presentation/topik_attempt_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_attempt_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

/// A submit that never returns, so Submit spins.
final class _PendingSubmit implements SubmitTopikAttemptUseCase {
  @override
  Future<Outcome<TopikAttempt, TopikRejection>> call({
    required String attemptId,
    required String testId,
    required int elapsedMs,
  }) => Completer<Outcome<TopikAttempt, TopikRejection>>().future;
}

/// Reading 96 with a real-length passage for group 1, so the two panes show
/// how they share the height.
TopikTest _reading() {
  final json = topikTestJson();
  groupJson(json, 'g1')['passage'] = {
    'textKo':
        '우리 회사는 다음 달부터 재택근무 제도를 시범적으로 운영합니다. '
        '희망하는 직원은 이번 주 금요일까지 팀장에게 신청서를 제출하면 됩니다. '
        '재택근무를 하는 날에도 오전 10시부터 오후 4시까지는 반드시 연락이 '
        '가능해야 하며, 주간 회의에는 화상으로 참여해야 합니다. 자세한 내용은 '
        '사내 게시판을 참고하시기 바랍니다.',
  };
  questionJson(json, 1)['stemKo'] = '이 글의 내용과 같은 것을 고르십시오.';
  return topikTestOfFixtureJson(json);
}

// Screen 37's states (detail file 37).
void main() {
  final reading = _reading();
  final listening = topikTestFixture(section: TopikSection.listening);
  final firstClip = TopikAudioClip(
    asset: listening.audioAsset!,
    startMs: listening.groups.first.audio!.startMs,
    endMs: listening.groups.first.audio!.endMs,
  );

  Future<TopikAttempt> seed(
    LibraryEnv env,
    TopikTest test, {
    int? currentNo,
    Map<int, int> answers = const {},
  }) async {
    final store = TopikAttemptRepositoryImpl(env.db);
    final attempt = topikOk(await store.start(test, now: libraryToday));
    for (final MapEntry(key: no, value: idx) in answers.entries) {
      topikOk(
        await store.answer(
          attemptId: attempt.id,
          questionNo: no,
          selectedIdx: idx,
          elapsedMs: 0,
          now: libraryToday,
        ),
      );
    }
    if (currentNo != null) {
      topikOk(
        await store.move(
          attemptId: attempt.id,
          toQuestionNo: currentNo,
          elapsedMs: 0,
          now: libraryToday,
        ),
      );
    }
    return attempt;
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      String attemptId, {
      List<TopikTest>? catalog,
      FakeTopikAudioRepository? player,
      List<Override> overrides = const [],
      Future<void> Function()? before,
      bool settles = true,
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikAttemptScreen(
          attemptId: attemptId,
          onClose: () {},
          onSubmitted: (_) {},
        ),
        brightness,
        overrides: [
          ...topikContentOverrides(catalog ?? [reading, listening]),
          topikAudioRepositoryProvider.overrideWithValue(
            player ?? FakeTopikAudioRepository(),
          ),
          ...overrides,
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      if (before != null) {
        await before();
        if (settles) {
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      await expectBoundaryGolden(
        tester,
        'goldens/topik_attempt_${state}_$theme.png',
      );
    });

    libraryTest('answering, $theme', (tester, env) async {
      final attempt = await seed(env, reading, answers: {1: 2});
      await shoot(tester, env, 'reading', attempt.id);
    });

    libraryTest('answeringListening, $theme', (tester, env) async {
      final attempt = await seed(env, listening);
      final player = FakeTopikAudioRepository(
        TopikAudioState(
          status: TopikAudioStatus.ready,
          clip: firstClip,
          positionMs: 12000,
          speed: 1,
        ),
      );
      await shoot(tester, env, 'listening', attempt.id, player: player);
    });

    libraryTest('scriptShown, $theme', (tester, env) async {
      final attempt = await seed(env, listening, answers: {1: 3});
      await shoot(tester, env, 'script', attempt.id);
    });

    libraryTest('collapsed, $theme', (tester, env) async {
      final attempt = await seed(env, reading, answers: {1: 2});
      await shoot(
        tester,
        env,
        'collapsed',
        attempt.id,
        before: () => tester.tap(find.text('Hide passage')),
      );
    });

    libraryTest('grid, $theme', (tester, env) async {
      final attempt = await seed(
        env,
        reading,
        currentNo: 12,
        answers: {for (var no = 1; no <= 11; no++) no: no % 4 + 1},
      );
      await shoot(
        tester,
        env,
        'grid',
        attempt.id,
        before: () => tester.tap(find.text('Questions')),
      );
    });

    libraryTest('submitConfirm, $theme', (tester, env) async {
      final attempt = await seed(
        env,
        reading,
        currentNo: 50,
        answers: {
          for (final question in reading.questions.take(47))
            question.no: 1,
        },
      );
      await shoot(
        tester,
        env,
        'submit_confirm',
        attempt.id,
        before: () => tester.tap(find.text('Submit')),
      );
    });

    libraryTest('submitting, $theme', (tester, env) async {
      final attempt = await seed(
        env,
        reading,
        currentNo: 50,
        answers: {for (final question in reading.questions) question.no: 1},
      );
      await shoot(
        tester,
        env,
        'submitting',
        attempt.id,
        overrides: [
          submitTopikAttemptUseCaseProvider.overrideWith(
            (ref) => _PendingSubmit(),
          ),
        ],
        before: () => tester.tap(find.text('Submit')),
        settles: false,
      );
    });

    libraryTest('audioError, $theme', (tester, env) async {
      final attempt = await seed(env, listening);
      await shoot(
        tester,
        env,
        'audio_error',
        attempt.id,
        player: FakeTopikAudioRepository()..failsLoads = true,
      );
    });

    libraryTest('attemptMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', 'gone');
    });

    libraryTest('contentMissing, $theme', (tester, env) async {
      final attempt = await seed(env, reading);
      await shoot(tester, env, 'content_missing', attempt.id, catalog: []);
    });

    libraryTest('submitted, $theme', (tester, env) async {
      final done = await topikSeedCompleted(
        env,
        reading,
        startedAt: libraryToday,
      );
      await shoot(tester, env, 'submitted', done.id);
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikAttemptView?>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        'a1',
        overrides: [
          topikAttemptProvider('a1').overrideWith((ref) => pending.stream),
        ],
      );
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        'a1',
        overrides: [
          topikAttemptProvider('a1').overrideWith(
            (ref) => Stream<TopikAttemptView?>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then open every `test/features/topik/presentation/goldens/topik_attempt_*_light.png` and two dark ones.
Expected:
- 26 new PNGs;
- no other golden changes;
- every state reads as its row in the States table;
- no line breaks inside a term, and no overflow stripes.

Fix what the pictures show before going on (The Wrap Rule, One Line Rule).

- [ ] **Step 2: The visual audit companion**

`test/visual_audit/screens/features/topik/screens/topik_attempt_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_attempt_fixtures.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_fakes.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 37, ${locale.languageCode}', (tester, env) async {
      // Listening at its fullest: the audio bar, the script shown, an
      // option chosen.
      final test = topikTestFixture(section: TopikSection.listening);
      final store = TopikAttemptRepositoryImpl(env.db);
      final attempt = topikOk(await store.start(test, now: libraryToday));
      topikOk(
        await store.answer(
          attemptId: attempt.id,
          questionNo: test.questions.first.no,
          selectedIdx: 2,
          elapsedMs: 0,
          now: libraryToday,
        ),
      );
      await auditProductionScreen(
        tester,
        screen: TopikAttemptScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikAttemptScreen(
            attemptId: attempt.id,
            onClose: () {},
            onSubmitted: (_) {},
          ),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: [
            ...topikContentOverrides([test]),
            topikAudioRepositoryProvider.overrideWithValue(
              FakeTopikAudioRepository(),
            ),
          ],
        ),
      );
    });
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/visual_audit/screens/features/topik/screens/topik_attempt_screen_visual_audit_test.dart`
Expected: PASS. A finding it reports is fixed in the screen, not silenced.

- [ ] **Step 3: The detail file as built**

In `docs/shared/ui/screen-handoff/37-topik-attempt.md`:

1. **Layout table.** Rewrite the rows to what was built:
   - Top bar: the track is the position (critique F2).
   - Group pane: recessed ground; at most half the body; "Hide passage" / "Show passage" text buttons (F5). It keeps the instruction and the audio bar when collapsed.
   - Audio bar: play-circle / pause-circle; time in `labelSmall` with no tabular figures; the speed sheet of `MxOptionRow`s (F6).
   - Question pane: "{no}. {stem}"; options `bodyLarge` ①–④ (F3).
   - Footer: Previous `MxIconButton` · "Questions" outline · Next / Submit primary (F1).
   - Grid: tinted cells (F7).
2. **States table.**
   - Add a row `error` (`topik_attempt_error_*`: `MxErrorState` with Retry, Close stays).
   - Add a row `submitted` (`topik_attempt_submitted_*`: a link to a submitted attempt, neutral `MxEmptyState` "This attempt was submitted" with "See summary").
   - Replace the "Not built yet" paragraph with: **Built (plan 6b, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_attempt_screen_test.dart`, `topik_attempt_controller_test.dart`, `test/app/topik_routes_test.dart`).
3. **Transitions table.** Keep every row. Set Evidence to `VERIFIED <test name>` from Task 5 (and Task 2 for the clock) for each one, with these exceptions:
   - "app to background": VERIFIED `::in the background no time runs (BR-TOPIK-015)`.
   - "process death": UNVERIFIED (the time since the last write is lost by design, spec §5.4; no test kills the process).
   - "attempt deleted or account switched": VERIFIED for the delete (`::the attempt deleted elsewhere…`); the account switch is the same stream emitting null after `LocalDataReset`, UNVERIFIED at screen level.
   - Add the rows for `error` → Retry, a link to a submitted attempt → `submitted` → See summary, and the delete from `contentMissing`.
4. **Rulings.** Add F1–F14 of the critique, one line each, with "(plan 6b)".
5. **Copy.** Write the copy as built:
   - "Retry" (`commonRetry`).
   - "Hide script".
   - "Playback speed".
   - "{n} questions unanswered".
   - "This attempt was submitted" · "See summary".
   - "Couldn't load this attempt".
   - "Picture".

In `docs/shared/ui/screen-handoff/00-index.md`, set row 37's status to `built`.

Run: `python3 tools/docs/generate.py`
Expected: `docs/_generated/traceability.md` is rewritten with the new tests.

- [ ] **Step 4: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/claude-0/dod6b.log 2>&1; echo $?; tail -5 /tmp/claude-0/dod6b.log`
Expected: `0` and `PASS`. Then run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`; expected: every golden passes.

- [ ] **Step 5: Commit**

```bash
git add test/features/topik test/visual_audit docs/shared/ui/screen-handoff docs/_generated
git commit -m "test(topik): DEV-394 screen 37's goldens and visual audit; detail file as built"
```
