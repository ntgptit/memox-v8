---
name: MemoX V8
description: A quiet, focused study space for spaced-repetition flashcards, in a light and a dark theme generated from one token file.
colors:
  primary: "#564BCB"
  on-primary: "#FFFFFF"
  primary-container: "#564BCB"
  on-primary-container: "#D9D4FF"
  primary-fixed: "#E3DFFF"
  primary-fixed-dim: "#C5C0FF"
  on-primary-fixed: "#130067"
  on-primary-fixed-variant: "#3D2FB2"
  secondary: "#535E7A"
  on-secondary: "#FFFFFF"
  secondary-container: "#D1DCFD"
  on-secondary-container: "#55607C"
  secondary-fixed: "#D9E2FF"
  secondary-fixed-dim: "#BBC6E6"
  on-secondary-fixed: "#0F1B33"
  on-secondary-fixed-variant: "#3B4661"
  tertiary: "#723700"
  on-tertiary: "#FFFFFF"
  tertiary-container: "#964A00"
  on-tertiary-container: "#FFD0B2"
  tertiary-fixed: "#FFDCC6"
  tertiary-fixed-dim: "#FFB785"
  on-tertiary-fixed: "#301400"
  on-tertiary-fixed-variant: "#723700"
  error: "#BA1A1A"
  on-error: "#FFFFFF"
  error-container: "#FFDAD6"
  on-error-container: "#93000A"
  surface: "#FFFFFF"
  on-surface: "#1C1B21"
  surface-dim: "#DFE0E0"
  surface-bright: "#FFFFFF"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#F9F9F9"
  surface-container: "#F3F3F3"
  surface-container-high: "#EEEEEE"
  surface-container-highest: "#E8E8E8"
  on-surface-variant: "#3B4661"
  outline: "#6C7794"
  outline-variant: "#BBC6E6"
  shadow: "#000000"
  scrim: "#000000"
  inverse-surface: "#313036"
  on-inverse-surface: "#F3EFF7"
  inverse-primary: "#C5C0FF"
  surface-tint: "#564BCB"
  success: "#006C49"
  on-success: "#FFFFFF"
  success-container: "#17AE79"
  on-success-container: "#003925"
  warning: "#855300"
  on-warning: "#FFFFFF"
  warning-container: "#F59E0B"
  on-warning-container: "#613B00"
  info: "#006684"
  on-info: "#FFFFFF"
  info-container: "#50CCFC"
  on-info-container: "#00546D"
  card-surface: "#F1F1FB"
  search-surface: "#F1F1FB"
  tile-surface: "#EDF8FF"
  divider: "#EEEEEE"
typography:
  display-term:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 400
    lineHeight: "32px"
    letterSpacing: "0px"
  term-tile:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: "28px"
    letterSpacing: "0px"
  display-stat:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 500
    lineHeight: "36px"
    letterSpacing: "0px"
  title-section:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: "28px"
    letterSpacing: "0px"
  title-card:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: "24px"
    letterSpacing: "0.15px"
  title-item:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "20px"
    letterSpacing: "0.1px"
  body-content:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
    letterSpacing: "0px"
  body:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
    letterSpacing: "0.25px"
  body-tile:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "16px"
    letterSpacing: "0px"
  label-button:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
    letterSpacing: "0.1px"
  label-meta:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
    letterSpacing: "0.5px"
  label-nav:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "16px"
    letterSpacing: "0.5px"
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "28px"
  full: "9999px"
spacing:
  space-4: "4px"
  space-8: "8px"
  space-12: "12px"
  space-16: "16px"
  space-24: "24px"
  space-32: "32px"
  space-48: "48px"
  margin-screen: "16px"
  margin-screen-medium: "24px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-secondary:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-outline:
    textColor: "{colors.primary}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-destructive:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  card:
    backgroundColor: "{colors.card-surface}"
    rounded: "{rounded.md}"
    padding: "24px"
  search-field:
    backgroundColor: "{colors.search-surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-meta}"
    rounded: "{rounded.full}"
    height: "56px"
  text-field:
    backgroundColor: "{colors.surface-container-low}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "52px"
  filter-chip:
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.label-button}"
    rounded: "{rounded.sm}"
    height: "32px"
  filter-chip-selected:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
    typography: "{typography.label-button}"
    rounded: "{rounded.sm}"
    height: "32px"
  nav-indicator:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
    rounded: "{rounded.full}"
    width: "56px"
    height: "32px"
---

# Design System: MemoX V8

## Overview

**Creative North Star: "The Quiet Study Desk"**

MemoX should feel like a quiet, focused study space. One structure ships two themes, light and dark, both generated from `design/tokens.json` (the "Flashcard Color Tokens" Design System, ADR-022): a calm page, cards raised by tone alone, and one accent that means "act". Every value in the app comes from that file; this document names the tokens and says how to use them, and never restates a value. To change the look, change the token file and run the generator (`docs/agent/visual-change.md`).

- Content is always more prominent than chrome.
- Hierarchy and spacing create structure before decoration does.
- Surfaces are raised by tone, never by a border or a shadow.
- The accent communicates the primary action.
- Green is semantic and reserved for mastery and success.
- Density supports efficient studying without crowding the screen.
- Empty space is intentional, not unfinished.
- Consistency takes priority over decorative novelty.

**Key Characteristics:**
- One sans family (Be Vietnam Pro, with Noto Sans KR for Korean), twelve Material roles, each used as the token defines it.
- Tonal surfaces: `cardSurface`, `searchSurface` and `tileSurface` sit on `surface` with no edge and no shadow.
- One accent rule: `context.accentColor` for accent text and glyphs, `primary` for fills, edges and indicators.
- Phone first, `context.screenMargin` at the screen edge, `sizeControl` touch targets everywhere.
- Every text and edge pair is contrast-tested in both themes; the pairs below AA are recorded in `design/contrast_exceptions.json`.

## Colors

A violet-indigo accent on a neutral field, a green that only ever means progress, an amber for warning and a blue for information. The frontmatter holds the light values; `.impeccable/design.json` `colorMeta` carries both themes. The Material roles are the generated `ColorScheme` (`context.colors`); the Design System's own colours are `MxColorsExtension` (`context.mxColors`).

### Primary
- **Accent** (`primary`): the fill of the primary button, the FAB and progress indicators, and the focus ring. It is the same in both themes.
- **Accent Text** (`context.accentColor`): the accent as text or glyph: outline and text buttons, links, a matched search term, the selected destination's glyph, the selected radio and the checked checkbox's fill (with `onAccentColor` for its check). It is `primary` in light and `primaryFixedDim` in dark, where `primary` on the page is too dim for text.
- **Accent Tint** (`context.accentColor.tintOver(colors.surface)`): the hero card and the accent's tinted tiles.

### Neutral
- **Page** (`surface`): the screen, the app bar, the bottom bar and the rail.
- **Card** (`cardSurface`): cards and the rows that are cards. **Search** (`searchSurface`): the search field. **Tile** (`tileSurface`): the deck tile behind its glyph (`context.deckIconColor`).
- **Containers** (`surfaceContainerLow` … `surfaceContainerHighest`): the field fill, the recessed study face, the secondary button, tracks, skeletons. A skeleton bar is one step off its ground: `surfaceContainerHigh` on the page, `surfaceContainerHighest` on a card, a sheet or a dialog. A dialog is `surfaceContainerHigh`; a bottom sheet is `surfaceContainerLow`, as in Material 3.
- **Text** (`onSurface`, `onSurfaceVariant`): primary and secondary text.
- **Edges** (`outline`, `outlineVariant`, `divider`): `outline` for every control edge at rest (fields, the outline button, code slots; the unchecked radio ring and checkbox box are `onSurfaceVariant`, as Material 3 draws them), `outlineVariant` for an inner rule and a disabled edge, `divider` for every hairline that separates: between list rows, above a footer or a sheet's actions, beside the navigation. `outlineVariant` is never a divider line.
- **Inverse** (`inverseSurface`, `onInverseSurface`, `inversePrimary`): the snackbar and the tooltip.

### Semantic
- **Success** (`success`, `successContainer` and their `on…` roles): a right answer, a finished session, mastery. `successContainer` is the mastery fill; `success` is its text.
- **Warning** (`warning`, `warningContainer` and their `on…` roles): a refusal or a limit where nothing was lost. `warningContainer` with `onWarningContainer` is the warning fill; `warning` is warning text and glyphs on a plain ground.
- **Info** (`info`, `infoContainer` and their `on…` roles): neutral information, the deck glyph.
- **Error** (`error`, `errorContainer` and their `on…` roles): errors and destructive actions.

### Named Rules
**The One Accent Rule.** The accent means "act". A primary fill appears once per decision; the rest of the screen is neutral. An action in an `MxInlineBanner` or `MxFloatingNotice`, and the action in an `MxFooterBar`, is primary only when the screen shows no other primary for the same decision; otherwise it is outline or secondary. A lone Close stays primary. A screen that asks *which way* fills its first way; a screen for one way fills that way's commit and outlines the other.

**The Green Means Progress Rule.** Green is `success` or `successContainer` and nothing else; green is never decoration.

**The Text Colour Rule.** Text and glyphs read a text role (`onSurface`, `onSurfaceVariant`, `context.accentColor`, `success`, `warning`, `info`, `error`, an `on…` role), never a fill. A control edge reads `outline`, a hairline `divider` or `outlineVariant`, focus `primary`.

**The Tint Rule.** A tinted ground is a role tinted over the surface directly beneath it, `color.tintOver(MxTintBase.of(context))`, at the Design System's tint strength (`opacity-dragged`). `MxCard`, `MxBottomSheet` and `MxDialog` set that base to the ground they paint; on the page it is `surface`. Nothing else lays a colour over a ground at an alpha.

**The Mode Rule.** A widget never chooses a colour or a size by brightness. A choice that differs by mode is a getter in `theme_rules.dart` (`context.accentColor`, `context.deckIconColor`), or a role the two generated themes already set differently.

**The Contrast Floor Rule.** Text holds 4.5:1 and non-text 3:1. `test/core/theme/token_contrast_test.dart` computes every pair from the token file; a pair below the floor is an entry of `design/contrast_exceptions.json` with its measured ratio and its reason, and a change that worsens one or adds one turns that test red.

## Typography

**Font:** Be Vietnam Pro, with Noto Sans KR as the fallback for Korean, both bundled; the mono face for code is `AppTypography.monoFamily`.

**Character:** One friendly, open sans throughout, at the weights the roles declare. Sizes, weights, line heights and tracking are the roles' own; a widget picks a role and changes only its colour, or switches to the mono face.

### Hierarchy
- **Term** (`displaySmall`, `display-term`): the word being studied on a flashcard.
- **Stat** (`displayMedium`, `display-stat`, tabular figures): key numbers that replace a sentence.
- **Tile term** (`headlineSmall`, `term-tile`): a word inside a match tile.
- **Section title** (`titleLarge`, `title-section`): screen and section headings, the app bar title.
- **Card title** (`titleMedium`, `title-card`): card titles and compact stats.
- **Item title** (`titleSmall`, `title-item`): list and settings rows and sheet titles (a dialog title is `headlineSmall`, as in Material 3).
- **Content** (`bodyLarge`, `body-content`): a card's meaning, a study passage.
- **Body** (`bodyMedium`, `body`): default running text, field text, notes.
- **Tile body** (`bodySmall`, `body-tile`): a meaning inside a match tile, a study option.
- **Button** (`labelLarge`, `label-button`): every button label, at every size.
- **Meta** (`labelMedium`, `label-meta`): metadata, the search field, field labels.
- **Nav** (`labelSmall`, `label-nav`): navigation labels, captions, counts, overlines.

### Named Rules
**The Twelve Roles Rule.** Screens use the twelve roles. `context.texts.<role>` may take `copyWith(color: …)` or `copyWith(fontFamily: AppTypography.monoFamily)` and nothing else; a size the roles cannot express is a Design System change, not a component override.

**The Text Grows Rule.** Text scale is never clamped and no fixed height wraps text. Heights are minimums and grow with wrapped labels and the OS text scale; the settings row stacks its trailing control at a large scale.

**The One Line Rule.** A label meant for one line fits on one line: shorten the copy, never add an ellipsis to the app's own words. A user's own text (a deck name, a tag) may end in an ellipsis. A label a layout must hold ("Per session" beside the stepper) is fixed by the layout.

## Layout

Phone first. The screen edge is `context.screenMargin` (`marginScreen` on a compact window, `marginScreenMedium` from `breakpointMedium`); the vertical rhythm is the spacing scale: `space4` icon to label, `space8` tight stacks, `space12` related rows, `space16` between list items, `space24` card interior and between sections, `space32` between major groups, `space48` the scroll tail (`MxScreenScroll`; under a FAB it also clears the FAB).

Every screen is a column in `MxAppShell`: top chrome, one scroll body, an in-flow footer, the FAB above (never over a footer). System insets are the platform's, never hard-coded.

The window size class (`context.windowSize`) sets the frame. It follows the whole window's width, also for a screen beside the rail (the tab shell publishes it), so the screen margin switches at `breakpointMedium` of the window, not of the pane. Compact: `MxBottomNav`, one column up to `sizeContentMax`. From `breakpointMedium`: `MxNavRail` on the leading edge, the bottom bar gone, content centred up to `sizeContentMaxWide`. A window shorter than `breakpointCompactHeight` keeps the bottom bar at any width, as Material 3 asks for a bar when the width or the height is compact. A study session keeps its column at `sizeContentMax` at every size. An overview splits into two columns (`MxTwoColumns`) when its content area, not the window, is at least `MxTwoColumns.minWidth`, measured with a `LayoutBuilder`.

Touch targets are `sizeControl` for every interactive control, whatever its painted size.

### Named Rules
**The Touch Floor Rule.** Painted size never sets the touch area. Paint at the size the design wants, then guarantee `sizeControl` square for the hit.

**The Column Rule.** Content never grows wider than its column; wide windows gain empty ground, not longer lines.

**The Footer Pair Rule.** Two footer actions (`MxActionPair`) share the row while both labels fit their share on one line at the current width and text scale, measured with a `LayoutBuilder`; when they do not, they stack full width, the leading action on top. A label is never wrapped or cut to keep the row.

**The Wrap Rule.** A meta line, a breakdown line, a session context line or a hint that already wraps keeps doing so between whole terms; a title keeps one line.

**The Clear Tail Rule.** A list under a FAB ends clear of it; when the FAB hides (selection), the clearance goes with it.

**The Content Gate Rule.** A control that acts on a screen's content (search, filter, select, tag, the FAB that adds a sibling to a list) exists only once that content exists, and is absent, not dimmed, until then; loading and failure count as no content. A control that creates the first content or recovers it (Create, Starter decks, Import, the Trash, Back) stays in every state. The disabled opacity is for a control that exists but cannot act right now.

## Elevation & Depth

Tonal, not shadowed. Cards and the search field are raised by their surface roles alone (`shadow-raised` is none in both themes); they have no border and no shadow. The surfaces that float above the page (dialogs, bottom sheets, the FAB, the floating notice) take Material's own elevation, the same in both themes, since the Design System defines no shadow for them. A dialog keeps the Material 3 dialog elevation and a sheet the Material 3 sheet elevation, but as in Material 3 neither draws a shadow (the theme's `shadowColor` is transparent): the surface role sets them apart. The snackbar is flat. The scrim behind a dialog or a sheet is `scrim` at `opacityScrim`, the Material 3 scrim alpha.

### Named Rules
**The Tone Before Shadow Rule.** Group with tone first; a surface that does not float never casts a shadow and never draws an edge.

## Shapes

The Material 3 shape scale: `radiusMd` for cards, fields and notes; `radiusXs` for small marks, snackbars and tooltips; `radiusCheckbox` for the checkbox corner; `radiusSm` for chips, notice banners, skeleton bars and the smallest tiles; `radiusLg` for the larger tiles; `radiusXl` for surfaces that float (dialogs, the sheet's top corners). A full radius (a `StadiumBorder`) for buttons, the search field, badges, the navigation indicator, toggle tracks and progress tracks. Hairlines are `strokeHairline`; the focus ring is `strokeFocus`, in `primary`, drawn `strokeFocusGap` outside a button's container so it shows on any fill; radio and checkbox controls use `strokeControl`: a radio is a `sizeSelectionControl` ring, selected it keeps the ring and adds a `sizeRadioDot` dot in the accent colour; a checkbox is a `sizeSelectionControl` box with a `radiusCheckbox` corner.

## Components

Calm and exact. All widgets are `Mx*` in `lib/shared/widgets/`; they hold no copy (callers pass localized strings) and read every colour, size and style from the theme.

### Actions
- **MxButton**: tones primary, secondary, outline (an `outline` edge, the accent text), text (no fill and no edge), destructive, dangerTint (the error tint with an error label) and warning; sizes regular (`sizeButton`) and small (`sizeButtonSmall`), plus the app's chip (the unselected filter chip, below) and study variants. The label is `labelLarge` at every size, the radius full, the touch area `sizeControl`. A leading glyph is `sizeIconButton` with `space8` before the label; the side padding is `space24` (`space16` on the glyph's side), and the text tone's is `space12` (`space16` after a glyph). A button alone or across a card is regular; a button sharing a row with other content is small; one card uses one size. `isLoading` swaps the label for a spinner at the same width and is never dimmed; disabled follows the Design System's disabled opacities; `semanticLabel` names the button to TalkBack on its own node, with its tap and state.
- **MxIconButton**: an icon at `sizeIcon` in a `sizeControl` circle; its long-press tooltip is on the inverse surface. **MxFab**: the Material 3 regular FAB, square at `sizeFab`, icon only at `sizeIcon`, corner `radiusLg`; it lifts a step when hovered and draws the offset focus ring.
- **MxActionPair** (a screen footer's pair, The Footer Pair Rule) and **MxSheetActions** (the pair of a dialog or a sheet, Cancel and the confirm sharing the row; the confirm is the verb alone and neither action carries an icon; `MxSheetActions.single` is one action across the row).

### Containers
- **MxCard**: `cardSurface` at `radiusMd`, no edge, no shadow, `space24` inside (`space16` when compact, two to a row). Tones: hero (the accent tint), warning, success and danger (each its role tinted over the surface), recessed (`surfaceContainerLow`). `isSelected` draws a `primary` edge at `strokeControl`.
- **MxDialog** and **MxBottomSheet**: `radiusXl`, the theme's scrim, Material elevation without a drawn shadow. A dialog is `surfaceContainerHigh` and reads the theme's dialog like Material 3's AlertDialog: `space24` all round, the title in `headlineSmall` over `onSurface`, the body in `bodyMedium` over `onSurfaceVariant`, `space16` between them, `space24` between the text and the action pair, and never narrower than the theme's minimum width. A sheet is `surfaceContainerLow` (what it holds is tinted over that ground, The Tint Rule) and opens on Material 3's drag handle, a small bar in `onSurfaceVariant` centred in a `sizeControl` target. A dialog centres in the room the keyboard leaves and scrolls its text when that room is short; a held dialog or sheet refuses Back and the scrim while its work runs. A sheet's `title` and `subtitle` draw the shared head (`titleSmall`, then the variant `bodyMedium`), the title a heading to TalkBack. `showMxConfirm` asks a yes/no question.
- **MxSection** (overline plus card; its note is an `MxNote.hint`), **MxDividedColumn** (rows with a `divider` hairline between them, none after the last, inset `space16` at each end as the Material 3 inset divider is: the one owner of list dividers), **MxNote** (one calm info line; `MxNote.hint` is the footnote form under a card, a section or an empty state), **MxDashedNote**, **MxFooterBar** (the in-flow commit bar, its sides on `context.screenMargin`; its caption fits one line on the narrowest supported phone in English and Vietnamese, as `test/l10n/footer_caption_length_test.dart` asserts), **MxScrollFade** (a fade over the edge of a scroll view while more lies past it), **MxTwoColumns**.

### Inputs
- **MxTextField**: one box for every entry: `sizeInput` at least, `surfaceContainerLow` that lightens to `surfaceContainerLowest` on focus, `radiusMd`, `bodyMedium`, an `outline` edge at rest, `primary` at `strokeFocus` on focus, `error` with an **MxFieldMessage** below on error, `outlineVariant` when disabled. Variants form, detail, term, code (six slots) and study (bare).
- **MxSearchField**: `searchSurface`, full radius, `sizeSearch` tall, no edge, no shadow; the hint and value in `labelMedium`.
- **MxStepper** (a bounded integer with press-and-hold repeat), **MxToggle** (the Material 3 switch, a `Switch` read from `switchTheme`: a full-radius track, `primary` with an `onPrimary` handle when on, `surfaceContainerHighest` with a `strokeControl` `outline` edge and an `outline` handle when off; the handle grows from small to large when it turns on and a little more while pressed; disabled, the track steps back to `opacityDisabledContainer` and the handle to `opacityDisabledContent`, and the switch dims itself; the touch area is `sizeControl` tall; the focus ring is `strokeFocus` in `primary`, `strokeFocusGap` outside the track, over the Material state layer), **MxOptionRow** (a single-choice radio row with the Material 3 radio: an `onSurfaceVariant` ring, and the accent colour for the ring and dot when selected; a dimmed row dims only its radio and title), **MxSelectionCheckbox** (the Material 3 checkbox, painted only: an `onSurfaceVariant` edge when clear, the accent colour with an `onAccentColor` check when checked), **MxSegmentedTray** (the Material 3 segmented button, a `SegmentedButton` read from `segmentedButtonTheme`: a full-radius edge `sizeButton` tall in a `sizeControl` touch band, a `strokeHairline` `outline` edge round and between the options, `labelLarge`, a `sizeIconButton` check before the chosen option; the chosen label takes the accent colour and the others `onSurface`; no option is filled, because the token rules keep `secondaryContainer` off buttons; disabled, the labels step back to `opacityDisabledContent` and the edge to `opacityDisabledContainer`; state layers are the label colour at the hover, pressed and focus opacities; the focus ring is `strokeFocus` in `primary`, `strokeFocusGap` outside the edge; when the labels do not fit on one line the options stack, one `sizeControl` line each, inside a `radiusMd` edge), **MxFilterChip** and **MxChipTrigger** (the Material 3 flat filter chip, read from `chipTheme`: `sizeChip` tall, `radiusSm` corners, `labelLarge`, a `sizeIconButton` glyph, `space8` around the chip and around the label; at rest no fill and a `strokeHairline` `outlineVariant` edge with an `onSurfaceVariant` label; selected `secondaryContainer` with an `onSecondaryContainer` label, no edge and a leading check in place of the glyph; the trigger is the ghost variant, no fill and no edge, with its glyph after the label; the touch area is `sizeControl`; the focus ring follows the corners). `MxButton`'s chip size is the same unselected chip.

### Navigation
- **MxAppBar**: `sizeAppBar`, `titleLarge`; the icon glyphs sit on `context.screenMargin`, in line with the body (the control's `sizeControl` touch area reaches past the margin by its inset), the leading one in `onSurface` and the trailing ones in `onSurfaceVariant`; a text action and a search field end on the margin. The bar has no ground of its own: `MxAppShell` paints it full-bleed behind the capped column, `surface` at rest and `surfaceContainer` once the body's scroll has moved content under it, easing over `Durations.short4` unless the platform asks for reduced motion; it clears when the body is replaced. A form's single save lives in its footer.
- **MxBottomNav**: `sizeNav` on `surface`, a `divider` hairline on top, no shadow. The selected tab is a full-radius `secondaryContainer` indicator behind its glyph (`onSecondaryContainer`) with an `onSurface` label; the rest read `onSurfaceVariant`; the label is `labelSmall`. The indicator grows in and fades in over `Durations.medium2` (at once with reduced motion); the tap target is the whole cell, and the ripple and state layers are clipped to the indicator.
- **MxNavRail**: `sizeRail` wide on `surface`, a `divider` hairline on its trailing edge, the bottom bar's indicator and colours, from `breakpointMedium`.
- **MxStudyTopBar** (its close glyph and its counter sit on `context.screenMargin`, as the app bar's glyphs do), **MxBreadcrumb** (a deep path fades its start edge; its hidden ancestors stay reachable buttons to TalkBack), **MxAppShell**, **MxScreenScroll**.

### Feedback and Status
- **MxSnackbar** (inverse surface, `radiusXs`, one optional action; the message has `space16` at the sides and 14 above and below, and an action wider than a quarter of the toast goes on its own line under the message, at the end; the action's focus ring is `inversePrimary`), **MxFloatingNotice** (the warning tint, floating over a screen that does not own the problem), **MxInlineBanner** (warning or danger, `radiusSm`, its tint with its role's glyph and title and no border: the tone is not carried by an edge), **MxEmptyState** (tones primary, neutral, success, warning, danger; each tone's tile is its tint with the role's glyph), **MxErrorState** (an inline load failure with Retry, its title a live region; a gone item is an `MxEmptyState` in the neutral tone), **MxSpinner**, the **MxSkeleton** family (`radiusSm` bars; a skeleton row is as tall as a two-line list row, so a list does not jump when it loads), **MxBadge**, **MxStatusBadge**.

### Study-specific
- **MxMasteryDonut** (its track is `MasteryRamp.track`, the same `surfaceContainerHighest` as the bar), **MxLinearProgress** (`sizeTrack` tall, full radius, a `surfaceContainerHighest` track, the `successContainer` fill) and the single **MasteryRamp**: the lowest band in `warning`, the middle in the accent, the top in `successContainer`, a flat fill and never a gradient; a label beside or inside a fill takes `MasteryRamp.foreground`, never the fill.
- **MxOutcomeTile**, **MxWorkloadBreakdownLine**, the study choice surfaces (idle, selected, right, wrong; an answered option out of play fades to `opacityMuted` and stays readable) and the recessed answer face.

### Data Display
- **MxSelectableCardRow** (a card that is one item of a list: the ink over all of it, the checkbox while selecting, one TalkBack node with its checked state), **MxListRow** (`sizeListRow` at least, `sizeListRowTwoLine` with a subtitle or a meta line, as the Material 3 list item; a disabled row dims its leading, title and end, never the line that says why), **MxSettingsRow** (the same two heights, by its subtitle; a trailing control that draws its own disabled state is not dimmed again; an `isAction` row shows no chevron; a `message` runs under the row from the label's start), **MxListSectionHeader**, **MxStatTile**, **MxStackedDayBars**, **MxTagChip**, **MxIconTile** (small, medium, large; tones tinted, primary, warning, success, caution, danger, neutral), **MxActionSheetCommandRow** (the same two heights, by its subtitle), **MxRowInk** (the shared row ripple, pressed in `onSurface` at `opacityPressed`; a pill-shaped control gives it its radius, as the search trigger does).
- **Settings pattern.** The Settings tab is a hub of `MxSection`s of navigation rows (label, the current value in the subtitle, a chevron) and at most one action row. A group with more than one setting, or a wide control, is a page of its own; on a page a boolean is an `MxToggle`, a bounded number an `MxStepper` in the row's trailing slot, a pick from a few fixed values a sheet of `MxOptionRow`s (`sizeListRow`, `sizeListRowTwoLine` with a description), and a value with its own state a page of its own.

## Do's and Don'ts

### Do:
- **Do** take every value from `design/tokens.json` through the generated theme, and change the look only through that file and the generator.
- **Do** use `primary` for exactly one primary action per decision and `context.accentColor` for accent text and glyphs.
- **Do** keep the contrast test green, with every exception recorded in `design/contrast_exceptions.json`.
- **Do** guarantee a `sizeControl` touch area on every interactive element, and let text containers grow instead of clamping scale or fixing heights.
- **Do** write failure copy in the local-first voice: say first that nothing was lost, then offer the retry.
- **Do** state a number once per screen, in the element that explains it.
- **Do** use the spacing scale and `context.screenMargin` rather than ad-hoc values.

### Don't:
- **Don't** write a hex code, a size or a duration in a widget, a test or a document; name the token.
- **Don't** use a fill as text; use its text role.
- **Don't** branch on brightness in a widget, and don't lay a colour over a ground at an alpha; use `theme_rules.dart` and `tintOver`.
- **Don't** give a card or the search field a border or a shadow.
- **Don't** restyle a text role beyond its colour or the mono face.
- **Don't** declare a removed theme name again in any form (`tools/design/removed_symbols.json`).
- **Don't** put failure copy in a component, or word a load failure as though data was lost.
