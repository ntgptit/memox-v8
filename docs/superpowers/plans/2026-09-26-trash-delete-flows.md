# MemoX V8 Trash Delete Flows Implementation Plan (FE-B1, plan 1 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every delete in the app say what BE-B1 already does, which is move to the
Trash. The deck and card dialogs, the card editor's "More" card, the Undo toast and the
gone states all say so. This is the first half of FE-B1 in
[`docs/wbs_FE.md`](../../wbs_FE.md). Plan 2 builds screen 06, its entry points and the
auto-purge.

**Architecture:**
- **One shared change.** `MxSnackbar` gains a duration. A toast with an action stays
  while TalkBack is on, and a new toast replaces the one on screen.
- **Deck and card.** Each keeps its own delete dialog and gains a small support
  function that shows the "moved to Trash" toast with Undo. Undo goes through a new
  controller method and a new provider for the BE-B1 Undo use case.
- **The toast outlives its screen.** It is shown on the root navigator, and Undo reads
  the app's `ProviderContainer`.
- **The card editor.** It gains a section that opens the same card dialog. `app/` closes
  the card detail when the editor reports that its card went to the Trash.
- **Nothing else changes.** No backend change, no schema change, no new import edge.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, gen-l10n (en, vi). No new package.

**Spec:** [`docs/superpowers/specs/2026-09-26-trash-ui-design.md`](../specs/2026-09-26-trash-ui-design.md)
§3 (D3, D4, D7, D11–D15), §5 and §8–§9. Use case: UC-TRASH-001 (main flow step 1, A1,
E3). The kit is the visual authority: "MemoX — Mobile UI Kit v3", screens 01, 07, 09,
10 and 12, with the pre-plan critique in
`.impeccable/critique/2026-09-26T10-32-30Z__trash-kit.md`.

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` at the spec's commit.
Generated code is not committed. In a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- Every task was built and committed in a scratch worktree of this branch, and each
  task's blocks below are that commit's files and diffs.
- The full gate (`dod_check.sh --force`) passed there with 1,796 host tests, a clean
  `flutter analyze`, a clean guard and clean architecture boundaries. The goldens ran
  separately in this Linux container.
- The blocks below were replayed mechanically onto a clean checkout of the spec's
  commit, and the result matched the scratch files byte for byte.
- The goldens were compared with the kit captures.
- Rules were then broken on purpose, and each break failed a test:
  - the TalkBack `persist` removed;
  - a new toast queued instead of replacing;
  - the confirm not spinning;
  - a refused Undo not shown;
  - several cards offered Undo;
  - the one-card preview dropped;
  - the card detail left open after the editor moved its card.

## Clarifications (rulings; amend the spec where they differ)

- **P1 (D14).**
  - `buildMxSnackBar` sets `persist` when the toast has an action and
    `MediaQuery.accessibleNavigationOf` is on. The action is drawn by
    `MxSnackbarContent`, not `SnackBar.action`, so Flutter does not do this itself.
  - `showMxSnackbar` hides the current toast before it shows the next.
  - `duration` defaults to `AppDurations.toast`, the platform's 4 seconds.
    `AppDurations.undoWindow` is 8 seconds (D3).
- **P2 (the toast outlives its screen).**
  - The Trash toasts are shown on
    `Navigator.of(context, rootNavigator: true).context`, whose `ScaffoldMessenger`,
    theme and localizations live as long as the app.
  - Undo reads `ProviderScope.containerOf(context, listen: false)`, taken when the
    toast is shown. By the time Undo is tapped, the dialog, and often the screen, is
    gone.
- **P3 (E3 copy; amends spec §5 in Task 6).** A refused Undo reads "Can't undo.
  {reason} Restore it from Trash and choose a deck." A full stop replaces the spec's
  dash, because `{reason}` is the rejection's own sentence and starts with a capital.
  An Undo can be refused for any value `refusalUnder` returns, not only the D16 ones.
- **P4 (deck, kit 01).**
  - The sheet row reads "Move to Trash" with the sub-line "Recoverable for 30 days". It
    is not destructive.
  - The dialog's body names the deck and its counts. Its note is an `MxNote` with the
    history glyph. Its confirm is primary, carries the trash glyph and spins while the
    deck moves (D15).
  - A deck gone before its sheet opens says `deckGoneTitle`. The message
    `deckDeletedToast` is removed.
- **P5 (cards, kit 07).**
  - The bulk bar's command reads "Trash", as the kit does. The dialog's confirm reads
    "Move to Trash" (`cardMoveToTrash`).
  - One card shows its front over its back (`CardTrashPreview`) when its row is loaded.
    The editor always passes it. Several cards show no preview.
  - One card gets "“{front}” moved to Trash" with Undo. Several get "{n} cards moved to
    Trash" without it (D4).
- **P6 (D13, the editor).**
  - `CardTrashSectionWidget` takes the `NavigatorState` before the dialog opens. Once
    the card has moved, it pops the editor's route with `true`. The editor swaps the
    form for its gone state as soon as the card leaves, so the form cannot pop itself.
  - `Navigator.pop` skips the discard guard. The unsaved edits go with the card, as the
    kit's gone state says.
  - `app/`'s `_editCard` awaits the push and pops the card detail on `true`.
  - The section's body says "Leaves this deck". It does not name the deck, which the
    path above already shows (UI-base row 110).
- **P7 (D10).** Plan 1 has no "Open Trash" anywhere, because the Trash screen does not
  exist yet: not on the several-cards toast, the refused Undo or the gone states. Plan 2
  adds each one.
- **P8 (D15, tests).** A second tap while a deck or cards are moving reaches the
  controller. Its result is dropped, because the dialog has unmounted, and nothing
  reaches the person. The tests therefore pin the visible part, the spinner.
- **P9 (goldens).** `library_deck_trashed_*` shows the gone state behind the toast. The
  harness has one route, so the step back pops nothing. The app's route test pins the
  step back.
- **P10.** `test/app/library_routes_test.dart` is at the guard's 400-line limit. The
  editor's route test starts `test/app/trash_routes_test.dart`, and plan 2 adds its
  routes there.
- **P11.** The capture manifest gains screens 09 and 10 with their Trash states only
  (delConfirm; the two gone states). Plan 2 references the gone states when it adds
  Open Trash.

## Global Constraints

Every task's requirements implicitly include these.

- The kit's screens 01, 07, 09, 10 and 12 are the visual authority. Every difference is
  in P1–P11, in the detail files of 01 and 07, or in UI-base §9 rows 108–110.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens;
  - no raw colour, `TextStyle`, spacing or radius literal;
  - no `ref.read` inside `build`;
  - no literal user string;
  - booleans read as predicates;
  - no source file over 400 lines.
- File suffixes and buckets follow the guard: `_provider`, `_controller`, `_widget` in
  `overlays/`, `sections/` or `support/`.
- Every read and write goes through a use case (ADR-011 D4). `deck` and `card` never
  import `trash`.
- No message carries an id or a path (BR-CORE-005). The names shown are the person's
  own text.
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- Goldens render in the Linux container only. On Windows, run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **A TalkBack user deletes a card.** The Undo toast waits for them and does not time
   out after 8 seconds. Test: "under TalkBack a toast with an action stays (FE-B1 D14)".
2. **Two toasts in a row,** such as a delete followed by another command's toast. The
   second replaces the first instead of queueing behind a toast that stays. Test: "a new
   toast replaces the one on screen (FE-B1 D14)".
3. **The deck an item was in goes to the Trash before Undo is tapped.** Undo says why
   and leaves the item in the Trash. Tests: "a refused Undo says why…" (deck and card).
4. **Moving the open deck, or the card being edited, to the Trash.** The screen steps
   back and the toast survives. Tests: "deleting the open deck returns to its parent
   once (RF1)" and "Move to Trash from the editor returns to the card list with Undo".
5. **Move to Trash tapped twice.** The confirm spins and one batch is made. Tests: "Move
   to Trash spins while the deck moves, and moves once" and "Move to Trash spins while
   the cards move".

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/core/theme/foundations/app_durations.dart`, `lib/shared/widgets/mx_snackbar.dart` | 1 | toast duration, TalkBack persist, replace |
| `lib/features/deck/presentation/providers/undo_deck_deletion_use_case_provider.dart`, `…/controllers/deck_actions_controller.dart` | 2 | Undo for a deck |
| `lib/features/deck/presentation/widgets/{overlays/deck_action_sheet_widget,overlays/deck_delete_dialog_widget,support/deck_actions_flow_widget,support/deck_trashed_snackbar_widget}.dart` | 2 | the deck's Move to Trash, its toast and Undo |
| `lib/features/card/presentation/providers/undo_card_deletion_use_case_provider.dart`, `…/controllers/card_actions_controller.dart` | 3 | Undo for a card |
| `lib/features/card/presentation/widgets/{overlays/card_delete_dialog_widget,sections/card_list_section_widget,support/card_trashed_snackbar_widget}.dart` | 3 | the cards' Move to Trash, their toast and Undo |
| `lib/features/card/presentation/widgets/sections/{card_trash_section_widget,card_editor_form_widget}.dart`, `lib/app/router/app_router.dart` | 4 | the editor's "More" card; the detail closes with it |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | 2–5 | the copy |
| `tools/design/screen_states.json`, `docs/**` | 6 | captures 09 and 10, detail files, index, register, spec, WBS |

---


### Task 1: The toast's duration, TalkBack and replacing

**Files:**
- Modify: `lib/core/theme/foundations/app_durations.dart`
- Modify: `lib/shared/widgets/mx_snackbar.dart`
- Test (modify): `test/shared/widgets/mx_snackbar_test.dart`

**Interfaces:**
- Produces: `showMxSnackbar(context, {message, actionLabel, onAction, Duration duration =
  AppDurations.toast})` and `buildMxSnackBar(...)` with the same `duration`;
  `AppDurations.toast` (4 s) and `AppDurations.undoWindow` (8 s). A toast with an action
  persists under TalkBack; `showMxSnackbar` hides the current toast first (P1).

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_snackbar_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_snackbar_test.dart b/test/shared/widgets/mx_snackbar_test.dart
index 90bbaf5..0a84c3c 100644
--- a/test/shared/widgets/mx_snackbar_test.dart
+++ b/test/shared/widgets/mx_snackbar_test.dart
@@ -157,6 +157,92 @@ void main() {
     expect(tester.getSize(find.text(long)).height, greaterThan(oneLine));
   });
 
+  Future<void> pumpToasts(
+    WidgetTester tester,
+    List<({String message, bool hasUndo})> toasts, {
+    Duration duration = const Duration(seconds: 8),
+  }) async {
+    await pumpMx(
+      tester,
+      Builder(
+        builder: (context) => Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            for (final toast in toasts)
+              MxButton(
+                label: 'Show ${toast.message}',
+                onPressed: () => showMxSnackbar(
+                  context,
+                  message: toast.message,
+                  actionLabel: toast.hasUndo ? 'Undo' : null,
+                  onAction: toast.hasUndo ? () {} : null,
+                  duration: duration,
+                ),
+              ),
+          ],
+        ),
+      ),
+    );
+  }
+
+  testWidgets('a toast stays its duration, then goes (FE-B1 D3)', (
+    tester,
+  ) async {
+    await pumpToasts(tester, [(message: 'Moved to Trash', hasUndo: true)]);
+    await tester.tap(find.text('Show Moved to Trash'));
+    await tester.pumpAndSettle();
+
+    await tester.pump(const Duration(seconds: 7));
+    expect(find.text('Moved to Trash'), findsOneWidget);
+    await tester.pump(const Duration(seconds: 2));
+    await tester.pumpAndSettle();
+    expect(find.byType(SnackBar), findsNothing);
+  });
+
+  testWidgets('under TalkBack a toast with an action stays (FE-B1 D14)', (
+    tester,
+  ) async {
+    tester.platformDispatcher.accessibilityFeaturesTestValue =
+        const FakeAccessibilityFeatures(accessibleNavigation: true);
+    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
+    await pumpToasts(tester, [
+      (message: 'Moved to Trash', hasUndo: true),
+      (message: 'Saved', hasUndo: false),
+    ]);
+
+    await tester.tap(find.text('Show Moved to Trash'));
+    await tester.pumpAndSettle();
+    await tester.pump(const Duration(seconds: 30));
+    await tester.pumpAndSettle();
+    expect(find.text('Moved to Trash'), findsOneWidget);
+
+    // One without an action still goes.
+    await tester.tap(find.text('Show Saved'));
+    await tester.pumpAndSettle();
+    await tester.pump(const Duration(seconds: 9));
+    await tester.pumpAndSettle();
+    expect(find.byType(SnackBar), findsNothing);
+  });
+
+  testWidgets('a new toast replaces the one on screen (FE-B1 D14)', (
+    tester,
+  ) async {
+    tester.platformDispatcher.accessibilityFeaturesTestValue =
+        const FakeAccessibilityFeatures(accessibleNavigation: true);
+    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
+    await pumpToasts(tester, [
+      (message: 'Moved to Trash', hasUndo: true),
+      (message: 'Saved', hasUndo: false),
+    ]);
+
+    await tester.tap(find.text('Show Moved to Trash'));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text('Show Saved'));
+    await tester.pumpAndSettle();
+    expect(find.text('Moved to Trash'), findsNothing);
+    expect(find.text('Saved'), findsOneWidget);
+  });
+
   test('actionLabel and onAction come together', () {
     expect(
       () => MxSnackbarContent(message: 'Saved', actionLabel: 'Undo'),
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/shared/widgets/mx_snackbar_test.dart
```

Expected: FAIL to compile: `showMxSnackbar` has no `duration`.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_durations.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_durations.dart b/lib/core/theme/foundations/app_durations.dart
index fbc650b..23497b5 100644
--- a/lib/core/theme/foundations/app_durations.dart
+++ b/lib/core/theme/foundations/app_durations.dart
@@ -17,4 +17,10 @@ abstract final class AppDurations {
 
   /// One skeleton pulse, 0.45 to 0.75 opacity and back.
   static const Duration skeletonPulse = Duration(milliseconds: 1400);
+
+  /// How long a toast stays: the platform's 4 seconds.
+  static const Duration toast = Duration(milliseconds: 4000);
+
+  /// How long a toast offering Undo stays (FE-B1 D3).
+  static const Duration undoWindow = Duration(seconds: 8);
 }
```

`lib/shared/widgets/mx_snackbar.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_snackbar.dart b/lib/shared/widgets/mx_snackbar.dart
index b9df8e5..47f4311 100644
--- a/lib/shared/widgets/mx_snackbar.dart
+++ b/lib/shared/widgets/mx_snackbar.dart
@@ -1,4 +1,5 @@
 import 'package:flutter/material.dart';
+import 'package:memox/core/theme/foundations/app_durations.dart';
 import 'package:memox/core/theme/foundations/app_radius.dart';
 import 'package:memox/core/theme/foundations/app_size.dart';
 import 'package:memox/core/theme/foundations/app_spacing.dart';
@@ -9,32 +10,48 @@ const double _verticalPadding = 10;
 
 /// Shows the MemoX toast: a message and one optional action on the inverse
 /// surface, which does not flip with the theme. Tapping the action hides the
-/// toast first. How long it stays is the platform's call.
+/// toast first. It stays [duration], the platform's 4 seconds by default.
+///
+/// A new toast replaces the one on screen instead of queueing behind it, so
+/// a toast that stays for TalkBack never holds back the next (FE-B1 D14).
 ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMxSnackbar(
   BuildContext context, {
   required String message,
   String? actionLabel,
   VoidCallback? onAction,
-}) => ScaffoldMessenger.of(context).showSnackBar(
-  buildMxSnackBar(
-    context,
-    message: message,
-    actionLabel: actionLabel,
-    onAction: onAction,
-  ),
-);
+  Duration duration = AppDurations.toast,
+}) {
+  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
+  return messenger.showSnackBar(
+    buildMxSnackBar(
+      context,
+      message: message,
+      actionLabel: actionLabel,
+      onAction: onAction,
+      duration: duration,
+    ),
+  );
+}
 
 /// The platform SnackBar that [showMxSnackbar] shows, configured with the
 /// contract's surface (ruling O9).
+///
+/// A toast with an action stays until it is acted on or replaced while
+/// TalkBack is on, so the action can be reached (WCAG 2.2.1, FE-B1 D14).
+/// The action is drawn by [MxSnackbarContent], not [SnackBar.action], so
+/// the platform does not do this itself.
 SnackBar buildMxSnackBar(
   BuildContext context, {
   required String message,
   String? actionLabel,
   VoidCallback? onAction,
+  Duration duration = AppDurations.toast,
 }) {
   final messenger = ScaffoldMessenger.of(context);
   // The surface, float, inset and radius are the theme's (spec §4.6).
   return SnackBar(
+    duration: duration,
+    persist: onAction != null && MediaQuery.accessibleNavigationOf(context),
     // Only the message carries the 10 vertical padding (MxSnackbarContent),
     // so the action's 48 target sits inside the 48 toast.
     padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
```

- [ ] **Step 4: Run the tests and the whole suite**

```bash
flutter test test/shared/widgets/mx_snackbar_test.dart
flutter test
flutter analyze
```

Expected: PASS. The whole suite matters here: every toast in the app now replaces the
one before it, and none of the existing tests waits on a queue.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/theme/foundations/app_durations.dart \
  lib/shared/widgets/mx_snackbar.dart \
  test/shared/widgets/mx_snackbar_test.dart
git commit -m "$(cat <<'EOF'
feat(ui): toasts replace each other; an action waits under TalkBack (FE-B1 D14)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: A deck moves to the Trash, with Undo

**Files:**
- Modify: `lib/features/deck/presentation/controllers/deck_actions_controller.dart`
- Create: `lib/features/deck/presentation/providers/undo_deck_deletion_use_case_provider.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Create: `lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/features/deck/presentation/goldens/library_deck_actions_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_actions_light.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_delete_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_delete_light.png`
- Create: `test/features/deck/presentation/goldens/library_deck_trashed_dark.png`
- Create: `test/features/deck/presentation/goldens/library_deck_trashed_light.png`
- Test (modify): `test/app/library_routes_test.dart`
- Test (modify): `test/features/deck/presentation/deck_action_sheet_test.dart`
- Test (modify): `test/features/deck/presentation/deck_screens_golden_test.dart`
- Test (modify): `test/features/deck/presentation/open_deck_screen_test.dart`

**Interfaces:**
- Consumes: Task 1's `showMxSnackbar(duration:)` and `AppDurations.undoWindow`; BE-B1's
  `UndoDeckDeletionUseCase` and `DeleteDeckUseCase` (its value is the batch id).
- Produces: `undoDeckDeletionUseCaseProvider`;
  `DeckActionsController.undoDeckDeletion({required String batchId}) →
  Future<Outcome<void, DeckRejection>>`; `showDeckTrashedSnackbar(context, {deckName,
  summary, batchId})`; `commonUndo`, `deckDeleteHint`, `deckDeleteNote`,
  `deckTrashedToast`, `deckUndoRefused`; `deckDeleteTitle` loses its parameter;
  `deckDeleteSummary` gains `deck`; `deckDeletedToast` is removed.

- [ ] **Step 1: Write the failing tests**

`test/app/library_routes_test.dart` (apply this diff):

```diff
diff --git a/test/app/library_routes_test.dart b/test/app/library_routes_test.dart
index 74a3d6c..2d5d5e4 100644
--- a/test/app/library_routes_test.dart
+++ b/test/app/library_routes_test.dart
@@ -126,7 +126,9 @@ void main() {
     await _tap(tester, find.text(_en.deckDelete));
 
     expect(_barTitle('Words'), findsOneWidget);
-    expect(find.text(_en.deckDeletedToast), findsOneWidget);
+    // The toast with Undo survives the step back (FE-B1 D3).
+    expect(find.text(_en.deckTrashedToast('Verbs', 0, 0)), findsOneWidget);
+    expect(find.text(_en.commonUndo), findsOneWidget);
   });
 
   libraryTest('Review algorithm pushes screen 02; Back returns to the deck', (
```

`test/features/deck/presentation/deck_action_sheet_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_action_sheet_test.dart b/test/features/deck/presentation/deck_action_sheet_test.dart
index a162e1c..48bf930 100644
--- a/test/features/deck/presentation/deck_action_sheet_test.dart
+++ b/test/features/deck/presentation/deck_action_sheet_test.dart
@@ -3,6 +3,7 @@ import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
+import 'package:memox/shared/widgets/mx_spinner.dart';
 
 import '../../../support/card_fixtures.dart';
 import '../../../support/deck_fixtures.dart';
@@ -158,18 +159,22 @@ void main() {
     expect(find.text('Hàn Quốc'), findsNWidgets(2));
   });
 
-  libraryTest('Delete says what goes with the deck, then sends it to the '
-      'Trash', (tester, env) async {
+  libraryTest('Move to Trash says what goes with the deck, then offers '
+      'Undo (FE-B1)', (tester, env) async {
     final korean = await env.decks.root('Korean');
     final words = await env.decks.sub(korean.id, 'Words');
     final verbs = await env.decks.sub(words.id, 'Verbs');
     await insertCard(env.db, id: 'one', deckId: verbs.id);
     await insertCard(env.db, id: 'two', deckId: verbs.id);
     await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
-    await _choose(tester, _en.deckDelete);
+    await _openSheet(tester);
+    expect(find.text(_en.deckDeleteHint), findsOneWidget);
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pumpAndSettle();
 
-    expect(find.text(_en.deckDeleteTitle('Words')), findsOneWidget);
-    expect(find.text(_en.deckDeleteSummary(1, 2)), findsOneWidget);
+    expect(find.text(_en.deckDeleteTitle), findsOneWidget);
+    expect(find.text(_en.deckDeleteSummary('Words', 1, 2)), findsOneWidget);
+    expect(find.text(_en.deckDeleteNote), findsOneWidget);
     await tester.tap(find.text(_en.deckDelete));
     // The screen is the test's only route: nothing to pop back to.
     await tester.pump();
@@ -177,7 +182,77 @@ void main() {
     await tester.pump(const Duration(milliseconds: 500));
 
     expect(await _activeDeckCount(env), 1);
-    expect(find.text(_en.deckDeletedToast), findsOneWidget);
+    expect(find.text(_en.deckTrashedToast('Words', 1, 2)), findsOneWidget);
+    expect(find.text(_en.commonUndo), findsOneWidget);
+  });
+
+  libraryTest('Undo puts the deck back where it was (UC-TRASH-001 A1)', (
+    tester,
+    env,
+  ) async {
+    final korean = await env.decks.root('Korean');
+    final words = await env.decks.sub(korean.id, 'Words');
+    await env.decks.sub(words.id, 'Verbs');
+    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
+    await tester.tap(find.byTooltip(_en.deckMoreActions('Words')));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pumpAndSettle();
+    expect(await _activeDeckCount(env), 1);
+
+    await tester.tap(find.text(_en.commonUndo));
+    await tester.pumpAndSettle();
+    expect(await _activeDeckCount(env), 3);
+    expect(await _parentOf(env, words.id), korean.id);
+    expect(find.text('Words'), findsOneWidget);
+  });
+
+  libraryTest('a refused Undo says why; the deck stays in the Trash '
+      '(UC-TRASH-001 E3)', (tester, env) async {
+    final korean = await env.decks.root('Korean');
+    final words = await env.decks.sub(korean.id, 'Words');
+    final verbs = await env.decks.sub(words.id, 'Verbs');
+    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
+    await tester.tap(find.byTooltip(_en.deckMoreActions('Verbs')));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pumpAndSettle();
+    // Meanwhile the deck it was in goes to the Trash as well.
+    await env.decks.deleteDeck(deckId: words.id);
+
+    await tester.tap(find.text(_en.commonUndo));
+    await tester.pumpAndSettle();
+    expect(
+      find.text(_en.deckUndoRefused(_en.deckRejectionTargetInTrash)),
+      findsOneWidget,
+    );
+    expect(await _activeDeckCount(env), 1);
+    expect(await _parentOf(env, verbs.id), words.id);
+  });
+
+  libraryTest('Move to Trash spins while the deck moves, and moves once '
+      '(FE-B1 D15)', (tester, env) async {
+    final korean = await env.decks.root('Korean');
+    await env.decks.sub(korean.id, 'Words');
+    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
+    await tester.tap(find.byTooltip(_en.deckMoreActions('Words')));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckDelete));
+    await tester.pump();
+    expect(find.byType(MxSpinner), findsOneWidget);
+    await tester.pumpAndSettle();
+
+    final batches = await env.db
+        .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
+        .getSingle();
+    expect(batches.read<int>('n'), 1);
+    expect(find.text(_en.deckRejectionNotFound), findsNothing);
   });
 
   libraryTest('Move lists targets by path and moves there', (
@@ -314,6 +389,6 @@ void main() {
     await tester.pumpAndSettle();
 
     expect(find.text(_en.deckOpen), findsNothing);
-    expect(find.text(_en.deckDeletedToast), findsOneWidget);
+    expect(find.text(_en.deckGoneTitle), findsOneWidget);
   });
 }
```

`test/features/deck/presentation/deck_screens_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_screens_golden_test.dart b/test/features/deck/presentation/deck_screens_golden_test.dart
index f2fdbfc..627eed2 100644
--- a/test/features/deck/presentation/deck_screens_golden_test.dart
+++ b/test/features/deck/presentation/deck_screens_golden_test.dart
@@ -140,6 +140,28 @@ void main() {
       });
     });
 
+    libraryTest('moved to Trash with Undo, $theme', (tester, env) async {
+      final ids = await _seed(env);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(
+          tester,
+          env,
+          deckScreen(deckId: ids.words),
+          brightness,
+        );
+        await tester.tap(find.byTooltip(_en.deckActions));
+        await _settleOverlay(tester);
+        await tester.tap(find.text(_en.deckDelete));
+        await _settleOverlay(tester);
+        await tester.tap(find.text(_en.deckDelete));
+        await _settleOverlay(tester);
+        await expectBoundaryGolden(
+          tester,
+          'goldens/library_deck_trashed_$theme.png',
+        );
+      });
+    });
+
     libraryTest('Library at text scale 2, $theme', (tester, env) async {
       await _seed(env);
       await withRealShadows(() async {
```

`test/features/deck/presentation/open_deck_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/open_deck_screen_test.dart b/test/features/deck/presentation/open_deck_screen_test.dart
index de308d5..8935999 100644
--- a/test/features/deck/presentation/open_deck_screen_test.dart
+++ b/test/features/deck/presentation/open_deck_screen_test.dart
@@ -241,7 +241,7 @@ void main() {
     await tester.pumpAndSettle();
 
     expect(find.text(_en.deckGoneTitle), findsOneWidget);
-    expect(find.text(_en.deckDeletedToast), findsNothing);
+    expect(find.byType(SnackBar), findsNothing);
     // Trash waits under Coming soon (spec A4, amended): Back is the one way.
     expect(find.byType(MxButton), findsOneWidget);
     await tester.tap(find.text(_en.deckBackToLibrary));
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/deck/presentation/deck_action_sheet_test.dart
```

Expected: FAIL to compile: `deckDeleteHint`, `deckTrashedToast` and `commonUndo` do not
exist.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/controllers/deck_actions_controller.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/controllers/deck_actions_controller.dart b/lib/features/deck/presentation/controllers/deck_actions_controller.dart
index b68ab5a..a057291 100644
--- a/lib/features/deck/presentation/controllers/deck_actions_controller.dart
+++ b/lib/features/deck/presentation/controllers/deck_actions_controller.dart
@@ -10,6 +10,7 @@ import 'package:memox/features/srs/di/reset_learning_progress_use_case_provider.
 import 'package:memox/features/deck/presentation/providers/move_deck_use_case_provider.dart';
 import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
 import 'package:memox/features/deck/presentation/providers/rename_deck_use_case_provider.dart';
+import 'package:memox/features/deck/presentation/providers/undo_deck_deletion_use_case_provider.dart';
 import 'package:memox/features/deck/presentation/providers/create_sub_deck_use_case_provider.dart';
 import 'package:memox/features/srs/domain/failures/srs_failure.dart';
 import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
@@ -44,9 +45,14 @@ class DeckActionsController extends _$DeckActionsController {
     required String name,
   }) => ref.read(renameDeckUseCaseProvider)(deckId: deckId, name: name);
 
+  /// Moves the deck to the Trash; its value is the batch an Undo names.
   Future<Outcome<String, DeckRejection>> deleteDeck({required String deckId}) =>
       ref.read(deleteDeckUseCaseProvider)(deckId: deckId);
 
+  Future<Outcome<void, DeckRejection>> undoDeckDeletion({
+    required String batchId,
+  }) => ref.read(undoDeckDeletionUseCaseProvider)(batchId: batchId);
+
   Future<Outcome<void, DeckRejection>> moveDeck({
     required String deckId,
     required String newParentId,
```

`lib/features/deck/presentation/providers/undo_deck_deletion_use_case_provider.dart`:

```dart
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/undo_deck_deletion_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_deck_deletion_use_case_provider.g.dart';

@riverpod
UndoDeckDeletionUseCase undoDeckDeletionUseCase(Ref ref) =>
    UndoDeckDeletionUseCase(ref.watch(deckRepositoryProvider));
```

`lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
index 5479748..b1a68b5 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
@@ -156,10 +156,11 @@ class DeckActionSheetWidget extends StatelessWidget {
           subtitle: l10n.deckReorderHint,
           onTap: () => choose(DeckAction.reorder),
         ),
+      // Recoverable, so not destructive (FE-B1, kit 01).
       MxActionSheetCommandRow(
         icon: AppIcons.delete,
         label: l10n.deckDelete,
-        isDestructive: true,
+        subtitle: l10n.deckDeleteHint,
         onTap: () => choose(DeckAction.delete),
       ),
     ];
```

`lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
index cedb8d3..9e40dec 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
@@ -2,18 +2,22 @@ import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:memox/core/error/failure.dart';
 import 'package:memox/core/error/outcome.dart';
+import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/features/deck/domain/entities/deck_entity.dart';
+import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
 import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
 import 'package:memox/features/deck/presentation/providers/deck_deletion_summary_provider.dart';
 import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
+import 'package:memox/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart';
 import 'package:memox/l10n/failure_message.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_dialog.dart';
+import 'package:memox/shared/widgets/mx_note.dart';
 import 'package:memox/shared/widgets/mx_sheet_actions.dart';
 import 'package:memox/shared/widgets/mx_snackbar.dart';
 
-/// Asks before [deck] and everything below it are deleted for good. True
-/// once the deck is deleted.
+/// Asks before [deck] and everything below it move to the Trash. True once
+/// they have, and the toast offering Undo is up (FE-B1, kit 01).
 Future<bool> showDeleteDeckDialog(
   BuildContext context, {
   required DeckEntity deck,
@@ -25,7 +29,9 @@ Future<bool> showDeleteDeckDialog(
     false;
 
 /// The body states how many sub-decks and cards go with the deck
-/// (BR-DECK-023). The confirm waits for that count and is destructive.
+/// (BR-DECK-023). The confirm waits for that count; it is not destructive,
+/// since the Trash keeps them for 30 days, and it spins while the deck
+/// moves (FE-B1 D15).
 class DeckDeleteDialogWidget extends ConsumerStatefulWidget {
   const DeckDeleteDialogWidget({super.key, required this.deck});
 
@@ -40,15 +46,23 @@ class _DeckDeleteDialogWidgetState
     extends ConsumerState<DeckDeleteDialogWidget> {
   var _isDeleting = false;
 
-  Future<void> _delete() async {
+  Future<void> _delete(DeckDeletionSummary summary) async {
     setState(() => _isDeleting = true);
     try {
       final outcome = await ref
           .read(deckActionsControllerProvider.notifier)
           .deleteDeck(deckId: widget.deck.id);
       if (!mounted) return;
-      if (outcome case Rejected(:final reason)) {
-        showMxSnackbar(context, message: context.l10n.deckRejection(reason));
+      switch (outcome) {
+        case Ok(value: final batchId):
+          showDeckTrashedSnackbar(
+            context,
+            deckName: widget.deck.name,
+            summary: summary,
+            batchId: batchId,
+          );
+        case Rejected(:final reason):
+          showMxSnackbar(context, message: context.l10n.deckRejection(reason));
       }
       Navigator.of(context).pop(outcome is Ok);
     } on Failure catch (failure) {
@@ -62,8 +76,13 @@ class _DeckDeleteDialogWidgetState
   Widget build(BuildContext context) {
     final l10n = context.l10n;
     final summary = ref.watch(deckDeletionSummaryProvider(widget.deck.id));
+    final counted = switch (summary) {
+      AsyncData(value: Ok(:final value)) => value,
+      _ => null,
+    };
     final body = switch (summary) {
       AsyncData(value: Ok(:final value)) => l10n.deckDeleteSummary(
+        widget.deck.name,
         value.subDeckCount,
         value.cardCount,
       ),
@@ -72,16 +91,22 @@ class _DeckDeleteDialogWidgetState
         error is Failure ? l10n.failure(error) : l10n.failureUnknown,
       _ => null,
     };
-    final canDelete = summary.value is Ok && !_isDeleting;
     return MxDialog(
-      title: l10n.deckDeleteTitle(widget.deck.name),
+      title: l10n.deckDeleteTitle,
       body: body,
+      content: counted == null
+          ? null
+          : MxNote(icon: AppIcons.history, text: l10n.deckDeleteNote),
       actions: MxSheetActions(
         cancelLabel: l10n.commonCancel,
         onCancel: () => Navigator.of(context).pop(),
         confirmLabel: l10n.deckDelete,
-        isDestructive: true,
-        onConfirm: canDelete ? _delete : null,
+        confirmIcon: AppIcons.delete,
+        isConfirmLoading: _isDeleting,
+        onConfirm: switch (counted) {
+          final summary? when !_isDeleting => () => _delete(summary),
+          _ => null,
+        },
       ),
     );
   }
```

`lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
index 7bef261..ff00273 100644
--- a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
+++ b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
@@ -46,7 +46,7 @@ Future<void> openDeckActions(
     Rejected() => null,
   };
   if (view == null) {
-    showMxSnackbar(context, message: context.l10n.deckDeletedToast);
+    showMxSnackbar(context, message: context.l10n.deckGoneTitle);
     return;
   }
   // The open deck reorders its children; a row reorders its siblings.
@@ -83,8 +83,9 @@ Future<void> openDeckActions(
   }
 }
 
-/// Deleting the open deck steps back to its parent and says so (C-L5); a
-/// row's deck just leaves its list.
+/// Moving the open deck to the Trash steps back to its parent (C-L5); a
+/// row's deck just leaves its list. The dialog has shown the toast with
+/// Undo, which lives on the root navigator and so survives the step back.
 Future<void> _deleteDeck(
   BuildContext context, {
   required DeckView view,
@@ -93,12 +94,7 @@ Future<void> _deleteDeck(
   // Taken before the dialog: once the deck is gone its screen swaps its
   // content, and [context] with it.
   final navigator = Navigator.of(context);
-  final navigatorContext = navigator.context;
   final isDeleted = await showDeleteDeckDialog(context, deck: view.deck);
-  if (!isDeleted || !isOpenDeck || !navigatorContext.mounted) return;
-  showMxSnackbar(
-    navigatorContext,
-    message: navigatorContext.l10n.deckDeletedToast,
-  );
+  if (!isDeleted || !isOpenDeck || !navigator.mounted) return;
   await navigator.maybePop();
 }
```

`lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Says a deck went to the Trash, with what went with it, and offers Undo
/// for 8 seconds (FE-B1 D3, BR-TRASH-008).
///
/// The toast outlives the dialog and often the screen that showed it, so it
/// lives on the root navigator and Undo reads the app's container, not a
/// widget's.
void showDeckTrashedSnackbar(
  BuildContext context, {
  required String deckName,
  required DeckDeletionSummary summary,
  required String batchId,
}) {
  final host = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = context.l10n;
  showMxSnackbar(
    host,
    message: l10n.deckTrashedToast(
      deckName,
      summary.subDeckCount,
      summary.cardCount,
    ),
    actionLabel: l10n.commonUndo,
    duration: AppDurations.undoWindow,
    onAction: () => unawaited(_undo(host, container, batchId)),
  );
}

/// The deck goes back where it was; a refusal says why and leaves it in
/// the Trash (UC-TRASH-001 A1, E3).
Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  String batchId,
) async {
  try {
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .undoDeckDeletion(batchId: batchId);
    if (outcome case Rejected(:final reason) when host.mounted) {
      final l10n = host.l10n;
      showMxSnackbar(
        host,
        message: l10n.deckUndoRefused(l10n.deckRejection(reason)),
      );
    }
  } on Failure catch (failure) {
    if (host.mounted) showMxSnackbar(host, message: host.l10n.failure(failure));
  }
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 91cc984..c908d7a 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -36,6 +36,10 @@
   "@commonCancel": {
     "description": "Generic cancel action."
   },
+  "commonUndo": "Undo",
+  "@commonUndo": {
+    "description": "Snackbar action that reverses the last move to the Trash (BR-TRASH-008)."
+  },
   "commonRetry": "Retry",
   "@commonRetry": {
     "description": "Generic retry action after a failure."
@@ -248,10 +252,6 @@
   "@deckLoadErrorTitle": {
     "description": "Error state title when an open deck fails to load."
   },
-  "deckDeletedToast": "Deck deleted",
-  "@deckDeletedToast": {
-    "description": "Snackbar after the open deck is deleted."
-  },
   "deckCreateSub": "Create sub-deck",
   "@deckCreateSub": {
     "description": "Action that creates a deck inside the open deck."
@@ -317,22 +317,43 @@
   "@deckReorder": {
     "description": "Deck action sheet command that starts drag-to-reorder."
   },
-  "deckDelete": "Delete",
+  "deckDelete": "Move to Trash",
   "@deckDelete": {
-    "description": "Deck action sheet command and delete confirm."
+    "description": "Deck action sheet command and the confirm of its dialog (FE-B1, kit 01)."
+  },
+  "deckDeleteHint": "Recoverable for 30 days",
+  "@deckDeleteHint": {
+    "description": "Deck action sheet: the Move to Trash command's sub-line (kit 01)."
   },
-  "deckDeleteTitle": "Delete “{deck}”?",
+  "deckDeleteTitle": "Move this deck to Trash?",
   "@deckDeleteTitle": {
+    "description": "Move to Trash dialog title (kit 01)."
+  },
+  "deckDeleteSummary": "“{deck}” goes to Trash with {subDeckCount, plural, =0{no sub-decks} =1{its 1 sub-deck} other{its {subDeckCount} sub-decks}} and {cardCount, plural, =0{no cards} =1{1 card} other{{cardCount} cards}}.",
+  "@deckDeleteSummary": {
     "placeholders": {
       "deck": {
         "type": "String"
+      },
+      "subDeckCount": {
+        "type": "int"
+      },
+      "cardCount": {
+        "type": "int"
       }
     },
-    "description": "Delete dialog title; deck is the deck's name."
+    "description": "Move to Trash dialog body: what goes with the deck (BR-DECK-023, kit 01)."
   },
-  "deckDeleteSummary": "This permanently deletes {subDeckCount, plural, =0{no sub-decks} =1{1 sub-deck} other{{subDeckCount} sub-decks}} and {cardCount, plural, =0{no cards} =1{1 card} other{{cardCount} cards}}. This can't be undone.",
-  "@deckDeleteSummary": {
+  "deckDeleteNote": "Recoverable from Trash for 30 days. Any open study session on these cards ends.",
+  "@deckDeleteNote": {
+    "description": "Move to Trash dialog note (kit 01)."
+  },
+  "deckTrashedToast": "“{deck}” moved to Trash · {subDeckCount, plural, =0{no sub-decks} =1{1 sub-deck} other{{subDeckCount} sub-decks}}, {cardCount, plural, =0{no cards} =1{1 card} other{{cardCount} cards}}",
+  "@deckTrashedToast": {
     "placeholders": {
+      "deck": {
+        "type": "String"
+      },
       "subDeckCount": {
         "type": "int"
       },
@@ -340,7 +361,16 @@
         "type": "int"
       }
     },
-    "description": "Delete dialog body: what the delete takes with it."
+    "description": "Snackbar after a deck moves to the Trash, with Undo (FE-B1 D3, kit 01)."
+  },
+  "deckUndoRefused": "Can't undo. {reason} Restore it from Trash and choose a deck.",
+  "@deckUndoRefused": {
+    "placeholders": {
+      "reason": {
+        "type": "String"
+      }
+    },
+    "description": "Snackbar when Undo of a deck is refused; reason is the rejection sentence (UC-TRASH-001 E3)."
   },
   "srsRejectionUnsupportedAction": "This answer doesn't fit the deck's scheduler.",
   "@srsRejectionUnsupportedAction": {
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 416db2a..27300bf 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -9,6 +9,7 @@
   "placeholderBody": "Màn hình này đang được xây dựng.",
   "openGallery": "Thư viện component",
   "commonCancel": "Hủy",
+  "commonUndo": "Hoàn tác",
   "commonRetry": "Thử lại",
   "commonLoading": "Đang tải",
   "libraryCreateDeck": "Tạo bộ thẻ",
@@ -57,7 +58,6 @@
   "libraryReorderDone": "Xong",
   "deckActions": "Thao tác với bộ thẻ",
   "deckLoadErrorTitle": "Không mở được bộ thẻ này",
-  "deckDeletedToast": "Đã xoá bộ thẻ",
   "deckCreateSub": "Tạo bộ thẻ con",
   "deckCreateSubTitle": "Bộ thẻ con mới",
   "deckUnsetTitle": "Bộ thẻ này chứa gì?",
@@ -73,9 +73,13 @@
   "deckMoveEmptyBody": "Không bộ thẻ nào khác chứa được bộ thẻ này.",
   "deckMovedToast": "Đã chuyển vào {deck}",
   "deckReorder": "Sắp xếp lại",
-  "deckDelete": "Xoá",
-  "deckDeleteTitle": "Xoá “{deck}”?",
-  "deckDeleteSummary": "Thao tác này xoá vĩnh viễn {subDeckCount} bộ thẻ con và {cardCount} thẻ. Không thể hoàn tác.",
+  "deckDelete": "Chuyển vào Thùng rác",
+  "deckDeleteHint": "Khôi phục được trong 30 ngày",
+  "deckDeleteTitle": "Chuyển bộ thẻ này vào Thùng rác?",
+  "deckDeleteSummary": "“{deck}” chuyển vào Thùng rác cùng {subDeckCount} bộ thẻ con và {cardCount} thẻ.",
+  "deckDeleteNote": "Khôi phục được từ Thùng rác trong 30 ngày. Phiên học đang mở trên các thẻ này sẽ kết thúc.",
+  "deckTrashedToast": "Đã chuyển “{deck}” vào Thùng rác · {subDeckCount} bộ thẻ con, {cardCount} thẻ",
+  "deckUndoRefused": "Không thể hoàn tác. {reason} Hãy khôi phục từ Thùng rác và chọn một bộ thẻ.",
   "srsRejectionUnsupportedAction": "Câu trả lời này không hợp với bộ lập lịch của bộ thẻ.",
   "srsRejectionSchedulerLocked": "Bộ lập lịch đã khoá vì thẻ trong bộ này đã được ôn.",
   "srsRejectionStaleGeneration": "Lịch của bộ thẻ đã thay đổi. Hãy bắt đầu lại.",
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/features/deck
flutter test test/features/deck test/app test/l10n
flutter analyze
```

Expected: PASS. Four goldens change and two are new:
- `library_deck_actions_*`: the last row reads "Move to Trash" with "Recoverable for 30
  days", not in the destructive tone.
- `library_deck_delete_*`: compare with `docs/shared/ui/screen-handoff/img/01-deck-list/deckDelete-*`.
  The title is "Move this deck to Trash?", the body names the deck and its counts, and
  the history note sits above Cancel · "Move to Trash".
- `library_deck_trashed_*` (new): "“Words” moved to Trash · 1 sub-deck, 5 cards" with
  Undo over the gone state (P9).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/deck/presentation/controllers/deck_actions_controller.dart \
  lib/features/deck/presentation/providers/undo_deck_deletion_use_case_provider.dart \
  lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart \
  lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/app/library_routes_test.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/deck_screens_golden_test.dart \
  test/features/deck/presentation/open_deck_screen_test.dart \
  test/features/deck/presentation/goldens/library_deck_actions_dark.png \
  test/features/deck/presentation/goldens/library_deck_actions_light.png \
  test/features/deck/presentation/goldens/library_deck_delete_dark.png \
  test/features/deck/presentation/goldens/library_deck_delete_light.png \
  test/features/deck/presentation/goldens/library_deck_trashed_dark.png \
  test/features/deck/presentation/goldens/library_deck_trashed_light.png
git commit -m "$(cat <<'EOF'
feat(deck): a deck moves to the Trash, with Undo (FE-B1, UC-TRASH-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: Cards move to the Trash, with Undo for one

**Files:**
- Modify: `lib/features/card/presentation/controllers/card_actions_controller.dart`
- Create: `lib/features/card/presentation/providers/undo_card_deletion_use_case_provider.dart`
- Modify: `lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Create: `lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/features/card/presentation/goldens/card_list_bulk_failed_dark.png`
- Modify: `test/features/card/presentation/goldens/card_list_bulk_failed_light.png`
- Create: `test/features/card/presentation/goldens/card_list_trash_dialog_dark.png`
- Create: `test/features/card/presentation/goldens/card_list_trash_dialog_light.png`
- Create: `test/features/card/presentation/goldens/card_list_trashed_dark.png`
- Create: `test/features/card/presentation/goldens/card_list_trashed_light.png`
- Modify: `test/features/card/presentation/goldens/card_selection_dark.png`
- Modify: `test/features/card/presentation/goldens/card_selection_light.png`
- Test (modify): `test/features/card/presentation/card_bulk_actions_test.dart`
- Test (modify): `test/features/card/presentation/card_list_golden_test.dart`

**Interfaces:**
- Consumes: Task 1's toast; Task 2's `commonUndo`; BE-B1's `UndoCardDeletionUseCase` and
  `DeleteCardsUseCase` (one batch id per card).
- Produces: `undoCardDeletionUseCaseProvider`;
  `CardActionsController.undoCardDeletion({required String batchId})`;
  `typedef CardTrashPreview = ({String front, String back})`;
  `showDeleteCardsDialog(context, {required Set<String> cardIds, CardTrashPreview?
  preview})`; `showCardsTrashedSnackbar(context, {required List<String> batchIds,
  String? front})`; `cardDeleteNote`, `cardMoveToTrash`, `cardTrashedToast`,
  `cardsTrashedToast`, `cardUndoRefused`; `cardDelete` reads "Trash";
  `cardDeleteBody` and `cardDeletedToast` are removed.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_bulk_actions_test.dart` (apply this diff):

```diff
diff --git a/test/features/card/presentation/card_bulk_actions_test.dart b/test/features/card/presentation/card_bulk_actions_test.dart
index 0734911..472d2a8 100644
--- a/test/features/card/presentation/card_bulk_actions_test.dart
+++ b/test/features/card/presentation/card_bulk_actions_test.dart
@@ -6,6 +6,7 @@ import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/shared/widgets/mx_dialog.dart';
 import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
+import 'package:memox/shared/widgets/mx_spinner.dart';
 
 import '../../../support/card_fixtures.dart';
 import '../../../support/deck_fixtures.dart';
@@ -55,6 +56,9 @@ Future<int> _count(
             .getSingle())
         .read<int>('n');
 
+Future<int> _activeCount(LibraryEnv env) =>
+    _count(env, 'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL');
+
 Future<void> _select(WidgetTester tester, List<String> fronts) async {
   await tester.longPress(find.text(fronts.first));
   await tester.pumpAndSettle();
@@ -205,31 +209,89 @@ void main() {
     expect(find.text(_en.cardMovedToast(2, 'Verbs')), findsOneWidget);
   });
 
-  libraryTest('Delete asks with the count; Cancel keeps the selection', (
-    tester,
-    env,
-  ) async {
+  libraryTest('Trash asks with the count; Cancel keeps the selection; '
+      'several cards get no Undo (FE-B1 D4)', (tester, env) async {
     final ids = await _seed(env);
     await pumpLibraryScreen(tester, env, _section(ids.words));
     await _select(tester, ['annyeong', 'gamsa']);
     await _bulk(tester, _en.cardDelete);
 
     expect(find.text(_en.cardDeleteTitle(2)), findsOneWidget);
+    expect(find.text(_en.cardDeleteNote(2)), findsOneWidget);
     await tester.tap(_inDialog(_en.commonCancel));
     await tester.pumpAndSettle();
     expect(find.text(_en.cardSelectedOf(2, 3).toUpperCase()), findsOneWidget);
 
     await _bulk(tester, _en.cardDelete);
-    await tester.tap(_inDialog(_en.cardDelete));
+    await tester.tap(_inDialog(_en.cardMoveToTrash));
+    await tester.pumpAndSettle();
+    expect(await _activeCount(env), 2);
+    expect(find.text(_en.cardsTrashedToast(2)), findsOneWidget);
+    expect(find.text(_en.commonUndo), findsNothing);
+  });
+
+  libraryTest('one card shows its text; Undo puts it back (UC-TRASH-001 '
+      'A1)', (tester, env) async {
+    final ids = await _seed(env);
+    await pumpLibraryScreen(tester, env, _section(ids.words));
+    await _select(tester, ['annyeong']);
+    await _bulk(tester, _en.cardDelete);
+
+    expect(find.text(_en.cardDeleteTitle(1)), findsOneWidget);
+    expect(_inDialog('annyeong'), findsOneWidget);
+    expect(_inDialog('back'), findsOneWidget);
+    expect(find.text(_en.cardDeleteNote(1)), findsOneWidget);
+    await tester.tap(_inDialog(_en.cardMoveToTrash));
+    await tester.pumpAndSettle();
+    expect(await _activeCount(env), 3);
+    expect(find.text(_en.cardTrashedToast('annyeong')), findsOneWidget);
+
+    await tester.tap(find.text(_en.commonUndo));
+    await tester.pumpAndSettle();
+    expect(await _activeCount(env), 4);
+    expect(find.text('annyeong'), findsOneWidget);
+  });
+
+  libraryTest('a refused Undo says why; the card stays in the Trash '
+      '(UC-TRASH-001 E3)', (tester, env) async {
+    final ids = await _seed(env);
+    await pumpLibraryScreen(tester, env, _section(ids.words));
+    await _select(tester, ['annyeong']);
+    await _bulk(tester, _en.cardDelete);
+    await tester.tap(_inDialog(_en.cardMoveToTrash));
     await tester.pumpAndSettle();
+    // Meanwhile its deck goes to the Trash as well.
+    await env.decks.deleteDeck(deckId: ids.words);
+
+    await tester.tap(find.text(_en.commonUndo));
+    await tester.pumpAndSettle();
+    expect(
+      find.text(_en.cardUndoRefused(_en.cardRejectionTargetInTrash)),
+      findsOneWidget,
+    );
     expect(
       await _count(
         env,
-        'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
+        "SELECT COUNT(*) AS n FROM card WHERE id = 'new1' "
+        'AND delete_batch_id IS NULL',
       ),
-      2,
+      0,
     );
-    expect(find.text(_en.cardDeletedToast(2)), findsOneWidget);
+  });
+
+  libraryTest('Move to Trash spins while the cards move (FE-B1 D15)', (
+    tester,
+    env,
+  ) async {
+    final ids = await _seed(env);
+    await pumpLibraryScreen(tester, env, _section(ids.words));
+    await _select(tester, ['annyeong']);
+    await _bulk(tester, _en.cardDelete);
+    await tester.tap(_inDialog(_en.cardMoveToTrash));
+    await tester.pump();
+
+    expect(find.byType(MxSpinner), findsOneWidget);
+    await tester.pumpAndSettle();
   });
 
   libraryTest('the bulk bar meets the target guidelines', (tester, env) async {
```

`test/features/card/presentation/card_list_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/card/presentation/card_list_golden_test.dart b/test/features/card/presentation/card_list_golden_test.dart
index a6ff2f4..ce83013 100644
--- a/test/features/card/presentation/card_list_golden_test.dart
+++ b/test/features/card/presentation/card_list_golden_test.dart
@@ -116,6 +116,32 @@ void main() {
       });
     });
 
+    libraryTest('move a card to Trash, $theme', (tester, env) async {
+      final deckId = await _seed(env);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(
+          tester,
+          env,
+          cardDeckScreen(deckId),
+          brightness,
+        );
+        await tester.longPress(find.text('sarang'));
+        await _settle(tester);
+        await tester.tap(find.text(_en.cardDelete));
+        await _settle(tester);
+        await expectBoundaryGolden(
+          tester,
+          'goldens/card_list_trash_dialog_$theme.png',
+        );
+        await tester.tap(find.text(_en.cardMoveToTrash));
+        await _settle(tester);
+        await expectBoundaryGolden(
+          tester,
+          'goldens/card_list_trashed_$theme.png',
+        );
+      });
+    });
+
     libraryTest('card bulk failed, $theme', (tester, env) async {
       final deckId = await _seed(env);
       await withRealShadows(() async {
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/presentation/card_bulk_actions_test.dart
```

Expected: FAIL to compile: `cardMoveToTrash`, `cardsTrashedToast` and `MxSpinner`'s use
do not resolve.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/controllers/card_actions_controller.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/controllers/card_actions_controller.dart b/lib/features/card/presentation/controllers/card_actions_controller.dart
index b9c0975..7b18785 100644
--- a/lib/features/card/presentation/controllers/card_actions_controller.dart
+++ b/lib/features/card/presentation/controllers/card_actions_controller.dart
@@ -10,6 +10,7 @@ import 'package:memox/features/card/presentation/providers/edit_card_use_case_pr
 import 'package:memox/features/card/presentation/providers/move_cards_use_case_provider.dart';
 import 'package:memox/features/card/presentation/providers/select_all_card_ids_use_case_provider.dart';
 import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
+import 'package:memox/features/card/presentation/providers/undo_card_deletion_use_case_provider.dart';
 import 'package:memox/features/tags/domain/failures/tag_failure.dart';
 import 'package:riverpod_annotation/riverpod_annotation.dart';
 
@@ -54,10 +55,16 @@ class CardActionsController extends _$CardActionsController {
     targetDeckId: targetDeckId,
   );
 
+  /// Moves the cards to the Trash; its value is one batch per card, which
+  /// an Undo names.
   Future<Outcome<List<String>, CardRejection>> deleteCards({
     required Set<String> cardIds,
   }) => ref.read(deleteCardsUseCaseProvider)(cardIds: cardIds);
 
+  Future<Outcome<void, CardRejection>> undoCardDeletion({
+    required String batchId,
+  }) => ref.read(undoCardDeletionUseCaseProvider)(batchId: batchId);
+
   Future<Outcome<CardEntity, CardRejection>> createCard({
     required String deckId,
     required CardDraft draft,
```

`lib/features/card/presentation/providers/undo_card_deletion_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/undo_card_deletion_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_card_deletion_use_case_provider.g.dart';

@riverpod
UndoCardDeletionUseCase undoCardDeletionUseCase(Ref ref) =>
    UndoCardDeletionUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart b/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart
index b9cf42b..50c759c 100644
--- a/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart
+++ b/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart
@@ -2,30 +2,51 @@ import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:memox/core/error/failure.dart';
 import 'package:memox/core/error/outcome.dart';
+import 'package:memox/core/theme/foundations/app_icons.dart';
+import 'package:memox/core/theme/foundations/app_spacing.dart';
+import 'package:memox/core/theme/theme_context.dart';
 import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
 import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
+import 'package:memox/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart';
 import 'package:memox/l10n/failure_message.dart';
 import 'package:memox/l10n/l10n_context.dart';
+import 'package:memox/shared/widgets/mx_card.dart';
 import 'package:memox/shared/widgets/mx_dialog.dart';
+import 'package:memox/shared/widgets/mx_note.dart';
 import 'package:memox/shared/widgets/mx_sheet_actions.dart';
 import 'package:memox/shared/widgets/mx_snackbar.dart';
 
-/// Asks before the cards of [cardIds] and their history are deleted for
-/// good (IT-ORG-014). Completes true once they are gone.
+/// The one card a Move to Trash names: its front over its back (kit 07, 09).
+typedef CardTrashPreview = ({String front, String back});
+
+/// Asks before the cards of [cardIds] move to the Trash with their history
+/// (IT-ORG-014, FE-B1). A single card shows [preview] when the caller has
+/// it. Completes true once they have, and the toast is up.
 Future<bool> showDeleteCardsDialog(
   BuildContext context, {
   required Set<String> cardIds,
+  CardTrashPreview? preview,
 }) async =>
     await showMxDialog<bool>(
       context,
-      builder: (_) => CardDeleteDialogWidget(cardIds: cardIds),
+      builder: (_) => CardDeleteDialogWidget(
+        cardIds: cardIds,
+        preview: cardIds.length == 1 ? preview : null,
+      ),
     ) ??
     false;
 
+/// The confirm is not destructive, since the Trash keeps the cards for 30
+/// days, and it spins while they move (FE-B1 D15).
 class CardDeleteDialogWidget extends ConsumerStatefulWidget {
-  const CardDeleteDialogWidget({super.key, required this.cardIds});
+  const CardDeleteDialogWidget({
+    super.key,
+    required this.cardIds,
+    this.preview,
+  });
 
   final Set<String> cardIds;
+  final CardTrashPreview? preview;
 
   @override
   ConsumerState<CardDeleteDialogWidget> createState() =>
@@ -43,14 +64,16 @@ class _CardDeleteDialogWidgetState
           .read(cardActionsControllerProvider.notifier)
           .deleteCards(cardIds: widget.cardIds);
       if (!mounted) return;
-      final l10n = context.l10n;
-      showMxSnackbar(
-        context,
-        message: switch (outcome) {
-          Ok() => l10n.cardDeletedToast(widget.cardIds.length),
-          Rejected(:final reason) => l10n.cardRejection(reason),
-        },
-      );
+      switch (outcome) {
+        case Ok(value: final batchIds):
+          showCardsTrashedSnackbar(
+            context,
+            batchIds: batchIds,
+            front: widget.preview?.front,
+          );
+        case Rejected(:final reason):
+          showMxSnackbar(context, message: context.l10n.cardRejection(reason));
+      }
       Navigator.of(context).pop(outcome is Ok);
     } on Failure catch (failure) {
       if (!mounted) return;
@@ -62,16 +85,59 @@ class _CardDeleteDialogWidgetState
   @override
   Widget build(BuildContext context) {
     final l10n = context.l10n;
+    final count = widget.cardIds.length;
     return MxDialog(
-      title: l10n.cardDeleteTitle(widget.cardIds.length),
-      body: l10n.cardDeleteBody,
+      title: l10n.cardDeleteTitle(count),
+      content: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        spacing: AppSpacing.control,
+        children: [
+          if (widget.preview case final preview?) _Preview(preview: preview),
+          MxNote(icon: AppIcons.history, text: l10n.cardDeleteNote(count)),
+        ],
+      ),
       actions: MxSheetActions(
         cancelLabel: l10n.commonCancel,
         onCancel: () => Navigator.of(context).pop(false),
-        confirmLabel: l10n.cardDelete,
-        isDestructive: true,
+        confirmLabel: l10n.cardMoveToTrash,
+        confirmIcon: AppIcons.delete,
+        isConfirmLoading: _isDeleting,
         onConfirm: _isDeleting ? null : _delete,
       ),
     );
   }
 }
+
+/// The card's front over its back, as the list row shows them.
+class _Preview extends StatelessWidget {
+  const _Preview({required this.preview});
+
+  final CardTrashPreview preview;
+
+  static const int _maxLines = 2;
+
+  @override
+  Widget build(BuildContext context) {
+    final styles = context.textStyles;
+    return MxCard(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        spacing: AppSpacing.micro,
+        children: [
+          Text(
+            preview.front,
+            maxLines: _maxLines,
+            overflow: TextOverflow.ellipsis,
+            style: styles.contentTitle,
+          ),
+          Text(
+            preview.back,
+            maxLines: _maxLines,
+            overflow: TextOverflow.ellipsis,
+            style: styles.rowDescription,
+          ),
+        ],
+      ),
+    );
+  }
+}
```

`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
index 9f39731..7dc475b 100644
--- a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
@@ -159,6 +159,16 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
     if (await write && mounted) _selection().clear();
   }
 
+  /// The one selected card's text, when its row is loaded (kit 07).
+  CardTrashPreview? _previewOf(Set<String> selected) {
+    if (selected.length != 1) return null;
+    final id = selected.single;
+    for (final item in _lastView?.items ?? const <CardListItem>[]) {
+      if (item.id == id) return (front: item.front, back: item.back);
+    }
+    return null;
+  }
+
   /// The bulk bar's commands over [selected]: Move, Flag, Tag, Export,
   /// Delete (kit 07). Select all is in the app bar (spec A14).
   List<CardBulkAction> _bulkActions(Set<String> selected) {
@@ -200,7 +210,13 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
         icon: AppIcons.delete,
         label: l10n.cardDelete,
         onTap: () => unawaited(
-          _clearAfter(showDeleteCardsDialog(context, cardIds: selected)),
+          _clearAfter(
+            showDeleteCardsDialog(
+              context,
+              cardIds: selected,
+              preview: _previewOf(selected),
+            ),
+          ),
         ),
       ),
     ];
```

`lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Says cards went to the Trash (FE-B1 D3, D4). One card, named by its
/// [front] when the caller has it, gets Undo for 8 seconds; several do not
/// (BR-TRASH-008).
///
/// The toast outlives the dialog and often the screen that showed it, so it
/// lives on the root navigator and Undo reads the app's container, not a
/// widget's.
void showCardsTrashedSnackbar(
  BuildContext context, {
  required List<String> batchIds,
  String? front,
}) {
  final host = Navigator.of(context, rootNavigator: true).context;
  final l10n = context.l10n;
  if (batchIds case [final batchId]) {
    final container = ProviderScope.containerOf(context, listen: false);
    showMxSnackbar(
      host,
      message: front == null
          ? l10n.cardsTrashedToast(1)
          : l10n.cardTrashedToast(front),
      actionLabel: l10n.commonUndo,
      duration: AppDurations.undoWindow,
      onAction: () => unawaited(_undo(host, container, batchId)),
    );
    return;
  }
  showMxSnackbar(host, message: l10n.cardsTrashedToast(batchIds.length));
}

/// The card goes back into its deck; a refusal says why and leaves it in
/// the Trash (UC-TRASH-001 A1, E3).
Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  String batchId,
) async {
  try {
    final outcome = await container
        .read(cardActionsControllerProvider.notifier)
        .undoCardDeletion(batchId: batchId);
    if (outcome case Rejected(:final reason) when host.mounted) {
      final l10n = host.l10n;
      showMxSnackbar(
        host,
        message: l10n.cardUndoRefused(l10n.cardRejection(reason)),
      );
    }
  } on Failure catch (failure) {
    if (host.mounted) showMxSnackbar(host, message: host.l10n.failure(failure));
  }
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index c908d7a..a2403bd 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -507,9 +507,9 @@
   "@cardMove": {
     "description": "Bulk bar action."
   },
-  "cardDelete": "Delete",
+  "cardDelete": "Trash",
   "@cardDelete": {
-    "description": "Bulk bar action and delete confirm."
+    "description": "Bulk bar command that moves the selected cards to the Trash (FE-B1, kit 07)."
   },
   "cardFlagSet": "Flag cards",
   "@cardFlagSet": {
@@ -589,27 +589,54 @@
     },
     "description": "Snackbar after a move; deck is the target's name."
   },
-  "cardDeleteTitle": "{count, plural, =1{Delete 1 card?} other{Delete {count} cards?}}",
+  "cardDeleteTitle": "{count, plural, =1{Move this card to Trash?} other{Move {count} cards to Trash?}}",
   "@cardDeleteTitle": {
     "placeholders": {
       "count": {
         "type": "int"
       }
     },
-    "description": "Delete dialog title."
+    "description": "Move to Trash dialog title (kit 07)."
   },
-  "cardDeleteBody": "The cards and their learning history are deleted for good. This can't be undone.",
-  "@cardDeleteBody": {
-    "description": "Delete dialog body."
+  "cardDeleteNote": "{count, plural, =1{Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected.} other{Recoverable from Trash for 30 days, with their schedule and history. Other cards are unaffected.}}",
+  "@cardDeleteNote": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Move to Trash dialog note (kit 07)."
+  },
+  "cardMoveToTrash": "Move to Trash",
+  "@cardMoveToTrash": {
+    "description": "The Move to Trash dialog's confirm (kit 07, 09)."
+  },
+  "cardTrashedToast": "“{front}” moved to Trash",
+  "@cardTrashedToast": {
+    "placeholders": {
+      "front": {
+        "type": "String"
+      }
+    },
+    "description": "Snackbar after one card moves to the Trash, with Undo (FE-B1 D3); front is the card's front."
   },
-  "cardDeletedToast": "{count, plural, =1{1 card deleted} other{{count} cards deleted}}",
-  "@cardDeletedToast": {
+  "cardsTrashedToast": "{count, plural, =1{1 card moved to Trash} other{{count} cards moved to Trash}}",
+  "@cardsTrashedToast": {
     "placeholders": {
       "count": {
         "type": "int"
       }
     },
-    "description": "Snackbar after a delete."
+    "description": "Snackbar after cards move to the Trash (FE-B1 D4)."
+  },
+  "cardUndoRefused": "Can't undo. {reason} Restore it from Trash and choose a deck.",
+  "@cardUndoRefused": {
+    "placeholders": {
+      "reason": {
+        "type": "String"
+      }
+    },
+    "description": "Snackbar when Undo of a card is refused; reason is the rejection sentence (UC-TRASH-001 E3)."
   },
   "cardRejectionBlankContent": "Enter both the front and the back.",
   "@cardRejectionBlankContent": {
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 27300bf..e6c38ab 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -110,7 +110,7 @@
   "cardFlag": "Gắn cờ",
   "cardTag": "Nhãn",
   "cardMove": "Di chuyển",
-  "cardDelete": "Xoá",
+  "cardDelete": "Thùng rác",
   "cardFlagSet": "Gắn cờ các thẻ",
   "cardFlagClear": "Bỏ cờ",
   "cardFlaggedToast": "Đã gắn cờ {count} thẻ",
@@ -124,9 +124,12 @@
   "cardMoveEmptyTitle": "Không có nơi để chuyển",
   "cardMoveEmptyBody": "Không có bộ thẻ nào khác ở đây chứa được thẻ.",
   "cardMovedToast": "Đã chuyển {count} thẻ vào {deck}",
-  "cardDeleteTitle": "Xoá {count} thẻ?",
-  "cardDeleteBody": "Các thẻ và lịch sử học của chúng sẽ bị xoá vĩnh viễn. Không thể hoàn tác.",
-  "cardDeletedToast": "Đã xoá {count} thẻ",
+  "cardDeleteTitle": "{count, plural, other{Chuyển {count} thẻ vào Thùng rác?}}",
+  "cardDeleteNote": "{count, plural, other{Khôi phục được từ Thùng rác trong 30 ngày, cùng lịch ôn và lịch sử. Các thẻ khác không bị ảnh hưởng.}}",
+  "cardMoveToTrash": "Chuyển vào Thùng rác",
+  "cardTrashedToast": "Đã chuyển “{front}” vào Thùng rác",
+  "cardsTrashedToast": "{count, plural, other{Đã chuyển {count} thẻ vào Thùng rác}}",
+  "cardUndoRefused": "Không thể hoàn tác. {reason} Hãy khôi phục từ Thùng rác và chọn một bộ thẻ.",
   "cardRejectionBlankContent": "Hãy nhập cả mặt trước và mặt sau.",
   "cardRejectionNotACardContainer": "Bộ thẻ này chứa bộ thẻ con nên không chứa thẻ.",
   "cardRejectionNotFound": "Thẻ này không còn nữa.",
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/features/card
flutter test test/features/card test/app
flutter analyze
```

Expected: PASS. Four goldens change and four are new:
- `card_selection_*` and `card_list_bulk_failed_*`: the bulk bar ends with "Trash".
- `card_list_trash_dialog_*` (new): compare with
  `docs/shared/ui/screen-handoff/img/07-card-list/delCard-*`. The card's front is over its
  back, and the note is above Cancel · "Move to Trash".
- `card_list_trashed_*` (new): "“sarang” moved to Trash" with Undo.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/card/presentation/controllers/card_actions_controller.dart \
  lib/features/card/presentation/providers/undo_card_deletion_use_case_provider.dart \
  lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart \
  lib/features/card/presentation/widgets/sections/card_list_section_widget.dart \
  lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/card/presentation/card_bulk_actions_test.dart \
  test/features/card/presentation/card_list_golden_test.dart \
  test/features/card/presentation/goldens/card_list_bulk_failed_dark.png \
  test/features/card/presentation/goldens/card_list_bulk_failed_light.png \
  test/features/card/presentation/goldens/card_list_trash_dialog_dark.png \
  test/features/card/presentation/goldens/card_list_trash_dialog_light.png \
  test/features/card/presentation/goldens/card_list_trashed_dark.png \
  test/features/card/presentation/goldens/card_list_trashed_light.png \
  test/features/card/presentation/goldens/card_selection_dark.png \
  test/features/card/presentation/goldens/card_selection_light.png
git commit -m "$(cat <<'EOF'
feat(card): cards move to the Trash, with Undo for one (FE-B1, UC-TRASH-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: Move to Trash from the card editor

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`
- Create: `lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/card/presentation/goldens/card_editor_more_dark.png`
- Create: `test/features/card/presentation/goldens/card_editor_more_light.png`
- Create: `test/features/card/presentation/goldens/card_editor_trash_dialog_dark.png`
- Create: `test/features/card/presentation/goldens/card_editor_trash_dialog_light.png`
- Test (create): `test/app/trash_routes_test.dart`
- Test (modify): `test/features/card/presentation/card_editor_golden_test.dart`

**Interfaces:**
- Consumes: Task 3's `showDeleteCardsDialog` and `cardMoveToTrash`.
- Produces: `CardTrashSectionWidget({required CardEntity card})`, which pops the
  editor's route with `true` once the card has moved (P6); `app/`'s `_editCard`, which
  pops the card detail on that `true`; `cardEditMore`, `cardEditTrashTitle`,
  `cardEditTrashBody`; `test/app/trash_routes_test.dart` (P10).

- [ ] **Step 1: Write the failing tests**

`test/app/trash_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The routes around the Trash (FE-B1).
void main() {
  libraryTest('Move to Trash from the editor returns to the card list with '
      'Undo (FE-B1 D13)', (tester, env) async {
    final words = await env.decks.sub(
      (await env.decks.root('Korean')).id,
      'Words',
    );
    await insertCard(
      env.db,
      id: 'c0',
      deckId: words.id,
      front: 'bap',
      back: 'rice',
    );
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
    await _tap(tester, find.text('bap'));
    await _tap(tester, find.widgetWithText(MxButton, _en.cardEditAction));
    // An unsaved edit goes with the card: no discard prompt (P6).
    await tester.enterText(find.byType(EditableText).at(1), 'cooked rice');
    await tester.pump();
    // The More card is the editor's last block (kit 09).
    await tester.drag(
      find.byType(CardEditorFormWidget),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(MxButton, _en.cardMoveToTrash));
    expect(find.text(_en.cardDeleteTitle(1)), findsOneWidget);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.cardMoveToTrash),
      ),
    );

    expect(find.text(_en.cardDiscardTitle), findsNothing);
    expect(_barTitle('Words'), findsOneWidget);
    expect(find.text(_en.cardTrashedToast('bap')), findsOneWidget);
    await _tap(tester, find.text(_en.commonUndo));
    expect(find.text('bap'), findsOneWidget);
  });
}
```

`test/features/card/presentation/card_editor_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/card/presentation/card_editor_golden_test.dart b/test/features/card/presentation/card_editor_golden_test.dart
index 0a5c1ba..820991f 100644
--- a/test/features/card/presentation/card_editor_golden_test.dart
+++ b/test/features/card/presentation/card_editor_golden_test.dart
@@ -5,6 +5,7 @@ import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/features/card/domain/models/card_draft_model.dart';
 import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
+import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 
@@ -77,6 +78,39 @@ void main() {
       });
     });
 
+    libraryTest('card editor, Move to Trash, $theme', (tester, env) async {
+      final deckId = await _words(env);
+      final card = await env.cards.card(
+        deckId,
+        const CardDraft(front: 'gamsahamnida', back: 'thank you'),
+      );
+      await withRealShadows(() async {
+        await pumpLibraryGolden(
+          tester,
+          env,
+          CardEditorScreen.edit(cardId: card.id, deckContext: _context),
+          brightness,
+        );
+        await tester.pumpAndSettle();
+        // The More card is the form's last block (kit 09).
+        await tester.drag(
+          find.byType(CardEditorFormWidget),
+          const Offset(0, -2000),
+        );
+        await tester.pumpAndSettle();
+        await expectBoundaryGolden(
+          tester,
+          'goldens/card_editor_more_$theme.png',
+        );
+        await tester.tap(find.text(_en.cardMoveToTrash));
+        await tester.pumpAndSettle();
+        await expectBoundaryGolden(
+          tester,
+          'goldens/card_editor_trash_dialog_$theme.png',
+        );
+      });
+    });
+
     libraryTest('card editor, edit, $theme', (tester, env) async {
       final deckId = await _words(env);
       final card = await env.cards.card(
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/app/trash_routes_test.dart
```

Expected: FAIL: no button "Move to Trash" in the editor.

- [ ] **Step 3: Implement**

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index 8b8a40f..fa6defa 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -102,8 +102,7 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                     builder: (context, state) => CardDetailScreen(
                       cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                       deckContext: _deckContext,
-                      onEdit: (id) =>
-                          unawaited(context.push(AppRoutes.editCard(id))),
+                      onEdit: (id) => unawaited(_editCard(context, id)),
                     ),
                     routes: [
                       GoRoute(
@@ -208,6 +207,14 @@ StudyEntryScreen _studyEntry(String deckId) => StudyEntryScreen(
   ),
 );
 
+/// Opens the editor over the card detail. The editor closes with true when
+/// it moved the card to the Trash; the detail, whose card is gone, closes
+/// with it (FE-B1 D13).
+Future<void> _editCard(BuildContext context, String cardId) async {
+  final isTrashed = await context.push<bool>(AppRoutes.editCard(cardId));
+  if (isTrashed == true && context.mounted) context.pop();
+}
+
 /// The deck path over the card editor (ruling P4a-L7, spec D8).
 Widget _deckContext(String deckId, String currentLabel) =>
     DeckContextHeaderWidget(deckId: deckId, currentLabel: currentLabel);
```

`lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart b/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart
index 26bbb52..69f79f1 100644
--- a/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart
@@ -18,6 +18,7 @@ import 'package:memox/features/card/presentation/widgets/sections/card_field_wid
 import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
 import 'package:memox/features/card/presentation/widgets/sections/card_optional_fields_widget.dart';
 import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
+import 'package:memox/features/card/presentation/widgets/sections/card_trash_section_widget.dart';
 import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
 import 'package:memox/features/tags/domain/entities/tag_entity.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
@@ -383,6 +384,7 @@ class _CardEditorFormWidgetState extends ConsumerState<CardEditorFormWidget> {
       onPendingChanged: (isPending) =>
           setState(() => _hasPendingTag = isPending),
     ),
+    if (_card case final card?) CardTrashSectionWidget(card: card),
   ];
 
   /// One optional field's input, message and touch.
```

`lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Kit 09 "More": moves the card being edited to the Trash after the same
/// dialog as the list's (FE-B1 D13), then closes the editor with true, so
/// the page that opened it can close too.
class CardTrashSectionWidget extends StatelessWidget {
  const CardTrashSectionWidget({super.key, required this.card});

  final CardEntity card;

  Future<void> _move(BuildContext context) async {
    // Taken before the dialog: once the card is gone the editor swaps the
    // form for its gone state, and [context] with it. The edits are left
    // behind with the card, so the route closes without asking.
    final navigator = Navigator.of(context);
    final isMoved = await showDeleteCardsDialog(
      context,
      cardIds: {card.id},
      preview: (front: card.front, back: card.back),
    );
    if (isMoved && navigator.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The overline sits as the editor's "Optional details" does.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.micro,
              0,
              AppSpacing.micro,
              AppSpacing.control,
            ),
            child: Text(
              l10n.cardEditMore.toUpperCase(),
              semanticsLabel: l10n.cardEditMore,
              style: styles.overline,
            ),
          ),
          MxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(l10n.cardEditTrashTitle, style: styles.rowTitle),
                Text(l10n.cardEditTrashBody, style: styles.rowDescription),
                const SizedBox(height: AppSpacing.control),
                MxButton(
                  label: l10n.cardMoveToTrash,
                  icon: AppIcons.delete,
                  tone: MxButtonTone.outline,
                  size: MxButtonSize.small,
                  onPressed: () => unawaited(_move(context)),
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

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index a2403bd..6a15d7d 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -638,6 +638,18 @@
     },
     "description": "Snackbar when Undo of a card is refused; reason is the rejection sentence (UC-TRASH-001 E3)."
   },
+  "cardEditMore": "More",
+  "@cardEditMore": {
+    "description": "Card editor, edit mode: the overline over the Move to Trash card (FE-B1 D13, kit 09)."
+  },
+  "cardEditTrashTitle": "Move this card to Trash",
+  "@cardEditTrashTitle": {
+    "description": "Card editor, edit mode: the Move to Trash card title (kit 09)."
+  },
+  "cardEditTrashBody": "Leaves this deck and can be restored from Trash for 30 days, schedule and history included.",
+  "@cardEditTrashBody": {
+    "description": "Card editor, edit mode: what Move to Trash does (kit 09; the deck path above names the deck)."
+  },
   "cardRejectionBlankContent": "Enter both the front and the back.",
   "@cardRejectionBlankContent": {
     "description": "Card refusal: blank content."
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index e6c38ab..7441be2 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -130,6 +130,9 @@
   "cardTrashedToast": "Đã chuyển “{front}” vào Thùng rác",
   "cardsTrashedToast": "{count, plural, other{Đã chuyển {count} thẻ vào Thùng rác}}",
   "cardUndoRefused": "Không thể hoàn tác. {reason} Hãy khôi phục từ Thùng rác và chọn một bộ thẻ.",
+  "cardEditMore": "Khác",
+  "cardEditTrashTitle": "Chuyển thẻ này vào Thùng rác",
+  "cardEditTrashBody": "Rời bộ thẻ này và khôi phục được từ Thùng rác trong 30 ngày, kể cả lịch ôn và lịch sử.",
   "cardRejectionBlankContent": "Hãy nhập cả mặt trước và mặt sau.",
   "cardRejectionNotACardContainer": "Bộ thẻ này chứa bộ thẻ con nên không chứa thẻ.",
   "cardRejectionNotFound": "Thẻ này không còn nữa.",
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features/card/presentation/card_editor_golden_test.dart
flutter test test/features/card test/app
flutter analyze
```

Expected: PASS. Four new goldens:
- `card_editor_more_*`: the "MORE" overline, then "Move this card to Trash", its line,
  and an outline "Move to Trash".
- `card_editor_trash_dialog_*`: the one-card dialog, as in Task 3. Compare with
  `docs/shared/ui/screen-handoff/img/09-card-edit/delConfirm-*` (Task 6 captures it).

`card_editor_edit_*` does not change, because the "More" card is below the fold.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/router/app_router.dart \
  lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart \
  lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/app/trash_routes_test.dart \
  test/features/card/presentation/card_editor_golden_test.dart \
  test/features/card/presentation/goldens/card_editor_more_dark.png \
  test/features/card/presentation/goldens/card_editor_more_light.png \
  test/features/card/presentation/goldens/card_editor_trash_dialog_dark.png \
  test/features/card/presentation/goldens/card_editor_trash_dialog_light.png
git commit -m "$(cat <<'EOF'
feat(card): Move to Trash from the card editor (FE-B1 D13)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: The gone states and the stale export say Trash

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/features/deck/presentation/goldens/library_deck_trashed_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_trashed_light.png`
- Modify: `test/features/transfer/presentation/goldens/export_stale_dark.png`
- Modify: `test/features/transfer/presentation/goldens/export_stale_light.png`

**Interfaces:**
- Produces: the new English and Vietnamese values of `deckGoneBody`, `cardGoneBody`,
  `cardDeckGoneBody`, `cardDetailGoneBody` and `exportStaleBody` (D11, D12). No key is
  added or removed.

- [ ] **Step 1: Change the copy**

No new test. Every one of these messages is already asserted through its key, and the
goldens show the new text.

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 6a15d7d..7b4fe29 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -935,17 +935,17 @@
   "@cardGoneTitle": {
     "description": "Editor state when the card was deleted meanwhile."
   },
-  "cardGoneBody": "It was deleted while you were editing. Your changes were not saved.",
+  "cardGoneBody": "It was moved to Trash while you were editing. Your unsaved changes were not applied; the card can still be restored from Trash.",
   "@cardGoneBody": {
-    "description": "Body of the gone card state."
+    "description": "Editor state when the card went to the Trash meanwhile (FE-B1 D11, kit 09)."
   },
   "cardDeckGoneTitle": "This deck is no longer here",
   "@cardDeckGoneTitle": {
     "description": "Editor state when the deck was deleted meanwhile."
   },
-  "cardDeckGoneBody": "It was deleted while you were adding cards. This card was not saved.",
+  "cardDeckGoneBody": "It was moved to Trash or deleted while you were adding cards. This card was not saved.",
   "@cardDeckGoneBody": {
-    "description": "Body of the gone deck state."
+    "description": "Editor state when the deck went to the Trash meanwhile (FE-B1 D11)."
   },
   "cardBackToDeck": "Back to deck",
   "@cardBackToDeck": {
@@ -1046,9 +1046,9 @@
   "@cardFlaggedLabel": {
     "description": "Accessible name of the flag glyph on a flagged card."
   },
-  "cardDetailGoneBody": "It was deleted while this page was open.",
+  "cardDetailGoneBody": "It was moved to Trash while you were away. It can still be restored from Trash, with its history.",
   "@cardDetailGoneBody": {
-    "description": "Body of the card detail's gone state."
+    "description": "Card detail state when the card went to the Trash meanwhile (FE-B1 D11, kit 10)."
   },
   "cardScheduleBox": "Current schedule · Box {box} of {count}",
   "@cardScheduleBox": {
@@ -1487,9 +1487,9 @@
   "@deckGoneTitle": {
     "description": "Screen handoff 01/04 (library alignment phase C): deckGoneTitle."
   },
-  "deckGoneBody": "It was deleted while you were away.",
+  "deckGoneBody": "It was moved to Trash or deleted while you were away. Anything in Trash can still be restored.",
   "@deckGoneBody": {
-    "description": "Screen handoff 01/04 (library alignment phase C): deckGoneBody."
+    "description": "Deck state when the deck went to the Trash meanwhile (FE-B1 D11, kit 01)."
   },
   "deckBackToLibrary": "Back to Library",
   "@deckBackToLibrary": {
@@ -3433,7 +3433,7 @@
   "@exportStaleTitle": {
     "description": "Export banner: a selected card is gone or moved (E6)."
   },
-  "exportStaleBody": "It was moved or deleted meanwhile. Nothing was exported. Refresh the selection and export again.",
+  "exportStaleBody": "It was moved to another deck or sent to Trash meanwhile. Nothing was exported. Refresh the selection and export again.",
   "@exportStaleBody": {
     "description": "Export banner body for E6."
   },
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 7441be2..ff4523c 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -199,9 +199,9 @@
   "cardDeckRejectsTitle": "Bộ thẻ này không còn nhận thẻ.",
   "cardDeckRejectsBody": "Giờ nó chứa các bộ thẻ con.",
   "cardGoneTitle": "Thẻ này không còn nữa",
-  "cardGoneBody": "Thẻ đã bị xoá trong lúc bạn sửa. Các thay đổi chưa được lưu.",
+  "cardGoneBody": "Thẻ đã được chuyển vào Thùng rác trong lúc bạn sửa. Các thay đổi chưa lưu không được áp dụng; thẻ vẫn khôi phục được từ Thùng rác.",
   "cardDeckGoneTitle": "Bộ thẻ này không còn nữa",
-  "cardDeckGoneBody": "Bộ thẻ đã bị xoá trong lúc bạn thêm thẻ. Thẻ này chưa được lưu.",
+  "cardDeckGoneBody": "Bộ thẻ đã được chuyển vào Thùng rác hoặc bị xoá trong lúc bạn thêm thẻ. Thẻ này chưa được lưu.",
   "cardBackToDeck": "Về bộ thẻ",
   "cardDiscardTitle": "Bỏ các thay đổi?",
   "cardDiscardBody": "Rời đi bây giờ thì thẻ giữ nguyên như lần lưu trước.",
@@ -223,7 +223,7 @@
   "cardDetailTitle": "Thẻ",
   "cardEditAction": "Sửa",
   "cardFlaggedLabel": "Đã gắn cờ",
-  "cardDetailGoneBody": "Thẻ đã bị xoá trong lúc trang này đang mở.",
+  "cardDetailGoneBody": "Thẻ đã được chuyển vào Thùng rác trong lúc bạn không ở đây. Thẻ vẫn khôi phục được từ Thùng rác, cùng lịch sử.",
   "cardScheduleBox": "Lịch hiện tại · Hộp {box}/{count}",
   "cardScheduleSm2": "Lịch hiện tại · SM-2",
   "cardBoxRampStart": "Hộp 1 · 1 ngày",
@@ -303,7 +303,7 @@
   "deckScheduledCount": "· {count} đã lên lịch",
   "deckDepthHeader": "{count} bộ thẻ con · cấp 10",
   "deckGoneTitle": "Bộ thẻ này không còn nữa",
-  "deckGoneBody": "Nó đã bị xoá trong lúc bạn không ở đây.",
+  "deckGoneBody": "Bộ thẻ đã được chuyển vào Thùng rác hoặc bị xoá trong lúc bạn không ở đây. Mọi thứ trong Thùng rác vẫn khôi phục được.",
   "deckBackToLibrary": "Về Thư viện",
   "searchFinds": "Tìm kiếm tìm được",
   "searchHintDeckName": "tên một bộ thẻ",
@@ -683,7 +683,7 @@
   "exportNoTargetTitle": "Không ứng dụng nào trên máy nhận được tệp",
   "exportNoTargetBody": "Hãy cài một ứng dụng quản lý tệp, lưu trữ hoặc email, rồi xuất lại.",
   "exportStaleTitle": "Một thẻ đã chọn không còn trong bộ thẻ này",
-  "exportStaleBody": "Thẻ đó vừa bị chuyển hoặc xoá. Chưa xuất gì. Hãy chọn lại rồi xuất lần nữa.",
+  "exportStaleBody": "Thẻ đó vừa được chuyển sang bộ thẻ khác hoặc vào Thùng rác. Chưa xuất gì. Hãy chọn lại rồi xuất lần nữa.",
   "exportEmptyTitle": "Không có gì để xuất",
   "exportEmptyBody": "Bộ thẻ này chưa có thẻ. Hãy thêm hoặc nhập thẻ trước.",
   "deckActionExport": "Xuất thẻ",
```

- [ ] **Step 2: Generate, render the goldens, run the whole suite**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features test/app test/visual_audit
flutter test
```

Expected: PASS. Four goldens change, and only these:
- `export_stale_*`: "It was moved to another deck or sent to Trash meanwhile…".
- `library_deck_trashed_*`: the gone state behind the toast reads "It was moved to Trash
  or deleted while you were away…".

- [ ] **Step 3: Commit**

```bash
git add \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/deck/presentation/goldens/library_deck_trashed_dark.png \
  test/features/deck/presentation/goldens/library_deck_trashed_light.png \
  test/features/transfer/presentation/goldens/export_stale_dark.png \
  test/features/transfer/presentation/goldens/export_stale_light.png
git commit -m "$(cat <<'EOF'
feat(l10n): the gone states and the stale export say Trash (FE-B1 D11, D12)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 6: Captures, detail files, register, spec and WBS; the gate

**Files:**
- Modify: `tools/design/screen_states.json`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md`
- Modify: `docs/shared/ui/screen-handoff/12-card-export.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/superpowers/specs/2026-09-26-trash-ui-design.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/shared/ui/screen-handoff/img/{09-card-edit,10-card-detail}/*.png (6 files)`
- Modify: `docs/_generated/traceability.md (generated)`

**Interfaces:** none (documents).

- [ ] **Step 1: Capture the kit's Trash states of screens 09 and 10**

`tools/design/screen_states.json` (apply this diff):

```diff
diff --git a/tools/design/screen_states.json b/tools/design/screen_states.json
index d436112..96abb1a 100644
--- a/tools/design/screen_states.json
+++ b/tools/design/screen_states.json
@@ -102,6 +102,23 @@
         { "id": "delDeck", "label": "Deck → Trash" }
       ]
     },
+    {
+      "num": "09",
+      "dir": "09-card-edit",
+      "title": "Card edit",
+      "states": [
+        { "id": "delConfirm", "label": "Move to Trash" },
+        { "id": "notFound", "label": "Card gone" }
+      ]
+    },
+    {
+      "num": "10",
+      "dir": "10-card-detail",
+      "title": "Card detail",
+      "states": [
+        { "id": "notFound", "label": "Not found" }
+      ]
+    },
     {
       "num": "11",
       "dir": "11-card-import",
```

```bash
node tools/design/capture_screens.mjs --html <artifact.html> --only 09,10
```

Expected: six images under `docs/shared/ui/screen-handoff/img/09-card-edit/` and
`…/10-card-detail/`.

- [ ] **Step 2: Update the documents**

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 67ec3aa..49b35ac 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -35,10 +35,10 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 03 | Starter decks | 10 | FE-B4 | out of V8 | — |
 | 04 | Library search | 5 | FE-A1, FE-A10 | aligned | [04-library-search.md](04-library-search.md) |
 | 05 | Tags | 12 | FE-B2 | out of V8 | — |
-| 06 | Trash | 15 | FE-B1 | out of V8 | — |
+| 06 | Trash | 15 | FE-B1 | not built | — (FE-B1 plan 2) |
 | 07 | Card list | 15 | FE-A2 | aligned | [07-card-list.md](07-card-list.md) |
 | 08 | Card create | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
-| 09 | Card edit | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
+| 09 | Card edit | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84; Move to Trash in [07-card-list.md](07-card-list.md)) |
 | 10 | Card detail | 7 | FE-A2 | built | — (#35, #36; UI-base §9 rows 85–90) |
 | 11 | Card import | 16 | FE-B3 | aligned | [11-card-import.md](11-card-import.md) |
 | 12 | Card export | 9 | FE-B3 | aligned | [12-card-export.md](12-card-export.md) |
@@ -64,7 +64,7 @@ The screens of the V3 handoff. The generated handoff next to this folder
   sheet names each such feature (spec A4, amended 2026-09-25).
 - **Data displays without their data** are hidden, never drawn empty: an empty mastery
   bar would claim 0 % (spec A5).
-- **Delete is permanent in V8.0** (BR-DECK-022, BR-DECK-023). Every "Move to Trash",
-  "Recoverable for 30 days" and "Undo" of the artifact becomes a permanent delete with
-  a count, until the Trash sub-project (UC-TRASH-001).
+- **Delete moves to the Trash** (UC-TRASH-001). "Move to Trash", "Recoverable for 30
+  days" and "Undo" are built as the artifact draws them: Undo after one item, for 8
+  seconds and until acted on under TalkBack (FE-B1 D3, D14).
 - **Copy** is the artifact's English; Vietnamese is added to the ARB with the screen.
```

`docs/shared/ui/screen-handoff/01-deck-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/01-deck-list.md b/docs/shared/ui/screen-handoff/01-deck-list.md
index a320899..cd087e7 100644
--- a/docs/shared/ui/screen-handoff/01-deck-list.md
+++ b/docs/shared/ui/screen-handoff/01-deck-list.md
@@ -34,9 +34,10 @@ One recursive screen for the Library root (`/decks`) and any open deck
 
 - **Root deck:** Open deck · Study this deck → screen 14 · Rename · Review algorithm
   ("{algorithm} · locked · reset to start over" when locked) → screen 02 · Reorder ·
-  Delete.
+  Move to Trash ("Recoverable for 30 days").
 - **Sub-deck:** Open ("N sub-decks · N cards") · Study this deck → screen 14 · Rename ·
-  Move to another deck · Reorder ("Move before or after a sibling") · Delete.
+  Move to another deck · Reorder ("Move before or after a sibling") · Move to Trash
+  ("Recoverable for 30 days").
 
 ## Sort & filter sheet
 
@@ -60,27 +61,28 @@ One `MxBottomSheet`, "Sort & filter":
 | rootSearch | ![](img/01-deck-list/rootSearch-light.png) | ![](img/01-deck-list/rootSearch-dark.png) | The field is a trigger: a tap opens screen 04 instead of typing here. |
 | rootSortFilter | ![](img/01-deck-list/rootSortFilter-light.png) | ![](img/01-deck-list/rootSortFilter-dark.png) | No "Progress" sort (Coming soon). |
 | rootDueEmpty | ![](img/01-deck-list/rootDueEmpty-light.png) | ![](img/01-deck-list/rootDueEmpty-dark.png) | As drawn. |
-| rootOverflow | ![](img/01-deck-list/rootOverflow-light.png) | ![](img/01-deck-list/rootOverflow-dark.png) | Rows as in "Action sheet"; Reorder added; Delete replaces Move to Trash. |
+| rootOverflow | ![](img/01-deck-list/rootOverflow-light.png) | ![](img/01-deck-list/rootOverflow-dark.png) | Rows as in "Action sheet"; Reorder added. |
 | rootCreate | ![](img/01-deck-list/rootCreate-light.png) | ![](img/01-deck-list/rootCreate-dark.png) | As drawn (BR-SRS-001). |
 | rootRename | ![](img/01-deck-list/rootRename-light.png) | ![](img/01-deck-list/rootRename-dark.png) | As drawn. |
-| rootDelete | ![](img/01-deck-list/rootDelete-light.png) | ![](img/01-deck-list/rootDelete-dark.png) | **Deviation:** permanent delete. |
+| rootDelete | ![](img/01-deck-list/rootDelete-light.png) | ![](img/01-deck-list/rootDelete-dark.png) | Moves to the Trash (UC-TRASH-001). The dialog has no glyph and names the deck in quotes, not bold. The confirm spins while the deck moves (FE-B1 D15). |
+| rootTrashed | ![](img/01-deck-list/rootTrashed-light.png) | ![](img/01-deck-list/rootTrashed-dark.png) | As drawn: Undo for 8 seconds, and until acted on under TalkBack (FE-B1 D3, D14). A refused Undo says why: "Can't undo. {reason} Restore it from Trash and choose a deck." |
 | deckLoaded | ![](img/01-deck-list/deckLoaded-light.png) | ![](img/01-deck-list/deckLoaded-dark.png) | No donut, no "Mastered". |
 | deckEmpty | ![](img/01-deck-list/deckEmpty-light.png) | ![](img/01-deck-list/deckEmpty-dark.png) | `unset` deck: both create choices and "Import cards from a file" (screen 11). |
 | deckMaxDepth | ![](img/01-deck-list/deckMaxDepth-light.png) | ![](img/01-deck-list/deckMaxDepth-dark.png) | No FAB. |
 | deckLoading | ![](img/01-deck-list/deckLoading-light.png) | ![](img/01-deck-list/deckLoading-dark.png) | As drawn. |
 | deckError | ![](img/01-deck-list/deckError-light.png) | ![](img/01-deck-list/deckError-dark.png) | As drawn. |
-| deckNotFound | ![](img/01-deck-list/deckNotFound-light.png) | ![](img/01-deck-list/deckNotFound-dark.png) | Back to Library only; replaces ruling P2-L7. |
-| deckOverflow | ![](img/01-deck-list/deckOverflow-light.png) | ![](img/01-deck-list/deckOverflow-dark.png) | Delete replaces Move to Trash. |
+| deckNotFound | ![](img/01-deck-list/deckNotFound-light.png) | ![](img/01-deck-list/deckNotFound-dark.png) | The kit's body. Back to Library only until FE-B1 plan 2 adds Open Trash; replaces ruling P2-L7. |
+| deckOverflow | ![](img/01-deck-list/deckOverflow-light.png) | ![](img/01-deck-list/deckOverflow-dark.png) | As drawn. |
 | deckMove | ![](img/01-deck-list/deckMove-light.png) | ![](img/01-deck-list/deckMove-dark.png) | As drawn (UC-DECK-005 checks). |
-| deckDelete | ![](img/01-deck-list/deckDelete-light.png) | ![](img/01-deck-list/deckDelete-dark.png) | **Deviation:** permanent delete. |
-
-Not captured: `rootTrashed`, `deckTrashed` (Undo after Move to Trash; no Trash in V8.0).
+| deckDelete | ![](img/01-deck-list/deckDelete-light.png) | ![](img/01-deck-list/deckDelete-dark.png) | As rootDelete. |
+| deckTrashed | ![](img/01-deck-list/deckTrashed-light.png) | ![](img/01-deck-list/deckTrashed-dark.png) | As rootTrashed. Moving the open deck steps back to its parent first (C-L5); the toast survives the step back. |
 
 ## Deviations
 
 | Artifact | V8 | Wins |
 |---|---|---|
-| "Move to Trash", "Recoverable for 30 days", neutral confirm, Undo snackbar | "Delete deck?" naming the sub-deck and card counts, destructive confirm, no Undo | BR-DECK-022, BR-DECK-023 |
+| A trash glyph over the Move to Trash dialog's title, the deck's name in bold | No glyph; the name in quotes | `MxDialog` has no glyph slot; no per-site text styling |
+| "Can't undo — “{deck}” is in Trash too. Restore it from here and choose a deck." on screen 06 | "Can't undo. {reason} Restore it from Trash and choose a deck." where the deck was deleted | An Undo happens where the item was deleted; the rejection carries no deck name (FE-B1 D7) |
 | Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
 | Root search hint "Search decks, cards, tags" | "Search decks" | Spec A11 (waits for FE-A10) |
 | No reorder entry at the root | Reorder in the root deck's action sheet | Library spec D7 |
@@ -116,6 +118,7 @@ Not captured: `rootTrashed`, `deckTrashed` (Undo after Move to Trash; no Trash i
 - Due filter, none: "Nothing due right now" · "No deck has cards waiting. The next card becomes due tomorrow at 00:00." · "Show all decks".
 - Create: "New deck" · "Holds sub-decks; sub-decks hold cards." · "Name" · "Review algorithm · required" · "Eight boxes" / "Cards move up a box each time you remember them, back to box 1 when you forget. Forgiving of long breaks." · "SM-2" / "Intervals adapt to how well you recall each card. You grade yourself: again · hard · good · easy." · "Locks once the first card finishes learning. After that, only “Reset learning progress” starts a new cycle." · "Cancel" · "Create deck".
 - Rename: "Rename deck" · "Only the name changes — sub-decks, cards and schedules stay as they are." · "Rename".
-- Not found: "This deck is no longer here" · "Back to Library" · "Open Trash". The artifact body mentions Trash; V8 uses "It was deleted while you were away." until FE-B1.
+- Not found: "This deck is no longer here" · "It was moved to Trash or deleted while you were away. Anything in Trash can still be restored." · "Back to Library" · "Open Trash" (FE-B1 plan 2).
+- Move to Trash: "Move to Trash" · "Recoverable for 30 days" · "Move this deck to Trash?" · "“{name}” goes to Trash with its {n} sub-decks and {n} cards." · "Recoverable from Trash for 30 days. Any open study session on these cards ends." · "Cancel" · "Move to Trash" · "“{name}” moved to Trash · {n} sub-decks, {n} cards" · "Undo".
 - Move: "Move “{name}” to…" · "Its {n} sub-decks and {n} cards come along, schedules included. Only decks in the same review algorithm can receive it." · "Move here".
 - Sort & filter: as in "Sort & filter sheet".
```

`docs/shared/ui/screen-handoff/07-card-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/07-card-list.md b/docs/shared/ui/screen-handoff/07-card-list.md
index 6719bdf..1268d97 100644
--- a/docs/shared/ui/screen-handoff/07-card-list.md
+++ b/docs/shared/ui/screen-handoff/07-card-list.md
@@ -16,13 +16,13 @@ An open deck whose content type is `card`: the card section of `DeckLevelScreen`
 | Filters | `MxFilterChip` | All · Due · New · Flagged with counts; the Tags filter waits under Coming soon (FE-B2). |
 | Header | `MxListSectionHeader` + `MxChipTrigger` | "Showing {n} of {total}" (selecting: "{n} of {total} selected"); sort "Newest first ⌄" / "Due first ⌄". |
 | Rows | card surface per row, 8 apart | Status dot (checkbox while selecting); front 16/700 and back 12, one line each; uppercase status label in its ink, up to two `MxTagChip`s and "+{n}"; trailing flag in the warning colour (E-L2) and the due chip, an `MxBadge` (E-L4): "New", "Due today", "In {n}d", "{n}d overdue". The status label, tags and "+{n}" wrap at large text. Rows build as they scroll into view (E-L5). |
-| Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Delete. |
+| Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Trash. |
 | FAB | `MxFab` | "New card" (#33); hidden while selecting. |
 
 ## Deck action sheet (`⋮`)
 
 Study this deck · Rename · Move to another deck · Import cards (screen 11) · Export cards
-(screen 12) · Delete. Study this deck opens the Study Entry, screen 14 (FE-A6 D10).
+(screen 12) · Move to Trash. Study this deck opens the Study Entry, screen 14 (FE-A6 D10).
 
 ## States
 
@@ -34,22 +34,26 @@ Study this deck · Rename · Move to another deck · Import cards (screen 11) ·
 | loading | ![](img/07-card-list/loading-light.png) | ![](img/07-card-list/loading-dark.png) | As drawn. |
 | error | ![](img/07-card-list/error-light.png) | ![](img/07-card-list/error-dark.png) | As drawn. |
 | notFound | ![](img/07-card-list/notFound-light.png) | ![](img/07-card-list/notFound-dark.png) | As screen 01 deckNotFound. |
-| deckActions | ![](img/07-card-list/deckActions-light.png) | ![](img/07-card-list/deckActions-dark.png) | Delete replaces Move to Trash. |
+| deckActions | ![](img/07-card-list/deckActions-light.png) | ![](img/07-card-list/deckActions-dark.png) | As drawn. |
 | selection | ![](img/07-card-list/selection-light.png) | ![](img/07-card-list/selection-dark.png) | Long-press selects (BR-CARD-020). The app bar carries close, "{n} selected" and "Select all {n}" (A14). |
 | moveTargets | ![](img/07-card-list/moveTargets-light.png) | ![](img/07-card-list/moveTargets-dark.png) | As drawn. |
 | noMoveTarget | ![](img/07-card-list/noMoveTarget-light.png) | ![](img/07-card-list/noMoveTarget-dark.png) | As drawn. |
-| bulkFailed | ![](img/07-card-list/bulkFailed-light.png) | ![](img/07-card-list/bulkFailed-dark.png) | Flag: an inline banner above the bulk bar (E-L6). Move, Tag and Delete keep their sheet or dialog open and say it there. The selection stays. |
-| delCard | ![](img/07-card-list/delCard-light.png) | ![](img/07-card-list/delCard-dark.png) | **Deviation:** permanent delete. |
-| delDeck | ![](img/07-card-list/delDeck-light.png) | ![](img/07-card-list/delDeck-dark.png) | **Deviation:** permanent delete. |
+| bulkFailed | ![](img/07-card-list/bulkFailed-light.png) | ![](img/07-card-list/bulkFailed-dark.png) | Flag: an inline banner above the bulk bar (E-L6). Move, Tag and Trash keep their sheet or dialog open and say it there. The selection stays. |
+| delCard | ![](img/07-card-list/delCard-light.png) | ![](img/07-card-list/delCard-dark.png) | One selected card, as drawn, without the glyph. Several: "Move {n} cards to Trash?" without the preview. The confirm spins while they move (FE-B1 D15). |
+| delDeck | ![](img/07-card-list/delDeck-light.png) | ![](img/07-card-list/delDeck-dark.png) | As screen 01 deckDelete. |
+| trashed | ![](img/07-card-list/trashed-light.png) | ![](img/07-card-list/trashed-dark.png) | One card: as drawn, Undo for 8 seconds (FE-B1 D3, D14). Several: "{n} cards moved to Trash", no Undo (D4); FE-B1 plan 2 adds Open Trash. |
 
-Not captured: `trashed` (Undo; no Trash in V8.0). `cardActions` gives way to the card
-detail: a tap opens it (#35).
+Not captured: `cardActions` gives way to the card detail: a tap opens it (#35). The card
+editor (screen 09) moves its card to the Trash from its "More" card with the same dialog
+(FE-B1 D13):
+![](img/09-card-edit/delConfirm-light.png)
 
 ## Deviations
 
 | Artifact | V8 | Wins |
 |---|---|---|
-| Move to Trash with Undo, for cards and for the deck | Permanent delete with a count, no Undo | BR-DECK-022, BR-DECK-023, UC-CARD-002 |
+| A trash glyph beside the Move to Trash dialog's title | No glyph | `MxDialog` has no glyph slot |
+| "Recoverable for 30 days with its 7 answers of history" | "Recoverable from Trash for 30 days, with its schedule and history" | The dialog reads no history count |
 | Tags filter | Hidden; named under Coming soon | Spec A4 (amended) |
 | An empty card list | The deck is unset again: screen 01's unset state | BR-DECK-015, ruling E-L1 |
 | The flag in the streak colour | The flag in the warning colour; the theme has no streak token | Ruling E-L2 |
@@ -60,7 +64,8 @@ detail: a tap opens it (#35).
 
 - Summary: "Deck progress · {algorithm}" · "{n} of {total} cards mastered" · "New" · "Beginning" · "Reviewing" · "Mastered" · "Study this deck · {n} due".
 - Filters and header: "All" · "Due" · "New" · "Flagged" · "Tags" · "Showing {n} of {total}" · "{n} of {total} selected" · "Newest first".
-- Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · "Export" · "Delete".
+- Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · "Export" · "Trash".
+- Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move to Trash" · "“{front}” moved to Trash" · "Undo" · "{n} cards moved to Trash".
 - Empty: "No cards in this deck yet" · "Write your first card, or bring many at once from a spreadsheet or pasted text." · "Import cards (CSV, TSV, XLSX, text)" · "Studying this deck becomes available once it holds at least one card."
 - Search empty: "No cards match “{term}”" · "Try a different term, or clear the search to see all {n} cards."
 - Error: "Couldn't open this deck" · "Your data is safe on this device. Try again in a moment."
```

`docs/shared/ui/screen-handoff/12-card-export.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/12-card-export.md b/docs/shared/ui/screen-handoff/12-card-export.md
index c51a0e2..9cf9dd1 100644
--- a/docs/shared/ui/screen-handoff/12-card-export.md
+++ b/docs/shared/ui/screen-handoff/12-card-export.md
@@ -39,7 +39,7 @@ The overline, the banner and the note line up with the title (20 dp).
 | shareClosed | ![](img/12-card-export/shareClosed-light.png) | ![](img/12-card-export/shareClosed-dark.png) | **Deviation:** the export sheet stays open, as it was. |
 | failed | ![](img/12-card-export/failed-light.png) | ![](img/12-card-export/failed-dark.png) | For a read or encode failure. A share failure has its own copy, also with Try again. |
 | noShareTarget | ![](img/12-card-export/noShareTarget-light.png) | ![](img/12-card-export/noShareTarget-dark.png) | As drawn; the banner shows the warning glyph. |
-| staleSelection | ![](img/12-card-export/staleSelection-light.png) | ![](img/12-card-export/staleSelection-dark.png) | "Moved or deleted", not "sent to Trash": V8.0 has no Trash. |
+| staleSelection | ![](img/12-card-export/staleSelection-light.png) | ![](img/12-card-export/staleSelection-dark.png) | As drawn (FE-B1 D12 closes X11). |
 | nothingToExport | ![](img/12-card-export/nothingToExport-light.png) | ![](img/12-card-export/nothingToExport-dark.png) | Reached only by a deck emptied between the count and the export, or by a count of 0. |
 
 Goldens: `test/features/transfer/presentation/goldens/export_{deck,failed,stale}_{light,dark}.png`.
@@ -56,7 +56,6 @@ Goldens: `test/features/transfer/presentation/goldens/export_{deck,failed,stale}
 | "Export and share" | "Export {n} cards" | UC-TRANSFER-002 step 3 (owner 2026-09-26) |
 | A file name folded to ASCII (`nha-hang-…`) | The deck's own letters (`Nhà-hàng-2026-09-26.csv`) | BR-TRANSFER-013, backend plan C5 |
 | A glyph per banner (share, copy) | The banner's tone glyph | `MxInlineBanner` has no glyph slot |
-| "Moved or sent to Trash" | "Moved or deleted" | V8.0 has no Trash (BR-DECK-022) |
 
 ## Copy
 
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index e7014ab..0351784 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -482,7 +482,7 @@ item names where it comes from.
 | 79 | The card editor follows the V3 kit (08, 09) over library spec §6.5: live validation with Save disabled until valid, failures inside the form (inline banner, warning banner, gone state), and a discard confirm | library phase 4a P4a-L1…L5 |
 | 80 | A new card has no flag control; the flag toggles from the edit app bar, and its glyph changes but does not recolour (`Icon(color:)` is banned) | library phase 4a P4a-L6 |
 | 81 | The editor's deck context drops the kit's pill border, and Add tag is an outline chip, not dashed: no `BorderSide`, and no dashed-border token | library phase 4a P4a-L7, P4a-L8 |
-| 82 | The editor offers no Move to Trash or Import cards; the edit summary's Details goes back, since the detail is the page under the editor from phase 4b | library phase 4a P4a-L10 |
+| 82 | The editor offers no Move to Trash or Import cards; the edit summary's Details goes back, since the detail is the page under the editor from phase 4b — Move to Trash closed by FE-B1 (D13): a "More" card at the foot of the edit form | library phase 4a P4a-L10 |
 | 83 | The edit mode is built and tested in phase 4a but has no route until phase 4b adds the card detail, which opens it — closed by library phase 4b | library phase 4a split |
 | 84 | A top-level deck holds sub-decks only, so its empty state offers New sub-deck alone, with its own copy; New card shows where the deck's create options include cards | library phase 4a (Task 4 ruling) |
 | 85 | The card detail follows the V3 kit (10) over library spec §6.6: a schedule card with the eight-box ramp or the SM-2 facts, history grouped by cycle, Load older history, and an end-of-history line | library phase 4b P4b-L1 |
@@ -496,7 +496,7 @@ item names where it comes from.
 | 91 | A deck row's meta and the due strip's tile carry no coloured glyph: the guard bans `Icon(color:)` in feature code | library alignment phase C (C-L1) |
 | 92 | The deck row's name is `rowTitle` (14/600), not the kit's 14/700, and the search match is a named role (`rowTitleMatch`) drawn by `MxListRow.titleMatch`, with no tinted mark: no per-site text styling | library alignment phase C (C-L2, C-O7) |
 | 93 | "Review algorithm" opens the scheduler sheet, not screen 02, until phase D — closed by library alignment phase D | library alignment phase C (C-L3) |
-| 94 | A deck deleted while open shows the "This deck is no longer here" empty state, superseding P2-L7's snackbar and pop; deleting the open deck from its own sheet still steps back with "Deck deleted" | library alignment phase C (C-L5) |
+| 94 | A deck deleted while open shows the "This deck is no longer here" empty state, superseding P2-L7's snackbar and pop; deleting the open deck from its own sheet still steps back, now with the Move to Trash toast and its Undo (FE-B1 D3) | library alignment phase C (C-L5) |
 | 95 | The level-10 banner over sub-decks at level 10 is absent; only the header names the level | library alignment phase C (C-O6) |
 | 96 | A card row's flag is drawn in the warning colour, not the kit's streak colour: the theme has no streak token | library alignment phase E (E-L2) |
 | 97 | The selection header's "Select all {n}" is a compact secondary `MxButton`, not the kit's text link: no bare-text button in the widget set | library alignment phase E (E-L3) |
@@ -510,6 +510,9 @@ item names where it comes from.
 | 105 | Success, caution and danger glyphs and success text use inks pulled toward `onSurface` (`successInk`, `warningInk`, `error`): the kit's pure green and amber fail 3:1 (glyph) and 4.5:1 (text) on their soft tints; the fills keep the kit's hues | FE-A6 D14 |
 | 106 | Card import names the fields two ways: "Term (front)" / "Meaning (back)" on the mapping, "term" and "meaning" in its notes and row reasons. One vocabulary waits for a copy pass over screens 08–12 | critique 2026-09-26 P3 (transfer) |
 | 107 | Card import shows one spinner card while a large import writes, with no progress or waiting line | critique 2026-09-26 P3 (transfer) |
+| 108 | The Move to Trash dialogs (screens 01, 07, 09) draw no trash glyph over or beside their title: `MxDialog` has no glyph slot | FE-B1 plan 1 |
+| 109 | A refused Undo reads "Can't undo. {reason} Restore it from Trash and choose a deck." where the item was deleted, not screen 06's "Can't undo — “{deck}” is in Trash too. Restore it from here…": the rejection carries no deck name | FE-B1 D7 |
+| 110 | Move to Trash names no counts the dialog cannot read: the card note says "with its schedule and history", not "with its 7 answers of history", and the editor's "More" card says "Leaves this deck", not the deck's name, which the path above it shows | FE-B1 plan 1 |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/superpowers/specs/2026-09-26-trash-ui-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-26-trash-ui-design.md b/docs/superpowers/specs/2026-09-26-trash-ui-design.md
index 604b5b8..fc78aa4 100644
--- a/docs/superpowers/specs/2026-09-26-trash-ui-design.md
+++ b/docs/superpowers/specs/2026-09-26-trash-ui-design.md
@@ -112,9 +112,11 @@ lib/features/trash/presentation/
     {n} sub-decks, {m} cards", with Undo (D3).
   - Deleting the open deck still steps back to its parent first (C-L5). The snackbar
     replaces "Deck deleted" (row 94).
-- **Card editor (D13).** The "More" card at the foot of the edit form opens the one-card
-  dialog below. On Ok the editor closes to the card list, which shows the one-card
-  snackbar with Undo.
+- **Card editor (D13).** The "More" card at the foot of the edit form ("Move this card
+  to Trash", "Leaves this deck and can be restored from Trash for 30 days, schedule and
+  history included.") opens the one-card dialog below. On Ok the editor closes with
+  true and the card detail under it closes too, back to where the detail was opened;
+  the one-card snackbar with Undo is up.
 - **Cards,** from the bulk bar's Delete.
   - **One card:** the kit's dialog. Its title is "Move this card to Trash?", with the
     card's front over its back. Its note is "Recoverable from Trash for 30 days, with its
@@ -125,8 +127,9 @@ lib/features/trash/presentation/
     cards are unaffected." The snackbar reads "{n} cards moved to Trash" (D4); plan 2
     adds its "Open Trash".
 - **Undo (A1).** The item goes back where it was.
-  - A refused Undo (E3) shows the snackbar "Can't undo — {reason} Restore it from Trash
-    and choose a deck.", where `{reason}` is the D16 string. Plan 2 adds "Open Trash".
+  - A refused Undo (E3) shows the snackbar "Can't undo. {reason} Restore it from Trash
+    and choose a deck.", where `{reason}` is the rejection's own sentence (D16 and the
+    older values). Plan 2 adds "Open Trash".
   - The item stays in the Trash.
   - The kit shows this refusal on screen 06 with "from here", but an Undo happens
     where the item was deleted.
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index 80b722c..8696c76 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -87,7 +87,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 
 | ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
 |---|---|---|---|---|---|---|
-| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | BE-B1 xong: hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
+| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | đang làm | BE-B1, FE-A1, FE-A2 | M | [spec](superpowers/specs/2026-09-26-trash-ui-design.md); [plan 1: luồng xoá, Undo, câu chữ](superpowers/plans/2026-09-26-trash-delete-flows.md) xong; plan 2 (màn 06, lối vào, auto-purge) còn lại. Hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
 | FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
 | FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
 | FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
```

- [ ] **Step 3: Regenerate the docs index and check**

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: no error. The existing warnings stay. `wbs_FE.md` links this plan, which is
already on the branch.

- [ ] **Step 4: The gate**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force
```

Expected: every gate green.

- [ ] **Step 5: Commit and push**

```bash
git add \
  tools/design/screen_states.json \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/shared/ui/screen-handoff/07-card-list.md \
  docs/shared/ui/screen-handoff/12-card-export.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/superpowers/specs/2026-09-26-trash-ui-design.md \
  docs/wbs_FE.md \
  docs/shared/ui/screen-handoff/img/09-card-edit \
  docs/shared/ui/screen-handoff/img/10-card-detail \
  docs/_generated/traceability.md
git commit -m "$(cat <<'EOF'
docs(trash): FE-B1 plan 1 done: detail files, register rows 108-110, captures 09 and 10

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
