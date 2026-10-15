# M3 shared-widget conformance (DEV-372)

**Goal:** Bring the shared widgets (`lib/shared/widgets/`, `lib/core/theme/app_component_themes.dart`) in line with the Material 3 component specs. The owner's ruling (2026-10-14): where M3 and Impeccable/DESIGN.md disagree, M3 wins. Groups A (plain M3 breaks) and C (documented deviations inherited from the retired kit or from DESIGN.md prose) are fixed. Group B (values that come from `design/tokens.json`) and group D (owner rulings: Trash's two filled buttons, DEV-230 disabled-row subtitle, SW-REV-007 flat snackbar, SB-U1 floating notice) stay as they are and are only reported.

**Source of M3 values:** m3.material.io is unreachable from this container (DNS/proxy), so values come from sources generated from the M3 token database: the Flutter 3.47.5 SDK `_*DefaultsM3` classes (`/root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/material/`), the Compose Material3 token files, MDC-Android and material-web docs. Prose rules that could not be read at source are marked UNVERIFIED in the report.

**Constraints:** never edit `design/tokens.json`; app-only values go to `design/app_tokens.json` and through `python3 tools/design/generate.py`. No removed theme names (`tools/design/removed_symbols.json`). No `else`, early return, English comments, no gate weakening. Every fix: verify the finding on the code first, a test that fails before and passes after, then the widget's own tests. Goldens are regenerated once at the end (`run_goldens.sh --update`, Linux only), followed by a golden-compare page.

**Token rules that bound the fixes:**
- `secondaryContainer`: "Chip … Never a button background". Filter chip selected may use it; a segmented button may not (its selected segment shows a check, the outline and the accent label; the fill is a TOKEN item for the owner).
- `radius-sm` (8): chips and NoticeBanner. `radius-xs` (4): tooltips, small marks. `radius-md` (12) stays for text fields (TOKEN).
- `outlineVariant`: not for divider lines; dividers use `divider`.
- `size-control` (48) is the icon button size (TOKEN, stays).

## Tasks

### Task 1 — Buttons (`mx_button.dart`, `app_component_themes.dart` `buttonStyle`)
- Text tone: 12dp horizontal padding (SDK `_TextButtonDefaultsM3`), other tones keep 24.
- Leading icon 18dp, 8dp gap to the label (SDK `iconSize` 18). Add `sizeIconButton: 18` to `app_tokens.json` if no token fits.
- Focus indicator visible on filled tones: the 2dp `primary` edge on a `primary` fill is 1:1. Draw the focus ring offset outside the container (2dp gap, `primary`), as `tokens.json` says ("focus ring in primary, offset 2px"), for every tone.
- Tests: padding per tone, icon size and gap, a focused filled button paints a ring outside its fill.

### Task 2 — Double dimming (`mx_stepper.dart`, `mx_filter_chip.dart`)
- Root cause: an `Opacity(0.38)` wrapper over `TextButton`s that already resolve their disabled state (container 12%, content 38%). Remove the wrapper; dim only non-button content (the stepper's value text) once.
- Check similar: every `Opacity(` in `lib/shared/widgets/` over a widget that resolves `WidgetState.disabled`.
- Tests: a disabled stepper's step button paints exactly the theme's disabled colours.

### Task 3 — FAB (`mx_fab.dart`, `app_tokens.json`)
- `sizeFab` 56, icon 24 (`sizeIcon`), corner 16 (`radiusLg`), elevation 6 resting / 8 hovered; hover 8% and focus 10% state layers and a visible focus indicator. Build on `FloatingActionButton` + `FloatingActionButtonThemeData` if it removes hand-rolled state code.
- Colour stays `primary`/`onPrimary` (DESIGN.md; `primaryContainer` equals `primary` here).

### Task 4 — Chips (`mx_filter_chip.dart`, `mx_chip_trigger.dart`, `MxButtonSize.chip`, `chipTheme`)
- Height 32 (`sizeChip` in `app_tokens.json`), corner 8 (`radiusSm`), icon 18, label inset 16 (8 + 8).
- Filter chip: unselected flat, no fill, 1dp `outlineVariant` edge; selected `secondaryContainer`/`onSecondaryContainer`, no edge, leading check 18dp.
- Chip trigger keeps its ghost look but takes the chip geometry.
- Make `chipTheme` the single source the Mx chips read, or delete its dead fields.

### Task 5 — Switch (`mx_toggle.dart`)
- M3 switch geometry: track 52×32, 2dp `outline` edge when off; handle 16 off, 24 on, 28 pressed; selected handle `onPrimary`, unselected handle `outline`; selected track `primary`, unselected `surfaceContainerHighest`; disabled track 12%, handle 38%; 40dp state layer. Prefer Material `Switch` with `SwitchThemeData` if the app's semantics and tests hold.
- Add the thumb/track pairs to `token_contrast_test.dart`.

### Task 6 — Radio and checkbox (`mx_option_row.dart`, `mx_selection_checkbox.dart`)
- Radio: 20dp icon, 2dp ring + 10dp dot when selected (SDK outer 8 radius, inner 4.5), unselected `onSurfaceVariant`, selected `primary` (accent in dark per DESIGN.md Accent Text).
- Checkbox: 18dp box, 2dp corner (add `radiusCheckbox: 2` to `app_tokens.json`), 2dp `onSurfaceVariant` border.

### Task 7 — Segmented button (`mx_segmented_tray.dart`)
- M3 segmented button: stadium container 40dp, 1dp `outline` edge between and around segments, `labelLarge` label, selected segment shows an 18dp check before the label and the accent label colour; 48dp targets. Selected fill: TOKEN item (secondaryContainer forbidden for buttons).

### Task 8 — Dialog, sheet, snackbar, tooltip, scrim
- `MxDialog`: title `headlineSmall` `onSurface`; body `bodyMedium` `onSurfaceVariant`; both read `DialogTheme`; padding 24, title→body 16, body→actions 24; min width 280; shadow transparent (elevation kept).
- `MxBottomSheet`: `surfaceContainerLow`; elevation 1, shadow transparent; drag handle 32×4 `onSurfaceVariant` centred in a 48×48 target.
- Scrim `opacityScrim` 0.32 (`app_tokens.json`).
- Snackbar: corner 4 (`radiusXs`), message vertical padding 14, an action label wider than 25% of the toast goes on its own line.
- Tooltip: min height 24, padding 8×4.
- `MxTintBase` follows the new sheet ground; contrast exceptions are re-measured.

### Task 9 — Lists, dividers, progress, skeleton, banner
- `MxListRow` (and rows that share its minimum): min height 56 one line, 72 two lines.
- `MxDividedColumn`: 16dp inset each side for rows inside a card or section, `divider` colour.
- `MxMasteryDonut`: track `surfaceContainerHighest` (token "countdown ring track"), via `MasteryRamp.track`.
- `MxSkeleton`: corner `radiusSm` (8); bar colour one step off the ground it sits on.
- `MxInlineBanner`: no border (M4), corner `radiusSm` (8, token NoticeBanner).
- `progressIndicatorTheme`: drop the dead circular colour or drive the Mx indicators from it.

### Task 10 — App bar, navigation, layout
- `MxAppBar`: `surface` → `surfaceContainer` while content scrolls under (shell listens to the body's scroll); leading/trailing icon glyphs aligned to the body margin; trailing action icons `onSurfaceVariant`.
- `MxNavItem` (bar and rail): animate the pill (colour and width) over the motion tokens, honour `disableAnimations`; ink clipped to the pill; target the full cell height.
- Bar vs rail: bar when the window height is compact (<480) too.
- `windowSize` and `screenMargin` from the full window width, not the pane beside the rail.
- `MxFooterBar`: horizontal padding `screenMargin`.
- `MxSearchField.trigger`: pressed/hover ripple via `MxRowInk`, clipped to the stadium.
- Doc: `01-deck-list.md` "MxAppBar (large)" → "(screen)".

### Task 11 — Text fields (`mx_text_field.dart`, `mx_field_message.dart`, `app_tokens.json`)
- `sizeInput` 56, horizontal padding 16, input text `bodyLarge`.
- Paint the `label` above the field (4dp gap, `onSurfaceVariant`, `error` in error); remove the per-screen hand-built labels.
- Add `supportingText` and `counter` to the supporting row (counter at the trailing end); move the two feature counters onto it.
- Caret `error` while in error.
- Field message aligned to the field's text inset.

### Task 12 — Docs, gate, goldens
- DESIGN.md prose follows every change (Shapes, Components, Typography, rules); `tools/design/check.py` clean; screen detail files whose widgets changed.
- `dod_check.sh`, `run_goldens.sh --update`, golden-compare page, green rerun; report B and D items to the owner.
