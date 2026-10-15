# TOPIK screens 13 (entry), 34, 35 and 36 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A person reaches TOPIK practice from Study home, picks an exam level, sees its tests with their status, and on a test sees Overall Progress, Recent attempts and History, deletes an attempt, and starts or continues one (UC-TOPIK-001, UC-TOPIK-002; spec §6.1–§6.3, §8). Plan 6a of Phase 2 (§13.9 item 6 split in three), epic DEV-394.

**Architecture:** `presentation/` of `lib/features/topik/` on the use cases of plan 4: use-case providers and stream providers in `providers/`, one controller for the detail screen's commands, screens taking callbacks only, overlays as `show…` functions. `lib/app/router/topik_routes.dart` composes the routes (Study branch, tab bar stays) and the Study home entry, which reaches `StudyHomeScreen` through a new optional slot so `study` never imports `topik` (ADR-023).

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, go_router 18, `intl` `DateFormat`, the `Mx*` shared widgets, golden harness (`test/support/library_harness.dart`).

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` §6.1–§6.3, §8; detail files `docs/shared/ui/screen-handoff/{13-study-home,34-topik-home,35-topik-test-list,36-topik-test-detail}.md`; rules BR-TOPIK-008, -009, -011, -018, -020, -021, -022; the pre-plan critique `plan6a-critique.md` (findings F1–F8, adopted below).

## Global Constraints

- `study` never imports `topik`: the entry row is a slot `practiceEntry` composed in `lib/app/` (ADR-023).
- Every presentation file ends `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider` (guard `memox.naming.presentation_file_role_suffix`); no `ref.read` in `build`; no `BuildContext`/`WidgetRef` in providers or controllers; a `mounted` check before any state write after an await.
- Copy is localized: every new key in `app_en.arb` (with `"@key": {…, "description": …}`, `description` last) and `app_vi.arb` (no `@` entries); `flutter gen-l10n`.
- Failure copy is local-first ("Nothing was lost"); a database `Failure` shows `l10n.failure(failure)`, never its cause.
- One primary per decision (The One Accent Rule): history actions are outline, the badge neutral; in `overviewEmpty` the FAB is absent (critique F2).
- The Content Gate Rule: the sort chip and the FAB exist only with content; the section tray and Back stay (critique F4).
- Times come from `dayClockProvider`; tests never read the wall clock.
- Goldens: English, light and dark, 1080×2400 at 3x, through `pumpLibraryGolden` + `expectBoundaryGolden`, run only by `run_goldens.sh`; every changed or new golden goes on the `golden-compare` page.
- No production TOPIK content ships yet (`assets/topik/` holds the manifest only), so the attempt, summary and review routes (plans 6b, 6c) are pushed by path and land on `RouteNotFoundScreen` until they exist; no one can reach them before then.
- Commits name DEV-394 and end with the session's attribution lines.

## Review Focus

1. **Start with an attempt in progress** (BR-TOPIK-011): the FAB asks Continue or Start new; Start new asks once more, then deletes the old attempt and opens the new one in one write; a scrim tap changes nothing (Task 5).
2. **Delete while the list streams** (BR-TOPIK-018, -021): the row leaves, the numbers and Overall Progress recompute; a failing delete leaves the row and says nothing was lost (Task 5).
3. **A second tap on the FAB while starting** opens one attempt only (Task 5).
4. **A level with no valid test** (BR-TOPIK-008): its row says "No tests yet", has no chevron and is not a button; nothing is an error (Task 2).
5. **A deep link to an unknown level or test** lands on the not-found screen (level) or `testMissing` with "Back to tests" (test) (Tasks 5, 6).

---

### Task 1: Labels and providers

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create: `lib/features/topik/presentation/widgets/support/topik_labels_widget.dart`
- Create: `lib/features/topik/presentation/providers/watch_topik_catalog_use_case_provider.dart`, `topik_catalog_provider.dart`, `watch_topik_test_detail_use_case_provider.dart`, `topik_test_detail_provider.dart`, `start_topik_attempt_use_case_provider.dart`, `delete_topik_attempt_use_case_provider.dart`, `topik_test_list_choice_provider.dart`
- Test: `test/features/topik/presentation/topik_labels_test.dart`, `test/features/topik/presentation/topik_providers_test.dart`

**Interfaces:**
- Produces: `extension TopikLabels on AppLocalizations` with `topikLevelName(TopikLevel)`, `topikLevelScope(TopikLevel)`, `topikSectionName(TopikSection)`, `topikTagName(TopikContentTag)`, `topikOrderName(TopikTestOrder)`, `topikTestStatusLine(TopikTestStatus?)`, `topikRejectionMessage(TopikRejection)`, `topikDateTime(DateTime)`; providers `watchTopikCatalogUseCaseProvider`, `topikCatalogProvider` (`Stream<List<TopikCatalogEntry>>`), `watchTopikTestDetailUseCaseProvider`, `topikTestDetailProvider(String testId)` (`Stream<TopikTestDetail>`), `startTopikAttemptUseCaseProvider`, `deleteTopikAttemptUseCaseProvider`, `topikTestListChoiceProvider(TopikLevel)` (`TopikTestListChoice` with `section`, `order`; methods `pickSection`, `pickOrder`).

- [ ] **Step 1: Add the copy**

Run this once from the repo root (it inserts after `"commonUndo"`'s entry in en and its line in vi, keeping `description` last):

```bash
python3 - <<'EOF'
import json, pathlib, re
KEYS = [
 # key, en, vi, description, placeholders
 ("topikTitle", "TOPIK", "TOPIK", "Screen handoff 34 (DEV-394): app bar title.", None),
 ("topikSubtitle", "한국어능력시험", "한국어능력시험", "Screen handoff 34: the exam's Korean name, under the title.", None),
 ("topikPractice", "Practice", "Luyện đề", "Screens 13 and 34: the section that holds the TOPIK entry and the levels.", None),
 ("topikEntryTitle", "TOPIK past papers", "Đề TOPIK các kỳ", "Screen 13: the row that opens TOPIK.", None),
 ("topikLevel1", "TOPIK I", "TOPIK I", "TOPIK level name.", None),
 ("topikLevel2", "TOPIK II", "TOPIK II", "TOPIK level name.", None),
 ("topikLevel1Scope", "Levels 1–2 · Reading, Listening", "Cấp 1–2 · Đọc, Nghe", "Screen 34: what TOPIK I covers.", None),
 ("topikLevel2Scope", "Levels 3–6 · Reading, Listening", "Cấp 3–6 · Đọc, Nghe", "Screen 34: what TOPIK II covers.", None),
 ("topikTestCount", "{count, plural, =1{1 test} other{{count} tests}}", "{count} đề", "How many tests.", {"count": {"type": "int"}}),
 ("topikNoTestsYet", "No tests yet", "Chưa có đề", "Screen 34: a level without a valid test (BR-TOPIK-008).", None),
 ("topikErrorTitle", "Couldn't load the tests", "Không tải được danh sách đề", "Screens 34, 35: load error title.", None),
 ("topikErrorBody", "Nothing was lost. Try again.", "Không mất gì cả. Thử lại nhé.", "Screens 34–36: load error body; says first that nothing was lost.", None),
 ("topikLoadingTests", "Loading tests", "Đang tải đề", "Screens 34, 35: what the skeleton is.", None),
 ("topikReading", "Reading", "Đọc", "TOPIK section name.", None),
 ("topikListening", "Listening", "Nghe", "TOPIK section name.", None),
 ("topikTestsHeaderBody", "Past papers published by NIIED.", "Đề thi các kỳ do NIIED công bố.", "Screen 35: what the list is.", None),
 ("topikOrderNewest", "Newest round", "Kỳ mới nhất", "Screen 35 sort.", None),
 ("topikOrderOldest", "Oldest round", "Kỳ cũ nhất", "Screen 35 sort.", None),
 ("topikOrderRecent", "Recent activity", "Làm gần đây", "Screen 35 sort.", None),
 ("topikSortTitle", "Sort tests", "Sắp xếp đề", "Screen 35: the sort sheet's title.", None),
 ("topikTagExplanation", "Explanation", "Giải thích", "Screen 35: a test carries explanations (BR-TOPIK-009).", None),
 ("topikTagTranslation", "Translation", "Bản dịch", "Screen 35: a test carries translations.", None),
 ("topikTagWords", "Words", "Từ vựng", "Screen 35: a test carries words.", None),
 ("topikTagGrammar", "Grammar", "Ngữ pháp", "Screen 35: a test carries grammar.", None),
 ("topikTagScript", "Script", "Lời thoại", "Screen 35: a listening test carries its script.", None),
 ("topikRoundNumber", "#{round}", "#{round}", "Screen 35: a test's round badge.", {"round": {"type": "int"}}),
 ("topikStatusNotStarted", "Not started", "Chưa làm", "Screen 35: a test never attempted.", None),
 ("topikStatusInProgress", "In progress", "Đang làm", "Screens 35, 36: an attempt in progress.", None),
 ("topikStatusBest", "Best {score}", "Cao nhất {score}", "Screen 35: the best score of a test.", {"score": {"type": "int"}}),
 ("topikAttemptCount", "{count, plural, =1{1 attempt} other{{count} attempts}}", "{count} lượt", "Screen 35: how many completed attempts.", {"count": {"type": "int"}}),
 ("topikSectionEmpty", "No tests yet for this section", "Phần này chưa có đề", "Screen 35: no valid test in the section (UC-TOPIK-001 A1).", None),
 ("topikTestSubtitle", "{level} · {section}", "{level} · {section}", "Screen 36: under the test's title.", {"level": {"type": "String"}, "section": {"type": "String"}}),
 ("topikOverview", "Overview", "Tổng quan", "Screen 36 tray.", None),
 ("topikHistory", "History", "Lịch sử", "Screen 36 tray.", None),
 ("topikOverallProgress", "Overall progress", "Tiến độ chung", "Screen 36: the progress card's header.", None),
 ("topikAccuracy", "Accuracy", "Độ chính xác", "Screen 36 figure.", None),
 ("topikBest", "Best", "Cao nhất", "Screen 36 figure.", None),
 ("topikAverage", "Average", "Trung bình", "Screen 36 figure.", None),
 ("topikCompleted", "Completed", "Đã nộp", "Screen 36 figure and badge.", None),
 ("topikPercent", "{value}%", "{value}%", "A whole percent.", {"value": {"type": "int"}}),
 ("topikOfTotal", "{part} / {total}", "{part} / {total}", "Screen 36: a part of a whole, as 3 / 5.", {"part": {"type": "int"}, "total": {"type": "int"}}),
 ("topikLastActivity", "Last activity {ago} · {duration}", "Lần gần nhất {ago} · {duration}", "Screen 36: when and how long in all.", {"ago": {"type": "String"}, "duration": {"type": "String"}}),
 ("topikScoresNote", "Scores use completed tests only", "Điểm chỉ tính các lượt đã nộp", "Screen 36 footnote (BR-TOPIK-020).", None),
 ("topikNoAttemptsTitle", "No attempts yet", "Chưa có lượt nào", "Screen 36 empty state.", None),
 ("topikNoAttemptsBody", "Each attempt is saved as you answer.", "Mỗi lượt được lưu ngay khi bạn trả lời.", "Screen 36 empty state.", None),
 ("topikStart", "Start", "Bắt đầu", "Screen 36: start an attempt.", None),
 ("topikRecentAttempts", "Recent attempts", "Các lượt gần đây", "Screen 36 header.", None),
 ("topikAttemptNumber", "#{number}", "#{number}", "Screen 36: an attempt's number.", {"number": {"type": "int"}}),
 ("topikSummary", "Summary", "Tổng kết", "Screen 36 action.", None),
 ("topikReview", "Review", "Xem lại", "Screen 36 action.", None),
 ("topikContinue", "Continue", "Làm tiếp", "Screen 36 action.", None),
 ("topikDeleteAttempt", "Delete attempt", "Xoá lượt làm", "Screen 36: the delete button's label.", None),
 ("topikDeleteTitle", "Delete this attempt?", "Xoá lượt làm này?", "Screen 36 delete confirm.", None),
 ("topikDeleteBody", "Its answers are deleted too. This can't be undone.", "Các câu trả lời cũng bị xoá. Không thể hoàn tác.", "Screen 36 delete confirm.", None),
 ("topikDelete", "Delete", "Xoá", "Screen 36 delete confirm.", None),
 ("topikContinueTitle", "You have an attempt in progress", "Bạn đang có một lượt dở", "Screen 36 dialog (BR-TOPIK-011).", None),
 ("topikContinueBody", "Continue where you left off, or start again.", "Làm tiếp từ chỗ đã dừng, hoặc bắt đầu lại.", "Screen 36 dialog.", None),
 ("topikStartNew", "Start new", "Làm lượt mới", "Screen 36 dialog.", None),
 ("topikStartNewTitle", "Start a new attempt?", "Bắt đầu lượt mới?", "Screen 36 second confirm.", None),
 ("topikStartNewBody", "The attempt in progress and its answers are deleted.", "Lượt đang dở và các câu trả lời của nó sẽ bị xoá.", "Screen 36 second confirm.", None),
 ("topikTestMissingTitle", "This test isn't available", "Đề này không còn", "Screen 36: unknown or invalid test (UC-TOPIK-002 E1).", None),
 ("topikBackToTests", "Back to tests", "Về danh sách đề", "Screen 36 missing state action.", None),
 ("topikDetailErrorTitle", "Couldn't load this test", "Không tải được đề này", "Screen 36 load error title.", None),
 ("topikLoadingTest", "Loading the test", "Đang tải đề", "Screen 36: what the skeleton is.", None),
 ("topikAttemptMissing", "This attempt isn't here any more", "Lượt làm này không còn nữa", "A refused command on a deleted attempt.", None),
 ("topikRefused", "That didn't go through. Nothing was lost.", "Chưa thực hiện được. Không mất gì cả.", "A refused command with no more specific message.", None),
]
en = pathlib.Path('lib/l10n/app_en.arb'); vi = pathlib.Path('lib/l10n/app_vi.arb')
def entry_en(k, e, d, ph):
    meta = {}
    if ph: meta["placeholders"] = ph
    meta["description"] = d
    return f'  "{k}": {json.dumps(e, ensure_ascii=False)},\n  "@{k}": ' + json.dumps(meta, ensure_ascii=False, indent=2).replace('\n', '\n  ') + ',\n'
s = en.read_text()
anchor = re.search(r'  "@commonUndo": \{.*?\n  \},\n', s, re.S)
s = s[:anchor.end()] + ''.join(entry_en(k, e, d, ph) for k, e, _, d, ph in KEYS) + s[anchor.end():]
en.write_text(s)
v = vi.read_text()
anchor = re.search(r'  "commonUndo": [^\n]*\n', v)
v = v[:anchor.end()] + ''.join(f'  "{k}": {json.dumps(x, ensure_ascii=False)},\n' for k, _, x, _, _ in KEYS) + v[anchor.end():]
vi.write_text(v)
EOF
flutter gen-l10n
```

Expected: `flutter gen-l10n` prints nothing and exits 0.

- [ ] **Step 2: Write the failing tests**

`test/features/topik/presentation/topik_labels_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

TopikTestStatus _status({
  bool hasInProgress = false,
  int completedCount = 0,
  int? bestScore,
}) => TopikTestStatus(
  testId: 't',
  hasInProgress: hasInProgress,
  completedCount: completedCount,
  bestScore: bestScore,
  lastActivityAt: DateTime.utc(2026, 9, 24),
);

// BR-TOPIK-022: the status line of a test, in both languages.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('a status line for every case, in-progress first', () {
    expect(en.topikTestStatusLine(null), 'Not started');
    expect(en.topikTestStatusLine(_status(hasInProgress: true)), 'In progress');
    expect(
      en.topikTestStatusLine(_status(completedCount: 1, bestScore: 82)),
      'Best 82 · 1 attempt',
    );
    expect(
      en.topikTestStatusLine(
        _status(hasInProgress: true, completedCount: 3, bestScore: 82),
      ),
      'In progress · Best 82 · 3 attempts',
    );
    expect(
      vi.topikTestStatusLine(_status(completedCount: 3, bestScore: 82)),
      'Cao nhất 82 · 3 lượt',
    );
  });

  test('level names and scopes', () {
    expect(en.topikLevelName(TopikLevel.topik1), 'TOPIK I');
    expect(en.topikLevelScope(TopikLevel.topik2), 'Levels 3–6 · Reading, Listening');
  });

  test('every rejection reads in the local-first voice', () {
    for (final reason in TopikRejection.values) {
      expect(en.topikRejectionMessage(reason), isNotEmpty);
    }
    expect(
      en.topikRejectionMessage(TopikRejection.testUnavailable),
      "This test isn't available",
    );
  });
}
```

`test/features/topik/presentation/topik_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_list_choice_provider.dart';

// Screen 35: the section and the sort live in the screen's provider and
// reset when the screen closes.
void main() {
  test('reading and newest round first, per level, reset on close', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = topikTestListChoiceProvider(TopikLevel.topik1);
    final subscription = container.listen(provider, (_, _) {});

    expect(subscription.read().section, TopikSection.reading);
    expect(subscription.read().order, TopikTestOrder.roundDescending);
    container.read(provider.notifier)
      ..pickSection(TopikSection.listening)
      ..pickOrder(TopikTestOrder.latestActivity);
    expect(subscription.read().section, TopikSection.listening);
    expect(subscription.read().order, TopikTestOrder.latestActivity);
    expect(
      container.read(topikTestListChoiceProvider(TopikLevel.topik2)).section,
      TopikSection.reading,
    );

    subscription.close();
    await pumpEventQueue();
    expect(container.read(provider).section, TopikSection.reading);
  });
}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation`
Expected: FAIL — the labels file and the choice provider do not exist.

- [ ] **Step 4: Implement the labels**

`lib/features/topik/presentation/widgets/support/topik_labels_widget.dart`:

```dart
import 'package:intl/intl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The TOPIK screens' words for domain values (spec §8).
extension TopikLabels on AppLocalizations {
  String topikLevelName(TopikLevel level) => switch (level) {
    TopikLevel.topik1 => topikLevel1,
    TopikLevel.topik2 => topikLevel2,
  };

  String topikLevelScope(TopikLevel level) => switch (level) {
    TopikLevel.topik1 => topikLevel1Scope,
    TopikLevel.topik2 => topikLevel2Scope,
  };

  String topikSectionName(TopikSection section) => switch (section) {
    TopikSection.reading => topikReading,
    TopikSection.listening => topikListening,
  };

  String topikTagName(TopikContentTag tag) => switch (tag) {
    TopikContentTag.explanation => topikTagExplanation,
    TopikContentTag.translation => topikTagTranslation,
    TopikContentTag.words => topikTagWords,
    TopikContentTag.grammars => topikTagGrammar,
    TopikContentTag.script => topikTagScript,
  };

  String topikOrderName(TopikTestOrder order) => switch (order) {
    TopikTestOrder.roundDescending => topikOrderNewest,
    TopikTestOrder.roundAscending => topikOrderOldest,
    TopikTestOrder.latestActivity => topikOrderRecent,
  };

  /// A test's status on its row (BR-TOPIK-022): in progress first, then the
  /// best score with the completed count.
  String topikTestStatusLine(TopikTestStatus? status) {
    final best = status?.bestScore;
    final parts = [
      if (status != null && status.hasInProgress) topikStatusInProgress,
      if (status != null && best != null) ...[
        topikStatusBest(best),
        topikAttemptCount(status.completedCount),
      ],
    ];
    return parts.isEmpty ? topikStatusNotStarted : parts.join(' · ');
  }

  String topikRejectionMessage(TopikRejection reason) => switch (reason) {
    TopikRejection.testUnavailable => topikTestMissingTitle,
    TopikRejection.notFound => topikAttemptMissing,
    TopikRejection.inProgressExists => topikContinueTitle,
    TopikRejection.attemptCompleted ||
    TopikRejection.unknownQuestion ||
    TopikRejection.invalidOption ||
    TopikRejection.contentMismatch => topikRefused,
  };

  /// "Oct 15, 09:30" in the UI language, local time.
  String topikDateTime(DateTime at) =>
      DateFormat.MMMd(localeName).add_Hm().format(at.toLocal());
}
```

(If `TopikRejection` has values beyond these, add each to an existing arm by meaning; the switch must stay exhaustive.)

- [ ] **Step 5: Implement the providers**

`watch_topik_catalog_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_catalog_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_catalog_use_case_provider.g.dart';

@riverpod
WatchTopikCatalogUseCase watchTopikCatalogUseCase(Ref ref) =>
    WatchTopikCatalogUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

`topik_catalog_provider.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_catalog_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_catalog_provider.g.dart';

/// Every valid test with the person's status (UC-TOPIK-001), again on each
/// attempt write. Screens 13, 34 and 35 read it.
@riverpod
Stream<List<TopikCatalogEntry>> topikCatalog(Ref ref) =>
    ref.watch(watchTopikCatalogUseCaseProvider)();
```

`watch_topik_test_detail_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_test_detail_use_case_provider.g.dart';

@riverpod
WatchTopikTestDetailUseCase watchTopikTestDetailUseCase(Ref ref) =>
    WatchTopikTestDetailUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

`topik_test_detail_provider.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_test_detail_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_test_detail_provider.g.dart';

/// One test's progress and attempts (UC-TOPIK-002), screen 36.
@riverpod
Stream<TopikTestDetail> topikTestDetail(Ref ref, String testId) =>
    ref.watch(watchTopikTestDetailUseCaseProvider)(testId);
```

`start_topik_attempt_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/start_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'start_topik_attempt_use_case_provider.g.dart';

@riverpod
StartTopikAttemptUseCase startTopikAttemptUseCase(Ref ref) =>
    StartTopikAttemptUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
```

`delete_topik_attempt_use_case_provider.dart`:

```dart
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_topik_attempt_use_case_provider.g.dart';

@riverpod
DeleteTopikAttemptUseCase deleteTopikAttemptUseCase(Ref ref) =>
    DeleteTopikAttemptUseCase(ref.watch(topikAttemptRepositoryProvider));
```

`topik_test_list_choice_provider.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_test_list_choice_provider.g.dart';

/// Screen 35's section and sort.
typedef TopikTestListChoice = ({TopikSection section, TopikTestOrder order});

/// Per level, reset when the screen closes (detail file 35, rulings).
@riverpod
class TopikTestListChoiceNotifier extends _$TopikTestListChoiceNotifier {
  @override
  TopikTestListChoice build(TopikLevel level) =>
      (section: TopikSection.reading, order: TopikTestOrder.roundDescending);

  void pickSection(TopikSection section) =>
      state = (section: section, order: state.order);

  void pickOrder(TopikTestOrder order) =>
      state = (section: state.section, order: order);
}
```

(Riverpod names a class provider after the class: `topikTestListChoiceNotifierProvider`. The test above uses `topikTestListChoiceProvider`; if the generator does not offer that name, rename the class to `TopikTestListChoice…` per the generator's rule or update the test's name, and record the ruling.)

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 6: Run and commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/features/topik/presentation test/features/topik/presentation
git commit -m "feat(topik): DEV-394 the TOPIK screens' copy and providers"
```

---

### Task 2: Screen 34, TOPIK home

**Files:**
- Create: `lib/features/topik/presentation/screens/topik_home_screen.dart`
- Create: `lib/features/topik/presentation/widgets/items/topik_level_row_widget.dart`
- Create: `lib/features/topik/presentation/widgets/sections/topik_app_bar_title_widget.dart`
- Create: `test/support/topik_screen_fixtures.dart`
- Test: `test/features/topik/presentation/topik_home_screen_test.dart`, `test/features/topik/presentation/topik_home_golden_test.dart`

**Interfaces:**
- Consumes: `topikCatalogProvider`, `TopikLabels` (Task 1).
- Produces: `TopikHomeScreen({required ValueChanged<TopikLevel> onOpenLevel})`; `TopikAppBarTitleWidget({required String title, required String subtitle})`; fixtures `topikScreenTests()`, `topikContentOverrides(List<TopikTest>)`, `topikSeedCompleted(...)`, `topikSeedInProgress(...)`.

- [ ] **Step 1: Write the fixtures and the failing tests**

`test/support/topik_screen_fixtures.dart`:

```dart
import 'package:flutter_riverpod/misc.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

import 'library_harness.dart';
import 'topik_attempt_fixtures.dart';
import 'topik_content_fixtures.dart';
import 'topik_fakes.dart';

/// The catalog the TOPIK screens are shown with: TOPIK I reading 91 and 96,
/// listening 96; TOPIK II reading 83, 91 and 96, listening 96.
List<TopikTest> topikScreenTests() => [
  for (final round in [91, 96])
    topikTestFixture(level: TopikLevel.topik1, round: round),
  topikTestFixture(
    level: TopikLevel.topik1,
    section: TopikSection.listening,
  ),
  for (final round in [83, 91, 96]) topikTestFixture(round: round),
  topikTestFixture(section: TopikSection.listening),
];

/// The bundled content replaced by [tests]; the attempt store is the
/// harness's database.
List<Override> topikContentOverrides(List<TopikTest> tests) => [
  topikContentRepositoryProvider.overrideWithValue(
    FakeTopikContentRepository(tests),
  ),
];

/// A completed attempt of [test], started at [startedAt], with the first
/// [correct] questions right and the rest unanswered, taking [elapsedMs].
Future<TopikAttempt> topikSeedCompleted(
  LibraryEnv env,
  TopikTest test, {
  required DateTime startedAt,
  int correct = 10,
  int elapsedMs = 600000,
}) async {
  final store = TopikAttemptRepositoryImpl(env.db);
  final attempt = topikOk(await store.start(test, now: startedAt));
  for (final question in test.questions.take(correct)) {
    topikOk(
      await store.answer(
        attemptId: attempt.id,
        questionNo: question.questionNo,
        selectedIdx: question.correctIdx,
        elapsedMs: 0,
        now: startedAt,
      ),
    );
  }
  return topikOk(
    await store.submit(
      attemptId: attempt.id,
      test: test,
      elapsedMs: elapsedMs,
      now: startedAt.add(Duration(milliseconds: elapsedMs)),
    ),
  );
}

/// An attempt of [test] in progress, started at [startedAt].
Future<TopikAttempt> topikSeedInProgress(
  LibraryEnv env,
  TopikTest test, {
  required DateTime startedAt,
}) async => topikOk(
  await TopikAttemptRepositoryImpl(env.db).start(test, now: startedAt),
);
```

(Check `TopikQuestion`'s field names for the number and the right option (`questionNo`, `correctIdx`) in `topik_question_model.dart`; use the real names.)

`test/features/topik/presentation/topik_home_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 34 (UC-TOPIK-001): the two exams with their test counts.
void main() {
  libraryTest('each level with its count; a tap opens it', (tester, env) async {
    final opened = <TopikLevel>[];
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: opened.add),
      overrides: topikContentOverrides(topikScreenTests()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Levels 1–2 · Reading, Listening · 3 tests'), findsOneWidget);
    expect(find.text('Levels 3–6 · Reading, Listening · 4 tests'), findsOneWidget);
    await tester.tap(find.text('TOPIK II'));
    expect(opened, [TopikLevel.topik2]);
  });

  libraryTest('a level with no valid test says so and is not a button '
      '(BR-TOPIK-008)', (tester, env) async {
    final opened = <TopikLevel>[];
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: opened.add),
      overrides: topikContentOverrides([topikTestFixture()]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Levels 1–2 · Reading, Listening · No tests yet'), findsOneWidget);
    final row = tester.widget<MxListRow>(
      find.ancestor(of: find.text('TOPIK I'), matching: find.byType(MxListRow)),
    );
    expect(row.onTap, isNull);
    expect(row.hasChevron, isFalse);
    expect(row.isEnabled, isTrue);
    await tester.tap(find.text('TOPIK I'));
    expect(opened, isEmpty);
  });

  libraryTest('a failed read says nothing was lost; Retry reads again', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: (_) {}),
      overrides: [
        topikCatalogProvider.overrideWith((ref) {
          reads++;
          return reads == 1
              ? Stream<List<TopikCatalogEntry>>.error(StateError('read'))
              : Stream.value(const []);
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text('Nothing was lost. Try again.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(MxErrorState), findsNothing);
    expect(reads, 2);
  });

  libraryTest('loading shows the skeleton, named once', (tester, env) async {
    final pending = StreamController<List<TopikCatalogEntry>>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      TopikHomeScreen(onOpenLevel: (_) {}),
      overrides: [topikCatalogProvider.overrideWith((ref) => pending.stream)],
    );
    expect(find.bySemanticsLabel('Loading tests'), findsOneWidget);
  });
}
```

(The Retry label is `commonRetry`; if its English value is not "Try again", use the value in `app_en.arb`.)

`test/features/topik/presentation/topik_home_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 34's states (detail file 34).
void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      List<Override> overrides,
    ) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikHomeScreen(onOpenLevel: (_) {}),
        brightness,
        overrides: overrides,
      );
      await tester.pump(const Duration(seconds: 1));
      await expectBoundaryGolden(tester, 'goldens/topik_home_${state}_$theme.png');
    });

    libraryTest('loaded, $theme', (tester, env) async {
      await shoot(tester, env, 'loaded', topikContentOverrides(topikScreenTests()));
    });

    libraryTest('noTests, $theme', (tester, env) async {
      await shoot(tester, env, 'no_tests', topikContentOverrides(const []));
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<List<TopikCatalogEntry>>();
      addTearDown(pending.close);
      await shoot(tester, env, 'loading', [
        topikCatalogProvider.overrideWith((ref) => pending.stream),
      ]);
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(tester, env, 'error', [
        topikCatalogProvider.overrideWith(
          (ref) => Stream<List<TopikCatalogEntry>>.error(StateError('read')),
        ),
      ]);
    });
  }
}
```

(Match `withRealShadows`, `expectBoundaryGolden` and `pumpLibraryGolden` to `test/features/progress/presentation/progress_golden_test.dart` if their signatures differ.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_home_screen_test.dart`
Expected: FAIL — `topik_home_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/presentation/widgets/sections/topik_app_bar_title_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// An app bar title with a subtitle line (detail files 34, 36): `MxAppBar`
/// has no subtitle yet (owner question Q-P6-2), so the TOPIK screens pass
/// this as its `titleWidget`. The title keeps one line; the subtitle reads
/// as meta. One heading node for TalkBack.
class TopikAppBarTitleWidget extends StatelessWidget {
  const TopikAppBarTitleWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.titleLarge,
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
```

`lib/features/topik/presentation/widgets/items/topik_level_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A level on screen 34: its name, what it covers and its test count. A
/// level without a valid test keeps its row as information, not as a
/// disabled control: no chevron, no tap, not dimmed (BR-TOPIK-008,
/// critique F5).
class TopikLevelRowWidget extends StatelessWidget {
  const TopikLevelRowWidget({
    super.key,
    required this.level,
    required this.testCount,
    required this.onOpen,
  });

  final TopikLevel level;
  final int testCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasTests = testCount > 0;
    final count = hasTests ? l10n.topikTestCount(testCount) : l10n.topikNoTestsYet;
    return MxListRow(
      title: l10n.topikLevelName(level),
      meta: Text(
        '${l10n.topikLevelScope(level)} · $count',
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      leading: const MxIconTile(icon: AppIcons.fileText),
      hasChevron: hasTests,
      onTap: hasTests ? onOpen : null,
    );
  }
}
```

`lib/features/topik/presentation/screens/topik_home_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_level_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_app_bar_title_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 34 (UC-TOPIK-001): the two exams, each with the number of valid
/// tests the bundled content holds. Where a level leads, `app/` decides.
class TopikHomeScreen extends ConsumerWidget {
  const TopikHomeScreen({super.key, required this.onOpenLevel});

  final ValueChanged<TopikLevel> onOpenLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final children = switch (ref.watch(topikCatalogProvider)) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          title: l10n.topikErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(topikCatalogProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) => [_levels(context, value)],
      _ => [
        MxListSectionHeader(label: l10n.topikPractice),
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingTests, rows: 2),
        ),
      ],
    };
    return MxAppShell(
      appBar: MxAppBar(
        titleWidget: TopikAppBarTitleWidget(
          title: l10n.topikTitle,
          subtitle: l10n.topikSubtitle,
        ),
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(children: children),
    );
  }

  Widget _levels(BuildContext context, List<TopikCatalogEntry> entries) =>
      MxSection(
        title: context.l10n.topikPractice,
        children: [
          for (final level in TopikLevel.values)
            TopikLevelRowWidget(
              level: level,
              testCount: entries.where((e) => e.test.level == level).length,
              onOpen: () => onOpenLevel(level),
            ),
        ],
      );
}
```

- [ ] **Step 4: Run, render the goldens, commit**

```bash
dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update
```

Look at all eight `topik_home_*` PNGs; no other golden may change. Then:

```bash
git add lib/features/topik/presentation test/features/topik/presentation test/support/topik_screen_fixtures.dart
git commit -m "feat(topik): DEV-394 screen 34, TOPIK home"
```

---

### Task 3: Screen 13's Practice entry

**Files:**
- Modify: `lib/features/study/presentation/screens/study_home_screen.dart` (optional `practiceEntry` slot)
- Create: `lib/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart`
- Modify: `test/features/study/presentation/study_home_golden_test.dart` (the entry in the frames)
- Test: `test/features/topik/presentation/topik_practice_entry_test.dart`, `test/features/study/presentation/study_home_screen_test.dart` (one case)

**Interfaces:**
- Consumes: `topikCatalogProvider` (Task 1).
- Produces: `StudyHomeScreen({…, Widget? practiceEntry})`; `TopikPracticeEntryWidget({required VoidCallback onOpen})`.

- [ ] **Step 1: Write the failing tests**

`test/features/topik/presentation/topik_practice_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 13: "Practice" with one row, "TOPIK past papers", "{n} tests".
void main() {
  libraryTest('names the tests and opens TOPIK', (tester, env) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      TopikPracticeEntryWidget(onOpen: () => opened++),
      overrides: topikContentOverrides(topikScreenTests()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('TOPIK past papers'), findsOneWidget);
    expect(find.text('7 tests'), findsOneWidget);
    await tester.tap(find.text('TOPIK past papers'));
    expect(opened, 1);
  });
}
```

In `test/features/study/presentation/study_home_screen_test.dart`, add (reuse that file's helpers for building the screen and seeding a library with a deck that has cards; if it builds the screen through a `_screen()`-like helper, add a `practiceEntry` parameter to it):

```dart
  libraryTest('the practice slot shows under the decks in every state with '
      'data, and not while loading', (tester, env) async {
    const entry = Text('practice-entry');
    // with data (no decks): shown
    await pumpLibraryScreen(tester, env, _screenWith(practiceEntry: entry));
    await tester.pumpAndSettle();
    expect(find.text('practice-entry'), findsOneWidget);
  });
```

(`_screenWith` is that file's existing screen helper with the new named argument; name it as the file does.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_practice_entry_test.dart test/features/study/presentation/study_home_screen_test.dart`
Expected: FAIL — the widget and the slot do not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// Screen 13's Practice section (detail file 13, owner brief 2026-10-15):
/// one row that opens TOPIK, with the number of valid tests once known. The
/// row opens TOPIK whatever the read says: screen 34 shows its own error.
class TopikPracticeEntryWidget extends ConsumerWidget {
  const TopikPracticeEntryWidget({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(topikCatalogProvider).value?.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.topikPractice),
        MxCard(
          isFullBleed: true,
          child: MxListRow(
            title: l10n.topikEntryTitle,
            meta: count == null
                ? null
                : Text(
                    l10n.topikTestCount(count),
                    style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
            leading: const MxIconTile(icon: AppIcons.fileText),
            hasChevron: true,
            onTap: onOpen,
          ),
        ),
      ],
    );
  }
}
```

In `study_home_screen.dart`:
- add the field and its doc after `reauthNotice`:

```dart
  /// The practice entry `app/` composes (TOPIK, ADR-023): `study` does not
  /// import the feature that fills it. Shown under the decks in every state
  /// with data, absent while loading and on error (detail file 13).
  final Widget? practiceEntry;
```

with `this.practiceEntry,` in the constructor;
- in `_loaded`, append to the returned list after `body`:

```dart
      if (practiceEntry case final entry?) ...[
        SizedBox(height: context.dimens.space16),
        entry,
      ],
```

(`_loaded` must receive the entry; it is an instance method, so `practiceEntry` is in scope. Import `theme_context.dart` if `context.dimens` is not yet imported.)

In `test/features/study/presentation/study_home_golden_test.dart`, pass `practiceEntry: TopikPracticeEntryWidget(onOpen: () {})` in `_screen()` and add `...topikContentOverrides(topikScreenTests())` to the overrides of every frame that reaches `_loaded`. This test file may import `topik` (tests are not features; the import rule is for `lib/features/study`).

- [ ] **Step 4: Run, render, commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation test/features/study/presentation
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update
```

Expected changes: `study_home_{loaded,no_resume,zero,no_decks,no_cards,sync_rejected,sync_stale}_{light,dark}.png` gain the Practice section; `loading` and `error` do not change. Any other changed golden is a finding to explain first.

```bash
git add lib/features/study lib/features/topik test/features/study test/features/topik
git commit -m "feat(study): DEV-394 the Practice entry on Study home"
```

---

### Task 4: Screen 35, the test list

**Files:**
- Create: `lib/features/topik/presentation/screens/topik_test_list_screen.dart`
- Create: `lib/features/topik/presentation/widgets/items/topik_test_row_widget.dart`
- Create: `lib/features/topik/presentation/widgets/sections/topik_test_list_header_widget.dart`
- Create: `lib/features/topik/presentation/widgets/overlays/topik_sort_sheet_widget.dart`
- Test: `test/features/topik/presentation/topik_test_list_screen_test.dart`, `test/features/topik/presentation/topik_test_list_golden_test.dart`

**Interfaces:**
- Consumes: `topikCatalogProvider`, `topikTestListChoiceProvider`, `TopikLabels`, `topikTestsOf` (plan 4).
- Produces: `TopikTestListScreen({required TopikLevel level, required ValueChanged<String> onOpenTest})`; `Future<TopikTestOrder?> showTopikSortSheet(BuildContext, {required TopikTestOrder selected})`.

- [ ] **Step 1: Write the failing tests**

`test/features/topik/presentation/topik_test_list_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

Finder _rowTitles() => find.textContaining('한국어능력시험');

// Screen 35 (UC-TOPIK-001, BR-TOPIK-009, BR-TOPIK-022).
void main() {
  final tests = topikScreenTests();

  libraryTest('reading first, newest round first, with tags and status', (
    tester,
    env,
  ) async {
    final topik2Reading96 = tests.firstWhere(
      (t) => t.level == TopikLevel.topik2 && t.round == 96 && t.section == TopikSection.reading,
    );
    await topikSeedCompleted(env, topik2Reading96, startedAt: libraryToday, correct: 41);
    await topikSeedInProgress(env, topik2Reading96, startedAt: libraryToday.add(const Duration(hours: 1)));
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 tests'), findsOneWidget);
    expect(
      [for (final e in tester.widgetList<Text>(find.textContaining('#'))) e.data],
      ['#96', '#91', '#83'],
    );
    expect(find.textContaining('In progress · Best'), findsOneWidget);
    expect(find.text('Not started'), findsNWidgets(2));
    expect(find.textContaining('Explanation · Words'), findsWidgets);
  });

  libraryTest('Listening shows its tests; the choice is per screen', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listening'));
    await tester.pumpAndSettle();

    expect(find.text('1 test'), findsOneWidget);
    expect(find.textContaining('Script'), findsWidgets);
  });

  libraryTest('the sort sheet re-orders the rows', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxChipTrigger));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest round'));
    await tester.pumpAndSettle();

    expect(
      [for (final e in tester.widgetList<Text>(find.textContaining('#'))) e.data],
      ['#83', '#91', '#96'],
    );
  });

  libraryTest('a row opens its test', (tester, env) async {
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: opened.add),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    await tester.tap(_rowTitles().first);
    expect(opened, ['topik2-96-reading']);
  });

  libraryTest('a section with no test is a calm empty state with no sort '
      '(A1, The Content Gate Rule)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik1, onOpenTest: (_) {}),
      overrides: topikContentOverrides([topikTestFixture()]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text('No tests yet for this section'), findsOneWidget);
    expect(find.byType(MxChipTrigger), findsNothing);
    expect(find.text('Listening'), findsOneWidget);
  });

  libraryTest('a submitted attempt updates the status in place (A2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
      overrides: topikContentOverrides(tests),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not started'), findsNWidgets(3));

    await tester.runAsync(
      () => topikSeedCompleted(env, tests[5], startedAt: libraryToday, correct: 41),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not started'), findsNWidgets(2));
  });
}
```

(`tests[5]` is TOPIK II reading 96 in `topikScreenTests()` order; use a lookup as in the first test if the order differs. Use the fixture's real Korean title prefix in `_rowTitles` if `titleKo` differs.)

`test/features/topik/presentation/topik_test_list_golden_test.dart`: the same `shoot` helper as Task 2's golden test with `TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {})`, one frame per state of detail file 35:
- `reading`: `topikScreenTests()`.
- `listening`: the same, then tap "Listening" and settle before the capture (do the tap inside `shoot` through a `before` callback parameter).
- `status`: seed TOPIK II reading 96 completed (41 correct) and in progress, 91 completed twice (30 and 35 correct), 83 none.
- `sort`: tap the `MxChipTrigger` before the capture.
- `empty`: `topikContentOverrides([topikTestFixture(level: TopikLevel.topik1)])` with level TOPIK II … no: pump `TopikTestListScreen(level: TopikLevel.topik1, …)` over `[topikTestFixture()]`.
- `loading`: `topikCatalogProvider` overridden with a pending stream.
- `error`: `topikCatalogProvider` overridden with `Stream.error`.
Names: `goldens/topik_list_{reading,listening,status,sort,empty,loading,error}_$theme.png`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_test_list_screen_test.dart`
Expected: FAIL — the screen does not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/presentation/widgets/overlays/topik_sort_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Screen 35's sort (BR-TOPIK-022): the three orders; the pick closes the
/// sheet. Null when dismissed.
Future<TopikTestOrder?> showTopikSortSheet(
  BuildContext context, {
  required TopikTestOrder selected,
}) => showMxBottomSheet<TopikTestOrder>(
  context,
  builder: (sheetContext) => TopikSortSheetWidget(selected: selected),
);

class TopikSortSheetWidget extends StatelessWidget {
  const TopikSortSheetWidget({super.key, required this.selected});

  final TopikTestOrder selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      title: l10n.topikSortTitle,
      child: MxDividedColumn(
        children: [
          for (final order in TopikTestOrder.values)
            MxOptionRow(
              title: l10n.topikOrderName(order),
              isSelected: order == selected,
              onSelected: () => Navigator.of(context).pop(order),
            ),
        ],
      ),
    );
  }
}
```

`lib/features/topik/presentation/widgets/sections/topik_test_list_header_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Screen 35's header: the section, how many tests, what they are, and the
/// sort. Shown only with tests (The Content Gate Rule, critique F4).
class TopikTestListHeaderWidget extends StatelessWidget {
  const TopikTestListHeaderWidget({
    super.key,
    required this.section,
    required this.testCount,
    required this.order,
    required this.onSort,
  });

  final TopikSection section;
  final int testCount;
  final TopikTestOrder order;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxCard(
      child: Row(
        spacing: context.dimens.space16,
        children: [
          MxIconTile(
            icon: section == TopikSection.reading
                ? AppIcons.fileText
                : AppIcons.speak,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.dimens.space4,
              children: [
                Text(l10n.topikTestCount(testCount), style: context.texts.titleMedium),
                Text(
                  l10n.topikTestsHeaderBody,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          MxChipTrigger(label: l10n.topikOrderName(order), onPressed: onSort),
        ],
      ),
    );
  }
}
```

`lib/features/topik/presentation/widgets/items/topik_test_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A test on screen 35: its round, its Korean title (content, so it may end
/// in an ellipsis, critique F7), its content tags (BR-TOPIK-009) and the
/// person's status (BR-TOPIK-022) as the row's meta.
class TopikTestRowWidget extends StatelessWidget {
  const TopikTestRowWidget({
    super.key,
    required this.entry,
    required this.onOpen,
  });

  final TopikCatalogEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final test = entry.test;
    final metaStyle = context.texts.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final tags = [
      for (final tag in TopikContentTagOrder.ordered(test.contentTags))
        l10n.topikTagName(tag),
    ];
    return MxListRow(
      title: test.titleKo,
      leading: MxBadge(
        label: l10n.topikRoundNumber(test.round),
        tone: MxBadgeTone.neutral,
      ),
      meta: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty) Text(tags.join(' · '), style: metaStyle),
          Text(l10n.topikTestStatusLine(entry.status), style: metaStyle),
        ],
      ),
      hasChevron: true,
      onTap: onOpen,
    );
  }
}

/// Tags in the order the enum declares, so every row reads alike.
abstract final class TopikContentTagOrder {
  static List<TopikContentTag> ordered(Set<TopikContentTag> tags) => [
    for (final tag in TopikContentTag.values)
      if (tags.contains(tag)) tag,
  ];
}
```

(`TopikContentTag` is in `topik_test_model.dart`: import it. If the guard rejects a non-widget class in a `_widget.dart` file, make `ordered` a private top-level function instead.)

`lib/features/topik/presentation/screens/topik_test_list_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_list_choice_provider.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_test_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_sort_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_test_list_header_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 35 (UC-TOPIK-001): one level's tests of the chosen section, in
/// the chosen order, each with its status, updated in place as attempts
/// change (A2). Where a row leads, `app/` decides.
class TopikTestListScreen extends ConsumerWidget {
  const TopikTestListScreen({
    super.key,
    required this.level,
    required this.onOpenTest,
  });

  final TopikLevel level;
  final ValueChanged<String> onOpenTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choiceProvider = topikTestListChoiceProvider(level);
    final choice = ref.watch(choiceProvider);
    final body = switch (ref.watch(topikCatalogProvider)) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          title: l10n.topikErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(topikCatalogProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) => _loaded(
        context,
        topikTestsOf(
          value,
          level: level,
          section: choice.section,
          order: choice.order,
        ),
        choice,
        onSort: () => unawaited(_sort(context, ref, choice.order)),
      ),
      _ => [
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingTests),
        ),
      ],
    };
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.topikLevelName(level),
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          // Navigation, so it stays in every state (The Content Gate Rule).
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxSegmentedTray<TopikSection>(
              segments: [
                for (final section in [TopikSection.reading, TopikSection.listening])
                  MxSegment(value: section, label: l10n.topikSectionName(section)),
              ],
              selected: choice.section,
              onSelected: ref.read(choiceProvider.notifier).pickSection,
              isWide: true,
            ),
          ),
          SizedBox(height: context.dimens.space16),
          ...body,
        ],
      ),
    );
  }

  List<Widget> _loaded(
    BuildContext context,
    List<TopikCatalogEntry> entries,
    TopikTestListChoice choice, {
    required VoidCallback onSort,
  }) {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      return [
        MxEmptyState(
          icon: choice.section == TopikSection.reading
              ? AppIcons.fileText
              : AppIcons.speak,
          title: l10n.topikSectionEmpty,
          tone: MxEmptyStateTone.neutral,
        ),
      ];
    }
    return [
      TopikTestListHeaderWidget(
        section: choice.section,
        testCount: entries.length,
        order: choice.order,
        onSort: onSort,
      ),
      SizedBox(height: context.dimens.space16),
      MxCard(
        isFullBleed: true,
        child: MxDividedColumn(
          children: [
            for (final entry in entries)
              TopikTestRowWidget(
                entry: entry,
                onOpen: () => onOpenTest(entry.test.testId),
              ),
          ],
        ),
      ),
    ];
  }

  Future<void> _sort(
    BuildContext context,
    WidgetRef ref,
    TopikTestOrder selected,
  ) async {
    final order = await showTopikSortSheet(context, selected: selected);
    if (order == null || !context.mounted) return;
    ref.read(topikTestListChoiceProvider(level).notifier).pickOrder(order);
  }
}
```

(`ref.read(choiceProvider.notifier).pickSection` as a tear-off inside `build` is a `ref.read` in build: if the guard flags it, pass `(section) => ref.read(...).pickSection(section)`, which reads only on tap.)

- [ ] **Step 4: Run, render, commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update
git add lib/features/topik/presentation test/features/topik/presentation
git commit -m "feat(topik): DEV-394 screen 35, the test list"
```

Only the fourteen `topik_list_*` PNGs may be new.

---

### Task 5: Screen 36, the test detail

**Files:**
- Create: `lib/features/topik/presentation/controllers/topik_test_detail_controller.dart`
- Create: `lib/features/topik/presentation/screens/topik_test_detail_screen.dart`
- Create: `lib/features/topik/presentation/widgets/sections/topik_overview_widget.dart`, `topik_history_widget.dart`
- Create: `lib/features/topik/presentation/widgets/items/topik_recent_attempt_row_widget.dart`, `topik_history_row_widget.dart`
- Create: `lib/features/topik/presentation/widgets/overlays/topik_attempt_dialogs_widget.dart`
- Test: `test/features/topik/presentation/topik_test_detail_screen_test.dart`, `test/features/topik/presentation/topik_test_detail_golden_test.dart`

**Interfaces:**
- Consumes: `topikTestDetailProvider`, `startTopikAttemptUseCaseProvider`, `deleteTopikAttemptUseCaseProvider`, `TopikLabels`, `TopikAppBarTitleWidget` (Tasks 1–2); `dayClockProvider`; `DurationText` (`l10n.duration`).
- Produces: `TopikTestDetailScreen({required String testId, required ValueChanged<String> onOpenAttempt, required ValueChanged<String> onOpenSummary, required ValueChanged<String> onOpenReview, required VoidCallback onBackToTests})`; `TopikTestDetailController` (state `bool` busy; `start({required bool replaceInProgress})`, `delete(String attemptId)`); `showTopikContinueDialog`, `showTopikStartNewDialog`, `showTopikDeleteDialog`.

- [ ] **Step 1: Write the failing tests**

`test/features/topik/presentation/topik_test_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

final class _Taps {
  final attempts = <String>[];
  final summaries = <String>[];
  final reviews = <String>[];
  var backToTests = 0;
}

// Screen 36 (UC-TOPIK-002, BR-TOPIK-011, -018, -020, -021).
void main() {
  final test = topikTestFixture();

  Widget screen(_Taps taps, {String? testId}) => TopikTestDetailScreen(
    testId: testId ?? test.testId,
    onOpenAttempt: taps.attempts.add,
    onOpenSummary: taps.summaries.add,
    onOpenReview: taps.reviews.add,
    onBackToTests: () => taps.backToTests++,
  );

  Future<void> pump(WidgetTester tester, LibraryEnv env, _Taps taps, {String? testId}) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(taps, testId: testId),
      overrides: topikContentOverrides([test]),
    );
    await tester.pumpAndSettle();
  }

  libraryTest('no attempt: the empty card starts one, and there is no FAB '
      '(BR-TOPIK-020, critique F2)', (tester, env) async {
    final taps = _Taps();
    await pump(tester, env, taps);

    expect(find.text('No attempts yet'), findsOneWidget);
    expect(find.byType(MxFab), findsNothing);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(taps.attempts, hasLength(1));
  });

  libraryTest('Overview: the figures, then recent attempts numbered', (
    tester,
    env,
  ) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday, correct: 25);
    await topikSeedCompleted(env, test, startedAt: libraryToday.add(const Duration(days: 1)), correct: 40);
    final taps = _Taps();
    await pump(tester, env, taps);

    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('the FAB with an attempt in progress asks; Continue opens it '
      '(BR-TOPIK-011)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(env, test, startedAt: libraryToday.add(const Duration(hours: 2)));
    final taps = _Taps();
    await pump(tester, env, taps);

    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    expect(find.text('You have an attempt in progress'), findsOneWidget);
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    expect(taps.attempts, [open.id]);
  });

  libraryTest('Start new asks again, then replaces the attempt in progress', (
    tester,
    env,
  ) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(env, test, startedAt: libraryToday.add(const Duration(hours: 2)));
    final taps = _Taps();
    await pump(tester, env, taps);

    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new attempt?'), findsOneWidget);
    await tester.tap(find.text('Start new').last);
    await tester.pumpAndSettle();

    expect(taps.attempts, hasLength(1));
    expect(taps.attempts.single, isNot(open.id));
    final store = TopikAttemptRepositoryImpl(env.db);
    final ids = await tester.runAsync(
      () async => [for (final a in await store.watchAttemptsOfTest(test.testId).first) a.id],
    );
    expect(ids, isNot(contains(open.id)));
  });

  libraryTest('the dialog dismissed changes nothing', (tester, env) async {
    await topikSeedInProgress(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(taps.attempts, isEmpty);
  });

  libraryTest('a second tap while starting opens one attempt', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.byType(MxFab));
    await tester.tap(find.byType(MxFab), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps.attempts, hasLength(1));
  });

  libraryTest('History: delete asks, then removes the row and renumbers '
      '(BR-TOPIK-018, -021)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    await topikSeedCompleted(env, test, startedAt: libraryToday.add(const Duration(days: 1)));
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('#2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Delete attempt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('#2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Delete attempt').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('#2'), findsNothing);
    expect(find.text('#1'), findsOneWidget);
  });

  libraryTest('History: Summary, Review and Continue open their screens', (
    tester,
    env,
  ) async {
    final done = await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(env, test, startedAt: libraryToday.add(const Duration(hours: 1)));
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summary'));
    await tester.tap(find.text('Review'));
    await tester.tap(find.text('Continue'));
    expect(taps.summaries, [done.id]);
    expect(taps.reviews, [done.id]);
    expect(taps.attempts, [open.id]);
  });

  libraryTest('an unknown test: missing, with Back to tests and no FAB '
      '(UC-TOPIK-002 E1)', (tester, env) async {
    final taps = _Taps();
    await pump(tester, env, taps, testId: 'topik2-1-reading');

    expect(find.text("This test isn't available"), findsOneWidget);
    expect(find.byType(MxFab), findsNothing);
    await tester.tap(find.text('Back to tests'));
    expect(taps.backToTests, 1);
  });

  libraryTest('History with no attempt keeps the FAB', (tester, env) async {
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });
}
```

The golden test `topik_test_detail_golden_test.dart` uses Task 2's `shoot` shape with `TopikTestDetailScreen(testId: …)`, one frame per state of detail file 36: `overview` (three completed, one in progress, seeded on distinct days), `overview_empty`, `history` (tap History), `history_empty` (tap History, no attempt), `delete` (History, then tap the first delete), `continue` (one in progress, tap the FAB), `missing` (unknown id), `loading` (`topikTestDetailProvider(testId)` overridden with a pending stream), `error` (with `Stream.error`). Names `goldens/topik_detail_{state}_$theme.png`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation/topik_test_detail_screen_test.dart`
Expected: FAIL — the screen does not exist.

- [ ] **Step 3: The controller and the dialogs**

`lib/features/topik/presentation/controllers/topik_test_detail_controller.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/start_topik_attempt_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_test_detail_controller.g.dart';

/// Screen 36's commands, each through its use case (UC-TOPIK-002,
/// UC-TOPIK-003 step 1). The state is whether one runs: a second tap while
/// it does is ignored (Review Focus 3). A database `Failure` is thrown
/// through; the widget says so.
@riverpod
class TopikTestDetailController extends _$TopikTestDetailController {
  @override
  bool build(String testId) => false;

  /// Null when a command already runs.
  Future<Outcome<TopikAttempt, TopikRejection>?> start({
    required bool replaceInProgress,
  }) => _run(
    () => ref.read(startTopikAttemptUseCaseProvider)(
      testId,
      replaceInProgress: replaceInProgress,
    ),
  );

  /// Null when a command already runs.
  Future<Outcome<void, TopikRejection>?> delete(String attemptId) =>
      _run(() => ref.read(deleteTopikAttemptUseCaseProvider)(attemptId));

  Future<T?> _run<T>(Future<T> Function() command) async {
    if (state) return null;
    state = true;
    try {
      return await command();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
```

`lib/features/topik/presentation/widgets/overlays/topik_attempt_dialogs_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// What the person picked when an attempt is in progress (BR-TOPIK-011).
enum TopikContinueChoice { continueAttempt, startNew }

/// "You have an attempt in progress": Continue (primary) or Start new; null
/// when dismissed.
Future<TopikContinueChoice?> showTopikContinueDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxDialog<TopikContinueChoice>(
    context,
    builder: (dialogContext) => MxDialog(
      title: l10n.topikContinueTitle,
      body: l10n.topikContinueBody,
      actions: MxSheetActions(
        cancelLabel: l10n.topikStartNew,
        onCancel: () =>
            Navigator.of(dialogContext).pop(TopikContinueChoice.startNew),
        confirmLabel: l10n.topikContinue,
        onConfirm: () => Navigator.of(
          dialogContext,
        ).pop(TopikContinueChoice.continueAttempt),
      ),
    ),
  );
}

/// The second question before the attempt in progress is deleted.
Future<bool> showTopikStartNewDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.topikStartNewTitle,
    body: l10n.topikStartNewBody,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.topikStartNew,
    isDestructive: true,
  );
}

Future<bool> showTopikDeleteDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.topikDeleteTitle,
    body: l10n.topikDeleteBody,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.topikDelete,
    isDestructive: true,
  );
}
```

(If the guard requires a `Widget` class in a `_widget.dart` overlay file, follow `tag_delete_dialog_widget.dart`'s shape.)

- [ ] **Step 4: The rows and sections**

`lib/features/topik/presentation/widgets/items/topik_recent_attempt_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A recent attempt (BR-TOPIK-021): "#n", when, the score and how long; an
/// attempt in progress reads "In progress" and continues.
class TopikRecentAttemptRowWidget extends StatelessWidget {
  const TopikRecentAttemptRowWidget({
    super.key,
    required this.numbered,
    required this.onOpen,
  });

  final TopikNumberedAttempt numbered;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attempt = numbered.attempt;
    final score = attempt.score;
    final meta = [
      l10n.topikDateTime(attempt.startedAt),
      if (!attempt.isCompleted || score == null)
        l10n.topikStatusInProgress
      else ...[
        l10n.topikOfTotal(score, attempt.maxScore),
        l10n.duration(attempt.totalTimeMs),
      ],
    ].join(' · ');
    return MxListRow(
      title: l10n.topikAttemptNumber(numbered.number),
      meta: Text(
        meta,
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      hasChevron: true,
      onTap: onOpen,
    );
  }
}
```

`lib/features/topik/presentation/widgets/items/topik_history_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// One attempt in History (critique F1): "#n" with its status badge, then
/// when, "{correct}/{count}" and how long, then its actions as small outline
/// buttons (never primary: one row of many, The One Accent Rule) and the
/// delete button at the end.
class TopikHistoryRowWidget extends StatelessWidget {
  const TopikHistoryRowWidget({
    super.key,
    required this.numbered,
    required this.onSummary,
    required this.onReview,
    required this.onContinue,
    required this.onDelete,
  });

  final TopikNumberedAttempt numbered;
  final VoidCallback onSummary;
  final VoidCallback onReview;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final attempt = numbered.attempt;
    final isCompleted = attempt.isCompleted;
    final meta = [
      l10n.topikDateTime(attempt.startedAt),
      if (isCompleted)
        l10n.topikOfTotal(attempt.correctCount ?? 0, attempt.questionCount),
      l10n.duration(attempt.totalTimeMs),
    ].join(' · ');
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space16,
        vertical: dimens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: dimens.space8,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: dimens.space4,
              children: [
                Row(
                  spacing: dimens.space8,
                  children: [
                    Text(
                      l10n.topikAttemptNumber(numbered.number),
                      style: context.texts.titleSmall,
                    ),
                    MxBadge(
                      label: isCompleted
                          ? l10n.topikCompleted
                          : l10n.topikStatusInProgress,
                      tone: isCompleted
                          ? MxBadgeTone.success
                          : MxBadgeTone.neutral,
                    ),
                  ],
                ),
                Text(
                  meta,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: dimens.space8,
                  runSpacing: dimens.space8,
                  children: [
                    if (isCompleted) ...[
                      MxButton(
                        label: l10n.topikSummary,
                        onPressed: onSummary,
                        tone: MxButtonTone.outline,
                        size: MxButtonSize.small,
                      ),
                      MxButton(
                        label: l10n.topikReview,
                        onPressed: onReview,
                        tone: MxButtonTone.outline,
                        size: MxButtonSize.small,
                      ),
                    ] else
                      MxButton(
                        label: l10n.topikContinue,
                        onPressed: onContinue,
                        tone: MxButtonTone.outline,
                        size: MxButtonSize.small,
                      ),
                  ],
                ),
              ),
              MxIconButton(
                icon: AppIcons.delete,
                semanticLabel: l10n.topikDeleteAttempt,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

`lib/features/topik/presentation/widgets/sections/topik_overview_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_recent_attempt_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/relative_time.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Overview of screen 36 (BR-TOPIK-020, BR-TOPIK-021): Overall Progress and
/// the recent attempts. No attempt: the card becomes the empty state with
/// Start, the screen's one action then (critique F2).
class TopikOverviewWidget extends StatelessWidget {
  const TopikOverviewWidget({
    super.key,
    required this.detail,
    required this.now,
    required this.onStart,
    required this.onOpenAttempt,
    required this.onOpenSummary,
  });

  final TopikTestDetail detail;
  final DateTime now;
  final VoidCallback onStart;
  final ValueChanged<String> onOpenAttempt;
  final ValueChanged<String> onOpenSummary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final progress = detail.progress;
    if (progress.isEmpty) {
      return MxEmptyState(
        icon: AppIcons.add,
        title: l10n.topikNoAttemptsTitle,
        body: l10n.topikNoAttemptsBody,
        actionLabel: l10n.topikStart,
        onAction: onStart,
      );
    }
    String figure(int? value, String Function(int) format) =>
        value == null ? '–' : format(value);
    final lastActivity = progress.lastActivityAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.topikOverallProgress),
        MxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: dimens.space16,
            children: [
              Row(
                spacing: dimens.space16,
                children: [
                  Expanded(
                    child: MxStatTile(
                      value: figure(progress.accuracyPercent, l10n.topikPercent),
                      label: l10n.topikAccuracy,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                  Expanded(
                    child: MxStatTile(
                      value: figure(progress.bestScore, (v) => '$v'),
                      label: l10n.topikBest,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: dimens.space16,
                children: [
                  Expanded(
                    child: MxStatTile(
                      value: figure(progress.averageScore, (v) => '$v'),
                      label: l10n.topikAverage,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                  Expanded(
                    child: MxStatTile(
                      value: l10n.topikOfTotal(progress.completed, progress.sessions),
                      label: l10n.topikCompleted,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                ],
              ),
              if (lastActivity != null)
                Text(
                  l10n.topikLastActivity(
                    l10n.ago(lastActivity, now),
                    l10n.duration(progress.totalTimeMs),
                  ),
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: dimens.space8),
        MxNote.hint(text: l10n.topikScoresNote),
        SizedBox(height: dimens.space24),
        MxListSectionHeader(label: l10n.topikRecentAttempts),
        MxCard(
          isFullBleed: true,
          child: MxDividedColumn(
            children: [
              for (final numbered in detail.recent)
                TopikRecentAttemptRowWidget(
                  numbered: numbered,
                  onOpen: () => numbered.attempt.isCompleted
                      ? onOpenSummary(numbered.attempt.id)
                      : onOpenAttempt(numbered.attempt.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
```

(The "–" for a figure with no value is not copy but a mark; if the guard flags a literal string in a widget, add `topikNoFigure` "–" to both ARB files.)

`lib/features/topik/presentation/widgets/sections/topik_history_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_history_row_widget.dart';

/// History of screen 36 (BR-TOPIK-018, BR-TOPIK-021): every attempt, newest
/// first, with its actions; none yet is a calm empty state (the FAB stays).
class TopikHistoryWidget extends StatelessWidget {
  const TopikHistoryWidget({
    super.key,
    required this.attempts,
    required this.onOpenAttempt,
    required this.onOpenSummary,
    required this.onOpenReview,
    required this.onDelete,
  });

  final List<TopikNumberedAttempt> attempts;
  final ValueChanged<String> onOpenAttempt;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onOpenReview;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (attempts.isEmpty) {
      return MxEmptyState(
        icon: AppIcons.history,
        title: l10n.topikNoAttemptsTitle,
        tone: MxEmptyStateTone.neutral,
      );
    }
    return MxCard(
      isFullBleed: true,
      child: MxDividedColumn(
        children: [
          for (final numbered in attempts)
            TopikHistoryRowWidget(
              numbered: numbered,
              onSummary: () => onOpenSummary(numbered.attempt.id),
              onReview: () => onOpenReview(numbered.attempt.id),
              onContinue: () => onOpenAttempt(numbered.attempt.id),
              onDelete: () => onDelete(numbered.attempt.id),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: The screen**

`lib/features/topik/presentation/screens/topik_test_detail_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_test_detail_controller.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_detail_provider.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_attempt_dialogs_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_app_bar_title_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_history_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_overview_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

enum _Tab { overview, history }

/// Screen 36 (UC-TOPIK-002): one test's Overall Progress, recent attempts
/// and History, the door to a new attempt (BR-TOPIK-011), and deleting one
/// (BR-TOPIK-018). Figures and numbers follow every write (A3). Where an
/// attempt, a summary or a review leads, `app/` decides.
class TopikTestDetailScreen extends ConsumerStatefulWidget {
  const TopikTestDetailScreen({
    super.key,
    required this.testId,
    required this.onOpenAttempt,
    required this.onOpenSummary,
    required this.onOpenReview,
    required this.onBackToTests,
  });

  final String testId;
  final ValueChanged<String> onOpenAttempt;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onOpenReview;
  final VoidCallback onBackToTests;

  @override
  ConsumerState<TopikTestDetailScreen> createState() =>
      _TopikTestDetailScreenState();
}

class _TopikTestDetailScreenState extends ConsumerState<TopikTestDetailScreen> {
  var _tab = _Tab.overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailProvider = topikTestDetailProvider(widget.testId);
    final async = ref.watch(detailProvider);
    final detail = async.value;
    final test = detail?.test;
    final now = ref.watch(dayClockProvider).now();
    final children = switch (async) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          title: l10n.topikDetailErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(detailProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) when value.test == null => [
        MxEmptyState(
          icon: AppIcons.alert,
          title: l10n.topikTestMissingTitle,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToTests,
          onAction: widget.onBackToTests,
        ),
      ],
      AsyncValue(:final value?) => _loaded(value, now),
      _ => [
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingTest),
        ),
      ],
    };
    // The FAB exists with the test and an attempt to add a sibling to; on
    // an empty Overview the empty state's Start is the one action
    // (The Content Gate Rule, critique F2).
    final hasFab =
        test != null &&
        detail != null &&
        !(detail.progress.isEmpty && _tab == _Tab.overview);
    return MxAppShell(
      appBar: MxAppBar(
        title: test == null ? l10n.topikTitle : null,
        titleWidget: test == null
            ? null
            : TopikAppBarTitleWidget(
                title: test.titleKo,
                subtitle: l10n.topikTestSubtitle(
                  l10n.topikLevelName(test.level),
                  l10n.topikSectionName(test.section),
                ),
              ),
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      fab: hasFab
          ? MxFab(
              icon: AppIcons.add,
              semanticLabel: l10n.topikStart,
              onPressed: () => unawaited(_start(detail)),
            )
          : null,
      body: MxScreenScroll(
        clearance: hasFab ? MxScrollClearance.fab : MxScrollClearance.base,
        children: children,
      ),
    );
  }

  List<Widget> _loaded(TopikTestDetail detail, DateTime now) {
    final l10n = context.l10n;
    return [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: MxSegmentedTray<_Tab>(
          segments: [
            MxSegment(value: _Tab.overview, label: l10n.topikOverview),
            MxSegment(value: _Tab.history, label: l10n.topikHistory),
          ],
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
          isWide: true,
        ),
      ),
      SizedBox(height: context.dimens.space16),
      switch (_tab) {
        _Tab.overview => TopikOverviewWidget(
          detail: detail,
          now: now,
          onStart: () => unawaited(_start(detail)),
          onOpenAttempt: widget.onOpenAttempt,
          onOpenSummary: widget.onOpenSummary,
        ),
        _Tab.history => TopikHistoryWidget(
          attempts: detail.attempts,
          onOpenAttempt: widget.onOpenAttempt,
          onOpenSummary: widget.onOpenSummary,
          onOpenReview: widget.onOpenReview,
          onDelete: (id) => unawaited(_delete(id)),
        ),
      },
    ];
  }

  TopikTestDetailController get _controller =>
      ref.read(topikTestDetailControllerProvider(widget.testId).notifier);

  /// BR-TOPIK-011: with an attempt in progress, Continue or Start new; Start
  /// new asks once more before the attempt in progress goes.
  Future<void> _start(TopikTestDetail detail) async {
    final inProgress = detail.inProgress;
    if (inProgress != null) {
      final choice = await showTopikContinueDialog(context);
      if (!mounted || choice == null) return;
      if (choice == TopikContinueChoice.continueAttempt) {
        widget.onOpenAttempt(inProgress.attempt.id);
        return;
      }
      if (!await showTopikStartNewDialog(context) || !mounted) return;
    }
    await _command(
      () => _controller.start(replaceInProgress: inProgress != null),
      onDone: (attempt) => widget.onOpenAttempt(attempt.id),
    );
  }

  Future<void> _delete(String attemptId) async {
    if (!await showTopikDeleteDialog(context) || !mounted) return;
    await _command(() => _controller.delete(attemptId), onDone: (_) {});
  }

  /// Runs a command; a refusal or a failure is a snackbar, and nothing is
  /// lost (UC-TOPIK-002 E3). A refusal for an attempt already gone says
  /// nothing: the row has already left.
  Future<void> _command<T>(
    Future<Outcome<T, TopikRejection>?> Function() command, {
    required void Function(T value) onDone,
  }) async {
    try {
      final outcome = await command();
      if (!mounted || outcome == null) return;
      switch (outcome) {
        case Ok(:final value):
          onDone(value);
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
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }
}
```

(`MxAppBar` asserts exactly one of `title` and `titleWidget`: the code passes one or the other. If `MxScrollClearance` has other names, use the one `MxScreenScroll`'s doc gives for a screen with a FAB.)

- [ ] **Step 6: Run, render, commit**

```bash
dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/presentation
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update
git add lib/features/topik/presentation test/features/topik/presentation
git commit -m "feat(topik): DEV-394 screen 36, the test detail"
```

Only the eighteen `topik_detail_*` PNGs may be new.

---

### Task 6: Routes, docs and the gates

**Files:**
- Modify: `lib/app/router/app_routes.dart`
- Create: `lib/app/router/topik_routes.dart`
- Modify: `lib/app/router/app_router.dart` (the topik route under Study; the entry slot)
- Modify: `docs/shared/ui/screen-handoff/{13-study-home,34-topik-home,35-topik-test-list,36-topik-test-detail}.md` (status built, states VERIFIED by their tests), the screen index row of 34–36
- Test: `test/app/topik_routes_test.dart`

**Interfaces:**
- Consumes: the three screens (Tasks 2, 4, 5), `TopikPracticeEntryWidget` (Task 3).
- Produces: `AppRoutes.topik`, `AppRoutes.topikLevel(String)`, `AppRoutes.topikTest(String)`, `AppRoutes.topikAttempt(String)`, `AppRoutes.topikSummary(String)`, `AppRoutes.topikReview(String)`; `GoRoute topikRoute()`; `Widget topikPracticeEntry(BuildContext)`.

- [ ] **Step 1: Write the failing test**

`test/app/topik_routes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/app_routes.dart';

// Detail files 34–36: the TOPIK screens under Study (the tab bar stays).
void main() {
  test('the paths', () {
    expect(AppRoutes.topik, '/study/topik');
    expect(AppRoutes.topikLevel('topik1'), '/study/topik/topik1');
    expect(AppRoutes.topikTest('topik2-96-reading'), '/study/topik/test/topik2-96-reading');
    expect(AppRoutes.topikAttempt('a1'), '/study/topik/attempt/a1');
    expect(AppRoutes.topikSummary('a1'), '/study/topik/attempt/a1/summary');
    expect(AppRoutes.topikReview('a1'), '/study/topik/attempt/a1/review');
  });
}
```

Add, reusing `test/app/` router tests' `pumpMemoxApp` shape (see an existing deep-link test, such as the one for `/study/session/...` or a settings child, and copy its harness):
- `/study/topik` deep link shows "TOPIK" with the tab bar;
- `/study/topik/xyz` shows the not-found screen;
- `/study/topik/test/topik2-1-reading` shows "This test isn't available".

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/topik_routes_test.dart`
Expected: FAIL — the constants do not exist.

- [ ] **Step 3: Implement**

In `app_routes.dart`, after the study constants:

```dart
  /// TOPIK home (screen 34), relative to [study]; screens 34–36 keep the
  /// tab bar (detail files 34–36).
  static const String topikChild = 'topik';
  static const String topik = '$study/$topikChild';

  /// The path parameter that names a TOPIK level (`topik1`, `topik2`).
  static const String topikLevelParam = 'level';

  /// A level's test list (screen 35), relative to [topik].
  static const String topikLevelChild = ':$topikLevelParam';
  static String topikLevel(String level) => '$topik/$level';

  /// The path parameter that names a TOPIK test.
  static const String topikTestIdParam = 'testId';

  /// A test's detail (screen 36), relative to [topik].
  static const String topikTestChild = 'test/:$topikTestIdParam';
  static String topikTest(String testId) => '$topik/test/$testId';

  /// An attempt (screen 37), its Summary (38) and its Review (39): routes of
  /// plans 6b and 6c; screen 36 already leads there.
  static String topikAttempt(String attemptId) => '$topik/attempt/$attemptId';
  static String topikSummary(String attemptId) =>
      '${topikAttempt(attemptId)}/summary';
  static String topikReview(String attemptId) =>
      '${topikAttempt(attemptId)}/review';
```

`lib/app/router/topik_routes.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/app/router/route_not_found_screen.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_practice_entry_widget.dart';

/// Screens 34–36 under Study (TOPIK spec §8): the tab bar stays, Back climbs
/// one level.
GoRoute topikRoute() => GoRoute(
  path: AppRoutes.topikChild,
  builder: (context, state) => TopikHomeScreen(
    onOpenLevel: (level) =>
        unawaited(context.push(AppRoutes.topikLevel(level.code))),
  ),
  routes: [
    GoRoute(
      path: AppRoutes.topikTestChild,
      builder: (context, state) => TopikTestDetailScreen(
        testId: state.pathParameters[AppRoutes.topikTestIdParam]!,
        onOpenAttempt: (id) => unawaited(context.push(AppRoutes.topikAttempt(id))),
        onOpenSummary: (id) => unawaited(context.push(AppRoutes.topikSummary(id))),
        onOpenReview: (id) => unawaited(context.push(AppRoutes.topikReview(id))),
        onBackToTests: () => context.go(AppRoutes.topik),
      ),
    ),
    GoRoute(
      path: AppRoutes.topikLevelChild,
      builder: (context, state) {
        final level = TopikLevel.ofCode(
          state.pathParameters[AppRoutes.topikLevelParam],
        );
        if (level == null) return const RouteNotFoundScreen();
        return TopikTestListScreen(
          level: level,
          onOpenTest: (id) => unawaited(context.push(AppRoutes.topikTest(id))),
        );
      },
    ),
  ],
);

/// Study home's Practice entry (screen 13), composed here so `study` does
/// not import `topik` (ADR-023).
Widget topikPracticeEntry(BuildContext context) => TopikPracticeEntryWidget(
  onOpen: () => unawaited(context.push(AppRoutes.topik)),
);
```

In `app_router.dart`, the Study branch's `GoRoute(path: AppRoutes.study, …)`: add `routes: [topikRoute()],` and `practiceEntry: topikPracticeEntry(context),` to `StudyHomeScreen(...)`; import `topik_routes.dart`.

- [ ] **Step 4: Docs**

- Detail files 34, 35, 36: replace "**Not built yet (status `shaped`).** …" with "**Built (plan 6a, 2026-10-15).** Goldens are under `test/features/topik/presentation/goldens/`; transitions are VERIFIED by `test/features/topik/presentation/topik_{home,test_list,test_detail}_screen_test.dart` unless a row says otherwise." and mark each transition row's evidence with the test name that executes it; a row no test executes says `UNVERIFIED` and why (attempt synced from another device, account switched: the stream tests of plan 4 cover the data, no screen test runs a sync).
- Detail file 13: replace "not built yet" in the TOPIK entry ruling with "built (plan 6a)".
- Detail file 36: add the rulings F1 (History row anatomy), F2 (no FAB on an empty Overview), F8 (score tiles without the maximum).
- Detail file 35: add the rulings F4 (header and sort only with tests) and F7 (a title may end in an ellipsis), and that the badge is neutral (The One Accent Rule).
- The screen index (`docs/shared/ui/screen-handoff/README.md` or the index the docs check names): status of 34–36 to built.
- Run `python3 tools/docs/check.py` (PASS).

- [ ] **Step 5: The gates, the audit, the review page**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh
```

Then, per CLAUDE.md's screen workflow step 5: `impeccable audit` of screens 13 (the entry), 34, 35 and 36 in every state of their States tables against `DESIGN.md`, from the goldens (every state has one). Fix everything it finds in one batch, then one `impeccable audit` of what changed. Then the `golden-compare` page for every new and changed golden (base: the merge base), published for the owner.

- [ ] **Step 6: Commit**

```bash
git add lib/app docs test/app
git commit -m "feat(app): DEV-394 the TOPIK routes under Study, and the screens as built"
```

## Plan-time rulings

| # | Ruling | Why |
|---|---|---|
| R1 | Plan 6 split in 6a (13, 34–36), 6b (37), 6c (38, 39), one PR each. | Seven screens and about fifty goldens do not fit one reviewable PR. |
| R2 | 6a pushes the attempt, summary and review paths before their routes exist. | No content ships yet, so no one reaches them; 6b and 6c add the routes. |
| R3 | The app bar subtitle is a TOPIK title widget, not a new `MxAppBar` slot. | Adding to `lib/shared` needs the owner (Q-P6-2). |
| R4 | Reading and levels use `AppIcons.fileText`, listening `AppIcons.speak`. | No book or headphones glyph; adding one to `lib/core` needs the owner (Q-P6-3). |
| R5 | Critique F1, F2, F4, F5, F7, F8 adopted as written in Global Constraints and the tasks. | Pre-plan Impeccable critique against DESIGN.md. |
| R6 | Screen 36's `testMissing` hides History, as its detail file says. | Q-P4-4 (keep History for a removed test) waits for the owner. |
| R7 | Recent attempts: a completed row opens its Summary; an attempt in progress continues. | The detail file names only the in-progress tap; a completed attempt's natural target is its result. |

## Out of this plan

Screens 37, 38, 39 and their routes (plans 6b, 6c); a sync or account switch driven through a screen test.
