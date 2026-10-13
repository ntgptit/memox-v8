# MemoX V8 Tags and Starter decks UI Implementation Plan (FE-B2 + FE-B4)

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build FE-B2 and FE-B4 in [`docs/wbs_FE.md`](../../wbs_FE.md) as one batch: kit
screen 03 (Starter decks, 10 states), kit screen 05 (Tags, 12 states), screen 07's Tags
chip and tag filter, and screen 01's app bar and `rootEmpty`. The Coming soon sheet goes.

**Architecture:**
- **One shared tone (D15).** `MxButtonTone.warning` paints the `warning` role with
  `onWarning`; `MxSheetActions` gains `isWarning`, and its Cancel may be disabled.
- **Starter decks (D4, D6).** `lib/features/starter_decks/presentation/` gains a
  provider per use case, `starterLibraryProvider` and `StarterAddController`, which
  guards the add and says how it ended. `StarterLibraryScreen` takes callbacks.
- **Tags (D4, D8).** `lib/features/tags/presentation/` gains a provider per use case,
  `tagCatalogProvider` and `TagActionsController` (plan, rename or merge, delete, busy
  rows). `TagsScreen` narrows the catalog it read with the store's fold.
- **The card list's filter (D3, D12, D14).** `card` reads the tags of a deck through its
  own `WatchCardTagFilterUseCase` over `TagRepository`, as `AddTagToCardsUseCase` does.
  `CardListRequestState` carries a `CardTagFilter` into `CardListQuery.tagIds`.
- **`app/`.** It adds `/decks/starter` and `/decks/tags` on the root navigator, wires
  screen 01's actions, and opens the Library search on a tag's name.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, Drift, gen-l10n (en, vi). No new package.

**Spec:** [`docs/superpowers/specs/2026-09-27-tags-starter-ui-design.md`](../specs/2026-09-27-tags-starter-ui-design.md)
(D1–D15, §5–§9).
- Use cases: UC-STARTER-001, UC-TAG-001.
- The kit is the visual authority: "MemoX — Mobile UI Kit v3", screens 03 and 05,
  captured in `docs/shared/ui/screen-handoff/img/{03-starter-decks,05-tags}/`; screens 01
  and 07 in their folders.
- The pre-plan critique and the shape brief of the filter sheet are
  `.impeccable/critique/2026-09-27T06-00-00Z__tags-starter-kit.md` (P1a → D15, P1b → D14,
  the brief → D3).

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` at the commit that adds
this plan: `master` at #93 plus the spec, the critique and this plan. Generated code is
not committed. In a fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- **Built in scratch.** Every task was built and committed in a scratch worktree of the
  branch, and each task's blocks below are that commit's files and diffs.
- **Each task alone.** Each task's commit was checked out on its own, generated, and
  analysed clean.
- **Gate.** The full gate (`dod_check.sh --force`) passed there, with a clean
  `flutter analyze`, a clean guard and clean architecture boundaries.
- **Goldens.** They ran in this Linux container, and every golden of screens 01, 03, 05
  and 07 was compared with its kit capture.
- **Replay.** The blocks were replayed mechanically onto a clean checkout, and the
  result matched the scratch files byte for byte, `docs/_generated/` included once
  regenerated.
- **Recorded results:**
  - the gate: 2341 tests, "✓ mechanical gates passed", guard "No violations found",
    docs "PASS — 0 error(s)";
  - the whole suite with goldens: 2688 tests; the goldens alone: 347.

## Clarifications (rulings; amend the spec where they differ)

- **C1 (the warning tone).** `MxButtonTone.warning` is the `warning` fill with its
  `onWarning` ink, about 6.5:1 in light. It does not join the tones whose spinner is on
  the fill: "Merge tags" never spins. `MxSheetActions` takes `isWarning`, exclusive with
  `isDestructive`, and its `onCancel` may be null, which disables Cancel (screen 03
  `adding`).
- **C2 (the add).** `StarterAddController.add` returns a `StarterAddResult`
  (`StarterAdded` with the `AddedStarterDeck`, or `StarterAlreadyPresent`) when the sheet
  should close, and null when it stays: an add while one runs, `templateNotFound`, or a
  `Failure`. The last two set `StarterAddState.hasFailed`. The controller lives while the
  sheet watches it, so each sheet starts clean.
- **C3 (names).** The screens are `StarterLibraryScreen` and `TagsScreen`. The second-copy
  dialog is `starter_repeat_add_dialog_widget.dart`: the guard takes "copy" in a file name
  for a backup file. The sheet's flag is `isSecondCopy` (a predicate). The language table
  is `starter_labels_widget.dart` (spec §4: `starter_language_labels_widget`).
- **C4 (Find cards, D11).** "Find cards with this tag" goes (`context.go`) to
  `/decks/search?q={name}`: the search lives in the Library branch, under the shell, and
  a push from a root-navigator page would land beneath it. Back from the search returns
  to the Library, not to Tags. `LibrarySearchScreen` takes `initialQuery` and searches it
  after the first frame.
- **C5 (the catalog's search).** Screen 05 reads the whole catalog once and narrows it
  with `List<TagCount>.matching(term)`, an extension in the tags domain model that folds
  as the store folds (`foldText`). A keystroke re-reads nothing, and the header tells
  "No tags" from "No matches" (A6).
- **C6 (the filter's read).** Another feature's use cases and presentation are private
  (`test/architecture/boundary_rules.dart`: only `entities`, `models`, `repositories`,
  `failures` and `di/`). So `card` has `WatchCardTagFilterUseCase` over `TagRepository`
  and its own `cardTagFilterProvider(deckId)`, and `tags` has no deck-count provider (spec
  §4 listed `deck_tag_counts_provider`).
- **C7 (the applied set).** `CardTagFilter` wraps the ids with value equality, as a
  family key needs. `CardListRequestState.tags` feeds `query` and `cardListProvider`; a new
  set starts from the first window; every other change keeps it. The app bar's "Select
  all" total is keyed by it too.
- **C8 (the settle, D8).** `tagRenameSettle` is a named 250 ms constant beside the
  dialog, as `searchDebounce` is beside the search: the repo keeps a feature's timing with
  the feature (spec D8 said an `AppDurations` token).
- **C9 (checking the name).** The dialog checks BR-TAG-001 as the name is typed
  (`TagEntity.checkName`), so "too long" shows at once, and reads the plan only for a
  valid name. Rename is off while the name is unchanged or has no plan yet; the last plan
  stays while the next one settles.
- **C10 (how a write ends).** `TagWriteResult` is `done`, `gone`, `replan` or `failed`.
  `replan` (`mergeNotConfirmed`, or a name rule) opens the dialog again on the name typed;
  `failed` toasts with Retry, which runs the same write; `done` says nothing, the catalog
  shows it.
- **C11 (toasts and names).** A toast is one sentence (`MxSnackbarContent` has one
  message), and a tag's name is quoted, never bold (UI-base rows 138, 139).
- **C12 (glyph inks).** A glyph takes its ink from `IconTheme.merge`, as the card row's
  flag does: the guard bans `Icon(color:)` in feature code.
- **C13 (the starter card).** The tile centres on the title's lines (the guard centres a
  row's marks), and the facts and the actions line up with the title, past
  `MxIconTile.mediumBox` (made public) and the gap.
- **C14 ("Create a deck").** The router pops screen 03 and opens
  `showCreateRootDeckDialog` over the root navigator's overlay. Open on the added toast
  goes (`router.go`) to the new root deck.
- **C15 (Coming soon).** The sheet, its six ARB keys, its test and its two goldens go.
  The Library's first-run test becomes "rootEmpty offers a starter deck beside Create
  deck".
- **C16 (fixtures).** Widget tests use in-memory templates (`StarterLibraryFake`, which
  also fails, holds or never loads) and `TagRepositoryFake` (fails, holds, never loads);
  both sit over the harness's real database.
- **C17 (copy).** The Vietnamese "In library" is "Trong thư viện", which fits beside a
  title at text scale 2. The filter sheet's count comes from `cardTagFilterCount`, since
  the guard bans a string literal in a `Text`.
- **C18 (UI-base §9).** Rows 134–140 are the next free rows at #93. If they are taken by
  the time this lands, use the next free numbers and change their references in the
  detail files.

## Global Constraints

Every task's requirements implicitly include these.

- The kit is the visual authority for screens 01, 03, 05 and 07. Every difference is in
  D1–D15, in C1–C18, in the detail files, or in UI-base §9 rows 125 and 134–140.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens in feature code;
  - no raw colour, `TextStyle`, spacing, radius or anonymous `Duration` literal;
  - no `Icon(color:)` in feature code;
  - no `ref.read` inside `build`, including in a callback: move it into a method;
  - no literal user string, TalkBack labels included;
  - booleans read as predicates;
  - no source file over 400 logical lines;
  - no `Row` pinning its marks to the top;
  - no file name that reads as a backup ("copy").
- File suffixes and buckets follow the guard:
  - `_provider`, `_controller`, `_state` and `_screen`;
  - `_widget` in `sections/`, `items/`, `overlays/` or `support/`.
- Every read and write goes through a use case (ADR-011 D4). A feature reaches another
  only through its public domain buckets and its `di/`, along the map in
  `test/architecture/boundary_rules.dart` (`card` → `tags`, `starter_decks` → `deck`,
  `card`, `srs`; `tags` → none).
- No message carries an id, a path or SQL (BR-CORE-005). A rejection is never shown as
  its raw text.
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- **Test rules:**
  - Controller tests are plain `test()`s over a `LibraryEnv`.
  - Screen and route tests are `libraryTest`s.
- Goldens render in the Linux container only. On Windows, run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **Tapping "Add deck" twice, or trying to leave while it adds.** One copy is made; the
   sheet cannot be dismissed until it ends. Tests: "a second add while one runs is
   ignored (adding)" (Task 1) and "adding: the options and Cancel lock and the add spins;
   the sheet cannot be dismissed" (Task 2).
2. **Renaming onto an existing tag in another case, or while someone else changes the
   tags.** The merge is told before it is confirmed, with the union count; a merge that
   no longer holds asks again. Tests: "renameMerge: …" and "a merge that appeared after
   the plan opens the dialog again on the name typed (mergeNotConfirmed)" (Task 4).
3. **A tag deleted while it filters the card list.** It leaves the applied set; the
   others keep filtering. Test: "a tag deleted meanwhile leaves the applied set (D12)"
   (Task 5).
4. **A 360 dp phone at text scale 2, in Vietnamese.** Nothing overflows, and every target
   is 48 dp. Tests: the screen 03 and 05 visual audits (Tasks 2, 4) and "at text scale 2
   in Vietnamese the sheet fits a 360 dp phone, with 48 dp targets" (Task 5).
5. **Find cards with this tag.** The search opens typed with the tag's name, showing its
   cards. Test: "Find cards with this tag opens the Library search on its name; Back
   returns to the Library (D11)" (Task 6).

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/shared/widgets/{mx_button,mx_sheet_actions}.dart` | 1, 2 | the warning tone; a disabled Cancel |
| `lib/features/starter_decks/presentation/{providers,controllers,states}/*` | 1 | the reads and the add |
| `lib/features/starter_decks/presentation/{screens,widgets}/*`, `lib/shared/widgets/mx_icon_tile.dart`, `lib/core/theme/foundations/app_icons.dart` | 2 | screen 03 |
| `lib/features/tags/presentation/{providers,controllers,states}/*` | 3 | the catalog and the writes |
| `lib/features/tags/presentation/{screens,widgets}/*`, `lib/features/tags/domain/models/tag_count_model.dart` | 4 | screen 05; the catalog's search |
| `lib/features/card/**` (tag filter) | 5 | the Tags chip, the filter sheet, the filtered list, A7 |
| `lib/features/deck/**`, `lib/features/search/**`, `lib/app/router/*` | 6 | screen 01; the routes; the search's initial query |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | 2, 4, 5, 6 | the copy |
| `docs/**` | 7 | detail files 03 and 05, 01, 07, index, checklist, register, `ui.md`, UC, WBS |

---


### Task 1: The warning tone, the starter reads and the add (D4, D6, D15)

**Files:**
- Create: `lib/features/starter_decks/presentation/controllers/starter_add_controller.dart`
- Create: `lib/features/starter_decks/presentation/providers/add_starter_deck_use_case_provider.dart`
- Create: `lib/features/starter_decks/presentation/providers/starter_library_provider.dart`
- Create: `lib/features/starter_decks/presentation/providers/watch_starter_library_use_case_provider.dart`
- Create: `lib/features/starter_decks/presentation/states/starter_add_state.dart`
- Modify: `lib/shared/widgets/mx_button.dart`
- Modify: `lib/shared/widgets/mx_sheet_actions.dart`
- Modify: `test/app/goldens/app_gallery_dark.png`
- Modify: `test/app/goldens/app_gallery_light.png`
- Modify: `test/shared/widgets/goldens/mx_button_dark.png`
- Modify: `test/shared/widgets/goldens/mx_button_light.png`
- Test (create): `test/features/starter_decks/presentation/starter_add_controller_test.dart`
- Test (modify): `test/shared/widgets/mx_button_test.dart`
- Test (modify): `test/shared/widgets/mx_sheet_actions_test.dart`
- Test (modify): `test/shared/widgets/shared_widgets_golden_test.dart`
- Test (create): `test/support/starter_screen_fixtures.dart`

**Interfaces:**
- Consumes: BE-B4's `WatchStarterLibraryUseCase`, `AddStarterDeckUseCase`,
  `StarterLibraryEntry`, `AddedStarterDeck`, `StarterRejection` over
  `starterLibraryRepositoryProvider`; `MxSemanticColors.warning`/`onWarning`.
- Produces:
  - `MxButtonTone.warning`; `MxSheetActions({…, bool isWarning = false})`;
  - `watchStarterLibraryUseCaseProvider`, `addStarterDeckUseCaseProvider`;
  - `starterLibraryProvider` → `Stream<List<StarterLibraryEntry>>`;
  - `StarterAddState({bool isAdding = false, bool hasFailed = false})`;
  - `sealed class StarterAddResult`: `StarterAdded(AddedStarterDeck deck)`,
    `StarterAlreadyPresent()`;
  - `starterAddControllerProvider` (`StarterAddController`):
    `Future<StarterAddResult?> add({required String templateId, required SchedulerType
    schedulerType, required bool allowSecondCopy})`;
  - test support `StarterLibraryFake(LibraryEnv, {templates, failsLoad, loaded})` with
    `failsAdds`, `hold`, `adds` and `asOverride`; `everydayTemplate`,
    `hangulTemplate` (kit 03's two templates: 120 cards in 4 sub-decks, 60 in 2).

- [ ] **Step 1: Write the failing tests**

`test/features/starter_decks/presentation/starter_add_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/presentation/controllers/starter_add_controller.dart';
import 'package:memox/features/starter_decks/presentation/providers/starter_library_provider.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';
import '../../../support/test_database.dart';

// FE-B4 spec D6: the add behind screen 03's algorithm sheet.

/// The root decks in the library, the Trash included.
Future<int> _roots(LibraryEnv env) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM deck WHERE parent_id IS NULL',
            )
            .getSingle())
        .read<int>('n');

void main() {
  late LibraryEnv env;
  late StarterLibraryFake library;
  late ProviderContainer container;

  setUp(() {
    env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    library = StarterLibraryFake(env);
    container = libraryContainer(env, overrides: [library.asOverride]);
    // The sheet keeps the auto-disposed controller alive.
    container.listen(starterAddControllerProvider, (_, _) {});
  });
  tearDown(() => env.db.close());

  StarterAddController controller() =>
      container.read(starterAddControllerProvider.notifier);

  Future<StarterAddResult?> add({bool allowSecondCopy = false}) =>
      controller().add(
        templateId: hangulTemplate.templateId,
        schedulerType: SchedulerType.sm2,
        allowSecondCopy: allowSecondCopy,
      );

  test('an add copies the template and says what was added; the library '
      'marks it in library', () async {
    container.listen(starterLibraryProvider, (_, _) {});
    final result = await add();

    final added = (result! as StarterAdded).deck;
    expect(
      (added.title, added.schedulerType, added.cardCount),
      (hangulTemplate.title, SchedulerType.sm2, 60),
    );
    await pumpEventQueue();
    final entries = container.read(starterLibraryProvider).value!;
    expect(entries.map((entry) => entry.isInLibrary), [false, true]);
    expect(container.read(starterAddControllerProvider).hasFailed, isFalse);
  });

  test('a template already in the library copies nothing '
      '(alreadyPresent)', () async {
    await add();

    expect(await add(), isA<StarterAlreadyPresent>());
    expect(await _roots(env), 1);
  });

  test('a confirmed second copy is a deck of its own (secondCopy)', () async {
    await add();

    expect(await add(allowSecondCopy: true), isA<StarterAdded>());
    expect(await _roots(env), 2);
  });

  test('a failed write keeps the sheet open and says so; the next add '
      'clears it (addFailed)', () async {
    library.failsAdds = true;

    expect(await add(), isNull);
    expect(container.read(starterAddControllerProvider).hasFailed, isTrue);
    expect(await _roots(env), 0);

    library.failsAdds = false;
    expect(await add(), isA<StarterAdded>());
    expect(container.read(starterAddControllerProvider).hasFailed, isFalse);
  });

  test('a template gone from the build reads as a failure', () async {
    final result = await controller().add(
      templateId: 'fixture.gone',
      schedulerType: SchedulerType.sm2,
      allowSecondCopy: false,
    );

    expect(result, isNull);
    expect(container.read(starterAddControllerProvider).hasFailed, isTrue);
  });

  test('a second add while one runs is ignored (adding)', () async {
    library.hold = Completer<void>();
    final first = add();
    expect(container.read(starterAddControllerProvider).isAdding, isTrue);

    expect(await add(), isNull);
    library.hold!.complete();

    expect(await first, isA<StarterAdded>());
    expect(library.adds, 1);
    expect(container.read(starterAddControllerProvider).isAdding, isFalse);
  });
}
```

`test/shared/widgets/mx_button_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_button_test.dart b/test/shared/widgets/mx_button_test.dart
index 9df232f..7cb150f 100644
--- a/test/shared/widgets/mx_button_test.dart
+++ b/test/shared/widgets/mx_button_test.dart
@@ -85,6 +85,25 @@ void main() {
     );
   });
 
+  testWidgets('warning paints the warning role with its ink, above 4.5:1 in '
+      'both themes (spec D15)', (tester) async {
+    await pumpMx(
+      tester,
+      MxButton(label: 'Merge', tone: MxButtonTone.warning, onPressed: () {}),
+    );
+    final material = _material(tester);
+
+    expect(material.color, MxSemanticColors.light.warning);
+    expect(material.textStyle!.color, MxSemanticColors.light.onWarning);
+    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
+    for (final colors in [MxSemanticColors.light, MxSemanticColors.dark]) {
+      expect(
+        _ratio(colors.warning, colors.onWarning),
+        greaterThanOrEqualTo(4.5),
+      );
+    }
+  });
+
   testWidgets('a detail line sits under the label in the button ink '
       '(FE-A6 P2, screen 16a)', (tester) async {
     await pumpMx(
@@ -423,3 +442,10 @@ void main() {
     expect(loading, idle);
   });
 }
+
+double _ratio(Color a, Color b) {
+  final la = a.computeLuminance();
+  final lb = b.computeLuminance();
+  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
+  return (hi + 0.05) / (lo + 0.05);
+}
```

`test/shared/widgets/mx_sheet_actions_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_sheet_actions_test.dart b/test/shared/widgets/mx_sheet_actions_test.dart
index e88637f..ead7bb8 100644
--- a/test/shared/widgets/mx_sheet_actions_test.dart
+++ b/test/shared/widgets/mx_sheet_actions_test.dart
@@ -93,6 +93,26 @@ void main() {
     );
   });
 
+  testWidgets('a warning confirm, for a merge (spec D15)', (tester) async {
+    await pumpMx(
+      tester,
+      _width(
+        MxSheetActions(
+          cancelLabel: 'Cancel',
+          onCancel: () {},
+          confirmLabel: 'Merge tags',
+          onConfirm: () {},
+          isWarning: true,
+        ),
+      ),
+    );
+
+    expect(
+      tester.widget<MxButton>(_button('Merge tags')).tone,
+      MxButtonTone.warning,
+    );
+  });
+
   testWidgets('a disabled confirm leaves Cancel live (RF3)', (tester) async {
     var cancels = 0;
     await pumpMx(
```

`test/shared/widgets/shared_widgets_golden_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/shared_widgets_golden_test.dart b/test/shared/widgets/shared_widgets_golden_test.dart
index 6283ca5..27b3fd3 100644
--- a/test/shared/widgets/shared_widgets_golden_test.dart
+++ b/test/shared/widgets/shared_widgets_golden_test.dart
@@ -31,8 +31,15 @@ void main() {
         crossAxisAlignment: CrossAxisAlignment.start,
         spacing: 8,
         children: [
-          for (final tone in MxButtonTone.values)
-            MxButton(label: tone.name, tone: tone, onPressed: () {}),
+          // The six tones share rows, so the column keeps to the phone.
+          Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            children: [
+              for (final tone in MxButtonTone.values)
+                MxButton(label: tone.name, tone: tone, onPressed: () {}),
+            ],
+          ),
           MxButton(
             label: 'Small',
             size: MxButtonSize.small,
```

`test/support/starter_screen_fixtures.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/di/starter_library_repository_provider.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

import 'library_harness.dart';

/// The everyday template of kit 03: English → Vietnamese, 120 cards in four
/// sub-decks, suggesting Eight boxes.
final StarterTemplate everydayTemplate = _template(
  id: 'fixture.everyday-en-vi',
  title: 'English → Vietnamese · Everyday',
  front: 'en',
  back: 'vi',
  scheduler: SchedulerType.eightBox,
  decks: ['Greetings', 'Food', 'Travel', 'Numbers'],
);

/// The Hangul template of kit 03: Korean → Romanisation, 60 cards in two
/// sub-decks, suggesting SM-2.
final StarterTemplate hangulTemplate = _template(
  id: 'fixture.hangul-basics',
  title: 'Korean → Romanisation · Hangul basics',
  front: 'ko',
  back: 'ko-Latn',
  scheduler: SchedulerType.sm2,
  decks: ['Consonants', 'Vowels'],
);

/// Thirty cards per sub-deck.
StarterTemplate _template({
  required String id,
  required String title,
  required String front,
  required String back,
  required SchedulerType scheduler,
  required List<String> decks,
}) => StarterTemplate(
  templateId: id,
  version: 1,
  locale: 'en',
  title: title,
  contentSource: 'Development fixture',
  frontLanguage: front,
  backLanguage: back,
  suggestedScheduler: scheduler,
  decks: [
    for (final name in decks)
      StarterDeck(
        name: name,
        cards: [
          for (var i = 0; i < 30; i++)
            StarterCard(front: '$name $i', back: 'b$i'),
        ],
      ),
  ],
);

/// The Starter library over [LibraryEnv]'s database, with the templates a
/// test chooses and the failures it needs.
final class StarterLibraryFake implements StarterLibraryRepository {
  StarterLibraryFake(
    LibraryEnv env, {
    List<StarterTemplate>? templates,
    bool failsLoad = false,
  }) : _library = StarterLibraryRepositoryImpl(
         env.db,
         env.decks,
         env.cards,
         templates: () async {
           if (failsLoad) {
             throw UnknownDatabaseFailure(cause: StateError('load failed'));
           }
           return templates ?? [everydayTemplate, hangulTemplate];
         },
       );

  final StarterLibraryRepositoryImpl _library;

  /// The next add throws as a full disk does (`addFailed`).
  bool failsAdds = false;

  /// Holds every add until completed (`adding`).
  Completer<void>? hold;

  /// Adds that reached the store.
  int adds = 0;

  Override get asOverride =>
      starterLibraryRepositoryProvider.overrideWithValue(this);

  @override
  Stream<List<StarterLibraryEntry>> watchLibrary() => _library.watchLibrary();

  @override
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  }) async {
    adds++;
    await hold?.future;
    if (failsAdds) {
      throw UnknownDatabaseFailure(cause: StateError('disk full'));
    }
    return _library.addStarterDeck(
      templateId: templateId,
      schedulerType: schedulerType,
      allowSecondCopy: allowSecondCopy,
      now: now,
    );
  }
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/presentation/starter_add_controller_test.dart test/shared/widgets/mx_button_test.dart test/shared/widgets/mx_sheet_actions_test.dart
```

Expected: FAIL to compile: `MxButtonTone` has no `warning`, `MxSheetActions` no
`isWarning`, and the starter presentation files do not exist.

- [ ] **Step 3: Implement**

`lib/features/starter_decks/presentation/controllers/starter_add_controller.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/presentation/providers/add_starter_deck_use_case_provider.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'starter_add_controller.g.dart';

/// The algorithm sheet's add (UC-STARTER-001 step 8, A2; FE-B4 spec D6). It
/// lives while the sheet does, so each sheet starts clean.
@riverpod
class StarterAddController extends _$StarterAddController {
  @override
  StarterAddState build() => const StarterAddState();

  /// Adds [templateId] under [schedulerType]. Null keeps the sheet open: an
  /// add while one runs is ignored, and a failed one sets
  /// [StarterAddState.hasFailed]. `templateNotFound` reads as a failure,
  /// never as its own message (spec §6).
  Future<StarterAddResult?> add({
    required String templateId,
    required SchedulerType schedulerType,
    required bool allowSecondCopy,
  }) async {
    if (state.isAdding) return null;
    state = const StarterAddState(isAdding: true);
    try {
      final outcome = await ref.read(addStarterDeckUseCaseProvider)(
        templateId: templateId,
        schedulerType: schedulerType,
        allowSecondCopy: allowSecondCopy,
      );
      final result = switch (outcome) {
        Ok(:final value) => StarterAdded(value),
        Rejected(reason: StarterRejection.alreadyInLibrary) =>
          const StarterAlreadyPresent(),
        Rejected(reason: StarterRejection.templateNotFound) => null,
      };
      if (ref.mounted) state = StarterAddState(hasFailed: result == null);
      return result;
    } on Failure {
      if (ref.mounted) state = const StarterAddState(hasFailed: true);
      return null;
    }
  }
}
```

`lib/features/starter_decks/presentation/providers/add_starter_deck_use_case_provider.dart`:

```dart
import 'package:memox/features/starter_decks/di/starter_library_repository_provider.dart';
import 'package:memox/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_starter_deck_use_case_provider.g.dart';

@riverpod
AddStarterDeckUseCase addStarterDeckUseCase(Ref ref) =>
    AddStarterDeckUseCase(ref.watch(starterLibraryRepositoryProvider));
```

`lib/features/starter_decks/presentation/providers/starter_library_provider.dart`:

```dart
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/providers/watch_starter_library_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'starter_library_provider.g.dart';

/// Screen 03's templates, each with whether it is in the library
/// (UC-STARTER-001 steps 4-5). An add flips "In library" in place.
@riverpod
Stream<List<StarterLibraryEntry>> starterLibrary(Ref ref) =>
    ref.watch(watchStarterLibraryUseCaseProvider)();
```

`lib/features/starter_decks/presentation/providers/watch_starter_library_use_case_provider.dart`:

```dart
import 'package:memox/features/starter_decks/di/starter_library_repository_provider.dart';
import 'package:memox/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_starter_library_use_case_provider.g.dart';

@riverpod
WatchStarterLibraryUseCase watchStarterLibraryUseCase(Ref ref) =>
    WatchStarterLibraryUseCase(ref.watch(starterLibraryRepositoryProvider));
```

`lib/features/starter_decks/presentation/states/starter_add_state.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';

/// The algorithm sheet's add (FE-B4 spec D6): running, or failed with the
/// sheet still open (`addFailed`).
@immutable
final class StarterAddState {
  const StarterAddState({this.isAdding = false, this.hasFailed = false});

  /// The options and Cancel lock, and "Add deck" spins (`adding`).
  final bool isAdding;

  /// The last add wrote nothing: the banner shows and the button reads
  /// "Try again" (`addFailed`).
  final bool hasFailed;
}

/// An add that closes the sheet; the screen toasts it.
sealed class StarterAddResult {
  const StarterAddResult();
}

/// `added`: the copy is in the library; Open goes to [deck]'s root.
final class StarterAdded extends StarterAddResult {
  const StarterAdded(this.deck);

  final AddedStarterDeck deck;
}

/// `alreadyPresent`: a copy was there already and nothing was copied.
final class StarterAlreadyPresent extends StarterAddResult {
  const StarterAlreadyPresent();
}
```

`lib/shared/widgets/mx_button.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_button.dart b/lib/shared/widgets/mx_button.dart
index 0de478a..98b42e1 100644
--- a/lib/shared/widgets/mx_button.dart
+++ b/lib/shared/widgets/mx_button.dart
@@ -9,9 +9,17 @@ import 'package:memox/core/theme/theme_context.dart';
 import 'package:memox/core/theme/app_button_style.dart';
 import 'package:memox/shared/widgets/mx_spinner.dart';
 
-/// Colour role of a button: the contract's four shipped tones, and the soft
-/// danger tint of a grade that marks a lapse (screen 16a).
-enum MxButtonTone { primary, secondary, outline, destructive, dangerSoft }
+/// Colour role of a button: the contract's four shipped tones, the soft
+/// danger tint of a grade that marks a lapse (screen 16a), and the warning
+/// fill of a merge (screen 05; FE-B2 spec D15).
+enum MxButtonTone {
+  primary,
+  secondary,
+  outline,
+  destructive,
+  dangerSoft,
+  warning,
+}
 
 /// Painted geometry. [chip] and [study] are the contract's geometry variants;
 /// the touch area is 48 for every size.
@@ -185,6 +193,13 @@ class MxButton extends StatelessWidget {
           width: AppStroke.hairline,
         ),
       ),
+      // The warning role and its ink, not the kit's orange and white, which
+      // is about 2.8:1 (FE-B2 spec D15).
+      MxButtonTone.warning => (
+        fill: context.semanticColors.warning,
+        ink: context.semanticColors.onWarning,
+        edge: BorderSide.none,
+      ),
     };
   }
 
```

`lib/shared/widgets/mx_sheet_actions.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_sheet_actions.dart b/lib/shared/widgets/mx_sheet_actions.dart
index 56fd392..491669a 100644
--- a/lib/shared/widgets/mx_sheet_actions.dart
+++ b/lib/shared/widgets/mx_sheet_actions.dart
@@ -18,9 +18,11 @@ class MxSheetActions extends StatelessWidget {
     required this.onConfirm,
     this.confirmIcon,
     this.isDestructive = false,
+    this.isWarning = false,
     this.isInSheet = false,
     this.isConfirmLoading = false,
-  }) : children = const [];
+  }) : assert(!(isDestructive && isWarning), 'a confirm has one tone'),
+       children = const [];
 
   /// A custom footer (Trash restore / delete-forever, a single OK) in place
   /// of the pair (ruling O10).
@@ -35,6 +37,7 @@ class MxSheetActions extends StatelessWidget {
        onConfirm = null,
        confirmIcon = null,
        isDestructive = false,
+       isWarning = false,
        isConfirmLoading = false;
 
   final String? cancelLabel;
@@ -48,6 +51,9 @@ class MxSheetActions extends StatelessWidget {
   /// The destructive Button tone on the confirm.
   final bool isDestructive;
 
+  /// The warning Button tone on the confirm: a merge (FE-B2 spec D15).
+  final bool isWarning;
+
   /// The confirm's work is running: it spins and cannot be pressed; Cancel
   /// stays live.
   final bool isConfirmLoading;
@@ -77,9 +83,11 @@ class MxSheetActions extends StatelessWidget {
               onPressed: onConfirm,
               icon: confirmIcon,
               isLoading: isConfirmLoading,
-              tone: isDestructive
-                  ? MxButtonTone.destructive
-                  : MxButtonTone.primary,
+              tone: switch ((isDestructive, isWarning)) {
+                (true, _) => MxButtonTone.destructive,
+                (_, true) => MxButtonTone.warning,
+                _ => MxButtonTone.primary,
+              },
               isBlock: true,
               isSingleLine: true,
             ),
```

- [ ] **Step 4: Generate, render the goldens and run**

```bash
dart run build_runner build --delete-conflicting-outputs
TZ=UTC flutter test --tags golden --update-goldens test/shared/widgets/shared_widgets_golden_test.dart test/app/app_golden_test.dart
flutter test test/features/starter_decks test/shared
flutter analyze
```

Expected: PASS, 6 tests in `starter_add_controller_test.dart`. Two goldens change
and no other: `mx_button_*` (the six tones in rows, "warning" amber with dark ink) and
`app_gallery_*` (the gallery lists the new tone).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/starter_decks/presentation/controllers/starter_add_controller.dart \
  lib/features/starter_decks/presentation/providers/add_starter_deck_use_case_provider.dart \
  lib/features/starter_decks/presentation/providers/starter_library_provider.dart \
  lib/features/starter_decks/presentation/providers/watch_starter_library_use_case_provider.dart \
  lib/features/starter_decks/presentation/states/starter_add_state.dart \
  lib/shared/widgets/mx_button.dart \
  lib/shared/widgets/mx_sheet_actions.dart \
  test/features/starter_decks/presentation/starter_add_controller_test.dart \
  test/shared/widgets/mx_button_test.dart \
  test/shared/widgets/mx_sheet_actions_test.dart \
  test/shared/widgets/shared_widgets_golden_test.dart \
  test/support/starter_screen_fixtures.dart \
  test/app/goldens/app_gallery_dark.png \
  test/app/goldens/app_gallery_light.png \
  test/shared/widgets/goldens/mx_button_dark.png \
  test/shared/widgets/goldens/mx_button_light.png
git commit -m "$(cat <<'EOF'
feat(starter): the warning tone, the starter reads and the add (FE-B4 D6, FE-B2 D15)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: Screen 03, Starter decks (UC-STARTER-001)

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Create: `lib/features/starter_decks/presentation/screens/starter_library_screen.dart`
- Create: `lib/features/starter_decks/presentation/widgets/items/starter_template_card_widget.dart`
- Create: `lib/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart`
- Create: `lib/features/starter_decks/presentation/widgets/overlays/starter_repeat_add_dialog_widget.dart`
- Create: `lib/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart`
- Modify: `lib/shared/widgets/mx_icon_tile.dart`
- Modify: `lib/shared/widgets/mx_sheet_actions.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/starter_decks/presentation/goldens/starter_add_failed_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_add_failed_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_added_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_added_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_adding_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_adding_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_already_present_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_already_present_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_choose_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_choose_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_list_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_list_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_load_failed_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_load_failed_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_loading_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_loading_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_none_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_none_light.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_second_copy_dark.png`
- Create: `test/features/starter_decks/presentation/goldens/starter_second_copy_light.png`
- Test (create): `test/features/starter_decks/presentation/starter_library_golden_test.dart`
- Test (create): `test/features/starter_decks/presentation/starter_library_screen_test.dart`
- Test (modify): `test/shared/widgets/mx_sheet_actions_test.dart`
- Test (modify): `test/support/starter_screen_fixtures.dart`
- Test (create): `test/visual_audit/screens/features/starter_decks/screens/starter_library_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 1's providers, controller, state, fixtures and the nullable `onCancel`.
- Produces:
  - `StarterLibraryScreen({required ValueChanged<String> onOpenDeck, required
    VoidCallback onCreateDeck})`;
  - `showStarterAlgorithmSheet(context, {required StarterLibraryEntry entry, required bool
    isSecondCopy})` → `Future<StarterAddResult?>`;
  - `showStarterRepeatAddDialog(context, {required String title})` → `Future<bool>`;
  - `starterLanguageName`, `starterSchedulerName`, `starterSchedulerDescription`,
    `starterEntryFacts`; `AppIcons.fixture`; `MxIconTile.mediumBox`;
  - the `starter…` ARB keys.

- [ ] **Step 1: Write the failing tests**

`test/features/starter_decks/presentation/starter_library_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';

// Screen 03 (FE-B4) against the kit's ten frames: the everyday template is
// in the library, as the kit draws it.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    /// The library with the everyday copy, unless [isSeeded] is false.
    Future<StarterLibraryFake> library(
      LibraryEnv env, {
      bool isSeeded = true,
      StarterLibraryFake? fake,
    }) async {
      final library = fake ?? StarterLibraryFake(env);
      if (isSeeded) {
        await library.addStarterDeck(
          templateId: everydayTemplate.templateId,
          schedulerType: everydayTemplate.suggestedScheduler,
        );
      }
      return library;
    }

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      StarterLibraryFake library,
      String name, {
      Future<void> Function()? before,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          StarterLibraryScreen(onOpenDeck: (_) {}, onCreateDeck: () {}),
          brightness,
          overrides: [library.asOverride],
        );
        await before?.call();
        await expectBoundaryGolden(
          tester,
          'goldens/starter_${name}_$theme.png',
        );
      });
    }

    Future<void> openHangul(WidgetTester tester) async {
      await tester.tap(
        find.widgetWithText(MxButton, _en.starterAddToLibrary).last,
      );
      await tester.pumpAndSettle();
    }

    Future<void> add(WidgetTester tester) async {
      await tester.tap(find.text(_en.starterAddDeck));
      await tester.pumpAndSettle();
    }

    libraryTest('starter, list, $theme', (tester, env) async {
      await shoot(tester, env, await library(env), 'list');
    });

    libraryTest('starter, choose, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        await library(env),
        'choose',
        before: () => openHangul(tester),
      );
    });

    libraryTest('starter, adding, $theme', (tester, env) async {
      final fake = await library(env);
      fake.hold = Completer<void>();
      await shoot(
        tester,
        env,
        fake,
        'adding',
        before: () async {
          await openHangul(tester);
          await tester.tap(find.text(_en.starterAddDeck));
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
      fake.hold!.complete();
      await tester.pumpAndSettle();
    });

    libraryTest('starter, added, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        await library(env),
        'added',
        before: () async {
          await openHangul(tester);
          await add(tester);
        },
      );
    });

    libraryTest('starter, alreadyPresent, $theme', (tester, env) async {
      final fake = await library(env);
      await shoot(
        tester,
        env,
        fake,
        'already_present',
        before: () async {
          await openHangul(tester);
          await fake.addStarterDeck(
            templateId: hangulTemplate.templateId,
            schedulerType: hangulTemplate.suggestedScheduler,
          );
          await add(tester);
        },
      );
    });

    libraryTest('starter, secondCopy, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        await library(env),
        'second_copy',
        before: () async {
          await tester.tap(find.text(_en.starterAddAnotherCopy));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('starter, addFailed, $theme', (tester, env) async {
      final fake = await library(env);
      fake.failsAdds = true;
      await shoot(
        tester,
        env,
        fake,
        'add_failed',
        before: () async {
          await openHangul(tester);
          await add(tester);
        },
      );
    });

    libraryTest('starter, loading, $theme', (tester, env) async {
      final loaded = Completer<void>();
      await shoot(
        tester,
        env,
        StarterLibraryFake(env, loaded: loaded.future),
        'loading',
      );
      loaded.complete();
    });

    libraryTest('starter, none, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        StarterLibraryFake(env, templates: const []),
        'none',
      );
    });

    libraryTest('starter, loadFailed, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        StarterLibraryFake(env, failsLoad: true),
        'load_failed',
        before: () => tester.pumpAndSettle(),
      );
    });
  }
}
```

`test/features/starter_decks/presentation/starter_library_screen_test.dart`:

```dart
import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';

// Screen 03 (FE-B4, UC-STARTER-001): the ten kit states.

final _en = lookupAppLocalizations(const Locale('en'));

/// The root decks copied from the Hangul template, by scheduler.
Future<List<String>> _hangulCopies(LibraryEnv env) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT scheduler_type FROM deck WHERE source_template_id = ? '
            'ORDER BY created_at, id',
            variables: [Variable<String>(hangulTemplate.templateId)],
          )
          .get())
    row.read<String>('scheduler_type'),
];

Finder _cardButton(String label) => find.widgetWithText(MxButton, label);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StarterLibraryFake library, {
  ValueChanged<String>? onOpenDeck,
  VoidCallback? onCreateDeck,
}) => pumpLibraryScreen(
  tester,
  env,
  StarterLibraryScreen(
    onOpenDeck: onOpenDeck ?? (_) {},
    onCreateDeck: onCreateDeck ?? () {},
  ),
  overrides: [library.asOverride],
);

/// Taps the Hangul card's add, which is its second button.
Future<void> _addHangul(WidgetTester tester, String label) async {
  await tester.tap(_cardButton(label).last);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('list: the note, then a card per template with its facts, '
      'its add and what it suggests', (tester, env) async {
    await _pump(tester, env, StarterLibraryFake(env));

    expect(find.text(_en.starterNote), findsOneWidget);
    expect(find.text(everydayTemplate.title), findsOneWidget);
    expect(
      find.text(
        'Korean · Latin · 60 cards · 2 sub-decks · Development fixture',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'English · Vietnamese · 120 cards · 4 sub-decks · '
        'Development fixture',
      ),
      findsOneWidget,
    );
    expect(_cardButton(_en.starterAddToLibrary), findsNWidgets(2));
    expect(find.text(_en.starterSuggests('SM-2')), findsOneWidget);
    expect(find.text(_en.starterSuggests('Eight boxes')), findsOneWidget);
    expect(find.text(_en.starterInLibrary), findsNothing);
  });

  libraryTest('choose: the sheet preselects the suggested scheduler; the one '
      'picked is the copy\'s, and the toast opens it (added)', (
    tester,
    env,
  ) async {
    String? opened;
    await _pump(
      tester,
      env,
      StarterLibraryFake(env),
      onOpenDeck: (id) => opened = id,
    );
    await _addHangul(tester, _en.starterAddToLibrary);

    expect(find.text(_en.starterSheetTitle(hangulTemplate.title)), findsOne);
    expect(find.text(_en.starterSheetBody(60, 2)), findsOneWidget);
    final sm2 = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, 'SM-2'),
    );
    expect(sm2.isSelected, isTrue);
    expect(sm2.description, _en.starterSuggested(_en.starterSm2Description));

    await tester.tap(find.text('Eight boxes').last);
    await tester.pump();
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(await _hangulCopies(env), ['eight_box']);
    expect(
      find.text(_en.starterAdded(hangulTemplate.title, 'Eight boxes', 60)),
      findsOneWidget,
    );
    expect(find.text(_en.starterInLibrary), findsOneWidget);
    await tester.tap(find.text(_en.starterOpen));
    await tester.pump();
    final rootId = await env.db
        .customSelect(
          'SELECT id FROM deck WHERE source_template_id = ?',
          variables: [Variable<String>(hangulTemplate.templateId)],
        )
        .getSingle();
    expect(opened, rootId.read<String>('id'));
  });

  libraryTest('adding: the options and Cancel lock and the add spins; the '
      'sheet cannot be dismissed', (tester, env) async {
    final library = StarterLibraryFake(env)..hold = Completer<void>();
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddToLibrary);
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    for (final row in tester.widgetList<MxOptionRow>(
      find.byType(MxOptionRow),
    )) {
      expect(row.onSelected, isNull);
    }
    expect(
      tester.widget<MxButton>(_cardButton(_en.commonCancel)).onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(180, 40));
    await tester.pump();
    expect(find.byType(MxOptionRow), findsNWidgets(2));

    library.hold!.complete();
    await tester.pumpAndSettle();
    expect(library.adds, 1);
    expect(find.byType(MxOptionRow), findsNothing);
  });

  libraryTest('alreadyPresent: a copy made while the sheet was open copies '
      'nothing more', (tester, env) async {
    final library = StarterLibraryFake(env);
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddToLibrary);
    await library.addStarterDeck(
      templateId: hangulTemplate.templateId,
      schedulerType: SchedulerType.sm2,
    );
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(find.text(_en.starterAlreadyPresent), findsOneWidget);
    expect(await _hangulCopies(env), ['sm2']);
  });

  libraryTest('secondCopy: a template in the library asks first; Cancel '
      'copies nothing, confirming adds a deck of its own', (tester, env) async {
    final library = StarterLibraryFake(env);
    await library.addStarterDeck(
      templateId: hangulTemplate.templateId,
      schedulerType: SchedulerType.sm2,
    );
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddAnotherCopy);

    expect(find.text(_en.starterSecondCopyTitle), findsOneWidget);
    expect(
      find.text(_en.starterSecondCopyBody(hangulTemplate.title)),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(MxOptionRow), findsNothing);

    await _addHangul(tester, _en.starterAddAnotherCopy);
    await tester.tap(find.text(_en.starterSecondCopyConfirm));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(await _hangulCopies(env), ['sm2', 'sm2']);
    expect(
      find.text(_en.starterAdded(hangulTemplate.title, 'SM-2', 60)),
      findsOneWidget,
    );
  });

  libraryTest('addFailed: the sheet stays with the choice and says so; Try '
      'again adds', (tester, env) async {
    final library = StarterLibraryFake(env)..failsAdds = true;
    await _pump(tester, env, library);
    await _addHangul(tester, _en.starterAddToLibrary);
    await tester.tap(find.text('Eight boxes').last);
    await tester.pump();
    await tester.tap(find.text(_en.starterAddDeck));
    await tester.pumpAndSettle();

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.starterAddFailedBody), findsOneWidget);
    expect(
      tester
          .widget<MxOptionRow>(find.widgetWithText(MxOptionRow, 'Eight boxes'))
          .isSelected,
      isTrue,
    );
    expect(await _hangulCopies(env), isEmpty);

    library.failsAdds = false;
    await tester.tap(find.text(_en.starterTryAgain));
    await tester.pumpAndSettle();
    expect(await _hangulCopies(env), ['eight_box']);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('none: a build without templates offers to create a deck', (
    tester,
    env,
  ) async {
    var creates = 0;
    await _pump(
      tester,
      env,
      StarterLibraryFake(env, templates: const []),
      onCreateDeck: () => creates++,
    );

    expect(find.text(_en.starterNoneTitle), findsOneWidget);
    expect(find.byType(MxEmptyState), findsOneWidget);
    await tester.tap(find.text(_en.starterCreateDeck));
    expect(creates, 1);
  });

  libraryTest('loading, then loadFailed with Retry; the message carries no '
      'failure text', (tester, env) async {
    final loaded = Completer<void>();
    await _pump(
      tester,
      env,
      StarterLibraryFake(env, failsLoad: true, loaded: loaded.future),
    );
    expect(find.bySemanticsLabel(_en.commonLoading), findsOneWidget);

    loaded.complete();
    await tester.pumpAndSettle();
    expect(find.text(_en.starterLoadErrorTitle), findsOneWidget);
    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.textContaining('load failed'), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
  });
}
```

`test/shared/widgets/mx_sheet_actions_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_sheet_actions_test.dart b/test/shared/widgets/mx_sheet_actions_test.dart
index ead7bb8..85099f6 100644
--- a/test/shared/widgets/mx_sheet_actions_test.dart
+++ b/test/shared/widgets/mx_sheet_actions_test.dart
@@ -113,6 +113,25 @@ void main() {
     );
   });
 
+  testWidgets('a null Cancel is disabled while the confirm runs', (
+    tester,
+  ) async {
+    await pumpMx(
+      tester,
+      _width(
+        MxSheetActions(
+          cancelLabel: 'Cancel',
+          onCancel: null,
+          confirmLabel: 'Add deck',
+          onConfirm: () {},
+          isConfirmLoading: true,
+        ),
+      ),
+    );
+
+    expect(tester.widget<MxButton>(_button('Cancel')).onPressed, isNull);
+  });
+
   testWidgets('a disabled confirm leaves Cancel live (RF3)', (tester) async {
     var cancels = 0;
     await pumpMx(
```

`test/support/starter_screen_fixtures.dart` (apply this diff):

```diff
diff --git a/test/support/starter_screen_fixtures.dart b/test/support/starter_screen_fixtures.dart
index 653514b..caff7b2 100644
--- a/test/support/starter_screen_fixtures.dart
+++ b/test/support/starter_screen_fixtures.dart
@@ -72,11 +72,14 @@ final class StarterLibraryFake implements StarterLibraryRepository {
     LibraryEnv env, {
     List<StarterTemplate>? templates,
     bool failsLoad = false,
+    Future<void>? loaded,
   }) : _library = StarterLibraryRepositoryImpl(
          env.db,
          env.decks,
          env.cards,
          templates: () async {
+           // A read that never ends leaves the screen `loading`.
+           await loaded;
            if (failsLoad) {
              throw UnknownDatabaseFailure(cause: StateError('load failed'));
            }
```

`test/visual_audit/screens/features/starter_decks/screens/starter_library_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/starter_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 03, ${locale.languageCode}', (tester, env) async {
      final library = StarterLibraryFake(env);
      // One card says "In library" and "Add another copy", the longest.
      await library.addStarterDeck(
        templateId: everydayTemplate.templateId,
        schedulerType: everydayTemplate.suggestedScheduler,
      );
      await auditProductionScreen(
        tester,
        screen: StarterLibraryScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          StarterLibraryScreen(onOpenDeck: (_) {}, onCreateDeck: () {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: [library.asOverride],
        ),
      );
    });
  }
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/presentation/starter_library_screen_test.dart
```

Expected: FAIL to compile: `starter_library_screen.dart` does not exist.

- [ ] **Step 3: Implement**

The copy: apply the ARB diffs, then the code.

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 0d3d147..3c98996 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -5408,5 +5408,194 @@
   "studyOptionsSaved": "Saved · applies to the next session",
   "@studyOptionsSaved": {
     "description": "Screen handoff 15 (FE-A3 plan 2): toast after a save."
+  },
+  "starterTitle": "Starter decks",
+  "@starterTitle": {
+    "description": "Screen 03: the app bar title."
+  },
+  "starterNote": "These decks are practice fixtures for development and testing, not published course material. Anything you add is yours to edit.",
+  "@starterNote": {
+    "description": "Screen 03: the note above the templates (BR-STARTER-010)."
+  },
+  "starterInLibrary": "In library",
+  "@starterInLibrary": {
+    "description": "Screen 03: the badge of a template already in the library."
+  },
+  "starterCardCount": "{count, plural, =1{1 card} other{{count} cards}}",
+  "@starterCardCount": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 03: a template's card count."
+  },
+  "starterSubDeckCount": "{count, plural, =1{1 sub-deck} other{{count} sub-decks}}",
+  "@starterSubDeckCount": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 03: a template's sub-deck count."
+  },
+  "starterAddToLibrary": "Add to library",
+  "@starterAddToLibrary": {
+    "description": "Screen 03: adds a template not in the library yet."
+  },
+  "starterAddAnotherCopy": "Add another copy",
+  "@starterAddAnotherCopy": {
+    "description": "Screen 03: adds a second copy of a template (BR-STARTER-008)."
+  },
+  "starterSuggests": "Suggests {algorithm}",
+  "@starterSuggests": {
+    "placeholders": {
+      "algorithm": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 03: the scheduler a template suggests (BR-STARTER-004)."
+  },
+  "starterSchedulerSm2": "SM-2",
+  "@starterSchedulerSm2": {
+    "description": "Screen 03: the SM-2 scheduler's name."
+  },
+  "starterSchedulerEightBox": "Eight boxes",
+  "@starterSchedulerEightBox": {
+    "description": "Screen 03: the Eight boxes scheduler's name."
+  },
+  "starterLanguageEnglish": "English",
+  "@starterLanguageEnglish": {
+    "description": "Screen 03: the language tag en."
+  },
+  "starterLanguageVietnamese": "Vietnamese",
+  "@starterLanguageVietnamese": {
+    "description": "Screen 03: the language tag vi."
+  },
+  "starterLanguageKorean": "Korean",
+  "@starterLanguageKorean": {
+    "description": "Screen 03: the language tag ko."
+  },
+  "starterLanguageLatin": "Latin",
+  "@starterLanguageLatin": {
+    "description": "Screen 03: a language tag in the Latin script, such as ko-Latn (spec D7)."
+  },
+  "starterSheetTitle": "Add “{title}”",
+  "@starterSheetTitle": {
+    "placeholders": {
+      "title": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 03 algorithm sheet: the title."
+  },
+  "starterSheetBody": "{cards, plural, =1{1 card} other{{cards} cards}} in {decks, plural, =1{1 sub-deck} other{{decks} sub-decks}}, as a new deck of your own.",
+  "@starterSheetBody": {
+    "placeholders": {
+      "cards": {
+        "type": "int"
+      },
+      "decks": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 03 algorithm sheet: what the copy holds."
+  },
+  "starterSheetOverline": "Review algorithm · required",
+  "@starterSheetOverline": {
+    "description": "Screen 03 algorithm sheet: the header above the two schedulers."
+  },
+  "starterSm2Description": "grade yourself, intervals adapt",
+  "@starterSm2Description": {
+    "description": "Screen 03 algorithm sheet: what SM-2 does."
+  },
+  "starterEightBoxDescription": "Boxes 1–8 · match, guess, recall, fill",
+  "@starterEightBoxDescription": {
+    "description": "Screen 03 algorithm sheet: what Eight boxes does."
+  },
+  "starterSuggested": "Suggested for this deck · {description}",
+  "@starterSuggested": {
+    "placeholders": {
+      "description": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 03 algorithm sheet: the suggested scheduler's description."
+  },
+  "starterAddDeck": "Add deck",
+  "@starterAddDeck": {
+    "description": "Screen 03 algorithm sheet: adds the template."
+  },
+  "starterTryAgain": "Try again",
+  "@starterTryAgain": {
+    "description": "Screen 03 algorithm sheet: adds again after a failure (addFailed)."
+  },
+  "starterAddFailedTitle": "Couldn't add the deck.",
+  "@starterAddFailedTitle": {
+    "description": "Screen 03 algorithm sheet: the failure banner's lead (addFailed)."
+  },
+  "starterAddFailedBody": "Nothing was copied — try again.",
+  "@starterAddFailedBody": {
+    "description": "Screen 03 algorithm sheet: the failure banner's body (addFailed)."
+  },
+  "starterAdded": "Added “{title}” · {algorithm} · {count, plural, =1{1 new card} other{{count} new cards}}",
+  "@starterAdded": {
+    "placeholders": {
+      "title": {
+        "type": "String"
+      },
+      "algorithm": {
+        "type": "String"
+      },
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 03: the toast after an add (added)."
+  },
+  "starterOpen": "Open",
+  "@starterOpen": {
+    "description": "Screen 03: the added toast's action; opens the new deck."
+  },
+  "starterAlreadyPresent": "Already in your library — nothing was copied",
+  "@starterAlreadyPresent": {
+    "description": "Screen 03: the toast when a copy is already there (alreadyPresent)."
+  },
+  "starterSecondCopyTitle": "Add a second copy?",
+  "@starterSecondCopyTitle": {
+    "description": "Screen 03 second copy dialog: the title (BR-STARTER-008)."
+  },
+  "starterSecondCopyBody": "“{title}” is already in your library. A second copy is a separate deck with its own progress.",
+  "@starterSecondCopyBody": {
+    "placeholders": {
+      "title": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 03 second copy dialog: the body."
+  },
+  "starterSecondCopyConfirm": "Add second copy",
+  "@starterSecondCopyConfirm": {
+    "description": "Screen 03 second copy dialog: confirms and opens the algorithm sheet."
+  },
+  "starterNoneTitle": "No starter decks in this build",
+  "@starterNoneTitle": {
+    "description": "Screen 03: the empty state title (none)."
+  },
+  "starterNoneBody": "This version ships without practice content. Create a deck or import cards instead.",
+  "@starterNoneBody": {
+    "description": "Screen 03: the empty state body (none)."
+  },
+  "starterCreateDeck": "Create a deck",
+  "@starterCreateDeck": {
+    "description": "Screen 03: the empty state action; back to the Library's create dialog."
+  },
+  "starterLoadErrorTitle": "Couldn't load starter decks",
+  "@starterLoadErrorTitle": {
+    "description": "Screen 03: the read error title (loadFailed)."
+  },
+  "starterLoadErrorBody": "Your library is unaffected. Try again in a moment.",
+  "@starterLoadErrorBody": {
+    "description": "Screen 03: the read error body (loadFailed)."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index b72fa90..f5977f2 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -1020,5 +1020,40 @@
   "studyOptionsSaveFailed": "Chưa lưu được. Bộ thẻ vẫn dùng {count} thẻ, {order}.",
   "studyOptionsLocalOnly": "Chỉ lưu trên thiết bị này.",
   "studyOptionsSaving": "Đang lưu…",
-  "studyOptionsSaved": "Đã lưu · áp dụng cho phiên sau"
+  "studyOptionsSaved": "Đã lưu · áp dụng cho phiên sau",
+  "starterTitle": "Deck mẫu",
+  "starterNote": "Các deck này là dữ liệu mẫu để phát triển và kiểm thử, không phải giáo trình đã phát hành. Mọi thứ bạn thêm đều là của bạn và sửa được.",
+  "starterInLibrary": "Trong thư viện",
+  "starterCardCount": "{count} thẻ",
+  "starterSubDeckCount": "{count} deck con",
+  "starterAddToLibrary": "Thêm vào thư viện",
+  "starterAddAnotherCopy": "Thêm một bản nữa",
+  "starterSuggests": "Gợi ý {algorithm}",
+  "starterSchedulerSm2": "SM-2",
+  "starterSchedulerEightBox": "Tám hộp",
+  "starterLanguageEnglish": "Tiếng Anh",
+  "starterLanguageVietnamese": "Tiếng Việt",
+  "starterLanguageKorean": "Tiếng Hàn",
+  "starterLanguageLatin": "Chữ Latinh",
+  "starterSheetTitle": "Thêm “{title}”",
+  "starterSheetBody": "{cards} thẻ trong {decks} deck con, thành một deck mới của riêng bạn.",
+  "starterSheetOverline": "Thuật toán ôn tập · bắt buộc",
+  "starterSm2Description": "tự chấm điểm, khoảng cách tự điều chỉnh",
+  "starterEightBoxDescription": "Hộp 1–8 · ghép, đoán, nhớ lại, điền",
+  "starterSuggested": "Gợi ý cho deck này · {description}",
+  "starterAddDeck": "Thêm deck",
+  "starterTryAgain": "Thử lại",
+  "starterAddFailedTitle": "Không thêm được deck.",
+  "starterAddFailedBody": "Chưa có gì được sao chép — hãy thử lại.",
+  "starterAdded": "Đã thêm “{title}” · {algorithm} · {count} thẻ mới",
+  "starterOpen": "Mở",
+  "starterAlreadyPresent": "Đã có trong thư viện — không sao chép gì",
+  "starterSecondCopyTitle": "Thêm bản thứ hai?",
+  "starterSecondCopyBody": "“{title}” đã có trong thư viện. Bản thứ hai là một deck riêng với tiến độ riêng.",
+  "starterSecondCopyConfirm": "Thêm bản thứ hai",
+  "starterNoneTitle": "Bản này không có deck mẫu",
+  "starterNoneBody": "Phiên bản này không kèm nội dung luyện tập. Hãy tạo deck hoặc nhập thẻ.",
+  "starterCreateDeck": "Tạo deck",
+  "starterLoadErrorTitle": "Không tải được deck mẫu",
+  "starterLoadErrorBody": "Thư viện của bạn không bị ảnh hưởng. Hãy thử lại sau giây lát."
 }
```

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index 1402b72..fd05007 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -64,6 +64,8 @@ abstract final class AppIcons {
       Icons.settings_backup_restore; // rotate-ccw
   static const IconData safe = Icons.verified_user_outlined; // shield-check
   static const IconData textScale = Icons.format_size;
+  // Development fixtures (screen 03, BR-STARTER-010).
+  static const IconData fixture = Icons.science_outlined; // flask-conical
 
   // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
   static const IconData starterDecks = Icons.auto_awesome_outlined; // sparkles
```

`lib/features/starter_decks/presentation/screens/starter_library_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/providers/starter_library_provider.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';
import 'package:memox/features/starter_decks/presentation/widgets/items/starter_template_card_widget.dart';
import 'package:memox/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart';
import 'package:memox/features/starter_decks/presentation/widgets/overlays/starter_repeat_add_dialog_widget.dart';
import 'package:memox/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 03, Starter decks (UC-STARTER-001): the templates bundled with the
/// app, each added as a deck of the person's own under the scheduler they
/// choose. [onOpenDeck] opens a new copy's root; [onCreateDeck] returns to
/// the Library's create dialog.
class StarterLibraryScreen extends ConsumerStatefulWidget {
  const StarterLibraryScreen({
    super.key,
    required this.onOpenDeck,
    required this.onCreateDeck,
  });

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onCreateDeck;

  @override
  ConsumerState<StarterLibraryScreen> createState() =>
      _StarterLibraryScreenState();
}

class _StarterLibraryScreenState extends ConsumerState<StarterLibraryScreen> {
  static const int _skeletonRows = 2;

  /// A copy already there asks first (A2); then the sheet adds, and the
  /// screen toasts what it did (FE-B4 spec D6).
  Future<void> _add(StarterLibraryEntry entry) async {
    if (entry.isInLibrary) {
      final isConfirmed = await showStarterRepeatAddDialog(
        context,
        title: entry.title,
      );
      if (!isConfirmed || !mounted) return;
    }
    final result = await showStarterAlgorithmSheet(
      context,
      entry: entry,
      isSecondCopy: entry.isInLibrary,
    );
    if (result == null || !mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case StarterAdded(:final deck):
        showMxSnackbar(
          context,
          message: l10n.starterAdded(
            deck.title,
            starterSchedulerName(l10n, deck.schedulerType),
            deck.cardCount,
          ),
          actionLabel: l10n.starterOpen,
          onAction: () => widget.onOpenDeck(deck.rootDeckId),
        );
      case StarterAlreadyPresent():
        showMxSnackbar(context, message: l10n.starterAlreadyPresent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library = ref.watch(starterLibraryProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.starterTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: switch (library) {
          AsyncData(:final value) when value.isEmpty => [
            MxEmptyState(
              icon: AppIcons.starterDecks,
              title: l10n.starterNoneTitle,
              body: l10n.starterNoneBody,
              actionLabel: l10n.starterCreateDeck,
              onAction: widget.onCreateDeck,
            ),
          ],
          AsyncData(:final value) => [
            const SizedBox(height: AppSpacing.control),
            MxNote(icon: AppIcons.fixture, text: l10n.starterNote),
            for (final entry in value) ...[
              const SizedBox(height: AppSpacing.grouped),
              StarterTemplateCardWidget(
                key: ValueKey(entry.templateId),
                entry: entry,
                onAdd: () => unawaited(_add(entry)),
              ),
            ],
          ],
          AsyncError() => [
            MxErrorState(
              title: l10n.starterLoadErrorTitle,
              body: l10n.starterLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(starterLibraryProvider),
            ),
          ],
          // The note is the screen's own copy: it shows while the templates
          // are read (kit 03 `loading`).
          _ => [
            const SizedBox(height: AppSpacing.control),
            MxNote(icon: AppIcons.fixture, text: l10n.starterNote),
            const SizedBox(height: AppSpacing.grouped),
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        },
      ),
    );
  }
}
```

`lib/features/starter_decks/presentation/widgets/items/starter_template_card_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// One template of screen 03: its title, "In library" once added, its
/// facts, the add and the scheduler it suggests (UC-STARTER-001 step 4).
class StarterTemplateCardWidget extends StatelessWidget {
  const StarterTemplateCardWidget({
    super.key,
    required this.entry,
    required this.onAdd,
  });

  final StarterLibraryEntry entry;
  final VoidCallback onAdd;

  static const double _tileGap = AppSpacing.grouped;

  /// The facts and the actions line up with the title, past the tile.
  static const double _indent = MxIconTile.mediumBox + _tileGap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // One node: the title, the badge and the facts.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                // The tile centres on the title, which wraps; the badge
                // follows it, or drops below when the line is full
                // (critique P3).
                Row(
                  spacing: _tileGap,
                  children: [
                    const MxIconTile(
                      icon: AppIcons.starterDecks,
                      size: MxIconTileSize.medium,
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.control,
                        runSpacing: AppSpacing.micro,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(entry.title, style: styles.contentTitle),
                          if (entry.isInLibrary)
                            MxBadge(
                              label: l10n.starterInLibrary,
                              tone: MxBadgeTone.neutral,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: _indent),
                  child: Text(
                    starterEntryFacts(l10n, entry),
                    style: styles.footerCaption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.grouped),
          // The suggestion drops below the button, whole, when both do not
          // fit on one line (critique P2a).
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _indent),
            child: Wrap(
              spacing: AppSpacing.grouped,
              runSpacing: AppSpacing.control,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MxButton(
                  label: entry.isInLibrary
                      ? l10n.starterAddAnotherCopy
                      : l10n.starterAddToLibrary,
                  icon: AppIcons.add,
                  size: MxButtonSize.small,
                  onPressed: onAdd,
                ),
                Text(
                  l10n.starterSuggests(
                    starterSchedulerName(l10n, entry.suggestedScheduler),
                  ),
                  style: styles.footerCaption,
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

`lib/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/controllers/starter_add_controller.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';
import 'package:memox/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// The scheduler a copy of [entry] studies under (UC-STARTER-001 step 6;
/// kit 03 `choose`). Completes with what the add did, or null when the
/// person cancelled.
Future<StarterAddResult?> showStarterAlgorithmSheet(
  BuildContext context, {
  required StarterLibraryEntry entry,
  required bool isSecondCopy,
}) => showMxBottomSheet<StarterAddResult>(
  context,
  builder: (_) =>
      StarterAlgorithmSheetWidget(entry: entry, isSecondCopy: isSecondCopy),
);

/// The two schedulers, the suggested one first chosen (BR-STARTER-004).
/// While the add runs nothing else can be touched (`adding`); a failure
/// keeps the sheet and the choice, and says so (`addFailed`).
class StarterAlgorithmSheetWidget extends ConsumerStatefulWidget {
  const StarterAlgorithmSheetWidget({
    super.key,
    required this.entry,
    required this.isSecondCopy,
  });

  final StarterLibraryEntry entry;

  /// The person confirmed a second copy (BR-STARTER-008).
  final bool isSecondCopy;

  @override
  ConsumerState<StarterAlgorithmSheetWidget> createState() =>
      _StarterAlgorithmSheetWidgetState();
}

class _StarterAlgorithmSheetWidgetState
    extends ConsumerState<StarterAlgorithmSheetWidget> {
  late var _scheduler = widget.entry.suggestedScheduler;

  Future<void> _add() async {
    final result = await ref
        .read(starterAddControllerProvider.notifier)
        .add(
          templateId: widget.entry.templateId,
          schedulerType: _scheduler,
          allowSecondCopy: widget.isSecondCopy,
        );
    if (result == null || !mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final state = ref.watch(starterAddControllerProvider);
    final isAdding = state.isAdding;
    const schedulers = [SchedulerType.sm2, SchedulerType.eightBox];
    return PopScope(
      canPop: !isAdding,
      child: MxBottomSheet(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.card,
            AppSpacing.micro,
            AppSpacing.card,
            AppSpacing.control,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.micro,
            children: [
              Text(
                l10n.starterSheetTitle(widget.entry.title),
                style: styles.compactTitle,
              ),
              Text(
                l10n.starterSheetBody(
                  widget.entry.cardCount,
                  widget.entry.subDeckCount,
                ),
                style: styles.footerCaption,
              ),
              const SizedBox(height: AppSpacing.control),
              Text(
                l10n.starterSheetOverline.toUpperCase(),
                style: styles.overline,
              ),
            ],
          ),
        ),
        footer: MxSheetActions(
          isInSheet: true,
          cancelLabel: l10n.commonCancel,
          onCancel: isAdding ? null : () => Navigator.of(context).pop(),
          confirmLabel: state.hasFailed
              ? l10n.starterTryAgain
              : l10n.starterAddDeck,
          confirmIcon: state.hasFailed ? null : AppIcons.add,
          isConfirmLoading: isAdding,
          onConfirm: () => unawaited(_add()),
        ),
        child: Column(
          children: [
            for (final (index, scheduler) in schedulers.indexed)
              MxOptionRow(
                title: starterSchedulerName(l10n, scheduler),
                description: _description(scheduler),
                isSelected: scheduler == _scheduler,
                onSelected: isAdding
                    ? null
                    : () => setState(() => _scheduler = scheduler),
                hasDivider: index < schedulers.length - 1,
              ),
            if (state.hasFailed)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.control,
                  AppSpacing.gutter,
                  AppSpacing.control,
                ),
                child: MxInlineBanner(
                  tone: MxBannerTone.danger,
                  title: l10n.starterAddFailedTitle,
                  message: l10n.starterAddFailedBody,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _description(SchedulerType scheduler) {
    final l10n = context.l10n;
    final description = starterSchedulerDescription(l10n, scheduler);
    if (scheduler != widget.entry.suggestedScheduler) return description;
    return l10n.starterSuggested(description);
  }
}
```

`lib/features/starter_decks/presentation/widgets/overlays/starter_repeat_add_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a second copy of [title] (BR-STARTER-008; kit 03
/// `secondCopy`). Completes true to go on to the algorithm sheet.
Future<bool> showStarterRepeatAddDialog(
  BuildContext context, {
  required String title,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return MxDialog(
          title: l10n.starterSecondCopyTitle,
          body: l10n.starterSecondCopyBody(title),
          actions: MxSheetActions(
            cancelLabel: l10n.commonCancel,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            confirmLabel: l10n.starterSecondCopyConfirm,
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    ) ??
    false;
```

`lib/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Between the facts of a template's line (kit 03).
const String starterFactSeparator = ' · ';

/// The script subtag every romanisation carries, such as `ko-Latn`.
const String _latinScript = '-Latn';

/// The name of a language tag the build ships (FE-B4 spec D7); any other
/// tag shows as written.
String starterLanguageName(AppLocalizations l10n, String tag) {
  if (tag.endsWith(_latinScript)) return l10n.starterLanguageLatin;
  return switch (tag) {
    'en' => l10n.starterLanguageEnglish,
    'vi' => l10n.starterLanguageVietnamese,
    'ko' => l10n.starterLanguageKorean,
    _ => tag,
  };
}

String starterSchedulerName(AppLocalizations l10n, SchedulerType type) =>
    switch (type) {
      SchedulerType.sm2 => l10n.starterSchedulerSm2,
      SchedulerType.eightBox => l10n.starterSchedulerEightBox,
    };

String starterSchedulerDescription(AppLocalizations l10n, SchedulerType type) =>
    switch (type) {
      SchedulerType.sm2 => l10n.starterSm2Description,
      SchedulerType.eightBox => l10n.starterEightBoxDescription,
    };

/// "{front} · {back} · {n} cards · {m} sub-decks · {source}" (kit 03).
String starterEntryFacts(AppLocalizations l10n, StarterLibraryEntry entry) => [
  starterLanguageName(l10n, entry.frontLanguage),
  starterLanguageName(l10n, entry.backLanguage),
  l10n.starterCardCount(entry.cardCount),
  l10n.starterSubDeckCount(entry.subDeckCount),
  entry.contentSource,
].join(starterFactSeparator);
```

`lib/shared/widgets/mx_icon_tile.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_icon_tile.dart b/lib/shared/widgets/mx_icon_tile.dart
index ba38d82..b21b51a 100644
--- a/lib/shared/widgets/mx_icon_tile.dart
+++ b/lib/shared/widgets/mx_icon_tile.dart
@@ -42,7 +42,9 @@ class MxIconTile extends StatelessWidget {
 
   /// The small step's side, for a caller that sizes the row around it.
   static const double smallBox = 28;
-  static const double _mediumBox = 36;
+
+  /// The medium step's side, for a caller that indents past it.
+  static const double mediumBox = 36;
   static const double _largeBox = 44;
   static const double _primaryTintLight = 0.10;
   static const double _primaryTintDark = 0.16;
@@ -59,7 +61,7 @@ class MxIconTile extends StatelessWidget {
     };
     final (box, radius, glyph) = switch (size) {
       MxIconTileSize.small => (smallBox, AppRadius.sm, AppIconSize.inline),
-      MxIconTileSize.medium => (_mediumBox, AppRadius.md, AppIconSize.compact),
+      MxIconTileSize.medium => (mediumBox, AppRadius.md, AppIconSize.compact),
       MxIconTileSize.large => (_largeBox, AppRadius.md, AppIconSize.compact),
     };
     final (fill, ink) = switch (tone) {
```

`lib/shared/widgets/mx_sheet_actions.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_sheet_actions.dart b/lib/shared/widgets/mx_sheet_actions.dart
index 491669a..2e0a8e0 100644
--- a/lib/shared/widgets/mx_sheet_actions.dart
+++ b/lib/shared/widgets/mx_sheet_actions.dart
@@ -13,7 +13,7 @@ class MxSheetActions extends StatelessWidget {
   const MxSheetActions({
     super.key,
     required String this.cancelLabel,
-    required VoidCallback this.onCancel,
+    required this.onCancel,
     required String this.confirmLabel,
     required this.onConfirm,
     this.confirmIcon,
@@ -41,6 +41,8 @@ class MxSheetActions extends StatelessWidget {
        isConfirmLoading = false;
 
   final String? cancelLabel;
+
+  /// Null disables Cancel, as while an add runs (screen 03 `adding`).
   final VoidCallback? onCancel;
   final String? confirmLabel;
 
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
TZ=UTC flutter test --tags golden --update-goldens test/features/starter_decks/presentation/starter_library_golden_test.dart
flutter test test/features/starter_decks test/shared/widgets/mx_sheet_actions_test.dart test/visual_audit test/app/l10n_test.dart
flutter analyze
```

Expected: PASS, 8 tests in `starter_library_screen_test.dart` and the audit in English and
Vietnamese. Twenty new goldens; compare each with
`docs/shared/ui/screen-handoff/img/03-starter-decks/` (the everyday template is in the
library, as the kit draws it):
- `starter_list_*` with `list-*`: the note, the two cards, "In library" after the
  everyday title, "Suggests …" whole under the add (UI-base row 135);
- `starter_choose_*`, `starter_adding_*` (the spinner alone, D13),
  `starter_add_failed_*` (the banner's lead, "Try again") with their frames;
- `starter_added_*` and `starter_already_present_*` with their toasts,
  `starter_second_copy_*` with the dialog;
- `starter_loading_*` (the note, then skeleton rows), `starter_none_*`,
  `starter_load_failed_*` ("Couldn't load starter decks").

- [ ] **Step 5: Commit**

```bash
git add \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/starter_decks/presentation/screens/starter_library_screen.dart \
  lib/features/starter_decks/presentation/widgets/items/starter_template_card_widget.dart \
  lib/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart \
  lib/features/starter_decks/presentation/widgets/overlays/starter_repeat_add_dialog_widget.dart \
  lib/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart \
  lib/shared/widgets/mx_icon_tile.dart \
  lib/shared/widgets/mx_sheet_actions.dart \
  test/features/starter_decks/presentation/starter_library_golden_test.dart \
  test/features/starter_decks/presentation/starter_library_screen_test.dart \
  test/shared/widgets/mx_sheet_actions_test.dart \
  test/support/starter_screen_fixtures.dart \
  test/visual_audit/screens/features/starter_decks/screens/starter_library_screen_visual_audit_test.dart \
  test/features/starter_decks/presentation/goldens/starter_add_failed_dark.png \
  test/features/starter_decks/presentation/goldens/starter_add_failed_light.png \
  test/features/starter_decks/presentation/goldens/starter_added_dark.png \
  test/features/starter_decks/presentation/goldens/starter_added_light.png \
  test/features/starter_decks/presentation/goldens/starter_adding_dark.png \
  test/features/starter_decks/presentation/goldens/starter_adding_light.png \
  test/features/starter_decks/presentation/goldens/starter_already_present_dark.png \
  test/features/starter_decks/presentation/goldens/starter_already_present_light.png \
  test/features/starter_decks/presentation/goldens/starter_choose_dark.png \
  test/features/starter_decks/presentation/goldens/starter_choose_light.png \
  test/features/starter_decks/presentation/goldens/starter_list_dark.png \
  test/features/starter_decks/presentation/goldens/starter_list_light.png \
  test/features/starter_decks/presentation/goldens/starter_load_failed_dark.png \
  test/features/starter_decks/presentation/goldens/starter_load_failed_light.png \
  test/features/starter_decks/presentation/goldens/starter_loading_dark.png \
  test/features/starter_decks/presentation/goldens/starter_loading_light.png \
  test/features/starter_decks/presentation/goldens/starter_none_dark.png \
  test/features/starter_decks/presentation/goldens/starter_none_light.png \
  test/features/starter_decks/presentation/goldens/starter_second_copy_dark.png \
  test/features/starter_decks/presentation/goldens/starter_second_copy_light.png
git commit -m "$(cat <<'EOF'
feat(starter): screen 03, Starter decks (FE-B4, UC-STARTER-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: The tag catalog and the tag writes (D4, D8)

**Files:**
- Create: `lib/features/tags/presentation/controllers/tag_actions_controller.dart`
- Create: `lib/features/tags/presentation/providers/delete_tag_use_case_provider.dart`
- Create: `lib/features/tags/presentation/providers/plan_tag_rename_use_case_provider.dart`
- Create: `lib/features/tags/presentation/providers/rename_tag_use_case_provider.dart`
- Create: `lib/features/tags/presentation/providers/tag_catalog_provider.dart`
- Create: `lib/features/tags/presentation/providers/watch_tag_catalog_use_case_provider.dart`
- Create: `lib/features/tags/presentation/states/tag_actions_state.dart`
- Test (create): `test/features/tags/presentation/tag_actions_controller_test.dart`
- Test (create): `test/support/tag_screen_fixtures.dart`

**Interfaces:**
- Consumes: BE-B2's `WatchTagCatalogUseCase`, `PlanTagRenameUseCase`,
  `RenameTagUseCase`, `DeleteTagUseCase` over `tagRepositoryProvider`; `TagCount`,
  `TagRenamePlan` (`TagRenameUnchanged`, `TagRenameRename`, `TagRenameMerge`),
  `TagRejection`.
- Produces:
  - `watchTagCatalogUseCaseProvider`, `planTagRenameUseCaseProvider`,
    `renameTagUseCaseProvider`, `deleteTagUseCaseProvider`;
  - `tagCatalogProvider` → `Stream<List<TagCount>>` (the whole library);
  - `enum TagWriteResult { done, gone, replan, failed }`;
  - `TagActionsState({Set<String> busyTagIds})` with `isBusy(tagId)`;
  - `tagActionsControllerProvider` (`TagActionsController`): `planRename({tagId,
    name})` → `Future<Outcome<TagRenamePlan, TagRejection>>`, `rename({tagId, name,
    mergeIntoTagId})` and `delete(tagId)` → `Future<TagWriteResult>`;
  - test support `kitTags`, `seedTags(env, [tags])`, and `TagRepositoryFake(env)` with
    `failsWrites`, `hold`, `failsReads`, `loaded` and `asOverride`.

- [ ] **Step 1: Write the failing tests**

Plain `test()`s over a `LibraryEnv`: Drift's streams need the real event loop.

`test/features/tags/presentation/tag_actions_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/presentation/controllers/tag_actions_controller.dart';
import 'package:memox/features/tags/presentation/states/tag_actions_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/tag_fixtures.dart';
import '../../../support/tag_screen_fixtures.dart';
import '../../../support/test_database.dart';

// FE-B2 spec D8: screen 05's writes, over the real tag store.

const _tags = [
  ('t-verb', 'động từ', 3),
  ('t-grammar', 'ngữ pháp', 2),
  ('t-tmp', 'tạm', 1),
];

void main() {
  late LibraryEnv env;
  late TagRepositoryFake store;
  late ProviderContainer container;

  setUp(() async {
    env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    await seedTags(env, _tags);
    store = TagRepositoryFake(env);
    container = libraryContainer(env, overrides: [store.asOverride]);
    container.listen(tagActionsControllerProvider, (_, _) {});
  });
  tearDown(() => env.db.close());

  TagActionsController tags() =>
      container.read(tagActionsControllerProvider.notifier);

  Future<TagRenamePlan> plan(String name) async =>
      switch (await tags().planRename(tagId: 't-verb', name: name)) {
        Ok(:final value) => value,
        Rejected(:final reason) => throw StateError('$reason'),
      };

  test('the plan says unchanged, rename, or merge with the union count '
      '(UC-TAG-001 A1, A2)', () async {
    expect(await plan('động từ'), isA<TagRenameUnchanged>());
    expect(await plan('Động từ'), isA<TagRenameRename>());
    expect(await plan('verb'), isA<TagRenameRename>());
    final merge = await plan('NGỮ PHÁP') as TagRenameMerge;
    expect(
      (merge.target.id, merge.target.name, merge.mergedCardCount),
      ('t-grammar', 'ngữ pháp', 5),
    );
  });

  test('a name that breaks a rule is a rejection of the plan (E2)', () async {
    final outcome = await tags().planRename(tagId: 't-verb', name: '  ');

    expect(outcome, isA<Rejected<TagRenamePlan, TagRejection>>());
  });

  test('rename keeps the id; merge folds into the confirmed target', () async {
    expect(
      await tags().rename(tagId: 't-verb', name: 'verb'),
      TagWriteResult.done,
    );
    expect((await tagRowsOf(env.db)).map((row) => row.$2), contains('verb'));

    expect(
      await tags().rename(
        tagId: 't-verb',
        name: 'ngữ pháp',
        mergeIntoTagId: 't-grammar',
      ),
      TagWriteResult.done,
    );
    expect((await tagRowsOf(env.db)).map((row) => row.$1), [
      't-grammar',
      't-tmp',
    ]);
  });

  test('a merge the person did not confirm plans again '
      '(mergeNotConfirmed)', () async {
    expect(
      await tags().rename(tagId: 't-verb', name: 'ngữ pháp'),
      TagWriteResult.replan,
    );
    expect(await tagRowsOf(env.db), hasLength(3));
  });

  test('delete removes the tag and keeps every card (A3)', () async {
    expect(await tags().delete('t-tmp'), TagWriteResult.done);

    expect((await tagRowsOf(env.db)).map((row) => row.$1), [
      't-grammar',
      't-verb',
    ]);
    final cards = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM card')
        .getSingle();
    expect(cards.read<int>('n'), 6);
  });

  test(
    'a tag deleted elsewhere is gone, for a rename and a delete (E3)',
    () async {
      await env.db.customStatement(
        "DELETE FROM card_tags WHERE tag_id = 't-tmp'",
      );
      await env.db.customStatement("DELETE FROM tags WHERE id = 't-tmp'");

      expect(await tags().delete('t-tmp'), TagWriteResult.gone);
      expect(
        await tags().rename(tagId: 't-tmp', name: 'x'),
        TagWriteResult.gone,
      );
    },
  );

  test('a failed write changes nothing and says so (E4, E5)', () async {
    store.failsWrites = true;

    expect(await tags().delete('t-tmp'), TagWriteResult.failed);
    expect(
      await tags().rename(tagId: 't-verb', name: 'verb'),
      TagWriteResult.failed,
    );
    expect(await tagRowsOf(env.db), hasLength(3));
    expect(container.read(tagActionsControllerProvider).busyTagIds, isEmpty);
  });

  test('the row is busy while its write runs, and only then', () async {
    store.hold = Completer<void>();
    final deleting = tags().delete('t-tmp');

    expect(
      container.read(tagActionsControllerProvider).isBusy('t-tmp'),
      isTrue,
    );
    expect(
      container.read(tagActionsControllerProvider).isBusy('t-verb'),
      isFalse,
    );

    store.hold!.complete();
    expect(await deleting, TagWriteResult.done);
    expect(
      container.read(tagActionsControllerProvider).isBusy('t-tmp'),
      isFalse,
    );
  });
}
```

`test/support/tag_screen_fixtures.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

import 'library_harness.dart';
import 'tag_fixtures.dart';

/// Kit 05's catalog: sixteen tags, each on as many cards as the kit counts,
/// no card carrying two of them. The long name is the kit's ellipsis case.
const List<(String, String, int)> kitTags = [
  ('t-bai', 'bài12', 12),
  ('t-cau', 'Cấu trúc thường gặp trong đề thi TOPIK II phần đọc', 3),
  ('t-can', 'cần ôn lại', 9),
  ('t-dong', 'động từ', 46),
  ('t-hay', 'hay nhầm', 14),
  ('t-hoc', 'Học', 5),
  ('t-lien', 'liên kết câu', 4),
  ('t-ngu', 'ngữ pháp', 31),
  ('t-nghe', 'nghe', 7),
  ('t-phat', 'phát âm', 6),
  ('t-quan', 'quan trọng', 11),
  ('t-so', 'sơ cấp', 20),
  ('t-tam', 'tạm', 2),
  ('t-topik', 'TOPIK I', 8),
  ('t-trung', 'trung cấp', 10),
  ('t-tu', 'từ vựng', 25),
];

/// [tags] on fresh cards of the `leaf` deck of [insertTagDecks].
Future<void> seedTags(
  LibraryEnv env, [
  List<(String, String, int)> tags = kitTags,
]) async {
  await insertTagDecks(env.db);
  var next = 0;
  for (final (id, name, count) in tags) {
    final cardIds = [for (var i = 0; i < count; i++) 'c${next + i}'];
    next += count;
    for (final cardId in cardIds) {
      await insertTagCard(env.db, cardId);
    }
    await insertTag(env.db, id, name, cardIds: cardIds);
  }
}

/// The tag store over [LibraryEnv]'s database, with the failures screen 05
/// must survive.
final class TagRepositoryFake implements TagRepository {
  TagRepositoryFake(LibraryEnv env) : _tags = TagRepositoryImpl(env.db);

  final TagRepositoryImpl _tags;

  /// The next rename or delete throws as a full disk does (`opError`).
  bool failsWrites = false;

  /// Holds every rename and delete until completed (`busy`).
  Completer<void>? hold;

  /// The catalog read fails (E1).
  bool failsReads = false;

  Override get asOverride => tagRepositoryProvider.overrideWithValue(this);

  Future<void> _before() async {
    await hold?.future;
    if (failsWrites) {
      throw UnknownDatabaseFailure(cause: StateError('disk full'));
    }
  }

  @override
  Stream<List<TagCount>> watchTagCounts({
    String? deckId,
    String searchTerm = '',
  }) => failsReads
      ? Stream.error(UnknownDatabaseFailure(cause: StateError('read failed')))
      : _tags.watchTagCounts(deckId: deckId, searchTerm: searchTerm);

  @override
  Future<Outcome<TagRenamePlan, TagRejection>> planRename({
    required String tagId,
    required String name,
  }) => _tags.planRename(tagId: tagId, name: name);

  @override
  Future<Outcome<void, TagRejection>> renameTag({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) async {
    await _before();
    return _tags.renameTag(
      tagId: tagId,
      name: name,
      mergeIntoTagId: mergeIntoTagId,
    );
  }

  @override
  Future<Outcome<void, TagRejection>> deleteTag({required String tagId}) async {
    await _before();
    return _tags.deleteTag(tagId: tagId);
  }

  @override
  Future<Outcome<void, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) => _tags.attachByName(cardIds: cardIds, name: name, now: now);

  @override
  Future<Outcome<void, TagRejection>> detach({
    required Set<String> cardIds,
    required String tagId,
  }) => _tags.detach(cardIds: cardIds, tagId: tagId);

  @override
  Future<Outcome<void, TagRejection>> replaceForCard({
    required String cardId,
    required List<String> names,
    DateTime? now,
  }) => _tags.replaceForCard(cardId: cardId, names: names, now: now);
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/tags/presentation/tag_actions_controller_test.dart
```

Expected: FAIL to compile: the controller does not exist.

- [ ] **Step 3: Implement**

`lib/features/tags/presentation/controllers/tag_actions_controller.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/presentation/providers/delete_tag_use_case_provider.dart';
import 'package:memox/features/tags/presentation/providers/plan_tag_rename_use_case_provider.dart';
import 'package:memox/features/tags/presentation/providers/rename_tag_use_case_provider.dart';
import 'package:memox/features/tags/presentation/states/tag_actions_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_actions_controller.g.dart';

/// Screen 05's writes (UC-TAG-001 steps 4-5, A1, A3): the rename plan, the
/// rename or merge, the delete, and the rows they keep busy.
@riverpod
class TagActionsController extends _$TagActionsController {
  @override
  TagActionsState build() => const TagActionsState();

  /// What renaming [tagId] to [name] would do (FE-B2 spec D8). A database
  /// `Failure` is thrown through; the dialog keeps its last plan.
  Future<Outcome<TagRenamePlan, TagRejection>> planRename({
    required String tagId,
    required String name,
  }) => ref.read(planTagRenameUseCaseProvider)(tagId: tagId, name: name);

  /// Renames [tagId], or merges it into [mergeIntoTagId], the target the
  /// person confirmed (BR-TAG-006, BR-TAG-007).
  Future<TagWriteResult> rename({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) => _write(
    tagId,
    () => ref.read(renameTagUseCaseProvider)(
      tagId: tagId,
      name: name,
      mergeIntoTagId: mergeIntoTagId,
    ),
  );

  /// Deletes [tagId] and its links; no card is touched (BR-TAG-008).
  Future<TagWriteResult> delete(String tagId) =>
      _write(tagId, () => ref.read(deleteTagUseCaseProvider)(tagId: tagId));

  Future<TagWriteResult> _write(
    String tagId,
    Future<Outcome<void, TagRejection>> Function() write,
  ) async {
    state = TagActionsState(busyTagIds: {...state.busyTagIds, tagId});
    try {
      return switch (await write()) {
        Ok() => TagWriteResult.done,
        Rejected(reason: TagRejection.notFound) => TagWriteResult.gone,
        Rejected() => TagWriteResult.replan,
      };
    } on Failure {
      return TagWriteResult.failed;
    } finally {
      if (ref.mounted) {
        state = TagActionsState(
          busyTagIds: {...state.busyTagIds}..remove(tagId),
        );
      }
    }
  }
}
```

`lib/features/tags/presentation/providers/delete_tag_use_case_provider.dart`:

```dart
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/delete_tag_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_tag_use_case_provider.g.dart';

@riverpod
DeleteTagUseCase deleteTagUseCase(Ref ref) =>
    DeleteTagUseCase(ref.watch(tagRepositoryProvider));
```

`lib/features/tags/presentation/providers/plan_tag_rename_use_case_provider.dart`:

```dart
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/plan_tag_rename_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_tag_rename_use_case_provider.g.dart';

@riverpod
PlanTagRenameUseCase planTagRenameUseCase(Ref ref) =>
    PlanTagRenameUseCase(ref.watch(tagRepositoryProvider));
```

`lib/features/tags/presentation/providers/rename_tag_use_case_provider.dart`:

```dart
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/rename_tag_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rename_tag_use_case_provider.g.dart';

@riverpod
RenameTagUseCase renameTagUseCase(Ref ref) =>
    RenameTagUseCase(ref.watch(tagRepositoryProvider));
```

`lib/features/tags/presentation/providers/tag_catalog_provider.dart`:

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/presentation/providers/watch_tag_catalog_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_catalog_provider.g.dart';

/// Every tag of the library with its active cards, by folded name
/// (UC-TAG-001 steps 1-2). Screen 05 narrows it as the search is typed.
@riverpod
Stream<List<TagCount>> tagCatalog(Ref ref) =>
    ref.watch(watchTagCatalogUseCaseProvider)();
```

`lib/features/tags/presentation/providers/watch_tag_catalog_use_case_provider.dart`:

```dart
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/watch_tag_catalog_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_tag_catalog_use_case_provider.g.dart';

@riverpod
WatchTagCatalogUseCase watchTagCatalogUseCase(Ref ref) =>
    WatchTagCatalogUseCase(ref.watch(tagRepositoryProvider));
```

`lib/features/tags/presentation/states/tag_actions_state.dart`:

```dart
import 'package:flutter/foundation.dart';

/// How a tag write ended, as screen 05 tells it (FE-B2 spec D8, §6).
enum TagWriteResult {
  /// Written; the catalog updates itself.
  done,

  /// The tag was deleted elsewhere in the meantime (`tagGone`, E3).
  gone,

  /// The name no longer plans the same way: a merge target appeared or
  /// went, or the name breaks a rule. The rename dialog opens again.
  replan,

  /// The database refused; nothing changed (`opError`, E4, E5).
  failed,
}

/// The tags whose write is running: their rows spin instead of ⋮ (`busy`).
@immutable
final class TagActionsState {
  const TagActionsState({this.busyTagIds = const {}});

  final Set<String> busyTagIds;

  bool isBusy(String tagId) => busyTagIds.contains(tagId);
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/tags
flutter analyze
```

Expected: PASS, 8 tests in `tag_actions_controller_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/tags/presentation/controllers/tag_actions_controller.dart \
  lib/features/tags/presentation/providers/delete_tag_use_case_provider.dart \
  lib/features/tags/presentation/providers/plan_tag_rename_use_case_provider.dart \
  lib/features/tags/presentation/providers/rename_tag_use_case_provider.dart \
  lib/features/tags/presentation/providers/tag_catalog_provider.dart \
  lib/features/tags/presentation/providers/watch_tag_catalog_use_case_provider.dart \
  lib/features/tags/presentation/states/tag_actions_state.dart \
  test/features/tags/presentation/tag_actions_controller_test.dart \
  test/support/tag_screen_fixtures.dart
git commit -m "$(cat <<'EOF'
feat(tags): the tag catalog and the tag writes (FE-B2 D4, D8)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: Screen 05, Tags (UC-TAG-001)

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/features/tags/domain/models/tag_count_model.dart`
- Create: `lib/features/tags/presentation/screens/tags_screen.dart`
- Create: `lib/features/tags/presentation/widgets/items/tag_row_widget.dart`
- Create: `lib/features/tags/presentation/widgets/overlays/tag_actions_sheet_widget.dart`
- Create: `lib/features/tags/presentation/widgets/overlays/tag_delete_dialog_widget.dart`
- Create: `lib/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart`
- Create: `lib/features/tags/presentation/widgets/support/tag_labels_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/tags/presentation/goldens/tags_busy_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_busy_light.png`
- Create: `test/features/tags/presentation/goldens/tags_del_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_del_light.png`
- Create: `test/features/tags/presentation/goldens/tags_empty_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_empty_light.png`
- Create: `test/features/tags/presentation/goldens/tags_loaded_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_loaded_light.png`
- Create: `test/features/tags/presentation/goldens/tags_loading_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_loading_light.png`
- Create: `test/features/tags/presentation/goldens/tags_name_too_long_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_name_too_long_light.png`
- Create: `test/features/tags/presentation/goldens/tags_op_error_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_op_error_light.png`
- Create: `test/features/tags/presentation/goldens/tags_read_error_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_read_error_light.png`
- Create: `test/features/tags/presentation/goldens/tags_rename_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_rename_light.png`
- Create: `test/features/tags/presentation/goldens/tags_rename_merge_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_rename_merge_light.png`
- Create: `test/features/tags/presentation/goldens/tags_search_empty_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_search_empty_light.png`
- Create: `test/features/tags/presentation/goldens/tags_sheet_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_sheet_light.png`
- Create: `test/features/tags/presentation/goldens/tags_tag_gone_dark.png`
- Create: `test/features/tags/presentation/goldens/tags_tag_gone_light.png`
- Test (create): `test/features/tags/domain/tag_counts_matching_test.dart`
- Test (create): `test/features/tags/presentation/tags_golden_test.dart`
- Test (create): `test/features/tags/presentation/tags_screen_test.dart`
- Test (modify): `test/support/tag_screen_fixtures.dart`
- Test (create): `test/visual_audit/screens/features/tags/screens/tags_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 3's providers, controller, state and fixtures; Task 1's warning tone.
- Produces:
  - `List<TagCount>.matching(String term)` (`TagCountsMatching`, tags domain model);
  - `TagsScreen({required ValueChanged<String> onFindCards})`;
  - `showTagActionsSheet` → `Future<TagAction?>` (`findCards`, `rename`, `delete`);
  - `showTagRenameDialog(context, {required TagCount tag, String? name})` →
    `Future<TagRenameRequest?>`, where `TagRenameRequest = ({String name, String?
    mergeIntoTagId})`; `tagRenameSettle` (250 ms);
  - `showTagDeleteDialog` → `Future<bool>`; `TagRowWidget`; `tagWithCount`;
  - `AppIcons.merge`; the `tags…` ARB keys.

- [ ] **Step 1: Write the failing tests**

`test/features/tags/domain/tag_counts_matching_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

// BR-TAG-003: the catalog's search, on a list already read.

const _tags = [
  TagCount(id: 'a', name: 'động từ', cardCount: 3),
  TagCount(id: 'b', name: 'Học', cardCount: 1),
  TagCount(id: 'c', name: 'ngữ pháp', cardCount: 2),
];

void main() {
  test('a term keeps the tags whose folded name holds its fold, in order', () {
    expect(_tags.matching('ĐỘNG').map((tag) => tag.id), ['a']);
    expect(_tags.matching(' học ').map((tag) => tag.id), ['b']);
    expect(_tags.matching('p').map((tag) => tag.id), ['c']);
  });

  test('accents matter, as the store folds only case', () {
    expect(_tags.matching('hoc'), isEmpty);
  });

  test('a blank term keeps every tag', () {
    expect(_tags.matching('  '), _tags);
  });
}
```

`test/features/tags/presentation/tags_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/tag_screen_fixtures.dart';

// Screen 05 (FE-B2) against the kit's twelve frames, plus the read error
// the kit does not draw (D10). The catalog is kit 05's sixteen tags, in
// the store's folded order (BR-TAG-003).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name, {
      bool isSeeded = true,
      void Function(TagRepositoryFake store)? arrange,
      Future<void> Function(TagRepositoryFake store)? before,
    }) async {
      if (isSeeded) await seedTags(env);
      final store = TagRepositoryFake(env);
      arrange?.call(store);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          TagsScreen(onFindCards: (_) {}),
          brightness,
          overrides: [store.asOverride],
        );
        await before?.call(store);
        await expectBoundaryGolden(tester, 'goldens/tags_${name}_$theme.png');
      });
    }

    Future<void> openActions(WidgetTester tester, String tag) async {
      await tester.tap(find.byTooltip(_en.tagsRowActions(tag)));
      await tester.pumpAndSettle();
    }

    Future<void> openRename(WidgetTester tester, String name) async {
      await openActions(tester, 'hay nhầm');
      await tester.tap(find.text(_en.tagsRename));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, name);
      await tester.pump(tagRenameSettle);
      await tester.pumpAndSettle();
    }

    Future<void> openDelete(WidgetTester tester) async {
      await openActions(tester, 'hay nhầm');
      await tester.tap(find.text(_en.tagsDelete));
      await tester.pumpAndSettle();
    }

    libraryTest('tags, loaded, $theme', (tester, env) async {
      await shoot(tester, env, 'loaded');
    });

    libraryTest('tags, loading, $theme', (tester, env) async {
      final loaded = Completer<void>();
      await shoot(
        tester,
        env,
        'loading',
        arrange: (store) => store.loaded = loaded.future,
      );
      loaded.complete();
    });

    libraryTest('tags, empty, $theme', (tester, env) async {
      await shoot(tester, env, 'empty', isSeeded: false);
    });

    libraryTest('tags, searchEmpty, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'search_empty',
        before: (_) async {
          await tester.enterText(find.byType(TextField), 'phras');
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('tags, sheet, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'sheet',
        before: (_) => openActions(tester, 'hay nhầm'),
      );
    });

    libraryTest('tags, rename, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'rename',
        before: (_) => openRename(tester, 'humans'),
      );
    });

    libraryTest('tags, renameMerge, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'rename_merge',
        before: (_) => openRename(tester, 'ngữ pháp'),
      );
    });

    libraryTest('tags, nameTooLong, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'name_too_long',
        before: (_) => openRename(
          tester,
          'Động từ bất quy tắc thường gặp trong đề thi TOPIK II phần đọc',
        ),
      );
    });

    libraryTest('tags, del, $theme', (tester, env) async {
      await shoot(tester, env, 'del', before: (_) => openDelete(tester));
    });

    libraryTest('tags, busy, $theme', (tester, env) async {
      late TagRepositoryFake held;
      await shoot(
        tester,
        env,
        'busy',
        before: (store) async {
          held = store..hold = Completer<void>();
          await openDelete(tester);
          await tester.tap(find.text(_en.tagsDeleteConfirm(14)));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
      held.hold!.complete();
      await tester.pumpAndSettle();
    });

    libraryTest('tags, opError, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'op_error',
        before: (store) async {
          store.failsWrites = true;
          await openRename(tester, 'humans');
          await tester.tap(find.text(_en.tagsRenameConfirm));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('tags, tagGone, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'tag_gone',
        before: (_) async {
          await openDelete(tester);
          await env.db.customStatement(
            "DELETE FROM card_tags WHERE tag_id = 't-hay'",
          );
          await env.db.customStatement("DELETE FROM tags WHERE id = 't-hay'");
          await tester.tap(find.text(_en.tagsDeleteConfirm(14)));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('tags, read error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'read_error',
        arrange: (store) => store.failsReads = true,
        before: (_) => tester.pumpAndSettle(),
      );
    });
  }
}
```

`test/features/tags/presentation/tags_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/tag_fixtures.dart';
import '../../../support/tag_screen_fixtures.dart';

// Screen 05 (FE-B2, UC-TAG-001): the twelve kit states and the read error.

final _en = lookupAppLocalizations(const Locale('en'));

Future<TagRepositoryFake> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  bool isSeeded = true,
  ValueChanged<String>? onFindCards,
  void Function(TagRepositoryFake store)? arrange,
}) async {
  if (isSeeded) await seedTags(env);
  final store = TagRepositoryFake(env);
  arrange?.call(store);
  await pumpLibraryScreen(
    tester,
    env,
    TagsScreen(onFindCards: onFindCards ?? (_) {}),
    overrides: [store.asOverride],
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _actions(WidgetTester tester, String tag) async {
  await tester.ensureVisible(find.byTooltip(_en.tagsRowActions(tag)));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(_en.tagsRowActions(tag)));
  await tester.pumpAndSettle();
}

Future<void> _openRename(WidgetTester tester, String tag) async {
  await _actions(tester, tag);
  await tester.tap(find.text(_en.tagsRename));
  await tester.pumpAndSettle();
}

/// Types [name] into the rename field and lets its plan settle.
Future<void> _type(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).last, name);
  await tester.pump(tagRenameSettle);
  await tester.pumpAndSettle();
}

MxButton _confirm(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  libraryTest('loaded: every tag with its cards, by folded name; the header '
      'counts them and A→Z is not a control', (tester, env) async {
    await _pump(tester, env);

    expect(find.text(_en.tagsCount(16).toUpperCase()), findsOneWidget);
    expect(find.text(_en.tagsOrder), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.tagsOrder), findsNothing);
    expect(find.text('bài12'), findsOneWidget);
    expect(find.text(_en.tagsCardCount(46)), findsOneWidget);
  });

  libraryTest('search uses the catalog\'s fold: ĐỘNG TỪ finds động từ '
      '(BR-TAG-003)', (tester, env) async {
    await _pump(tester, env);
    await tester.enterText(find.byType(TextField), 'ĐỘNG TỪ');
    await tester.pump();

    expect(find.text(_en.tagsCount(1).toUpperCase()), findsOneWidget);
    expect(find.byType(MxListRow), findsOneWidget);
    expect(find.text('động từ'), findsOneWidget);
  });

  libraryTest('searchEmpty: no tag matches, which is not "no tags" (A6)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);
    await tester.enterText(find.byType(TextField), 'phras');
    await tester.pump();

    expect(find.text(_en.tagsNoMatches.toUpperCase()), findsOneWidget);
    expect(find.text(_en.tagsSearchEmptyTitle('phras')), findsOneWidget);
    expect(find.text(_en.tagsEmptyTitle), findsNothing);
  });

  libraryTest('empty: a library without tags says where they come from', (
    tester,
    env,
  ) async {
    await _pump(tester, env, isSeeded: false);

    expect(find.text(_en.tagsNone.toUpperCase()), findsOneWidget);
    expect(find.text(_en.tagsEmptyTitle), findsOneWidget);
    expect(find.text(_en.tagsGoToLibrary), findsOneWidget);
  });

  libraryTest('a failed read shows the error with Retry (E1, D10)', (
    tester,
    env,
  ) async {
    await _pump(tester, env, arrange: (store) => store.failsReads = true);

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.tagsLoadErrorTitle), findsOneWidget);
    expect(find.textContaining('read failed'), findsNothing);
  });

  libraryTest('sheet: the tag with its count and three commands; Find cards '
      'hands over the name (D11)', (tester, env) async {
    String? found;
    await _pump(tester, env, onFindCards: (name) => found = name);
    await _actions(tester, 'động từ');

    expect(find.text('động từ · 46'), findsOneWidget);
    expect(find.text(_en.tagsFindCardsHint('động từ')), findsOneWidget);
    expect(find.text(_en.tagsDeleteHint(46)), findsOneWidget);
    await tester.tap(find.text(_en.tagsFindCards));
    await tester.pumpAndSettle();
    expect(found, 'động từ');
  });

  libraryTest('rename: prefilled, nothing to write until the name changes; a '
      'new name renames in place (step 5)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    expect(find.text(_en.tagsRenameBody('động từ')), findsOneWidget);
    expect(find.text(_en.tagsCaseHint), findsOneWidget);
    expect(_confirm(tester, _en.tagsRenameConfirm).onPressed, isNull);

    await _type(tester, 'verb');
    await tester.tap(find.text(_en.tagsRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.text('verb'), findsOneWidget);
    expect(find.text('động từ'), findsNothing);
    expect((await tagRowsOf(env.db)).map((row) => row.$1), contains('t-dong'));
  });

  libraryTest('renameMerge: the merge is told before it is confirmed, with '
      'the union count, and confirmed in the warning tone (A1)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');
    await _type(tester, 'NGỮ PHÁP');

    expect(
      find.text(_en.tagsMergeNotice('ngữ pháp', 'động từ')),
      findsOneWidget,
    );
    expect(find.text('động từ · 46'), findsOneWidget);
    expect(find.text('ngữ pháp · 77'), findsOneWidget);
    expect(find.text(_en.tagsLengthUnique(8, 50)), findsOneWidget);
    expect(_confirm(tester, _en.tagsMergeConfirm).tone, MxButtonTone.warning);

    await tester.tap(find.text(_en.tagsMergeConfirm));
    await tester.pumpAndSettle();

    expect(await tagRowsOf(env.db), hasLength(15));
    expect(find.text(_en.tagsCardCount(77)), findsOneWidget);
    expect(find.text('động từ'), findsNothing);
  });

  libraryTest('nameTooLong: the counter and the field say so, and Rename is '
      'off; a blank name has its own message (E2)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');
    await _type(
      tester,
      'Động từ bất quy tắc thường gặp trong đề thi TOPIK II phần đọc',
    );

    expect(find.text(_en.tagsLength(61, 50)), findsOneWidget);
    expect(find.text(_en.tagsNameTooLong(50)), findsOneWidget);
    expect(_confirm(tester, _en.tagsRenameConfirm).onPressed, isNull);

    await _type(tester, '   ');
    expect(find.text(_en.tagRejectionBlankName), findsOneWidget);
    expect(_confirm(tester, _en.tagsRenameConfirm).onPressed, isNull);
  });

  libraryTest('a merge that appeared after the plan opens the dialog again '
      'on the name typed (mergeNotConfirmed)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'tạm');
    await _type(tester, 'verbs');
    await insertTag(env.db, 't-verbs', 'Verbs', cardIds: ['c0']);
    await tester.tap(find.text(_en.tagsRenameConfirm));
    await tester.pumpAndSettle();
    await tester.pump(tagRenameSettle);
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsMergeNotice('Verbs', 'tạm')), findsOneWidget);
    expect(find.text('tạm'), findsWidgets);
  });

  libraryTest('del: the dialog says no card is deleted; the tag goes and '
      'every card stays (A3)', (tester, env) async {
    await _pump(tester, env);
    await _actions(tester, 'động từ');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsDeleteBody('động từ', 46)), findsOneWidget);
    expect(find.text(_en.tagsDeleteSafe(46)), findsOneWidget);
    expect(
      _confirm(tester, _en.tagsDeleteConfirm(46)).tone,
      MxButtonTone.destructive,
    );
    await tester.tap(find.text(_en.tagsDeleteConfirm(46)));
    await tester.pumpAndSettle();

    expect(find.text('động từ'), findsNothing);
    final cards = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM card')
        .getSingle();
    expect(cards.read<int>('n'), 213);
  });

  libraryTest('busy: the row spins instead of ⋮ while its write runs', (
    tester,
    env,
  ) async {
    final store = await _pump(tester, env);
    store.hold = Completer<void>();
    await _actions(tester, 'tạm');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.tagsDeleteConfirm(2)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.byTooltip(_en.tagsRowActions('tạm')), findsNothing);

    store.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MxSpinner), findsNothing);
    expect(find.text('tạm'), findsNothing);
  });

  libraryTest('opError: a failed delete changes nothing and offers Retry, '
      'which deletes (E5)', (tester, env) async {
    final store = await _pump(tester, env);
    store.failsWrites = true;
    await _actions(tester, 'tạm');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.tagsDeleteConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsDeleteFailed), findsOneWidget);
    expect(find.text('tạm'), findsOneWidget);

    store.failsWrites = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text('tạm'), findsNothing);
  });

  libraryTest('tagGone: a tag deleted elsewhere says so and writes nothing '
      '(E3)', (tester, env) async {
    await _pump(tester, env);
    await _actions(tester, 'tạm');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();
    await env.db.customStatement(
      "DELETE FROM card_tags WHERE tag_id = 't-tam'",
    );
    await env.db.customStatement("DELETE FROM tags WHERE id = 't-tam'");
    await tester.tap(find.text(_en.tagsDeleteConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsGone('tạm')), findsOneWidget);
  });
}
```

`test/support/tag_screen_fixtures.dart` (apply this diff):

```diff
diff --git a/test/support/tag_screen_fixtures.dart b/test/support/tag_screen_fixtures.dart
index 4fb0751..4e38217 100644
--- a/test/support/tag_screen_fixtures.dart
+++ b/test/support/tag_screen_fixtures.dart
@@ -67,6 +67,9 @@ final class TagRepositoryFake implements TagRepository {
   /// The catalog read fails (E1).
   bool failsReads = false;
 
+  /// Reads wait for this before they emit (`loading`).
+  Future<void>? loaded;
+
   Override get asOverride => tagRepositoryProvider.overrideWithValue(this);
 
   Future<void> _before() async {
@@ -80,9 +83,13 @@ final class TagRepositoryFake implements TagRepository {
   Stream<List<TagCount>> watchTagCounts({
     String? deckId,
     String searchTerm = '',
-  }) => failsReads
-      ? Stream.error(UnknownDatabaseFailure(cause: StateError('read failed')))
-      : _tags.watchTagCounts(deckId: deckId, searchTerm: searchTerm);
+  }) async* {
+    await loaded;
+    if (failsReads) {
+      throw UnknownDatabaseFailure(cause: StateError('read failed'));
+    }
+    yield* _tags.watchTagCounts(deckId: deckId, searchTerm: searchTerm);
+  }
 
   @override
   Future<Outcome<TagRenamePlan, TagRejection>> planRename({
```

`test/visual_audit/screens/features/tags/screens/tags_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/tag_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 05, ${locale.languageCode}', (tester, env) async {
      // Kit 05's catalog, with its name longer than a row.
      await seedTags(env);
      final store = TagRepositoryFake(env);
      await auditProductionScreen(
        tester,
        screen: TagsScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TagsScreen(onFindCards: (_) {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: [store.asOverride],
        ),
      );
    });
  }
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/tags
```

Expected: FAIL to compile: `matching` and `tags_screen.dart` do not exist.

- [ ] **Step 3: Implement**

The copy: apply the ARB diffs, then the code.

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 3c98996..542a6a0 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -5597,5 +5597,248 @@
   "starterLoadErrorBody": "Your library is unaffected. Try again in a moment.",
   "@starterLoadErrorBody": {
     "description": "Screen 03: the read error body (loadFailed)."
+  },
+  "tagsTitle": "Tags",
+  "@tagsTitle": {
+    "description": "Screen 05: the app bar title."
+  },
+  "tagsSearchHint": "Search tags",
+  "@tagsSearchHint": {
+    "description": "Screen 05: the search field hint."
+  },
+  "tagsSearchClear": "Clear search",
+  "@tagsSearchClear": {
+    "description": "Screen 05: the search field's clear button label."
+  },
+  "tagsCount": "{count, plural, =1{1 tag} other{{count} tags}}",
+  "@tagsCount": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05: the header over the tags shown."
+  },
+  "tagsNone": "No tags",
+  "@tagsNone": {
+    "description": "Screen 05: the header when the library has no tag."
+  },
+  "tagsNoMatches": "No matches",
+  "@tagsNoMatches": {
+    "description": "Screen 05: the header when the search finds no tag."
+  },
+  "tagsOrder": "A→Z",
+  "@tagsOrder": {
+    "description": "Screen 05: the one order of the catalog (BR-TAG-003); static text, not a control."
+  },
+  "tagsCardCount": "{count, plural, =0{No cards} =1{1 card} other{{count} cards}}",
+  "@tagsCardCount": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05: the active cards carrying a tag."
+  },
+  "tagsRowActions": "Actions for {tag}",
+  "@tagsRowActions": {
+    "placeholders": {
+      "tag": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 05: a row's more button, for TalkBack."
+  },
+  "tagsEmptyTitle": "No tags yet",
+  "@tagsEmptyTitle": {
+    "description": "Screen 05: the empty catalog title."
+  },
+  "tagsEmptyBody": "Tags appear here as you add them when creating or editing flashcards.",
+  "@tagsEmptyBody": {
+    "description": "Screen 05: the empty catalog body."
+  },
+  "tagsGoToLibrary": "Go to library",
+  "@tagsGoToLibrary": {
+    "description": "Screen 05: the empty catalog action; back to the Library."
+  },
+  "tagsSearchEmptyTitle": "No tags match “{term}”",
+  "@tagsSearchEmptyTitle": {
+    "placeholders": {
+      "term": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 05: the search finds no tag (UC-TAG-001 A6)."
+  },
+  "tagsSearchEmptyBody": "Try a different spelling. Tag search is case-insensitive.",
+  "@tagsSearchEmptyBody": {
+    "description": "Screen 05: the search empty body."
+  },
+  "tagsLoadErrorTitle": "Couldn't load tags",
+  "@tagsLoadErrorTitle": {
+    "description": "Screen 05: the catalog read error (UC-TAG-001 E1)."
+  },
+  "tagsActionsCaption": "Tag actions",
+  "@tagsActionsCaption": {
+    "description": "Screen 05 action sheet: the caption under the tag."
+  },
+  "tagsFindCards": "Find cards with this tag",
+  "@tagsFindCards": {
+    "description": "Screen 05 action sheet: opens the Library search with the tag."
+  },
+  "tagsFindCardsHint": "Search the library for “{tag}”",
+  "@tagsFindCardsHint": {
+    "placeholders": {
+      "tag": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 05 action sheet: what Find cards does."
+  },
+  "tagsRename": "Rename tag",
+  "@tagsRename": {
+    "description": "Screen 05: the rename action and the rename dialog title."
+  },
+  "tagsRenameHint": "Renaming onto an existing name merges the two",
+  "@tagsRenameHint": {
+    "description": "Screen 05 action sheet: what a rename may do (A1)."
+  },
+  "tagsDelete": "Delete tag",
+  "@tagsDelete": {
+    "description": "Screen 05 action sheet: the delete action."
+  },
+  "tagsDeleteHint": "{count, plural, =0{Removes it from the catalog} =1{Removes it from 1 card · the card stays} other{Removes it from {count} cards · the cards stay}}",
+  "@tagsDeleteHint": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 action sheet: what a delete does (BR-TAG-008)."
+  },
+  "tagsRenameBody": "Renaming updates every card that uses “{tag}”.",
+  "@tagsRenameBody": {
+    "placeholders": {
+      "tag": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 05 rename dialog: the body."
+  },
+  "tagsNewName": "New name",
+  "@tagsNewName": {
+    "description": "Screen 05 rename dialog: the field's overline."
+  },
+  "tagsCaseHint": "Tag names are case-insensitive.",
+  "@tagsCaseHint": {
+    "description": "Screen 05 rename dialog: the hint under the field."
+  },
+  "tagsLength": "{length} / {max}",
+  "@tagsLength": {
+    "placeholders": {
+      "length": {
+        "type": "int"
+      },
+      "max": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 rename dialog: the name's length against the limit."
+  },
+  "tagsLengthUnique": "{length} / {max} · names are unique regardless of letter case.",
+  "@tagsLengthUnique": {
+    "placeholders": {
+      "length": {
+        "type": "int"
+      },
+      "max": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 rename dialog: the count line of a merge."
+  },
+  "tagsNameTooLong": "A tag name can be at most {max} characters.",
+  "@tagsNameTooLong": {
+    "placeholders": {
+      "max": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 rename dialog: the name is too long (E2)."
+  },
+  "tagsRenameConfirm": "Rename",
+  "@tagsRenameConfirm": {
+    "description": "Screen 05 rename dialog: renames the tag."
+  },
+  "tagsMergeConfirm": "Merge tags",
+  "@tagsMergeConfirm": {
+    "description": "Screen 05 rename dialog: merges into the tag that folds alike (A1)."
+  },
+  "tagsMergeNotice": "A tag called “{target}” already exists. Continuing will merge “{source}” into it — its spelling stays “{target}”.",
+  "@tagsMergeNotice": {
+    "placeholders": {
+      "target": {
+        "type": "String"
+      },
+      "source": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 05 rename dialog: the merge panel (A1, BR-TAG-007)."
+  },
+  "tagsMergeSafe": "No card is deleted. Cards carrying both keep one tag; no card goes over 10 tags.",
+  "@tagsMergeSafe": {
+    "description": "Screen 05 rename dialog: what a merge leaves (BR-TAG-002)."
+  },
+  "tagsDeleteTitle": "Delete this tag?",
+  "@tagsDeleteTitle": {
+    "description": "Screen 05 delete dialog: the title."
+  },
+  "tagsDeleteBody": "“{tag}” is removed from {count, plural, =0{the catalog} =1{1 card and disappears from the catalog} other{{count} cards and disappears from the catalog}}. Tags are not kept in Trash.",
+  "@tagsDeleteBody": {
+    "placeholders": {
+      "tag": {
+        "type": "String"
+      },
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 delete dialog: the body (A3)."
+  },
+  "tagsDeleteSafe": "{count, plural, =0{No card is deleted, hidden or changed.} =1{No card is deleted, hidden or changed — the card stays exactly where it is.} other{No card is deleted, hidden or changed — all {count} cards stay exactly where they are.}}",
+  "@tagsDeleteSafe": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 delete dialog: the note that no card is touched (BR-TAG-008)."
+  },
+  "tagsDeleteConfirm": "{count, plural, =0{Delete tag} =1{Remove from 1 card} other{Remove from {count} cards}}",
+  "@tagsDeleteConfirm": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 05 delete dialog: the destructive confirm."
+  },
+  "tagsRenameFailed": "Couldn't rename tag. Nothing changed — try again in a moment.",
+  "@tagsRenameFailed": {
+    "description": "Screen 05: the toast of a failed rename or merge (opError, E4)."
+  },
+  "tagsDeleteFailed": "Couldn't delete tag. Nothing changed — try again in a moment.",
+  "@tagsDeleteFailed": {
+    "description": "Screen 05: the toast of a failed delete (opError, E5)."
+  },
+  "tagsGone": "“{tag}” no longer exists — it was removed a moment ago.",
+  "@tagsGone": {
+    "placeholders": {
+      "tag": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 05: the toast when the tag was deleted elsewhere (tagGone, E3)."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index f5977f2..1bb1cbf 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -1055,5 +1055,44 @@
   "starterNoneBody": "Phiên bản này không kèm nội dung luyện tập. Hãy tạo deck hoặc nhập thẻ.",
   "starterCreateDeck": "Tạo deck",
   "starterLoadErrorTitle": "Không tải được deck mẫu",
-  "starterLoadErrorBody": "Thư viện của bạn không bị ảnh hưởng. Hãy thử lại sau giây lát."
+  "starterLoadErrorBody": "Thư viện của bạn không bị ảnh hưởng. Hãy thử lại sau giây lát.",
+  "tagsTitle": "Tag",
+  "tagsSearchHint": "Tìm tag",
+  "tagsSearchClear": "Xoá tìm kiếm",
+  "tagsCount": "{count} tag",
+  "tagsNone": "Không có tag",
+  "tagsNoMatches": "Không khớp",
+  "tagsOrder": "A→Z",
+  "tagsCardCount": "{count} thẻ",
+  "tagsRowActions": "Thao tác cho {tag}",
+  "tagsEmptyTitle": "Chưa có tag nào",
+  "tagsEmptyBody": "Tag xuất hiện ở đây khi bạn thêm chúng lúc tạo hoặc sửa thẻ.",
+  "tagsGoToLibrary": "Về thư viện",
+  "tagsSearchEmptyTitle": "Không có tag nào khớp “{term}”",
+  "tagsSearchEmptyBody": "Thử cách viết khác. Tìm tag không phân biệt hoa thường.",
+  "tagsLoadErrorTitle": "Không tải được tag",
+  "tagsActionsCaption": "Thao tác với tag",
+  "tagsFindCards": "Tìm thẻ có tag này",
+  "tagsFindCardsHint": "Tìm “{tag}” trong thư viện",
+  "tagsRename": "Đổi tên tag",
+  "tagsRenameHint": "Đổi sang tên đã có sẽ gộp hai tag",
+  "tagsDelete": "Xoá tag",
+  "tagsDeleteHint": "{count, plural, =0{Xoá khỏi danh mục} other{Gỡ khỏi {count} thẻ · thẻ vẫn còn}}",
+  "tagsRenameBody": "Đổi tên sẽ cập nhật mọi thẻ đang dùng “{tag}”.",
+  "tagsNewName": "Tên mới",
+  "tagsCaseHint": "Tên tag không phân biệt hoa thường.",
+  "tagsLength": "{length} / {max}",
+  "tagsLengthUnique": "{length} / {max} · tên là duy nhất, không phân biệt hoa thường.",
+  "tagsNameTooLong": "Tên tag tối đa {max} ký tự.",
+  "tagsRenameConfirm": "Đổi tên",
+  "tagsMergeConfirm": "Gộp tag",
+  "tagsMergeNotice": "Đã có tag “{target}”. Tiếp tục sẽ gộp “{source}” vào tag đó — giữ cách viết “{target}”.",
+  "tagsMergeSafe": "Không thẻ nào bị xoá. Thẻ mang cả hai chỉ giữ một tag; không thẻ nào vượt 10 tag.",
+  "tagsDeleteTitle": "Xoá tag này?",
+  "tagsDeleteBody": "“{tag}” sẽ bị gỡ khỏi {count, plural, =0{danh mục} other{{count} thẻ và biến mất khỏi danh mục}}. Tag không được giữ trong Thùng rác.",
+  "tagsDeleteSafe": "{count, plural, =0{Không thẻ nào bị xoá, ẩn hay thay đổi.} other{Không thẻ nào bị xoá, ẩn hay thay đổi — cả {count} thẻ vẫn ở nguyên chỗ.}}",
+  "tagsDeleteConfirm": "{count, plural, =0{Xoá tag} other{Gỡ khỏi {count} thẻ}}",
+  "tagsRenameFailed": "Không đổi được tên tag. Chưa có gì thay đổi — hãy thử lại sau giây lát.",
+  "tagsDeleteFailed": "Không xoá được tag. Chưa có gì thay đổi — hãy thử lại sau giây lát.",
+  "tagsGone": "“{tag}” không còn nữa — nó vừa bị xoá."
 }
```

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index fd05007..045781e 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -66,6 +66,8 @@ abstract final class AppIcons {
   static const IconData textScale = Icons.format_size;
   // Development fixtures (screen 03, BR-STARTER-010).
   static const IconData fixture = Icons.science_outlined; // flask-conical
+  // A rename onto an existing tag merges the two (screen 05).
+  static const IconData merge = Icons.merge; // git-merge
 
   // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
   static const IconData starterDecks = Icons.auto_awesome_outlined; // sparkles
```

`lib/features/tags/domain/models/tag_count_model.dart` (apply this diff):

```diff
diff --git a/lib/features/tags/domain/models/tag_count_model.dart b/lib/features/tags/domain/models/tag_count_model.dart
index 47c269a..0dbfc58 100644
--- a/lib/features/tags/domain/models/tag_count_model.dart
+++ b/lib/features/tags/domain/models/tag_count_model.dart
@@ -1,3 +1,5 @@
+import 'package:memox/core/text/folded_text.dart';
+
 /// A tag and the active cards carrying it in the read's scope: the library
 /// for the catalog, one deck for the card list's filter (BR-TAG-003; tag
 /// management spec D3).
@@ -16,3 +18,17 @@ final class TagCount {
   /// Active cards only: a card in the Trash is not counted (BR-TAG-010).
   final int cardCount;
 }
+
+/// The catalog's search, done on a list already read (BR-TAG-003).
+extension TagCountsMatching on List<TagCount> {
+  /// The tags whose folded name holds [term]'s fold, in order: the fold the
+  /// store writes and searches with. A blank term keeps every tag.
+  List<TagCount> matching(String term) {
+    final folded = foldText(term);
+    if (folded.isEmpty) return this;
+    return [
+      for (final tag in this)
+        if (foldText(tag.name).contains(folded)) tag,
+    ];
+  }
+}
```

`lib/features/tags/presentation/screens/tags_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/presentation/controllers/tag_actions_controller.dart';
import 'package:memox/features/tags/presentation/providers/tag_catalog_provider.dart';
import 'package:memox/features/tags/presentation/states/tag_actions_state.dart';
import 'package:memox/features/tags/presentation/widgets/items/tag_row_widget.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_actions_sheet_widget.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_delete_dialog_widget.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 05, Tags (UC-TAG-001): every tag of the library with its cards,
/// narrowed as the search is typed, each renamed, merged or deleted from
/// its actions. [onFindCards] opens the Library search with a tag's name
/// (FE-B2 spec D11).
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key, required this.onFindCards});

  final ValueChanged<String> onFindCards;

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  static const int _skeletonRows = 5;

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TagActionsController _tags() =>
      ref.read(tagActionsControllerProvider.notifier);

  Future<void> _openActions(TagCount tag) async {
    final action = await showTagActionsSheet(context, tag: tag);
    if (action == null || !mounted) return;
    switch (action) {
      case TagAction.findCards:
        widget.onFindCards(tag.name);
      case TagAction.rename:
        await _rename(tag);
      case TagAction.delete:
        await _delete(tag);
    }
  }

  /// The dialog, then the write; a plan that no longer holds opens the
  /// dialog again on the name typed (D8).
  Future<void> _rename(TagCount tag, {String? name}) async {
    final request = await showTagRenameDialog(context, tag: tag, name: name);
    if (request == null || !mounted) return;
    await _write(
      tag,
      () => _tags().rename(
        tagId: tag.id,
        name: request.name,
        mergeIntoTagId: request.mergeIntoTagId,
      ),
      failure: context.l10n.tagsRenameFailed,
      onReplan: () => _rename(tag, name: request.name),
    );
  }

  Future<void> _delete(TagCount tag) async {
    if (!await showTagDeleteDialog(context, tag: tag) || !mounted) return;
    await _write(
      tag,
      () => _tags().delete(tag.id),
      failure: context.l10n.tagsDeleteFailed,
    );
  }

  /// Runs [write] while [tag]'s row spins, then says how it ended; a
  /// success says nothing, the catalog shows it (spec §6).
  Future<void> _write(
    TagCount tag,
    Future<TagWriteResult> Function() write, {
    required String failure,
    Future<void> Function()? onReplan,
  }) async {
    final result = await write();
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case TagWriteResult.done:
        return;
      case TagWriteResult.gone:
        showMxSnackbar(context, message: l10n.tagsGone(tag.name));
      case TagWriteResult.replan:
        await onReplan?.call();
      case TagWriteResult.failed:
        showMxSnackbar(
          context,
          message: failure,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(
            _write(tag, write, failure: failure, onReplan: onReplan),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(tagCatalogProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.tagsTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: _back,
        ),
      ),
      body: MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxSearchField(
            controller: _search,
            hintText: l10n.tagsSearchHint,
            clearLabel: l10n.tagsSearchClear,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.grouped),
          ...switch (catalog) {
            AsyncData(:final value) => _catalog(l10n, value),
            AsyncError() => [
              MxErrorState(
                title: l10n.tagsLoadErrorTitle,
                body: l10n.libraryLoadErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(tagCatalogProvider),
              ),
            ],
            _ => [
              MxSkeletonList(
                semanticLabel: l10n.commonLoading,
                rows: _skeletonRows,
              ),
            ],
          },
        ],
      ),
    );
  }

  void _back() => unawaited(Navigator.of(context).maybePop());

  /// The header, then the rows, or why there are none: no tag at all, or
  /// none under the search (A6).
  List<Widget> _catalog(AppLocalizations l10n, List<TagCount> tags) {
    final term = _search.text.trim();
    final shown = tags.matching(term);
    final busy = ref.watch(tagActionsControllerProvider);
    final header = MxListSectionHeader(
      label: switch ((tags.isEmpty, shown.isEmpty)) {
        (true, _) => l10n.tagsNone,
        (false, true) => l10n.tagsNoMatches,
        _ => l10n.tagsCount(shown.length),
      },
      trailing: Text(l10n.tagsOrder, style: context.textStyles.overline),
    );
    if (tags.isEmpty) {
      return [
        header,
        MxEmptyState(
          icon: AppIcons.tag,
          title: l10n.tagsEmptyTitle,
          body: l10n.tagsEmptyBody,
          actionLabel: l10n.tagsGoToLibrary,
          onAction: _back,
        ),
      ];
    }
    if (shown.isEmpty) {
      return [
        header,
        MxEmptyState(
          icon: AppIcons.search,
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
          title: l10n.tagsSearchEmptyTitle(term),
          body: l10n.tagsSearchEmptyBody,
        ),
      ];
    }
    return [
      header,
      MxSection(
        children: [
          for (final tag in shown)
            TagRowWidget(
              key: ValueKey(tag.id),
              tag: tag,
              isBusy: busy.isBusy(tag.id),
              onActions: () => unawaited(_openActions(tag)),
            ),
        ],
      ),
    ];
  }
}
```

`lib/features/tags/presentation/widgets/items/tag_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One tag of screen 05: its name, its cards and ⋮, which spins while the
/// tag's write runs (`busy`). A long name ends in an ellipsis; the action
/// sheet names it whole.
class TagRowWidget extends StatelessWidget {
  const TagRowWidget({
    super.key,
    required this.tag,
    required this.isBusy,
    required this.onActions,
  });

  final TagCount tag;
  final bool isBusy;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxListRow(
      leading: const MxIconTile(icon: AppIcons.tag),
      title: tag.name,
      subtitle: l10n.tagsCardCount(tag.cardCount),
      isBusy: isBusy,
      onTap: isBusy ? null : onActions,
      trailing: MxIconButton(
        icon: AppIcons.more,
        semanticLabel: l10n.tagsRowActions(tag.name),
        onPressed: onActions,
      ),
      hasDivider: false,
    );
  }
}
```

`lib/features/tags/presentation/widgets/overlays/tag_actions_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/presentation/widgets/support/tag_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// A tag's three commands (kit 05 `sheet`).
enum TagAction { findCards, rename, delete }

/// Opens [tag]'s commands; completes with the chosen one, or null.
Future<TagAction?> showTagActionsSheet(
  BuildContext context, {
  required TagCount tag,
}) => showMxBottomSheet<TagAction>(
  context,
  builder: (_) => TagActionsSheetWidget(tag: tag),
);

/// Find cards, Rename (which may merge, A1) and Delete, the one destructive
/// command (A3).
class TagActionsSheetWidget extends StatelessWidget {
  const TagActionsSheetWidget({super.key, required this.tag});

  final TagCount tag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void choose(TagAction action) => Navigator.of(context).pop(action);
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            MxTagChip(label: tagWithCount(tag.name, tag.cardCount)),
            Text(
              l10n.tagsActionsCaption,
              style: context.textStyles.rowDescription,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.search,
              label: l10n.tagsFindCards,
              subtitle: l10n.tagsFindCardsHint(tag.name),
              hasChevron: true,
              onTap: () => choose(TagAction.findCards),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: l10n.tagsRename,
              subtitle: l10n.tagsRenameHint,
              hasChevron: true,
              onTap: () => choose(TagAction.rename),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.tagsDelete,
              subtitle: l10n.tagsDeleteHint(tag.cardCount),
              isDestructive: true,
              onTap: () => choose(TagAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/tags/presentation/widgets/overlays/tag_delete_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before [tag] is deleted, saying no card is (UC-TAG-001 A3; kit 05
/// `del`). Completes true to delete.
Future<bool> showTagDeleteDialog(
  BuildContext context, {
  required TagCount tag,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => TagDeleteDialogWidget(tag: tag),
    ) ??
    false;

class TagDeleteDialogWidget extends StatelessWidget {
  const TagDeleteDialogWidget({super.key, required this.tag});

  final TagCount tag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = tag.cardCount;
    return MxDialog(
      title: l10n.tagsDeleteTitle,
      body: l10n.tagsDeleteBody(tag.name, count),
      content: MxCard(
        isSuccess: true,
        child: IconTheme.merge(
          data: IconThemeData(color: context.derivedColors.successInk),
          child: Row(
            spacing: AppSpacing.control,
            children: [
              const Icon(AppIcons.safe),
              Expanded(
                child: Text(
                  l10n.tagsDeleteSafe(count),
                  style: context.textStyles.noteText,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.tagsDeleteConfirm(count),
        confirmIcon: AppIcons.delete,
        isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
```

`lib/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/presentation/controllers/tag_actions_controller.dart';
import 'package:memox/features/tags/presentation/widgets/support/tag_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// How long the name stays still before its plan is read (FE-B2 spec D8).
const Duration tagRenameSettle = Duration(milliseconds: 250);

/// The name to write, and the tag the person confirmed merging into.
typedef TagRenameRequest = ({String name, String? mergeIntoTagId});

/// Renames [tag], starting from [name] when the last try must be planned
/// again (kit 05 `rename`, `renameMerge`, `nameTooLong`). Completes with
/// the request to write, or null when cancelled.
Future<TagRenameRequest?> showTagRenameDialog(
  BuildContext context, {
  required TagCount tag,
  String? name,
}) => showMxDialog<TagRenameRequest>(
  context,
  builder: (_) => TagRenameDialogWidget(tag: tag, name: name ?? tag.name),
);

/// The name, checked as it is typed (BR-TAG-001), and what writing it would
/// do: nothing, a rename, or a merge disclosed before it is confirmed
/// (UC-TAG-001 A1). The last plan stays while the next one settles.
class TagRenameDialogWidget extends ConsumerStatefulWidget {
  const TagRenameDialogWidget({
    super.key,
    required this.tag,
    required this.name,
  });

  final TagCount tag;
  final String name;

  @override
  ConsumerState<TagRenameDialogWidget> createState() =>
      _TagRenameDialogWidgetState();
}

class _TagRenameDialogWidgetState extends ConsumerState<TagRenameDialogWidget> {
  late final _name = TextEditingController(text: widget.name);
  Timer? _settle;
  TagRenamePlan? _plan;

  @override
  void initState() {
    super.initState();
    unawaited(_readPlan());
  }

  @override
  void dispose() {
    _settle?.cancel();
    _name.dispose();
    super.dispose();
  }

  /// The name rule the text breaks, checked at once; null when it passes.
  TagRejection? get _rejection => switch (TagEntity.checkName(_name.text)) {
    Ok() => null,
    Rejected(:final reason) => reason,
  };

  int get _length => _name.text.trim().characters.length;

  void _changed(String _) {
    _settle?.cancel();
    setState(() {});
    if (_rejection != null) return;
    _settle = Timer(tagRenameSettle, () => unawaited(_readPlan()));
  }

  Future<void> _readPlan() async {
    final name = _name.text;
    if (_rejection != null) return;
    try {
      final outcome = await ref
          .read(tagActionsControllerProvider.notifier)
          .planRename(tagId: widget.tag.id, name: name);
      if (!mounted || _name.text != name) return;
      setState(() {
        _plan = switch (outcome) {
          Ok(:final value) => value,
          // A tag gone meanwhile: the write says so (E3).
          Rejected() => null,
        };
      });
    } on Failure {
      // The last plan stays; the write checks again.
    }
  }

  /// Rename or merge, once the name passes and would change something.
  VoidCallback? get _confirm {
    if (_rejection != null) return null;
    return switch (_plan) {
      TagRenameRename() => () => _pop(null),
      TagRenameMerge(:final target) => () => _pop(target.id),
      TagRenameUnchanged() || null => null,
    };
  }

  void _pop(String? mergeIntoTagId) =>
      Navigator.of(context)
          .pop((name: _name.text, mergeIntoTagId: mergeIntoTagId));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final rejection = _rejection;
    final isTooLong = rejection == TagRejection.nameTooLong;
    final merge = switch (_plan) {
      final TagRenameMerge plan when rejection == null => plan,
      _ => null,
    };
    final confirm = _confirm;
    return MxDialog(
      title: l10n.tagsRename,
      body: l10n.tagsRenameBody(widget.tag.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tagsNewName.toUpperCase(),
                  style: styles.overline,
                ),
              ),
              if (isTooLong)
                Text(
                  l10n.tagsLength(_length, TagEntity.maxNameLength),
                  style: styles.captionIn(context.colors.error),
                ),
            ],
          ),
          MxTextField(
            controller: _name,
            label: l10n.tagsNewName,
            errorText: _message(l10n, rejection),
            textInputAction: TextInputAction.done,
            onChanged: _changed,
            onSubmitted: (_) => confirm?.call(),
          ),
          if (rejection == null)
            Text(
              merge == null
                  ? l10n.tagsCaseHint
                  : l10n.tagsLengthUnique(_length, TagEntity.maxNameLength),
              style: styles.footerCaption,
            ),
          if (merge != null) _MergePanel(source: widget.tag, merge: merge),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: merge == null
            ? l10n.tagsRenameConfirm
            : l10n.tagsMergeConfirm,
        confirmIcon: merge == null ? null : AppIcons.merge,
        isWarning: merge != null,
        onConfirm: confirm,
      ),
    );
  }

  String? _message(AppLocalizations l10n, TagRejection? rejection) =>
      switch (rejection) {
        TagRejection.nameTooLong => l10n.tagsNameTooLong(
          TagEntity.maxNameLength,
        ),
        TagRejection.blankName => l10n.tagRejectionBlankName,
        TagRejection.controlCharacter => l10n.tagRejectionControlCharacter,
        _ => null,
      };
}

/// What the merge does, before it is confirmed (A1): the target keeps its
/// spelling, and carries the union of both tags' cards (BE-B2 D6).
class _MergePanel extends StatelessWidget {
  const _MergePanel({required this.source, required this.merge});

  final TagCount source;
  final TagRenameMerge merge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = context.textStyles.noteText;
    final ink = context.derivedColors.warningInk;
    return MxCard(
      isWarning: true,
      // The panel's glyphs take the warning ink.
      child: IconTheme.merge(
        data: IconThemeData(color: ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.control,
          children: [
            Row(
              spacing: AppSpacing.control,
              children: [
                const Icon(AppIcons.merge),
                Expanded(
                  child: Text(
                    l10n.tagsMergeNotice(merge.target.name, source.name),
                    style: note,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.control,
              runSpacing: AppSpacing.micro,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MxTagChip(label: tagWithCount(source.name, source.cardCount)),
                const Icon(AppIcons.arrowRight),
                MxTagChip(
                  label: tagWithCount(merge.target.name, merge.mergedCardCount),
                ),
              ],
            ),
            Text(l10n.tagsMergeSafe, style: note),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/tags/presentation/widgets/support/tag_labels_widget.dart`:

```dart
/// Between a tag's name and its count on a chip (kit 05).
const String tagCountSeparator = ' · ';

/// "{tag} · {n}", the chip of a tag with its cards.
String tagWithCount(String name, int count) => '$name$tagCountSeparator$count';
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
TZ=UTC flutter test --tags golden --update-goldens test/features/tags/presentation/tags_golden_test.dart
flutter test test/features/tags test/visual_audit test/app/l10n_test.dart
flutter analyze
```

Expected: PASS, 14 tests in `tags_screen_test.dart`, 3 in
`tag_counts_matching_test.dart`, and the audit in English and Vietnamese. Twenty-six new
goldens; compare each with `docs/shared/ui/screen-handoff/img/05-tags/` (kit 05's
sixteen tags, in the store's folded order, so "động từ" is last; UI-base row 137):
- `tags_loaded_*`: "16 TAGS" with "A→Z" as plain text, the long name ending in "…";
- `tags_sheet_*`, `tags_rename_*`, `tags_rename_merge_*` (the panel, "ngữ pháp · 45",
  the union, and "Merge tags" amber with dark ink), `tags_name_too_long_*` ("61 / 50"),
  `tags_del_*` with their frames;
- `tags_busy_*`, `tags_op_error_*` (one sentence with Retry), `tags_tag_gone_*`;
- `tags_loading_*`, `tags_empty_*`, `tags_search_empty_*`, and `tags_read_error_*`,
  which the kit lacks (D10).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/tags/domain/models/tag_count_model.dart \
  lib/features/tags/presentation/screens/tags_screen.dart \
  lib/features/tags/presentation/widgets/items/tag_row_widget.dart \
  lib/features/tags/presentation/widgets/overlays/tag_actions_sheet_widget.dart \
  lib/features/tags/presentation/widgets/overlays/tag_delete_dialog_widget.dart \
  lib/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart \
  lib/features/tags/presentation/widgets/support/tag_labels_widget.dart \
  test/features/tags/domain/tag_counts_matching_test.dart \
  test/features/tags/presentation/tags_golden_test.dart \
  test/features/tags/presentation/tags_screen_test.dart \
  test/support/tag_screen_fixtures.dart \
  test/visual_audit/screens/features/tags/screens/tags_screen_visual_audit_test.dart \
  test/features/tags/presentation/goldens/tags_busy_dark.png \
  test/features/tags/presentation/goldens/tags_busy_light.png \
  test/features/tags/presentation/goldens/tags_del_dark.png \
  test/features/tags/presentation/goldens/tags_del_light.png \
  test/features/tags/presentation/goldens/tags_empty_dark.png \
  test/features/tags/presentation/goldens/tags_empty_light.png \
  test/features/tags/presentation/goldens/tags_loaded_dark.png \
  test/features/tags/presentation/goldens/tags_loaded_light.png \
  test/features/tags/presentation/goldens/tags_loading_dark.png \
  test/features/tags/presentation/goldens/tags_loading_light.png \
  test/features/tags/presentation/goldens/tags_name_too_long_dark.png \
  test/features/tags/presentation/goldens/tags_name_too_long_light.png \
  test/features/tags/presentation/goldens/tags_op_error_dark.png \
  test/features/tags/presentation/goldens/tags_op_error_light.png \
  test/features/tags/presentation/goldens/tags_read_error_dark.png \
  test/features/tags/presentation/goldens/tags_read_error_light.png \
  test/features/tags/presentation/goldens/tags_rename_dark.png \
  test/features/tags/presentation/goldens/tags_rename_light.png \
  test/features/tags/presentation/goldens/tags_rename_merge_dark.png \
  test/features/tags/presentation/goldens/tags_rename_merge_light.png \
  test/features/tags/presentation/goldens/tags_search_empty_dark.png \
  test/features/tags/presentation/goldens/tags_search_empty_light.png \
  test/features/tags/presentation/goldens/tags_sheet_dark.png \
  test/features/tags/presentation/goldens/tags_sheet_light.png \
  test/features/tags/presentation/goldens/tags_tag_gone_dark.png \
  test/features/tags/presentation/goldens/tags_tag_gone_light.png
git commit -m "$(cat <<'EOF'
feat(tags): screen 05, Tags (FE-B2, UC-TAG-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: Screen 07's tag filter (D3, D12, D14; UC-TAG-001 steps 6-8, A4, A5, A7)

**Files:**
- Create: `lib/features/card/domain/usecases/watch_card_tag_filter_use_case.dart`
- Modify: `lib/features/card/presentation/providers/card_list_provider.dart`
- Create: `lib/features/card/presentation/providers/card_tag_filter_provider.dart`
- Create: `lib/features/card/presentation/providers/watch_card_tag_filter_use_case_provider.dart`
- Modify: `lib/features/card/presentation/states/card_list_request_state.dart`
- Create: `lib/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/features/card/presentation/goldens/card_list_dark.png`
- Modify: `test/features/card/presentation/goldens/card_list_light.png`
- Modify: `test/features/card/presentation/goldens/card_list_search_dark.png`
- Modify: `test/features/card/presentation/goldens/card_list_search_light.png`
- Modify: `test/features/card/presentation/goldens/card_list_trashed_dark.png`
- Modify: `test/features/card/presentation/goldens/card_list_trashed_light.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_applied_dark.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_applied_light.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_no_card_dark.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_no_card_light.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_none_dark.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_none_light.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_one_dark.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_one_light.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_several_dark.png`
- Create: `test/features/card/presentation/goldens/card_tag_filter_several_light.png`
- Test (modify): `test/features/card/presentation/card_list_section_test.dart`
- Test (modify): `test/features/card/presentation/card_list_state_test.dart`
- Test (create): `test/features/card/presentation/card_tag_filter_golden_test.dart`
- Test (create): `test/features/card/presentation/card_tag_filter_test.dart`

**Interfaces:**
- Consumes: `TagRepository`, `tagRepositoryProvider` (tags `di/`), `TagCount` and
  Task 4's `matching`; `CardListQuery.tagIds` (BE-C4); Task 1's nullable `onCancel`.
- Produces:
  - `WatchCardTagFilterUseCase(TagRepository)` → `Stream<List<TagCount>> call({required
    String deckId})`; `watchCardTagFilterUseCaseProvider`;
    `cardTagFilterProvider(String deckId)`;
  - `CardTagFilter([Set<String> ids])` (value equality, `isEmpty`);
    `CardListRequestState.tags`; `CardListRequest.filterTags(Set<String>)`;
  - `cardListProvider({…, required CardTagFilter tags, …})`;
  - `showCardTagFilterSheet(context, {required String deckId, required Set<String>
    applied})` → `Future<Set<String>?>`;
  - `CardListToolbarWidget({required String deckId, …})`;
    `CardListEmptyWidget({…, required VoidCallback onClearTags, …})`;
  - the `cardFilterTags`, `cardTagFilter…` and `cardClearTagFilter` ARB keys.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_list_section_test.dart` (apply this diff):

```diff
diff --git a/test/features/card/presentation/card_list_section_test.dart b/test/features/card/presentation/card_list_section_test.dart
index 5595f34..ce0327c 100644
--- a/test/features/card/presentation/card_list_section_test.dart
+++ b/test/features/card/presentation/card_list_section_test.dart
@@ -275,6 +275,7 @@ void main() {
           filter: CardListFilter.all,
           sort: CardListSort.newest,
           searchTerm: '',
+          tags: const CardTagFilter(),
           windowSize: cardListWindowStep,
         ).overrideWith(
           (ref) => Stream<CardListView>.error(StateError('disk I/O error')),
@@ -324,6 +325,7 @@ void main() {
           filter: CardListFilter.all,
           sort: CardListSort.newest,
           searchTerm: '',
+          tags: const CardTagFilter(),
           windowSize: cardListWindowStep,
         ).overrideWith((ref) => stream.stream),
       ],
```

`test/features/card/presentation/card_list_state_test.dart` (apply this diff):

```diff
diff --git a/test/features/card/presentation/card_list_state_test.dart b/test/features/card/presentation/card_list_state_test.dart
index 2bd8669..4110fd1 100644
--- a/test/features/card/presentation/card_list_state_test.dart
+++ b/test/features/card/presentation/card_list_state_test.dart
@@ -36,6 +36,32 @@ void main() {
     expect(container.read(provider).query.filter, CardListFilter.due);
   });
 
+  test('tags filter the query; applying them starts again from the first '
+      'window and every other change keeps them (BR-TAG-004)', () {
+    final container = ProviderContainer();
+    addTearDown(container.dispose);
+    final provider = cardListRequestProvider('d');
+    final keep = container.listen(provider, (_, _) {});
+    addTearDown(keep.close);
+    final notifier = container.read(provider.notifier);
+
+    notifier
+      ..show(CardListFilter.due)
+      ..grow()
+      ..filterTags({'t1', 't2'});
+    expect(container.read(provider).windowSize, cardListWindowStep);
+    expect(container.read(provider).query.tagIds, {'t1', 't2'});
+    expect(container.read(provider).query.filter, CardListFilter.due);
+    notifier
+      ..search('kor')
+      ..sortBy(CardListSort.dueFirst)
+      ..show(CardListFilter.all)
+      ..grow();
+    expect(container.read(provider).tags, const CardTagFilter({'t2', 't1'}));
+    notifier.filterTags(const {});
+    expect(container.read(provider).tags.isEmpty, isTrue);
+  });
+
   test('a selection toggles, takes a whole set, and clears', () {
     final container = ProviderContainer();
     addTearDown(container.dispose);
```

`test/features/card/presentation/card_tag_filter_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Screen 07's tag filter (FE-B2 spec D3, D14), which the kit does not draw:
// the sheet with none, one and several tags chosen, the list it filters,
// and a filter with no card (A7). Romanized fronts: the golden test font
// has no Hangul glyphs.

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words with four cards, tagged verb, noun and greeting; travel
/// is on no card of the deck.
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final other = await env.decks.sub(korean.id, 'Other');
  final rows = [
    ('annyeonghaseyo', 'hello'),
    ('gamsahamnida', 'thank you'),
    ('mul', 'water'),
    ('sarang', 'love'),
  ];
  for (final (index, (front, back)) in rows.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: words.id,
      front: front,
      back: back,
      createdAt: DateTime(2026, 9, 1 + index),
    );
  }
  await insertCard(env.db, id: 'o', deckId: other.id, front: 'yeohaeng');
  final tags = TagRepositoryImpl(env.db);
  await tags.attachByName(cardIds: {'c0', 'c1'}, name: 'greeting');
  await tags.attachByName(cardIds: {'c1', 'c3'}, name: 'verb');
  await tags.attachByName(cardIds: {'c2'}, name: 'noun');
  await tags.attachByName(cardIds: {'o'}, name: 'travel');
  return words.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name,
      Future<void> Function() before,
    ) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          cardDeckScreen(deckId),
          brightness,
        );
        await before();
        await expectBoundaryGolden(
          tester,
          'goldens/card_tag_filter_${name}_$theme.png',
        );
      });
    }

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterTags));
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, List<String> names) async {
      for (final name in names) {
        await tester.tap(find.text(name).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    libraryTest('tag filter, none chosen, $theme', (tester, env) async {
      await shoot(tester, env, 'none', () => openSheet(tester));
    });

    libraryTest('tag filter, one chosen, $theme', (tester, env) async {
      await shoot(tester, env, 'one', () async {
        await openSheet(tester);
        await choose(tester, ['verb']);
      });
    });

    libraryTest('tag filter, several chosen, $theme', (tester, env) async {
      await shoot(tester, env, 'several', () async {
        await openSheet(tester);
        await choose(tester, ['verb', 'noun']);
      });
    });

    libraryTest('tag filter, applied, $theme', (tester, env) async {
      await shoot(tester, env, 'applied', () async {
        await openSheet(tester);
        await choose(tester, ['verb', 'noun']);
        await tester.tap(find.text(_en.cardTagFilterApply));
        await tester.pumpAndSettle();
      });
    });

    libraryTest('tag filter, no card (A7), $theme', (tester, env) async {
      await shoot(tester, env, 'no_card', () async {
        await openSheet(tester);
        await choose(tester, ['travel']);
        await tester.tap(find.text(_en.cardTagFilterApply));
        await tester.pumpAndSettle();
      });
    });
  }
}
```

`test/features/card/presentation/card_tag_filter_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

// Screen 07's tag filter (FE-B2 spec D3, D12, D14; UC-TAG-001 steps 6-8,
// A4, A5, A7).

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// Korean › Words: annyeong and gamsa are verbs, mul is a noun, sarang has
/// no tag; "travel" is on a card of another deck only.
Future<String> _seed(LibraryEnv env, {int extraTags = 0}) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final other = await env.decks.sub(korean.id, 'Other');
  for (final (id, front) in [
    ('a', 'annyeong'),
    ('g', 'gamsa'),
    ('m', 'mul'),
    ('s', 'sarang'),
  ]) {
    await insertCard(env.db, id: id, deckId: words.id, front: front);
  }
  await insertCard(env.db, id: 'o', deckId: other.id, front: 'yeohaeng');
  final tags = TagRepositoryImpl(env.db);
  await tags.attachByName(cardIds: {'a', 'g'}, name: 'verb');
  await tags.attachByName(cardIds: {'m'}, name: 'noun');
  await tags.attachByName(cardIds: {'o'}, name: 'travel');
  for (var i = 0; i < extraTags; i++) {
    await tags.attachByName(cardIds: {'s'}, name: 'extra $i');
  }
  return words.id;
}

/// [text] inside the sheet: a card's row also shows its tags.
Finder _inSheet(String text) => find.descendant(
  of: find.byType(CardTagFilterSheetWidget),
  matching: find.text(text),
);

MxFilterChip _tagsChip(WidgetTester tester) => tester.widget<MxFilterChip>(
  find.widgetWithText(MxFilterChip, _en.cardFilterTags),
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterTags));
  await tester.pumpAndSettle();
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.text(_en.cardTagFilterApply));
  await tester.pumpAndSettle();
}

List<String> _fronts(WidgetTester tester) => [
  for (final row in tester.widgetList<CardRowWidget>(
    find.byType(CardRowWidget),
  ))
    row.item.front,
];

void main() {
  libraryTest('none chosen: every tag with its cards in this deck, 0 '
      'included, in the catalog order; Clear is off', (tester, env) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));

    expect(_tagsChip(tester).isSelected, isFalse);
    await _openSheet(tester);

    expect(find.text(_en.cardTagFilterTitle), findsOneWidget);
    expect(find.text(_en.cardTagFilterNone), findsOneWidget);
    for (final (name, count) in [('noun', 1), ('travel', 0), ('verb', 2)]) {
      expect(_inSheet(name), findsOneWidget);
      expect(find.text(_en.cardTagFilterCount(count)), findsWidgets);
    }
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.cardTagFilterClear),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(MxSearchField), findsNothing);
  });

  libraryTest('one, then several: Apply shows the cards with any of them, '
      'and the chip says how many are applied (steps 7-8)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await tester.pump();
    expect(find.text(_en.cardTagFilterChosen(1)), findsOneWidget);
    await _apply(tester);

    expect(_fronts(tester)..sort(), ['annyeong', 'gamsa']);
    expect((_tagsChip(tester).isSelected, _tagsChip(tester).count), (true, 1));

    await _openSheet(tester);
    await tester.tap(_inSheet('noun'));
    await tester.pump();
    expect(find.text(_en.cardTagFilterChosen(2)), findsOneWidget);
    await _apply(tester);

    expect(_fronts(tester)..sort(), ['annyeong', 'gamsa', 'mul']);
    expect(_tagsChip(tester).count, 2);
  });

  libraryTest('closing without Apply keeps what was applied (A5)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await _apply(tester);
    await _openSheet(tester);
    await tester.tap(_inSheet('noun'));
    await tester.pump();
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();

    expect(_fronts(tester)..sort(), ['annyeong', 'gamsa']);
    expect(_tagsChip(tester).count, 1);
  });

  libraryTest('Clear empties the choice and Apply shows every card again '
      '(A4)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await _apply(tester);
    await _openSheet(tester);
    await tester.tap(find.text(_en.cardTagFilterClear));
    await tester.pump();

    expect(find.text(_en.cardTagFilterNone), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    await _apply(tester);

    expect(_fronts(tester), hasLength(4));
    expect(_tagsChip(tester).isSelected, isFalse);
  });

  libraryTest('a tag with no card here shows none, and offers to clear the '
      'tag filter (A7)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('travel'));
    await _apply(tester);

    expect(find.text(_en.cardTagFilterEmptyTitle), findsOneWidget);
    await tester.tap(find.text(_en.cardClearTagFilter));
    await tester.pumpAndSettle();

    expect(_fronts(tester), hasLength(4));
    expect(_tagsChip(tester).isSelected, isFalse);
  });

  libraryTest('a tag deleted meanwhile leaves the applied set (D12)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await tester.tap(_inSheet('noun'));
    await _apply(tester);
    final verb = await env.db
        .customSelect(
          'SELECT id FROM tags WHERE name = ?',
          variables: [const Variable<String>('verb')],
        )
        .getSingle();
    await TagRepositoryImpl(env.db).deleteTag(tagId: verb.read<String>('id'));
    await tester.pumpAndSettle();

    expect(_tagsChip(tester).count, 1);
    expect(_fronts(tester), ['mul']);
  });

  libraryTest('above eight tags a search heads the list; a chosen tag it '
      'hides stays chosen', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _section(await _seed(env, extraTags: 6)),
    );
    await _openSheet(tester);
    expect(find.byType(MxSearchField), findsOneWidget);

    await tester.tap(_inSheet('noun'));
    await tester.enterText(find.byType(TextField), 'VER');
    await tester.pump();

    expect(_inSheet('noun'), findsNothing);
    expect(_inSheet('verb'), findsOneWidget);
    expect(find.text(_en.cardTagFilterChosen(1)), findsOneWidget);
    await tester.tap(_inSheet('verb'));
    await _apply(tester);
    expect(_tagsChip(tester).count, 2);
  });

  libraryTest('no tag in the library: the sheet says where tags come from '
      'and closes', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: words.id, front: 'annyeong');
    await pumpLibraryScreen(tester, env, _section(words.id));
    await _openSheet(tester);

    expect(find.text(_en.cardTagFilterEmpty), findsOneWidget);
    await tester.tap(find.text(_en.cardTagFilterClose));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardTagFilterTitle), findsNothing);
  });

  libraryTest('at text scale 2 in Vietnamese the sheet fits a 360 dp phone, '
      'with 48 dp targets', (tester, env) async {
    final vi = lookupAppLocalizations(const Locale('vi'));
    await pumpLibraryScreen(
      tester,
      env,
      _section(await _seed(env, extraTags: 6)),
      textScale: 2,
      locale: const Locale('vi'),
    );
    await tester.ensureVisible(
      find.widgetWithText(MxFilterChip, vi.cardFilterTags),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, vi.cardFilterTags));
    await tester.pumpAndSettle();
    await tester.tap(_inSheet('extra 0'));
    await tester.pump();

    expect(find.text(vi.cardTagFilterChosen(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/presentation/card_tag_filter_test.dart test/features/card/presentation/card_list_state_test.dart
```

Expected: FAIL to compile: `CardTagFilter`, `filterTags` and the sheet do not exist.

- [ ] **Step 3: Implement**

The copy: apply the ARB diffs, then the code.

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 542a6a0..c4e12c2 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -5840,5 +5840,71 @@
       }
     },
     "description": "Screen 05: the toast when the tag was deleted elsewhere (tagGone, E3)."
+  },
+  "cardFilterTags": "Tags",
+  "@cardFilterTags": {
+    "description": "Screen 07: the Tags filter chip; it opens the tag filter sheet (spec D14)."
+  },
+  "cardTagFilterTitle": "Filter by tags",
+  "@cardTagFilterTitle": {
+    "description": "Screen 07 tag filter sheet: the title."
+  },
+  "cardTagFilterNone": "Show cards with any of the chosen tags",
+  "@cardTagFilterNone": {
+    "description": "Screen 07 tag filter sheet: the sub-line with nothing chosen (OR, BR-TAG-004)."
+  },
+  "cardTagFilterChosen": "{count} chosen · cards with any of them",
+  "@cardTagFilterChosen": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 07 tag filter sheet: the sub-line with tags chosen."
+  },
+  "cardTagFilterSearchHint": "Search tags",
+  "@cardTagFilterSearchHint": {
+    "description": "Screen 07 tag filter sheet: the search above 8 tags."
+  },
+  "cardTagFilterSearchClear": "Clear search",
+  "@cardTagFilterSearchClear": {
+    "description": "Screen 07 tag filter sheet: the search field's clear button label."
+  },
+  "cardTagFilterClear": "Clear",
+  "@cardTagFilterClear": {
+    "description": "Screen 07 tag filter sheet: empties the draft and stays open (A4)."
+  },
+  "cardTagFilterApply": "Apply",
+  "@cardTagFilterApply": {
+    "description": "Screen 07 tag filter sheet: applies the chosen tags and closes."
+  },
+  "cardTagFilterEmpty": "No tags yet. Add tags while creating or editing cards.",
+  "@cardTagFilterEmpty": {
+    "description": "Screen 07 tag filter sheet: the library has no tag."
+  },
+  "cardTagFilterClose": "Close",
+  "@cardTagFilterClose": {
+    "description": "Screen 07 tag filter sheet: closes the sheet when there is no tag."
+  },
+  "cardTagFilterLoadError": "Couldn't load tags",
+  "@cardTagFilterLoadError": {
+    "description": "Screen 07 tag filter sheet: the tag read failed."
+  },
+  "cardTagFilterEmptyTitle": "No cards with these tags",
+  "@cardTagFilterEmptyTitle": {
+    "description": "Screen 07: the tag filter matches no card (UC-TAG-001 A7)."
+  },
+  "cardClearTagFilter": "Clear tag filter",
+  "@cardClearTagFilter": {
+    "description": "Screen 07: removes the tag filter (A7)."
+  },
+  "cardTagFilterCount": "{count}",
+  "@cardTagFilterCount": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 07 tag filter sheet: the cards of this deck carrying a tag, 0 included (BE-B2 D3)."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 1bb1cbf..da9b3f0 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -1094,5 +1094,19 @@
   "tagsDeleteConfirm": "{count, plural, =0{Xoá tag} other{Gỡ khỏi {count} thẻ}}",
   "tagsRenameFailed": "Không đổi được tên tag. Chưa có gì thay đổi — hãy thử lại sau giây lát.",
   "tagsDeleteFailed": "Không xoá được tag. Chưa có gì thay đổi — hãy thử lại sau giây lát.",
-  "tagsGone": "“{tag}” không còn nữa — nó vừa bị xoá."
+  "tagsGone": "“{tag}” không còn nữa — nó vừa bị xoá.",
+  "cardFilterTags": "Tag",
+  "cardTagFilterTitle": "Lọc theo tag",
+  "cardTagFilterNone": "Hiện thẻ có bất kỳ tag nào được chọn",
+  "cardTagFilterChosen": "Đã chọn {count} · thẻ có bất kỳ tag nào",
+  "cardTagFilterSearchHint": "Tìm tag",
+  "cardTagFilterSearchClear": "Xoá tìm kiếm",
+  "cardTagFilterClear": "Bỏ chọn",
+  "cardTagFilterApply": "Áp dụng",
+  "cardTagFilterEmpty": "Chưa có tag nào. Hãy thêm tag khi tạo hoặc sửa thẻ.",
+  "cardTagFilterClose": "Đóng",
+  "cardTagFilterLoadError": "Không tải được tag",
+  "cardTagFilterEmptyTitle": "Không có thẻ nào mang các tag này",
+  "cardClearTagFilter": "Bỏ lọc tag",
+  "cardTagFilterCount": "{count}"
 }
```

`lib/features/card/domain/usecases/watch_card_tag_filter_use_case.dart`:

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 6: every tag of the library with the active cards of
/// [deckId] carrying it, 0 included, for the card list's tag filter (tag
/// management spec D3).
final class WatchCardTagFilterUseCase {
  const WatchCardTagFilterUseCase(this._tags);

  final TagRepository _tags;

  Stream<List<TagCount>> call({required String deckId}) =>
      _tags.watchTagCounts(deckId: deckId);
}
```

`lib/features/card/presentation/providers/card_list_provider.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/providers/card_list_provider.dart b/lib/features/card/presentation/providers/card_list_provider.dart
index 17f61c1..0a05657 100644
--- a/lib/features/card/presentation/providers/card_list_provider.dart
+++ b/lib/features/card/presentation/providers/card_list_provider.dart
@@ -1,13 +1,15 @@
 import 'package:memox/features/card/domain/models/card_list_query_model.dart';
 import 'package:memox/features/card/domain/models/card_list_view_model.dart';
 import 'package:memox/features/card/presentation/providers/watch_card_list_use_case_provider.dart';
+import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
 import 'package:riverpod_annotation/riverpod_annotation.dart';
 
 part 'card_list_provider.g.dart';
 
 /// A window of [deckId]'s cards and the filter counts (UC-CARD-001), again
 /// on every change and at each local midnight. The query arrives as
-/// primitives: `CardListQuery` has no `==`, and a family key needs one.
+/// primitives and a [CardTagFilter]: `CardListQuery` has no `==`, and a
+/// family key needs one.
 @riverpod
 Stream<CardListView> cardList(
   Ref ref, {
@@ -15,9 +17,15 @@ Stream<CardListView> cardList(
   required CardListFilter filter,
   required CardListSort sort,
   required String searchTerm,
+  required CardTagFilter tags,
   required int windowSize,
 }) => ref.watch(watchCardListUseCaseProvider)(
   deckId: deckId,
-  query: CardListQuery(filter: filter, sort: sort, searchTerm: searchTerm),
+  query: CardListQuery(
+    filter: filter,
+    sort: sort,
+    searchTerm: searchTerm,
+    tagIds: tags.ids,
+  ),
   windowSize: windowSize,
 );
```

`lib/features/card/presentation/providers/card_tag_filter_provider.dart`:

```dart
import 'package:memox/features/card/presentation/providers/watch_card_tag_filter_use_case_provider.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_tag_filter_provider.g.dart';

/// The tags the card list of [deckId] can filter by, each with its cards
/// in the deck, 0 included (UC-TAG-001 step 6; BE-B2 D3).
@riverpod
Stream<List<TagCount>> cardTagFilter(Ref ref, String deckId) =>
    ref.watch(watchCardTagFilterUseCaseProvider)(deckId: deckId);
```

`lib/features/card/presentation/providers/watch_card_tag_filter_use_case_provider.dart`:

```dart
import 'package:memox/features/card/domain/usecases/watch_card_tag_filter_use_case.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_tag_filter_use_case_provider.g.dart';

@riverpod
WatchCardTagFilterUseCase watchCardTagFilterUseCase(Ref ref) =>
    WatchCardTagFilterUseCase(ref.watch(tagRepositoryProvider));
```

`lib/features/card/presentation/states/card_list_request_state.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/states/card_list_request_state.dart b/lib/features/card/presentation/states/card_list_request_state.dart
index c9628df..b255ab4 100644
--- a/lib/features/card/presentation/states/card_list_request_state.dart
+++ b/lib/features/card/presentation/states/card_list_request_state.dart
@@ -1,3 +1,4 @@
+import 'package:flutter/foundation.dart';
 import 'package:memox/features/card/domain/models/card_list_query_model.dart';
 import 'package:riverpod_annotation/riverpod_annotation.dart';
 
@@ -7,27 +8,53 @@ part 'card_list_request_state.g.dart';
 /// (ruling P3-L5).
 const int cardListWindowStep = 50;
 
+/// The tags a card list is filtered by (UC-TAG-001 step 7), equal by value
+/// so the list's provider is found again: a family key needs `==`.
+@immutable
+final class CardTagFilter {
+  const CardTagFilter([this.ids = const {}]);
+
+  /// A card passes when it carries any of them; none lets every card
+  /// through (BR-TAG-004).
+  final Set<String> ids;
+
+  bool get isEmpty => ids.isEmpty;
+
+  @override
+  bool operator ==(Object other) =>
+      other is CardTagFilter && setEquals(other.ids, ids);
+
+  @override
+  int get hashCode => Object.hashAllUnordered(ids);
+}
+
 /// What the person asked a deck's card list for, and how far it has grown.
 final class CardListRequestState {
   const CardListRequestState({
     this.filter = CardListFilter.all,
     this.sort = CardListSort.newest,
     this.searchTerm = '',
+    this.tags = const CardTagFilter(),
     this.windowSize = cardListWindowStep,
   });
 
   final CardListFilter filter;
   final CardListSort sort;
   final String searchTerm;
+  final CardTagFilter tags;
   final int windowSize;
 
   /// The query the list, its counts and Select all share (BR-CARD-012).
-  CardListQuery get query =>
-      CardListQuery(filter: filter, sort: sort, searchTerm: searchTerm);
+  CardListQuery get query => CardListQuery(
+    filter: filter,
+    sort: sort,
+    searchTerm: searchTerm,
+    tagIds: tags.ids,
+  );
 }
 
 /// A deck's card list request, kept while its screen lives. A new filter,
-/// sort or term starts again from the first window.
+/// sort, term or tag set starts again from the first window.
 @riverpod
 class CardListRequest extends _$CardListRequest {
   @override
@@ -37,18 +64,21 @@ class CardListRequest extends _$CardListRequest {
     filter: filter,
     sort: state.sort,
     searchTerm: state.searchTerm,
+    tags: state.tags,
   );
 
   void sortBy(CardListSort sort) => state = CardListRequestState(
     filter: state.filter,
     sort: sort,
     searchTerm: state.searchTerm,
+    tags: state.tags,
   );
 
   void search(String term) => state = CardListRequestState(
     filter: state.filter,
     sort: state.sort,
     searchTerm: term,
+    tags: state.tags,
   );
 
   /// The list neared its end while more cards follow.
@@ -56,6 +86,15 @@ class CardListRequest extends _$CardListRequest {
     filter: state.filter,
     sort: state.sort,
     searchTerm: state.searchTerm,
+    tags: state.tags,
     windowSize: state.windowSize + cardListWindowStep,
   );
+
+  /// The tags applied from the filter sheet; none is no tag filter (A4).
+  void filterTags(Set<String> tagIds) => state = CardListRequestState(
+    filter: state.filter,
+    sort: state.sort,
+    searchTerm: state.searchTerm,
+    tags: CardTagFilter(tagIds),
+  );
 }
```

`lib/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/card/presentation/providers/card_tag_filter_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Picks the tags [deckId]'s card list shows (UC-TAG-001 steps 6-7; FE-B2
/// spec D3). Completes with the set to apply, or null when dismissed, which
/// keeps [applied] (A5).
Future<Set<String>?> showCardTagFilterSheet(
  BuildContext context, {
  required String deckId,
  required Set<String> applied,
}) => showMxBottomSheet<Set<String>>(
  context,
  builder: (_) => CardTagFilterSheetWidget(deckId: deckId, applied: applied),
);

/// Every tag with its cards in this deck, 0 included (BE-B2 D3), in the
/// catalog's order: a checked row never moves. A search heads the list once
/// there are more than eight; it never drops a chosen tag.
class CardTagFilterSheetWidget extends ConsumerStatefulWidget {
  const CardTagFilterSheetWidget({
    super.key,
    required this.deckId,
    required this.applied,
  });

  final String deckId;
  final Set<String> applied;

  @override
  ConsumerState<CardTagFilterSheetWidget> createState() =>
      _CardTagFilterSheetWidgetState();
}

class _CardTagFilterSheetWidgetState
    extends ConsumerState<CardTagFilterSheetWidget> {
  /// Above this many tags the sheet offers its search (shape brief §5).
  static const int _searchAbove = 8;
  static const int _skeletonRows = 3;

  final _search = TextEditingController();
  late final Set<String> _draft = {...widget.applied};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String tagId) => setState(() {
    if (!_draft.remove(tagId)) _draft.add(tagId);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tags = ref.watch(cardTagFilterProvider(widget.deckId));
    return switch (tags) {
      AsyncData(:final value) when value.isEmpty => _none(l10n),
      AsyncData(:final value) => _picker(l10n, value),
      AsyncError() => MxBottomSheet(
        child: MxErrorState(
          title: l10n.cardTagFilterLoadError,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(cardTagFilterProvider(widget.deckId)),
        ),
      ),
      _ => MxBottomSheet(
        header: _header(l10n, l10n.cardTagFilterNone),
        child: MxSkeletonList(
          semanticLabel: l10n.commonLoading,
          rows: _skeletonRows,
        ),
      ),
    };
  }

  Widget _header(AppLocalizations l10n, String subLine) {
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.micro,
        children: [
          Text(l10n.cardTagFilterTitle, style: styles.compactTitle),
          Text(subLine, style: styles.rowDescription),
        ],
      ),
    );
  }

  /// No tag in the library: where tags come from, and Close.
  Widget _none(AppLocalizations l10n) => MxBottomSheet(
    header: _header(l10n, l10n.cardTagFilterEmpty),
    footer: MxSheetActions.custom(
      isInSheet: true,
      children: [
        Expanded(
          child: MxButton(
            label: l10n.cardTagFilterClose,
            tone: MxButtonTone.outline,
            isBlock: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
    child: const SizedBox.shrink(),
  );

  Widget _picker(AppLocalizations l10n, List<TagCount> tags) {
    // A tag gone from the library leaves the draft too (FE-B2 spec D12).
    _draft.retainAll({for (final tag in tags) tag.id});
    final shown = tags.matching(_search.text);
    return MxBottomSheet(
      header: _header(
        l10n,
        _draft.isEmpty
            ? l10n.cardTagFilterNone
            : l10n.cardTagFilterChosen(_draft.length),
      ),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.cardTagFilterClear,
        onCancel: _draft.isEmpty ? null : () => setState(_draft.clear),
        confirmLabel: l10n.cardTagFilterApply,
        onConfirm: () => Navigator.of(context).pop({..._draft}),
      ),
      child: Column(
        children: [
          if (tags.length > _searchAbove)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.control,
              ),
              child: MxSearchField(
                controller: _search,
                hintText: l10n.cardTagFilterSearchHint,
                clearLabel: l10n.cardTagFilterSearchClear,
                onChanged: (_) => setState(() {}),
              ),
            ),
          for (final (index, tag) in shown.indexed)
            _TagRow(
              key: ValueKey(tag.id),
              tag: tag,
              isChecked: _draft.contains(tag.id),
              onTap: () => _toggle(tag.id),
              hasDivider: index < shown.length - 1,
            ),
        ],
      ),
    );
  }
}

/// One tag: the box, the name and its cards in this deck. The whole row is
/// the target and one checkbox node.
class _TagRow extends StatelessWidget {
  const _TagRow({
    super.key,
    required this.tag,
    required this.isChecked,
    required this.onTap,
    required this.hasDivider,
  });

  final TagCount tag;
  final bool isChecked;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      checked: isChecked,
      child: MxListRow(
        leading: MxSelectionCheckbox(isChecked: isChecked),
        title: tag.name,
        trailing: Text(
          context.l10n.cardTagFilterCount(tag.cardCount),
          style: context.textStyles.counter,
        ),
        onTap: onTap,
        hasDivider: hasDivider,
      ),
    ),
  );
}
```

`lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart b/lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart
index dff5391..82ed1e7 100644
--- a/lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart
@@ -45,10 +45,11 @@ class CardDeckAppBarWidget extends ConsumerStatefulWidget {
 }
 
 class _CardDeckAppBarWidgetState extends ConsumerState<CardDeckAppBarWidget> {
-  /// The last total "Select all" offered, and the filter and term it counts:
-  /// a larger window loads as a new list, and the count must not blink out
-  /// meanwhile.
-  ({CardListFilter filter, String term, int total})? _lastTotal;
+  /// The last total "Select all" offered, and the filter, term and tags it
+  /// counts: a larger window loads as a new list, and the count must not
+  /// blink out meanwhile.
+  ({CardListFilter filter, String term, CardTagFilter tags, int total})?
+  _lastTotal;
 
   String get _deckId => widget.view.deck.id;
 
@@ -83,6 +84,7 @@ class _CardDeckAppBarWidgetState extends ConsumerState<CardDeckAppBarWidget> {
         filter: request.filter,
         sort: request.sort,
         searchTerm: request.searchTerm,
+        tags: request.tags,
         windowSize: request.windowSize,
       ),
     );
@@ -91,6 +93,7 @@ class _CardDeckAppBarWidgetState extends ConsumerState<CardDeckAppBarWidget> {
       _lastTotal = (
         filter: request.filter,
         term: request.searchTerm,
+        tags: request.tags,
         total: counts.of(request.filter),
       );
     }
@@ -98,7 +101,8 @@ class _CardDeckAppBarWidgetState extends ConsumerState<CardDeckAppBarWidget> {
     final isSameSet =
         last != null &&
         last.filter == request.filter &&
-        last.term == request.searchTerm;
+        last.term == request.searchTerm &&
+        last.tags == request.tags;
     return isSameSet ? last.total : null;
   }
 
```

`lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart b/lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart
index e67f804..b1d4be5 100644
--- a/lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart
@@ -6,14 +6,16 @@ import 'package:memox/features/card/presentation/widgets/support/card_list_label
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_empty_state.dart';
 
-/// Why no row shows: a search or a filter with no hit. A deck left with no
-/// card is unset again (ruling E-L1), so it never reaches this section.
+/// Why no row shows: a search, the tags or a filter with no hit. A deck left
+/// with no card is unset again (ruling E-L1), so it never reaches this
+/// section.
 class CardListEmptyWidget extends StatelessWidget {
   const CardListEmptyWidget({
     super.key,
     required this.request,
     required this.total,
     required this.onShowAll,
+    required this.onClearTags,
     required this.onAddCard,
   });
 
@@ -22,6 +24,9 @@ class CardListEmptyWidget extends StatelessWidget {
   /// Every card of the deck, for the search's way back.
   final int total;
   final VoidCallback onShowAll;
+
+  /// Drops the tag filter (UC-TAG-001 A7).
+  final VoidCallback onClearTags;
   final VoidCallback onAddCard;
 
   @override
@@ -41,6 +46,16 @@ class CardListEmptyWidget extends StatelessWidget {
         isCompact: true,
       );
     }
+    if (!request.tags.isEmpty) {
+      return MxEmptyState(
+        icon: AppIcons.tag,
+        title: l10n.cardTagFilterEmptyTitle,
+        tone: MxEmptyStateTone.neutral,
+        isCompact: true,
+        actionLabel: l10n.cardClearTagFilter,
+        onAction: onClearTags,
+      );
+    }
     if (request.filter != CardListFilter.all) {
       return MxEmptyState(
         icon: AppIcons.filter,
```

`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
index 2be752b..80ca02a 100644
--- a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
@@ -254,6 +254,7 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
       filter: request.filter,
       sort: request.sort,
       searchTerm: request.searchTerm,
+      tags: request.tags,
       windowSize: request.windowSize,
     );
     final async = ref.watch(provider);
@@ -355,6 +356,7 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
           onStudy: widget.onStudy,
         ),
         CardListToolbarWidget(
+          deckId: widget.deckId,
           request: request,
           counts: view.counts,
           onFilter: _show,
@@ -377,6 +379,7 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
           request: request,
           total: view.statusCounts.total,
           onShowAll: () => _show(CardListFilter.all),
+          onClearTags: () => _request().filterTags(const {}),
           onAddCard: widget.onAddCard,
         )
       else
```

`lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart b/lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart
index b5c4c74..3357a07 100644
--- a/lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart
@@ -1,30 +1,73 @@
+import 'dart:async';
+
 import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/core/theme/foundations/app_spacing.dart';
 import 'package:memox/features/card/domain/models/card_list_query_model.dart';
 import 'package:memox/features/card/domain/models/card_list_view_model.dart';
 import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
+import 'package:memox/features/card/presentation/states/card_selection_state.dart';
+import 'package:memox/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart';
 import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
+import 'package:memox/features/tags/domain/models/tag_count_model.dart';
+import 'package:memox/features/card/presentation/providers/card_tag_filter_provider.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_filter_chip.dart';
 
-/// The four filters with their counts (screen 07). The search shows above
-/// them once the app bar asks for it; the sort sits in the header; the Tags
-/// filter waits under Coming soon (spec A4, amended).
-class CardListToolbarWidget extends StatelessWidget {
+/// The four filters with their counts, then Tags (screen 07). The search
+/// shows above them once the app bar asks for it; the sort sits in the
+/// header. Tags is selected while tags are applied (FE-B2 spec D14); its
+/// tap opens the sheet and never toggles.
+class CardListToolbarWidget extends ConsumerWidget {
   const CardListToolbarWidget({
     super.key,
+    required this.deckId,
     required this.request,
     required this.counts,
     required this.onFilter,
   });
 
+  final String deckId;
   final CardListRequestState request;
   final CardListCounts counts;
   final ValueChanged<CardListFilter> onFilter;
 
+  /// Applying tags shows other cards, so the selection goes (BR-TAG-005).
+  void _apply(WidgetRef ref, Set<String> tagIds) {
+    ref.read(cardListRequestProvider(deckId).notifier).filterTags(tagIds);
+    ref.read(cardSelectionProvider(deckId).notifier).clear();
+  }
+
+  Future<void> _openTags(BuildContext context, WidgetRef ref) async {
+    final tagIds = await showCardTagFilterSheet(
+      context,
+      deckId: deckId,
+      applied: request.tags.ids,
+    );
+    if (tagIds == null || !context.mounted) return;
+    _apply(ref, tagIds);
+  }
+
+  /// A tag deleted or merged away leaves the applied set (spec D12).
+  void _prune(WidgetRef ref, List<TagCount> tags) {
+    final applied = request.tags.ids;
+    final kept = {
+      for (final tag in tags)
+        if (applied.contains(tag.id)) tag.id,
+    };
+    if (kept.length == applied.length) return;
+    ref.read(cardListRequestProvider(deckId).notifier).filterTags(kept);
+  }
+
   @override
-  Widget build(BuildContext context) {
+  Widget build(BuildContext context, WidgetRef ref) {
     final l10n = context.l10n;
+    final applied = request.tags.ids.length;
+    ref.listen(
+      cardTagFilterProvider(deckId),
+      (_, next) => next.whenData((tags) => _prune(ref, tags)),
+    );
     return Padding(
       padding: const EdgeInsets.only(bottom: AppSpacing.control),
       // The chips never shrink or wrap, so their row scrolls.
@@ -40,6 +83,13 @@ class CardListToolbarWidget extends StatelessWidget {
                 isSelected: filter == request.filter,
                 onSelected: (_) => onFilter(filter),
               ),
+            MxFilterChip(
+              label: l10n.cardFilterTags,
+              icon: AppIcons.tag,
+              count: applied == 0 ? null : applied,
+              isSelected: applied > 0,
+              onSelected: (_) => unawaited(_openTags(context, ref)),
+            ),
           ],
         ),
       ),
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
TZ=UTC flutter test --tags golden --update-goldens test/features/card/presentation/card_tag_filter_golden_test.dart test/features/card/presentation/card_list_golden_test.dart
flutter test test/features/card test/architecture
flutter analyze
```

Expected: PASS, 9 tests in `card_tag_filter_test.dart`, and the architecture check clean
(`card` reaches `tags` through `di/` and the domain model only). Ten new goldens, the
states the kit lacks: `card_tag_filter_{none,one,several,applied,no_card}_*`, to check
against the shape brief (D3): the sub-line, the counts with a 0, Clear off with nothing
chosen, "Tags 2" selected, and "No cards with these tags" with "Clear tag filter". Six
goldens change: `card_list_*`, `card_list_search_*` and the trash-toast frames of
`card_list_golden_test.dart` gain the Tags chip; compare `card_list_light.png` with kit
07's `loaded-light.png`.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/features/card/domain/usecases/watch_card_tag_filter_use_case.dart \
  lib/features/card/presentation/providers/card_list_provider.dart \
  lib/features/card/presentation/providers/card_tag_filter_provider.dart \
  lib/features/card/presentation/providers/watch_card_tag_filter_use_case_provider.dart \
  lib/features/card/presentation/states/card_list_request_state.dart \
  lib/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart \
  lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart \
  lib/features/card/presentation/widgets/sections/card_list_empty_widget.dart \
  lib/features/card/presentation/widgets/sections/card_list_section_widget.dart \
  lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart \
  test/features/card/presentation/card_list_section_test.dart \
  test/features/card/presentation/card_list_state_test.dart \
  test/features/card/presentation/card_tag_filter_golden_test.dart \
  test/features/card/presentation/card_tag_filter_test.dart \
  test/features/card/presentation/goldens/card_list_dark.png \
  test/features/card/presentation/goldens/card_list_light.png \
  test/features/card/presentation/goldens/card_list_search_dark.png \
  test/features/card/presentation/goldens/card_list_search_light.png \
  test/features/card/presentation/goldens/card_list_trashed_dark.png \
  test/features/card/presentation/goldens/card_list_trashed_light.png \
  test/features/card/presentation/goldens/card_tag_filter_applied_dark.png \
  test/features/card/presentation/goldens/card_tag_filter_applied_light.png \
  test/features/card/presentation/goldens/card_tag_filter_no_card_dark.png \
  test/features/card/presentation/goldens/card_tag_filter_no_card_light.png \
  test/features/card/presentation/goldens/card_tag_filter_none_dark.png \
  test/features/card/presentation/goldens/card_tag_filter_none_light.png \
  test/features/card/presentation/goldens/card_tag_filter_one_dark.png \
  test/features/card/presentation/goldens/card_tag_filter_one_light.png \
  test/features/card/presentation/goldens/card_tag_filter_several_dark.png \
  test/features/card/presentation/goldens/card_tag_filter_several_light.png
git commit -m "$(cat <<'EOF'
feat(card): the tag filter of screen 07 (FE-B2 D3, D14; UC-TAG-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 6: Screen 01, the routes to 03 and 05, and the search's initial query (D2, D5, D11)

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Delete: `lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart`
- Modify: `lib/features/search/presentation/screens/library_search_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/app/goldens/app_library_dark.png`
- Modify: `test/app/goldens/app_library_light.png`
- Delete: `test/features/deck/presentation/goldens/library_coming_soon_dark.png`
- Delete: `test/features/deck/presentation/goldens/library_coming_soon_light.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_2x_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_2x_light.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_light.png`
- Modify: `test/features/deck/presentation/goldens/library_empty_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_empty_light.png`
- Test (create): `test/app/starter_tags_routes_test.dart`
- Test (modify): `test/features/deck/presentation/deck_level_screen_test.dart`
- Test (modify): `test/features/deck/presentation/deck_screens_golden_test.dart`
- Test (modify): `test/features/search/presentation/library_search_screen_test.dart`
- Test (modify): `test/support/library_harness.dart`

**Interfaces:**
- Consumes: Task 2's `StarterLibraryScreen`, Task 4's `TagsScreen`,
  `showCreateRootDeckDialog`.
- Produces:
  - `DeckLevelScreen({…, required VoidCallback onOpenStarterDecks, required VoidCallback
    onOpenTags, …})`, passed to `DeckLibraryRootWidget`;
  - `AppRoutes.starterDecksChild`/`starterDecks` (`/decks/starter`),
    `tagsChild`/`tags` (`/decks/tags`), `searchQueryParam` (`q`) and
    `searchFor(String term)`;
  - `LibrarySearchScreen({…, String initialQuery = ''})`;
  - `pumpMemoxApp(…, {List<Override> overrides = const []})` and `deckScreen(…,
    {onOpenStarterDecks, onOpenTags})` in the harness;
  - `libraryBrowseStarterDecks`; the Coming soon sheet and its six keys removed (C15).

- [ ] **Step 1: Write the failing tests**

`test/app/starter_tags_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/starter_screen_fixtures.dart';
import '../support/tag_fixtures.dart';

// The routes around Starter decks and Tags (FE-B2 + FE-B4 spec D2, D5,
// D11, §5.1).

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Korean › Words with bap, tagged "food".
Future<void> _seed(LibraryEnv env) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap');
  await insertTag(env.db, 't-food', 'food', cardIds: ['c0']);
}

void main() {
  libraryTest('the Library app bar opens Starter decks and Tags above the '
      'shell; Back returns (D2, D5)', (tester, env) async {
    await _seed(env);
    final library = StarterLibraryFake(env);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await _tap(tester, find.byTooltip(_en.libraryStarterDecks));
    expect(_barTitle(_en.starterTitle), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.libraryTags));
    expect(_barTitle(_en.tagsTitle), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    expect(find.text('food'), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest('an empty Library browses starter decks; Open lands on the '
      'new deck in the Library (§5.1)', (tester, env) async {
    final library = StarterLibraryFake(env);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await _tap(tester, find.text(_en.libraryBrowseStarterDecks));
    await _tap(
      tester,
      find.widgetWithText(MxButton, _en.starterAddToLibrary).last,
    );
    await _tap(tester, find.text(_en.starterAddDeck));
    await _tap(tester, find.text(_en.starterOpen));

    expect(_barTitle(hangulTemplate.title), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(find.text(hangulTemplate.title), findsOneWidget);
  });

  libraryTest('a build without templates sends "Create a deck" back to the '
      "Library's create dialog", (tester, env) async {
    final library = StarterLibraryFake(env, templates: const []);
    await pumpMemoxApp(tester, env, overrides: [library.asOverride]);

    await _tap(tester, find.text(_en.libraryBrowseStarterDecks));
    await _tap(tester, find.text(_en.starterCreateDeck));

    expect(find.byType(MxDialog), findsOneWidget);
    await _tap(tester, find.text(_en.commonCancel));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('Find cards with this tag opens the Library search on its '
      'name; Back returns to the Library (D11)', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.byTooltip(_en.libraryTags));
    await _tap(tester, find.byTooltip(_en.tagsRowActions('food')));
    await _tap(tester, find.text(_en.tagsFindCards));
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'food'), findsOneWidget);
    expect(find.text('bap · back'), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });
}
```

`test/features/deck/presentation/deck_level_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_level_screen_test.dart b/test/features/deck/presentation/deck_level_screen_test.dart
index 375e3fd..43528c5 100644
--- a/test/features/deck/presentation/deck_level_screen_test.dart
+++ b/test/features/deck/presentation/deck_level_screen_test.dart
@@ -5,7 +5,6 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/features/deck/domain/models/deck_level_model.dart';
 import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
 import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
-import 'package:memox/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
 import 'package:memox/shared/widgets/mx_badge.dart';
@@ -70,17 +69,6 @@ void main() {
     expect(find.byType(MxDialog), findsOneWidget);
   });
 
-  libraryTest('first run: only Create deck, the footnote below', (
-    tester,
-    env,
-  ) async {
-    await pumpLibraryScreen(tester, env, deckScreen());
-
-    // Features that wait are listed under Coming soon (spec A4, amended).
-    expect(find.byType(MxButton), findsOneWidget);
-    expect(find.text(_en.libraryEmptyFootnote), findsOneWidget);
-  });
-
   libraryTest('the due strip leads; each deck carries its due badge', (
     tester,
     env,
@@ -279,48 +267,67 @@ void main() {
     expect(find.text(_vi.libraryDecksCount(2).toUpperCase()), findsOneWidget);
   });
 
-  libraryTest('the root app bar holds Trash and Coming soon, which lists what '
-      'waits (FE-B1 D1)', (tester, env) async {
-    var trashOpened = 0;
+  libraryTest('the root app bar holds Starter decks, Tags and Trash, as '
+      'kit 01 draws it; nothing waits under Coming soon (spec D2)', (
+    tester,
+    env,
+  ) async {
+    final opened = <String>[];
     await pumpLibraryScreen(
       tester,
       env,
-      deckScreen(onOpenTrash: () => trashOpened++),
+      deckScreen(
+        onOpenStarterDecks: () => opened.add('starter'),
+        onOpenTags: () => opened.add('tags'),
+        onOpenTrash: () => opened.add('trash'),
+      ),
     );
-    await tester.tap(find.byTooltip(_en.libraryTrash));
-    expect(trashOpened, 1);
 
-    // Reorder moved to a row's sheet (ruling C-L4): Trash and Coming soon.
     expect(
-      find.descendant(
-        of: find.byType(MxAppBar),
-        matching: find.byType(MxIconButton),
-      ),
-      findsNWidgets(2),
+      [
+        for (final button in tester.widgetList<MxIconButton>(
+          find.descendant(
+            of: find.byType(MxAppBar),
+            matching: find.byType(MxIconButton),
+          ),
+        ))
+          button.semanticLabel,
+      ],
+      [_en.libraryStarterDecks, _en.libraryTags, _en.libraryTrash],
     );
-    await tester.tap(find.byTooltip(_en.libraryComingSoon));
-    await tester.pumpAndSettle();
-
-    expect(find.text(_en.libraryComingSoonBody), findsOneWidget);
-    for (final feature in [
+    for (final label in [
       _en.libraryStarterDecks,
       _en.libraryTags,
-      _en.comingSoonProgressSort,
+      _en.libraryTrash,
     ]) {
-      expect(find.text(feature), findsOneWidget, reason: feature);
+      await tester.tap(find.byTooltip(label));
     }
-    // Study options shipped (FE-A3 D3): it no longer waits here.
-    expect(find.text(_en.deckStudyOptions), findsNothing);
-    // Import and export shipped (FE-B3): neither waits here any more.
-    expect(find.text(_en.deckActionExport), findsNothing);
-    // Study is live (FE-A6 D10).
+    expect(opened, ['starter', 'tags', 'trash']);
+  });
+
+  libraryTest('rootEmpty offers a starter deck beside Create deck (spec '
+      '§5.4)', (tester, env) async {
+    var starters = 0;
+    await pumpLibraryScreen(
+      tester,
+      env,
+      deckScreen(onOpenStarterDecks: () => starters++),
+    );
+
+    expect(find.text(_en.libraryEmptyBody), findsOneWidget);
     expect(
-      find.descendant(
-        of: find.byType(DeckComingSoonSheetWidget),
-        matching: find.text(_en.studyThisDeck),
-      ),
-      findsNothing,
+      [
+        for (final button in tester.widgetList<MxButton>(find.byType(MxButton)))
+          (button.label, button.tone),
+      ],
+      [
+        (_en.libraryCreateDeck, MxButtonTone.primary),
+        (_en.libraryBrowseStarterDecks, MxButtonTone.secondary),
+      ],
     );
+    expect(find.text(_en.libraryEmptyFootnote), findsOneWidget);
+    await tester.tap(find.text(_en.libraryBrowseStarterDecks));
+    expect(starters, 1);
   });
 
   libraryTest('the search field opens the search', (tester, env) async {
```

`test/features/deck/presentation/deck_screens_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_screens_golden_test.dart b/test/features/deck/presentation/deck_screens_golden_test.dart
index 627eed2..aa8d6c6 100644
--- a/test/features/deck/presentation/deck_screens_golden_test.dart
+++ b/test/features/deck/presentation/deck_screens_golden_test.dart
@@ -179,19 +179,5 @@ void main() {
         );
       });
     });
-
-    libraryTest('Coming soon sheet, $theme', (tester, env) async {
-      await _seed(env);
-      await withRealShadows(() async {
-        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
-        await tester.pumpAndSettle();
-        await tester.tap(find.byTooltip(_en.libraryComingSoon));
-        await _settleOverlay(tester);
-        await expectBoundaryGolden(
-          tester,
-          'goldens/library_coming_soon_$theme.png',
-        );
-      });
-    });
   }
 }
```

`test/features/search/presentation/library_search_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/search/presentation/library_search_screen_test.dart b/test/features/search/presentation/library_search_screen_test.dart
index c60a2dc..6dcb035 100644
--- a/test/features/search/presentation/library_search_screen_test.dart
+++ b/test/features/search/presentation/library_search_screen_test.dart
@@ -97,6 +97,29 @@ void main() {
     expect(tester.testTextInput.hasAnyClients, isTrue);
   });
 
+  libraryTest('a term given on arrival is typed and searched, as Find cards '
+      'with this tag opens it (FE-B2 spec D11)', (tester, env) async {
+    final korean = await env.decks.root('Korean');
+    await insertCard(env.db, id: 'hw', deckId: korean.id, front: 'homework');
+    await TagRepositoryImpl(env.db).attachByName(cardIds: {'hw'}, name: 'Học');
+    await pumpLibraryScreen(
+      tester,
+      env,
+      LibrarySearchScreen(
+        initialQuery: 'Học',
+        onOpenDeck: (_) {},
+        onOpenCard: (_) {},
+      ),
+    );
+    await tester.pump(searchDebounce);
+    await tester.pump();
+    await tester.pump();
+
+    expect(find.widgetWithText(MxSearchField, 'Học'), findsOneWidget);
+    expect(find.byType(SearchCardHitRowWidget), findsOneWidget);
+    expect(find.widgetWithText(MxTagChip, 'Học'), findsOneWidget);
+  });
+
   libraryTest('before a term it says what search finds (step 2)', (
     tester,
     env,
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
index 9bd0910..24ea28d 100644
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -214,6 +214,8 @@ DeckLevelScreen deckScreen({
   ValueChanged<String>? onOpenStudy,
   ValueChanged<String>? onOpenStudyOptions,
   VoidCallback? onOpenTrash,
+  VoidCallback? onOpenStarterDecks,
+  VoidCallback? onOpenTags,
 }) => DeckLevelScreen(
   deckId: deckId,
   onOpenDeck: onOpenDeck ?? (_) {},
@@ -226,6 +228,8 @@ DeckLevelScreen deckScreen({
   onImportCards: onImportCards ?? (_) {},
   onExportCards: onExportCards ?? (_) {},
   onOpenTrash: onOpenTrash ?? () {},
+  onOpenStarterDecks: onOpenStarterDecks ?? () {},
+  onOpenTags: onOpenTags ?? () {},
   cardContent: cardContent ?? (_) => const SizedBox.shrink(),
   cardAppBar:
       cardAppBar ??
@@ -274,13 +278,14 @@ Future<void> pumpMemoxApp(
   LibraryEnv env, {
   AppSettingsEntity? initialSettings,
   bool isSettled = true,
+  List<Override> overrides = const [],
 }) async {
   tester.view.physicalSize = const Size(1080, 2400);
   tester.view.devicePixelRatio = 3;
   addTearDown(tester.view.reset);
   await tester.pumpWidget(
     ProviderScope(
-      overrides: _backend(env),
+      overrides: [..._backend(env), ...overrides],
       retry: _noRetry,
       child: MemoxApp(initialSettings: initialSettings),
     ),
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/app/starter_tags_routes_test.dart test/features/deck/presentation/deck_level_screen_test.dart test/features/search/presentation/library_search_screen_test.dart
```

Expected: FAIL to compile: `DeckLevelScreen` has no `onOpenStarterDecks`, and
`LibrarySearchScreen` no `initialQuery`.

- [ ] **Step 3: Implement**

The copy: apply the ARB diffs, then the code. Delete the Coming soon sheet and its two
goldens with `git rm`.

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index c4e12c2..fe4a184 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -56,10 +56,14 @@
   "@libraryEmptyTitle": {
     "description": "First-run empty state title: the Library has no deck."
   },
-  "libraryEmptyBody": "A deck groups the sub-decks that hold your cards. Create one to begin.",
+  "libraryEmptyBody": "A deck groups the sub-decks that hold your cards. Create one, or copy a starter deck to begin with content.",
   "@libraryEmptyBody": {
     "description": "First-run empty state body."
   },
+  "libraryBrowseStarterDecks": "Browse starter decks",
+  "@libraryBrowseStarterDecks": {
+    "description": "Library root empty state: opens Starter decks (screen 03; FE-B4 spec §5.4)."
+  },
   "libraryNothingDueTitle": "Nothing due right now",
   "@libraryNothingDueTitle": {
     "description": "Empty state when the due filter leaves no deck."
@@ -2298,30 +2302,6 @@
     },
     "description": "Screen handoff 02 (library alignment phase D): resetDoneToast."
   },
-  "libraryComingSoon": "Coming soon",
-  "@libraryComingSoon": {
-    "description": "Library app bar action and sheet title: features that arrive later (spec A4, amended)."
-  },
-  "libraryComingSoonBody": "These arrive in a later version. Everything you add now is kept.",
-  "@libraryComingSoonBody": {
-    "description": "Coming soon sheet: the line under its title."
-  },
-  "comingSoonStarterDecksBody": "Ready-made decks to copy.",
-  "@comingSoonStarterDecksBody": {
-    "description": "Coming soon: what starter decks do."
-  },
-  "comingSoonTagsBody": "Label cards, filter by label.",
-  "@comingSoonTagsBody": {
-    "description": "Coming soon: what tags do."
-  },
-  "comingSoonProgressSort": "Sort by progress",
-  "@comingSoonProgressSort": {
-    "description": "Coming soon: the progress sort's name."
-  },
-  "comingSoonProgressSortBody": "Least mastered decks first.",
-  "@comingSoonProgressSortBody": {
-    "description": "Coming soon: what the progress sort does."
-  },
   "cardDeckProgress": "Deck progress · {algorithm}",
   "@cardDeckProgress": {
     "placeholders": {
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index da9b3f0..88c512b 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -14,7 +14,8 @@
   "commonLoading": "Đang tải",
   "libraryCreateDeck": "Tạo bộ thẻ",
   "libraryEmptyTitle": "Bắt đầu thư viện của bạn",
-  "libraryEmptyBody": "Một bộ thẻ gom các bộ thẻ con chứa thẻ của bạn. Hãy tạo một bộ để bắt đầu.",
+  "libraryEmptyBody": "Một bộ thẻ gom các bộ thẻ con chứa thẻ của bạn. Hãy tạo một bộ, hoặc sao chép một bộ thẻ mẫu để bắt đầu với nội dung có sẵn.",
+  "libraryBrowseStarterDecks": "Xem bộ thẻ mẫu",
   "libraryNothingDueTitle": "Hiện không có gì đến hạn",
   "libraryNothingDueBody": "Không bộ thẻ nào có thẻ đang chờ.",
   "libraryShowAllDecks": "Hiện mọi bộ thẻ",
@@ -422,12 +423,6 @@
   "resetConfirm": "Đặt lại và bắt đầu chu kỳ {cycle}",
   "resetRunning": "Đang đặt lại…",
   "resetDoneToast": "Đã bắt đầu chu kỳ {cycle} · {count} thẻ trở lại thẻ mới",
-  "libraryComingSoon": "Sắp có",
-  "libraryComingSoonBody": "Những tính năng này sẽ có ở phiên bản sau. Mọi thứ bạn thêm bây giờ đều được giữ.",
-  "comingSoonStarterDecksBody": "Bộ thẻ có sẵn để sao chép.",
-  "comingSoonTagsBody": "Gắn nhãn thẻ, lọc theo nhãn.",
-  "comingSoonProgressSort": "Sắp xếp theo độ thuộc",
-  "comingSoonProgressSortBody": "Bộ thẻ thuộc ít nhất lên trước.",
   "cardDeckProgress": "Tiến độ bộ thẻ · {algorithm}",
   "cardMasteredOf": "{mastered}/{total} thẻ đã thuộc",
   "cardShowingOf": "Đang hiện {shown}/{total}",
```

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index 31f5441..5d8c1c6 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -16,6 +16,7 @@ import 'package:memox/features/card/presentation/widgets/sections/card_list_sect
 import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
 import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
 import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
+import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
 import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
 import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
 import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
@@ -23,6 +24,8 @@ import 'package:memox/features/settings/presentation/screens/language_screen.dar
 import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
 import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
 import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
+import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
+import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
 import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
@@ -116,9 +119,30 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                     parentNavigatorKey: rootNavigator,
                     builder: (context, state) => const TrashScreen(),
                   ),
+                  GoRoute(
+                    path: AppRoutes.starterDecksChild,
+                    parentNavigatorKey: rootNavigator,
+                    builder: (context, state) =>
+                        _starterDecks(context, rootNavigator),
+                  ),
+                  GoRoute(
+                    path: AppRoutes.tagsChild,
+                    parentNavigatorKey: rootNavigator,
+                    // The search lives in the Library branch, under the
+                    // shell: Find cards goes there, and Back returns to the
+                    // Library (plan C-ruling on D11).
+                    builder: (context, state) => TagsScreen(
+                      onFindCards: (name) =>
+                          context.go(AppRoutes.searchFor(name)),
+                    ),
+                  ),
                   GoRoute(
                     path: AppRoutes.searchChild,
                     builder: (context, state) => LibrarySearchScreen(
+                      initialQuery:
+                          state.uri.queryParameters[AppRoutes
+                              .searchQueryParam] ??
+                          '',
                       onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
                       onOpenCard: (id) => context.push(AppRoutes.card(id)),
                     ),
@@ -264,6 +288,8 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
       showDeckExportSheet(context, deckId: deck.id, deckName: deck.name),
     ),
     onOpenTrash: openTrash,
+    onOpenStarterDecks: _opener(context, AppRoutes.starterDecks),
+    onOpenTags: _opener(context, AppRoutes.tags),
     cardAppBar: (view, back, actions) =>
         CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
     cardBreadcrumb: (id, child) =>
@@ -317,11 +343,33 @@ StudyOptionsScreen _studyOptions(BuildContext context, String deckId) =>
       ),
     );
 
-/// Opens the Trash on the root navigator (FE-B1 D2). The router pushes it,
-/// not the page's context: a toast's action can outlive its page.
-VoidCallback _openTrash(BuildContext context) {
+/// Opens the Trash on the root navigator (FE-B1 D2).
+VoidCallback _openTrash(BuildContext context) =>
+    _opener(context, AppRoutes.trash);
+
+/// Pushes [location]. The router pushes it, not the page's context: a
+/// toast's action can outlive its page.
+VoidCallback _opener(BuildContext context, String location) {
+  final router = GoRouter.of(context);
+  return () => unawaited(router.push(location));
+}
+
+/// Screen 03 (FE-B4). Open goes to the new copy's root in the Library, and
+/// "Create a deck" returns to the Library and opens its create dialog
+/// (spec §5.1).
+StarterLibraryScreen _starterDecks(
+  BuildContext context,
+  GlobalKey<NavigatorState> rootNavigator,
+) {
   final router = GoRouter.of(context);
-  return () => unawaited(router.push(AppRoutes.trash));
+  return StarterLibraryScreen(
+    onOpenDeck: (id) => router.go(AppRoutes.deck(id)),
+    onCreateDeck: () {
+      router.pop();
+      final host = rootNavigator.currentState?.overlay?.context;
+      if (host != null) unawaited(showCreateRootDeckDialog(host));
+    },
+  );
 }
 
 /// Opens the editor over the card detail. The editor closes with true when
```

`lib/app/router/app_routes.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_routes.dart b/lib/app/router/app_routes.dart
index 3766182..0d156b2 100644
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -34,11 +34,28 @@ abstract final class AppRoutes {
 
   static const String deckSearch = '$decks/$searchChild';
 
+  /// The search's term on arrival, as a query parameter (FE-B2 spec D11).
+  static const String searchQueryParam = 'q';
+
+  /// The search, opened on [term].
+  static String searchFor(String term) => Uri(
+    path: deckSearch,
+    queryParameters: {searchQueryParam: term},
+  ).toString();
+
   /// The Trash (screen 06), relative to [decks]: a full-screen task on the
   /// root navigator (FE-B1 D2).
   static const String trashChild = 'trash';
   static const String trash = '$decks/$trashChild';
 
+  /// Starter decks (screen 03) and Tags (screen 05), relative to [decks]:
+  /// full-screen pages on the root navigator, as the kit draws them and as
+  /// the Trash is (FE-B2 + FE-B4 spec D5).
+  static const String starterDecksChild = 'starter';
+  static const String starterDecks = '$decks/$starterDecksChild';
+  static const String tagsChild = 'tags';
+  static const String tags = '$decks/$tagsChild';
+
   /// A root deck's review algorithm (screen 02), relative to [deckChild].
   static const String algorithmChild = 'algorithm';
 
```

`lib/features/deck/presentation/screens/deck_level_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/screens/deck_level_screen.dart b/lib/features/deck/presentation/screens/deck_level_screen.dart
index acac948..dfecdf5 100644
--- a/lib/features/deck/presentation/screens/deck_level_screen.dart
+++ b/lib/features/deck/presentation/screens/deck_level_screen.dart
@@ -47,6 +47,8 @@ class DeckLevelScreen extends StatelessWidget {
     required this.onImportCards,
     required this.onExportCards,
     required this.onOpenTrash,
+    required this.onOpenStarterDecks,
+    required this.onOpenTags,
     required this.cardFab,
   });
 
@@ -95,6 +97,13 @@ class DeckLevelScreen extends StatelessWidget {
   /// refused Undo (FE-B1).
   final VoidCallback onOpenTrash;
 
+  /// Opens Starter decks (screen 03): the Library's app bar and its empty
+  /// state (FE-B4 spec D2).
+  final VoidCallback onOpenStarterDecks;
+
+  /// Opens Tags (screen 05) from the Library's app bar (FE-B2 spec D2).
+  final VoidCallback onOpenTags;
+
   /// A deck of cards' FAB, from the card feature like [cardContent] (spec
   /// D8). It hides itself while cards are selected.
   final Widget Function(String deckId) cardFab;
@@ -108,6 +117,8 @@ class DeckLevelScreen extends StatelessWidget {
       onOpenStudy: onOpenStudy,
       onOpenStudyOptions: onOpenStudyOptions,
       onOpenTrash: onOpenTrash,
+      onOpenStarterDecks: onOpenStarterDecks,
+      onOpenTags: onOpenTags,
     ),
     final id => _OpenDeck(
       deckId: id,
```

`lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart`: delete it.

```bash
git rm lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
```

`lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
index d8728d2..02e7afb 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
@@ -8,7 +8,6 @@ import 'package:memox/features/deck/presentation/providers/deck_level_provider.d
 import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
 import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
 import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
-import 'package:memox/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_level_body_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_done_widget.dart';
 import 'package:memox/l10n/l10n_context.dart';
@@ -29,6 +28,8 @@ class DeckLibraryRootWidget extends ConsumerWidget {
     required this.onOpenStudy,
     required this.onOpenStudyOptions,
     required this.onOpenTrash,
+    required this.onOpenStarterDecks,
+    required this.onOpenTags,
   });
 
   final ValueChanged<String> onOpenDeck;
@@ -44,6 +45,13 @@ class DeckLibraryRootWidget extends ConsumerWidget {
   /// Opens the Trash (screen 06) from the app bar (FE-B1 D1).
   final VoidCallback onOpenTrash;
 
+  /// Opens Starter decks (screen 03) from the app bar and the empty
+  /// Library (FE-B4 spec D2, §5.4).
+  final VoidCallback onOpenStarterDecks;
+
+  /// Opens Tags (screen 05) from the app bar (FE-B2 spec D2).
+  final VoidCallback onOpenTags;
+
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final l10n = context.l10n;
@@ -70,18 +78,23 @@ class DeckLibraryRootWidget extends ConsumerWidget {
         title: l10n.navLibrary,
         actions: isReordering
             ? const [DeckReorderDoneWidget(parentId: null)]
-            // Features that wait are named in one place (spec A4, amended).
+            // Kit 01: Starter decks, Tags, Trash (spec D2).
             : [
+                MxIconButton(
+                  icon: AppIcons.starterDecks,
+                  semanticLabel: l10n.libraryStarterDecks,
+                  onPressed: onOpenStarterDecks,
+                ),
+                MxIconButton(
+                  icon: AppIcons.tag,
+                  semanticLabel: l10n.libraryTags,
+                  onPressed: onOpenTags,
+                ),
                 MxIconButton(
                   icon: AppIcons.delete,
                   semanticLabel: l10n.libraryTrash,
                   onPressed: onOpenTrash,
                 ),
-                MxIconButton(
-                  icon: AppIcons.upcoming,
-                  semanticLabel: l10n.libraryComingSoon,
-                  onPressed: () => unawaited(showDeckComingSoonSheet(context)),
-                ),
               ],
       ),
       fab: isReordering || !hasDecks
@@ -122,6 +135,8 @@ class DeckLibraryRootWidget extends ConsumerWidget {
                 body: l10n.libraryEmptyBody,
                 actionLabel: l10n.libraryCreateDeck,
                 onAction: createDeck,
+                secondaryActionLabel: l10n.libraryBrowseStarterDecks,
+                onSecondaryAction: onOpenStarterDecks,
                 footnote: l10n.libraryEmptyFootnote,
               ),
             ),
```

`lib/features/search/presentation/screens/library_search_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/search/presentation/screens/library_search_screen.dart b/lib/features/search/presentation/screens/library_search_screen.dart
index 03c1011..5c3a620 100644
--- a/lib/features/search/presentation/screens/library_search_screen.dart
+++ b/lib/features/search/presentation/screens/library_search_screen.dart
@@ -19,26 +19,33 @@ class LibrarySearchScreen extends ConsumerStatefulWidget {
     super.key,
     required this.onOpenDeck,
     required this.onOpenCard,
+    this.initialQuery = '',
   });
 
   final ValueChanged<String> onOpenDeck;
   final ValueChanged<String> onOpenCard;
 
+  /// A term searched on arrival, such as a tag's name from screen 05 (FE-B2
+  /// spec D11). Blank opens the search idle.
+  final String initialQuery;
+
   @override
   ConsumerState<LibrarySearchScreen> createState() =>
       _LibrarySearchScreenState();
 }
 
 class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
-  final _query = TextEditingController();
+  late final _query = TextEditingController(text: widget.initialQuery);
   final _focus = FocusNode();
 
   @override
   void initState() {
     super.initState();
-    // The person came here to type (step 1).
+    // The person came here to type (step 1), or with a term to search.
     WidgetsBinding.instance.addPostFrameCallback((_) {
-      if (mounted) _focus.requestFocus();
+      if (!mounted) return;
+      _focus.requestFocus();
+      if (widget.initialQuery.isNotEmpty) _search(widget.initialQuery);
     });
   }
 
```

`test/features/deck/presentation/goldens/library_coming_soon_dark.png`: delete it.

```bash
git rm test/features/deck/presentation/goldens/library_coming_soon_dark.png
```

`test/features/deck/presentation/goldens/library_coming_soon_light.png`: delete it.

```bash
git rm test/features/deck/presentation/goldens/library_coming_soon_light.png
```

- [ ] **Step 4: Generate, render the goldens, run the whole suite**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
TZ=UTC flutter test --tags golden --update-goldens test/features/deck/presentation test/app/app_golden_test.dart
flutter test
TZ=UTC flutter test --tags golden
flutter analyze
```

Expected: PASS. Eight goldens change: `library_empty_*` (compare with kit 01's
`rootEmpty-*`: the new body, "Create deck", "Browse starter decks", the footnote),
`library_decks_*`, `library_decks_2x_*` and `app_library_*` (the app bar's sparkles, tag
and trash); `library_coming_soon_*` are gone.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/app/router/app_router.dart \
  lib/app/router/app_routes.dart \
  lib/features/deck/presentation/screens/deck_level_screen.dart \
  lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart \
  lib/features/search/presentation/screens/library_search_screen.dart \
  test/app/starter_tags_routes_test.dart \
  test/features/deck/presentation/deck_level_screen_test.dart \
  test/features/deck/presentation/deck_screens_golden_test.dart \
  test/features/search/presentation/library_search_screen_test.dart \
  test/support/library_harness.dart \
  test/app/goldens/app_library_dark.png \
  test/app/goldens/app_library_light.png \
  test/features/deck/presentation/goldens/library_decks_2x_dark.png \
  test/features/deck/presentation/goldens/library_decks_2x_light.png \
  test/features/deck/presentation/goldens/library_decks_dark.png \
  test/features/deck/presentation/goldens/library_decks_light.png \
  test/features/deck/presentation/goldens/library_empty_dark.png \
  test/features/deck/presentation/goldens/library_empty_light.png
git commit -m "$(cat <<'EOF'
feat(library): screen 01 opens Starter decks and Tags; the routes; Coming soon goes (FE-B2 + FE-B4 D2, D5, D11)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 7: Detail files 03 and 05, 01 and 07, index, checklist, register, ui.md, use cases, WBS; the gate

**Files:**
- Modify: `docs/features/starter-decks/README.md`
- Modify: `docs/features/starter-decks/ui.md`
- Modify: `docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md`
- Modify: `docs/features/tags/README.md`
- Modify: `docs/features/tags/ui.md`
- Modify: `docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`
- Create: `docs/shared/ui/screen-handoff/03-starter-decks.md`
- Create: `docs/shared/ui/screen-handoff/05-tags.md`
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md`
- Modify: `docs/shared/ui/screen-state-checklist.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/_generated/traceability.md (generated)`
- Modify: `docs/_generated/open-questions.md (generated)`

**Interfaces:** none (documents). The kit's captures of screens 03 and 05 and their
entries in `tools/design/screen_states.json` are already on the branch (with the spec).

- [ ] **Step 1: Update the documents**

`docs/features/starter-decks/README.md` (apply this diff):

```diff
diff --git a/docs/features/starter-decks/README.md b/docs/features/starter-decks/README.md
index 81235d2..e8ed1e9 100644
--- a/docs/features/starter-decks/README.md
+++ b/docs/features/starter-decks/README.md
@@ -1,12 +1,12 @@
 ---
 feature: starter-decks
-code: [lib/features/starter_decks/domain, lib/features/starter_decks/data, lib/features/starter_decks/di]
+code: [lib/features/starter_decks/domain, lib/features/starter_decks/data, lib/features/starter_decks/di, lib/features/starter_decks/presentation]
 depends_on: [card, deck]
 ---
 ## Phạm vi
 
 **Phạm vi:** Starter library, phần store (BE-B4,
-[spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn 03 thuộc FE-B4.
+[spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn 03 thuộc FE-B4: [ui.md](ui.md).
 
 Starter deck / template: thư viện starter và sao chép một template vào dữ liệu cá nhân.
 Template là asset JSON đi kèm bản build (xem [`data.md`](data.md)); bản sao được ghi bởi
```

`docs/features/starter-decks/ui.md` (apply this diff):

```diff
diff --git a/docs/features/starter-decks/ui.md b/docs/features/starter-decks/ui.md
index 72da770..4f694fd 100644
--- a/docs/features/starter-decks/ui.md
+++ b/docs/features/starter-decks/ui.md
@@ -2,6 +2,17 @@
 
 Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.
 
+## Màn hình và điều hướng
+
+| Màn | Route | Mở từ | Handoff |
+|---|---|---|---|
+| 03 · Starter decks | `/decks/starter`, toàn màn hình trên root navigator, không có bottom bar | Hành động Starter decks trên app bar của Thư viện; "Browse starter decks" khi Thư viện trống | [03-starter-decks.md](../../shared/ui/screen-handoff/03-starter-decks.md) |
+
+Open trên toast "Added" đi tới deck gốc mới trong Thư viện; "Create a deck" (bản build
+không có template) quay về Thư viện và mở hộp thoại tạo deck. Nguồn: [spec FE-B2 +
+FE-B4](../../superpowers/specs/2026-09-27-tags-starter-ui-design.md) §3 (D5, D6, D7),
+§5.1.
+
 ## Edge case chưa gắn BR
 
 | Case | Expected behaviour |
```

`docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md` (apply this diff):

```diff
diff --git a/docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md b/docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md
index e4f4fde..5adfe43 100644
--- a/docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md
+++ b/docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md
@@ -3,7 +3,7 @@ id: UC-STARTER-001
 title: Khởi động lần đầu và chọn starter deck
 status: ready
 rules: [BR-CARD-004, BR-DECK-002, BR-STARTER-001, BR-STARTER-002, BR-STARTER-003, BR-STARTER-004, BR-STARTER-005, BR-STARTER-006, BR-STARTER-007, BR-STARTER-008, BR-STARTER-009, BR-STARTER-010, BR-STUDY-077]
-code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart, lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart]
+code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart, lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart, lib/features/starter_decks/presentation/screens/starter_library_screen.dart, lib/features/starter_decks/presentation/controllers/starter_add_controller.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/features/tags/README.md` (apply this diff):

```diff
diff --git a/docs/features/tags/README.md b/docs/features/tags/README.md
index 2a2bdc3..04d42cb 100644
--- a/docs/features/tags/README.md
+++ b/docs/features/tags/README.md
@@ -1,12 +1,13 @@
 ---
 feature: tags
-code: [lib/features/tags/domain, lib/features/tags/data, lib/features/tags/di]
+code: [lib/features/tags/domain, lib/features/tags/data, lib/features/tags/di, lib/features/tags/presentation]
 depends_on: [card]
 ---
 ## Phạm vi
 
 **Phạm vi:** Tag Management, phần store (BE-B2,
-[spec](../../superpowers/specs/2026-09-26-tag-management-backend-design.md)).
+[spec](../../superpowers/specs/2026-09-26-tag-management-backend-design.md)) và màn 05 cùng
+bộ lọc tag của card list (FE-B2): [ui.md](ui.md).
 
 Mô hình dữ liệu tag (BR-TAG-001, BR-TAG-002) và Tag Management v1: catalog, lọc theo tag, đổi tên/gộp, xoá.
 
@@ -30,4 +31,3 @@ Nguồn: trigger của UC-TAG-001.
 | Thứ | Vì sao |
 |---|---|
 | Tag phân cấp, màu tag, taxonomy chia sẻ | Ngoài phạm vi Tag Management v1 — UC-TAG-001 chốt tag là nhãn phẳng, là định danh văn bản, không phải hệ thống deck thứ hai |
-| Màn catalog (màn 05), overlay lọc của card list, hành động `Tags` trên app bar của Library | FE-B2 ([`wbs_FE.md`](../../wbs_FE.md)) |
```

`docs/features/tags/ui.md` (apply this diff):

```diff
diff --git a/docs/features/tags/ui.md b/docs/features/tags/ui.md
index 2e3accf..fa84d35 100644
--- a/docs/features/tags/ui.md
+++ b/docs/features/tags/ui.md
@@ -2,6 +2,19 @@
 
 Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.
 
+## Màn hình và điều hướng
+
+| Màn | Route | Mở từ | Handoff |
+|---|---|---|---|
+| 05 · Tags | `/decks/tags`, toàn màn hình trên root navigator, không có bottom bar | Hành động Tags trên app bar của Thư viện | [05-tags.md](../../shared/ui/screen-handoff/05-tags.md) |
+| 07 · Overlay lọc theo tag | Bottom sheet trên card list | Chip Tags trên thanh filter của card list | [07-card-list.md](../../shared/ui/screen-handoff/07-card-list.md) |
+
+"Find cards with this tag" mở tìm kiếm thư viện với tên tag; tìm kiếm nằm trong nhánh
+Thư viện nên Back về Thư viện. Đổi tên chạy `PlanTagRenameUseCase` sau khi tên dừng 250
+ms, xác nhận gộp bằng `mergeIntoTagId`; gặp `mergeNotConfirmed` thì mở lại hộp thoại với
+tên đã gõ. Nguồn: [spec FE-B2 + FE-B4](../../superpowers/specs/2026-09-27-tags-starter-ui-design.md)
+§3 (D3, D5, D8, D11, D12, D14), §5.2, §5.3.
+
 ## Validation
 
 | Trường | Rule | Message hiển thị | Enforced by |
```

`docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md` (apply this diff):

```diff
diff --git a/docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md b/docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md
index 88c5b82..545ddb5 100644
--- a/docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md
+++ b/docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md
@@ -3,7 +3,7 @@ id: UC-TAG-001
 title: Quản lý tag và lọc thẻ theo tag
 status: ready
 rules: [BR-CARD-012, BR-DECK-015, BR-TAG-001, BR-TAG-002, BR-TAG-003, BR-TAG-004, BR-TAG-005, BR-TAG-006, BR-TAG-007, BR-TAG-008, BR-TAG-009, BR-TAG-010, BR-TAG-011, BR-TRANSFER-009]
-code: [lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart, lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart, lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart, lib/features/tags/domain/usecases/rename_tag_use_case.dart, lib/features/tags/domain/usecases/delete_tag_use_case.dart, lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart]
+code: [lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart, lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart, lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart, lib/features/tags/domain/usecases/rename_tag_use_case.dart, lib/features/tags/domain/usecases/delete_tag_use_case.dart, lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart, lib/features/tags/presentation/screens/tags_screen.dart, lib/features/tags/presentation/controllers/tag_actions_controller.dart, lib/features/card/domain/usecases/watch_card_tag_filter_use_case.dart, lib/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 1d003e6..2cde317 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -35,9 +35,9 @@ The screens of the V3 handoff. The generated handoff next to this folder
 |---|---|---|---|---|---|
 | 01 | Deck list · recursive | 22 | FE-A1 | aligned | [01-deck-list.md](01-deck-list.md) |
 | 02 | Review algorithm & reset | 9 | FE-A4 | aligned | [02-review-algorithm.md](02-review-algorithm.md) |
-| 03 | Starter decks | 10 | FE-B4 | out of V8 | — |
+| 03 | Starter decks | 10 | FE-B4 | aligned | [03-starter-decks.md](03-starter-decks.md) |
 | 04 | Library search | 5 | FE-A1, FE-A10 | aligned | [04-library-search.md](04-library-search.md) |
-| 05 | Tags | 12 | FE-B2 | out of V8 | — |
+| 05 | Tags | 12 | FE-B2 | aligned | [05-tags.md](05-tags.md) |
 | 06 | Trash | 15 | FE-B1 | aligned | [06-trash.md](06-trash.md) |
 | 07 | Card list | 15 | FE-A2 | aligned | [07-card-list.md](07-card-list.md) |
 | 08 | Card create | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
```

`docs/shared/ui/screen-handoff/01-deck-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/01-deck-list.md b/docs/shared/ui/screen-handoff/01-deck-list.md
index 974c87b..be32008 100644
--- a/docs/shared/ui/screen-handoff/01-deck-list.md
+++ b/docs/shared/ui/screen-handoff/01-deck-list.md
@@ -9,7 +9,7 @@ One recursive screen for the Library root (`/decks`) and any open deck
 
 | Region | Widget | Design |
 |---|---|---|
-| App bar | `MxAppBar` (large) | "Library". One action, "Coming soon": a sheet naming the features that wait (spec A4). |
+| App bar | `MxAppBar` (large) | "Library", then Starter decks (sparkles, screen 03), Tags (tag, screen 05) and Trash (screen 06), as the kit draws them (FE-B2 + FE-B4 D2). |
 | Search | `MxSearchField`, trigger mode | Hint "Search decks". A tap pushes `/decks/search` (screen 04). |
 | Due strip | `MxCard` (hero) + `MxIconTile` + `MxWorkloadBreakdownLine` | Bolt tile on primary, "N cards due", overdue · today · new. Display-only until Study home (FE-A8). Hidden when the library holds no card. |
 | Section header | `MxListSectionHeader` + `MxChipTrigger` | "N DECKS"; pill "Manual ⌄", or "Manual · Due only" tinted primary with the filter on. |
@@ -46,8 +46,8 @@ One recursive screen for the Library root (`/decks`) and any open deck
 One `MxBottomSheet`, "Sort & filter":
 
 - Sort by (`MxOptionRow`): Manual order "Drag decks to arrange them" · Date added
-  "Newest first" · Name "A → Z" · Most due cards. Progress waits under Coming soon
-  for a BR/UC definition (blocked in `wbs_BE.md`).
+  "Newest first" · Name "A → Z" · Most due cards. Progress is absent until a BR/UC
+  defines it (blocked in `wbs_BE.md`).
 - Toggle (`MxToggle`): "Only decks with due cards" / "Hides decks where nothing is
   waiting".
 - Button "Done".
@@ -58,10 +58,10 @@ One `MxBottomSheet`, "Sort & filter":
 |---|---|---|---|
 | rootLoaded | ![](img/01-deck-list/rootLoaded-light.png) | ![](img/01-deck-list/rootLoaded-dark.png) | As drawn, without the mastery bars (hidden). |
 | rootLoading | ![](img/01-deck-list/rootLoading-light.png) | ![](img/01-deck-list/rootLoading-dark.png) | Skeletons in the row's shape; header kept. |
-| rootEmpty | ![](img/01-deck-list/rootEmpty-light.png) | ![](img/01-deck-list/rootEmpty-dark.png) | Create deck only; starter decks wait under Coming soon. |
+| rootEmpty | ![](img/01-deck-list/rootEmpty-light.png) | ![](img/01-deck-list/rootEmpty-dark.png) | As drawn: "Create deck", then "Browse starter decks" (screen 03), and the footnote (FE-B4 §5.4). |
 | rootError | ![](img/01-deck-list/rootError-light.png) | ![](img/01-deck-list/rootError-dark.png) | As drawn, with Retry. |
 | rootSearch | ![](img/01-deck-list/rootSearch-light.png) | ![](img/01-deck-list/rootSearch-dark.png) | The field is a trigger: a tap opens screen 04 instead of typing here. |
-| rootSortFilter | ![](img/01-deck-list/rootSortFilter-light.png) | ![](img/01-deck-list/rootSortFilter-dark.png) | No "Progress" sort (Coming soon). |
+| rootSortFilter | ![](img/01-deck-list/rootSortFilter-light.png) | ![](img/01-deck-list/rootSortFilter-dark.png) | No "Progress" sort: it waits for a BR/UC. |
 | rootDueEmpty | ![](img/01-deck-list/rootDueEmpty-light.png) | ![](img/01-deck-list/rootDueEmpty-dark.png) | As drawn. |
 | rootOverflow | ![](img/01-deck-list/rootOverflow-light.png) | ![](img/01-deck-list/rootOverflow-dark.png) | Rows as in "Action sheet"; Reorder added. |
 | rootCreate | ![](img/01-deck-list/rootCreate-light.png) | ![](img/01-deck-list/rootCreate-dark.png) | As drawn (BR-SRS-001). |
@@ -83,7 +83,6 @@ One `MxBottomSheet`, "Sort & filter":
 
 | Artifact | V8 | Wins |
 |---|---|---|
-| Starter decks · Tags · Trash in the root app bar | Trash · Coming soon (which names starter decks and tags) | FE-B4 and FE-B2 wait (FE-B1 D1) |
 | A trash glyph over the Move to Trash dialog's title, the deck's name in bold | No glyph; the name in quotes | `MxDialog` has no glyph slot; no per-site text styling |
 | "Can't undo — “{deck}” is in Trash too. Restore it from here and choose a deck." on screen 06 | "Can't undo. {reason} Restore it from Trash and choose a deck." where the deck was deleted | An Undo happens where the item was deleted; the rejection carries no deck name (FE-B1 D7) |
 | Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
@@ -96,16 +95,13 @@ One `MxBottomSheet`, "Sort & filter":
 | Row meta and the first-run footnote in plain 12/500 | The caption role (`rowSubtitle`, `noteText`), tracked 1.2 | Guard: no per-site text styling; the caption role is shared |
 | Sort pill "⇅ Manual ⌄" | `MxChipTrigger`: "Manual" with the sort glyph after it | The shared chip trigger's anatomy |
 | "Create deck" and "Browse starter decks" carry glyphs | Text-only `MxEmptyState` actions | The shared empty state's anatomy |
-| First-run body offers "or copy a starter deck to begin with content" | "Create one to begin." | Starter decks wait (FE-B4); the body must not promise them |
 | Action sheet header with the deck's tile and "N sub-decks · N cards · {algorithm}"; Open and Study rows with count subtitles | The deck's name only; no count subtitles | `DeckView` carries no counts; the sheet reads only the view (ruling C-L6) |
 
 ## Pending
 
 | Element | Shown as | Waits for |
 |---|---|---|
-| Starter decks, Tags actions | under Coming soon | FE-B4, FE-B2 |
-| "Browse starter decks" | under Coming soon | FE-B4 |
-| Sort by progress | under Coming soon | a BR/UC definition (blocked in `wbs_BE.md`) |
+| Sort by progress | absent | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Mastery bar, donut | hidden | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Due strip tap | not interactive | FE-A8 |
 | Level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks at level 10 | absent; the header says "· level 10" | a later phase (owner decision C-O6) |
```

`docs/shared/ui/screen-handoff/03-starter-decks.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 03 · Starter decks

The templates bundled with the build, each copied into the library as a deck of the
person's own under the scheduler they choose. UC-STARTER-001; BR-STARTER-001…010; spec
[2026-09-27-tags-starter-ui-design.md](../../../superpowers/specs/2026-09-27-tags-starter-ui-design.md)
(FE-B4).

## Entry points

- **The Library's app bar:** the sparkles action pushes `/decks/starter`, full screen on
  the root navigator, with no bottom bar (D2, D5).
- **The empty Library:** "Browse starter decks" under "Create deck" (screen 01
  `rootEmpty`).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back and "Starter decks". |
| Note | `MxNote` (flask) | "These decks are practice fixtures for development and testing, not published course material. Anything you add is yours to edit." (BR-STARTER-010). Shown while the templates load too. |
| A card per template | `MxCard` + `MxIconTile` (sparkles) + `MxBadge` | The title, "In library" once a copy is in the library, the facts "{front} · {back} · {n} cards · {m} sub-decks · {source}", then the add ("Add to library", or "Add another copy") and "Suggests {algorithm}". The title wraps and the badge follows it; the suggestion drops below the button, whole, when both do not fit (critique P2a). The facts and the actions line up with the title, past the tile. |
| Algorithm sheet | `MxBottomSheet` + `MxOptionRow` ×2 + `MxSheetActions` | "Add “{title}”", "{n} cards in {m} sub-decks, as a new deck of your own.", "REVIEW ALGORITHM · REQUIRED", SM-2 ("grade yourself, intervals adapt") and Eight boxes ("Boxes 1–8 · match, guess, recall, fill"); the suggested one is prefixed "Suggested for this deck ·" and chosen first. Cancel / "Add deck". |

Language names come from a small table of the tags the build ships: English,
Vietnamese, Korean, and "Latin" for a `-Latn` tag; any other tag shows as written (D7).

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| list | ![](img/03-starter-decks/list-light.png) | ![](img/03-starter-decks/list-dark.png) | As drawn; the badge and the suggestion wrap instead of truncating (UI-base row 135). |
| choose | ![](img/03-starter-decks/choose-light.png) | ![](img/03-starter-decks/choose-dark.png) | As drawn. |
| adding | ![](img/03-starter-decks/adding-light.png) | ![](img/03-starter-decks/adding-dark.png) | The options and Cancel lock, the sheet cannot be dismissed, and "Add deck" spins with no "Adding…" text (D13). A second add is ignored. |
| added | ![](img/03-starter-decks/added-light.png) | ![](img/03-starter-decks/added-dark.png) | The sheet closes; "Added “{title}” · {algorithm} · {n} new cards" with Open, which goes to the new root deck in the Library. |
| alreadyPresent | ![](img/03-starter-decks/alreadyPresent-light.png) | ![](img/03-starter-decks/alreadyPresent-dark.png) | As drawn: a copy made meanwhile copies nothing more. |
| secondCopy | ![](img/03-starter-decks/secondCopy-light.png) | ![](img/03-starter-decks/secondCopy-dark.png) | As drawn; "Add second copy" opens the algorithm sheet (BR-STARTER-008). |
| addFailed | ![](img/03-starter-decks/addFailed-light.png) | ![](img/03-starter-decks/addFailed-dark.png) | The sheet stays with the choice; the danger banner's lead "Couldn't add the deck." sits above "Nothing was copied — try again."; the button reads "Try again". `templateNotFound` reads the same (spec §6). |
| loading | ![](img/03-starter-decks/loading-light.png) | ![](img/03-starter-decks/loading-dark.png) | The note, then skeleton rows (UI-base row 125). |
| none | ![](img/03-starter-decks/none-light.png) | ![](img/03-starter-decks/none-dark.png) | As drawn; "Create a deck" returns to the Library and opens its create dialog. |
| loadFailed | ![](img/03-starter-decks/loadFailed-light.png) | ![](img/03-starter-decks/loadFailed-dark.png) | As drawn, titled "Couldn't load starter decks" (the kit drops "load"), with Retry. |

Goldens: `test/features/starter_decks/presentation/goldens/starter_{list,choose,adding,added,already_present,second_copy,add_failed,loading,none,load_failed}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| "In library" pinned beside the title's first line | It follows the title, on the next line when the title wraps | No overflow at text scale 2 (critique P3) |
| "Suggests…" cut beside "Add another copy" | The suggestion drops below the button, whole | Critique P2a |
| "Adding…" beside the spinner | The spinner alone | D13 (FE-A3 C8) |
| A skeleton in each card's shape | The note, then skeleton rows | UI-base row 125 |
| "Couldn't starter decks" | "Couldn't load starter decks" | The kit's typo |

## Copy

"Starter decks" · "These decks are practice fixtures for development and testing, not
published course material. Anything you add is yours to edit." · "In library" · "{n}
cards" · "{m} sub-decks" · "Add to library" · "Add another copy" · "Suggests {algorithm}"
· "SM-2" · "Eight boxes" · "Add “{title}”" · "{n} cards in {m} sub-decks, as a new deck
of your own." · "Review algorithm · required" · "grade yourself, intervals adapt" · "Boxes
1–8 · match, guess, recall, fill" · "Suggested for this deck · {description}" · "Add
deck" · "Try again" · "Couldn't add the deck." · "Nothing was copied — try again." ·
"Added “{title}” · {algorithm} · {n} new cards" · "Open" · "Already in your library —
nothing was copied" · "Add a second copy?" · "“{title}” is already in your library. A
second copy is a separate deck with its own progress." · "Add second copy" · "No starter
decks in this build" · "This version ships without practice content. Create a deck or
import cards instead." · "Create a deck" · "Couldn't load starter decks" · "Your library
is unaffected. Try again in a moment."
```

`docs/shared/ui/screen-handoff/05-tags.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 05 · Tags

The tag catalog: every tag of the library with its active cards, narrowed by a search,
each renamed, merged or deleted from its actions. UC-TAG-001; BR-TAG-001…011; spec
[2026-09-27-tags-starter-ui-design.md](../../../superpowers/specs/2026-09-27-tags-starter-ui-design.md)
(FE-B2). The card list's tag filter is on screen 07.

## Entry points

- **The Library's app bar:** the tag action pushes `/decks/tags`, full screen on the root
  navigator, with no bottom bar (D2, D5).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back and "Tags". |
| Search | `MxSearchField` | "Search tags". It narrows the catalog with the fold the store writes and searches with (BR-TAG-003): `ĐỘNG TỪ` finds `động từ`. |
| Header | `MxListSectionHeader` | "{n} tags", "No tags" or "No matches", with "A→Z" as plain text: there is one order, and nothing to tap (critique P2b). |
| Rows | `MxSection` + `MxListRow` | A tag tile, the name (one line, ellipsis), "{n} cards" and ⋮ ("Actions for {tag}"). While the tag's write runs, ⋮ is a spinner and the row cannot be tapped. |
| Action sheet | `MxBottomSheet` + `MxTagChip` + `MxActionSheetCommandRow` ×3 | The chip "{tag} · {n}" and "Tag actions"; "Find cards with this tag" / "Search the library for “{tag}”"; "Rename tag" / "Renaming onto an existing name merges the two"; "Delete tag" / "Removes it from {n} cards · the cards stay" (destructive). |
| Rename dialog | `MxDialog` + `MxTextField` + `MxSheetActions` | "Rename tag", "Renaming updates every card that uses “{tag}”.", the overline "NEW NAME", the field prefilled, "Tag names are case-insensitive."; Cancel / Rename. The name rules are checked as it is typed; what the rename would do is read 250 ms after the name stops changing (D8). Rename is off while the name is unchanged. |
| Delete dialog | `MxDialog` + `MxCard` (success) + `MxSheetActions` | "Delete this tag?", "“{tag}” is removed from {n} cards and disappears from the catalog. Tags are not kept in Trash.", the note "No card is deleted, hidden or changed — all {n} cards stay exactly where they are."; Cancel / "Remove from {n} cards" (destructive). |

"Find cards with this tag" opens the Library search on the tag's name (D11). The search
lives in the Library branch, under the shell, so Back from it returns to the Library,
not to Tags (plan C4).

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| loaded | ![](img/05-tags/loaded-light.png) | ![](img/05-tags/loaded-dark.png) | Tags in the store's folded order (BR-TAG-003; UI-base row 137); no sort glyph. |
| loading | ![](img/05-tags/loading-light.png) | ![](img/05-tags/loading-dark.png) | The search, then skeleton rows (UI-base row 125). |
| empty | ![](img/05-tags/empty-light.png) | ![](img/05-tags/empty-dark.png) | As drawn; "Go to library" goes back. |
| searchEmpty | ![](img/05-tags/searchEmpty-light.png) | ![](img/05-tags/searchEmpty-dark.png) | "No tags match “{term}”" (A6), distinct from "No tags yet". |
| sheet | ![](img/05-tags/sheet-light.png) | ![](img/05-tags/sheet-dark.png) | As drawn. |
| rename | ![](img/05-tags/rename-light.png) | ![](img/05-tags/rename-dark.png) | The tag's name in quotes, not bold. |
| renameMerge | ![](img/05-tags/renameMerge-light.png) | ![](img/05-tags/renameMerge-dark.png) | "{len} / 50 · names are unique regardless of letter case.", the warning panel, the chips `{source} · {n}` → `{target} · {union}` (the union, BE-B2 D6), and "Merge tags" in the warning tone, amber with dark ink (D15; UI-base row 134). A merge that no longer plans the same way when written (`mergeNotConfirmed`) opens the dialog again on the name typed. |
| nameTooLong | ![](img/05-tags/nameTooLong-light.png) | ![](img/05-tags/nameTooLong-dark.png) | The counter "{len} / 50" in the error ink, "A tag name can be at most 50 characters." under the field, Rename off. The field keeps one line. A blank name and a control character show their own messages (E2). |
| del | ![](img/05-tags/del-light.png) | ![](img/05-tags/del-dark.png) | No glyph over the title; the text is left-aligned; the buttons stack when "Remove from {n} cards" cannot keep its line (UI-base row 139). |
| busy | ![](img/05-tags/busy-light.png) | ![](img/05-tags/busy-dark.png) | As drawn. |
| opError | ![](img/05-tags/opError-light.png) | ![](img/05-tags/opError-dark.png) | One sentence, "Couldn't rename tag. Nothing changed — try again in a moment." (or delete), with Retry, which runs the same write (UI-base row 138). |
| tagGone | ![](img/05-tags/tagGone-light.png) | ![](img/05-tags/tagGone-dark.png) | As drawn (E3). |
| read error | — | — | **V8 addition (E1, D10):** `MxErrorState` "Couldn't load tags" with Retry. |

Goldens: `test/features/tags/presentation/goldens/tags_{loaded,loading,empty,search_empty,sheet,rename,rename_merge,name_too_long,del,busy,op_error,tag_gone,read_error}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| "Merge tags" orange with white text (about 2.8:1) | The warning role with its ink | AA; D15 |
| The target chip counts the sum (46 + 31 = 77) | The union of both tags' cards | BE-B2 D6; D8 |
| A sort glyph beside "A→Z" | Plain text | One order (BR-TAG-003); critique P2b |
| Diacritics folded in the order (động từ after cần ôn lại) | The store's folded order | BR-TAG-003 |
| Tag names in bold in the dialogs | In quotes | No per-site text styling |
| A tag glyph over "Delete this tag?", centred text | No glyph, left-aligned | `MxDialog` has no glyph slot |
| Toasts with a bold title line | One sentence | `MxSnackbarContent` has one message |
| No read error | `MxErrorState` with Retry | UC-TAG-001 E1; D10 |

## Copy

"Tags" · "Search tags" · "{n} tags" · "No tags" · "No matches" · "A→Z" · "{n} cards" ·
"Actions for {tag}" · "No tags yet" · "Tags appear here as you add them when creating or
editing flashcards." · "Go to library" · "No tags match “{term}”" · "Try a different
spelling. Tag search is case-insensitive." · "Couldn't load tags" · "Tag actions" · "Find
cards with this tag" · "Search the library for “{tag}”" · "Rename tag" · "Renaming onto
an existing name merges the two" · "Delete tag" · "Removes it from {n} cards · the cards
stay" · "Renaming updates every card that uses “{tag}”." · "New name" · "Tag names are
case-insensitive." · "{len} / {max}" · "{len} / {max} · names are unique regardless of
letter case." · "A tag name can be at most {max} characters." · "Rename" · "Merge tags" ·
"A tag called “{target}” already exists. Continuing will merge “{source}” into it — its
spelling stays “{target}”." · "No card is deleted. Cards carrying both keep one tag; no
card goes over 10 tags." · "Delete this tag?" · "“{tag}” is removed from {n} cards and
disappears from the catalog. Tags are not kept in Trash." · "No card is deleted, hidden
or changed — all {n} cards stay exactly where they are." · "Remove from {n} cards" ·
"Couldn't rename tag. Nothing changed — try again in a moment." · "Couldn't delete tag.
Nothing changed — try again in a moment." · "“{tag}” no longer exists — it was removed a
moment ago."
```

`docs/shared/ui/screen-handoff/07-card-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/07-card-list.md b/docs/shared/ui/screen-handoff/07-card-list.md
index 1b3a323..45400ea 100644
--- a/docs/shared/ui/screen-handoff/07-card-list.md
+++ b/docs/shared/ui/screen-handoff/07-card-list.md
@@ -13,7 +13,7 @@ An open deck whose content type is `card`: the card section of `DeckLevelScreen`
 | Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck; hidden while selecting. |
 | Search | `MxSearchField` | Revealed by the search action; closing it clears the term. Hidden while selecting; its term stays and returns with it. |
 | Summary card | `MxCard` (hero) + `MxMasteryDonut` + `MxWorkloadBreakdownLine` | "DECK PROGRESS · {algorithm}", "{n} of {total} cards mastered", overdue · today · new, the four-state bar and its legend (New · Beginning · Reviewing · Mastered). "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the deck holds no card to study. Hidden while selecting. |
-| Filters | `MxFilterChip` | All · Due · New · Flagged with counts; the Tags filter waits under Coming soon (FE-B2). |
+| Filters | `MxFilterChip` | All · Due · New · Flagged with counts, then Tags with the tag glyph: selected with the count of tags applied, and its tap opens the tag filter (FE-B2 D14). |
 | Header | `MxListSectionHeader` + `MxChipTrigger` | "Showing {n} of {total}" (selecting: "{n} of {total} selected"); sort "Newest first ⌄" / "Due first ⌄". |
 | Rows | card surface per row, 8 apart | Status dot (checkbox while selecting); front 16/700 and back 12, one line each; uppercase status label in its ink, up to two `MxTagChip`s and "+{n}"; trailing flag in the warning colour (E-L2) and the due chip, an `MxBadge` (E-L4): "New", "Due today", "In {n}d", "{n}d overdue". The status label, tags and "+{n}" wrap at large text. Rows build as they scroll into view (E-L5). |
 | Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Trash. |
@@ -28,7 +28,7 @@ Study this deck · Rename · Move to another deck · Import cards (screen 11) ·
 
 | State | Light | Dark | V8 |
 |---|---|---|---|
-| loaded | ![](img/07-card-list/loaded-light.png) | ![](img/07-card-list/loaded-dark.png) | As drawn, without the Tags chip (Coming soon). |
+| loaded | ![](img/07-card-list/loaded-light.png) | ![](img/07-card-list/loaded-dark.png) | As drawn; the Tags chip reads as selected while tags are applied (D14; UI-base row 140). |
 | empty | ![](img/07-card-list/empty-light.png) | ![](img/07-card-list/empty-dark.png) | The deck is unset again (E-L1): screen 01's unset state. |
 | searchEmpty | ![](img/07-card-list/searchEmpty-light.png) | ![](img/07-card-list/searchEmpty-dark.png) | As drawn. |
 | loading | ![](img/07-card-list/loading-light.png) | ![](img/07-card-list/loading-dark.png) | As drawn. |
@@ -48,13 +48,42 @@ editor (screen 09) moves its card to the Trash from its "More" card with the sam
 (FE-B1 D13):
 ![](img/09-card-edit/delConfirm-light.png)
 
+## Tag filter
+
+Not in the kit; shaped by Impeccable before the plan (FE-B2 D3,
+`.impeccable/critique/2026-09-27T06-00-00Z__tags-starter-kit.md`).
+
+- **The sheet:** `MxBottomSheet`, "Filter by tags" over "Show cards with any of the chosen
+  tags", or "{k} chosen · cards with any of them". A row per tag of the library
+  (`MxListRow` with `MxSelectionCheckbox`, one checkbox node): the name and its cards in
+  this deck, 0 included, in the catalog's order; a checked row never moves. Above eight
+  tags, "Search tags" heads the list; it never drops a chosen tag.
+- **The footer:** "Clear" (empties the choice, stays open; off when nothing is chosen) and
+  "Apply" (closes and applies). Closing it any other way keeps what was applied (A5).
+  With no tag in the library, the sheet says "No tags yet. Add tags while creating or
+  editing cards." and offers Close.
+- **Applying:** a card passes with any chosen tag (BR-TAG-004), and with the status filter
+  and the search. The list starts again from its first window, and the selection clears
+  (BR-TAG-005). A tag deleted or merged away leaves the applied set (D12).
+- **No card with these tags (A7):** "No cards with these tags" with "Clear tag filter".
+
+| State | Golden (light) | Golden (dark) |
+|---|---|---|
+| none chosen | `card_tag_filter_none_light.png` | `card_tag_filter_none_dark.png` |
+| one chosen | `card_tag_filter_one_light.png` | `card_tag_filter_one_dark.png` |
+| several chosen | `card_tag_filter_several_light.png` | `card_tag_filter_several_dark.png` |
+| applied | `card_tag_filter_applied_light.png` | `card_tag_filter_applied_dark.png` |
+| no card (A7) | `card_tag_filter_no_card_light.png` | `card_tag_filter_no_card_dark.png` |
+
+The goldens are in `test/features/card/presentation/goldens/`.
+
 ## Deviations
 
 | Artifact | V8 | Wins |
 |---|---|---|
 | A trash glyph beside the Move to Trash dialog's title | No glyph | `MxDialog` has no glyph slot |
 | "Recoverable for 30 days with its 7 answers of history" | "Recoverable from Trash for 30 days, with its schedule and history" | The dialog reads no history count |
-| Tags filter | Hidden; named under Coming soon | Spec A4 (amended) |
+| The Tags chip as a ghost trigger | A filter chip, selected while tags are applied | FE-B2 D14 (critique P1b) |
 | An empty card list | The deck is unset again: screen 01's unset state | BR-DECK-015, ruling E-L1 |
 | The flag in the streak colour | The flag in the warning colour; the theme has no streak token | Ruling E-L2 |
 | "Select all" as a text link | A compact secondary `MxButton` | Ruling E-L3 |
@@ -68,5 +97,6 @@ editor (screen 09) moves its card to the Trash from its "More" card with the sam
 - Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move to Trash" · "“{front}” moved to Trash" · "Undo" · "{n} cards moved to Trash".
 - Empty: "No cards in this deck yet" · "Write your first card, or bring many at once from a spreadsheet or pasted text." · "Import cards (CSV, TSV, XLSX, text)" · "Studying this deck becomes available once it holds at least one card."
 - Search empty: "No cards match “{term}”" · "Try a different term, or clear the search to see all {n} cards."
+- Tag filter: "Tags" · "Filter by tags" · "Show cards with any of the chosen tags" · "{k} chosen · cards with any of them" · "Search tags" · "Clear" · "Apply" · "No tags yet. Add tags while creating or editing cards." · "Close" · "Couldn't load tags" · "No cards with these tags" · "Clear tag filter".
 - Error: "Couldn't open this deck" · "Your data is safe on this device. Try again in a moment."
 - Move: "Move {n} cards to…" · "Schedule, history, flags and tags travel with the cards. Decks in other trees are not offered." · no target: "Nowhere to move these cards" · "No other deck in “{root}” holds cards or is empty. Create an empty sub-deck first; cards can only move within their own tree."
```

`docs/shared/ui/screen-state-checklist.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-state-checklist.md b/docs/shared/ui/screen-state-checklist.md
index 9ef766a..d452d4f 100644
--- a/docs/shared/ui/screen-state-checklist.md
+++ b/docs/shared/ui/screen-state-checklist.md
@@ -32,17 +32,17 @@ Màn 14, 16, 16a và 17–21 là `aligned` trong index từ phase P5 của roadm
 
 ## Tổng hợp
 
-Kit có **26 màn, 211 state**. Xong **151**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **31**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
+Kit có **26 màn, 211 state**. Xong **175**; một phần **3**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **9**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
 
 | # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
 |---|---|---|---|---|---|---|---|---|
-| 01 | Deck list · recursive | FE-A1 | 22 | 19 | 3 | 0 | 0 | [01-deck-list.md](screen-handoff/01-deck-list.md) |
+| 01 | Deck list · recursive | FE-A1 | 22 | 20 | 2 | 0 | 0 | [01-deck-list.md](screen-handoff/01-deck-list.md) |
 | 02 | Review algorithm & reset | FE-A4 | 9 | 9 | 0 | 0 | 0 | [02-review-algorithm.md](screen-handoff/02-review-algorithm.md) |
-| 03 | Starter decks | FE-B4 | 10 | 0 | 0 | 10 | 0 | — |
+| 03 | Starter decks | FE-B4 | 10 | 10 | 0 | 0 | 0 | [03-starter-decks.md](screen-handoff/03-starter-decks.md) |
 | 04 | Library search | FE-A1, FE-A10 | 5 | 5 | 0 | 0 | 0 | [04-library-search.md](screen-handoff/04-library-search.md) |
-| 05 | Tags | FE-B2 | 12 | 0 | 0 | 12 | 0 | — |
+| 05 | Tags | FE-B2 | 12 | 12 | 0 | 0 | 0 | [05-tags.md](screen-handoff/05-tags.md) |
 | 06 | Trash | FE-B1 | 15 | 15 | 0 | 0 | 0 | [06-trash.md](screen-handoff/06-trash.md) |
-| 07 | Card list | FE-A2 | 15 | 13 | 1 | 0 | 1 | [07-card-list.md](screen-handoff/07-card-list.md) |
+| 07 | Card list | FE-A2 | 15 | 14 | 0 | 0 | 1 | [07-card-list.md](screen-handoff/07-card-list.md) |
 | 08 | Card create | FE-A2 | 9 | 0 | 9 | 0 | 0 | — |
 | 09 | Card edit | FE-A2 | 9 | 2 | 7 | 0 | 0 | — |
 | 10 | Card detail | FE-A2 | 7 | 1 | 6 | 0 | 0 | — |
@@ -73,10 +73,10 @@ FE-A1 · [01-deck-list.md](screen-handoff/01-deck-list.md)
 |---|---|---|---|---|
 | [~] | Root · decks | `rootLoaded` | một phần | Thanh mastery ẩn: chờ BR/UC của deck định nghĩa mastery (điểm chặn trong `wbs_BE.md`). |
 | [x] | Root · loading | `rootLoading` | xong |  |
-| [~] | Root · first launch | `rootEmpty` | một phần | Chỉ có Create deck; starter decks nằm dưới Coming soon, chờ FE-B4. |
+| [x] | Root · first launch | `rootEmpty` | xong | Create deck và "Browse starter decks" (FE-B4). |
 | [x] | Root · error | `rootError` | xong |  |
 | [x] | Root · search | `rootSearch` | xong |  |
-| [~] | Root · sort & filter | `rootSortFilter` | một phần | Chưa có sort "Progress" (Coming soon), cùng điểm chặn mastery. |
+| [~] | Root · sort & filter | `rootSortFilter` | một phần | Chưa có sort "Progress": chờ BR/UC, cùng điểm chặn mastery. |
 | [x] | Root · due filter, none | `rootDueEmpty` | xong |  |
 | [x] | Root · deck actions | `rootOverflow` | xong |  |
 | [x] | Root · create deck | `rootCreate` | xong |  |
@@ -112,20 +112,20 @@ FE-A4 · [02-review-algorithm.md](screen-handoff/02-review-algorithm.md)
 
 ### 03 · Starter decks
 
-FE-B4 · chưa có detail file
+FE-B4 · [03-starter-decks.md](screen-handoff/03-starter-decks.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | Templates | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Choose algorithm | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Adding | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Added | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Already present | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Second copy | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Add failed | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Loading | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | None in build | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
-| [ ] | Load failed | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
+| [x] | Templates | `list` | xong | Badge và dòng gợi ý xuống dòng thay vì bị cắt. |
+| [x] | Choose algorithm | `choose` | xong |  |
+| [x] | Adding | `adding` | xong | Nút quay, không kèm chữ (D13). |
+| [x] | Added | `added` | xong | Open mở deck gốc mới trong Thư viện. |
+| [x] | Already present | `alreadyPresent` | xong |  |
+| [x] | Second copy | `secondCopy` | xong |  |
+| [x] | Add failed | `addFailed` | xong |  |
+| [x] | Loading | `loading` | xong | Note rồi skeleton rows (UI-base dòng 125). |
+| [x] | None in build | `none` | xong |  |
+| [x] | Load failed | `loadFailed` | xong |  |
 
 ### 04 · Library search
 
@@ -141,22 +141,22 @@ FE-A1, FE-A10 · [04-library-search.md](screen-handoff/04-library-search.md)
 
 ### 05 · Tags
 
-FE-B2 · chưa có detail file
+FE-B2 · [05-tags.md](screen-handoff/05-tags.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | Loaded | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Loading | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Empty | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Search empty | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Tag actions | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Rename | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Rename → merge | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Name too long | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Delete | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Busy row | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Op error | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
-| [ ] | Tag gone | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
+| [x] | Loaded | `loaded` | xong | Thứ tự theo tên đã fold (BR-TAG-003). |
+| [x] | Loading | `loading` | xong |  |
+| [x] | Empty | `empty` | xong |  |
+| [x] | Search empty | `searchEmpty` | xong |  |
+| [x] | Tag actions | `sheet` | xong |  |
+| [x] | Rename | `rename` | xong |  |
+| [x] | Rename → merge | `renameMerge` | xong | Số thẻ là hợp (BE-B2 D6); nút tông warning (D15). |
+| [x] | Name too long | `nameTooLong` | xong |  |
+| [x] | Delete | `del` | xong |  |
+| [x] | Busy row | `busy` | xong |  |
+| [x] | Op error | `opError` | xong | Toast một câu, có Retry. |
+| [x] | Tag gone | `tagGone` | xong |  |
 
 ### 06 · Trash
 
@@ -186,7 +186,7 @@ FE-A2 · [07-card-list.md](screen-handoff/07-card-list.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [~] | Loaded | `loaded` | một phần | Chưa có chip Tags: chờ FE-B2. |
+| [x] | Loaded | `loaded` | xong | Chip Tags và bộ lọc tag (FE-B2 D3, D14). |
 | [x] | Empty | `empty` | xong |  |
 | [x] | Search empty | `searchEmpty` | xong |  |
 | [x] | Loading | `loading` | xong |  |
@@ -484,3 +484,5 @@ FE-A3 · [26-language.md](screen-handoff/26-language.md)
 - **Cập nhật ngày 2026-09-26:** FE-A3 plan 1 dựng màn 23, 25 và 26; 14 state chuyển sang
   xong.
 - **Cập nhật ngày 2026-09-27:** FE-A3 plan 2 dựng màn 15; 7 state chuyển sang xong.
+- **Cập nhật ngày 2026-09-27:** FE-B2 + FE-B4 dựng màn 03 và 05, `rootEmpty` của màn 01 và
+  chip Tags của màn 07; 24 state chuyển sang xong.
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index 059e181..9bcbf81 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -536,6 +536,13 @@ item names where it comes from.
 | 131 | Screen 22's list opens with a total row of the level's four numbers ("All decks", "Whole deck"; BR-PROGRESS-001), and its header carries no trailing totals (kit: "{n} active cards · {m} card-days") | owner 2026-09-27, FE-A9 D2 |
 | 132 | Screen 22 dims nothing by opacity: an idle deck row keeps its name and "No activity in this range" at full contrast, and its 0 is muted (kit: the row at 60%, which fails 4.5:1) | FE-A9 D11 (critique P2) |
 | 133 | Screen 22 never studied adds "Start studying" to the Study tab under Today's placeholder (UC-PROGRESS-001 A2); it adds the states the kit lacks: a quiet range (A3), no deck (A2) and a deck with no children (A1) | owner 2026-09-27, FE-A9 D1 |
+| 134 | `MxButtonTone.warning` paints the `warning` role with `onWarning` (amber, dark ink): screen 05's "Merge tags". The kit fills it orange with white text, about 2.8:1 | FE-B2 D15 (critique P1a) |
+| 135 | Screen 03's card lets "In library" follow the title and drops "Suggests {algorithm}" below the add when they do not fit; the kit pins the badge beside the title and cuts the suggestion to "Suggests…". The tile centres on the title's lines | FE-B4 critique P2a, P3; guard: marks centre on their row |
+| 136 | Screen 03's add spins with no "Adding…" text, as screen 15's save does | FE-B4 D13 (FE-A3 C8) |
+| 137 | Screen 05 lists tags in the store's folded order (BR-TAG-003), with "A→Z" as plain text; the kit folds diacritics in its order and draws a sort glyph | BR-TAG-003; FE-B2 critique P2b |
+| 138 | Screen 05's toasts are one sentence ("Couldn't rename tag. Nothing changed — try again in a moment.") with Retry; the kit draws a bold title line over a body | `MxSnackbarContent` has one message |
+| 139 | Screen 05's dialogs quote tag names instead of bolding them, and "Delete this tag?" has no glyph and is left-aligned | No per-site text styling; `MxDialog` has no glyph slot |
+| 140 | Screen 07's Tags chip is an `MxFilterChip`, selected with the count of tags applied, and opens the tag filter sheet, which the kit does not draw; the kit's chip is a ghost trigger that never reads as selected | owner 2026-09-27, FE-B2 D3, D14 |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index 36eb629..3cd6085 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -91,9 +91,9 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 | ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
 |---|---|---|---|---|---|---|
 | FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | xong | BE-B1, FE-A1, FE-A2 | M | [spec](superpowers/specs/2026-09-26-trash-ui-design.md); [plan 1: luồng xoá, Undo, câu chữ](superpowers/plans/2026-09-26-trash-delete-flows.md); [plan 2: màn 06, lối vào, auto-purge](superpowers/plans/2026-09-26-trash-screen.md); [screen handoff 06](shared/ui/screen-handoff/06-trash.md). Hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | — |
-| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
+| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | xong | BE-B2, FE-A2 | M | [spec](superpowers/specs/2026-09-27-tags-starter-ui-design.md) và [plan](superpowers/plans/2026-09-27-tags-starter-ui.md) (chung với FE-B4); file chi tiết [05](shared/ui/screen-handoff/05-tags.md), bộ lọc tag ở [07](shared/ui/screen-handoff/07-card-list.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | — |
 | FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
-| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | BE-B4 xong: hợp đồng cho UI ở §9 của [spec gói 10](superpowers/specs/2026-09-26-starter-decks-backend-design.md); [ui.md](features/starter-decks/ui.md) | Màn 03 trên 2 use case của `starter_decks`: `WatchStarterLibraryUseCase` cho `loading`, `list`, `none`, `loadFailed`; `AddStarterDeckUseCase` cho `adding`, `added` (Open tới `rootDeckId`), `alreadyPresent` (`alreadyInLibrary`), `secondCopy` (xác nhận rồi gọi lại với `allowSecondCopy`) và `addFailed`; sheet chọn scheduler chọn sẵn `suggestedScheduler`; tên ngôn ngữ lấy từ thẻ BCP 47; note "Development fixture" theo BR-STARTER-010 |
+| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | xong | BE-B4, FE-A1 | M | [spec](superpowers/specs/2026-09-27-tags-starter-ui-design.md) và [plan](superpowers/plans/2026-09-27-tags-starter-ui.md) (chung với FE-B2); file chi tiết [03](shared/ui/screen-handoff/03-starter-decks.md); `rootEmpty` của màn 01 có "Browse starter decks"; [ui.md](features/starter-decks/ui.md) | — |
 | FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5a, BE-B5b, FE-A3 | S–M | [README reminders](features/reminders/README.md); hợp đồng sáu use case ở [spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §9 | Sau BE-B5b. Màn 24 không bắt đầu một thao tác nhắc học khi thao tác trước chưa xong ([spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §14). Khi hiện hàng Daily reminder ở màn 23: câu chữ reset nêu cả nhắc học (dòng 123 của sổ nợ UI-base), và sau khi reset thì gọi `ReconcileReminderUseCase` (spec gói 11a §9; FE-A3 D4) |
 
 ### Nợ của UI base (spec UI base §9)
@@ -168,9 +168,8 @@ và phụ thuộc giữa các màn quyết định:
 1. Mọi màn của V8.0 đã dựng: FE-A9 (Tiến độ) là màn cuối. Còn lại của V8.0 là phần dở
    của FE-A1 (mastery, chờ BR/UC) và FE-A2 (file chi tiết 08–10).
 2. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
-3. Sau V8.0: FE-B1 (Trash, #78) và FE-B3 (import/export, #72) đã xong. FE-B2 (tag) và
-   FE-B4 (starter) không còn chờ backend vì BE-B2 và BE-B4 đã xong. BE-B5a xong trong
-   gói 11a; FE-B5 còn chờ BE-B5b, adapter Android.
+3. Sau V8.0: FE-B1 (Trash, #78), FE-B3 (import/export, #72), FE-B2 (tag) và FE-B4
+   (starter) đã xong. BE-B5a xong trong gói 11a; FE-B5 còn chờ BE-B5b, adapter Android.
 
 ## Ước lượng effort (rà soát 2026-09-25)
 
@@ -250,3 +249,5 @@ giờ mỗi trạng thái, cộng thêm phần tương tác phức tạp.
   sheet của deck và từ app bar màn 14; Coming soon không còn nêu Study options.
 - **Cập nhật ngày 2026-09-27:** FE-A9 xong: màn 22 thay placeholder cuối cùng (tab
   Progress), hai cấp `/progress` và `/progress/:deckId`; `PlaceholderScreen` đã bỏ.
+- **Cập nhật ngày 2026-09-27:** FE-B2 và FE-B4 xong trong một plan: màn 03 và 05, chip Tags
+  và bộ lọc tag của màn 07, app bar và `rootEmpty` của màn 01; sheet Coming soon đã bỏ.
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
TZ=UTC flutter test --tags golden
```

Expected: every gate green. In scratch: the gate ran 2341 tests, "✓ mechanical gates
passed", guard "No violations found", docs "PASS — 0 error(s)"; the goldens, 347 tests,
all pass.

- [ ] **Step 4: Commit and push**

```bash
git add \
  docs/features/starter-decks/README.md \
  docs/features/starter-decks/ui.md \
  docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md \
  docs/features/tags/README.md \
  docs/features/tags/ui.md \
  docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/shared/ui/screen-handoff/03-starter-decks.md \
  docs/shared/ui/screen-handoff/05-tags.md \
  docs/shared/ui/screen-handoff/07-card-list.md \
  docs/shared/ui/screen-state-checklist.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/wbs_FE.md \
  docs/_generated/traceability.md \
  docs/_generated/open-questions.md
git commit -m "$(cat <<'EOF'
docs: FE-B2 + FE-B4 done: detail files 03 and 05, register rows 134-140, UC, WBS

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
