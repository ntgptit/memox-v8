# SP3a Phase 2 — Primitives and core controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Phase 2 primitives and the 14 core controls of the DESIGN.md catalog (spec §4.4, Phase 2). Each one gets its theme slot where Material has one, its `Mx*` widget, its widget test, its `mx_*` goldens and its catalog contract, so `check.py` marks it `built`.

**Architecture:**
- **One style source per component family.** Each family has one style function in `lib/core/theme/components/`. `AppTheme`'s slot and the `Mx*` widget both call it, so a raw Material widget and its `Mx*` cannot drift apart.
- **Where widgets live.** `Mx*` widgets live in `lib/shared/widgets/`, primitives in `lib/shared/widgets/primitives/`, and the tests in `test/shared/widgets/` (spec §4.2).
- **What widgets read.** Widgets read the theme through `context.colors`, `context.semanticColors` and `context.texts`. Geometry comes from the generated `AppSize`, `AppIconSize` and the earlier scales.
- **Goldens.** Each golden is a composite sheet per state group, in light and dark. The file name is `mx_<component>__<state>__<variant>.png`.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13 (Material 3: `ButtonStyle`, `InputDecorationThemeData`, `FocusableActionDetector`, `Semantics`); `flutter_test` goldens through `flutter_test_config.dart`, which loads the bundled fonts; Python 3 standard library for the generator and `check.py`.

**Spec:** `docs/superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md` (A1–A11; §4 catalog; §5 component contract). Phase 1 plan: `docs/superpowers/plans/2026-10-04-sp3a-p1-tokens-theme.md`.

## Global Constraints

- **The API takes meaning, not looks.** The caller passes semantic variants and localized copy only: never a `Color`, `TextStyle`, `BorderRadius`, `BorderSide`, `BoxShadow`, `ButtonStyle`, padding or icon size (spec §5; `flutter-theme-design`).
- **Every control has a 48 × 48 hit area, whatever it paints** (DESIGN.md, "The 48 Floor Rule").
- **Every text restyle lives in `lib/core/theme/components/`.** The guard's `no_text_restyle` and `no_raw_text_style` forbid restyling in `lib/shared/`. A colour is applied with `.apply(color:)` on a theme role.
- **No literal sizes or durations in `lib/shared/`.** No numeric spacing, radius, stroke or duration appears in `lib/shared/`; every value comes from the generated scales.
- **Code style.** Booleans read as predicates (`isX`, `hasX`, `shouldX`), as the guard's `boolean_reads_as_predicate` requires. Code uses no `else` and returns early (owner's code style).
- **Placement.** A public `Mx*` type lives at its catalog path, or carries a catalogued component's name as its prefix (`MxButtonTone`, `MxSegmentedTrayItem`).
- **Goldens are full-HD** (decision 6): `mxGoldenPixelRatio = 2.625` on a 1080 × 2400 view; no test changes it.
- **Goldens are generated in the Linux container only**, with `flutter test --update-goldens <file>` (CLAUDE.md, "The gate").
- **Commit attribution.** Every commit ends with the two attribution lines of this session (as in Phase 1).

## Decisions this plan makes (for the owner's review)

1. **Composite goldens.** A golden shows a whole state group, for example `mx_button__tones__light.png` with all seven tones enabled and disabled. It never shows one state per file. That gives 32 pictures instead of about 150, each one reviewable on the `golden-compare` page.
2. **Geometry DESIGN.md does not state:**
   - spinner sizes 16 / 20 / 32 / 48;
   - checkbox 18 and radio 20 (the Material 3 sizes);
   - segment 36 painted inside a 48 cell;
   - the stepper repeat at 80 ms after the platform's long-press delay.

   All of them are sidecar tokens, not literals.
3. **`MxStepper` has no typed entry yet.** It is recorded as `- Debt:` in its contract. SCR-SETTINGS-001, its first consumer, adds it in SP3c.
4. **New primitives.** `MxFocusRing`, `MxTapTarget` and `MxChipShell` join `MxRowInk` as catalogued primitives. Each exists because two or more components share it.
5. **Guard housekeeping.** The `targets_pending` entries of `widget_no_database_access`, `widget_no_repository_access` and `no_flat_style_from` are removed, because `lib/shared/widgets/` gives them targets. The guard reports them as stale otherwise.
6. **Full-HD goldens** (owner, 2026-10-04: the DPR-1 pictures were blurred). The harness renders on a 1080 × 2400 physical screen at a device pixel ratio of 2.625, the density of a common 1080p Android phone, and captures the sheet with `RenderRepaintBoundary.toImage(pixelRatio: 2.625)`. The layout stays at 411 × 914 logical pixels, so geometry tests are unchanged.
7. **A gallery of the shared widgets** (owner, 2026-10-04). `tools/design/gallery.py` reads the DESIGN.md catalog and contracts and writes one self-contained HTML page: each built component with its contract and its light and dark goldens side by side. It is published as an Artifact for the owner beside the `golden-compare` page, which stays the review of record.

## Review Focus

- **A loading or disabled button.** It must neither tap nor change width, and a loading button keeps its label for TalkBack. Tested in Task 3.
- **Keyboard focus on Android with a hardware keyboard.** Every control shows the 2dp ring, and a tap never leaves one behind. Tested in Tasks 2, 3 and 7.
- **A field whose painted height differs from its box.** `InputDecoration.constraints` grows the box and not the paint, so it is forbidden; the test measures padding plus line height. Tested in Task 5.
- **Holding a stepper button.** The repeat must keep counting before the parent rebuilds, and it must not compete with the tooltip's long press. Tested in Task 8.
- **Dark theme inversions.** A raised segment must stay lighter than its tray in both themes, and the detail line of a button must take the button's content colour. Tested in Tasks 3 and 8.

---

### Task 1: Tokens for Phase 2 and the theme accessors

**Files:**
- Modify: `.impeccable/design.json` (`extensions.iconSize`, `extensions.size`, `extensions.motion.repeat`)
- Modify: `tools/design/generate.py` (`emit`), `tools/design/test_generate.py`
- Create (generated): `lib/core/theme/foundations/app_icon_size.dart`, `lib/core/theme/foundations/app_size.dart`; regenerated `app_durations.dart`
- Create: `lib/core/theme/theme_context.dart`
- Modify: `.claude/skills/flutter-design-system/references/tokens.md`

**Interfaces:**
- Produces:
  - `AppIconSize.small` (16), `mark` (18), `medium` (20) and `large` (24);
  - `AppSize.tapTarget`, `buttonRegular`, `buttonSmall`, `buttonCompact`, `buttonChip`, `buttonStudyPadding`, `iconButton`, `fab`, `field`, `fieldDetail`, `fieldMeaning`, `toggleWidth`, `toggleHeight`, `toggleThumb`, `chip`, `checkbox`, `radio`, `focusOffset`, `spinnerSmall`, `spinnerMedium`, `spinnerLarge`, `spinnerXlarge` and `segment`;
  - `AppDurations.repeat`;
  - `BuildContext.colors`, `.semanticColors` and `.texts`.

- [ ] **Step 1: Write the failing generator test**

In `tools/design/test_generate.py`, add to the `extensions()` fixture, after `"breakpoints": {"nav-rail": 600},`:

```python
        "iconSize": {"small": 16},
        "size": {"tap-target": 48},
```

and add to `EmitTest`:

```python
    def test_icon_sizes_and_component_sizes_are_generated(self):
        emitted = g.emit(design())
        self.assertIn("static const double small = 16;", emitted[g.OUT_DIR / "app_icon_size.dart"])
        self.assertIn("static const double tapTarget = 48;", emitted[g.OUT_DIR / "app_size.dart"])
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python3 tools/design/test_generate.py`
Expected: FAIL, `KeyError` on `app_icon_size.dart`.

- [ ] **Step 3: Emit the two scales**

In `tools/design/generate.py`, `emit()`, add after the `app_breakpoints.dart` line:

```python
        OUT_DIR / "app_icon_size.dart": emit_scale("AppIconSize", "Glyph sizes.", ext["iconSize"]),
        OUT_DIR / "app_size.dart": emit_scale("AppSize", "Component geometry: painted sizes, the 48 target, fixed offsets.", ext["size"]),
```

Run: `python3 tools/design/test_generate.py`
Expected: `OK`.

- [ ] **Step 4: Add the token values**

Run from the repo root (a one-off, not committed):

```bash
python3 - <<'EOF'
import json
from pathlib import Path
s = Path(".impeccable/design.json")
d = json.loads(s.read_text(encoding="utf-8"))
e = d["extensions"]
motion = {}
for key, value in e["motion"].items():
    motion[key] = value
    if key == "settle":
        motion["repeat"] = 80
e["motion"] = motion
e["iconSize"] = {"small": 16, "mark": 18, "medium": 20, "large": 24}
e["size"] = {"tap-target": 48, "button-regular": 48, "button-small": 36, "button-compact": 32, "button-chip": 28,
             "button-study-padding": 36, "icon-button": 36, "fab": 52, "field": 52, "field-detail": 48,
             "field-meaning": 76, "toggle-width": 44, "toggle-height": 26, "toggle-thumb": 20, "chip": 28,
             "checkbox": 18, "radio": 20, "focus-offset": 2, "spinner-small": 16, "spinner-medium": 20,
             "spinner-large": 32, "spinner-xlarge": 48, "segment": 36}
s.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
EOF
python3 tools/design/generate.py --write && python3 tools/design/generate.py --check
```

Expected: `wrote 12 files to lib/core/theme/foundations` then `PASS — …`.

- [ ] **Step 5: The theme accessors**

Create `lib/core/theme/theme_context.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// The design-system layer's one read of the theme (flutter-design-system,
/// tokens.md): the 45 roles, MemoX's semantic roles and the type scale.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;

  TextTheme get texts => Theme.of(this).textTheme;
}
```

- [ ] **Step 6: The skill's token map**

In `.claude/skills/flutter-design-system/references/tokens.md`, add these two lines to the generated tree, after the `app_breakpoints.dart` line:

```
├── app_icon_size.dart        # AppIconSize.small (16), mark (18), medium (20), large (24)
├── app_size.dart             # AppSize: painted sizes, the 48 tap target, fixed offsets
```

Add these after the `app_theme.dart` line:

```
lib/core/theme/theme_context.dart   # context.colors / .semanticColors / .texts (design-system layer)
lib/core/theme/components/          # one style source per component family; AppTheme's slots and the Mx* widgets share it
```

- [ ] **Step 7: Verify and commit**

Run: `flutter analyze lib/core/theme` → `No issues found!`; `python3 tools/docs/check.py | tail -1` → `PASS`.

```bash
git add .impeccable/design.json tools/design lib/core/theme .claude/skills/flutter-design-system
git commit -m "feat(sp3a-p2): icon sizes, component sizes and the theme accessors"
```

---

### Task 2: Primitives — focus ring, tap target, row ink — and the harness

**Files:**
- Create: `lib/shared/widgets/primitives/mx_focus_ring.dart`, `mx_tap_target.dart`, `mx_row_ink.dart`
- Create: `test/shared/widgets/support/mx_harness.dart`
- Test: `test/shared/widgets/mx_focus_ring_test.dart`, `mx_tap_target_test.dart`, `mx_row_ink_test.dart`
- Modify: `tools/docs/design_catalog.py`, `tools/docs/test_design_catalog.py` (catalogued snake names are not ink)
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
- Modify: `DESIGN.md` (`### Catalog` rows, `### Contracts`)

**Interfaces:**
- Produces:
  - `MxFocusRing({required BorderRadius borderRadius, required Widget child, double? paintedHeight, bool? isShown})`;
  - `MxTapTarget({required Widget child})`;
  - `MxRowInk({required VoidCallback? onTap, required Widget child, BorderRadius borderRadius})`;
  - test helpers `mxThemes`, `pumpMx(tester, child, {theme, textDirection})` and `expectMxGolden(tester, {component, state, variant, sheet})`.

- [ ] **Step 1: Write the harness and the failing tests**

Create `test/shared/widgets/support/mx_harness.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

/// Both themes, by the variant name a golden carries (`light`, `dark`).
final Map<String, ThemeData> mxThemes = {
  'light': AppTheme.light(),
  'dark': AppTheme.dark(),
};

/// Pumps [child] on the theme's page ground, as a screen would show it.
Future<void> pumpMx(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? mxThemes['light'],
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// A full-HD phone's density: 1080 px across a 412 dp screen.
const double mxGoldenPixelRatio = 2.625;

/// The key of the picture a component golden captures.
const Key mxGoldenKey = ValueKey<String>('mx-golden');

/// One component golden: [sheet] laid out on the page ground of [variant]'s
/// theme at a phone's width, captured as `mx_<component>__<state>__<variant>`.
Future<void> expectMxGolden(
  WidgetTester tester, {
  required String component,
  required String state,
  required String variant,
  required Widget sheet,
}) async {
  // A full-HD phone, 412 dp wide; the picture is rasterized at its density
  // (below), so a golden is as sharp as the device it stands for.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = mxGoldenPixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: mxThemes[variant],
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: mxGoldenKey,
            child: ColoredBox(
              color: mxThemes[variant]!.colorScheme.surface,
              child: Padding(padding: const EdgeInsets.all(16), child: sheet),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // `matchesGoldenFile` on a finder captures at 1 px per dp; rasterize the
  // boundary at the device density instead and compare that picture.
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(mxGoldenKey),
  );
  final ui.Image picture = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: mxGoldenPixelRatio),
  ))!;
  addTearDown(picture.dispose);
  await expectLater(
    picture,
    matchesGoldenFile('goldens/mx_${component}__${state}__$variant.png'),
  );
}
```

Create `test/shared/widgets/mx_tap_target_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('MxTapTarget grows a small child to 48 and centres it', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxTapTarget(child: SizedBox.square(dimension: 20)),
    );
    expect(
      tester.getSize(find.byType(MxTapTarget)),
      const Size.square(AppSize.tapTarget),
    );
  });
}
```

Create `test/shared/widgets/mx_row_ink_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('MxRowInk taps, and does nothing without onTap', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(onTap: () => taps++, child: const Text('Row')),
    );
    await tester.tap(find.text('Row'));
    expect(taps, 1);
    await pumpMx(tester, const MxRowInk(onTap: null, child: Text('Row')));
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
```

Create `test/shared/widgets/mx_focus_ring_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('MxFocusRing paints only when it is told to', (tester) async {
    Finder ring() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.foregroundPainter != null,
    );
    await pumpMx(
      tester,
      const MxFocusRing(
        borderRadius: BorderRadius.zero,
        isShown: true,
        child: SizedBox.square(dimension: 20),
      ),
    );
    expect(ring(), findsOneWidget);
    await pumpMx(
      tester,
      const MxFocusRing(
        borderRadius: BorderRadius.zero,
        isShown: false,
        child: SizedBox.square(dimension: 20),
      ),
    );
    expect(ring(), findsNothing);
  });
}
```

In `tools/docs/test_design_catalog.py`, add to `InkVocabularyTest`:

```python
    def test_a_catalogued_component_file_name_is_allowed(self):
        root = tree({"lib/x.dart": "import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';\n"})
        self.assertEqual(dc.check_ink_vocabulary(root, frozenset({"MxRowInk"})), [])
        self.assertEqual(len(dc.check_ink_vocabulary(root)), 1)
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets`
Expected: compile failure, because `package:memox/shared/widgets/primitives/…` is not found.

Run: `python3 tools/docs/test_design_catalog.py`
Expected: 1 failure (`test_a_catalogued_component_file_name_is_allowed`).

- [ ] **Step 3: Write the primitives**

Create `lib/shared/widgets/primitives/mx_focus_ring.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The 2dp `primary` ring a control shows while it holds keyboard focus,
/// 2dp outside its edge (DESIGN.md, Shapes). It listens to the focus of the
/// focusable inside [child] and paints only in traditional (keyboard)
/// highlight mode, so a tap never leaves a ring behind.
class MxFocusRing extends StatefulWidget {
  const MxFocusRing({
    required this.borderRadius,
    required this.child,
    this.paintedHeight,
    this.isShown,
    super.key,
  });

  /// The control's own corner radius; the ring follows it, grown by the offset.
  final BorderRadius borderRadius;

  /// The painted height of a control whose box is padded to the 48 target
  /// (a 32 compact button): the ring hugs the paint, not the hit area.
  final double? paintedHeight;

  /// Set by a control that tracks its own focus highlight (one built on
  /// `FocusableActionDetector`); `null` lets the ring listen for itself.
  final bool? isShown;
  final Widget child;

  @override
  State<MxFocusRing> createState() => _MxFocusRingState();
}

class _MxFocusRingState extends State<MxFocusRing> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool isVisible =
        widget.isShown ??
        (_focused &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: CustomPaint(
        foregroundPainter: isVisible
            ? _RingPainter(
                color: context.colors.primary,
                borderRadius: widget.borderRadius,
                paintedHeight: widget.paintedHeight,
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.borderRadius,
    this.paintedHeight,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double? paintedHeight;

  @override
  void paint(Canvas canvas, Size size) {
    const double grow = AppSize.focusOffset + AppStroke.focus / 2;
    final double height = paintedHeight ?? size.height;
    final Rect paint = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width,
      height: height < size.height ? height : size.height,
    );
    final RRect ring = borderRadius
        .resolve(TextDirection.ltr)
        .toRRect(paint)
        .inflate(grow);
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.focus
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.paintedHeight != paintedHeight;
}
```

Create `lib/shared/widgets/primitives/mx_tap_target.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_size.dart';

/// Guarantees the 48×48 hit area around a control painted smaller (DESIGN.md,
/// "The 48 Floor Rule"): the child paints at its own size, centred.
class MxTapTarget extends StatelessWidget {
  const MxTapTarget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSize.tapTarget,
        minHeight: AppSize.tapTarget,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
```

Create `lib/shared/widgets/primitives/mx_row_ink.dart`:

```dart
import 'package:flutter/material.dart';

/// The press and ripple every tappable row shares: the theme's splash, no
/// hover, clipped to the row's own corners.
class MxRowInk extends StatelessWidget {
  const MxRowInk({
    required this.onTap,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  /// `null` makes the row inert: no ripple and no tap.
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
    );
  }
}
```

- [ ] **Step 4: The ink scan knows catalogued file names**

In `tools/docs/design_catalog.py`, add above `check_ink_vocabulary`:

```python
def _word_at(line: str, match: re.Match[str]) -> str:
    """The whole identifier a match sits in (`mx_row_ink` around `row_ink`)."""
    start, end = match.start(), match.end()
    while start > 0 and (line[start - 1].isalnum() or line[start - 1] == "_"):
        start -= 1
    while end < len(line) and (line[end].isalnum() or line[end] == "_"):
        end += 1
    return line[start:end]
```

and inside `check_ink_vocabulary`, add `allowed_files = {snake(name) for name in allowed}` after the docstring. Replace

```python
                matches = [*PROSE_INK.finditer(line), *CAMEL_INK.finditer(line), *SNAKE_INK.finditer(line)]
```

with

```python
                matches = [*PROSE_INK.finditer(line), *CAMEL_INK.finditer(line)]
                matches += [m for m in SNAKE_INK.finditer(line) if _word_at(line, m) not in allowed_files]
```

- [ ] **Step 5: Guard housekeeping**

In `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`, delete the three `targets_pending` entries of `memox.architecture.widget_no_database_access`, `memox.architecture.widget_no_repository_access` and `memox_v8.design_system.no_flat_style_from`. Then extend the comment above them so its last sentence reads:

```yaml
    # presentation and its visual audits. SP3a Phase 2's shared widgets gave the
    # two widget-access rules and `no_flat_style_from` their targets.
```

- [ ] **Step 6: Catalog**

Insert these rows directly above the `| MxButton |` row of `### Catalog`:

```markdown
| MxFocusRing | The 2dp keyboard focus ring at a 2dp offset | primitive | MxButton, MxIconButton, MxFab, MxToggle | SP3a | built |
| MxTapTarget | Grows a small control's hit area to 48 | primitive | MxToggle, MxFilterChip, MxChipTrigger | SP3a | built |
```

Set the `Status` cell of `MxRowInk` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxRowInk
- Variants: one; `borderRadius` clips the ripple to the row's corners
- States: resting, pressed, inert (no `onTap`)
- Accessibility: adds no semantics of its own; the row it wraps names itself
- Tokens: the theme's splash (`on-surface` at `AppOpacity.pressed`), no hover
- Golden: none — paints only the press, seen in the rows that use it

#### MxFocusRing
- Variants: listens to the focus inside it, or is driven by `isShown`
- States: hidden, shown (keyboard highlight only)
- Accessibility: the visible focus of every Mx control; never shown after a tap
- Tokens: `primary`, `AppStroke.focus`, `AppSize.focusOffset`
- Golden: none — a ring around another component, covered by that component's tests

#### MxTapTarget
- Variants: one
- States: one
- Accessibility: guarantees the 48 × 48 hit area ("The 48 Floor Rule")
- Tokens: `AppSize.tapTarget`
- Golden: none — paints nothing
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

Run:
- `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets` → all pass;
- `python3 tools/docs/test_design_catalog.py` → `OK`;
- `flutter analyze lib/shared test/shared` → `No issues found!`;
- `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0 | Warnings: 0`.

```bash
git add lib/shared test/shared tools/docs code-verification-guard-v2 DESIGN.md
git commit -m "feat(sp3a-p2): focus ring, tap target and row ink primitives"
```

---

### Task 3: MxSpinner and MxButton

**Files:**
- Create: `lib/core/theme/components/button_style.dart`, `lib/shared/widgets/mx_spinner.dart`, `lib/shared/widgets/mx_button.dart`
- Modify: `lib/core/theme/app_theme.dart` (filled, outlined and text button slots)
- Test: `test/shared/widgets/mx_spinner_test.dart`, `mx_button_test.dart`; goldens `mx_spinner_golden_test.dart`, `mx_button_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxFocusRing`, `context.colors`, `.semanticColors` and `.texts`, `AppSize`, `AppIconSize`.
- Produces:
  - `MxButtonTone` (`primary`, `secondary`, `outline`, `text`, `destructive`, `dangerSoft`, `warning`);
  - `MxButtonSize` (`regular`, `small`, `compact`, `chip`, `study`);
  - `mxButtonStyle({colors, semantic, texts, tone, size})`;
  - `MxButton({label, onPressed, tone, size, icon, brandMark, detail, isLoading})`;
  - `MxSpinner({semanticLabel, size, tone})`, with `MxSpinnerSize` and `MxSpinnerTone` (`primary`, `inherit`).

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_spinner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import 'support/mx_harness.dart';

void main() {
  for (final size in MxSpinnerSize.values) {
    testWidgets('${size.name} is ${size.extent} square', (tester) async {
      await pumpMx(tester, MxSpinner(semanticLabel: 'Loading', size: size));
      expect(tester.getSize(find.byType(MxSpinner)), Size.square(size.extent));
    });
  }

  testWidgets('it is read by its label, and silent without one', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner(semanticLabel: 'Loading decks'));
    expect(find.bySemanticsLabel('Loading decks'), findsOneWidget);
    await pumpMx(tester, const MxSpinner());
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
  });

  testWidgets('it turns, and stands still under reduced motion', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner(semanticLabel: 'Loading'));
    final RotationTransition turn = tester.widget(
      find.descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(RotationTransition),
      ),
    );
    final double before = turn.turns.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(turn.turns.value, isNot(before));
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MxSpinner(semanticLabel: 'Loading'),
        ),
      ),
    );
    final RotationTransition still = tester.widget(
      find.descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(RotationTransition),
      ),
    );
    final double at = still.turns.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(still.turns.value, at);
  });
}
```

Create `test/shared/widgets/mx_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import 'support/mx_harness.dart';

Color? _fill(WidgetTester tester) => tester
    .widget<TextButton>(find.byType(TextButton))
    .style!
    .backgroundColor!
    .resolve(<WidgetState>{});

Color? _content(WidgetTester tester) => tester
    .widget<TextButton>(find.byType(TextButton))
    .style!
    .foregroundColor!
    .resolve(<WidgetState>{});

Size _painted(WidgetTester tester) => tester.getSize(
  find.descendant(of: find.byType(TextButton), matching: find.byType(Material)),
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxButtonTone, (Color, Color)> pairs = {
      MxButtonTone.primary: (s.primary, s.onPrimary),
      MxButtonTone.secondary: (s.surfaceContainer, s.onSurface),
      MxButtonTone.outline: (Colors.transparent, s.primary),
      MxButtonTone.text: (Colors.transparent, s.primary),
      MxButtonTone.destructive: (s.error, s.onError),
      MxButtonTone.dangerSoft: (s.errorContainer, s.onErrorContainer),
      MxButtonTone.warning: (x.warning, x.onWarning),
    };
    for (final MapEntry(key: tone, value: (fill, content)) in pairs.entries) {
      testWidgets('$name: ${tone.name} paints its role pair', (tester) async {
        await pumpMx(
          tester,
          MxButton(label: 'Go', tone: tone, onPressed: () {}),
          theme: theme,
        );
        expect(_fill(tester), fill);
        expect(_content(tester), content);
      });
    }

    testWidgets('$name: the theme slots are the same style as MxButton', (
      tester,
    ) async {
      final Map<ButtonStyle?, MxButtonTone> slots = {
        theme.filledButtonTheme.style: MxButtonTone.primary,
        theme.outlinedButtonTheme.style: MxButtonTone.outline,
        theme.textButtonTheme.style: MxButtonTone.text,
      };
      for (final MapEntry(key: style, value: tone) in slots.entries) {
        expect(style!.backgroundColor!.resolve({}), pairs[tone]!.$1);
        expect(style.foregroundColor!.resolve({}), pairs[tone]!.$2);
      }
    });
  }

  testWidgets('outline draws an outline edge; the others draw none', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final BorderSide edge = tester
        .widget<TextButton>(find.byType(TextButton))
        .style!
        .side!
        .resolve({})!;
    expect(edge.color, s.outline);
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () {}));
    expect(
      tester
          .widget<TextButton>(find.byType(TextButton))
          .style!
          .side!
          .resolve({}),
      BorderSide.none,
    );
  });

  for (final size in MxButtonSize.values) {
    testWidgets('${size.name} paints ${size.height} and hits at least 48', (
      tester,
    ) async {
      await pumpMx(tester, MxButton(label: 'Go', size: size, onPressed: () {}));
      expect(_painted(tester).height, size.height);
      final Size hit = tester.getSize(find.byType(TextButton));
      expect(hit.height, greaterThanOrEqualTo(AppSize.tapTarget));
      expect(hit.width, greaterThanOrEqualTo(AppSize.tapTarget));
    });
  }

  testWidgets('a disabled button is dimmed and announced as disabled', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpMx(tester, const MxButton(label: 'Go', onPressed: null));
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      AppOpacity.disabled,
    );
    expect(
      tester.getSemantics(find.byType(TextButton)),
      matchesSemantics(
        label: 'Go',
        isButton: true,
        hasEnabledState: true,
        isFocusable: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('loading keeps the width, shows a spinner and blocks taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxButton(label: 'Save the deck', onPressed: () => taps++),
    );
    final double width = tester.getSize(find.byType(TextButton)).width;
    await pumpMx(
      tester,
      MxButton(
        label: 'Save the deck',
        isLoading: true,
        onPressed: () => taps++,
      ),
    );
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(tester.getSize(find.byType(TextButton)).width, width);
    expect(find.byType(Opacity), findsNothing);
    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    expect(taps, 0);
    expect(find.bySemanticsLabel('Save the deck'), findsOneWidget);
  });

  testWidgets('a regular label wraps to two lines; compact keeps one', (
    tester,
  ) async {
    const String long = 'Import the cards from a file you exported before';
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: MxButton(label: long, onPressed: () {}),
      ),
    );
    expect(tester.widget<Text>(find.text(long)).maxLines, 2);
    expect(_painted(tester).height, greaterThan(AppSize.buttonRegular));
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: MxButton(
          label: long,
          size: MxButtonSize.compact,
          onPressed: () {},
        ),
      ),
    );
    expect(tester.widget<Text>(find.text(long)).maxLines, 1);
    expect(_painted(tester).height, AppSize.buttonCompact);
  });

  testWidgets('the detail line takes the button content colour', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Study', detail: 'Overdue first', onPressed: () {}),
      theme: mxThemes['dark'],
    );
    final RenderParagraph line = tester.renderObject(
      find.text('Overdue first'),
    );
    expect(line.text.style!.color, mxThemes['dark']!.colorScheme.onPrimary);
  });

  testWidgets('the icon leads the label, on the right in RTL', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Add', icon: Icons.add, onPressed: () {}),
      textDirection: TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.byIcon(Icons.add)).dx,
      greaterThan(tester.getCenter(find.text('Add')).dx),
    );
  });

  testWidgets('a keyboard focus draws the focus ring; a tap does not', (
    tester,
  ) async {
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () {}));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final Finder ring = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.foregroundPainter != null,
    );
    expect(ring, findsOneWidget);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_spinner_test.dart test/shared/widgets/mx_button_test.dart`
Expected: compile failure, because `mx_spinner.dart` and `mx_button.dart` are not found.

- [ ] **Step 3: The style and the widgets**

Create `lib/core/theme/components/button_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// What a button means (DESIGN.md, Components › Actions).
enum MxButtonTone {
  /// The one action of a decision: `primary` under `on-primary`.
  primary,

  /// A neutral alternative: `surface-container` under `on-surface`.
  secondary,

  /// A lesser alternative with an `outline` edge and `primary` text.
  outline,

  /// The quiet action beside a decision's fill: no fill, no edge.
  text,

  /// An action that destroys: `error` under `on-error`.
  destructive,

  /// A destructive action that is not the decision: `error-container`.
  dangerSoft,

  /// A refusal or limit where nothing is lost: `warning` under `on-warning`.
  warning,
}

/// A button's geometry; the caller never passes a size or a padding.
enum MxButtonSize {
  regular(AppSize.buttonRegular, AppSpacing.gutter, AppRadius.md),
  small(AppSize.buttonSmall, AppSpacing.gutter, AppRadius.md),
  compact(AppSize.buttonCompact, AppSpacing.grouped, AppRadius.sm),
  chip(AppSize.buttonChip, AppSpacing.grouped, AppRadius.full),
  study(AppSize.buttonRegular, AppSize.buttonStudyPadding, AppRadius.full);

  const MxButtonSize(this.height, this.horizontalPadding, this.radius);

  /// The painted height; the hit area is never under 48.
  final double height;
  final double horizontalPadding;
  final double radius;

  /// Regular labels wrap to two lines; every other size keeps one.
  int get maxLines => this == MxButtonSize.regular ? 2 : 1;

  /// Compact and chip buttons use the small label (DESIGN.md, Typography).
  bool get usesSmallLabel =>
      this == MxButtonSize.compact || this == MxButtonSize.chip;
}

/// The single source of every button's look: `AppTheme` fills the filled,
/// outlined and text button slots from it, and `MxButton` passes it, so a
/// raw button and an `MxButton` of the same tone cannot differ.
ButtonStyle mxButtonStyle({
  required ColorScheme colors,
  required AppSemanticColors semantic,
  required TextTheme texts,
  required MxButtonTone tone,
  MxButtonSize size = MxButtonSize.regular,
}) {
  final (Color fill, Color content) = switch (tone) {
    MxButtonTone.primary => (colors.primary, colors.onPrimary),
    MxButtonTone.secondary => (colors.surfaceContainer, colors.onSurface),
    MxButtonTone.outline => (Colors.transparent, colors.primary),
    MxButtonTone.text => (Colors.transparent, colors.primary),
    MxButtonTone.destructive => (colors.error, colors.onError),
    MxButtonTone.dangerSoft => (colors.errorContainer, colors.onErrorContainer),
    MxButtonTone.warning => (semantic.warning, semantic.onWarning),
  };
  final BorderSide edge = tone == MxButtonTone.outline
      ? BorderSide(color: colors.outline, width: AppStroke.hairline)
      : BorderSide.none;
  final OutlinedBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(size.radius),
    side: edge,
  );
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(fill),
    foregroundColor: WidgetStatePropertyAll<Color>(content),
    iconColor: WidgetStatePropertyAll<Color>(content),
    overlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.pressed)
          ? content.withValues(alpha: AppOpacity.pressed)
          : Colors.transparent,
    ),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    elevation: const WidgetStatePropertyAll<double>(0),
    textStyle: WidgetStatePropertyAll<TextStyle?>(
      size.usesSmallLabel ? texts.labelSmall : texts.labelLarge,
    ),
    iconSize: const WidgetStatePropertyAll<double>(AppIconSize.small),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: size == MxButtonSize.regular ? AppSpacing.micro : 0,
      ),
    ),
    minimumSize: WidgetStatePropertyAll<Size>(Size(0, size.height)),
    shape: WidgetStatePropertyAll<OutlinedBorder>(shape),
    side: WidgetStatePropertyAll<BorderSide>(edge),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    alignment: Alignment.center,
  );
}
```

Create `lib/shared/widgets/mx_spinner.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The four spinner sizes (DESIGN.md, Feedback and Status).
enum MxSpinnerSize {
  small(AppSize.spinnerSmall),
  medium(AppSize.spinnerMedium),
  large(AppSize.spinnerLarge),
  xlarge(AppSize.spinnerXlarge);

  const MxSpinnerSize(this.extent);

  final double extent;
}

/// Who colours the spinner: `primary` on its own, or the content colour of
/// the control it sits in (a button's label colour while it loads).
enum MxSpinnerTone { primary, inherit }

/// An indeterminate wait: a three-quarter arc turning once every 800 ms. Still
/// when the platform asks for reduced motion.
class MxSpinner extends StatefulWidget {
  const MxSpinner({
    this.semanticLabel,
    this.size = MxSpinnerSize.medium,
    this.tone = MxSpinnerTone.primary,
    super.key,
  });

  /// What is being waited for, read aloud; `null` only inside a control that
  /// already names the wait (a loading button keeps its own label).
  final String? semanticLabel;
  final MxSpinnerSize size;
  final MxSpinnerTone tone;

  @override
  State<MxSpinner> createState() => _MxSpinnerState();
}

class _MxSpinnerState extends State<MxSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: AppDurations.spinnerCycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
      return;
    }
    if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = switch (widget.tone) {
      MxSpinnerTone.primary => context.colors.primary,
      MxSpinnerTone.inherit =>
        IconTheme.of(context).color ?? context.colors.primary,
    };
    final Widget arc = SizedBox.square(
      dimension: widget.size.extent,
      child: RotationTransition(
        turns: _turn,
        child: CustomPaint(painter: _ArcPainter(color)),
      ),
    );
    final String? label = widget.semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: arc);
    }
    return Semantics(label: label, liveRegion: true, child: arc);
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double sweep = math.pi * 1.5;
    final Rect box = (Offset.zero & size).deflate(AppStroke.control / 2);
    canvas.drawArc(
      box,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = AppStroke.control
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
```

Create `lib/shared/widgets/mx_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/button_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

export 'package:memox/core/theme/components/button_style.dart'
    show MxButtonSize, MxButtonTone;

/// A text-labelled action (DESIGN.md, Components › Actions). The caller picks
/// a tone and a size; colours, padding, radius and states belong here.
class MxButton extends StatelessWidget {
  const MxButton({
    required this.label,
    required this.onPressed,
    this.tone = MxButtonTone.primary,
    this.size = MxButtonSize.regular,
    this.icon,
    this.brandMark,
    this.detail,
    this.isLoading = false,
    super.key,
  });

  final String label;

  /// `null` disables the button, drawn at `AppOpacity.disabled`.
  final VoidCallback? onPressed;
  final MxButtonTone tone;
  final MxButtonSize size;

  /// A 16dp glyph before the label.
  final IconData? icon;

  /// An 18dp brand image in the glyph's place (Google's G), never read aloud.
  final ImageProvider? brandMark;

  /// A second, smaller line under a regular button's label.
  final String? detail;

  /// Swaps the label for a spinner at the same width and blocks taps.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = mxButtonStyle(
      colors: context.colors,
      semantic: context.semanticColors,
      texts: context.texts,
      tone: tone,
      size: size,
    );
    final bool isEnabled = onPressed != null;
    Widget content = _Content(
      label: label,
      size: size,
      icon: icon,
      brandMark: brandMark,
      detail: size == MxButtonSize.regular ? detail : null,
    );
    if (isLoading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            maintainSemantics: true,
            child: content,
          ),
          const MxSpinner(
            size: MxSpinnerSize.small,
            tone: MxSpinnerTone.inherit,
          ),
        ],
      );
    }
    final Widget button = MxFocusRing(
      borderRadius: BorderRadius.circular(size.radius),
      paintedHeight: size.height,
      child: TextButton(
        style: style,
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
    if (isEnabled) {
      return button;
    }
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.size,
    this.icon,
    this.brandMark,
    this.detail,
  });

  final String label;
  final MxButtonSize size;
  final IconData? icon;
  final ImageProvider? brandMark;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final Widget? lead = _lead();
    Widget text = Text(
      label,
      maxLines: size.maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    final String? line = detail;
    if (line != null) {
      text = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // The caption role without a colour, so the line takes the
            // button's content colour like the label does.
            style: AppTextStyles.caption,
          ),
        ],
      );
    }
    if (lead == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        lead,
        const SizedBox(width: AppSpacing.control),
        Flexible(child: text),
      ],
    );
  }

  Widget? _lead() {
    final ImageProvider? mark = brandMark;
    if (mark != null) {
      return ExcludeSemantics(
        child: Image(
          image: mark,
          width: AppIconSize.mark,
          height: AppIconSize.mark,
        ),
      );
    }
    final IconData? glyph = icon;
    if (glyph == null) {
      return null;
    }
    return Icon(glyph);
  }
}
```

In `lib/core/theme/app_theme.dart`, add `import 'package:memox/core/theme/components/button_style.dart';`. Then add these slots to the `ThemeData(...)` call, after `extensions: <AppSemanticColors>[semantic],`:

```dart
      filledButtonTheme: FilledButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.outline,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.text,
        ),
      ),
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_spinner_test.dart test/shared/widgets/mx_button_test.dart test/core/theme`
Expected: all pass.

- [ ] **Step 5: Goldens**

Create `test/shared/widgets/mx_spinner_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('spinner', 'sizes'): () => Wrap(
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in MxSpinnerSize.values)
          MxSpinner(semanticLabel: 'Loading', size: size),
      ],
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Create `test/shared/widgets/mx_button_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<String, Widget> sheets = {
    'tones': Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tone in MxButtonTone.values) ...[
          MxButton(label: tone.name, tone: tone, onPressed: () {}),
          MxButton(label: tone.name, tone: tone, onPressed: null),
        ],
      ],
    ),
    'sizes': Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in MxButtonSize.values)
          MxButton(label: size.name, size: size, onPressed: () {}),
        for (final size in MxButtonSize.values)
          MxButton(
            label: size.name,
            size: size,
            tone: MxButtonTone.outline,
            icon: Icons.add,
            onPressed: () {},
          ),
      ],
    ),
    'states': SizedBox(
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          MxButton(label: 'Saving the deck', isLoading: true, onPressed: () {}),
          MxButton(
            label: 'Study this deck · 4 due',
            detail: 'Overdue first, then today',
            onPressed: () {},
          ),
          SizedBox(
            width: 220,
            child: MxButton(
              label: 'Import the cards from a file you exported before',
              tone: MxButtonTone.secondary,
              onPressed: () {},
            ),
          ),
          MxButton(
            label: 'Move to Trash',
            tone: MxButtonTone.destructive,
            icon: Icons.delete_outline,
            onPressed: () {},
          ),
        ],
      ),
    ),
  };
  for (final MapEntry(key: state, value: sheet) in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_button $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: 'button',
          state: state,
          variant: variant,
          sheet: sheet,
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_spinner_golden_test.dart test/shared/widgets/mx_button_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_spinner__*__light.png` / `__dark.png`, `mx_button__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

- [ ] **Step 6: Catalog**

Set the `Status` cell of `MxSpinner`, `MxButton` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxSpinner
- Variants: sizes small, medium, large, xlarge; tones primary, inherit
- States: turning, still (reduced motion)
- Accessibility: a live region named by `semanticLabel`; silent inside a control that already names the wait
- Tokens: `primary`; `AppStroke.control`; `AppDurations.spinnerCycle`; `AppSize.spinner*`
- Golden: sizes__light, sizes__dark

#### MxButton
- Variants: tones primary, secondary, outline, text, destructive, dangerSoft, warning; sizes regular, small, compact, chip, study; optional icon, brand mark, detail line
- States: enabled, pressed, focused, disabled (`AppOpacity.disabled`), loading
- Accessibility: a button named by its label; disabled announced; loading keeps the label and blocks taps; 48 hit at every size; the brand mark is never read
- Tokens: `primary`, `on-primary`, `surface-container`, `on-surface`, `outline`, `error`, `on-error`, `error-container`, `on-error-container`, `warning`, `on-warning`; `labelLarge` (`labelSmall` for compact and chip); `AppRadius.md` / `sm` / `full`; `AppSize.button*`
- Golden: tones__light, tones__dark, sizes__light, sizes__dark, states__light, states__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

Run: `flutter analyze lib test/shared test/core` → `No issues found!`; run the guard (Task 2, Step 7) → 0 errors.

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p2): MxSpinner and MxButton, one style for the button slots and the widget"
```

---

### Task 4: MxIconButton and MxFab

**Files:**
- Create: `lib/core/theme/components/icon_button_style.dart`, `lib/shared/widgets/mx_icon_button.dart`, `lib/shared/widgets/mx_fab.dart`
- Modify: `lib/core/theme/app_theme.dart` (icon button and FAB slots)
- Test: `test/shared/widgets/mx_icon_button_test.dart`, `mx_fab_test.dart`; golden `mx_actions_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxFocusRing`, `AppShadows`, `AppSize`.
- Produces:
  - `MxIconButtonTone` (`standard`, `accent`, `destructive`) and `mxIconButtonStyle({colors, tone})`;
  - `MxIconButton({icon, semanticLabel, onPressed, tone})`;
  - `MxFab({icon, semanticLabel, onPressed})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_icon_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final Map<MxIconButtonTone, Color> inks = {
      MxIconButtonTone.standard: s.onSurfaceVariant,
      MxIconButtonTone.accent: s.primary,
      MxIconButtonTone.destructive: s.error,
    };
    for (final MapEntry(key: tone, value: ink) in inks.entries) {
      testWidgets('$name: ${tone.name} draws its glyph in its role', (
        tester,
      ) async {
        await pumpMx(
          tester,
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: 'More',
            tone: tone,
            onPressed: () {},
          ),
          theme: theme,
        );
        final IconButton button = tester.widget(find.byType(IconButton));
        expect(button.style!.foregroundColor!.resolve({}), ink);
      });
    }
    testWidgets('$name: the theme slot is the standard style', (tester) async {
      expect(
        theme.iconButtonTheme.style!.foregroundColor!.resolve({}),
        s.onSurfaceVariant,
      );
    });
  }

  testWidgets('a 20 glyph in a 36 circle with a 48 hit', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(icon: Icons.close, semanticLabel: 'Close', onPressed: () {}),
    );
    expect(tester.getSize(find.byIcon(Icons.close)).width, AppIconSize.medium);
    final Size painted = tester.getSize(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Material),
      ),
    );
    expect(painted, const Size.square(AppSize.iconButton));
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
  });

  testWidgets('it is read by its label and is dimmed when disabled', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxIconButton(
        icon: Icons.close,
        semanticLabel: 'Close',
        onPressed: null,
      ),
    );
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      AppOpacity.disabled,
    );
  });
}
```

Create `test/shared/widgets/mx_fab_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: a 52 primary square read by its label', (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxFab(
          icon: Icons.add,
          semanticLabel: 'New deck',
          onPressed: () => taps++,
        ),
        theme: theme,
      );
      expect(
        tester.getSize(find.byType(FloatingActionButton)),
        const Size.square(AppSize.fab),
      );
      final Material fill = tester.widget(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Material),
        ),
      );
      expect(fill.color, theme.colorScheme.primary);
      expect(find.byTooltip('New deck'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(taps, 1);
    });
  }
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_icon_button_test.dart test/shared/widgets/mx_fab_test.dart`
Expected: compile failure, because the two widgets are not found.

- [ ] **Step 3: The style, the widgets and the slots**

Create `lib/core/theme/components/icon_button_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';

/// What an icon-only action means (flutter-theme-design §19).
enum MxIconButtonTone {
  /// A quiet tool: `on-surface-variant`.
  standard,

  /// An indigo action: `primary`.
  accent,

  /// An action that destroys: `error`.
  destructive,
}

/// A 20dp glyph in a 36dp round ink box with a 48dp hit (DESIGN.md, Actions);
/// `AppTheme`'s icon button slot and `MxIconButton` share it.
ButtonStyle mxIconButtonStyle({
  required ColorScheme colors,
  MxIconButtonTone tone = MxIconButtonTone.standard,
}) {
  final Color content = switch (tone) {
    MxIconButtonTone.standard => colors.onSurfaceVariant,
    MxIconButtonTone.accent => colors.primary,
    MxIconButtonTone.destructive => colors.error,
  };
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll<Color>(content),
    iconColor: WidgetStatePropertyAll<Color>(content),
    backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    overlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.pressed)
          ? content.withValues(alpha: AppOpacity.pressed)
          : Colors.transparent,
    ),
    iconSize: const WidgetStatePropertyAll<double>(AppIconSize.medium),
    fixedSize: const WidgetStatePropertyAll<Size>(
      Size.square(AppSize.iconButton),
    ),
    minimumSize: const WidgetStatePropertyAll<Size>(
      Size.square(AppSize.iconButton),
    ),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
    shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
  );
}
```

Create `lib/shared/widgets/mx_icon_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/icon_button_style.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

export 'package:memox/core/theme/components/icon_button_style.dart'
    show MxIconButtonTone;

/// An icon-only action. It always has a name: [semanticLabel] is read aloud
/// and shown as the long-press tooltip.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tone = MxIconButtonTone.standard,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;

  /// `null` disables the button, drawn at `AppOpacity.disabled`.
  final VoidCallback? onPressed;
  final MxIconButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final Widget button = MxFocusRing(
      borderRadius: BorderRadius.circular(AppSize.iconButton / 2),
      paintedHeight: AppSize.iconButton,
      child: IconButton(
        style: mxIconButtonStyle(colors: context.colors, tone: tone),
        tooltip: semanticLabel,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
    if (onPressed != null) {
      return button;
    }
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}
```

Create `lib/shared/widgets/mx_fab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

/// The screen's floating creation action: a 52dp `primary` square, r16, icon
/// only, with the FAB shadow (DESIGN.md, Actions; Elevation & Depth).
class MxFab extends StatelessWidget {
  const MxFab({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;

  /// Read aloud and shown as the tooltip: the FAB has no visible label.
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppShadow shadow = isDark ? AppShadows.fabDark : AppShadows.fabLight;
    return MxFocusRing(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [shadow.on(context.colors.shadow)],
        ),
        child: FloatingActionButton(
          heroTag: null,
          tooltip: semanticLabel,
          onPressed: onPressed,
          child: Icon(icon),
        ),
      ),
    );
  }
}
```

In `lib/core/theme/app_theme.dart`, add these imports: `components/icon_button_style.dart`, `foundations/app_icon_size.dart`, `foundations/app_radius.dart` and `foundations/app_size.dart`. Then add these slots:

```dart
      iconButtonTheme: IconButtonThemeData(
        style: mxIconButtonStyle(colors: scheme),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        splashColor: scheme.onPrimary.withValues(alpha: AppOpacity.pressed),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        iconSize: AppIconSize.large,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSize.fab,
          height: AppSize.fab,
        ),
      ),
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets test/core/theme`
Expected: all pass.

- [ ] **Step 5: Golden**

Create `test/shared/widgets/mx_actions_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/mx_harness.dart';

void main() {
  for (final variant in mxThemes.keys) {
    testWidgets('mx_icon_button tones $variant', (tester) async {
      await expectMxGolden(
        tester,
        component: 'icon_button',
        state: 'tones',
        variant: variant,
        sheet: Wrap(
          children: [
            for (final tone in MxIconButtonTone.values) ...[
              MxIconButton(
                icon: Icons.more_vert,
                semanticLabel: 'More',
                tone: tone,
                onPressed: () {},
              ),
              MxIconButton(
                icon: Icons.more_vert,
                semanticLabel: 'More',
                tone: tone,
                onPressed: null,
              ),
            ],
          ],
        ),
      );
    });
    testWidgets('mx_fab resting $variant', (tester) async {
      await expectMxGolden(
        tester,
        component: 'fab',
        state: 'resting',
        variant: variant,
        sheet: Padding(
          padding: const EdgeInsets.all(16),
          child: MxFab(
            icon: Icons.add,
            semanticLabel: 'New deck',
            onPressed: () {},
          ),
        ),
      );
    });
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_actions_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_icon_button__*__light.png` / `__dark.png`, `mx_fab__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

The FAB's shadow renders with a hard edge in tests, because `flutter_test` disables shadow blur (`debugDisableShadows`). That is expected.

- [ ] **Step 6: Catalog**

Set the `Status` cell of `MxIconButton`, `MxFab` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxIconButton
- Variants: standard, accent, destructive
- States: enabled, pressed, focused, disabled
- Accessibility: `semanticLabel` is required, read aloud and shown as the tooltip; 36 painted, 48 hit
- Tokens: `on-surface-variant`, `primary`, `error`; `AppIconSize.medium`; `AppSize.iconButton`
- Golden: tones__light, tones__dark

#### MxFab
- Variants: one; icon only, no extended form
- States: resting, pressed, focused
- Accessibility: `semanticLabel` is required; 52 square
- Tokens: `primary`, `on-primary`, `shadow`; `AppShadows.fab*`; `AppRadius.lg`; `AppSize.fab`
- Golden: resting__light, resting__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

Run: analyze and the guard as in Task 3, Step 7.

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p2): MxIconButton and MxFab with their theme slots"
```

---

### Task 5: MxFieldMessage and MxTextField, and the theme parity of every slot

**Files:**
- Create: `lib/core/theme/components/field_style.dart`, `lib/shared/widgets/mx_field_message.dart`, `lib/shared/widgets/mx_text_field.dart`
- Modify: `lib/core/theme/app_theme.dart` (input decoration and text selection slots)
- Test: `test/shared/widgets/mx_field_message_test.dart`, `mx_text_field_test.dart`; golden `mx_text_field_golden_test.dart`; `test/core/theme/app_theme_test.dart` (slot parity)
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Produces:
  - `MxTextFieldVariant` (`form`, `detail`, `meaning`, `term`, `code`, `study`);
  - `mxInputDecorationTheme`, `mxFieldPadding`, `mxFieldTextStyle`, `mxFieldRadius`, `mxFieldMinHeight`, `mxFieldBorder`, `mxFieldLabelStyle`, `mxRequiredStyle`;
  - `MxFieldMessage({message, tone})` with `MxFieldMessageTone` (`error`, `warning`);
  - `MxTextField({controller, variant, label, requiredText, hint, message, messageTone, onChanged, onSubmitted, focusNode, isEnabled, shouldAutofocus, isObscured, keyboardType, textInputAction})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_field_message_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a message is announced as it appears', (tester) async {
    await pumpMx(tester, const MxFieldMessage(message: 'Enter a name'));
    expect(
      tester.getSemantics(find.text('Enter a name')),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets('each tone writes in its role', (tester) async {
    final ThemeData theme = mxThemes['light']!;
    await pumpMx(tester, const MxFieldMessage(message: 'Too long'));
    expect(
      tester.widget<Text>(find.text('Too long')).style!.color,
      theme.colorScheme.error,
    );
    await pumpMx(
      tester,
      const MxFieldMessage(message: 'Close', tone: MxFieldMessageTone.warning),
    );
    expect(
      tester.widget<Icon>(find.byType(Icon)).color,
      theme.extension<AppSemanticColors>()!.warning,
    );
  });
}
```

Create `test/shared/widgets/mx_text_field_test.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/mx_harness.dart';

OutlineInputBorder _enabledEdge(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!.enabledBorder!
        as OutlineInputBorder;

/// The height the fill and the edge are painted at: one line of the field's
/// style plus its padding. An outer `constraints` box would make the widget
/// taller than this without growing the paint, so none may be set.
double _paintedHeight(WidgetTester tester) {
  final TextField field = tester.widget(find.byType(TextField));
  final InputDecoration decoration = field.decoration!;
  expect(decoration.constraints, isNull);
  final EdgeInsets padding = decoration.contentPadding! as EdgeInsets;
  final TextStyle style = field.style!;
  return padding.vertical + style.fontSize! * style.height!;
}

void main() {
  testWidgets('form: 52 tall on the muted fill with an outline-variant edge', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(controller: TextEditingController()),
      ),
    );
    expect(tester.getSize(find.byType(TextField)).height, AppSize.field);
    expect(_paintedHeight(tester), AppSize.field);
    expect(_enabledEdge(tester).borderSide.color, s.outlineVariant);
  });

  testWidgets('an error turns the edge to error and shows its message', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Name',
          message: 'Enter a name',
        ),
      ),
    );
    expect(_enabledEdge(tester).borderSide.color, s.error);
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(find.text('Enter a name'), findsOneWidget);
  });

  testWidgets('a warning keeps the edge and shows its message', (tester) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          message: 'Close to the limit',
          messageTone: MxFieldMessageTone.warning,
        ),
      ),
    );
    expect(_enabledEdge(tester).borderSide.color, s.outlineVariant);
  });

  testWidgets('the label and the Required mark sit above the field', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Term',
          requiredText: 'Required',
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.text('Term')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('detail and meaning grow with their text', (tester) async {
    final controller = TextEditingController(text: 'one');
    await pumpMx(
      tester,
      SizedBox(
        width: 240,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.meaning,
        ),
      ),
    );
    expect(_paintedHeight(tester), AppSize.fieldMeaning);
    final double short = tester.getSize(find.byType(TextField)).height;
    controller.text = List.filled(12, 'a meaning that wraps').join(' ');
    await tester.pump();
    expect(
      tester.getSize(find.byType(InputDecorator)).height,
      greaterThan(short),
    );
  });

  testWidgets('code takes six digits only, centred', (tester) async {
    final controller = TextEditingController();
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.code,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '12a34567');
    expect(controller.text, '123456');
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.textAlign, TextAlign.center);
    expect(field.keyboardType, TextInputType.number);
  });

  testWidgets('study is bare: no fill and no edge', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          variant: MxTextFieldVariant.study,
        ),
      ),
    );
    final InputDecoration decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
  });
}
```

In `test/core/theme/app_theme_test.dart`, add inside the per-theme `group`, before `'pads every tap target to 48'`:

```dart
      test('the component slots read the same roles as the Mx widgets', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(
          theme.inputDecorationTheme.fillColor,
          isA<WidgetStateColor>(),
        );
        expect(
          theme.iconButtonTheme.style!.foregroundColor!.resolve({}),
          scheme.onSurfaceVariant,
        );
        expect(theme.floatingActionButtonTheme.backgroundColor, scheme.primary);
        expect(
          theme.floatingActionButtonTheme.foregroundColor,
          scheme.onPrimary,
        );
        expect(theme.textSelectionTheme.cursorColor, scheme.primary);
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          scheme.primary,
        );
      });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_field_message_test.dart test/shared/widgets/mx_text_field_test.dart test/core/theme`
Expected: compile failure for the two widgets. The parity test fails on `inputDecorationTheme.filled`.

- [ ] **Step 3: The style, the widgets and the slots**

Create `lib/core/theme/components/field_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The six text-field variants (DESIGN.md, Components › Inputs).
enum MxTextFieldVariant {
  /// One line on the muted fill, 52 tall.
  form,

  /// Grows from 48 with its text.
  detail,

  /// A card's meaning: body large, grows from 76, r20.
  meaning,

  /// A card's term: the headline role, r20.
  term,

  /// Six digits on one centred line, tabular and widely tracked.
  code,

  /// Bare: no fill and no edge, inside a study face.
  study,
}

/// The fill of a field: muted at rest, lighter while it has focus.
Color mxFieldFill(ColorScheme colors, Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? colors.surfaceContainerLowest
    : colors.surfaceContainerLow;

/// The field's edge, by state: `outline-variant`, `primary` on focus,
/// `error` while the field holds an error.
InputBorder mxFieldBorder({
  required Color color,
  required double radius,
  double width = AppStroke.hairline,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// The decoration `AppTheme` installs and every variant starts from.
InputDecorationThemeData mxInputDecorationTheme({
  required ColorScheme colors,
  required TextTheme texts,
}) {
  return InputDecorationThemeData(
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => mxFieldFill(colors, states),
    ),
    hintStyle: texts.bodyMedium?.apply(color: colors.onSurfaceVariant),
    contentPadding: mxFieldPadding(texts.bodyMedium, AppSize.field),
    enabledBorder: mxFieldBorder(
      color: colors.outlineVariant,
      radius: AppRadius.md,
    ),
    focusedBorder: mxFieldBorder(
      color: colors.primary,
      radius: AppRadius.md,
      width: AppStroke.control,
    ),
    errorBorder: mxFieldBorder(color: colors.error, radius: AppRadius.md),
    focusedErrorBorder: mxFieldBorder(
      color: colors.error,
      radius: AppRadius.md,
      width: AppStroke.control,
    ),
    disabledBorder: mxFieldBorder(
      color: colors.outlineVariant,
      radius: AppRadius.md,
    ),
    border: mxFieldBorder(color: colors.outlineVariant, radius: AppRadius.md),
  );
}

/// The padding that makes one line of [style] exactly [minHeight] tall, so
/// the fill and the edge are the height DESIGN.md names; more lines grow it.
EdgeInsets mxFieldPadding(TextStyle? style, double minHeight) {
  final double line = (style?.fontSize ?? 0) * (style?.height ?? 1);
  return EdgeInsets.symmetric(
    horizontal: AppSpacing.grouped,
    vertical: (minHeight - line) / 2,
  );
}

/// The text style a variant types in; component overrides of the nearest
/// role (DESIGN.md, "The Seven Roles Rule"), never new global styles.
TextStyle? mxFieldTextStyle(TextTheme texts, MxTextFieldVariant variant) {
  return switch (variant) {
    MxTextFieldVariant.meaning => texts.bodyLarge,
    MxTextFieldVariant.term => texts.headlineLarge,
    MxTextFieldVariant.code => texts.headlineLarge?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      letterSpacing: AppSpacing.control,
    ),
    _ => texts.bodyMedium,
  };
}

/// The radius of a variant: r20 for the card's two faces, r12 otherwise.
double mxFieldRadius(MxTextFieldVariant variant) => switch (variant) {
  MxTextFieldVariant.meaning || MxTextFieldVariant.term => AppRadius.xl,
  _ => AppRadius.md,
};

/// The minimum height a variant grows from.
double mxFieldMinHeight(MxTextFieldVariant variant) => switch (variant) {
  MxTextFieldVariant.detail => AppSize.fieldDetail,
  MxTextFieldVariant.meaning => AppSize.fieldMeaning,
  _ => AppSize.field,
};

/// The field label above a field: 600, 14, `on-surface` (DESIGN.md,
/// Typography › Field Label).
TextStyle? mxFieldLabelStyle(TextTheme texts) => texts.titleSmall;

/// The weight a "Required" mark keeps, smaller and in `primary`.
TextStyle? mxRequiredStyle(TextTheme texts, ColorScheme colors) =>
    AppTypography.withWeight(
      texts.bodySmall!.apply(color: colors.primary),
      FontWeight.w600,
    );
```

Create `lib/shared/widgets/mx_field_message.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Whether a field's message stops the save or only warns.
enum MxFieldMessageTone { error, warning }

/// One line under a field: a glyph and the message in the tone's role
/// (`error` or `warning`), announced when it appears.
class MxFieldMessage extends StatelessWidget {
  const MxFieldMessage({
    required this.message,
    this.tone = MxFieldMessageTone.error,
    super.key,
  });

  final String message;
  final MxFieldMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color ink, IconData glyph) = switch (tone) {
      MxFieldMessageTone.error => (context.colors.error, Icons.error_outline),
      MxFieldMessageTone.warning => (
        context.semanticColors.warning,
        Icons.warning_amber_outlined,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(glyph, size: AppIconSize.small, color: ink),
          const SizedBox(width: AppSpacing.micro),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.apply(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

export 'package:memox/core/theme/components/field_style.dart'
    show MxTextFieldVariant;
export 'package:memox/shared/widgets/mx_field_message.dart'
    show MxFieldMessageTone;

/// The digits a one-time code holds.
const int _codeLength = 6;

/// A text input (DESIGN.md, Components › Inputs). The caller names the
/// variant and supplies localized copy; fill, edges, padding and type are
/// the variant's.
class MxTextField extends StatelessWidget {
  const MxTextField({
    required this.controller,
    this.variant = MxTextFieldVariant.form,
    this.label,
    this.requiredText,
    this.hint,
    this.message,
    this.messageTone = MxFieldMessageTone.error,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.isEnabled = true,
    this.shouldAutofocus = false,
    this.isObscured = false,
    this.keyboardType,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final MxTextFieldVariant variant;

  /// The field label above the field.
  final String? label;

  /// "Required", beside the label, when the field must be filled.
  final String? requiredText;
  final String? hint;

  /// The line under the field; an error also turns the edge to `error`.
  final String? message;
  final MxFieldMessageTone messageTone;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool isEnabled;
  final bool shouldAutofocus;
  final bool isObscured;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  bool get _isCode => variant == MxTextFieldVariant.code;
  bool get _grows =>
      variant == MxTextFieldVariant.detail ||
      variant == MxTextFieldVariant.meaning ||
      variant == MxTextFieldVariant.term;

  @override
  Widget build(BuildContext context) {
    final String? line = message;
    final bool hasError =
        line != null && messageTone == MxFieldMessageTone.error;
    final Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      autofocus: shouldAutofocus,
      obscureText: isObscured,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: mxFieldTextStyle(context.texts, variant),
      textAlign: _isCode ? TextAlign.center : TextAlign.start,
      keyboardType: _isCode ? TextInputType.number : keyboardType,
      textInputAction: textInputAction,
      autofillHints: _isCode ? const [AutofillHints.oneTimeCode] : null,
      inputFormatters: _isCode
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_codeLength),
            ]
          : null,
      minLines: _grows ? 1 : null,
      maxLines: _grows ? null : 1,
      decoration: _decoration(context, hasError),
    );
    final String? title = label;
    if (title == null && line == null) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          _Label(text: title, requiredText: requiredText),
          const SizedBox(height: AppSpacing.control),
        ],
        field,
        if (line != null) ...[
          const SizedBox(height: AppSpacing.micro),
          MxFieldMessage(message: line, tone: messageTone),
        ],
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, bool hasError) {
    final ColorScheme colors = context.colors;
    final double radius = mxFieldRadius(variant);
    if (variant == MxTextFieldVariant.study) {
      return InputDecoration(
        hintText: hint,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isCollapsed: true,
      );
    }
    return InputDecoration(
      hintText: hint,
      contentPadding: mxFieldPadding(
        mxFieldTextStyle(context.texts, variant),
        mxFieldMinHeight(variant),
      ),
      enabledBorder: mxFieldBorder(
        color: hasError ? colors.error : colors.outlineVariant,
        radius: radius,
      ),
      focusedBorder: mxFieldBorder(
        color: hasError ? colors.error : colors.primary,
        radius: radius,
        width: AppStroke.control,
      ),
      disabledBorder: mxFieldBorder(
        color: colors.outlineVariant,
        radius: radius,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, this.requiredText});

  final String text;
  final String? requiredText;

  @override
  Widget build(BuildContext context) {
    final String? mark = requiredText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: Text(text, style: mxFieldLabelStyle(context.texts))),
        if (mark != null) ...[
          const SizedBox(width: AppSpacing.control),
          Text(mark, style: mxRequiredStyle(context.texts, context.colors)),
        ],
      ],
    );
  }
}
```

In `lib/core/theme/app_theme.dart`, add `import 'package:memox/core/theme/components/field_style.dart';` and these slots:

```dart
      inputDecorationTheme: mxInputDecorationTheme(
        colors: scheme,
        texts: textTheme,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primaryContainer,
        selectionHandleColor: scheme.primary,
      ),
```

The final `lib/core/theme/app_theme.dart` after this task:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/button_style.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/components/icon_button_style.dart';
import 'package:memox/core/theme/foundations/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';

/// The light and dark themes, built only from the generated foundations
/// (spec 2026-10-04-sp3a §3.3). Component themes join in the phase that
/// builds their `Mx*`.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(AppColorSchemes.light, AppSemanticColors.light);

  static ThemeData dark() =>
      _build(AppColorSchemes.dark, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final TextTheme textTheme = AppTextStyles.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppTextStyles.family,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      splashColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
      focusColor: scheme.primary.withValues(alpha: AppOpacity.focus),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      extensions: <AppSemanticColors>[semantic],
      filledButtonTheme: FilledButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.outline,
        ),
      ),
      inputDecorationTheme: mxInputDecorationTheme(
        colors: scheme,
        texts: textTheme,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primaryContainer,
        selectionHandleColor: scheme.primary,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: mxIconButtonStyle(colors: scheme),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        splashColor: scheme.onPrimary.withValues(alpha: AppOpacity.pressed),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        iconSize: AppIconSize.large,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSize.fab,
          height: AppSize.fab,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.text,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets test/core/theme`
Expected: all pass.

- [ ] **Step 5: Golden**

Create `test/shared/widgets/mx_text_field_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

TextEditingController _text(String value) => TextEditingController(text: value);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('text_field', 'variants'): () => _column([
      MxTextField(controller: _text(''), hint: 'Deck name'),
      MxTextField(
        controller: _text(
          'A detail that is long enough to wrap onto a second line',
        ),
        variant: MxTextFieldVariant.detail,
      ),
      MxTextField(
        controller: _text('to remember'),
        variant: MxTextFieldVariant.meaning,
      ),
      MxTextField(
        controller: _text('remember'),
        variant: MxTextFieldVariant.term,
      ),
      MxTextField(
        controller: _text('042917'),
        variant: MxTextFieldVariant.code,
      ),
      MxTextField(
        controller: _text('typed answer'),
        variant: MxTextFieldVariant.study,
      ),
    ]),
    ('text_field', 'states'): () => _column([
      MxTextField(
        controller: _text('Korean'),
        label: 'Name',
        requiredText: 'Required',
      ),
      MxTextField(
        controller: _text(''),
        label: 'Name',
        message: 'Enter a name',
      ),
      MxTextField(
        controller: _text(
          'A name of fifty-eight characters that nearly fills it',
        ),
        message: 'Close to the 60 character limit',
        messageTone: MxFieldMessageTone.warning,
      ),
      MxTextField(controller: _text('Locked'), isEnabled: false),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_text_field_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_text_field__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

The golden types Latin text only. The test host has no Hangul fallback font, so Korean would render as boxes; on a device the system font supplies Hangul.

- [ ] **Step 6: Catalog**

Set the `Status` cell of `MxFieldMessage`, `MxTextField` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxFieldMessage
- Variants: error, warning
- States: one
- Accessibility: a live region, announced as it appears; glyph plus words, never colour alone
- Tokens: `error`, `warning`; `bodySmall`; `AppIconSize.small`
- Golden: none — shown under a field in `mx_text_field__states`

#### MxTextField
- Variants: form, detail, meaning, term, code, study
- States: resting, focused, error, warning, disabled; with a label and a "Required" mark
- Accessibility: the field label sits above the field; the message is announced; code takes digits only and offers one-time-code autofill; a painted height of 52 (form), 48 (detail) or 76 (meaning) that grows with text
- Tokens: `surface-container-low` (focused `surface-container-lowest`), `outline-variant`, `primary`, `error`; `bodyMedium`, `bodyLarge`, `headlineLarge`, `titleSmall`; `AppRadius.md` / `xl`; `AppSize.field*`
- Golden: variants__light, variants__dark, states__light, states__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

Run: analyze and the guard as in Task 3, Step 7.

```bash
git add lib test DESIGN.md
git commit -m "feat(sp3a-p2): MxTextField in six variants and MxFieldMessage; slot parity"
```

---

### Task 6: MxSearchField

**Files:**
- Create: `lib/shared/widgets/mx_search_field.dart`
- Test: `test/shared/widgets/mx_search_field_test.dart`; golden `mx_search_field_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxIconButton`, `MxRowInk`, the input decoration theme.
- Produces: `MxSearchField({hint, controller, onChanged, clearLabel, onOpen, focusNode})`. It types when given `controller`, and opens search when given `onOpen`; exactly one of the two.

- [ ] **Step 1: Write the failing test**

Create `test/shared/widgets/mx_search_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('typing shows a named clear button that empties the field', (
    tester,
  ) async {
    final controller = TextEditingController();
    final List<String> seen = [];
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSearchField(
          hint: 'Search decks',
          controller: controller,
          clearLabel: 'Clear search',
          onChanged: seen.add,
        ),
      ),
    );
    expect(find.byTooltip('Clear search'), findsNothing);
    await tester.enterText(find.byType(TextField), 'kor');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(seen.last, '');
  });

  testWidgets('trigger mode opens search on a tap and reads as a button', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSearchField(hint: 'Search decks', onOpen: () => opened++),
      ),
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      tester.getSize(find.byType(MxSearchField)).height,
      greaterThanOrEqualTo(AppSize.field),
    );
    await tester.tap(find.text('Search decks'));
    expect(opened, 1);
    expect(
      tester.getSemantics(find.byType(MxSearchField)),
      matchesSemantics(
        label: 'Search decks',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('the trigger starts its hint where the input starts its text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxSearchField(
              hint: 'Typed',
              controller: TextEditingController(text: 'Typed'),
            ),
            MxSearchField(hint: 'Trigger', onOpen: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Trigger')).dx,
      moreOrLessEquals(
        tester.getTopLeft(find.text('Typed').last).dx,
        epsilon: 0.5,
      ),
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_search_field_test.dart`
Expected: compile failure, because `mx_search_field.dart` is not found.

- [ ] **Step 3: The widget**

Create `lib/shared/widgets/mx_search_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// A search input, or (with [onOpen]) a trigger that looks like one and
/// opens the search screen instead of typing here (SCR-DECK-001, Root).
class MxSearchField extends StatelessWidget {
  const MxSearchField({
    required this.hint,
    this.controller,
    this.onChanged,
    this.clearLabel,
    this.onOpen,
    this.focusNode,
    super.key,
  }) : assert(
         (controller == null) == (onOpen != null),
         'A search field either types (controller) or opens search (onOpen).',
       );

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// The clear button's name, read aloud; it shows while there is text.
  final String? clearLabel;

  /// Trigger mode: a tap opens the search screen.
  final VoidCallback? onOpen;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? open = onOpen;
    if (open != null) {
      return _Trigger(hint: hint, onOpen: open);
    }
    final TextEditingController field = controller!;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: field,
      builder: (context, value, _) {
        final String? clear = clearLabel;
        return TextField(
          controller: field,
          focusNode: focusNode,
          onChanged: onChanged,
          style: context.texts.bodyMedium,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.search,
              size: AppIconSize.medium,
              color: context.colors.onSurfaceVariant,
            ),
            suffixIcon: value.text.isEmpty || clear == null
                ? null
                : MxIconButton(
                    icon: Icons.close,
                    semanticLabel: clear,
                    onPressed: () {
                      field.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _Trigger extends StatelessWidget {
  const _Trigger({required this.hint, required this.onOpen});

  final String hint;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      label: hint,
      onTap: onOpen,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: MxRowInk(
          onTap: onOpen,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.field),
            // The input's geometry: the glyph centred in a 48 box where a
            // prefix icon sits, the hint where typed text starts.
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: AppSpacing.grouped,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSize.tapTarget,
                    child: Icon(
                      Icons.search,
                      size: AppIconSize.medium,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.micro),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.apply(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
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

- [ ] **Step 4: Run the test**

Run: the Step 2 command. Expected: 3 pass.

- [ ] **Step 5: Golden**

Create `test/shared/widgets/mx_search_field_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

TextEditingController _text(String value) => TextEditingController(text: value);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('search_field', 'modes'): () => _column([
      MxSearchField(
        hint: 'Search decks',
        controller: _text(''),
        clearLabel: 'Clear',
      ),
      MxSearchField(
        hint: 'Search decks',
        controller: _text('kor'),
        clearLabel: 'Clear',
      ),
      MxSearchField(hint: 'Search decks', onOpen: () {}),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_search_field_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_search_field__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

- [ ] **Step 6: Catalog**

Set the `Status` cell of `MxSearchField` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxSearchField
- Variants: input (with a clear button), trigger (opens the search screen)
- States: empty, typed, trigger
- Accessibility: the clear button is named by `clearLabel`; the trigger is a button named by its hint; the trigger's hint starts where typed text starts
- Tokens: `surface-container-low`, `outline-variant`, `on-surface-variant`; `bodyMedium`; `AppIconSize.medium`; `AppSize.field`
- Golden: modes__light, modes__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p2): MxSearchField, input and trigger on one geometry"
```

---

### Task 7: MxToggle, MxSelectionCheckbox and MxOptionRow

**Files:**
- Create: `lib/shared/widgets/mx_toggle.dart`, `mx_selection_checkbox.dart`, `mx_option_row.dart`
- Test: `test/shared/widgets/mx_toggle_test.dart`, `mx_selection_checkbox_test.dart`, `mx_option_row_test.dart`; golden `mx_selection_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxFocusRing` (driven through `isShown`), `MxTapTarget`, `MxRowInk`.
- Produces:
  - `MxToggle({isOn, onChanged, semanticLabel})`;
  - `MxSelectionCheckbox({isChecked})`;
  - `MxOptionRow({title, isSelected, onSelected, description})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_toggle_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a tap flips it; it is announced as toggled', (tester) async {
    bool? next;
    await pumpMx(
      tester,
      MxToggle(
        isOn: false,
        semanticLabel: 'Due only',
        onChanged: (v) => next = v,
      ),
    );
    await tester.tap(find.byType(MxToggle));
    expect(next, isTrue);
    expect(
      tester.getSemantics(find.byType(MxToggle)),
      matchesSemantics(
        label: 'Due only',
        hasToggledState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('it paints 44x26 inside a 48 hit area', (tester) async {
    await pumpMx(tester, MxToggle(isOn: true, onChanged: (_) {}));
    expect(
      tester.getSize(find.byType(AnimatedContainer).first),
      const Size(AppSize.toggleWidth, AppSize.toggleHeight),
    );
    final Size hit = tester.getSize(find.byType(GestureDetector).first);
    expect(hit.height, greaterThanOrEqualTo(AppSize.tapTarget));
    expect(hit.width, greaterThanOrEqualTo(AppSize.tapTarget));
  });

  testWidgets('on fills primary; off rests on the highest container', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    BoxDecoration track() =>
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
                .decoration!
            as BoxDecoration;
    await pumpMx(tester, MxToggle(isOn: true, onChanged: (_) {}));
    expect(track().color, s.primary);
    await pumpMx(tester, MxToggle(isOn: false, onChanged: (_) {}));
    expect(track().color, s.surfaceContainerHighest);
  });

  testWidgets('disabled, a tap does nothing', (tester) async {
    await pumpMx(tester, const MxToggle(isOn: false, onChanged: null));
    await tester.tap(find.byType(MxToggle));
    expect(find.byType(Opacity), findsOneWidget);
  });
}
```

Create `test/shared/widgets/mx_selection_checkbox_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('an 18 box that carries its checked state to the row', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Semantics(
        label: 'Card 1',
        container: true,
        child: const MxSelectionCheckbox(isChecked: true),
      ),
    );
    expect(
      tester.getSize(find.byType(MxSelectionCheckbox)),
      const Size.square(AppSize.checkbox),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(MxSelectionCheckbox)),
      matchesSemantics(hasCheckedState: true, isChecked: true),
    );
  });

  testWidgets('empty, it draws only its outline', (tester) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));
    expect(find.byIcon(Icons.check), findsNothing);
  });
}
```

Create `test/shared/widgets/mx_option_row_test.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a tap picks it; it is a checked member of a group', (
    tester,
  ) async {
    var picked = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: MxOptionRow(
          title: 'Name',
          isSelected: true,
          onSelected: () => picked++,
        ),
      ),
    );
    await tester.tap(find.text('Name'));
    expect(picked, 1);
    expect(
      tester.getSemantics(find.byType(MxOptionRow)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
    );
    expect(
      tester.getSize(find.byType(MxOptionRow)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
  });

  testWidgets('a locked row dims its radio and title, never the reason', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 320,
        child: MxOptionRow(
          title: 'SM-2',
          description: 'Locked after the first review',
          isSelected: false,
          onSelected: null,
        ),
      ),
    );
    final Iterable<Opacity> dims = tester.widgetList<Opacity>(
      find.byType(Opacity),
    );
    expect(dims.map((o) => o.opacity), everyElement(AppOpacity.disabled));
    expect(dims, hasLength(2));
    expect(
      find.ancestor(
        of: find.text('Locked after the first review'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('the selected row is never dimmed, even when locked', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 320,
        child: MxOptionRow(
          title: 'Eight boxes',
          isSelected: true,
          onSelected: null,
        ),
      ),
    );
    final Iterable<Opacity> dims = tester.widgetList<Opacity>(
      find.byType(Opacity),
    );
    expect(dims.map((o) => o.opacity), everyElement(1));
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_toggle_test.dart test/shared/widgets/mx_selection_checkbox_test.dart test/shared/widgets/mx_option_row_test.dart`
Expected: compile failure, because the three widgets are not found.

- [ ] **Step 3: The widgets**

Create `lib/shared/widgets/mx_toggle.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

/// An on/off switch: a 44×26 pill track and a 20 thumb (DESIGN.md, Inputs),
/// `primary` with an `on-primary` thumb when on, the highest container with
/// an `outline` edge and thumb when off.
class MxToggle extends StatefulWidget {
  const MxToggle({
    required this.isOn,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool isOn;

  /// `null` disables the toggle, drawn at `AppOpacity.disabled`.
  final ValueChanged<bool>? onChanged;

  /// The setting it switches; `null` when a row around it already says so.
  final String? semanticLabel;

  @override
  State<MxToggle> createState() => _MxToggleState();
}

class _MxToggleState extends State<MxToggle> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final bool isOn = widget.isOn;
    final ValueChanged<bool>? change = widget.onChanged;
    final ColorScheme colors = context.colors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppShadow? whisper = isDark
        ? AppShadows.whisperDark
        : AppShadows.whisperLight;
    final Widget track = AnimatedContainer(
      duration: AppDurations.toggle,
      width: AppSize.toggleWidth,
      height: AppSize.toggleHeight,
      padding: const EdgeInsets.all(
        (AppSize.toggleHeight - AppSize.toggleThumb) / 2,
      ),
      alignment: isOn
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: isOn ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: isOn
            ? null
            : Border.all(color: colors.outline, width: AppStroke.hairline),
      ),
      child: Container(
        width: AppSize.toggleThumb,
        height: AppSize.toggleThumb,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? colors.onPrimary : colors.outline,
          boxShadow: [?whisper?.on(colors.shadow)],
        ),
      ),
    );
    final Widget control = Semantics(
      toggled: isOn,
      enabled: change != null,
      label: widget.semanticLabel,
      onTap: change == null ? null : () => change(!isOn),
      child: FocusableActionDetector(
        enabled: change != null,
        onShowFocusHighlight: (shown) => setState(() => _isHighlighted = shown),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => change?.call(!isOn),
          ),
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: change == null ? null : () => change(!isOn),
          child: MxTapTarget(
            child: MxFocusRing(
              borderRadius: BorderRadius.circular(AppRadius.full),
              isShown: _isHighlighted,
              child: track,
            ),
          ),
        ),
      ),
    );
    if (change != null) {
      return control;
    }
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }
}
```

Create `lib/shared/widgets/mx_selection_checkbox.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The mark of a multi-select row: an 18 box, r4, a 2dp `outline` stroke when
/// empty and a `primary` fill with an `on-primary` check when chosen. It
/// paints only; the row that holds it owns the tap, the label and the 48 area,
/// and its semantics merge this checked state.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({required this.isChecked, super.key});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Semantics(
      checked: isChecked,
      child: AnimatedContainer(
        duration: AppDurations.toggle,
        width: AppSize.checkbox,
        height: AppSize.checkbox,
        decoration: BoxDecoration(
          color: isChecked ? colors.primary : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: isChecked
              ? null
              : Border.all(color: colors.outline, width: AppStroke.control),
        ),
        child: isChecked
            ? Icon(
                Icons.check,
                size: AppIconSize.small,
                color: colors.onPrimary,
              )
            : null,
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_option_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One choice of a single-choice list: a radio, a title and an optional
/// description (DESIGN.md, Inputs). A row that cannot be picked dims only its
/// radio and title, never the description that says why; the selected row is
/// never dimmed, so a locked current choice still reads.
class MxOptionRow extends StatelessWidget {
  const MxOptionRow({
    required this.title,
    required this.isSelected,
    required this.onSelected,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final bool isSelected;

  /// `null` when the choice cannot be made now.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? select = onSelected;
    final bool isDimmed = select == null && !isSelected;
    final double emphasis = isDimmed ? AppOpacity.disabled : 1;
    final String? why = description;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      enabled: select != null,
      child: MxRowInk(
        onTap: select,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.grouped,
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: emphasis,
                  child: _Radio(isSelected: isSelected),
                ),
                const SizedBox(width: AppSpacing.grouped),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: emphasis,
                        child: Text(title, style: context.texts.bodyLarge),
                      ),
                      if (why != null)
                        Text(
                          why,
                          style: context.texts.bodyMedium?.apply(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 20 ring, 2dp `outline` when idle; selected, the ring thickens to 6 in
/// `primary` without moving (DESIGN.md, Shapes).
class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.toggle,
      width: AppSize.radio,
      height: AppSize.radio,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.outline,
          width: isSelected ? AppStroke.indicator : AppStroke.control,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: the Step 2 command. Expected: all pass.

- [ ] **Step 5: Golden**

Create `test/shared/widgets/mx_selection_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('toggle', 'states'): () => Wrap(
      spacing: 8,
      children: [
        MxToggle(isOn: true, onChanged: (_) {}),
        MxToggle(isOn: false, onChanged: (_) {}),
        const MxToggle(isOn: true, onChanged: null),
        const MxToggle(isOn: false, onChanged: null),
      ],
    ),
    ('selection_checkbox', 'states'): () => const Wrap(
      spacing: 16,
      children: [
        MxSelectionCheckbox(isChecked: true),
        MxSelectionCheckbox(isChecked: false),
      ],
    ),
    ('option_row', 'states'): () => _column([
      MxOptionRow(
        title: 'Manual order',
        description: 'Drag decks to arrange them',
        isSelected: true,
        onSelected: () {},
      ),
      MxOptionRow(
        title: 'Date added',
        description: 'Newest first',
        isSelected: false,
        onSelected: () {},
      ),
      const MxOptionRow(
        title: 'SM-2',
        description: 'Locked after the first review',
        isSelected: false,
        onSelected: null,
      ),
      const MxOptionRow(
        title: 'Eight boxes',
        isSelected: true,
        onSelected: null,
      ),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_selection_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_toggle__*__light.png` / `__dark.png`, `mx_selection_checkbox__*__light.png` / `__dark.png`, `mx_option_row__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

- [ ] **Step 6: Catalog**

Set the `Status` cell of `MxToggle`, `MxSelectionCheckbox`, `MxOptionRow` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxToggle
- Variants: one
- States: on, off, disabled on, disabled off, focused
- Accessibility: announced as toggled; Space and Enter switch it; 44 × 26 painted inside a 48 hit
- Tokens: `primary`, `on-primary`, `surface-container-highest`, `outline`, `shadow`; `AppShadows.whisper*`; `AppSize.toggle*`; `AppDurations.toggle`
- Golden: states__light, states__dark

#### MxSelectionCheckbox
- Variants: one
- States: checked, unchecked
- Accessibility: carries its checked state into the row that holds it; the row owns the tap, the name and the 48 area
- Tokens: `primary`, `on-primary`, `outline`; `AppRadius.xs`; `AppStroke.control`; `AppSize.checkbox`
- Golden: states__light, states__dark

#### MxOptionRow
- Variants: with or without a description
- States: selected, idle, locked (dims the radio and title only), locked and selected (never dimmed)
- Accessibility: a checked or unchecked member of a mutually exclusive group; 48 minimum height
- Tokens: `primary`, `outline`, `on-surface`, `on-surface-variant`; `bodyLarge`, `bodyMedium`; `AppStroke.control` / `indicator`; `AppSize.radio`
- Golden: states__light, states__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p2): MxToggle, MxSelectionCheckbox and MxOptionRow"
```

---

### Task 8: MxStepper and MxSegmentedTray

**Files:**
- Create: `lib/core/theme/components/control_style.dart`, `lib/shared/widgets/mx_stepper.dart`, `lib/shared/widgets/mx_segmented_tray.dart`
- Test: `test/shared/widgets/mx_stepper_test.dart`, `mx_segmented_tray_test.dart`; golden `mx_stepper_tray_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxIconButton`, `MxRowInk`, `AppDurations.repeat`.
- Produces:
  - `mxStepperValueStyle(texts)` and `mxRaisedInTray(colors)`;
  - `MxStepper({value, min, max, onChanged, decreaseLabel, increaseLabel, valueLabel, minDigits})`;
  - `MxSegmentedTray<T>({segments, selected, onChanged, isExpanded})` with `MxSegmentedTrayItem<T>({value, label})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_stepper_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import 'support/mx_harness.dart';

class _Host extends StatefulWidget {
  const _Host({required this.start, this.minDigits = 1});

  final int start;
  final int minDigits;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.start;

  @override
  Widget build(BuildContext context) => MxStepper(
    value: value,
    min: 0,
    max: 23,
    minDigits: widget.minDigits,
    valueLabel: 'Hour',
    decreaseLabel: 'Earlier hour',
    increaseLabel: 'Later hour',
    onChanged: (v) => setState(() => value = v),
  );
}

void main() {
  testWidgets('+ and − step by one and stop at the bounds', (tester) async {
    await pumpMx(tester, const _Host(start: 22));
    await tester.tap(find.byTooltip('Later hour'));
    await tester.pump();
    expect(find.text('23'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Earlier hour'));
    await tester.pump();
    expect(find.text('22'), findsOneWidget);
  });

  testWidgets('minDigits zero-pads the value', (tester) async {
    await pumpMx(tester, const _Host(start: 7, minDigits: 2));
    expect(find.text('07'), findsOneWidget);
  });

  testWidgets('holding + repeats until release', (tester) async {
    await pumpMx(tester, const _Host(start: 0));
    final TestGesture press = await tester.startGesture(
      tester.getCenter(find.byTooltip('Later hour')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    await tester.pump(AppDurations.repeat * 3);
    await press.up();
    await tester.pump();
    final int reached = int.parse(
      tester.widget<Text>(find.textContaining(RegExp(r'^\d+$'))).data!,
    );
    expect(reached, greaterThanOrEqualTo(2));
    await tester.pump(AppDurations.repeat * 3);
    expect(find.text('$reached'), findsOneWidget);
  });

  testWidgets('it reads its value and offers increase and decrease', (
    tester,
  ) async {
    await pumpMx(tester, const _Host(start: 7, minDigits: 2));
    expect(
      tester.getSemantics(find.byType(MxStepper)),
      matchesSemantics(
        label: 'Hour',
        value: '07',
        increasedValue: '08',
        decreasedValue: '06',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
  });

  testWidgets('the buttons stay put as the digits change', (tester) async {
    await pumpMx(tester, const _Host(start: 9));
    final double plus = tester.getCenter(find.byTooltip('Later hour')).dx;
    await tester.tap(find.byTooltip('Later hour'));
    await tester.pump();
    expect(find.text('10'), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('Later hour')).dx, plus);
  });
}
```

Create `test/shared/widgets/mx_segmented_tray_test.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import 'support/mx_harness.dart';

void main() {
  const segments = [
    MxSegmentedTrayItem(value: 7, label: 'Last 7 days'),
    MxSegmentedTrayItem(value: 30, label: 'Last 30 days'),
  ];

  testWidgets('a tap picks a segment; the chosen one reads as selected', (
    tester,
  ) async {
    int? picked;
    await pumpMx(
      tester,
      MxSegmentedTray<int>(
        segments: segments,
        selected: 7,
        onChanged: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('Last 30 days'));
    expect(picked, 30);
    expect(
      tester.getSemantics(find.text('Last 7 days')),
      isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
    );
  });

  testWidgets('each segment is 48 to the touch', (tester) async {
    await pumpMx(
      tester,
      MxSegmentedTray<int>(segments: segments, selected: 7, onChanged: (_) {}),
    );
    expect(
      tester.getSize(find.byType(MxSegmentedTray<int>)).height,
      AppSize.tapTarget,
    );
  });

  testWidgets('expanded, the segments share the width equally', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxSegmentedTray<int>(
          segments: segments,
          selected: 7,
          isExpanded: true,
          onChanged: (_) {},
        ),
      ),
    );
    final double a = tester
        .getSize(
          find.ancestor(
            of: find.text('Last 7 days'),
            matching: find.byType(Expanded),
          ),
        )
        .width;
    final double b = tester
        .getSize(
          find.ancestor(
            of: find.text('Last 30 days'),
            matching: find.byType(Expanded),
          ),
        )
        .width;
    expect(a, b);
  });

  testWidgets('the chosen segment is lighter than its tray in both themes', (
    tester,
  ) async {
    for (final theme in mxThemes.values) {
      await pumpMx(
        tester,
        MxSegmentedTray<int>(
          segments: segments,
          selected: 7,
          onChanged: (_) {},
        ),
        theme: theme,
      );
      final BoxDecoration chosen =
          tester
                  .widget<AnimatedContainer>(
                    find.byType(AnimatedContainer).first,
                  )
                  .decoration!
              as BoxDecoration;
      final BoxDecoration tray =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      expect(
        chosen.color!.computeLuminance(),
        greaterThan(tray.color!.computeLuminance()),
        reason: theme.brightness.name,
      );
    }
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_stepper_test.dart test/shared/widgets/mx_segmented_tray_test.dart`
Expected: compile failure, because the two widgets are not found.

- [ ] **Step 3: The styles and the widgets**

Create `lib/core/theme/components/control_style.dart`:

```dart
import 'package:flutter/material.dart';

/// A stepper's value: the title role with tabular figures, so the buttons
/// stay put as the digits change.
TextStyle? mxStepperValueStyle(TextTheme texts) => texts.titleLarge?.copyWith(
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
);

/// The ground a chosen segment is raised to inside a muted tray: white on the
/// light tray, the highest container on the dark one (in dark the low
/// containers are darker, so the lowest would read as sunken).
Color mxRaisedInTray(ColorScheme colors) => colors.brightness == Brightness.dark
    ? colors.surfaceContainerHighest
    : colors.surfaceContainerLowest;
```

Create `lib/shared/widgets/mx_stepper.dart`:

```dart
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/control_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// A bounded integer with − and +, repeating while held (DESIGN.md, Inputs).
/// [minDigits] zero-pads the value, as the reminder's "07" : "05".
class MxStepper extends StatefulWidget {
  const MxStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.valueLabel,
    this.minDigits = 1,
    super.key,
  }) : assert(min <= max, 'min must not exceed max');

  final int value;
  final int min;
  final int max;

  /// `null` disables both buttons.
  final ValueChanged<int>? onChanged;

  /// The names of the two buttons, read aloud ("Earlier hour").
  final String decreaseLabel;
  final String increaseLabel;

  /// What the value is ("Hour"), read before it.
  final String? valueLabel;
  final int minDigits;

  @override
  State<MxStepper> createState() => _MxStepperState();
}

class _MxStepperState extends State<MxStepper> {
  Timer? _repeat;

  /// The last value sent; a repeat can tick again before the parent rebuilds
  /// with it, so each step counts from here, not from a stale `widget.value`.
  late int _latest = widget.value;

  @override
  void didUpdateWidget(MxStepper old) {
    super.didUpdateWidget(old);
    _latest = widget.value;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  bool get _canDecrease =>
      widget.onChanged != null && widget.value > widget.min;
  bool get _canIncrease =>
      widget.onChanged != null && widget.value < widget.max;

  void _step(int delta) {
    final int next = (_latest + delta).clamp(widget.min, widget.max);
    if (next == _latest) {
      _stopRepeat();
      return;
    }
    _latest = next;
    widget.onChanged?.call(next);
  }

  void _startRepeat(int delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(AppDurations.repeat, (_) => _step(delta));
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  String get _shown => widget.value.toString().padLeft(widget.minDigits, '0');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.valueLabel,
      value: _shown,
      increasedValue: _canIncrease
          ? (widget.value + 1).toString().padLeft(widget.minDigits, '0')
          : null,
      decreasedValue: _canDecrease
          ? (widget.value - 1).toString().padLeft(widget.minDigits, '0')
          : null,
      onIncrease: _canIncrease ? () => _step(1) : null,
      onDecrease: _canDecrease ? () => _step(-1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Hold(
            onHold: _canDecrease ? () => _startRepeat(-1) : null,
            onRelease: _stopRepeat,
            child: MxIconButton(
              icon: Icons.remove,
              semanticLabel: widget.decreaseLabel,
              tone: MxIconButtonTone.accent,
              onPressed: _canDecrease ? () => _step(-1) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.micro),
          ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: AppSize.tapTarget),
              child: Text(
                _shown,
                textAlign: TextAlign.center,
                style: mxStepperValueStyle(context.texts),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.micro),
          _Hold(
            onHold: _canIncrease ? () => _startRepeat(1) : null,
            onRelease: _stopRepeat,
            child: MxIconButton(
              icon: Icons.add,
              semanticLabel: widget.increaseLabel,
              tone: MxIconButtonTone.accent,
              onPressed: _canIncrease ? () => _step(1) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Starts the repeat once a press has been held for the long-press delay and
/// stops it on release. It reads raw pointers, so it never competes with the
/// button's own tap or its tooltip for the gesture.
class _Hold extends StatefulWidget {
  const _Hold({
    required this.onHold,
    required this.onRelease,
    required this.child,
  });

  final VoidCallback? onHold;
  final VoidCallback onRelease;
  final Widget child;

  @override
  State<_Hold> createState() => _HoldState();
}

class _HoldState extends State<_Hold> {
  Timer? _delay;

  void _down(PointerDownEvent event) {
    final VoidCallback? hold = widget.onHold;
    if (hold == null) {
      return;
    }
    _delay = Timer(kLongPressTimeout, hold);
  }

  void _up() {
    _delay?.cancel();
    _delay = null;
    widget.onRelease();
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: widget.child,
    );
  }
}
```

Create `lib/shared/widgets/mx_segmented_tray.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/control_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One segment: the value it stands for and its localized label.
@immutable
class MxSegmentedTrayItem<T> {
  const MxSegmentedTrayItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// One of a few: a muted tray whose chosen segment is raised (DESIGN.md,
/// Inputs). Each segment is 48 tall to the touch and 36 painted.
class MxSegmentedTray<T> extends StatelessWidget {
  const MxSegmentedTray({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.isExpanded = false,
    super.key,
  });

  final List<MxSegmentedTrayItem<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Share the full width equally, as Progress's range tray does.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    const double inset = (AppSize.tapTarget - AppSize.segment) / 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: inset),
        child: Row(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (final segment in segments)
              _wrap(
                _Segment<T>(
                  segment: segment,
                  isSelected: segment.value == selected,
                  onTap: () => onChanged(segment.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wrap(Widget child) => isExpanded ? Expanded(child: child) : child;
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final MxSegmentedTrayItem<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppShadow? whisper = isDark
        ? AppShadows.whisperDark
        : AppShadows.whisperLight;
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: MxRowInk(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: AppSize.tapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppDurations.standard,
              height: AppSize.segment,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.grouped,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? mxRaisedInTray(colors) : null,
                borderRadius: radius,
                boxShadow: isSelected ? [?whisper?.on(colors.shadow)] : null,
              ),
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelLarge?.apply(
                  color: isSelected
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: the Step 2 command. Expected: all pass. That includes `holding + repeats until release`, which proves the repeat counts from the last value it sent, and `the chosen segment is lighter than its tray in both themes`.

- [ ] **Step 5: Golden**

Create `test/shared/widgets/mx_stepper_tray_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('stepper', 'states'): () => _column([
      MxStepper(
        value: 20,
        min: 1,
        max: 200,
        onChanged: (_) {},
        decreaseLabel: 'Fewer',
        increaseLabel: 'More',
      ),
      MxStepper(
        value: 1,
        min: 1,
        max: 200,
        onChanged: (_) {},
        decreaseLabel: 'Fewer',
        increaseLabel: 'More',
      ),
      MxStepper(
        value: 7,
        min: 0,
        max: 23,
        minDigits: 2,
        onChanged: (_) {},
        decreaseLabel: 'Earlier',
        increaseLabel: 'Later',
      ),
    ]),
    ('segmented_tray', 'states'): () => _column([
      Align(
        alignment: Alignment.centerLeft,
        child: MxSegmentedTray<int>(
          segments: const [
            MxSegmentedTrayItem(value: 0, label: 'Server'),
            MxSegmentedTrayItem(value: 1, label: 'Not sent (3)'),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
      ),
      MxSegmentedTray<int>(
        segments: const [
          MxSegmentedTrayItem(value: 7, label: 'Last 7 days'),
          MxSegmentedTrayItem(value: 30, label: 'Last 30 days'),
        ],
        selected: 30,
        isExpanded: true,
        onChanged: (_) {},
      ),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_stepper_tray_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_stepper__*__light.png` / `__dark.png`, `mx_segmented_tray__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

- [ ] **Step 6: Catalog**

Set the `Status` cell of `MxStepper`, `MxSegmentedTray` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxStepper
- Variants: `minDigits` zero-padding
- States: inside its bounds, at a bound (that button disabled), held (repeating)
- Accessibility: reads its value with increase and decrease actions; its buttons are named by the caller; the value keeps a fixed, tabular width so the buttons never move
- Tokens: `primary`, `on-surface`; `titleLarge` with tabular figures; `AppDurations.repeat`
- Golden: states__light, states__dark
- Debt: a typed entry (SCR-SETTINGS-001, "a typed entry") is not built; its first consumer in SP3c adds it

#### MxSegmentedTray
- Variants: hugging its segments, or `isExpanded` sharing the width equally
- States: selected segment raised, idle segments
- Accessibility: each segment is a selected or unselected member of a mutually exclusive group; 48 to the touch, 36 painted
- Tokens: `surface-container-low`, `surface-container-lowest` (dark: `surface-container-highest`), `on-surface`, `on-surface-variant`, `shadow`; `labelLarge`; `AppSize.segment`
- Golden: states__light, states__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p2): MxStepper and MxSegmentedTray"
```

---

### Task 9: MxChipShell, MxFilterChip and MxChipTrigger

**Files:**
- Create: `lib/core/theme/components/chip_style.dart`, `lib/shared/widgets/primitives/mx_chip_shell.dart`, `lib/shared/widgets/mx_filter_chip.dart`, `lib/shared/widgets/mx_chip_trigger.dart`
- Test: `test/shared/widgets/mx_chip_shell_test.dart`, `mx_filter_chip_test.dart`, `mx_chip_trigger_test.dart`; golden `mx_chips_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Produces:
  - `mxChipColors({colors, isSelected, isGhost})`;
  - `MxChipShell({label, isSelected, isGhost, onTap, trailing})`;
  - `MxFilterChip({label, isSelected, onSelected})`;
  - `MxChipTrigger({label, onOpen, isActive})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_chip_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/primitives/mx_chip_shell.dart';

import 'support/mx_harness.dart';

BoxDecoration _ground(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxChipShell),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final ColorScheme s = mxThemes['light']!.colorScheme;

  testWidgets('a filled chip rests raised and fills primary when selected', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxChipShell(
        label: 'All',
        isSelected: false,
        isGhost: false,
        onTap: () {},
      ),
    );
    expect(_ground(tester).color, s.surfaceContainerLowest);
    await pumpMx(
      tester,
      MxChipShell(label: 'All', isSelected: true, isGhost: false, onTap: () {}),
    );
    expect(_ground(tester).color, s.primary);
  });

  testWidgets('a ghost chip has no fill until it is active', (tester) async {
    await pumpMx(
      tester,
      MxChipShell(
        label: 'Manual',
        isSelected: false,
        isGhost: true,
        onTap: () {},
      ),
    );
    expect(_ground(tester).color, isNull);
    await pumpMx(
      tester,
      MxChipShell(
        label: 'Manual',
        isSelected: true,
        isGhost: true,
        onTap: () {},
      ),
    );
    expect(_ground(tester).color, s.primaryContainer);
  });

  testWidgets('it paints 28 inside a 48 hit area', (tester) async {
    await pumpMx(
      tester,
      MxChipShell(
        label: 'All',
        isSelected: false,
        isGhost: false,
        onTap: () {},
      ),
    );
    expect(tester.getSize(find.byType(MxChipShell)).height, AppSize.tapTarget);
    expect(tester.getSize(find.byType(DecoratedBox).last).height, AppSize.chip);
  });
}
```

Create `test/shared/widgets/mx_filter_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a filter chip toggles and reads selected', (tester) async {
    bool? next;
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Flagged',
        isSelected: true,
        onSelected: (v) => next = v,
      ),
    );
    await tester.tap(find.text('Flagged'));
    expect(next, isFalse);
    expect(
      tester.getSemantics(find.byType(MxFilterChip)),
      matchesSemantics(
        label: 'Flagged',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('both chips paint 28 inside a 48 hit area', (tester) async {
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxFilterChip(label: 'All', isSelected: false, onSelected: (_) {}),
          MxChipTrigger(label: 'Manual', onOpen: () {}),
        ],
      ),
    );
    for (final Type type in [MxFilterChip, MxChipTrigger]) {
      final Finder chip = find.byType(type);
      expect(tester.getSize(chip).height, AppSize.tapTarget);
      expect(
        tester
            .getSize(
              find.descendant(of: chip, matching: find.byType(SizedBox)).first,
            )
            .height,
        AppSize.chip,
      );
    }
  });
}
```

Create `test/shared/widgets/mx_chip_trigger_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a trigger opens what it names and shows a chevron', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      MxChipTrigger(label: 'Manual', onOpen: () => opened++),
    );
    await tester.tap(find.text('Manual'));
    expect(opened, 1);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_chip_shell_test.dart test/shared/widgets/mx_filter_chip_test.dart test/shared/widgets/mx_chip_trigger_test.dart`
Expected: compile failure.

- [ ] **Step 3: The style, the shell and the chips**

Create `lib/core/theme/components/chip_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// A chip's ground, content and edge for its state (DESIGN.md, Inputs):
/// a filter chip rests on `surface-container-lowest` with an
/// `outline-variant` edge and fills `primary` when selected; a chip trigger
/// is a ghost with an `outline-variant` edge, tinted `primary-container`
/// while what it opens is in force.
({Color? fill, Color content, BorderSide edge}) mxChipColors({
  required ColorScheme colors,
  required bool isSelected,
  required bool isGhost,
}) {
  if (isSelected && !isGhost) {
    return (
      fill: colors.primary,
      content: colors.onPrimary,
      edge: BorderSide.none,
    );
  }
  if (isSelected) {
    return (
      fill: colors.primaryContainer,
      content: colors.onPrimaryContainer,
      edge: BorderSide.none,
    );
  }
  return (
    fill: isGhost ? null : colors.surfaceContainerLowest,
    content: colors.onSurface,
    edge: BorderSide(color: colors.outlineVariant, width: AppStroke.hairline),
  );
}
```

Create `lib/shared/widgets/primitives/mx_chip_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chip_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

/// The 28dp pill both chips are drawn as, with a 48 hit area; the two chips
/// differ in meaning, not in geometry.
class MxChipShell extends StatelessWidget {
  const MxChipShell({
    required this.label,
    required this.isSelected,
    required this.isGhost,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final String label;
  final bool isSelected;
  final bool isGhost;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final style = mxChipColors(
      colors: context.colors,
      isSelected: isSelected,
      isGhost: isGhost,
    );
    final BorderRadius pill = BorderRadius.circular(AppRadius.full);
    final IconData? glyph = trailing;
    return MxTapTarget(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.fill,
          borderRadius: pill,
          border: Border.fromBorderSide(style.edge),
        ),
        child: MxRowInk(
          onTap: onTap,
          borderRadius: pill,
          child: SizedBox(
            height: AppSize.chip,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.control,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.apply(
                        color: style.content,
                      ),
                    ),
                  ),
                  if (glyph != null) ...[
                    const SizedBox(width: AppSpacing.micro),
                    Icon(glyph, size: AppIconSize.small, color: style.content),
                  ],
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

Create `lib/shared/widgets/mx_filter_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/primitives/mx_chip_shell.dart';

/// A filter that is on or off: 28 pill, `primary` under `on-primary` when
/// selected (DESIGN.md, Inputs). Announced as a selected or unselected button.
class MxFilterChip extends StatelessWidget {
  const MxFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: label,
      onTap: () => onSelected(!isSelected),
      child: MxChipShell(
        label: label,
        isSelected: isSelected,
        isGhost: false,
        onTap: () => onSelected(!isSelected),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_chip_trigger.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/primitives/mx_chip_shell.dart';

/// A ghost chip that opens a menu or a sheet ("Manual ⌄"); tinted
/// `primary-container` while what it opened is in force ("Manual · Due only").
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    required this.label,
    required this.onOpen,
    this.isActive = false,
    super.key,
  });

  final String label;
  final VoidCallback onOpen;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onOpen,
      child: MxChipShell(
        label: label,
        isSelected: isActive,
        isGhost: true,
        trailing: Icons.expand_more,
        onTap: onOpen,
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: the Step 2 command. Expected: all pass.

- [ ] **Step 5: Golden**

Create `test/shared/widgets/mx_chips_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('filter_chip', 'states'): () => Wrap(
      spacing: 8,
      children: [
        MxFilterChip(label: 'All 42', isSelected: true, onSelected: (_) {}),
        MxFilterChip(label: 'Flagged 3', isSelected: false, onSelected: (_) {}),
      ],
    ),
    ('chip_trigger', 'states'): () => Wrap(
      spacing: 8,
      children: [
        MxChipTrigger(label: 'Manual', onOpen: () {}),
        MxChipTrigger(
          label: 'Manual · Due only',
          isActive: true,
          onOpen: () {},
        ),
      ],
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_chips_golden_test.dart`
Expected: `All tests passed!` and these files under `test/shared/widgets/goldens/`: `mx_filter_chip__*__light.png` / `__dark.png`, `mx_chip_trigger__*__light.png` / `__dark.png`.

Open every new PNG and check it against the component's contract and DESIGN.md before the commit: a wrong picture committed here becomes the baseline.

- [ ] **Step 6: Catalog**

Insert these rows directly above the `| MxButton |` row of `### Catalog`:

```markdown
| MxChipShell | The 28 pill both chips are drawn as | primitive | MxFilterChip, MxChipTrigger | SP3a | built |
```

Set the `Status` cell of `MxFilterChip`, `MxChipTrigger` to `built`. Append these contracts at the end of `### Contracts` (after its introduction paragraph and any earlier block):

```markdown
#### MxChipShell
- Variants: filled (filter), ghost (trigger); optional trailing glyph
- States: resting, selected or active, pressed
- Accessibility: 28 painted inside a 48 hit; the chip that uses it owns the semantics
- Tokens: `surface-container-lowest`, `outline-variant`, `primary` / `on-primary`, `primary-container` / `on-primary-container`, `labelSmall`, `AppSize.chip`
- Golden: none — seen in `MxFilterChip` and `MxChipTrigger`

#### MxFilterChip
- Variants: one
- States: selected, unselected
- Accessibility: a selected or unselected button named by its label; 28 painted inside a 48 hit
- Tokens: through `MxChipShell`
- Golden: states__light, states__dark

#### MxChipTrigger
- Variants: one; a trailing chevron
- States: idle, active (what it opened is in force)
- Accessibility: a button named by its label; 28 painted inside a 48 hit
- Tokens: through `MxChipShell`
- Golden: states__light, states__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`; `check.py` now requires each `built` component's source, widget test and every listed golden.

- [ ] **Step 7: Verify and commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p2): MxFilterChip and MxChipTrigger on one chip shell"
```

---

### Task 10: Review, Impeccable, gate and sign-off

**Files:**
- Create: `tools/design/gallery.py`, `tools/design/test_gallery.py`
- Modify (only if findings): the component, style or `DESIGN.md`, with the goldens it changes
- Modify: `docs/wbs_FE.md`

- [ ] **Step 1: The whole suite and the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: every gate passes. The host suite now includes the `test/shared` tests.

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`
Expected: 32 goldens match.

- [ ] **Step 2: Impeccable critique of the components**

Run the `impeccable` skill's `critique` on the 32 `mx_*` goldens, measured against DESIGN.md (Components, Colors, Typography, Shapes) and the catalog contracts. Assessments A and B run on two sub-agents (Sonnet).

Apply A10 to each finding. A token finding changes `DESIGN.md` first, then the value is regenerated. A theme finding goes to `lib/core/theme/components/`. A widget finding goes to `lib/shared/widgets/`. Fix every finding in one batch, re-render the goldens it touches, and run one `impeccable audit` of what changed (CLAUDE.md). Report its result to the owner and run no further audit.

- [ ] **Step 3: The golden review page**

Build the before · after · diff page with the `golden-compare` skill for every added `mx_*` golden. All 32 are new, so the page shows "after" only. Give it to the owner before any approval (CLAUDE.md, "Golden review").

- [ ] **Step 4: The shared-widget gallery**

Write the failing test `tools/design/test_gallery.py`:

```python
"""Tests for tools/design/gallery.py:  python3 tools/design/test_gallery.py"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gallery  # noqa: E402

DESIGN = """---
name: X
---

## Components

### Catalog

| Component | Purpose | Layer | Consumers | Owner phase | Status |
|---|---|---|---|---|---|
| MxButton | An action | shared | DECK | SP3a | built |
| MxCard | A surface | shared | DECK | SP3a | planned |
| MxRowInk | A ripple | primitive | MxButton | SP3a | built |

### Contracts

#### MxButton
- Variants: primary
- States: enabled
- Accessibility: 48 target
- Tokens: primary
- Golden: tones__light, tones__dark

#### MxRowInk
- Variants: one
- States: one
- Accessibility: none of its own
- Tokens: splash
- Golden: none — paints only the press

## Do's and Don'ts
"""

PNG = bytes.fromhex("89504e470d0a1a0a0000000d4948445200000001000000010806000000")


def tree(goldens: tuple[str, ...]) -> Path:
    root = Path(tempfile.mkdtemp())
    (root / "DESIGN.md").write_text(DESIGN, encoding="utf-8")
    folder = root / gallery.GOLDENS
    folder.mkdir(parents=True)
    for name in goldens:
        (folder / name).write_bytes(PNG)
    return root


class GalleryTest(unittest.TestCase):
    def test_built_components_show_their_goldens_side_by_side(self):
        page, problems = gallery.build(tree(("mx_button__tones__light.png", "mx_button__tones__dark.png")))
        self.assertEqual(problems, [])
        self.assertIn('<section id="mx_button">', page)
        self.assertEqual(page.count("data:image/png;base64,"), 2)
        self.assertIn("mx_button__tones__dark.png", page)
        self.assertIn("<title>MemoX Mx Gallery</title>", page)

    def test_planned_components_are_left_out(self):
        page, _ = gallery.build(tree(("mx_button__tones__light.png", "mx_button__tones__dark.png")))
        self.assertNotIn("MxCard", page)

    def test_a_component_without_goldens_says_why(self):
        page, _ = gallery.build(tree(("mx_button__tones__light.png", "mx_button__tones__dark.png")))
        self.assertIn("none — paints only the press", page)

    def test_a_missing_golden_is_reported(self):
        _, problems = gallery.build(tree(("mx_button__tones__light.png",)))
        self.assertEqual(problems, ["MxButton: mx_button__tones__dark.png is missing"])


if __name__ == "__main__":
    unittest.main()
```

Run: `python3 tools/design/test_gallery.py` → FAIL (`No module named 'gallery'`).

Write `tools/design/gallery.py`:

```python
#!/usr/bin/env python3
"""Build the shared-widget gallery: one HTML page of every catalogued component's
`mx_*` goldens, light and dark side by side, with its catalog contract.

    python3 tools/design/gallery.py --out <path.html>

Run from the repository root. The page is self-contained (images inlined as
data URIs) so it can be published as an Artifact for the owner's review
(SP3a Phase 2, owner 2026-10-04). Exit code 1 when a `built` component lists a
golden that does not exist.
"""
from __future__ import annotations

import argparse
import base64
import html
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "docs"))
import design_catalog as dc  # noqa: E402

ROOT = Path.cwd()
GOLDENS = Path("test/shared/widgets/goldens")
VARIANTS = ("light", "dark")

STYLE = """
/* A review sheet, not a showcase: components down one column, each a header
   row (name, layer, status) over its contract and its light/dark pictures. */
:root {
  --page: #F7F9FE; --raised: #FFFFFF; --muted: #F1F4FB; --ink: #0F1638;
  --ink-2: #4A5278; --edge: #C5CBE3; --accent: #4151C6; --built: #1A6B48;
  --font: "Plus Jakarta Sans", system-ui, sans-serif;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --page: #0A0E27; --raised: #131A3A; --muted: #1B2249; --ink: #E4E8FA;
  --ink-2: #ADB5D8; --edge: #2A3267; --accent: #AAB4FF; --built: #6FE0BD; color-scheme: dark } }
:root[data-theme="dark"] {
  --page: #0A0E27; --raised: #131A3A; --muted: #1B2249; --ink: #E4E8FA;
  --ink-2: #ADB5D8; --edge: #2A3267; --accent: #AAB4FF; --built: #6FE0BD; color-scheme: dark }
body { background: var(--page); color: var(--ink); font: 15px/1.5 var(--font);
  margin: 0; padding-inline: 16px; padding-block: 24px 48px; }
main { max-width: 1120px; margin-inline: auto; display: grid; gap: 32px; }
h1 { font-size: 28px; line-height: 1.2; letter-spacing: -0.5px; margin: 0; text-wrap: balance; }
.lede { color: var(--ink-2); margin: 4px 0 0; max-width: 65ch; }
nav { display: flex; flex-wrap: wrap; gap: 8px; }
nav a { color: var(--ink); text-decoration: none; border: 1px solid var(--edge);
  border-radius: 999px; padding: 4px 12px; font-size: 13px; font-weight: 600; }
nav a:hover, nav a:focus-visible { border-color: var(--accent); color: var(--accent); outline: none; }
section { background: var(--raised); border: 1px solid var(--edge); border-radius: 12px;
  padding: 20px; display: grid; gap: 16px; scroll-margin-top: 16px; min-width: 0; }
.head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 8px 12px; }
h2 { font-size: 20px; margin: 0; letter-spacing: -0.3px; }
.tag { font-size: 12px; font-weight: 600; letter-spacing: 0.6px; text-transform: uppercase;
  color: var(--ink-2); }
.tag.built { color: var(--built); }
.purpose { color: var(--ink-2); margin: 0; }
dl { display: grid; grid-template-columns: max-content minmax(0, 1fr); gap: 4px 16px; margin: 0; font-size: 14px; }
dt { color: var(--ink-2); font-weight: 600; }
dd { margin: 0; min-width: 0; }
.state { display: grid; gap: 8px; }
.state h3 { font-size: 13px; font-weight: 700; letter-spacing: 0.6px; text-transform: uppercase; margin: 0; color: var(--ink-2); }
.pair { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px; }
figure { margin: 0; display: grid; gap: 4px; min-width: 0; }
figure img { width: 100%; height: auto; border-radius: 8px; border: 1px solid var(--edge); background: var(--muted); }
figcaption { font-size: 12px; color: var(--ink-2); font-variant-numeric: tabular-nums; }
.none { color: var(--ink-2); font-size: 14px; margin: 0; }
"""


def data_uri(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def states_of(goldens: list[str]) -> list[str]:
    """`tones__light`, `tones__dark` → `tones`, in the contract's order."""
    seen: list[str] = []
    for golden in goldens:
        state = golden.rsplit("__", 1)[0]
        if state not in seen:
            seen.append(state)
    return seen


def build(root: Path) -> tuple[str, list[str]]:
    text = (root / dc.DESIGN_MD).read_text(encoding="utf-8")
    entries, contracts = dc.parse(text)
    shown = [e for e in entries if e.status in ("implementing", "built") and e.layer in ("primitive", "shared")]
    problems: list[str] = []
    sections: list[str] = []
    for entry in shown:
        contract = contracts.get(entry.name)
        fields = contract.fields if contract else {}
        rows = "".join(
            f"<dt>{html.escape(key)}</dt><dd>{html.escape(fields[key])}</dd>"
            for key in ("Variants", "States", "Accessibility", "Tokens", "Debt")
            if key in fields
        )
        goldens = contract.goldens() if contract else []
        pictures: list[str] = []
        for state in states_of(goldens):
            figures = []
            for variant in VARIANTS:
                name = f"{dc.snake(entry.name)}__{state}__{variant}.png"
                path = root / GOLDENS / name
                if not path.exists():
                    problems.append(f"{entry.name}: {name} is missing")
                    continue
                figures.append(
                    f'<figure><img src="{data_uri(path)}" alt="{html.escape(entry.name)}, {html.escape(state)}, {variant} theme" loading="lazy">'
                    f"<figcaption>{html.escape(name)}</figcaption></figure>"
                )
            pictures.append(f'<div class="state"><h3>{html.escape(state.replace("_", " "))}</h3><div class="pair">{"".join(figures)}</div></div>')
        if not pictures:
            reason = fields.get("Golden", "none")
            pictures.append(f'<p class="none">{html.escape(reason)}</p>')
        anchor = dc.snake(entry.name)
        sections.append(
            f'<section id="{anchor}"><div class="head"><h2>{html.escape(entry.name)}</h2>'
            f'<span class="tag">{html.escape(entry.layer)}</span>'
            f'<span class="tag {html.escape(entry.status)}">{html.escape(entry.status)}</span></div>'
            f'<p class="purpose">{html.escape(entry.purpose)}</p><dl>{rows}</dl>{"".join(pictures)}</section>'
        )
    nav = "".join(f'<a href="#{dc.snake(e.name)}">{html.escape(e.name)}</a>' for e in shown)
    count = sum(1 for e in shown if e.status == "built")
    page = f"""<title>MemoX Mx Gallery</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap">
<style>{STYLE}</style>
<main>
<header><h1>MemoX Mx Gallery</h1>
<p class="lede">{count} built components from the DESIGN.md catalog, each with its contract and its goldens in the light and dark themes. Pictures are the committed <code>mx_*</code> goldens at full-HD density.</p></header>
<nav aria-label="Components">{nav}</nav>
{"".join(sections)}
</main>
"""
    return page, problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args(argv)
    page, problems = build(ROOT)
    for problem in problems:
        print(f"ERROR {problem}")
    args.out.write_text(page, encoding="utf-8", newline="\n")
    print(f"wrote {args.out}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
```

Run: `python3 tools/design/test_gallery.py` → `OK` (4 tests).

Run: `python3 tools/design/gallery.py --out <scratchpad>/mx-gallery.html` → `wrote …`, exit 0. Publish the page with the Artifact tool (icon `gallery`); republishing the same file keeps its link.

```bash
git add tools/design
git commit -m "feat(sp3a-p2): shared-widget gallery from the goldens"
```

- [ ] **Step 5: WBS, push and sign-off**

In `docs/wbs_FE.md`, set SP3a-P2 to `đang làm` with this plan's link and the evidence (tests, 32 goldens, gate). Then run `python3 tools/docs/generate.py` and `python3 tools/docs/check.py | tail -1` → `PASS`.

```bash
git add docs
git commit -m "docs(wbs): SP3a Phase 2 ready for sign-off"
```

Push: `git push -u origin claude/wonderful-ride-dnypk9`.

Ask the owner for the Phase 2 sign-off through `AskUserQuestion`. Include the gate result, the golden review page link, the gallery link, the Impeccable findings and what was done with each, and the plan's decisions 1–7.
