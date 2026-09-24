# Library Screens — Phase 1 (Infrastructure and Library Root) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lay the first `presentation/` layer and ship the Library root:
- the level's workload and the root decks;
- sort and filter;
- the empty, loading and error states;
- creating a root deck;
- status ink tokens that bring status text to AA.

**Architecture:**
- **Reads:** Riverpod codegen providers in `lib/features/deck/presentation/`. Each read model is a stream family over exactly one use case (AD-12).
- **Writes:** go through a thin controller that returns the use case's `Outcome`. The widget maps a rejection to ARB copy, and a database `Failure` to plain copy.
- **Tests:** screens run against the real backend, an in-memory Drift database and a `FakeDayClock` overridden in the `ProviderScope`.
- **Routing:** the `/decks` branch of the router gets the new screen. Every other branch keeps its placeholder.

**Tech Stack:** Flutter 3.47.5, flutter_riverpod 3.4.3, riverpod_annotation 4.0.7, riverpod_generator 4.0.9, go_router 18.0.1, Drift 2.35.0 (tests: `NativeDatabase.memory`), gen-l10n.

**Spec:** [`docs/superpowers/specs/2026-09-24-library-screens-design.md`](../specs/2026-09-24-library-screens-design.md). This phase covers §3, §4 (root only), §5, §6.1 (root), §6.2 (create root deck), §7, §8, §9 and §10 row 1.

## Global Constraints

- **UI only.** No file under `lib/features/*/{domain,data,di}/` changes, and neither does `lib/core/database/`.
- **Folders and names (ADR-011):**
  - `presentation/{screens,controllers,states,providers}` and `presentation/widgets/{sections,items,overlays,support}`, one level deep.
  - File suffixes: `_screen`, `_controller`, `_state`, `_provider`, `_widget`.
- **Imports:**
  - `presentation/` imports its own `domain/` and `di/`, `core/`, `shared/` and `l10n/`. It never imports `data/`.
  - No feature imports `app/`. Tests may import `data/` to build fixtures.
- **One use case per interaction (AD-12).**
- **Only the shared `Mx*` widgets and theme accessors.** The guard's design-system rules forbid `AppBar(`, `TextButton(`, `CircularProgressIndicator(`, `showModalBottomSheet`, `Icon(... color:)`, `ButtonStyle(`, `BorderSide(`, `RoundedRectangleBorder(`, `Card(`, `ListTile(`, `IconButton(` and `Checkbox(` in `presentation/`.
- **Guard rules on `lib/`:**
  - No hex values and no `Colors.*`.
  - No digit literals in `EdgeInsets`, `SizedBox`, `spacing:` or `BorderRadius.circular`.
  - No `TextStyle(`.
  - No `Text('…letters…')`, and no `label|title|tooltip|semanticLabel: '…'` literals.
  - Booleans read as predicates.
  - Files stay under 400 lines.
- **Copy:** every user string is in `lib/l10n/app_en.arb` and `app_vi.arb`, each with an `@description`. No message shows an id, path or SQL (BR-CORE-005). Failure copy says first that nothing was lost.
- **Generated files:** run `dart run build_runner build --delete-conflicting-outputs` after changing any `@riverpod` file and before running tests. `*.g.dart` is git-ignored and never committed. `flutter gen-l10n` runs as part of `flutter test` and `flutter run`, because `generate: true` is set.
- **Gate:** run it before every commit.
  - `dart format lib test` makes no changes.
  - `flutter analyze` is clean.
  - The guard `memox-v8` reports `Errors: 0 | Warnings: 0`.
- **End-of-phase gate** (Task 6): adds `flutter test`, `check_architecture.py`, the CI tooling tests, `tools/docs/check.py` and `dod_check.sh`.
- **Commits** use scope `ui`, `theme`, `deck` or `app`, and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Rulings made while planning

- **L1:** Phase 1 builds only the Library root.
  - `DeckLevelScreen` takes no `deckId` yet, and its rows have no tap and no chevron.
  - Phase 2 adds `deckId`, the breadcrumb and `onOpenDeck`.
- **L2:** The copy for a database `Failure` lives once, in `lib/l10n/failure_copy.dart`, as an extension on `AppLocalizations`. Both features use it. Nothing forbids `l10n/` from importing `core/`.
- **L3:** Every reason the create-root-deck dialog can meet is shown under the name field. `DeckRejection.blankName` and `nameTooLong` are the only reasons its use case returns.
- **L4:** When the level holds no decks, the list is the first-run empty state. When the due filter leaves nothing, a neutral empty state offers "Show all decks". The two differ by the filter, because a level whose decks have no cards has zero counts too.
- **L5:** The sort and filter chips name the current choice ("Sort: Manual"), so TalkBack reads what the chip does.
- **L6:** The status ink mixes toward `onSurface`, with these ratios:

  | | new | learning | reviewing | mastered |
  |---|---|---|---|---|
  | light | 0.40 | 0.50 | 0.25 | 0.25 |
  | dark | 0.40 | 0 | 0.10 | 0 |

  These are the smallest 0.05 steps measured to reach 4.5:1 on `surface`, `surfaceContainerLowest`, `surfaceContainer` and each one's 12% status tint.

## Review Focus

1. **Midnight while Library is open.**
   - Expected: counts move from due today to overdue with no write and no reload.
   - Pinned in Task 4.
2. **A deck created elsewhere while Library is open.**
   - Expected: it appears without a reload.
   - Pinned in Task 4.
3. **A double tap on Create.**
   - Expected: exactly one deck is created.
   - Pinned in Task 3.
4. **A database failure while creating.**
   - Expected: a plain snackbar, the dialog stays open, and nothing technical is shown.
   - Pinned in Task 3.
5. **A long Korean or Vietnamese deck name at 2x text.**
   - Expected: the row ellipsizes and nothing overflows.
   - Pinned in Task 4.

---

## File Structure

```
lib/core/theme/mx_derived_colors.dart            modify: four status inks
lib/shared/widgets/mx_status_badge.dart          modify: label in the ink
lib/shared/widgets/mx_workload_breakdown_line.dart  modify: new term in the ink
lib/l10n/app_en.arb, app_vi.arb                  modify: phase 1 strings
lib/l10n/failure_copy.dart                       create
lib/features/deck/presentation/
  providers/watch_deck_level_use_case_provider.dart
  providers/create_root_deck_use_case_provider.dart
  providers/deck_level_provider.dart
  states/deck_level_query_state.dart
  controllers/deck_actions_controller.dart
  screens/deck_level_screen.dart
  widgets/sections/deck_level_list_widget.dart
  widgets/sections/deck_level_header_widget.dart
  widgets/items/deck_row_widget.dart
  widgets/overlays/create_root_deck_dialog_widget.dart
  widgets/overlays/deck_level_query_sheets_widget.dart
  widgets/support/deck_rejection_copy_widget.dart
  widgets/support/deck_level_query_copy_widget.dart
  widgets/support/deck_workload_line_widget.dart
lib/app/router/app_router.dart                   modify: /decks → DeckLevelScreen
code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml  modify
test/support/library_harness.dart                create
test/core/theme/mx_derived_colors_test.dart      modify
test/shared/widgets/{mx_status_badge,mx_workload_breakdown_line}_test.dart  modify
test/l10n/failure_copy_test.dart                 create
test/features/deck/presentation/…_test.dart      create
test/features/deck/presentation/goldens/         create
test/app/app_test.dart, app_golden_test.dart     modify
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md  modify (§9 rows)
```

---

### Task 1: Status ink tokens

**Files:**
- Modify: `lib/core/theme/mx_derived_colors.dart`, `lib/shared/widgets/mx_status_badge.dart`, `lib/shared/widgets/mx_workload_breakdown_line.dart`
- Test: `test/core/theme/mx_derived_colors_test.dart`, `test/shared/widgets/mx_status_badge_test.dart`, `test/shared/widgets/mx_workload_breakdown_line_test.dart`

**Interfaces:**
- Produces: `MxDerivedColors.statusNewInk`, `statusLearningInk`, `statusReviewingInk`, `statusMasteredInk` (all `Color`).

- [ ] **Step 1: Write the failing tests**

Append to `test/core/theme/mx_derived_colors_test.dart`, inside `main`. Add `import 'package:memox/core/theme/app_color_schemes.dart';` and `import 'package:memox/core/theme/mx_semantic_colors.dart';` if they are missing.

```dart
  test('status inks reach 4.5:1 on every ground and tint (L6)', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (hi, lo) = la > lb ? (la, lb) : (lb, la);
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      for (final (status, ink) in [
        (semantic.statusNew, derived.statusNewInk),
        (semantic.statusLearning, derived.statusLearningInk),
        (semantic.statusReviewing, derived.statusReviewingInk),
        (semantic.statusMastered, derived.statusMasteredInk),
      ]) {
        for (final ground in [
          scheme.surface,
          scheme.surfaceContainerLowest,
          scheme.surfaceContainer,
        ]) {
          final tint = Color.alphaBlend(status.withValues(alpha: 0.12), ground);
          expect(ratio(ink, ground), greaterThanOrEqualTo(4.5));
          expect(ratio(ink, tint), greaterThanOrEqualTo(4.5));
        }
      }
    }
  });
```

In `test/shared/widgets/mx_status_badge_test.dart`, add `import 'package:memox/core/theme/app_color_schemes.dart';` and `import 'package:memox/core/theme/mx_derived_colors.dart';`. Then replace the test `'the status fixes the dot, label and 12% fill'` with:

```dart
  testWidgets('the status fixes the dot and fill; the label is its ink', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(AppColorSchemes.light, semantic);
    for (final (status, color, ink) in [
      (MxCardStatus.newCard, semantic.statusNew, derived.statusNewInk),
      (
        MxCardStatus.learning,
        semantic.statusLearning,
        derived.statusLearningInk,
      ),
      (
        MxCardStatus.reviewing,
        semantic.statusReviewing,
        derived.statusReviewingInk,
      ),
      (
        MxCardStatus.mastered,
        semantic.statusMastered,
        derived.statusMasteredInk,
      ),
    ]) {
      await pumpMx(tester, MxStatusBadge(status: status, label: 'State'));
      final pill = find
          .descendant(
            of: find.byType(MxStatusBadge),
            matching: find.byType(DecoratedBox),
          )
          .first;

      expect(_fill(tester, pill), color.withValues(alpha: 0.12));
      expect(_fill(tester, find.byKey(_dotKey)), color);
      expect(tester.widget<Text>(find.text('State')).style!.color, ink);
    }
  });
```

In `test/shared/widgets/mx_workload_breakdown_line_test.dart`, change the expectation `expect(_termStyle(tester, '2 new')!.color, semantic.statusNew);` to `expect(_termStyle(tester, '2 new')!.color, derived.statusNewInk);`. The test's `main` already declares `derived` (`MxDerivedColors.resolve(scheme, semantic)`).

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/mx_derived_colors_test.dart test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_workload_breakdown_line_test.dart`
Expected: FAIL to compile, because `statusNewInk` is not defined.

- [ ] **Step 3: Implement**

In `lib/core/theme/mx_derived_colors.dart`:
- Add four `required this.status…Ink,` parameters to the private constructor after `required this.warningInk,`.
- In `resolve`, after `warningInk: …,`, add:

```dart
      // Status TEXT (StatusBadge label, the workload "new" term): the
      // status colour pulled toward onSurface until it reads at 4.5:1 on
      // every ground and on its own 12% tint (library spec §7, ruling L6).
      // Dots, fills and tints keep the status colour itself.
      statusNewInk: _ink(semantic.statusNew, scheme, isDark ? _newInkDark : _newInkLight),
      statusLearningInk: _ink(
        semantic.statusLearning,
        scheme,
        isDark ? _learningInkDark : _learningInkLight,
      ),
      statusReviewingInk: _ink(
        semantic.statusReviewing,
        scheme,
        isDark ? _reviewingInkDark : _reviewingInkLight,
      ),
      statusMasteredInk: _ink(
        semantic.statusMastered,
        scheme,
        isDark ? _masteredInkDark : _masteredInkLight,
      ),
```

- Add after the ghost-border ratios:

```dart
  static const double _newInkLight = 0.40;
  static const double _newInkDark = 0.40;
  static const double _learningInkLight = 0.50;
  static const double _learningInkDark = 0;
  static const double _reviewingInkLight = 0.25;
  static const double _reviewingInkDark = 0.10;
  static const double _masteredInkLight = 0.25;
  static const double _masteredInkDark = 0;

  static Color _ink(Color status, ColorScheme scheme, double mix) =>
      Color.lerp(status, scheme.onSurface, mix)!;
```

- Add the fields after `warningInk`:

```dart
  /// Status TEXT inks (StatusBadge label, WorkloadBreakdownLine new term),
  /// never the status dot or fill.
  final Color statusNewInk;
  final Color statusLearningInk;
  final Color statusReviewingInk;
  final Color statusMasteredInk;
```

In `lib/shared/widgets/mx_status_badge.dart`, in `build`:
- After `final color = switch (status) { … };`, add:

```dart
    final derived = context.derivedColors;
    // The label reads in the status ink (AA); dot and fill keep the colour.
    final ink = switch (status) {
      MxCardStatus.newCard => derived.statusNewInk,
      MxCardStatus.learning => derived.statusLearningInk,
      MxCardStatus.reviewing => derived.statusReviewingInk,
      MxCardStatus.mastered => derived.statusMasteredInk,
    };
```

- Change the pill label's `style: context.textStyles.badgeLabel(color)` to `style: context.textStyles.badgeLabel(ink)`.

In `lib/shared/widgets/mx_workload_breakdown_line.dart`, change `(newCount, newLabel, context.semanticColors.statusNew),` to `(newCount, newLabel, context.derivedColors.statusNewInk),`.

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/core/theme test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_workload_breakdown_line_test.dart`
Expected: PASS.

- [ ] **Step 5: Regenerate the changed goldens, look, gate, commit**

```bash
flutter test --tags golden test/shared/widgets test/app
```

Expected: the only failures are `mx_badges_tags` and `mx_workload_donut` in `status_widgets_golden_test.dart`, plus `app_gallery_*` if the gallery's first screen shows a status badge. Treat any other failure as a finding.

```bash
flutter test --update-goldens --tags golden test/shared/widgets test/app
flutter test --tags golden test/shared/widgets test/app
```

Delete any `failures/` folder the run leaves. Open `mx_badges_tags_light.png`: the status labels are darker than their dots, and the dots and fills are unchanged. Open `mx_workload_donut_light.png`: the "new" term is darker than before, and the donuts are unchanged.

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme lib/shared/widgets test/core/theme test/shared/widgets test/app
git commit -m "feat(theme): status inks bring status text to AA

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Presentation plumbing, copy and the screen harness

**Files:**
- Create:
  - `lib/features/deck/presentation/providers/watch_deck_level_use_case_provider.dart`
  - `lib/features/deck/presentation/providers/create_root_deck_use_case_provider.dart`
  - `lib/features/deck/presentation/providers/deck_level_provider.dart`
  - `lib/features/deck/presentation/states/deck_level_query_state.dart`
  - `lib/features/deck/presentation/controllers/deck_actions_controller.dart`
  - `lib/features/deck/presentation/widgets/support/deck_rejection_copy_widget.dart`
  - `lib/features/deck/presentation/widgets/support/deck_level_query_copy_widget.dart`
  - `lib/l10n/failure_copy.dart`
  - `test/support/library_harness.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
- Test: `test/features/deck/presentation/deck_level_provider_test.dart`, `test/features/deck/presentation/deck_actions_controller_test.dart`, `test/features/deck/presentation/deck_copy_test.dart`, `test/l10n/failure_copy_test.dart`

**Interfaces:**
- Produces:
  - `watchDeckLevelUseCaseProvider` → `WatchDeckLevelUseCase`
  - `createRootDeckUseCaseProvider` → `CreateRootDeckUseCase`
  - `deckLevelProvider({String? parentId, DeckLevelSort sort = DeckLevelSort.manual, DeckLevelFilter filter = DeckLevelFilter.all})` → `AsyncValue<DeckLevel>`
  - `deckLevelQueryProvider` → `DeckLevelQueryState(sort, filter)`, with notifier methods `sortBy(DeckLevelSort)` and `show(DeckLevelFilter)`
  - `deckActionsControllerProvider.notifier.createRootDeck({required String name, required SchedulerType schedulerType})` → `Future<Outcome<DeckEntity, DeckRejection>>`, which throws `Failure` on a database error
  - `AppLocalizations.deckRejection(DeckRejection)`, `.deckSort(DeckLevelSort)`, `.deckFilter(DeckLevelFilter)` and `.failure(Failure)` → `String`
  - Test harness: `libraryTest(description, body(tester, env))`, `LibraryEnv { db, clock, decks }`, `pumpLibraryScreen(tester, env, screen, {brightness, textScale, locale, overrides})`, `pumpLibraryGolden(tester, env, screen, brightness)` and `libraryToday`

- [ ] **Step 1: Add the phase 1 strings**

Add these keys to `lib/l10n/app_en.arb`, each followed by its `@key` entry holding a `description` (and `placeholders` where the value has one). Add the same keys with the Vietnamese values to `lib/l10n/app_vi.arb`, without the `@` entries, following the file's existing pattern.

| Key | English | Vietnamese | Placeholders |
|---|---|---|---|
| `commonCancel` | Cancel | Hủy | |
| `commonRetry` | Retry | Thử lại | |
| `libraryDecksHeader` | Decks | Bộ thẻ | |
| `libraryCreateDeck` | Create deck | Tạo bộ thẻ | |
| `libraryEmptyTitle` | No decks yet | Chưa có bộ thẻ nào | |
| `libraryEmptyBody` | Create a deck, then add the words you want to remember. | Tạo một bộ thẻ, rồi thêm những từ bạn muốn nhớ. | |
| `libraryNothingDueTitle` | Nothing due | Không có gì đến hạn | |
| `libraryNothingDueBody` | No deck has cards to review today. | Hôm nay không bộ thẻ nào có thẻ cần ôn. | |
| `libraryShowAllDecks` | Show all decks | Hiện mọi bộ thẻ | |
| `libraryLoadErrorTitle` | Couldn't load your decks | Không tải được bộ thẻ | |
| `libraryLoadErrorBody` | Nothing was lost. Try again in a moment. | Không mất dữ liệu nào. Hãy thử lại sau giây lát. | |
| `workloadOverdue` | {count} overdue | {count} quá hạn | `count`: int |
| `workloadToday` | {count} today | {count} hôm nay | `count`: int |
| `workloadNew` | {count} new | {count} mới | `count`: int |
| `workloadNothingDue` | {count, plural, =1{1 card · nothing due} other{{count} cards · nothing due}} | {count} thẻ · không có gì đến hạn | `count`: int |
| `workloadNoCards` | No cards yet | Chưa có thẻ | |
| `deckSortTitle` | Sort decks | Sắp xếp bộ thẻ | |
| `deckSortTrigger` | Sort: {order} | Sắp xếp: {order} | `order`: String |
| `deckSortManual` | Manual | Thủ công | |
| `deckSortName` | Name | Tên | |
| `deckSortRecent` | Newest | Mới tạo | |
| `deckSortDue` | Most due | Nhiều thẻ đến hạn | |
| `deckFilterTitle` | Show | Hiển thị | |
| `deckFilterTrigger` | Show: {filter} | Hiển thị: {filter} | `filter`: String |
| `deckFilterAll` | All decks | Mọi bộ thẻ | |
| `deckFilterDue` | Due decks | Bộ thẻ đến hạn | |
| `deckCreateRootTitle` | New deck | Bộ thẻ mới | |
| `deckNameHint` | Deck name | Tên bộ thẻ | |
| `deckSchedulerEightBox` | Eight box | Tám hộp | |
| `deckSchedulerSm2` | SM-2 | SM-2 | |
| `deckSchedulerNote` | The scheduler locks after the first review. Changing it later resets learning progress. | Thuật toán sẽ khóa sau lần ôn đầu tiên. Đổi về sau sẽ đặt lại tiến độ học. | |
| `deckCreateConfirm` | Create | Tạo | |
| `deckRejectionBlankName` | Enter a name. | Hãy nhập tên. | |
| `deckRejectionNameTooLong` | Keep the name to 200 characters. | Tên dài tối đa 200 ký tự. | |
| `deckRejectionDepthExceeded` | Decks nest 10 levels deep at most. | Bộ thẻ lồng nhau tối đa 10 cấp. | |
| `deckRejectionNotADeckContainer` | This deck holds cards, so it can't hold decks. | Bộ thẻ này chứa thẻ nên không chứa được bộ thẻ con. | |
| `deckRejectionNotACardContainer` | This deck holds decks, so it can't hold cards. | Bộ thẻ này chứa bộ thẻ con nên không chứa được thẻ. | |
| `deckRejectionSubtreeSchedulerMismatch` | That deck uses a different scheduler. | Bộ thẻ đó dùng thuật toán khác. | |
| `deckRejectionMovingIntoOwnSubtree` | A deck can't move inside itself. | Không thể chuyển bộ thẻ vào bên trong chính nó. | |
| `deckRejectionRootCannotMove` | A top-level deck can't be moved. | Không thể di chuyển bộ thẻ cấp cao nhất. | |
| `deckRejectionNotFound` | This deck no longer exists. | Bộ thẻ này không còn nữa. | |
| `deckRejectionNotSiblings` | The order changed. Try again. | Thứ tự đã thay đổi. Hãy thử lại. | |
| `deckRejectionSameParent` | The deck is already there. | Bộ thẻ đã ở đó rồi. | |
| `failureConstraint` | Nothing was saved: the change breaks a data rule. | Chưa lưu gì: thay đổi này vi phạm một quy tắc dữ liệu. | |
| `failureBusy` | Nothing was lost. The data is busy, so try again. | Không mất dữ liệu nào. Dữ liệu đang bận, hãy thử lại. | |
| `failureUnknown` | Nothing was lost, but something went wrong. Try again. | Không mất dữ liệu nào, nhưng đã có lỗi. Hãy thử lại. | |

Example of an entry with a placeholder in `app_en.arb`:

```json
  "workloadOverdue": "{count} overdue",
  "@workloadOverdue": {
    "description": "Workload term: cards past their due day.",
    "placeholders": { "count": { "type": "int" } }
  },
```

Run: `flutter test test/app/l10n_test.dart`
Expected: PASS. The parity test checks that every template key has a description and a Vietnamese value.

- [ ] **Step 2: Write the failing tests**

`test/support/library_harness.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_day_clock.dart';
import 'golden_harness.dart';
import 'test_database.dart';

/// The day every Library test lives in: 2026-09-24, mid-morning local time.
final DateTime libraryToday = DateTime(2026, 9, 24, 9);

/// The real backend behind a screen: an in-memory database, a day moved by
/// hand, and the deck repository for fixtures.
final class LibraryEnv {
  LibraryEnv(this.db, this.clock) : decks = DeckRepositoryImpl(db);

  final AppDatabase db;
  final FakeDayClock clock;
  final DeckRepository decks;
}

/// A widget test over [LibraryEnv]. The widget tree is torn down before the
/// database closes, so no Drift stream outlives the test.
void libraryTest(
  String description,
  Future<void> Function(WidgetTester tester, LibraryEnv env) body,
) {
  testWidgets(description, (tester) async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(tester, env);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await env.db.close();
    }
  });
}

List<Override> _backend(LibraryEnv env) => [
  databaseProvider.overrideWithValue(env.db),
  dayClockProvider.overrideWithValue(env.clock),
];

Widget _app(
  LibraryEnv env,
  Widget screen, {
  required Brightness brightness,
  required double textScale,
  required Locale locale,
  required List<Override> overrides,
}) => ProviderScope(
  overrides: [..._backend(env), ...overrides],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    themeAnimationDuration: Duration.zero,
    theme: brightness == Brightness.light
        ? buildLightTheme()
        : buildDarkTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    ),
  ),
);

/// Pumps [screen] on a 360×800 phone over the real backend and lets its
/// first streams emit.
Future<void> pumpLibraryScreen(
  WidgetTester tester,
  LibraryEnv env,
  Widget screen, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      env,
      screen,
      brightness: brightness,
      textScale: textScale,
      locale: locale,
      overrides: overrides,
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// [screen] over the real backend at 1080×2400 (3x), inside the golden
/// boundary. Compare with [expectBoundaryGolden] inside [withRealShadows].
Future<void> pumpLibraryGolden(
  WidgetTester tester,
  LibraryEnv env,
  Widget screen,
  Brightness brightness, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: goldenBoundaryKey,
      child: _app(
        env,
        screen,
        brightness: brightness,
        textScale: 1,
        locale: const Locale('en'),
        overrides: overrides,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
```

`test/features/deck/presentation/deck_level_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

ProviderContainer _container(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<List<String>> names(
    ProviderContainer container, {
    DeckLevelSort sort = DeckLevelSort.manual,
    DeckLevelFilter filter = DeckLevelFilter.all,
  }) async {
    final provider = deckLevelProvider(sort: sort, filter: filter);
    container.listen(provider, (_, _) {});
    final level = await container.read(provider.future);
    return [for (final tile in level.tiles) tile.name];
  }

  test('the roots arrive as one level, in manual order', () async {
    final decks = DeckRepositoryImpl(db);
    await decks.root('Korean');
    await decks.root('Kanji');

    expect(await names(_container(db)), ['Korean', 'Kanji']);
  });

  test('sort and filter reach the use case', () async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('b Korean');
    await decks.root('A Kanji');
    final words = await decks.sub(korean.id, 'Words');
    await insertCard(
      db,
      id: 'due',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24),
    );
    final container = _container(db);

    expect(
      await names(container, sort: DeckLevelSort.name),
      ['A Kanji', 'b Korean'],
    );
    expect(
      await names(container, filter: DeckLevelFilter.due),
      ['b Korean'],
    );
  });

  test('the level query starts manual and all, and changes on demand', () {
    final container = _container(db);
    final notifier = container.read(deckLevelQueryProvider.notifier);

    expect(container.read(deckLevelQueryProvider).sort, DeckLevelSort.manual);
    notifier
      ..sortBy(DeckLevelSort.due)
      ..show(DeckLevelFilter.due);
    final query = container.read(deckLevelQueryProvider);
    expect((query.sort, query.filter), (DeckLevelSort.due, DeckLevelFilter.due));
  });
}
```

`test/features/deck/presentation/deck_actions_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> deckCount() async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
          .read<int>('n');

  test('createRootDeck hands back the new deck', () async {
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .createRootDeck(name: 'Korean', schedulerType: SchedulerType.sm2);

    expect(outcome, isA<Ok<Object?, DeckRejection>>());
    expect(await deckCount(), 1);
  });

  test('a blank name is refused and nothing is written', () async {
    final before = await totalChanges(db);
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .createRootDeck(name: '   ', schedulerType: SchedulerType.eightBox);

    expect(
      outcome,
      isA<Rejected<Object?, DeckRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        DeckRejection.blankName,
      ),
    );
    expect(await totalChanges(db), before);
  });
}
```

`test/features/deck/presentation/deck_copy_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_copy_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_copy_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

final _technical = RegExp(r'sql|sqlite|exception|/|\\|null|[0-9a-f]{8}-', caseSensitive: false);

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);

    test('every deck rejection has plain ${locale.languageCode} copy', () {
      for (final reason in DeckRejection.values) {
        final copy = l10n.deckRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
    });

    test('every sort and filter has ${locale.languageCode} copy', () {
      for (final sort in DeckLevelSort.values) {
        expect(l10n.deckSort(sort).trim(), isNotEmpty);
      }
      for (final filter in DeckLevelFilter.values) {
        expect(l10n.deckFilter(filter).trim(), isNotEmpty);
      }
    });
  }
}
```

`test/l10n/failure_copy_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/l10n/failure_copy.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    test('each failure reads as plain ${locale.languageCode} copy', () {
      final l10n = lookupAppLocalizations(locale);
      final failures = [
        const ConstraintFailure(cause: 'CHECK constraint failed: deck'),
        const DatabaseLockedFailure(cause: 'database is locked'),
        const UnknownDatabaseFailure(cause: '/data/app/memox.sqlite'),
      ];

      for (final failure in failures) {
        final copy = l10n.failure(failure);
        expect(copy.trim(), isNotEmpty);
        expect(copy, isNot(contains('/')));
        expect(copy.toLowerCase(), isNot(contains('sql')));
        expect(copy.toLowerCase(), isNot(contains('constraint failed')));
      }
    });
  }
}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation test/l10n/failure_copy_test.dart`
Expected: FAIL to compile, because the presentation files and `failure_copy.dart` do not exist.

- [ ] **Step 4: Implement**

`lib/features/deck/presentation/providers/watch_deck_level_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_level_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_level_use_case_provider.g.dart';

@riverpod
WatchDeckLevelUseCase watchDeckLevelUseCase(Ref ref) => WatchDeckLevelUseCase(
  ref.watch(deckRepositoryProvider),
  ref.watch(dayClockProvider),
);
```

`lib/features/deck/presentation/providers/create_root_deck_use_case_provider.dart`:

```dart
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_root_deck_use_case_provider.g.dart';

@riverpod
CreateRootDeckUseCase createRootDeckUseCase(Ref ref) =>
    CreateRootDeckUseCase(ref.watch(deckRepositoryProvider));
```

`lib/features/deck/presentation/providers/deck_level_provider.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_level_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_level_provider.g.dart';

/// A level of the deck tree with its counts, the roots when [parentId] is
/// null (UC-DECK-003). It emits again on every change and at each local
/// midnight.
@riverpod
Stream<DeckLevel> deckLevel(
  Ref ref, {
  String? parentId,
  DeckLevelSort sort = DeckLevelSort.manual,
  DeckLevelFilter filter = DeckLevelFilter.all,
}) => ref.watch(watchDeckLevelUseCaseProvider)(
  parentId: parentId,
  sort: sort,
  filter: filter,
);
```

`lib/features/deck/presentation/states/deck_level_query_state.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_level_query_state.g.dart';

/// What the person asked the Library level for: its order and which decks
/// show (UC-DECK-003, UC-DECK-006).
final class DeckLevelQueryState {
  const DeckLevelQueryState({
    this.sort = DeckLevelSort.manual,
    this.filter = DeckLevelFilter.all,
  });

  final DeckLevelSort sort;
  final DeckLevelFilter filter;
}

/// The Library level's query, kept while the screen lives.
@riverpod
class DeckLevelQuery extends _$DeckLevelQuery {
  @override
  DeckLevelQueryState build() => const DeckLevelQueryState();

  void sortBy(DeckLevelSort sort) =>
      state = DeckLevelQueryState(sort: sort, filter: state.filter);

  void show(DeckLevelFilter filter) =>
      state = DeckLevelQueryState(sort: state.sort, filter: filter);
}
```

`lib/features/deck/presentation/controllers/deck_actions_controller.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/providers/create_root_deck_use_case_provider.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_actions_controller.g.dart';

/// The deck writes the Library triggers.
///
/// Each command calls exactly one use case (AD-12) and hands back its
/// `Outcome`, and the widget chooses the feedback. A database `Failure` is
/// thrown through for the widget to show. The controller holds no state.
@riverpod
class DeckActionsController extends _$DeckActionsController {
  @override
  void build() {}

  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
  }) => ref.read(createRootDeckUseCaseProvider)(
    name: name,
    schedulerType: schedulerType,
  );
}
```

`lib/features/deck/presentation/widgets/support/deck_rejection_copy_widget.dart`:

```dart
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason the deck feature refuses a write (BR-CORE-005).
/// Exhaustive with no default, so a new reason fails to compile until it has
/// copy.
extension DeckRejectionCopy on AppLocalizations {
  String deckRejection(DeckRejection reason) => switch (reason) {
    DeckRejection.blankName => deckRejectionBlankName,
    DeckRejection.nameTooLong => deckRejectionNameTooLong,
    DeckRejection.depthExceeded => deckRejectionDepthExceeded,
    DeckRejection.notADeckContainer => deckRejectionNotADeckContainer,
    DeckRejection.notACardContainer => deckRejectionNotACardContainer,
    DeckRejection.subtreeSchedulerMismatch =>
      deckRejectionSubtreeSchedulerMismatch,
    DeckRejection.movingIntoOwnSubtree => deckRejectionMovingIntoOwnSubtree,
    DeckRejection.rootCannotMove => deckRejectionRootCannotMove,
    DeckRejection.notFound => deckRejectionNotFound,
    DeckRejection.notSiblings => deckRejectionNotSiblings,
    DeckRejection.sameParent => deckRejectionSameParent,
  };
}
```

`lib/features/deck/presentation/widgets/support/deck_level_query_copy_widget.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Names of the Library's sort orders and filters.
extension DeckLevelQueryCopy on AppLocalizations {
  String deckSort(DeckLevelSort sort) => switch (sort) {
    DeckLevelSort.manual => deckSortManual,
    DeckLevelSort.name => deckSortName,
    DeckLevelSort.recent => deckSortRecent,
    DeckLevelSort.due => deckSortDue,
  };

  String deckFilter(DeckLevelFilter filter) => switch (filter) {
    DeckLevelFilter.all => deckFilterAll,
    DeckLevelFilter.due => deckFilterDue,
  };
}
```

`lib/l10n/failure_copy.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The copy a database [Failure] shows (ruling L2). It never shows the
/// failure's cause, and it says first that nothing was lost where that is
/// true (PRODUCT.md, Brand commitments; BR-CORE-005).
extension FailureCopy on AppLocalizations {
  String failure(Failure failure) => switch (failure) {
    ConstraintFailure() => failureConstraint,
    DatabaseLockedFailure() => failureBusy,
    UnknownDatabaseFailure() => failureUnknown,
  };
}
```

- [ ] **Step 5: Generate, run, and retire the presentation waiting list**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation test/l10n/failure_copy_test.dart test/app/l10n_test.dart
```

Expected: PASS.

```bash
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: one `guard.config.stale_targets_pending` warning for each rule whose `targets_pending: presentation` entry now has a target in `lib/features/*/presentation/`.
- For every rule the guard names that way, delete its entry (the rule id line and its `targets_pending: presentation` line) from `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.
- Keep entries the guard does not name.
- Delete the `# -- \`presentation\`` comment line only when no entry of that group is left.

Then run the guard again.
Expected: `Errors: 0 | Warnings: 0`. A rule that now reports an error on the new files is a finding: fix the code, never the rule.

- [ ] **Step 6: Gate and commit**

```bash
dart format lib test
flutter analyze
flutter test test/features/deck/presentation test/l10n test/app/l10n_test.dart
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/l10n lib/features/deck/presentation test/support/library_harness.dart test/features/deck/presentation test/l10n code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(deck): Library presentation plumbing, copy and screen harness

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The create-root-deck dialog

**Files:**
- Create: `lib/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart`
- Test: `test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`

**Interfaces:**
- Consumes: `deckActionsControllerProvider`, `AppLocalizations.deckRejection`, `AppLocalizations.failure`, `showMxDialog`, `MxDialog`, `MxTextField`, `MxSegmentedTray`, `MxNote`, `MxSheetActions`, `showMxSnackbar`.
- Produces: `Future<DeckEntity?> showCreateRootDeckDialog(BuildContext context)`.

- [ ] **Step 1: Write the failing test**

`test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/create_root_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host() => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showCreateRootDeckDialog(context),
    ),
  ),
);

Future<List<(String, String)>> _decks(LibraryEnv env) async => [
  for (final row in await env.db
      .customSelect('SELECT name, scheduler_type FROM deck')
      .get())
    (row.read<String>('name'), row.read<String>('scheduler_type')),
];

/// A create use case that fails the first way a real database can.
final class _FailingCreate implements CreateRootDeckUseCase {
  @override
  Future<Outcome<DeckEntity, DeckRejection>> call({
    required String name,
    required SchedulerType schedulerType,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
}

/// A create use case that stays pending until [release].
final class _SlowCreate implements CreateRootDeckUseCase {
  _SlowCreate(this._real);

  final CreateRootDeckUseCase _real;
  final _gate = Completer<void>();
  int calls = 0;

  void release() => _gate.complete();

  @override
  Future<Outcome<DeckEntity, DeckRejection>> call({
    required String name,
    required SchedulerType schedulerType,
  }) async {
    calls++;
    await _gate.future;
    return _real(name: name, schedulerType: schedulerType);
  }
}

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  libraryTest('a blank name is refused under the field; nothing is written', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
    expect(find.byType(MxDialog), findsOneWidget);
    expect(await _decks(env), isEmpty);
  });

  libraryTest('a name longer than 200 characters is refused', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'a' * 201);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckRejectionNameTooLong), findsOneWidget);
  });

  libraryTest('a name and SM-2 create a root deck and close the dialog', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);
    await tester.enterText(find.byType(EditableText), '  Korean  ');
    await tester.tap(find.text(_en.deckSchedulerSm2));
    await tester.pump();
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(await _decks(env), [('Korean', 'sm2')]);
  });

  libraryTest('a double tap on Create makes one deck (RF3)', (
    tester,
    env,
  ) async {
    final slow = _SlowCreate(CreateRootDeckUseCase(env.decks));
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [createRootDeckUseCaseProvider.overrideWithValue(slow)],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pump();
    await tester.tap(find.text(_en.deckCreateConfirm), warnIfMissed: false);
    await tester.pump();
    slow.release();
    await tester.pumpAndSettle();

    expect(slow.calls, 1);
    expect(await _decks(env), hasLength(1));
  });

  libraryTest('a database failure keeps the dialog and says so plainly (RF4)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [
        createRootDeckUseCaseProvider.overrideWithValue(_FailingCreate()),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('the dialog meets the target guidelines', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host());
    await open(tester);

    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`
Expected: FAIL to compile, because `create_root_deck_dialog_widget.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_copy_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_copy.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Opens the new-deck dialog (UC-DECK-001). It completes with the created
/// deck, or with null when the person cancels.
Future<DeckEntity?> showCreateRootDeckDialog(BuildContext context) =>
    showMxDialog<DeckEntity>(
      context,
      builder: (_) => const CreateRootDeckDialogWidget(),
    );

/// A root deck's name and the scheduler its cards will follow. The scheduler
/// locks after the first review, so the choice is explained up front.
class CreateRootDeckDialogWidget extends ConsumerStatefulWidget {
  const CreateRootDeckDialogWidget({super.key});

  @override
  ConsumerState<CreateRootDeckDialogWidget> createState() =>
      _CreateRootDeckDialogWidgetState();
}

class _CreateRootDeckDialogWidgetState
    extends ConsumerState<CreateRootDeckDialogWidget> {
  final _name = TextEditingController();
  var _scheduler = SchedulerType.eightBox;
  DeckRejection? _rejection;

  /// One create at a time: a second tap while the first runs does nothing.
  var _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _rejection = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .createRootDeck(name: _name.text, schedulerType: _scheduler);
      if (!mounted) return;
      switch (outcome) {
        case Ok(:final value):
          Navigator.of(context).pop(value);
        // Ruling L3: both reasons this use case returns are about the name.
        case Rejected(:final reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.deckCreateRootTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          MxTextField(
            controller: _name,
            hintText: l10n.deckNameHint,
            errorText: switch (_rejection) {
              null => null,
              final reason => l10n.deckRejection(reason),
            },
            textInputAction: TextInputAction.done,
          ),
          MxSegmentedTray<SchedulerType>(
            segments: [
              MxSegment(
                value: SchedulerType.eightBox,
                label: l10n.deckSchedulerEightBox,
              ),
              MxSegment(value: SchedulerType.sm2, label: l10n.deckSchedulerSm2),
            ],
            selected: _scheduler,
            onSelected: (type) => setState(() => _scheduler = type),
          ),
          MxNote(text: l10n.deckSchedulerNote),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.deckCreateConfirm,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`
Expected: PASS, 6 tests.

`_FailingCreate` and `_SlowCreate` implement `CreateRootDeckUseCase`, a `final class` declared in `lib/`. Dart forbids implementing a `final class` outside its library. If the compiler refuses:
- Build `_SlowCreate` as `CreateRootDeckUseCase(_GatedDeckRepository(env.decks))`, where `_GatedDeckRepository implements DeckRepository` and awaits the gate inside `createRootDeck`, forwarding every other member with `noSuchMethod`.
- Build `_FailingCreate` the same way, with a repository whose `createRootDeck` throws the failure.
- Record this as a test-only ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/deck/presentation test/features/deck/presentation
git commit -m "feat(deck): the create-root-deck dialog

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The Library root screen

**Files:**
- Create:
  - `lib/features/deck/presentation/screens/deck_level_screen.dart`
  - `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart`
  - `lib/features/deck/presentation/widgets/sections/deck_level_header_widget.dart`
  - `lib/features/deck/presentation/widgets/items/deck_row_widget.dart`
  - `lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart`
  - `lib/features/deck/presentation/widgets/support/deck_workload_line_widget.dart`
- Test: `test/features/deck/presentation/deck_level_screen_test.dart`, `test/features/deck/presentation/deck_level_screen_golden_test.dart`

**Interfaces:**
- Consumes: `deckLevelProvider`, `deckLevelQueryProvider`, `showCreateRootDeckDialog`, `AppLocalizations.deckSort`/`deckFilter`, and the shared widgets.
- Produces: `DeckLevelScreen()`, a `ConsumerWidget`. It owns its `MxAppShell`, app bar and FAB.

- [ ] **Step 1: Write the failing tests**

`test/features/deck/presentation/deck_level_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

Finder _rich(String text) => find.text(text, findRichText: true);

/// Korean holds one overdue, one due-today and one new card; Kanji is empty.
Future<void> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  await env.decks.root('Kanji');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(
    env.db,
    id: 'late',
    deckId: words.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 22),
  );
  await insertCard(
    env.db,
    id: 'today',
    deckId: words.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  await insertCard(env.db, id: 'new', deckId: words.id);
}

void main() {
  libraryTest('first run: an empty Library offers to create a deck', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());

    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.text(_en.libraryCreateDeck),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
  });

  libraryTest('the level line leads; each deck carries its own workload', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());

    // The level line and the Korean row say the same.
    expect(_rich('1 overdue · 1 today · 1 new'), findsNWidgets(2));
    expect(_rich(_en.workloadNoCards), findsOneWidget);
    expect(
      tester.getTopLeft(_rich('1 overdue · 1 today · 1 new').first).dy,
      lessThan(tester.getTopLeft(find.text('Korean')).dy),
    );
  });

  libraryTest('the FAB opens the create dialog', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
  });

  libraryTest('sort by name reorders the decks', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await tester.tap(find.text(_en.deckSortTrigger(_en.deckSortManual)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckSortName));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Kanji')).dy,
      lessThan(tester.getTopLeft(find.text('Korean')).dy),
    );
    expect(find.text(_en.deckSortTrigger(_en.deckSortName)), findsOneWidget);
  });

  libraryTest('the due filter hides idle decks and says so when none is left', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await tester.tap(find.text(_en.deckFilterTrigger(_en.deckFilterAll)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckFilterDue));
    await tester.pumpAndSettle();

    expect(find.text('Kanji'), findsNothing);
    expect(find.text(_en.libraryNothingDueTitle), findsOneWidget);
    await tester.tap(find.text(_en.libraryShowAllDecks));
    await tester.pumpAndSettle();
    expect(find.text('Kanji'), findsOneWidget);
  });

  libraryTest('a deck made elsewhere appears without a reload (RF2)', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    await env.decks.root('Hanja');
    await tester.pump();
    await tester.pump();

    expect(find.text('Hanja'), findsOneWidget);
  });

  libraryTest('midnight turns Due today into Overdue with no write (RF1)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());
    env.clock.startDay(DateTime(2026, 9, 25));
    await tester.pump();
    await tester.pump();

    expect(_rich('2 overdue · 1 new'), findsNWidgets(2));
  });

  libraryTest('loading shows skeleton rows', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const DeckLevelScreen(),
      overrides: [
        deckLevelProvider().overrideWith(
          (ref) => StreamController<DeckLevel>().stream,
        ),
      ],
    );

    expect(find.byType(MxSkeletonRow), findsWidgets);
  });

  libraryTest('a load error offers Retry, in plain words', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const DeckLevelScreen(),
      overrides: [
        deckLevelProvider().overrideWith(
          (ref) => Stream<DeckLevel>.error(StateError('disk I/O error')),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.libraryLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.textContaining('disk'), findsNothing);
  });

  libraryTest('a long Korean name at 2x ellipsizes without overflow (RF5)', (
    tester,
    env,
  ) async {
    await env.decks.root(List.filled(12, '한국어 어휘 공부').join(' '));
    await pumpLibraryScreen(
      tester,
      env,
      const DeckLevelScreen(),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });

  libraryTest('meets the target guidelines', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, const DeckLevelScreen());

    await expectAccessibleTargets(tester);
  });

  libraryTest('Vietnamese names the header in Vietnamese', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      const DeckLevelScreen(),
      locale: const Locale('vi'),
    );

    expect(find.text(_vi.libraryDecksHeader.toUpperCase()), findsOneWidget);
  });
}
```

`test/features/deck/presentation/deck_level_screen_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

void main() {
  for (final brightness in Brightness.values) {
    libraryTest('Library with decks, ${brightness.name}', (tester, env) async {
      final korean = await env.decks.root('Korean');
      await env.decks.root('Kanji N5');
      await env.decks.root('Hanja');
      final words = await env.decks.sub(korean.id, 'Words');
      for (var i = 0; i < 3; i++) {
        await insertCard(
          env.db,
          id: 'late$i',
          deckId: words.id,
          learnedAt: DateTime(2026, 9, 1),
          dueAt: DateTime(2026, 9, 20),
        );
      }
      await insertCard(
        env.db,
        id: 'today',
        deckId: words.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 24),
      );
      await insertCard(env.db, id: 'new', deckId: words.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const DeckLevelScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/library_decks_${brightness.name}.png',
        );
      });
    });

    libraryTest('Library first run, ${brightness.name}', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const DeckLevelScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/library_empty_${brightness.name}.png',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_level_screen_test.dart`
Expected: FAIL to compile, because `deck_level_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/widgets/support/deck_workload_line_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// A deck's or a level's workload: overdue · today · new, or the calm line
/// when nothing is due ("3 cards · nothing due", "No cards yet").
class DeckWorkloadLineWidget extends StatelessWidget {
  const DeckWorkloadLineWidget({
    super.key,
    required this.overdueCount,
    required this.todayCount,
    required this.newCount,
    required this.cardCount,
  });

  final int overdueCount;
  final int todayCount;
  final int newCount;

  /// Every card counted, due or not, to word the nothing-due line.
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxWorkloadBreakdownLine(
      overdueCount: overdueCount,
      todayCount: todayCount,
      newCount: newCount,
      overdueLabel: l10n.workloadOverdue,
      todayLabel: l10n.workloadToday,
      newLabel: l10n.workloadNew,
      fallback: cardCount == 0
          ? l10n.workloadNoCards
          : l10n.workloadNothingDue(cardCount),
    );
  }
}
```

`lib/features/deck/presentation/widgets/items/deck_row_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One deck of a level: its tile, its name and its workload. Opening a deck
/// arrives in phase 2 (ruling L1).
class DeckRowWidget extends StatelessWidget {
  const DeckRowWidget({super.key, required this.tile, this.hasDivider = true});

  final DeckTile tile;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) => MxListRow(
    title: tile.name,
    leading: const MxIconTile(
      icon: AppIcons.library,
      size: MxIconTileSize.large,
    ),
    meta: DeckWorkloadLineWidget(
      overdueCount: tile.overdueCount,
      todayCount: tile.dueTodayCount,
      newCount: tile.newCount,
      cardCount: tile.cardCount,
    ),
    hasDivider: hasDivider,
  );
}
```

`lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Picks the level's order. The chosen option closes the sheet.
Future<void> showDeckSortSheet(
  BuildContext context, {
  required DeckLevelSort selected,
  required ValueChanged<DeckLevelSort> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => _OptionSheet<DeckLevelSort>(
    title: sheetContext.l10n.deckSortTitle,
    options: DeckLevelSort.values,
    labelOf: sheetContext.l10n.deckSort,
    selected: selected,
    onSelected: (sort) {
      onSelected(sort);
      Navigator.of(sheetContext).pop();
    },
  ),
);

/// Picks which decks of the level show.
Future<void> showDeckFilterSheet(
  BuildContext context, {
  required DeckLevelFilter selected,
  required ValueChanged<DeckLevelFilter> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => _OptionSheet<DeckLevelFilter>(
    title: sheetContext.l10n.deckFilterTitle,
    options: DeckLevelFilter.values,
    labelOf: sheetContext.l10n.deckFilter,
    selected: selected,
    onSelected: (filter) {
      onSelected(filter);
      Navigator.of(sheetContext).pop();
    },
  ),
);

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<T> options;
  final String Function(T option) labelOf;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => MxBottomSheet(
    header: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Text(title, style: context.textStyles.compactTitle),
    ),
    child: Column(
      children: [
        for (final (index, option) in options.indexed)
          MxOptionRow(
            title: labelOf(option),
            isSelected: option == selected,
            onSelected: () => onSelected(option),
            hasDivider: index < options.length - 1,
          ),
      ],
    ),
  );
}
```

`lib/features/deck/presentation/widgets/sections/deck_level_header_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// "DECKS" and the two chips that name the level's order and filter (L5).
class DeckLevelHeaderWidget extends ConsumerWidget {
  const DeckLevelHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider);
    return MxListSectionHeader(
      label: l10n.libraryDecksHeader,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          MxChipTrigger(
            label: l10n.deckSortTrigger(l10n.deckSort(query.sort)),
            icon: AppIcons.sort,
            onPressed: () => showDeckSortSheet(
              context,
              selected: query.sort,
              onSelected: (sort) =>
                  ref.read(deckLevelQueryProvider.notifier).sortBy(sort),
            ),
          ),
          MxChipTrigger(
            label: l10n.deckFilterTrigger(l10n.deckFilter(query.filter)),
            icon: AppIcons.filter,
            onPressed: () => showDeckFilterSheet(
              context,
              selected: query.filter,
              onSelected: (filter) =>
                  ref.read(deckLevelQueryProvider.notifier).show(filter),
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_header_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// A loaded level: today's work first, then the decks (spec §6.1, D3).
class DeckLevelListWidget extends ConsumerWidget {
  const DeckLevelListWidget({
    super.key,
    required this.level,
    required this.onCreateDeck,
  });

  final DeckLevel level;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(deckLevelQueryProvider).filter;
    final tiles = level.tiles;
    // Ruling L4: an empty level is the first run; an empty filter is not.
    if (tiles.isEmpty && filter == DeckLevelFilter.all) {
      return MxScreenScroll(
        clearance: MxScrollClearance.fabAboveNav,
        children: [
          const SizedBox(height: AppSpacing.gutter),
          MxEmptyState(
            icon: AppIcons.library,
            title: l10n.libraryEmptyTitle,
            body: l10n.libraryEmptyBody,
            actionLabel: l10n.libraryCreateDeck,
            onAction: onCreateDeck,
          ),
        ],
      );
    }
    return MxScreenScroll(
      clearance: MxScrollClearance.fabAboveNav,
      children: [
        const SizedBox(height: AppSpacing.gutter),
        DeckWorkloadLineWidget(
          overdueCount: level.overdueCount,
          todayCount: level.dueTodayCount,
          newCount: level.newCount,
          cardCount:
              level.overdueCount +
              level.dueTodayCount +
              level.newCount +
              level.scheduledCount,
        ),
        const SizedBox(height: AppSpacing.section),
        const DeckLevelHeaderWidget(),
        if (tiles.isEmpty)
          MxEmptyState(
            icon: AppIcons.library,
            title: l10n.libraryNothingDueTitle,
            body: l10n.libraryNothingDueBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
            actionLabel: l10n.libraryShowAllDecks,
            onAction: () => ref
                .read(deckLevelQueryProvider.notifier)
                .show(DeckLevelFilter.all),
          )
        else
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, tile) in tiles.indexed)
                  DeckRowWidget(
                    tile: tile,
                    hasDivider: index < tiles.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
```

`lib/features/deck/presentation/screens/deck_level_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_list_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// The Library root: the roots with today's work first (UC-DECK-003). Phase
/// 2 turns it into the recursive deck screen (ruling L1).
class DeckLevelScreen extends ConsumerWidget {
  const DeckLevelScreen({super.key});

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider);
    final provider = deckLevelProvider(sort: query.sort, filter: query.filter);
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(title: l10n.navLibrary),
      fab: MxFab(
        icon: AppIcons.add,
        semanticLabel: l10n.libraryCreateDeck,
        onPressed: createDeck,
      ),
      body: ref
          .watch(provider)
          .when(
            data: (level) =>
                DeckLevelListWidget(level: level, onCreateDeck: createDeck),
            loading: () => MxScreenScroll(
              clearance: MxScrollClearance.fabAboveNav,
              children: [
                for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
              ],
            ),
            error: (_, _) => MxScreenScroll(
              clearance: MxScrollClearance.fabAboveNav,
              children: [
                MxErrorState(
                  title: l10n.libraryLoadErrorTitle,
                  body: l10n.libraryLoadErrorBody,
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(provider),
                ),
              ],
            ),
          ),
    );
  }
}
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation/deck_level_screen_test.dart
```

Expected: PASS, 12 tests.

- If a Drift stream timer remains pending at the end of a test, add one `await tester.pump(Duration.zero)` before `env.db.close()` in `libraryTest`, and record a test-only ruling.
- If `deckLevelProvider().overrideWith` does not accept a stream closure in Riverpod 3.4.3, override `watchDeckLevelUseCaseProvider` with a `WatchDeckLevelUseCase` over a repository whose `watchLevel` returns the pending or error stream. Record a test-only ruling.

- [ ] **Step 5: Golden, look, gate, commit**

```bash
flutter test --update-goldens --tags golden test/features/deck/presentation/deck_level_screen_golden_test.dart
flutter test --tags golden test/features/deck/presentation/deck_level_screen_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/deck/presentation test/features/deck/presentation
git commit -m "feat(deck): the Library root screen

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check the goldens:
- The level line ("3 overdue · 1 today · 1 new") is the first thing under the app bar.
- The "DECKS" header carries the two chips.
- The decks sit in one card with hairlines between them, and each row has a 44 tile and its workload line.
- The FAB sits bottom right.
- The first-run golden shows the empty card with "Create deck".

---

### Task 5: Route the Library branch to the new screen

**Files:**
- Modify: `lib/app/router/app_router.dart`, `test/app/app_test.dart`, `test/app/app_golden_test.dart`, `test/app/goldens/app_library_{light,dark}.png`

**Interfaces:**
- Consumes: `DeckLevelScreen`, `libraryTest`, `LibraryEnv`.

- [ ] **Step 1: Write the failing test**

In `test/app/app_test.dart`:
- Add these imports:
  - `package:memox/core/clock/di/day_clock_provider.dart`
  - `package:memox/core/database/di/database_provider.dart`
  - `../support/library_harness.dart`
- Change `_pumpApp` to take a `LibraryEnv` and override the backend:

```dart
Future<void> _pumpApp(
  WidgetTester tester,
  LibraryEnv env, {
  bool hasGallery = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(env.db),
        dayClockProvider.overrideWithValue(env.clock),
      ],
      child: MemoxApp(hasGallery: hasGallery),
    ),
  );
  await tester.pumpAndSettle();
}
```

- Every test that calls `_pumpApp` becomes `libraryTest('…', (tester, env) async { … })` and passes `env` to `_pumpApp`. Tests that do not pump the app stay `testWidgets`.
- Replace the test `'each tab shows the neutral placeholder'` with:

```dart
  libraryTest('Library opens on its screen; the other tabs are placeholders', (
    tester,
    env,
  ) async {
    await _pumpApp(tester, env);
    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    expect(find.text(_en.placeholderTitle), findsNothing);

    await tester.tap(_tab(_en.navStudy));
    await tester.pumpAndSettle();
    expect(find.text(_en.placeholderTitle), findsOneWidget);
  });
```

In `test/app/app_golden_test.dart`, give `_pumpApp` the same `LibraryEnv` parameter and overrides. Make both tests `libraryTest`.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/app/app_test.dart`
Expected: FAIL, because Library still shows the placeholder.

- [ ] **Step 3: Implement**

In `lib/app/router/app_router.dart`:
- Import `package:memox/features/deck/presentation/screens/deck_level_screen.dart`.
- Replace the first branch:

```dart
        _branch(AppRoutes.decks, (context) => context.l10n.navLibrary),
```

with:

```dart
        // The Library (library spec §4); its child routes arrive in phase 2.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.decks,
              builder: (context, state) => const DeckLevelScreen(),
            ),
          ],
        ),
```

- [ ] **Step 4: Run it to verify it passes; regenerate the Library golden**

```bash
flutter test test/app/app_test.dart
flutter test --tags golden test/app/app_golden_test.dart
```

Expected: `app_test.dart` passes. The golden run fails only on `app_library_*`, which now shows the first-run Library.

```bash
flutter test --update-goldens --tags golden test/app/app_golden_test.dart
flutter test --tags golden test/app/app_golden_test.dart
```

Delete any `failures/` folder. Open `app_library_light.png` and `_dark.png`: the Library title, the first-run empty card, the FAB, and the bottom nav with Library selected. `app_gallery_*` must not change.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/app test/app
git commit -m "feat(app): the Library tab opens the Library root

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Register, full gate, hand back

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9)

- [ ] **Step 1: Record the phase in the debt register**

Append after the last row of UI-base spec §9 (row 66):

```markdown
| 67 | Status text reads in derived status inks (`statusNewInk`…`statusMasteredInk`): the status colour mixed toward `onSurface` (light 0.40/0.50/0.25/0.25, dark 0.40/0/0.10/0), at least 4.5:1 on surface, surfaceContainerLowest, surfaceContainer and each 12% tint. This resolves row 57's StatusBadge half and row 60; row 57's MasteryDonut label and row 3's remaining status texts stay open | library phase 1 L6 |
| 68 | A database `Failure` shows ARB copy from `lib/l10n/failure_copy.dart`, never `Failure.message`, which stays English for logs | library phase 1 L2 |
| 69 | The Library root's deck rows open nothing until phase 2 adds the recursive deck screen | library phase 1 L1 |
```

- [ ] **Step 2: Full gate**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python tools/docs/check.py
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- Every command exits 0, and the guard reports 0 errors and 0 warnings.
- `dod_check.sh` is the gate from this phase on (spec §9). If it fails on a step this phase does not own, record the step and its output as a finding for the final review, not a ruling.

- [ ] **Step 3: Scope check and commit**

```bash
git add docs/superpowers
git commit -m "docs(spec): record Library phase 1 in the UI debt register

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected: the diff lists only:
- `PRODUCT.md`
- `docs/superpowers/`
- `lib/core/theme/`
- `lib/shared/widgets/`
- `lib/l10n/`
- `lib/features/deck/presentation/`
- `lib/app/router/`
- `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
- `test/`

Report to the user in Vietnamese:
- Counts and results.
- Every execution ruling.
- The Library goldens, sent with SendUserFile.

Then ask through AskUserQuestion whether to open the PR, merge it, and continue to phase 2.
