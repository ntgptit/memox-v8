# MemoX V8 Progress UI Implementation Plan (FE-A9)

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build FE-A9 in [`docs/wbs_FE.md`](../../wbs_FE.md): kit screen 22, Progress,
in two levels over BE-A7's read models. The Progress tab stops being the last
placeholder of the app.

**Architecture:**
- **Two shared widgets and a colour (D6, D7).** `MxStackedDayBars` and `MxDashedNote`
  join `lib/shared/widgets/`, and `streak` joins `MxSemanticColors`.
- **Reads only (D3).** `lib/features/progress/presentation/` gains:
  - one `StreamProvider` per use case (`progressProvider`,
    `deckProgressProvider(deckId)`);
  - the tab's range, `progressRangeChoiceProvider` (D4);
  - no controller: the screen writes nothing (BR-PROGRESS-009).
- **Two screens.** `ProgressScreen` (`/progress`) and `DeckProgressScreen`
  (`/progress/:deckId`) share the range tray, the level list and the row widget.
- **`app/`.** It wires the Progress branch with a child route per level (D5), the
  breadcrumb's ancestors and "Start studying" to the Study tab (D9).
  `PlaceholderScreen` has no tab left and goes.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, `intl`, gen-l10n (en, vi). No new package.

**Spec:** [`docs/superpowers/specs/2026-09-27-progress-ui-design.md`](../specs/2026-09-27-progress-ui-design.md)
(D1–D11, §5–§8).
- Use cases: UC-PROGRESS-001, UC-PROGRESS-002.
- The kit is the visual authority: "MemoX — Mobile UI Kit v3", screen 22 (8 states),
  captured in `docs/shared/ui/screen-handoff/img/22-progress/`.
- The pre-plan critique is `.impeccable/critique/2026-09-27T04-00-00Z__progress-kit.md`
  (P1 → D10, P2 → D11, P3 → D2).

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` at the commit that adds
this plan: `master` at #91 plus the spec, the critique and this plan. Generated code is
not committed. In a fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- **Built in scratch.** Every task was built and committed in a scratch worktree of the
  branch, and each task's blocks below are that commit's files and diffs.
- **Gate.** The full gate (`dod_check.sh --force`) passed there, with a clean
  `flutter analyze`, a clean guard and clean architecture boundaries.
- **Goldens.** They ran in this Linux container, and every screen 22 golden was compared
  with its kit capture.
- **Replay.** The blocks were replayed mechanically onto a clean checkout, and the
  result matched the scratch files byte for byte, `docs/_generated/` included once
  regenerated.
- **Recorded results:**
  - the gate: 2277 tests, "✓ mechanical gates passed", guard "No violations found",
    docs "PASS — 0 error(s)";
  - the whole suite with goldens: 2570 tests;
  - Tasks 1–3 alone: `flutter analyze` clean, and 523 tests in `test/features/progress`,
    `test/shared` and `test/app` pass.

## Clarifications (rulings; amend the spec where they differ)

- **C1 (the streak tiles).** A tile is the recessed ground
  (`AppDecorations.recessedCard`) at a 12 inset, as the kit draws it, not an `MxCard`,
  whose 20 inset leaves two tiles too narrow on a phone. The app's caption is 12/600
  where the kit's is 12/400, so "includes today" may take two lines. That is accepted.
- **C2 (day labels).** A label wider than its bar, such as "Today", scales down to fit
  (`FittedBox`), and never loses letters.
- **C3 (the placeholder).** With Progress built, no tab uses `PlaceholderScreen`. The
  following go:
  - the screen, its visual audit companion and the `_branch` helper;
  - `placeholderTitle` and `placeholderBody`.
  The tests that named it now name screen 22.
- **C4 (the route).** The child route is `:deckId` under `/progress`
  (`AppRoutes.progressDeckChild`, `AppRoutes.progressDeck(id)`). `_openAncestor`
  gains `levelOf`, so a breadcrumb segment pops to its level in either branch.
- **C5 (a row's sub-line).**
  - Three keys: `progressRowDays` (plural), `progressRowLearning` and
    `progressRowReviewing`.
  - They are joined by the app's `' · '` separator constant.
  - The learning and reviewing runs take `MxTextStyles.captionIn(ink)`, which is new.
  - The figure reuses `factValue` (16/700 tabular).
- **C6 (loading).** The library level loads as `MxSkeletonList` alone. A deck's level
  keeps its tray above the skeleton, because the tray is at its top (D10).
- **C7 (the notes).** The A3 and A1 notes follow the list card, directly below the
  total row that heads it.
- **C8 (a lost streak's day).** The weekday name (`DateFormat.EEEE`) is used when
  `lastActiveDay` is within six days of today; otherwise a short date
  (`DateFormat.MMMd`).
- **C9 (names).**
  - The range notifier is `ProgressRangeChoice`, because the domain enum is
    `ProgressRange`.
  - The screens are `ProgressScreen` and `DeckProgressScreen`.
  - The sections are `progress_{today,streak,range,level_list}_widget.dart`, and the
    item is `progress_deck_row_widget.dart`.
- **C10 (a deck's level before its path is read).** The app bar says "Progress" while
  it loads, errs or finds the deck gone. After that it shows the deck's name.
- **C11 (UI-base §9).**
  - Rows 130–133 are the next free rows at #91. If they are taken by the time this
    lands, use the next free numbers and change their references in
    `22-progress.md`.
  - Rows 125 and 129 now name screen 22 too.

## Global Constraints

Every task's requirements implicitly include these.

- Kit screen 22 is the visual authority. Every difference is in D1–D11, in C1–C11, in
  `22-progress.md`, or in UI-base §9 rows 125, 129 and 130–133.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens in feature code;
  - no raw colour, `TextStyle`, spacing, radius or anonymous `Duration` literal;
  - no `ref.read` inside `build`, including in a callback: move it into a method;
  - no literal user string, TalkBack labels included;
  - booleans read as predicates;
  - no source file over 400 lines;
  - no `Row` pinning its marks to the top.
- File suffixes and buckets follow the guard:
  - `_provider` and `_screen`;
  - `_widget` in `sections/` or `items/`.
- Every read goes through a use case (ADR-011 D4). `progress` imports no feature
  (`test/architecture/boundary_rules.dart`): "Start studying" and the rows are
  callbacks that `app/` wires.
- No message carries an id, a path or SQL (BR-CORE-005). A failed read shows the
  `progressError…` copy, never the failure's text.
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- **Test rules:**
  - Provider tests are plain `test()`s over a `LibraryEnv`.
  - Screen and route tests are `libraryTest`s.
- Goldens render in the Linux container only. On Windows, run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **Tapping "Last 30 days" on a phone.** The list that changes is right under the
   tray; Today and Streak never move. Tests: "the range sits above the list, after
   Streak (D10)" and "Last 30 days switches the numbers and the order at once, with no
   loading…" (Task 3).
2. **Studying in the Study tab, then coming back.** The numbers are new, and no
   skeleton flashes. Test: "a new answer updates the numbers with no skeleton (D8,
   UC-PROGRESS-001 A3)" (Task 3).
3. **Drilling two levels down, then Back or the breadcrumb.** Each Back climbs one
   level, the range is kept, and "Progress" in the path returns to the top. Tests: "a
   row opens its level under the tab bar, keeping the range; Back climbs one level" and
   "the path's Progress segment returns to the library level" (Task 4).
4. **A deck moved to the Trash while its level is open.** The level says the deck is
   no longer here and offers Back only. Test: "a deck gone to the Trash offers Back
   only, no Retry (E2)" (Task 4).
5. **A 360 dp phone at text scale 2, in Vietnamese.** Nothing overflows, and every
   target is 48 dp. Tests: the screen 22 visual audits, en and vi, at both levels
   (Tasks 3, 4).

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/core/theme/{mx_semantic_colors,mx_text_styles}.dart`, `lib/core/theme/foundations/app_icons.dart` | 1, 3 | `streak`; `dayLabel`, `captionIn`; the flame and the calendar-check |
| `lib/shared/widgets/{mx_stacked_day_bars,mx_dashed_note}.dart` | 1 | the week's bars; the dashed placeholder |
| `lib/features/progress/presentation/providers/*.dart` | 2 | the use cases; both reads; the tab's range |
| `lib/features/progress/presentation/screens/progress_screen.dart`, `…/widgets/{sections,items}/*` | 3 | the library level |
| `lib/features/progress/presentation/screens/deck_progress_screen.dart` | 4 | a deck's level |
| `lib/app/router/*`, `lib/app/placeholder_screen.dart` (removed) | 4 | the route, the ancestors, Start studying |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | 3, 4 | the copy |
| `docs/**` | 5 | detail file 22, index, checklist, register, `ui.md`, UC, WBS |

---


### Task 1: The streak colour, the day bars and the dashed note (D6, D7)

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/core/theme/mx_semantic_colors.dart`
- Modify: `lib/core/theme/mx_text_styles.dart`
- Create: `lib/shared/widgets/mx_dashed_note.dart`
- Create: `lib/shared/widgets/mx_stacked_day_bars.dart`
- Create: `test/shared/widgets/goldens/mx_day_bars_dark.png`
- Create: `test/shared/widgets/goldens/mx_day_bars_light.png`
- Test (modify): `test/core/theme/mx_semantic_colors_test.dart`
- Test (create): `test/shared/widgets/mx_dashed_note_test.dart`
- Test (create): `test/shared/widgets/mx_stacked_day_bars_test.dart`
- Test (modify): `test/shared/widgets/status_widgets_golden_test.dart`

**Interfaces:**
- Consumes: `MxSemanticColors`, `MxTextStyles`, `AppIcons`; foundations' `streak`
  (#F97316 / #FFAE6E).
- Produces:
  - `MxSemanticColors.streak` (light `0xFFF97316`, dark `0xFFFFAE6E`);
  - `AppIcons.streak` (flame) and `AppIcons.studiedToday` (calendar-check);
  - `MxTextStyles.dayLabel({required bool isCurrent})`;
  - `MxBarSeries({required String label, required Color color})`;
  - `MxDayBar({required String label, required int base, required int top, required
    String semanticLabel, bool isCurrent = false})`;
  - `MxStackedDayBars({required List<MxDayBar> days, required MxBarSeries base,
    required MxBarSeries top})`: the top series over the base, scaled to the fullest
    day; one TalkBack node per bar;
  - `MxDashedNote({required String text})`.

- [ ] **Step 1: Write the failing tests**

`test/core/theme/mx_semantic_colors_test.dart` (apply this diff):

```diff
diff --git a/test/core/theme/mx_semantic_colors_test.dart b/test/core/theme/mx_semantic_colors_test.dart
index 85bbc1f..3aa34d8 100644
--- a/test/core/theme/mx_semantic_colors_test.dart
+++ b/test/core/theme/mx_semantic_colors_test.dart
@@ -3,7 +3,7 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/core/theme/mx_semantic_colors.dart';
 
 // The ten BIND_NOW MEMOX_SEMANTIC_COLOR entries plus onMastery (spec
-// 2026-09-27), light then dark.
+// 2026-09-27) and streak (FE-A9 D7), light then dark.
 final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
   'mastery': ((c) => c.mastery, 0xFF1F8A5B, 0xFF6FE0BD),
   'warning': ((c) => c.warning, 0xFFF59E0B, 0xFFFFC658),
@@ -16,6 +16,7 @@ final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
   'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF),
   'onMastery': ((c) => c.onMastery, 0xFFFFFFFF, 0xFF11173A),
   'success': ((c) => c.success, 0xFF2BA88B, 0xFF6FE0BD),
+  'streak': ((c) => c.streak, 0xFFF97316, 0xFFFFAE6E),
 };
 
 void main() {
```

`test/shared/widgets/mx_dashed_note_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';

import '../../support/widget_harness.dart';

// FE-A9 D6: kit 22's per-chart empty.

const _line = 'A streak starts with your first study day.';

void main() {
  testWidgets('a centred note line on the muted fill, padded 24 16', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxDashedNote(text: _line)),
    );
    final text = tester.widget<Text>(find.text(_line));
    final box =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxDashedNote),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(text.textAlign, TextAlign.center);
    expect(text.style!.color, scheme.onSurfaceVariant);
    expect(box.color, scheme.surfaceContainerLow);
    expect(
      tester.getTopLeft(find.text(_line)).dy -
          tester.getTopLeft(find.byType(MxDashedNote)).dy,
      24,
    );
  });

  testWidgets('TalkBack reads the line once', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxDashedNote(text: _line));

    expect(find.bySemanticsLabel(_line), findsOneWidget);
    handle.dispose();
  });
}
```

`test/shared/widgets/mx_stacked_day_bars_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

import '../../support/widget_harness.dart';

// FE-A9 D6: kit 22's seven stacked day bars.

const _learning = MxBarSeries(label: 'Learning', color: Colors.orange);
const _reviewing = MxBarSeries(label: 'Reviewing', color: Colors.indigo);

MxDayBar _day(String label, int reviewing, int learning, {bool now = false}) =>
    MxDayBar(
      label: label,
      base: reviewing,
      top: learning,
      semanticLabel: '$label: ${reviewing + learning} cards',
      isCurrent: now,
    );

Widget _chart(List<MxDayBar> days) => SizedBox(
  width: 300,
  child: MxStackedDayBars(days: days, base: _reviewing, top: _learning),
);

double _height(WidgetTester tester, Color color) => tester
    .getSize(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.rectangle &&
            (widget.decoration! as BoxDecoration).color?.toARGB32() ==
                color.toARGB32(),
      ),
    )
    .height;

void main() {
  testWidgets('the fullest day fills the chart; the rest scale to it', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _chart([_day('M', 10, 0), _day('Today', 12, 8, now: true)]),
    );

    // Today: 8 learning over 12 reviewing fill the 78 of the chart.
    expect(_height(tester, _learning.color), closeTo(8 * 78 / 20, 0.01));
    expect(_height(tester, _reviewing.color), closeTo(12 * 78 / 20, 0.01));
    // Monday's reviewing is faded, and half of Today's 20.
    expect(
      _height(tester, _reviewing.color.withValues(alpha: 0.55)),
      closeTo(10 * 78 / 20, 0.01),
    );
  });

  testWidgets('a day with nothing is a 2-high baseline', (tester) async {
    await pumpMx(tester, _chart([_day('F', 0, 0), _day('S', 3, 0)]));
    final baseline = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxHeight == 2,
    );

    expect(baseline, findsOneWidget);
  });

  testWidgets('each bar is one TalkBack node; labels and legend say nothing '
      'more', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _chart([_day('S', 3, 1), _day('Today', 0, 2, now: true)]),
    );

    expect(find.bySemanticsLabel('S: 4 cards'), findsOneWidget);
    expect(find.bySemanticsLabel('Today: 2 cards'), findsOneWidget);
    expect(find.bySemanticsLabel('Learning'), findsNothing);
    expect(find.bySemanticsLabel('Reviewing'), findsNothing);
    handle.dispose();
  });

  testWidgets('the current day is labelled in bold', (tester) async {
    await pumpMx(
      tester,
      _chart([_day('S', 1, 0), _day('Today', 1, 0, now: true)]),
    );

    expect(
      tester.widget<Text>(find.text('Today')).style!.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('S')).style!.fontWeight,
      FontWeight.w400,
    );
  });
}
```

`test/shared/widgets/status_widgets_golden_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/status_widgets_golden_test.dart b/test/shared/widgets/status_widgets_golden_test.dart
index 3964fd3..bc42dd7 100644
--- a/test/shared/widgets/status_widgets_golden_test.dart
+++ b/test/shared/widgets/status_widgets_golden_test.dart
@@ -4,8 +4,11 @@ library;
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
+import 'package:memox/core/theme/theme_context.dart';
 import 'package:memox/shared/widgets/mx_badge.dart';
+import 'package:memox/shared/widgets/mx_dashed_note.dart';
 import 'package:memox/shared/widgets/mx_mastery_donut.dart';
+import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';
 import 'package:memox/shared/widgets/mx_stat_tile.dart';
 import 'package:memox/shared/widgets/mx_status_badge.dart';
 import 'package:memox/shared/widgets/mx_tag_chip.dart';
@@ -167,4 +170,47 @@ void main() {
       ),
     );
   });
+
+  testWidgets('MxStackedDayBars and MxDashedNote', (tester) async {
+    // Kit 22: the seven days before and with today, and the empty chart.
+    const week = [(8, 4), (18, 0), (0, 0), (16, 6), (12, 2), (9, 0), (12, 5)];
+    const labels = ['W', 'T', 'F', 'S', 'S', 'M', 'Today'];
+    await expectThemedGoldens(
+      tester,
+      'mx_day_bars',
+      Builder(
+        builder: (context) => Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          spacing: 16,
+          children: [
+            MxStackedDayBars(
+              days: [
+                for (final (index, (reviewing, learning)) in week.indexed)
+                  MxDayBar(
+                    label: labels[index],
+                    base: reviewing,
+                    top: learning,
+                    semanticLabel: labels[index],
+                    isCurrent: index == week.length - 1,
+                  ),
+              ],
+              base: MxBarSeries(
+                label: 'Reviewing',
+                color: context.colors.primary,
+              ),
+              top: MxBarSeries(
+                label: 'Learning',
+                color: context.semanticColors.statusLearning,
+              ),
+            ),
+            const MxDashedNote(
+              text:
+                  'Your last seven days appear here once you study. '
+                  'Browsing cards does not count.',
+            ),
+          ],
+        ),
+      ),
+    );
+  });
 }
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/shared/widgets/mx_stacked_day_bars_test.dart test/shared/widgets/mx_dashed_note_test.dart test/core/theme/mx_semantic_colors_test.dart
```

Expected: FAIL to compile: `mx_stacked_day_bars.dart` and `mx_dashed_note.dart` do not
exist, and `MxSemanticColors` has no `streak`.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index 0858ab6..1402b72 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -85,6 +85,10 @@ abstract final class AppIcons {
   // Card export (kit 12).
   static const IconData share = Icons.share_outlined; // share-2
   static const IconData fileDown = Icons.file_download_outlined; // file-down
+  // Progress (kit 22).
+  static const IconData streak = Icons.local_fire_department_outlined; // flame
+  static const IconData studiedToday =
+      Icons.event_available_outlined; // calendar-check
   static const IconData library = Icons.layers_outlined;
   static const IconData librarySelected = Icons.layers;
   static const IconData study = Icons.play_circle_outline;
```

`lib/core/theme/mx_semantic_colors.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/mx_semantic_colors.dart b/lib/core/theme/mx_semantic_colors.dart
index 8aab5b9..f7a7ffc 100644
--- a/lib/core/theme/mx_semantic_colors.dart
+++ b/lib/core/theme/mx_semantic_colors.dart
@@ -4,10 +4,11 @@ import 'package:flutter/material.dart';
 /// (02-theme-binding MEMOX_SEMANTIC_COLOR, BIND_NOW only).
 ///
 /// Holds the semantics a V3 component paints, plus onMastery (spec
-/// 2026-09-27: the done import step lost its ink). Aliases resolve to
-/// their ColorScheme role, derived colours live in MxDerivedColors, and the
-/// PRESERVE_ONLY semantics (streak, mastery-fixed…) get no field
-/// until a component consumes them. Green means mastery, never tertiary.
+/// 2026-09-27: the done import step lost its ink) and streak (FE-A9 D7: the
+/// Progress streak's flame). Aliases resolve to their ColorScheme role,
+/// derived colours live in MxDerivedColors, and the other PRESERVE_ONLY
+/// semantics (mastery-fixed…) get no field until a component consumes them.
+/// Green means mastery, never tertiary.
 @immutable
 final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
   const MxSemanticColors({
@@ -22,6 +23,7 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
     required this.errorFill,
     required this.onErrorFill,
     required this.success,
+    required this.streak,
   });
 
   static const MxSemanticColors light = MxSemanticColors(
@@ -36,6 +38,7 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
     errorFill: Color(0xFFDC2D4E),
     onErrorFill: Color(0xFFFFFFFF),
     success: Color(0xFF2BA88B),
+    streak: Color(0xFFF97316),
   );
 
   static const MxSemanticColors dark = MxSemanticColors(
@@ -51,6 +54,7 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
     errorFill: Color(0xFFB0485C),
     onErrorFill: Color(0xFFFFFFFF),
     success: Color(0xFF6FE0BD),
+    streak: Color(0xFFFFAE6E),
   );
 
   /// Mastery and progress green.
@@ -77,6 +81,9 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
   /// never [mastery], though both read as progress.
   final Color success;
 
+  /// The current streak's accent: the flame on Progress (FE-A9 D7).
+  final Color streak;
+
   @override
   MxSemanticColors copyWith({
     Color? mastery,
@@ -90,6 +97,7 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
     Color? errorFill,
     Color? onErrorFill,
     Color? success,
+    Color? streak,
   }) => MxSemanticColors(
     mastery: mastery ?? this.mastery,
     onMastery: onMastery ?? this.onMastery,
@@ -102,6 +110,7 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
     errorFill: errorFill ?? this.errorFill,
     onErrorFill: onErrorFill ?? this.onErrorFill,
     success: success ?? this.success,
+    streak: streak ?? this.streak,
   );
 
   @override
@@ -123,6 +132,7 @@ final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
       errorFill: Color.lerp(errorFill, other.errorFill, t)!,
       onErrorFill: Color.lerp(onErrorFill, other.onErrorFill, t)!,
       success: Color.lerp(success, other.success, t)!,
+      streak: Color.lerp(streak, other.streak, t)!,
     );
   }
 }
```

`lib/core/theme/mx_text_styles.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/mx_text_styles.dart b/lib/core/theme/mx_text_styles.dart
index 77f21ac..f337aa8 100644
--- a/lib/core/theme/mx_text_styles.dart
+++ b/lib/core/theme/mx_text_styles.dart
@@ -150,6 +150,13 @@ final class MxTextStyles {
     color: isReached ? _scheme.onSurface : _scheme.onSurfaceVariant,
   );
 
+  /// A day bar's label (kit 22): 12, onSurfaceVariant, at 700 on the current
+  /// day.
+  TextStyle dayLabel({required bool isCurrent}) => AppTypography.withWeight(
+    _texts.labelSmall!,
+    isCurrent ? FontWeight.w700 : FontWeight.w400,
+  ).copyWith(color: _scheme.onSurfaceVariant);
+
   /// The number on an import step's dot (kit 11): the counter in [ink].
   TextStyle stepNumber(Color ink) => counter.copyWith(color: ink);
 
```

`lib/shared/widgets/mx_dashed_note.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The place a chart or a figure takes once there is something to show
/// (kit 22's per-chart empty, FE-A9 D6): one centred line in a muted box
/// with a dashed hairline. A fact, never an error and never an action.
class MxDashedNote extends StatelessWidget {
  const MxDashedNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      foregroundPainter: _DashedBorder(color: colors.outlineVariant),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.section,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.textStyles.noteText,
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle's outline in dashes, drawn over the box.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppStroke.hairline / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - AppStroke.hairline,
            size.height - AppStroke.hairline,
          ),
          const Radius.circular(AppRadius.md),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.hairline;
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color;
}
```

`lib/shared/widgets/mx_stacked_day_bars.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One series of an MxStackedDayBars: its legend label and its fill.
@immutable
final class MxBarSeries {
  const MxBarSeries({required this.label, required this.color});

  final String label;
  final Color color;
}

/// One day of an MxStackedDayBars: the [top] series stacked over the [base]
/// series, a short label under the bar, and the whole day in words for
/// TalkBack.
@immutable
final class MxDayBar {
  const MxDayBar({
    required this.label,
    required this.base,
    required this.top,
    required this.semanticLabel,
    this.isCurrent = false,
  }) : assert(base >= 0 && top >= 0, 'a bar counts from zero');

  /// A narrow weekday, or the current day's word ("Today").
  final String label;
  final int base;
  final int top;

  /// The day and its numbers: "Sunday: 17 cards, 5 learning, 12 reviewing".
  final String semanticLabel;

  /// Drawn at full strength, with a bold label.
  final bool isCurrent;

  int get total => base + top;
}

/// A week of days as stacked bars (kit 22, FE-A9 D6): the [MxBarSeries.color]
/// of the top series over the base series, scaled to the fullest day, with
/// the labels under the bars and the legend under the labels. A day with
/// nothing is a thin baseline. Each bar is one TalkBack node; the drawing
/// and the legend say nothing more.
class MxStackedDayBars extends StatelessWidget {
  const MxStackedDayBars({
    super.key,
    required this.days,
    required this.base,
    required this.top,
  }) : assert(days.length > 0, 'a chart has at least one day');

  final List<MxDayBar> days;
  final MxBarSeries base;
  final MxBarSeries top;

  static const double _chartHeight = 78;
  static const double _emptyHeight = 2;
  static const double _legendDot = 6;

  /// The kit's fades of the days before the current one.
  static const double _pastBaseOpacity = 0.55;
  static const double _pastTopOpacity = 0.7;

  @override
  Widget build(BuildContext context) {
    final most = days.map((day) => day.total).fold(1, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            spacing: AppSpacing.control,
            children: [
              for (final day in days) Expanded(child: _bar(context, day, most)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.micro),
        ExcludeSemantics(
          child: Row(
            spacing: AppSpacing.control,
            children: [
              for (final day in days)
                // A label wider than its bar, such as "Today", shrinks to
                // fit rather than lose letters.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day.label,
                      maxLines: 1,
                      style: context.textStyles.dayLabel(
                        isCurrent: day.isCurrent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        ExcludeSemantics(
          child: Wrap(
            spacing: AppSpacing.grouped,
            runSpacing: AppSpacing.micro,
            children: [_legend(context, top), _legend(context, base)],
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, MxDayBar day, int most) => Semantics(
    label: day.semanticLabel,
    excludeSemantics: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxHeight / most;
        const round = Radius.circular(AppRadius.xs);
        final topFade = day.isCurrent ? 1.0 : _pastTopOpacity;
        final baseFade = day.isCurrent ? 1.0 : _pastBaseOpacity;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (day.total == 0)
              Container(
                height: _emptyHeight,
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHigh,
                  borderRadius: const BorderRadius.all(round),
                ),
              ),
            if (day.top > 0)
              Container(
                height: day.top * unit,
                decoration: BoxDecoration(
                  color: top.color.withValues(alpha: topFade),
                  borderRadius: const BorderRadius.vertical(top: round),
                ),
              ),
            if (day.base > 0)
              Container(
                height: day.base * unit,
                decoration: BoxDecoration(
                  color: base.color.withValues(alpha: baseFade),
                  borderRadius: day.top > 0
                      ? const BorderRadius.vertical(bottom: round)
                      : const BorderRadius.all(round),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _legend(BuildContext context, MxBarSeries series) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.micro,
    children: [
      Container(
        width: _legendDot,
        height: _legendDot,
        decoration: BoxDecoration(color: series.color, shape: BoxShape.circle),
      ),
      Text(series.label, style: context.textStyles.dayLabel(isCurrent: false)),
    ],
  );
}
```

- [ ] **Step 4: Render the goldens and run**

```bash
TZ=UTC flutter test --tags golden --update-goldens test/shared/widgets/status_widgets_golden_test.dart
flutter test test/shared test/core
flutter analyze
```

Expected: PASS: 4 tests in `mx_stacked_day_bars_test.dart`, 2 in
`mx_dashed_note_test.dart`, `streak` in `mx_semantic_colors_test.dart`. Two new goldens,
`mx_day_bars_{light,dark}.png`: the kit's seven bars (learning in amber over
reviewing in primary, today at full strength, Friday a baseline, "Today" whole) and the
dashed note. No other golden changes.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/theme/foundations/app_icons.dart \
  lib/core/theme/mx_semantic_colors.dart \
  lib/core/theme/mx_text_styles.dart \
  lib/shared/widgets/mx_dashed_note.dart \
  lib/shared/widgets/mx_stacked_day_bars.dart \
  test/core/theme/mx_semantic_colors_test.dart \
  test/shared/widgets/mx_dashed_note_test.dart \
  test/shared/widgets/mx_stacked_day_bars_test.dart \
  test/shared/widgets/status_widgets_golden_test.dart \
  test/shared/widgets/goldens/mx_day_bars_dark.png \
  test/shared/widgets/goldens/mx_day_bars_light.png
git commit -m "$(cat <<'EOF'
feat(ui): the streak colour, stacked day bars and the dashed note (FE-A9 D6, D7)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: The Progress reads and the tab's range (D3, D4, D8)

**Files:**
- Create: `lib/features/progress/presentation/providers/deck_progress_provider.dart`
- Create: `lib/features/progress/presentation/providers/progress_provider.dart`
- Create: `lib/features/progress/presentation/providers/progress_range_provider.dart`
- Create: `lib/features/progress/presentation/providers/watch_deck_progress_use_case_provider.dart`
- Create: `lib/features/progress/presentation/providers/watch_progress_use_case_provider.dart`
- Test (create): `test/features/progress/presentation/progress_providers_test.dart`

**Interfaces:**
- Consumes: BE-A7's `WatchProgressUseCase` and `WatchDeckProgressUseCase` over
  `progressRepositoryProvider` and `dayClockProvider`; `Progress`, `DeckProgress`
  (`DeckProgressLevel`, `ProgressDeckMissing`), `ProgressRange`.
- Produces:
  - `watchProgressUseCaseProvider`, `watchDeckProgressUseCaseProvider`;
  - `progressProvider` → `Stream<Progress>`;
  - `deckProgressProvider(String deckId)` → `Stream<DeckProgress>`;
  - `progressRangeChoiceProvider` (`ProgressRangeChoice`): `ProgressRange`, starting at
    `week`, with `choose(ProgressRange)`.

- [ ] **Step 1: Write the failing tests**

Plain `test()`s over a `LibraryEnv`: Drift's streams need the real event loop.

`test/features/progress/presentation/progress_providers_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/providers/deck_progress_provider.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/providers/progress_range_provider.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/fake_day_clock.dart';

// FE-A9 D3, D4, D8: the two reads of screen 22 and the tab's range.

/// A read that fails the way the database does (Progress spec §6.6).
final class _FailingProgress implements ProgressRepository {
  var reads = 0;

  @override
  Stream<Progress> watchProgress(ProgressDays days) {
    reads++;
    return Stream.error(
      UnknownDatabaseFailure(cause: StateError('read failed')),
    );
  }

  @override
  Stream<DeckProgress> watchDeckProgress({
    required String deckId,
    required ProgressDays days,
  }) => Stream.error(UnknownDatabaseFailure(cause: StateError('read failed')));
}

void main() {
  late LibraryEnv env;

  setUp(() => env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday)));
  tearDown(() => env.db.close());

  /// A root deck with one learned card [cardId]; returns the root's id.
  Future<String> deck(String name, String cardId) async {
    final root = await env.decks.root(name);
    await learnedCard(env.db, root.id, cardId);
    await lockScheduler(env.db, root.id);
    return root.id;
  }

  test(
    'a new answer updates the library level; nothing else is read',
    () async {
      await deck('Korean', 'a');
      final container = libraryContainer(env);
      final seen = <Progress>[];
      container.listen(
        progressProvider,
        (_, next) => next.whenData(seen.add),
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(seen.single.level.total.week.activeCards, 0);

      await answer(env.db, 'a', libraryToday);
      await pumpEventQueue();

      expect(seen.last.level.total.week.activeCards, 1);
      expect(seen.last.overview.today.total, 1);
    },
  );

  test("a deck's level lists its children; a deck that is gone is a value, "
      'not an error (UC-PROGRESS-002 E2)', () async {
    final root = await env.decks.root('Korean');
    await env.decks.sub(root.id, 'Verbs');
    final container = libraryContainer(env);
    container.listen(deckProgressProvider(root.id), (_, _) {});
    container.listen(deckProgressProvider('gone'), (_, _) {});

    final level = await container.read(deckProgressProvider(root.id).future);
    final gone = await container.read(deckProgressProvider('gone').future);

    expect(
      (level as DeckProgressLevel).level
          .decksFor(ProgressRange.week)
          .map((row) => row.name),
      ['Verbs'],
    );
    expect(gone, isA<ProgressDeckMissing>());
  });

  test('a failed read is an error; Retry reads again, once (UC-PROGRESS-001 '
      'E1, E2)', () async {
    final failing = _FailingProgress();
    final container = libraryContainer(
      env,
      overrides: [progressRepositoryProvider.overrideWithValue(failing)],
    );
    container.listen(progressProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(progressProvider).hasError, isTrue);

    container.invalidate(progressProvider);
    await pumpEventQueue();

    expect(container.read(progressProvider).hasError, isTrue);
    expect(failing.reads, 2);
  });

  test('the range starts at 7 days and is one choice for every level (D4)', () {
    final container = libraryContainer(env);
    container.listen(progressRangeChoiceProvider, (_, _) {});
    expect(container.read(progressRangeChoiceProvider), ProgressRange.week);

    container
        .read(progressRangeChoiceProvider.notifier)
        .choose(ProgressRange.month);

    expect(container.read(progressRangeChoiceProvider), ProgressRange.month);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/presentation/progress_providers_test.dart
```

Expected: FAIL to compile: the providers do not exist.

- [ ] **Step 3: Implement**

`lib/features/progress/presentation/providers/deck_progress_provider.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/watch_deck_progress_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_progress_provider.g.dart';

/// `/progress/:deckId` (UC-PROGRESS-002 at a deck's level): the deck's path
/// and its children, or [ProgressDeckMissing]; again on every write it can
/// see and at each local midnight.
@riverpod
Stream<DeckProgress> deckProgress(Ref ref, String deckId) =>
    ref.watch(watchDeckProgressUseCaseProvider)(deckId);
```

`lib/features/progress/presentation/providers/progress_provider.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/watch_progress_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_provider.g.dart';

/// `/progress` (UC-PROGRESS-001, UC-PROGRESS-002 at the library level),
/// again on every write it can see and at each local midnight. It writes
/// nothing (BR-PROGRESS-009).
@riverpod
Stream<Progress> progress(Ref ref) => ref.watch(watchProgressUseCaseProvider)();
```

`lib/features/progress/presentation/providers/progress_range_provider.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_range_provider.g.dart';

/// The range the Progress tab shows, one choice for every level: a deck
/// opened from Last 30 days opens at Last 30 days, and Back keeps it
/// (FE-A9 D4). Switching reads nothing (BR-PROGRESS-003).
@riverpod
class ProgressRangeChoice extends _$ProgressRangeChoice {
  @override
  ProgressRange build() => ProgressRange.week;

  void choose(ProgressRange range) => state = range;
}
```

`lib/features/progress/presentation/providers/watch_deck_progress_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/usecases/watch_deck_progress_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_progress_use_case_provider.g.dart';

@riverpod
WatchDeckProgressUseCase watchDeckProgressUseCase(Ref ref) =>
    WatchDeckProgressUseCase(
      ref.watch(progressRepositoryProvider),
      ref.watch(dayClockProvider),
    );
```

`lib/features/progress/presentation/providers/watch_progress_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/usecases/watch_progress_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_progress_use_case_provider.g.dart';

@riverpod
WatchProgressUseCase watchProgressUseCase(Ref ref) => WatchProgressUseCase(
  ref.watch(progressRepositoryProvider),
  ref.watch(dayClockProvider),
);
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/progress
flutter analyze
```

Expected: PASS, 4 tests in `progress_providers_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/progress/presentation/providers/deck_progress_provider.dart \
  lib/features/progress/presentation/providers/progress_provider.dart \
  lib/features/progress/presentation/providers/progress_range_provider.dart \
  lib/features/progress/presentation/providers/watch_deck_progress_use_case_provider.dart \
  lib/features/progress/presentation/providers/watch_progress_use_case_provider.dart \
  test/features/progress/presentation/progress_providers_test.dart
git commit -m "$(cat <<'EOF'
feat(progress): the Progress reads and the tab's range (FE-A9 D3, D4)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: Screen 22, the library level

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`
- Create: `lib/features/progress/presentation/screens/progress_screen.dart`
- Create: `lib/features/progress/presentation/widgets/items/progress_deck_row_widget.dart`
- Create: `lib/features/progress/presentation/widgets/sections/progress_level_list_widget.dart`
- Create: `lib/features/progress/presentation/widgets/sections/progress_range_widget.dart`
- Create: `lib/features/progress/presentation/widgets/sections/progress_streak_widget.dart`
- Create: `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/progress/presentation/goldens/progress_error_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_error_light.png`
- Create: `test/features/progress/presentation/goldens/progress_held_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_held_light.png`
- Create: `test/features/progress/presentation/goldens/progress_loading_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_loading_light.png`
- Create: `test/features/progress/presentation/goldens/progress_lost_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_lost_light.png`
- Create: `test/features/progress/presentation/goldens/progress_month_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_month_light.png`
- Create: `test/features/progress/presentation/goldens/progress_never_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_never_light.png`
- Create: `test/features/progress/presentation/goldens/progress_no_decks_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_no_decks_light.png`
- Create: `test/features/progress/presentation/goldens/progress_quiet_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_quiet_light.png`
- Create: `test/features/progress/presentation/goldens/progress_week_dark.png`
- Create: `test/features/progress/presentation/goldens/progress_week_light.png`
- Test (create): `test/features/progress/presentation/progress_golden_test.dart`
- Test (create): `test/features/progress/presentation/progress_screen_test.dart`
- Test (create): `test/support/progress_screen_fixtures.dart`
- Test (create): `test/visual_audit/screens/features/progress/screens/progress_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 1's `MxStackedDayBars`, `MxDashedNote`, `streak`, `dayLabel`; Task 2's
  providers; `ProgressOverview` (`today`, `lastSevenDays`, `streak`, `lastActiveDay`,
  `hasLifetimeActivity`), `ProgressLevel` (`total.of`, `decksFor`, `hasDecks`).
- Produces:
  - `ProgressScreen({required ValueChanged<String> onOpenDeck, required VoidCallback
    onStartStudying})`;
  - `ProgressRangeWidget()`, `ProgressLevelListWidget({required ProgressLevel level,
    required bool isDeckLevel, required ValueChanged<String> onOpenDeck})`,
    `ProgressDeckRowWidget`, `ProgressTodayWidget`, `ProgressStreakWidget`;
  - `MxTextStyles.captionIn(Color ink)`;
  - the `progress…` ARB keys;
  - the test fixtures `studiedDeck`, `studiedSubDeck`, `progressLibrary` and the
    `StudyDay` record (`test/support/progress_screen_fixtures.dart`).

- [ ] **Step 1: Write the failing tests**

The fixtures answer learned cards on given days before the harness's Thursday
24 September, so a golden shows a real week.

`test/features/progress/presentation/progress_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 (FE-A9) against the kit's frames, at the library level: its
// decks with Latin and Vietnamese names (goldens render no Hangul).

final _en = lookupAppLocalizations(const Locale('en'));

ProgressScreen _screen() =>
    ProgressScreen(onOpenDeck: (_) {}, onStartStudying: () {});

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name, {
      List<Override> overrides = const [],
      Future<void> Function()? before,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: overrides,
        );
        await before?.call();
        await expectBoundaryGolden(
          tester,
          'goldens/progress_${name}_$theme.png',
        );
      });
    }

    libraryTest('progress, last 7 days, $theme', (tester, env) async {
      await progressLibrary(env);
      await shoot(tester, env, 'week');
    });

    libraryTest('progress, last 30 days, the list, $theme', (
      tester,
      env,
    ) async {
      await progressLibrary(env);
      await shoot(
        tester,
        env,
        'month',
        before: () async {
          await tester.tap(find.text(_en.progressRangeMonth));
          await tester.pump();
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -900),
          );
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    });

    libraryTest('progress, streak held, $theme', (tester, env) async {
      await progressLibrary(env, today: false);
      await shoot(tester, env, 'held');
    });

    libraryTest('progress, streak lost, $theme', (tester, env) async {
      await progressLibrary(env, lastDaysAgo: 2);
      await shoot(tester, env, 'lost');
    });

    libraryTest('progress, never studied, $theme', (tester, env) async {
      await studiedDeck(env, 'Tiếng Hàn TOPIK I · Từ vựng');
      await studiedDeck(env, 'IELTS Academic Word List');
      await studiedDeck(env, 'Tiếng Anh giao tiếp hằng ngày');
      await shoot(tester, env, 'never');
    });

    libraryTest('progress, a quiet week, $theme', (tester, env) async {
      await studiedDeck(
        env,
        'Korean Basics',
        days: [(daysAgo: 20, learning: 0, reviewing: 10)],
      );
      await studiedDeck(env, 'IT');
      await shoot(
        tester,
        env,
        'quiet',
        before: () async {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -900),
          );
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    });

    libraryTest('progress, no decks, $theme', (tester, env) async {
      await shoot(tester, env, 'no_decks');
    });

    libraryTest('progress, loading, $theme', (tester, env) async {
      final never = StreamController<Progress>();
      addTearDown(never.close);
      await shoot(
        tester,
        env,
        'loading',
        overrides: [progressProvider.overrideWith((ref) => never.stream)],
      );
    });

    libraryTest('progress, error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        overrides: [
          progressProvider.overrideWith(
            (ref) => Stream<Progress>.error(StateError('read failed')),
          ),
        ],
      );
    });
  }
}
```

`test/features/progress/presentation/progress_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 at the library level: UC-PROGRESS-001 (main, A1, A2, A3, E1,
// E2) and UC-PROGRESS-002 (main, A2, A3); FE-A9 D1, D2, D4, D8, D10, D11.

final _en = lookupAppLocalizations(const Locale('en'));

final class _Taps {
  final decks = <String>[];
  var study = 0;
}

ProgressScreen _screen(_Taps taps) => ProgressScreen(
  onOpenDeck: taps.decks.add,
  onStartStudying: () => taps.study++,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The row of [name], scrolled into view.
Future<Finder> _row(WidgetTester tester, String name) async {
  final row = find.widgetWithText(MxListRow, name);
  await tester.scrollUntilVisible(row, 200);
  return row;
}

void main() {
  libraryTest('Today, the seven bars, the streak, and a row per root deck '
      'with its four numbers under a total (UC-PROGRESS-001 step 4, D2)', (
    tester,
    env,
  ) async {
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text('17'), findsOneWidget);
    expect(find.text(_en.progressTodaySplit(5, 12)), findsOneWidget);
    expect(find.text(_en.progressStreakDays(4)), findsOneWidget);
    expect(find.text(_en.progressStreakIncludesToday), findsOneWidget);
    final total = await _row(tester, _en.progressAllDecks);
    expect(
      find.descendant(of: total, matching: find.text('26')),
      findsOneWidget,
    );
    final topik = await _row(tester, 'Tiếng Hàn TOPIK I · Từ vựng');
    expect(
      find.descendant(of: topik, matching: find.text('13')),
      findsOneWidget,
    );
  });

  libraryTest('the range sits above the list, after Streak (D10)', (
    tester,
    env,
  ) async {
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);
    final tray = find.byWidgetPredicate((widget) => widget is MxSegmentedTray);
    await tester.scrollUntilVisible(tray, 200);

    expect(
      tester.getTopLeft(tray).dy,
      greaterThan(
        tester
            .getBottomLeft(find.text(_en.progressStreakCurrent.toUpperCase()))
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(tray).dy,
      lessThan(tester.getTopLeft(find.text(_en.progressAllDecks)).dy),
    );
  });

  libraryTest('Last 30 days switches the numbers and the order at once, with '
      'no loading; the idle deck keeps full contrast (UC-PROGRESS-002 step 4, '
      'D11)', (tester, env) async {
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text(_en.progressRangeMonth), 200);
    await tester.tap(find.text(_en.progressRangeMonth));
    await tester.pump();

    expect(find.byType(MxSkeletonList), findsNothing);
    final basics = await _row(tester, 'Korean Basics');
    expect(
      find.descendant(of: basics, matching: find.text('10')),
      findsOneWidget,
    );
    final it = await _row(tester, 'IT');
    expect(
      find.descendant(of: it, matching: find.text(_en.progressNoActivity)),
      findsOneWidget,
    );
    expect(find.byWidgetPredicate((w) => w is Opacity), findsNothing);
  });

  libraryTest('a new answer updates the numbers with no skeleton (D8, '
      'UC-PROGRESS-001 A3)', (tester, env) async {
    await progressLibrary(env);
    final root = await env.decks.root('Fresh');
    await learnedCard(env.db, root.id, 'fresh');
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);
    expect(find.text('17'), findsOneWidget);

    await answer(env.db, 'fresh', libraryToday);
    await tester.pump();
    expect(find.byType(MxSkeletonList), findsNothing);
    await _settle(tester);

    expect(find.text('18'), findsOneWidget);
  });

  libraryTest('with nothing today but yesterday, the streak holds and says '
      'where it goes next (UC-PROGRESS-001 A1)', (tester, env) async {
    await progressLibrary(env, today: false);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(find.text(_en.progressTodayNone), findsOneWidget);
    expect(find.text(_en.progressStreakHeld), findsOneWidget);
    expect(find.text(_en.progressHeldNote(4)), findsOneWidget);
  });

  libraryTest('a lost streak names the day it ended', (tester, env) async {
    await progressLibrary(env, lastDaysAgo: 2);
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    // Last study two days before Thursday 24 September.
    expect(find.text(_en.progressLostNote('Tuesday')), findsOneWidget);
    expect(find.text(_en.progressStreakDays(0)), findsOneWidget);
  });

  libraryTest('never studied: the places of the chart and the streak, every '
      'deck at 0, and Start studying opens the Study tab (UC-PROGRESS-001 A2, '
      'D1)', (tester, env) async {
    final taps = _Taps();
    await studiedDeck(env, 'IELTS Academic Word List');
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    expect(find.byType(MxDashedNote), findsNWidgets(2));
    await tester.tap(find.text(_en.progressStartStudying));
    expect(taps.study, 1);
    final ielts = await _row(tester, 'IELTS Academic Word List');
    expect(
      find.descendant(of: ielts, matching: find.text(_en.progressNoActivity)),
      findsOneWidget,
    );
  });

  libraryTest('a quiet week says so and points to 30 days; at 30 days only '
      'the fact (UC-PROGRESS-002 A3)', (tester, env) async {
    await studiedDeck(
      env,
      'Korean Basics',
      days: [(daysAgo: 40, learning: 0, reviewing: 3)],
    );
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text(_en.progressQuietWeek), 200);
    await tester.tap(find.text(_en.progressRangeMonth));
    await tester.pump();

    expect(find.text(_en.progressQuietWeek), findsNothing);
    expect(find.text(_en.progressQuietMonth), findsOneWidget);
  });

  libraryTest('no deck: only the empty state, no range, no total '
      '(UC-PROGRESS-002 A2)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen(_Taps()));
    await _settle(tester);

    expect(
      find.widgetWithText(MxEmptyState, _en.progressNoDecksTitle),
      findsOneWidget,
    );
    expect(find.text(_en.progressRangeWeek), findsNothing);
    expect(find.text(_en.progressAllDecks), findsNothing);
  });

  libraryTest('a row opens its deck; the total is not a button', (
    tester,
    env,
  ) async {
    final taps = _Taps();
    await progressLibrary(env);
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);

    await tester.tap(await _row(tester, 'IELTS Academic Word List'));
    await tester.tap(await _row(tester, _en.progressAllDecks));

    expect(taps.decks, hasLength(1));
  });

  libraryTest('a failed read shows the error; Retry reads again '
      '(UC-PROGRESS-001 E1)', (tester, env) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [
        progressProvider.overrideWith((ref) {
          reads++;
          return Stream<Progress>.error(StateError('read failed'));
        }),
      ],
    );
    await _settle(tester);
    expect(find.text(_en.progressErrorTitle), findsOneWidget);

    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(reads, 2);
    expect(find.text(_en.progressErrorTitle), findsOneWidget);
  });

  libraryTest('loading is labelled for TalkBack', (tester, env) async {
    final never = StreamController<Progress>();
    addTearDown(never.close);
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [progressProvider.overrideWith((ref) => never.stream)],
    );

    expect(find.bySemanticsLabel(_en.progressLoading), findsOneWidget);
    handle.dispose();
  });
}
```

`test/support/progress_screen_fixtures.dart`:

```dart
import 'library_harness.dart';
import 'progress_fixtures.dart';
import 'deck_fixtures.dart';

/// One day of a deck's history: [daysAgo] before [libraryToday], with
/// [learning] cards answered while being learned and [reviewing] cards
/// answered in review, each card once (a card-day, BR-PROGRESS-011).
typedef StudyDay = ({int daysAgo, int learning, int reviewing});

/// A root deck named [name] with one "Words" sub-deck, whose cards were
/// answered on [days]; returns the root's id.
Future<String> studiedDeck(
  LibraryEnv env,
  String name, {
  List<StudyDay> days = const [],
}) async {
  final root = await env.decks.root(name);
  final words = await env.decks.sub(root.id, 'Words');
  final most = days.fold(
    0,
    (most, day) => day.learning + day.reviewing > most
        ? day.learning + day.reviewing
        : most,
  );
  for (var i = 0; i < most; i++) {
    await learnedCard(env.db, words.id, '${root.id}-$i');
  }
  if (most > 0) await lockScheduler(env.db, root.id);
  for (final day in days) {
    // Early morning of that day, before the harness's 9:00.
    final at = DateTime(
      libraryToday.year,
      libraryToday.month,
      libraryToday.day - day.daysAgo,
      8,
    );
    for (var i = 0; i < day.learning + day.reviewing; i++) {
      await answer(
        env.db,
        '${root.id}-$i',
        at,
        kind: i < day.learning ? 'learning' : 'scheduled',
      );
    }
  }
  return root.id;
}

/// Kit 22's library, with Latin and Vietnamese names (goldens render no
/// Hangul): a week of study ending today, an idle deck, and a deck last
/// studied three weeks ago. [today] false drops today's answers (the held
/// streak); [lastDaysAgo] moves every answer that many days further back
/// (the lost streak).
Future<void> progressLibrary(
  LibraryEnv env, {
  bool today = true,
  int lastDaysAgo = 0,
}) async {
  List<StudyDay> shifted(List<StudyDay> days) => [
    for (final day in days)
      if (today || day.daysAgo > 0 || lastDaysAgo > 0)
        (
          daysAgo: day.daysAgo + lastDaysAgo,
          learning: day.learning,
          reviewing: day.reviewing,
        ),
  ];
  await studiedDeck(
    env,
    'Tiếng Hàn TOPIK I · Từ vựng',
    days: shifted([
      (daysAgo: 6, learning: 3, reviewing: 5),
      (daysAgo: 5, learning: 0, reviewing: 12),
      (daysAgo: 3, learning: 4, reviewing: 9),
      (daysAgo: 2, learning: 1, reviewing: 8),
      (daysAgo: 1, learning: 0, reviewing: 6),
      (daysAgo: 0, learning: 4, reviewing: 8),
    ]),
  );
  await studiedDeck(
    env,
    'IELTS Academic Word List',
    days: shifted([
      (daysAgo: 6, learning: 1, reviewing: 3),
      (daysAgo: 5, learning: 0, reviewing: 6),
      (daysAgo: 3, learning: 2, reviewing: 7),
      (daysAgo: 0, learning: 1, reviewing: 4),
    ]),
  );
  await studiedDeck(
    env,
    'Tiếng Anh giao tiếp hằng ngày',
    days: shifted([(daysAgo: 2, learning: 0, reviewing: 4)]),
  );
  await studiedDeck(env, 'IT');
  await studiedDeck(
    env,
    'Korean Basics',
    days: shifted([(daysAgo: 20, learning: 0, reviewing: 10)]),
  );
}
```

`test/visual_audit/screens/features/progress/screens/progress_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/progress_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 22, ${locale.languageCode}', (tester, env) async {
      // The held streak: its note is the longest overview.
      await progressLibrary(env, today: false);
      await auditProductionScreen(
        tester,
        screen: ProgressScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          ProgressScreen(onOpenDeck: (_) {}, onStartStudying: () {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
        ),
      );
    });
  }
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/presentation/progress_screen_test.dart
```

Expected: FAIL to compile: `progress_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/core/theme/mx_text_styles.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/mx_text_styles.dart b/lib/core/theme/mx_text_styles.dart
index f337aa8..c64cf79 100644
--- a/lib/core/theme/mx_text_styles.dart
+++ b/lib/core/theme/mx_text_styles.dart
@@ -388,6 +388,10 @@ final class MxTextStyles {
     FontWeight.w700,
   ).copyWith(color: _scheme.onSurface);
 
+  /// A caption run in [ink], such as a Progress row's learning and
+  /// reviewing counts (kit 22): 12/600.
+  TextStyle captionIn(Color ink) => footerCaption.copyWith(color: ink);
+
   /// A summary fact's value (kit ResultRow): 16/700 tabular, in [ink].
   TextStyle factValue(Color ink) => AppTypography.withWeight(
     _texts.bodyLarge!.copyWith(fontSize: _factValueSize),
```

`lib/features/progress/presentation/screens/progress_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_level_list_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 22, the Progress tab (UC-PROGRESS-001, UC-PROGRESS-002 at the
/// library level): Today with the last seven days, the streak, the range,
/// and a row per root deck, read as one snapshot. It writes nothing
/// (BR-PROGRESS-009). Where a row and "Start studying" lead, `app/` decides.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({
    super.key,
    required this.onOpenDeck,
    required this.onStartStudying,
  });

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onStartStudying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Once shown, a new snapshot only replaces the numbers (FE-A9 D8).
    final children = switch (ref.watch(progressProvider)) {
      AsyncError() => [
        MxErrorState(
          title: l10n.progressErrorTitle,
          body: l10n.progressErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(progressProvider),
        ),
      ],
      AsyncValue(:final value?) => _loaded(context, value),
      _ => [MxSkeletonList(semanticLabel: l10n.progressLoading)],
    };
    return MxAppShell(
      appBar: MxAppBar(title: l10n.progressTitle),
      body: MxScreenScroll(children: children),
    );
  }

  List<Widget> _loaded(BuildContext context, Progress progress) {
    final l10n = context.l10n;
    // No deck, no range to show (UC-PROGRESS-002 A2).
    if (!progress.level.hasDecks) {
      return [
        MxEmptyState(
          icon: AppIcons.progress,
          title: l10n.progressNoDecksTitle,
          body: l10n.progressNoDecksBody,
          tone: MxEmptyStateTone.neutral,
        ),
      ];
    }
    return [
      ProgressTodayWidget(
        overview: progress.overview,
        onStartStudying: onStartStudying,
      ),
      const SizedBox(height: AppSpacing.grouped),
      ProgressStreakWidget(overview: progress.overview),
      const SizedBox(height: AppSpacing.gutter),
      // Above the list it changes; Today and Streak never do (FE-A9 D10).
      const ProgressRangeWidget(),
      const SizedBox(height: AppSpacing.gutter),
      ProgressLevelListWidget(
        level: progress.level,
        isDeckLevel: false,
        onOpenDeck: onOpenDeck,
      ),
    ];
  }
}
```

`lib/features/progress/presentation/widgets/items/progress_deck_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One row of a Progress level (kit 22): a deck, or the level's total
/// (FE-A9 D2), with the four numbers of the range (BR-PROGRESS-001). A deck
/// opens its own level; the total is not a button. A row with no activity
/// keeps full contrast and says so (D11).
class ProgressDeckRowWidget extends StatelessWidget {
  const ProgressDeckRowWidget({
    super.key,
    required this.name,
    required this.numbers,
    required this.hasDivider,
    this.onOpen,
  });

  final String name;
  final ProgressNumbers numbers;
  final bool hasDivider;

  /// Null for the total row.
  final VoidCallback? onOpen;

  static const String _separator = ' · ';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final colors = context.colors;
    final derived = context.derivedColors;
    final caption = styles.footerCaption;
    final isActive = numbers.hasActivity;
    return MxListRow(
      title: name,
      meta: isActive
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.progressRowDays(numbers.activeDays)),
                  const TextSpan(text: _separator),
                  TextSpan(
                    text: l10n.progressRowLearning(numbers.learningCardDays),
                    style: styles.captionIn(derived.statusLearningInk),
                  ),
                  const TextSpan(text: _separator),
                  TextSpan(
                    text: l10n.progressRowReviewing(numbers.reviewingCardDays),
                    style: styles.captionIn(derived.primaryInk),
                  ),
                ],
              ),
              style: caption,
            )
          : Text(l10n.progressNoActivity, style: caption),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${numbers.activeCards}',
            style: styles.factValue(
              isActive ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
          Text(l10n.progressRowCards, style: caption),
        ],
      ),
      onTap: onOpen,
      hasDivider: hasDivider,
    );
  }
}
```

`lib/features/progress/presentation/widgets/sections/progress_level_list_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_range_provider.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// A level's list (UC-PROGRESS-002 steps 1–3): the header of the range, the
/// total row (FE-A9 D2), a row per deck in the range's order
/// (BR-PROGRESS-006), the notes of a quiet range (A3) and of a deck with no
/// children (A1), and the read-only line.
class ProgressLevelListWidget extends ConsumerWidget {
  const ProgressLevelListWidget({
    super.key,
    required this.level,
    required this.isDeckLevel,
    required this.onOpenDeck,
  });

  final ProgressLevel level;

  /// A deck's level: "Sub-decks" and "Whole deck"; the library's otherwise.
  final bool isDeckLevel;
  final ValueChanged<String> onOpenDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(progressRangeChoiceProvider);
    final total = level.total.of(range);
    final decks = level.decksFor(range);
    final header = switch ((isDeckLevel, range)) {
      (false, ProgressRange.week) => l10n.progressByDeckWeek,
      (false, ProgressRange.month) => l10n.progressByDeckMonth,
      (true, ProgressRange.week) => l10n.progressSubDecksWeek,
      (true, ProgressRange.month) => l10n.progressSubDecksMonth,
    };
    final note = switch ((decks.isEmpty, total.hasActivity, range)) {
      (true, _, _) => l10n.progressLeafNote,
      (false, false, ProgressRange.week) => l10n.progressQuietWeek,
      (false, false, ProgressRange.month) => l10n.progressQuietMonth,
      (false, true, _) => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: header),
        MxCard(
          isFullBleed: true,
          child: Column(
            children: [
              ProgressDeckRowWidget(
                name: isDeckLevel
                    ? l10n.progressWholeDeck
                    : l10n.progressAllDecks,
                numbers: total,
                hasDivider: decks.isNotEmpty,
              ),
              for (final (index, deck) in decks.indexed)
                ProgressDeckRowWidget(
                  name: deck.name,
                  numbers: deck.progress.of(range),
                  hasDivider: index < decks.length - 1,
                  onOpen: () => onOpenDeck(deck.deckId),
                ),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.grouped),
          MxNote(text: note),
        ],
        const SizedBox(height: AppSpacing.gutter),
        Text(
          l10n.progressFooter,
          textAlign: TextAlign.center,
          style: context.textStyles.footerCaption,
        ),
      ],
    );
  }
}
```

`lib/features/progress/presentation/widgets/sections/progress_range_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_range_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

/// The range tray, Last 7 days or Last 30 days (BR-PROGRESS-003): the tab's
/// one choice (FE-A9 D4). Switching reads nothing.
class ProgressRangeWidget extends ConsumerWidget {
  const ProgressRangeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MxSegmentedTray<ProgressRange>(
        segments: [
          MxSegment(value: ProgressRange.week, label: l10n.progressRangeWeek),
          MxSegment(value: ProgressRange.month, label: l10n.progressRangeMonth),
        ],
        selected: ref.watch(progressRangeChoiceProvider),
        onSelected: (range) => _choose(ref, range),
        isWide: true,
      ),
    );
  }

  void _choose(WidgetRef ref, ProgressRange range) =>
      ref.read(progressRangeChoiceProvider.notifier).choose(range);
}
```

`lib/features/progress/presentation/widgets/sections/progress_streak_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// The current streak (BR-PROGRESS-016): its days and how it stands, beside
/// today's count, with a note when it is held from yesterday or lost. With
/// nothing ever studied, the streak's place.
class ProgressStreakWidget extends StatelessWidget {
  const ProgressStreakWidget({super.key, required this.overview});

  final ProgressOverview overview;

  /// A lost streak names its last day by weekday within this many days, and
  /// by date beyond.
  static const int _weekdayReach = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final streak = overview.streak;
    final note = switch (streak.state) {
      StreakState.heldFromYesterday => l10n.progressHeldNote(streak.days + 1),
      StreakState.lost => l10n.progressLostNote(_lastDay(context)),
      StreakState.includesToday || StreakState.never => null,
    };
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.progressStreak.toUpperCase(),
            semanticsLabel: l10n.progressStreak,
            style: context.textStyles.overline,
          ),
          const SizedBox(height: AppSpacing.grouped),
          if (streak.state == StreakState.never)
            MxDashedNote(text: l10n.progressNeverStreak)
          else
            _tiles(context),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxNote(text: note),
          ],
        ],
      ),
    );
  }

  Widget _tiles(BuildContext context) {
    final l10n = context.l10n;
    final streak = overview.streak;
    final todayCount = overview.today.total;
    final current = _StreakTile(
      icon: AppIcons.streak,
      tint: streak.days > 0
          ? context.semanticColors.streak
          : context.colors.onSurfaceVariant,
      label: l10n.progressStreakCurrent,
      value: l10n.progressStreakDays(streak.days),
      sub: switch (streak.state) {
        StreakState.includesToday => l10n.progressStreakIncludesToday,
        StreakState.heldFromYesterday => l10n.progressStreakHeld,
        StreakState.lost || StreakState.never => l10n.progressStreakLost,
      },
    );
    final today = _StreakTile(
      icon: AppIcons.studiedToday,
      label: l10n.progressToday,
      value: l10n.progressTodayCards(todayCount),
      sub: todayCount == 0
          ? l10n.progressTodayNothing
          : l10n.progressTodayCounted,
    );
    return Row(
      spacing: AppSpacing.control,
      children: [
        Expanded(child: current),
        Expanded(child: today),
      ],
    );
  }

  String _lastDay(BuildContext context) {
    final locale = context.l10n.localeName;
    final last = overview.lastActiveDay!;
    final gap = overview.today.date.difference(last).inDays;
    return gap <= _weekdayReach
        ? DateFormat.EEEE(locale).format(last)
        : DateFormat.MMMd(locale).format(last);
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.tint,
  });

  final IconData icon;

  /// Null tints with primary.
  final Color? tint;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    // The kit's tile: the recessed ground at a 12 inset, tighter than a card,
    // so two fit side by side on a phone.
    return DecoratedBox(
      decoration: AppDecorations.recessedCard(
        context.colors,
        context.derivedColors,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.grouped),
        child: Row(
          spacing: AppSpacing.control,
          children: [
            MxIconTile(icon: icon, seed: tint),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    semanticsLabel: label,
                    style: styles.compactOverline,
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(value, style: styles.summaryBodyStrong),
                  Text(sub, style: styles.footerCaption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/progress/presentation/widgets/sections/progress_today_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

/// Today and the last seven days (UC-PROGRESS-001 step 4; BR-PROGRESS-014,
/// BR-PROGRESS-015): today's card-days split into learning and reviewing,
/// and a bar per day. With nothing ever studied, the chart's place and a way
/// to the Study tab (FE-A9 D1).
class ProgressTodayWidget extends StatelessWidget {
  const ProgressTodayWidget({
    super.key,
    required this.overview,
    required this.onStartStudying,
  });

  final ProgressOverview overview;
  final VoidCallback onStartStudying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final today = overview.today;
    final isNever = !overview.hasLifetimeActivity;
    final sub = switch ((isNever, today.total)) {
      (true, _) => l10n.progressNothingYet,
      (false, 0) => l10n.progressTodayNone,
      _ => l10n.progressTodaySplit(today.learning, today.reviewing),
    };
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.progressToday.toUpperCase(),
            semanticsLabel: l10n.progressToday,
            style: styles.overline,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            '${today.total}',
            style: styles.statValue(context.colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(sub, style: styles.footerCaption),
          const SizedBox(height: AppSpacing.grouped),
          if (isNever) ...[
            MxDashedNote(text: l10n.progressNeverChart),
            const SizedBox(height: AppSpacing.grouped),
            MxButton(
              label: l10n.progressStartStudying,
              icon: AppIcons.play,
              tone: MxButtonTone.secondary,
              isBlock: true,
              onPressed: onStartStudying,
            ),
          ] else
            _chart(context),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context) {
    final l10n = context.l10n;
    final narrow = DateFormat('EEEEE', l10n.localeName);
    final weekday = DateFormat.EEEE(l10n.localeName);
    final days = overview.lastSevenDays;
    return MxStackedDayBars(
      days: [
        for (final (index, day) in days.indexed)
          MxDayBar(
            label: index == days.length - 1
                ? l10n.progressToday
                : narrow.format(day.date),
            base: day.reviewing,
            top: day.learning,
            isCurrent: index == days.length - 1,
            semanticLabel: l10n.progressDayBar(
              weekday.format(day.date),
              day.total,
              day.learning,
              day.reviewing,
            ),
          ),
      ],
      base: MxBarSeries(
        label: l10n.progressReviewing,
        color: context.colors.primary,
      ),
      top: MxBarSeries(
        label: l10n.progressLearning,
        color: context.semanticColors.statusLearning,
      ),
    );
  }
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index b033d0b..e404714 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -4602,6 +4602,239 @@
     },
     "description": "Screen handoff 13 (FE-A8): a deck row's badge."
   },
+  "progressTitle": "Progress",
+  "@progressTitle": {
+    "description": "Screen handoff 22 (FE-A9): the Progress tab's app bar title."
+  },
+  "progressToday": "Today",
+  "@progressToday": {
+    "description": "Screen handoff 22 (FE-A9): the Today card's overline, and the last day bar's label."
+  },
+  "progressTodaySplit": "{learning} learning · {reviewing} reviewing · a card counts once per day",
+  "@progressTodaySplit": {
+    "placeholders": {
+      "learning": {
+        "type": "int"
+      },
+      "reviewing": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): Today's sub-line: its card-days split into learning and reviewing."
+  },
+  "progressTodayNone": "No cards studied yet today",
+  "@progressTodayNone": {
+    "description": "Screen handoff 22 (FE-A9): Today's sub-line when today has no card-day."
+  },
+  "progressNothingYet": "Nothing studied yet",
+  "@progressNothingYet": {
+    "description": "Screen handoff 22 (FE-A9): Today's sub-line when nothing was ever studied."
+  },
+  "progressLearning": "Learning",
+  "@progressLearning": {
+    "description": "Screen handoff 22 (FE-A9): the chart legend's learning series."
+  },
+  "progressReviewing": "Reviewing",
+  "@progressReviewing": {
+    "description": "Screen handoff 22 (FE-A9): the chart legend's reviewing series."
+  },
+  "progressDayBar": "{day}: {total, plural, =1{1 card} other{{total} cards}}, {learning} learning, {reviewing} reviewing",
+  "@progressDayBar": {
+    "placeholders": {
+      "day": {
+        "type": "String"
+      },
+      "total": {
+        "type": "int"
+      },
+      "learning": {
+        "type": "int"
+      },
+      "reviewing": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): what TalkBack reads for one day bar; day is the weekday name."
+  },
+  "progressStreak": "Streak",
+  "@progressStreak": {
+    "description": "Screen handoff 22 (FE-A9): the Streak card's overline."
+  },
+  "progressStreakCurrent": "Current",
+  "@progressStreakCurrent": {
+    "description": "Screen handoff 22 (FE-A9): the current streak tile's label."
+  },
+  "progressStreakDays": "{count, plural, =1{1 day} other{{count} days}}",
+  "@progressStreakDays": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): the current streak in days."
+  },
+  "progressStreakIncludesToday": "includes today",
+  "@progressStreakIncludesToday": {
+    "description": "Screen handoff 22 (FE-A9): the streak tile when today has activity."
+  },
+  "progressStreakHeld": "held from yesterday",
+  "@progressStreakHeld": {
+    "description": "Screen handoff 22 (FE-A9): the streak tile when only yesterday has activity."
+  },
+  "progressStreakLost": "no study yesterday",
+  "@progressStreakLost": {
+    "description": "Screen handoff 22 (FE-A9): the streak tile when the streak is lost."
+  },
+  "progressTodayCards": "{count, plural, =1{1 card} other{{count} cards}}",
+  "@progressTodayCards": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): the Today tile's count."
+  },
+  "progressTodayCounted": "counted once each",
+  "@progressTodayCounted": {
+    "description": "Screen handoff 22 (FE-A9): the Today tile when today has activity."
+  },
+  "progressTodayNothing": "nothing yet",
+  "@progressTodayNothing": {
+    "description": "Screen handoff 22 (FE-A9): the Today tile when today has no activity."
+  },
+  "progressHeldNote": "Study one card today and the streak continues at {next}.",
+  "@progressHeldNote": {
+    "placeholders": {
+      "next": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): the note under a streak held from yesterday."
+  },
+  "progressLostNote": "The streak ended on {day}. It starts again with the next card you study.",
+  "@progressLostNote": {
+    "placeholders": {
+      "day": {
+        "type": "String"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): the note under a lost streak; day is a weekday name or a short date."
+  },
+  "progressNeverChart": "Your last seven days appear here once you study. Browsing cards does not count.",
+  "@progressNeverChart": {
+    "description": "Screen handoff 22 (FE-A9): Today's placeholder when nothing was ever studied."
+  },
+  "progressNeverStreak": "A streak starts with your first study day.",
+  "@progressNeverStreak": {
+    "description": "Screen handoff 22 (FE-A9): the Streak card's placeholder when nothing was ever studied."
+  },
+  "progressStartStudying": "Start studying",
+  "@progressStartStudying": {
+    "description": "Screen handoff 22 (FE-A9): the button that opens the Study tab when nothing was ever studied (FE-A9 D1)."
+  },
+  "progressRangeWeek": "Last 7 days",
+  "@progressRangeWeek": {
+    "description": "Screen handoff 22 (FE-A9): the range tray option for seven days."
+  },
+  "progressRangeMonth": "Last 30 days",
+  "@progressRangeMonth": {
+    "description": "Screen handoff 22 (FE-A9): the range tray option for thirty days."
+  },
+  "progressByDeckWeek": "By deck · last 7 days",
+  "@progressByDeckWeek": {
+    "description": "Screen handoff 22 (FE-A9): the library level's list header at seven days."
+  },
+  "progressByDeckMonth": "By deck · last 30 days",
+  "@progressByDeckMonth": {
+    "description": "Screen handoff 22 (FE-A9): the library level's list header at thirty days."
+  },
+  "progressSubDecksWeek": "Sub-decks · last 7 days",
+  "@progressSubDecksWeek": {
+    "description": "Screen handoff 22 (FE-A9): a deck level's list header at seven days."
+  },
+  "progressSubDecksMonth": "Sub-decks · last 30 days",
+  "@progressSubDecksMonth": {
+    "description": "Screen handoff 22 (FE-A9): a deck level's list header at thirty days."
+  },
+  "progressAllDecks": "All decks",
+  "@progressAllDecks": {
+    "description": "Screen handoff 22 (FE-A9): the library level's total row (FE-A9 D2)."
+  },
+  "progressWholeDeck": "Whole deck",
+  "@progressWholeDeck": {
+    "description": "Screen handoff 22 (FE-A9): a deck level's total row (FE-A9 D2)."
+  },
+  "progressRowDays": "{count, plural, =1{1 active day} other{{count} active days}}",
+  "@progressRowDays": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): a row's active days in the range."
+  },
+  "progressRowLearning": "{count} learning",
+  "@progressRowLearning": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): a row's learning card-days, in the learning ink."
+  },
+  "progressRowReviewing": "{count} reviewing",
+  "@progressRowReviewing": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 22 (FE-A9): a row's reviewing card-days, in the primary ink."
+  },
+  "progressRowCards": "cards",
+  "@progressRowCards": {
+    "description": "Screen handoff 22 (FE-A9): the word under a row's active cards."
+  },
+  "progressNoActivity": "No activity in this range",
+  "@progressNoActivity": {
+    "description": "Screen handoff 22 (FE-A9): a row's sub-line when the deck has no activity in the range."
+  },
+  "progressQuietWeek": "Nothing studied in the last 7 days. Switch to Last 30 days to see older study.",
+  "@progressQuietWeek": {
+    "description": "Screen handoff 22 (FE-A9): the note when seven days have no activity (UC-PROGRESS-002 A3)."
+  },
+  "progressQuietMonth": "Nothing studied in the last 30 days.",
+  "@progressQuietMonth": {
+    "description": "Screen handoff 22 (FE-A9): the note when thirty days have no activity (UC-PROGRESS-002 A3)."
+  },
+  "progressNoDecksTitle": "No decks yet",
+  "@progressNoDecksTitle": {
+    "description": "Screen handoff 22 (FE-A9): the library level with no deck (UC-PROGRESS-002 A2)."
+  },
+  "progressNoDecksBody": "Create a deck in the Library and its progress appears here.",
+  "@progressNoDecksBody": {
+    "description": "Screen handoff 22 (FE-A9): the body of the library level with no deck."
+  },
+  "progressLeafNote": "This deck holds its cards directly, so the total above is all of it.",
+  "@progressLeafNote": {
+    "description": "Screen handoff 22 (FE-A9): a deck level with no sub-deck (UC-PROGRESS-002 A1)."
+  },
+  "progressFooter": "Read-only · a card studied several times in a day counts once · resets change nothing here",
+  "@progressFooter": {
+    "description": "Screen handoff 22 (FE-A9): the line at the end of every level."
+  },
+  "progressErrorTitle": "Couldn't summarise your progress",
+  "@progressErrorTitle": {
+    "description": "Screen handoff 22 (FE-A9): the error state (UC-PROGRESS-001 E1)."
+  },
+  "progressErrorBody": "Your study history is safe on this device. Try again in a moment.",
+  "@progressErrorBody": {
+    "description": "Screen handoff 22 (FE-A9): the error state's body."
+  },
+  "progressLoading": "Loading your progress",
+  "@progressLoading": {
+    "description": "Screen handoff 22 (FE-A9): what TalkBack reads while the screen loads."
+  },
   "studyHomeNoDecksTitle": "Nothing to study yet",
   "@studyHomeNoDecksTitle": {
     "description": "Screen handoff 13 (FE-A8): no root deck."
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 4401277..ce81845 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -864,6 +864,50 @@
   "studyHomeDecks": "Bộ thẻ của bạn",
   "studyHomeLibrary": "Thư viện",
   "studyHomeRowDue": "{count} đến hạn",
+  "progressTitle": "Tiến độ",
+  "progressToday": "Hôm nay",
+  "progressTodaySplit": "{learning} học mới · {reviewing} ôn tập · mỗi thẻ tính một lần mỗi ngày",
+  "progressTodayNone": "Hôm nay chưa học thẻ nào",
+  "progressNothingYet": "Chưa học gì",
+  "progressLearning": "Học mới",
+  "progressReviewing": "Ôn tập",
+  "progressDayBar": "{day}: {total} thẻ, {learning} học mới, {reviewing} ôn tập",
+  "progressStreak": "Chuỗi ngày học",
+  "progressStreakCurrent": "Hiện tại",
+  "progressStreakDays": "{count} ngày",
+  "progressStreakIncludesToday": "tính cả hôm nay",
+  "progressStreakHeld": "giữ từ hôm qua",
+  "progressStreakLost": "hôm qua không học",
+  "progressTodayCards": "{count} thẻ",
+  "progressTodayCounted": "mỗi thẻ tính một lần",
+  "progressTodayNothing": "chưa có gì",
+  "progressHeldNote": "Học một thẻ hôm nay để chuỗi tiếp tục lên {next} ngày.",
+  "progressLostNote": "Chuỗi đã dừng vào {day}. Chuỗi mới bắt đầu từ thẻ tiếp theo bạn học.",
+  "progressNeverChart": "Bảy ngày gần nhất sẽ hiện ở đây khi bạn học. Chỉ lướt thẻ thì không tính.",
+  "progressNeverStreak": "Chuỗi bắt đầu từ ngày học đầu tiên của bạn.",
+  "progressStartStudying": "Bắt đầu học",
+  "progressRangeWeek": "7 ngày qua",
+  "progressRangeMonth": "30 ngày qua",
+  "progressByDeckWeek": "Theo deck · 7 ngày qua",
+  "progressByDeckMonth": "Theo deck · 30 ngày qua",
+  "progressSubDecksWeek": "Deck con · 7 ngày qua",
+  "progressSubDecksMonth": "Deck con · 30 ngày qua",
+  "progressAllDecks": "Tất cả deck",
+  "progressWholeDeck": "Cả deck",
+  "progressRowDays": "{count} ngày có học",
+  "progressRowLearning": "{count} học mới",
+  "progressRowReviewing": "{count} ôn tập",
+  "progressRowCards": "thẻ",
+  "progressNoActivity": "Không có hoạt động trong khoảng này",
+  "progressQuietWeek": "Không học gì trong 7 ngày qua. Chuyển sang 30 ngày qua để xem những lần học cũ hơn.",
+  "progressQuietMonth": "Không học gì trong 30 ngày qua.",
+  "progressNoDecksTitle": "Chưa có deck nào",
+  "progressNoDecksBody": "Tạo một deck trong Thư viện, tiến độ của nó sẽ hiện ở đây.",
+  "progressLeafNote": "Deck này chứa thẻ trực tiếp, nên tổng ở trên đã là toàn bộ.",
+  "progressFooter": "Chỉ đọc · một thẻ học nhiều lần trong ngày chỉ tính một lần · đặt lại không đổi gì ở đây",
+  "progressErrorTitle": "Không tổng hợp được tiến độ",
+  "progressErrorBody": "Lịch sử học vẫn an toàn trên thiết bị này. Hãy thử lại sau giây lát.",
+  "progressLoading": "Đang tải tiến độ",
   "studyHomeNoDecksTitle": "Chưa có gì để học",
   "studyHomeNoDecksBody": "Thư viện đang trống. Hãy tạo một bộ thẻ trong Thư viện để bắt đầu.",
   "studyHomeNoCardsTitle": "Các bộ thẻ chưa có thẻ nào",
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
TZ=UTC flutter test --tags golden --update-goldens test/features/progress/presentation/progress_golden_test.dart
flutter test test/features/progress test/visual_audit test/l10n
flutter analyze
```

Expected: PASS, 12 tests in `progress_screen_test.dart` and the audit in English and
Vietnamese. Eighteen new goldens; compare each with
`docs/shared/ui/screen-handoff/img/22-progress/`:
- `progress_week_*` with `loaded-*`: Today 17 with its split, the seven bars ending
  "Today", the streak tiles, then the tray above "By deck" (D10);
- `progress_month_*` with `month-*`, scrolled: "All decks" then each deck with its 30-day
  numbers; "IT" reads "No activity in this range" at full contrast (D11);
- `progress_held_*`, `progress_lost_*` and `progress_never_*` with their frames, "Start
  studying" under Today's placeholder (D1);
- `progress_loading_*` (skeleton rows, C6), `progress_error_*`, and the two states the
  kit lacks, `progress_quiet_*` (A3) and `progress_no_decks_*` (A2).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/theme/mx_text_styles.dart \
  lib/features/progress/presentation/screens/progress_screen.dart \
  lib/features/progress/presentation/widgets/items/progress_deck_row_widget.dart \
  lib/features/progress/presentation/widgets/sections/progress_level_list_widget.dart \
  lib/features/progress/presentation/widgets/sections/progress_range_widget.dart \
  lib/features/progress/presentation/widgets/sections/progress_streak_widget.dart \
  lib/features/progress/presentation/widgets/sections/progress_today_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/progress/presentation/progress_golden_test.dart \
  test/features/progress/presentation/progress_screen_test.dart \
  test/support/progress_screen_fixtures.dart \
  test/visual_audit/screens/features/progress/screens/progress_screen_visual_audit_test.dart \
  test/features/progress/presentation/goldens/progress_error_dark.png \
  test/features/progress/presentation/goldens/progress_error_light.png \
  test/features/progress/presentation/goldens/progress_held_dark.png \
  test/features/progress/presentation/goldens/progress_held_light.png \
  test/features/progress/presentation/goldens/progress_loading_dark.png \
  test/features/progress/presentation/goldens/progress_loading_light.png \
  test/features/progress/presentation/goldens/progress_lost_dark.png \
  test/features/progress/presentation/goldens/progress_lost_light.png \
  test/features/progress/presentation/goldens/progress_month_dark.png \
  test/features/progress/presentation/goldens/progress_month_light.png \
  test/features/progress/presentation/goldens/progress_never_dark.png \
  test/features/progress/presentation/goldens/progress_never_light.png \
  test/features/progress/presentation/goldens/progress_no_decks_dark.png \
  test/features/progress/presentation/goldens/progress_no_decks_light.png \
  test/features/progress/presentation/goldens/progress_quiet_dark.png \
  test/features/progress/presentation/goldens/progress_quiet_light.png \
  test/features/progress/presentation/goldens/progress_week_dark.png \
  test/features/progress/presentation/goldens/progress_week_light.png
git commit -m "$(cat <<'EOF'
feat(progress): screen 22, the library level (FE-A9, UC-PROGRESS-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: A deck's level and the Progress routes (D5, D9)

**Files:**
- Delete: `lib/app/placeholder_screen.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/app/router/app_routes.dart`
- Create: `lib/features/progress/presentation/screens/deck_progress_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/progress/presentation/goldens/deck_progress_deck_dark.png`
- Create: `test/features/progress/presentation/goldens/deck_progress_deck_light.png`
- Create: `test/features/progress/presentation/goldens/deck_progress_gone_dark.png`
- Create: `test/features/progress/presentation/goldens/deck_progress_gone_light.png`
- Create: `test/features/progress/presentation/goldens/deck_progress_leaf_dark.png`
- Create: `test/features/progress/presentation/goldens/deck_progress_leaf_light.png`
- Test (modify): `test/app/app_test.dart`
- Test (modify): `test/app/l10n_test.dart`
- Test (create): `test/app/progress_routes_test.dart`
- Test (modify): `test/app/settings_routes_test.dart`
- Test (create): `test/features/progress/presentation/deck_progress_golden_test.dart`
- Test (create): `test/features/progress/presentation/deck_progress_screen_test.dart`
- Test (modify): `test/support/progress_screen_fixtures.dart`
- Test (delete): `test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart`
- Test (create): `test/visual_audit/screens/features/progress/screens/deck_progress_screen_visual_audit_test.dart`
- Test (modify): `test/visual_audit/screens/screen_audit_coverage_test.dart`

**Interfaces:**
- Consumes: Task 2's `deckProgressProvider`; Task 3's `ProgressScreen`,
  `ProgressRangeWidget`, `ProgressLevelListWidget` and fixtures.
- Produces:
  - `DeckProgressScreen({required String deckId, required ValueChanged<String>
    onOpenDeck, required ValueChanged<String?> onOpenAncestor})`;
  - `AppRoutes.progressDeckChild` (`:deckId`) and `AppRoutes.progressDeck(deckId)`;
  - `_openAncestor(context, deckId, {levelOf})` in `app_router.dart`;
  - `PlaceholderScreen`, `placeholderTitle` and `placeholderBody` removed (C3).

- [ ] **Step 1: Write the failing tests**

`test/app/app_test.dart` (apply this diff):

```diff
diff --git a/test/app/app_test.dart b/test/app/app_test.dart
index a5fcd15..2e70395 100644
--- a/test/app/app_test.dart
+++ b/test/app/app_test.dart
@@ -108,19 +108,17 @@ void main() {
   });
 
   libraryTest('Library opens on its screen; Study shows Study Home (FE-A8); '
-      'Progress is still a placeholder', (tester, env) async {
+      'Progress shows screen 22 (FE-A9)', (tester, env) async {
     await _pumpApp(tester, env);
     expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
-    expect(find.text(_en.placeholderTitle), findsNothing);
 
     await tester.tap(_tab(_en.navStudy));
     await tester.pumpAndSettle();
     expect(find.text(_en.studyHomeNoDecksTitle), findsOneWidget);
-    expect(find.text(_en.placeholderTitle), findsNothing);
 
     await tester.tap(_tab(_en.navProgress));
     await tester.pumpAndSettle();
-    expect(find.text(_en.placeholderTitle), findsOneWidget);
+    expect(find.text(_en.progressNoDecksTitle), findsOneWidget);
   });
 
   libraryTest('Vietnamese device locale gives Vietnamese tabs', (
```

`test/app/l10n_test.dart` (apply this diff):

```diff
diff --git a/test/app/l10n_test.dart b/test/app/l10n_test.dart
index 311ed9e..7dc977c 100644
--- a/test/app/l10n_test.dart
+++ b/test/app/l10n_test.dart
@@ -53,13 +53,13 @@ void main() {
         supportedLocales: AppLocalizations.supportedLocales,
         home: Builder(
           builder: (context) {
-            title = context.l10n.placeholderTitle;
+            title = context.l10n.navProgress;
             return const SizedBox.shrink();
           },
         ),
       ),
     );
 
-    expect(title, 'Sắp có');
+    expect(title, 'Tiến độ');
   });
 }
```

`test/app/progress_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/progress_screen_fixtures.dart';

// Screen 22's levels in the app (FE-A9 D1, D4, D5; UC-PROGRESS-002 step 5).

final _en = lookupAppLocalizations(const Locale('en'));

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openRow(WidgetTester tester, String name) async {
  final row = find.widgetWithText(MxListRow, name);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await _tap(tester, row);
}

/// Korean › Grammar › Particles, each studied today.
Future<void> _tree(LibraryEnv env) async {
  final korean = await studiedDeck(
    env,
    'Korean',
    days: [(daysAgo: 0, learning: 0, reviewing: 2)],
  );
  final grammar = await env.decks.sub(korean, 'Grammar');
  await env.decks.sub(grammar.id, 'Particles');
}

void main() {
  libraryTest('a row opens its level under the tab bar, keeping the range; '
      'Back climbs one level (D4, D5)', (tester, env) async {
    await _tree(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navProgress));
    await tester.scrollUntilVisible(find.text(_en.progressRangeMonth), 200);
    await _tap(tester, find.text(_en.progressRangeMonth));

    await _openRow(tester, 'Korean');

    expect(find.byType(DeckProgressScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
    expect(find.text(_en.progressSubDecksMonth.toUpperCase()), findsOneWidget);

    await _openRow(tester, 'Grammar');
    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.text('Grammar'),
      ),
      findsOneWidget,
    );

    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(
      find.descendant(of: find.byType(MxAppBar), matching: find.text('Korean')),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.byType(DeckProgressScreen), findsNothing);
  });

  libraryTest("the path's Progress segment returns to the library level", (
    tester,
    env,
  ) async {
    await _tree(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navProgress));
    await _openRow(tester, 'Korean');
    await _openRow(tester, 'Grammar');

    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.text(_en.progressTitle),
      ),
    );

    expect(find.byType(DeckProgressScreen), findsNothing);
    expect(find.byType(ProgressScreen), findsOneWidget);
  });

  libraryTest('Start studying opens the Study tab (D1)', (tester, env) async {
    await studiedDeck(env, 'Korean');
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navProgress));

    await _tap(tester, find.text(_en.progressStartStudying));

    expect(find.byType(StudyHomeScreen), findsOneWidget);
  });
}
```

`test/app/settings_routes_test.dart` (apply this diff):

```diff
diff --git a/test/app/settings_routes_test.dart b/test/app/settings_routes_test.dart
index 8985831..02f4faf 100644
--- a/test/app/settings_routes_test.dart
+++ b/test/app/settings_routes_test.dart
@@ -1,6 +1,5 @@
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
-import 'package:memox/app/placeholder_screen.dart';
 import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
 import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
 import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
@@ -28,15 +27,11 @@ Future<void> _tap(WidgetTester tester, Finder finder) async {
 
 /// The routes around Settings (FE-A3).
 void main() {
-  libraryTest('the Settings tab is screen 23, not a placeholder', (
-    tester,
-    env,
-  ) async {
+  libraryTest('the Settings tab is screen 23', (tester, env) async {
     await pumpMemoxApp(tester, env);
     await _tap(tester, _tab(_en.navSettings));
 
     expect(find.byType(SettingsScreen), findsOneWidget);
-    expect(find.byType(PlaceholderScreen), findsNothing);
   });
 
   for (final (row, title) in [
```

`test/features/progress/presentation/deck_progress_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 inside a deck (FE-A9) against the kit's "Inside a deck", with
// the Korean names in Vietnamese; and the two states the kit lacks: a deck
// with no children (A1) and a deck that is gone (E2).

DeckProgressScreen _screen(String deckId) => DeckProgressScreen(
  deckId: deckId,
  onOpenDeck: (_) {},
  onOpenAncestor: (_) {},
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String deckId,
      String name,
    ) => withRealShadows(() async {
      await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
      await expectBoundaryGolden(
        tester,
        'goldens/deck_progress_${name}_$theme.png',
      );
    });

    libraryTest('deck progress, inside a deck, $theme', (tester, env) async {
      final root = await env.decks.root('Tiếng Hàn TOPIK I · Từ vựng');
      Future<void> child(String name, List<StudyDay> days) =>
          studiedSubDeck(env, root.id, root.id, name, days: days);
      await child('Động từ', [
        (daysAgo: 4, learning: 3, reviewing: 5),
        (daysAgo: 1, learning: 2, reviewing: 6),
        (daysAgo: 0, learning: 1, reviewing: 9),
      ]);
      await child('Danh từ', [
        (daysAgo: 3, learning: 2, reviewing: 6),
        (daysAgo: 0, learning: 2, reviewing: 7),
      ]);
      await child('Trạng từ', [(daysAgo: 2, learning: 0, reviewing: 4)]);
      await child('Tính từ', []);
      await shoot(tester, env, root.id, 'deck');
    });

    libraryTest('deck progress, no sub-decks, $theme', (tester, env) async {
      final root = await env.decks.root('Tiếng Hàn TOPIK I · Từ vựng');
      final verbs = await studiedSubDeck(
        env,
        root.id,
        root.id,
        'Động từ',
        days: [(daysAgo: 1, learning: 2, reviewing: 6)],
      );
      await shoot(tester, env, verbs, 'leaf');
    });

    libraryTest('deck progress, gone, $theme', (tester, env) async {
      final root = await env.decks.root('Korean');
      await env.decks.deleteDeck(deckId: root.id);
      await shoot(tester, env, root.id, 'gone');
    });
  }
}
```

`test/features/progress/presentation/deck_progress_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/deck_progress_provider.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 at a deck's level: UC-PROGRESS-002 (steps 1, 5; A1; E1; E2),
// FE-A9 D2, D5.

final _en = lookupAppLocalizations(const Locale('en'));

final class _Taps {
  final decks = <String>[];
  final ancestors = <String?>[];
}

DeckProgressScreen _screen(String deckId, _Taps taps) => DeckProgressScreen(
  deckId: deckId,
  onOpenDeck: taps.decks.add,
  onOpenAncestor: taps.ancestors.add,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  libraryTest("the deck's path, its whole-deck total and a row per child; a "
      'row opens the child, a segment its level (steps 1, 5; D2)', (
    tester,
    env,
  ) async {
    final taps = _Taps();
    final korean = await studiedDeck(
      env,
      'Korean',
      days: [(daysAgo: 0, learning: 1, reviewing: 2)],
    );
    final grammar = await env.decks.sub(korean, 'Grammar');
    await pumpLibraryScreen(tester, env, _screen(korean, taps));
    await _settle(tester);

    expect(find.text(_en.progressToday.toUpperCase()), findsNothing);
    final whole = find.widgetWithText(MxListRow, _en.progressWholeDeck);
    expect(
      find.descendant(of: whole, matching: find.text('3')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(MxListRow, 'Grammar'));
    await tester.tap(
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.text(_en.progressTitle),
      ),
    );

    expect(taps.decks, [grammar.id]);
    expect(taps.ancestors, [null]);
  });

  libraryTest('a deck with no children keeps its total and says it is all of '
      'it (A1)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final words = await env.decks.sub(root.id, 'Words');
    await pumpLibraryScreen(tester, env, _screen(words.id, _Taps()));
    await _settle(tester);

    expect(find.text(_en.progressWholeDeck), findsOneWidget);
    expect(find.text(_en.progressLeafNote), findsOneWidget);
  });

  libraryTest('a deck gone to the Trash offers Back only, no Retry (E2)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    await env.decks.deleteDeck(deckId: root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id, _Taps()));
    await _settle(tester);

    expect(
      find.widgetWithText(MxEmptyState, _en.deckGoneTitle),
      findsOneWidget,
    );
    expect(find.text(_en.commonBack), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
  });

  libraryTest('a failed read shows the error with Retry (E1)', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any', _Taps()),
      overrides: [
        deckProgressProvider('any').overrideWith((ref) {
          reads++;
          return Stream<DeckProgress>.error(StateError('read failed'));
        }),
      ],
    );
    await _settle(tester);
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(find.text(_en.progressErrorTitle), findsOneWidget);
    expect(reads, 2);
  });
}
```

`test/support/progress_screen_fixtures.dart` (apply this diff):

```diff
diff --git a/test/support/progress_screen_fixtures.dart b/test/support/progress_screen_fixtures.dart
index d25fdca..25ae847 100644
--- a/test/support/progress_screen_fixtures.dart
+++ b/test/support/progress_screen_fixtures.dart
@@ -16,6 +16,32 @@ Future<String> studiedDeck(
 }) async {
   final root = await env.decks.root(name);
   final words = await env.decks.sub(root.id, 'Words');
+  await _study(env, root.id, words.id, days);
+  return root.id;
+}
+
+/// A sub-deck of [parentId] under the root [rootId], holding its own cards
+/// answered on [days]; returns its id.
+Future<String> studiedSubDeck(
+  LibraryEnv env,
+  String rootId,
+  String parentId,
+  String name, {
+  List<StudyDay> days = const [],
+}) async {
+  final deck = await env.decks.sub(parentId, name);
+  await _study(env, rootId, deck.id, days);
+  return deck.id;
+}
+
+/// Learned cards of [deckId], as many as the fullest of [days] needs, each
+/// answered once on each day that uses it.
+Future<void> _study(
+  LibraryEnv env,
+  String rootId,
+  String deckId,
+  List<StudyDay> days,
+) async {
   final most = days.fold(
     0,
     (most, day) => day.learning + day.reviewing > most
@@ -23,9 +49,9 @@ Future<String> studiedDeck(
         : most,
   );
   for (var i = 0; i < most; i++) {
-    await learnedCard(env.db, words.id, '${root.id}-$i');
+    await learnedCard(env.db, deckId, '$deckId-$i');
   }
-  if (most > 0) await lockScheduler(env.db, root.id);
+  if (most > 0) await lockScheduler(env.db, rootId);
   for (final day in days) {
     // Early morning of that day, before the harness's 9:00.
     final at = DateTime(
@@ -37,13 +63,12 @@ Future<String> studiedDeck(
     for (var i = 0; i < day.learning + day.reviewing; i++) {
       await answer(
         env.db,
-        '${root.id}-$i',
+        '$deckId-$i',
         at,
         kind: i < day.learning ? 'learning' : 'scheduled',
       );
     }
   }
-  return root.id;
 }
 
 /// Kit 22's library, with Latin and Vietnamese names (goldens render no
```

`test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart`: delete it.

```bash
git rm test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart
```

`test/visual_audit/screens/features/progress/screens/deck_progress_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../../support/progress_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 22 inside a deck, ${locale.languageCode}', (
      tester,
      env,
    ) async {
      final root = await env.decks.root('Tiếng Hàn TOPIK I · Từ vựng');
      await studiedSubDeck(
        env,
        root.id,
        root.id,
        'Động từ',
        days: [(daysAgo: 0, learning: 2, reviewing: 6)],
      );
      await studiedSubDeck(env, root.id, root.id, 'Tính từ');
      await auditProductionScreen(
        tester,
        screen: DeckProgressScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          DeckProgressScreen(
            deckId: root.id,
            onOpenDeck: (_) {},
            onOpenAncestor: (_) {},
          ),
          brightness: brightness,
          textScale: scale,
          locale: locale,
        ),
      );
    });
  }
}
```

`test/visual_audit/screens/screen_audit_coverage_test.dart` (apply this diff):

```diff
diff --git a/test/visual_audit/screens/screen_audit_coverage_test.dart b/test/visual_audit/screens/screen_audit_coverage_test.dart
index aa0ae63..5a7233a 100644
--- a/test/visual_audit/screens/screen_audit_coverage_test.dart
+++ b/test/visual_audit/screens/screen_audit_coverage_test.dart
@@ -46,12 +46,10 @@ void main() {
       'deck_level_screen_visual_audit_test.dart',
     );
     expect(
-      companionFor('lib/app/placeholder_screen.dart'),
-      'test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart',
-    );
-    expect(
-      screenClassOf('lib/app/placeholder_screen.dart'),
-      'PlaceholderScreen',
+      screenClassOf(
+        'lib/features/progress/presentation/screens/deck_progress_screen.dart',
+      ),
+      'DeckProgressScreen',
     );
   });
 
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/presentation/deck_progress_screen_test.dart test/app/progress_routes_test.dart
```

Expected: FAIL to compile: `deck_progress_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/app/placeholder_screen.dart`: delete it.

```bash
git rm lib/app/placeholder_screen.dart
```

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index 165d832..31f5441 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -4,7 +4,6 @@ import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart';
 import 'package:go_router/go_router.dart';
 import 'package:memox/app/gallery/gallery_screen.dart';
-import 'package:memox/app/placeholder_screen.dart';
 import 'package:memox/app/router/app_routes.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
@@ -17,6 +16,8 @@ import 'package:memox/features/card/presentation/widgets/sections/card_list_sect
 import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
 import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
 import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
+import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
+import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
 import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
 import 'package:memox/features/settings/presentation/screens/language_screen.dart';
 import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
@@ -161,7 +162,35 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
               ),
             ],
           ),
-          _branch(AppRoutes.progress, (context) => context.l10n.navProgress),
+          // Screen 22 (FE-A9): one page per level, under the tab bar, so
+          // Back climbs one level (D5).
+          StatefulShellBranch(
+            routes: [
+              GoRoute(
+                path: AppRoutes.progress,
+                builder: (context, state) => ProgressScreen(
+                  onOpenDeck: (id) =>
+                      unawaited(context.push(AppRoutes.progressDeck(id))),
+                  onStartStudying: () => context.go(AppRoutes.study),
+                ),
+                routes: [
+                  GoRoute(
+                    path: AppRoutes.progressDeckChild,
+                    builder: (context, state) => DeckProgressScreen(
+                      deckId: state.pathParameters[AppRoutes.deckIdParam]!,
+                      onOpenDeck: (id) =>
+                          unawaited(context.push(AppRoutes.progressDeck(id))),
+                      onOpenAncestor: (id) => _openAncestor(
+                        context,
+                        id,
+                        levelOf: AppRoutes.progressDeck,
+                      ),
+                    ),
+                  ),
+                ],
+              ),
+            ],
+          ),
           StatefulShellBranch(
             routes: [
               GoRoute(
@@ -307,10 +336,15 @@ Future<void> _editCard(BuildContext context, String cardId) async {
 Widget _deckContext(String deckId, String currentLabel) =>
     DeckContextHeaderWidget(deckId: deckId, currentLabel: currentLabel);
 
-/// Ruling P2-L5: a breadcrumb tap pops the Library stack back to [deckId],
+/// Ruling P2-L5: a breadcrumb tap pops the branch's stack back to [deckId],
 /// or to the root for null. A deck that is not on the stack (it was opened
-/// from search) is pushed over the root instead.
-void _openAncestor(BuildContext context, String? deckId) {
+/// from search) is pushed over the root instead, as its [levelOf] location:
+/// a Library level, or a Progress level (FE-A9 D5).
+void _openAncestor(
+  BuildContext context,
+  String? deckId, {
+  String Function(String deckId) levelOf = AppRoutes.deck,
+}) {
   final router = GoRouter.of(context);
   var isOnStack = false;
   Navigator.of(context).popUntil((route) {
@@ -322,19 +356,9 @@ void _openAncestor(BuildContext context, String? deckId) {
     return isOnStack || route.isFirst;
   });
   if (deckId == null || isOnStack) return;
-  unawaited(router.push(AppRoutes.deck(deckId)));
+  unawaited(router.push(levelOf(deckId)));
 }
 
-StatefulShellBranch _branch(String path, String Function(BuildContext) title) =>
-    StatefulShellBranch(
-      routes: [
-        GoRoute(
-          path: path,
-          builder: (context, state) => PlaceholderScreen(title: title(context)),
-        ),
-      ],
-    );
-
 /// The bottom nav around the current branch.
 class _TabShell extends StatelessWidget {
   const _TabShell({required this.navigationShell});
```

`lib/app/router/app_routes.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_routes.dart b/lib/app/router/app_routes.dart
index e9a0282..3766182 100644
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -75,6 +75,13 @@ abstract final class AppRoutes {
   static String studyOptions(String deckId) =>
       '${deck(deckId)}/$studyOptionsChild';
 
+  /// A deck's Progress level (screen 22), relative to [progress]: one page
+  /// per level, under the tab bar (FE-A9 D5).
+  static const String progressDeckChild = ':$deckIdParam';
+
+  /// [deckId]'s Progress level.
+  static String progressDeck(String deckId) => '$progress/$deckId';
+
   /// The session [sessionId], its summary once it has ended.
   static String studySession(String sessionId) => '$study/session/$sessionId';
 
```

`lib/features/progress/presentation/screens/deck_progress_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/deck_progress_provider.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_level_list_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 22 inside a deck (UC-PROGRESS-002 at a deck's level): the deck's
/// path, the range, the deck's total and a row per direct child, each
/// opening the next level down. A deck gone to the Trash is a value with
/// the way back, never a retry (E2). Where a row and a segment of the path
/// lead, `app/` decides.
class DeckProgressScreen extends ConsumerWidget {
  const DeckProgressScreen({
    super.key,
    required this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
  });

  final String deckId;
  final ValueChanged<String> onOpenDeck;

  /// A segment of the path: null for Progress itself, else a deck above.
  final ValueChanged<String?> onOpenAncestor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final read = ref.watch(deckProgressProvider(deckId));
    final level = switch (read) {
      AsyncError() => null,
      AsyncValue(value: final DeckProgressLevel level) => level,
      _ => null,
    };
    final Widget body = switch (read) {
      AsyncError() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.progressErrorTitle,
            body: l10n.progressErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(deckProgressProvider(deckId)),
          ),
        ],
      ),
      _ when level != null => MxScreenScroll(
        children: [
          const ProgressRangeWidget(),
          const SizedBox(height: AppSpacing.gutter),
          ProgressLevelListWidget(
            level: level.level,
            isDeckLevel: true,
            onOpenDeck: onOpenDeck,
          ),
        ],
      ),
      AsyncValue(value: ProgressDeckMissing()) => _gone(context),
      _ => MxScreenScroll(
        children: [
          const ProgressRangeWidget(),
          const SizedBox(height: AppSpacing.gutter),
          MxSkeletonList(semanticLabel: l10n.progressLoading),
        ],
      ),
    };
    final path = level?.path;
    return MxAppShell(
      appBar: MxAppBar(
        title: path == null ? l10n.progressTitle : path.last.name,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (path != null)
            MxBreadcrumb(
              segments: [
                MxBreadcrumbSegment(
                  label: l10n.progressTitle,
                  onTap: () => onOpenAncestor(null),
                ),
                for (final segment in path)
                  MxBreadcrumbSegment(
                    label: segment.name,
                    onTap: () => onOpenAncestor(segment.deckId),
                  ),
              ],
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// The deck of the link went to the Trash or no longer exists
  /// (UC-PROGRESS-002 E2; UI-base row 129).
  Widget _gone(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.deckGoneTitle,
          body: l10n.deckGoneBody,
          actionLabel: l10n.commonBack,
          onAction: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ],
    );
  }
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index e404714..0d3d147 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -20,14 +20,6 @@
   "@navSettings": {
     "description": "Bottom navigation: the settings tab."
   },
-  "placeholderTitle": "Coming soon",
-  "@placeholderTitle": {
-    "description": "Title on a tab whose screen is not built yet."
-  },
-  "placeholderBody": "This screen is being built.",
-  "@placeholderBody": {
-    "description": "Line under placeholderTitle."
-  },
   "openGallery": "Component gallery",
   "@openGallery": {
     "description": "Debug builds only: the Settings action that opens the component gallery."
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index ce81845..b72fa90 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -5,8 +5,6 @@
   "navStudy": "Học",
   "navProgress": "Tiến độ",
   "navSettings": "Cài đặt",
-  "placeholderTitle": "Sắp có",
-  "placeholderBody": "Màn hình này đang được xây dựng.",
   "openGallery": "Thư viện component",
   "commonCancel": "Hủy",
   "commonUndo": "Hoàn tác",
```

- [ ] **Step 4: Generate, render the goldens, run the whole suite**

```bash
flutter gen-l10n
TZ=UTC flutter test --tags golden --update-goldens test/features/progress/presentation/deck_progress_golden_test.dart
flutter test
TZ=UTC flutter test --tags golden
flutter analyze
```

Expected: PASS. The architecture check stays clean: `progress` imports no feature. Six
new goldens: `deck_progress_deck_*` against the kit's `deck-*` (the path, "Sub-decks ·
last 7 days", "Whole deck", four children with the idle one last), and the two states
the kit lacks, `deck_progress_leaf_*` (A1) and `deck_progress_gone_*` (E2). No other
golden changes.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/placeholder_screen.dart \
  lib/app/router/app_router.dart \
  lib/app/router/app_routes.dart \
  lib/features/progress/presentation/screens/deck_progress_screen.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/app/app_test.dart \
  test/app/l10n_test.dart \
  test/app/progress_routes_test.dart \
  test/app/settings_routes_test.dart \
  test/features/progress/presentation/deck_progress_golden_test.dart \
  test/features/progress/presentation/deck_progress_screen_test.dart \
  test/support/progress_screen_fixtures.dart \
  test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart \
  test/visual_audit/screens/features/progress/screens/deck_progress_screen_visual_audit_test.dart \
  test/visual_audit/screens/screen_audit_coverage_test.dart \
  test/features/progress/presentation/goldens/deck_progress_deck_dark.png \
  test/features/progress/presentation/goldens/deck_progress_deck_light.png \
  test/features/progress/presentation/goldens/deck_progress_gone_dark.png \
  test/features/progress/presentation/goldens/deck_progress_gone_light.png \
  test/features/progress/presentation/goldens/deck_progress_leaf_dark.png \
  test/features/progress/presentation/goldens/deck_progress_leaf_light.png
git commit -m "$(cat <<'EOF'
feat(progress): a deck's level and the Progress routes; the placeholder goes (FE-A9 D5)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: Detail file 22, index, checklist, register, ui.md, use cases, WBS; the gate

**Files:**
- Modify: `docs/features/progress/README.md`
- Create: `docs/features/progress/ui.md`
- Modify: `docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md`
- Modify: `docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Create: `docs/shared/ui/screen-handoff/22-progress.md`
- Modify: `docs/shared/ui/screen-state-checklist.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/_generated/traceability.md (generated)`

**Interfaces:** none (documents). The kit's captures of screen 22 and its entry in
`tools/design/screen_states.json` are already on the branch (with the spec).

- [ ] **Step 1: Update the documents**

`docs/features/progress/README.md` (apply this diff):

```diff
diff --git a/docs/features/progress/README.md b/docs/features/progress/README.md
index f47129e..0e77329 100644
--- a/docs/features/progress/README.md
+++ b/docs/features/progress/README.md
@@ -1,6 +1,6 @@
 ---
 feature: progress
-code: [lib/features/progress/domain, lib/features/progress/data, lib/features/progress/di]
+code: [lib/features/progress/domain, lib/features/progress/data, lib/features/progress/di, lib/features/progress/presentation]
 depends_on: [deck, srs, study]
 ---
 ## Phạm vi
@@ -14,6 +14,8 @@ Tiến độ theo deck và Progress overview (V8.0): đọc lại lịch sử h
 | Tab Tiến độ / Progress | UC-PROGRESS-001, UC-PROGRESS-002 |
 | Hàng deck trên màn tiến độ (drill-down) | UC-PROGRESS-002 |
 
+Màn 22 và điều hướng giữa các cấp: [ui.md](ui.md).
+
 Nguồn: trigger của UC-PROGRESS-001 ("Chạm tab **Tiến độ / Progress** ở bottom navigation") và UC-PROGRESS-002 ("Mở tab Progress, hoặc chạm một hàng deck trên màn hình tiến độ").
 
 ## Không thuộc phạm vi
```

`docs/features/progress/ui.md`:

```markdown
# Progress — UI

Màn hình và điều hướng dùng chung hai UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 22 · Progress, cấp thư viện | `/progress` (tab Progress) | Bottom bar | [22-progress.md](../../shared/ui/screen-handoff/22-progress.md) |
| 22 · Progress, cấp của một deck | `/progress/:deckId`, trong branch Progress, có bottom bar | Một hàng deck ở cấp trên; một đoạn của breadcrumb | [22-progress.md](../../shared/ui/screen-handoff/22-progress.md) |

Mỗi hàng deck push thêm một cấp; Back về đúng cấp vừa rời. Khoảng 7 hoặc 30 ngày là một
lựa chọn chung cho mọi cấp của tab: mở một deck từ "Last 30 days" thì cấp đó cũng ở 30
ngày. Đổi khoảng không đọc lại database (BR-PROGRESS-003). Khi chưa từng học, nút "Start
studying" mở tab Học. Nguồn: [spec FE-A9](../../superpowers/specs/2026-09-27-progress-ui-design.md)
§3 (D1, D4, D5), §5.

## Validation

Không có: màn chỉ đọc, không có trường nhập (BR-PROGRESS-009).
```

`docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md` (apply this diff):

```diff
diff --git a/docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md b/docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md
index 917e23a..4cf0ef9 100644
--- a/docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md
+++ b/docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md
@@ -3,7 +3,7 @@ id: UC-PROGRESS-001
 title: Xem tiến độ học
 status: ready
 rules: [BR-MODE-005, BR-CORE-002, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGRESS-012, BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016, BR-PROGRESS-017, BR-PROGRESS-018, BR-STUDY-074]
-code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart]
+code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/presentation/screens/progress_screen.dart, lib/features/progress/presentation/providers/progress_provider.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md` (apply this diff):

```diff
diff --git a/docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md b/docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md
index 8300c86..6baa271 100644
--- a/docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md
+++ b/docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md
@@ -3,7 +3,7 @@ id: UC-PROGRESS-002
 title: Xem tiến độ theo deck
 status: ready
 rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-CORE-001, BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-003, BR-PROGRESS-004, BR-PROGRESS-005, BR-PROGRESS-006, BR-PROGRESS-007, BR-PROGRESS-008, BR-SRS-015, BR-SRS-023, BR-STUDY-074]
-code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart]
+code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart, lib/features/progress/presentation/screens/progress_screen.dart, lib/features/progress/presentation/screens/deck_progress_screen.dart, lib/features/progress/presentation/providers/deck_progress_provider.dart, lib/features/progress/presentation/providers/progress_range_provider.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 81c1a5a..1d003e6 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -55,7 +55,7 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 19 | Study · Recall | 3 | FE-A6 | aligned | [19-study-recall.md](19-study-recall.md) |
 | 20 | Study · Fill | 3 | FE-A6 | aligned | [20-study-fill.md](20-study-fill.md) |
 | 21 | Session summary | 10 | FE-A6 | aligned | [21-session-summary.md](21-session-summary.md) |
-| 22 | Progress | 8 | FE-A9 | not built | — |
+| 22 | Progress | 8 | FE-A9 | aligned | [22-progress.md](22-progress.md) |
 | 23 | Settings | 8 | FE-A3 | aligned | [23-settings.md](23-settings.md) |
 | 24 | Daily reminder | 9 | FE-B5 | out of V8 | — |
 | 25 | Theme | 3 | FE-A3 | aligned | [25-theme.md](25-theme.md) |
```

`docs/shared/ui/screen-handoff/22-progress.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 22 · Progress

The Progress tab: what was studied today and over the last seven days, the current
streak, and how much each deck was studied over 7 or 30 days, level by level down the
deck tree. It only reads. UC-PROGRESS-001, UC-PROGRESS-002; BR-PROGRESS-001…018; spec
[2026-09-27-progress-ui-design.md](../../../superpowers/specs/2026-09-27-progress-ui-design.md).

## Entry points

- **The bottom navigation:** the Progress tab opens the library level, `/progress`.
- **A deck row:** opens that deck's level, `/progress/:deckId`, under the tab bar (D5).
  Each row pushes one level, and Back climbs one.
- **The breadcrumb of a deck's level:** "Progress" returns to the library level; a deck
  above returns to its level.

## Layout

The library level, top to bottom:

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (screen) | "Progress". |
| Today | `MxCard` | The overline "Today", the day's card-days, and "{l} learning · {r} reviewing · a card counts once per day", "No cards studied yet today" or "Nothing studied yet". Below, `MxStackedDayBars`: the last seven days, learning over reviewing, today at full strength, labelled by narrow weekday and "Today", with the legend. |
| Streak | `MxCard` | Two tiles: "Current" (the flame in the `streak` colour, "{n} days", and "includes today", "held from yesterday" or "no study yesterday") and "Today" ("{n} cards", "counted once each" or "nothing yet"). A held streak adds "Study one card today and the streak continues at {n}."; a lost one "The streak ended on {day}. It starts again with the next card you study." |
| Range | `MxSegmentedTray` (wide) | "Last 7 days" · "Last 30 days", directly above the list (D10). |
| List | `MxListSectionHeader` + `MxCard` + `MxListRow`s | "By deck · last 7 days"; the total row "All decks" (D2), then a row per root deck: the name, "{d} active days · {l} learning · {r} reviewing" (learning in the learning ink, reviewing in the primary ink), and the active cards over "cards". An idle deck reads "No activity in this range", its 0 muted, nothing dimmed (D11). |
| Note | `MxNote` | A quiet range: "Nothing studied in the last 7 days. Switch to Last 30 days to see older study." (at 30 days, the first sentence only). |
| Footer line | text | "Read-only · a card studied several times in a day counts once · resets change nothing here". |

A deck's level: the app bar with Back and the deck's name, the breadcrumb "Progress › …
› {deck}", the range at the top, "Sub-decks · last 7 days", the total row "Whole deck",
a row per direct child, and the footer line. A deck with no children adds "This deck
holds its cards directly, so the total above is all of it."

Switching the range reads nothing (BR-PROGRESS-003). The numbers follow every write and
every local midnight with no skeleton once shown (BR-PROGRESS-018, D8).

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| loaded (Last 7 days) | ![](img/22-progress/loaded-light.png) | ![](img/22-progress/loaded-dark.png) | **Deviation:** the range sits above the list (D10); one total row, no header totals (D2). |
| month (Last 30 days) | ![](img/22-progress/month-light.png) | ![](img/22-progress/month-dark.png) | As loaded. |
| held | ![](img/22-progress/held-light.png) | ![](img/22-progress/held-dark.png) | As drawn. |
| lost | ![](img/22-progress/lost-light.png) | ![](img/22-progress/lost-dark.png) | The note names the weekday within six days, else a short date. |
| deck | ![](img/22-progress/deck-light.png) | ![](img/22-progress/deck-dark.png) | "Whole deck" total row (D2). |
| never | ![](img/22-progress/never-light.png) | ![](img/22-progress/never-dark.png) | **Deviation (D1):** "Start studying" under Today's placeholder opens the Study tab (UC-PROGRESS-001 A2). |
| loading | ![](img/22-progress/loading-light.png) | ![](img/22-progress/loading-dark.png) | Skeleton rows (UI-base row 125). |
| error | ![](img/22-progress/error-light.png) | ![](img/22-progress/error-dark.png) | As drawn, with Retry. |
| quiet range | — | — | **V8 addition (UC-PROGRESS-002 A3):** the note under the list. |
| no decks | — | — | **V8 addition (A2):** only "No decks yet · Create a deck in the Library and its progress appears here". No range, no total, no button. |
| no sub-decks | — | — | **V8 addition (A1):** the total row and its note. |
| deck gone | — | — | **V8 addition (E2):** "This deck is no longer here" with Back, no Retry (UI-base row 129). |

Goldens: `test/features/progress/presentation/goldens/progress_{week,month,held,lost,never,quiet,no_decks,loading,error}_{light,dark}.png` and `deck_progress_{deck,leaf,gone}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| The range tray at the top of the library level | Directly above the list it changes | UC-PROGRESS-001 step 4, UC-PROGRESS-002 step 1; D10 |
| "{n} active cards · {m} card-days" in the list header | A total row with the four numbers | BR-PROGRESS-001; D2 |
| An idle deck row at 60% opacity | Full contrast, its 0 muted | Contrast (critique P2); D11 |
| Never studied: placeholders only | Plus "Start studying" to the Study tab | UC-PROGRESS-001 A2; D1 |
| A skeleton per card, the tray shown | Skeleton rows | UI-base row 125 |
| No quiet-range, no-deck, leaf or gone state | Built from the UC | UC-PROGRESS-002 A1–A3, E2 |

## Copy

"Progress" · "Today" · "{l} learning · {r} reviewing · a card counts once per day" · "No
cards studied yet today" · "Nothing studied yet" · "Learning" · "Reviewing" · "Streak" ·
"Current" · "{n} days" · "includes today" · "held from yesterday" · "no study yesterday" ·
"{n} cards" · "counted once each" · "nothing yet" · "Study one card today and the streak
continues at {n}." · "The streak ended on {day}. It starts again with the next card you
study." · "Your last seven days appear here once you study. Browsing cards does not
count." · "A streak starts with your first study day." · "Start studying" · "Last 7 days"
· "Last 30 days" · "By deck · last 7 days" · "Sub-decks · last 7 days" · "All decks" ·
"Whole deck" · "{d} active days" · "{l} learning" · "{r} reviewing" · "cards" · "No
activity in this range" · "Nothing studied in the last 7 days. Switch to Last 30 days to
see older study." · "No decks yet" · "Create a deck in the Library and its progress
appears here." · "This deck holds its cards directly, so the total above is all of it." ·
"Read-only · a card studied several times in a day counts once · resets change nothing
here" · "Couldn't summarise your progress" · "Your study history is safe on this device.
Try again in a moment."
```

`docs/shared/ui/screen-state-checklist.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-state-checklist.md b/docs/shared/ui/screen-state-checklist.md
index ff5e838..9ef766a 100644
--- a/docs/shared/ui/screen-state-checklist.md
+++ b/docs/shared/ui/screen-state-checklist.md
@@ -32,7 +32,7 @@ Màn 14, 16, 16a và 17–21 là `aligned` trong index từ phase P5 của roadm
 
 ## Tổng hợp
 
-Kit có **26 màn, 211 state**. Xong **143**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **39**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
+Kit có **26 màn, 211 state**. Xong **151**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **31**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
 
 | # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
 |---|---|---|---|---|---|---|---|---|
@@ -57,7 +57,7 @@ Kit có **26 màn, 211 state**. Xong **143**; một phần **5**; đã dựng nh
 | 19 | Study · Recall | FE-A6 | 3 | 3 | 0 | 0 | 0 | [19-study-recall.md](screen-handoff/19-study-recall.md) |
 | 20 | Study · Fill | FE-A6 | 3 | 3 | 0 | 0 | 0 | [20-study-fill.md](screen-handoff/20-study-fill.md) |
 | 21 | Session summary | FE-A6 | 10 | 8 | 1 | 0 | 1 | [21-session-summary.md](screen-handoff/21-session-summary.md) |
-| 22 | Progress | FE-A9 | 8 | 0 | 0 | 8 | 0 | — |
+| 22 | Progress | FE-A9 | 8 | 8 | 0 | 0 | 0 | [22-progress.md](screen-handoff/22-progress.md) |
 | 23 | Settings | FE-A3 | 8 | 8 | 0 | 0 | 0 | [23-settings.md](screen-handoff/23-settings.md) |
 | 24 | Daily reminder | FE-B5 | 9 | 0 | 0 | 9 | 0 | — |
 | 25 | Theme | FE-A3 | 3 | 3 | 0 | 0 | 0 | [25-theme.md](screen-handoff/25-theme.md) |
@@ -407,18 +407,21 @@ FE-A6 · [21-session-summary.md](screen-handoff/21-session-summary.md)
 
 ### 22 · Progress
 
-FE-A9 · chưa có detail file
+FE-A9 · [22-progress.md](screen-handoff/22-progress.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | Last 7 days | — | chưa làm |  |
-| [ ] | Last 30 days | — | chưa làm |  |
-| [ ] | Streak held | — | chưa làm |  |
-| [ ] | Streak lost | — | chưa làm |  |
-| [ ] | Inside a deck | — | chưa làm |  |
-| [ ] | Never studied | — | chưa làm |  |
-| [ ] | Loading | — | chưa làm |  |
-| [ ] | Error | — | chưa làm |  |
+| [x] | Last 7 days | `loaded` | xong | Bộ chọn khoảng nằm ngay trên danh sách (D10); một hàng tổng, header không ghi tổng (D2). |
+| [x] | Last 30 days | `month` | xong |  |
+| [x] | Streak held | `held` | xong |  |
+| [x] | Streak lost | `lost` | xong | Ghi chú nêu tên thứ trong 6 ngày, xa hơn thì nêu ngày. |
+| [x] | Inside a deck | `deck` | xong | Hàng tổng "Whole deck" (D2). |
+| [x] | Never studied | `never` | xong | Thêm "Start studying" sang tab Học (D1). |
+| [x] | Loading | `loading` | xong | Skeleton list (UI-base §9 dòng 125). |
+| [x] | Error | `error` | xong |  |
+
+V8 thêm bốn state kit không có: khoảng không có hoạt động (A3), chưa có deck (A2), deck
+không có deck con (A1), deck đã bị xoá (E2).
 
 ### 23 · Settings
 
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index 7066bd6..059e181 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -527,11 +527,15 @@ item names where it comes from.
 | 122 | Dark `primary-soft` and `primary-border` follow the new primary (the kit mixes `#8B9AFF`), and dark `surface-hero` mixes it at 18 % (kit: 12 %) to keep the kit's lift; the selected radio ring inks in `primaryInk`; a solid `MxBadge` is primary only; a done import step's check inks in `onMastery` (the kit's dark on-primary, kept) | owner 2026-09-27, D1, D5, D6 |
 | 123 | "Reset app options" also turns the daily reminder off and puts it back at 20:00 (BR-SETTINGS-008): the kit's confirmation body ("Theme, language, cards per session and new-card order go back to their defaults.") and the row's sub-line ("Theme, language, study defaults") leave it out. FE-B5 names it in both, and calls `ReconcileReminderUseCase` after a reset, when it shows the Daily reminder row; until then nobody can turn the reminder on, so nothing a person sees changes (FE-A3 D4, owner 2026-09-27) | reminders spec D3, D4; FE-A3 D4 |
 | 124 | Screen 23's Theme is a row naming the choice ("Follows the system setting", "Light", "Dark") that opens screen 25, not the kit's inline System · Light · Dark tray | FE-A3 D2 |
-| 125 | Screen 23 loads as `MxSkeletonList`, not skeleton sub-lines and controls inside its sections; a failed read shows `MxErrorState` with Retry, which the kit does not draw (UC-SETTINGS-001 E3). Screens 15, 25 and 26 do the same | FE-A3 plan 1 |
+| 125 | Screen 23 loads as `MxSkeletonList`, not skeleton sub-lines and controls inside its sections; a failed read shows `MxErrorState` with Retry, which the kit does not draw (UC-SETTINGS-001 E3). Screens 15, 25 and 26 do the same, and screen 22 loads the same way where the kit draws a skeleton per card | FE-A3 plan 1; FE-A9 |
 | 126 | `MxStepper` goes beyond the kit's −/+ by one: holding −/+ repeats (400 ms, then every 80 ms) and a tap on the number types one (FE-A3 D6). The number's box stays 36 tall, its tap target 48 | FE-A3 plan 1 |
 | 127 | `MxSegmentedTray` stacks its options, one per line, when their labels do not fit on one (large text, long Vietnamese labels); the kit draws one line only | FE-A3 plan 1 (visual audit) |
 | 128 | Beside a wide control, `MxSettingsRow`'s tile sits at the top with the label, as kit 23 draws it, not centred on the row; the one exception to row 117 | FE-A3 plan 1; owner 2026-09-27 |
-| 129 | Screen 15 on a deck gone to the Trash, or gone for good, shows the Library's gone state (\"This deck is no longer here\") with Back; the kit draws none | FE-A3 plan 2 (spec §6) |
+| 129 | Screen 15 on a deck gone to the Trash, or gone for good, shows the Library's gone state (\"This deck is no longer here\") with Back; the kit draws none. Screen 22 at a gone deck's level does the same, with no Retry (UC-PROGRESS-002 E2) | FE-A3 plan 2 (spec §6); FE-A9 |
+| 130 | Screen 22's range tray sits directly above the list it changes, after Streak, where the kit puts it above Today, which never changes with it (UC-PROGRESS-001 step 4, UC-PROGRESS-002 step 1). A deck's level keeps it at the top | owner 2026-09-27, FE-A9 D10 |
+| 131 | Screen 22's list opens with a total row of the level's four numbers ("All decks", "Whole deck"; BR-PROGRESS-001), and its header carries no trailing totals (kit: "{n} active cards · {m} card-days") | owner 2026-09-27, FE-A9 D2 |
+| 132 | Screen 22 dims nothing by opacity: an idle deck row keeps its name and "No activity in this range" at full contrast, and its 0 is muted (kit: the row at 60%, which fails 4.5:1) | FE-A9 D11 (critique P2) |
+| 133 | Screen 22 never studied adds "Start studying" to the Study tab under Today's placeholder (UC-PROGRESS-001 A2); it adds the states the kit lacks: a quiet range (A3), no deck (A2) and a deck with no children (A1) | owner 2026-09-27, FE-A9 D1 |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index bd616b0..36eb629 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -41,9 +41,8 @@
     ghi luồng học chưa được thiết kế (P1, đóng ở FE-A5) và typography tiếng Việt/tiếng
     Hàn chưa được thiết kế (P2, đóng ở FE-C2).
 - **Điều hướng:** bốn destination Thư viện · Học · Tiến độ · Cài đặt. Thư viện starter
-  là child flow trong Thư viện; nhắc học nằm trong nhánh Cài đặt. Tab Thư viện đã có màn
-  thật; ba tab Học, Tiến độ, Cài đặt còn hiển thị placeholder
-  (`lib/app/placeholder_screen.dart`).
+  là child flow trong Thư viện; nhắc học nằm trong nhánh Cài đặt. Cả bốn tab đã có màn
+  thật; `PlaceholderScreen` đã bỏ ở FE-A9.
 - **Gate:** gate là `dod_check.sh` (FE-D2); danh sách `targets_pending` của guard đã
   rỗng ([`README.md` gốc](../README.md)).
 - **Quy trình:** mỗi nhóm hạng mục qua thiết kế của Impeccable, rồi brainstorm → spec
@@ -83,7 +82,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 | FE-A6 | Study Entry, màn hình phiên học và ôn tập cho sáu mode, tổng kết phiên (UC-STUDY-001; BR-MODE-001…BR-MODE-019) | xong | FE-A5, BE-A3, BE-A4, BE-A10 | XL | Backend đã sẵn (BE-A3, BE-A4, BE-A10 xong); màn 14, 16–21 trong kit; kịch bản IT của [study](features/study/it-scenarios.md) và [study-mode](features/study-mode/it-scenarios.md); [spec study UI](superpowers/specs/2026-09-26-study-ui-design.md) (đã duyệt 2026-09-26, chia phase P1–P5; D11 thêm hai phần backend nhỏ trong P1 và P2); phase P1a (nền: tone `success`/`caution`/`danger`, `MxStatTile`, read model của entry và tổng kết): [plan](superpowers/plans/2026-09-26-study-p1a-foundations.md); phase P1b (màn 14 chỉ đọc, route, lối vào từ action sheet và summary, đóng phiên cũ khi mở app): [plan](superpowers/plans/2026-09-26-study-p1b-entry.md); phase P1c (route phiên toàn màn hình, controller, màn 16 Browse, màn 21 Summary; thoát giữa phiên hiện tổng kết theo quyết định của chủ dự án về D8): [plan](superpowers/plans/2026-09-26-study-p1c-session.md); phase P2 (màn 16a self-assess với preview khoảng cách D11b, các action của màn 14: Learn, Review, Continue, starting/refused/startFailed, sheet chọn chiều hỏi FE-A7; deck `sm2` học được trọn vẹn): [plan](superpowers/plans/2026-09-26-study-p2-self-assess.md); roadmap P3→P6 đã duyệt: [roadmap](superpowers/plans/2026-09-26-study-chain-roadmap.md); phase P3 (Guess 18, Match 17, chọn mode ôn cho eight_box, sửa `MxStudyTopBar` ở chữ 2x): [plan](superpowers/plans/2026-09-26-study-p3-guess-match.md); phase P4 (Recall 19, Fill 20; deck `eight_box` học và ôn được trọn vẹn, bỏ tập mode đã dựng): [plan](superpowers/plans/2026-09-26-study-p4-recall-fill.md); phase P5 (bộ kịch bản IT tầng host của study, index 14 và 16–21 `aligned`, đóng các minor còn hoãn): [plan](superpowers/plans/2026-09-26-study-p5-it-records.md) | — |
 | FE-A7 | Chọn chiều hỏi trước lượt đầu của phiên self-assess (UC-STUDY-003) | xong | FE-A6, BE-A5 | S | Sheet chọn chiều hỏi của màn 14, làm trong phase P2 của FE-A6: [plan](superpowers/plans/2026-09-26-study-p2-self-assess.md) | — |
 | FE-A8 | Tab Học: Study Home (UC-STUDY-002) | xong | FE-A5, BE-A6 | M | BE-A6 (`WatchStudyHomeUseCase`); file chi tiết [13](shared/ui/screen-handoff/13-study-home.md); phase P6 của [roadmap luồng học](superpowers/plans/2026-09-26-study-chain-roadmap.md): Study Home thay placeholder của tab Học, `MxLinearProgress` dùng chung với banner resume của màn 14, số hạng thứ tư "scheduled" của `MxWorkloadBreakdownLine`: [plan](superpowers/plans/2026-09-26-study-p6-study-home.md) | — |
-| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | chưa bắt đầu | BE-A7 | L | Tab Tiến độ đang là placeholder; nội dung theo `navigation.md`; [kịch bản IT](features/progress/it-scenarios.md); BE-A7 xong (`WatchProgressUseCase`, `WatchDeckProgressUseCase`) | Đọc màn 22 trong kit, viết file chi tiết handoff (chưa có `ui.md` của progress), rồi lập plan |
+| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | xong | BE-A7 | L | [spec](superpowers/specs/2026-09-27-progress-ui-design.md) và [plan](superpowers/plans/2026-09-27-progress-ui.md); file chi tiết [22](shared/ui/screen-handoff/22-progress.md), [ui.md](features/progress/ui.md), [kịch bản IT](features/progress/it-scenarios.md); `PlaceholderScreen` không còn tab nào dùng và đã bỏ | — |
 | FE-A10 | Tìm kiếm toàn thư viện từ header của Thư viện, ở mọi cấp (UC-SEARCH-001) | xong | BE-A8, FE-A1 | M | [PR #68](https://github.com/ntgptit/memox-v8/pull/68); [spec](superpowers/specs/2026-09-26-library-search-ui-design.md) và [plan](superpowers/plans/2026-09-26-library-search-ui.md); màn 04 trên `SearchLibraryUseCase` ở `lib/features/search/presentation/`: deck, card và tag, debounce 250 ms, Load more theo keyset, lỗi trang đầu (E1) và trang sau (E2); `SearchDecksUseCase` cùng phần đọc phía deck đã bỏ; IT-DISC-006/007 kiểm trên màn 04 theo nghĩa toàn thư viện; [handoff 04](shared/ui/screen-handoff/04-library-search.md) | — |
 | FE-A11 | Căn Thư viện theo screen handoff V3 (artifact "MemoX — Mobile UI Kit v3"): màn 01, 02, 04, 07; 5 phase A–E | xong | FE-A1, FE-A2, BE-A2 | L | [spec](superpowers/specs/2026-09-24-library-artifact-alignment-design.md); phase A (#32), B (#34), C (#38), D (#42), E (#46, #49) | — |
 
@@ -144,7 +143,7 @@ so nội dung.
 
 | Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
 |---|---|---|---|
-| FE-A2, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 22 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
+| FE-A2 | Chưa có file chi tiết handoff cho màn 08–10 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi đối chiếu |
 | FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
 | FE-D3 | Không có emulator hoặc thiết bị | 8 kịch bản `DEVICE-E2E` | Môi trường chạy |
@@ -166,8 +165,8 @@ so nội dung.
 Mọi hạng mục FE của V8.0 đã có backend (BE-A1…BE-A10 xong). Thứ tự còn lại do thiết kế
 và phụ thuộc giữa các màn quyết định:
 
-1. FE-A9 (Tiến độ): viết file chi tiết handoff của màn 22 trước khi lập plan. Luồng học
-   (FE-A6, FE-A7, FE-A8) và Cài đặt (FE-A3) đã xong.
+1. Mọi màn của V8.0 đã dựng: FE-A9 (Tiến độ) là màn cuối. Còn lại của V8.0 là phần dở
+   của FE-A1 (mastery, chờ BR/UC) và FE-A2 (file chi tiết 08–10).
 2. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
 3. Sau V8.0: FE-B1 (Trash, #78) và FE-B3 (import/export, #72) đã xong. FE-B2 (tag) và
    FE-B4 (starter) không còn chờ backend vì BE-B2 và BE-B4 đã xong. BE-B5a xong trong
@@ -249,3 +248,5 @@ giờ mỗi trạng thái, cộng thêm phần tương tác phức tạp.
   hàng Daily reminder (dòng FE-B5 và dòng 123 của sổ nợ UI-base).
 - **Cập nhật ngày 2026-09-27:** FE-A3 xong sau plan 2: màn 15 Study options mở từ action
   sheet của deck và từ app bar màn 14; Coming soon không còn nêu Study options.
+- **Cập nhật ngày 2026-09-27:** FE-A9 xong: màn 22 thay placeholder cuối cùng (tab
+  Progress), hai cấp `/progress` và `/progress/:deckId`; `PlaceholderScreen` đã bỏ.
```

- [ ] **Step 2: Regenerate the docs index and check**

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: no error. The existing warnings stay. `wbs_FE.md` links this plan, which is
already on the branch.

- [ ] **Step 3: The gate**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force
```

Expected: every gate green.

- [ ] **Step 4: Commit and push**

```bash
git add \
  docs/features/progress/README.md \
  docs/features/progress/ui.md \
  docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md \
  docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/22-progress.md \
  docs/shared/ui/screen-state-checklist.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/wbs_FE.md \
  docs/_generated/traceability.md
git commit -m "$(cat <<'EOF'
docs(progress): FE-A9 done: detail file 22, register rows 130-133, UC, WBS

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
