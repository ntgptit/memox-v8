---
name: forui-shared-widgets
description: The contract for this app's Mx* shared widgets on ForUI and for the ForUI theme in lib/core/theme/ (ADR-025). Use when building or changing an Mx* widget, the palette, the type scale or the theme host (BUILD); when a feature needs a component the Mx set does not have (ADMIT); when auditing shared widgets for states, 48dp targets, semantics, overlays or theme parity (AUDIT); when fixing a confirmed shared-widget defect (FIX). Not for values (lib/core/theme/ owns them) or a screen's layout (its detail file owns it).
---

# ForUI shared widgets

The app is drawn with ForUI 0.27.6; features compose the `Mx*` widgets in
`lib/shared/widgets/`, which are built on ForUI components
([ADR-025](../../../docs/shared/decisions/ADR-025-forui-la-he-component-giao-dien.md)).
This skill is the procedure for keeping that layer correct. Values are not
written here: they live in `lib/core/theme/` and are named in `DESIGN.md`.

## 1. Sources and precedence

| # | Source |
|---|---|
| 1 | Approved decisions: BR/UC, ADRs, `PRODUCT.md`, owner rulings, screen detail files |
| 2 | The production theme (`lib/core/theme/`), `DESIGN.md` (frontmatter rendered from it) and the reviewed goldens |
| 3 | ForUI 0.27.6 as resolved in `pubspec.lock`, read from its source in the pub cache (`~/.pub-cache/hosted/pub.dev/forui-0.27.6/lib/src/`) |
| 4 | `docs/forui-migration/FORUI_ARCHITECTURE.md`, `SHARED_WIDGET_INVENTORY.md` |
| 5 | Conventions |

Read ForUI's source, not your memory of it: its style classes, variants and
defaults change between versions.

## 2. The facade contract

An `Mx*` widget:

- takes semantic parameters (a tone, a size, a label, a callback), never a
  colour, a `TextStyle`, a padding or a ForUI style object;
- reads every value from the theme: `context.colors` (`FColors`),
  `context.status`, `context.texts`, `context.dimens`, `context.radii`,
  `context.hairline`, or a resolved ForUI style (`FTheme.of(context)`);
- restyles ForUI only through style deltas (`FButtonStyleDelta.delta`,
  `DecorationDelta.shapeDelta`, `EdgeInsetsGeometryDelta.value`, …) or
  `FVariants`, so every state ForUI resolves keeps working;
- holds no copy: callers pass localized strings;
- keeps a `sizeControl` target, painting a smaller control inside it with
  `mxInsetDecoration` / `mxTargetStyle`;
- keeps one semantics node per control, with its label, state and actions
  (`MxTooltip` folds ForUI's tooltip long press into it);
- opens overlays only through `showMxDialog`, `showMxBottomSheet`,
  `showMxSnackbar`.

A public API change is a breaking change: update every caller in the same PR,
prove it with tests, record it in `SHARED_WIDGET_INVENTORY.md`, and never leave
a forwarding alias (`tools/design/removed_symbols.json`).

## 3. Workflows

**BUILD** (a new or changed widget, palette or theme host):
1. Read the widget's file, its tests and goldens, `DESIGN.md`, and the ForUI
   component's source.
2. Write the contract test first (`test/shared/widgets/<widget>_test.dart`;
   `mx_button_test.dart` is the reference): callbacks, enabled/disabled,
   loading, selection, semantics, focus, 48dp target, light and dark.
3. Build on the ForUI component. A value ForUI does not have is a theme
   change (`docs/agent/visual-change.md`), not a literal.
4. Run the narrow checks: `run_tests.sh` on the touched tests,
   `dart run tools/ui_lint/ui_lint.dart <files>`, `python3 tools/design/check.py`,
   `run_goldens.sh --changed`.

**ADMIT** (a feature needs a component the Mx set lacks): the component gets an
`Mx*` facade with its tests first, then features use it. Never import
`package:forui` in a feature (UIL06), never use a Material component there
(UIL03). If ForUI has no fitting component, build it from Flutter primitives in
`lib/shared/widgets/` and say why in its doc comment (`MxSpinner` is the
example).

**AUDIT**: for each widget, check every state against `DESIGN.md` and the
contract above; report each as `VERIFIED`, `FAILED`, `UNVERIFIED` or `N/A` with
its evidence (CLAUDE.md "A screen is a state machine").

**FIX**: a shared defect is fixed in the shared widget or the theme, never in a
screen (CLAUDE.md "Fix at the lowest shared owner"). Search for the same
mechanism in the other `Mx*` widgets before closing.

## 4. ForUI behaviours that bite

- **Press timers.** `FTappable` starts 100 ms timers on press; a widget test that
  taps must settle (`pumpAndSettle`) or it ends with a pending timer.
- **Semantics.** ForUI's tappable reports `hasSelectedState`; a
  `semanticsLabel` excludes the children. Find nodes with
  `find.bySemanticsLabel`; `find.byTooltip` does not see `FTooltip`.
- **Tooltip long press** is its own unlabelled semantics node unless merged:
  wrap with `MxTooltip`, never a bare `FTooltip`.
- **Barriers pop.** ForUI's dialog and sheet barriers call `Navigator.pop`
  directly, bypassing `PopScope`; a held popup overrides `barrierDismissible`
  through `MxHeldRoute`.
- **`FTextField` `onChange`** fires on every controller change, including
  programmatic ones; `MxUserEdits` keeps the `onChanged`-per-user-edit contract.
- **`FCircularProgress` stops under reduced motion**, so `MxSpinner` stays
  custom.
- **Icon sizes** are ForUI's per button size (a large ghost icon is smaller than
  `sizeIcon`); set the glyph size when a layout depends on it (`MxIconButton`).
- **Text style leaks.** The Material host's `DefaultTextStyle` comes from the
  host theme; `materialHostTheme` builds it from ForUI's scale so no letter
  spacing leaks into ForUI text.
- **Two Material packages.** ForUI uses `material_ui`, whose `ThemeData` and
  `ThemeExtension` are not the SDK's. Theme extensions extend `material_ui`'s.

## 5. Gates

| Gate | Command |
|---|---|
| UI boundary lint | `dart run tools/ui_lint/ui_lint.dart [files]` (UIL00..UIL06, table in `FORUI_ARCHITECTURE.md`) |
| Theme structure, palette, removed names | `python3 tools/design/check.py` |
| Design docs equal the theme | `test/tools/design_doc_test.dart` (`MEMOX_WRITE_DESIGN_DOCS=1` rewrites) |
| Contrast | `test/core/theme/token_contrast_test.dart` |
| Production theme and overlays | `test/app/production_theme_test.dart` |
| Everything | `dod_check.sh`, then `run_goldens.sh` and the `golden-compare` page when goldens change |
