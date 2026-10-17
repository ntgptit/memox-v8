# Migration execution

How the move from the hand-built Material 3 system to ForUI was carried out,
phase by phase, with the decisions taken along the way. Branch
`claude/ecstatic-lovelace-s80gci`, from `a4f56ce2`.

## Phases

| Phase | Work | Outcome |
|---|---|---|
| 1–2 Baseline and audit | Clean worktree of `a4f56ce2`; full gate and goldens run there; `SOURCE_AUDIT.md` | Baseline gate PASS (4745 tests), goldens PASS; APK build blocked by the network (see `MIGRATION_VERIFICATION.md`) |
| 3 Decision | ADR-025; `FORUI_ARCHITECTURE.md` | ForUI 0.27.6 pinned; Material kept as one-way infrastructure |
| 5 Theme and root | `lib/core/theme/` rebuilt on `FThemeData`; `AppThemeHost` in `MaterialApp.router`'s builder | One palette file, one status-colour file, the type scale, `AppDimens`; Light/Dark/System through `themeMode` |
| 6 Shared widgets | The `Mx*` widgets rebuilt on ForUI components (inventory in `SHARED_WIDGET_INVENTORY.md`) | Public contracts kept, except the four breaking changes listed in the inventory |
| 7 Call sites and tests | A codemod renamed theme reads in `lib/` and `test/`; the test harness moved onto the ForUI host; every test file migrated (three parallel test agents, then the defects they found fixed in `lib/`) | Tests assert ForUI's resolved styles, not Material values |
| 8 Gates and legacy | `tools/ui_lint` replaces `tools/m3_lint`; `tools/design/check.py` rewritten; design docs rendered from the theme; guard rules, hooks, skills, CLAUDE.md updated; legacy removed (`LEGACY_REMOVAL.md`) | See `FORUI_ARCHITECTURE.md` for the rule tables |
| 9–10 Verify and report | Full gate, goldens regenerated with a review page, Android builds attempted | `MIGRATION_VERIFICATION.md` |

## Decisions taken without the owner (routine, reversible)

| Decision | Why |
|---|---|
| Keep `MaterialApp.router` | go_router 18 builds Material pages when it finds a `MaterialApp`; replacing it brings no visual gain and risks the routing behaviour the task said to keep |
| Palette: ForUI neutral base, MemoX indigo `primary`, three contrast adjustments | Keeps the brand accent; every pair holds 4.5:1 / 3:1 with no exception list (`token_contrast_test.dart`) |
| Twelve text roles kept as `MxTextRoles` on ForUI's type scale | Keeps the screens' hierarchy and the guard rule on roles; sizes are ForUI's steps |
| `MxSpinner` stays custom | ForUI's `FCircularProgress` stops animating under reduced motion, so a loading state would look frozen |
| `MxSnackbar` renders `FToast` from its own host instead of ForUI's toaster | ForUI's toaster puts an unlabelled tap on the screen's root semantics node (a TalkBack defect); the host keeps "above every route" |
| Held popups gate ForUI's barrier at hit-test time | ForUI's barrier pops with `Navigator.pop` and fixes its dismiss at build; the hold must apply from the frame it starts |
| `MxIconButton` glyph at `sizeIcon` | Bars put the glyph on the screen margin; ForUI's default ghost icon is smaller |
| `MxSettingsRow` subtitle gap 2, as `MxListRow` | ForUI's taller line heights pushed the two-line row past `sizeListRowTwoLine` |
| `MxDividedColumn` draws `border`, not ForUI's divider `secondary` | One hairline colour (DESIGN.md); ForUI's divider is barely visible on white |
| Retire the Material 3 skills instead of rewriting them | Their content was Material slot checklists; `forui-shared-widgets` carries what still applies |

## Defects found by the contract tests and fixed at the shared owner

Each was reproduced by a failing test before the fix; root causes are in the
commit messages.

| Widget | Defect | Fix |
|---|---|---|
| `MxIconButton`, `MxFab`, stepper steps | ForUI's tooltip long press made an unlabelled semantics node | `MxTooltip` merges it into the labelled node |
| `MxIconButton` | Glyph 2dp off the screen margin in the bars | Glyph at `sizeIcon`, padding keeps the 48 box |
| `MxToggle` | Filled a bounded height; kept focus when disabled | `heightFactor: 1`; `ExcludeFocus` when disabled |
| `MxRowInk` | Remounted its child when enabled/static flipped | Global keys restored, as before the migration |
| `MxSettingsRow` | Two-line row 73 tall | Gap 2 |
| `MxSnackbar` | 40-tall action; root-node tap | `MxButton` action; own toast host |
| `MxOptionRow`, `MxSelectionCheckbox`, search trigger | Painted ForUI control kept a focus node | `mxPaintedOnly` |
| `MxFilterChip` | Count ignored the chip's ink | Count takes the button's text colour |
| `MxButton` | Loading + disabled dimmed label and spinner | `mxTargetStyle(isLoading:)` freezes the foreground |
| `MxSlider` | TalkBack read a percentage; 25-tall target | ForUI's `semanticFormatterCallback`; margins of a 48 box seek |
| `MxTextField` | Name on a parent node; a wrapping hint held a filled box open; "Required" merged into the name | Name on the input node; hint only while empty; marker its own node |
| `MxSearchField` | Search screen named its route with nothing | Name and route flag on the input node |
| `MxBottomSheet` / `MxDialog` | Held popup dismissible by a scrim tap in the hold's first frame; drag on locked rows | Immediate hold with a barrier gate; opaque, always-mounted drag absorber |
| `AppThemeHost` | Glyphs without a colour drew in the accent | Ambient `IconTheme` `mutedForeground` |
| Study hidden bar, skeleton | Bar equal to a recessed ground | `MxTintBase.stepOf` |

## Not done in this branch

- Linear tracking: the workspace refused new issues (free plan limit).
- On-device and TalkBack runs: no emulator or device in this environment.
- The Android builds: blocked by the network policy (`dl.google.com`).
