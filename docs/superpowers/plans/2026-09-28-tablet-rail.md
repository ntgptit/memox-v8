# FE-C5 Tablet Rail Implementation Plan

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** At a window width of 600 dp or more the app shows a navigation rail and caps
every screen at a centred 720 dp column; below 600 dp nothing changes.

**Architecture:** `MxAppShell` (the one Scaffold every screen uses) caps its column and
anchors the FAB to it. A new shared `MxNavRail` mirrors `MxBottomNav`'s API. The tab shell,
moved out of `app_router.dart` into `app_tab_shell.dart`, picks the rail or the bottom nav
by width and gives the branch its own size and insets.

**Tech Stack:** Flutter 3.47.5, go_router `StatefulShellRoute`, flutter_test goldens.

**Spec:** `docs/superpowers/specs/2026-09-28-tablet-rail-design.md`

## Global Constraints

- Breakpoint: window width **600 dp** (`AppSize.navRailBreakpoint`); rail width **80**
  (`AppSize.navRail`); column cap **720 dp** (`AppSize.contentMaxWidth`).
- Phone goldens (360 × 800) stay byte-identical; run `TZ=UTC flutter test --tags golden`
  without `--update-goldens` before regenerating only the new ones.
- Rail tokens: ground `surfaceContainerLow`; pill tint `primary` at 0.14 light / 0.20
  dark; selected glyph `primaryInk`; resting glyph `onSurfaceVariant`; label `navLabel`.
- No new package, no window-size-class type, no two-pane layout.
- Tests before code (TDD); `flutter analyze` clean; the guard (`/usr/bin/python3.13`)
  clean at the end.

## Review Focus

1. **RTL:** the rail sits on the right and the FAB anchors to the column's left edge
   (Task 1 FAB RTL test, Task 3 RTL rail test).
2. **Rotation across 600 dp:** switching between the bottom nav and the rail keeps each
   branch's stack (Task 3 resize test).
3. **Landscape with a side inset (camera cutout):** the rail takes the start inset and
   the branch is not padded twice (Task 3 inset test).
4. **Short landscape phone at text scale 2:** the rail scrolls, nothing overflows
   (Task 2 test).
5. **Snackbar on a phone:** unchanged width and inset (Task 4 test).

---

### Task 1: Column cap and FAB anchor in `MxAppShell`

**Files:**
- Modify: `lib/core/theme/foundations/app_size.dart`
- Modify: `lib/shared/widgets/mx_app_shell.dart`
- Test: `test/shared/widgets/mx_app_shell_test.dart`

**Interfaces:**
- Produces: `AppSize.navRailBreakpoint = 600`, `AppSize.contentMaxWidth = 720`,
  `AppSize.navRail = 80`.

- [ ] **Step 1: Write the failing tests** (append to `mx_app_shell_test.dart`; use a
  wide view set on `tester.view`, not `pumpMx`'s phone frame):

```dart
Future<void> _pumpWide(WidgetTester tester, Widget shell, {TextDirection
    direction = TextDirection.ltr}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildLightTheme(),
    home: Directionality(textDirection: direction, child: shell),
  ));
}

testWidgets('wide: the column is 720 and centred; the ground fills (FE-C5)',
    (tester) async {
  await _pumpWide(tester, const MxAppShell(
    appBar: MxAppBar(title: 'Library'),
    body: SizedBox.expand(key: ValueKey('body')),
  ));
  final body = tester.getRect(find.byKey(const ValueKey('body')));
  expect(body.width, 720);
  expect(body.left, (1280 - 720) / 2);
  expect(tester.getSize(find.byType(Scaffold)).width, 1280);
});

testWidgets('wide: the FAB sits 16 in from the column edge, mirrored in RTL',
    (tester) async {
  for (final (direction, expectedLeft) in [
    (TextDirection.ltr, 1000.0 - 16 - 52),
    (TextDirection.rtl, 280.0 + 16),
  ]) {
    await _pumpWide(tester, MxAppShell(
      body: const SizedBox.expand(),
      fab: MxFab(icon: AppIcons.add, semanticLabel: 'Add', onPressed: () {}),
    ), direction: direction);
    expect(tester.getTopLeft(find.byType(MxFab)).dx, expectedLeft);
  }
});
```

(Check `MxFab`'s constructor in `lib/shared/widgets/mx_fab.dart` and use its real
parameter names.)

- [ ] **Step 2: Run** `flutter test test/shared/widgets/mx_app_shell_test.dart` — Expected:
  FAIL (body is 1280 wide; FAB at the window edge).

- [ ] **Step 3: Implement.** In `app_size.dart` add:

```dart
  /// From this window width the top-level destinations sit in a rail (FE-C5).
  static const double navRailBreakpoint = 600;

  /// The rail's width.
  static const double navRail = 80;

  /// A screen's column never grows past this; the page ground fills the rest.
  static const double contentMaxWidth = 720;
```

In `MxAppShell.build`, wrap the body `Column` so it keeps its full height and caps its
width:

```dart
      body: Builder(
        builder: (bodyContext) => LayoutBuilder(
          builder: (_, constraints) => Center(
            child: SizedBox(
              width: math.min(constraints.maxWidth, AppSize.contentMaxWidth),
              child: Column(
                children: [ /* unchanged children */ ],
              ),
            ),
          ),
        ),
      ),
```

In `_MxFabLocation.getOffset`, anchor to the column:

```dart
    final width = geometry.scaffoldSize.width;
    final column = math.min(width, AppSize.contentMaxWidth);
    final columnStart = (width - column) / 2;
    final columnEnd = columnStart + column;
    final x = switch (geometry.textDirection) {
      TextDirection.ltr =>
        math.min(columnEnd, width - geometry.minInsets.right) -
            AppSpacing.gutter -
            fab.width,
      TextDirection.rtl =>
        math.max(columnStart, geometry.minInsets.left) + AppSpacing.gutter,
    };
```

Update the class doc of `_MxFabLocation`: "16 from the column's trailing edge".

- [ ] **Step 4: Run** the shell test, then `TZ=UTC flutter test --tags golden` —
  Expected: PASS, no golden changed (phone layout identical).
- [ ] **Step 5: Commit** `feat(ui): cap the screen column at 720 and anchor the FAB to it (FE-C5)`.

### Task 2: `MxNavRail`

**Files:**
- Create: `lib/shared/widgets/mx_nav_rail.dart`
- Test: `test/shared/widgets/mx_nav_rail_test.dart`
- Test: `test/shared/widgets/mx_nav_rail_golden_test.dart` (+ `goldens/mx_nav_rail_{light,dark}.png`)

**Interfaces:**
- Consumes: `MxNavDestination` from `mx_bottom_nav.dart`; `AppSize.navRail`.
- Produces: `MxNavRail({required List<MxNavDestination> destinations, required int
  selectedIndex, required ValueChanged<int> onSelected})`.

- [ ] **Step 1: Write the failing tests** (reuse the four destinations of
  `mx_bottom_nav_test.dart`):

```dart
testWidgets('80 wide on surfaceContainerLow; every item at least 48×56', ...
  // pumpMx(tester, SizedBox(height: 600, child: _rail()))
  // expect width 80; the ground ColoredBox color == scheme.surfaceContainerLow;
  // each item (find.byType(InkWell)) >= Size(48, 56).
testWidgets('the selected item: filled glyph in primaryInk on the pill; the rest '
    'outlined in onSurfaceVariant', ...);
testWidgets('a tap reports its index, a re-tap of the current one too', ...);
testWidgets('announced as selected buttons named by their labels', ...
  // isSemantics(isButton: true, isSelected: true, label: 'Library')
  // then expectAccessibleTargets(tester)
testWidgets('RTL: the rail takes the right inset, not the left', ...
  // pumpMx with padding: EdgeInsets.only(right: 32) under
  // Directionality(textDirection: TextDirection.rtl): the rail is 80 + 32 wide.
testWidgets('at text scale 2 in an 800×360 landscape the rail scrolls and '
    'nothing overflows', ...
  // tester.view.physicalSize = Size(800, 360); textScale 2;
  // expect(tester.takeException(), isNull); find.byType(Scrollable) findsOneWidget
```

Golden test: `expectThemedGoldens(tester, 'mx_nav_rail', Align(alignment:
AlignmentDirectional.centerStart, child: _rail(selected: 1)))`.

- [ ] **Step 2: Run** — Expected: FAIL (no `MxNavRail`).
- [ ] **Step 3: Implement** `mx_nav_rail.dart`:

```dart
/// The top-level destinations in a rail on the leading edge, for windows of
/// 600 dp and more (FE-C5). The kit has no rail: it takes MxBottomNav's
/// glyphs, pill and label so the two read as one control. It takes the
/// start and top insets itself and scrolls when the window is short.
class MxNavRail extends StatelessWidget {
  const MxNavRail({super.key, required this.destinations,
      required this.selectedIndex, required this.onSelected})
      : assert(selectedIndex >= 0 && selectedIndex < destinations.length,
            'selectedIndex must name a destination');

  final List<MxNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _pillTintLight = 0.14;
  static const double _pillTintDark = 0.20;
  static const double _itemMinHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pillTint = colors.primary.withValues(
      alpha: colors.brightness == Brightness.dark
          ? _pillTintDark
          : _pillTintLight,
    );
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    return ColoredBox(
      color: colors.surfaceContainerLow,
      child: SafeArea(
        left: isLtr,
        right: !isLtr,
        child: SizedBox(
          width: AppSize.navRail,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: AppSpacing.control),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                spacing: AppSpacing.micro,
                children: [
                  for (final (index, destination) in destinations.indexed)
                    _RailItem(/* destination, isSelected, pillTint, onTap */),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

`SafeArea`'s `left`/`right` are physical sides, so the rail takes only the inset on its
own side; `top` and `bottom` stay on.
`_RailItem` repeats `MxBottomNav._Item`'s body (Semantics container/selected/button,
InkWell, the pill `DecoratedBox`, the `Icon` at `AppIconSize.compact`, the one-line
ellipsized `Text` in `navLabel(isSelected:)`) inside
`ConstrainedBox(constraints: BoxConstraints(minHeight: _itemMinHeight, minWidth:
AppSize.touchTarget))`. Keep it private in this file; do not export `_Item`.

- [ ] **Step 4: Run** the rail tests; generate the two goldens with
  `TZ=UTC flutter test test/shared/widgets/mx_nav_rail_golden_test.dart --update-goldens`
  and look at them. Expected: PASS.
- [ ] **Step 5: Commit** `feat(ui): MxNavRail for windows of 600 dp and more (FE-C5)`.

### Task 3: The tab shell picks the rail

**Files:**
- Create: `lib/app/router/app_tab_shell.dart` (moved `_TabShell`, now `AppTabShell`)
- Modify: `lib/app/router/app_router.dart` (use `AppTabShell`; delete `_TabShell`)
- Modify: `test/support/library_harness.dart` (`pumpMemoxApp` gains `Size physicalSize
  = const Size(1080, 2400)`, `double devicePixelRatio = 3`)
- Test: `test/app/tab_shell_test.dart`

**Interfaces:**
- Consumes: `MxNavRail`, `MxBottomNav`, `AppSize.navRailBreakpoint`, `AppSize.navRail`.
- Produces: `AppTabShell({required StatefulNavigationShell navigationShell})`.

- [ ] **Step 1: Write the failing tests** (`libraryTest` + `pumpMemoxApp`):

```dart
libraryTest('599 wide: the bottom nav; 600 wide: the rail', ...
  // pumpMemoxApp(tester, env, physicalSize: Size(599, 900), devicePixelRatio: 1)
  // expect MxBottomNav findsOneWidget, MxNavRail findsNothing; then 600 → reversed.
libraryTest('the rail switches branches and keeps each stack; a re-tap returns '
    'to the root', ...
  // seed a root deck, open it, tap rail 'Study', tap rail 'Library' → still on the
  // deck (its app bar title); tap 'Library' again → Library root.
libraryTest('rotating across 600 keeps the open deck', ...
  // at 400×900 open a deck; set tester.view.physicalSize = Size(900, 400);
  // pumpAndSettle → MxNavRail shown, deck title still shown.
libraryTest('a start inset goes to the rail, not twice to the branch', ...
  // tester.view.padding = FakeViewPadding(left: 32); view 1280×800 at dpr 1:
  // the rail's ColoredBox is 80 + 32 wide; inside the branch,
  // MediaQuery.paddingOf(<a context under MxAppShell>).left == 0.
```

RTL is pinned in Task 2's widget test (the rail takes the right inset under
`TextDirection.rtl`), since the app has no RTL locale to pump.

- [ ] **Step 2: Run** — Expected: FAIL (no rail anywhere).
- [ ] **Step 3: Implement** `app_tab_shell.dart`:

```dart
/// The top-level destinations around the current branch: a bottom nav on a
/// phone, a rail from 600 dp (FE-C5). The branch gets its own width and
/// loses the inset the rail took, so what it lays out and centres (the
/// column, sheets, snackbars) is measured against its own area.
class AppTabShell extends StatelessWidget {
  const AppTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context.l10n);
    void onSelected(int index) => navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    final media = MediaQuery.of(context);
    if (media.size.width < AppSize.navRailBreakpoint) {
      return MxAppShell(
        body: navigationShell,
        bottomBar: MxBottomNav(destinations: destinations,
            selectedIndex: navigationShell.currentIndex, onSelected: onSelected),
      );
    }
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    return ColoredBox(
      color: context.colors.surface,
      child: Row(
        children: [
          MxNavRail(destinations: destinations,
              selectedIndex: navigationShell.currentIndex, onSelected: onSelected),
          Expanded(child: MediaQuery(
            data: media.copyWith(
              size: Size(media.size.width - AppSize.navRail - (isLtr
                  ? media.padding.left : media.padding.right), media.size.height),
              padding: isLtr ? media.padding.copyWith(left: 0)
                  : media.padding.copyWith(right: 0),
              viewPadding: isLtr ? media.viewPadding.copyWith(left: 0)
                  : media.viewPadding.copyWith(right: 0),
            ),
            child: navigationShell,
          )),
        ],
      ),
    );
  }

  static List<MxNavDestination> _destinations(AppLocalizations l10n) => [
    // the four MxNavDestination entries moved verbatim from _TabShell
  ];
}
```

Switching layouts re-parents `navigationShell`. If the rotation test shows a branch
stack lost, wrap `navigationShell` in `KeyedSubtree(key: _branchKey, child: …)` in both
layouts, with `static final GlobalKey _branchKey = GlobalKey();`, so the element moves
instead of being rebuilt.

- [ ] **Step 4: Run** `flutter test test/app/` — Expected: PASS (existing app tests at
  360 wide unchanged).
- [ ] **Step 5: Commit** `feat(app): a navigation rail from 600 dp (FE-C5)`.

### Task 4: Snackbar width

**Files:**
- Modify: `lib/shared/widgets/mx_snackbar.dart:43-70`
- Test: `test/shared/widgets/mx_snackbar_test.dart`

- [ ] **Step 1: Write the failing tests:**

```dart
testWidgets('wide: at most the column, centred (FE-C5)', ...
  // view 1280×800; show via showMxSnackbar; the SnackBar's Material width ==
  // AppSize.contentMaxWidth - 2 * AppSpacing.gutter, centred.
testWidgets('phone: the theme inset, as before', ...
  // view 360×800: the snackbar's Material width == 360 - 2 * AppSpacing.gutter.
```

- [ ] **Step 2: Run** — Expected: first FAIL, second PASS.
- [ ] **Step 3: Implement** in `buildMxSnackBar`:

```dart
  // On a wide window the toast is at most the screen column (FE-C5 D5);
  // SnackBar.width replaces the theme's side inset only there.
  final window = MediaQuery.sizeOf(context).width;
  const column = AppSize.contentMaxWidth - 2 * AppSpacing.gutter;
  ...
  return SnackBar(
    width: window > AppSize.contentMaxWidth ? column : null,
    ...
```

- [ ] **Step 4: Run** the snackbar tests and the golden suite — Expected: PASS, phone
  goldens unchanged.
- [ ] **Step 5: Commit** `feat(ui): cap the snackbar at the column on wide windows (FE-C5)`.

### Task 5: Gallery entry and tablet app goldens

**Files:**
- Modify: `lib/app/gallery/gallery_chrome_section.dart` (an `MxNavRail` beside the
  `MxBottomNav` sample, in a `SizedBox(height: 320)`)
- Modify: `test/support/golden_harness.dart` (`expectBoundaryGolden` gains
  `double pixelRatio = _goldenPixelRatio`)
- Modify: `test/app/app_golden_test.dart` (tablet cases)
- Goldens: `test/app/goldens/app_tablet_{landscape_library,portrait_deck}_{light,dark}.png`

- [ ] **Step 1: Add the golden tests:** `_pumpApp` gains `Size size` (default phone);
  cases `Library tab at 1280×800, <brightness>` and `a deck at 800×1280, <brightness>`
  (seed one root deck with two sub-decks, tap it), captured with
  `expectBoundaryGolden(tester, ..., pixelRatio: 1.5)`; each also runs
  `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`.
- [ ] **Step 2: Run** with `--update-goldens`, open the four PNGs and compare with the
  approved B mockup (`fec1/review/10_tablet_landscape.png` in the session scratchpad;
  rail on the left, 720 column centred, FAB at the column edge).
- [ ] **Step 3: Run** the full golden suite without `--update-goldens` — only the four
  new files and `app_gallery_*` differ from master.
- [ ] **Step 4: Commit** `test(app): tablet goldens for the rail and the column (FE-C5)`.

### Task 6: Docs

**Files:**
- Modify: `PRODUCT.md` (line 51 "Phones only, for now…" → "Phones first. On tablets and
  in landscape (600 dp and wider) the destinations move to a navigation rail and each
  screen keeps its phone layout in a centred column of at most 720 dp (FE-C5,
  owner 2026-09-28). No two-pane layouts.")
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (row 63
  closed by FE-C5; a new row: the rail and the column are V8's, the kit has neither)
- Modify: `docs/wbs_FE.md` (FE-C5 `xong` with evidence; §Bước tiếp theo; effort row)
- Modify: `docs/shared/ui/screen-handoff/00-index.md` shared rules, if it states the
  bottom nav is on every width (check with `grep -n "bottom nav\|BottomNav"`)

- [ ] **Step 1:** Edit the files as above.
- [ ] **Step 2:** Run `flutter analyze`, `flutter test --exclude-tags golden`,
  `TZ=UTC flutter test --tags golden`, the guard
  (`/usr/bin/python3.13 code-verification-guard-v2/...` as `dod_check.sh` calls it) and
  `dod_check.sh`.
- [ ] **Step 3: Commit** `docs: FE-C5 done — rail and column on tablets`.
