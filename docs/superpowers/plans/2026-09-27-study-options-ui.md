# MemoX V8 Study Options Implementation Plan (FE-A3, plan 2 of 2)

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish FE-A3 in [`docs/wbs_FE.md`](../../wbs_FE.md) with kit screen 15, Study
options: a root deck's own cards per session and new-card order, or the app defaults.
The screen opens from the deck action sheet and from screen 14's app bar. It also fixes
the `MxStepper` hold that a scroll could leave running, found in review of plan 1 (#89).

**Architecture:**
- **One controller.** `lib/features/settings/presentation/` gains an `@riverpod` family
  controller keyed by the deck id. It holds only a draft of what the person changed.
  `StudyOptionsForm` lays that draft over the options in force (from the BE-A1
  `WatchStudyOptionsUseCase` stream) and over Settings' defaults.
- **Save.** One write: `UseAppDefaultsUseCase` or `SaveRootStudyOptionsUseCase`.
- **The deck's path and root name.** The ADR-011 import map keeps `settings` from
  reading `deck`. So `app/` composes the breadcrumb from the deck feature, as it does
  for screen 14. The root's name comes from settings' own store, in the statement that
  already reads the root's options.
- **The ways in.** `deck` and `study` learn about screen 15 only through callbacks,
  which `app/` wires to the root-navigator route `/decks/deck/:deckId/options`.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, gen-l10n (en, vi). No new package.

**Spec:** [`docs/superpowers/specs/2026-09-26-settings-ui-design.md`](../specs/2026-09-26-settings-ui-design.md)
§3 (D3, D9), §4, §5.5, §6, §7, §8.
- Use case: UC-SETTINGS-001 A1, A4, E1, E4.
- The kit is the visual authority: "MemoX — Mobile UI Kit v3", screen 15 (7 states).
- The pre-plan critique is `.impeccable/critique/2026-09-26T17-00-00Z__settings-kit.md`
  (P1 footer, P3 Save).

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` at the commit that adds
this plan, which is `master` up to #90 (plan 1 is #89) plus this plan. Generated code is
not committed. In a fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- **Built in scratch.** Every task was built and committed in a scratch worktree of
  `master` at #90, and each task's blocks below are that commit's files and diffs.
- **Gate.** The full gate (`dod_check.sh --force`) passed there, with a clean
  `flutter analyze`, a clean guard (including #90's row-marks rule) and clean
  architecture boundaries.
- **Goldens.** They ran in this Linux container, and the new and changed ones were
  compared with the kit's captures of screens 01, 14 and 15.
- **Replay.** The blocks were replayed mechanically onto a clean checkout, and the
  result matched the scratch files byte for byte.
- **Architecture.** `test/architecture/boundaries_test.dart` passes: an earlier draft
  read the deck feature from `settings` and failed it (C6).
- **Mutations.** Rules were broken on purpose, and each break failed a test:
  - an unreadable override no longer counted as a change;
  - the second-Save guard removed;
  - the save written to the sub-deck instead of its root;
  - the stepper's slop check removed.

## Clarifications (rulings; amend the spec where they differ)

- **C1 (the #89 review finding).** `MxStepper`'s hold is driven by a raw `Listener`.
  When a scroll view wins the gesture arena, the listener gets no cancel event, so a
  vertical drag that began on −/+ kept repeating and the result was saved. The hold now
  stops once the pointer moves past `kTouchSlop` from where it went down.
- **C2 (the draft).** `StudyOptionsState` holds only what the person changed; a null
  field shows the stored value. `StudyOptionsForm.of(stored, draft, appDefaults:)`
  derives what the screen shows:
  - **Toggle on:** Settings' values, read-only. A deck with its own options that turns
    the toggle on shows the app defaults it will follow, not its old override.
  - **Toggle off:** the draft over the options in force. A deck on the app defaults
    starts from them (A1).
- **C3 (D9, what counts as a change).** Save is enabled only when the form is valid and
  something changed: the toggle, the limit or the order. An override that cannot be
  read (`unreadableRootOverride`) counts as a change, so Save can replace it. A warning
  banner says so.
- **C4 (Save).**
  - With the toggle on over an override, Save runs `UseAppDefaultsUseCase`; otherwise it
    runs `SaveRootStudyOptionsUseCase` on the root (`EffectiveStudyOptions.rootDeckId`).
  - `Ok` clears the draft and shows the toast.
  - `deckNotFound` goes back to idle, and the stream shows the gone state.
  - Any other rejection, or a `Failure`, keeps the draft for "Retry save", and the
    caption names what the deck still uses (E4). This includes `notARootDeck`, which
    cannot occur because the root comes from the stream. Spec §6 names a toast for it;
    the caption is the screen's one failure message.
- **C5 (while Save runs).** The controls keep their look, as kit 15 draws them: the
  stepper and the button spin. The controller ignores every edit and a second Save until
  it ends (A4).
- **C6 (the deck; spec §5.5 amended).** `test/architecture/boundary_rules.dart` (the
  ADR-011 map) allows `settings` no feature import, and a `usecases/` bucket is never
  public. The spec's "reads through the deck feature's domain use case" would break
  both, so:
  - **Breadcrumb.** `StudyOptionsScreen` takes a `breadcrumb` widget. `app/` builds it
    from the deck feature: `DeckStudyHeaderWidget(part: breadcrumb)` gains a
    `trailingLabel` that ends the path at "Study options". This is FE-A6 D16's pattern
    for screen 14.
  - **The note's root.** `EffectiveStudyOptions` gains `rootDeckName`, read with the
    root's options in the same join (`effectiveStudyOptionsOf`). A sub-deck's note
    therefore names its root.
- **C7 (gone and error).** A deck gone to the Trash, or gone for good, shows the
  Library's "This deck is no longer here" with Back only, as spec §6 says (UI-base row
  129). A failed read shows `MxErrorState` with Retry and no invented value.
- **C8 (copy).**
  - The note's root name is plain text: `MxNote` carries one string, where the kit
    bolds it.
  - Save and Retry save reuse `cardSave` and `cardRetrySave`.
  - The button spins without the kit's "Saving…" text (`MxButton.isLoading`).
- **C9 (the ways in, D3).**
  - `onOpenStudyOptions` is threaded beside `onOpenAlgorithm`, and is required on
    `DeckLevelScreen` and every widget below it.
  - The sheet's row sits below Rename, as kit 01 draws it, with the kit's sliders icon
    (`AppIcons.studyOptions`).
  - On `StudyEntryScreen` the callback is optional, and null hides the icon; `app/`
    always passes it. Screen 14's goldens and audit pass it, so they show the app as it
    runs.
  - The Coming soon sheet drops Study options, and `comingSoonStudyOptionsBody` goes.
- **C10 (UI-base §9).**
  - Row 129 is the next free row at #90; if it is taken by the time this lands, use the
    next free number and change its references in `15-study-options.md`.
  - Row 125 now names screen 15 too.

## Global Constraints

Every task's requirements implicitly include these.

- The kit's screen 15 (and 01's sheet, 14's app bar) is the visual authority. Every
  difference is in C1–C10, in `15-study-options.md`, or in UI-base §9 rows 125 and 129.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens;
  - no raw colour, `TextStyle`, spacing, radius or anonymous `Duration` literal;
  - no `ref.read` inside `build`, including in a callback inside a conditional
    expression;
  - no literal user string, TalkBack labels included;
  - booleans read as predicates;
  - no source file over 400 lines;
  - no `Row` pinning its marks to the top (#90).
- File suffixes and buckets follow the guard: `_provider`, `_controller`, `_state`,
  `_screen`, and `_widget` in `sections/`.
- Every read and write goes through a use case (ADR-011 D4). `deck` and `study` never
  import `settings`, and `settings` imports no feature
  (`test/architecture/boundary_rules.dart`).
- No message carries an id, a path or SQL (BR-CORE-005).
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- **Test rules:**
  - Controller tests are plain `test()`s over a `LibraryEnv`.
  - Screen and route tests are `libraryTest`s.
- Goldens render in the Linux container only. On Windows, run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **Scrolling the page with a finger that landed on +.** The limit does not move. Test:
   "a hold that turns into a scroll never repeats" (Task 1).
2. **Turning Use app defaults on for a deck with its own options.** The screen shows
   Settings' values, and Save clears the override. Tests: "turning app defaults on
   shows the app's values, not the override it replaces" and "Use app defaults clears
   the root's override (A1)" (Task 2).
3. **Opening options on a sub-deck.** The root's options show, and Save writes the root.
   Test: "turning app defaults off and stepping saves the root's own options, from a
   sub-deck (A1, BR-STUDY-056)" (Task 2).
4. **Tapping Save twice, or editing while it runs.** One write. Test: "a second Save
   while one runs is ignored (A4)" (Task 2).
5. **A 360 dp phone at text scale 2.** Nothing overflows, and every target is 48 dp.
   Test: the screen 15 visual audit (Task 3).

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/shared/widgets/mx_stepper.dart` | 1 | a hold stops when it turns into a scroll |
| `lib/features/settings/{domain/models/effective_study_options_model,data/mappers/study_config_mapper}.dart` | 2 | `rootDeckName` with the options in force |
| `lib/features/settings/presentation/providers/{watch_study_options,save_root_study_options,use_app_defaults}_use_case_provider.dart`, `…/study_options_provider.dart` | 2 | the use cases; the options stream |
| `lib/features/settings/presentation/{states/study_options_state,controllers/study_options_controller}.dart` | 2 | draft, form, Save |
| `lib/features/settings/presentation/screens/study_options_screen.dart`, `…/widgets/sections/study_options_{form,footer}_widget.dart` | 3 | screen 15 |
| `lib/app/router/*` | 4 | the route, the breadcrumb, the ways in |
| `lib/features/deck/presentation/**`, `lib/features/study/presentation/screens/study_entry_screen.dart` | 4 | the sheet row, Coming soon, screen 14's icon, the breadcrumb's last segment |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/core/theme/foundations/app_icons.dart` | 3, 4 | the copy; `AppIcons.studyOptions` |
| `docs/**` | 5 | detail file 15, 01 and 14, index, checklist, register, UC, WBS |

---

### Task 1: A stepper hold that turns into a scroll stops (C1)

**Files:**
- Modify: `lib/shared/widgets/mx_stepper.dart`
- Test (modify): `test/shared/widgets/mx_stepper_input_test.dart`

**Interfaces:**
- Consumes: plan 1's `MxStepper` and its `_StepButton` hold (`AppDurations.stepperRepeatDelay`,
  `stepperRepeatInterval`).
- Produces: no new API. `_StepButton` remembers where the pointer went down and stops the
  hold on a `PointerMoveEvent` past `kTouchSlop`.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_stepper_input_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_stepper_input_test.dart b/test/shared/widgets/mx_stepper_input_test.dart
index fd07184..f0c8574 100644
--- a/test/shared/widgets/mx_stepper_input_test.dart
+++ b/test/shared/widgets/mx_stepper_input_test.dart
@@ -1,3 +1,4 @@
+import 'package:flutter/gestures.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/core/theme/foundations/app_durations.dart';
@@ -62,6 +63,20 @@ void main() {
     expect(_value(tester), 24);
   });
 
+  testWidgets('a hold that turns into a scroll never repeats', (tester) async {
+    await pumpMx(tester, const _Bounded());
+    final drag = await tester.startGesture(
+      tester.getCenter(find.byTooltip('More cards')),
+    );
+    // Past touch slop: the finger is scrolling the page, not holding +.
+    await drag.moveBy(const Offset(0, kTouchSlop * 2));
+    await tester.pump(AppDurations.stepperRepeatDelay * 2);
+    await drag.up();
+    await tester.pump();
+
+    expect(_value(tester), 20);
+  });
+
   testWidgets('a hold stops at the bound the caller sets', (tester) async {
     await pumpMx(tester, const _Bounded(max: 22));
     final hold = await tester.startGesture(
```

- [ ] **Step 2: Run it to see it fail**

```bash
flutter test test/shared/widgets/mx_stepper_input_test.dart
```

Expected: FAIL, 1 of 8: "a hold that turns into a scroll never repeats" reads
`Actual: <26>`, not 20.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_stepper.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_stepper.dart b/lib/shared/widgets/mx_stepper.dart
index 172c9af..5591deb 100644
--- a/lib/shared/widgets/mx_stepper.dart
+++ b/lib/shared/widgets/mx_stepper.dart
@@ -1,5 +1,6 @@
 import 'dart:async';
 
+import 'package:flutter/gestures.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 import 'package:memox/core/theme/foundations/app_durations.dart';
@@ -242,6 +243,10 @@ class _StepButtonState extends State<_StepButton> {
   /// Set once a hold has stepped, so its release is not one more tap.
   var _hasRepeated = false;
 
+  /// Where the pointer went down: past touch slop from here it scrolls the
+  /// page, and a hold that the scroll view has taken must not repeat.
+  Offset? _downAt;
+
   @override
   void didUpdateWidget(_StepButton oldWidget) {
     super.didUpdateWidget(oldWidget);
@@ -254,9 +259,10 @@ class _StepButtonState extends State<_StepButton> {
     super.dispose();
   }
 
-  void _start(PointerDownEvent _) {
+  void _start(PointerDownEvent event) {
     _hasRepeated = false;
     _stop();
+    _downAt = event.position;
     if (widget.onPressed == null) return;
     _timer = Timer(AppDurations.stepperRepeatDelay, () {
       _repeat();
@@ -282,6 +288,14 @@ class _StepButtonState extends State<_StepButton> {
     _timer = null;
   }
 
+  /// The gesture arena sends no cancel to a raw listener when a scroll
+  /// wins, so the movement itself ends the hold.
+  void _move(PointerMoveEvent event) {
+    final downAt = _downAt;
+    if (downAt == null) return;
+    if ((event.position - downAt).distance > kTouchSlop) _stop();
+  }
+
   void _tap() {
     if (_hasRepeated) {
       _hasRepeated = false;
@@ -295,6 +309,7 @@ class _StepButtonState extends State<_StepButton> {
     final colors = context.colors;
     return Listener(
       onPointerDown: _start,
+      onPointerMove: _move,
       onPointerUp: _stop,
       onPointerCancel: _stop,
       child: Tooltip(
```

- [ ] **Step 4: Run**

```bash
flutter test test/shared test/features/settings
flutter analyze
```

Expected: PASS, 8 tests in `mx_stepper_input_test.dart`. No golden changes.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/shared/widgets/mx_stepper.dart \
  test/shared/widgets/mx_stepper_input_test.dart
git commit -m "$(cat <<'EOF'
fix(ui): a stepper hold that turns into a scroll stops repeating (review of #89)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: Screen 15's providers, draft, form and controller

**Files:**
- Modify: `lib/features/settings/data/mappers/study_config_mapper.dart`
- Modify: `lib/features/settings/domain/models/effective_study_options_model.dart`
- Create: `lib/features/settings/presentation/controllers/study_options_controller.dart`
- Create: `lib/features/settings/presentation/providers/save_root_study_options_use_case_provider.dart`
- Create: `lib/features/settings/presentation/providers/study_options_provider.dart`
- Create: `lib/features/settings/presentation/providers/use_app_defaults_use_case_provider.dart`
- Create: `lib/features/settings/presentation/providers/watch_study_options_use_case_provider.dart`
- Create: `lib/features/settings/presentation/states/study_options_state.dart`
- Test (modify): `test/features/settings/data/root_study_options_repository_test.dart`
- Test (modify): `test/features/settings/domain/study_options_model_test.dart`
- Test (create): `test/features/settings/presentation/study_options_controller_test.dart`

**Interfaces:**
- Consumes: BE-A1's `WatchStudyOptionsUseCase`, `SaveRootStudyOptionsUseCase` and
  `UseAppDefaultsUseCase` over `settingsRepositoryProvider`; `EffectiveStudyOptions`
  (`rootDeckId`, `options`, `source`, `hasRootOverride`); plan 1's
  `appSettingsProvider` and `FlakySettingsRepository` (`isFailing`, `writes`, `hold`).
- Produces:
  - `EffectiveStudyOptions.rootDeckName` (required), set by `effectiveStudyOptionsOf`
    from the root row it already joins (C6);
  - `watchStudyOptionsUseCaseProvider`, `saveRootStudyOptionsUseCaseProvider`,
    `useAppDefaultsUseCaseProvider`;
  - `studyOptionsProvider(String deckId)` →
    `Stream<Outcome<EffectiveStudyOptions, SettingsRejection>>`;
  - `enum StudyOptionsSave {idle, saving, failed}`;
    `StudyOptionsState({bool? isUsingAppDefaults, int? cardLimit, bool
    isCardLimitInvalid, NewCardOrder? newCardOrder, StudyOptionsSave save, int
    timesSaved})` with `isSaving`;
  - `StudyOptionsForm.of(EffectiveStudyOptions stored, StudyOptionsState draft,
    {required StudyOptions appDefaults})` with `isUsingAppDefaults`, `options`,
    `isCardLimitInvalid`, `isChanged`, `canSave`;
  - `studyOptionsControllerProvider(String deckId)`: `useAppDefaults({required bool
    isOn})`, `stepCardLimit(int delta)`, `typeCardLimit(String text)`,
    `chooseNewCardOrder(NewCardOrder)`, `Future<void> save()` (also Retry save).

- [ ] **Step 1: Write the failing tests**

The tests are plain `test()`s over a `LibraryEnv` (Drift's streams need the real event
loop). An override is written straight into `deck.study_config`, as the repository's
own tests do, including one that cannot be read.

`test/features/settings/data/root_study_options_repository_test.dart` (apply this diff):

```diff
diff --git a/test/features/settings/data/root_study_options_repository_test.dart b/test/features/settings/data/root_study_options_repository_test.dart
index 4bf49f2..466c5f9 100644
--- a/test/features/settings/data/root_study_options_repository_test.dart
+++ b/test/features/settings/data/root_study_options_repository_test.dart
@@ -117,6 +117,8 @@ void main() {
     expect(ofRoot?.options.newCardOrder, NewCardOrder.random);
     expect(ofRoot?.source, StudyOptionsSource.rootOverride);
     expect(ofSub?.rootDeckId, 'r');
+    // Screen 15 names the root from the same read (FE-A3 plan 2, C6).
+    expect(ofSub?.rootDeckName, 'r');
     expect(ofSub?.options.cardLimit, 30);
     expect(await settings.studyOptionsOf(deckId: 'missing'), isNull);
     await _moveTreeToTrash(db);
```

`test/features/settings/domain/study_options_model_test.dart` (apply this diff):

```diff
diff --git a/test/features/settings/domain/study_options_model_test.dart b/test/features/settings/domain/study_options_model_test.dart
index f495d4f..b8bf28f 100644
--- a/test/features/settings/domain/study_options_model_test.dart
+++ b/test/features/settings/domain/study_options_model_test.dart
@@ -77,6 +77,7 @@ void main() {
     EffectiveStudyOptions from(StudyOptionsSource source) =>
         EffectiveStudyOptions(
           rootDeckId: 'root',
+          rootDeckName: 'Korean',
           options: StudyOptions.defaults,
           source: source,
         );
```

`test/features/settings/presentation/study_options_controller_test.dart`:

```dart
import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/test_database.dart';

typedef _Rig = ({
  ProviderContainer container,
  FlakySettingsRepository store,
  LibraryEnv env,
  String rootId,
  String subId,
});

/// Korean › Words, the screen open on the sub-deck, whose options are its
/// root's (BR-STUDY-056).
Future<_Rig> _rig(LibraryEnv env, {String? rootConfig}) async {
  final root = await env.decks.root('Korean');
  final sub = await env.decks.sub(root.id, 'Words');
  if (rootConfig != null) {
    await env.db.customUpdate(
      'UPDATE deck SET study_config = ? WHERE id = ?',
      variables: [Variable(rootConfig), Variable(root.id)],
    );
  }
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  final container = libraryContainer(
    env,
    overrides: [settingsRepositoryProvider.overrideWithValue(store)],
  );
  container.listen(studyOptionsControllerProvider(sub.id), (_, _) {});
  await container.read(studyOptionsProvider(sub.id).future);
  await container.read(appSettingsProvider.future);
  return (
    container: container,
    store: store,
    env: env,
    rootId: root.id,
    subId: sub.id,
  );
}

StudyOptionsController _controller(_Rig rig) =>
    rig.container.read(studyOptionsControllerProvider(rig.subId).notifier);

StudyOptionsState _state(_Rig rig) =>
    rig.container.read(studyOptionsControllerProvider(rig.subId));

Future<EffectiveStudyOptions> _stored(_Rig rig) async =>
    (await SettingsRepositoryImpl(rig.env.db)
        .studyOptionsOf(deckId: rig.rootId))!;

Future<StudyOptionsForm> _form(_Rig rig) async => StudyOptionsForm.of(
  await _stored(rig),
  _state(rig),
  appDefaults: StudyOptions.defaults,
);

/// Past the write and the stream's echo.
Future<void> _settled() =>
    Future<void>.delayed(const Duration(milliseconds: 150));

const _override = '{"card_limit":50,"new_card_order":"random"}';

void _optionsTest(
  String description,
  Future<void> Function(_Rig rig) body, {
  String? rootConfig,
}) {
  test(description, () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(await _rig(env, rootConfig: rootConfig));
    } finally {
      await env.db.close();
    }
  });
}

void main() {
  _optionsTest('a deck with no override follows the app defaults, and '
      'nothing is to save (D9)', (rig) async {
    final form = await _form(rig);

    expect(form.isUsingAppDefaults, isTrue);
    expect(form.options.cardLimit, StudyOptions.defaultCardLimit);
    expect(form.canSave, isFalse);
  });

  _optionsTest('turning app defaults off and stepping saves the root\'s own '
      'options, from a sub-deck (A1, BR-STUDY-056)', (rig) async {
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(5)
      ..chooseNewCardOrder(NewCardOrder.random);
    expect((await _form(rig)).canSave, isTrue);

    await _controller(rig).save();
    await _settled();

    final stored = await _stored(rig);
    expect(stored.source, StudyOptionsSource.rootOverride);
    expect(stored.options.cardLimit, 25);
    expect(stored.options.newCardOrder, NewCardOrder.random);
    expect(_state(rig).timesSaved, 1);
    expect(_state(rig).cardLimit, isNull);
  });

  _optionsTest('Use app defaults clears the root\'s override (A1)', (
    rig,
  ) async {
    expect((await _form(rig)).isUsingAppDefaults, isFalse);
    _controller(rig).useAppDefaults(isOn: true);
    await _controller(rig).save();
    await _settled();

    expect((await _stored(rig)).source, StudyOptionsSource.appDefaults);
  }, rootConfig: _override);

  _optionsTest('turning app defaults on shows the app\'s values, not the '
      'override it replaces', (rig) async {
    _controller(rig).useAppDefaults(isOn: true);

    final form = await _form(rig);
    expect(form.options.cardLimit, StudyOptions.defaultCardLimit);
    expect(form.options.newCardOrder, NewCardOrder.created);
  }, rootConfig: _override);

  _optionsTest('an override saved unchanged has nothing to save', (rig) async {
    expect((await _form(rig)).options.cardLimit, 50);
    expect((await _form(rig)).canSave, isFalse);
  }, rootConfig: _override);

  _optionsTest('an unreadable override can be replaced by Save', (rig) async {
    final form = await _form(rig);
    expect(form.isUsingAppDefaults, isFalse);
    expect(form.canSave, isTrue);

    await _controller(rig).save();
    await _settled();
    expect((await _stored(rig)).source, StudyOptionsSource.rootOverride);
  }, rootConfig: '{not json');

  _optionsTest('a typed 250 is invalid and Save writes nothing (E1)', (
    rig,
  ) async {
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..typeCardLimit('250');
    final form = await _form(rig);
    expect(form.isCardLimitInvalid, isTrue);
    expect(form.options.cardLimit, 250);
    expect(form.canSave, isFalse);

    await _controller(rig).save();
    expect(rig.store.writes, 0);
  });

  _optionsTest('a failed save keeps the draft, and Retry save writes it '
      '(E4)', (rig) async {
    rig.store.isFailing = true;
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(1);
    await _controller(rig).save();
    expect(_state(rig).save, StudyOptionsSave.failed);
    expect(_state(rig).cardLimit, 21);
    expect((await _stored(rig)).source, StudyOptionsSource.appDefaults);

    rig.store.isFailing = false;
    await _controller(rig).save();
    await _settled();
    expect((await _stored(rig)).options.cardLimit, 21);
    expect(_state(rig).save, StudyOptionsSave.idle);
  });

  _optionsTest('a second Save while one runs is ignored (A4)', (rig) async {
    final gate = rig.store.hold = Completer<void>();
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(1);
    final first = _controller(rig).save();
    await _controller(rig).save();
    expect(_state(rig).isSaving, isTrue);

    rig.store.hold = null;
    gate.complete();
    await first;
    expect(rig.store.writes, 1);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/presentation/study_options_controller_test.dart
```

Expected: FAIL to compile: `study_options_controller.dart` does not exist, and
`EffectiveStudyOptions` has no `rootDeckName`.

- [ ] **Step 3: Implement**

`lib/features/settings/data/mappers/study_config_mapper.dart` (apply this diff):

```diff
diff --git a/lib/features/settings/data/mappers/study_config_mapper.dart b/lib/features/settings/data/mappers/study_config_mapper.dart
index d937a44..bd3e0bf 100644
--- a/lib/features/settings/data/mappers/study_config_mapper.dart
+++ b/lib/features/settings/data/mappers/study_config_mapper.dart
@@ -48,6 +48,7 @@ EffectiveStudyOptions effectiveStudyOptionsOf(Deck root, AppSetting settings) {
   if (studyConfig == null) {
     return EffectiveStudyOptions(
       rootDeckId: root.id,
+      rootDeckName: root.name,
       options: appDefaults,
       source: StudyOptionsSource.appDefaults,
     );
@@ -56,12 +57,14 @@ EffectiveStudyOptions effectiveStudyOptionsOf(Deck root, AppSetting settings) {
   if (override == null) {
     return EffectiveStudyOptions(
       rootDeckId: root.id,
+      rootDeckName: root.name,
       options: appDefaults,
       source: StudyOptionsSource.unreadableRootOverride,
     );
   }
   return EffectiveStudyOptions(
     rootDeckId: root.id,
+    rootDeckName: root.name,
     options: override,
     source: StudyOptionsSource.rootOverride,
   );
```

`lib/features/settings/domain/models/effective_study_options_model.dart` (apply this diff):

```diff
diff --git a/lib/features/settings/domain/models/effective_study_options_model.dart b/lib/features/settings/domain/models/effective_study_options_model.dart
index 001e717..9da3bee 100644
--- a/lib/features/settings/domain/models/effective_study_options_model.dart
+++ b/lib/features/settings/domain/models/effective_study_options_model.dart
@@ -18,11 +18,16 @@ enum StudyOptionsSource {
 final class EffectiveStudyOptions {
   const EffectiveStudyOptions({
     required this.rootDeckId,
+    required this.rootDeckName,
     required this.options,
     required this.source,
   });
 
   final String rootDeckId;
+
+  /// The root's name, read with its options, for screen 15's note
+  /// (BR-STUDY-056).
+  final String rootDeckName;
   final StudyOptions options;
   final StudyOptionsSource source;
 
```

`lib/features/settings/presentation/controllers/study_options_controller.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/save_root_study_options_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/providers/use_app_defaults_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_options_controller.g.dart';

/// Screen 15 (UC-SETTINGS-001 A1, E4): a draft of the options of [deckId]'s
/// root, saved in one write by Save. A second Save while one runs is
/// ignored (A4); a failure keeps the draft for Retry save.
@riverpod
class StudyOptionsController extends _$StudyOptionsController {
  @override
  StudyOptionsState build(String deckId) {
    // Kept alive while the screen is: the draft is read against them.
    ref
      ..listen(studyOptionsProvider(deckId), (_, _) {})
      ..listen(appSettingsProvider, (_, _) {});
    return const StudyOptionsState();
  }

  EffectiveStudyOptions? get _stored =>
      switch (ref.read(studyOptionsProvider(deckId)).value) {
        Ok(:final value) => value,
        _ => null,
      };

  StudyOptionsForm? get _form {
    final stored = _stored;
    final appDefaults = ref.read(appSettingsProvider).value?.studyDefaults;
    if (stored == null || appDefaults == null) return null;
    return StudyOptionsForm.of(stored, state, appDefaults: appDefaults);
  }

  void useAppDefaults({required bool isOn}) {
    if (state.isSaving) return;
    state = state.edited(isUsingAppDefaults: isOn);
  }

  /// −/+ or a hold, within 1–200; an invalid typed value steps from the
  /// shown one.
  void stepCardLimit(int delta) {
    final form = _form;
    if (form == null || state.isSaving || form.isUsingAppDefaults) return;
    final next = (form.options.cardLimit + delta).clamp(
      StudyOptions.minCardLimit,
      StudyOptions.maxCardLimit,
    );
    state = state.edited(cardLimit: next, isCardLimitInvalid: false);
  }

  /// A typed limit: kept and shown in either case, and marked invalid
  /// outside 1–200 (E1).
  void typeCardLimit(String text) {
    if (state.isSaving) return;
    final value = int.tryParse(text);
    final isValid =
        value != null &&
        value >= StudyOptions.minCardLimit &&
        value <= StudyOptions.maxCardLimit;
    state = state.edited(cardLimit: value, isCardLimitInvalid: !isValid);
  }

  void chooseNewCardOrder(NewCardOrder order) {
    if (state.isSaving) return;
    state = state.edited(newCardOrder: order);
  }

  /// Save, or Retry save: Use app defaults clears the root's override;
  /// otherwise the root takes the options shown (spec §5.5).
  Future<void> save() async {
    final stored = _stored;
    final form = _form;
    if (stored == null || form == null || state.isSaving) return;
    if (!form.canSave) return;
    state = state.withSave(StudyOptionsSave.saving);
    final Outcome<void, SettingsRejection> outcome;
    try {
      outcome = form.isUsingAppDefaults
          ? await ref.read(useAppDefaultsUseCaseProvider)(
              rootDeckId: stored.rootDeckId,
            )
          : await ref.read(saveRootStudyOptionsUseCaseProvider)(
              rootDeckId: stored.rootDeckId,
              options: form.options,
            );
    } on Failure {
      if (ref.mounted) state = state.withSave(StudyOptionsSave.failed);
      return;
    }
    if (!ref.mounted) return;
    state = switch (outcome) {
      Ok() => StudyOptionsState(timesSaved: state.timesSaved + 1),
      // The deck went meanwhile: the stream shows it gone.
      Rejected(reason: SettingsRejection.deckNotFound) => state.withSave(
        StudyOptionsSave.idle,
      ),
      Rejected() => state.withSave(StudyOptionsSave.failed),
    };
  }
}
```

`lib/features/settings/presentation/providers/save_root_study_options_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/save_root_study_options_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_root_study_options_use_case_provider.g.dart';

@riverpod
SaveRootStudyOptionsUseCase saveRootStudyOptionsUseCase(Ref ref) =>
    SaveRootStudyOptionsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/providers/study_options_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/presentation/providers/watch_study_options_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_options_provider.g.dart';

/// The options in force for [deckId]: its root's override or the app
/// defaults, again whenever either changes (BR-STUDY-056); `deckNotFound`
/// once the deck is gone or in the Trash.
@riverpod
Stream<Outcome<EffectiveStudyOptions, SettingsRejection>> studyOptions(
  Ref ref,
  String deckId,
) => ref.watch(watchStudyOptionsUseCaseProvider)(deckId: deckId);
```

`lib/features/settings/presentation/providers/use_app_defaults_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/use_app_defaults_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'use_app_defaults_use_case_provider.g.dart';

@riverpod
UseAppDefaultsUseCase useAppDefaultsUseCase(Ref ref) =>
    UseAppDefaultsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/providers/watch_study_options_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/watch_study_options_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_options_use_case_provider.g.dart';

@riverpod
WatchStudyOptionsUseCase watchStudyOptionsUseCase(Ref ref) =>
    WatchStudyOptionsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/states/study_options_state.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

/// Where screen 15's Save stands (spec §5.5).
enum StudyOptionsSave { idle, saving, failed }

/// Screen 15's draft: only what the person changed, over the options in
/// force; a null field shows the stored value (BR-SETTINGS-001).
@immutable
final class StudyOptionsState {
  const StudyOptionsState({
    this.isUsingAppDefaults,
    this.cardLimit,
    this.isCardLimitInvalid = false,
    this.newCardOrder,
    this.save = StudyOptionsSave.idle,
    this.timesSaved = 0,
  });

  final bool? isUsingAppDefaults;
  final int? cardLimit;

  /// A typed limit outside 1–200: shown in the error ring, never saved (E1).
  final bool isCardLimitInvalid;
  final NewCardOrder? newCardOrder;
  final StudyOptionsSave save;

  /// Grows with each save that landed, so the screen says "Saved" once per
  /// save.
  final int timesSaved;

  bool get isSaving => save == StudyOptionsSave.saving;

  /// The draft after an edit: a new edit ends a failed save's caption.
  StudyOptionsState edited({
    bool? isUsingAppDefaults,
    int? cardLimit,
    bool? isCardLimitInvalid,
    NewCardOrder? newCardOrder,
  }) => StudyOptionsState(
    isUsingAppDefaults: isUsingAppDefaults ?? this.isUsingAppDefaults,
    cardLimit: cardLimit ?? this.cardLimit,
    isCardLimitInvalid: isCardLimitInvalid ?? this.isCardLimitInvalid,
    newCardOrder: newCardOrder ?? this.newCardOrder,
    timesSaved: timesSaved,
  );

  StudyOptionsState withSave(StudyOptionsSave save) => StudyOptionsState(
    isUsingAppDefaults: isUsingAppDefaults,
    cardLimit: cardLimit,
    isCardLimitInvalid: isCardLimitInvalid,
    newCardOrder: newCardOrder,
    save: save,
    timesSaved: timesSaved,
  );
}

/// What screen 15 shows: the draft over the options in force.
@immutable
final class StudyOptionsForm {
  const StudyOptionsForm._({
    required this.isUsingAppDefaults,
    required this.options,
    required this.isCardLimitInvalid,
    required this.isChanged,
  });

  /// [appDefaults] are Settings' values, shown while the deck follows
  /// them: [stored] holds the override until Save clears it.
  factory StudyOptionsForm.of(
    EffectiveStudyOptions stored,
    StudyOptionsState draft, {
    required StudyOptions appDefaults,
  }) {
    final wasUsingAppDefaults = stored.source == StudyOptionsSource.appDefaults;
    final isUsingAppDefaults = draft.isUsingAppDefaults ?? wasUsingAppDefaults;
    // App defaults are shown as they are; own options start from the ones
    // in force (A1).
    final options = isUsingAppDefaults
        ? appDefaults
        : StudyOptions(
            cardLimit: draft.cardLimit ?? stored.options.cardLimit,
            newCardOrder: draft.newCardOrder ?? stored.options.newCardOrder,
          );
    final isChanged =
        isUsingAppDefaults != wasUsingAppDefaults ||
        // An override that cannot be read is replaced by any save.
        stored.source == StudyOptionsSource.unreadableRootOverride ||
        (!isUsingAppDefaults &&
            (options.cardLimit != stored.options.cardLimit ||
                options.newCardOrder != stored.options.newCardOrder));
    return StudyOptionsForm._(
      isUsingAppDefaults: isUsingAppDefaults,
      options: options,
      isCardLimitInvalid: !isUsingAppDefaults && draft.isCardLimitInvalid,
      isChanged: isChanged,
    );
  }

  final bool isUsingAppDefaults;
  final StudyOptions options;
  final bool isCardLimitInvalid;
  final bool isChanged;

  /// D9: Save only for a valid change.
  bool get canSave => isChanged && !isCardLimitInvalid;
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/settings test/features/study
flutter analyze
```

Expected: PASS, 9 tests in `study_options_controller_test.dart`; the repository and
model tests read `rootDeckName`.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/settings/data/mappers/study_config_mapper.dart \
  lib/features/settings/domain/models/effective_study_options_model.dart \
  lib/features/settings/presentation/controllers/study_options_controller.dart \
  lib/features/settings/presentation/providers/save_root_study_options_use_case_provider.dart \
  lib/features/settings/presentation/providers/study_options_provider.dart \
  lib/features/settings/presentation/providers/use_app_defaults_use_case_provider.dart \
  lib/features/settings/presentation/providers/watch_study_options_use_case_provider.dart \
  lib/features/settings/presentation/states/study_options_state.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/settings/domain/study_options_model_test.dart \
  test/features/settings/presentation/study_options_controller_test.dart
git commit -m "$(cat <<'EOF'
feat(settings): the study options draft, form and Save (FE-A3, UC-SETTINGS-001 A1, E4)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: Screen 15

**Files:**
- Create: `lib/features/settings/presentation/screens/study_options_screen.dart`
- Create: `lib/features/settings/presentation/widgets/sections/study_options_footer_widget.dart`
- Create: `lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/settings/presentation/goldens/study_options_defaults_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_defaults_light.png`
- Create: `test/features/settings/presentation/goldens/study_options_invalid_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_invalid_light.png`
- Create: `test/features/settings/presentation/goldens/study_options_loading_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_loading_light.png`
- Create: `test/features/settings/presentation/goldens/study_options_override_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_override_light.png`
- Create: `test/features/settings/presentation/goldens/study_options_save_failed_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_save_failed_light.png`
- Create: `test/features/settings/presentation/goldens/study_options_saved_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_saved_light.png`
- Create: `test/features/settings/presentation/goldens/study_options_saving_dark.png`
- Create: `test/features/settings/presentation/goldens/study_options_saving_light.png`
- Test (create): `test/features/settings/presentation/study_options_golden_test.dart`
- Test (create): `test/features/settings/presentation/study_options_screen_test.dart`
- Test (create): `test/visual_audit/screens/features/settings/screens/study_options_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 2's providers, form, controller and `rootDeckName`; plan 1's
  `MxStepper`, `settingsLoadErrorTitle` and card limit copy.
- Produces:
  - `StudyOptionsScreen({required String deckId, required Widget breadcrumb})`;
  - `StudyOptionsFormWidget`, `StudyOptionsFooterWidget`, and
    `studyOptionsOrderName(AppLocalizations, NewCardOrder)`;
  - the `studyOptions…` ARB keys.

- [ ] **Step 1: Write the failing tests**

`test/features/settings/presentation/study_options_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The path kit 15 draws; `app/` composes it from the deck feature (C6).
StudyOptionsScreen _screen(String deckId) => StudyOptionsScreen(
  deckId: deckId,
  breadcrumb: MxBreadcrumb(
    segments: [
      MxBreadcrumbSegment(label: _en.navLibrary),
      const MxBreadcrumbSegment(label: 'Korean TOPIK I'),
      const MxBreadcrumbSegment(label: 'Từ vựng'),
      MxBreadcrumbSegment(label: _en.deckStudyOptions),
    ],
  ),
);

const _override = '{"card_limit":50,"new_card_order":"random"}';

/// 한국어 TOPIK I › Từ vựng, as the kit draws it; [rootConfig] is the
/// root's override.
Future<String> _seed(LibraryEnv env, {String? rootConfig}) async {
  final root = await env.decks.root('Korean TOPIK I');
  final sub = await env.decks.sub(root.id, 'Từ vựng');
  if (rootConfig != null) {
    await env.db.customUpdate(
      'UPDATE deck SET study_config = ? WHERE id = ?',
      variables: [Variable(rootConfig), Variable(root.id)],
    );
  }
  return sub.id;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shot(WidgetTester tester, String name) => expectBoundaryGolden(
      tester,
      'goldens/study_options_${name}_$theme.png',
    );

    libraryTest('study options, override, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await shot(tester, 'override');
      });
    });

    libraryTest('study options, defaults, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await shot(tester, 'defaults');
      });
    });

    libraryTest('study options, invalid, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await tester.tap(find.byKey(const ValueKey('mx-stepper-value')));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '0');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        await shot(tester, 'invalid');
      });
    });

    libraryTest('study options, saving, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      final gate = Completer<void>();
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..hold = gate;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(deckId),
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump();
        await tester.tap(find.text(_en.cardSave));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await shot(tester, 'saving');
      });
      store.hold = null;
      gate.complete();
      await _settle(tester);
    });

    libraryTest('study options, saved, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump();
        await tester.tap(find.text(_en.cardSave));
        await _settle(tester);
        await _settle(tester);
        await shot(tester, 'saved');
      });
    });

    libraryTest('study options, save failed, $theme', (tester, env) async {
      final deckId = await _seed(env);
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..isFailing = true;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(deckId),
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.byType(MxToggle));
        await tester.pump();
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump();
        await tester.tap(find.text(_en.cardSave));
        await _settle(tester);
        await shot(tester, 'save_failed');
      });
    });

    libraryTest('study options, loading, $theme', (tester, env) async {
      final never = StreamController<Never>();
      addTearDown(never.close);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen('any'),
          brightness,
          overrides: [
            studyOptionsProvider('any').overrideWith((ref) => never.stream),
          ],
        );
        await shot(tester, 'loading');
      });
    });
  }
}
```

`test/features/settings/presentation/study_options_screen_test.dart`:

```dart
import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _valueKey = ValueKey('mx-stepper-value');

/// The screen with a stand-in path: `app/` composes the real one (C6).
StudyOptionsScreen _screen(String deckId) =>
    StudyOptionsScreen(deckId: deckId, breadcrumb: const SizedBox.shrink());

/// Korean › Words; the screen opens on Words. [rootConfig] is Korean's
/// stored override.
Future<({String rootId, String subId})> _seed(
  LibraryEnv env, {
  String? rootConfig,
}) async {
  final root = await env.decks.root('Korean');
  final sub = await env.decks.sub(root.id, 'Words');
  if (rootConfig != null) {
    await env.db.customUpdate(
      'UPDATE deck SET study_config = ? WHERE id = ?',
      variables: [Variable(rootConfig), Variable(root.id)],
    );
  }
  return (rootId: root.id, subId: sub.id);
}

MxButton _save(WidgetTester tester) =>
    tester.widget<MxButton>(find.byType(MxButton).last);

Future<EffectiveStudyOptions> _stored(LibraryEnv env, String deckId) async =>
    (await SettingsRepositoryImpl(env.db).studyOptionsOf(deckId: deckId))!;

void main() {
  libraryTest('a sub-deck shows its root\'s options, following Settings, '
      'with nothing to save (kit defaults, D9)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.text(_en.studyOptionsBelongTo('Korean')), findsOneWidget);
    expect(
      find.text(
        _en.studyOptionsFollowing(20, _en.studyOptionsOrderCreatedShort),
      ),
      findsOneWidget,
    );
    expect(
      find.text(_en.studyOptionsAppDefaultsHeader.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_en.studyOptionsLocalOnly), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });

  libraryTest('turning app defaults off, stepping and saving writes the '
      'root\'s options and says so (A1)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    expect(find.text(_en.studyOptionsThisDeck.toUpperCase()), findsOneWidget);
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    await tester.tap(find.text(_en.studyOptionsRandomHint));
    await tester.pump();
    await tester.tap(find.text(_en.cardSave));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyOptionsSaved), findsOneWidget);
    final stored = await tester.runAsync(() => _stored(env, ids.rootId));
    expect(stored!.source, StudyOptionsSource.rootOverride);
    expect(stored.options.cardLimit, 21);
    expect(stored.options.newCardOrder, NewCardOrder.random);
  });

  libraryTest('a typed 250 is refused under the stepper and Save waits '
      '(E1)', (tester, env) async {
    final ids = await _seed(
      env,
      rootConfig: '{"card_limit":50,"new_card_order":"random"}',
    );
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text(_en.settingsCardLimitInvalid(1, 200)), findsOneWidget);
    expect(find.text(_en.studyOptionsFixLimit), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });

  libraryTest('a failed save names what the deck still uses; Retry save '
      'writes it (E4)', (tester, env) async {
    final ids = await _seed(env);
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(ids.subId),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    await tester.tap(find.text(_en.cardSave));
    await tester.pumpAndSettle();

    expect(
      find.text(
        _en.studyOptionsSaveFailed(20, _en.studyOptionsOrderCreatedShort),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('memox.sqlite'), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.cardRetrySave));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyOptionsSaved), findsOneWidget);
  });

  libraryTest('an override that cannot be read is named, and Save replaces '
      'it', (tester, env) async {
    final ids = await _seed(env, rootConfig: '{not json');
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(_save(tester).onPressed, isNotNull);
  });

  libraryTest('a deck gone to the Trash shows the gone state with Back '
      '(spec §6)', (tester, env) async {
    final ids = await _seed(env);
    await env.decks.deleteDeck(deckId: ids.subId);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    expect(find.text(_en.commonBack), findsOneWidget);
  });

  libraryTest('a failed read shows the error with Retry and no invented '
      'value', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any'),
      overrides: [
        studyOptionsProvider(
          'any',
        ).overrideWith((ref) => Stream.error(FlakySettingsRepository.failure)),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
  });

  libraryTest('before the first read the screen shows skeleton rows and no '
      'Save (loading)', (tester, env) async {
    final never = StreamController<Never>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any'),
      overrides: [
        studyOptionsProvider('any').overrideWith((ref) => never.stream),
      ],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.text(_en.cardSave), findsNothing);
  });
}
```

`test/visual_audit/screens/features/settings/screens/study_options_screen_visual_audit_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 15', (tester, env) async {
    final root = await env.decks.root('Korean TOPIK I');
    final sub = await env.decks.sub(root.id, 'Từ vựng');
    await auditProductionScreen(
      tester,
      screen: StudyOptionsScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        StudyOptionsScreen(deckId: sub.id, breadcrumb: const SizedBox.shrink()),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/presentation/study_options_screen_test.dart
```

Expected: FAIL to compile: `study_options_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/settings/presentation/screens/study_options_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/study_options_footer_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/study_options_form_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 15, a root deck's study options, open on any deck of its tree
/// (UC-SETTINGS-001 A1, BR-STUDY-056): its own options or the app defaults,
/// saved by Save for sessions started afterwards (BR-SETTINGS-004).
class StudyOptionsScreen extends ConsumerWidget {
  const StudyOptionsScreen({
    super.key,
    required this.deckId,
    required this.breadcrumb,
  });

  final String deckId;

  /// The deck's path from the Library, ending at "Study options"; composed
  /// by `app/` from the deck feature, which settings may not read (C6).
  final Widget breadcrumb;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      studyOptionsControllerProvider(deckId).select((s) => s.timesSaved),
      (before, after) {
        if (after > (before ?? 0)) {
          showMxSnackbar(context, message: l10n.studyOptionsSaved);
        }
      },
    );
    final draft = ref.watch(studyOptionsControllerProvider(deckId));
    final appDefaults = ref.watch(appSettingsProvider).value?.studyDefaults;
    final options = ref.watch(studyOptionsProvider(deckId));
    final loaded = switch ((options, appDefaults)) {
      (AsyncData(value: Ok(:final value)), final defaults?) => (
        value,
        StudyOptionsForm.of(value, draft, appDefaults: defaults),
      ),
      _ => null,
    };
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.deckStudyOptions,
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
          breadcrumb,
          Expanded(
            child: switch (options) {
              _ when loaded != null => StudyOptionsFormWidget(
                deckId: deckId,
                stored: loaded.$1,
                form: loaded.$2,
                rootName: loaded.$1.rootDeckName,
              ),
              AsyncData(value: Rejected()) => _gone(context),
              AsyncError() => MxScreenScroll(
                children: [
                  MxErrorState(
                    title: l10n.settingsLoadErrorTitle,
                    body: l10n.libraryLoadErrorBody,
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(studyOptionsProvider(deckId)),
                  ),
                ],
              ),
              _ => MxScreenScroll(
                children: [
                  MxSkeletonList(
                    semanticLabel: l10n.commonLoading,
                    rows: _skeletonRows,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
      footer: switch (loaded) {
        (final EffectiveStudyOptions stored, final StudyOptionsForm form) =>
          StudyOptionsFooterWidget(deckId: deckId, stored: stored, form: form),
        null => null,
      },
    );
  }

  /// The deck went to the Trash or no longer exists (spec §6).
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

`lib/features/settings/presentation/widgets/sections/study_options_footer_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/study_options_form_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Screen 15's Save (kit 15): enabled only for a valid change (D9); after
/// a failure it is Retry save, and the caption names what the deck still
/// uses (E4).
class StudyOptionsFooterWidget extends ConsumerWidget {
  const StudyOptionsFooterWidget({
    super.key,
    required this.deckId,
    required this.stored,
    required this.form,
  });

  final String deckId;
  final EffectiveStudyOptions stored;
  final StudyOptionsForm form;

  /// Read in the callback only, never while building.
  void _save(WidgetRef ref) => unawaited(
    ref.read(studyOptionsControllerProvider(deckId).notifier).save(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final save = ref.watch(
      studyOptionsControllerProvider(deckId).select((s) => s.save),
    );
    final caption = switch (save) {
      _ when form.isCardLimitInvalid => l10n.studyOptionsFixLimit,
      StudyOptionsSave.failed => l10n.studyOptionsSaveFailed(
        stored.options.cardLimit,
        studyOptionsOrderName(l10n, stored.options.newCardOrder),
      ),
      _ => l10n.studyOptionsLocalOnly,
    };
    final (label, icon) = switch (save) {
      StudyOptionsSave.saving => (l10n.studyOptionsSaving, null),
      StudyOptionsSave.failed => (l10n.cardRetrySave, AppIcons.retry),
      StudyOptionsSave.idle => (l10n.cardSave, AppIcons.check),
    };
    return MxFooterBar(
      caption: caption,
      child: MxButton(
        label: label,
        icon: icon,
        isBlock: true,
        isLoading: save == StudyOptionsSave.saving,
        onPressed: form.canSave && save != StudyOptionsSave.saving
            ? () => _save(ref)
            : null,
      ),
    );
  }
}
```

`lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// [order] as it reads inside a sentence.
String studyOptionsOrderName(AppLocalizations l10n, NewCardOrder order) =>
    switch (order) {
      NewCardOrder.created => l10n.studyOptionsOrderCreatedShort,
      NewCardOrder.random => l10n.studyOptionsOrderRandomShort,
    };

/// Screen 15's options (kit 15): Use app defaults, then the card limit and
/// the new-card order, read-only while the deck follows Settings (A1).
class StudyOptionsFormWidget extends ConsumerWidget {
  const StudyOptionsFormWidget({
    super.key,
    required this.deckId,
    required this.stored,
    required this.form,
    required this.rootName,
  });

  final String deckId;
  final EffectiveStudyOptions stored;
  final StudyOptionsForm form;

  /// The root deck whose options these are (BR-STUDY-056).
  final String rootName;

  /// Read in callbacks only, never while building.
  StudyOptionsController _controller(WidgetRef ref) =>
      ref.read(studyOptionsControllerProvider(deckId).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSaving = ref.watch(
      studyOptionsControllerProvider(deckId).select((s) => s.isSaving),
    );
    // While Save runs the controls keep their look, as the kit draws it;
    // the controller ignores them until it ends (A4).
    final isEditable = !form.isUsingAppDefaults;
    final options = form.options;
    return MxScreenScroll(
      children: [
        MxNote(
          icon: AppIcons.library,
          text: l10n.studyOptionsBelongTo(rootName),
        ),
        if (stored.source == StudyOptionsSource.unreadableRootOverride)
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.studyOptionsUnreadable,
          ),
        MxSection(
          children: [
            MxSettingsRow(
              label: l10n.studyOptionsUseAppDefaults,
              subtitle: form.isUsingAppDefaults
                  ? l10n.studyOptionsFollowing(
                      options.cardLimit,
                      studyOptionsOrderName(l10n, options.newCardOrder),
                    )
                  : l10n.studyOptionsOwn,
              trailing: MxToggle(
                isOn: form.isUsingAppDefaults,
                semanticLabel: l10n.studyOptionsUseAppDefaults,
                onChanged: (isOn) =>
                    _controller(ref).useAppDefaults(isOn: isOn),
              ),
            ),
          ],
        ),
        MxSection(
          title: form.isUsingAppDefaults
              ? l10n.studyOptionsAppDefaultsHeader
              : l10n.studyOptionsThisDeck,
          note: l10n.studyOptionsApplyNote,
          children: [
            MxSettingsRow(
              label: l10n.settingsCardLimit,
              subtitle: l10n.studyOptionsCardLimitRange(
                StudyOptions.maxCardLimit,
              ),
              isEnabled: !form.isUsingAppDefaults,
              wideControl: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.micro,
                children: [
                  MxStepper(
                    value: options.cardLimit,
                    decrementLabel: l10n.settingsFewerCards,
                    incrementLabel: l10n.settingsMoreCards,
                    valueLabel: l10n.settingsCardLimit,
                    editHint: l10n.commonEdit,
                    isEnabled: isEditable,
                    isBusy: isSaving,
                    isInvalid: form.isCardLimitInvalid,
                    onDecrement: options.cardLimit > StudyOptions.minCardLimit
                        ? () => _controller(ref).stepCardLimit(-1)
                        : null,
                    onIncrement: options.cardLimit < StudyOptions.maxCardLimit
                        ? () => _controller(ref).stepCardLimit(1)
                        : null,
                    onValueSubmitted: (text) =>
                        _controller(ref).typeCardLimit(text),
                  ),
                  if (form.isCardLimitInvalid)
                    MxFieldMessage(
                      message: l10n.settingsCardLimitInvalid(
                        StudyOptions.minCardLimit,
                        StudyOptions.maxCardLimit,
                      ),
                    ),
                ],
              ),
            ),
            MxSettingsRow(
              label: l10n.settingsNewCardOrder,
              isEnabled: !form.isUsingAppDefaults,
            ),
            for (final (order, title, hint) in [
              (
                NewCardOrder.created,
                l10n.studyOptionsCreationOrder,
                l10n.studyOptionsCreationOrderHint,
              ),
              (
                NewCardOrder.random,
                l10n.settingsOrderRandom,
                l10n.studyOptionsRandomHint,
              ),
            ])
              MxOptionRow(
                title: title,
                description: hint,
                isSelected: options.newCardOrder == order,
                hasDivider: order != NewCardOrder.random,
                onSelected: isEditable
                    ? () => _controller(ref).chooseNewCardOrder(order)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 29524ba..eed667e 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -5081,5 +5081,107 @@
   "settingsOrderSaveFailed": "Couldn't save the new-card order.",
   "@settingsOrderSaveFailed": {
     "description": "Toast when saving the new-card order failed (E2); offers Retry."
+  },
+  "studyOptionsBelongTo": "These options belong to {root} and every sub-deck in it.",
+  "@studyOptionsBelongTo": {
+    "placeholders": {
+      "root": {
+        "type": "String"
+      }
+    },
+    "description": "Screen handoff 15 (FE-A3 plan 2): the note naming the root deck (BR-STUDY-056)."
+  },
+  "studyOptionsUnreadable": "This deck's options could not be read. Saving replaces them.",
+  "@studyOptionsUnreadable": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): warning for an override that cannot be read."
+  },
+  "studyOptionsUseAppDefaults": "Use app defaults",
+  "@studyOptionsUseAppDefaults": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): the toggle (UC-SETTINGS-001 A1)."
+  },
+  "studyOptionsFollowing": "Following Settings · {count} cards, {order}",
+  "@studyOptionsFollowing": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      },
+      "order": {
+        "type": "String"
+      }
+    },
+    "description": "Screen handoff 15 (FE-A3 plan 2): the toggle sub-line while on; {order} is studyOptionsOrderCreatedShort or …RandomShort."
+  },
+  "studyOptionsOwn": "Off · this deck has its own options",
+  "@studyOptionsOwn": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): the toggle sub-line while off."
+  },
+  "studyOptionsOrderCreatedShort": "created order",
+  "@studyOptionsOrderCreatedShort": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): the order inside a sentence."
+  },
+  "studyOptionsOrderRandomShort": "random order",
+  "@studyOptionsOrderRandomShort": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): the order inside a sentence."
+  },
+  "studyOptionsAppDefaultsHeader": "App defaults (read-only here)",
+  "@studyOptionsAppDefaultsHeader": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): section header while the toggle is on."
+  },
+  "studyOptionsThisDeck": "This deck",
+  "@studyOptionsThisDeck": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): section header while the toggle is off."
+  },
+  "studyOptionsCardLimitRange": "1 to {max}",
+  "@studyOptionsCardLimitRange": {
+    "placeholders": {
+      "max": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 15 (FE-A3 plan 2): the card limit sub-line."
+  },
+  "studyOptionsCreationOrder": "Creation order",
+  "@studyOptionsCreationOrder": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): order option."
+  },
+  "studyOptionsCreationOrderHint": "Oldest cards first — the order you added or imported them",
+  "@studyOptionsCreationOrderHint": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): order option description."
+  },
+  "studyOptionsRandomHint": "Shuffled each learning session",
+  "@studyOptionsRandomHint": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): order option description."
+  },
+  "studyOptionsApplyNote": "Changes apply to sessions started from now on. A session already open keeps the options it started with.",
+  "@studyOptionsApplyNote": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): the note under the options (BR-SETTINGS-004)."
+  },
+  "studyOptionsFixLimit": "Fix the limit to enable save.",
+  "@studyOptionsFixLimit": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): footer caption while the limit is invalid."
+  },
+  "studyOptionsSaveFailed": "Couldn't save. The deck still uses {count} cards, {order}.",
+  "@studyOptionsSaveFailed": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      },
+      "order": {
+        "type": "String"
+      }
+    },
+    "description": "Screen handoff 15 (FE-A3 plan 2): footer caption after a failed save (E4); {order} is …Short."
+  },
+  "studyOptionsLocalOnly": "Saved to this device only.",
+  "@studyOptionsLocalOnly": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): footer caption."
+  },
+  "studyOptionsSaving": "Saving…",
+  "@studyOptionsSaving": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): the Save button while it runs."
+  },
+  "studyOptionsSaved": "Saved · applies to the next session",
+  "@studyOptionsSaved": {
+    "description": "Screen handoff 15 (FE-A3 plan 2): toast after a save."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 7f18a3a..7d29c5f 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -959,5 +959,24 @@
   "settingsResetFailed": "Không đặt lại được tuỳ chọn ứng dụng. Chưa có gì thay đổi.",
   "settingsSaved": "Đã lưu",
   "settingsCardLimitSaveFailed": "Không lưu được số thẻ mỗi phiên. Vẫn là {count}.",
-  "settingsOrderSaveFailed": "Không lưu được thứ tự thẻ mới."
+  "settingsOrderSaveFailed": "Không lưu được thứ tự thẻ mới.",
+  "studyOptionsBelongTo": "Các tuỳ chọn này thuộc về {root} và mọi bộ thẻ con trong đó.",
+  "studyOptionsUnreadable": "Không đọc được tuỳ chọn của bộ thẻ này. Lưu sẽ thay chúng.",
+  "studyOptionsUseAppDefaults": "Dùng mặc định của ứng dụng",
+  "studyOptionsFollowing": "Theo Cài đặt · {count} thẻ, {order}",
+  "studyOptionsOwn": "Tắt · bộ thẻ này có tuỳ chọn riêng",
+  "studyOptionsOrderCreatedShort": "theo ngày tạo",
+  "studyOptionsOrderRandomShort": "ngẫu nhiên",
+  "studyOptionsAppDefaultsHeader": "Mặc định của ứng dụng (chỉ xem ở đây)",
+  "studyOptionsThisDeck": "Bộ thẻ này",
+  "studyOptionsCardLimitRange": "1 đến {max}",
+  "studyOptionsCreationOrder": "Theo thứ tự tạo",
+  "studyOptionsCreationOrderHint": "Thẻ cũ nhất trước — theo thứ tự bạn thêm hoặc nhập",
+  "studyOptionsRandomHint": "Xáo trộn mỗi phiên học",
+  "studyOptionsApplyNote": "Thay đổi áp dụng cho các phiên bắt đầu từ bây giờ. Phiên đang mở giữ tuỳ chọn lúc nó bắt đầu.",
+  "studyOptionsFixLimit": "Sửa giới hạn để lưu được.",
+  "studyOptionsSaveFailed": "Chưa lưu được. Bộ thẻ vẫn dùng {count} thẻ, {order}.",
+  "studyOptionsLocalOnly": "Chỉ lưu trên thiết bị này.",
+  "studyOptionsSaving": "Đang lưu…",
+  "studyOptionsSaved": "Đã lưu · áp dụng cho phiên sau"
 }
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/features/settings/presentation/study_options_golden_test.dart
flutter test test/features/settings test/visual_audit test/l10n
flutter analyze
```

Expected: PASS, 8 tests in `study_options_screen_test.dart`. Fourteen new goldens; compare
each with `docs/shared/ui/screen-handoff/img/15-study-options/`:
- `study_options_override_*` with `override-*`: the breadcrumb, the note naming the
  root, the toggle off, "This deck", 50 and Random, and Save disabled (D9);
- `study_options_defaults_*` with `defaults-*`: the toggle on with "Following Settings ·
  20 cards, created order", the options dimmed;
- `study_options_invalid_*`, `…_saving_*`, `…_saved_*`, `…_save_failed_*` and
  `…_loading_*` with their kit frames (C5, C8; the message under the stepper).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/settings/presentation/screens/study_options_screen.dart \
  lib/features/settings/presentation/widgets/sections/study_options_footer_widget.dart \
  lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/settings/presentation/study_options_golden_test.dart \
  test/features/settings/presentation/study_options_screen_test.dart \
  test/visual_audit/screens/features/settings/screens/study_options_screen_visual_audit_test.dart \
  test/features/settings/presentation/goldens/study_options_defaults_dark.png \
  test/features/settings/presentation/goldens/study_options_defaults_light.png \
  test/features/settings/presentation/goldens/study_options_invalid_dark.png \
  test/features/settings/presentation/goldens/study_options_invalid_light.png \
  test/features/settings/presentation/goldens/study_options_loading_dark.png \
  test/features/settings/presentation/goldens/study_options_loading_light.png \
  test/features/settings/presentation/goldens/study_options_override_dark.png \
  test/features/settings/presentation/goldens/study_options_override_light.png \
  test/features/settings/presentation/goldens/study_options_save_failed_dark.png \
  test/features/settings/presentation/goldens/study_options_save_failed_light.png \
  test/features/settings/presentation/goldens/study_options_saved_dark.png \
  test/features/settings/presentation/goldens/study_options_saved_light.png \
  test/features/settings/presentation/goldens/study_options_saving_dark.png \
  test/features/settings/presentation/goldens/study_options_saving_light.png
git commit -m "$(cat <<'EOF'
feat(settings): screen 15 Study options (FE-A3, UC-SETTINGS-001 A1, E4)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: The ways in: the deck action sheet and screen 14 (D3)

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_entry_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_light.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_actions_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_actions_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_direction_sheet_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_direction_sheet_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_eight_box_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_eight_box_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_loading_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_loading_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_nothing_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_nothing_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_only_new_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_only_new_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_refused_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_refused_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_resume_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_resume_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_sm2_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_sm2_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_start_failed_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_start_failed_light.png`
- Modify: `test/features/study/presentation/goldens/study_entry_starting_dark.png`
- Modify: `test/features/study/presentation/goldens/study_entry_starting_light.png`
- Test (modify): `test/app/settings_routes_test.dart`
- Test (modify): `test/features/deck/presentation/deck_action_sheet_test.dart`
- Test (modify): `test/features/deck/presentation/deck_level_screen_test.dart`
- Test (modify): `test/features/study/presentation/study_entry_actions_golden_test.dart`
- Test (modify): `test/features/study/presentation/study_entry_golden_test.dart`
- Test (modify): `test/features/study/presentation/study_entry_screen_test.dart`
- Test (modify): `test/support/library_harness.dart`
- Test (modify): `test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 3's `StudyOptionsScreen`.
- Produces:
  - `AppRoutes.studyOptionsChild` (`options`) and `AppRoutes.studyOptions(deckId)`, a
    child of the deck route on the root navigator, built by `app/`'s `_studyOptions`
    with the deck's breadcrumb (C6);
  - `DeckStudyHeaderWidget({String? trailingLabel})`, the breadcrumb's last segment;
  - `DeckAction.studyOptions`, and the sheet row with `deckStudyOptionsHint`;
  - `openDeckActions(…, {required ValueChanged<String> onOpenStudyOptions})`;
  - `DeckLevelScreen({required ValueChanged<String> onOpenStudyOptions})`, and the same
    on every deck widget that carries `onOpenAlgorithm`;
  - `StudyEntryScreen({VoidCallback? onOpenStudyOptions})`;
  - `AppIcons.studyOptions`;
  - `deckScreen({ValueChanged<String>? onOpenStudyOptions})` in the test harness;
  - `comingSoonStudyOptionsBody` is removed.

- [ ] **Step 1: Write the failing tests**

`test/app/settings_routes_test.dart` (apply this diff):

```diff
diff --git a/test/app/settings_routes_test.dart b/test/app/settings_routes_test.dart
index c1a19fa..8985831 100644
--- a/test/app/settings_routes_test.dart
+++ b/test/app/settings_routes_test.dart
@@ -2,10 +2,15 @@ import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/app/placeholder_screen.dart';
 import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
+import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
+import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
+import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
 import 'package:memox/shared/widgets/mx_bottom_nav.dart';
+import 'package:memox/shared/widgets/mx_breadcrumb.dart';
 
+import '../support/deck_fixtures.dart';
 import '../support/library_harness.dart';
 
 final _en = lookupAppLocalizations(const Locale('en'));
@@ -54,4 +59,53 @@ void main() {
       expect(find.byType(MxBottomNav), findsOneWidget);
     });
   }
+
+  libraryTest('a deck\'s Study options opens screen 15 above the shell; '
+      'Back returns to the deck (FE-A3 D3)', (tester, env) async {
+    await env.decks.root('Korean');
+    await pumpMemoxApp(tester, env);
+    await _tap(tester, find.text('Korean'));
+    await _tap(tester, find.byTooltip(_en.deckActions));
+    await _tap(
+      tester,
+      find.descendant(
+        of: find.byType(MxActionSheetCommandRow),
+        matching: find.text(_en.deckStudyOptions),
+      ),
+    );
+
+    expect(find.byType(StudyOptionsScreen), findsOneWidget);
+    expect(find.byType(MxBottomNav), findsNothing);
+    // The path from the deck feature, ending at this page (C6).
+    expect(
+      find.descendant(
+        of: find.byType(MxBreadcrumb),
+        matching: find.text(_en.deckStudyOptions),
+      ),
+      findsOneWidget,
+    );
+    await _tap(tester, find.byTooltip(_en.commonBack));
+    expect(find.byType(StudyOptionsScreen), findsNothing);
+    expect(_barTitle('Korean'), findsOneWidget);
+  });
+
+  libraryTest('screen 14\'s icon opens screen 15; Back returns to the '
+      'entry (FE-A3 D3)', (tester, env) async {
+    await env.decks.root('Korean');
+    await pumpMemoxApp(tester, env);
+    await _tap(tester, find.text('Korean'));
+    await _tap(tester, find.byTooltip(_en.deckActions));
+    await _tap(
+      tester,
+      find.descendant(
+        of: find.byType(MxActionSheetCommandRow),
+        matching: find.text(_en.studyThisDeck),
+      ),
+    );
+    await _tap(tester, find.byTooltip(_en.deckStudyOptions));
+
+    expect(find.byType(StudyOptionsScreen), findsOneWidget);
+    await _tap(tester, find.byTooltip(_en.commonBack));
+    expect(find.byType(StudyEntryScreen), findsOneWidget);
+  });
 }
```

`test/features/deck/presentation/deck_action_sheet_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_action_sheet_test.dart b/test/features/deck/presentation/deck_action_sheet_test.dart
index 48bf930..baaaab1 100644
--- a/test/features/deck/presentation/deck_action_sheet_test.dart
+++ b/test/features/deck/presentation/deck_action_sheet_test.dart
@@ -55,10 +55,32 @@ void main() {
     expect(find.text(_en.deckDelete), findsOneWidget);
     expect(find.text(_en.deckMove), findsNothing);
     expect(find.text(_en.deckReorder), findsNothing);
-    // Study opens the entry (FE-A6 D10); Study options waits under Coming
-    // soon (spec A4, amended).
+    // Study opens the entry (FE-A6 D10); Study options opens screen 15
+    // (FE-A3 D3).
     expect(find.text(_en.studyThisDeck), findsOneWidget);
-    expect(find.text(_en.deckStudyOptions), findsNothing);
+    expect(find.text(_en.deckStudyOptions), findsOneWidget);
+    expect(find.text(_en.deckStudyOptionsHint), findsOneWidget);
+  });
+
+  libraryTest('Study options opens the deck\'s options, below Rename '
+      '(FE-A3 D3, kit 01)', (tester, env) async {
+    final korean = await env.decks.root('Korean');
+    final words = await env.decks.sub(korean.id, 'Words');
+    final opened = <String>[];
+    await pumpLibraryScreen(
+      tester,
+      env,
+      deckScreen(deckId: words.id, onOpenStudyOptions: opened.add),
+    );
+    await _openSheet(tester);
+
+    expect(
+      tester.getTopLeft(find.text(_en.deckStudyOptions)).dy,
+      greaterThan(tester.getTopLeft(find.text(_en.deckRename)).dy),
+    );
+    await tester.tap(find.text(_en.deckStudyOptions));
+    await tester.pumpAndSettle();
+    expect(opened, [words.id]);
   });
 
   libraryTest('a sub-deck offers move, not the scheduler; two decks reorder', (
```

`test/features/deck/presentation/deck_level_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_level_screen_test.dart b/test/features/deck/presentation/deck_level_screen_test.dart
index fb3c99f..375e3fd 100644
--- a/test/features/deck/presentation/deck_level_screen_test.dart
+++ b/test/features/deck/presentation/deck_level_screen_test.dart
@@ -305,14 +305,15 @@ void main() {
     for (final feature in [
       _en.libraryStarterDecks,
       _en.libraryTags,
-      _en.deckStudyOptions,
       _en.comingSoonProgressSort,
     ]) {
       expect(find.text(feature), findsOneWidget, reason: feature);
     }
+    // Study options shipped (FE-A3 D3): it no longer waits here.
+    expect(find.text(_en.deckStudyOptions), findsNothing);
     // Import and export shipped (FE-B3): neither waits here any more.
     expect(find.text(_en.deckActionExport), findsNothing);
-    // Study is live (FE-A6 D10); only Study options still waits.
+    // Study is live (FE-A6 D10).
     expect(
       find.descendant(
         of: find.byType(DeckComingSoonSheetWidget),
```

`test/features/study/presentation/study_entry_actions_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/study/presentation/study_entry_actions_golden_test.dart b/test/features/study/presentation/study_entry_actions_golden_test.dart
index 0b1921b..cf9a614 100644
--- a/test/features/study/presentation/study_entry_actions_golden_test.dart
+++ b/test/features/study/presentation/study_entry_actions_golden_test.dart
@@ -29,6 +29,8 @@ StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
     part: DeckStudyHeaderPart.breadcrumb,
   ),
   onOpenSession: (_) {},
+  // As app/ wires it: the app bar carries Study options (kit 14).
+  onOpenStudyOptions: () {},
 );
 
 /// The kit's sm2 frame without Hangul: 25 new, 4 due, two of them overdue.
```

`test/features/study/presentation/study_entry_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/study/presentation/study_entry_golden_test.dart b/test/features/study/presentation/study_entry_golden_test.dart
index ac621fe..316551e 100644
--- a/test/features/study/presentation/study_entry_golden_test.dart
+++ b/test/features/study/presentation/study_entry_golden_test.dart
@@ -23,6 +23,8 @@ StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
     part: DeckStudyHeaderPart.breadcrumb,
   ),
   onOpenSession: (_) {},
+  // As app/ wires it: the app bar carries Study options (kit 14).
+  onOpenStudyOptions: () {},
 );
 
 /// A learned card of [deckId], due at [due].
```

`test/features/study/presentation/study_entry_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/study/presentation/study_entry_screen_test.dart b/test/features/study/presentation/study_entry_screen_test.dart
index 2680bfe..9be904e 100644
--- a/test/features/study/presentation/study_entry_screen_test.dart
+++ b/test/features/study/presentation/study_entry_screen_test.dart
@@ -49,6 +49,26 @@ MxStatTile _tile(WidgetTester tester, String label) => tester
     .singleWhere((tile) => tile.label == label);
 
 void main() {
+  libraryTest('the app bar\'s Study options icon opens the deck\'s options '
+      '(FE-A3 D3, kit 14)', (tester, env) async {
+    final deck = await env.decks.root('Korean');
+    var opened = 0;
+    await pumpLibraryScreen(
+      tester,
+      env,
+      StudyEntryScreen(
+        deckId: deck.id,
+        title: const Text('Deck'),
+        breadcrumb: const SizedBox.shrink(),
+        onOpenSession: (_) {},
+        onOpenStudyOptions: () => opened++,
+      ),
+    );
+
+    await tester.tap(find.byTooltip(_en.deckStudyOptions));
+    expect(opened, 1);
+  });
+
   libraryTest('New and Due are two figures, never one sum, and the overdue '
       'note counts the due cards from before today (IT-STUDY-001)', (
     tester,
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
index 90c6714..9bd0910 100644
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -212,6 +212,7 @@ DeckLevelScreen deckScreen({
   ValueChanged<String>? onImportCards,
   ValueChanged<DeckEntity>? onExportCards,
   ValueChanged<String>? onOpenStudy,
+  ValueChanged<String>? onOpenStudyOptions,
   VoidCallback? onOpenTrash,
 }) => DeckLevelScreen(
   deckId: deckId,
@@ -220,6 +221,7 @@ DeckLevelScreen deckScreen({
   onSearch: onSearch ?? () {},
   onOpenAlgorithm: onOpenAlgorithm ?? (_) {},
   onOpenStudy: onOpenStudy ?? (_) {},
+  onOpenStudyOptions: onOpenStudyOptions ?? (_) {},
   onAddCard: onAddCard ?? (_) {},
   onImportCards: onImportCards ?? (_) {},
   onExportCards: onExportCards ?? (_) {},
```

`test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart` (apply this diff):

```diff
diff --git a/test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart b/test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart
index b23fd43..66390d8 100644
--- a/test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart
+++ b/test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart
@@ -20,6 +20,8 @@ StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
     part: DeckStudyHeaderPart.breadcrumb,
   ),
   onOpenSession: (_) {},
+  // As app/ wires it: the app bar carries Study options (kit 14).
+  onOpenStudyOptions: () {},
 );
 
 void main() {
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/deck/presentation/deck_action_sheet_test.dart test/features/study/presentation/study_entry_screen_test.dart
```

Expected: FAIL to compile: `deckStudyOptionsHint` is not a member of
`AppLocalizations`, and `DeckLevelScreen` has no `onOpenStudyOptions`.

- [ ] **Step 3: Implement**

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index d18a66b..165d832 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -20,6 +20,7 @@ import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart'
 import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
 import 'package:memox/features/settings/presentation/screens/language_screen.dart';
 import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
+import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
 import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
@@ -88,6 +89,16 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                           state.pathParameters[AppRoutes.deckIdParam]!,
                         ),
                       ),
+                      // A full-screen task above the shell, as the kit
+                      // draws it (FE-A3 spec §4).
+                      GoRoute(
+                        path: AppRoutes.studyOptionsChild,
+                        parentNavigatorKey: rootNavigator,
+                        builder: (context, state) => _studyOptions(
+                          context,
+                          state.pathParameters[AppRoutes.deckIdParam]!,
+                        ),
+                      ),
                       GoRoute(
                         path: AppRoutes.algorithmChild,
                         builder: (context, state) => DeckAlgorithmScreen(
@@ -216,6 +227,8 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
     onOpenAlgorithm: (id) =>
         unawaited(context.push(AppRoutes.deckAlgorithm(id))),
     onOpenStudy: study,
+    onOpenStudyOptions: (id) =>
+        unawaited(context.push(AppRoutes.studyOptions(id))),
     onAddCard: addCard,
     onImportCards: (id) => unawaited(context.push(AppRoutes.importCards(id))),
     onExportCards: (deck) => unawaited(
@@ -259,6 +272,20 @@ StudyEntryScreen _studyEntry(BuildContext context, String deckId) =>
       ),
       onOpenSession: (sessionId) =>
           context.go(AppRoutes.studySession(sessionId)),
+      onOpenStudyOptions: () =>
+          unawaited(context.push(AppRoutes.studyOptions(deckId))),
+    );
+
+/// Screen 15 with the deck's path from the deck feature, which settings
+/// may not read (FE-A3 plan 2, C6).
+StudyOptionsScreen _studyOptions(BuildContext context, String deckId) =>
+    StudyOptionsScreen(
+      deckId: deckId,
+      breadcrumb: DeckStudyHeaderWidget(
+        deckId: deckId,
+        part: DeckStudyHeaderPart.breadcrumb,
+        trailingLabel: context.l10n.deckStudyOptions,
+      ),
     );
 
 /// Opens the Trash on the root navigator (FE-B1 D2). The router pushes it,
```

`lib/app/router/app_routes.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_routes.dart b/lib/app/router/app_routes.dart
index c899732..e9a0282 100644
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -45,6 +45,9 @@ abstract final class AppRoutes {
   /// A deck's Study Entry (screen 14), relative to [deckChild] (FE-A6 D1).
   static const String studyChild = 'study';
 
+  /// A deck's study options (screen 15), relative to [deckChild] (FE-A3).
+  static const String studyOptionsChild = 'options';
+
   /// A deck's card editor in create mode, relative to [deckChild].
   static const String cardNewChild = 'cards/new';
 
@@ -68,6 +71,10 @@ abstract final class AppRoutes {
   /// Screen 14 for [deckId].
   static String studyEntry(String deckId) => '${deck(deckId)}/$studyChild';
 
+  /// Screen 15 for [deckId], whose options are its root's.
+  static String studyOptions(String deckId) =>
+      '${deck(deckId)}/$studyOptionsChild';
+
   /// The session [sessionId], its summary once it has ended.
   static String studySession(String sessionId) => '$study/session/$sessionId';
 
```

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index 91f1954..0858ab6 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -57,6 +57,7 @@ abstract final class AppIcons {
   static const IconData gallery = Icons.widgets_outlined;
   static const IconData themeMode = Icons.contrast;
   static const IconData theme = Icons.palette_outlined;
+  static const IconData studyOptions = Icons.tune; // sliders-horizontal
   static const IconData shuffle = Icons.shuffle; // shuffle
   static const IconData language = Icons.language; // globe
   static const IconData resetOptions =
```

`lib/features/deck/presentation/screens/deck_level_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/screens/deck_level_screen.dart b/lib/features/deck/presentation/screens/deck_level_screen.dart
index e4cefbb..acac948 100644
--- a/lib/features/deck/presentation/screens/deck_level_screen.dart
+++ b/lib/features/deck/presentation/screens/deck_level_screen.dart
@@ -39,6 +39,7 @@ class DeckLevelScreen extends StatelessWidget {
     required this.onSearch,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenStudyOptions,
     required this.cardContent,
     required this.cardAppBar,
     required this.cardBreadcrumb,
@@ -62,6 +63,9 @@ class DeckLevelScreen extends StatelessWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Screen 15 for a deck (FE-A3 D3).
+  final ValueChanged<String> onOpenStudyOptions;
+
   /// What a deck of cards shows. The router passes the card feature's list
   /// section; `deck` never imports `card` (spec D8).
   final Widget Function(DeckView view) cardContent;
@@ -102,6 +106,7 @@ class DeckLevelScreen extends StatelessWidget {
       onSearch: onSearch,
       onOpenAlgorithm: onOpenAlgorithm,
       onOpenStudy: onOpenStudy,
+      onOpenStudyOptions: onOpenStudyOptions,
       onOpenTrash: onOpenTrash,
     ),
     final id => _OpenDeck(
@@ -110,6 +115,7 @@ class DeckLevelScreen extends StatelessWidget {
       onOpenAncestor: onOpenAncestor,
       onOpenAlgorithm: onOpenAlgorithm,
       onOpenStudy: onOpenStudy,
+      onOpenStudyOptions: onOpenStudyOptions,
       cardContent: cardContent,
       cardAppBar: cardAppBar,
       cardBreadcrumb: cardBreadcrumb,
@@ -130,6 +136,7 @@ class _OpenDeck extends ConsumerWidget {
     required this.onOpenAncestor,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenStudyOptions,
     required this.cardContent,
     required this.cardAppBar,
     required this.cardBreadcrumb,
@@ -147,6 +154,9 @@ class _OpenDeck extends ConsumerWidget {
 
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
+
+  /// Screen 15 for a deck (FE-A3 D3).
+  final ValueChanged<String> onOpenStudyOptions;
   final Widget Function(DeckView view) cardContent;
   final Widget Function(DeckView view, Widget back, Widget deckActions)
   cardAppBar;
@@ -178,6 +188,7 @@ class _OpenDeck extends ConsumerWidget {
         onOpenAncestor: onOpenAncestor,
         onOpenAlgorithm: onOpenAlgorithm,
         onOpenStudy: onOpenStudy,
+        onOpenStudyOptions: onOpenStudyOptions,
         cardContent: cardContent,
         cardAppBar: cardAppBar,
         cardBreadcrumb: cardBreadcrumb,
@@ -231,6 +242,7 @@ class _OpenDeckContent extends ConsumerWidget {
     required this.onOpenAncestor,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenStudyOptions,
     required this.cardContent,
     required this.cardAppBar,
     required this.cardBreadcrumb,
@@ -248,6 +260,9 @@ class _OpenDeckContent extends ConsumerWidget {
 
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
+
+  /// Screen 15 for a deck (FE-A3 D3).
+  final ValueChanged<String> onOpenStudyOptions;
   final Widget Function(DeckView view) cardContent;
   final Widget Function(DeckView view, Widget back, Widget deckActions)
   cardAppBar;
@@ -288,6 +303,7 @@ class _OpenDeckContent extends ConsumerWidget {
               ? () => onExportCards(deck)
               : null,
           onOpenStudy: onOpenStudy,
+          onOpenStudyOptions: onOpenStudyOptions,
           onOpenTrash: onOpenTrash,
           isOpenDeck: true,
         ),
@@ -343,6 +359,7 @@ class _OpenDeckContent extends ConsumerWidget {
                 onOpenDeck: onOpenDeck,
                 onOpenAlgorithm: onOpenAlgorithm,
                 onOpenStudy: onOpenStudy,
+                onOpenStudyOptions: onOpenStudyOptions,
                 onOpenTrash: onOpenTrash,
                 schedulerType: view.schedulerType,
                 // Owner decision C-O6: its sub-decks are at level 10.
```

`lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
index b1a68b5..662d315 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
@@ -13,6 +13,7 @@ enum DeckAction {
   open,
   study,
   rename,
+  studyOptions,
   move,
   reviewAlgorithm,
   importCards,
@@ -91,9 +92,9 @@ class DeckActionSheetWidget extends StatelessWidget {
     );
   }
 
-  /// Study opens the Study Entry (FE-A6 D10); Study options waits under
-  /// Coming soon (spec A4, amended). Root
-  /// decks own the algorithm and cannot move (ruling P2-L8).
+  /// Study opens the Study Entry (FE-A6 D10) and Study options screen 15
+  /// (FE-A3 D3), below Rename as kit 01 draws it. Root decks own the
+  /// algorithm and cannot move (ruling P2-L8).
   List<Widget> _rows(BuildContext context) {
     final l10n = context.l10n;
     final deck = view.deck;
@@ -117,6 +118,13 @@ class DeckActionSheetWidget extends StatelessWidget {
         label: l10n.deckRename,
         onTap: () => choose(DeckAction.rename),
       ),
+      MxActionSheetCommandRow(
+        icon: AppIcons.studyOptions,
+        label: l10n.deckStudyOptions,
+        subtitle: l10n.deckStudyOptionsHint,
+        hasChevron: true,
+        onTap: () => choose(DeckAction.studyOptions),
+      ),
       if (deck.isRoot) ...[
         MxActionSheetCommandRow(
           icon: AppIcons.scheduler,
```

`lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
index 75c2f85..d15c55f 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
@@ -21,7 +21,6 @@ class DeckComingSoonSheetWidget extends StatelessWidget {
   const DeckComingSoonSheetWidget({super.key});
 
   static List<(IconData, String, String)> _features(AppLocalizations l10n) => [
-    (AppIcons.settings, l10n.deckStudyOptions, l10n.comingSoonStudyOptionsBody),
     (
       AppIcons.progress,
       l10n.comingSoonProgressSort,
```

`lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart
index 1909737..ee81e27 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart
@@ -22,6 +22,7 @@ class DeckLevelBodyWidget extends ConsumerWidget {
     required this.onOpenDeck,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenStudyOptions,
     required this.emptyState,
     required this.schedulerType,
     required this.hasDeepestSubDecks,
@@ -37,6 +38,9 @@ class DeckLevelBodyWidget extends ConsumerWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Screen 15 for a deck (FE-A3 D3).
+  final ValueChanged<String> onOpenStudyOptions;
+
   /// Opens the Trash (screen 06), for a refused Undo (FE-B1).
   final VoidCallback? onOpenTrash;
 
@@ -73,6 +77,7 @@ class DeckLevelBodyWidget extends ConsumerWidget {
                   onOpenDeck: onOpenDeck,
                   onOpenAlgorithm: onOpenAlgorithm,
                   onOpenStudy: onOpenStudy,
+                  onOpenStudyOptions: onOpenStudyOptions,
                   onOpenTrash: onOpenTrash,
                   emptyState: emptyState,
                   schedulerType: schedulerType,
```

`lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart
index dda876c..6f0b173 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart
@@ -28,6 +28,7 @@ class DeckLevelListWidget extends ConsumerWidget {
     required this.onOpenDeck,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenStudyOptions,
     required this.emptyState,
     required this.schedulerType,
     required this.hasDeepestSubDecks,
@@ -44,6 +45,9 @@ class DeckLevelListWidget extends ConsumerWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Screen 15 for a deck (FE-A3 D3).
+  final ValueChanged<String> onOpenStudyOptions;
+
   /// Opens the Trash (screen 06), for a refused Undo (FE-B1).
   final VoidCallback? onOpenTrash;
 
@@ -142,6 +146,7 @@ class DeckLevelListWidget extends ConsumerWidget {
                       onOpenDeck: onOpenDeck,
                       onOpenAlgorithm: onOpenAlgorithm,
                       onOpenStudy: onOpenStudy,
+                      onOpenStudyOptions: onOpenStudyOptions,
                       onOpenTrash: onOpenTrash,
                       isOpenDeck: false,
                     ),
```

`lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
index abfcec4..d8728d2 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
@@ -27,6 +27,7 @@ class DeckLibraryRootWidget extends ConsumerWidget {
     required this.onSearch,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenStudyOptions,
     required this.onOpenTrash,
   });
 
@@ -37,6 +38,9 @@ class DeckLibraryRootWidget extends ConsumerWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Screen 15 for a deck (FE-A3 D3).
+  final ValueChanged<String> onOpenStudyOptions;
+
   /// Opens the Trash (screen 06) from the app bar (FE-B1 D1).
   final VoidCallback onOpenTrash;
 
@@ -108,6 +112,7 @@ class DeckLibraryRootWidget extends ConsumerWidget {
               onOpenDeck: onOpenDeck,
               onOpenAlgorithm: onOpenAlgorithm,
               onOpenStudy: onOpenStudy,
+              onOpenStudyOptions: onOpenStudyOptions,
               onOpenTrash: onOpenTrash,
               schedulerType: null,
               hasDeepestSubDecks: false,
```

`lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart
index b8adc30..ff677a9 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart
@@ -18,11 +18,16 @@ class DeckStudyHeaderWidget extends ConsumerWidget {
     super.key,
     required this.deckId,
     required this.part,
+    this.trailingLabel,
   });
 
   final String deckId;
   final DeckStudyHeaderPart part;
 
+  /// A page under the deck (screen 15's "Study options"): the breadcrumb's
+  /// last, current segment.
+  final String? trailingLabel;
+
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final view = switch (ref.watch(deckViewProvider(deckId))) {
@@ -47,6 +52,8 @@ class DeckStudyHeaderWidget extends ConsumerWidget {
           for (final entry in view.breadcrumb)
             MxBreadcrumbSegment(label: entry.name),
           MxBreadcrumbSegment(label: view.deck.name),
+          if (trailingLabel case final label?)
+            MxBreadcrumbSegment(label: label),
         ],
       ),
     };
```

`lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
index e6b4fa8..daac93c 100644
--- a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
+++ b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
@@ -27,6 +27,7 @@ Future<void> openDeckActions(
   required ValueChanged<String> onOpenDeck,
   required ValueChanged<String> onOpenAlgorithm,
   required ValueChanged<String> onOpenStudy,
+  required ValueChanged<String> onOpenStudyOptions,
   required bool isOpenDeck,
   VoidCallback? onImportCards,
   VoidCallback? onExportCards,
@@ -68,6 +69,8 @@ Future<void> openDeckActions(
       onOpenDeck(deckId);
     case DeckAction.study:
       onOpenStudy(deckId);
+    case DeckAction.studyOptions:
+      onOpenStudyOptions(deckId);
     case DeckAction.rename:
       await showRenameDeckDialog(context, deck: view.deck);
     case DeckAction.move:
```

`lib/features/study/presentation/screens/study_entry_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/study/presentation/screens/study_entry_screen.dart b/lib/features/study/presentation/screens/study_entry_screen.dart
index 0ff25d6..1c0a2dc 100644
--- a/lib/features/study/presentation/screens/study_entry_screen.dart
+++ b/lib/features/study/presentation/screens/study_entry_screen.dart
@@ -32,6 +32,7 @@ class StudyEntryScreen extends ConsumerWidget {
     required this.title,
     required this.breadcrumb,
     required this.onOpenSession,
+    this.onOpenStudyOptions,
   });
 
   final String deckId;
@@ -45,6 +46,10 @@ class StudyEntryScreen extends ConsumerWidget {
   /// Opens the session a start answered; composed by `app/`.
   final ValueChanged<String> onOpenSession;
 
+  /// Opens the deck's study options (screen 15, FE-A3 D3); composed by
+  /// `app/`, as study may not read settings. Null hides the icon.
+  final VoidCallback? onOpenStudyOptions;
+
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     ref.listen(
@@ -61,6 +66,14 @@ class StudyEntryScreen extends ConsumerWidget {
           semanticLabel: l10n.commonBack,
           onPressed: () => unawaited(Navigator.of(context).maybePop()),
         ),
+        actions: [
+          if (onOpenStudyOptions case final open?)
+            MxIconButton(
+              icon: AppIcons.studyOptions,
+              semanticLabel: l10n.deckStudyOptions,
+              onPressed: open,
+            ),
+        ],
       ),
       body: StudyEntryBodyWidget(
         deckId: deckId,
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index eed667e..b033d0b 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -1872,6 +1872,10 @@
   "@deckStudyOptions": {
     "description": "Screen handoff 01/04 (library alignment phase C): deckStudyOptions."
   },
+  "deckStudyOptionsHint": "Cards per session · new-card order",
+  "@deckStudyOptionsHint": {
+    "description": "Screen handoff 01 (FE-A3 D3): the Study options row's sub-line in the deck action sheet."
+  },
   "deckReviewAlgorithm": "Review algorithm",
   "@deckReviewAlgorithm": {
     "description": "Screen handoff 01/04 (library alignment phase C): deckReviewAlgorithm."
@@ -2318,10 +2322,6 @@
   "@comingSoonTagsBody": {
     "description": "Coming soon: what tags do."
   },
-  "comingSoonStudyOptionsBody": "Session size and new-card order.",
-  "@comingSoonStudyOptionsBody": {
-    "description": "Coming soon: what study options do."
-  },
   "comingSoonProgressSort": "Sort by progress",
   "@comingSoonProgressSort": {
     "description": "Coming soon: the progress sort's name."
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 7d29c5f..4401277 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -354,6 +354,7 @@
   "commonDone": "Xong",
   "deckOpen": "Mở bộ thẻ",
   "deckStudyOptions": "Tuỳ chọn học",
+  "deckStudyOptionsHint": "Số thẻ mỗi phiên · thứ tự thẻ mới",
   "deckReviewAlgorithm": "Thuật toán ôn tập",
   "deckReviewAlgorithmLocked": "{algorithm} · đã khoá · đặt lại để bắt đầu lại",
   "deckReorderHint": "Đưa lên trước hoặc sau một bộ thẻ cùng cấp",
@@ -427,7 +428,6 @@
   "libraryComingSoonBody": "Những tính năng này sẽ có ở phiên bản sau. Mọi thứ bạn thêm bây giờ đều được giữ.",
   "comingSoonStarterDecksBody": "Bộ thẻ có sẵn để sao chép.",
   "comingSoonTagsBody": "Gắn nhãn thẻ, lọc theo nhãn.",
-  "comingSoonStudyOptionsBody": "Số thẻ mỗi phiên, thứ tự thẻ mới.",
   "comingSoonProgressSort": "Sắp xếp theo độ thuộc",
   "comingSoonProgressSortBody": "Bộ thẻ thuộc ít nhất lên trước.",
   "cardDeckProgress": "Tiến độ bộ thẻ · {algorithm}",
```

- [ ] **Step 4: Generate, render the goldens, run the whole suite**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features/deck test/features/study
flutter test
flutter test --tags golden
flutter analyze
bash .claude/skills/flutter-architecture/scripts/check_architecture.sh
```

Expected: PASS, and the architecture check is clean: `deck` and `study` never import
`settings`. `settings_routes_test.dart` has 5 tests. 24 goldens change:
- `library_deck_actions_*`: the Study options row with its sub-line, below Rename;
- `library_coming_soon_*`: no Study options line;
- every `study_entry_*`: the sliders icon at the end of the app bar, as kit 14 draws it.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/router/app_router.dart \
  lib/app/router/app_routes.dart \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/deck/presentation/screens/deck_level_screen.dart \
  lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart \
  lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart \
  lib/features/study/presentation/screens/study_entry_screen.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/app/settings_routes_test.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/deck_level_screen_test.dart \
  test/features/study/presentation/study_entry_actions_golden_test.dart \
  test/features/study/presentation/study_entry_golden_test.dart \
  test/features/study/presentation/study_entry_screen_test.dart \
  test/support/library_harness.dart \
  test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart \
  test/features/deck/presentation/goldens/library_coming_soon_dark.png \
  test/features/deck/presentation/goldens/library_coming_soon_light.png \
  test/features/deck/presentation/goldens/library_deck_actions_dark.png \
  test/features/deck/presentation/goldens/library_deck_actions_light.png \
  test/features/study/presentation/goldens/study_entry_direction_sheet_dark.png \
  test/features/study/presentation/goldens/study_entry_direction_sheet_light.png \
  test/features/study/presentation/goldens/study_entry_eight_box_dark.png \
  test/features/study/presentation/goldens/study_entry_eight_box_light.png \
  test/features/study/presentation/goldens/study_entry_loading_dark.png \
  test/features/study/presentation/goldens/study_entry_loading_light.png \
  test/features/study/presentation/goldens/study_entry_nothing_dark.png \
  test/features/study/presentation/goldens/study_entry_nothing_light.png \
  test/features/study/presentation/goldens/study_entry_only_new_dark.png \
  test/features/study/presentation/goldens/study_entry_only_new_light.png \
  test/features/study/presentation/goldens/study_entry_refused_dark.png \
  test/features/study/presentation/goldens/study_entry_refused_light.png \
  test/features/study/presentation/goldens/study_entry_resume_dark.png \
  test/features/study/presentation/goldens/study_entry_resume_light.png \
  test/features/study/presentation/goldens/study_entry_sm2_dark.png \
  test/features/study/presentation/goldens/study_entry_sm2_light.png \
  test/features/study/presentation/goldens/study_entry_start_failed_dark.png \
  test/features/study/presentation/goldens/study_entry_start_failed_light.png \
  test/features/study/presentation/goldens/study_entry_starting_dark.png \
  test/features/study/presentation/goldens/study_entry_starting_light.png
git commit -m "$(cat <<'EOF'
feat(settings): the route, the deck sheet and screen 14 open Study options (FE-A3 D3)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: Detail file 15, 01 and 14, index, checklist, register, use case, WBS; the gate

**Files:**
- Modify: `docs/features/settings/README.md`
- Modify: `docs/features/settings/ui.md`
- Modify: `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`
- Modify: `docs/shared/ui/screen-handoff/14-study-entry.md`
- Create: `docs/shared/ui/screen-handoff/15-study-options.md`
- Modify: `docs/shared/ui/screen-state-checklist.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/_generated/traceability.md (generated)`

**Interfaces:** none (documents). The kit's captures of screen 15 are already in
`docs/shared/ui/screen-handoff/img/15-study-options/`.

- [ ] **Step 1: Update the documents**

`docs/features/settings/README.md` (apply this diff):

```diff
diff --git a/docs/features/settings/README.md b/docs/features/settings/README.md
index 02585a9..6d176cf 100644
--- a/docs/features/settings/README.md
+++ b/docs/features/settings/README.md
@@ -14,6 +14,7 @@ Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn
 | Tab Settings (màn 23) | UC-SETTINGS-001 |
 | Theme (màn 25) | UC-SETTINGS-001 |
 | Language (màn 26) | UC-SETTINGS-001 |
+| Study options của bộ thẻ (màn 15) | UC-SETTINGS-001 (A1, E4) |
 
 Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặc deep link `/settings`"). Nhắc học hằng ngày (UC-REMINDER-001) nằm trong branch Settings nhưng thuộc feature `reminders`.
 
```

`docs/features/settings/ui.md` (apply this diff):

```diff
diff --git a/docs/features/settings/ui.md b/docs/features/settings/ui.md
index a813ee0..6eae3b5 100644
--- a/docs/features/settings/ui.md
+++ b/docs/features/settings/ui.md
@@ -9,6 +9,7 @@ Màn hình, điều hướng và validation dùng chung nhiều UC của feature
 | 23 · Settings | `/settings` (tab Settings) | Bottom bar | [23-settings.md](../../shared/ui/screen-handoff/23-settings.md) |
 | 25 · Theme | `/settings/theme`, trên root navigator, không có bottom bar | Hàng Theme của màn 23 | [25-theme.md](../../shared/ui/screen-handoff/25-theme.md) |
 | 26 · Language | `/settings/language`, trên root navigator, không có bottom bar | Hàng Language của màn 23 | [26-language.md](../../shared/ui/screen-handoff/26-language.md) |
+| 15 · Study options | `/decks/deck/:deckId/options`, trên root navigator, không có bottom bar | Hàng Study options trong action sheet của deck; icon trên app bar màn 14 | [15-study-options.md](../../shared/ui/screen-handoff/15-study-options.md) |
 
 Theme và ngôn ngữ áp cho cả app: `main()` đọc dòng `app_settings` một lần trước frame
 đầu (chờ tối đa 2 giây), rồi `MemoxApp` theo stream. Nguồn:
```

`docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md` (apply this diff):

```diff
diff --git a/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md b/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md
index 4471bda..d9b0699 100644
--- a/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md
+++ b/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md
@@ -3,7 +3,7 @@ id: UC-SETTINGS-001
 title: Đặt tuỳ chọn ứng dụng
 status: ready
 rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008, BR-SRS-022, BR-STUDY-003, BR-STUDY-024, BR-STUDY-035, BR-STUDY-056, BR-STUDY-057]
-code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart, lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/usecases/save_root_study_options_use_case.dart, lib/features/settings/domain/usecases/use_app_defaults_use_case.dart, lib/features/settings/presentation/screens/settings_screen.dart, lib/features/settings/presentation/screens/theme_screen.dart, lib/features/settings/presentation/screens/language_screen.dart, lib/features/settings/presentation/controllers/settings_controller.dart, lib/app/startup_settings.dart]
+code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart, lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/usecases/save_root_study_options_use_case.dart, lib/features/settings/domain/usecases/use_app_defaults_use_case.dart, lib/features/settings/presentation/screens/settings_screen.dart, lib/features/settings/presentation/screens/theme_screen.dart, lib/features/settings/presentation/screens/language_screen.dart, lib/features/settings/presentation/controllers/settings_controller.dart, lib/features/settings/presentation/screens/study_options_screen.dart, lib/features/settings/presentation/controllers/study_options_controller.dart, lib/app/startup_settings.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 1476726..81c1a5a 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -47,7 +47,7 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 12 | Card export | 9 | FE-B3 | aligned | [12-card-export.md](12-card-export.md) |
 | 13 | Study home | 7 | FE-A8 | built (P6) | [13-study-home.md](13-study-home.md) |
 | 14 | Study entry | 9 | FE-A6, FE-A7 | aligned | [14-study-entry.md](14-study-entry.md) |
-| 15 | Study options | 7 | FE-A3 | not built | — |
+| 15 | Study options | 7 | FE-A3 | aligned | [15-study-options.md](15-study-options.md) |
 | 16 | Study · Browse | 1 | FE-A6 | aligned | [16-study-browse.md](16-study-browse.md) |
 | 16a | Study · Self-check (`self_assess`; not in the kit) | — | FE-A6 | aligned | [16a-study-self-assess.md](16a-study-self-assess.md) (shape brief) |
 | 17 | Study · Match | 1 | FE-A6 | aligned | [17-study-match.md](17-study-match.md) |
```

`docs/shared/ui/screen-handoff/01-deck-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/01-deck-list.md b/docs/shared/ui/screen-handoff/01-deck-list.md
index 4e42a5a..974c87b 100644
--- a/docs/shared/ui/screen-handoff/01-deck-list.md
+++ b/docs/shared/ui/screen-handoff/01-deck-list.md
@@ -32,10 +32,12 @@ One recursive screen for the Library root (`/decks`) and any open deck
 `MxBottomSheet` with a header (tile, name, "N sub-decks · N cards · {algorithm}") and
 `MxActionSheetCommandRow`s:
 
-- **Root deck:** Open deck · Study this deck → screen 14 · Rename · Review algorithm
+- **Root deck:** Open deck · Study this deck → screen 14 · Rename · Study options
+  ("Cards per session · new-card order") → screen 15 · Review algorithm
   ("{algorithm} · locked · reset to start over" when locked) → screen 02 · Reorder ·
   Move to Trash ("Recoverable for 30 days").
 - **Sub-deck:** Open ("N sub-decks · N cards") · Study this deck → screen 14 · Rename ·
+  Study options → screen 15 (its root's options) ·
   Move to another deck · Reorder ("Move before or after a sibling") · Move to Trash
   ("Recoverable for 30 days").
 
@@ -103,7 +105,6 @@ One `MxBottomSheet`, "Sort & filter":
 |---|---|---|
 | Starter decks, Tags actions | under Coming soon | FE-B4, FE-B2 |
 | "Browse starter decks" | under Coming soon | FE-B4 |
-| Study options | under Coming soon | FE-A3 |
 | Sort by progress | under Coming soon | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Mastery bar, donut | hidden | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Due strip tap | not interactive | FE-A8 |
```

`docs/shared/ui/screen-handoff/14-study-entry.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/14-study-entry.md b/docs/shared/ui/screen-handoff/14-study-entry.md
index d69a42f..afa7fda 100644
--- a/docs/shared/ui/screen-handoff/14-study-entry.md
+++ b/docs/shared/ui/screen-handoff/14-study-entry.md
@@ -9,7 +9,7 @@ between Learn and Review before a session opens. UC-STUDY-001, UC-STUDY-003.
 
 | Region | Widget | Design |
 |---|---|---|
-| App bar | `MxAppBar` (content density) | Back, deck name (composed by `app/` from the deck feature, FE-A6 spec D16). The kit's trailing "Study options" icon is hidden — see Deviations. |
+| App bar | `MxAppBar` (content density) | Back, deck name (composed by `app/` from the deck feature, FE-A6 spec D16), and the trailing "Study options" icon, which opens screen 15 (FE-A3 D3). |
 | Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck. |
 | Hero | `MxCard` (hero) + `MxStatTile` × 2 (FE-A6 spec D17) | "{algorithm} · cards per session {n}" (BR-STUDY-024); two stat tiles, New and Due: Due above zero in primary, New above zero muted, a zero in plain ink (BR-STUDY-047, BR-STUDY-051 — the two sets never merge); "{n} of the due cards are overdue" note, in the warning ink, when any are overdue. |
 | Resume banner | `MxCard` | "Session from today" overline with a pulse dot, "{kind} · {mode} · {done} of {total} cards", a line explaining Continue vs. starting fresh, "Continue" (`MxButton`, primary block). Shown only per BR-STUDY-072's in-progress, same-day session. |
@@ -70,7 +70,6 @@ the toast "This deck no longer exists" (UC-STUDY-001 E1). Goldens:
 | Artifact | V8 | Wins |
 |---|---|---|
 | SM-2's direction choice as inline `MxOptionRow`s on the entry screen itself | A separate `MxBottomSheet` opened by the footer's Review action, with the same three choices and a locked "Start review" action; the space the rows took stays empty above the pinned footer, as the kit's own `onlyNew` frame draws it | UC-STUDY-003 (the documented flow is a sheet, opened after Review, not an inline section) |
-| App bar's trailing "Study options" icon | Hidden; named under Coming soon | Spec A4 row 92 (amended 2026-09-25) names "Study options" explicitly; no screen or UC defines its destination yet |
 | Resume banner's pulse dot in the kit's streak colour | Primary colour | Row 28 of the UI-base ruling ledger: no `streak` tone exists |
 | The resume dot pulses | Static and decorative | FE-A8 ruling S3: one treatment for 13 and 14 |
 | The resume banner states its progress as text only | A `MxLinearProgress` track under the line too, as 13's Resume card draws it | FE-A8 H2: the shared track has two callers |
```

`docs/shared/ui/screen-handoff/15-study-options.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 15 · Study options

A root deck's study options, opened from any deck in its tree: its own cards per session
and new-card order, or the app defaults from Settings. Save writes them for sessions
started afterwards. UC-SETTINGS-001 A1, E4; BR-STUDY-056, BR-SETTINGS-003,
BR-SETTINGS-004; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.5.

## Entry points

- **The deck action sheet (screen 01):** "Study options" / "Cards per session · new-card
  order", below Rename (D3). It left the Coming soon sheet.
- **Screen 14's app bar:** the sliders icon, "Study options" (D3).

Both open `/decks/deck/:deckId/options` on the root navigator, with no bottom bar. On a
sub-deck the screen shows its root's options (BR-STUDY-056).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back and "Study options". |
| Breadcrumb | `MxBreadcrumb` | Library › the deck's path › the deck › "Study options". |
| Note | `MxNote` (layers) | "These options belong to {root} and every sub-deck in it." |
| Unreadable override | `MxInlineBanner` (warning) | "This deck's options could not be read. Saving replaces them." |
| Toggle | `MxSection` + `MxSettingsRow` + `MxToggle` | "Use app defaults"; on: "Following Settings · {n} cards, {order}", off: "Off · this deck has its own options". |
| Options | `MxSection` | "App defaults (read-only here)" or "This deck"; "Cards per session" / "1 to 200" with an `MxStepper` (−/+, hold, typed entry); "New-card order" and two `MxOptionRow`s: "Creation order" / "Oldest cards first — the order you added or imported them", "Random" / "Shuffled each learning session". Read-only and dimmed while the toggle is on. The note: "Changes apply to sessions started from now on. A session already open keeps the options it started with." |
| Card limit message | `MxFieldMessage` (error) | "Enter a number from 1 to 200", under the stepper (UC E1). |
| Footer | `MxFooterBar` + `MxButton` | "Save", enabled only for a valid change (D9); spinning while it runs; "Retry save" after a failure. The caption: "Saved to this device only.", "Fix the limit to enable save." or "Couldn't save. The deck still uses {n} cards, {order}." |
| Toast | `MxSnackbar` | "Saved · applies to the next session". |

Save runs Use app defaults when the toggle is on and the root had its own options, and
saves the root's options otherwise. A second Save while one runs is ignored (A4).

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| override | ![](img/15-study-options/override-light.png) | ![](img/15-study-options/override-dark.png) | Save is disabled until something changes (D9). |
| defaults | ![](img/15-study-options/defaults-light.png) | ![](img/15-study-options/defaults-dark.png) | As drawn; Save disabled. |
| invalid | ![](img/15-study-options/invalid-light.png) | ![](img/15-study-options/invalid-dark.png) | **Deviation:** the message sits under the stepper and the sub-line stays (UC E1). |
| saving | ![](img/15-study-options/saving-light.png) | ![](img/15-study-options/saving-dark.png) | The stepper and the button spin; the button has no "Saving…" text (`MxButton.isLoading`). |
| saved | ![](img/15-study-options/saved-light.png) | ![](img/15-study-options/saved-dark.png) | As drawn. |
| saveFailed | ![](img/15-study-options/saveFailed-light.png) | ![](img/15-study-options/saveFailed-dark.png) | As drawn. |
| loading | ![](img/15-study-options/loading-light.png) | ![](img/15-study-options/loading-dark.png) | Skeleton rows, no footer (UI-base row 125). |
| gone | — | — | **V8 addition (spec §6):** a deck gone to the Trash shows "This deck is no longer here" with Back (UI-base row 129). |
| read error | — | — | **V8 addition:** `MxErrorState` with Retry and no invented value. |

Goldens: `test/features/settings/presentation/goldens/study_options_{override,defaults,invalid,saving,saved,save_failed,loading}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| The root's name in bold inside the note | Plain text | `MxNote` carries one plain string |
| "Enter a number from 1 to 200" in place of the sub-line | Under the stepper, the sub-line kept | UC-SETTINGS-001 E1 |
| Save enabled in override and defaults | Enabled only for a valid change | D9 |
| A spinner and "Saving…" in the button | The button spins | `MxButton.isLoading` |
| No gone state | The Library's gone state with Back | Spec §6; UI-base row 129 |

## Copy

"Study options" · "These options belong to {root} and every sub-deck in it." · "This
deck's options could not be read. Saving replaces them." · "Use app defaults" ·
"Following Settings · {n} cards, {order}" · "created order" · "random order" · "Off · this
deck has its own options" · "App defaults (read-only here)" · "This deck" · "Cards per
session" · "1 to {max}" · "Enter a number from {min} to {max}" · "New-card order" ·
"Creation order" · "Oldest cards first — the order you added or imported them" ·
"Random" · "Shuffled each learning session" · "Changes apply to sessions started from now
on. A session already open keeps the options it started with." · "Save" · "Retry save" ·
"Saved to this device only." · "Fix the limit to enable save." · "Couldn't save. The deck
still uses {n} cards, {order}." · "Saved · applies to the next session" · "Cards per
session · new-card order".
```

`docs/shared/ui/screen-state-checklist.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-state-checklist.md b/docs/shared/ui/screen-state-checklist.md
index 7617d4e..ff5e838 100644
--- a/docs/shared/ui/screen-state-checklist.md
+++ b/docs/shared/ui/screen-state-checklist.md
@@ -32,7 +32,7 @@ Màn 14, 16, 16a và 17–21 là `aligned` trong index từ phase P5 của roadm
 
 ## Tổng hợp
 
-Kit có **26 màn, 211 state**. Xong **136**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **46**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
+Kit có **26 màn, 211 state**. Xong **143**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **39**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
 
 | # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
 |---|---|---|---|---|---|---|---|---|
@@ -50,7 +50,7 @@ Kit có **26 màn, 211 state**. Xong **136**; một phần **5**; đã dựng nh
 | 12 | Card export | FE-B3 | 9 | 9 | 0 | 0 | 0 | [12-card-export.md](screen-handoff/12-card-export.md) |
 | 13 | Study home | FE-A8 | 7 | 7 | 0 | 0 | 0 | [13-study-home.md](screen-handoff/13-study-home.md) |
 | 14 | Study entry | FE-A6, FE-A7 | 9 | 9 | 0 | 0 | 0 | [14-study-entry.md](screen-handoff/14-study-entry.md) |
-| 15 | Study options | FE-A3 | 7 | 0 | 0 | 7 | 0 | — |
+| 15 | Study options | FE-A3 | 7 | 7 | 0 | 0 | 0 | [15-study-options.md](screen-handoff/15-study-options.md) |
 | 16 | Study · Browse | FE-A6 | 1 | 1 | 0 | 0 | 0 | [16-study-browse.md](screen-handoff/16-study-browse.md) |
 | 17 | Study · Match | FE-A6 | 1 | 1 | 0 | 0 | 0 | [17-study-match.md](screen-handoff/17-study-match.md) |
 | 18 | Study · Guess | FE-A6 | 1 | 1 | 0 | 0 | 0 | [18-study-guess.md](screen-handoff/18-study-guess.md) |
@@ -319,17 +319,17 @@ FE-A6, FE-A7 · [14-study-entry.md](screen-handoff/14-study-entry.md)
 
 ### 15 · Study options
 
-FE-A3 · chưa có detail file
+FE-A3 · [15-study-options.md](screen-handoff/15-study-options.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | Deck override | — | chưa làm |  |
-| [ ] | App defaults | — | chưa làm |  |
-| [ ] | Invalid limit | — | chưa làm |  |
-| [ ] | Saving | — | chưa làm |  |
-| [ ] | Saved | — | chưa làm |  |
-| [ ] | Save failed | — | chưa làm |  |
-| [ ] | Loading | — | chưa làm |  |
+| [x] | Deck override | `override` | xong | Save chỉ bật khi có thay đổi hợp lệ (D9). |
+| [x] | App defaults | `defaults` | xong |  |
+| [x] | Invalid limit | `invalid` | xong | Thông báo nằm dưới stepper (UC E1). |
+| [x] | Saving | `saving` | xong | Nút chỉ có spinner, không có chữ "Saving…". |
+| [x] | Saved | `saved` | xong |  |
+| [x] | Save failed | `saveFailed` | xong |  |
+| [x] | Loading | `loading` | xong | Skeleton list (UI-base §9 dòng 125). |
 
 ### 16 · Study · Browse
 
@@ -480,3 +480,4 @@ FE-A3 · [26-language.md](screen-handoff/26-language.md)
 - **Tạo ngày 2026-09-26** theo yêu cầu của chủ dự án, từ `master` tại `e2ad9de`.
 - **Cập nhật ngày 2026-09-26:** FE-A3 plan 1 dựng màn 23, 25 và 26; 14 state chuyển sang
   xong.
+- **Cập nhật ngày 2026-09-27:** FE-A3 plan 2 dựng màn 15; 7 state chuyển sang xong.
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index 24edc7f..3b91d2e 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -527,10 +527,11 @@ item names where it comes from.
 | 122 | Dark `primary-soft` and `primary-border` follow the new primary (the kit mixes `#8B9AFF`), and dark `surface-hero` mixes it at 18 % (kit: 12 %) to keep the kit's lift; the selected radio ring inks in `primaryInk`; a solid `MxBadge` is primary only; a done import step's check inks in `onMastery` (the kit's dark on-primary, kept) | owner 2026-09-27, D1, D5, D6 |
 | 123 | "Reset app options" also turns the daily reminder off and puts it back at 20:00 (BR-SETTINGS-008): the kit's confirmation body ("Theme, language, cards per session and new-card order go back to their defaults.") and the row's sub-line ("Theme, language, study defaults") leave it out. FE-B5 names it in both, and calls `ReconcileReminderUseCase` after a reset, when it shows the Daily reminder row; until then nobody can turn the reminder on, so nothing a person sees changes (FE-A3 D4, owner 2026-09-27) | reminders spec D3, D4; FE-A3 D4 |
 | 124 | Screen 23's Theme is a row naming the choice ("Follows the system setting", "Light", "Dark") that opens screen 25, not the kit's inline System · Light · Dark tray | FE-A3 D2 |
-| 125 | Screen 23 loads as `MxSkeletonList`, not skeleton sub-lines and controls inside its sections; a failed read shows `MxErrorState` with Retry, which the kit does not draw (UC-SETTINGS-001 E3). Screens 25 and 26 do the same | FE-A3 plan 1 |
+| 125 | Screen 23 loads as `MxSkeletonList`, not skeleton sub-lines and controls inside its sections; a failed read shows `MxErrorState` with Retry, which the kit does not draw (UC-SETTINGS-001 E3). Screens 15, 25 and 26 do the same | FE-A3 plan 1 |
 | 126 | `MxStepper` goes beyond the kit's −/+ by one: holding −/+ repeats (400 ms, then every 80 ms) and a tap on the number types one (FE-A3 D6). The number's box stays 36 tall, its tap target 48 | FE-A3 plan 1 |
 | 127 | `MxSegmentedTray` stacks its options, one per line, when their labels do not fit on one (large text, long Vietnamese labels); the kit draws one line only | FE-A3 plan 1 (visual audit) |
 | 128 | Beside a wide control, `MxSettingsRow`'s tile sits at the top with the label, as kit 23 draws it, not centred on the row | FE-A3 plan 1 |
+| 129 | Screen 15 on a deck gone to the Trash, or gone for good, shows the Library's gone state (\"This deck is no longer here\") with Back; the kit draws none | FE-A3 plan 2 (spec §6) |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index 6db657d..bd616b0 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -77,7 +77,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 |---|---|---|---|---|---|---|
 | FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | đang làm | BE-03 | L | [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); căn theo screen handoff ở FE-A11; [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: panel "Mastered x/y" và sort theo progress chờ BR/UC của deck định nghĩa (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | đang làm | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: file chi tiết handoff cho màn 08–10 |
-| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | đang làm | BE-A1 | M | [spec](superpowers/specs/2026-09-26-settings-ui-design.md); [plan 1: màn 23, 25, 26, `MxStepper`, theme và ngôn ngữ toàn app](superpowers/plans/2026-09-26-settings-ui.md); screen handoff [23](shared/ui/screen-handoff/23-settings.md), [25](shared/ui/screen-handoff/25-theme.md), [26](shared/ui/screen-handoff/26-language.md); [ui.md](features/settings/ui.md) | Plan 2: màn 15 (Study options) và hai lối vào (D3) |
+| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | xong | BE-A1 | M | [spec](superpowers/specs/2026-09-26-settings-ui-design.md); [plan 1: màn 23, 25, 26, `MxStepper`, theme và ngôn ngữ toàn app](superpowers/plans/2026-09-26-settings-ui.md); [plan 2: màn 15 và hai lối vào](superpowers/plans/2026-09-27-study-options-ui.md); screen handoff [15](shared/ui/screen-handoff/15-study-options.md), [23](shared/ui/screen-handoff/23-settings.md), [25](shared/ui/screen-handoff/25-theme.md), [26](shared/ui/screen-handoff/26-language.md); [ui.md](features/settings/ui.md) | — |
 | FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
 | FE-A5 | Thiết kế luồng học (Impeccable): mặt thẻ, lật thẻ, hàng chấm điểm, tổng kết phiên, streak, cách trình bày sáu mode | xong | FE-07 | S | File chi tiết handoff 13, 14, 16–21 kèm ảnh state ([screen handoff index](shared/ui/screen-handoff/00-index.md)); shape cho phiên `self_assess` ở `16a-study-self-assess.md` (chấm Again/Hard/Good/Easy, hiện khoảng ôn dự kiến ở lượt scheduled) | — |
 | FE-A6 | Study Entry, màn hình phiên học và ôn tập cho sáu mode, tổng kết phiên (UC-STUDY-001; BR-MODE-001…BR-MODE-019) | xong | FE-A5, BE-A3, BE-A4, BE-A10 | XL | Backend đã sẵn (BE-A3, BE-A4, BE-A10 xong); màn 14, 16–21 trong kit; kịch bản IT của [study](features/study/it-scenarios.md) và [study-mode](features/study-mode/it-scenarios.md); [spec study UI](superpowers/specs/2026-09-26-study-ui-design.md) (đã duyệt 2026-09-26, chia phase P1–P5; D11 thêm hai phần backend nhỏ trong P1 và P2); phase P1a (nền: tone `success`/`caution`/`danger`, `MxStatTile`, read model của entry và tổng kết): [plan](superpowers/plans/2026-09-26-study-p1a-foundations.md); phase P1b (màn 14 chỉ đọc, route, lối vào từ action sheet và summary, đóng phiên cũ khi mở app): [plan](superpowers/plans/2026-09-26-study-p1b-entry.md); phase P1c (route phiên toàn màn hình, controller, màn 16 Browse, màn 21 Summary; thoát giữa phiên hiện tổng kết theo quyết định của chủ dự án về D8): [plan](superpowers/plans/2026-09-26-study-p1c-session.md); phase P2 (màn 16a self-assess với preview khoảng cách D11b, các action của màn 14: Learn, Review, Continue, starting/refused/startFailed, sheet chọn chiều hỏi FE-A7; deck `sm2` học được trọn vẹn): [plan](superpowers/plans/2026-09-26-study-p2-self-assess.md); roadmap P3→P6 đã duyệt: [roadmap](superpowers/plans/2026-09-26-study-chain-roadmap.md); phase P3 (Guess 18, Match 17, chọn mode ôn cho eight_box, sửa `MxStudyTopBar` ở chữ 2x): [plan](superpowers/plans/2026-09-26-study-p3-guess-match.md); phase P4 (Recall 19, Fill 20; deck `eight_box` học và ôn được trọn vẹn, bỏ tập mode đã dựng): [plan](superpowers/plans/2026-09-26-study-p4-recall-fill.md); phase P5 (bộ kịch bản IT tầng host của study, index 14 và 16–21 `aligned`, đóng các minor còn hoãn): [plan](superpowers/plans/2026-09-26-study-p5-it-records.md) | — |
@@ -133,7 +133,6 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 
 - Luồng học xong: FE-A6 (P1–P5), FE-A7 và FE-A8 (P6 của
   [roadmap luồng học](superpowers/plans/2026-09-26-study-chain-roadmap.md)).
-- **FE-A3:** plan 1 (màn 23, 25, 26) xong; plan 2 (màn 15) chưa bắt đầu.
 - **FE-A1, FE-A2:** chức năng xong; phần còn lại ở cột "Việc tiếp theo" của từng dòng.
 
 Nhánh `claude/study-large-files` không còn gì để merge: cả hai commit của nó (bỏ qua file
@@ -145,7 +144,7 @@ so nội dung.
 
 | Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
 |---|---|---|---|
-| FE-A2, FE-A3, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 15, 22 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
+| FE-A2, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 22 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
 | FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
 | FE-D3 | Không có emulator hoặc thiết bị | 8 kịch bản `DEVICE-E2E` | Môi trường chạy |
@@ -167,8 +166,8 @@ so nội dung.
 Mọi hạng mục FE của V8.0 đã có backend (BE-A1…BE-A10 xong). Thứ tự còn lại do thiết kế
 và phụ thuộc giữa các màn quyết định:
 
-1. FE-A3 (Cài đặt) và FE-A9 (Tiến độ), làm song song được: mỗi hạng mục viết file chi
-   tiết handoff của màn trước khi lập plan. Luồng học (FE-A6, FE-A7, FE-A8) đã xong.
+1. FE-A9 (Tiến độ): viết file chi tiết handoff của màn 22 trước khi lập plan. Luồng học
+   (FE-A6, FE-A7, FE-A8) và Cài đặt (FE-A3) đã xong.
 2. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
 3. Sau V8.0: FE-B1 (Trash, #78) và FE-B3 (import/export, #72) đã xong. FE-B2 (tag) và
    FE-B4 (starter) không còn chờ backend vì BE-B2 và BE-B4 đã xong. BE-B5a xong trong
@@ -248,3 +247,5 @@ giờ mỗi trạng thái, cộng thêm phần tương tác phức tạp.
 - **Cập nhật ngày 2026-09-27:** sau khi BE-B5a (#88) vào `master`, chủ dự án giữ D4 của FE-A3:
   câu chữ reset chưa nêu nhắc học; FE-B5 thêm nó và gọi `ReconcileReminderUseCase` khi hiện
   hàng Daily reminder (dòng FE-B5 và dòng 123 của sổ nợ UI-base).
+- **Cập nhật ngày 2026-09-27:** FE-A3 xong sau plan 2: màn 15 Study options mở từ action
+  sheet của deck và từ app bar màn 14; Coming soon không còn nêu Study options.
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
  docs/features/settings/README.md \
  docs/features/settings/ui.md \
  docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/shared/ui/screen-handoff/14-study-entry.md \
  docs/shared/ui/screen-handoff/15-study-options.md \
  docs/shared/ui/screen-state-checklist.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/wbs_FE.md \
  docs/_generated/traceability.md
git commit -m "$(cat <<'EOF'
docs(settings): FE-A3 done: detail file 15, register row 129, UC-SETTINGS-001, WBS

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
