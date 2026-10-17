---
name: MemoX V8
description: A quiet, focused study space for spaced-repetition flashcards, drawn with ForUI in a light and a dark theme from one palette.
colors:
  background: "#FFFFFF"
  foreground: "#0A0A0A"
  primary: "#564BCB"
  primary-foreground: "#FFFFFF"
  secondary: "#F5F5F5"
  secondary-foreground: "#171717"
  muted: "#F5F5F5"
  muted-foreground: "#616161"
  destructive: "#C4000A"
  destructive-foreground: "#FAFAFA"
  error: "#C4000A"
  error-foreground: "#FAFAFA"
  card: "#FFFFFF"
  border: "#E5E5E5"
  barrier: "#00000033"
  success: "#006C49"
  success-fill: "#17AE79"
  on-success-fill: "#003925"
  warning: "#855300"
  warning-fill: "#F59E0B"
  on-warning-fill: "#613B00"
  info: "#006684"
  info-fill: "#50CCFC"
typography:
  figure:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "30px"
    fontWeight: 600
    lineHeight: "39px"
    letterSpacing: "0px"
  term:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 500
    lineHeight: "30.8px"
    letterSpacing: "0px"
  term-compact:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: "28px"
    letterSpacing: "0px"
  screen-title:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: "28px"
    letterSpacing: "0px"
  section-title:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: "27px"
    letterSpacing: "0px"
  item-title:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: "24px"
    letterSpacing: "0px"
  content:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
    letterSpacing: "0px"
  body:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "21px"
    letterSpacing: "0px"
  caption:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "18px"
    letterSpacing: "0px"
  button:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: "24px"
    letterSpacing: "0px"
  label:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "21px"
    letterSpacing: "0px"
  meta:
    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "18px"
    letterSpacing: "0px"
rounded:
  xs2: "4px"
  xs: "6px"
  sm: "8px"
  md: "10px"
  lg: "14px"
  xl: "18px"
  xl2: "22px"
  xl3: "26px"
  pill: "100px"
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
    textColor: "{colors.primary-foreground}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: "48px"
  button-secondary:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.secondary-foreground}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: "48px"
  button-outline:
    backgroundColor: "{colors.background}"
    textColor: "{colors.secondary-foreground}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: "48px"
  button-ghost:
    textColor: "{colors.secondary-foreground}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: "48px"
  button-destructive:
    backgroundColor: "#C4000A1A"
    textColor: "{colors.destructive}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    height: "48px"
  card:
    backgroundColor: "{colors.card}"
    rounded: "{rounded.lg}"
---

# Design System: MemoX V8

## Overview

**Creative North Star: "The Quiet Study Desk"**

MemoX should feel like a quiet, focused study space. The app is drawn with ForUI (ADR-026): one ForUI theme in a light and a dark palette, cards on a neutral page, and one accent that means "act". The values live in Dart: the palette in `lib/core/theme/app_palette.dart` and `mx_status_colors.dart`, the type scale in `app_typography.dart`, the spacing in `app_dimens.dart`, and ForUI's own radii, border width and component styles. The frontmatter above is rendered from the production theme (`test/tools/design_doc_test.dart`); this prose names roles and never restates a value. To change the look, follow `docs/agent/visual-change.md`.

- Content is always more prominent than chrome.
- Hierarchy and spacing create structure before decoration does.
- A surface is a neutral ground with a hairline edge; shadows belong to what floats.
- The accent communicates the primary action.
- Green is semantic and reserved for mastery and success.
- Density supports efficient studying without crowding the screen.
- Empty space is intentional, not unfinished.
- Consistency takes priority over decorative novelty.

**Key Characteristics:**
- One sans family (Be Vietnam Pro, with Noto Sans KR for Korean), twelve text roles on ForUI's type scale.
- Neutral grounds: `background` for the page, `card` for cards, `muted` for recessed grounds, each edge a `border` hairline.
- One accent: `primary` for the primary fill, the selected control and accent text; its two palette values keep it readable in both modes.
- Phone first, `context.screenMargin` at the screen edge, `sizeControl` touch targets everywhere.
- Every text and edge pair of the palette is contrast-tested in both modes, with no exception list.

## Colors

An indigo accent on ForUI's neutral field, a green that only ever means progress, an amber for warning and a blue for information. The frontmatter holds the light values; `.impeccable/design.json` `colorMeta` carries both modes. ForUI's roles are `context.colors` (`FColors`); the status colours are `context.status` (`MxStatusColors`).

### Primary
- **Accent** (`primary`): the primary button, the FAB, the selected tab, chip, radio and checkbox, progress, the focus outline, and accent text and glyphs. Light and dark each have their own value, so the accent reads on both pages without a per-mode rule in a widget.
- **On Accent** (`primaryForeground`): text and glyphs on an accent fill.
- **Accent Tint** (`primary.tintOver(MxTintBase.of(context))`): the hero card and the accent's tinted grounds.

### Neutral
- **Page** (`background`): screens, the app bar, the bottom bar, the rail and sheets.
- **Card** (`card`): cards and the rows that are cards, and dialogs.
- **Recessed** (`muted`): the search field, tracks, skeleton bars, the segmented tray and the recessed study face.
- **Secondary** (`secondary`, `secondaryForeground`): the secondary button, the stepper steps, a pressed or hovered row.
- **Text** (`foreground`, `mutedForeground`): primary and secondary text; resting glyphs are `mutedForeground`.
- **Edges** (`border`): every hairline: card and field edges, dividers, the app bar's edge once content scrolls under it.
- **Scrim** (`barrier`): behind dialogs and bottom sheets.

### Semantic
- **Success** (`status.success`, `status.successFill`, `status.onSuccessFill`): a right answer, a finished session, mastery. The fill is the mastery fill; `success` is its text.
- **Warning** (`status.warning`, `status.warningFill`, `status.onWarningFill`): a refusal or a limit where nothing was lost.
- **Info** (`status.info`, `status.infoFill`): neutral information, the deck glyph.
- **Error** (`error`, `errorForeground`, `destructive`): errors and destructive actions. The destructive button is ForUI's soft destructive tint with a `destructive` label.

### Named Rules
**The One Accent Rule.** The accent means "act". A primary fill appears once per decision; the rest of the screen is neutral.

**The Green Means Progress Rule.** Green is `status.success` or `status.successFill` and nothing else; green is never decoration.

**The Text Colour Rule.** Text and glyphs read a text role (`foreground`, `mutedForeground`, `primary`, a status colour, `error`, a `…Foreground` role), never a fill.

**The Tint Rule.** A tinted ground is a role tinted over the surface directly beneath it, `color.tintOver(MxTintBase.of(context))`. `MxCard`, `MxBottomSheet` and `MxDialog` set the base for what they hold.

**The Mode Rule.** A widget never chooses a colour or a size by brightness. A colour that differs by mode is a palette role the light and the dark palettes already differ on.

**The Contrast Floor Rule.** Text holds 4.5:1 and non-text 3:1. `test/core/theme/token_contrast_test.dart` computes every pair of both palettes; a pair below the floor is a palette change, never an exception.

## Typography

**Font:** Be Vietnam Pro, with Noto Sans KR as the fallback for Korean, both bundled; the mono face for code is `AppTypography.monoFamily`.

**Character:** One friendly, open sans throughout, at the weights the roles declare. Sizes, weights and line heights are the roles' own, on ForUI's type scale; a widget picks a role and changes only its colour, or switches to the mono face.

### Hierarchy
- **Figure** (`texts.figure`, tabular figures): key numbers that replace a sentence.
- **Term** (`texts.term`): the word being studied on a flashcard.
- **Compact term** (`texts.termCompact`): a word inside a match tile, a dialog title.
- **Screen title** (`texts.screenTitle`): screen and section headings, the app bar title.
- **Section title** (`texts.sectionTitle`): card titles and compact stats.
- **Item title** (`texts.itemTitle`): list and settings rows, sheet titles.
- **Content** (`texts.content`): a card's meaning, a study passage, the text typed in a field and its hint.
- **Body** (`texts.body`): default running text, notes, a row's subtitle.
- **Caption** (`texts.caption`): a field's message and counter, a tile's meaning, captions.
- **Button** (`texts.button`): every button label.
- **Label** (`texts.label`): field labels, chips, metadata, the search field.
- **Meta** (`texts.meta`): navigation labels, counts, overlines.

### Named Rules
**The Twelve Roles Rule.** Screens use the twelve roles. `context.texts.<role>` may take `copyWith(color: …)` or `copyWith(fontFamily: AppTypography.monoFamily)` and nothing else; a size the roles cannot express is a Design System change.

**The Text Grows Rule.** Text scale is never clamped and no fixed height wraps text. Heights are minimums and grow with wrapped labels and the OS text scale; the settings row stacks its trailing control at a large scale.

**The One Line Rule.** A label meant for one line fits on one line: shorten the copy, never add an ellipsis to the app's own words. A user's own text (a deck name, a tag) may end in an ellipsis.

## Layout

Phone first. The screen edge is `context.screenMargin` (`marginScreen` on a compact window, `marginScreenMedium` from `breakpointMedium`); the vertical rhythm is the spacing scale (`space4` … `space48`).

Every screen is a column in `MxAppShell`: top chrome, one scroll body, an in-flow footer, the FAB above (never over a footer). System insets are the platform's, never hard-coded.

The window size class (`context.windowSize`) sets the frame; from `breakpointMedium` the rail replaces the bottom bar.

Touch targets are `sizeControl` for every interactive control, whatever its painted size. A ForUI control painted smaller (a chip, a stepper step, a checkbox, a radio) paints inside its target (`mxInsetDecoration`).

### Named Rules
**The Touch Floor Rule.** Painted size never sets the touch area. Paint at the size the design wants, then guarantee a `sizeControl` square for the hit.

**The Column Rule.** Content never grows wider than its column; wide windows gain empty ground, not longer lines.

**The Footer Pair Rule.** Two footer actions (`MxActionPair`) share the row while both labels fit their share on one line; when they do not, they stack.

**The Wrap Rule.** A meta line, a breakdown line, a session context line or a hint that already wraps keeps doing so between whole terms; a title keeps one line.

**The Clear Tail Rule.** A list under a FAB ends clear of it; when the FAB hides (selection), the clearance goes with it.

**The Content Gate Rule.** A control that acts on a screen's content (search, filter, select, tag, the FAB that adds a sibling to a list) exists only once that content exists, and is absent, not dimmed, until then.

## Elevation & Depth

Flat by default. Cards and fields are a ground and a `border` hairline; they cast no shadow. What floats over the scroll (the FAB, the floating notice, toasts) takes ForUI's shadow; dialogs and sheets sit over the `barrier` scrim.

### Named Rules
**The Hairline Before Shadow Rule.** Group with a ground and a hairline first; a surface that does not float never casts a shadow.

## Shapes

ForUI's radius scale (`context.radii`): `md` for buttons, fields and dialogs (ForUI's own), `lg` for cards, `xl2` for the top of a sheet, `pill` for the search field and badges. A full radius on a custom shape is `StadiumBorder`.

## Components

Calm and exact. All widgets are `Mx*` in `lib/shared/widgets/`, built on ForUI; they hold no copy (callers pass localized strings) and read every colour, size and style from the theme. Features use the `Mx*` widgets only; `docs/forui-migration/SHARED_WIDGET_INVENTORY.md` lists each widget with the ForUI component under it.

### Actions
- **MxButton**: ForUI's button. Tones primary, secondary, outline, text (ForUI's ghost), destructive (the soft destructive tint), dangerTint (the error tint with an error edge) and warning (`status.warningFill`); sizes regular and study (ForUI's large size, a `sizeControl` target), small and chip. Loading keeps the resting fill with a spinner over the hidden label.
- **MxIconButton**: an icon at `sizeIcon` in a `sizeControl` box, ForUI's ghost icon button; its tooltip (`MxTooltip`) shows on a long press and shares the button's semantics node. **MxFab**: ForUI's primary icon button at `sizeFab`, with ForUI's shadow.
- **MxActionPair** (a screen footer's pair) and **MxSheetActions** (the pair of a dialog or a sheet; the confirm is the verb alone).

### Containers
- **MxCard**: ForUI's card: `card` ground, `border` hairline, `lg` radius. Tones: hero (the accent tint), warning, success and danger (each its role tinted over the base), recessed (`muted`); a selected card's edge is `primary` at twice the hairline.
- **MxDialog** and **MxBottomSheet**: ForUI's dialog and modal sheet routes over the `barrier` scrim, opened only through `showMxDialog` and `showMxBottomSheet`. A held popup ignores the scrim, the drag and Back until it is released.
- **MxSection** (overline plus card), **MxDividedColumn** (rows with a `border` hairline between them, inset `space16` at each end).

### Inputs
- **MxTextField**: ForUI's text field at the large size: a label row, the field, then the description or error row with its counter. Typing calls `onChanged` once per user edit, as before (`MxUserEdits`).
- **MxSearchField**: ForUI's text field on `muted` with a `pill` radius; a clear button when it holds text.
- **MxStepper** (a bounded integer with press-and-hold repeat; ForUI secondary icon buttons as steps), **MxToggle** (ForUI's switch in a `sizeControl` box), **MxSlider** (ForUI's slider), **MxSelectionCheckbox** and **MxOptionRow** (ForUI's checkbox and radio, painted inside the row's target), **MxSegmentedTray** (ForUI's tab-list look on `muted`), **MxFilterChip** and **MxChipTrigger** (ForUI's chip-size buttons).

### Navigation
- **MxAppBar**: `sizeAppBar`, `texts.screenTitle`, the title a heading that names the route; the icon glyphs sit on `context.screenMargin`, in line with the body. Its ground is the page, with a `border` edge once content scrolls under it.
- **MxBottomNav**: ForUI's bottom navigation bar on `background`; the selected item is `primary`.
- **MxNavRail**: `sizeRail` wide on `background`, the same items and semantics, from `breakpointMedium`.
- **MxStudyTopBar** (its close glyph and its counter sit on `context.screenMargin`; its progress track is `sizeTrack` tall), **MxBreadcrumb**.

### Feedback and Status
- **MxSnackbar** (`showMxSnackbar`): ForUI's toast, one at a time, one optional action; it returns an `MxSnackbarController` (`close()`, `closed`). A toast with an action stays while TalkBack is on.
- **MxBadge**, **MxStatusBadge**, **MxTagChip**: ForUI's badge in a tone (`MxToneBadge`).
- **MxInlineBanner**, **MxFloatingNotice**, **MxNote**, **MxEmptyState**, **MxErrorState**, **MxSkeleton** (`muted` bars, `border` on a `muted` ground), **MxSpinner** (ForUI's `FCircularProgress`, one turn per 0.8 s; it stops only under Android's Remove animations, so an `FAccessibilityScope` keeps it turning there: it is the one sign that work is in flight).

### Study-specific
- **MxMasteryDonut** and **MxLinearProgress** (`MasteryRamp`: `muted` track, status fills), **MxOutcomeTile**, **MxWorkloadBreakdownLine**, the study choice surfaces (idle, selected, right, wrong; an answered option out of play fades to `opacityMuted` and stays readable) and the recessed answer face.

### Data Display
- **MxSelectableCardRow** (a card that is one item of a list: the press layer over all of it, the checkbox while selecting, one TalkBack node with its checked state), **MxListRow** and **MxSettingsRow** (`sizeListRow` for one line, `sizeListRowTwoLine` with a subtitle), **MxRowInk** (ForUI's tappable: the `secondary` press layer and ForUI's focus outline across a row).
- **Settings pattern.** The Settings tab is a hub of `MxSection`s of navigation rows (label, the current value in the subtitle, a chevron) and at most one action row.

## Do's and Don'ts

### Do:
- **Do** take every value from the ForUI theme through `context.colors`, `context.status`, `context.texts`, `context.dimens`, `context.radii`, `context.hairline` and, for the room a focus outline needs, `context.focusOutlineReach`.
- **Do** change the look in `lib/core/theme/` only, then rewrite this frontmatter with `MEMOX_WRITE_DESIGN_DOCS=1` on `test/tools/design_doc_test.dart`.
- **Do** use `primary` for exactly one primary action per decision.
- **Do** keep the contrast test green; a failing pair is a palette change.
- **Do** guarantee a `sizeControl` touch area on every interactive element, and let text containers grow instead of clamping scale or fixing heights.
- **Do** write failure copy in the local-first voice: say first that nothing was lost, then offer the retry.
- **Do** use the spacing scale and `context.screenMargin` rather than ad-hoc values.

### Don't:
- **Don't** write a hex code, a size or a duration in a widget, a test or a document; name the role.
- **Don't** import `package:forui` in a feature or build a ForUI component there; extend an `Mx*` widget.
- **Don't** import Material whole or use a Material component; Material is infrastructure, imported by name (`tools/ui_lint`).
- **Don't** open a dialog, a sheet or a toast except through the `Mx*` adapters.
- **Don't** use a fill as text; use its text role.
- **Don't** branch on brightness in a widget, and don't lay a colour over a ground at an alpha; use the palette and `tintOver`.
- **Don't** restyle a text role beyond its colour or the mono face.
- **Don't** declare a removed theme name again in any form (`tools/design/removed_symbols.json`).
- **Don't** put failure copy in a component, or word a load failure as though data was lost.
