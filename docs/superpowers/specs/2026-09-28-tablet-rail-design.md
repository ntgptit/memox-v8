# FE-C5 · Tablet: navigation rail and a content column

Status: draft for owner review · 2026-09-28 · closes UI-base §9 row 63

## 1. Intent

The owner reviewed three rendered options on 2026-09-28 (the phone layout as it is,
A: a 640 dp column with the bottom nav, B: a navigation rail with a 720 dp column) and
chose **B**. The goal is that MemoX reads as a tablet app on a tablet and in landscape,
without redesigning any screen: every screen keeps its phone layout, and only the chrome
around it adapts.

Success:

- At a window width of 600 dp or more, the four top-level destinations sit in a
  navigation rail on the leading edge; below 600 dp the app is exactly as today.
- Every screen's chrome and content (app bar, scroll body, footer) is at most 720 dp
  wide and centred; the page ground fills the rest.
- Phone goldens do not change.

Not in scope (unchanged decisions): two-pane or list-detail layouts, larger type or
spacing on tablets, a tablet-specific kit, per-screen wide layouts. PRODUCT.md's
"phone first" principle stays.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | One breakpoint, **600 dp** window width (Material's compact/medium line). No window-size-class type: a width check where it is needed | Two behaviours only; a class hierarchy would be speculative structure |
| D2 | A new shared widget **`MxNavRail`** takes the same `MxNavDestination` list, `selectedIndex` and `onSelected` as `MxBottomNav`. `_TabShell` picks one by width | The kit has no rail; one API keeps the shell's destinations in one place |
| D3 | **`MxAppShell` caps its column at 720 dp**, centred: app bar, body and footer. The page ground (`surface`) stays full width. Below 720 dp nothing changes | Every screen, including pushed ones (study session, settings pages, editors), gets the cap from the one widget they all use |
| D4 | The FAB anchors to the column's trailing edge (16 in), not the window's | It stays next to the content it acts on, as on a phone |
| D5 | A floating snackbar is at most the column wide, centred | A 1200 dp snackbar reads as a banner, not a message |
| D6 | Sheets and dialogs are unchanged: a modal sheet is already capped at 640 dp by Material 3, `MxDialog` has its own widths | Nothing to add |
| D7 | Phone landscape counts by width: a phone at 800 × 360 gets the rail | Same rule as Material; the rail scrolls if the height is short |

## 3. `MxNavRail` (Impeccable shape — the kit does not draw a rail)

Built from `MxBottomNav`'s tokens, so the two read as the same control:

- Width 80, ground `surfaceContainerLow`, full height, no edge line; it adds the leading
  and top safe-area insets itself.
- Destinations top-aligned, 8 below the top inset, 4 between them. Each is at least
  56 tall and 48 wide: the glyph (`AppIconSize.compact`) inside a pill (horizontal
  padding `gutter`, vertical `micro`), and under it the label in `navLabel`.
- Selected: filled glyph in `primaryInk` on the pill tint `MxBottomNav` uses
  (`primary` at 0.14 light / 0.20 dark); label `navLabel(isSelected: true)`. Resting:
  outlined glyph and label in `onSurfaceVariant`.
- Semantics as `MxBottomNav`: each item a button, `selected` on the current one, its label
  as the name.
- At text scale 2 a label stays on one line and ellipsizes; when the items are taller
  than the window, the rail scrolls. Nothing overflows.
- Re-tapping the current destination returns its branch to its root, as today.

The owner saw the rail in the B mockup (rendered with Material's `NavigationRail`); the
built widget follows the tokens above.

## 4. Changes

| Where | Change |
|---|---|
| `lib/core/theme/foundations/app_size.dart` | `navRailBreakpoint = 600`, `contentMaxWidth = 720`, `navRail = 80` |
| `lib/shared/widgets/mx_nav_rail.dart` | New, §3 |
| `lib/shared/widgets/mx_app_shell.dart` | D3 column cap; D4 FAB anchor on the column |
| `lib/app/router/app_router.dart` `_TabShell` | Width ≥ 600: `Row(MxNavRail, Expanded(branch))`, no bottom bar; below: as today |
| `lib/shared/widgets/mx_snackbar.dart` | D5 width cap |
| `lib/app/gallery/` | A rail entry beside the bottom nav |
| `PRODUCT.md` | "Phones only" becomes: phones first; on tablets and in landscape, a rail and a 720 dp column (FE-C5) |
| UI-base spec §9 | Row 63 closed; a new row records the rail and the column as V8's, not the kit's |
| `docs/wbs_FE.md` | FE-C5 done |

## 5. Testing

- `MxNavRail`: widget tests (destinations, selection, re-tap, semantics, 48 targets, text
  scale 2 with no overflow, scroll when short) and light/dark goldens.
- `MxAppShell`: at 1280 dp the column is 720 wide and centred, the FAB sits 16 in from
  the column's edge; at 360 dp the layout is unchanged (existing tests and goldens).
- `_TabShell`: at 599 dp the bottom nav shows, at 600 dp the rail; switching tabs from
  the rail keeps each branch's stack.
- App goldens at 1280 × 800 (Library root) and 800 × 1280 (a deck level), light and
  dark; the tap-target guidelines run on them.
- All phone goldens stay byte-identical.

## 6. Risks

- A screen that measures `MediaQuery.sizeOf(context).width` for its layout would see the
  window, not the column. Today only the sheet (height) and the study top bar
  (`LayoutBuilder`) measure, so nothing reads the width wrongly; the plan checks again.
- Rollback: revert the PR; no data or schema is touched.
