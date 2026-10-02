# UI hardening SP1 — Foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the shared-widget, theme, platform and `DESIGN.md` findings of the 2026-10-02/03 critique, harden and audit (spec §5, items 1–19), so SP2–SP5 build on them.

**Architecture:** Every change lands in the layer that owns it: `lib/shared/widgets` (Mx* widgets), `lib/core/theme` (tokens, derived colours, component themes, page transitions), `lib/app` (system bars), `android/app/src/main/res` (launch window), and `DESIGN.md`. No feature behaviour changes, apart from three haptic calls and one streak ink.

**Tech Stack:** Flutter 3.47.5 (`.fvmrc`), Dart, Riverpod, flutter_test. Android resources (XML).

**Spec:** `docs/superpowers/specs/2026-10-03-ui-hardening-design.md` (§3 rulings R1–R7, §5 SP1).

## Global Constraints

- Colours, sizes, radii, durations and opacities come from tokens (`lib/core/theme/foundations/*`, `context.colors`, `context.derivedColors`, `context.semanticColors`). Never write `Color(0x…)`, `Colors.*` or literal sizes in `lib/shared`, `lib/features` or `lib/app`. The guard (`check_design_tokens.py` hook) checks every edited Dart file.
- No user-facing string in a widget. Copy is caller-supplied and localized (`lib/l10n/app_en.arb`, `app_vi.arb`). This plan adds no ARB keys; tab positions come from `MaterialLocalizations.tabLabel`.
- Tests run at the default text scale only (owner 2026-09-30).
- On Windows run `flutter test <path>` (never `--update-goldens`); the gate excludes goldens there. Goldens are regenerated only in the Linux container: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`.
- Commit messages: conventional, scoped, English, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- R2: the footer caption reads at full `onSurfaceVariant`. R4: the nav stays custom. R7: toast replacement is unchanged.

## Review Focus

- **The dialog under a keyboard with "remove animations" on.** The padding must apply at once (zero duration), not animate. Pinned in Task 1.
- **Back with the stepper's keyboard up.** The route pops while the field is editing. The typed value must reach `onValueSubmitted` exactly once, without a `setState` during deactivate. Pinned in Task 2.
- **App theme dark while the phone is light.** System-bar icons must follow the app (light icons), not the OS. Pinned in Task 9.
- **A landscape window with insets on both sides.** Body and footer must clear both the start and the end inset, in LTR and RTL. Pinned in Task 8.
- **A held dialog when the write fails.** `isHeld` turns false again and the dialog must become dismissible. Pinned in Task 1.

---

### Task 1: `MxDialog` clears the keyboard, avoids the hinge, and can be held

**Files:**
- Modify: `lib/shared/widgets/mx_dialog.dart`
- Test: `test/shared/widgets/mx_dialog_test.dart`

**Interfaces:**
- Produces: `MxDialog({…, bool isHeld = false})`. SP2 sets `isHeld: _isWriting` on writing dialogs.

- [ ] **Step 1: Write the failing tests** (append inside `main()` of `mx_dialog_test.dart`)

```dart
  const actionsKey = ValueKey('dialog-actions');
  Widget withKeyboard(Widget child, {bool still = true}) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        viewInsets: const EdgeInsets.only(bottom: 300),
        disableAnimations: still,
      ),
      child: child,
    ),
  );
  const tall = MxDialog(
    title: 'Rename deck',
    content: SizedBox(height: 260),
    actions: SizedBox(key: actionsKey, height: 48),
  );

  testWidgets('the dialog sits above the keyboard (harden 01, audit P1)', (
    tester,
  ) async {
    await pumpMxPage(tester, withKeyboard(tall));
    await tester.pump();
    expect(
      tester.getBottomLeft(find.byKey(actionsKey)).dy,
      lessThanOrEqualTo(800 - 300),
    );
  });

  testWidgets('with remove animations the keyboard inset applies at once', (
    tester,
  ) async {
    await pumpMxPage(tester, withKeyboard(tall));
    // No pump of a duration: a zero-length AnimatedPadding is already there.
    expect(
      tester.widget<AnimatedPadding>(find.byType(AnimatedPadding)).duration,
      Duration.zero,
    );
  });

  testWidgets('a held dialog ignores Back and the scrim; released, it closes', (
    tester,
  ) async {
    final held = ValueNotifier(true);
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxDialog<void>(
            context,
            builder: (_) => ValueListenableBuilder(
              valueListenable: held,
              builder: (_, isHeld, _) =>
                  MxDialog(title: 'Deleting…', isHeld: isHeld),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Deleting…'), findsOneWidget);
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Deleting…'), findsOneWidget);

    held.value = false;
    await tester.pump();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Deleting…'), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/widgets/mx_dialog_test.dart`
Expected: FAIL. The first test fails because the actions' bottom is about 570 > 500; the second finds no `AnimatedPadding`; the third does not compile (`isHeld` is undefined).

- [ ] **Step 3: Implement**

In `mx_dialog.dart` add the field and wrap the `Center`:

```dart
  const MxDialog({
    super.key,
    this.title,
    this.body,
    this.content,
    this.actions,
    this.width = MxDialogWidth.large,
    this.isHeld = false,
  });
  …
  /// While true, Back and a scrim tap do nothing: the dialog is writing and
  /// its result must reach the screen (critique 2026-10-02 harden, SP1 §5.1).
  final bool isHeld;
```

Replace the `return Semantics(...)` block's `child: Center(` opening with this structure (the `Center` subtree itself is unchanged):

```dart
    // The keyboard's inset: showGeneralDialog adds none, so a field dialog
    // would sit under it on a short phone (harden 01/05, SP1 §5.1).
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !isHeld,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        // Never across a hinge (showDialog does this; showGeneralDialog not).
        child: DisplayFeatureSubScreen(
          child: AnimatedPadding(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppDurations.standard,
            curve: Easing.standard,
            padding: EdgeInsets.only(bottom: keyboard),
            child: Center(
              // … the existing Padding › ConstrainedBox › DecoratedBox › Material tree …
            ),
          ),
        ),
      ),
    );
```

Update the class doc's first line to: `/// The centred modal for confirmations and short forms. It rises above the keyboard and never straddles a hinge. The text sits 20 in …`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_dialog_test.dart`
Expected: PASS (all tests, old and new).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_dialog.dart test/shared/widgets/mx_dialog_test.dart
git commit -m "fix(ui): MxDialog rises above the keyboard, avoids the hinge and can be held (SP1 §5.1)"
```

---

### Task 2: `MxStepper` commits what was typed on a tap outside and on leaving

**Files:**
- Modify: `lib/shared/widgets/mx_stepper.dart` (state class, `TextField` in `_value`)
- Test: `test/shared/widgets/mx_stepper_input_test.dart`

**Interfaces:**
- Consumes: the existing `onValueSubmitted: ValueChanged<String>?`. Its semantics are unchanged: it receives the raw typed text.

- [ ] **Step 1: Write the failing tests** (append inside `main()`)

```dart
  testWidgets('a tap outside the field submits what was typed (harden 15)', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bounded(onSubmitted: submitted.add),
          const SizedBox(key: ValueKey('outside'), width: 200, height: 48),
        ],
      ),
    );
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '42');
    await tester.tap(find.byKey(const ValueKey('outside')));
    await tester.pump();
    expect(submitted, ['42']);
  });

  testWidgets('leaving the route with the field open submits once (harden 23)', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                body: Center(child: _Bounded(onSubmitted: submitted.add)),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '7');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(submitted, ['7']);
    expect(tester.takeException(), isNull);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/widgets/mx_stepper_input_test.dart`
Expected: FAIL. The first test gives `submitted` empty (a tap outside does not unfocus on Android). The second gives an empty list as well.

- [ ] **Step 3: Implement** in `_MxStepperState`

```dart
  @override
  void deactivate() {
    // Back with the keyboard up: the route goes before the field loses
    // focus, so what was typed is handed over here (harden 15, 23; SP1
    // §5.1). No setState: the subtree is leaving.
    if (_isEditing) {
      _isEditing = false;
      widget.onValueSubmitted?.call(_field.text);
    }
    super.deactivate();
  }
```

In the `TextField(` inside `_value`, add after `focusNode: _focus,`:

```dart
                // Android keeps focus on a tap elsewhere; the stepper does
                // not, so Save reads the typed value (harden 15, SP1 §5.1).
                onTapOutside: (_) => _focus.unfocus(),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_stepper_input_test.dart test/shared/widgets/mx_stepper_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_stepper.dart test/shared/widgets/mx_stepper_input_test.dart
git commit -m "fix(ui): MxStepper hands over a typed value on a tap outside and on leaving (SP1 §5.1)"
```

---

### Task 3: `MxScreenScroll` dismisses the keyboard on drag

**Files:**
- Modify: `lib/shared/widgets/mx_screen_scroll.dart`
- Test: `test/shared/widgets/mx_screen_scroll_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('dragging the scroll dismisses the keyboard (audit Platform)', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      const Scaffold(body: MxScreenScroll(children: [SizedBox(height: 10)])),
    );
    expect(
      tester.widget<ListView>(find.byType(ListView)).keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_screen_scroll_test.dart`
Expected: FAIL (`manual`).

- [ ] **Step 3: Implement.** In `ListView(` add `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,`. Add to the class doc: `A drag dismisses the keyboard.`

- [ ] **Step 4: Run it to verify it passes.** Same command; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_screen_scroll.dart test/shared/widgets/mx_screen_scroll_test.dart
git commit -m "fix(ui): a drag on the screen scroll dismisses the keyboard (SP1 §5.1)"
```

---

### Task 4: Contrast — footer caption at full ink, toggle thumb, streak ink, test pairs

**Files:**
- Modify: `lib/shared/widgets/mx_footer_bar.dart:51-58`
- Modify: `lib/shared/widgets/mx_toggle.dart` (thumb colour)
- Modify: `lib/core/theme/mx_derived_colors.dart` (new `streakInk`)
- Modify: `lib/features/progress/presentation/widgets/sections/progress_streak_widget.dart` (the `tint:` of the current tile; use `git ls-files | grep progress_streak_widget` for the exact path)
- Test: `test/core/theme/token_contrast_test.dart`, `test/shared/widgets/mx_footer_bar_test.dart`, `test/shared/widgets/mx_toggle_test.dart`

**Interfaces:**
- Produces: `MxDerivedColors.streakInk` (`Color`). Light is `streak` pulled 20% toward `onSurface` (#CA601D: 4.04 on the card, 3.57 on its 12% tint). Dark is `streak` itself.

- [ ] **Step 1: Write the failing tests**

In `token_contrast_test.dart`, inside the `for (final (ground, where) …)` list add:

```dart
      ('reviewingInk on $where', derived.statusReviewingInk, ground, _text),
      ('successInk on $where', derived.successInk, ground, _text),
      ('dangerInk on $where', derived.dangerInk, ground, _text),
      // R2: the footer caption at full strength (it was 3.50:1 at 0.7).
      ('footer caption on $where', scheme.onSurfaceVariant, ground, _text),
```

After the `'sheet grabber'` entry add:

```dart
    // SP1 §5.2: the ON thumb on its primary track; the streak flame on
    // the card and on its own 12% tint.
    ('toggle on thumb on its track', scheme.onPrimary, scheme.primary, _nonText),
    ('streak glyph on the card', derived.streakInk, row, _nonText),
    (
      'streak glyph on its 12% tint',
      derived.streakInk,
      _tint(derived.streakInk, 0.12, row),
      _nonText,
    ),
```

In `mx_footer_bar_test.dart`:

```dart
  testWidgets('the caption reads at full strength, no opacity (R2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxFooterBar(caption: 'Saved to this device only.', child: SizedBox()),
    );
    expect(
      find.ancestor(
        of: find.text('Saved to this device only.'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });
```

In `mx_toggle_test.dart`:

```dart
  testWidgets('the ON thumb is onPrimary in dark (2.90:1 before)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxToggle(isOn: true, semanticLabel: 'Reminder', onChanged: (_) {}),
      brightness: Brightness.dark,
    );
    final thumb = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('mx-toggle-thumb')),
    );
    expect(
      (thumb.decoration as BoxDecoration).color,
      AppColorSchemes.dark.onPrimary,
    );
  });
```

(Use the toggle's actual constructor parameters from `mx_toggle.dart`; add `import 'package:memox/core/theme/app_color_schemes.dart';` if missing.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/theme/token_contrast_test.dart test/shared/widgets/mx_footer_bar_test.dart test/shared/widgets/mx_toggle_test.dart`
Expected: FAIL. `streakInk` does not compile; the footer finds an `Opacity`; the toggle thumb is `surfaceBright`.

- [ ] **Step 3: Implement**

`mx_footer_bar.dart`: replace the `Opacity(...)` child with:

```dart
            if (caption case final caption? when !isTyping)
              // Full variant ink, 7.2:1; at AppOpacity.muted it was 3.50:1
              // in light (audit 2026-10-03, owner R2).
              Text(
                caption,
                textAlign: TextAlign.center,
                style: context.textStyles.footerCaption,
              ),
```

Remove the now-unused `app_opacity.dart` import.

`mx_toggle.dart`: thumb `color: widget.isOn ? colors.onPrimary : colors.onSurfaceVariant,`. Update the comment above it: `// On, onPrimary on the primary track (4.63:1 both themes; surfaceBright was 2.90 in dark, SP1 §5.2). Off, …` and keep the off sentence.

`mx_derived_colors.dart`: add `required this.streakInk,` to the private constructor, the field

```dart
  /// The streak flame as a glyph: 3:1 on the card and its tint
  /// (SP1 §5.2; the colour itself was 2.48 in light).
  final Color streakInk;
```

the resolve entry

```dart
      streakInk: _ink(
        semantic.streak,
        scheme,
        isDark ? _streakInkDark : _streakInkLight,
      ),
```

and the constants `static const double _streakInkLight = 0.20;` and `static const double _streakInkDark = 0;`. If `MxDerivedColors` has `copyWith`, `lerp` or `==`, add `streakInk` there too, following `warningInk`.

`progress_streak_widget.dart`: in `_tiles`, `tint: streak.days > 0 ? context.derivedColors.streakInk : context.colors.onSurfaceVariant,`.

- [ ] **Step 4: Run the tests to verify they pass.** Same command; expected PASS. Also run `flutter test test/features/progress --exclude-tags golden`; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_footer_bar.dart lib/shared/widgets/mx_toggle.dart lib/core/theme/mx_derived_colors.dart lib/features/progress test/core/theme/token_contrast_test.dart test/shared/widgets/mx_footer_bar_test.dart test/shared/widgets/mx_toggle_test.dart
git commit -m "fix(a11y): footer caption, dark toggle thumb and streak glyph meet contrast; contrast test covers every ink (SP1 §5.2)"
```

---

### Task 5: Section headers are TalkBack headings

**Files:**
- Modify: `lib/shared/widgets/mx_list_section_header.dart`
- Test: `test/shared/widgets/mx_list_section_header_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the label is a heading for TalkBack (audit A11y)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxListSectionHeader(label: 'Decks'));
    expect(
      tester.getSemantics(find.text('DECKS')),
      matchesSemantics(label: 'Decks', isHeader: true),
    );
    handle.dispose();
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_list_section_header_test.dart`
Expected: FAIL (`isHeader` false).

- [ ] **Step 3: Implement.** Wrap the label:

```dart
        // A heading, so TalkBack's heading navigation jumps between
        // sections (audit 2026-10-03 A11y; covers every MxSection title).
        Semantics(
          header: true,
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: context.textStyles.overline,
          ),
        ),
```

- [ ] **Step 4: Run it, then the shared suite**

Run: `flutter test test/shared/widgets --exclude-tags golden`
Expected: PASS. If a screen test matches a section label with `matchesSemantics` and now sees `isHeader`, update that expectation to include `isHeader: true`.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_list_section_header.dart test/shared/widgets/mx_list_section_header_test.dart
git commit -m "fix(a11y): section headers are headings for TalkBack (SP1 §5.2)"
```

---

### Task 6: Tint rungs in `AppOpacity` (no visual change)

**Files:**
- Modify: `lib/core/theme/foundations/app_opacity.dart`
- Modify (replace the private constant with the rung): `mx_action_sheet_command_row.dart:41` (0.08 → `tintFaint`), `mx_outcome_tile.dart:28` (0.08 → `tintFaint`), `mx_empty_state.dart:66` (0.10 → `tintSoft`), `mx_study_top_bar.dart:44` (0.10 → `tintSoft`), `mx_icon_tile.dart:49-51` (0.10 → `tintSoft`, 0.16 → `tintSoftDark`, 0.12 → `tintMedium`), `mx_badge.dart:38` and `mx_status_badge.dart:33` (0.12 → `tintMedium`), `lib/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart:23` (0.10 → `tintSoft`), all under `lib/shared/widgets/` unless pathed
- Test: existing suites. Values are identical, so behaviour and goldens do not move.

**Interfaces:**
- Produces: `AppOpacity.tintFaint` (0.08), `tintSoft` (0.10), `tintSoftDark` (0.16), `tintMedium` (0.12), `navPillLight` (0.14), `navPillDark` (0.20), `selection` (0.24). Tasks 7 and 11 use `navPill*` and `selection`.

- [ ] **Step 1: Add the rungs** to `AppOpacity`:

```dart
  /// Tint rungs: a role laid at this alpha over its ground, for tiles,
  /// badges and pills. One rung per value, so a tint changes in one place
  /// (audit 2026-10-03 Theming, SP1 §5.3).
  static const double tintFaint = 0.08;
  static const double tintSoft = 0.10;
  static const double tintMedium = 0.12;

  /// The primary tile tint in dark, where 0.10 vanishes on Nebula.
  static const double tintSoftDark = 0.16;

  /// The selected destination's pill, bottom nav and rail alike.
  static const double navPillLight = 0.14;
  static const double navPillDark = 0.20;

  /// Selected text behind the cursor's handles (Material's default).
  static const double selection = 0.24;
```

- [ ] **Step 2: Replace each private constant.** Delete the `static const double _x = …;` line and use `AppOpacity.<rung>` at its use sites, adding `import 'package:memox/core/theme/foundations/app_opacity.dart';` where missing. Leave the non-tint constants as they are: `mx_skeleton.dart` pulse, `mx_filter_chip.dart` count opacities, `card_schedule_widget.dart` `_pastAlpha`.

- [ ] **Step 3: Verify nothing moved**

Run: `flutter test test/shared test/core --exclude-tags golden`, then `flutter analyze lib`.
Expected: PASS, no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/foundations/app_opacity.dart lib/shared/widgets lib/features/card
git commit -m "refactor(theme): tint rungs in AppOpacity replace per-widget tint constants (SP1 §5.3)"
```

---

### Task 7: Bottom nav and rail announce their position; the unused blur goes

**Files:**
- Modify: `lib/shared/widgets/mx_bottom_nav.dart`, `lib/shared/widgets/mx_nav_rail.dart`, `lib/core/theme/foundations/app_effects.dart` (delete `glassBlur`)
- Test: `test/shared/widgets/mx_bottom_nav_test.dart`, `test/shared/widgets/mx_nav_rail_test.dart`

**Interfaces:**
- Consumes: `AppOpacity.navPillLight`, `AppOpacity.navPillDark` (Task 6).

- [ ] **Step 1: Write the failing tests**

`mx_bottom_nav_test.dart` (top-level helper plus two tests; `AppIcons` glyphs as the
file's existing tests use them):

```dart
const _three = [
  MxNavDestination(icon: AppIcons.library, selectedIcon: AppIcons.librarySelected, label: 'Library'),
  MxNavDestination(icon: AppIcons.study, selectedIcon: AppIcons.studySelected, label: 'Study'),
  MxNavDestination(icon: AppIcons.settings, selectedIcon: AppIcons.settingsSelected, label: 'Settings'),
];

MxBottomNav _nav() =>
    MxBottomNav(destinations: _three, selectedIndex: 0, onSelected: (_) {});

  testWidgets('each destination reads its tab position (R4)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _nav());
    expect(find.bySemanticsLabel('Library\nTab 1 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings\nTab 3 of 3'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no backdrop blur: the bar never sits over content (R4)', (
    tester,
  ) async {
    await pumpMx(tester, _nav());
    expect(find.byType(BackdropFilter), findsNothing);
  });
```

(`AppIcons.library…settingsSelected` are defined in `app_icons.dart:109-116`.)

`mx_nav_rail_test.dart`: the same `_three` list and test with
`MxNavRail(destinations: _three, selectedIndex: 0, onSelected: (_) {})`, expecting
`'Library\nTab 1 of 3'`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/widgets/mx_bottom_nav_test.dart test/shared/widgets/mx_nav_rail_test.dart`
Expected: FAIL (the label is only "Library"; a `BackdropFilter` is found).

- [ ] **Step 3: Implement**

Both widgets:
- Pass `tabIndex: index + 1` and `tabCount: destinations.length` into `_Item` and `_RailItem` (new `final int tabIndex; final int tabCount;` fields).
- Replace `_pillTintLight` and `_pillTintDark` with `AppOpacity.navPillLight` and `AppOpacity.navPillDark`.
- In the item's `Text(destination.label, …)` add:

```dart
              // The position, as Material's NavigationBar reads it (R4).
              semanticsLabel:
                  '${destination.label}\n${MaterialLocalizations.of(context).tabLabel(tabIndex: tabIndex, tabCount: tabCount)}',
```

In `mx_bottom_nav.dart`:
- Remove the `BackdropFilter(...)` wrapper, so `ClipRRect`'s child is the `DecoratedBox` directly.
- Remove `import 'dart:ui';` and the `app_effects.dart` import if unused.
- Update the class doc: `The top-level destinations on a translucent bar (surface at 84%) with a tinted pill behind the current glyph. It is in-flow, never over the scroll, so it carries no blur (SP1 §5.2). Custom by owner ruling R4: Material's NavigationBar would change the bar's look; this one reads its tab positions the same way.`

In `app_effects.dart`, delete `glassBlur` and its doc.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_bottom_nav_test.dart test/shared/widgets/mx_nav_rail_test.dart test/app/tab_shell_test.dart test/app/app_appearance_test.dart`
Expected: PASS. If a route test finds a tab by `bySemanticsLabel('Library')` exactly, change it to `RegExp('^Library')`.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_bottom_nav.dart lib/shared/widgets/mx_nav_rail.dart lib/core/theme/foundations/app_effects.dart test/shared/widgets test/app
git commit -m "fix(a11y): nav destinations read their tab position; the bar drops an unused blur (SP1 §5.2, R4)"
```

---

### Task 8: `MxAppShell` side insets and `AppTabShell` breakpoint read

**Files:**
- Modify: `lib/shared/widgets/mx_app_shell.dart` (`_scaffold`)
- Modify: `lib/app/router/app_tab_shell.dart:26-27`
- Test: `test/shared/widgets/mx_app_shell_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
  for (final direction in TextDirection.values) {
    testWidgets('body and footer clear both side insets ($direction)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const bodyKey = ValueKey('body');
      const footerKey = ValueKey('footer');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Directionality(
            textDirection: direction,
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  viewPadding: const EdgeInsets.symmetric(horizontal: 40),
                ),
                child: const MxAppShell(
                  appBar: SizedBox(height: 56),
                  body: SizedBox.expand(key: bodyKey),
                  footer: SizedBox(key: footerKey, height: 48),
                ),
              ),
            ),
          ),
        ),
      );
      for (final key in [bodyKey, footerKey]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(40));
        expect(rect.right, lessThanOrEqualTo(780 - 40));
      }
    });
  }
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_app_shell_test.dart`
Expected: FAIL (the body spans 30 to 750 inside the 720 column, so `left` is 30).

- [ ] **Step 3: Implement** in `_scaffold`:
- The body child becomes `appBar == null ? SafeArea(bottom: false, child: body) : SafeArea(top: false, bottom: false, child: body)`.
- The footer slot becomes `if (footer case final footer?) SafeArea(top: false, bottom: false, child: footer),` in place of `?footer,`.

Add a comment: `// Side insets (a landscape cutout or 3-button bar) for body and footer as the app bar already takes them (audit 2026-10-03 Adaptivity, SP1 §5.2).`

`app_tab_shell.dart`: replace

```dart
    final media = MediaQuery.of(context);
    if (media.size.width < AppSize.navRailBreakpoint) {
```

with

```dart
    // sizeOf: the keyboard's frames must not rebuild the nav (audit Perf).
    if (MediaQuery.sizeOf(context).width < AppSize.navRailBreakpoint) {
```

and declare `final media = MediaQuery.of(context);` immediately before the rail branch's `return ColoredBox(`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/shared/widgets/mx_app_shell_test.dart test/app/tab_shell_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_app_shell.dart lib/app/router/app_tab_shell.dart test/shared/widgets/mx_app_shell_test.dart
git commit -m "fix(ui): body and footer clear side insets; the tab shell reads only the window size (SP1 §5.2)"
```

---

### Task 9: System bars follow the app theme; the launch window uses the theme's surface

**Files:**
- Create: `lib/app/app_system_bars.dart`
- Modify: `lib/app/app.dart` (`builder:` of `MaterialApp.router`)
- Create: `android/app/src/main/res/values/colors.xml`, `android/app/src/main/res/values-night/colors.xml`, `android/app/src/main/res/values-v31/styles.xml`, `android/app/src/main/res/values-night-v31/styles.xml`
- Modify: `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/drawable-v21/launch_background.xml`, `android/app/src/main/res/values/styles.xml`, `android/app/src/main/res/values-night/styles.xml`
- Test: `test/app/app_system_bars_test.dart` (create), `test/app/android_manifest_test.dart`

**Interfaces:**
- Produces: `AppSystemBars({required Widget child})`.

- [ ] **Step 1: Write the failing tests**

`test/app/app_system_bars_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app_system_bars.dart';
import 'package:memox/core/theme/app_theme.dart';

SystemUiOverlayStyle _style(WidgetTester tester) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    )
    .value;

Future<void> _pump(WidgetTester tester, ThemeMode mode) => tester.pumpWidget(
  MaterialApp(
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: mode,
    builder: (_, child) => AppSystemBars(child: child!),
    home: const SizedBox(),
  ),
);

void main() {
  testWidgets('the app theme, not the phone, sets the bar icons (audit P1)', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _pump(tester, ThemeMode.dark);
    expect(_style(tester).statusBarIconBrightness, Brightness.light);
    expect(_style(tester).systemNavigationBarIconBrightness, Brightness.light);

    await _pump(tester, ThemeMode.light);
    expect(_style(tester).statusBarIconBrightness, Brightness.dark);
    expect(_style(tester).systemNavigationBarContrastEnforced, isFalse);
  });
}
```

In `test/app/android_manifest_test.dart` add (with `import 'dart:io';` if missing):

```dart
  test('the launch window paints each theme surface (SP1 §5.2)', () {
    String read(String path) => File('android/app/src/main/res/$path').readAsStringSync();
    expect(read('values/colors.xml'), contains('#F7F9FE'));
    expect(read('values-night/colors.xml'), contains('#0A0E27'));
    for (final path in [
      'drawable/launch_background.xml',
      'drawable-v21/launch_background.xml',
    ]) {
      expect(read(path), contains('@color/launch_surface'));
    }
    for (final path in ['values-v31/styles.xml', 'values-night-v31/styles.xml']) {
      expect(read(path), contains('windowSplashScreenBackground'));
    }
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app/app_system_bars_test.dart test/app/android_manifest_test.dart`
Expected: FAIL (the file does not exist; `colors.xml` is missing).

- [ ] **Step 3: Implement**

`lib/app/app_system_bars.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The status and navigation bars follow the app's theme, not the phone's.
/// The bars are transparent over the edge-to-edge surface, and their icons
/// contrast with that surface. MxAppBar is not Material's AppBar, which
/// would otherwise set this (audit 2026-10-03 Platform, SP1 §5.2).
class AppSystemBars extends StatelessWidget {
  const AppSystemBars({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icons = isDark ? Brightness.light : Brightness.dark;
    final clear = context.colors.surface.withValues(alpha: 0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: clear,
        statusBarIconBrightness: icons,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: clear,
        systemNavigationBarIconBrightness: icons,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
```

`app.dart`: `builder: (context, child) => AppSystemBars(child: AccountLayerHostWidget(…unchanged…)),` plus the import.

`values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Tokyo Pure Light surface: the window before Flutter's first frame. -->
    <color name="launch_surface">#F7F9FE</color>
</resources>
```

`values-night/colors.xml`: the same file with `<!-- Tokyo Nebula surface … -->` and `#0A0E27`.

Both `launch_background.xml`: `<item android:drawable="@color/launch_surface" />` in place of `?android:colorBackground`.

`values/styles.xml` and `values-night/styles.xml`: in `NormalTheme`, `<item name="android:windowBackground">@color/launch_surface</item>`.

`values-v31/styles.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Android 12+ splash: the theme surface, not the platform default. -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/launch_surface</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@color/launch_surface</item>
    </style>
</resources>
```

`values-night-v31/styles.xml`: the same file with `Theme.Black.NoTitleBar` parents.

- [ ] **Step 4: Run the tests to verify they pass.** Same command; expected PASS. Then run `flutter test test/app --exclude-tags golden`; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/app_system_bars.dart lib/app/app.dart android/app/src/main/res test/app/app_system_bars_test.dart test/app/android_manifest_test.dart
git commit -m "fix(platform): system bar icons follow the app theme; the launch window paints the theme surface (SP1 §5.2)"
```

---

### Task 10: Route transitions honour Remove animations

**Files:**
- Create: `lib/core/theme/app_page_transitions.dart`
- Modify: `lib/core/theme/app_theme.dart` (`_build`)
- Test: `test/core/theme/app_page_transitions_test.dart` (create)

**Interfaces:**
- Produces: `AppPageTransitionsBuilder` (a `PageTransitionsBuilder`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_page_transitions.dart';
import 'package:memox/core/theme/app_theme.dart';

void main() {
  test('the theme routes Android through AppPageTransitionsBuilder', () {
    expect(
      buildLightTheme().pageTransitionsTheme.builders[TargetPlatform.android],
      isA<AppPageTransitionsBuilder>(),
    );
  });

  testWidgets('remove animations: the page is the child, untransformed', (
    tester,
  ) async {
    late Widget built;
    const page = SizedBox(key: ValueKey('page'));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            final route = MaterialPageRoute<void>(builder: (_) => page);
            built = const AppPageTransitionsBuilder().buildTransitions(
              route,
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0),
              page,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(built, page), isTrue);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/theme/app_page_transitions_test.dart`
Expected: FAIL (the file does not exist).

- [ ] **Step 3: Implement** `lib/core/theme/app_page_transitions.dart`:

```dart
import 'package:flutter/material.dart';

/// Android's route transition (the SDK default, predictive back included),
/// or none at all when the system's "remove animations" is on (audit
/// 2026-10-03 A11y, SP1 §5.2).
final class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static final PageTransitionsBuilder _platform =
      const PageTransitionsTheme().builders[TargetPlatform.android]!;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _platform.delegatedTransition;

  @override
  Duration get transitionDuration => _platform.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _platform.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _platform.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
```

In `app_theme.dart` `_build`, add to `copyWith`:

```dart
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: AppPageTransitionsBuilder()},
    ),
```

- [ ] **Step 4: Run it, then the route tests**

Run: `flutter test test/core/theme/app_page_transitions_test.dart test/app --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_page_transitions.dart lib/core/theme/app_theme.dart test/core/theme/app_page_transitions_test.dart
git commit -m "fix(a11y): route transitions honour remove animations (SP1 §5.2)"
```

---

### Task 11: Component slots — progress indicator, text selection, reorder proxy

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart:90`
- Test: `test/core/theme/app_theme_test.dart` (create if absent), `test/features/deck/presentation/deck_reorder_list_widget_test.dart` (or the existing reorder test, found with `git ls-files test | grep -i reorder`)

**Interfaces:**
- Consumes: `AppOpacity.selection` (Task 6), `MxDerivedColors.primaryInkOf(ColorScheme)`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';

void main() {
  for (final (name, theme, scheme) in [
    ('light', buildLightTheme(), AppColorSchemes.light),
    ('dark', buildDarkTheme(), AppColorSchemes.dark),
  ]) {
    test('$name: refresh and selection use primary ink (audit Theming)', () {
      final ink = MxDerivedColors.primaryInkOf(scheme);
      expect(theme.progressIndicatorTheme.color, ink);
      expect(theme.textSelectionTheme.cursorColor, ink);
      expect(theme.textSelectionTheme.selectionHandleColor, ink);
      expect(
        theme.textSelectionTheme.selectionColor,
        scheme.primary.withValues(alpha: AppOpacity.selection),
      );
    });
  }
}
```

Reorder test: pump the reorder list as its existing test does, then assert the widget has a proxy decorator:

```dart
    expect(
      tester.widget<ReorderableListView>(find.byType(ReorderableListView)).proxyDecorator,
      isNotNull,
    );
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/app_theme_test.dart`, plus the reorder test file.
Expected: FAIL.

- [ ] **Step 3: Implement**

`app_theme.dart` `_build`:

```dart
    // The admin lists' RefreshIndicator and every text selection read in
    // primary ink, not Material's raw primary (audit 2026-10-03 Theming).
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: MxDerivedColors.primaryInkOf(scheme),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: MxDerivedColors.primaryInkOf(scheme),
      selectionHandleColor: MxDerivedColors.primaryInkOf(scheme),
      selectionColor: scheme.primary.withValues(alpha: AppOpacity.selection),
    ),
```

`deck_reorder_list_widget.dart`: add to `ReorderableListView.builder(`:

```dart
    // A dragged row stays flat, with the ghost edge, as the theme has no
    // elevation (audit 2026-10-03 Theming).
    proxyDecorator: (child, _, _) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.derivedColors.ghostBorder,
          width: AppStroke.hairline,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    ),
```

Add imports for `app_stroke.dart`, `app_radius.dart` and `theme_context.dart` if missing.

- [ ] **Step 4: Run them to verify they pass.** Same commands; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/features/deck test/core/theme/app_theme_test.dart test/features/deck
git commit -m "fix(theme): progress, text selection and the reorder proxy follow the system (SP1 §5.3)"
```

---

### Task 12: `MxChipTrigger` reads as a control and shows an active choice

**Files:**
- Modify: `lib/shared/widgets/mx_chip_trigger.dart`
- Test: `test/shared/widgets/mx_chip_trigger_test.dart`

**Interfaces:**
- Produces: `MxChipTrigger({…, bool isActive = false})`. SP3 and SP5 set it where a filter or sort holds a non-default choice.

- [ ] **Step 1: Write the failing tests**

```dart
  ButtonStyle style(WidgetTester tester) =>
      tester.widget<TextButton>(find.byType(TextButton)).style!;

  testWidgets('a hairline ghost edge at rest (critique 28)', (tester) async {
    await pumpMx(tester, MxChipTrigger(label: 'Level', onPressed: () {}));
    final side = style(tester).side!.resolve(const {})!;
    expect(side.width, AppStroke.hairline);
    expect(
      side.color,
      MxDerivedColors.resolve(AppColorSchemes.light, MxSemanticColors.light)
          .ghostBorder,
    );
  });

  testWidgets('active: primaryContainer ground, onPrimaryContainer ink', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxChipTrigger(label: 'Level · Error', isActive: true, onPressed: () {}),
    );
    final scheme = AppColorSchemes.light;
    expect(
      style(tester).backgroundColor!.resolve(const {}),
      scheme.primaryContainer,
    );
    expect(
      style(tester).foregroundColor!.resolve(const {}),
      scheme.onPrimaryContainer,
    );
  });
```

Add imports for `app_color_schemes.dart`, `mx_derived_colors.dart`, `mx_semantic_colors.dart` and `app_stroke.dart`.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_chip_trigger_test.dart`
Expected: FAIL (`isActive` is undefined; the side is none).

- [ ] **Step 3: Implement**

```dart
/// A chip that opens a menu (sort, filters). A ghost hairline marks it as a
/// control; while it holds a choice other than the default ([isActive]) it
/// fills with the primary container, so a filtered list says so
/// (critique 2026-10-02 screen 28, SP1 §5.3). The menu is the caller's.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.chevronDown,
    this.isActive = false,
  });
  …
  /// The chip holds a non-default choice.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: appButtonStyle(
        fill: isActive ? colors.primaryContainer : null,
        ink: isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        edge: isActive
            ? BorderSide.none
            : BorderSide(
                color: context.derivedColors.ghostBorder,
                width: AppStroke.hairline,
              ),
        focusColor: context.derivedColors.primaryInk,
        height: AppSize.chip,
        radius: AppRadius.full,
        padding: AppSpacing.control,
        label: context.textStyles.buttonLabelSmall,
      ),
      child: … unchanged …,
    );
  }
}
```

Check `appButtonStyle`'s parameter names in `lib/core/theme/app_button_style.dart` before editing.

- [ ] **Step 4: Run it, then the shared suite**

Run: `flutter test test/shared/widgets --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_chip_trigger.dart test/shared/widgets/mx_chip_trigger_test.dart
git commit -m "feat(ui): MxChipTrigger draws a ghost edge and an active state (SP1 §5.3)"
```

---

### Task 13: Haptics on selection start, grades and a Match pair

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_row_widget.dart:62`, `lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart:95`, `lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart:101`, `lib/features/study/presentation/widgets/sections/study_recall_widget.dart:261,270`, `lib/features/study/presentation/widgets/sections/study_match_widget.dart:128`
- Test: `test/features/card/presentation/card_row_widget_test.dart` (or the existing card row test), `test/features/study/presentation/study_recall_widget_test.dart` (or the existing recall test)

- [ ] **Step 1: Write the failing tests**

A shared recorder at the top of each test file:

```dart
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}
```

Card row (`test/features/card/presentation/card_row_test.dart`, which already has
`_item()`, `_host()` and `pumpLibraryScreen`):

```dart
  libraryTest('a long-press that starts a selection clicks (audit Platform)', (
    tester,
    env,
  ) async {
    final haptics = _recordHaptics(tester);
    var started = false;
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(
          item: _item(),
          isSelecting: false,
          isSelected: false,
          onLongPress: () => started = true,
        ),
      ]),
    );
    await tester.longPress(find.byType(CardRowWidget));
    expect(started, isTrue);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });
```

Recall (`test/features/study/presentation/study_recall_test.dart`, reusing its
`_recall`, `_screen` and `_settle` helpers):

```dart
  libraryTest('a grade gives a light tick (audit Platform)', (
    tester,
    env,
  ) async {
    final haptics = _recordHaptics(tester);
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);
    await tester.tap(find.text(_en.studyRecallRemembered));
    await _settle(tester);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });
```

Both files need `import 'package:flutter/services.dart';`.

- [ ] **Step 2: Run them to verify they fail.** Expected: FAIL (empty list).

- [ ] **Step 3: Implement** (add `import 'package:flutter/services.dart';` where needed)

`card_row_widget.dart` and `trash_entry_row_widget.dart`:

```dart
            onLongPress: switch (onLongPress) {
              null => null,
              // A selection begins: a tick under the thumb (audit Platform).
              final start => () {
                HapticFeedback.selectionClick();
                start();
              },
            },
```

`study_self_assess_widget.dart:101`:

```dart
                  onGrade: (grade) {
                    HapticFeedback.lightImpact();
                    widget.onGrade(grade);
                  },
```

`study_recall_widget.dart:261,270`: wrap each `widget.onAnswer(...)` as `() { HapticFeedback.lightImpact(); widget.onAnswer(RecallOutcome.forgot); }`, and the same for `remembered`, keeping the existing null branch.

`study_match_widget.dart:128`: `HapticFeedback.lightImpact();` on the line before `widget.onPair(termCardId, meaningCardId);`.

- [ ] **Step 4: Run them to verify they pass**

Run: the two test files, then `flutter test test/features/study test/features/card test/features/trash --exclude-tags golden`.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card lib/features/trash lib/features/study test/features/card test/features/study
git commit -m "feat(platform): haptics when a selection starts, a grade commits and a Match pair is made (SP1 §5.3)"
```

---

### Task 14: `DESIGN.md` rules and component records; WBS row

**Files:**
- Modify: `DESIGN.md`
- Modify: `docs/wbs_FE.md` (new row after FE-D26)

- [ ] **Step 1: Edit `DESIGN.md`**

1. Line 249, **Streak Orange**: append ` Its glyph uses **Streak Ink** (`streakInk`): pulled 20% toward `on-surface` in light (3:1 on the card and its tint), the colour itself in dark (SP1 2026-10-03).`
2. Line 315: replace `The bottom bar is translucent glass (surface at 84% with an 18 blur).` with `The bottom bar is translucent (surface at 84%), with no blur: it never sits over content.`
3. Line 335, **MxFooterBar**: replace `its caption at `AppOpacity.muted`` with `its caption in variant ink at full strength, 7.2:1 (owner R2, 2026-10-03)`. Also add `; `isHeld` holds a writing dialog against Back and the scrim; it rises above the keyboard` after `**MxDialog** (widths 340, 320, 300; scale-in`.
4. Line 339:
   - **MxToggle**: `(44x26 track, 20 thumb; the ON thumb is on-primary)`.
   - **MxChipTrigger**: `(chip that opens a menu: a ghost hairline at rest, the primary container while it holds a non-default choice)`.
   - **MxStepper**: append `; a typed value is handed over on a tap outside and when the screen is left`.
5. Line 342, **MxBottomNav**: `(translucent bar, outlined resting glyph, filled selected glyph, tinted pill; each destination reads "Tab n of m". Custom rather than Material's NavigationBar by owner ruling R4, 2026-10-03)`. Also append to **MxListSectionHeader** on line 354: ` (a TalkBack heading)`.
6. Under `## Colors`, after the Named Rules: add `**No Dynamic Color.** Material You's wallpaper scheme is not used: the authored Tokyo palette is the identity (SP1 2026-10-03).`
7. Under `### Do:` add these bullets:

```markdown
- **Do** show "no connection" as a neutral `MxNote`. Warning amber means a refusal, a limit or something not done; danger means a loss. Offline is never either (SP1 2026-10-03).
- **Do** let a note say something the screen does not already show, and place it after the decision it explains, never before it.
- **Do** name the loss on a destructive confirm: "Lose changes and continue", "Discard and continue", never a bare "Continue".
- **Do** give a footer caption a fact of its own: it never restates the button or contradicts the screen's state.
- **Do** keep an eyebrow inside the card it introduces.
```

8. Under `### Don't:` add:

```markdown
- **Don't** put an overline over a one-row group, unless it sets apart a destructive group.
- **Don't** lead every row with the same tile: a lead tile appears only when its glyph or tone varies with the row.
```

- [ ] **Step 2: Add the WBS row** after FE-D26 in `docs/wbs_FE.md` (Vietnamese, as the file is):

```markdown
| FE-D27 | UI hardening SP1 Foundations: MxDialog (bàn phím, hinge, `isHeld`), MxStepper commit, footer caption, heading, nav semantics, system bars, launch window, page transition, tint rungs, MxChipTrigger, haptics, luật DESIGN.md | xong | — | L | [spec](superpowers/specs/2026-10-03-ui-hardening-design.md), [plan](superpowers/plans/2026-10-03-ui-hardening-sp1-foundations.md); `dod_check.sh` xanh | SP2 |
```

- [ ] **Step 3: Check the docs**

Run: `python tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

- [ ] **Step 4: Commit**

```bash
git add DESIGN.md docs/wbs_FE.md
git commit -m "docs: SP1 rulings and component records in DESIGN.md; FE-D27 in the WBS"
```

---

### Task 15: Gate, goldens, golden review, the one audit

**Files:** goldens under `test/**/goldens/` (regenerated), nothing else unless the gate finds something.

- [ ] **Step 1: Run the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: green. Fix anything it reports in the task that owns it, and commit with `fix:`.

- [ ] **Step 2: Regenerate goldens in the Linux container**

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` (it must pass).

Expected movers:
- every screen with a footer caption (it is darker);
- screens with a `MxChipTrigger` (it gains an edge): Library sort, card list, Monitoring;
- dark screens with an ON toggle;
- Progress (the streak glyph);
- the nav bar only if the blur was visible (it should not be).

Anything else that moves is a defect: investigate it before going on.

- [ ] **Step 3: Commit the goldens**

```bash
git add test
git commit -m "test(goldens): regenerate for SP1 foundations"
```

- [ ] **Step 4: Golden review page.** Use the `golden-compare` skill on the changed PNGs and give the owner the before · after · diff page.

- [ ] **Step 5: One `impeccable audit`** of what SP1 changed (the shared widgets, theme, system bars). Fix whatever it finds in one batch, report it to the owner, and run no further audit.
