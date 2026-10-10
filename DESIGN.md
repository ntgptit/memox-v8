---
name: MemoX V8
description: A quiet, focused study space for spaced-repetition flashcards, in two themes, Indigo Day and Indigo Night.
colors:
  primary: "#4255FF"
  on-primary: "#FFFFFF"
  primary-container: "#EDEFFF"
  on-primary-container: "#4255FF"
  secondary: "#586380"
  secondary-container: "#EDEFF4"
  on-secondary-container: "#2E3856"
  tertiary: "#9C63FF"
  tertiary-container: "#FAA6FF"
  on-tertiary-container: "#282E3E"
  error: "#B00020"
  error-container: "#FFE8D8"
  on-error-container: "#B00020"
  surface: "#FFFFFF"
  surface-bright: "#FFFFFF"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#F6F7FB"
  surface-container: "#F6F7FB"
  surface-container-high: "#EDEFF4"
  surface-container-highest: "#D9DDE8"
  on-surface: "#282E3E"
  on-surface-variant: "#586380"
  outline: "#939BB4"
  outline-variant: "#D9DDE8"
  inverse-surface: "#1A1D28"
  on-inverse-surface: "#F6F7FB"
  inverse-primary: "#F6F7FB"
  scrim: "#010110"
  mastery: "#18AE79"
  on-mastery: "#FFFFFF"
  success: "#12815A"
  warning: "#FFCD1F"
  on-warning: "#282E3E"
  error-fill: "#B00020"
  on-error-fill: "#FFFFFF"
  status-new: "#939BB4"
  status-learning: "#FF983A"
  status-reviewing: "#4255FF"
  status-mastered: "#18AE79"
  streak: "#F6406C"
  primary-text: "#4255FF"
  mastery-text: "#12815A"
  learning-text: "#CC4E00"
  warning-text: "#997700"
  focus-ring: "#A8B1FF"
  border: "#EDEFF4"
  primary-track: "#DBDFFF"
  neutral-track: "#939BB4"
  primary-soft: "#EDEFFF"
  on-primary-soft: "#4255FF"
  success-soft: "#E6FCF4"
  success-border: "#98F1D1"
  on-success-soft: "#12815A"
  learning-soft: "#FFF6EF"
  learning-border: "#FFC38C"
  on-learning-soft: "#CC4E00"
  warning-soft: "#FFEDAB"
  warning-border: "#FFDC62"
  on-warning-soft: "#997700"
  danger-soft: "#FFE8D8"
  danger-border: "#FFC38C"
  on-danger-soft: "#B00020"
  neutral-soft: "#EDEFFF"
  on-neutral-soft: "#2E3856"
  on-soft: "#282E3E"
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
    textColor: "{colors.primary-text}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
  button-text:
    textColor: "{colors.primary-text}"
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
    backgroundColor: "{colors.surface-container-lowest}"
    rounded: "{rounded.xl}"
  snackbar:
    backgroundColor: "{colors.inverse-surface}"
    textColor: "{colors.on-inverse-surface}"
    rounded: "{rounded.md}"
---

# Design System: MemoX V8

## Overview

**Creative North Star: "The Quiet Study Desk"**

MemoX should feel like a quiet, focused study space. The system ships two themes from one structure: **Indigo Day**, a white page whose cards are edged in a cool grey hairline, and **Indigo Night**, a deep indigo page (#0A092D) with cards a step lighter (#202040) and inputs and chips a step lighter again (#2E3856). The brand indigo (#4255FF) holds in both. Every colour is a literal token per theme; nothing is derived from another colour. Component philosophy: **"Calm and exact"**. A control does one job at one size, and its numbers (48 tall, 12 radius, 16 gutter) do not drift between screens.

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
- Tonal surfaces plus a 1px border hairline; shadows are whisper-quiet.
- One radius (12) for every in-flow surface; larger radii only for surfaces that float.
- Phone-first, 16dp gutter, single content column, 48dp touch targets everywhere.
- Every text and edge colour is contrast-tested in both themes; the pairs below AA are recorded exceptions of the fixed palette.

## Colors

One saturated brand indigo on a cool grey-blue neutral field, a green that only ever means progress, an orange for learning and a yellow for warning. Every colour is a literal token, one value per theme (spec 2026-10-10): no colour is pulled toward another, laid over a ground at an alpha, or otherwise derived. Frontmatter holds the Indigo Day values; Indigo Night values live in `.impeccable/design.json` `colorMeta`. Material roles live in `AppColorSchemes`, everything else in `MxSemanticColors`.

### Primary
- **Brand Indigo** (`primary`, #4255FF in both themes): the fill of primary buttons, the FAB, the selected filter chip, progress fills and the selected-choice surface. White on it in both themes.
- **Primary Text** (`primaryText`): primary as text and glyph: outline and text buttons, links, the selected destination, a reviewing status label. Day #4255FF, Night #7583FF.
- **Focus Ring** (`focusRing`, #A8B1FF in both themes): the 2dp focus ring of every control, the code slot taking the next digit, the stepper being edited.
- **Primary Container** (`primary-container`): the hero card and the selected nav pill. Day #EDEFFF with #4255FF, Night #14125C with #EDEFFF.

### Neutral
- **Page** (`surface`): the screen, the app bar and the bottom bar. Day #FFFFFF, Night #0A092D.
- **Card** (`surface-container-lowest`): cards, list rows, dialogs and bottom sheets. Day #FFFFFF, Night #202040.
- **Surface** (`surface-container-low`, `surface-container`): the field fill, tracks, the recessed study face, the secondary button, chips, the segmented tray, the stepper. Day #F6F7FB, Night #2E3856.
- **Muted Fill** (`surface-container-high`): skeletons and neutral marks. Day #EDEFF4, Night #282E3E.
- **On Surface** (`on-surface`) and **On Surface Variant** (`on-surface-variant`): primary and secondary text. Day #282E3E and #586380, Night #F6F7FB and #D9DDE8.
- **Border** (`border`): the 1px hairline of cards, sections, dividers, chrome and a disabled field. Day #EDEFF4, Night #282E3E. Every card draws it in both themes, since Day's card and page are both white.
- **Outline** (`outline`): every control edge at rest: fields, the outline button, the code slots, the unselected radio and the unchecked box. Day #939BB4, Night #586380. **Outline Variant** (#D9DDE8 Day, #586380 Night): the dashed note.
- **Inverse Surface** (`inverse-surface`): the snackbar and the tooltip, the inverse of each theme: Day #1A1D28 with #F6F7FB text and action, Night #EDEFF4 with #282E3E text and a #586380 action.

### Semantic
- **Mastery** (`mastery`, #18AE79) and **Success** (`success`): progress and a finished session or a right answer. Two roles, never interchangeable; a right answer is success, never mastery. Success is text-safe: Day #12815A, Night #59E8B5. Mastery as text is **Mastery Text** (`masteryText`, the same two values).
- **Status ramp**: `status-new` (#939BB4 Day, #586380 Night), `status-learning` (#FF983A), `status-reviewing` (indigo), `status-mastered` (#18AE79): dots and fills. Status text reads its text token: new in `on-surface-variant`, learning in **Learning Text** (`learningText`, Day #CC4E00, Night #FF983A), reviewing in `primaryText`, mastered in `masteryText`.
- **Warning** (`warning`, #FFCD1F, with `on-warning` #282E3E): a refusal or a limit where nothing was lost. Warning text and glyphs on a plain ground read **Warning Text** (`warningText`, Day #997700, Night #FFCD1F).
- **Error** (`error`): the text, glyph and edge role, Day #B00020, Night #FC3C60. **Destructive Fill** (`error-fill`, #B00020 in both): the solid destructive button only.
- **Streak** (`streak`, #F6406C): the Progress flame only.
- **Switch**: `primaryTrack` (#DBDFFF) with a primary thumb when on, `neutralTrack` (#939BB4) with a white thumb when off.

### Soft grounds
A soft ground is a light tint with its own edge and text, the same in both themes, so in Indigo Night a toned card, a banner, a badge, an icon tile or a right or wrong study tile is a light box with dark text.

| Family | Soft | Border | Text on it |
|---|---|---|---|
| primary | `primarySoft` #EDEFFF | — | `onPrimarySoft` #4255FF |
| success / mastery | `successSoft` #E6FCF4 | `successBorder` #98F1D1 | `onSuccessSoft` #12815A |
| learning | `learningSoft` #FFF6EF | `learningBorder` #FFC38C | `onLearningSoft` #CC4E00 |
| warning | `warningSoft` #FFEDAB | `warningBorder` #FFDC62 | `onWarningSoft` #997700 |
| danger | `dangerSoft` #FFE8D8 | `dangerBorder` #FFC38C | `onDangerSoft` #B00020 |
| neutral | `neutralSoft` Day #EDEFFF, Night #586380 | — | `onNeutralSoft` Day #2E3856, Night #F6F7FB |

A soft ground that holds a caller's content (MxCard's toned variants, MxInlineBanner, MxFloatingNotice, MxOutcomeTile) is an **MxSoftGround**: it themes its content with Indigo Day, so the text, glyphs and buttons inside read Day's tokens in both themes: body text is Day's `on-surface` (#282E3E, the same value as `onSoft`), a detail line or eyebrow Day's `on-surface-variant` (#586380), and an outline or text button's label Day's `primary-text`. `onSoft` is the text token of a soft ground drawn without MxSoftGround.

### Named Rules
**The One Indigo Rule.** Indigo means "act". A primary fill appears once per decision; the rest of the screen is neutral. An action in an `MxInlineBanner` or `MxFloatingNotice`, and the action in an `MxFooterBar`, is primary only when the screen shows no other primary for the same decision; otherwise it is outline or secondary (Sync's refused rows, an open session on Study entry, Study home's sync notice). A lone Close stays primary: one primary per decision holds (critique 2026-09-30 part 1, R8). A screen that asks *which way* fills its first way (Welcome: Google); a screen for one way fills that way's commit and outlines the other (Sign-in: Send code, then Google) (sign-in redesign 2026-10-05, S7).

**The Green Means Progress Rule.** Green is `mastery` or `success` and nothing else. Violet is never a status; green is never decoration.

**The Text Token Rule.** Text and glyphs read a text token (`on-surface`, `on-surface-variant`, `primaryText`, `masteryText`, `learningText`, `warningText`, `success`, `error`, an `on…Soft`), never a fill. Focus reads `focusRing`, a control edge `outline`, a hairline `border`. No colour is derived from another.

**The Contrast Floor Rule.** Text holds 4.5:1 and non-text 3:1 where the palette allows. The palette is fixed (owner 2026-10-10): the pairs below the floor are the exceptions `test/core/theme/token_contrast_test.dart` lists with their measured floors, and a change that worsens one or adds one turns that test red.

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
- **Field Label** (600, 14px, `on-surface`, sentence case): names an input or a read-only field; "Required" is the optional caption's size in `primaryText`.

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

**The Content Gate Rule.** A control that acts on a screen's content (search, filter, select, tag, the FAB that adds a sibling to a list) exists only once that content exists, and is absent, not dimmed, until then; loading and failure count as no content. A control that creates the first content or recovers it (Create, Starter decks, Import, the Trash, Back) stays in every state. Trash › Select, Tags › search, the Library's FAB, search field and Tags follow it (DEV-309); the 0.38 dim is for a control that exists but cannot act right now.

## Elevation & Depth

Hybrid, tonal first. Depth is conveyed by stepping through the surface ramp and the 1px border hairline; shadows are built on the scheme's `shadow` role (#282E3E, never brand-tinted) and appear only on cards, dialogs, sheets and the FAB. Night has almost no shadow on cards; cards draw the hairline in both themes.

### Shadow Vocabulary
- **Whisper** (`0 1px 2px` at 4%, light only): Card and toggle thumb. Night: none.
- **Chrome** (`0 -2px 12px` at 5% light, `0 -2px 14px` at 36% dark): bottom sheet and bottom chrome, cast upward. The snackbar is flat (SW-REV-007).
- **Overlay** (`0 12px 32px` at 10% light, `0 16px 40px` at 42% dark): dialogs.
- **FAB** (`0 8px 24px` at 12% light, `0 10px 28px` at 50% dark): the floating action.
- **Scrim** (scheme `scrim`, #010110, at 56%): behind every dialog and sheet. The bottom bar is the page surface with the border hairline: it floats over nothing, since the body ends where it starts (audit 2026-10-08, DEV-302).

### Named Rules
**The Hairline Before Shadow Rule.** Group with tone and the 1px border hairline first; reach for a shadow only for a surface that floats above content.

## Shapes

One radius for everything in the flow: 12 (`md`) for cards, buttons, inputs, notes, banners and snackbars. 4 for checkboxes, 8 for compact buttons and the smallest tiles, 16 for the FAB, the bottom bar and the error tile, 20 for surfaces that float (dialogs, sheet top corners, the empty-state tile), and a pill (999) for chips, badges, toggle tracks, grabbers, progress tracks and study action buttons. Borders are 1px hairlines; the focus ring is 2px with a 2px offset; radio and checkbox controls use a 2px stroke, and a selected radio thickens its ring to 6 without moving.

## Components

Calm and exact. All widgets are `Mx*` in `lib/shared/widgets/`; they hold no copy (callers pass localized strings) and read colour only from the theme.

### Actions
- **MxButton**: tones primary, secondary, outline, text (no fill and no edge, `primaryText`: the quiet action beside a decision's fill), destructive, dangerSoft, warning; sizes regular (48, r12, 16 pad), small (36), compact (32, r8, 12 pad), chip (28 pill) and study (48 pill, 36 pad). One label style, icon at 16, an optional brand mark (an image at 18 in the icon's place, such as Google's G, never read aloud), optional detail line, `isLoading` swaps the label for a spinner at the same width and is never dimmed, whatever `onPressed` is (SW-REV-003), disabled is 0.38 opacity (`AppOpacity.disabled`, for controls that cannot be used), `semanticLabel` names the button to TalkBack when its painted label does not say it, on its own node with the tap and the state (SW-REV-005), pressed overlay 12%, 2px focus ring in `focusRing`. Regular labels wrap to two lines; others stay single line. The outline tone's edge is `outline`. The dangerSoft tone is the danger soft ground with `onDangerSoft`.
- **MxIconButton**: 20 glyph in a 36 round ink box with a 48 hit area; its long-press tooltip is the caption on the inverse surface at radius 8, as the snackbar's ground (SW-REV-007). **MxFab**: square 52, r16, icon only, no extended form.
- **MxActionPair** (two footer actions, side by side; stacked only as the last resort of The Short Label Rule; a screen footer's Cancel and its action share the row 1 : 1, as Card editor and Import do, DEV-169) and **MxSheetActions** (dialog and sheet footer; Cancel and the confirm share the row 1 : 1, the confirm being the verb alone, and neither carries an icon, since the tone already tells the weight, owner 2026-10-06, DEV-179; `MxSheetActions.single` is one action across the row, a lone Close, Done or OK, primary unless it dismisses beside choices, SW-REV-008). In a dialog it is inset 16 all round, on the edge the dialog's title and body share (DEV-166); the sheet form stays 8 / 16 / 16 under a border rule.

### Containers
- **MxCard**: raised (the card ground, r12, the border hairline in both themes, the whisper shadow in Day), plus hero (`primary-container`), warning, success, danger (soft grounds, through `MxSoftGround`) and recessed tones (one at a time), `isSelected` primary 2px edge, `isFullBleed` for edge-to-edge rows. Card interior 20.
- **MxDialog** (widths 340, 320, 300; scale-in; centres in the room the keyboard leaves and scrolls its text when that room is short, SW-REV-002; `isHeld` refuses Back and the scrim while its work runs, as MxBottomSheet's and MxDeckPickerSheet's do, SW-REV-004; `showMxConfirm` asks a yes/no question, true only on the confirm, the tone on the confirm alone, SW-REV-009; title and body 16 in at the sides and 20 down, on the action pair's edge, DEV-166), **MxBottomSheet** (top corners 20, chrome shadow, grabber; `title` and `subtitle` draw the head every sheet shares: the compact title 20 in and 4 down, at most two lines, a heading to TalkBack, the subtitle 4 under it in the note role and 12 above the content, SW-REV-008; a head that is not a title and a line keeps `header`), **MxDeckPickerSheet** (with its loading and error sheets, which keep its head; the error sheet adds Retry and a dismiss, SW-REV-008), **MxSection** (overline plus card; its note is an `MxNote.hint`), **MxDividedColumn** (rows with the border hairline between them, none after the last: the one owner of list dividers, DEV-305; a row draws no edge of its own), **MxNote** (one calm info line; `onDismiss` with a required `dismissLabel` adds a close button for a one-time note, stored as dismissed on the device; `MxNote.hint` is the footnote form with no fill and no border, and the one form for a footnote under a card, a section or an empty state (`MxSection.note`, `MxEmptyState.footnote`); the boxed note stands on its own in the flow, never inside another surface, DEV-303), **MxDashedNote** (placeholder for a chart or figure to come), **MxFooterBar** (in-flow commit bar; its caption in `footerCaption` at full strength, 4.5:1 or more, since it can carry a reason such as the offline note; sign-in redesign 2026-10-05; one line at a 360dp phone in English and Vietnamese, so a caption that does not fit is shortened, never wrapped, as `test/l10n/footer_caption_length_test.dart` asserts, owner 2026-10-05), **MxScrollFade** (a 24 fade over the edge of a scroll view while more lies past it: the bottom of a study face, both ends of a horizontal row such as the breadcrumb or a chip row; it takes no taps and says nothing to TalkBack, DEV-306).

### Inputs
- **MxTextField**: one box for every entry: 52 floor, muted fill that lightens on focus, r12, 12 padding, the body role. Variants form (one line), detail (multi-line, grows with its lines on a 12 padding; a card's meaning and details, pasted rows), term (wraps like detail, Enter moves on; a card's term, in the body role like every field, DEV-169), code (six slots, 48 wide at most and 56 tall at least, r12 on the form fill, edged in `outline` (the border hairline when disabled), the slot that takes the next digit in a 2dp `focusRing` edge, every slot in `error` on a wrong code, the next one still 2dp wide; read-only while a code is checked, at full strength; one hidden field under them keeps the numeric keyboard, one-time-code autofill, paste and the TalkBack label; headline role with tabular figures; sign-in redesign 2026-10-05) and study (bare). Every edged variant, and **MxSearchField** (whose edges are the theme's), rests on `outline`, a disabled one on the border hairline; the `focusRing` edge on focus, error edge plus **MxFieldMessage** (error or warning) below.
- **MxSearchField**, **MxStepper** (bounded integer, press-and-hold repeat; `minDigits` zero-pads the value, as the reminder's "07" : "05", critique 2026-09-30 part 3d-2), **MxToggle** (44x26 track, 20 thumb: `primaryTrack` and a primary thumb on, `neutralTrack` and a white thumb off), **MxOptionRow** (single-choice radio row; a dimmed row dims only its radio and title, never the description that says why, and the selected row is never dimmed, so a locked current choice reads), **MxSelectionCheckbox**, **MxSegmentedTray**, **MxFilterChip** (28 pill, selected fills primary with on-primary text), **MxChipTrigger** (ghost chip that opens a menu).

### Navigation
- **MxAppBar** (56, content or screen density; a bar without a leading control starts its title on the gutter, in line with the body, critique 2026-09-30 part 3c-1; a form's single save lives in its footer, never also in the bar), **MxStudyTopBar** (close, mode badge, thin progress, Indigo in every mode; the session context line under it names deck, kind, stage and round in two lines at most, never the mode again; critique 2026-09-30 part 3c-2), **MxBottomNav** (surface bar with the border hairline, outlined resting glyph, filled selected glyph in `primaryText` on a `primary-container` pill), **MxNavRail** (80 wide, from 600dp), **MxBreadcrumb** (on a form it is the only statement of the deck: the path ends in the deck and the operation; a deep path fades its start edge, its hidden ancestors still reachable buttons to TalkBack, DEV-306), **MxAppShell** and **MxScreenScroll** (tail clearance for FAB and nav).

### Feedback and Status
- **MxSnackbar** (inverse surface, one optional action, 4s; 8s when offering Undo), **MxFloatingNotice** (floats over a screen that does not own the problem, as Study home's sync notice; the screen that owns it shows an `MxInlineBanner` in place), **MxInlineBanner** (warning or danger; a soft ground through `MxSoftGround`: the glyph and the bold title read `onWarningSoft` or `onDangerSoft`, and the message stays neutral in Day's text, critique 2026-09-30 tone pass; its actions put the primary last, as Material 3 does, so screen 24's permission banner reads Try again then Open system settings; critique 2026-09-30 part 3a, R5 amends FE-B6; it keeps 16 below itself, which `hasBottomMargin: false` drops when it ends a dialog's content, as in the sign-in confirms, 2026-10-05 L3), **MxEmptyState** (tones primary, neutral, success, warning, danger; each tone's tile is its soft ground with its `on…Soft` glyph), **MxErrorState** (inline load failure with Retry, its title a live region; a gone item is not a failure but an `MxEmptyState` in the neutral tone, owner 2026-10-08; the alert glyph by default, cloud-off only for a network failure), **MxSpinner** (4 sizes, 800ms cycle), **MxSkeleton** family (pulse 0.45 to 0.75 over 1.4s), **MxBadge** (primary, mastery, success, warning, danger, neutral; each on its soft ground with its `on…Soft` label; mastery is learning progress, success a right answer or a finished, fine state; critique 2026-09-30 tone pass), **MxStatusBadge** (new, learning, reviewing, mastered).

### Study-specific
- **MxMasteryDonut** (its label in the band's text token, `MasteryRamp.label`), **MxLinearProgress** and the single **MasteryRamp** threshold function: below 34% learning orange, 34 to 66% reviewing indigo, from 67% mastered green, a flat fill on a `surface-container-low` track, never a gradient; percent never rounds to 0 or 100 falsely.
- **MxOutcomeTile** (what a reset keeps, in success, or loses, in warning; critique 2026-09-30 tone pass), **MxWorkloadBreakdownLine** ("overdue, today, new" with one colour each), study choice surfaces (idle, selected, right, wrong; an answered option out of play fades to `AppOpacity.muted`, 0.7, and stays readable) and the recessed answer face, whose ground Match's idle meaning tiles share while its terms stay raised (part 3c-2).
- **StudyCtaRow**: two actions share the row at up to 160 each and stack at text scale 1.3; a lone button spans the width of that pair (2 × 160 + 8), so Continue weighs what a pair does. Grades that judge the learner (Forgot, Remembered) share one tone. An action swapped in place under the finger (Show answer to the grades, Show meaning to Forgot · Remembered, Check to Continue) settles for 400 ms, easing in from `AppOpacity.muted`, before it takes a tap (critique 2026-09-30 part 3c-2).
- **SessionFooterHint**: the glyph sits inline before the first line and wraps with the text; every hint is one line at normal size in English and Vietnamese, so the CTA above it stands in one place in every mode with no empty line under it (critique 2026-09-30 part 3c-2).

### Data Display
- **MxSelectableCardRow** (the card that is one item of a list: the raised card, the ink over all of it, the checkbox while selecting, 16 in and 12 down, one TalkBack node with the checked state, a ⋮ outside the ink 4 from the edge; the deck, card and Trash rows are its content, DEV-304), **MxListRow** (48 minimum, grows to two title lines; a trailing badge or the chevron, never both; a disabled row dims its leading, title and chevron, never the subtitle or meta that says why, DEV-230; no edge of its own, the list's `MxDividedColumn` divides, DEV-305), **MxSettingsRow** (a value that only follows another setting reads as plain trailing text at full contrast, not as a dimmed control; a disabled row dims its tile, label and chevron, never the subtitle that says why; a trailing control that draws its own disabled state (`MxButton`, `MxToggle`, `MxStepper`) is not dimmed again (critique 2026-09-30 part 3a); an `isAction` row, which runs an action or opens a dialog, shows no chevron; `iconTone` sets the lead tile's tone, tinted by default (critique 2026-09-30 tone pass); a `message`, such as a field error, runs under the row from the label's start to the row's end, so a trailing control does not squeeze it (owner 2026-10-07)), **MxListSectionHeader**, **MxStatTile** (boxed or inline; a boxed tile fills with the Muted Fill so it stays a box on a plain card, DEV-231; emphasis primary, plain, muted; its value keeps one line and scales down in a narrow column, critique 2026-09-30 part 3c-1), **MxStackedDayBars** (every day at full strength, each series in its fill; the current day is told by its bold label, critique 2026-10-02), **MxTagChip** (22 or 18), the card history timeline (screen 10, a card-feature widget, DEV-170: a 2dp rail on the centre of a leading 24, 14dp dots ringed 2dp in the outcome's colour, hollow marks for a cycle and the beginning; `AppSize.timelineDot`), **MxIconTile** (small, medium, large; tones tinted, primary, warning, success, caution, danger, neutral; a seed is a theme-invariant accent that holds 3:1 on the primary soft ground, never a colour of the outer scheme; an idle glyph takes the neutral tone), **MxActionSheetCommandRow**, **MxRowInk** (shared row ripple and press, pressed in `onSurface` at the 12% overlay; `onLongPress` for a row that selects on a long-press, SW-REV-005, SW-REV-007).
- **Settings pattern** (settings hub spec 2026-10-07, §4). The Settings tab is a hub: `MxSection`s of navigation rows (label, the current value first in the subtitle, a chevron) and at most one action row (`isAction`, opens a dialog). No wide control and no toggle on the hub. A group with more than one setting of its own, or with a wide control, is a page under `/settings/<group>`, titled as its hub row, with a content-density app bar and Back; its rows sit in `MxSection`s with one note per section. On a page a setting is: a boolean → an `MxToggle` in the row; a bounded number → an `MxStepper` in the row's trailing slot, with a label short enough to stay on one line beside it and its error in the row's `message` slot (23a); a pick from at most ten fixed values → a bottom sheet of `MxOptionRow`s opened by a value row; a value with its own state, feedback or preview (a time, sync, the account) → a page of its own. Theme and Language predate the rule and keep their pages (FE-A3 D2). A row that opens a page or a sheet always names the current value in its subtitle.

## Do's and Don'ts

### Do:
- **Do** use `primary` for exactly one primary action per decision, `primaryText` for indigo text and glyphs, and `focusRing` for focus.
- **Do** keep the contrast test green: text at 4.5:1 and non-text at 3:1 except the recorded exceptions of the fixed palette.
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
- **Do** separate groups with tone and the 1px border hairline first; use the named shadows only for floating surfaces.
- **Do** use 12 for every in-flow surface and the spacing steps (4, 8, 12, 16, 20, 24, 32, 48) rather than ad-hoc values.
- **Do** centre content at a 720dp maximum column and switch to the navigation rail from 600dp.

### Don't:
- **Don't** use a fill colour as text (primary fill, warning fill, success fill, status colour); use its text token.
- **Don't** use violet or green as decoration, or green for anything but progress and success.
- **Don't** tint shadows with the brand colour, and don't add elevation where a hairline groups the content.
- **Don't** add hover states (Android only) or a global text style for one component.
- **Don't** stack a pair of actions to make room for a long label; shorten the label (The Short Label Rule).
- **Don't** put text below 12px (the 9px donut label is the sole exception, inside a fixed ring) or a fixed height around text.
- **Don't** put failure copy in a component, or word a load failure as though data was lost.
- **Don't** introduce an all-caps overline above headings as decoration; the section label introduces a list or settings group, the eyebrow is the one context line above a title or number, and user data is never upper-cased.
