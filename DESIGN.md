---
name: MemoX V8
description: A quiet, focused study space for spaced-repetition flashcards, in two themes, Tokyo Pure Light and Tokyo Nebula.
colors:
  primary: "#5265F5"
  on-primary: "#FFFFFF"
  primary-container: "#E0E5FE"
  on-primary-container: "#1A2580"
  secondary: "#6E7CD9"
  secondary-container: "#E3E6F7"
  on-secondary-container: "#262E6E"
  tertiary: "#8B6FF5"
  tertiary-container: "#EBE3FE"
  on-tertiary-container: "#33177E"
  error: "#C02447"
  error-container: "#FBDDE3"
  on-error-container: "#7A0A23"
  surface: "#F7F9FE"
  surface-bright: "#FFFFFF"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#F1F4FB"
  surface-container: "#E9EDF7"
  surface-container-high: "#E2E7F3"
  surface-container-highest: "#DAE0EF"
  on-surface: "#0F1638"
  on-surface-variant: "#4A5278"
  outline: "#7C85AB"
  outline-variant: "#C5CBE3"
  inverse-surface: "#34395D"
  on-inverse-surface: "#E8EAFC"
  inverse-primary: "#A0ACFF"
  scrim: "#0A0E27"
  mastery: "#1F8A5B"
  on-mastery: "#FFFFFF"
  success: "#2BA88B"
  warning: "#F59E0B"
  on-warning: "#3A2A00"
  warning-ink: "#895806"
  error-fill: "#DC2D4E"
  on-error-fill: "#FFFFFF"
  status-new: "#8C95B8"
  status-learning: "#F59E0B"
  status-reviewing: "#5265F5"
  status-mastered: "#1F8A5B"
  streak: "#F97316"
typography:
  stat:
    fontFamily: "PlusJakartaSans"
    fontSize: "40px"
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: "-0.64px"
    fontFeature: "tnum"
  display:
    fontFamily: "PlusJakartaSans"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.64px"
  headline:
    fontFamily: "PlusJakartaSans"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.64px"
  title:
    fontFamily: "PlusJakartaSans"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.64px"
  body-large:
    fontFamily: "PlusJakartaSans"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.5
  body:
    fontFamily: "PlusJakartaSans"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  caption:
    fontFamily: "PlusJakartaSans"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.4
  button-label:
    fontFamily: "PlusJakartaSans"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.5
    letterSpacing: "0.1px"
  section-label:
    fontFamily: "PlusJakartaSans"
    fontSize: "13px"
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: "0.6px"
    fontFeature: "tnum"
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  full: "999px"
spacing:
  micro: "4px"
  control: "8px"
  grouped: "12px"
  gutter: "16px"
  card: "20px"
  section: "24px"
  major: "32px"
  page-end: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
  button-secondary:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
  button-outline:
    textColor: "{colors.primary}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
  button-text:
    textColor: "{colors.primary}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
  button-destructive:
    backgroundColor: "{colors.error-fill}"
    textColor: "{colors.on-error-fill}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
  button-warning:
    backgroundColor: "{colors.warning}"
    textColor: "{colors.on-warning}"
    rounded: "{rounded.md}"
    height: "48px"
  button-compact:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.sm}"
    height: "32px"
    padding: "0 12px"
  card:
    backgroundColor: "{colors.surface-container-lowest}"
    rounded: "{rounded.md}"
    padding: "20px"
  text-field:
    backgroundColor: "{colors.surface-container-low}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "52px"
    padding: "0 12px"
  filter-chip:
    backgroundColor: "{colors.surface-container-lowest}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.full}"
    height: "28px"
    padding: "0 8px"
  filter-chip-selected:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
  fab:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.lg}"
    size: "52px"
  dialog:
    backgroundColor: "{colors.surface-container-high}"
    rounded: "{rounded.xl}"
  snackbar:
    backgroundColor: "{colors.inverse-surface}"
    textColor: "{colors.on-inverse-surface}"
    rounded: "{rounded.md}"
---

# Design System: MemoX V8

## Overview

**Creative North Star: "The Quiet Study Desk"**

MemoX should feel like a quiet, focused study space. The system ships two themes from one structure: **Tokyo Pure Light**, a cool blue-tinted white where every neutral carries a trace of indigo, and **Tokyo Nebula**, a deep navy theme authored on its own rather than filtered from light, where the brand indigo holds and the surfaces step up in lightness instead of inverting. Component philosophy: **"Calm and exact"**. A control does one job at one size, and its numbers (48 tall, 12 radius, 16 gutter) do not drift between screens.

- Content is always more prominent than chrome.
- Clear hierarchy and spacing create structure before decoration does.
- Surfaces stay calm and lightweight; elevation and borders are used only when they clarify grouping.
- Indigo communicates primary actions.
- Violet is reserved for meaningful accents.
- Green is semantic and reserved for mastery/success states.
- Density should support efficient studying without making screens feel crowded.
- Empty space must feel intentional, not unfinished.
- Visual consistency takes priority over decorative novelty.

**Key Characteristics:**
- One sans family (Plus Jakarta Sans), seven roles, tight-tracked for headings and figures.
- Tonal surfaces plus a 1px ghost hairline; shadows are neutral and whisper-quiet.
- One radius (12) for every in-flow surface; larger radii only for surfaces that float.
- Phone-first, 16dp gutter, single content column, 48dp touch targets everywhere.
- Every text and edge colour is contrast-tested (AA) in both themes.

## Colors

A cool indigo-tinted neutral field with one saturated brand indigo, one reserved violet, and a green that only ever means progress. Frontmatter holds the Tokyo Pure Light values; Tokyo Nebula values and tonal information live in `.impeccable/design.json` `colorMeta`.

### Primary
- **Brand Indigo** (`primary`): the fill of primary buttons, the FAB, the selected filter chip, progress fills and the selected-choice surface. Identical in both themes (#5265F5). White ink on it in both themes.
- **Indigo Ink** (derived, not a fill): primary as text, icon, focus ring or spinner is `primary` pulled toward `on-surface` (25% in light, 45% in dark) so it reads at 4.5:1 on every ground. Outline buttons, links and the 2dp focus ring use it.
- **Indigo Wash** (`primary-container`, `on-primary-container`): quiet selected and informational grounds. Dark: #2D346A / #D9DFFF.

### Secondary
- **Soft Periwinkle** (`secondary`, `secondary-container`): supporting tonal role; rarely painted directly.

### Tertiary
- **Meaningful Violet** (`tertiary`, `tertiary-container`): the reserved accent. Never used for status and never for mastery.

### Neutral
- **Pure Light Page** (`surface`, #F7F9FE): the screen ground. Dark: #0A0E27 (Nebula Night).
- **Raised White** (`surface-container-lowest`): cards, list rows, chips. Dark: #131A3A.
- **Muted Fill** (`surface-container-low`): text-field fill at rest, the mastery track, navigation rail ground, recessed study face. Dark: #1B2249.
- **Sheet Ground** (`surface-container-high`): dialogs and bottom sheets. Dark: #2C356E.
- **On Surface** (`on-surface`) and **Variant Ink** (`on-surface-variant`): primary and secondary text. Dark: #E4E8FA and #A4ACD0.
- **Outline** (`outline`) and **Outline Variant** (`outline-variant`): control edges and dividers; the everyday hairline is the derived Ghost Border (primary at 14% light, 16% dark). The edge of every control that must hold 3:1 is the derived **Outline Edge** (`outlineEdge`), as light as 3:1 allows: in light, `outline` with its hue and lightness kept and its saturation raised to 30% (≈ #7380B4: 3.65:1 on the page, 3.50 on the field fill, 3.11 on the sheet); in dark, where saturation alone cannot reach 3:1, `outline` pulled 20% toward `on-surface` (≈ #7684BD: 5.25, 4.23, 3.15); 3:1 or more on the warning ground in both (owner 2026-10-06, DEV-179). Fields at rest, the outline button, the code slots, the unselected radio, the unchecked box and the off toggle use it (shared widgets review 2026-10-07, SW-REV-001; DEV-166, replacing R7's light `outline-variant`, which held about 1.5:1). The Ghost Border stays the everyday hairline of cards, sections, dividers and a disabled field.
- **Inverse Surface** (`inverse-surface`, #34395D): the snackbar ground, identical in both themes, with `inverse-primary` (#A0ACFF, 5.21:1) for its action.

### Semantic
- **Mastery Green** (`mastery`, #1F8A5B; dark #6FE0BD) and **Success Teal** (`success`, #2BA88B): progress and a finished session. Two roles, never interchangeable; a right answer is success, never mastery.
- **Status ramp**: `status-new` (#8C95B8), `status-learning` (#F59E0B), `status-reviewing` (indigo), `status-mastered` (green). Dots, fills and tints use the colour itself; status text uses an Ink derived by pulling the colour toward `on-surface`.
- **Warning Amber** (`warning`, `on-warning`, `warning-ink`): a refusal or a limit where nothing was lost. Warning text and glyphs use **Warning Ink** (`warningInk`): #895806 in light (amber's hue at 28% lightness, 4.5:1 or more on every ground and tint, the sheet included), the amber itself in dark. `on-warning` is only the ink on an amber fill (critique 2026-09-30 tone pass, T1).
- **Error** (`error`, #C02447) is the text/icon/edge role; **Danger Ink** (`dangerInk`) is error pulled toward `on-surface` (10% light, 30% dark) for text on the danger ground, such as a banner title, 4.5:1 or more on every surface including a sheet (critique 2026-09-30 tone pass); **Destructive Fill** (`error-fill`, #DC2D4E; dark #B0485C) is the solid destructive button only.
- **Streak Orange** (`streak`): the Progress flame only.
- **Derived tints**: danger/warning/success soft grounds are the role at 8-18% alpha over the surface (danger 8/16, warning 12/18, success 10/18, light/dark), with borders at 22-32%.

### Named Rules
**The One Indigo Rule.** Indigo means "act". A primary fill appears once per decision; the rest of the screen is neutral. An action in an `MxInlineBanner` or `MxFloatingNotice`, and the action in an `MxFooterBar`, is primary only when the screen shows no other primary for the same decision; otherwise it is outline or secondary (Sync's refused rows, an open session on Study entry, Study home's sync notice). A lone Close stays primary: one primary per decision holds (critique 2026-09-30 part 1, R8). A screen that asks *which way* fills its first way (Welcome: Google); a screen for one way fills that way's commit and outlines the other (Sign-in: Send code, then Google) (sign-in redesign 2026-10-05, S7).

**The Green Means Progress Rule.** Green is `mastery` or `success` and nothing else. Violet is never a status; green is never decoration.

**The Ink Is Not The Fill Rule.** Text, icons and focus rings use the derived ink (primary ink, status inks, success ink, warning ink, `error`), never the fill colour, because the fills fail 4.5:1 as text on light surfaces.

**The Contrast Floor Rule.** Text and glyphs hold 4.5:1 and non-text (edges, thumbs, progress fill on its track, grabber) hold 3:1, on page, row, low and sheet grounds, in both themes. Pull the ink, not the ground, to pass.

## Typography

**Display, Body and Label Font:** Plus Jakarta Sans (variable, bundled as `PlusJakartaSans`; weight also moves the variable `wght` axis).

**Character:** One friendly geometric sans throughout. Theme headings and figures are tight-tracked (-0.64px) and heavy; component titles set their own tighter-than-body tracking (-0.3px titles, -0.5px screen titles, -0.1px row titles); running text is relaxed at 1.5 line height.

### Hierarchy
- **Stat** (600, 40px, 1.0, -0.64px, tabular numerals): large metrics.
- **Display** (800, 32px, 1.1, -0.64px): hero figure.
- **Headline** (700, 24px, 1.2, -0.64px): screen headline; the study term and summary title override its size.
- **Title** (700, 20px, 1.2, -0.64px): section and screen titles.
- **Body Large** (500, 16px, 1.5): list titles, emphasised body.
- **Body** (400, 14px, 1.5): default running text.
- **Caption** (600, 12px, 1.4): metadata, counts, chips. 12px is a hard floor; nothing renders smaller than 12 except the 9px donut centre label.
- **Button Label** (600, 14px, 1.5, 0.1px): component override of Body; compact and chip buttons use the small label.
- **Section Label** (700, 13px, 0.6px, tabular, upper-cased by the widget): the overline that introduces a list or settings group, and nothing else.
- **Eyebrow** (600, 12px, 0.8px, tabular, `on-surface-variant`): the context line above a big title or number; the app's own words upper-cased, user data as typed (critique 2026-09-30 part 2).
- **Field Label** (600, 14px, `on-surface`, sentence case): names an input or a read-only field; "Required" is the optional caption's size in primary ink.

Component styles (row title, field term, study term, banner title) override the nearest role inside that component; they never add a global style.

### Named Rules
**The Seven Roles Rule.** Screens use the seven roles above; a new size is a component-level override of the nearest role, never a new global style.

**The Text Grows Rule.** Text scale is never clamped and no fixed height wraps text. Heights are minimums (button 48, app bar 56, field 52) and grow with wrapped labels and OS text scaling; the settings row stacks its trailing control at large scale.

## Layout

Phone-first, single column, 16dp screen gutter (`gutter`). Vertical rhythm: 4 icon-to-label, 8 tight stacks, 12 related rows, 16 between list items, 20 card and sheet interior, 24 between sections, 32 between major groups, and a 24 scroll tail (`MxScreenScroll`; under a FAB it also clears the FAB, The Clear Tail Rule) so the last item is never trapped under pinned chrome.

Every screen is a column in `MxAppShell`: top chrome, one scroll body, in-flow footer, with the FAB layered above (never over a footer). System insets (status bar, cutout, gesture bar, keyboard) are supplied by the platform, never hard-coded.

From a 600dp window width, top-level destinations move from the bottom bar (64dp bar in an 80dp block) to an 80dp navigation rail on the leading edge (`MxNavRail`, same glyphs, pill and label as the bottom bar). The content column is centred at a 720dp maximum; the page ground fills the rest, and the FAB anchors 16dp inside the column's trailing edge, not the window's.

Touch targets are 48dp minimum for every interactive control, whatever the painted size: a 32 compact button, a 36 icon-button circle, a 28 chip and a 26 toggle track all keep a 48dp hit area (`tapTargetSize: padded`, explicit minimum constraints).

### Named Rules
**The 48 Floor Rule.** Painted size never sets the touch area. Paint at the size the design wants, then guarantee 48x48 for the hit.

**The Column Rule.** Content never grows wider than 720dp; wide windows gain empty ground, not longer lines.

**The Short Label Rule.** Two actions side by side (`MxActionPair`, `MxSheetActions`) stay on one row in English and Vietnamese at a 360dp phone and the default text scale. When a label does not fit its share, shorten the label first: a verb and its object, dropping what the title, the step or the caption already says ("Read and map columns" became "Map columns", "Import 12 cards" became "Import 12"). A dialog's or sheet's confirm whose title already names the object is the verb alone ("Delete this tag?" · "Delete", "Switch account?" · "Switch", owner 2026-10-06, DEV-179). Stack the pair only when no shorter label keeps the meaning, and record that exception and its reason in the screen's detail file (owner 2026-10-05). `MxActionPair` asserts the rule at the default text scale on a window of 360dp or wider; a recorded exception passes `canStack`, as Trash's selection bar does from 1,000 items.

**The Wrap Rule.** A meta line, a breakdown line, a session context line or a hint that already wraps (the study session, Study home, the Library row meta) keeps doing so between whole terms. Large text scales are not a design target (PRODUCT.md, owner 2026-09-30), so no new work goes into wrapping for them; a title keeps one line.

**The Clear Tail Rule.** A list under a FAB ends clear of it (`MxScrollClearance.fab` or `fabAboveNav`); when the FAB hides (selection), the clearance goes with it.

## Elevation & Depth

Hybrid, tonal first. Depth is conveyed by stepping through the surface-container ramp and a 1px ghost hairline; shadows are neutral (built on the scheme's `shadow` role, never brand-tinted) and appear only on cards, dialogs, sheets and the FAB. Dark has almost no shadow on cards and draws the hairline instead.

### Shadow Vocabulary
- **Whisper** (`0 1px 2px` at 4%, light only): Card and toggle thumb. Dark: none, ghost border instead.
- **Chrome** (`0 -2px 12px` at 5% light, `0 -2px 14px` at 36% dark): bottom sheet and bottom chrome, cast upward. The snackbar is flat (SW-REV-007).
- **Overlay** (`0 12px 32px` at 10% light, `0 16px 40px` at 42% dark): dialogs.
- **FAB** (`0 8px 24px` at 12% light, `0 10px 28px` at 50% dark): the floating action.
- **Scrim** (scheme `scrim` at 45%): behind every dialog and sheet. The bottom bar is the page surface with the ghost edge: it floats over nothing, since the body ends where it starts (audit 2026-10-08, DEV-302).

### Named Rules
**The Hairline Before Shadow Rule.** Group with tone and a 1px ghost edge first; reach for a shadow only for a surface that floats above content.

## Shapes

One radius for everything in the flow: 12 (`md`) for cards, buttons, inputs, notes, banners and snackbars. 4 for checkboxes, 8 for compact buttons and the smallest tiles, 16 for the FAB, the bottom bar and the error tile, 20 for surfaces that float (dialogs, sheet top corners, the empty-state tile), and a pill (999) for chips, badges, toggle tracks, grabbers, progress tracks and study action buttons. Borders are 1px hairlines; the focus ring is 2px with a 2px offset; radio and checkbox controls use a 2px stroke, and a selected radio thickens its ring to 6 without moving.

## Components

Calm and exact. All widgets are `Mx*` in `lib/shared/widgets/`; they hold no copy (callers pass localized strings) and read colour only from the theme.

### Actions
- **MxButton**: tones primary, secondary, outline, text (no fill and no edge, Indigo Ink: the quiet action beside a decision's fill), destructive, dangerSoft, warning; sizes regular (48, r12, 16 pad), small (36), compact (32, r8, 12 pad), chip (28 pill) and study (48 pill, 36 pad). One label style, icon at 16, an optional brand mark (an image at 18 in the icon's place, such as Google's G, never read aloud), optional detail line, `isLoading` swaps the label for a spinner at the same width and is never dimmed, whatever `onPressed` is (SW-REV-003), disabled is 0.38 opacity (`AppOpacity.disabled`, for controls that cannot be used), `semanticLabel` names the button to TalkBack when its painted label does not say it, on its own node with the tap and the state (SW-REV-005), pressed overlay 12%, 2px focus ring in primary ink. Regular labels wrap to two lines; others stay single line. The outline tone's edge is Outline Edge, 3:1 on the page, the card, the sheet and the warning ground in both themes.
- **MxIconButton**: 20 glyph in a 36 round ink box with a 48 hit area; its long-press tooltip is the caption on the inverse surface at radius 8, as the snackbar's ground (SW-REV-007). **MxFab**: square 52, r16, icon only, no extended form.
- **MxActionPair** (two footer actions, side by side; stacked only as the last resort of The Short Label Rule; a screen footer's Cancel and its action share the row 1 : 1, as Card editor and Import do, DEV-169) and **MxSheetActions** (dialog and sheet footer; Cancel and the confirm share the row 1 : 1, the confirm being the verb alone, and neither carries an icon, since the tone already tells the weight, owner 2026-10-06, DEV-179; `MxSheetActions.single` is one action across the row, a lone Close, Done or OK, primary unless it dismisses beside choices, SW-REV-008). In a dialog it is inset 16 all round, on the edge the dialog's title and body share (DEV-166); the sheet form stays 8 / 16 / 16 under a ghost rule.

### Containers
- **MxCard**: raised (surface-container-lowest, r12, whisper shadow or dark ghost edge), plus hero, warning, success, danger and recessed tones (one at a time), `isSelected` primary 2px edge, `isFullBleed` for edge-to-edge rows. Card interior 20.
- **MxDialog** (widths 340, 320, 300; scale-in; centres in the room the keyboard leaves and scrolls its text when that room is short, SW-REV-002; `isHeld` refuses Back and the scrim while its work runs, as MxBottomSheet's and MxDeckPickerSheet's do, SW-REV-004; `showMxConfirm` asks a yes/no question, true only on the confirm, the tone on the confirm alone, SW-REV-009; title and body 16 in at the sides and 20 down, on the action pair's edge, DEV-166), **MxBottomSheet** (top corners 20, chrome shadow, grabber; `title` and `subtitle` draw the head every sheet shares: the compact title 20 in and 4 down, at most two lines, a heading to TalkBack, the subtitle 4 under it in the note role and 12 above the content, SW-REV-008; a head that is not a title and a line keeps `header`), **MxDeckPickerSheet** (with its loading and error sheets, which keep its head; the error sheet adds Retry and a dismiss, SW-REV-008), **MxSection** (overline plus card; its note is an `MxNote.hint`), **MxNote** (one calm info line; `onDismiss` with a required `dismissLabel` adds a close button for a one-time note, stored as dismissed on the device; `MxNote.hint` is the footnote form with no fill and no border, and the one form for a footnote under a card, a section or an empty state (`MxSection.note`, `MxEmptyState.footnote`); the boxed note stands on its own in the flow, never inside another surface, DEV-303), **MxDashedNote** (placeholder for a chart or figure to come), **MxFooterBar** (in-flow commit bar; its caption in `footerCaption` at full ink, 4.5:1 or more, since it can carry a reason such as the offline note; sign-in redesign 2026-10-05; one line at a 360dp phone in English and Vietnamese, so a caption that does not fit is shortened, never wrapped, as `test/l10n/footer_caption_length_test.dart` asserts, owner 2026-10-05), **MxScrollFade** (a 24 fade over the edge of a scroll view while more lies past it: the bottom of a study face, both ends of a horizontal row such as the breadcrumb or a chip row; it takes no taps and says nothing to TalkBack, DEV-306).

### Inputs
- **MxTextField**: one box for every entry: 52 floor, muted fill that lightens on focus, r12, 12 padding, the body role. Variants form (one line), detail (multi-line, grows with its lines on a 12 padding; a card's meaning and details, pasted rows), term (wraps like detail, Enter moves on; a card's term, in the body role like every field, DEV-169), code (six slots, 48 wide at most and 56 tall at least, r12 on the form fill, edged in Outline Edge (3:1 on the page and the fill; the Ghost Border when disabled), the slot that takes the next digit in a 2dp primary-ink edge, every slot in `error` on a wrong code, the next one still 2dp wide; read-only while a code is checked, at full ink; one hidden field under them keeps the numeric keyboard, one-time-code autofill, paste and the TalkBack label; headline role with tabular figures; sign-in redesign 2026-10-05) and study (bare). Every edged variant, and **MxSearchField** (whose edges are the theme's), rests on Outline Edge (3:1 on the page, the field fill, the card and the sheet, DEV-166), a disabled one on the Ghost Border; primary-ink edge on focus, error edge plus **MxFieldMessage** (error or warning) below.
- **MxSearchField**, **MxStepper** (bounded integer, press-and-hold repeat; `minDigits` zero-pads the value, as the reminder's "07" : "05", critique 2026-09-30 part 3d-2), **MxToggle** (44x26 track, 20 thumb), **MxOptionRow** (single-choice radio row; a dimmed row dims only its radio and title, never the description that says why, and the selected row is never dimmed, so a locked current choice reads), **MxSelectionCheckbox**, **MxSegmentedTray**, **MxFilterChip** (28 pill, selected fills primary with on-primary ink), **MxChipTrigger** (ghost chip that opens a menu).

### Navigation
- **MxAppBar** (56, content or screen density; a bar without a leading control starts its title on the gutter, in line with the body, critique 2026-09-30 part 3c-1; a form's single save lives in its footer, never also in the bar), **MxStudyTopBar** (close, mode badge, thin progress, Indigo in every mode; the session context line under it names deck, kind, stage and round in two lines at most, never the mode again; critique 2026-09-30 part 3c-2), **MxBottomNav** (surface bar with the ghost edge, outlined resting glyph, filled selected glyph, tinted pill), **MxNavRail** (80 wide, from 600dp), **MxBreadcrumb** (on a form it is the only statement of the deck: the path ends in the deck and the operation; a deep path fades its start edge, its hidden ancestors still reachable buttons to TalkBack, DEV-306), **MxAppShell** and **MxScreenScroll** (tail clearance for FAB and nav).

### Feedback and Status
- **MxSnackbar** (inverse surface, one optional action, 4s; 8s when offering Undo), **MxFloatingNotice** (floats over a screen that does not own the problem, as Study home's sync notice; the screen that owns it shows an `MxInlineBanner` in place), **MxInlineBanner** (warning or danger; the glyph reads in warning ink or error and the bold title in warning ink or danger ink, and the message stays neutral, critique 2026-09-30 tone pass; its actions put the primary last, as Material 3 does, so screen 24's permission banner reads Try again then Open system settings; critique 2026-09-30 part 3a, R5 amends FE-B6; it keeps 16 below itself, which `hasBottomMargin: false` drops when it ends a dialog's content, as in the sign-in confirms, 2026-10-05 L3), **MxEmptyState** (tones primary, neutral, success, warning, danger; success tints with success and draws its glyph in success ink, critique 2026-09-30 tone pass; warning draws its glyph in warning ink, part 3d-2), **MxErrorState** (inline load failure with Retry, its title a live region; a gone item is not a failure but an `MxEmptyState` in the neutral tone, owner 2026-10-08; the alert glyph by default, cloud-off only for a network failure), **MxSpinner** (4 sizes, 800ms cycle), **MxSkeleton** family (pulse 0.45 to 0.75 over 1.4s), **MxBadge** (primary, mastery, success, warning, danger, neutral; mastery is learning progress, success a right answer or a finished, fine state, in its success ink; critique 2026-09-30 tone pass), **MxStatusBadge** (new, learning, reviewing, mastered).

### Study-specific
- **MxMasteryDonut** (its label in the band's ink, `MasteryRamp.ink`, SW-REV-001), **MxLinearProgress** and the single **MasteryRamp** threshold function: below 34% learning ink, 34 to 66% reviewing indigo, from 67% mastered green, a flat fill on a `surface-container-low` track, never a gradient; percent never rounds to 0 or 100 falsely.
- **MxOutcomeTile** (what a reset keeps, in success, or loses, in warning; critique 2026-09-30 tone pass), **MxWorkloadBreakdownLine** ("overdue, today, new" with one colour each), study choice surfaces (idle, selected, right, wrong; an answered option out of play fades to `AppOpacity.muted`, 0.7, and stays readable) and the recessed answer face, whose ground Match's idle meaning tiles share while its terms stay raised (part 3c-2).
- **StudyCtaRow**: two actions share the row at up to 160 each and stack at text scale 1.3; a lone button spans the width of that pair (2 × 160 + 8), so Continue weighs what a pair does. Grades that judge the learner (Forgot, Remembered) share one tone. An action swapped in place under the finger (Show answer to the grades, Show meaning to Forgot · Remembered, Check to Continue) settles for 400 ms, easing in from `AppOpacity.muted`, before it takes a tap (critique 2026-09-30 part 3c-2).
- **SessionFooterHint**: the glyph sits inline before the first line and wraps with the text; every hint is one line at normal size in English and Vietnamese, so the CTA above it stands in one place in every mode with no empty line under it (critique 2026-09-30 part 3c-2).

### Data Display
- **MxListRow** (48 minimum, grows to two title lines; a trailing badge or the chevron, never both; a disabled row dims its leading, title and chevron, never the subtitle or meta that says why, DEV-230), **MxSettingsRow** (a value that only follows another setting reads as plain trailing text at full contrast, not as a dimmed control; a disabled row dims its tile, label and chevron, never the subtitle that says why; a trailing control that draws its own disabled state (`MxButton`, `MxToggle`, `MxStepper`) is not dimmed again (critique 2026-09-30 part 3a); an `isAction` row, which runs an action or opens a dialog, shows no chevron; `iconTone` sets the lead tile's tone, tinted by default (critique 2026-09-30 tone pass); a `message`, such as a field error, runs under the row from the label's start to the row's end, so a trailing control does not squeeze it (owner 2026-10-07)), **MxListSectionHeader**, **MxStatTile** (boxed or inline; a boxed tile fills with the Muted Fill so it stays a box on a plain card, DEV-231; emphasis primary, plain, muted; its value keeps one line and scales down in a narrow column, critique 2026-09-30 part 3c-1), **MxStackedDayBars** (every day at full strength, each series in a colour that holds 3:1 on the card, learning in its ink; the current day is told by its bold label, critique 2026-10-02), **MxTagChip** (22 or 18), the card history timeline (screen 10, a card-feature widget, DEV-170: a 2dp rail on the centre of a leading 24, 14dp dots ringed 2dp in the outcome ink, hollow marks for a cycle and the beginning; `AppSize.timelineDot`), **MxIconTile** (small, medium, large; tones tinted, primary, warning, success, caution, danger), **MxActionSheetCommandRow**, **MxRowInk** (shared row ripple and press, pressed in `onSurface` at the 12% overlay; `onLongPress` for a row that selects on a long-press, SW-REV-005, SW-REV-007).
- **Settings pattern** (settings hub spec 2026-10-07, §4). The Settings tab is a hub: `MxSection`s of navigation rows (label, the current value first in the subtitle, a chevron) and at most one action row (`isAction`, opens a dialog). No wide control and no toggle on the hub. A group with more than one setting of its own, or with a wide control, is a page under `/settings/<group>`, titled as its hub row, with a content-density app bar and Back; its rows sit in `MxSection`s with one note per section. On a page a setting is: a boolean → an `MxToggle` in the row; a bounded number → an `MxStepper` in the row's trailing slot, with a label short enough to stay on one line beside it and its error in the row's `message` slot (23a); a pick from at most ten fixed values → a bottom sheet of `MxOptionRow`s opened by a value row; a value with its own state, feedback or preview (a time, sync, the account) → a page of its own. Theme and Language predate the rule and keep their pages (FE-A3 D2). A row that opens a page or a sheet always names the current value in its subtitle.

## Do's and Don'ts

### Do:
- **Do** use `primary` for exactly one primary action per decision and the derived primary ink for any indigo text, icon or focus ring.
- **Do** keep text at 4.5:1 and non-text edges, thumbs and fills at 3:1 on every surface, in both themes; adjust the ink, and keep the contrast test green.
- **Do** guarantee a 48x48dp touch area on every interactive element, and let text containers grow instead of clamping scale or fixing heights.
- **Do** write failure copy in the local-first voice: say first that nothing was lost, then offer the retry. Copy is caller-supplied and localized; components hold no copy.
- **Do** use `mastery` and `success` green only for mastery and success, and route mastery fills through `MasteryRamp`.
- **Do** state a number once per screen (critique 2026-09-30 part 3b). A number lives in the element that explains it: a hero, a tile, a filter chip or the app bar title. A hero figure is not repeated in a list, a legend or a second tile.
  - A button names the action; it carries a count only when that count is what the action acts on and nothing else states that total: "Study this deck · 4 due" (the hero lists the parts), "Import 12", "Review 12 due cards", a bulk action's "({n})".
  - A caption under a button never repeats the button's number.
  - A list header counts only when no hero, title or chip above states the same number.
  - While selecting, the selected count lives in the app bar title only.
  - A row states a status once: a coloured label, not a dot beside it.
  - Kept because a rule asks for them: the card list's filter chip counts (IT-ORG-005), Study entry's NEW and DUE tiles and each mode's count (UC-STUDY-001, BR-STUDY-044), the selected count (UC-CARD-001), Import's preview counts (UC-TRANSFER-001), Progress's two ranges (BR-PROGRESS-003).
- **Do** make a hero card that leads somewhere tappable, with a trailing chevron (the Library's due strip opens Study).
- **Do** separate groups with tone and a 1px ghost hairline first; use the named shadows only for floating surfaces.
- **Do** use 12 for every in-flow surface and the spacing steps (4, 8, 12, 16, 20, 24, 32, 48) rather than ad-hoc values.
- **Do** centre content at a 720dp maximum column and switch to the navigation rail from 600dp.

### Don't:
- **Don't** use a fill colour as text (primary fill, warning fill, success fill, status colour); use its ink.
- **Don't** use violet or green as decoration, or green for anything but progress and success.
- **Don't** tint shadows with the brand colour, and don't add elevation where a hairline groups the content.
- **Don't** add hover states (Android only) or a global text style for one component.
- **Don't** stack a pair of actions to make room for a long label; shorten the label (The Short Label Rule).
- **Don't** put text below 12px (the 9px donut label is the sole exception, inside a fixed ring) or a fixed height around text.
- **Don't** put failure copy in a component, or word a load failure as though data was lost.
- **Don't** introduce an all-caps overline above headings as decoration; the section label introduces a list or settings group, the eyebrow is the one context line above a title or number, and user data is never upper-cased.
