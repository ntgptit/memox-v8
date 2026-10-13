# Shared widgets mobile-native fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the six P2 findings of the 2026-10-08 mobile-native audit (DEV-302 … DEV-307 under epic DEV-301) so `MxBottomNav`, `MxBreadcrumb` and `MxEmptyState` pass the gate and the three list screens share one card row.

**Architecture:** Two shared widgets are added (`MxSelectableCardRow`, `MxScrollFade`), one shared helper replaces a row API (`MxDividedColumn` for `hasDivider`), one effect token and one derived colour go, and the card feature's selection state gains an explicit `isSelecting` so the deck's ⋮ can enter selection. Every fix lands in `lib/shared/` or `lib/core/theme/` first; callers change only to adopt it.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3 codegen (`dart run build_runner build --delete-conflicting-outputs`), the repo's widget harness (`test/support/widget_harness.dart`, `library_harness.dart`), `run_tests.sh`, `run_goldens.sh`, `dod_check.sh`.

**Spec:** `docs/superpowers/specs/2026-10-08-shared-widgets-mobile-native-fixes-design.md`

## Global Constraints

- Colours, spacing, radius, durations only from `lib/core/theme/` tokens; no `Color` or `TextStyle` parameter on a shared widget (components.md). The `check_design_tokens.py` hook runs on every edit.
- Every tappable control keeps a 48×48 target and an accessible name; text is never clamped.
- Components hold no copy: every label is a parameter; user-facing strings live in `lib/l10n/app_en.arb` and `app_vi.arb`.
- A `Semantics` node that excludes its children carries the tap and the long-press itself (SW-REV-005).
- Commit messages name the sub-issue (`fix(shared): DEV-302 …`) and end with the session's attribution lines. Each task sets its sub-issue In Progress on Linear when it starts (`save_issue`, `state: "In Progress"`).
- Goldens are regenerated only in the Linux container with `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, once, in Task 7, then reviewed on a `golden-compare` page.
- Tests run through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file…>`; never `flutter test` on a directory.

## Review Focus

1. A 10-level breadcrumb at 320 dp: the first ancestor is scrolled out of view but still a reachable, labelled TalkBack button; a fade shows on its edge (Task 3 test).
2. A Trash entry of the other kind while selecting: dimmed to 0.38, its tap and long-press blocked, its ⋮ gone, its label still read in full (Task 4 caller test).
3. "Select cards" from the deck's ⋮ with no card picked: the app bar shows "0 selected", the bulk bar shows, Close leaves selection, and unticking the last card keeps the mode (Task 5 tests).
4. A list that drew its own row dividers (search results, Study home decks, picker) after `hasDivider` goes: still n − 1 hairlines, none under the last row (Task 6 tests).
5. The bottom bar after the blur goes: the body still ends where the bar starts, the bar is the page surface, and the gallery renders every section at 320 dp without an exception (Task 1 and Task 7 tests).

---

### Task 1: `MxBottomNav` without glass (DEV-302)

**Files:**
- Modify: `lib/shared/widgets/mx_bottom_nav.dart:1-11, 26-28, 48-107`
- Modify: `lib/core/theme/foundations/app_effects.dart`
- Modify: `lib/core/theme/mx_derived_colors.dart:2, 21, 73-74, 214-215`
- Modify: `DESIGN.md:317, 344`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md:174, 178-181, 571` (register row 160)
- Test: `test/shared/widgets/mx_bottom_nav_test.dart:122-128`, `test/shared/widgets/mx_app_shell_test.dart`, `test/core/theme/foundations_test.dart:72-80`, `test/core/theme/mx_derived_colors_test.dart:104-107`

**Interfaces:**
- Produces: `AppEffects` keeps only `scrimOpacity`; `MxDerivedColors` loses `chromeGlass`. No caller outside the three files above reads them (verified: `grep -rn "chromeGlass\|glassBlur\|glassOpacity" lib test`).

- [ ] **Step 1: Set DEV-302 In Progress on Linear** (`save_issue`, `id: "DEV-302"`, `state: "In Progress"`).

- [ ] **Step 2: Write the failing tests**

In `test/shared/widgets/mx_bottom_nav_test.dart`, replace the test `'glass: a backdrop blur behind the chrome surface'` (lines 122–128) with:

```dart
  testWidgets('the bar is the page surface with the ghost edge, no backdrop '
      'blur: nothing scrolls under it (DEV-302)', (tester) async {
    await pumpMx(tester, _nav());

    expect(find.byType(BackdropFilter), findsNothing);
    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxBottomNav),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((bar.decoration as BoxDecoration).color, scheme.surface);
  });
```

In `test/shared/widgets/mx_app_shell_test.dart`, add the import `import 'package:memox/shared/widgets/mx_bottom_nav.dart';` and this test at the end of `main`:

```dart
  testWidgets('the bottom bar sits below the body, never over it (DEV-302)', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      MxAppShell(
        body: const SizedBox.expand(key: _bodyKey),
        bottomBar: MxBottomNav(
          key: _barKey,
          destinations: const [
            MxNavDestination(
              icon: AppIcons.library,
              selectedIcon: AppIcons.librarySelected,
              label: 'Library',
            ),
            MxNavDestination(
              icon: AppIcons.study,
              selectedIcon: AppIcons.studySelected,
              label: 'Study',
            ),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );

    expect(
      tester.getBottomLeft(find.byKey(_bodyKey)).dy,
      tester.getTopLeft(find.byKey(_barKey)).dy,
    );
  });
```

(If `_barKey` is already bound to another helper in that file, add `const _navKey = Key('nav');` and use it instead.)

In `test/core/theme/foundations_test.dart`, rename the test at line 72 to `'strokes and state opacities'` and delete the two `AppEffects.glass…` expectations (keep the `AppEffects.scrimOpacity` one at line 101 and the import). In `test/core/theme/mx_derived_colors_test.dart`, delete the test `'chromeGlass is surface at the glass opacity, not pre-flattened'`.

- [ ] **Step 3: Run them and see them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_bottom_nav_test.dart test/shared/widgets/mx_app_shell_test.dart`
Expected: the bottom nav test fails on `findsNothing` (a `BackdropFilter` is still there); the shell test passes already (it pins the decision).

- [ ] **Step 4: Implement**

`lib/shared/widgets/mx_bottom_nav.dart`: delete `import 'dart:ui';` and the `app_effects.dart` import; change the class doc to "The top-level destinations on a bar of the page surface with the ghost edge, a tinted pill behind the current glyph. It is in-flow, never over the scroll, and adds the gesture inset below itself."; replace the `ClipRRect` subtree so it reads:

```dart
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: radius,
            border: Border.all(
              color: derived.ghostBorder,
              width: AppStroke.hairline,
            ),
          ),
          // Ruling R3: 64 at minimum, grows with text scaling.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.bottomNavBar),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  for (final (index, destination) in destinations.indexed)
                    Expanded(
                      child: _Item(
                        destination: destination,
                        isSelected: index == selectedIndex,
                        pillTint: pillTint,
                        onTap: () => onSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
```

`lib/core/theme/foundations/app_effects.dart` becomes:

```dart
/// Visual effect configuration (02-theme-binding EFFECT_TOKEN). Translucency,
/// not interaction, so it lives outside AppOpacity. The bottom bar's glass
/// (opacity and blur) went with DEV-302: nothing scrolled under it.
abstract final class AppEffects {
  /// Alpha of the `scrim` behind a dialog or a bottom sheet (spec §5, O8).
  static const double scrimOpacity = 0.45;
}
```

`lib/core/theme/mx_derived_colors.dart`: remove the `app_effects.dart` import, the `chromeGlass` constructor parameter, its `resolve` line (with the comment above it) and its field with its doc.

- [ ] **Step 5: Run the tests and see them pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_bottom_nav_test.dart test/shared/widgets/mx_app_shell_test.dart test/core/theme/foundations_test.dart test/core/theme/mx_derived_colors_test.dart test/app/gallery_test.dart`
Expected: all pass. Then `flutter analyze lib test` reports no error.

- [ ] **Step 6: Documents**

`DESIGN.md` line 317: replace "- **Scrim** (scheme `scrim` at 45%): behind every dialog and sheet. The bottom bar is translucent glass (surface at 84% with an 18 blur)." with "- **Scrim** (scheme `scrim` at 45%): behind every dialog and sheet. The bottom bar is the page surface with the ghost edge: it floats over nothing, since the body ends where it starts (audit 2026-10-08, DEV-302)."
`DESIGN.md` line 344: "**MxBottomNav** (glass bar, outlined resting glyph, …)" → "**MxBottomNav** (surface bar with the ghost edge, outlined resting glyph, …)".
UI-base spec line 174: `| \`AppEffects\` | scrimOpacity 0.45 (effect token, kept out of the state layer); glassOpacity and glassBlur went with DEV-302 |`. Lines 178–181: replace the glass paragraph with "The bottom nav was translucent `chromeGlass` plus a `BackdropFilter` blur 18 until DEV-302 (audit 2026-10-08): the bar is an in-flow sibling of the body, so the blur had nothing under it and the bar is now the page surface with the ghost edge." Append register row: `| 160 | The bottom bar's glass blur blurred nothing (the body ends where the bar starts) — closed by DEV-302 (spec \`2026-10-08-shared-widgets-mobile-native-fixes-design.md\` §3.1): the bar is the page surface with the ghost edge; \`AppEffects.glassOpacity\`, \`glassBlur\` and \`MxDerivedColors.chromeGlass\` removed | audit 2026-10-08 F-01 |`.
Run `python3 tools/docs/check.py` → PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/mx_bottom_nav.dart lib/core/theme/foundations/app_effects.dart lib/core/theme/mx_derived_colors.dart test/shared/widgets/mx_bottom_nav_test.dart test/shared/widgets/mx_app_shell_test.dart test/core/theme/foundations_test.dart test/core/theme/mx_derived_colors_test.dart DESIGN.md docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
git commit -m "fix(shared): DEV-302 MxBottomNav drops the backdrop blur nothing scrolled under"
```

---

### Task 2: `MxEmptyState` footnote as a hint (DEV-303)

**Files:**
- Modify: `lib/shared/widgets/mx_empty_state.dart:63-64, 157-160`
- Modify: `DESIGN.md:337` (the `MxNote` clause)
- Test: `test/shared/widgets/mx_empty_state_test.dart:110-127`

- [ ] **Step 1: Set DEV-303 In Progress on Linear.**

- [ ] **Step 2: Write the failing test**

In `mx_empty_state_test.dart`, inside the test `'a footnote sits 20 below the action as a note'`, add after the existing `expect`:

```dart
    // The footnote form, with no fill and no edge: a boxed note inside the
    // raised card was two ghost edges in dark (audit 2026-10-08 F-02).
    expect(tester.widget<MxNote>(find.byType(MxNote)).isHint, isTrue);
```

- [ ] **Step 3: Run it and see it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_empty_state_test.dart`
Expected: FAIL, `isHint` is false.

- [ ] **Step 4: Implement**

`mx_empty_state.dart` line 63–64 doc: "A product rule under the action, in the footnote form (`MxNote.hint`, ruling S19; a boxed note inside the card was two edges in dark, audit 2026-10-08 F-02)." Line 159: `MxNote(text: rule),` → `MxNote.hint(text: rule),`.

- [ ] **Step 5: Run and see it pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_empty_state_test.dart test/app/gallery_test.dart`
Expected: PASS.

- [ ] **Step 6: Document**

`DESIGN.md` line 337, in the `MxNote` clause after "`MxNote.hint` is the footnote form with no fill and no border)": insert ", and the one form for a footnote under a card, a section or an empty state (`MxSection.note`, `MxEmptyState.footnote`); the boxed note stands on its own in the flow, never inside another surface (DEV-303)". Run `python3 tools/docs/check.py`.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/mx_empty_state.dart test/shared/widgets/mx_empty_state_test.dart DESIGN.md
git commit -m "fix(shared): DEV-303 MxEmptyState footnote is the hint note, not a box in the card"
```

---

### Task 3: `MxScrollFade` replaces the study fade and marks horizontal scrolls (DEV-306)

**Files:**
- Create: `lib/shared/widgets/mx_scroll_fade.dart`
- Delete: `lib/features/study/presentation/widgets/support/study_scroll_fade_widget.dart`
- Modify: `lib/features/study/presentation/widgets/support/study_face_card_widget.dart:5, 45-55`, `lib/features/study/presentation/widgets/sections/study_browse_widget.dart:302-303`, `study_guess_widget.dart:134`, `study_match_widget.dart:140` (imports too)
- Modify: `lib/shared/widgets/mx_breadcrumb.dart:34-37`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart:93-96`
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_filter_bar_widget.dart:46-49`
- Modify: `DESIGN.md:344` (Navigation: `MxBreadcrumb`), the Components list (add `MxScrollFade` to Containers)
- Create: `test/shared/widgets/mx_scroll_fade_test.dart`
- Modify: `test/features/study/presentation/study_support_widgets_test.dart:114, 130`, `study_match_test.dart:416`, `study_guess_test.dart:198`, `test/shared/widgets/mx_breadcrumb_test.dart`

**Interfaces:**
- Produces: `enum MxScrollFadeGround { page, raised, recessed }`; `MxScrollFade({required Widget child, Axis axis = Axis.vertical, MxScrollFadeGround ground = MxScrollFadeGround.page})`; test keys `MxScrollFade.leadingKey`, `MxScrollFade.trailingKey`.

- [ ] **Step 1: Set DEV-306 In Progress on Linear.**

- [ ] **Step 2: Write the failing tests**

Create `test/shared/widgets/mx_scroll_fade_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../support/widget_harness.dart';

Widget _horizontal({double content = 600, bool reverse = false}) => SizedBox(
  width: 200,
  height: 48,
  child: MxScrollFade(
    axis: Axis.horizontal,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: reverse,
      child: SizedBox(width: content, height: 48),
    ),
  ),
);

Widget _vertical({
  double content = 600,
  MxScrollFadeGround ground = MxScrollFadeGround.page,
}) => SizedBox(
  width: 200,
  height: 200,
  child: MxScrollFade(
    ground: ground,
    child: SingleChildScrollView(child: SizedBox(width: 200, height: content)),
  ),
);

Color _lastStop(WidgetTester tester, Key key) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
  );
  return ((box.decoration as BoxDecoration).gradient! as LinearGradient)
      .colors
      .last;
}

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('content that fits shows no fade', (tester) async {
    await pumpMx(tester, _horizontal(content: 100));
    await tester.pump();

    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('horizontal: the edge with more content fades, and follows the '
      'scroll', (tester) async {
    await pumpMx(tester, _horizontal());
    await tester.pump();
    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(-1000, 0));
    await tester.pump();
    expect(find.byKey(MxScrollFade.leadingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('a reversed horizontal scroll opens at its end: the start edge '
      'fades (MxBreadcrumb)', (tester) async {
    await pumpMx(tester, _horizontal(reverse: true));
    await tester.pump();

    expect(find.byKey(MxScrollFade.leadingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('vertical: only the bottom edge fades while more lies below', (
    tester,
  ) async {
    await pumpMx(tester, _vertical());
    await tester.pump();
    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);
    expect(tester.getSize(find.byKey(MxScrollFade.trailingKey)).height, 24);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1000));
    await tester.pump();
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
  });

  testWidgets('the fade dissolves into its ground and takes no taps', (
    tester,
  ) async {
    await pumpMx(tester, _vertical(ground: MxScrollFadeGround.recessed));
    await tester.pump();

    expect(
      _lastStop(tester, MxScrollFade.trailingKey),
      scheme.surfaceContainerLow,
    );
    expect(
      find.descendant(
        of: find.byKey(MxScrollFade.trailingKey),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });
}
```

In `test/shared/widgets/mx_breadcrumb_test.dart`, add the import `import 'package:memox/shared/widgets/mx_scroll_fade.dart';` and the test:

```dart
  testWidgets('a deep path fades its start edge and keeps its hidden '
      'ancestors reachable (DEV-306)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(10))),
    );
    await tester.pump();

    expect(find.byKey(MxScrollFade.leadingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.trailingKey), findsNothing);
    expect(
      tester.getSemantics(find.text('Level 1', skipOffstage: false)),
      isSemantics(label: 'Level 1', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
```

Change the three study assertions: `find.byKey(const ValueKey('study-scroll-fade'))` → `find.byKey(MxScrollFade.trailingKey)` in `study_support_widgets_test.dart` (lines 114, 130), `study_match_test.dart:416`, `study_guess_test.dart:198`, adding the import of `mx_scroll_fade.dart` to each.

- [ ] **Step 3: Run them and see them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_scroll_fade_test.dart test/shared/widgets/mx_breadcrumb_test.dart`
Expected: compile failure (no `MxScrollFade`).

- [ ] **Step 4: Implement the shared widget**

Create `lib/shared/widgets/mx_scroll_fade.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The ground a fade dissolves into: the page, a raised card, or the
/// recessed answer face.
enum MxScrollFadeGround { page, raised, recessed }

/// A soft fade over the edge of a scroll view while more of it lies past
/// that edge, so a cut row or chip reads as "scroll for more" (study faces,
/// FE-A6 P3 C4; breadcrumb and chip rows, audit 2026-10-08 F-05). Vertical,
/// it fades the bottom; horizontal, each edge that still has content, in the
/// scroll's own direction, so a reversed view fades the right side.
/// Decorative: it takes no taps and says nothing to TalkBack.
class MxScrollFade extends StatefulWidget {
  const MxScrollFade({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.ground = MxScrollFadeGround.page,
  });

  /// A scroll view, or a tree with one scroll view on [axis].
  final Widget child;
  final Axis axis;
  final MxScrollFadeGround ground;

  /// The fade over the start edge (left, or top), for tests.
  @visibleForTesting
  static const Key leadingKey = ValueKey('mx-scroll-fade-leading');

  /// The fade over the end edge (right, or bottom), for tests.
  @visibleForTesting
  static const Key trailingKey = ValueKey('mx-scroll-fade-trailing');

  static const double _extent = AppSpacing.section;

  @override
  State<MxScrollFade> createState() => _MxScrollFadeState();
}

class _MxScrollFadeState extends State<MxScrollFade> {
  var _hasMoreBefore = false;
  var _hasMoreAfter = false;
  var _direction = AxisDirection.down;

  bool _onMetrics(ScrollMetrics metrics) {
    if (metrics.axis != widget.axis) return false;
    final before = metrics.extentBefore > 0;
    final after = metrics.extentAfter > 0;
    final direction = metrics.axisDirection;
    if (before == _hasMoreBefore &&
        after == _hasMoreAfter &&
        direction == _direction) {
      return false;
    }
    setState(() {
      _hasMoreBefore = before;
      _hasMoreAfter = after;
      _direction = direction;
    });
    return false;
  }

  /// Whether the start edge (left or top) and the end edge (right or
  /// bottom) still hide content. A reversed view counts "after" at its
  /// start. The vertical form fades the bottom only.
  (bool, bool) _edges() {
    final isReversed =
        _direction == AxisDirection.up || _direction == AxisDirection.left;
    final (start, end) = isReversed
        ? (_hasMoreAfter, _hasMoreBefore)
        : (_hasMoreBefore, _hasMoreAfter);
    if (widget.axis == Axis.vertical) return (false, end);
    return (start, end);
  }

  Color _ground(BuildContext context) => switch (widget.ground) {
    MxScrollFadeGround.page => context.colors.surface,
    MxScrollFadeGround.raised => context.colors.surfaceContainerLowest,
    MxScrollFadeGround.recessed => context.colors.surfaceContainerLow,
  };

  @override
  Widget build(BuildContext context) {
    final ground = _ground(context);
    final (fadeStart, fadeEnd) = _edges();
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) => _onMetrics(notification.metrics),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => _onMetrics(notification.metrics),
            child: widget.child,
          ),
        ),
        if (fadeStart)
          _Fade(
            key: MxScrollFade.leadingKey,
            axis: widget.axis,
            isAtEnd: false,
            ground: ground,
          ),
        if (fadeEnd)
          _Fade(
            key: MxScrollFade.trailingKey,
            axis: widget.axis,
            isAtEnd: true,
            ground: ground,
          ),
      ],
    );
  }
}

/// One edge's fade: from the ground at the edge to clear toward the content.
class _Fade extends StatelessWidget {
  const _Fade({
    super.key,
    required this.axis,
    required this.isAtEnd,
    required this.ground,
  });

  final Axis axis;
  final bool isAtEnd;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    final clear = ground.withValues(alpha: 0);
    final gradient = LinearGradient(
      begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
      end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: isAtEnd ? [clear, ground] : [ground, clear],
    );
    return Positioned(
      left: isVertical || !isAtEnd ? 0 : null,
      right: isVertical || isAtEnd ? 0 : null,
      top: !isVertical || !isAtEnd ? 0 : null,
      bottom: !isVertical || isAtEnd ? 0 : null,
      width: isVertical ? null : MxScrollFade._extent,
      height: isVertical ? MxScrollFade._extent : null,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Migrate the callers and delete the study copy**

- `study_face_card_widget.dart`: import `package:memox/shared/widgets/mx_scroll_fade.dart` instead of the study fade; lines 45–55 become `child: MxScrollFade(ground: isAnswer ? MxScrollFadeGround.recessed : MxScrollFadeGround.raised, child: Center(…))`.
- `study_browse_widget.dart:302-303`: `StudyScrollFadeWidget(ground: context.colors.surfaceContainerLowest, …)` → `MxScrollFade(ground: MxScrollFadeGround.raised, …)`; fix the import.
- `study_guess_widget.dart:134` and `study_match_widget.dart:140`: `StudyScrollFadeWidget(` → `MxScrollFade(`; fix the imports.
- `git rm lib/features/study/presentation/widgets/support/study_scroll_fade_widget.dart`.
- `mx_breadcrumb.dart`: add the import and wrap the scroll view: `builder: (context, constraints) => MxScrollFade(axis: Axis.horizontal, child: SingleChildScrollView(…unchanged…))`. Extend the class doc: "A deep path fades its start edge while ancestors are scrolled out of view (DEV-306)."
- `card_list_toolbar_widget.dart:93-96`: `child: MxScrollFade(axis: Axis.horizontal, child: SingleChildScrollView(…))`; import.
- `monitoring_filter_bar_widget.dart:46`: `return MxScrollFade(axis: Axis.horizontal, child: SingleChildScrollView(…))`; import.

- [ ] **Step 6: Run the tests and see them pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_scroll_fade_test.dart test/shared/widgets/mx_breadcrumb_test.dart test/features/study/presentation/study_support_widgets_test.dart test/features/study/presentation/study_match_test.dart test/features/study/presentation/study_guess_test.dart test/features/study/presentation/study_browse_test.dart test/features/card/presentation/card_list_layout_test.dart test/features/monitoring/presentation/monitoring_filters_test.dart`
Expected: PASS (if a study browse test file has another name, run `ls test/features/study/presentation | grep browse` and use it). Then `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` passes.

- [ ] **Step 7: Document**

`DESIGN.md` Containers (line 337), append to the end of the bullet: ", **MxScrollFade** (a 24 fade over the edge of a scroll view while more lies past it: the bottom of a study face, both ends of a horizontal row such as the breadcrumb or a chip row; it takes no taps, DEV-306)". Navigation (line 344) `MxBreadcrumb`: add "; a deep path fades its start edge, its hidden ancestors still reachable to TalkBack". Run `python3 tools/docs/check.py`.

- [ ] **Step 8: Commit**

```bash
git add lib/shared/widgets/mx_scroll_fade.dart lib/shared/widgets/mx_breadcrumb.dart lib/features/study lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart lib/features/monitoring/presentation/widgets/sections/monitoring_filter_bar_widget.dart test/shared/widgets/mx_scroll_fade_test.dart test/shared/widgets/mx_breadcrumb_test.dart test/features/study DESIGN.md
git commit -m "feat(shared): DEV-306 MxScrollFade marks a cut edge on the breadcrumb, chip rows and study faces"
```

---

### Task 4: `MxSelectableCardRow` and its three callers (DEV-304)

**Files:**
- Create: `lib/shared/widgets/mx_selectable_card_row.dart`
- Modify: `lib/features/deck/presentation/widgets/items/deck_row_widget.dart:31-93`, `lib/features/card/presentation/widgets/items/card_row_widget.dart:38-75`, `lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart:45-130`
- Modify: `lib/app/gallery/gallery_surfaces_section.dart` (two rows after the selected card), `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`gallerySelectableRow`, `gallerySelectableRowPicked`)
- Modify: `test/shared/widgets/surface_widgets_golden_test.dart` (new golden `mx_selectable_card_row`)
- Modify: `DESIGN.md:356` (Data Display)
- Create: `test/shared/widgets/mx_selectable_card_row_test.dart`
- Test: `test/features/deck/presentation/deck_row_widget_test.dart`, `test/features/card/presentation/card_row_test.dart`, `test/features/trash/presentation/trash_selection_test.dart`

**Interfaces:**
- Produces: `MxSelectableCardRow({required Widget child, VoidCallback? onTap, VoidCallback? onLongPress, bool isSelecting = false, bool isSelected = false, bool isEnabled = true, Widget? trailing, String? semanticLabel})`.

- [ ] **Step 1: Set DEV-304 In Progress on Linear.**

- [ ] **Step 2: Write the failing shared test**

Create `test/shared/widgets/mx_selectable_card_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_selectable_card_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../support/widget_harness.dart';

Widget _row({
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool isSelecting = false,
  bool isSelected = false,
  bool isEnabled = true,
  Widget? trailing,
  String? semanticLabel,
}) => SizedBox(
  width: 360,
  child: MxSelectableCardRow(
    onTap: onTap,
    onLongPress: onLongPress,
    isSelecting: isSelecting,
    isSelected: isSelected,
    isEnabled: isEnabled,
    trailing: trailing,
    semanticLabel: semanticLabel,
    child: const Text('Korean'),
  ),
);

void main() {
  testWidgets('a tap opens and a long-press selects; the content sits 16 in '
      'and 12 down (M3-D1)', (tester) async {
    var taps = 0;
    var holds = 0;
    await pumpMx(tester, _row(onTap: () => taps++, onLongPress: () => holds++));
    await tester.tap(find.text('Korean'));
    await tester.longPress(find.text('Korean'));

    expect((taps, holds), (1, 1));
    final card = tester.getTopLeft(find.byType(MxCard));
    final text = tester.getTopLeft(find.text('Korean'));
    expect(text.dx - card.dx, 16);
    expect(text.dy - card.dy, 12);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  testWidgets('selecting shows the checkbox, ticked when selected, centred '
      'on the card with the trailing control', (tester) async {
    await pumpMx(
      tester,
      _row(
        onTap: () {},
        isSelecting: true,
        isSelected: true,
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More',
          onPressed: () {},
        ),
      ),
    );

    expect(
      tester.widget<MxSelectionCheckbox>(find.byType(MxSelectionCheckbox)).isChecked,
      isTrue,
    );
    expect(
      tester.widget<MxCard>(find.byType(MxCard)).isSelected,
      isTrue,
    );
    expectCentredOn(tester, find.byType(MxCard), [
      find.byType(MxSelectionCheckbox),
      find.byType(MxIconButton),
    ]);
  });

  testWidgets('with a label, one node carries the label, the checked state, '
      'the tap and the long-press; the trailing control stays its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var more = 0;
    await pumpMx(
      tester,
      _row(
        onTap: () {},
        onLongPress: () {},
        isSelecting: true,
        semanticLabel: 'Korean, 6 cards',
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More',
          onPressed: () => more++,
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Korean, 6 cards')),
      isSemantics(
        label: 'Korean, 6 cards',
        isChecked: false,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    expect(find.text('Korean'), findsOneWidget);
    await tester.tap(find.byTooltip('More'));
    expect(more, 1);
    handle.dispose();
  });

  testWidgets('without a label, the content is read with the checked state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _row(onTap: () {}, isSelecting: true, isSelected: true));

    expect(
      tester.getSemantics(find.text('Korean')),
      isSemantics(label: 'Korean', isChecked: true),
    );
    handle.dispose();
  });

  testWidgets('disabled: dimmed to 0.38, no tap, no long-press, no trailing '
      'needed', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      _row(onTap: () => taps++, isSelecting: true, isEnabled: false),
    );
    await tester.tap(find.text('Korean'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      closeTo(0.38, 0.001),
    );
  });

  testWidgets('tappable row and trailing control are 48 targets with names', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _row(
        onTap: () {},
        semanticLabel: 'Korean',
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: 'More',
          onPressed: () {},
        ),
      ),
    );
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 3: Run it and see it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_selectable_card_row_test.dart`
Expected: compile failure (no `MxSelectableCardRow`).

- [ ] **Step 4: Implement the shared widget**

Create `lib/shared/widgets/mx_selectable_card_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

/// One item of a list drawn as a card the person can open, long-press into
/// selection and tick: a deck (screen 01), a card (07), a Trash entry (06).
/// The frame is shared, the content is the caller's (audit 2026-10-08 F-03,
/// DEV-304): the raised card, the ink over all of it, the checkbox while
/// selecting, 16 in and 12 down, and one TalkBack node. [trailing] (a ⋮)
/// sits outside the ink, 4 from the edge, and keeps its own node and tap.
class MxSelectableCardRow extends StatelessWidget {
  const MxSelectableCardRow({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelecting = false,
    this.isSelected = false,
    this.isEnabled = true,
    this.trailing,
    this.semanticLabel,
  }) : assert(!isSelected || isSelecting, 'a selected row is selecting');

  final Widget child;

  /// Opens the item, or toggles it while selecting.
  final VoidCallback? onTap;

  /// Starts the selection with this item (BR-CARD-020, Trash spec D8).
  final VoidCallback? onLongPress;

  /// The list is selecting: the checkbox leads the content.
  final bool isSelecting;
  final bool isSelected;

  /// False dims the whole card to the disabled opacity and blocks its taps:
  /// an item that cannot join the selection (BR-TRASH-011).
  final bool isEnabled;

  /// A control of the item's own, usually an MxIconButton; outside the ink.
  final Widget? trailing;

  /// One sentence for TalkBack in place of the content, when the content
  /// is cut or scattered (the Trash entry, spec D15). Without it the
  /// content's own text is read, with the checked state.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final canAct = isEnabled;
    final ink = MxRowInk(
      onTap: onTap,
      onLongPress: onLongPress,
      isEnabled: canAct,
      shouldDimWhenDisabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
        ),
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            if (isSelecting) MxSelectionCheckbox(isChecked: isSelected),
            Expanded(child: child),
          ],
        ),
      ),
    );
    final checked = isSelecting ? isSelected : null;
    final target = switch (semanticLabel) {
      null => MergeSemantics(
        child: Semantics(checked: checked, child: ink),
      ),
      // The excluded content's actions, kept on this one node (SW-REV-005).
      final label => Semantics(
        container: true,
        excludeSemantics: true,
        button: !isSelecting,
        checked: checked,
        enabled: canAct && onTap != null,
        label: label,
        onTap: canAct ? onTap : null,
        onLongPress: canAct ? onLongPress : null,
        child: ink,
      ),
    };
    final trailing = this.trailing;
    final card = MxCard(
      isFullBleed: true,
      isSelected: isSelected,
      child: trailing == null
          ? target
          : Row(
              children: [
                Expanded(child: target),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: AppSpacing.micro,
                  ),
                  child: trailing,
                ),
              ],
            ),
    );
    if (canAct) return card;
    return Opacity(opacity: AppOpacity.disabled, child: card);
  }
}
```

- [ ] **Step 5: Run the shared test and see it pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_selectable_card_row_test.dart`
Expected: PASS. If the "without a label" test reads a merged label other than `Korean` (the checkbox has no label, so it should be `Korean`), adjust the expectation to the merged string the test prints, as long as it starts with `Korean`.

- [ ] **Step 6: Migrate the deck row**

`deck_row_widget.dart`: replace the imports of `mx_card.dart` and `mx_row_ink.dart` with `mx_selectable_card_row.dart`; the build becomes:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSelectableCardRow(
      onTap: onTap,
      trailing: MxIconButton(
        icon: AppIcons.more,
        semanticLabel: l10n.deckMoreActions(tile.name),
        onPressed: onMore,
      ),
      child: Row(
        spacing: AppSpacing.gutter,
        children: [
          MxIconTile(icon: deckTileGlyph(tile), size: MxIconTileSize.large),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.grouped,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Row(
                      spacing: AppSpacing.control,
                      children: [
                        Expanded(
                          child: Text(
                            tile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.rowTitle,
                          ),
                        ),
                        if (tile.dueCount > 0)
                          MxBadge(label: l10n.deckDueBadge(tile.dueCount)),
                      ],
                    ),
                    Text(
                      deckTileMeta(tile, l10n),
                      style: context.textStyles.rowSubtitle,
                    ),
                  ],
                ),
                _MasteryBar(fraction: tile.masteryFraction),
              ],
            ),
          ),
        ],
      ),
    );
  }
```

Update the class doc: "… and ⋮ for its commands, outside the row's ink (DEV-304). A tap anywhere else opens it." Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_row_widget_test.dart test/features/deck/presentation/deck_level_screen_test.dart` (use `ls test/features/deck/presentation` for the screen test's name); an assertion of the old 16 vertical padding, if any, moves to 12 with a comment "ruling D1 (DEV-304)".

- [ ] **Step 7: Migrate the card row**

`card_row_widget.dart`: imports: drop `mx_card.dart`, `mx_row_ink.dart`, `mx_selection_checkbox.dart`; add `mx_selectable_card_row.dart`. The build becomes:

```dart
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.control),
    // The frame is the shared card row (DEV-304): the checkbox while
    // selecting, the ink, 16/12 and one node with the checked state. No
    // status dot: the status line states it once (critique 2026-09-30 part
    // 3b, R3).
    child: MxSelectableCardRow(
      onTap: onTap,
      onLongPress: onLongPress,
      isSelecting: isSelecting,
      isSelected: isSelected,
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          Expanded(child: _Content(item: item)),
          _Trailing(item: item),
        ],
      ),
    ),
  );
```

Keep `_Content` and `_Trailing` as they are. Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card/presentation/card_row_test.dart test/features/card/presentation/card_list_layout_test.dart test/features/card/presentation/card_list_selection_test.dart` (check the last name with `ls test/features/card/presentation | grep select`).

- [ ] **Step 8: Migrate the Trash row**

`trash_entry_row_widget.dart`: imports: drop `mx_card.dart`, `mx_row_ink.dart`, `mx_selection_checkbox.dart`, `app_opacity.dart`; add `mx_selectable_card_row.dart`. From `final lines = Row(` to the end of `build`, replace with:

```dart
    // While selecting, an entry of the other kind cannot be picked
    // (BR-TRASH-011): the shared row dims it and blocks its taps.
    final isLocked = isSelecting && onTap == null;
    final onActions = this.onActions;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxSelectableCardRow(
        onTap: onTap,
        onLongPress: onLongPress,
        isSelecting: isSelecting,
        isSelected: isSelected,
        isEnabled: !isLocked,
        // One TalkBack node with every fact, whatever the ellipsis hides
        // (spec D15); the ⋮ stays its own control.
        semanticLabel: l10n.trashEntrySemantics(name, meta, timeLeft, origin),
        trailing: onActions == null || isSelecting
            ? null
            : MxIconButton(
                icon: AppIcons.more,
                semanticLabel: l10n.trashEntryActions(name),
                onPressed: onActions,
              ),
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            // The kind's tile; while selecting the shared row's checkbox
            // takes its place (spec 2026-09-26 D4).
            if (!isSelecting)
              MxIconTile(
                icon: entry is TrashDeckEntry
                    ? AppIcons.library
                    : AppIcons.cardDeck,
              ),
            Expanded(
              child: _Lines(
                name: name,
                timeLeft: timeLeft,
                isExpiringSoon: isTrashExpiringSoon(entry, now),
                meta: meta,
                origin: origin,
              ),
            ),
          ],
        ),
      ),
    );
```

Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/trash/presentation/trash_selection_test.dart test/features/trash/presentation/trash_screen_test.dart`.

- [ ] **Step 9: Golden and gallery**

`surface_widgets_golden_test.dart`: add the imports of `mx_selectable_card_row.dart` and `package:memox/core/theme/theme_context.dart`, a private content widget and the test:

```dart
/// A deck-like content for the shared card row's golden.
class _RowContent extends StatelessWidget {
  const _RowContent(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      const MxIconTile(icon: AppIcons.library),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textStyles.rowTitle),
            Text(subtitle, style: context.textStyles.rowSubtitle),
          ],
        ),
      ),
    ],
  );
}

  testWidgets('MxSelectableCardRow resting, selecting, selected, locked', (
    tester,
  ) async {
    await expectThemedGoldens(
      tester,
      'mx_selectable_card_row',
      Column(
        spacing: 8,
        children: [
          MxSelectableCardRow(
            onTap: () {},
            trailing: MxIconButton(
              icon: AppIcons.more,
              semanticLabel: 'Deck actions',
              onPressed: () {},
            ),
            child: const _RowContent('Korean', '1 sub-deck · 6 cards'),
          ),
          MxSelectableCardRow(
            onTap: () {},
            isSelecting: true,
            child: const _RowContent('Kanji N5', '2 cards'),
          ),
          MxSelectableCardRow(
            onTap: () {},
            isSelecting: true,
            isSelected: true,
            child: const _RowContent('Hanja', '1 card'),
          ),
          const MxSelectableCardRow(
            isSelecting: true,
            isEnabled: false,
            child: _RowContent('Basics', 'Deck · cannot join a card pick'),
          ),
        ],
      ),
    );
  });
```

ARB: in `app_en.arb` next to the other `gallery…` keys add `"gallerySelectableRow": "Selectable card row"`, `"@gallerySelectableRow": {"description": "Gallery: the shared card row at rest."}`, `"gallerySelectableRowPicked": "Picked while selecting"`, `"@gallerySelectableRowPicked": {"description": "Gallery: the shared card row ticked."}`; in `app_vi.arb`: `"gallerySelectableRow": "Hàng card chọn được"`, `"gallerySelectableRowPicked": "Đã chọn khi đang chọn"`. In `gallery_surfaces_section.dart` after the `isSelected` card add:

```dart
      MxSelectableCardRow(
        onTap: () {},
        trailing: MxIconButton(
          icon: AppIcons.more,
          semanticLabel: context.l10n.galleryDeckActions,
          onPressed: () {},
        ),
        child: Text(context.l10n.gallerySelectableRow),
      ),
      MxSelectableCardRow(
        onTap: () {},
        isSelecting: true,
        isSelected: true,
        child: Text(context.l10n.gallerySelectableRowPicked),
      ),
```

(`galleryDeckActions` exists if the gallery already names a ⋮; otherwise use the existing key the list row sample uses in that file.) Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/gallery_test.dart test/l10n`.

- [ ] **Step 10: Document and commit**

`DESIGN.md` line 356 (Data Display), before `**MxListRow**`: "**MxSelectableCardRow** (the card that is one item of a list: the raised card, the ink over all of it, the checkbox while selecting, 16 in and 12 down, one TalkBack node with the checked state, a ⋮ outside the ink 4 from the edge; the deck, card and Trash rows are its content, DEV-304), ". Screen detail files: `01-deck-list.md` Rows row: "`MxSelectableCardRow` per deck, 8 apart"; `07-card-list.md` Rows: "`MxSelectableCardRow` per row"; `06-trash.md` Rows: "`MxSelectableCardRow` per entry". Run `python3 tools/docs/check.py`.

```bash
git add lib/shared/widgets/mx_selectable_card_row.dart lib/features/deck/presentation/widgets/items/deck_row_widget.dart lib/features/card/presentation/widgets/items/card_row_widget.dart lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart lib/app/gallery/gallery_surfaces_section.dart lib/l10n test/shared/widgets/mx_selectable_card_row_test.dart test/shared/widgets/surface_widgets_golden_test.dart test/features DESIGN.md docs/shared/ui/screen-handoff
git commit -m "feat(shared): DEV-304 MxSelectableCardRow frames the deck, card and Trash rows"
```

---

### Task 5: "Select cards" from the deck's ⋮ (DEV-307)

**Files:**
- Modify: `lib/features/card/presentation/states/card_selection_state.dart` (regenerate `.g.dart`)
- Modify: `lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart:171-175`, `card_add_fab_widget.dart:26-29`, `card_deck_breadcrumb_widget.dart:19`, `card_list_section_widget.dart:189-200, 272-280, 450-460`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`, `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`, `lib/features/deck/presentation/screens/deck_level_screen.dart` (three classes), `lib/app/router/app_router.dart:380-400`, `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/l10n/app_en.arb` (after `deckActionExport`), `lib/l10n/app_vi.arb:812`
- Modify: `test/support/library_harness.dart` (`deckScreen`), `docs/shared/ui/screen-handoff/01-deck-list.md:30-40`, `07-card-list.md:12, 39`
- Test: `test/features/card/presentation/card_selection_state_test.dart` (create), `test/features/deck/presentation/deck_action_sheet_test.dart`, `test/features/card/presentation/card_list_layout_test.dart`

**Interfaces:**
- Produces: `CardSelectionState({bool isSelecting = false, Set<String> ids = const {}})` with `contains(String)`; `CardSelection.start()`; `DeckAction.selectCards`; `openDeckActions(…, VoidCallback? onSelectCards)`; `DeckLevelScreen(onSelectCards: ValueChanged<String>)`; `AppIcons.select`; `l10n.deckActionSelectCards`.

- [ ] **Step 1: Set DEV-307 In Progress on Linear.**

- [ ] **Step 2: Write the failing state test**

Create `test/features/card/presentation/card_selection_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  CardSelection notifier() =>
      container.read(cardSelectionProvider('d').notifier);
  CardSelectionState state() => container.read(cardSelectionProvider('d'));

  test('starts out of selection with nothing picked', () {
    expect(state().isSelecting, isFalse);
    expect(state().ids, isEmpty);
  });

  test('Select cards enters selection with nothing picked (DEV-307)', () {
    notifier().start();
    expect(state().isSelecting, isTrue);
    expect(state().ids, isEmpty);
  });

  test('a long-press toggle enters selection with its card; unticking the '
      'last card keeps the mode until Close', () {
    notifier().toggle('c1');
    expect(state(), isA<CardSelectionState>()
        .having((s) => s.isSelecting, 'isSelecting', isTrue)
        .having((s) => s.ids, 'ids', {'c1'}));
    notifier().toggle('c1');
    expect(state().isSelecting, isTrue);
    expect(state().ids, isEmpty);
    notifier().clear();
    expect(state().isSelecting, isFalse);
  });

  test('select all replaces the picks and stays selecting', () {
    notifier().toggle('c1');
    notifier().selectAll({'c2', 'c3'});
    expect(state().ids, {'c2', 'c3'});
    expect(state().contains('c1'), isFalse);
  });
}
```

- [ ] **Step 3: Run it and see it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card/presentation/card_selection_state_test.dart`
Expected: compile failure (`CardSelectionState`, `start`).

- [ ] **Step 4: Implement the state and regenerate**

`card_selection_state.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_selection_state.g.dart';

/// A deck's selection mode (BR-CARD-020): whether the list is selecting,
/// and the cards picked. A long-press on a row enters it with that card;
/// "Select cards" from the deck's ⋮ enters it with none (DEV-307). It
/// ends only with Close, so unticking the last card keeps the mode, as the
/// Trash does.
@immutable
final class CardSelectionState {
  const CardSelectionState({this.isSelecting = false, this.ids = const {}})
    : assert(isSelecting || ids.isEmpty, 'picks only while selecting');

  static const CardSelectionState none = CardSelectionState();

  final bool isSelecting;
  final Set<String> ids;

  bool contains(String cardId) => ids.contains(cardId);
}

@riverpod
class CardSelection extends _$CardSelection {
  @override
  CardSelectionState build(String deckId) => CardSelectionState.none;

  /// Enters selection with nothing picked.
  void start() => state = const CardSelectionState(isSelecting: true);

  void toggle(String cardId) => state = CardSelectionState(
    isSelecting: true,
    ids: state.contains(cardId)
        ? ({...state.ids}..remove(cardId))
        : {...state.ids, cardId},
  );

  void selectAll(Set<String> cardIds) =>
      state = CardSelectionState(isSelecting: true, ids: {...cardIds});

  void clear() => state = CardSelectionState.none;
}
```

Run `dart run build_runner build --delete-conflicting-outputs` (it rewrites `card_selection_state.g.dart`; the file is git-ignored).

- [ ] **Step 5: Adapt the five consumers**

- `card_deck_app_bar_widget.dart:171-175`: `final selection = ref.watch(cardSelectionProvider(_deckId)); if (!selection.isSelecting) return _deckBar(); return _selectingBar(selection.ids.length);`
- `card_add_fab_widget.dart:27`: `ref.watch(cardSelectionProvider(deckId)).isSelecting ||`
- `card_deck_breadcrumb_widget.dart:19`: `.isSelecting;`
- `card_list_section_widget.dart`: around line 276, `final selection = ref.watch(cardSelectionProvider(widget.deckId)); final selected = selection.ids; final isSelecting = selection.isSelecting;` and keep every later use of `selected` (a `Set<String>`); where a row reads `isSelected: selected.contains(item.id)` nothing changes. Read lines 265–300 and 445–465 before editing; the listener at line 272 keeps its signature.
- Search for any other `.isNotEmpty` on the provider: `grep -rn "cardSelectionProvider" lib | grep -v "\.g\.dart"`.

Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card/presentation/card_selection_state_test.dart test/features/card/presentation/card_list_layout_test.dart test/features/card/presentation/card_deck_app_bar_test.dart test/features/card/presentation/card_list_flag_retry_test.dart`. A test that expected unticking the last card to leave selection is updated to expect the mode kept and "0 selected" in the bar, with the comment "(DEV-307: selection ends with Close, as in the Trash)".

- [ ] **Step 6: Write the failing sheet test**

In `test/features/deck/presentation/deck_action_sheet_test.dart` add (the harness `deckScreen` and `card_fixtures` are already imported):

```dart
  libraryTest('Select cards shows only from an open deck of cards and enters '
      'selection with nothing picked (DEV-307)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await seedCard(env, words.id, front: 'annyeong', back: 'hello');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _choose(tester, _en.deckActionSelectCards);

    expect(find.text(_en.cardSelectedCount(0)), findsOneWidget);
    expect(find.text(_en.cardSelectAllCount(1)), findsOneWidget);
  });

  libraryTest('a deck of decks and a row\'s ⋮ offer no Select cards', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _openSheet(tester);

    expect(find.text(_en.deckActionSelectCards), findsNothing);
  });
```

Use the card seeding helper `card_fixtures.dart` actually exports (`grep -n "Future" test/support/card_fixtures.dart`), with its real name and parameters, in place of `seedCard`.

- [ ] **Step 7: Run it and see it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_action_sheet_test.dart`
Expected: compile failure (`deckActionSelectCards`).

- [ ] **Step 8: Implement the entry**

- `app_icons.dart`, after `check`: `static const IconData select = Icons.checklist; // list-checks`.
- ARB en, after the `@deckActionExport` block: `"deckActionSelectCards": "Select cards",` and `"@deckActionSelectCards": {"description": "Deck action sheet, open deck of cards only: enters the card list's selection with nothing picked (BR-CARD-020, DEV-307)."},`. ARB vi, after line 812: `"deckActionSelectCards": "Chọn thẻ",`.
- `deck_action_sheet_widget.dart`: add `selectCards` to `DeckAction` after `rename`; `showDeckActionSheet` and `DeckActionSheetWidget` take `bool canSelect = false` ("The open deck holds cards: Select cards enters the list's selection (DEV-307)."); in `_rows`, after the Rename row:

```dart
      if (canSelect)
        MxActionSheetCommandRow(
          icon: AppIcons.select,
          label: l10n.deckActionSelectCards,
          onTap: () => choose(DeckAction.selectCards),
        ),
```

- `deck_actions_flow_widget.dart`: parameter `VoidCallback? onSelectCards,` after `onExportCards`; pass `canSelect: onSelectCards != null`; `case DeckAction.selectCards: onSelectCards?.call();`.
- `deck_level_screen.dart`: `DeckLevelScreen` and `_OpenDeck` and the content class that builds `deckActions` each gain `required this.onSelectCards` (`final ValueChanged<String> onSelectCards;`, doc "Enters the card list's selection with nothing picked (DEV-307): the router reaches the card feature."), threaded like `onExportCards`; at the `openDeckActions` call: `onSelectCards: deck.contentType == DeckContentType.card ? () => onSelectCards(deck.id) : null,`.
- `app_router.dart` `_deckLevel`: `onSelectCards: (id) => ProviderScope.containerOf(context).read(cardSelectionProvider(id).notifier).start(),` with the import of `card_selection_state.dart`. If `app_router.dart` already holds a `ref` or container, use it instead.
- `test/support/library_harness.dart` `deckScreen(…)`: add the same `onSelectCards` wiring using the container the harness already builds (`grep -n "onExportCards" test/support/library_harness.dart` shows the place).

- [ ] **Step 9: Run the tests and see them pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_action_sheet_test.dart test/features/card/presentation test/app/library_routes_test.dart test/l10n`
Expected: PASS; `flutter analyze lib test` no error; `check_architecture.sh` passes (deck still imports no card file).

- [ ] **Step 10: Document and commit**

`01-deck-list.md` Action sheet: in the sub-deck list after "Rename ·" add "Select cards (an open deck of cards only, DEV-307) → selection on screen 07 ·". `07-card-list.md` row 12 App bar: "… `⋮` (the deck's action sheet, with Select cards)". Row 39 selection: "Long-press selects (BR-CARD-020), or Select cards from `⋮` enters selection with nothing picked; Close ends it, unticking the last card does not (DEV-307)." Run `python3 tools/docs/check.py`.

```bash
git add lib/features/card lib/features/deck lib/app/router/app_router.dart lib/core/theme/foundations/app_icons.dart lib/l10n test/features test/support/library_harness.dart docs/shared/ui/screen-handoff
git commit -m "feat(card): DEV-307 Select cards from the deck's actions enters selection without a long-press"
```

---

### Task 6: Dividers owned by the container (DEV-305)

**Files:**
- Create: `lib/shared/widgets/mx_divided_column.dart`
- Modify: `lib/shared/widgets/mx_section.dart:24-48`, `lib/shared/widgets/mx_list_row.dart:65-67, 106-116`, `lib/shared/widgets/mx_option_row.dart:19, 41-42, 60-69`, `lib/shared/widgets/mx_deck_picker_sheet.dart:96-108`
- Modify: the 36 callers listed by `grep -rln "hasDivider" lib --include=*.dart`
- Modify: `DESIGN.md:337, 356`
- Create: `test/shared/widgets/mx_divided_column_test.dart`
- Test: `test/shared/widgets/mx_list_row_test.dart:180-215`, `mx_option_row_test.dart:116-140`, `mx_section_test.dart:55-77`, `surface_widgets_golden_test.dart:68-117`, `mx_deck_picker_sheet_test.dart`

**Interfaces:**
- Produces: `MxDividedColumn({required List<Widget> children})`; `MxListRow` and `MxOptionRow` lose `hasDivider`.

- [ ] **Step 1: Set DEV-305 In Progress on Linear.**

- [ ] **Step 2: Write the failing tests**

Create `test/shared/widgets/mx_divided_column_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';

import '../../support/widget_harness.dart';

Iterable<ColoredBox> _hairlines(WidgetTester tester) {
  final ghost = MxDerivedColors.resolve(
    AppColorSchemes.light,
    MxSemanticColors.light,
  ).ghostBorder;
  return tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((box) => box.color == ghost);
}

void main() {
  testWidgets('n children get n - 1 ghost hairlines, 1 tall, between them', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxDividedColumn(
        children: [
          SizedBox(key: ValueKey('a'), height: 48),
          SizedBox(key: ValueKey('b'), height: 48),
          SizedBox(key: ValueKey('c'), height: 48),
        ],
      ),
    );

    expect(_hairlines(tester), hasLength(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('b'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('a'))).dy,
      1,
    );
  });

  testWidgets('one child draws no hairline', (tester) async {
    await pumpMx(
      tester,
      const MxDividedColumn(children: [SizedBox(height: 48)]),
    );

    expect(_hairlines(tester), isEmpty);
  });
}
```

In `mx_list_row_test.dart` (lines 180–215) remove the two `edge()` expectations and the `_width(const MxListRow(title: 'Kana', hasDivider: false))` pump, rename the test to `'disabled dims and ignores taps'`; delete the `edge()` helper. In `mx_option_row_test.dart` (116–140) drop `hasDivider: false` and the `isEmpty` assertion on bordered boxes, rename to `'disabled at 0.38'`. In `surface_widgets_golden_test.dart:68-117` wrap the four `MxListRow`s in `MxDividedColumn(children: […])` in place of the `Column`, and drop `hasDivider: false`. `mx_section_test.dart` stays as is.

- [ ] **Step 3: Run them and see them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_divided_column_test.dart`
Expected: compile failure.

- [ ] **Step 4: Implement the shared helper and strip the rows**

Create `lib/shared/widgets/mx_divided_column.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Rows stacked with the ghost hairline between them and none after the
/// last: the one owner of list dividers (DEV-305). A section, a sheet or a
/// full-bleed card holds its rows in one; a row draws no edge of its own.
class MxDividedColumn extends StatelessWidget {
  const MxDividedColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      height: AppStroke.hairline,
      child: ColoredBox(color: context.derivedColors.ghostBorder),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) divider,
          child,
        ],
      ],
    );
  }
}
```

`mx_section.dart`: replace the `divider` local and the inner `Column` with `MxDividedColumn(children: children)`; drop the `app_stroke.dart` import; doc "The section's rows sit in an `MxDividedColumn` (ruling S8)".
`mx_list_row.dart`: remove `hasDivider` (constructor, field, doc), the `DecoratedBox` with the bottom border (the `MxRowInk` becomes the root), and the now-unused `app_stroke.dart` import; class doc gains "Dividers are the list's (`MxDividedColumn`, DEV-305)."
`mx_option_row.dart`: the same (`hasDivider`, the `DecoratedBox` border; keep the radio's `DecoratedBox`).
`mx_deck_picker_sheet.dart:96-108`: `Column(children: [for … MxListRow(… no hasDivider …)])` → `MxDividedColumn(children: [for (final candidate in candidates) MxListRow(…)])`.

- [ ] **Step 5: Migrate the callers**

For each file from `grep -rln "hasDivider" lib --include=*.dart` (36 files, all feature or gallery):

1. If every row in the list passed `hasDivider: false`, or the rows are the children of an `MxSection`, delete the argument only.
2. Otherwise (rows relied on their own divider, usually with `hasDivider: index < length - 1` or the default), replace the `Column`/list literal that holds the rows with `MxDividedColumn(children: […])` and delete the arguments. A `ListView.builder` list (search results, Study home decks, users) keeps its builder and gets the hairline back by wrapping each row in the same pattern the builder already uses for spacing, or by switching to `ListView` + `MxDividedColumn` where the list is short (fewer than 50 rows); read the file before choosing.
3. Keep the gallery (`gallery_inputs_section.dart:109`, `gallery_surfaces_section.dart:155`) under rule 1.

After each feature, run its tests: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/<feature>/presentation`. Then `flutter analyze lib test` must report no error and `grep -rn "hasDivider" lib test` must be empty.

- [ ] **Step 6: Run the shared tests and see them pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared test/app/gallery_test.dart`
Expected: PASS.

- [ ] **Step 7: Document and commit**

`DESIGN.md` Containers (line 337): after `MxSection` add "**MxDividedColumn** (rows with the ghost hairline between them, none after the last: the one owner of list dividers, DEV-305; a row draws no edge of its own)". Data Display `MxListRow`: remove any mention of a row's own divider. Run `python3 tools/docs/check.py`.

```bash
git add lib test DESIGN.md
git commit -m "refactor(shared): DEV-305 lists own their dividers through MxDividedColumn"
```

---

### Task 7: Goldens, audit, gate and the owner's review

**Files:**
- Modify: every `test/**/goldens/*.png` the changes move
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (register rows for F-02 … F-06, after row 160)

- [ ] **Step 1: Regenerate goldens in the container**

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then `git status --short test | grep goldens` to list the changed images. Expected movers: `mx_bottom_nav_*` (bit-identical or near), `mx_empty_state_*`, `mx_breadcrumb_*`, `mx_list_row_*`, new `mx_selectable_card_row_*`, `app_gallery_*`, `app_library_*`, the Library, Card list, Trash, Monitoring and study screens. Any other mover is explained in the PR body or fixed.

- [ ] **Step 2: Golden review page**

Invoke the `golden-compare` skill on the changed images; keep its page path for the PR body and the Linear comments.

- [ ] **Step 3: One Impeccable audit**

Invoke `impeccable` with `audit` on the changed goldens against `DESIGN.md` (CLAUDE.md: one audit, fix what it finds in one batch, no second audit). Commit any fix as `fix(shared): DEV-301 impeccable audit batch`.

- [ ] **Step 4: Register rows and the gate**

Append to UI-base §9 one row per sub-issue 303–307 in the form of row 160 (what was wrong, closed by DEV-n, this spec's section). Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → PASS. Commit `docs: DEV-301 register rows and goldens`.

- [ ] **Step 5: Linear and the branch**

Comment on each sub-issue with the commits and the golden page (template "Done" waits for the merge; this is a progress comment: "Đã cài trên nhánh `ccr-e1b4f874-uftugm`, commit `<sha7>`; golden review: <link>"). Then run the `finishing-a-development-branch` skill: the final whole-branch review on Opus, the push, and the PR for epic DEV-301 (the owner opens or approves it through `AskUserQuestion`).
