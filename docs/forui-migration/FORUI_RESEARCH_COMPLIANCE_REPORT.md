# ForUI research compliance report

The owner's directive: no MemoX UI component is implemented from remembered
ForUI behaviour; each follows Investigate → Verify API → Compare behaviour →
Write tests → Implement → Validate, at the highest suitable ForUI level
(native > composition > foundation > justified Flutter fallback). This
report says how far the branch meets it. The evidence is in
[FORUI_API_CATALOG.md](FORUI_API_CATALOG.md) (what forui 0.27.6 provides,
from its installed source and its documentation at the matching tag) and
[FORUI_RESEARCH_LEDGER.md](FORUI_RESEARCH_LEDGER.md) (one record per
component).

## What was done, in order

1. **Catalog.** Every public ForUI API the app could use, read from the
   installed package (`forui-0.27.6/lib/`), the official docs sources at tag
   `forui/0.27.6` and ForUI's own tests, with a source line per claim.
2. **Re-audit.** Every shared widget and every significant feature UI
   component already migrated was audited again against the catalog, with its
   contract tests run and, where reading the source could not settle a
   question, a throwaway probe against forui 0.27.6 outside the repository.
   No component was trusted because it already passed its tests.
3. **Corrections.** Each correction got its contract tests first, run against
   the old code (a test that must change behaviour failed there; a test that
   pins what must survive passed there), then the change, then the
   component's tests and every caller's tests.

## Counts

| Measure | Count |
|---|---|
| Components audited (records) | 90 (G1 actions and overlays 17, G2 inputs and selection 16, G3 layout and navigation 19, G4 data surfaces 17, G5 feature components 21) |
| Records with a verified mapping (every claim cites source, docs, a ForUI test or a probe) | 90 |
| Records with missing evidence | 0 |
| Status at audit time | 60 MIGRATED, 22 CORRECTION NEEDED, 8 BLOCKED |
| Selected level: native ForUI widget (configured by style delta or parameters) | 17 |
| Selected level: ForUI composition (ForUI widgets composed by an Mx facade) | 29 |
| Selected level: ForUI foundation (`FTappable`, `FFocusedOutline`, routes) + minimal Flutter | 7 |
| Selected level: justified Flutter fallback | 37 |
| BLOCKED (an owner ruling or a ForUI API limit; fallback kept with evidence) | 8 |
| Unnecessary reimplementations found | 16 |
| Defects found that were not reimplementations | 4 |
| Corrections declined with evidence | 3 (one decision) |
| Corrective actions implemented | 19 records changed in code, plus 2 test-only gaps closed |

The fallbacks are mostly where ForUI has no component (charts, painted
study surfaces, drag-to-reorder, pull-to-refresh, selectable text, scroll
fades, the screen's route name) or where a ForUI component breaks a verified
contract (the 48dp target, the row heights, the semantics a screen's rulings
require). Each one names the ForUI APIs considered and the line that rules
them out.

## Unnecessary reimplementations found and corrected

| Component | What MemoX rebuilt | ForUI API now used |
|---|---|---|
| `MxFab` | The primary button's variants, rebuilt by hand to add a shadow | `FButton.icon(variant: primary, size: lg)` + `FVariantsDelta` shadow on every state |
| `MxSheetActions` | A hairline drawn with a `DecoratedBox` | `FDivider` + `FDividerStyleDelta` |
| `MxDialog` | Its own entrance animation object | The route's animation (`ModalRoute.of(context)?.animation`) |
| `MxSnackbar` | Toast durations and the reduced-motion rule from Material | `FToastMotion` from the theme and `context.accessibility`, ForUI's toaster rule |
| `MxFloatingNotice` | A hand-painted surface | `FCard` + a decoration delta |
| `MxSpinner` | A controller and a custom painter | `FCircularProgress` in an `FAccessibilityScope` |
| `MxSearchField.trigger` | A painted text field with its own tap and semantics | `FButton` (lg) + a style delta |
| `MxChoiceTile` | A `GestureDetector` with no keyboard focus | `FTappable.static` + the theme focus outline |
| `MxStudyTopBar` | A hand-built chip and track | `MxToneBadge` (`FBadge.raw`) and `MxLinearProgress` |
| `MxNavRail` | A hand-drawn frame and edge | `FSidebar.raw` |
| `MxBreadcrumb` | Its own segment row | `FBreadcrumb` + `FBreadcrumbItem` |
| `MxRowInk` | ForUI's default press timing on a list row | The item press timing, `itemStyles.primary.tappableStyle` |
| `MxLinearProgress` | A tween over coloured boxes | `FDeterminateProgress` + a style delta |
| `RecallCountdownBarWidget` | A second hand-built track | `MxLinearProgress` (`FDeterminateProgress`) |
| `CardRemovableTagChipWidget` | A hand-painted chip with a `GestureDetector` and its own semantics | `MxChipTrigger(isGhost: false)` = `FButton` xs outline |
| `LibrarySearchScreen` | A focus node requested after the first frame | ForUI's `FTextField(autofocus:)` through `MxSearchField(isAutofocused:)` |

## Defects found that were not reimplementations

| Component | Defect | Fix |
|---|---|---|
| `showMxDialog` | Pushed on the nearest navigator, so inside a tab the bottom bar stayed tappable through the scrim (PROBE) | The root navigator |
| `showMxDialog`, `showMxBottomSheet` | ForUI's Vietnamese barrier strings reached TalkBack as "Scrim" and a literal `$modalRouteContentName` | Barrier and grabber strings from `MaterialLocalizations`, the pre-migration source |
| `MxAppShell` / app root | The status-bar style ForUI's `FScaffold` applies was applied nowhere, because the app keeps Material's `Scaffold` | `AppThemeHost` puts `theme.scaffoldStyle.systemOverlayStyle` in an `AnnotatedRegion` |
| `MxSlider` | ForUI's tooltip showed a percentage while TalkBack read the caller's unit | `tooltipBuilder` in the caller's unit |

`showMxBottomSheet` stays on the nearest navigator: owner ruling M3C-52
(KEEP_EXISTING) decides that, and the ledger records it.

## One decision against a ledger correction

The audit proposed moving the accessible name of `MxButton`, `MxIconButton`
and the stepper's buttons out of `FButton.semanticsLabel`, because ForUI
excludes the child semantics when a label is given (`button.dart:302-304`),
which drops the input-focus flag and the `focus` action from the node. It was
not done. On Android, TalkBack focuses any node with a label or an action,
and the node keeps its tap (`tappable.dart:707-723`). Keyboard focus is the
`Focus` widget, which the label does not touch. The change brings no
user-visible gain on the only platform this app targets.

## What remains outside verification

- No device and no TalkBack run in this environment: every semantics claim
  is a widget test, never a run on a device.
- Golden images changed for the visual corrections. They are regenerated and
  shown before, after and as a diff on the review page; the owner reviews
  them before any merge.
- forui.dev answered 403 here, so the docs were read from their sources at
  the matching tag, which is what `llms.txt` is generated from.
- The MemoX v9 POC was not available and was not used.
