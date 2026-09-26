# MemoX V8 Settings UI Implementation Plan (FE-A3, plan 1 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first part of FE-A3 in [`docs/wbs_FE.md`](../../wbs_FE.md): kit
screens 23 (Settings), 25 (Theme) and 26 (Language), over the BE-A1 settings use cases.
The Settings tab stops being a placeholder. The stored theme and language apply to the
whole app from the first frame. Plan 2 adds screen 15 (Study options).

**Architecture:**
- **One shared widget grows.** `MxStepper` gains hold-to-repeat and a typed entry (D6).
- **The feature's presentation.** `lib/features/settings/presentation/` gains:
  - one provider per use case, and `appSettingsProvider` (the `app_settings` stream);
  - one `@riverpod` controller for every submit of screens 23, 25 and 26: the settle,
    the in-flight guard, the failure with Retry, and the reset;
  - the three screens, made of `Mx*` widgets.
- **`app/`.** `main()` reads the row once before `runApp` (D5). `MemoxApp` then maps
  the stream to `themeMode` and `locale`, and the router is never rebuilt. The Settings
  branch shows screen 23, whose rows push 25 and 26 on the root navigator.
- **Shared fixes found by the visual audits.** `MxSegmentedTray` stacks its options when
  they do not fit. `MxSettingsRow` keeps its tile beside the label over a wide control.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, gen-l10n (en, vi). No new package.

**Spec:** [`docs/superpowers/specs/2026-09-26-settings-ui-design.md`](../specs/2026-09-26-settings-ui-design.md)
§3 (D1, D2, D4–D8), §4, §5.1–§5.4, §6–§8. Use case: UC-SETTINGS-001 (steps 1–6, A2–A4,
E1–E3). The kit is the visual authority: "MemoX — Mobile UI Kit v3", screens 23, 25
and 26 (14 states). The pre-plan critique is in
`.impeccable/critique/2026-09-26T17-00-00Z__settings-kit.md`.

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` at the commit that adds
this plan, with `master` up to #83 (shared UI refinements) merged. Generated code is not committed. In a fresh
working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- **Built in scratch.** Every task was built and committed in a scratch worktree of this
  branch, and each task's blocks below are that commit's files and diffs.
- **Gate.** The full gate (`dod_check.sh --force`) passed there, with a clean
  `flutter analyze`, a clean guard and clean architecture boundaries.
- **Goldens.** Every kit state of the three screens has a light and a dark golden
  (spec §7). They ran separately in this Linux container, and were compared with the
  kit captures in `docs/shared/ui/screen-handoff/img/{23-settings,25-theme,26-language}/`.
- **Replay.** The blocks were replayed mechanically onto a clean checkout of this
  branch, and the result matched the scratch files byte for byte.
- **Mutations.** Rules were then broken on purpose, and each break failed a test:
  - the in-flight guard removed;
  - the pre-read ignored by `MemoxApp`;
  - the queued limit write dropped, once after its own write and once after the order's;
  - a limit write built on the row the stream last sent rather than the order just
    written.

## Clarifications (rulings; amend the spec where they differ)

- **C1 (settle, D1).** The card limit is written 600 ms (`cardLimitSettle`) after its
  last step.
  - A hold's repeats are steps, so a hold is written 600 ms after its release, not at
    the release (spec §5.2). This needs no pointer events in the controller.
  - A typed value in range is written at once. A segment tap is written at once.
- **C2 (a write during a write).** A limit that changes while a study-defaults write
  runs is queued, and written once that write ends. This covers the limit's own write
  and the new-card order's.
  - A limit write builds on the study defaults last written (`_written`) until the
    stream sends them back. Without that, it would restore the order the order write
    just replaced.
  - A second submit of a kind already in flight is ignored (A4). A new-card order tap
    while the limit writes is ignored too: the tray keeps the stored order, so nothing
    reads as saved.
- **C3 (E1).** "Enter a number from 1 to 200" is an `MxFieldMessage` under the stepper,
  and the row's sub-line stays. The kit replaces the sub-line; UC E1 says "under the
  field".
- **C4 (toasts).** Each screen says its own:
  - screen 23: the card limit, the new-card order and the reset ("Saved", the failures
    with Retry, "App options reset to defaults");
  - screen 25: a failed theme write with Retry. A theme that applies needs no toast;
    the kit draws none.
  - screen 26: "Switched to …" in the new language, looked up with
    `lookupAppLocalizations`, and a failed write with Retry.
- **C5 (screen 25).**
  - The file is `theme_screen.dart` (spec §4 says `appearance_screen.dart`), after D7.
  - The kit's "THEME" overline is dropped: the title already says it.
  - The previews paint `buildLightTheme()` and `buildDarkTheme()` colours with no new
    token, and System is split in half.
- **C6 (screen 26).**
  - The rows are `MxOptionRow` radios, the app's single-choice list, not the kit's
    tinted row with a trailing check.
  - A phone language the app lacks reads "Your phone's language isn't available ·
    English". It does not name the language, because naming any locale would need a
    table the app does not have (D8 names it).
  - A sub-line that repeats the title is left out, so English has none.
- **C7 (loading and E3).** Loading is `MxSkeletonList`, not the kit's in-place
  skeleton. A failed read is `MxErrorState` "Couldn't open Settings" with the Library's
  local-first body and Retry (`ref.invalidate(appSettingsProvider)`), on all three
  screens.
- **C8 (screen 23's rows).**
  - The Theme row's sub-line is "Follows the system setting", "Light" or "Dark"
    (§5.2), not screen 25's "Always light" or "Always dark".
  - UC step 1's group names (Study defaults, Appearance, Language) are layout, so the
    kit's sections are used: Study defaults, App, Reset. The UC changes only at step 2
    (D1).
- **C9 (the gallery).** The debug gallery icon moves from the placeholder to screen 23's
  app bar. `PlaceholderScreen` loses `onOpenGallery`; Study and Progress still use it.
- **C10 (D5).**
  - `main()` builds the `ProviderContainer` itself, with no retry, and passes it to
    `UncontrolledProviderScope`.
  - `readStartupSettings` listens to `appSettingsProvider.future` while it reads,
    because Riverpod 3 pauses a provider with no listener. It gives up after 2 s or on
    a `Failure`, and the app then follows the platform.
- **C11 (shared widgets).** The visual audit of screen 23 at 360 dp and text scale 2
  found three defects, fixed where they live:
  - the stepper's number was a 36-tall tap target, now 48 (Task 1);
  - the tray overflowed with "Created" · "Random" at 2x, and "Theo ngày tạo" ·
    "Ngẫu nhiên" barely fit at 1x, so it now stacks when its labels do not fit
    (Task 5);
  - the settings row centred its tile over a wide control, where kit 23 puts it beside
    the label (Task 5).
- **C12 (UI-base §9).** Rows 120–124 are the next free rows on `master` at #83, which
  took 115–119. If other work takes them before this lands, use the next free numbers,
  and change the references in `23-settings.md` and the checklist to match.
- **C13 (the reset dialog's footer).** It follows #83's rule for a footer pair (UI-base
  row 118):
  - `MxActionPair` inside `MxSheetActions.custom`, with `MxSheetActions`' 10:13 shares;
  - Cancel is disabled while the reset runs, which `MxSheetActions`' own pair cannot do
    (its Cancel stays live), as the Trash purge dialog does;
  - at text scale 2 the two buttons stack instead of wrapping "Reset options".

## Global Constraints

Every task's requirements implicitly include these.

- The kit's screens 23, 25 and 26 are the visual authority. Every difference is in
  C1–C12, in the detail files `23-settings.md`, `25-theme.md` and `26-language.md`, or
  in UI-base §9 rows 120–124.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens;
  - no raw colour, `TextStyle`, spacing, radius or anonymous `Duration` literal;
  - no `ref.read` inside `build`, including in a local function declared there;
  - no literal user string, TalkBack labels included;
  - booleans read as predicates;
  - no source file over 400 lines;
  - no "transaction" in a presentation comment.
- File suffixes and buckets follow the guard: `_provider`, `_controller`, `_state`,
  `_screen`, and `_widget` in `items/`, `sections/`, `overlays/` or `support/`.
- Every read and write goes through a use case (ADR-011 D4). `deck` and `study` never
  import `settings`.
- No message carries an id, a path or SQL (BR-SETTINGS-007, BR-CORE-005).
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- **Test rules:**
  - Controller tests are plain `test()`s over a `LibraryEnv`: a Drift stream awaited
    inside `testWidgets` never completes under its fake clock.
  - A provider read from a bare container is kept alive with `container.listen`.
- Goldens render in the Linux container only. On Windows, run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **Holding + all the way to 200, then still holding.** The value stops at 200, and
   one write follows the release. Tests: "a hold stops at the bound the caller sets"
   (Task 1) and "steps settle into one write of the last value (D1, D6)" (Task 2).
2. **Changing the limit right after tapping Random.** Both are written; neither
   undoes the other. Tests: "a limit changed while its group writes is written once
   that write ends, not dropped" and "a step while its own write runs is written after
   it" (Task 2).
3. **Switching to Dark with a deck open behind Settings.** The stack and the deck stay.
   Test: "a theme change keeps the open deck; System follows the platform" (Task 3).
4. **A store that fails on start.** The app opens on the platform theme and language,
   and Settings says it could not open. Tests: "a failed read starts the app on the
   platform, with no invented value (E3)" (Task 3) and "a failed read shows the error
   with Retry and no invented value (E3)" (Task 5).
5. **A 360 dp phone at text scale 2, in Vietnamese.** Nothing overflows, no button
   label wraps, and every target is 48 dp. Tests: "labels too wide for one line stack,
   one option per line, each a full-width target", "at large text the reset buttons
   stack instead of wrapping (UI-base row 118)" and the screen 23, 25 and 26 visual
   audits (Tasks 4, 5).

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/shared/widgets/mx_stepper.dart`, `lib/core/theme/foundations/app_durations.dart`, `lib/app/gallery/gallery_inputs_section.dart` | 1 | hold-to-repeat, typed entry, the number's node |
| `lib/features/settings/presentation/providers/*.dart` | 2 | the use cases; the `app_settings` stream |
| `lib/features/settings/presentation/{states/settings_state,controllers/settings_controller}.dart` | 2 | every submit of 23, 25, 26 |
| `lib/main.dart`, `lib/app/{app,startup_settings}.dart` | 3 | the pre-read; theme and locale from the stream |
| `lib/features/settings/presentation/screens/{theme,language}_screen.dart`, `…/widgets/items/theme_choice_card_widget.dart` | 4 | screens 25 and 26 |
| `lib/features/settings/presentation/screens/settings_screen.dart`, `…/widgets/{sections,overlays}/*` | 5 | screen 23 and its reset dialog |
| `lib/app/router/*`, `lib/app/placeholder_screen.dart` | 4, 5 | the routes; the gallery icon moves |
| `lib/shared/widgets/{mx_segmented_tray,mx_settings_row}.dart` | 5 | the tray stacks; the tile beside the label |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/core/theme/foundations/app_icons.dart` | 1, 4, 5 | the copy; five icons |
| `docs/**` | 6 | detail files 23, 25, 26, index, checklist, register, UC, WBS |

---

### Task 1: `MxStepper` hold-to-repeat and typed entry

**Files:**
- Modify: `lib/app/gallery/gallery_inputs_section.dart`
- Modify: `lib/core/theme/foundations/app_durations.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/shared/widgets/mx_stepper.dart`
- Test (create): `test/shared/widgets/mx_stepper_input_test.dart`

**Interfaces:**
- Consumes: the existing `MxStepper`, `MxSpinner`, `appButtonStyle`, `AppSize`,
  `AppDurations`.
- Produces:
  - `MxStepper({required int value, required String decrementLabel, required String
    incrementLabel, required VoidCallback? onDecrement, required VoidCallback?
    onIncrement, String? valueLabel, String? editHint, ValueChanged<String>?
    onValueSubmitted, int maxDigits = 3, bool isInvalid = false, bool isBusy = false,
    bool isEnabled = true})`. A null callback is the bound: a hold stops there. With
    `onValueSubmitted`, a tap on the number opens a digits-only field; Done or a lost
    focus submits its text.
  - The number is keyed `ValueKey('mx-stepper-value')`, one TalkBack node
    (`valueLabel`, the value, the tap hint `editHint`), and a 48-tall tap target around
    a 36-tall box.
  - `AppDurations.stepperRepeatDelay` (400 ms) and `stepperRepeatInterval` (80 ms);
    the ARB key `commonEdit` ("Edit" / "Sửa").

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_stepper_input_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import '../../support/widget_harness.dart';

const _valueKey = ValueKey('mx-stepper-value');
const _tick = Duration(milliseconds: 1);

/// A stepper bounded to 1…[max] that records what it receives.
class _Bounded extends StatefulWidget {
  const _Bounded({this.max = 200, this.onSubmitted});

  final int max;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_Bounded> createState() => _BoundedState();
}

class _BoundedState extends State<_Bounded> {
  var value = 20;

  @override
  Widget build(BuildContext context) => MxStepper(
    value: value,
    decrementLabel: 'Fewer cards',
    incrementLabel: 'More cards',
    valueLabel: 'Cards per session',
    editHint: 'Edit',
    onDecrement: value > 1 ? () => setState(() => value--) : null,
    onIncrement: value < widget.max ? () => setState(() => value++) : null,
    onValueSubmitted: widget.onSubmitted,
  );
}

int _value(WidgetTester tester) =>
    tester.state<_BoundedState>(find.byType(_Bounded)).value;

void main() {
  testWidgets('a tap steps once; a hold repeats after its delay, then at '
      'its interval, and stops on release', (tester) async {
    await pumpMx(tester, const _Bounded());
    await tester.tap(find.byTooltip('More cards'));
    expect(_value(tester), 21);

    final hold = await tester.startGesture(
      tester.getCenter(find.byTooltip('More cards')),
    );
    await tester.pump(AppDurations.stepperRepeatDelay - _tick);
    expect(_value(tester), 21);
    await tester.pump(_tick);
    expect(_value(tester), 22);
    await tester.pump(AppDurations.stepperRepeatInterval);
    await tester.pump(AppDurations.stepperRepeatInterval);
    expect(_value(tester), 24);

    await hold.up();
    await tester.pump(AppDurations.stepperRepeatDelay * 2);
    // Releasing a hold is not one more tap.
    expect(_value(tester), 24);
  });

  testWidgets('a hold stops at the bound the caller sets', (tester) async {
    await pumpMx(tester, const _Bounded(max: 22));
    final hold = await tester.startGesture(
      tester.getCenter(find.byTooltip('More cards')),
    );
    await tester.pump(AppDurations.stepperRepeatDelay);
    for (var i = 0; i < 5; i++) {
      await tester.pump(AppDurations.stepperRepeatInterval);
    }
    await hold.up();
    await tester.pump();

    expect(_value(tester), 22);
  });

  testWidgets('tapping the number types a value; Done submits it', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpMx(tester, _Bounded(onSubmitted: submitted.add));
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '150');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, ['150']);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('leaving the field submits what was typed; only digits go in', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpMx(tester, _Bounded(onSubmitted: submitted.add));
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '2a50');
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();

    expect(submitted, ['250']);
  });

  testWidgets('without onValueSubmitted the number cannot be typed', (
    tester,
  ) async {
    await pumpMx(tester, const _Bounded());
    await tester.tap(find.byKey(_valueKey), warnIfMissed: false);
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the number is one TalkBack node: its name, its value and Edit', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _Bounded(onSubmitted: (_) {}));

    expect(
      tester.getSemantics(find.byKey(_valueKey)),
      matchesSemantics(
        label: 'Cards per session',
        value: '20',
        isButton: true,
        hasTapAction: true,
        onTapHint: 'Edit',
      ),
    );
    handle.dispose();
  });

  testWidgets('the editable number is a full touch target in a row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // As in a settings row: no height to fill, so the number sizes itself.
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [_Bounded(onSubmitted: (_) {})],
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/shared/widgets/mx_stepper_input_test.dart
```

Expected: FAIL to compile: `MxStepper` has no named parameter `valueLabel`, and
`AppDurations` has no `stepperRepeatDelay`.

- [ ] **Step 3: Implement**

`lib/app/gallery/gallery_inputs_section.dart` (apply this diff):

```diff
diff --git a/lib/app/gallery/gallery_inputs_section.dart b/lib/app/gallery/gallery_inputs_section.dart
index dc6a031..46ef375 100644
--- a/lib/app/gallery/gallery_inputs_section.dart
+++ b/lib/app/gallery/gallery_inputs_section.dart
@@ -128,6 +128,14 @@ class _GalleryInputsSectionState extends State<GalleryInputsSection> {
         incrementLabel: context.l10n.galleryMoreCards,
         onDecrement: _cards > _minCards ? () => setState(() => _cards--) : null,
         onIncrement: _cards < _maxCards ? () => setState(() => _cards++) : null,
+        valueLabel: context.l10n.galleryCardsPerSession,
+        editHint: context.l10n.commonEdit,
+        onValueSubmitted: (text) => setState(
+          () => _cards = (int.tryParse(text) ?? _cards).clamp(
+            _minCards,
+            _maxCards,
+          ),
+        ),
       ),
     ],
   );
```

`lib/core/theme/foundations/app_durations.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_durations.dart b/lib/core/theme/foundations/app_durations.dart
index 23497b5..08acbd2 100644
--- a/lib/core/theme/foundations/app_durations.dart
+++ b/lib/core/theme/foundations/app_durations.dart
@@ -23,4 +23,10 @@ abstract final class AppDurations {
 
   /// How long a toast offering Undo stays (FE-B1 D3).
   static const Duration undoWindow = Duration(seconds: 8);
+
+  /// How long a stepper button is held before it starts repeating (FE-A3 D6).
+  static const Duration stepperRepeatDelay = Duration(milliseconds: 400);
+
+  /// The pace of a held stepper button, one step each (FE-A3 D6).
+  static const Duration stepperRepeatInterval = Duration(milliseconds: 80);
 }
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 50000bc..c28229e 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -48,6 +48,10 @@
   "@commonRetry": {
     "description": "Generic retry action after a failure."
   },
+  "commonEdit": "Edit",
+  "@commonEdit": {
+    "description": "Generic action to change a value; TalkBack names it on a typeable number."
+  },
   "commonLoading": "Loading",
   "@commonLoading": {
     "description": "What a screen reader hears while a list or a value loads."
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 8d0d265..06f3eac 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -12,6 +12,7 @@
   "commonUndo": "Hoàn tác",
   "commonOpenTrash": "Mở Thùng rác",
   "commonRetry": "Thử lại",
+  "commonEdit": "Sửa",
   "commonLoading": "Đang tải",
   "libraryCreateDeck": "Tạo bộ thẻ",
   "libraryEmptyTitle": "Bắt đầu thư viện của bạn",
```

`lib/shared/widgets/mx_stepper.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_stepper.dart b/lib/shared/widgets/mx_stepper.dart
index 05f8223..e39fe2d 100644
--- a/lib/shared/widgets/mx_stepper.dart
+++ b/lib/shared/widgets/mx_stepper.dart
@@ -1,4 +1,8 @@
+import 'dart:async';
+
 import 'package:flutter/material.dart';
+import 'package:flutter/services.dart';
+import 'package:memox/core/theme/foundations/app_durations.dart';
 import 'package:memox/core/theme/foundations/app_icon_size.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/core/theme/foundations/app_opacity.dart';
@@ -14,7 +18,11 @@ import 'package:memox/shared/widgets/mx_spinner.dart';
 /// the busy spinner and the disabled dim. The bounds, the clamping and the
 /// validation message are the caller's: at a bound, pass null for that
 /// button's callback and it stops without a separate look.
-class MxStepper extends StatelessWidget {
+///
+/// Holding − or + repeats the step (FE-A3 D6). With [onValueSubmitted], a
+/// tap on the number turns it into a digits-only field; Done or leaving the
+/// field hands the text back, and the caller parses and validates it.
+class MxStepper extends StatefulWidget {
   const MxStepper({
     super.key,
     required this.value,
@@ -22,6 +30,10 @@ class MxStepper extends StatelessWidget {
     required this.incrementLabel,
     required this.onDecrement,
     required this.onIncrement,
+    this.valueLabel,
+    this.editHint,
+    this.onValueSubmitted,
+    this.maxDigits = _defaultMaxDigits,
     this.isInvalid = false,
     this.isBusy = false,
     this.isEnabled = true,
@@ -32,6 +44,19 @@ class MxStepper extends StatelessWidget {
   final String incrementLabel;
   final VoidCallback? onDecrement;
   final VoidCallback? onIncrement;
+
+  /// The number's name for TalkBack ("Cards per session"), read with its
+  /// value.
+  final String? valueLabel;
+
+  /// The action TalkBack names for typing a value ("Edit").
+  final String? editHint;
+
+  /// Non-null makes the number typeable; receives the typed digits.
+  final ValueChanged<String>? onValueSubmitted;
+
+  /// How many digits the field takes.
+  final int maxDigits;
   final bool isInvalid;
 
   /// A spinner replaces the number while the write is in flight.
@@ -42,59 +67,159 @@ class MxStepper extends StatelessWidget {
   static const double _valueColumn = 48;
   static const double _buttonPadding = 0;
 
+  /// Cards per session tops out at 200.
+  static const int _defaultMaxDigits = 3;
+
+  @override
+  State<MxStepper> createState() => _MxStepperState();
+}
+
+class _MxStepperState extends State<MxStepper> {
+  final _field = TextEditingController();
+  final _focus = FocusNode();
+  var _isEditing = false;
+
+  bool get _canEdit =>
+      widget.onValueSubmitted != null && widget.isEnabled && !widget.isBusy;
+
+  @override
+  void initState() {
+    super.initState();
+    _focus.addListener(() {
+      if (!_focus.hasFocus) _submit();
+    });
+  }
+
+  @override
+  void dispose() {
+    _field.dispose();
+    _focus.dispose();
+    super.dispose();
+  }
+
+  void _edit() {
+    final text = widget.value.toString();
+    _field.value = TextEditingValue(
+      text: text,
+      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
+    );
+    setState(() => _isEditing = true);
+    _focus.requestFocus();
+  }
+
+  void _submit() {
+    if (!_isEditing) return;
+    setState(() => _isEditing = false);
+    widget.onValueSubmitted?.call(_field.text);
+  }
+
+  /// A step while typing first hands over what was typed.
+  VoidCallback? _step(VoidCallback? onStep) {
+    if (onStep == null || !widget.isEnabled) return null;
+    return () {
+      _submit();
+      onStep();
+    };
+  }
+
   @override
   Widget build(BuildContext context) {
-    final colors = context.colors;
     final control = Row(
       mainAxisSize: MainAxisSize.min,
       spacing: AppSpacing.micro,
       children: [
         _StepButton(
           icon: AppIcons.remove,
-          label: decrementLabel,
-          onPressed: isEnabled ? onDecrement : null,
-        ),
-        ConstrainedBox(
-          constraints: const BoxConstraints(
-            minWidth: _valueColumn,
-            minHeight: AppSize.buttonSmall,
-          ),
-          child: DecoratedBox(
-            key: const ValueKey('mx-stepper-value'),
-            decoration: BoxDecoration(
-              borderRadius: BorderRadius.circular(AppRadius.md),
-              // Ruling I3. A null border when valid: turning invalid adds
-              // colour, never layout.
-              border: isInvalid
-                  ? Border.all(color: colors.error, width: AppStroke.hairline)
-                  : null,
-            ),
-            child: Center(
-              widthFactor: 1,
-              child: isBusy
-                  ? const MxSpinner()
-                  : Text(
-                      value.toString(),
-                      style: context.textStyles.stepperValue(
-                        isInvalid: isInvalid,
-                      ),
-                    ),
-            ),
-          ),
+          label: widget.decrementLabel,
+          onPressed: _step(widget.onDecrement),
         ),
+        _value(context),
         _StepButton(
           icon: AppIcons.add,
-          label: incrementLabel,
-          onPressed: isEnabled ? onIncrement : null,
+          label: widget.incrementLabel,
+          onPressed: _step(widget.onIncrement),
         ),
       ],
     );
-    if (isEnabled) return control;
+    if (widget.isEnabled) return control;
     return Opacity(opacity: AppOpacity.disabled, child: control);
   }
+
+  Widget _value(BuildContext context) {
+    final colors = context.colors;
+    final style = context.textStyles.stepperValue(isInvalid: widget.isInvalid);
+    final box = ConstrainedBox(
+      constraints: const BoxConstraints(
+        minWidth: MxStepper._valueColumn,
+        minHeight: AppSize.buttonSmall,
+      ),
+      child: DecoratedBox(
+        key: const ValueKey('mx-stepper-value'),
+        decoration: BoxDecoration(
+          borderRadius: BorderRadius.circular(AppRadius.md),
+          // Ruling I3. A null border when valid and not typing: turning
+          // invalid adds colour, never layout.
+          border: widget.isInvalid || _isEditing
+              ? Border.all(
+                  color: widget.isInvalid ? colors.error : colors.primary,
+                  width: AppStroke.hairline,
+                )
+              : null,
+        ),
+        child: Center(
+          widthFactor: 1,
+          heightFactor: 1,
+          child: switch ((widget.isBusy, _isEditing)) {
+            (true, _) => const MxSpinner(),
+            (_, true) => SizedBox(
+              width: MxStepper._valueColumn,
+              child: TextField(
+                controller: _field,
+                focusNode: _focus,
+                style: style,
+                textAlign: TextAlign.center,
+                keyboardType: TextInputType.number,
+                textInputAction: TextInputAction.done,
+                inputFormatters: [
+                  FilteringTextInputFormatter.digitsOnly,
+                  LengthLimitingTextInputFormatter(widget.maxDigits),
+                ],
+                decoration: const InputDecoration.collapsed(hintText: null),
+                onSubmitted: (_) => _submit(),
+              ),
+            ),
+            _ => Text(widget.value.toString(), style: style),
+          },
+        ),
+      ),
+    );
+    if (_isEditing) return box;
+    return Semantics(
+      container: true,
+      excludeSemantics: true,
+      button: _canEdit,
+      label: widget.valueLabel,
+      value: widget.value.toString(),
+      onTap: _canEdit ? _edit : null,
+      onTapHint: _canEdit ? widget.editHint : null,
+      child: GestureDetector(
+        behavior: HitTestBehavior.opaque,
+        onTap: _canEdit ? _edit : null,
+        // The box stays button-small; the tap target is a full one.
+        child: ConstrainedBox(
+          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
+          child: Center(widthFactor: 1, heightFactor: 1, child: box),
+        ),
+      ),
+    );
+  }
 }
 
-class _StepButton extends StatelessWidget {
+/// A − or + button. A hold repeats it, first after
+/// [AppDurations.stepperRepeatDelay] and then every
+/// [AppDurations.stepperRepeatInterval], until release or a null
+/// [onPressed] (the caller's bound).
+class _StepButton extends StatefulWidget {
   const _StepButton({
     required this.icon,
     required this.label,
@@ -105,32 +230,99 @@ class _StepButton extends StatelessWidget {
   final String label;
   final VoidCallback? onPressed;
 
+  @override
+  State<_StepButton> createState() => _StepButtonState();
+}
+
+class _StepButtonState extends State<_StepButton> {
+  Timer? _timer;
+
+  /// Set once a hold has stepped, so its release is not one more tap.
+  var _hasRepeated = false;
+
+  @override
+  void didUpdateWidget(_StepButton oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.onPressed == null) _stop();
+  }
+
+  @override
+  void dispose() {
+    _stop();
+    super.dispose();
+  }
+
+  void _start(PointerDownEvent _) {
+    _hasRepeated = false;
+    _stop();
+    if (widget.onPressed == null) return;
+    _timer = Timer(AppDurations.stepperRepeatDelay, () {
+      _repeat();
+      _timer = Timer.periodic(
+        AppDurations.stepperRepeatInterval,
+        (_) => _repeat(),
+      );
+    });
+  }
+
+  void _repeat() {
+    final onPressed = widget.onPressed;
+    if (onPressed == null) {
+      _stop();
+      return;
+    }
+    _hasRepeated = true;
+    onPressed();
+  }
+
+  void _stop([PointerEvent? _]) {
+    _timer?.cancel();
+    _timer = null;
+  }
+
+  void _tap() {
+    if (_hasRepeated) {
+      _hasRepeated = false;
+      return;
+    }
+    widget.onPressed?.call();
+  }
+
   @override
   Widget build(BuildContext context) {
     final colors = context.colors;
-    return Tooltip(
-      message: label,
-      // The icon carries the name into the button node; announcing the
-      // tooltip too would read it twice.
-      excludeFromSemantics: true,
-      child: TextButton(
-        onPressed: onPressed,
-        style:
-            appButtonStyle(
-              fill: colors.surfaceContainer,
-              ink: colors.onSurface,
-              edge: BorderSide.none,
-              focusColor: colors.primary,
-              height: AppSize.buttonSmall,
-              radius: AppRadius.md,
-              padding: MxStepper._buttonPadding,
-              label: context.textStyles.buttonLabel,
-            ).copyWith(
-              fixedSize: const WidgetStatePropertyAll(
-                Size.square(AppSize.buttonSmall),
+    return Listener(
+      onPointerDown: _start,
+      onPointerUp: _stop,
+      onPointerCancel: _stop,
+      child: Tooltip(
+        message: widget.label,
+        // The icon carries the name into the button node; announcing the
+        // tooltip too would read it twice.
+        excludeFromSemantics: true,
+        child: TextButton(
+          onPressed: widget.onPressed == null ? null : _tap,
+          style:
+              appButtonStyle(
+                fill: colors.surfaceContainer,
+                ink: colors.onSurface,
+                edge: BorderSide.none,
+                focusColor: colors.primary,
+                height: AppSize.buttonSmall,
+                radius: AppRadius.md,
+                padding: MxStepper._buttonPadding,
+                label: context.textStyles.buttonLabel,
+              ).copyWith(
+                fixedSize: const WidgetStatePropertyAll(
+                  Size.square(AppSize.buttonSmall),
+                ),
               ),
-            ),
-        child: Icon(icon, size: AppIconSize.compact, semanticLabel: label),
+          child: Icon(
+            widget.icon,
+            size: AppIconSize.compact,
+            semanticLabel: widget.label,
+          ),
+        ),
       ),
     );
   }
```

- [ ] **Step 4: Generate and run**

```bash
flutter gen-l10n
flutter test test/shared test/app/gallery_test.dart
flutter test --tags golden test/shared test/app
flutter analyze
```

Expected: PASS, 7 tests in `mx_stepper_input_test.dart`. No golden changes: the
stepper looks the same at rest.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/gallery/gallery_inputs_section.dart \
  lib/core/theme/foundations/app_durations.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/shared/widgets/mx_stepper.dart \
  test/shared/widgets/mx_stepper_input_test.dart
git commit -m "$(cat <<'EOF'
feat(ui): MxStepper repeats on hold and takes a typed value (FE-A3 D6)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: The settings providers, state and controller

**Files:**
- Create: `lib/features/settings/presentation/controllers/settings_controller.dart`
- Create: `lib/features/settings/presentation/providers/app_settings_provider.dart`
- Create: `lib/features/settings/presentation/providers/reset_app_settings_use_case_provider.dart`
- Create: `lib/features/settings/presentation/providers/save_study_defaults_use_case_provider.dart`
- Create: `lib/features/settings/presentation/providers/set_language_use_case_provider.dart`
- Create: `lib/features/settings/presentation/providers/set_theme_use_case_provider.dart`
- Create: `lib/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart`
- Create: `lib/features/settings/presentation/states/settings_state.dart`
- Test (create): `test/features/settings/presentation/settings_controller_test.dart`
- Test (modify): `test/support/library_harness.dart`
- Test (create): `test/support/settings_fakes.dart`

**Interfaces:**
- Consumes: BE-A1's `WatchAppSettingsUseCase`, `SaveStudyDefaultsUseCase`,
  `SetThemeUseCase`, `SetLanguageUseCase` and `ResetAppSettingsUseCase` over
  `settingsRepositoryProvider`; `StudyOptions` (`minCardLimit` 1, `maxCardLimit` 200,
  `defaultCardLimit` 20), `NewCardOrder`, `ThemeChoice`, `LanguageChoice`.
- Produces:
  - one `…UseCaseProvider` per use case, and `appSettingsProvider`
    (`@Riverpod(keepAlive: true) Stream<AppSettingsEntity>`);
  - `enum SettingsSubmit {cardLimit, newCardOrder, theme, language, reset}`;
    `sealed class SettingsNotice(kind)` with `SettingsSaved` and `SettingsSaveFailed`
    (not const: each notice is a new object, so the same notice twice still fires a
    listener);
  - `SettingsState({int? cardLimitDraft, bool isCardLimitInvalid, Set<SettingsSubmit>
    inFlight, SettingsNotice? notice})` with `isBusy(kind)` and `isStudyDefaultsBusy`;
  - `const Duration cardLimitSettle` (600 ms);
  - `settingsControllerProvider`: `stepCardLimit(int delta)`, `typeCardLimit(String)`,
    `chooseNewCardOrder(NewCardOrder)`, `chooseTheme(ThemeChoice)`,
    `chooseLanguage(LanguageChoice)`, `Future<bool> reset()` (true once it landed),
    `Future<void> retry(SettingsSubmit kind)`;
  - `test/support/settings_fakes.dart`'s `FlakySettingsRepository(inner)` with
    `isFailing`, `writes`, `hold` (a `Completer` every write waits for) and the static
    `failure` (an `UnknownDatabaseFailure` whose cause is a path);
  - `test/support/library_harness.dart`'s `libraryContainer(env, {overrides})`.

- [ ] **Step 1: Write the failing tests**

`test/features/settings/presentation/settings_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/test_database.dart';

typedef _Rig = ({ProviderContainer container, FlakySettingsRepository store});

/// A container over [env] whose settings store counts and can fail, with
/// the controller kept alive and the first row read.
Future<_Rig> _rig(LibraryEnv env) async {
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  final container = libraryContainer(
    env,
    overrides: [settingsRepositoryProvider.overrideWithValue(store)],
  );
  container.listen(settingsControllerProvider, (_, _) {});
  await container.read(appSettingsProvider.future);
  return (container: container, store: store);
}

SettingsController _controller(_Rig rig) =>
    rig.container.read(settingsControllerProvider.notifier);

SettingsState _state(_Rig rig) =>
    rig.container.read(settingsControllerProvider);

/// What the store holds now.
Future<AppSettingsEntity> _stored(_Rig rig) =>
    rig.container.read(watchAppSettingsUseCaseProvider)().first;

/// Past the settle, with the write and the stream's echo done.
Future<void> _settled() =>
    Future<void>.delayed(cardLimitSettle + const Duration(milliseconds: 150));

/// A plain test over a fresh [LibraryEnv]: drift's streams need the real
/// event loop, which a widget test's fake clock does not run.
void _settingsTest(String description, Future<void> Function(_Rig rig) body) {
  test(description, () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(await _rig(env));
    } finally {
      await env.db.close();
    }
  });
}

void main() {
  _settingsTest('steps settle into one write of the last value (D1, D6)', (
    rig,
  ) async {
    _controller(rig)
      ..stepCardLimit(1)
      ..stepCardLimit(1)
      ..stepCardLimit(1);
    expect(_state(rig).cardLimitDraft, 23);
    expect((await _stored(rig)).studyDefaults.cardLimit, 20);

    await _settled();
    expect((await _stored(rig)).studyDefaults.cardLimit, 23);
    expect(rig.store.writes, 1);
    expect(_state(rig).cardLimitDraft, isNull);
    expect(_state(rig).notice, isA<SettingsSaved>());
  });

  _settingsTest('a step stops at the bounds', (rig) async {
    _controller(rig).stepCardLimit(-50);
    expect(_state(rig).cardLimitDraft, StudyOptions.minCardLimit);
    _controller(rig).stepCardLimit(500);
    expect(_state(rig).cardLimitDraft, StudyOptions.maxCardLimit);
  });

  _settingsTest('a typed limit outside 1–200 is shown as invalid and not '
      'written; a valid one is written at once (E1)', (rig) async {
    _controller(rig).typeCardLimit('250');
    expect(_state(rig).isCardLimitInvalid, isTrue);
    expect(_state(rig).cardLimitDraft, 250);
    await _settled();
    expect(rig.store.writes, 0);

    _controller(rig).typeCardLimit('');
    expect(_state(rig).isCardLimitInvalid, isTrue);

    _controller(rig).typeCardLimit('150');
    await pumpEventQueue();
    expect((await _stored(rig)).studyDefaults.cardLimit, 150);
    expect(_state(rig).isCardLimitInvalid, isFalse);
  });

  _settingsTest('a second submit of a kind in flight is ignored (A4)', (
    rig,
  ) async {
    _controller(rig)
      ..chooseNewCardOrder(NewCardOrder.random)
      ..chooseNewCardOrder(NewCardOrder.random)
      ..chooseTheme(ThemeChoice.dark)
      ..chooseTheme(ThemeChoice.dark);
    await pumpEventQueue();

    expect(rig.store.writes, 2);
    final stored = await _stored(rig);
    expect(stored.studyDefaults.newCardOrder, NewCardOrder.random);
    expect(stored.theme, ThemeChoice.dark);
  });

  _settingsTest('a limit changed while its group writes is written once '
      'that write ends, not dropped', (rig) async {
    _controller(rig)
      ..chooseNewCardOrder(NewCardOrder.random)
      ..typeCardLimit('30');
    await _settled();

    final stored = await _stored(rig);
    expect(stored.studyDefaults.newCardOrder, NewCardOrder.random);
    expect(stored.studyDefaults.cardLimit, 30);
    expect(_state(rig).cardLimitDraft, isNull);
  });

  _settingsTest('a step while its own write runs is written after it', (
    rig,
  ) async {
    final gate = rig.store.hold = Completer<void>();
    _controller(rig).typeCardLimit('30');
    _controller(rig).stepCardLimit(1);
    // The step settles while the first write still runs.
    await _settled();
    rig.store.hold = null;
    gate.complete();
    await _settled();

    expect((await _stored(rig)).studyDefaults.cardLimit, 31);
    expect(rig.store.writes, 2);
  });

  _settingsTest('a failed write keeps the persisted value, says so, and '
      'Retry writes the same change (E2)', (rig) async {
    rig.store.isFailing = true;
    _controller(rig).stepCardLimit(5);
    await _settled();

    expect(_state(rig).notice, isA<SettingsSaveFailed>());
    expect(_state(rig).notice!.kind, SettingsSubmit.cardLimit);
    expect(_state(rig).cardLimitDraft, isNull);
    expect((await _stored(rig)).studyDefaults.cardLimit, 20);

    rig.store.isFailing = false;
    await _controller(rig).retry(SettingsSubmit.cardLimit);
    await pumpEventQueue();
    expect((await _stored(rig)).studyDefaults.cardLimit, 25);
    expect(_state(rig).notice, isA<SettingsSaved>());
  });

  _settingsTest('theme and language are each one write; choosing the '
      'persisted value writes nothing', (rig) async {
    _controller(rig)
      ..chooseTheme(ThemeChoice.system)
      ..chooseLanguage(LanguageChoice.system);
    await pumpEventQueue();
    expect(rig.store.writes, 0);

    _controller(rig).chooseLanguage(LanguageChoice.vi);
    await pumpEventQueue();
    expect((await _stored(rig)).language, LanguageChoice.vi);
    expect(_state(rig).notice!.kind, SettingsSubmit.language);
  });

  _settingsTest('reset returns every option to its default in one write '
      '(A3)', (rig) async {
    _controller(rig)
      ..chooseTheme(ThemeChoice.dark)
      ..chooseLanguage(LanguageChoice.vi)
      ..typeCardLimit('50');
    await pumpEventQueue();
    rig.store.writes = 0;

    expect(await _controller(rig).reset(), isTrue);
    final stored = await _stored(rig);
    expect(stored.theme, AppSettingsEntity.defaults.theme);
    expect(stored.language, AppSettingsEntity.defaults.language);
    expect(stored.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
    expect(rig.store.writes, 1);
    expect(_state(rig).notice!.kind, SettingsSubmit.reset);
  });

  _settingsTest('a failed reset changes nothing and says so', (rig) async {
    _controller(rig).chooseTheme(ThemeChoice.dark);
    await pumpEventQueue();
    rig.store.isFailing = true;

    expect(await _controller(rig).reset(), isFalse);
    expect((await _stored(rig)).theme, ThemeChoice.dark);
    expect(_state(rig).notice, isA<SettingsSaveFailed>());
  });
}
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
index 5b2dde1..12a89f0 100644
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -97,8 +97,13 @@ List<Override> _backend(LibraryEnv env) => [
 
 /// A provider container over [env]'s backend, for a test that drives
 /// providers without a widget tree. Disposed when the test ends.
-ProviderContainer libraryContainer(LibraryEnv env) {
-  final container = ProviderContainer(overrides: _backend(env));
+ProviderContainer libraryContainer(
+  LibraryEnv env, {
+  List<Override> overrides = const [],
+}) {
+  final container = ProviderContainer(
+    overrides: [..._backend(env), ...overrides],
+  );
   addTearDown(container.dispose);
   return container;
 }
```

`test/support/settings_fakes.dart`:

```dart
import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// The real settings store, counting its writes, with every write failing
/// while [isFailing] is on (UC-SETTINGS-001 E2).
final class FlakySettingsRepository implements SettingsRepository {
  FlakySettingsRepository(this._inner);

  final SettingsRepository _inner;
  var isFailing = false;
  var writes = 0;

  /// While set, every write waits for it: a write still running.
  Completer<void>? hold;

  /// A path, so a test can check no message shows it (BR-CORE-005).
  static const failure = UnknownDatabaseFailure(cause: '/data/memox.sqlite');

  Future<Outcome<void, SettingsRejection>> _write(
    Future<Outcome<void, SettingsRejection>> Function() run,
  ) async {
    writes++;
    if (hold case final gate?) await gate.future;
    if (isFailing) throw failure;
    return run();
  }

  @override
  Stream<AppSettingsEntity> watchAppSettings() => _inner.watchAppSettings();

  @override
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  }) => _write(() => _inner.saveStudyDefaults(options: options));

  @override
  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  }) => _write(() => _inner.setTheme(theme: theme));

  @override
  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  }) => _write(() => _inner.setLanguage(language: language));

  @override
  Future<Outcome<void, SettingsRejection>> resetToDefaults() =>
      _write(_inner.resetToDefaults);

  @override
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
      _inner.watchStudyOptions(deckId: deckId);

  @override
  Future<EffectiveStudyOptions?> studyOptionsOf({required String deckId}) =>
      _inner.studyOptionsOf(deckId: deckId);

  @override
  Future<Outcome<void, SettingsRejection>> saveRootStudyOptions({
    required String rootDeckId,
    required StudyOptions options,
  }) => _write(
    () => _inner.saveRootStudyOptions(rootDeckId: rootDeckId, options: options),
  );

  @override
  Future<Outcome<void, SettingsRejection>> clearRootStudyOptions({
    required String rootDeckId,
  }) => _write(() => _inner.clearRootStudyOptions(rootDeckId: rootDeckId));
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/presentation/settings_controller_test.dart
```

Expected: FAIL to compile: `settings_controller.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/settings/presentation/controllers/settings_controller.dart`:

```dart
import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/reset_app_settings_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/save_study_defaults_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/set_language_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/set_theme_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// How long the card limit stays still before it is saved (spec §5.2): a
/// hold or a run of taps is one write.
const Duration cardLimitSettle = Duration(milliseconds: 600);

/// Screen 23's submits (UC-SETTINGS-001): each settled change is one write
/// (D1, D6), a second submit of a kind in flight is ignored (A4), and a
/// failure keeps the persisted value with a Retry (E2). Widgets only draw
/// its state and the `app_settings` stream.
@riverpod
class SettingsController extends _$SettingsController {
  Timer? _settle;

  /// The limit changed again while its write ran: write it once that ends.
  var _isCardLimitQueued = false;

  /// What Retry resubmits, per kind.
  final _retries = <SettingsSubmit, Future<void> Function()>{};

  /// The study defaults last written, until the stream brings them back: a
  /// write right after another builds on it, not on the older row.
  StudyOptions? _written;

  @override
  SettingsState build() {
    ref.onDispose(() => _settle?.cancel());
    ref.listen(appSettingsProvider, (_, next) {
      _written = null;
      _dropSavedDraft(next.value);
    });
    return const SettingsState();
  }

  AppSettingsEntity? get _persisted => ref.read(appSettingsProvider).value;

  StudyOptions? get _studyDefaults => _written ?? _persisted?.studyDefaults;

  /// −/+ or a hold: the draft moves by [delta] within 1–200, and is saved
  /// [cardLimitSettle] after the last step.
  void stepCardLimit(int delta) {
    final persisted = _persisted;
    if (persisted == null) return;
    final from = state.isCardLimitInvalid
        ? persisted.studyDefaults.cardLimit
        : state.cardLimitDraft ?? persisted.studyDefaults.cardLimit;
    final next = (from + delta).clamp(
      StudyOptions.minCardLimit,
      StudyOptions.maxCardLimit,
    );
    state = state.withDraft(next);
    _settle?.cancel();
    _settle = Timer(cardLimitSettle, () => unawaited(_saveCardLimit()));
  }

  /// A typed limit: saved at once when it is within 1–200; otherwise shown
  /// as invalid and not written (E1).
  void typeCardLimit(String text) {
    _settle?.cancel();
    final value = int.tryParse(text);
    final isValid =
        value != null &&
        value >= StudyOptions.minCardLimit &&
        value <= StudyOptions.maxCardLimit;
    state = state.withDraft(value, isInvalid: !isValid);
    if (isValid) unawaited(_saveCardLimit());
  }

  void chooseNewCardOrder(NewCardOrder order) {
    final persisted = _studyDefaults;
    if (persisted == null || order == persisted.newCardOrder) return;
    if (state.isStudyDefaultsBusy) return;
    final options = StudyOptions(
      cardLimit: persisted.cardLimit,
      newCardOrder: order,
    );
    unawaited(
      _submit(
        SettingsSubmit.newCardOrder,
        () => ref.read(saveStudyDefaultsUseCaseProvider)(options: options),
        retry: () async => chooseNewCardOrder(order),
      ).then((hasSaved) => _afterStudyDefaults(options, hasSaved: hasSaved)),
    );
  }

  void chooseTheme(ThemeChoice theme) {
    if (theme == _persisted?.theme) return;
    unawaited(
      _submit(
        SettingsSubmit.theme,
        () => ref.read(setThemeUseCaseProvider)(theme: theme),
        retry: () async => chooseTheme(theme),
      ),
    );
  }

  void chooseLanguage(LanguageChoice language) {
    if (language == _persisted?.language) return;
    unawaited(
      _submit(
        SettingsSubmit.language,
        () => ref.read(setLanguageUseCaseProvider)(language: language),
        retry: () async => chooseLanguage(language),
      ),
    );
  }

  /// A3: every app option back to its default in one write; completes true
  /// once it landed, so the dialog can close.
  Future<bool> reset() async {
    _settle?.cancel();
    final hasReset = await _submit(
      SettingsSubmit.reset,
      () => ref.read(resetAppSettingsUseCaseProvider)(),
      retry: () async => unawaited(reset()),
    );
    if (hasReset && ref.mounted) {
      _written = null;
      state = state.withDraft(null);
    }
    return hasReset;
  }

  /// Retry after [SettingsSaveFailed] of [kind].
  Future<void> retry(SettingsSubmit kind) async {
    final again = _retries.remove(kind);
    if (again != null) await again();
  }

  Future<void> _saveCardLimit() async {
    final draft = state.cardLimitDraft;
    final persisted = _studyDefaults;
    if (draft == null || persisted == null || state.isCardLimitInvalid) {
      return;
    }
    if (state.isStudyDefaultsBusy) {
      _isCardLimitQueued = true;
      return;
    }
    final options = StudyOptions(
      cardLimit: draft,
      newCardOrder: persisted.newCardOrder,
    );
    final hasSaved = await _submit(
      SettingsSubmit.cardLimit,
      () => ref.read(saveStudyDefaultsUseCaseProvider)(options: options),
      retry: () async {
        state = state.withDraft(draft);
        await _saveCardLimit();
      },
    );
    if (!ref.mounted) return;
    if (!hasSaved) {
      // The control shows the persisted value again (E2).
      state = state.withDraft(null);
      return;
    }
    _dropSavedDraft(_persisted);
    await _afterStudyDefaults(options, hasSaved: true);
  }

  /// After a study defaults write: remember what it wrote, then write the
  /// limit that changed meanwhile.
  Future<void> _afterStudyDefaults(
    StudyOptions options, {
    required bool hasSaved,
  }) async {
    if (!ref.mounted) return;
    if (hasSaved) _written = options;
    await _saveQueuedCardLimit();
  }

  /// The limit changed while its group wrote: write it now.
  Future<void> _saveQueuedCardLimit() async {
    if (!_isCardLimitQueued || !ref.mounted) return;
    _isCardLimitQueued = false;
    await _saveCardLimit();
  }

  /// One submit of [kind]; ignored while one of the same group runs (A4).
  /// Completes true once it wrote.
  Future<bool> _submit(
    SettingsSubmit kind,
    Future<Outcome<void, SettingsRejection>> Function() write, {
    required Future<void> Function() retry,
  }) async {
    if (state.isBusy(kind)) return false;
    state = state.withBusy(kind, isBusy: true);
    var hasWritten = false;
    try {
      hasWritten = await write() is Ok;
    } on Failure {
      hasWritten = false;
    }
    if (!ref.mounted) return hasWritten;
    state = state.withBusy(kind, isBusy: false);
    if (hasWritten) {
      _retries.remove(kind);
      state = state.withNotice(SettingsSaved(kind));
    } else {
      _retries[kind] = retry;
      state = state.withNotice(SettingsSaveFailed(kind));
    }
    return hasWritten;
  }

  /// The draft goes once the store holds it and no write of it runs.
  void _dropSavedDraft(AppSettingsEntity? persisted) {
    final draft = state.cardLimitDraft;
    if (draft == null || persisted == null) return;
    if (state.isBusy(SettingsSubmit.cardLimit) || state.isCardLimitInvalid) {
      return;
    }
    if (persisted.studyDefaults.cardLimit == draft) {
      state = state.withDraft(null);
    }
  }
}
```

`lib/features/settings/presentation/providers/app_settings_provider.dart`:

```dart
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_provider.g.dart';

/// The one `app_settings` row, as every surface reads it (BR-SETTINGS-001).
/// Kept alive: the app follows its theme and language for its whole life.
@Riverpod(keepAlive: true)
Stream<AppSettingsEntity> appSettings(Ref ref) =>
    ref.watch(watchAppSettingsUseCaseProvider)();
```

`lib/features/settings/presentation/providers/reset_app_settings_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_app_settings_use_case_provider.g.dart';

@riverpod
ResetAppSettingsUseCase resetAppSettingsUseCase(Ref ref) =>
    ResetAppSettingsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/providers/save_study_defaults_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/save_study_defaults_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_study_defaults_use_case_provider.g.dart';

@riverpod
SaveStudyDefaultsUseCase saveStudyDefaultsUseCase(Ref ref) =>
    SaveStudyDefaultsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/providers/set_language_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_language_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_language_use_case_provider.g.dart';

@riverpod
SetLanguageUseCase setLanguageUseCase(Ref ref) =>
    SetLanguageUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/providers/set_theme_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_theme_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_theme_use_case_provider.g.dart';

@riverpod
SetThemeUseCase setThemeUseCase(Ref ref) =>
    SetThemeUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/watch_app_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_app_settings_use_case_provider.g.dart';

@riverpod
WatchAppSettingsUseCase watchAppSettingsUseCase(Ref ref) =>
    WatchAppSettingsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/settings/presentation/states/settings_state.dart`:

```dart
import 'package:flutter/foundation.dart';

/// The submits of screen 23; each is a write of its own (BR-SETTINGS-007).
enum SettingsSubmit { cardLimit, newCardOrder, theme, language, reset }

/// What screen 23 says once a submit ends. Each is a new object, so a
/// listener sees two of the same kind in a row (spec §5.2).
sealed class SettingsNotice {
  SettingsNotice(this.kind);

  final SettingsSubmit kind;
}

/// The write landed.
final class SettingsSaved extends SettingsNotice {
  SettingsSaved(super.kind);
}

/// The write failed; the persisted value stands and Retry resubmits (E2).
final class SettingsSaveFailed extends SettingsNotice {
  SettingsSaveFailed(super.kind);
}

/// Screen 23's own state. The persisted values live in the `app_settings`
/// stream; this holds only the card limit being changed, the submits in
/// flight and the last notice (BR-SETTINGS-001).
@immutable
final class SettingsState {
  const SettingsState({
    this.cardLimitDraft,
    this.isCardLimitInvalid = false,
    this.inFlight = const {},
    this.notice,
  });

  /// The card limit shown instead of the persisted one while it is changed;
  /// null once the store holds it.
  final int? cardLimitDraft;

  /// A typed limit outside 1–200: shown in the error ring, never written
  /// (E1).
  final bool isCardLimitInvalid;
  final Set<SettingsSubmit> inFlight;
  final SettingsNotice? notice;

  bool isBusy(SettingsSubmit kind) => inFlight.contains(kind);

  /// Card limit and new-card order write the same pair (BR-SETTINGS-002):
  /// one at a time, so neither overwrites the other.
  bool get isStudyDefaultsBusy =>
      isBusy(SettingsSubmit.cardLimit) || isBusy(SettingsSubmit.newCardOrder);

  SettingsState withDraft(int? draft, {bool isInvalid = false}) =>
      SettingsState(
        cardLimitDraft: draft,
        isCardLimitInvalid: isInvalid,
        inFlight: inFlight,
        notice: notice,
      );

  SettingsState withBusy(SettingsSubmit kind, {required bool isBusy}) =>
      SettingsState(
        cardLimitDraft: cardLimitDraft,
        isCardLimitInvalid: isCardLimitInvalid,
        inFlight: isBusy ? {...inFlight, kind} : ({...inFlight}..remove(kind)),
        notice: notice,
      );

  SettingsState withNotice(SettingsNotice notice) => SettingsState(
    cardLimitDraft: cardLimitDraft,
    isCardLimitInvalid: isCardLimitInvalid,
    inFlight: inFlight,
    notice: notice,
  );
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/settings
flutter analyze
```

Expected: PASS, 10 tests in `settings_controller_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/settings/presentation/controllers/settings_controller.dart \
  lib/features/settings/presentation/providers/app_settings_provider.dart \
  lib/features/settings/presentation/providers/reset_app_settings_use_case_provider.dart \
  lib/features/settings/presentation/providers/save_study_defaults_use_case_provider.dart \
  lib/features/settings/presentation/providers/set_language_use_case_provider.dart \
  lib/features/settings/presentation/providers/set_theme_use_case_provider.dart \
  lib/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart \
  lib/features/settings/presentation/states/settings_state.dart \
  test/features/settings/presentation/settings_controller_test.dart \
  test/support/library_harness.dart \
  test/support/settings_fakes.dart
git commit -m "$(cat <<'EOF'
feat(settings): the settings controller: settle, in-flight guard, Retry, reset (FE-A3 D1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: The stored theme and language, app-wide

**Files:**
- Modify: `lib/app/app.dart`
- Create: `lib/app/startup_settings.dart`
- Modify: `lib/main.dart`
- Test (create): `test/app/app_appearance_test.dart`
- Test (create): `test/app/startup_settings_test.dart`
- Test (modify): `test/support/library_harness.dart`

**Interfaces:**
- Consumes: Task 2's `appSettingsProvider`.
- Produces:
  - `const Duration startupSettingsLimit` (2 s) and
    `Future<AppSettingsEntity?> readStartupSettings(ProviderContainer)` in
    `lib/app/startup_settings.dart`;
  - `MemoxApp({bool hasGallery = kDebugMode, AppSettingsEntity? initialSettings})`;
  - `pumpMemoxApp(tester, env, {AppSettingsEntity? initialSettings, bool isSettled =
    true})` in the test harness.

- [ ] **Step 1: Write the failing tests**

`test/app/app_appearance_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

const _dark = AppSettingsEntity(
  studyDefaults: StudyOptions.defaults,
  theme: ThemeChoice.dark,
  language: LanguageChoice.system,
);

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(MxBottomNav))).brightness;

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

void main() {
  libraryTest('the first frame already paints the stored theme (FE-A3 D5)', (
    tester,
    env,
  ) async {
    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await pumpMemoxApp(tester, env, initialSettings: _dark, isSettled: false);

    expect(_brightness(tester), Brightness.dark);
  });

  libraryTest('a theme change keeps the open deck; System follows the '
      'platform (BR-SETTINGS-005, UC A2)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    expect(_barTitle('Korean'), findsOneWidget);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(_barTitle('Korean'), findsOneWidget);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.system);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
  });

  libraryTest('a language change applies at once and survives a restart; '
      'System falls back to English (BR-SETTINGS-006)', (tester, env) async {
    await pumpMemoxApp(tester, env);
    await SettingsRepositoryImpl(env.db)
        .setLanguage(language: LanguageChoice.vi);
    await tester.pumpAndSettle();
    expect(_tab(_vi.navLibrary), findsOneWidget);

    // A new app over the same database.
    await tester.pumpWidget(const SizedBox());
    await pumpMemoxApp(tester, env);
    expect(_tab(_vi.navLibrary), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await SettingsRepositoryImpl(env.db)
        .setLanguage(language: LanguageChoice.system);
    await tester.pumpAndSettle();
    expect(_tab(_en.navLibrary), findsOneWidget);
  });
}
```

`test/app/startup_settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';

import '../support/fake_day_clock.dart';
import '../support/library_harness.dart';
import '../support/settings_fakes.dart';
import '../support/test_database.dart';

void main() {
  test('the stored theme and language are read before the first frame '
      '(FE-A3 D5)', () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    addTearDown(env.db.close);
    final store = SettingsRepositoryImpl(env.db);
    await store.setTheme(theme: ThemeChoice.dark);
    await store.setLanguage(language: LanguageChoice.vi);

    final settings = await readStartupSettings(libraryContainer(env));

    expect(settings!.theme, ThemeChoice.dark);
    expect(settings.language, LanguageChoice.vi);
  });

  test('a failed read starts the app on the platform, with no invented '
      'value (E3)', () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    addTearDown(env.db.close);
    final container = libraryContainer(
      env,
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(await readStartupSettings(container), isNull);
  });
}
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
index 12a89f0..90c6714 100644
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -3,6 +3,7 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:flutter_riverpod/misc.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/app/app.dart';
+import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
 import 'package:memox/core/clock/di/day_clock_provider.dart';
 import 'package:memox/core/database/app_database.dart';
 import 'package:memox/core/database/di/database_provider.dart';
@@ -266,7 +267,12 @@ DeckAlgorithmScreen deckAlgorithmScreen({
 
 /// The whole app over [env] on a 1080×2400 (3x) phone, settled on the
 /// Library root.
-Future<void> pumpMemoxApp(WidgetTester tester, LibraryEnv env) async {
+Future<void> pumpMemoxApp(
+  WidgetTester tester,
+  LibraryEnv env, {
+  AppSettingsEntity? initialSettings,
+  bool isSettled = true,
+}) async {
   tester.view.physicalSize = const Size(1080, 2400);
   tester.view.devicePixelRatio = 3;
   addTearDown(tester.view.reset);
@@ -274,10 +280,10 @@ Future<void> pumpMemoxApp(WidgetTester tester, LibraryEnv env) async {
     ProviderScope(
       overrides: _backend(env),
       retry: _noRetry,
-      child: const MemoxApp(),
+      child: MemoxApp(initialSettings: initialSettings),
     ),
   );
-  await tester.pumpAndSettle();
+  if (isSettled) await tester.pumpAndSettle();
 }
 
 /// As `main.dart`: no hidden retry loop, so a failure shows as a failure.
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/app/startup_settings_test.dart test/app/app_appearance_test.dart
```

Expected: FAIL to compile: `startup_settings.dart` does not exist, and `MemoxApp` has
no `initialSettings`.

- [ ] **Step 3: Implement**

`lib/app/app.dart` (apply this diff):

```diff
diff --git a/lib/app/app.dart b/lib/app/app.dart
index 2b79b7e..d7599e2 100644
--- a/lib/app/app.dart
+++ b/lib/app/app.dart
@@ -9,19 +9,32 @@ import 'package:memox/app/font_license.dart';
 import 'package:memox/app/router/app_router.dart';
 import 'package:memox/core/error/failure.dart';
 import 'package:memox/core/theme/app_theme.dart';
+import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
+import 'package:memox/features/settings/domain/models/language_choice_model.dart';
+import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
+import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
 import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';
 import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 
 /// The composition root: themes, localization and the router, the start-up
 /// close of an earlier day's open study session (FE-A6 D9), and the Trash's
-/// auto-purge at start and on every resume (FE-B1 D5).
+/// auto-purge at start and on every resume (FE-B1 D5). The theme and the
+/// language follow the `app_settings` row (BR-SETTINGS-005, BR-SETTINGS-006).
 class MemoxApp extends ConsumerStatefulWidget {
-  const MemoxApp({super.key, this.hasGallery = kDebugMode});
+  const MemoxApp({
+    super.key,
+    this.hasGallery = kDebugMode,
+    this.initialSettings,
+  });
 
   /// Registers the debug-only component gallery.
   final bool hasGallery;
 
+  /// The row `main()` read before the first frame (FE-A3 D5); null follows
+  /// the platform until the stream answers.
+  final AppSettingsEntity? initialSettings;
+
   @override
   ConsumerState<MemoxApp> createState() => _MemoxAppState();
 }
@@ -78,16 +91,36 @@ class _MemoxAppState extends ConsumerState<MemoxApp> {
   }
 
   @override
-  Widget build(BuildContext context) => MaterialApp.router(
-    debugShowCheckedModeBanner: false,
-    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
-    theme: buildLightTheme(),
-    darkTheme: buildDarkTheme(),
-    // The system choice until the settings feature persists one
-    // (BR-SETTINGS-005, BR-SETTINGS-006).
-    themeMode: ThemeMode.system,
-    localizationsDelegates: AppLocalizations.localizationsDelegates,
-    supportedLocales: AppLocalizations.supportedLocales,
-    routerConfig: _router,
-  );
+  Widget build(BuildContext context) {
+    // Only the theme and the locale follow the row: the router stays, so a
+    // change keeps the stack and the scroll position (BR-SETTINGS-005).
+    final settings =
+        ref.watch(appSettingsProvider).value ?? widget.initialSettings;
+    return MaterialApp.router(
+      debugShowCheckedModeBanner: false,
+      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
+      theme: buildLightTheme(),
+      darkTheme: buildDarkTheme(),
+      themeMode: _themeMode(settings?.theme),
+      locale: _locale(settings?.language),
+      localizationsDelegates: AppLocalizations.localizationsDelegates,
+      supportedLocales: AppLocalizations.supportedLocales,
+      routerConfig: _router,
+    );
+  }
 }
+
+/// `system` follows the platform's brightness as it changes.
+ThemeMode _themeMode(ThemeChoice? theme) => switch (theme) {
+  ThemeChoice.light => ThemeMode.light,
+  ThemeChoice.dark => ThemeMode.dark,
+  ThemeChoice.system || null => ThemeMode.system,
+};
+
+/// `system` is no locale: Flutter resolves the platform's on the supported
+/// locales and falls back to English, the first (BR-SETTINGS-006).
+Locale? _locale(LanguageChoice? language) => switch (language) {
+  LanguageChoice.en => const Locale('en'),
+  LanguageChoice.vi => const Locale('vi'),
+  LanguageChoice.system || null => null,
+};
```

`lib/app/startup_settings.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';

/// How long the first frame waits for the stored theme and language.
const Duration startupSettingsLimit = Duration(seconds: 2);

/// FE-A3 D5: the `app_settings` row before the first frame, so the app
/// paints its stored theme and language from the start. Null when the read
/// fails or is slow: the app then follows the platform until the stream
/// answers, and the Settings screen shows the failure (E3).
Future<AppSettingsEntity?> readStartupSettings(
  ProviderContainer container,
) async {
  // A provider with no listener is paused; this one listens while it reads.
  final subscription = container.listen(appSettingsProvider.future, (_, _) {});
  try {
    return await subscription.read().timeout(startupSettingsLimit);
  } on Failure {
    return null;
  } on TimeoutException {
    return null;
  } finally {
    subscription.close();
  }
}
```

`lib/main.dart` (apply this diff):

```diff
diff --git a/lib/main.dart b/lib/main.dart
index d5e9152..afae204 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,15 +1,20 @@
 import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:memox/app/app.dart';
+import 'package:memox/app/startup_settings.dart';
 
-void main() {
+Future<void> main() async {
+  WidgetsFlutterBinding.ensureInitialized();
+  // DB errors are mapped to Failure explicitly (core/error/failure.dart);
+  // Riverpod's default retry-on-error would otherwise sit a failed provider
+  // in a hidden retry loop while showing AsyncLoading.
+  final container = ProviderContainer(retry: _noRetry);
+  // The stored theme and language before the first frame (FE-A3 D5).
+  final settings = await readStartupSettings(container);
   runApp(
-    const ProviderScope(
-      // DB errors are mapped to Failure explicitly (core/error/failure.dart);
-      // Riverpod's default retry-on-error would otherwise sit a failed
-      // provider in a hidden retry loop while showing AsyncLoading.
-      retry: _noRetry,
-      child: MemoxApp(),
+    UncontrolledProviderScope(
+      container: container,
+      child: MemoxApp(initialSettings: settings),
     ),
   );
 }
```

- [ ] **Step 4: Run**

```bash
flutter test test/app
flutter analyze
```

Expected: PASS, 2 tests in `startup_settings_test.dart` and 3 in
`app_appearance_test.dart`. The app goldens do not change.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/app.dart \
  lib/app/startup_settings.dart \
  lib/main.dart \
  test/app/app_appearance_test.dart \
  test/app/startup_settings_test.dart \
  test/support/library_harness.dart
git commit -m "$(cat <<'EOF'
feat(app): the stored theme and language from the first frame (FE-A3 D5, BR-SETTINGS-005/006)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: Screens 25 (Theme) and 26 (Language)

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/app/router/app_routes.dart`
- Create: `lib/features/settings/presentation/screens/language_screen.dart`
- Create: `lib/features/settings/presentation/screens/theme_screen.dart`
- Create: `lib/features/settings/presentation/widgets/items/theme_choice_card_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/settings/presentation/goldens/settings_language_english_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_language_english_light.png`
- Create: `test/features/settings/presentation/goldens/settings_language_switched_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_language_switched_light.png`
- Create: `test/features/settings/presentation/goldens/settings_language_system_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_language_system_light.png`
- Create: `test/features/settings/presentation/goldens/settings_theme_dark_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_theme_dark_light.png`
- Create: `test/features/settings/presentation/goldens/settings_theme_light_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_theme_light_light.png`
- Create: `test/features/settings/presentation/goldens/settings_theme_system_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_theme_system_light.png`
- Test (create): `test/features/settings/presentation/language_screen_test.dart`
- Test (create): `test/features/settings/presentation/settings_pages_golden_test.dart`
- Test (create): `test/features/settings/presentation/theme_screen_test.dart`
- Test (create): `test/visual_audit/screens/features/settings/screens/language_screen_visual_audit_test.dart`
- Test (create): `test/visual_audit/screens/features/settings/screens/theme_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 2's `appSettingsProvider`, `settingsControllerProvider`
  (`chooseTheme`, `chooseLanguage`, `retry`) and `FlakySettingsRepository`; Task 3's
  app-wide theme and locale.
- Produces:
  - `ThemeScreen()` and `LanguageScreen()`;
  - `ThemeChoiceCardWidget({required ThemeChoice theme, required bool isSelected,
    required VoidCallback onSelected})`;
  - `AppRoutes.settingsThemeChild` (`theme`), `settingsTheme` (`/settings/theme`),
    `settingsLanguageChild` (`language`) and `settingsLanguage`
    (`/settings/language`): children of the settings route on the root navigator;
  - the ARB keys of both pages, and `settingsLoadErrorTitle`, which Task 5 reuses.

- [ ] **Step 1: Write the failing tests**

`test/features/settings/presentation/language_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/screens/language_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

MxOptionRow _row(WidgetTester tester, String title) => tester.widget(
  find.ancestor(of: find.text(title), matching: find.byType(MxOptionRow)),
);

void main() {
  libraryTest('a tap switches the language and the toast reads in it '
      '(UC-SETTINGS-001 step 5)', (tester, env) async {
    await pumpLibraryScreen(tester, env, const LanguageScreen());
    expect(_row(tester, _en.settingsLanguageSystem).isSelected, isTrue);

    await tester.tap(find.text(_en.languageVietnamese));
    await tester.pumpAndSettle();

    expect(_row(tester, _en.languageVietnamese).isSelected, isTrue);
    expect(find.text(_vi.settingsLanguageSwitched), findsOneWidget);
  });

  libraryTest('Follow the system names the phone language, or says the app '
      'lacks it (FE-A3 D8)', (tester, env) async {
    tester.platformDispatcher
      ..localeTestValue = const Locale('vi')
      ..localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpLibraryScreen(tester, env, const LanguageScreen());
    expect(
      find.text(_en.settingsLanguagePhoneIs(_en.languageVietnamese)),
      findsOneWidget,
    );

    tester.platformDispatcher
      ..localeTestValue = const Locale('fr')
      ..localesTestValue = const [Locale('fr')];
    await pumpLibraryScreen(tester, env, const LanguageScreen());
    expect(find.text(_en.settingsLanguageUnavailable), findsOneWidget);
  });

  libraryTest('a language named the same in the UI language has no second '
      'line', (tester, env) async {
    await pumpLibraryScreen(tester, env, const LanguageScreen());

    expect(_row(tester, _en.languageEnglish).description, isNull);
    expect(
      _row(tester, _en.languageVietnamese).description,
      _en.settingsLanguageVietnameseName,
    );
  });

  libraryTest('a failed save keeps the stored language and offers Retry '
      '(E2)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      const LanguageScreen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text(_en.languageVietnamese));
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsLanguageSaveFailed), findsOneWidget);
    expect(_row(tester, _en.settingsLanguageSystem).isSelected, isTrue);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(_row(tester, _en.languageVietnamese).isSelected, isTrue);
  });
}
```

`test/features/settings/presentation/settings_pages_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/screens/language_screen.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('settings theme, system chosen, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const ThemeScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_theme_system_$theme.png',
        );
      });
    });

    libraryTest('settings theme, dark chosen, $theme', (tester, env) async {
      await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const ThemeScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_theme_dark_$theme.png',
        );
      });
    });

    libraryTest('settings theme, light chosen, $theme', (tester, env) async {
      await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.light);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const ThemeScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_theme_light_$theme.png',
        );
      });
    });

    libraryTest('settings language, English chosen, $theme', (
      tester,
      env,
    ) async {
      await SettingsRepositoryImpl(env.db)
          .setLanguage(language: LanguageChoice.en);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const LanguageScreen(),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_language_english_$theme.png',
        );
      });
    });

    libraryTest('settings language, phone in Vietnamese, $theme', (
      tester,
      env,
    ) async {
      tester.platformDispatcher.localeTestValue = const Locale('vi');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const LanguageScreen(),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_language_system_$theme.png',
        );
      });
    });

    libraryTest('settings language, switched, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const LanguageScreen(),
          brightness,
        );
        await tester.tap(find.text(_en.languageVietnamese));
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_language_switched_$theme.png',
        );
      });
    });
  }
}
```

`test/features/settings/presentation/theme_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

String _card(String name, String hint) => _en.settingsThemeCard(name, hint);

final _system = _card(_en.settingsThemeSystem, _en.settingsThemeSystemHint);
final _dark = _card(_en.settingsThemeDark, _en.settingsThemeDarkHint);

bool _isSelected(WidgetTester tester, String label) => tester
    .getSemantics(find.bySemanticsLabel(label))
    .flagsCollection
    .isSelected
    .toBoolOrNull()!;

void main() {
  libraryTest('the stored theme is selected; a tap saves another and selects '
      'it (UC-SETTINGS-001 step 4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, const ThemeScreen());
    expect(_isSelected(tester, _system), isTrue);

    await tester.tap(find.text(_en.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, _dark), isTrue);
    expect(_isSelected(tester, _system), isFalse);
    handle.dispose();
  });

  libraryTest('a failed save keeps the stored theme and offers Retry, which '
      'saves it (E2)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      const ThemeScreen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text(_en.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsThemeSaveFailed), findsOneWidget);
    expect(_isSelected(tester, _system), isTrue);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(_isSelected(tester, _dark), isTrue);
    handle.dispose();
  });

  libraryTest('a failed read shows the error with Retry and no invented '
      'choice (E3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const ThemeScreen(),
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.settingsLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.settingsThemeDark), findsNothing);
    expect(find.textContaining('memox.sqlite'), findsNothing);
  });
}
```

`test/visual_audit/screens/features/settings/screens/language_screen_visual_audit_test.dart`:

```dart
import 'package:memox/features/settings/presentation/screens/language_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 26', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: LanguageScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const LanguageScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

`test/visual_audit/screens/features/settings/screens/theme_screen_visual_audit_test.dart`:

```dart
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 25', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: ThemeScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const ThemeScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/presentation/theme_screen_test.dart test/features/settings/presentation/language_screen_test.dart
```

Expected: FAIL to compile: `theme_screen.dart` and `language_screen.dart` do not
exist.

- [ ] **Step 3: Implement**

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index e8ffae5..952f7fa 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -18,6 +18,8 @@ import 'package:memox/features/card/presentation/widgets/support/card_history_la
 import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
 import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
 import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
+import 'package:memox/features/settings/presentation/screens/language_screen.dart';
+import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
 import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
@@ -142,6 +144,18 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                       ? () => context.push(AppRoutes.gallery)
                       : null,
                 ),
+                routes: [
+                  GoRoute(
+                    path: AppRoutes.settingsThemeChild,
+                    parentNavigatorKey: rootNavigator,
+                    builder: (context, state) => const ThemeScreen(),
+                  ),
+                  GoRoute(
+                    path: AppRoutes.settingsLanguageChild,
+                    parentNavigatorKey: rootNavigator,
+                    builder: (context, state) => const LanguageScreen(),
+                  ),
+                ],
               ),
             ],
           ),
```

`lib/app/router/app_routes.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_routes.dart b/lib/app/router/app_routes.dart
index 6799906..c899732 100644
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -12,6 +12,16 @@ abstract final class AppRoutes {
   /// A study session, full screen on the root navigator (FE-A6 D2).
   static const String studySessionPath = '$study/session/:$sessionIdParam';
 
+  /// The theme (screen 25), relative to [settings]: a full-screen page on
+  /// the root navigator, as the kit draws it (FE-A3 D2).
+  static const String settingsThemeChild = 'theme';
+  static const String settingsTheme = '$settings/$settingsThemeChild';
+
+  /// The language (screen 26), relative to [settings], on the root
+  /// navigator.
+  static const String settingsLanguageChild = 'language';
+  static const String settingsLanguage = '$settings/$settingsLanguageChild';
+
   /// Debug builds only: the component gallery.
   static const String gallery = '/gallery';
 
```

`lib/features/settings/presentation/screens/language_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 26, the language (UC-SETTINGS-001 step 5): a tap saves the choice
/// and the whole app switches at once (BR-SETTINGS-006). "Follow the
/// system" says what it resolves to now (FE-A3 D8).
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  static const int _skeletonRows = 3;

  /// The choice last tapped, so its toast reads in that language.
  LanguageChoice? _chosen;

  /// The language `system` resolves to: the phone's when the app has it,
  /// English otherwise.
  Locale? _phoneLocale() {
    final code = View.of(context).platformDispatcher.locale.languageCode;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  void _choose(LanguageChoice language) {
    _chosen = language;
    ref.read(settingsControllerProvider.notifier).chooseLanguage(language);
  }

  void _say(SettingsNotice? notice) {
    if (notice == null || notice.kind != SettingsSubmit.language) return;
    final l10n = context.l10n;
    switch (notice) {
      case SettingsSaved():
        final target = switch (_chosen) {
          LanguageChoice.en => const Locale('en'),
          LanguageChoice.vi => const Locale('vi'),
          LanguageChoice.system || null => _phoneLocale() ?? const Locale('en'),
        };
        showMxSnackbar(
          context,
          message: lookupAppLocalizations(target).settingsLanguageSwitched,
        );
      case SettingsSaveFailed():
        showMxSnackbar(
          context,
          message: l10n.settingsLanguageSaveFailed,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(
            ref
                .read(settingsControllerProvider.notifier)
                .retry(SettingsSubmit.language),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(
      settingsControllerProvider.select((state) => state.notice),
      (_, notice) => _say(notice),
    );
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsLanguage,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            MxCard(
              isFullBleed: true,
              child: Column(children: _rows(l10n, value.language)),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              l10n.settingsLanguageNote,
              style: context.textStyles.noteText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
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
    );
  }

  List<Widget> _rows(AppLocalizations l10n, LanguageChoice selected) {
    final phone = _phoneLocale();
    final phoneLine = switch (phone?.languageCode) {
      'en' => l10n.settingsLanguagePhoneIs(l10n.languageEnglish),
      'vi' => l10n.settingsLanguagePhoneIs(l10n.languageVietnamese),
      _ => l10n.settingsLanguageUnavailable,
    };
    // A language named the same in the UI language needs no second line.
    String? nameIn(String endonym, String name) =>
        name == endonym ? null : name;
    return [
      MxOptionRow(
        title: l10n.settingsLanguageSystem,
        description: phoneLine,
        isSelected: selected == LanguageChoice.system,
        onSelected: () => _choose(LanguageChoice.system),
      ),
      MxOptionRow(
        title: l10n.languageEnglish,
        description: nameIn(
          l10n.languageEnglish,
          l10n.settingsLanguageEnglishName,
        ),
        isSelected: selected == LanguageChoice.en,
        onSelected: () => _choose(LanguageChoice.en),
      ),
      MxOptionRow(
        title: l10n.languageVietnamese,
        description: nameIn(
          l10n.languageVietnamese,
          l10n.settingsLanguageVietnameseName,
        ),
        isSelected: selected == LanguageChoice.vi,
        onSelected: () => _choose(LanguageChoice.vi),
        hasDivider: false,
      ),
    ];
  }
}
```

`lib/features/settings/presentation/screens/theme_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/items/theme_choice_card_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 25, the theme (UC-SETTINGS-001 step 4): a tap saves the choice
/// and the whole app follows at once, this page included
/// (BR-SETTINGS-005, FE-A3 D2, D7).
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  static const int _skeletonRows = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(settingsControllerProvider.select((state) => state.notice), (
      _,
      notice,
    ) {
      if (notice is! SettingsSaveFailed) return;
      if (notice.kind != SettingsSubmit.theme) return;
      showMxSnackbar(
        context,
        message: l10n.settingsThemeSaveFailed,
        actionLabel: l10n.commonRetry,
        onAction: () => unawaited(
          ref
              .read(settingsControllerProvider.notifier)
              .retry(SettingsSubmit.theme),
        ),
      );
    });
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsTheme,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                for (final theme in ThemeChoice.values)
                  Expanded(
                    child: ThemeChoiceCardWidget(
                      theme: theme,
                      isSelected: value.theme == theme,
                      onSelected: () => ref
                          .read(settingsControllerProvider.notifier)
                          .chooseTheme(theme),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              l10n.settingsAppliesAtOnce,
              style: context.textStyles.noteText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
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
    );
  }
}
```

`lib/features/settings/presentation/widgets/items/theme_choice_card_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One theme on screen 25 (kit 25): a preview in that theme's own colours,
/// its name and its line (FE-A3 D7). One TalkBack node, selected when
/// chosen.
class ThemeChoiceCardWidget extends StatelessWidget {
  const ThemeChoiceCardWidget({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onSelected,
  });

  final ThemeChoice theme;
  final bool isSelected;
  final VoidCallback onSelected;

  static const double _padding = AppSpacing.control;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final (name, hint) = switch (theme) {
      ThemeChoice.system => (
        l10n.settingsThemeSystem,
        l10n.settingsThemeSystemHint,
      ),
      ThemeChoice.light => (
        l10n.settingsThemeLight,
        l10n.settingsThemeLightHint,
      ),
      ThemeChoice.dark => (l10n.settingsThemeDark, l10n.settingsThemeDarkHint),
    };
    return MxCard(
      isFullBleed: true,
      isSelected: isSelected,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: true,
        selected: isSelected,
        label: l10n.settingsThemeCard(name, hint),
        child: MxRowInk(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                _Preview(theme: theme),
                Row(
                  spacing: AppSpacing.micro,
                  children: [
                    Expanded(child: Text(name, style: styles.rowTitle)),
                    if (isSelected)
                      Icon(
                        AppIcons.check,
                        size: AppIconSize.compact,
                        color: context.colors.primary,
                      ),
                  ],
                ),
                Text(hint, style: styles.rowSubtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature screen: the surface, a primary tile and two lines of the
/// theme it stands for. System shows light and dark side by side.
class _Preview extends StatelessWidget {
  const _Preview({required this.theme});

  final ThemeChoice theme;

  static const double _height = 62;
  static const double _tile = 20;
  static const double _lineHeight = 5;
  static const double _longLine = 28;
  static const double _shortLine = 18;

  @override
  Widget build(BuildContext context) {
    final light = buildLightTheme().colorScheme;
    final dark = buildDarkTheme().colorScheme;
    final main = theme == ThemeChoice.dark ? dark : light;
    final radius = BorderRadius.circular(AppRadius.sm);
    // The kit's hairline keeps a light preview apart from a light card.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: context.colors.outlineVariant,
          width: AppStroke.hairline,
        ),
      ),
      child: _clipped(main, dark, radius),
    );
  }

  Widget _clipped(ColorScheme main, ColorScheme dark, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: main.surface)),
            if (theme == ThemeChoice.system)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 0.5,
                  child: ColoredBox(color: dark.surface),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.control),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.micro,
                children: [
                  _block(main.primary, _tile, _tile),
                  const SizedBox(height: AppSpacing.micro),
                  _block(main.outlineVariant, _longLine, _lineHeight),
                  _block(main.outlineVariant, _shortLine, _lineHeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _block(Color color, double width, double height) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: SizedBox(width: width, height: height),
      );
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index c28229e..381b556 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -4732,5 +4732,106 @@
   "summaryDoneCaption": "Done returns you to the deck.",
   "@summaryDoneCaption": {
     "description": "Screen handoff 21 (FE-A6 P1c): the footer caption."
+  },
+  "settingsLoadErrorTitle": "Couldn't open Settings",
+  "@settingsLoadErrorTitle": {
+    "description": "Settings screens, the app_settings row failed to read (UC-SETTINGS-001 E3)."
+  },
+  "settingsTheme": "Theme",
+  "@settingsTheme": {
+    "description": "Screen 25 title and the Settings row that opens it (FE-A3 D2, D7)."
+  },
+  "settingsThemeSystem": "System",
+  "@settingsThemeSystem": {
+    "description": "Theme choice that follows the phone."
+  },
+  "settingsThemeLight": "Light",
+  "@settingsThemeLight": {
+    "description": "Theme choice: always light."
+  },
+  "settingsThemeDark": "Dark",
+  "@settingsThemeDark": {
+    "description": "Theme choice: always dark."
+  },
+  "settingsThemeSystemHint": "Match phone",
+  "@settingsThemeSystemHint": {
+    "description": "Line under the System theme card (FE-A3 D7)."
+  },
+  "settingsThemeLightHint": "Always light",
+  "@settingsThemeLightHint": {
+    "description": "Line under the Light theme card, and the Theme row when Light is chosen (FE-A3 D7)."
+  },
+  "settingsThemeDarkHint": "Always dark",
+  "@settingsThemeDarkHint": {
+    "description": "Line under the Dark theme card, and the Theme row when Dark is chosen (FE-A3 D7)."
+  },
+  "settingsThemeCard": "{name}, {hint}",
+  "@settingsThemeCard": {
+    "placeholders": {
+      "name": {
+        "type": "String"
+      },
+      "hint": {
+        "type": "String"
+      }
+    },
+    "description": "TalkBack label of a theme card: its name and its line."
+  },
+  "settingsAppliesAtOnce": "Applies at once — no restart, and you stay where you are.",
+  "@settingsAppliesAtOnce": {
+    "description": "Footnote of screen 25 (BR-SETTINGS-005)."
+  },
+  "settingsThemeSaveFailed": "Couldn't change the theme.",
+  "@settingsThemeSaveFailed": {
+    "description": "Toast when saving the theme failed (E2); offers Retry."
+  },
+  "settingsLanguage": "Language",
+  "@settingsLanguage": {
+    "description": "Screen 26 title and the Settings row that opens it."
+  },
+  "settingsLanguageSystem": "Follow the system",
+  "@settingsLanguageSystem": {
+    "description": "Language choice that follows the phone (BR-SETTINGS-006)."
+  },
+  "settingsLanguagePhoneIs": "Phone is set to {language}",
+  "@settingsLanguagePhoneIs": {
+    "placeholders": {
+      "language": {
+        "type": "String"
+      }
+    },
+    "description": "Line under Follow the system when the phone language is supported (FE-A3 D8)."
+  },
+  "settingsLanguageUnavailable": "Your phone's language isn't available · English",
+  "@settingsLanguageUnavailable": {
+    "description": "Line under Follow the system when the phone language is not supported: the app falls back to English (FE-A3 D8)."
+  },
+  "languageEnglish": "English",
+  "@languageEnglish": {
+    "description": "The English language in its own name (endonym); never translated."
+  },
+  "languageVietnamese": "Tiếng Việt",
+  "@languageVietnamese": {
+    "description": "The Vietnamese language in its own name (endonym); never translated."
+  },
+  "settingsLanguageEnglishName": "English",
+  "@settingsLanguageEnglishName": {
+    "description": "The English language named in the UI language (FE-A3 D8)."
+  },
+  "settingsLanguageVietnameseName": "Vietnamese",
+  "@settingsLanguageVietnameseName": {
+    "description": "The Vietnamese language named in the UI language (FE-A3 D8)."
+  },
+  "settingsLanguageNote": "Applies at once — no restart, and you stay where you are. Your cards stay in their own language.",
+  "@settingsLanguageNote": {
+    "description": "Footnote of screen 26 (BR-SETTINGS-006, BR-STUDY-035)."
+  },
+  "settingsLanguageSwitched": "Switched to English",
+  "@settingsLanguageSwitched": {
+    "description": "Toast after a language switch, read in the language switched to."
+  },
+  "settingsLanguageSaveFailed": "Couldn't change the language.",
+  "@settingsLanguageSaveFailed": {
+    "description": "Toast when saving the language failed (E2); offers Retry."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 06f3eac..0e38df0 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -889,5 +889,27 @@
   "summaryNoteHistory": "Không mất gì — các câu trả lời vẫn nằm trong lịch sử.",
   "summaryNoteTrash": "Khôi phục thẻ từ Thùng rác để đưa nó vào lần ôn tới.",
   "summaryDone": "Xong",
-  "summaryDoneCaption": "Xong sẽ đưa bạn về bộ thẻ."
+  "summaryDoneCaption": "Xong sẽ đưa bạn về bộ thẻ.",
+  "settingsLoadErrorTitle": "Không mở được Cài đặt",
+  "settingsTheme": "Giao diện",
+  "settingsThemeSystem": "Hệ thống",
+  "settingsThemeLight": "Sáng",
+  "settingsThemeDark": "Tối",
+  "settingsThemeSystemHint": "Theo điện thoại",
+  "settingsThemeLightHint": "Luôn sáng",
+  "settingsThemeDarkHint": "Luôn tối",
+  "settingsThemeCard": "{name}, {hint}",
+  "settingsAppliesAtOnce": "Áp dụng ngay — không cần khởi động lại, bạn vẫn ở nguyên chỗ.",
+  "settingsThemeSaveFailed": "Không đổi được giao diện.",
+  "settingsLanguage": "Ngôn ngữ",
+  "settingsLanguageSystem": "Theo hệ thống",
+  "settingsLanguagePhoneIs": "Điện thoại đang dùng {language}",
+  "settingsLanguageUnavailable": "Chưa có ngôn ngữ của điện thoại · dùng tiếng Anh",
+  "languageEnglish": "English",
+  "languageVietnamese": "Tiếng Việt",
+  "settingsLanguageEnglishName": "Tiếng Anh",
+  "settingsLanguageVietnameseName": "Tiếng Việt",
+  "settingsLanguageNote": "Áp dụng ngay — không cần khởi động lại, bạn vẫn ở nguyên chỗ. Thẻ của bạn giữ nguyên ngôn ngữ của chúng.",
+  "settingsLanguageSwitched": "Đã chuyển sang Tiếng Việt",
+  "settingsLanguageSaveFailed": "Không đổi được ngôn ngữ."
 }
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features/settings
flutter test test/features/settings test/visual_audit test/l10n
flutter analyze
```

Expected: PASS, 3 tests in `theme_screen_test.dart` and 4 in
`language_screen_test.dart`. Twelve new goldens, one per kit state and brightness:
- `settings_theme_system_*` with `docs/shared/ui/screen-handoff/img/25-theme/system-*`:
  "Theme", three cards with their previews, System ringed and checked, "Match phone" ·
  "Always light" · "Always dark", and the note (C5);
- `settings_theme_light_*` with `light-*` and `settings_theme_dark_*` with `dark-*`;
- `settings_language_english_*` with `26-language/english-*`: English chosen, with no
  sub-line;
- `settings_language_system_*` with `26-language/system-*`: "Phone is set to Tiếng
  Việt" under Follow the system, English with no sub-line, Tiếng Việt over
  "Vietnamese", and the note (C6);
- `settings_language_switched_*` with `vietnamese-*`: Tiếng Việt chosen and the toast
  "Đã chuyển sang Tiếng Việt". The harness pins English, so the page itself stays in
  English, as in the kit; `app_appearance_test.dart` covers the app switching.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/router/app_router.dart \
  lib/app/router/app_routes.dart \
  lib/features/settings/presentation/screens/language_screen.dart \
  lib/features/settings/presentation/screens/theme_screen.dart \
  lib/features/settings/presentation/widgets/items/theme_choice_card_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/settings/presentation/language_screen_test.dart \
  test/features/settings/presentation/settings_pages_golden_test.dart \
  test/features/settings/presentation/theme_screen_test.dart \
  test/visual_audit/screens/features/settings/screens/language_screen_visual_audit_test.dart \
  test/visual_audit/screens/features/settings/screens/theme_screen_visual_audit_test.dart \
  test/features/settings/presentation/goldens/settings_language_english_dark.png \
  test/features/settings/presentation/goldens/settings_language_english_light.png \
  test/features/settings/presentation/goldens/settings_language_switched_dark.png \
  test/features/settings/presentation/goldens/settings_language_switched_light.png \
  test/features/settings/presentation/goldens/settings_language_system_dark.png \
  test/features/settings/presentation/goldens/settings_language_system_light.png \
  test/features/settings/presentation/goldens/settings_theme_dark_dark.png \
  test/features/settings/presentation/goldens/settings_theme_dark_light.png \
  test/features/settings/presentation/goldens/settings_theme_light_dark.png \
  test/features/settings/presentation/goldens/settings_theme_light_light.png \
  test/features/settings/presentation/goldens/settings_theme_system_dark.png \
  test/features/settings/presentation/goldens/settings_theme_system_light.png
git commit -m "$(cat <<'EOF'
feat(settings): screens 25 Theme and 26 Language (FE-A3, UC-SETTINGS-001 steps 4-5)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: Screen 23 (Settings) in the Settings tab

**Files:**
- Modify: `lib/app/placeholder_screen.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Create: `lib/features/settings/presentation/screens/settings_screen.dart`
- Create: `lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart`
- Create: `lib/features/settings/presentation/widgets/sections/settings_app_section_widget.dart`
- Create: `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/shared/widgets/mx_segmented_tray.dart`
- Modify: `lib/shared/widgets/mx_settings_row.dart`
- Create: `test/features/settings/presentation/goldens/settings_invalid_limit_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_invalid_limit_light.png`
- Create: `test/features/settings/presentation/goldens/settings_loaded_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_loaded_light.png`
- Create: `test/features/settings/presentation/goldens/settings_loading_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_loading_light.png`
- Create: `test/features/settings/presentation/goldens/settings_reset_confirm_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_reset_confirm_light.png`
- Create: `test/features/settings/presentation/goldens/settings_reset_done_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_reset_done_light.png`
- Create: `test/features/settings/presentation/goldens/settings_save_failed_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_save_failed_light.png`
- Create: `test/features/settings/presentation/goldens/settings_saved_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_saved_light.png`
- Create: `test/features/settings/presentation/goldens/settings_saving_dark.png`
- Create: `test/features/settings/presentation/goldens/settings_saving_light.png`
- Modify: `test/shared/widgets/goldens/mx_settings_command_rows_dark.png`
- Modify: `test/shared/widgets/goldens/mx_settings_command_rows_light.png`
- Test (create): `test/app/settings_routes_test.dart`
- Test (create): `test/features/settings/presentation/settings_screen_golden_test.dart`
- Test (create): `test/features/settings/presentation/settings_screen_test.dart`
- Test (modify): `test/shared/widgets/mx_segmented_tray_test.dart`
- Test (modify): `test/shared/widgets/mx_settings_row_test.dart`
- Test (modify): `test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart`
- Test (create): `test/visual_audit/screens/features/settings/screens/settings_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 1's `MxStepper`; Task 2's controller, state and fakes; Task 4's
  routes and `settingsLoadErrorTitle`.
- Produces:
  - `SettingsScreen({required VoidCallback onOpenTheme, required VoidCallback
    onOpenLanguage, VoidCallback? onOpenGallery})`, built by the Settings branch;
  - `SettingsStudyDefaultsSectionWidget({required StudyOptions stored})`,
    `SettingsAppSectionWidget({required AppSettingsEntity stored, required
    VoidCallback onOpenTheme, required VoidCallback onOpenLanguage})`,
    `showSettingsResetDialog(BuildContext)`;
  - `PlaceholderScreen({required String title})`, with no gallery icon (C9);
  - `AppIcons.shuffle`, `language`, `resetOptions`, `safe` and `theme`;
  - `MxSegmentedTray` stacks its options when they do not fit; `MxSettingsRow` puts
    its tile beside the label over a wide control (C11);
  - the reset dialog's footer is an `MxActionPair` (C13).

- [ ] **Step 1: Write the failing tests**

`test/app/settings_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The routes around Settings (FE-A3).
void main() {
  libraryTest('the Settings tab is screen 23, not a placeholder', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navSettings));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(PlaceholderScreen), findsNothing);
  });

  for (final (row, title) in [
    (_en.settingsTheme, _en.settingsTheme),
    (_en.settingsLanguage, _en.settingsLanguage),
  ]) {
    libraryTest('$row opens its page above the shell; Back returns (D2)', (
      tester,
      env,
    ) async {
      await pumpMemoxApp(tester, env);
      await _tap(tester, _tab(_en.navSettings));

      await _tap(tester, find.text(row));
      expect(_barTitle(title), findsOneWidget);
      expect(find.byType(MxBottomNav), findsNothing);

      await _tap(tester, find.byTooltip(_en.commonBack));
      expect(_barTitle(_en.navSettings), findsOneWidget);
      expect(find.byType(MxBottomNav), findsOneWidget);
    });
  }
}
```

`test/features/settings/presentation/settings_screen_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

final _screen = SettingsScreen(onOpenTheme: () {}, onOpenLanguage: () {});

/// A toast or dialog in, its entrance done.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// One step up, settled into its save.
Future<void> _stepAndSettle(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.settingsMoreCards));
  await tester.pump(cardLimitSettle);
  await _settle(tester);
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('settings, loaded, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_loaded_$theme.png',
        );
      });
    });

    libraryTest('settings, loading, $theme', (tester, env) async {
      final never = StreamController<AppSettingsEntity>();
      addTearDown(never.close);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [appSettingsProvider.overrideWith((ref) => never.stream)],
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_loading_$theme.png',
        );
      });
    });

    libraryTest('settings, saving, $theme', (tester, env) async {
      final gate = Completer<void>();
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..hold = gate;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump(cardLimitSettle);
        await tester.pump();
        await expectBoundaryGolden(
          tester,
          'goldens/settings_saving_$theme.png',
        );
      });
      store.hold = null;
      gate.complete();
      await _settle(tester);
    });

    libraryTest('settings, saved, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await _stepAndSettle(tester);
        await expectBoundaryGolden(tester, 'goldens/settings_saved_$theme.png');
      });
    });

    libraryTest('settings, invalid limit, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.byKey(const ValueKey('mx-stepper-value')));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '250');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_invalid_limit_$theme.png',
        );
      });
    });

    libraryTest('settings, save failed, $theme', (tester, env) async {
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..isFailing = true;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await _stepAndSettle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_save_failed_$theme.png',
        );
      });
    });

    libraryTest('settings, reset confirm, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.text(_en.settingsResetRow));
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_reset_confirm_$theme.png',
        );
      });
    });

    libraryTest('settings, reset done, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.text(_en.settingsResetRow));
        await _settle(tester);
        await tester.tap(find.text(_en.settingsResetConfirm));
        await _settle(tester);
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_reset_done_$theme.png',
        );
      });
    });
  }
}
```

`test/features/settings/presentation/settings_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _valueKey = ValueKey('mx-stepper-value');

SettingsScreen _screen({
  VoidCallback? onOpenTheme,
  VoidCallback? onOpenLanguage,
}) => SettingsScreen(
  onOpenTheme: onOpenTheme ?? () {},
  onOpenLanguage: onOpenLanguage ?? () {},
);

Future<int> _storedLimit(LibraryEnv env) async => (await SettingsRepositoryImpl(
  env.db,
).watchAppSettings().first).studyDefaults.cardLimit;

void main() {
  libraryTest('the three sections show the stored values; the reminder row '
      'is hidden until FE-B5', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    // Section titles show in capitals; their semantics keep the words.
    expect(find.text(_en.settingsStudyDefaults.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsApp.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsResetRow), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(_valueKey), matching: find.text('20')),
      findsOneWidget,
    );
    expect(find.text(_en.settingsThemeFollowsSystem), findsOneWidget);
    expect(find.textContaining('eminder'), findsNothing);
  });

  libraryTest('steps settle into one save, then "Saved" (D1)', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip(_en.settingsMoreCards));
      await tester.pump();
    }
    expect(store.writes, 0);

    await tester.pump(cardLimitSettle);
    await tester.pumpAndSettle();

    expect(store.writes, 1);
    expect(find.text(_en.settingsSaved), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(_valueKey), matching: find.text('23')),
      findsOneWidget,
    );
  });

  libraryTest('while the limit writes, the stepper spins and the order '
      'stays usable (saving)', (tester, env) async {
    final gate = Completer<void>();
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..hold = gate;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump(cardLimitSettle);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(_valueKey),
        matching: find.byType(MxSpinner),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.settingsSaved), findsNothing);

    store.hold = null;
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(_en.settingsSaved), findsOneWidget);
  });

  libraryTest('before the first read the screen shows skeleton rows and no '
      'value (loading)', (tester, env) async {
    final never = StreamController<AppSettingsEntity>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [appSettingsProvider.overrideWith((ref) => never.stream)],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
  });

  libraryTest('a typed 250 is refused under the stepper and saves nothing '
      '(E1)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text(
        _en.settingsCardLimitInvalid(
          StudyOptions.minCardLimit,
          StudyOptions.maxCardLimit,
        ),
      ),
      findsOneWidget,
    );
    expect(store.writes, 0);
  });

  libraryTest('a failed save names the kept value and Retry saves it (E2)', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump(cardLimitSettle);
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsCardLimitSaveFailed(20)), findsOneWidget);
    expect(find.textContaining('memox.sqlite'), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => _storedLimit(env)), 21);
  });

  libraryTest('the Theme row names a fixed choice by its name (§5.2)', (
    tester,
    env,
  ) async {
    await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark),
    );
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.settingsThemeDark), findsOneWidget);
  });

  libraryTest('Reset asks first, then puts the defaults back (A3)', (
    tester,
    env,
  ) async {
    final repository = SettingsRepositoryImpl(env.db);
    await tester.runAsync(() async {
      await repository.setTheme(theme: ThemeChoice.dark);
      await repository.saveStudyDefaults(
        options: const StudyOptions(
          cardLimit: 50,
          newCardOrder: NewCardOrder.random,
        ),
      );
    });
    await pumpLibraryScreen(tester, env, _screen());

    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.settingsResetSafe), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(await tester.runAsync(() => _storedLimit(env)), 50);

    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.settingsResetDone), findsOneWidget);
    expect(
      await tester.runAsync(() => _storedLimit(env)),
      StudyOptions.defaultCardLimit,
    );
    expect(find.text(_en.settingsThemeFollowsSystem), findsOneWidget);
  });

  libraryTest('at large text the reset buttons stack instead of wrapping '
      '(UI-base row 118)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen(), textScale: 2);
    await tester.scrollUntilVisible(
      find.text(_en.settingsResetRow),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text(_en.settingsResetConfirm)).dy,
      greaterThan(tester.getBottomLeft(find.text(_en.commonCancel)).dy),
    );
    expect(tester.takeException(), isNull);
  });

  libraryTest('a failed read shows the error with Retry and no invented '
      'value (E3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.settingsLoadErrorTitle), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
    expect(find.textContaining('memox.sqlite'), findsNothing);
  });

  libraryTest('the Theme and Language rows open their pages', (
    tester,
    env,
  ) async {
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      _screen(
        onOpenTheme: () => opened.add('theme'),
        onOpenLanguage: () => opened.add('language'),
      ),
    );
    await tester.tap(find.text(_en.settingsTheme));
    await tester.tap(find.text(_en.settingsLanguage));

    expect(opened, ['theme', 'language']);
  });
}
```

`test/shared/widgets/mx_segmented_tray_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_segmented_tray_test.dart b/test/shared/widgets/mx_segmented_tray_test.dart
index 543ea8f..958d4bf 100644
--- a/test/shared/widgets/mx_segmented_tray_test.dart
+++ b/test/shared/widgets/mx_segmented_tray_test.dart
@@ -91,6 +91,38 @@ void main() {
     handle.dispose();
   });
 
+  testWidgets('labels too wide for one line stack, one option per line, '
+      'each a full-width target', (tester) async {
+    _Range? picked;
+    await pumpMx(
+      tester,
+      SizedBox(
+        width: 200,
+        child: MxSegmentedTray(
+          segments: const [
+            MxSegment(value: _Range.week, label: 'Theo ngày tạo'),
+            MxSegment(value: _Range.month, label: 'Ngẫu nhiên'),
+          ],
+          selected: _Range.week,
+          onSelected: (v) => picked = v,
+        ),
+      ),
+      textScale: 2,
+    );
+
+    expect(tester.takeException(), isNull);
+    final first = tester.getRect(find.text('Theo ngày tạo'));
+    final second = tester.getRect(find.text('Ngẫu nhiên'));
+    expect(second.top, greaterThan(first.bottom));
+    expect(
+      _thumb(tester, 'Theo ngày tạo').color,
+      scheme.surfaceContainerLowest,
+    );
+    await tester.tap(find.text('Ngẫu nhiên'));
+    expect(picked, _Range.month);
+    await expectAccessibleTargets(tester);
+  });
+
   test('two or three options only', () {
     expect(
       () => MxSegmentedTray(
```

`test/shared/widgets/mx_settings_row_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_settings_row_test.dart b/test/shared/widgets/mx_settings_row_test.dart
index 9986190..9e6af43 100644
--- a/test/shared/widgets/mx_settings_row_test.dart
+++ b/test/shared/widgets/mx_settings_row_test.dart
@@ -127,6 +127,27 @@ void main() {
     );
   });
 
+  testWidgets('with a wide control the tile sits at the top, beside the '
+      'label, as in kit 23', (tester) async {
+    await pumpMx(
+      tester,
+      _width(
+        const MxSettingsRow(
+          label: 'Cards per session',
+          subtitle: '1 to 200 · default 20',
+          icon: AppIcons.library,
+          wideControl: SizedBox(key: _controlKey, width: 120, height: 36),
+        ),
+      ),
+    );
+
+    expect(
+      tester.getTopLeft(find.byType(MxIconTile)).dy -
+          tester.getTopLeft(find.byType(MxSettingsRow)).dy,
+      12,
+    );
+  });
+
   testWidgets('dimmed at 0.38 while unavailable', (tester) async {
     var taps = 0;
     await pumpMx(
```

`test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart` (apply this diff):

```diff
diff --git a/test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart b/test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart
index 0618545..5650ec4 100644
--- a/test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart
+++ b/test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart
@@ -11,7 +11,7 @@ void main() {
       pump: (brightness, scale) => pumpLibraryScreen(
         tester,
         env,
-        PlaceholderScreen(title: 'Study', onOpenGallery: () {}),
+        const PlaceholderScreen(title: 'Study'),
         brightness: brightness,
         textScale: scale,
       ),
```

`test/visual_audit/screens/features/settings/screens/settings_screen_visual_audit_test.dart`:

```dart
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 23', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: SettingsScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        SettingsScreen(
          onOpenTheme: () {},
          onOpenLanguage: () {},
          onOpenGallery: () {},
        ),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/presentation/settings_screen_test.dart test/shared/widgets/mx_segmented_tray_test.dart test/shared/widgets/mx_settings_row_test.dart
```

Expected: FAIL. `settings_screen.dart` does not exist. The tray test fails with "A
RenderFlex overflowed by 148 pixels on the right". The settings row test fails with
"Expected: <12> Actual: <40.5>".

- [ ] **Step 3: Implement**

`lib/app/placeholder_screen.dart` (apply this diff):

```diff
diff --git a/lib/app/placeholder_screen.dart b/lib/app/placeholder_screen.dart
index 80f53f0..8c91a6e 100644
--- a/lib/app/placeholder_screen.dart
+++ b/lib/app/placeholder_screen.dart
@@ -4,34 +4,20 @@ import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
 import 'package:memox/shared/widgets/mx_app_shell.dart';
 import 'package:memox/shared/widgets/mx_empty_state.dart';
-import 'package:memox/shared/widgets/mx_icon_button.dart';
 import 'package:memox/shared/widgets/mx_screen_scroll.dart';
 
 /// The stand-in for a tab whose feature screen is not built yet. The
 /// feature's first real screen replaces it in its branch.
 class PlaceholderScreen extends StatelessWidget {
-  const PlaceholderScreen({super.key, required this.title, this.onOpenGallery});
+  const PlaceholderScreen({super.key, required this.title});
 
   final String title;
 
-  /// Debug builds only: opens the component gallery.
-  final VoidCallback? onOpenGallery;
-
   @override
   Widget build(BuildContext context) {
     final l10n = context.l10n;
     return MxAppShell(
-      appBar: MxAppBar(
-        title: title,
-        actions: [
-          if (onOpenGallery case final openGallery?)
-            MxIconButton(
-              icon: AppIcons.gallery,
-              semanticLabel: l10n.openGallery,
-              onPressed: openGallery,
-            ),
-        ],
-      ),
+      appBar: MxAppBar(title: title),
       body: MxScreenScroll(
         children: [
           // Ruling G4: a fact, not a failure.
```

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index 952f7fa..25c88e9 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -19,6 +19,7 @@ import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.d
 import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
 import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
 import 'package:memox/features/settings/presentation/screens/language_screen.dart';
+import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
 import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
@@ -138,8 +139,10 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
             routes: [
               GoRoute(
                 path: AppRoutes.settings,
-                builder: (context, state) => PlaceholderScreen(
-                  title: context.l10n.navSettings,
+                builder: (context, state) => SettingsScreen(
+                  onOpenTheme: () => context.push(AppRoutes.settingsTheme),
+                  onOpenLanguage: () =>
+                      context.push(AppRoutes.settingsLanguage),
                   onOpenGallery: hasGallery
                       ? () => context.push(AppRoutes.gallery)
                       : null,
```

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index 81637c4..cb4c876 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -56,6 +56,12 @@ abstract final class AppIcons {
   // Debug gallery.
   static const IconData gallery = Icons.widgets_outlined;
   static const IconData themeMode = Icons.contrast;
+  static const IconData theme = Icons.palette_outlined;
+  static const IconData shuffle = Icons.shuffle; // shuffle
+  static const IconData language = Icons.language; // globe
+  static const IconData resetOptions =
+      Icons.settings_backup_restore; // rotate-ccw
+  static const IconData safe = Icons.verified_user_outlined; // shield-check
   static const IconData textScale = Icons.format_size;
 
   // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
```

`lib/features/settings/presentation/screens/settings_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_app_section_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 23, the Settings tab (UC-SETTINGS-001): the app-wide study
/// defaults, the Theme and Language pages, and Reset app options. Every
/// value shown is the persisted one, or the card limit being changed
/// (BR-SETTINGS-001).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    required this.onOpenTheme,
    required this.onOpenLanguage,
    this.onOpenGallery,
  });

  final VoidCallback onOpenTheme;
  final VoidCallback onOpenLanguage;

  /// Debug builds only: opens the component gallery.
  final VoidCallback? onOpenGallery;

  static const int _skeletonRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      settingsControllerProvider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navSettings,
        actions: [
          if (onOpenGallery case final openGallery?)
            MxIconButton(
              icon: AppIcons.gallery,
              semanticLabel: l10n.openGallery,
              onPressed: openGallery,
            ),
        ],
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            SettingsStudyDefaultsSectionWidget(stored: value.studyDefaults),
            SettingsAppSectionWidget(
              stored: value,
              onOpenTheme: onOpenTheme,
              onOpenLanguage: onOpenLanguage,
            ),
            MxSection(
              title: l10n.settingsReset,
              note: l10n.settingsResetNote,
              children: [
                MxSettingsRow(
                  label: l10n.settingsResetRow,
                  subtitle: l10n.settingsResetRowHint,
                  icon: AppIcons.resetOptions,
                  onTap: () => unawaited(showSettingsResetDialog(context)),
                ),
              ],
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
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
    );
  }

  /// The toasts of the study defaults and the reset; the Theme and
  /// Language pages say their own.
  void _say(BuildContext context, WidgetRef ref, SettingsNotice? notice) {
    if (notice == null) return;
    final l10n = context.l10n;
    void retry() => unawaited(
      ref.read(settingsControllerProvider.notifier).retry(notice.kind),
    );
    final stored = ref.read(appSettingsProvider).value?.studyDefaults;
    final message = switch ((notice, notice.kind)) {
      (SettingsSaved(), SettingsSubmit.cardLimit) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.newCardOrder) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.reset) => l10n.settingsResetDone,
      (SettingsSaveFailed(), SettingsSubmit.cardLimit) when stored != null =>
        l10n.settingsCardLimitSaveFailed(stored.cardLimit),
      (SettingsSaveFailed(), SettingsSubmit.newCardOrder) =>
        l10n.settingsOrderSaveFailed,
      (SettingsSaveFailed(), SettingsSubmit.reset) => l10n.settingsResetFailed,
      _ => null,
    };
    if (message == null) return;
    final canRetry = notice is SettingsSaveFailed;
    showMxSnackbar(
      context,
      message: message,
      actionLabel: canRetry ? l10n.commonRetry : null,
      onAction: canRetry ? retry : null,
    );
  }
}
```

`lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before Reset app options (UC-SETTINGS-001 A3) and runs it. The
/// toasts are screen 23's.
Future<void> showSettingsResetDialog(BuildContext context) =>
    showMxDialog<void>(
      context,
      builder: (_) => const SettingsResetDialogWidget(),
    );

/// The reset confirmation of kit 23: what goes back to its default, and
/// that learning progress is not touched (BR-SETTINGS-008, BR-SRS-022).
/// While it runs, nothing can look like a cancel.
class SettingsResetDialogWidget extends ConsumerStatefulWidget {
  const SettingsResetDialogWidget({super.key});

  @override
  ConsumerState<SettingsResetDialogWidget> createState() =>
      _SettingsResetDialogWidgetState();
}

class _SettingsResetDialogWidgetState
    extends ConsumerState<SettingsResetDialogWidget> {
  // MxSheetActions' shares: the confirm keeps its line first.
  static const int _cancelShare = 10;
  static const int _confirmShare = 13;

  var _isResetting = false;

  Future<void> _reset() async {
    if (_isResetting) return;
    setState(() => _isResetting = true);
    await ref.read(settingsControllerProvider.notifier).reset();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_isResetting,
      child: MxDialog(
        width: MxDialogWidth.medium,
        title: l10n.settingsResetTitle,
        body: l10n.settingsResetBody,
        content: MxNote(icon: AppIcons.safe, text: l10n.settingsResetSafe),
        // The pair of MxSheetActions, with Cancel off while it runs.
        actions: MxSheetActions.custom(
          children: [
            Expanded(
              child: MxActionPair(
                leading: MxButton(
                  label: l10n.commonCancel,
                  tone: MxButtonTone.outline,
                  isBlock: true,
                  isSingleLine: true,
                  onPressed: _isResetting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                trailing: MxButton(
                  label: l10n.settingsResetConfirm,
                  isBlock: true,
                  isSingleLine: true,
                  isLoading: _isResetting,
                  onPressed: _reset,
                ),
                leadingFlex: _cancelShare,
                trailingFlex: _confirmShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/settings/presentation/widgets/sections/settings_app_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's App section: Theme and Language, each opening its page and
/// naming the current choice (FE-A3 D2). The Daily reminder row waits for
/// FE-B5 (spec A4: a control without its feature is hidden).
class SettingsAppSectionWidget extends StatelessWidget {
  const SettingsAppSectionWidget({
    super.key,
    required this.stored,
    required this.onOpenTheme,
    required this.onOpenLanguage,
  });

  final AppSettingsEntity stored;
  final VoidCallback onOpenTheme;
  final VoidCallback onOpenLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = Localizations.localeOf(context).languageCode == 'vi'
        ? l10n.languageVietnamese
        : l10n.languageEnglish;
    return MxSection(
      title: l10n.settingsApp,
      children: [
        MxSettingsRow(
          label: l10n.settingsTheme,
          subtitle: switch (stored.theme) {
            ThemeChoice.system => l10n.settingsThemeFollowsSystem,
            ThemeChoice.light => l10n.settingsThemeLight,
            ThemeChoice.dark => l10n.settingsThemeDark,
          },
          icon: AppIcons.theme,
          onTap: onOpenTheme,
        ),
        MxSettingsRow(
          label: l10n.settingsLanguage,
          subtitle: switch (stored.language) {
            LanguageChoice.system => l10n.settingsLanguageSystemHint(shown),
            LanguageChoice.en => l10n.languageEnglish,
            LanguageChoice.vi => l10n.languageVietnamese,
          },
          icon: AppIcons.language,
          onTap: onOpenLanguage,
        ),
      ],
    );
  }
}
```

`lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

/// Screen 23's Study defaults (UC-SETTINGS-001 step 2): the card limit by
/// −/+, a hold or typing, and the new-card order, each saved on change
/// (FE-A3 D1, D6).
class SettingsStudyDefaultsSectionWidget extends ConsumerWidget {
  const SettingsStudyDefaultsSectionWidget({super.key, required this.stored});

  /// The persisted defaults (BR-SETTINGS-001).
  final StudyOptions stored;

  /// Read in callbacks only, never while building.
  SettingsController _controller(WidgetRef ref) =>
      ref.read(settingsControllerProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    final limit = state.cardLimitDraft ?? stored.cardLimit;
    return MxSection(
      title: l10n.settingsStudyDefaults,
      note: l10n.settingsStudyDefaultsNote,
      children: [
        MxSettingsRow(
          label: l10n.settingsCardLimit,
          subtitle: l10n.settingsCardLimitRange(
            StudyOptions.maxCardLimit,
            StudyOptions.defaultCardLimit,
          ),
          icon: AppIcons.library,
          wideControl: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.micro,
            children: [
              MxStepper(
                value: limit,
                decrementLabel: l10n.settingsFewerCards,
                incrementLabel: l10n.settingsMoreCards,
                valueLabel: l10n.settingsCardLimit,
                editHint: l10n.commonEdit,
                onDecrement: limit > StudyOptions.minCardLimit
                    ? () => _controller(ref).stepCardLimit(-1)
                    : null,
                onIncrement: limit < StudyOptions.maxCardLimit
                    ? () => _controller(ref).stepCardLimit(1)
                    : null,
                onValueSubmitted: (text) =>
                    _controller(ref).typeCardLimit(text),
                isInvalid: state.isCardLimitInvalid,
                isBusy: state.isBusy(SettingsSubmit.cardLimit),
              ),
              if (state.isCardLimitInvalid)
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
          subtitle: l10n.settingsNewCardOrderHint,
          icon: AppIcons.shuffle,
          wideControl: MxSegmentedTray<NewCardOrder>(
            segments: [
              MxSegment(
                value: NewCardOrder.created,
                label: l10n.settingsOrderCreated,
              ),
              MxSegment(
                value: NewCardOrder.random,
                label: l10n.settingsOrderRandom,
              ),
            ],
            selected: stored.newCardOrder,
            onSelected: (order) => _controller(ref).chooseNewCardOrder(order),
          ),
        ),
      ],
    );
  }
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 381b556..7f40289 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -4833,5 +4833,139 @@
   "settingsLanguageSaveFailed": "Couldn't change the language.",
   "@settingsLanguageSaveFailed": {
     "description": "Toast when saving the language failed (E2); offers Retry."
+  },
+  "settingsStudyDefaults": "Study defaults",
+  "@settingsStudyDefaults": {
+    "description": "Screen 23 section title (UC-SETTINGS-001 step 1)."
+  },
+  "settingsStudyDefaultsNote": "Apply to sessions started from now on. A deck with its own study options keeps them.",
+  "@settingsStudyDefaultsNote": {
+    "description": "Note under Study defaults (BR-SETTINGS-003, BR-SETTINGS-004)."
+  },
+  "settingsCardLimit": "Cards per session",
+  "@settingsCardLimit": {
+    "description": "The app-wide card limit row, and its number for TalkBack (BR-SETTINGS-002)."
+  },
+  "settingsCardLimitRange": "1 to {max} · default {count}",
+  "@settingsCardLimitRange": {
+    "placeholders": {
+      "max": {
+        "type": "int"
+      },
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Line under Cards per session."
+  },
+  "settingsCardLimitInvalid": "Enter a number from {min} to {max}",
+  "@settingsCardLimitInvalid": {
+    "placeholders": {
+      "min": {
+        "type": "int"
+      },
+      "max": {
+        "type": "int"
+      }
+    },
+    "description": "Message under a typed card limit out of range (UC-SETTINGS-001 E1)."
+  },
+  "settingsFewerCards": "Fewer cards per session",
+  "@settingsFewerCards": {
+    "description": "Stepper minus button."
+  },
+  "settingsMoreCards": "More cards per session",
+  "@settingsMoreCards": {
+    "description": "Stepper plus button."
+  },
+  "settingsNewCardOrder": "New-card order",
+  "@settingsNewCardOrder": {
+    "description": "The app-wide new-card order row (BR-STUDY-057)."
+  },
+  "settingsNewCardOrderHint": "How new cards enter a learning session",
+  "@settingsNewCardOrderHint": {
+    "description": "Line under New-card order."
+  },
+  "settingsOrderCreated": "Created",
+  "@settingsOrderCreated": {
+    "description": "New-card order: the order cards were created."
+  },
+  "settingsOrderRandom": "Random",
+  "@settingsOrderRandom": {
+    "description": "New-card order: shuffled."
+  },
+  "settingsApp": "App",
+  "@settingsApp": {
+    "description": "Screen 23 section title for theme and language."
+  },
+  "settingsThemeFollowsSystem": "Follows the system setting",
+  "@settingsThemeFollowsSystem": {
+    "description": "Line under the Theme row when System is chosen."
+  },
+  "settingsLanguageSystemHint": "System · {language}",
+  "@settingsLanguageSystemHint": {
+    "placeholders": {
+      "language": {
+        "type": "String"
+      }
+    },
+    "description": "Line under the Language row when Follow the system is chosen; names what it resolves to."
+  },
+  "settingsReset": "Reset",
+  "@settingsReset": {
+    "description": "Screen 23 section title for Reset app options."
+  },
+  "settingsResetNote": "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched.",
+  "@settingsResetNote": {
+    "description": "Note under the Reset section (BR-SETTINGS-008)."
+  },
+  "settingsResetRow": "Reset app options",
+  "@settingsResetRow": {
+    "description": "The row that opens the reset confirmation (UC-SETTINGS-001 A3)."
+  },
+  "settingsResetRowHint": "Theme, language, study defaults",
+  "@settingsResetRowHint": {
+    "description": "Line under Reset app options."
+  },
+  "settingsResetTitle": "Reset app options?",
+  "@settingsResetTitle": {
+    "description": "Reset confirmation title."
+  },
+  "settingsResetBody": "Theme, language, cards per session and new-card order go back to their defaults.",
+  "@settingsResetBody": {
+    "description": "Reset confirmation body; names what the app shows (FE-A3 D4)."
+  },
+  "settingsResetSafe": "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”.",
+  "@settingsResetSafe": {
+    "description": "Reset confirmation note: it is not Reset learning progress (BR-SETTINGS-008, BR-SRS-022)."
+  },
+  "settingsResetConfirm": "Reset options",
+  "@settingsResetConfirm": {
+    "description": "Reset confirmation button."
+  },
+  "settingsResetDone": "App options reset to defaults",
+  "@settingsResetDone": {
+    "description": "Toast after a reset."
+  },
+  "settingsResetFailed": "Couldn't reset the app options. Nothing changed.",
+  "@settingsResetFailed": {
+    "description": "Toast when the reset failed (E2); offers Retry."
+  },
+  "settingsSaved": "Saved",
+  "@settingsSaved": {
+    "description": "Toast after a study default was saved (FE-A3 D1)."
+  },
+  "settingsCardLimitSaveFailed": "Couldn't save cards per session. Still {count}.",
+  "@settingsCardLimitSaveFailed": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Toast when saving the card limit failed (E2); names the value that stands, and offers Retry."
+  },
+  "settingsOrderSaveFailed": "Couldn't save the new-card order.",
+  "@settingsOrderSaveFailed": {
+    "description": "Toast when saving the new-card order failed (E2); offers Retry."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 0e38df0..6819678 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -911,5 +911,32 @@
   "settingsLanguageVietnameseName": "Tiếng Việt",
   "settingsLanguageNote": "Áp dụng ngay — không cần khởi động lại, bạn vẫn ở nguyên chỗ. Thẻ của bạn giữ nguyên ngôn ngữ của chúng.",
   "settingsLanguageSwitched": "Đã chuyển sang Tiếng Việt",
-  "settingsLanguageSaveFailed": "Không đổi được ngôn ngữ."
+  "settingsLanguageSaveFailed": "Không đổi được ngôn ngữ.",
+  "settingsStudyDefaults": "Mặc định khi học",
+  "settingsStudyDefaultsNote": "Áp dụng cho các phiên bắt đầu từ bây giờ. Bộ thẻ có tuỳ chọn học riêng vẫn giữ tuỳ chọn đó.",
+  "settingsCardLimit": "Số thẻ mỗi phiên",
+  "settingsCardLimitRange": "1 đến {max} · mặc định {count}",
+  "settingsCardLimitInvalid": "Nhập một số từ {min} đến {max}",
+  "settingsFewerCards": "Ít thẻ hơn mỗi phiên",
+  "settingsMoreCards": "Nhiều thẻ hơn mỗi phiên",
+  "settingsNewCardOrder": "Thứ tự thẻ mới",
+  "settingsNewCardOrderHint": "Cách thẻ mới vào phiên học",
+  "settingsOrderCreated": "Theo ngày tạo",
+  "settingsOrderRandom": "Ngẫu nhiên",
+  "settingsApp": "Ứng dụng",
+  "settingsThemeFollowsSystem": "Theo cài đặt của hệ thống",
+  "settingsLanguageSystemHint": "Hệ thống · {language}",
+  "settingsReset": "Đặt lại",
+  "settingsResetNote": "Chỉ các tuỳ chọn ứng dụng này trở về mặc định. Bộ thẻ, thẻ, tuỳ chọn học của từng bộ thẻ và tiến độ học không bị đụng tới.",
+  "settingsResetRow": "Đặt lại tuỳ chọn ứng dụng",
+  "settingsResetRowHint": "Giao diện, ngôn ngữ, mặc định khi học",
+  "settingsResetTitle": "Đặt lại tuỳ chọn ứng dụng?",
+  "settingsResetBody": "Giao diện, ngôn ngữ, số thẻ mỗi phiên và thứ tự thẻ mới trở về mặc định.",
+  "settingsResetSafe": "Bộ thẻ, thẻ, lịch ôn và lịch sử học của bạn giữ nguyên. Đây không phải là “Đặt lại tiến độ học”.",
+  "settingsResetConfirm": "Đặt lại tuỳ chọn",
+  "settingsResetDone": "Đã đặt lại tuỳ chọn ứng dụng về mặc định",
+  "settingsResetFailed": "Không đặt lại được tuỳ chọn ứng dụng. Chưa có gì thay đổi.",
+  "settingsSaved": "Đã lưu",
+  "settingsCardLimitSaveFailed": "Không lưu được số thẻ mỗi phiên. Vẫn là {count}.",
+  "settingsOrderSaveFailed": "Không lưu được thứ tự thẻ mới."
 }
```

`lib/shared/widgets/mx_segmented_tray.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_segmented_tray.dart b/lib/shared/widgets/mx_segmented_tray.dart
index 56804c8..3a75ccf 100644
--- a/lib/shared/widgets/mx_segmented_tray.dart
+++ b/lib/shared/widgets/mx_segmented_tray.dart
@@ -1,3 +1,5 @@
+import 'dart:math' as math;
+
 import 'package:flutter/material.dart';
 import 'package:memox/core/theme/foundations/app_radius.dart';
 import 'package:memox/core/theme/foundations/app_shadows.dart';
@@ -15,8 +17,9 @@ final class MxSegment<T> {
 }
 
 /// A two- or three-option exclusive switch: a recessed tray with a raised
-/// thumb behind the active option. Beyond three options, or when labels stop
-/// fitting, use MxOptionRow instead.
+/// thumb behind the active option. When the labels stop fitting on one line
+/// (long copy, large text), the options stack, one per line (FE-A3 ruling).
+/// Beyond three options, use MxOptionRow instead.
 class MxSegmentedTray<T> extends StatelessWidget {
   const MxSegmentedTray({
     super.key,
@@ -42,7 +45,61 @@ class MxSegmentedTray<T> extends StatelessWidget {
   static const double _segmentGap = 2;
 
   @override
-  Widget build(BuildContext context) {
+  Widget build(BuildContext context) => LayoutBuilder(
+    builder: (context, constraints) =>
+        _naturalWidth(context) > constraints.maxWidth
+        ? _stacked(context)
+        : _inline(context),
+  );
+
+  double get _padding => isWide ? AppSpacing.gutter : AppSpacing.grouped;
+
+  /// The one-line width: each option its label and padding, at least a
+  /// touch target, plus the gaps and the tray's inset.
+  double _naturalWidth(BuildContext context) {
+    final style = context.textStyles.trayLabel(isSelected: true);
+    final textScaler = MediaQuery.textScalerOf(context);
+    final direction = Directionality.of(context);
+    var width = AppSpacing.micro * 2 + _segmentGap * (segments.length - 1);
+    for (final segment in segments) {
+      final painter = TextPainter(
+        text: TextSpan(text: segment.label, style: style),
+        textDirection: direction,
+        textScaler: textScaler,
+        maxLines: 1,
+      )..layout();
+      width += math.max(AppSize.touchTarget, painter.width + _padding * 2);
+      painter.dispose();
+    }
+    return width;
+  }
+
+  Widget _stacked(BuildContext context) => DecoratedBox(
+    decoration: BoxDecoration(
+      color: context.colors.surfaceContainer,
+      borderRadius: BorderRadius.circular(AppRadius.md),
+    ),
+    child: Padding(
+      padding: const EdgeInsets.all(AppSpacing.micro),
+      child: Column(
+        mainAxisSize: MainAxisSize.min,
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        spacing: _segmentGap,
+        children: [
+          for (final segment in segments)
+            _Segment(
+              label: segment.label,
+              isSelected: segment.value == selected,
+              padding: _padding,
+              isStretched: true,
+              onTap: () => onSelected(segment.value),
+            ),
+        ],
+      ),
+    ),
+  );
+
+  Widget _inline(BuildContext context) {
     // Ruling I4: the tray paints 40 tall inside a 48 layout band.
     const trayHeight = _thumbHeight + AppSpacing.micro + AppSpacing.micro;
     return Stack(
@@ -72,7 +129,7 @@ class MxSegmentedTray<T> extends StatelessWidget {
                 _Segment(
                   label: segment.label,
                   isSelected: segment.value == selected,
-                  padding: isWide ? AppSpacing.gutter : AppSpacing.grouped,
+                  padding: _padding,
                   onTap: () => onSelected(segment.value),
                 ),
             ],
@@ -89,6 +146,7 @@ class _Segment extends StatelessWidget {
     required this.isSelected,
     required this.padding,
     required this.onTap,
+    this.isStretched = false,
   });
 
   final String label;
@@ -96,6 +154,9 @@ class _Segment extends StatelessWidget {
   final double padding;
   final VoidCallback onTap;
 
+  /// Stacked: the thumb spans the tray's width.
+  final bool isStretched;
+
   @override
   Widget build(BuildContext context) {
     final colors = context.colors;
@@ -115,6 +176,7 @@ class _Segment extends StatelessWidget {
             ),
             child: Center(
               heightFactor: 1,
+              widthFactor: isStretched ? null : 1,
               child: DecoratedBox(
                 decoration: BoxDecoration(
                   color: isSelected ? colors.surfaceContainerLowest : null,
@@ -123,6 +185,7 @@ class _Segment extends StatelessWidget {
                 ),
                 child: SizedBox(
                   height: MxSegmentedTray._thumbHeight,
+                  width: isStretched ? double.infinity : null,
                   child: Padding(
                     padding: EdgeInsets.symmetric(horizontal: padding),
                     child: Center(
```

`lib/shared/widgets/mx_settings_row.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_settings_row.dart b/lib/shared/widgets/mx_settings_row.dart
index a5f4a25..0ed3468 100644
--- a/lib/shared/widgets/mx_settings_row.dart
+++ b/lib/shared/widgets/mx_settings_row.dart
@@ -59,13 +59,25 @@ class MxSettingsRow extends StatelessWidget {
           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
           child: Row(
             spacing: AppSpacing.gutter,
+            // Kit 23: beside a wide control the tile stays with the label.
+            crossAxisAlignment: wideControl == null
+                ? CrossAxisAlignment.center
+                : CrossAxisAlignment.start,
             children: [
               if (icon case final glyph?)
-                SizedBox(
-                  width: _leadColumn,
-                  child: Center(
-                    heightFactor: 1,
-                    child: MxIconTile(icon: glyph, size: MxIconTileSize.medium),
+                Padding(
+                  padding: EdgeInsets.only(
+                    top: wideControl == null ? 0 : AppSpacing.grouped,
+                  ),
+                  child: SizedBox(
+                    width: _leadColumn,
+                    child: Center(
+                      heightFactor: 1,
+                      child: MxIconTile(
+                        icon: glyph,
+                        size: MxIconTileSize.medium,
+                      ),
+                    ),
                   ),
                 ),
               // As in MxListRow, only the text carries the 12/12 inset, so a
```

- [ ] **Step 4: Generate, render the goldens, run the whole suite and look**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features/settings test/shared
flutter test
flutter test --tags golden
flutter analyze
bash .claude/skills/flutter-architecture/scripts/check_architecture.sh
```

Expected: PASS, and the architecture check is clean. `settings_screen_test.dart` has 11
tests and `settings_routes_test.dart` has 3. 16 new goldens; compare each
with `docs/shared/ui/screen-handoff/img/23-settings/`:
- `settings_loading_*` with `loading-*`: skeleton rows, and no value (C7);
- `settings_saving_*` with `saving-*`: the spinner in place of the number;
- `settings_loaded_*` with `loaded-*`: Study defaults with the stepper and the tray
  under their labels, the tiles at the top; App with the Theme and Language rows (C8);
  Reset with its note;
- `settings_saved_*` with `saved-*`: 21 and "Saved";
- `settings_invalid_limit_*` with `invalidLimit-*`: 250 in the red ring, and the
  message under the stepper (C3);
- `settings_save_failed_*` with `saveFailed-*`: 20 again, and "Couldn't save cards per
  session. Still 20." with Retry;
- `settings_reset_confirm_*` with `resetConfirm-*`: the title, the body, the shield
  note, Cancel and "Reset options" side by side (C13);
- `settings_reset_done_*` with `resetDone-*`: the toast "App options reset to
  defaults".

Two goldens change: `mx_settings_command_rows_*`, where the stepper row's tile moves up
beside its label.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/placeholder_screen.dart \
  lib/app/router/app_router.dart \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/settings/presentation/screens/settings_screen.dart \
  lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart \
  lib/features/settings/presentation/widgets/sections/settings_app_section_widget.dart \
  lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/shared/widgets/mx_segmented_tray.dart \
  lib/shared/widgets/mx_settings_row.dart \
  test/app/settings_routes_test.dart \
  test/features/settings/presentation/settings_screen_golden_test.dart \
  test/features/settings/presentation/settings_screen_test.dart \
  test/shared/widgets/mx_segmented_tray_test.dart \
  test/shared/widgets/mx_settings_row_test.dart \
  test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart \
  test/visual_audit/screens/features/settings/screens/settings_screen_visual_audit_test.dart \
  test/features/settings/presentation/goldens/settings_invalid_limit_dark.png \
  test/features/settings/presentation/goldens/settings_invalid_limit_light.png \
  test/features/settings/presentation/goldens/settings_loaded_dark.png \
  test/features/settings/presentation/goldens/settings_loaded_light.png \
  test/features/settings/presentation/goldens/settings_loading_dark.png \
  test/features/settings/presentation/goldens/settings_loading_light.png \
  test/features/settings/presentation/goldens/settings_reset_confirm_dark.png \
  test/features/settings/presentation/goldens/settings_reset_confirm_light.png \
  test/features/settings/presentation/goldens/settings_reset_done_dark.png \
  test/features/settings/presentation/goldens/settings_reset_done_light.png \
  test/features/settings/presentation/goldens/settings_save_failed_dark.png \
  test/features/settings/presentation/goldens/settings_save_failed_light.png \
  test/features/settings/presentation/goldens/settings_saved_dark.png \
  test/features/settings/presentation/goldens/settings_saved_light.png \
  test/features/settings/presentation/goldens/settings_saving_dark.png \
  test/features/settings/presentation/goldens/settings_saving_light.png \
  test/shared/widgets/goldens/mx_settings_command_rows_dark.png \
  test/shared/widgets/goldens/mx_settings_command_rows_light.png
git commit -m "$(cat <<'EOF'
feat(settings): screen 23 replaces the Settings placeholder (FE-A3, UC-SETTINGS-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 6: Detail files 23, 25, 26, index, checklist, register, use case, WBS; the gate

**Files:**
- Modify: `docs/features/settings/README.md`
- Modify: `docs/features/settings/ui.md`
- Modify: `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Create: `docs/shared/ui/screen-handoff/23-settings.md`
- Create: `docs/shared/ui/screen-handoff/25-theme.md`
- Create: `docs/shared/ui/screen-handoff/26-language.md`
- Modify: `docs/shared/ui/screen-state-checklist.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/_generated/traceability.md (generated)`
- Modify: `docs/_generated/open-questions.md (generated)`

**Interfaces:** none (documents). The kit's captures of screens 23, 25 and 26 are already
in `docs/shared/ui/screen-handoff/img/`.

- [ ] **Step 1: Update the documents**

`docs/features/settings/README.md` (apply this diff):

```diff
diff --git a/docs/features/settings/README.md b/docs/features/settings/README.md
index fd60b9b..a15e5a4 100644
--- a/docs/features/settings/README.md
+++ b/docs/features/settings/README.md
@@ -1,6 +1,6 @@
 ---
 feature: settings
-code: [lib/features/settings/domain, lib/features/settings/data, lib/features/settings/di]
+code: [lib/features/settings/domain, lib/features/settings/data, lib/features/settings/di, lib/features/settings/presentation]
 depends_on: [deck, srs, study]
 ---
 ## Phạm vi
@@ -11,7 +11,9 @@ Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn
 
 | Màn hình | UC |
 |---|---|
-| Tab Settings | UC-SETTINGS-001 |
+| Tab Settings (màn 23) | UC-SETTINGS-001 |
+| Theme (màn 25) | UC-SETTINGS-001 |
+| Language (màn 26) | UC-SETTINGS-001 |
 
 Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặc deep link `/settings`"). Nhắc học hằng ngày (UC-REMINDER-001) nằm trong branch Settings nhưng thuộc feature `reminders`.
 
```

`docs/features/settings/ui.md` (apply this diff):

```diff
diff --git a/docs/features/settings/ui.md b/docs/features/settings/ui.md
index bb8ec78..a813ee0 100644
--- a/docs/features/settings/ui.md
+++ b/docs/features/settings/ui.md
@@ -2,11 +2,23 @@
 
 Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.
 
+## Màn hình và điều hướng
+
+| Màn | Route | Mở từ | Handoff |
+|---|---|---|---|
+| 23 · Settings | `/settings` (tab Settings) | Bottom bar | [23-settings.md](../../shared/ui/screen-handoff/23-settings.md) |
+| 25 · Theme | `/settings/theme`, trên root navigator, không có bottom bar | Hàng Theme của màn 23 | [25-theme.md](../../shared/ui/screen-handoff/25-theme.md) |
+| 26 · Language | `/settings/language`, trên root navigator, không có bottom bar | Hàng Language của màn 23 | [26-language.md](../../shared/ui/screen-handoff/26-language.md) |
+
+Theme và ngôn ngữ áp cho cả app: `main()` đọc dòng `app_settings` một lần trước frame
+đầu (chờ tối đa 2 giây), rồi `MemoxApp` theo stream. Nguồn:
+[spec FE-A3](../../superpowers/specs/2026-09-26-settings-ui-design.md) §5.4.
+
 ## Validation
 
 | Trường | Rule | Message hiển thị | Enforced by |
 |---|---|---|---|
-| app_settings.cardLimit | cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SETTINGS-002) | như tùy chọn của deck — không có message riêng | rule |
+| app_settings.cardLimit | cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SETTINGS-002) | "Enter a number from 1 to 200" dưới stepper, khi số gõ vào nằm ngoài khoảng; không ghi gì (UC E1) | rule + UI |
 | app_settings.themeMode | thuộc `system` \| `light` \| `dark` (BR-SETTINGS-005) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |
 | app_settings.language | thuộc `system` \| `en` \| `vi` (BR-SETTINGS-006) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |
 
```

`docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md` (apply this diff):

```diff
diff --git a/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md b/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md
index 14a6fae..f5915e9 100644
--- a/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md
+++ b/docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md
@@ -3,7 +3,7 @@ id: UC-SETTINGS-001
 title: Đặt tuỳ chọn ứng dụng
 status: ready
 rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008, BR-SRS-022, BR-STUDY-003, BR-STUDY-024, BR-STUDY-035, BR-STUDY-056, BR-STUDY-057]
-code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart, lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/usecases/save_root_study_options_use_case.dart, lib/features/settings/domain/usecases/use_app_defaults_use_case.dart]
+code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart, lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/usecases/save_root_study_options_use_case.dart, lib/features/settings/domain/usecases/use_app_defaults_use_case.dart, lib/features/settings/presentation/screens/settings_screen.dart, lib/features/settings/presentation/screens/theme_screen.dart, lib/features/settings/presentation/screens/language_screen.dart, lib/features/settings/presentation/controllers/settings_controller.dart, lib/app/startup_settings.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
@@ -18,9 +18,13 @@ code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, l
 1. Người dùng mở tab Settings. Hệ thống đọc dòng `app_settings` qua stream và
    hiển thị ba nhóm: `Study defaults`, `Appearance`, `Language` — mỗi control
    hiển thị **giá trị đang có hiệu lực**, không phải placeholder (BR-SETTINGS-001).
-2. Người dùng đổi trần thẻ mỗi phiên và/hoặc thứ tự thẻ mới, rồi bấm lưu nhóm
-   `Study defaults`. Hệ thống validate trần thẻ bằng đúng ràng buộc của tùy chọn
-   deck (BR-SETTINGS-002), ghi một transaction, và stream đẩy giá trị mới ra mọi surface.
+2. Người dùng đổi trần thẻ mỗi phiên và/hoặc thứ tự thẻ mới. Không có nút lưu: mỗi
+   thay đổi đã dừng là một submit (trần thẻ dừng 600 ms sau bước cuối, kể cả khi giữ
+   −/+; số gõ vào và thứ tự thẻ mới lưu ngay). Hệ thống validate trần thẻ bằng đúng
+   ràng buộc của tùy chọn deck (BR-SETTINGS-002), ghi một transaction, và stream đẩy
+   giá trị mới ra mọi surface. (Sửa ngày 2026-09-26 theo quyết định D1 của
+   [spec FE-A3](../../../superpowers/specs/2026-09-26-settings-ui-design.md), chủ dự án
+   duyệt.)
 3. Hệ thống nói rõ tại chỗ rằng mặc định mới áp cho **phiên tạo sau đó**; phiên
    đang chạy giữ nguyên trần đã chốt (BR-SETTINGS-004).
 4. Người dùng chọn theme trong `System` / `Light` / `Dark`. Lựa chọn là một
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index b0b0f0b..125d6e5 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -56,10 +56,10 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 20 | Study · Fill | 3 | FE-A6 | aligned | [20-study-fill.md](20-study-fill.md) |
 | 21 | Session summary | 10 | FE-A6 | aligned | [21-session-summary.md](21-session-summary.md) |
 | 22 | Progress | 8 | FE-A9 | not built | — |
-| 23 | Settings | 8 | FE-A3 | not built | — |
+| 23 | Settings | 8 | FE-A3 | aligned | [23-settings.md](23-settings.md) |
 | 24 | Daily reminder | 9 | FE-B5 | out of V8 | — |
-| 25 | Theme | 3 | FE-A3 | not built | — |
-| 26 | Language | 3 | FE-A3 | not built | — |
+| 25 | Theme | 3 | FE-A3 | aligned | [25-theme.md](25-theme.md) |
+| 26 | Language | 3 | FE-A3 | aligned | [26-language.md](26-language.md) |
 
 ## Rules shared by every screen
 
```

`docs/shared/ui/screen-handoff/23-settings.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 23 · Settings

The Settings tab: the app-wide study defaults, the Theme and Language pages, and Reset
app options. Every value shown is the stored one, or the card limit being changed.
UC-SETTINGS-001; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.2.

## Entry points

- **The Settings tab** of the bottom bar, `/settings`. It replaces the tab's placeholder.
- **Debug builds only:** the app bar's gallery icon opens the component gallery.

The Theme and Language rows open screens 25 and 26 on the root navigator, with no bottom
bar (D2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | "Settings"; the gallery icon in debug builds. |
| Study defaults | `MxSection` + `MxSettingsRow` × 2 | "Cards per session" / "1 to 200 · default 20", with an `MxStepper` under the label: −/+, a hold repeats, a tap on the number types one (D6). "New-card order" / "How new cards enter a learning session", with an `MxSegmentedTray` Created · Random. The note: "Apply to sessions started from now on. A deck with its own study options keeps them." |
| Card limit message | `MxFieldMessage` (error) | "Enter a number from 1 to 200", under the stepper, while a typed value is out of range (E1). |
| App | `MxSection` + `MxSettingsRow` × 2 | "Theme" with the choice ("Follows the system setting", "Light" or "Dark"); "Language" with "System · {language}", "English" or "Tiếng Việt". Both open their page. |
| Reset | `MxSection` + `MxSettingsRow` | "Reset app options" / "Theme, language, study defaults". The note: "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched." |
| Reset dialog | `MxDialog` + `MxNote` + `MxSheetActions.custom` | "Reset app options?", "Theme, language, cards per session and new-card order go back to their defaults.", the shield note "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”.", then Cancel (outline) · "Reset options" (primary, spinning while it runs), stacked when a label cannot fit (UI-base row 118). Back and Cancel do nothing while it runs. |
| Toasts | `MxSnackbar` | "Saved"; "Couldn't save cards per session. Still {n}." · Retry; "Couldn't save the new-card order." · Retry; "App options reset to defaults"; "Couldn't reset the app options. Nothing changed." · Retry. |

The card limit is saved once a change settles: 600 ms after the last step, a hold
included, or at once for a typed value. A segment tap saves at once (D1).

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| loaded | ![](img/23-settings/loaded-light.png) | ![](img/23-settings/loaded-dark.png) | Theme is a row that opens screen 25 (D2); the Daily reminder row is hidden until FE-B5. |
| loading | ![](img/23-settings/loading-light.png) | ![](img/23-settings/loading-dark.png) | Skeleton rows (UI-base row 121). |
| saving | ![](img/23-settings/saving-light.png) | ![](img/23-settings/saving-dark.png) | The stepper's spinner; the other rows stay usable. |
| saved | ![](img/23-settings/saved-light.png) | ![](img/23-settings/saved-dark.png) | As drawn. |
| invalidLimit | ![](img/23-settings/invalidLimit-light.png) | ![](img/23-settings/invalidLimit-dark.png) | **Deviation:** the message sits under the stepper and the sub-line stays (UC E1). |
| saveFailed | ![](img/23-settings/saveFailed-light.png) | ![](img/23-settings/saveFailed-dark.png) | As drawn; the stepper shows the stored value again. |
| resetConfirm | ![](img/23-settings/resetConfirm-light.png) | ![](img/23-settings/resetConfirm-dark.png) | As drawn. |
| resetDone | ![](img/23-settings/resetDone-light.png) | ![](img/23-settings/resetDone-dark.png) | As drawn. |
| read error | — | — | **V8 addition (UC E3):** `MxErrorState` "Couldn't open Settings" with the local-first body and Retry; no value is shown. |

Goldens: `test/features/settings/presentation/goldens/settings_{loaded,loading,saving,saved,invalid_limit,save_failed,reset_confirm,reset_done}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| Theme as an inline System · Light · Dark tray | A row naming the choice, opening screen 25 | D2 (owner); UI-base row 120 |
| The Daily reminder row | Hidden until FE-B5 | Spec A4: a control without its feature is hidden |
| "Enter a number from 1 to 200" in place of the sub-line | Under the stepper, the sub-line kept | UC-SETTINGS-001 E1 ("under the field") |
| −/+ by one | −/+, a hold that repeats, and a typed number | D6 (owner); UI-base row 122 |
| Loading as skeleton sub-lines inside the sections | `MxSkeletonList` | UI-base row 121 |
| No read-error state | `MxErrorState` with Retry | UC E3; UI-base row 121 |
| The tray on one line at any size | The options stack when their labels do not fit | UI-base row 123 |
| The tile centred on a row with a wide control | The tile beside the label, as the kit draws it | UI-base row 124 |

## Copy

- Study defaults: "Study defaults" · "Cards per session" · "1 to {max} · default {n}" · "Fewer cards per session" · "More cards per session" · "Enter a number from {min} to {max}" · "New-card order" · "How new cards enter a learning session" · "Created" · "Random" · "Apply to sessions started from now on. A deck with its own study options keeps them."
- App: "App" · "Theme" · "Follows the system setting" · "Light" · "Dark" · "Language" · "System · {language}" · "English" · "Tiếng Việt".
- Reset: "Reset" · "Reset app options" · "Theme, language, study defaults" · "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched." · "Reset app options?" · "Theme, language, cards per session and new-card order go back to their defaults." · "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”." · "Cancel" · "Reset options".
- Toasts: "Saved" · "Couldn't save cards per session. Still {n}." · "Couldn't save the new-card order." · "App options reset to defaults" · "Couldn't reset the app options. Nothing changed." · "Retry".
- Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · "Retry".
```

`docs/shared/ui/screen-handoff/25-theme.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 25 · Theme

The app's theme: follow the phone, always light or always dark. A tap applies it at
once, and the page stays open. UC-SETTINGS-001 step 4, BR-SETTINGS-005; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.3.

## Entry points

- **Screen 23's Theme row**, `/settings/theme`, on the root navigator with no bottom bar
  (D2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back and "Theme" (D7). |
| Cards | `MxCard` (selected ring) + `MxRowInk` × 3 | A preview, then "System" / "Match phone", "Light" / "Always light", "Dark" / "Always dark", and a check on the chosen card. The preview paints the light and dark themes' own colours; System is split in half. Each card is one TalkBack node, "selected" when chosen. |
| Note | Text | "Applies at once — no restart, and you stay where you are." |
| Toast | `MxSnackbar` | "Couldn't change the theme." · Retry. The stored choice stays selected. |

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| system | ![](img/25-theme/system-light.png) | ![](img/25-theme/system-dark.png) | Titled "Theme", with plain descriptors (D7); no "THEME" overline. |
| light | ![](img/25-theme/light-light.png) | ![](img/25-theme/light-dark.png) | As system. |
| dark | ![](img/25-theme/dark-light.png) | ![](img/25-theme/dark-dark.png) | As system. |
| read error | — | — | **V8 addition (UC E3):** `MxErrorState` "Couldn't open Settings" with Retry. |

Goldens: `test/features/settings/presentation/goldens/settings_theme_{system,light,dark}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| "Appearance", and a "THEME" overline | "Theme", with no overline: the title already names it | D7 (owner) |
| "Tokyo Pure", "Tokyo Nebula" | "Always light", "Always dark" | D7 (owner) |

## Copy

"Theme" · "System" · "Match phone" · "Light" · "Always light" · "Dark" · "Always dark" ·
"Applies at once — no restart, and you stay where you are." · "Couldn't change the
theme." · "Retry".
```

`docs/shared/ui/screen-handoff/26-language.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 26 · Language

The app's language: follow the phone, English or Tiếng Việt. A tap applies it at once,
and the page stays open. UC-SETTINGS-001 step 5, BR-SETTINGS-006; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.3.

## Entry points

- **Screen 23's Language row**, `/settings/language`, on the root navigator with no bottom
  bar (D2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back and "Language". |
| Rows | `MxCard` + `MxOptionRow` × 3 | "Follow the system" with what it resolves to now: "Phone is set to English", "Phone is set to Tiếng Việt", or "Your phone's language isn't available · English" (D8). "English", and "Tiếng Việt" with its name in the current language ("Vietnamese"); a sub-line that repeats the title is left out. |
| Note | Text | "Applies at once — no restart, and you stay where you are. Your cards stay in their own language." |
| Toasts | `MxSnackbar` | After a switch, in the new language: "Switched to English" or "Đã chuyển sang Tiếng Việt". "Couldn't change the language." · Retry; the stored choice stays selected. |

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| english | ![](img/26-language/english-light.png) | ![](img/26-language/english-dark.png) | Radio rows; English has no sub-line. |
| vietnamese | ![](img/26-language/vietnamese-light.png) | ![](img/26-language/vietnamese-dark.png) | The toast reads in Vietnamese. |
| system | ![](img/26-language/system-light.png) | ![](img/26-language/system-dark.png) | **Deviation:** the line names what `system` resolves to (D8). |
| read error | — | — | **V8 addition (UC E3):** `MxErrorState` "Couldn't open Settings" with Retry. |

Goldens: `test/features/settings/presentation/goldens/settings_language_{english,switched,system}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| "Phone is set to Tiếng Việt · falls back to English" | "Phone is set to Tiếng Việt"; the fallback line only for a language the app lacks | D8, BR-SETTINGS-006 |
| A tinted selected row with a trailing check | `MxOptionRow` radios, the app's single-choice list | The shared option row |
| English over "English" | No sub-line when it repeats the title | Critique 2026-09-26 (minor) |

## Copy

"Language" · "Follow the system" · "Phone is set to {language}" · "Your phone's language
isn't available · English" · "English" · "Tiếng Việt" · "Vietnamese" · "Applies at once —
no restart, and you stay where you are. Your cards stay in their own language." ·
"Switched to English" · "Đã chuyển sang Tiếng Việt" · "Couldn't change the language." ·
"Retry".
```

`docs/shared/ui/screen-state-checklist.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-state-checklist.md b/docs/shared/ui/screen-state-checklist.md
index bc05598..2a86de0 100644
--- a/docs/shared/ui/screen-state-checklist.md
+++ b/docs/shared/ui/screen-state-checklist.md
@@ -32,7 +32,7 @@ Màn 14, 16, 16a và 17–21 là `aligned` trong index từ phase P5 của roadm
 
 ## Tổng hợp
 
-Kit có **26 màn, 211 state**. Xong **115**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **67**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
+Kit có **26 màn, 211 state**. Xong **129**; một phần **5**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **53**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
 
 | # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
 |---|---|---|---|---|---|---|---|---|
@@ -58,10 +58,10 @@ Kit có **26 màn, 211 state**. Xong **115**; một phần **5**; đã dựng nh
 | 20 | Study · Fill | FE-A6 | 3 | 3 | 0 | 0 | 0 | [20-study-fill.md](screen-handoff/20-study-fill.md) |
 | 21 | Session summary | FE-A6 | 10 | 8 | 1 | 0 | 1 | [21-session-summary.md](screen-handoff/21-session-summary.md) |
 | 22 | Progress | FE-A9 | 8 | 0 | 0 | 8 | 0 | — |
-| 23 | Settings | FE-A3 | 8 | 0 | 0 | 8 | 0 | — |
+| 23 | Settings | FE-A3 | 8 | 8 | 0 | 0 | 0 | [23-settings.md](screen-handoff/23-settings.md) |
 | 24 | Daily reminder | FE-B5 | 9 | 0 | 0 | 9 | 0 | — |
-| 25 | Theme | FE-A3 | 3 | 0 | 0 | 3 | 0 | — |
-| 26 | Language | FE-A3 | 3 | 0 | 0 | 3 | 0 | — |
+| 25 | Theme | FE-A3 | 3 | 3 | 0 | 0 | 0 | [25-theme.md](screen-handoff/25-theme.md) |
+| 26 | Language | FE-A3 | 3 | 3 | 0 | 0 | 0 | [26-language.md](screen-handoff/26-language.md) |
 
 ## Theo màn
 
@@ -422,18 +422,18 @@ FE-A9 · chưa có detail file
 
 ### 23 · Settings
 
-FE-A3 · chưa có detail file
+FE-A3 · [23-settings.md](screen-handoff/23-settings.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | Loaded | — | chưa làm |  |
-| [ ] | Loading | — | chưa làm |  |
-| [ ] | Saving | — | chưa làm |  |
-| [ ] | Saved | — | chưa làm |  |
-| [ ] | Invalid limit | — | chưa làm |  |
-| [ ] | Save failed | — | chưa làm |  |
-| [ ] | Reset options | — | chưa làm |  |
-| [ ] | Options reset | — | chưa làm |  |
+| [x] | Loaded | `loaded` | xong | Theme là hàng mở màn 25 (D2); hàng Daily reminder ẩn tới FE-B5. |
+| [x] | Loading | `loading` | xong | Skeleton list (UI-base §9 dòng 121). |
+| [x] | Saving | `saving` | xong | Spinner trong stepper. |
+| [x] | Saved | `saved` | xong |  |
+| [x] | Invalid limit | `invalidLimit` | xong | Thông báo nằm dưới stepper (UC E1). |
+| [x] | Save failed | `saveFailed` | xong |  |
+| [x] | Reset options | `resetConfirm` | xong |  |
+| [x] | Options reset | `resetDone` | xong |  |
 
 ### 24 · Daily reminder
 
@@ -453,23 +453,23 @@ FE-B5 · chưa có detail file
 
 ### 25 · Theme
 
-FE-A3 · chưa có detail file
+FE-A3 · [25-theme.md](screen-handoff/25-theme.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | System | — | chưa làm |  |
-| [ ] | Light | — | chưa làm |  |
-| [ ] | Dark | — | chưa làm |  |
+| [x] | System | `system` | xong | Tiêu đề "Theme", dòng mô tả dễ hiểu (D7). |
+| [x] | Light | `light` | xong |  |
+| [x] | Dark | `dark` | xong |  |
 
 ### 26 · Language
 
-FE-A3 · chưa có detail file
+FE-A3 · [26-language.md](screen-handoff/26-language.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [ ] | English | — | chưa làm |  |
-| [ ] | Switched to Vietnamese | — | chưa làm |  |
-| [ ] | Follow system | — | chưa làm |  |
+| [x] | English | `english` | xong | Hàng radio `MxOptionRow`. |
+| [x] | Switched to Vietnamese | `vietnamese` | xong | Toast viết bằng ngôn ngữ mới. |
+| [x] | Follow system | `system` | xong | Dòng phụ nói `system` đang ra ngôn ngữ nào (D8). |
 
 ## Cập nhật
 
@@ -478,3 +478,5 @@ FE-A3 · chưa có detail file
 - **Khi kit đổi phiên bản:** so lại danh sách state với bộ chuyển state của kit, rồi
   sửa dòng "Nguồn" và `tools/design/screen_states.json`.
 - **Tạo ngày 2026-09-26** theo yêu cầu của chủ dự án, từ `master` tại `e2ad9de`.
+- **Cập nhật ngày 2026-09-26:** FE-A3 plan 1 dựng màn 23, 25 và 26; 14 state chuyển sang
+  xong.
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index b1ebade..be46144 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -522,6 +522,11 @@ item names where it comes from.
 | 117 | A selecting row's checkbox is centred vertically on the row (kit: top-aligned with the title) | owner 2026-09-26, D4 |
 | 118 | A footer pair stacks full width when a label cannot fit its share on one line (kit: always side by side, labels wrap) | owner 2026-09-26, D3 |
 | 119 | The deck summary's progress label keeps the 12 overline (`compactOverline`), onSurface, so it stays on one line on a 360 phone; every other overline is 13 (row 116) | owner 2026-09-26 |
+| 120 | Screen 23's Theme is a row naming the choice ("Follows the system setting", "Light", "Dark") that opens screen 25, not the kit's inline System · Light · Dark tray | FE-A3 D2 |
+| 121 | Screen 23 loads as `MxSkeletonList`, not skeleton sub-lines and controls inside its sections; a failed read shows `MxErrorState` with Retry, which the kit does not draw (UC-SETTINGS-001 E3). Screens 25 and 26 do the same | FE-A3 plan 1 |
+| 122 | `MxStepper` goes beyond the kit's −/+ by one: holding −/+ repeats (400 ms, then every 80 ms) and a tap on the number types one (FE-A3 D6). The number's box stays 36 tall, its tap target 48 | FE-A3 plan 1 |
+| 123 | `MxSegmentedTray` stacks its options, one per line, when their labels do not fit on one (large text, long Vietnamese labels); the kit draws one line only | FE-A3 plan 1 (visual audit) |
+| 124 | Beside a wide control, `MxSettingsRow`'s tile sits at the top with the label, as kit 23 draws it, not centred on the row | FE-A3 plan 1 |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index 250466a..b6181f0 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -77,7 +77,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 |---|---|---|---|---|---|---|
 | FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | đang làm | BE-03 | L | [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); căn theo screen handoff ở FE-A11; [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: panel "Mastered x/y" và sort theo progress chờ BR/UC của deck định nghĩa (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | đang làm | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: file chi tiết handoff cho màn 08–10 |
-| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | chưa bắt đầu | BE-A1 | M | `lib/app/app.dart` để `ThemeMode.system` tới khi feature settings lưu được lựa chọn; spec UI base §10 để việc lưu theme và ngôn ngữ ngoài phạm vi; [ui.md](features/settings/ui.md); backend sẵn: 8 use case trong `lib/features/settings/domain/usecases/` | Đọc màn 15, 23, 25, 26 trong kit, viết file chi tiết handoff, rồi lập plan |
+| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | đang làm | BE-A1 | M | [spec](superpowers/specs/2026-09-26-settings-ui-design.md); [plan 1: màn 23, 25, 26, `MxStepper`, theme và ngôn ngữ toàn app](superpowers/plans/2026-09-26-settings-ui.md); screen handoff [23](shared/ui/screen-handoff/23-settings.md), [25](shared/ui/screen-handoff/25-theme.md), [26](shared/ui/screen-handoff/26-language.md); [ui.md](features/settings/ui.md) | Plan 2: màn 15 (Study options) và hai lối vào (D3) |
 | FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
 | FE-A5 | Thiết kế luồng học (Impeccable): mặt thẻ, lật thẻ, hàng chấm điểm, tổng kết phiên, streak, cách trình bày sáu mode | xong | FE-07 | S | File chi tiết handoff 13, 14, 16–21 kèm ảnh state ([screen handoff index](shared/ui/screen-handoff/00-index.md)); shape cho phiên `self_assess` ở `16a-study-self-assess.md` (chấm Again/Hard/Good/Easy, hiện khoảng ôn dự kiến ở lượt scheduled) | — |
 | FE-A6 | Study Entry, màn hình phiên học và ôn tập cho sáu mode, tổng kết phiên (UC-STUDY-001; BR-MODE-001…BR-MODE-019) | xong | FE-A5, BE-A3, BE-A4, BE-A10 | XL | Backend đã sẵn (BE-A3, BE-A4, BE-A10 xong); màn 14, 16–21 trong kit; kịch bản IT của [study](features/study/it-scenarios.md) và [study-mode](features/study-mode/it-scenarios.md); [spec study UI](superpowers/specs/2026-09-26-study-ui-design.md) (đã duyệt 2026-09-26, chia phase P1–P5; D11 thêm hai phần backend nhỏ trong P1 và P2); phase P1a (nền: tone `success`/`caution`/`danger`, `MxStatTile`, read model của entry và tổng kết): [plan](superpowers/plans/2026-09-26-study-p1a-foundations.md); phase P1b (màn 14 chỉ đọc, route, lối vào từ action sheet và summary, đóng phiên cũ khi mở app): [plan](superpowers/plans/2026-09-26-study-p1b-entry.md); phase P1c (route phiên toàn màn hình, controller, màn 16 Browse, màn 21 Summary; thoát giữa phiên hiện tổng kết theo quyết định của chủ dự án về D8): [plan](superpowers/plans/2026-09-26-study-p1c-session.md); phase P2 (màn 16a self-assess với preview khoảng cách D11b, các action của màn 14: Learn, Review, Continue, starting/refused/startFailed, sheet chọn chiều hỏi FE-A7; deck `sm2` học được trọn vẹn): [plan](superpowers/plans/2026-09-26-study-p2-self-assess.md); roadmap P3→P6 đã duyệt: [roadmap](superpowers/plans/2026-09-26-study-chain-roadmap.md); phase P3 (Guess 18, Match 17, chọn mode ôn cho eight_box, sửa `MxStudyTopBar` ở chữ 2x): [plan](superpowers/plans/2026-09-26-study-p3-guess-match.md); phase P4 (Recall 19, Fill 20; deck `eight_box` học và ôn được trọn vẹn, bỏ tập mode đã dựng): [plan](superpowers/plans/2026-09-26-study-p4-recall-fill.md); phase P5 (bộ kịch bản IT tầng host của study, index 14 và 16–21 `aligned`, đóng các minor còn hoãn): [plan](superpowers/plans/2026-09-26-study-p5-it-records.md) | — |
@@ -133,6 +133,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 
 - **FE-A8:** phase P6 của [roadmap luồng học](superpowers/plans/2026-09-26-study-chain-roadmap.md)
   đã duyệt. FE-A6 xong: P1 (#71, #73), P2 (#75, kèm FE-A7), P3 (#76), P4 (#80) và P5.
+- **FE-A3:** plan 1 (màn 23, 25, 26) xong; plan 2 (màn 15) chưa bắt đầu.
 - **FE-A1, FE-A2:** chức năng xong; phần còn lại ở cột "Việc tiếp theo" của từng dòng.
 
 Nhánh `claude/study-large-files` không còn gì để merge: cả hai commit của nó (bỏ qua file
@@ -144,7 +145,7 @@ so nội dung.
 
 | Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
 |---|---|---|---|
-| FE-A2, FE-A3, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 15, 22, 23, 25, 26 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
+| FE-A2, FE-A3, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 15, 22 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
 | FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
 | FE-D3 | Không có emulator hoặc thiết bị | 8 kịch bản `DEVICE-E2E` | Môi trường chạy |
@@ -239,3 +240,6 @@ giờ mỗi trạng thái, cộng thêm phần tương tác phức tạp.
 - **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
 - **Cập nhật ngày 2026-09-26:** FE-A6 xong sau phase P5 (#80 cho P4); "Đang làm" và
   "Bước tiếp theo" chuyển sang FE-A8 (phase P6 của roadmap luồng học).
+- **Cập nhật ngày 2026-09-26:** FE-A3 plan 1 xong: màn 23, 25, 26 thay placeholder của
+  tab Settings; theme và ngôn ngữ lưu được và áp cho cả app. FE-A3 chuyển sang "đang
+  làm"; còn plan 2 (màn 15).
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
  docs/shared/ui/screen-handoff/23-settings.md \
  docs/shared/ui/screen-handoff/25-theme.md \
  docs/shared/ui/screen-handoff/26-language.md \
  docs/shared/ui/screen-state-checklist.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/wbs_FE.md \
  docs/_generated/traceability.md \
  docs/_generated/open-questions.md
git commit -m "$(cat <<'EOF'
docs(settings): FE-A3 plan 1 done: detail files 23, 25, 26, register rows 120-124, UC-SETTINGS-001 step 2

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
