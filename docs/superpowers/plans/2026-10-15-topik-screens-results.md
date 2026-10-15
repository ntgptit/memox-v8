# TOPIK screens 38 (summary) and 39 (review) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** after a submit, a person sees the result of the attempt and reviews each question with its right answer and its supporting content.
- **Result:** score, a donut of correct answers, the figures, the time per question, every answer filtered by status, and the result per question type.
- **Review:** filtered like the summary, read-only, with the audio and the script.
- Sources: UC-TOPIK-004, UC-TOPIK-005; BR-TOPIK-006, -010, -013, -017, -019, -023…025; spec §6.4, §8. Plan 6c of Phase 2, epic DEV-394.

**Architecture:**
- In `lib/features/topik/presentation/`:
  - Two stream providers over the plan-4 use cases. `WatchTopikSummaryUseCase` gives the snapshot; `WatchTopikReviewUseCase` gives the attempt over the current content.
  - Section widgets: hero and donut, figures, filter chips, bar chart, answer rows, type stats, review question.
  - Two screens.
- The review screen reuses screen 37's panes and audio bar.
- `lib/app/router/topik_routes.dart` adds `…/attempt/:id/summary` and `…/attempt/:id/review?q=` on the root navigator, as siblings of the attempt route, so Submit's `pushReplacement` leaves 36 under 38.

**Tech Stack:**
- Flutter 3.47.5 and Riverpod 3 codegen.
- go_router 18.
- `CustomPaint` (donut).
- The `Mx*` shared widgets, including `MxChoiceTile`'s right and wrong tones.
- The golden harness.

**Spec:**
- `docs/superpowers/specs/2026-10-15-topik-practice-design.md` §6.4, §8, §13.10.
- Detail files `docs/shared/ui/screen-handoff/38-topik-summary.md` and `39-topik-review.md`.
- The pre-plan critique `critique-38-39.md` (findings S1–S11 and V1–V10, adopted below).

## Global Constraints

- **Presentation rules, as in plans 6a and 6b:**
  - File suffixes.
  - No `ref.read` in `build`.
  - `mounted` checks.
  - No raw `InkWell`, `Slider`, bare `Icon` or Material button in feature code. A tappable bar is an `MxRowInk`.
- **Copy:**
  - Every new key goes in `app_en.arb`, with `placeholders` first and `description` last in `"@key"`, and in `app_vi.arb`. Then run `flutter gen-l10n`.
  - Korean content is never localized.
  - Meta lines glue their terms with `topikTerms` (The Wrap Rule).
- **The summary reads the snapshot only** (BR-TOPIK-013, -019). The test's current content never changes a figure; its absence changes nothing on 38.
- **Your and Correct are option numbers ①–④, never option text** (brief 2026-10-15). Text lives in Review.
- **Unanswered is neutral, never warning** (DESIGN.md Semantic).
- **One primary per decision:**
  - On 38, "Review answers" is primary and "Done" outline.
  - On 39, "Next" (or "Done" on the last question) is primary and "Previous" outline.
- **Goldens:** English, light and dark, 1080×2400 at 3x, through `pumpLibraryGolden` + `expectBoundaryGolden`, run only by `run_goldens.sh`. Every new golden goes on the `golden-compare` page.
- **Commits** name DEV-394 and end with the session's attribution lines.

## Review Focus

1. **Perfect and zero** (BR-TOPIK-023, -025):
   - 100 / 100 does not break the hero at 360 dp, and there is no weakest type.
   - 0 / 100 with every question blank shows an empty donut, every bar neutral, and Wrong / Correct filters that are empty but say so (Tasks 2, 3, 6).
2. **TOPIK I reading numbering** (BR-TOPIK-001): the chart, the rows and Review use the real numbers 31–70; `?q=31` opens question 31 (Tasks 2, 5).
3. **The content gone or updated after the attempt** (BR-TOPIK-019):
   - 38 is unchanged.
   - 39 shows the banner when the version differs, and contentMissing with "Back to summary" when the test is gone (Tasks 3, 5).
4. **Filters on 39**: Previous and Next walk the filtered questions only. A filter change opens its first question. A filter with no question cannot be picked (Task 5).
5. **The attempt deleted while 38 or 39 is open** gives attemptMissing with a way back. A link to an attempt in progress is not reviewable (Tasks 3, 5).

---

### Task 1: Copy, labels and providers

**Files:**
- Modify:
  - `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`
  - `lib/features/topik/presentation/widgets/support/topik_labels_widget.dart`
  - `lib/app/router/app_routes.dart` (`topikReview` takes `questionNo`)
- Create, in `lib/features/topik/presentation/providers/`:
  - `watch_topik_summary_use_case_provider.dart`
  - `topik_summary_provider.dart`
  - `watch_topik_review_use_case_provider.dart`
  - `topik_review_provider.dart`
- Test:
  - `test/features/topik/presentation/topik_labels_test.dart` (one test added)
  - `test/app/topik_routes_test.dart` (`the paths` extended)

**Interfaces:**
- Produces:
  - `topikSummaryProvider(String attemptId)` → `Stream<TopikSummaryView?>`.
  - `topikReviewProvider(String attemptId)` → `Stream<TopikReviewView?>`.
  - On `TopikLabels`:
    - `topikTypeName(TopikQuestionType)`
    - `topikFilterName(TopikAnswerFilter)`
    - `topikAnswerStatusName(TopikAnswerStatus)`
    - `topikFilterEmpty(TopikAnswerFilter)`
  - `AppRoutes.topikReview(String attemptId, {int? questionNo})`, and `AppRoutes.topikSummaryChild` / `AppRoutes.topikReviewChild`.

- [ ] **Step 1: The copy**

```bash
python3 - <<'EOF'
import json
S = {"type": "String"}
I = {"type": "int"}
TYPES = [
 ("AnswerQuestion", "Answer the question", "Trả lời câu hỏi"),
 ("NextUtterance", "Next line", "Câu nói tiếp theo"),
 ("Place", "Where it happens", "Địa điểm"),
 ("Topic", "What it's about", "Chủ đề"),
 ("Picture", "Matching picture", "Chọn tranh"),
 ("SameContent", "Same content", "Nội dung giống"),
 ("MainIdea", "Main idea", "Ý chính"),
 ("Paired", "Paired questions", "Câu hỏi theo cặp"),
 ("FillBlank", "Fill the blank", "Điền chỗ trống"),
 ("NotSame", "Not the same", "Nội dung không giống"),
 ("Ordering", "Sentence order", "Sắp xếp câu"),
 ("LongPassage", "Long passage", "Đoạn văn dài"),
 ("PictureGraph", "Picture or graph", "Tranh hoặc biểu đồ"),
 ("NextAction", "Next action", "Hành động tiếp theo"),
 ("PairedAdvanced", "Paired, advanced", "Câu hỏi theo cặp, nâng cao"),
 ("GrammarBlank", "Grammar blank", "Điền ngữ pháp"),
 ("SimilarExpression", "Similar expression", "Biểu hiện tương tự"),
 ("AdTopic", "What the ad is for", "Chủ đề quảng cáo"),
 ("ParagraphBlank", "Paragraph blank", "Điền vào đoạn văn"),
 ("Headline", "Headline", "Tiêu đề báo"),
 ("ComplexBlank", "Complex blank", "Điền chỗ trống phức hợp"),
 ("SameContentMid", "Same content, mid-length", "Nội dung giống, đoạn vừa"),
 ("Theme", "Main theme", "Chủ đề chính"),
 ("SentenceInsert", "Where the sentence goes", "Chèn câu"),
]
KEYS = [("topikType" + k, en, vi, "Screen 38: a question type's name (BR-TOPIK-005, -024).", None) for k, en, vi in TYPES] + [
 ("topikHideAnswers", "Hide answers", "Ẩn đáp án", "Screen 38: the eye hides the right answers.", None),
 ("topikShowAnswers", "Show answers", "Hiện đáp án", "Screen 38: the eye shows them again.", None),
 ("topikAnswered", "Answered", "Đã trả lời", "Screen 38: a figure.", None),
 ("topikUnanswered", "Unanswered", "Chưa trả lời", "Screens 38, 39: a figure, a filter and a status.", None),
 ("topikLongest", "Longest", "Lâu nhất", "Screen 38: a figure with no question.", None),
 ("topikLongestOf", "Longest · Q{no}", "Lâu nhất · Câu {no}", "Screen 38: the figure's label, with the question that took longest.", {"no": I}),
 ("topikFilterAll", "All", "Tất cả", "Screens 38, 39: a filter.", None),
 ("topikWrong", "Wrong", "Sai", "Screens 38, 39: a filter and a status.", None),
 ("topikCorrect", "Correct", "Đúng", "Screens 38, 39: a filter and a status.", None),
 ("topikTimePerQuestion", "Time per question", "Thời gian mỗi câu", "Screen 38: the chart's header.", None),
 ("topikBarLabel", "Question {no}, {status}, {duration}", "Câu {no}, {status}, {duration}", "Screen 38: a bar of the chart to TalkBack.", {"no": I, "status": S, "duration": S}),
 ("topikQuestionTitle", "Question {no}", "Câu {no}", "Screen 38: an answer row.", {"no": I}),
 ("topikYourAnswer", "Your answer {option}", "Bạn chọn {option}", "Screens 38, 39: the option the person chose, as ①–④.", {"option": S}),
 ("topikRightAnswer", "Right answer {option}", "Đáp án đúng {option}", "Screens 38, 39: the right option, as ①–④.", {"option": S}),
 ("topikNotAnswered", "Not answered", "Chưa trả lời", "Screens 38, 39: a question left blank.", None),
 ("topikAnswers", "Answers", "Các câu trả lời", "Screen 38: the rows' header.", None),
 ("topikByType", "By question type", "Theo dạng câu", "Screen 38: the type section's title.", None),
 ("topikWeakest", "Weakest", "Yếu nhất", "Screen 38: the weakest type's badge (BR-TOPIK-024).", None),
 ("topikReviewAnswers", "Review answers", "Xem lại đáp án", "Screen 38: opens Review.", None),
 ("topikDone", "Done", "Xong", "Screens 38, 39: leaves.", None),
 ("topikNoWrong", "No wrong answers", "Không có câu sai", "Screen 38: the Wrong filter with nothing.", None),
 ("topikNoUnanswered", "No unanswered questions", "Không có câu bỏ trống", "Screen 38: the Unanswered filter with nothing.", None),
 ("topikNoCorrect", "No correct answers yet", "Chưa có câu đúng", "Screen 38: the Correct filter with nothing.", None),
 ("topikSummaryErrorTitle", "Couldn't load this summary", "Không tải được tổng kết", "Screen 38: load error title.", None),
 ("topikLoadingSummary", "Loading the summary", "Đang tải tổng kết", "Screen 38: what the skeleton is.", None),
 ("topikScoreLabel", "Score {score} of {max}, {correct} of {count} correct", "Điểm {score} trên {max}, đúng {correct} trên {count} câu", "Screen 38: the hero's score and donut to TalkBack.", {"score": I, "max": I, "correct": I, "count": I}),
 ("topikReviewTitle", "Review · {no} / {last}", "Xem lại · {no} / {last}", "Screen 39: the title with the real question numbers.", {"no": I, "last": I}),
 ("topikOptionReviewLabel", "Option {number}, {text}, {state}", "Phương án {number}, {text}, {state}", "Screen 39: an option with its state to TalkBack.", {"number": I, "text": S, "state": S}),
 ("topikRightState", "the right answer", "đáp án đúng", "Screen 39: an option's state.", None),
 ("topikYourWrongState", "your answer, wrong", "bạn chọn, sai", "Screen 39: an option's state.", None),
 ("topikUpdatedTitle", "This test was updated after this attempt", "Đề này đã được cập nhật sau lượt làm", "Screen 39: the content banner (BR-TOPIK-019).", None),
 ("topikUpdatedBody", "Your score stays as it was.", "Điểm của bạn vẫn giữ nguyên.", "Screen 39: the content banner's body.", None),
 ("topikReviewUnavailableTitle", "Review isn't available for this test", "Không xem lại được đề này", "Screen 39: the test is gone (BR-TOPIK-019).", None),
 ("topikReviewUnavailableBody", "Your score is still in the summary.", "Điểm vẫn có trong tổng kết.", "Screen 39: the test is gone; nothing was lost.", None),
 ("topikBackToSummary", "Back to summary", "Về tổng kết", "Screen 39: leaves to 38.", None),
 ("topikReviewErrorTitle", "Couldn't load this review", "Không tải được phần xem lại", "Screen 39: load error title.", None),
 ("topikLoadingReview", "Loading the review", "Đang tải phần xem lại", "Screen 39: what the skeleton is.", None),
]
for lang in ("en", "vi"):
    path = f"lib/l10n/app_{lang}.arb"
    data = json.load(open(path))
    out = {}
    anchor = "@topikLoadingAttempt" if lang == "en" else "topikLoadingAttempt"
    assert anchor in data, anchor
    for key, value in data.items():
        out[key] = value
        if key == anchor:
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

Expected: `flutter gen-l10n` exits 0.

- [ ] **Step 2: Write the failing tests**

Add to `test/features/topik/presentation/topik_labels_test.dart`. Import `topik_question_type_model.dart`, `topik_attempt_summary_model.dart` and `topik_attempt_model.dart`, then add:

```dart
  test('screen 38 names: every type, filter and status in both languages', () {
    for (final type in TopikQuestionType.values) {
      expect(en.topikTypeName(type), isNotEmpty, reason: type.name);
      expect(vi.topikTypeName(type), isNotEmpty, reason: type.name);
    }
    expect(en.topikTypeName(TopikQuestionType.r2SentenceInsert),
        'Where the sentence goes');
    expect([for (final f in TopikAnswerFilter.values) en.topikFilterName(f)],
        ['All', 'Wrong', 'Unanswered', 'Correct']);
    expect(en.topikAnswerStatusName(TopikAnswerStatus.unanswered),
        'Unanswered');
    expect(en.topikFilterEmpty(TopikAnswerFilter.wrong), 'No wrong answers');
  });
```

In `test/app/topik_routes_test.dart`'s `the paths`, add:

```dart
    expect(
      AppRoutes.topikReview('a1', questionNo: 31),
      '/study/topik/attempt/a1/review?q=31',
    );
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_labels_test.dart test/app/topik_routes_test.dart`
Expected: FAIL to compile (`topikTypeName` and `questionNo` are undefined).

- [ ] **Step 3: Labels**

In `topik_labels_widget.dart`, add `import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';`, `import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';` and `import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';`. Then add inside the extension:

```dart
  /// A question type's short name (screen 38's By question type).
  String topikTypeName(TopikQuestionType type) => switch (type) {
    TopikQuestionType.l1AnswerQuestion => topikTypeAnswerQuestion,
    TopikQuestionType.l1NextUtterance ||
    TopikQuestionType.l2NextUtterance => topikTypeNextUtterance,
    TopikQuestionType.l1Place => topikTypePlace,
    TopikQuestionType.l1Topic || TopikQuestionType.r1Topic => topikTypeTopic,
    TopikQuestionType.l1Picture => topikTypePicture,
    TopikQuestionType.l1MatchContent ||
    TopikQuestionType.r1MatchContent ||
    TopikQuestionType.l2MatchContent ||
    TopikQuestionType.r2MatchContent => topikTypeSameContent,
    TopikQuestionType.l1MainIdea ||
    TopikQuestionType.r1MainIdea ||
    TopikQuestionType.l2MainIdea => topikTypeMainIdea,
    TopikQuestionType.l1Paired ||
    TopikQuestionType.r1Paired ||
    TopikQuestionType.l2Paired ||
    TopikQuestionType.r2Paired => topikTypePaired,
    TopikQuestionType.r1FillBlank => topikTypeFillBlank,
    TopikQuestionType.r1NotMatch => topikTypeNotSame,
    TopikQuestionType.r1Ordering ||
    TopikQuestionType.r2Ordering => topikTypeOrdering,
    TopikQuestionType.r1LongPaired ||
    TopikQuestionType.r2LongPaired => topikTypeLongPassage,
    TopikQuestionType.l2PictureGraph => topikTypePictureGraph,
    TopikQuestionType.l2NextAction => topikTypeNextAction,
    TopikQuestionType.l2PairedAdvanced => topikTypePairedAdvanced,
    TopikQuestionType.r2GrammarBlank => topikTypeGrammarBlank,
    TopikQuestionType.r2SimilarExpression => topikTypeSimilarExpression,
    TopikQuestionType.r2AdTopic => topikTypeAdTopic,
    TopikQuestionType.r2ParagraphBlank => topikTypeParagraphBlank,
    TopikQuestionType.r2Headline => topikTypeHeadline,
    TopikQuestionType.r2ComplexBlank => topikTypeComplexBlank,
    TopikQuestionType.r2MatchContentMid => topikTypeSameContentMid,
    TopikQuestionType.r2Theme => topikTypeTheme,
    TopikQuestionType.r2SentenceInsert => topikTypeSentenceInsert,
  };

  String topikFilterName(TopikAnswerFilter filter) => switch (filter) {
    TopikAnswerFilter.all => topikFilterAll,
    TopikAnswerFilter.wrong => topikWrong,
    TopikAnswerFilter.unanswered => topikUnanswered,
    TopikAnswerFilter.correct => topikCorrect,
  };

  String topikAnswerStatusName(TopikAnswerStatus status) => switch (status) {
    TopikAnswerStatus.correct => topikCorrect,
    TopikAnswerStatus.wrong => topikWrong,
    TopikAnswerStatus.unanswered => topikUnanswered,
  };

  /// What a filter with no question says (screen 38's filterEmpty).
  String topikFilterEmpty(TopikAnswerFilter filter) => switch (filter) {
    TopikAnswerFilter.wrong => topikNoWrong,
    TopikAnswerFilter.unanswered => topikNoUnanswered,
    TopikAnswerFilter.correct || TopikAnswerFilter.all => topikNoCorrect,
  };
```

- [ ] **Step 4: Routes' paths**

In `lib/app/router/app_routes.dart`, replace `topikReview` and add the two children after `topikAttemptChild`:

```dart
  /// A submitted attempt's Summary (screen 38), relative to [topik]; on the
  /// root navigator, beside the attempt so Submit can replace 37 with it.
  static const String topikSummaryChild =
      'attempt/:$topikAttemptIdParam/summary';

  /// An attempt's Review (screen 39), relative to [topik]; `?q=` opens a
  /// question.
  static const String topikReviewChild = 'attempt/:$topikAttemptIdParam/review';

  /// The query parameter that names the question Review opens.
  static const String topikReviewQuestionParam = 'q';
```

```dart
  static String topikReview(String attemptId, {int? questionNo}) =>
      questionNo == null
      ? '${topikAttempt(attemptId)}/review'
      : '${topikAttempt(attemptId)}/review?$topikReviewQuestionParam=$questionNo';
```

- [ ] **Step 5: Providers**

`lib/features/topik/presentation/providers/watch_topik_summary_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_summary_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_summary_use_case_provider.g.dart';

@riverpod
WatchTopikSummaryUseCase watchTopikSummaryUseCase(Ref ref) =>
    WatchTopikSummaryUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

`lib/features/topik/presentation/providers/topik_summary_provider.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_summary_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_summary_provider.g.dart';

/// Screen 38's data, from the attempt's snapshot; null once the attempt is
/// gone or is not submitted.
@riverpod
Stream<TopikSummaryView?> topikSummary(Ref ref, String attemptId) =>
    ref.watch(watchTopikSummaryUseCaseProvider)(attemptId);
```

`lib/features/topik/presentation/providers/watch_topik_review_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_review_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_review_use_case_provider.g.dart';

@riverpod
WatchTopikReviewUseCase watchTopikReviewUseCase(Ref ref) =>
    WatchTopikReviewUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

`lib/features/topik/presentation/providers/topik_review_provider.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_review_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_review_provider.g.dart';

/// Screen 39's data: the attempt over the current content; null once the
/// attempt is gone.
@riverpod
Stream<TopikReviewView?> topikReview(Ref ref, String attemptId) =>
    ref.watch(watchTopikReviewUseCaseProvider)(attemptId);
```

Run: `dart run build_runner build --delete-conflicting-outputs`, then the tests of Step 2.
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/topik lib/app/router/app_routes.dart test/features/topik test/app/topik_routes_test.dart
git commit -m "feat(topik): DEV-394 screens 38 and 39's copy, labels and providers"
```

---
### Task 2: The summary's widgets

**Files:**
- Create, in `lib/features/topik/presentation/widgets/`:
  - `sections/topik_score_donut_widget.dart`
  - `sections/topik_summary_hero_widget.dart`
  - `sections/topik_summary_figures_widget.dart`
  - `sections/topik_answer_filter_chips_widget.dart`
  - `sections/topik_question_bar_chart_widget.dart`
  - `sections/topik_type_stats_widget.dart`
  - `items/topik_answer_row_widget.dart`
- Test: `test/features/topik/presentation/topik_summary_widgets_test.dart`

**Interfaces:**
- Consumes: `TopikAttemptSummary`, `TopikAttemptAnswer`, `TopikAnswerFilter` (plan 4), and the Task 1 labels.
- Produces:
  - `TopikSummaryHeroWidget({required TopikAttempt attempt, required TopikAttemptSummary summary})`.
  - `TopikScoreDonutWidget({required int correct, required int total})`.
  - `TopikSummaryFiguresWidget({required TopikAttemptSummary summary})`.
  - `TopikAnswerFilterChipsWidget({required TopikAttemptSummary summary, required TopikAnswerFilter selected, required ValueChanged<TopikAnswerFilter> onSelected, bool isEmptyDisabled = false})`.
  - `TopikQuestionBarChartWidget({required List<TopikAttemptAnswer> answers, required ValueChanged<int> onOpen})`.
  - `TopikTypeStatsWidget({required TopikAttemptSummary summary})`.
  - `TopikAnswerRowWidget({required TopikAttemptAnswer answer, required bool isRightHidden, required VoidCallback onOpen})`.

- [ ] **Step 1: Write the failing tests**

`test/features/topik/presentation/topik_summary_widgets_test.dart`:

```dart
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_answer_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_figures_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

/// Question [no] answered [selected] (null: blank) where [correct] is right,
/// taking [ms]; of [type].
TopikAttemptAnswer _answer(
  int no, {
  int? selected,
  int correct = 1,
  int ms = 60000,
  TopikQuestionType type = TopikQuestionType.r1Topic,
}) => TopikAttemptAnswer(
  questionNo: no,
  selectedIdx: selected,
  timeSpentMs: ms,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: correct,
  points: 2,
  pointsEarned: selected == correct ? 2 : 0,
  questionType: type,
);

TopikAttemptSummary _summary(List<TopikAttemptAnswer> answers) {
  final correct = answers.where((a) => a.status == TopikAnswerStatus.correct);
  final answered = answers.where((a) => a.selectedIdx != null).length;
  return TopikAttemptSummary(
    score: correct.length * 2,
    maxScore: answers.length * 2,
    correctCount: correct.length,
    questionCount: answers.length,
    answeredCount: answered,
    accuracyPercent: answered == 0 ? 0 : correct.length * 100 ~/ answered,
    longest: answers.reduce((a, b) => b.timeSpentMs > a.timeSpentMs ? b : a),
    typeStats: const [
      TopikTypeStat(type: TopikQuestionType.r1Topic, correct: 2, total: 2),
      TopikTypeStat(type: TopikQuestionType.r1FillBlank, correct: 0, total: 2),
    ],
    weakestType: TopikQuestionType.r1FillBlank,
    answers: answers,
  );
}

// Screen 38's parts (detail file 38; critique S1, S3–S7).
void main() {
  final answers = [
    _answer(31, selected: 1, ms: 65000),
    _answer(32, selected: 3, ms: 125000, type: TopikQuestionType.r1FillBlank),
    _answer(33, ms: 0, type: TopikQuestionType.r1FillBlank),
    _answer(34, selected: 1, ms: 30000),
  ];
  final summary = _summary(answers);

  Future<void> host(WidgetTester tester, LibraryEnv env, Widget child) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: SingleChildScrollView(child: child)),
    );
    await tester.pumpAndSettle();
  }

  libraryTest('the donut writes correct of total', (tester, env) async {
    await host(tester, env, const TopikScoreDonutWidget(correct: 48, total: 50));
    expect(find.text('48 / 50'), findsOneWidget);
  });

  libraryTest('the figures: accuracy, answered, unanswered, and the longest '
      'with its real number (critique S1)', (tester, env) async {
    await host(tester, env, TopikSummaryFiguresWidget(summary: summary));

    expect(find.text('66%'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2m 05s'), findsOneWidget);
    expect(find.text('LONGEST · Q32'), findsOneWidget);
  });

  libraryTest('the chips carry their counts; an empty one can be off', (
    tester,
    env,
  ) async {
    final picks = <TopikAnswerFilter>[];
    await host(
      tester,
      env,
      TopikAnswerFilterChipsWidget(
        summary: _summary([_answer(31, selected: 1)]),
        selected: TopikAnswerFilter.all,
        onSelected: picks.add,
        isEmptyDisabled: true,
      ),
    );

    final chips = tester.widgetList<MxFilterChip>(find.byType(MxFilterChip));
    expect([for (final c in chips) c.count], [1, 0, 0, 1]);
    expect([for (final c in chips) c.onSelected == null], [
      false,
      true,
      true,
      false,
    ]);
    await tester.tap(find.text('Correct'));
    expect(picks, [TopikAnswerFilter.correct]);
  });

  libraryTest('the chart: a bar per question with its real number, one node '
      'each, and a tap opens it (critique S4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final opened = <int>[];
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(answers: answers, onOpen: opened.add),
    );

    for (final no in [31, 32, 33, 34]) {
      expect(find.text('$no'), findsOneWidget);
    }
    expect(
      find.bySemanticsLabel('Question 32, Wrong, 2m 05s'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Question 33, Unanswered, 0s'),
      findsOneWidget,
    );
    await tester.tap(find.text('32'));
    expect(opened, [32]);
    handle.dispose();
  });

  libraryTest('an answer row: yours, the right one and the time; the eye '
      'hides the right one; the status badge (critique S5)', (
    tester,
    env,
  ) async {
    var opens = 0;
    await host(
      tester,
      env,
      Column(
        children: [
          TopikAnswerRowWidget(
            answer: answers[1],
            isRightHidden: false,
            onOpen: () => opens++,
          ),
          TopikAnswerRowWidget(
            answer: answers[2],
            isRightHidden: true,
            onOpen: () {},
          ),
        ],
      ),
    );

    expect(findPlainText('Your answer ③ · Right answer ① · 2m 05s'),
        findsOneWidget);
    expect(findPlainText('Not answered · 0s'), findsOneWidget);
    final badges = tester.widgetList<MxBadge>(find.byType(MxBadge)).toList();
    expect([for (final b in badges) b.tone], [
      MxBadgeTone.danger,
      MxBadgeTone.neutral,
    ]);
    await tester.tap(find.text('Question 32'));
    expect(opens, 1);
  });

  libraryTest('by type: each with its share; the weakest marked '
      '(BR-TOPIK-024)', (tester, env) async {
    await host(tester, env, TopikTypeStatsWidget(summary: summary));

    expect(find.text("What it's about"), findsOneWidget);
    expect(find.text('Fill the blank'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('Weakest'), findsOneWidget);
  });

  libraryTest('by type: no weakest when every type is perfect', (
    tester,
    env,
  ) async {
    final perfect = TopikAttemptSummary(
      score: 4,
      maxScore: 4,
      correctCount: 2,
      questionCount: 2,
      answeredCount: 2,
      accuracyPercent: 100,
      longest: answers.first,
      typeStats: const [
        TopikTypeStat(type: TopikQuestionType.r1Topic, correct: 2, total: 2),
      ],
      weakestType: null,
      answers: [answers.first, answers.last],
    );
    await host(tester, env, TopikTypeStatsWidget(summary: perfect));
    expect(find.text('Weakest'), findsNothing);
  });

  libraryTest('a chip says selected to TalkBack', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikAnswerFilterChipsWidget(
        summary: summary,
        selected: TopikAnswerFilter.wrong,
        onSelected: (_) {},
      ),
    );
    final node = tester.getSemantics(find.text('Wrong'));
    expect(node.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_summary_widgets_test.dart`
Expected: FAIL to compile (the widget files are missing).

- [ ] **Step 2: The donut**

`lib/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

/// Screen 38's donut (detail file 38, critique S3): the correct answers of
/// the questions, a `success` arc on the `surfaceContainerHighest` track,
/// "{correct} / {total}" inside. A topik widget, not MxMasteryDonut, which
/// draws the mastery ramp. Its row says the figures to TalkBack.
class TopikScoreDonutWidget extends StatelessWidget {
  const TopikScoreDonutWidget({
    super.key,
    required this.correct,
    required this.total,
  });

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return SizedBox.square(
      dimension: dimens.sizeControl * 2,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: total == 0 ? 0 : correct / total,
          track: context.colors.surfaceContainerHighest,
          arc: context.mxColors.success,
          width: dimens.space8,
        ),
        child: Center(
          child: Text(
            context.l10n.topikOfTotal(correct, total),
            style: context.texts.titleMedium,
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fraction,
    required this.track,
    required this.arc,
    required this.width,
  });

  final double fraction;
  final Color track;
  final Color arc;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, stroke..color = track);
    if (fraction <= 0) return;
    canvas.drawArc(rect, -pi / 2, 2 * pi * fraction, false, stroke..color = arc);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.arc != arc ||
      old.width != width;
}
```

- [ ] **Step 3: The hero and the figures**

`lib/features/topik/presentation/widgets/sections/topik_summary_hero_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Screen 38's hero (detail file 38, critique S2, S3): which test, when and
/// how long, then the score in the stat role beside the donut of correct
/// answers. From the attempt's own fields, so it holds when the test is
/// gone (BR-TOPIK-019).
class TopikSummaryHeroWidget extends StatelessWidget {
  const TopikSummaryHeroWidget({
    super.key,
    required this.attempt,
    required this.summary,
  });

  final TopikAttempt attempt;
  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: dimens.space16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: dimens.space4,
            children: [
              Text(
                l10n.topikTerms([
                  l10n.topikRoundNumber(attempt.round),
                  l10n.topikLevelName(attempt.level),
                  l10n.topikSectionName(attempt.section),
                ]),
                style: context.texts.titleMedium,
              ),
              Text(
                l10n.topikTerms([
                  l10n.topikDateTime(attempt.startedAt),
                  l10n.duration(attempt.totalTimeMs),
                ]),
                style: context.texts.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Semantics(
            label: l10n.topikScoreLabel(
              summary.score,
              summary.maxScore,
              summary.correctCount,
              summary.questionCount,
            ),
            excludeSemantics: true,
            child: Row(
              spacing: dimens.space16,
              children: [
                Expanded(
                  child: Text(
                    l10n.topikOfTotal(summary.score, summary.maxScore),
                    style: context.texts.displayMedium,
                  ),
                ),
                TopikScoreDonutWidget(
                  correct: summary.correctCount,
                  total: summary.questionCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/topik/presentation/widgets/sections/topik_summary_figures_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Screen 38's figures (critique S1): accuracy, answered, unanswered and the
/// longest question, two by two so each fits one line at 360 dp. The
/// longest names its real number in the label; with no time it is a dash.
class TopikSummaryFiguresWidget extends StatelessWidget {
  const TopikSummaryFiguresWidget({super.key, required this.summary});

  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final longest = summary.longest;
    final hasLongest = longest != null && longest.timeSpentMs > 0;
    Widget tile(String value, String label) => Expanded(
      child: MxStatTile(
        value: value,
        label: label,
        layout: MxStatTileLayout.boxed,
      ),
    );
    return MxCard(
      child: Column(
        spacing: dimens.space16,
        children: [
          Row(
            spacing: dimens.space16,
            children: [
              tile(l10n.topikPercent(summary.accuracyPercent), l10n.topikAccuracy),
              tile('${summary.answeredCount}', l10n.topikAnswered),
            ],
          ),
          Row(
            spacing: dimens.space16,
            children: [
              tile('${summary.unansweredCount}', l10n.topikUnanswered),
              tile(
                hasLongest ? l10n.duration(longest.timeSpentMs) : '–',
                hasLongest
                    ? l10n.topikLongestOf(longest.questionNo)
                    : l10n.topikLongest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: The chips, the chart, the rows and the types**

`lib/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_row.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

/// All · Wrong · Unanswered · Correct, each with its count in the chip's
/// count slot (screens 38, 39). [isEmptyDisabled] turns off a chip with no
/// question (39, critique V5); 38 lets it show its empty state.
class TopikAnswerFilterChipsWidget extends StatelessWidget {
  const TopikAnswerFilterChipsWidget({
    super.key,
    required this.summary,
    required this.selected,
    required this.onSelected,
    this.isEmptyDisabled = false,
  });

  final TopikAttemptSummary summary;
  final TopikAnswerFilter selected;
  final ValueChanged<TopikAnswerFilter> onSelected;
  final bool isEmptyDisabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxChipRow(
      children: [
        for (final filter in TopikAnswerFilter.values)
          _chip(l10n.topikFilterName(filter), filter),
      ],
    );
  }

  Widget _chip(String label, TopikAnswerFilter filter) {
    final count = summary.answersFor(filter).length;
    final isOff = isEmptyDisabled && count == 0 && filter != selected;
    return MxFilterChip(
      label: label,
      count: count,
      isSelected: filter == selected,
      onSelected: isOff ? null : (_) => onSelected(filter),
    );
  }
}
```

`lib/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart`:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// Screen 38's time per question (detail file 38, critique S4):
/// - one bar per question, its height by time, its colour by status;
/// - the real number under each bar;
/// - it scrolls sideways.
///
/// Each bar is a control-wide `MxRowInk` with one TalkBack node; a tap opens
/// that question in Review.
class TopikQuestionBarChartWidget extends StatelessWidget {
  const TopikQuestionBarChartWidget({
    super.key,
    required this.answers,
    required this.onOpen,
  });

  final List<TopikAttemptAnswer> answers;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final longestMs = answers.fold(0, (most, a) => max(most, a.timeSpentMs));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: dimens.space4,
        children: [
          for (final answer in answers)
            _Bar(
              answer: answer,
              share: longestMs == 0 ? 0 : answer.timeSpentMs / longestMs,
              onTap: () => onOpen(answer.questionNo),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.answer, required this.share, required this.onTap});

  final TopikAttemptAnswer answer;

  /// Its time as a share of the longest.
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final status = answer.status ?? TopikAnswerStatus.unanswered;
    final colour = switch (status) {
      TopikAnswerStatus.correct => context.mxColors.success,
      TopikAnswerStatus.wrong => context.colors.error,
      TopikAnswerStatus.unanswered => context.colors.outline,
    };
    final fullHeight = dimens.sizeControl * 2;
    final radius = BorderRadius.circular(dimens.radiusSm);
    return MxRowInk(
      onTap: onTap,
      borderRadius: radius,
      child: Semantics(
        label: l10n.topikBarLabel(
          answer.questionNo,
          l10n.topikAnswerStatusName(status),
          l10n.duration(answer.timeSpentMs),
        ),
        excludeSemantics: true,
        child: SizedBox(
          width: dimens.sizeControl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: dimens.space4,
            children: [
              SizedBox(
                height: fullHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: dimens.space12,
                    height: max(dimens.space4, fullHeight * share),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colour,
                        borderRadius: BorderRadius.circular(dimens.radiusXs),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                '${answer.questionNo}',
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/features/topik/presentation/widgets/items/topik_answer_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One answer of screen 38 (critique S5):
/// - "Question {no}";
/// - "Your answer ② · Right answer ③ · 1m 05s", option numbers only
///   (brief 2026-10-15); the eye drops the right answer;
/// - the status as a badge: success, danger, or neutral for a blank
///   (never warning).
///
/// The row opens Review at the question.
class TopikAnswerRowWidget extends StatelessWidget {
  const TopikAnswerRowWidget({
    super.key,
    required this.answer,
    required this.isRightHidden,
    required this.onOpen,
  });

  final TopikAttemptAnswer answer;
  final bool isRightHidden;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = answer.status ?? TopikAnswerStatus.unanswered;
    final selected = answer.selectedIdx;
    final correct = answer.correctIdx;
    final meta = l10n.topikTerms([
      if (selected == null)
        l10n.topikNotAnswered
      else
        l10n.topikYourAnswer(topikCircled(selected)),
      if (!isRightHidden && correct != null)
        l10n.topikRightAnswer(topikCircled(correct)),
      l10n.duration(answer.timeSpentMs),
    ]);
    return MxListRow(
      title: l10n.topikQuestionTitle(answer.questionNo),
      meta: Text(
        meta,
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: MxBadge(
        label: l10n.topikAnswerStatusName(status),
        tone: switch (status) {
          TopikAnswerStatus.correct => MxBadgeTone.success,
          TopikAnswerStatus.wrong => MxBadgeTone.danger,
          TopikAnswerStatus.unanswered => MxBadgeTone.neutral,
        },
      ),
      hasChevron: true,
      onTap: onOpen,
    );
  }
}
```

`lib/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// Screen 38's By question type (critique S7, BR-TOPIK-024): each type with
/// "{correct} / {total}" and a thin track; the weakest marked.
class TopikTypeStatsWidget extends StatelessWidget {
  const TopikTypeStatsWidget({super.key, required this.summary});

  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxSection(
      title: l10n.topikByType,
      children: [
        for (final stat in summary.typeStats)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space16,
              vertical: dimens.space12,
            ),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: dimens.space8,
                children: [
                  Row(
                    spacing: dimens.space8,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.topikTypeName(stat.type),
                          style: context.texts.titleSmall,
                        ),
                      ),
                      if (stat.type == summary.weakestType)
                        MxBadge(
                          label: l10n.topikWeakest,
                          tone: MxBadgeTone.warning,
                        ),
                      Text(
                        l10n.topikOfTotal(stat.correct, stat.total),
                        style: context.texts.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  MxLinearProgress(
                    value: stat.total == 0 ? 0 : stat.correct / stat.total,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_summary_widgets_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/topik test/features/topik
git commit -m "feat(topik): DEV-394 screen 38's hero, figures, chips, chart, rows and types"
```

---
### Task 3: Screen 38 and its route

**Files:**
- Create: `lib/features/topik/presentation/screens/topik_summary_screen.dart`
- Modify:
  - `lib/app/router/topik_routes.dart`
  - `test/support/topik_attempt_screen_fixtures.dart` (`topikSeedSubmitted`)
- Test:
  - `test/features/topik/presentation/topik_summary_screen_test.dart`
  - `test/app/topik_routes_test.dart` (one test added)

**Interfaces:**
- Consumes: `topikSummaryProvider` (Task 1) and the Task 2 widgets.
- Produces:
  - `TopikSummaryScreen({required String attemptId, required void Function(int? questionNo) onReview, required VoidCallback onDone})`.
  - In `test/support/topik_attempt_screen_fixtures.dart`: `topikSeedSubmitted(LibraryEnv, TopikTest, {Map<int, int> answers})`, which submits after the answers and gives them varied times.

- [ ] **Step 1: The fixture**

Append to `test/support/topik_attempt_screen_fixtures.dart`:

```dart
/// A submitted attempt of [test] with [answers] (question → option) chosen
/// in that order; each answer gives the question before it a different time,
/// so the chart has varied bars.
Future<TopikAttempt> topikSeedSubmitted(
  LibraryEnv env,
  TopikTest test, {
  Map<int, int> answers = const {},
}) async {
  final store = TopikAttemptRepositoryImpl(env.db);
  final attempt = topikOk(await store.start(test, now: libraryToday));
  var stepMs = 20000;
  for (final MapEntry(key: no, value: idx) in answers.entries) {
    topikOk(
      await store.answer(
        attemptId: attempt.id,
        questionNo: no,
        selectedIdx: idx,
        elapsedMs: stepMs,
        now: libraryToday,
      ),
    );
    stepMs = stepMs % 150000 + 35000;
  }
  return topikOk(
    await store.submit(
      attemptId: attempt.id,
      test: test,
      elapsedMs: 45000,
      now: libraryToday.add(const Duration(minutes: 50)),
    ),
  );
}
```

- [ ] **Step 2: Write the failing screen tests**

`test/features/topik/presentation/topik_summary_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_summary_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

final class _Exits {
  final reviews = <int?>[];
  var dones = 0;
}

// Screen 38 (UC-TOPIK-004; BR-TOPIK-013, -019, -023…025): each test is a
// row of detail file 38's Transitions table.
void main() {
  final reading = topikTestFixture();

  /// Questions 1–3 right, 4 wrong, 5 blank, the rest blank.
  Map<int, int> mixed(TopikTest test) {
    final q = test.questions;
    return {
      for (final question in q.take(3)) question.no: question.answerIdx,
      q[3].no: q[3].answerIdx % 4 + 1,
    };
  }

  Future<_Exits> pump(
    WidgetTester tester,
    LibraryEnv env,
    String attemptId, {
    List<TopikTest>? catalog,
    List<Override> overrides = const [],
  }) async {
    final exits = _Exits();
    await pumpLibraryScreen(
      tester,
      env,
      TopikSummaryScreen(
        attemptId: attemptId,
        onReview: exits.reviews.add,
        onDone: () => exits.dones++,
      ),
      overrides: [...topikContentOverrides(catalog ?? [reading]), ...overrides],
    );
    await tester.pumpAndSettle();
    return exits;
  }

  libraryTest('the result from the snapshot: score, rows per question; a row, '
      'Review answers and Done lead out (UC-TOPIK-004)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    final exits = await pump(tester, env, done.id);

    expect(find.text('${done.score} / 100'), findsOneWidget);
    expect(find.text('3 / 50'), findsOneWidget);
    expect(find.text('Question 1'), findsOneWidget);
    await tester.tap(find.text('Question 1'));
    await tester.tap(find.text('Review answers'));
    await tester.tap(find.text('Done'));
    expect(exits.reviews, [1, null]);
    expect(exits.dones, 1);
  });

  libraryTest('a filter narrows the chart and the rows; an empty one says so '
      '(UC-TOPIK-004 step 5, A1)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    await pump(tester, env, done.id);

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    expect(find.text('Question 4'), findsOneWidget);
    expect(find.text('Question 1'), findsNothing);

    final perfect = await topikSeedSubmitted(
      env,
      reading,
      answers: {for (final q in reading.questions) q.no: q.answerIdx},
    );
    await pump(tester, env, perfect.id);
    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    expect(find.text('No wrong answers'), findsOneWidget);
    expect(find.text('Weakest'), findsNothing);
  });

  libraryTest('the eye hides the right answers, and shows them again '
      '(UC-TOPIK-004 step 6)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    await pump(tester, env, done.id);

    expect(findPlainTextContaining('Right answer'), findsWidgets);
    await tester.tap(find.byTooltip('Hide answers'));
    await tester.pumpAndSettle();
    expect(findPlainTextContaining('Right answer'), findsNothing);
    await tester.tap(find.byTooltip('Show answers'));
    await tester.pumpAndSettle();
    expect(findPlainTextContaining('Right answer'), findsWidgets);
  });

  libraryTest('TOPIK I reading numbers 31–70 (BR-TOPIK-001)', (
    tester,
    env,
  ) async {
    final t1 = topikTestFixture(level: TopikLevel.topik1);
    final done = await topikSeedSubmitted(env, t1, answers: mixed(t1));
    await pump(tester, env, done.id, catalog: [t1]);

    expect(find.text('Question 31'), findsOneWidget);
    expect(find.text('Question 1'), findsNothing);
  });

  libraryTest('the test removed afterwards changes nothing: the snapshot '
      'stays (BR-TOPIK-019)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    await pump(tester, env, done.id, catalog: const []);

    expect(find.text('${done.score} / 100'), findsOneWidget);
    expect(find.text('Question 4'), findsOneWidget);
  });

  libraryTest('the attempt deleted elsewhere: missing, Back to the test '
      '(UC-TOPIK-004 E1)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading);
    final exits = await pump(tester, env, done.id);

    await TopikAttemptRepositoryImpl(env.db).delete(done.id);
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
    await tester.tap(find.text('Back to the test'));
    expect(exits.dones, 1);
  });

  libraryTest('an attempt in progress has no summary', (tester, env) async {
    final open = await topikSeedAttempt(env, reading);
    await pump(tester, env, open.id);
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });

  libraryTest('a read that fails: Retry reads again', (tester, env) async {
    var reads = 0;
    final done = await topikSeedSubmitted(env, reading);
    await pump(
      tester,
      env,
      done.id,
      overrides: [
        topikSummaryProvider(done.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikSummaryView?>.error(StateError('read'));
          }
          return Stream.value(null);
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_summary_screen_test.dart`
Expected: FAIL to compile (`topik_summary_screen.dart` is missing).

- [ ] **Step 3: The screen**

`lib/features/topik/presentation/screens/topik_summary_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_summary_provider.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_answer_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_figures_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_hero_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 38 (UC-TOPIK-004): one submitted attempt's result, from its
/// snapshot (BR-TOPIK-013, -019).
///
/// - The score and a donut of correct answers.
/// - The figures.
/// - The answers by status, filtered, as a time chart and rows.
/// - The result per question type, with the weakest marked (BR-TOPIK-024).
/// - The eye hides the right answers.
///
/// Where Review and Done lead, `app/` decides.
class TopikSummaryScreen extends ConsumerStatefulWidget {
  const TopikSummaryScreen({
    super.key,
    required this.attemptId,
    required this.onReview,
    required this.onDone,
  });

  final String attemptId;

  /// Opens Review (39), at [questionNo] when one was picked.
  final void Function(int? questionNo) onReview;

  /// Leaves: Done, Back, and the way out of attemptMissing.
  final VoidCallback onDone;

  @override
  ConsumerState<TopikSummaryScreen> createState() => _TopikSummaryScreenState();
}

class _TopikSummaryScreenState extends ConsumerState<TopikSummaryScreen> {
  var _filter = TopikAnswerFilter.all;

  /// The eye: the right answers are hidden (UC-TOPIK-004 step 6).
  var _isRightHidden = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = topikSummaryProvider(widget.attemptId);
    return switch (ref.watch(provider)) {
      AsyncError(:final error, :final isLoading) => _plain(
        MxErrorState(
          title: l10n.topikSummaryErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
          isRetrying: isLoading,
        ),
      ),
      // Gone (deleted elsewhere, the account changed) or not submitted.
      AsyncData(value: null) => _plain(
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.topikAttemptMissing,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToTest,
          onAction: widget.onDone,
        ),
      ),
      AsyncValue(:final value?) => _loaded(value),
      _ => _plain(
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingSummary),
        ),
      ),
    };
  }

  MxAppBar _appBar({List<Widget> actions = const []}) {
    final l10n = context.l10n;
    return MxAppBar(
      title: l10n.topikSummary,
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: l10n.commonBack,
        onPressed: widget.onDone,
      ),
      actions: actions,
    );
  }

  /// A state with nothing to show: the bar and [body], no footer.
  Widget _plain(Widget body) => MxAppShell(
    appBar: _appBar(),
    body: MxScreenScroll(children: [body]),
  );

  Widget _loaded(TopikSummaryView view) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final summary = view.summary;
    final shown = summary.answersFor(_filter);
    return MxAppShell(
      appBar: _appBar(
        actions: [
          MxIconButton(
            icon: AppIcons.preview,
            semanticLabel: _isRightHidden
                ? l10n.topikShowAnswers
                : l10n.topikHideAnswers,
            onPressed: () => setState(() => _isRightHidden = !_isRightHidden),
          ),
        ],
      ),
      body: MxScreenScroll(
        children: [
          TopikSummaryHeroWidget(attempt: view.attempt, summary: summary),
          SizedBox(height: dimens.space24),
          TopikSummaryFiguresWidget(summary: summary),
          SizedBox(height: dimens.space24),
          MxListSectionHeader(label: l10n.topikAnswers),
          TopikAnswerFilterChipsWidget(
            summary: summary,
            selected: _filter,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          SizedBox(height: dimens.space16),
          ..._answers(shown),
          if (summary.typeStats.isNotEmpty) ...[
            SizedBox(height: dimens.space24),
            TopikTypeStatsWidget(summary: summary),
          ],
        ],
      ),
      footer: MxFooterBar(
        child: MxActionPair(
          leading: MxButton(
            label: l10n.topikDone,
            tone: MxButtonTone.outline,
            isBlock: true,
            isSingleLine: true,
            onPressed: widget.onDone,
          ),
          trailing: MxButton(
            label: l10n.topikReviewAnswers,
            isBlock: true,
            isSingleLine: true,
            onPressed: () => widget.onReview(null),
          ),
        ),
      ),
    );
  }

  /// The filtered answers as the time chart and their rows, or what an empty
  /// filter says (UC-TOPIK-004 A1).
  List<Widget> _answers(List<TopikAttemptAnswer> shown) {
    final l10n = context.l10n;
    if (shown.isEmpty) {
      return [
        MxEmptyState(
          icon: AppIcons.check,
          title: l10n.topikFilterEmpty(_filter),
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
        ),
      ];
    }
    return [
      MxListSectionHeader(label: l10n.topikTimePerQuestion),
      TopikQuestionBarChartWidget(answers: shown, onOpen: widget.onReview),
      SizedBox(height: context.dimens.space16),
      MxCard(
        isFullBleed: true,
        child: MxDividedColumn(
          children: [
            for (final answer in shown)
              TopikAnswerRowWidget(
                answer: answer,
                isRightHidden: _isRightHidden,
                onOpen: () => widget.onReview(answer.questionNo),
              ),
          ],
        ),
      ),
    ];
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_summary_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: The route**

In `lib/app/router/topik_routes.dart`, add `import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';` and insert first in `routes: [` (before the attempt route, which would otherwise take `attempt/:id` and find no `summary` child):

```dart
    // A submitted attempt's result (spec §8): Submit replaces 37 with it,
    // so Done and Back land on 36.
    GoRoute(
      path: AppRoutes.topikSummaryChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) {
        final id = state.pathParameters[AppRoutes.topikAttemptIdParam]!;
        return TopikSummaryScreen(
          attemptId: id,
          onReview: (no) => unawaited(
            context.push(AppRoutes.topikReview(id, questionNo: no)),
          ),
          onDone: () => _leave(context),
        );
      },
    ),
```

Add to `test/app/topik_routes_test.dart`, importing `topik_summary_screen.dart` and `../support/topik_attempt_screen_fixtures.dart`:

```dart
  libraryTest('Submit on 37 replaces it with the summary; Done lands on the '
      'test (UC-TOPIK-003 step 6)', (tester, env) async {
    final tests = topikScreenTests();
    final test96 = tests.firstWhere(
      (t) =>
          t.level == TopikLevel.topik2 &&
          t.round == 96 &&
          t.section == TopikSection.reading,
    );
    await topikSeedAttempt(
      env,
      test96,
      answers: {for (final q in test96.questions) q.no: 1},
    );
    await pumpMemoxApp(tester, env, overrides: topikContentOverrides(tests));
    await _go(tester, AppRoutes.topikTest(test96.testId));
    await _tap(tester, find.text('#1'));
    expect(find.byType(TopikAttemptScreen), findsOneWidget);

    await _tap(tester, find.text(_en.topikSubmit));
    expect(find.byType(TopikSummaryScreen), findsOneWidget);
    expect(find.byType(TopikAttemptScreen), findsNothing);
    await _tap(tester, find.text(_en.topikDone));
    expect(find.byType(TopikTestDetailScreen), findsOneWidget);
  });
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/topik_routes_test.dart test/features/topik/presentation/topik_summary_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/router lib/features/topik test/support test/features/topik test/app/topik_routes_test.dart
git commit -m "feat(topik): DEV-394 screen 38, the summary, replacing 37 on submit"
```

---
### Task 4: The review's question, and the group's clip as a domain function

**Files:**
- Modify:
  - `lib/features/topik/domain/models/topik_audio_model.dart` (`topikGroupClip`)
  - `lib/features/topik/presentation/screens/topik_attempt_screen.dart` (its private `_clipOf` goes; it calls `topikGroupClip`)
- Create: `lib/features/topik/presentation/widgets/sections/topik_review_question_widget.dart`
- Test:
  - `test/features/topik/domain/topik_audio_model_test.dart` (one test added)
  - `test/features/topik/presentation/topik_review_question_test.dart`

**Interfaces:**
- Produces:
  - `TopikAudioClip? topikGroupClip(TopikTest test, TopikQuestionGroup group)`.
  - `TopikReviewQuestionWidget({required TopikQuestion question, required TopikAttemptAnswer answer, required bool isContentUpdated})`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/topik/domain/topik_audio_model_test.dart`, importing `topik_section_model.dart` and `../../../support/topik_content_fixtures.dart` if missing:

```dart
  test('a group plays its range of its section file; no file or no range is '
      'no clip', () {
    final listening = topikTestFixture(section: TopikSection.listening);
    final group = listening.groups[1];
    expect(
      topikGroupClip(listening, group),
      TopikAudioClip(
        asset: listening.audioAsset!,
        startMs: group.audio!.startMs,
        endMs: group.audio!.endMs,
      ),
    );
    final reading = topikTestFixture();
    expect(topikGroupClip(reading, reading.groups.first), isNull);
  });
```

`test/features/topik/presentation/topik_review_question_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_review_question_widget.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

TopikAttemptAnswer _answer(TopikQuestion q, int? selected) =>
    TopikAttemptAnswer(
      questionNo: q.no,
      selectedIdx: selected,
      timeSpentMs: 30000,
      answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
      correctIdx: q.answerIdx,
      points: q.points,
      pointsEarned: selected == q.answerIdx ? q.points : 0,
      questionType: q.questionType,
    );

// Screen 39's question (detail file 39; critique V2–V4; BR-TOPIK-006, -010).
void main() {
  final test = topikTestFixture();
  final first = test.questions.first; // answer 1, explanation and a word
  final second = test.questions[1]; // answer 2, no supporting content

  Future<void> host(WidgetTester tester, LibraryEnv env, Widget child) async {
    await pumpLibraryScreen(tester, env, Scaffold(body: child));
    await tester.pumpAndSettle();
  }

  List<MxChoiceTone> tones(WidgetTester tester) => [
    for (final tile in tester.widgetList<MxChoiceTile>(
      find.byType(MxChoiceTile),
    ))
      tile.tone,
  ];

  libraryTest('a wrong answer: the right option right, the choice wrong, '
      'nothing tappable; the explanation and the words in the UI language', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: first,
        answer: _answer(first, 3),
        isContentUpdated: false,
      ),
    );

    expect(tones(tester), [
      MxChoiceTone.right,
      MxChoiceTone.idle,
      MxChoiceTone.wrong,
      MxChoiceTone.idle,
    ]);
    expect(
      tester
          .widgetList<MxChoiceTile>(find.byType(MxChoiceTile))
          .every((tile) => tile.onTap == null),
      isTrue,
    );
    expect(findPlainText('Your answer ③ · Right answer ①'), findsOneWidget);
    expect(find.text('Explanation.'), findsOneWidget);
    expect(findPlainTextContaining('기획'), findsOneWidget);
    expect(findPlainTextContaining('planning'), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('a right answer with no supporting content: no section', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: second,
        answer: _answer(second, 2),
        isContentUpdated: false,
      ),
    );

    expect(tones(tester), [
      MxChoiceTone.idle,
      MxChoiceTone.right,
      MxChoiceTone.idle,
      MxChoiceTone.idle,
    ]);
    expect(find.text('Explanation'), findsNothing);
    expect(find.text('Words'), findsNothing);
  });

  libraryTest('not answered: only the right option marked, and it says so', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: second,
        answer: _answer(second, null),
        isContentUpdated: false,
      ),
    );

    expect(tones(tester), [
      MxChoiceTone.idle,
      MxChoiceTone.right,
      MxChoiceTone.idle,
      MxChoiceTone.idle,
    ]);
    expect(findPlainText('Not answered · Right answer ②'), findsOneWidget);
  });

  libraryTest('content updated after the attempt: the banner '
      '(BR-TOPIK-019)', (tester, env) async {
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: second,
        answer: _answer(second, 2),
        isContentUpdated: true,
      ),
    );

    expect(find.text('This test was updated after this attempt'), findsOneWidget);
    expect(find.text('Your score stays as it was.'), findsOneWidget);
  });

  libraryTest('the options say their state to TalkBack', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikReviewQuestionWidget(
        question: first,
        answer: _answer(first, 3),
        isContentUpdated: false,
      ),
    );

    expect(
      find.bySemanticsLabel('Option 1, 보기 1, the right answer'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Option 3, 보기 3, your answer, wrong'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_audio_model_test.dart test/features/topik/presentation/topik_review_question_test.dart`
Expected: FAIL to compile (`topikGroupClip` and the widget are missing).

- [ ] **Step 2: The group's clip**

At the end of `lib/features/topik/domain/models/topik_audio_model.dart`, adding `import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';` and `import 'package:memox/features/topik/domain/models/topik_test_model.dart';`:

```dart
/// The range of [test]'s section file that [group] plays (spec §5.5); null
/// when the test has no file or the group no range.
TopikAudioClip? topikGroupClip(TopikTest test, TopikQuestionGroup group) {
  final asset = test.audioAsset;
  final audio = group.audio;
  if (asset == null || audio == null) return null;
  return TopikAudioClip(
    asset: asset,
    startMs: audio.startMs,
    endMs: audio.endMs,
  );
}
```

In `topik_attempt_screen.dart`, delete the `_clipOf` method, write `audio: topikGroupClip(test, group),` at its one call, and remove the imports this leaves unused (`topik_question_group_model.dart`, `topik_test_model.dart` if unused).

- [ ] **Step 3: The review question**

`lib/features/topik/presentation/widgets/sections/topik_review_question_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// Screen 39's question (detail file 39, critique V2–V4):
/// - the banner when the content changed after the attempt (BR-TOPIK-019);
/// - "{no}. {stem}";
/// - the options: the right one in the study `right` tone, the person's
///   wrong choice in `wrong`, nothing tappable (BR-TOPIK-010);
/// - "Your answer ③ · Right answer ①";
/// - the supporting content in the UI language, a section only when it has
///   data (BR-TOPIK-006, A2).
///
/// The right answer is the snapshot's, the one that scored.
class TopikReviewQuestionWidget extends StatelessWidget {
  const TopikReviewQuestionWidget({
    super.key,
    required this.question,
    required this.answer,
    required this.isContentUpdated,
  });

  final TopikQuestion question;
  final TopikAttemptAnswer answer;
  final bool isContentUpdated;

  int get _right => answer.correctIdx ?? question.answerIdx;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final selected = answer.selectedIdx;
    return MxScreenScroll(
      children: [
        SizedBox(height: dimens.space16),
        if (isContentUpdated) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: l10n.topikUpdatedTitle,
            message: l10n.topikUpdatedBody,
            hasBottomMargin: false,
          ),
          SizedBox(height: dimens.space16),
        ],
        Text(
          l10n.topikQuestionStem(question.no, question.stemKo),
          style: context.texts.bodyLarge,
        ),
        SizedBox(height: dimens.space16),
        for (final option in question.options) ...[
          _option(context, option),
          SizedBox(height: dimens.space8),
        ],
        Text(
          l10n.topikTerms([
            if (selected == null)
              l10n.topikNotAnswered
            else
              l10n.topikYourAnswer(topikCircled(selected)),
            l10n.topikRightAnswer(topikCircled(_right)),
          ]),
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        ..._support(context),
      ],
    );
  }

  Widget _option(BuildContext context, TopikOption option) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final isRight = option.idx == _right;
    final isWrongChoice = !isRight && option.idx == answer.selectedIdx;
    final text = option.textKo ?? l10n.topikPicture;
    return MxChoiceTile(
      tone: isRight
          ? MxChoiceTone.right
          : (isWrongChoice ? MxChoiceTone.wrong : MxChoiceTone.idle),
      isSelected: option.idx == answer.selectedIdx,
      semanticsLabel: isRight || isWrongChoice
          ? l10n.topikOptionReviewLabel(
              option.idx,
              text,
              isRight ? l10n.topikRightState : l10n.topikYourWrongState,
            )
          : l10n.topikOptionLabel(option.idx, text),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space16,
        vertical: dimens.space12,
      ),
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

  /// Explanation, Translation, Words, Grammar: each only with data.
  List<Widget> _support(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    Widget line(String text) => Padding(
      padding: EdgeInsets.all(dimens.space16),
      child: Text(text, style: context.texts.bodyMedium),
    );
    final sections = [
      if (question.explanation case final text?)
        MxSection(
          title: l10n.topikTagExplanation,
          children: [line(l10n.topikText(text))],
        ),
      if (question.translation case final text?)
        MxSection(
          title: l10n.topikTagTranslation,
          children: [line(l10n.topikText(text))],
        ),
      if (question.words.isNotEmpty)
        MxSection(
          title: l10n.topikTagWords,
          children: [
            for (final word in question.words)
              line(
                l10n.topikTerms([
                  word.ko,
                  ?word.pos,
                  l10n.topikText(word.meaning),
                ]),
              ),
          ],
        ),
      if (question.grammars.isNotEmpty)
        MxSection(
          title: l10n.topikTagGrammar,
          children: [
            for (final grammar in question.grammars)
              line(
                l10n.topikTerms([
                  grammar.pattern,
                  l10n.topikText(grammar.meaning),
                ]),
              ),
          ],
        ),
    ];
    return [
      for (final section in sections) ...[
        SizedBox(height: dimens.space24),
        section,
      ],
    ];
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_audio_model_test.dart test/features/topik/presentation/topik_review_question_test.dart test/features/topik/presentation/topik_attempt_screen_states_test.dart`
Expected: PASS (the attempt screen keeps its audio tests green after `_clipOf` goes).

- [ ] **Step 4: Commit**

```bash
git add lib/features/topik test/features/topik
git commit -m "feat(topik): DEV-394 screen 39's question; the group's clip in the domain"
```

---
### Task 5: Screen 39 and its route

**Files:**
- Create: `lib/features/topik/presentation/screens/topik_review_screen.dart`
- Modify: `lib/app/router/topik_routes.dart`
- Test:
  - `test/features/topik/presentation/topik_review_screen_test.dart`
  - `test/app/topik_routes_test.dart` (one test added)

**Interfaces:**
- Consumes:
  - `topikReviewProvider` (Task 1).
  - `TopikAnswerFilterChipsWidget` (Task 2).
  - `TopikReviewQuestionWidget`, `topikGroupClip` (Task 4).
  - `TopikTwoPaneWidget`, `TopikGroupPaneWidget` (plan 6b).
  - `topikAttemptSummaryOf` (plan 4).
- Produces: `TopikReviewScreen({required String attemptId, int? initialQuestionNo, required VoidCallback onBack, required VoidCallback onBackToSummary})`.

- [ ] **Step 1: Write the failing screen tests**

`test/features/topik/presentation/topik_review_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_review_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

final class _Exits {
  var backs = 0;
  var summaries = 0;
}

// Screen 39 (UC-TOPIK-005; BR-TOPIK-006, -010, -017, -019): each test is a
// row of detail file 39's Transitions table.
void main() {
  final reading = topikTestFixture();

  /// 1 wrong, 2 right, 3 wrong, the rest blank.
  Map<int, int> mixed(TopikTest test) {
    final q = test.questions;
    return {
      q[0].no: q[0].answerIdx % 4 + 1,
      q[1].no: q[1].answerIdx,
      q[2].no: q[2].answerIdx % 4 + 1,
    };
  }

  Future<_Exits> pump(
    WidgetTester tester,
    LibraryEnv env,
    String attemptId, {
    int? questionNo,
    List<TopikTest>? catalog,
    List<Override> overrides = const [],
  }) async {
    final exits = _Exits();
    await pumpLibraryScreen(
      tester,
      env,
      TopikReviewScreen(
        attemptId: attemptId,
        initialQuestionNo: questionNo,
        onBack: () => exits.backs++,
        onBackToSummary: () => exits.summaries++,
      ),
      overrides: [
        ...topikContentOverrides(catalog ?? [reading]),
        topikAudioRepositoryProvider.overrideWithValue(
          FakeTopikAudioRepository(),
        ),
        ...overrides,
      ],
    );
    await tester.pumpAndSettle();
    return exits;
  }

  List<MxChoiceTone> tones(WidgetTester tester) => [
    for (final tile in tester.widgetList<MxChoiceTile>(
      find.byType(MxChoiceTile),
    ))
      tile.tone,
  ];

  libraryTest('opens the question asked, with its real number; an unknown '
      'number opens the first (UC-TOPIK-005, A3)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    await pump(tester, env, done.id, questionNo: 2);
    expect(find.text('Review · 2 / 50'), findsOneWidget);
    expect(tones(tester)[1], MxChoiceTone.right);

    await pump(tester, env, done.id, questionNo: 99);
    expect(find.text('Review · 1 / 50'), findsOneWidget);
  });

  libraryTest('Next and Previous walk the filter; a filter opens its first '
      'question; the last says Done (UC-TOPIK-005 step 4)', (
    tester,
    env,
  ) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    final exits = await pump(tester, env, done.id);

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 1 / 50'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 3 / 50'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Review · 1 / 50'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    expect(exits.backs, 1);
  });

  libraryTest('a filter with no question cannot be picked', (
    tester,
    env,
  ) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: {for (final q in reading.questions) q.no: q.answerIdx},
    );
    await pump(tester, env, done.id);

    final wrong = tester.widget<MxFilterChip>(
      find.widgetWithText(MxFilterChip, 'Wrong'),
    );
    expect(wrong.onSelected, isNull);
  });

  libraryTest('an option tapped changes nothing and writes nothing '
      '(BR-TOPIK-010)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    await pump(tester, env, done.id);

    await tester.tap(find.text('④ 보기 4'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tones(tester)[3], MxChoiceTone.idle);
    final stored = await topikStoredAttempt(tester, env, done.id);
    expect(stored.answers.first.selectedIdx, reading.questions.first.answerIdx % 4 + 1);
  });

  libraryTest('content updated after the attempt: the banner '
      '(BR-TOPIK-019)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading, answers: mixed(reading));
    final updated = topikTestJson()..['contentVersion'] = 2;
    await pump(
      tester,
      env,
      done.id,
      catalog: [topikTestOfFixtureJson(updated)],
    );

    expect(find.text('This test was updated after this attempt'), findsOneWidget);
  });

  libraryTest('the test gone: Review is unavailable, Back to summary '
      '(BR-TOPIK-019)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading);
    final exits = await pump(tester, env, done.id, catalog: const []);

    expect(find.text("Review isn't available for this test"), findsOneWidget);
    expect(find.text('Your score is still in the summary.'), findsOneWidget);
    await tester.tap(find.text('Back to summary'));
    expect(exits.summaries, 1);
  });

  libraryTest('the attempt deleted elsewhere, or still in progress: missing '
      '(UC-TOPIK-005 E2)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading);
    final exits = await pump(tester, env, done.id);
    await TopikAttemptRepositoryImpl(env.db).delete(done.id);
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
    await tester.tap(find.text('Back to the test'));
    expect(exits.backs, 1);

    final open = await topikSeedAttempt(env, reading);
    await pump(tester, env, open.id);
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });

  libraryTest('TOPIK I reading: ?q=31 opens question 31 (BR-TOPIK-001)', (
    tester,
    env,
  ) async {
    final t1 = topikTestFixture(level: TopikLevel.topik1);
    final done = await topikSeedSubmitted(env, t1);
    await pump(tester, env, done.id, questionNo: 31, catalog: [t1]);

    expect(find.text('Review · 31 / 70'), findsOneWidget);
  });

  libraryTest('listening: the audio bar and the script, open '
      '(BR-TOPIK-017)', (tester, env) async {
    final listening = topikTestFixture(section: TopikSection.listening);
    final done = await topikSeedSubmitted(env, listening);
    await pump(tester, env, done.id, catalog: [listening]);

    expect(find.byType(TopikAudioBarWidget), findsOneWidget);
    expect(find.text(listening.groups.first.script!), findsOneWidget);
  });

  libraryTest('a read that fails: Retry reads again', (tester, env) async {
    var reads = 0;
    final done = await topikSeedSubmitted(env, reading);
    await pump(
      tester,
      env,
      done.id,
      overrides: [
        topikReviewProvider(done.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikReviewView?>.error(StateError('read'));
          }
          return Stream.value(null);
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_review_screen_test.dart`
Expected: FAIL to compile (`topik_review_screen.dart` is missing).

- [ ] **Step 2: The screen**

`lib/features/topik/presentation/screens/topik_review_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_review_provider.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_review_question_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 39 (UC-TOPIK-005): each question of a submitted attempt with its
/// right answer and supporting content, read-only (BR-TOPIK-010).
///
/// - Filtered as on 38; Previous and Next walk the filter.
/// - The group's material and audio as on 37, with the script open.
/// - The content's own version decides the banner, and its absence
///   contentMissing (BR-TOPIK-019).
class TopikReviewScreen extends ConsumerStatefulWidget {
  const TopikReviewScreen({
    super.key,
    required this.attemptId,
    this.initialQuestionNo,
    required this.onBack,
    required this.onBackToSummary,
  });

  final String attemptId;

  /// The question to open (`?q=`); null or unknown opens the first.
  final int? initialQuestionNo;

  /// Leaves: Back, Done, and the way out of attemptMissing.
  final VoidCallback onBack;

  /// The test is gone: the summary still works.
  final VoidCallback onBackToSummary;

  @override
  ConsumerState<TopikReviewScreen> createState() => _TopikReviewScreenState();
}

class _TopikReviewScreenState extends ConsumerState<TopikReviewScreen> {
  var _filter = TopikAnswerFilter.all;

  /// The question shown; null until the person moves (then the initial one).
  int? _no;

  var _isCollapsed = false;

  /// The person's own hide or show of a group's script; open by default.
  final _scriptChoice = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = topikReviewProvider(widget.attemptId);
    return switch (ref.watch(provider)) {
      AsyncError(:final error, :final isLoading) => _plain(
        MxErrorState(
          title: l10n.topikReviewErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
          isRetrying: isLoading,
        ),
      ),
      // Gone, the account changed, or not submitted: nothing to review.
      AsyncData(value: null) => _missing(),
      AsyncValue(:final value?) when !value.detail.attempt.isCompleted =>
        _missing(),
      AsyncValue(:final value?) when value.isUnavailable => _plain(
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.topikReviewUnavailableTitle,
          body: l10n.topikReviewUnavailableBody,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToSummary,
          onAction: widget.onBackToSummary,
        ),
      ),
      AsyncValue(:final value?) => _loaded(value),
      _ => _plain(
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingReview),
        ),
      ),
    };
  }

  Widget _missing() {
    final l10n = context.l10n;
    return _plain(
      MxEmptyState(
        icon: AppIcons.searchOff,
        title: l10n.topikAttemptMissing,
        tone: MxEmptyStateTone.neutral,
        actionLabel: l10n.topikBackToTest,
        onAction: widget.onBack,
      ),
    );
  }

  MxAppBar _appBar(String title) => MxAppBar(
    title: title,
    leading: MxIconButton(
      icon: AppIcons.back,
      semanticLabel: context.l10n.commonBack,
      onPressed: widget.onBack,
    ),
  );

  /// A state with nothing to review: the bar and [body], no footer.
  Widget _plain(Widget body) => MxAppShell(
    appBar: _appBar(context.l10n.topikReview),
    body: MxScreenScroll(children: [body]),
  );

  Widget _loaded(TopikReviewView view) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final test = view.test!;
    final summary = topikAttemptSummaryOf(view.detail);
    final numbers = [
      for (final answer in summary.answersFor(_filter)) answer.questionNo,
    ];
    final wanted = _no ?? widget.initialQuestionNo;
    final current = numbers.contains(wanted) ? wanted! : numbers.first;
    final index = numbers.indexOf(current);
    final question = test.questions.firstWhere((q) => q.no == current);
    final answer = summary.answers.firstWhere((a) => a.questionNo == current);
    final group = test.groups.firstWhere((g) => g.groupId == question.groupId);
    final isScriptShown = _scriptChoice[group.groupId] ?? true;
    final isLast = index == numbers.length - 1;
    return MxAppShell(
      appBar: _appBar(l10n.topikReviewTitle(current, test.questions.last.no)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenMargin,
              vertical: dimens.space8,
            ),
            child: TopikAnswerFilterChipsWidget(
              summary: summary,
              selected: _filter,
              isEmptyDisabled: true,
              onSelected: (filter) => setState(() {
                _filter = filter;
                _no = summary.answersFor(filter).first.questionNo;
              }),
            ),
          ),
          Expanded(
            child: TopikTwoPaneWidget(
              top: TopikGroupPaneWidget(
                key: ValueKey(group.groupId),
                group: group,
                audio: topikGroupClip(test, group),
                isCollapsed: _isCollapsed,
                isScriptShown: isScriptShown,
                onToggleCollapsed: () =>
                    setState(() => _isCollapsed = !_isCollapsed),
                onToggleScript: () => setState(
                  () => _scriptChoice[group.groupId] = !isScriptShown,
                ),
              ),
              bottom: TopikReviewQuestionWidget(
                key: ValueKey(current),
                question: question,
                answer: answer,
                isContentUpdated: view.isContentChanged,
              ),
            ),
          ),
        ],
      ),
      footer: MxFooterBar(
        child: MxActionPair(
          leading: MxButton(
            label: l10n.topikPrevious,
            tone: MxButtonTone.outline,
            isBlock: true,
            isSingleLine: true,
            onPressed: index == 0
                ? null
                : () => setState(() => _no = numbers[index - 1]),
          ),
          trailing: MxButton(
            label: isLast ? l10n.topikDone : l10n.topikNext,
            isBlock: true,
            isSingleLine: true,
            onPressed: isLast
                ? widget.onBack
                : () => setState(() => _no = numbers[index + 1]),
          ),
        ),
      ),
    );
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_review_screen_test.dart`
Expected: PASS.

- [ ] **Step 3: The route**

In `lib/app/router/topik_routes.dart`, add `import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';` and insert right after the summary route:

```dart
    // An attempt's Review (spec §8): `?q=` opens a question.
    GoRoute(
      path: AppRoutes.topikReviewChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) {
        final id = state.pathParameters[AppRoutes.topikAttemptIdParam]!;
        return TopikReviewScreen(
          attemptId: id,
          initialQuestionNo: int.tryParse(
            state.uri.queryParameters[AppRoutes.topikReviewQuestionParam] ??
                '',
          ),
          onBack: () => _leave(context),
          onBackToSummary: () => context.go(AppRoutes.topikSummary(id)),
        );
      },
    ),
```

Add to `test/app/topik_routes_test.dart`, importing `topik_review_screen.dart`:

```dart
  libraryTest('from the summary a row opens Review at its question; Back '
      'returns to the summary (UC-TOPIK-004 step 7)', (tester, env) async {
    final tests = topikScreenTests();
    final done = await topikSeedSubmitted(env, tests.first);
    await pumpMemoxApp(tester, env, overrides: topikContentOverrides(tests));
    await _go(tester, AppRoutes.topikSummary(done.id));
    expect(find.byType(TopikSummaryScreen), findsOneWidget);

    await _tap(tester, find.text(_en.topikQuestionTitle(33)));
    expect(find.byType(TopikReviewScreen), findsOneWidget);
    expect(find.text(_en.topikReviewTitle(33, 70)), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(TopikSummaryScreen), findsOneWidget);
  });
```

`tests.first` is TOPIK I reading round 91, which numbers 31–70.

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/topik_routes_test.dart test/features/topik/presentation/topik_review_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/app/router lib/features/topik test/features/topik test/app/topik_routes_test.dart
git commit -m "feat(topik): DEV-394 screen 39, the review, read-only and filtered"
```

---
### Task 6: Goldens, the visual audits, and the detail files as built

**Files:**
- Create:
  - `test/features/topik/presentation/topik_summary_golden_test.dart`
  - `test/features/topik/presentation/topik_review_golden_test.dart`
  - `test/visual_audit/screens/features/topik/screens/topik_summary_screen_visual_audit_test.dart`
  - `test/visual_audit/screens/features/topik/screens/topik_review_screen_visual_audit_test.dart`
- Modify:
  - `docs/shared/ui/screen-handoff/38-topik-summary.md` and `39-topik-review.md`
  - `00-index.md`
  - `docs/_generated/traceability.md` (generated)

- [ ] **Step 1: The goldens**

`test/features/topik/presentation/topik_summary_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_summary_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

/// Every third question wrong, every fifth blank, the rest right.
Map<int, int> _mixed(TopikTest test) => {
  for (final (i, q) in test.questions.indexed)
    if (i % 5 != 4) q.no: i % 3 == 2 ? q.answerIdx % 4 + 1 : q.answerIdx,
};

// Screen 38's states (detail file 38).
void main() {
  final reading = topikTestFixture();
  final t1 = topikTestFixture(level: TopikLevel.topik1);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      String attemptId, {
      List<TopikTest>? catalog,
      List<Override> overrides = const [],
      Future<void> Function()? before,
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikSummaryScreen(
          attemptId: attemptId,
          onReview: (_) {},
          onDone: () {},
        ),
        brightness,
        overrides: [
          ...topikContentOverrides(catalog ?? [reading, t1]),
          ...overrides,
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      if (before != null) {
        await before();
        await tester.pumpAndSettle();
      }
      await expectBoundaryGolden(
        tester,
        'goldens/topik_summary_${state}_$theme.png',
      );
    });

    libraryTest('loaded, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: _mixed(reading),
      );
      await shoot(tester, env, 'loaded', done.id);
    });

    libraryTest('perfect, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: {for (final q in reading.questions) q.no: q.answerIdx},
      );
      await shoot(tester, env, 'perfect', done.id);
    });

    libraryTest('zero, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(env, reading);
      await shoot(tester, env, 'zero', done.id);
    });

    libraryTest('topik1Reading, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(env, t1, answers: _mixed(t1));
      await shoot(tester, env, 't1_reading', done.id);
    });

    libraryTest('correctHidden, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: _mixed(reading),
      );
      await shoot(
        tester,
        env,
        'hidden',
        done.id,
        before: () async {
          await tester.tap(find.byTooltip('Hide answers'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Question 1'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
        },
      );
    });

    libraryTest('filterEmpty, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: {for (final q in reading.questions) q.no: q.answerIdx},
      );
      await shoot(
        tester,
        env,
        'filter_empty',
        done.id,
        before: () => tester.tap(find.text('Wrong')),
      );
    });

    libraryTest('attemptMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', 'gone');
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikSummaryView?>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        'a1',
        overrides: [
          topikSummaryProvider('a1').overrideWith((ref) => pending.stream),
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
          topikSummaryProvider('a1').overrideWith(
            (ref) => Stream<TopikSummaryView?>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
```

`test/features/topik/presentation/topik_review_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_review_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

/// Reading 96 with question 1's full supporting content and a real passage.
TopikTest _reading({int contentVersion = 1}) {
  final json = topikTestJson()..['contentVersion'] = contentVersion;
  groupJson(json, 'g1')['passage'] = {
    'textKo':
        '우리 회사는 다음 달부터 재택근무 제도를 시범적으로 운영합니다. '
        '희망하는 직원은 이번 주 금요일까지 팀장에게 신청서를 제출하면 됩니다.',
  };
  questionJson(json, 1)
    ..['stemKo'] = '이 글의 내용과 같은 것을 고르십시오.'
    ..['explanation'] = {
      'vi': 'Đoạn văn nói nhân viên nộp đơn trước thứ Sáu.',
      'en': 'The notice says staff apply by Friday.',
    }
    ..['translation'] = {
      'vi': 'Công ty chúng tôi thử nghiệm làm việc tại nhà từ tháng sau.',
      'en': 'Our company trials working from home from next month.',
    };
  return topikTestOfFixtureJson(json);
}

// Screen 39's states (detail file 39).
void main() {
  final reading = _reading();
  final listening = topikTestFixture(section: TopikSection.listening);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      String attemptId, {
      int? questionNo,
      List<TopikTest>? catalog,
      List<Override> overrides = const [],
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikReviewScreen(
          attemptId: attemptId,
          initialQuestionNo: questionNo,
          onBack: () {},
          onBackToSummary: () {},
        ),
        brightness,
        overrides: [
          ...topikContentOverrides(catalog ?? [reading, listening]),
          topikAudioRepositoryProvider.overrideWithValue(
            FakeTopikAudioRepository(),
          ),
          ...overrides,
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      await expectBoundaryGolden(
        tester,
        'goldens/topik_review_${state}_$theme.png',
      );
    });

    Future<String> submitted(LibraryEnv env, TopikTest test) async =>
        (await topikSeedSubmitted(
          env,
          test,
          answers: {
            test.questions[0].no: test.questions[0].answerIdx % 4 + 1,
            test.questions[1].no: test.questions[1].answerIdx,
          },
        )).id;

    libraryTest('wrong, $theme', (tester, env) async {
      await shoot(tester, env, 'wrong', await submitted(env, reading));
    });

    libraryTest('correct, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'correct',
        await submitted(env, reading),
        questionNo: 2,
      );
    });

    libraryTest('unanswered, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'unanswered',
        await submitted(env, reading),
        questionNo: 3,
      );
    });

    libraryTest('listening, $theme', (tester, env) async {
      await shoot(tester, env, 'listening', await submitted(env, listening));
    });

    libraryTest('contentUpdated, $theme', (tester, env) async {
      final id = await submitted(env, reading);
      await shoot(
        tester,
        env,
        'updated',
        id,
        questionNo: 2,
        catalog: [_reading(contentVersion: 2)],
      );
    });

    libraryTest('contentMissing, $theme', (tester, env) async {
      final id = await submitted(env, reading);
      await shoot(tester, env, 'content_missing', id, catalog: const []);
    });

    libraryTest('attemptMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', 'gone');
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikReviewView?>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        'a1',
        overrides: [
          topikReviewProvider('a1').overrideWith((ref) => pending.stream),
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
          topikReviewProvider('a1').overrideWith(
            (ref) => Stream<TopikReviewView?>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then look at every new `topik_summary_*` and `topik_review_*` light golden and a few dark ones.
Expected:
- 36 new PNGs and no other golden changed.
- Every state reads as its States row, with no line breaking inside a term and no overflow stripe.
- 100 / 100 holds its line beside the donut.

Fix what the pictures show in one batch before going on.

- [ ] **Step 2: The visual audits**

`test/visual_audit/screens/features/topik/screens/topik_summary_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_attempt_screen_fixtures.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 38, ${locale.languageCode}', (tester, env) async {
      // A mixed result: every status, the weakest type.
      final test = topikTestFixture();
      final done = await topikSeedSubmitted(
        env,
        test,
        answers: {
          for (final (i, q) in test.questions.indexed)
            if (i.isEven) q.no: i % 4 == 0 ? q.answerIdx : q.answerIdx % 4 + 1,
        },
      );
      await auditProductionScreen(
        tester,
        screen: TopikSummaryScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikSummaryScreen(
            attemptId: done.id,
            onReview: (_) {},
            onDone: () {},
          ),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: topikContentOverrides([test]),
        ),
      );
    });
  }
}
```

`test/visual_audit/screens/features/topik/screens/topik_review_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_attempt_screen_fixtures.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_fakes.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 39, ${locale.languageCode}', (tester, env) async {
      // Listening at its fullest: audio, the open script, a wrong answer
      // with its explanation and word.
      final test = topikTestFixture(section: TopikSection.listening);
      final first = test.questions.first;
      final done = await topikSeedSubmitted(
        env,
        test,
        answers: {first.no: first.answerIdx % 4 + 1},
      );
      await auditProductionScreen(
        tester,
        screen: TopikReviewScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikReviewScreen(
            attemptId: done.id,
            onBack: () {},
            onBackToSummary: () {},
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

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/visual_audit/screens/features/topik/screens/`
Expected: PASS.

- [ ] **Step 3: The detail files as built**

Rewrite `docs/shared/ui/screen-handoff/38-topik-summary.md` and `39-topik-review.md` to what was built. For each file:
- **Layout:** apply critique S1–S11 and V1–V10.
- **States:** add `error` to both, and `loading` to 39.
- **"Built" paragraph:** replace "Not built yet" with "Built (plan 6c, 2026-10-15)".
- **Transitions:**
  - Give every row the executed test that verifies it (Tasks 3, 5 and the routes test), or UNVERIFIED with its reason. The account switch is UNVERIFIED, as on 36 and 37.
  - Add a row for every transition the code has: a chart bar → 39; an attempt in progress → attemptMissing; error → Retry; Back to summary.
- **Rulings:** add the S and V findings, one line each, marked "(plan 6c)".
- **Copy:** write the copy as built.

In `00-index.md`, set rows 38 and 39 to `built`, with their state counts.

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS`.

- [ ] **Step 4: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/claude-0/dod6c.log 2>&1; echo $?`, then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`.
Expected: `0`, and every golden passes.

- [ ] **Step 5: Commit**

```bash
git add test/features/topik test/visual_audit docs/shared/ui/screen-handoff docs/_generated
git commit -m "test(topik): DEV-394 screens 38 and 39's goldens and audits; detail files as built"
```
