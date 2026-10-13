---
name: MemoX V8
description: A quiet, focused study space for spaced-repetition flashcards, in a light and a dark theme from the "Flashcard Color Tokens" spec (ADR-022).
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
  mastery: "#17AE79"
  on-mastery: "#003925"
  success: "#006C49"
  warning: "#F59E0B"
  on-warning: "#613B00"
  status-new: "#6C7794"
  status-learning: "#F59E0B"
  status-reviewing: "#564BCB"
  status-mastered: "#17AE79"
  error-fill: "#BA1A1A"
  on-error-fill: "#FFFFFF"
  streak: "#F59E0B"
  primary-text: "#564BCB"
  mastery-text: "#006C49"
  learning-text: "#855300"
  warning-text: "#855300"
  focus-ring: "#564BCB"
  border: "#BBC6E6"
  primary-track: "#564BCB"
  neutral-track: "#E8E8E8"
  primary-soft: "#E4E2F7"
  on-primary-soft: "#564BCB"
  success-soft: "#D6E7E2"
  success-border: "#006C49"
  on-success-soft: "#006C49"
  learning-soft: "#EBE3D6"
  learning-border: "#855300"
  on-learning-soft: "#855300"
  warning-soft: "#EBE3D6"
  warning-border: "#855300"
  on-warning-soft: "#855300"
  danger-soft: "#F4DADA"
  danger-border: "#BA1A1A"
  on-danger-soft: "#BA1A1A"
  neutral-soft: "#D1DCFD"
  on-neutral-soft: "#55607C"
  on-soft: "#1C1B21"
  card-surface: "#F1F1FB"
  search-surface: "#F1F1FB"
  tile-surface: "#EDF8FF"
  divider: "#EEEEEE"
  info: "#006684"
  info-container: "#50CCFC"
  on-info-container: "#00546D"
typography:
  display-term:
    fontFamily: "BeVietnamPro"
    fontSize: "24px"
    fontWeight: 400
    lineHeight: "32px"
    letterSpacing: "0px"
  term-tile:
    fontFamily: "BeVietnamPro"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: "28px"
    letterSpacing: "0px"
  display-stat:
    fontFamily: "BeVietnamPro"
    fontSize: "28px"
    fontWeight: 500
    lineHeight: "36px"
    letterSpacing: "0px"
    fontFeature: "tnum"
  title-section:
    fontFamily: "BeVietnamPro"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: "28px"
    letterSpacing: "0px"
  title-card:
    fontFamily: "BeVietnamPro"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: "24px"
    letterSpacing: "0.15px"
  title-item:
    fontFamily: "BeVietnamPro"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "20px"
    letterSpacing: "0.1px"
  body-content:
    fontFamily: "BeVietnamPro"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
    letterSpacing: "0px"
  body:
    fontFamily: "BeVietnamPro"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
    letterSpacing: "0.25px"
  body-tile:
    fontFamily: "BeVietnamPro"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "16px"
    letterSpacing: "0px"
  label-button:
    fontFamily: "BeVietnamPro"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
    letterSpacing: "0.1px"
  label-meta:
    fontFamily: "BeVietnamPro"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
    letterSpacing: "0.5px"
  label-nav:
    fontFamily: "BeVietnamPro"
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
  full: "999px"
spacing:
  micro: "4px"
  control: "8px"
  grouped: "12px"
  gutter: "16px"
  gutter-medium: "24px"
  card-compact: "16px"
  card: "24px"
  section: "24px"
  major: "32px"
  page-end: "48px"
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
    textColor: "{colors.primary-text}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-text:
    textColor: "{colors.primary-text}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-destructive:
    backgroundColor: "{colors.error-fill}"
    textColor: "{colors.on-error-fill}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-warning:
    backgroundColor: "{colors.warning}"
    textColor: "{colors.on-warning}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "40px"
    padding: "0 24px"
  button-small:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "32px"
    padding: "0 12px"
  card:
    backgroundColor: "{colors.card-surface}"
    rounded: "{rounded.md}"
    padding: "24px"
  card-hero:
    backgroundColor: "{colors.primary-soft}"
    rounded: "{rounded.md}"
    padding: "24px"
  text-field:
    backgroundColor: "{colors.surface-container-low}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "52px"
    padding: "0 12px"
  search-field:
    backgroundColor: "{colors.search-surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-meta}"
    rounded: "{rounded.full}"
    height: "56px"
  filter-chip:
    backgroundColor: "{colors.neutral-soft}"
    textColor: "{colors.on-neutral-soft}"
    typography: "{typography.label-button}"
    rounded: "{rounded.full}"
    height: "28px"
    padding: "0 8px"
  filter-chip-selected:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
  bottom-nav:
    backgroundColor: "{colors.surface}"
    height: "64px"
  nav-indicator:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
    rounded: "{rounded.full}"
    width: "56px"
    height: "32px"
  nav-rail:
    backgroundColor: "{colors.surface}"
    width: "80px"
  app-bar:
    backgroundColor: "{colors.surface}"
    typography: "{typography.title-section}"
    height: "64px"
  linear-progress:
    backgroundColor: "{colors.surface-container-highest}"
    textColor: "{colors.mastery}"
    rounded: "{rounded.full}"
    height: "4px"
  fab:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.lg}"
    size: "52px"
  dialog:
    backgroundColor: "{colors.card-surface}"
    rounded: "{rounded.xl}"
  snackbar:
    backgroundColor: "{colors.inverse-surface}"
    textColor: "{colors.on-inverse-surface}"
    rounded: "{rounded.md}"
---

# Design System: MemoX V8

## Overview

**Creative North Star: "The Quiet Study Desk"**

MemoX should feel like a quiet, focused study space. The values come from the owner's "Flashcard Color Tokens" spec ([`docs/shared/design/memox-design-tokens.md`](docs/shared/design/memox-design-tokens.md), ADR-022), which outranks this file. One structure ships two themes: a **light** theme, a white page whose cards rise on a pale lavender tone (#F1F1FB), and a **dark** theme, a deep navy page (#0A082D) whose cards rise a step lighter (#222145). The accent indigo (#564BCB) holds in both. Every colour is a literal token per theme; nothing is derived at run time. Component philosophy: **"Calm and exact"**. A control does one job at one size, and its numbers (a 40 button, a 12 card radius, a 16 or 24 margin) do not drift between screens.

- Content is always more prominent than chrome.
- Clear hierarchy and spacing create structure before decoration does.
- Surfaces rise by tone: cards, the search field and navigation carry no border and no shadow.
- Indigo communicates primary actions.
- Green is semantic and reserved for mastery/success states.
- Density should support efficient studying without making screens feel crowded.
- Empty space must feel intentional, not unfinished.
- Visual consistency takes priority over decorative novelty.

**Key Characteristics:**
- One sans family (Be Vietnam Pro, with Noto Sans KR for Korean), twelve roles; interface text is 14, study content keeps its own size, only section titles are bold.
- Tonal surfaces with no resting shadow in either theme; a hairline only inside a card or on a control.
- One radius (12) for every card; pills for buttons, search, progress and the navigation indicator; 28 for dialogs and sheets.
- Phone-first: a 16dp margin and one 599dp column below 600, a navigation rail, a 24dp margin and a 1040dp area from 600; 48dp touch targets everywhere.
- Every text and edge colour is contrast-tested in both themes; the pairs below AA are recorded exceptions of the fixed palette.

## Colors

The spec's Material 3 scheme (46 roles per theme, no seed at run time) plus the extension colours Material has no role for. Frontmatter holds the light values; the dark values live in `.impeccable/design.json` `colorMeta`. Material roles live in `AppColorSchemes`, everything else in `MxSemanticColors`.

### Primary
- **Accent Indigo** (`primary`, #564BCB in both themes): the fill of primary buttons, the FAB, the selected filter chip and the toggle's track when on. White on it in both themes. On the dark page it is 3.01:1, so it is never text there.
- **Primary Text** (`primaryText`): primary as text and glyph: outline and text buttons, links, a reviewing status label. Light #564BCB, dark #C5C0FF (`primaryFixedDim`).
- **Focus Ring** (`focusRing`, `primary` in both themes): the 2dp focus ring of every control, 2dp outside its edge; the code slot taking the next digit, the stepper being edited.
- **Primary Container** (`primary-container`, #564BCB with #D9D4FF): not used as a ground; the hero card is the primary soft ground (owner 2026-10-13).

### Neutral
- **Page** (`surface`): the screen, the app bar, the bottom bar and the rail. Light #FFFFFF, dark #0A082D.
- **Card** (`cardSurface`): every card, a dialog, a bottom sheet, a match tile at rest. Light #F1F1FB, dark #222145. **Search** (`searchSurface`) is the same tone.
- **Surface** (`surface-container-low`, `surface-container`): the field fill, the recessed study face, the secondary button, the segmented tray. Light #F9F9F9 / #F3F3F3, dark #141337 / #18173B.
- **Track** (`surface-container-highest`): the progress track and the toggle's track when off. Light #E8E8E8, dark #2D2C51.
- **On Surface** (`on-surface`) and **On Surface Variant** (`on-surface-variant`): primary and secondary text. Light #1C1B21 and #3B4661, dark #E5E1E9 and #BBC6E6.
- **Border** (`border` = `outline-variant`): the 1px hairline inside a card, of a control and of a disabled field. Light #BBC6E6, dark #3B4661. **Divider** (`divider`): the rule on the page ground, the bottom bar's top edge and the rail's trailing edge. Light #EEEEEE, dark #18173B.
- **Outline** (`outline`): every control edge at rest and the toggle's thumb when off. Light #6C7794, dark #8590AE.
- **Secondary Container** (`secondary-container` with `on-secondary-container`): the navigation indicator pill. Light #D1DCFD / #55607C, dark #3B4661 / #AAB5D4.
- **Inverse Surface** (`inverse-surface`): the snackbar and the tooltip. Light #313036 with #F3EFF7 text and a #C5C0FF action, dark #E5E1E9 with #313036 text and a #564BCB action.

### Semantic
- **Mastery** (`mastery`, #17AE79 with `onMastery` #003925) and **Success** (`success`): progress and a finished session or a right answer. Two roles, never interchangeable; a right answer is success, never mastery. Success is text-safe: light #006C49, dark #5ADDA4. Mastery as text is **Mastery Text** (`masteryText`, the same two values). Every linear progress fill is `mastery`.
- **Status ramp**: `status-new` (`outline`), `status-learning` (#F59E0B), `status-reviewing` (light #564BCB, dark #C5C0FF), `status-mastered` (#17AE79): dots and fills. Status text reads its text token: learning in **Learning Text** (`learningText`, light #855300, dark #FFC174), reviewing in `primaryText`, mastered in `masteryText`. Learning and warning share the spec's one orange family; an icon and a label tell them apart.
- **Warning** (`warning`, #F59E0B, with `on-warning` #613B00): a refusal or a limit where nothing was lost. Warning text and glyphs read **Warning Text** (`warningText`, light #855300, dark #FFC174).
- **Error** (`error`): light #BA1A1A, dark #FFB4AB; on error #FFFFFF / #690005; error container #FFDAD6 / #93000A (light), #93000A / #FFDAD6 (dark). **Destructive Fill** (`error-fill`) is `error` with `on-error`.
- **Info** (`info`, light #006684, dark #A9E3FF) for information on a plain ground; **Info Container** (#50CCFC with #00546D) for an info fill and a deck's glyph on its tile in dark.
- **Tile** (`tileSurface`, light #EDF8FF, dark #2E3953): a deck's 64 icon tile.
- **Streak** (`streak`, the warning container's orange): the Progress flame only.
- **Switch**: `primaryTrack` (`primary`) with an `on-primary` thumb when on, `neutralTrack` (`surface-container-highest`) with an `outline` thumb when off.

### Soft grounds
A soft ground is a colour at 16% over the theme's `surface`, precomputed as a solid hex: light in the light theme, dark in the dark theme. Its content renders in the current theme. A banner and a toned card have no edge; a study tile's selected, right and wrong tones draw a 1dp edge in the tone's border.

| Family | Soft (light / dark) | Border | Text on it |
|---|---|---|---|
| primary | `primarySoft` #E4E2F7 / #28254F | `primary` | `onPrimarySoft` = `primaryText` |
| success / mastery | `successSoft` #D6E7E2 / #172A40 | `successBorder` = `success` | `onSuccessSoft` = `success` |
| learning | `learningSoft` #EBE3D6 / #312638 | `learningBorder` = `learningText` | `onLearningSoft` = `learningText` |
| warning | `warningSoft` #EBE3D6 / #312638 | `warningBorder` = `warningText` | `onWarningSoft` = `warningText` |
| danger | `dangerSoft` #F4DADA / #312441 | `dangerBorder` = `error` | `onDangerSoft` = `error` |
| neutral | `neutralSoft` = `secondary-container` | — | `onNeutralSoft` = `on-secondary-container` |

`onSoft` is `on-surface`: body text on any soft ground.

### Named Rules
**The One Indigo Rule.** Indigo means "act". A primary fill appears once per decision; the rest of the screen is neutral. An action in an `MxInlineBanner` or `MxFloatingNotice`, and the action in an `MxFooterBar`, is primary only when the screen shows no other primary for the same decision; otherwise it is outline or secondary (Sync's refused rows, an open session on Study entry, Study home's sync notice). A lone Close stays primary: one primary per decision holds (critique 2026-09-30 part 1, R8). A screen that asks *which way* fills its first way (Welcome: Google); a screen for one way fills that way's commit and outlines the other (Sign-in: Send code, then Google) (sign-in redesign 2026-10-05, S7).

**The Green Means Progress Rule.** Green is `mastery` or `success` and nothing else; green is never decoration.

**The Text Token Rule.** Text and glyphs read a text token (`on-surface`, `on-surface-variant`, `primaryText`, `masteryText`, `learningText`, `warningText`, `success`, `info`, `error`, an `on…Soft`), never a fill. `primary` on the dark page is a fill only. Focus reads `focusRing`, a control edge `outline`, a hairline inside a card `border`, a rule on the page `divider`. No colour is derived from another at run time.

**The Contrast Floor Rule.** Text holds 4.5:1 and non-text 3:1 where the palette allows. The palette is fixed (spec §2.3, owner 2026-10-13): the pairs below the floor are the exceptions `test/core/theme/token_contrast_test.dart` lists with their measured ratios, and a change that worsens one or adds one turns that test red.

## Typography

**Display, Body and Label Font:** Be Vietnam Pro (400, 500, 600, bundled as `BeVietnamPro`) with Noto Sans KR (`NotoSansKR`, variable) as the fallback for Korean. Weight also moves a variable font's `wght` axis (`AppTypography.withWeight`).

**Character:** One humanist sans built for Vietnamese. Interface text is 14; study content (the term, a meaning) keeps its own size and no tracking. Bold is rare: only section titles are 600; card titles, item names and navigation labels are 500; everything else, a button's label included, is 400.

### Hierarchy
`height` is the line height over the size.
- **display-term** → `displaySmall` (24/32, 400): the word being studied.
- **term-tile** → `headlineSmall` (20/28, 400): a Korean word in a match tile.
- **display-stat** → `displayMedium` (28/36, 500, tabular numerals): a key number that replaces a sentence.
- **title-section** → `titleLarge` (20/28, 600): a section heading, the app bar's screen title.
- **title-card** → `titleMedium` (18/24, 500, 0.15): a card's title, a compact stat's number.
- **title-item** → `titleSmall` (14/20, 500, 0.1): an item or row title.
- **body-content** → `bodyLarge` (16/24, 400): the meaning on a study card.
- **body** → `bodyMedium` (14/20, 400, 0.25): interface copy, list subtitles, notes.
- **body-tile** → `bodySmall` (13/16, 400): a meaning in a match tile or a guess option.
- **label-button** → `labelLarge` (14/20, 400, 0.1): a button's label at both sizes.
- **label-meta** → `labelMedium` (14/20, 400, 0.5): progress text, the search placeholder, a banner, a count.
- **label-nav** → `labelSmall` (12/16, 500, 0.5): a navigation label; the 12 floor.

Every `MxTextStyles` style is exactly one of these roles; only its colour is the component's (spec §3.3).

### Named Rules
**The Twelve Roles Rule.** Screens use the twelve roles above, untouched; a component picks a role and a colour, never a size, weight, height or tracking of its own.

**The Text Grows Rule.** Text scale is never clamped and no fixed height wraps text. Heights are minimums (button 40, app bar 64, field 52, search 56) and grow with wrapped labels and OS text scaling; the settings row stacks its trailing control at large scale. At the spec's line heights a stacked Vietnamese capital (Ẳ, Ổ) rises about 0.12em above its line box, so a line cut by an ellipsis clips that mark (ADR-022).

## Layout

Material 3 window size classes (spec §5):

| Window | Width | Navigation | Content |
|---|---|---|---|
| Compact | < 600 | `MxBottomNav` at the bottom | one column, at most 599, margin 16 (`gutter`) |
| Medium | 600–839 | `MxNavRail` on the leading edge | at most 1040, centred, margin 24 (`gutterMedium`) |
| Expanded | ≥ 840 | `MxNavRail` | as Medium |

A study session keeps one 599 column, centred, at every size (`MxAppShell.isSession`). A screen's side margin is `context.screenMargin`; `gutter` stays the gap between list items. Vertical rhythm: 4 icon-to-label, 8 tight stacks, 12 related rows, 16 between list items, 24 card interior (16 on the overview), 24 between sections, 32 between major groups, 48 between page sections, and a scroll tail (`MxScreenScroll`; under a FAB it also clears the FAB, The Clear Tail Rule) so the last item is never trapped under pinned chrome.

Every screen is a column in `MxAppShell`: top chrome, one scroll body, in-flow footer, with the FAB layered above (never over a footer). System insets (status bar, cutout, gesture bar, keyboard) are supplied by the platform, never hard-coded. The FAB anchors the screen margin inside the column's trailing edge.

Touch targets are 48dp minimum for every interactive control, whatever the painted size: a 32 or 40 button, a 36 icon-button circle, a 28 chip and a 26 toggle track all keep a 48dp hit area (`tapTargetSize: padded`, explicit minimum constraints).

### Named Rules
**The 48 Floor Rule.** Painted size never sets the touch area. Buttons paint at 40 or 32 (spec §4.3); every control keeps a 48x48 hit.

**The Column Rule.** Content never grows wider than 599dp on a compact window or in a session, or 1040dp from 600; wide windows gain empty ground, not longer lines.

**The Short Label Rule.** Two actions side by side (`MxActionPair`, `MxSheetActions`) stay on one row in English and Vietnamese at a 360dp phone and the default text scale. `MxActionPair` keeps their flex shares when each label fits its share, and otherwise splits the row by the labels' widths, so a pair stays side by side whenever both fit the row together. When they do not, shorten the label first: a verb and its object, dropping what the title, the step or the caption already says ("Read and map columns" became "Map columns", "Import 12 cards" became "Import 12"). A dialog's or sheet's confirm whose title already names the object is the verb alone ("Delete this tag?" · "Delete", "Switch account?" · "Switch", owner 2026-10-06, DEV-179). Stack the pair only when no shorter label keeps the meaning, and record that exception and its reason in the screen's detail file (owner 2026-10-05). `MxActionPair` asserts the rule at the default text scale on a window of 360dp or wider; a recorded exception passes `canStack`, as Trash's selection bar does from 100 items and Import's result in English (owner 2026-10-13, at the spec's 24 button padding).

**The Wrap Rule.** A meta line, a breakdown line, a session context line or a hint that already wraps (the study session, Study home, the Library row meta) keeps doing so between whole terms. Large text scales are not a design target (PRODUCT.md, owner 2026-09-30), so no new work goes into wrapping for them; a title keeps one line.

**The Clear Tail Rule.** A list under a FAB ends clear of it (`MxScrollClearance.fab` or `fabAboveNav`); when the FAB hides (selection), the clearance goes with it.

**The Content Gate Rule.** A control that acts on a screen's content (search, filter, select, tag, the FAB that adds a sibling to a list) exists only once that content exists, and is absent, not dimmed, until then; loading and failure count as no content. A control that creates the first content or recovers it (Create, Starter decks, Import, the Trash, Back) stays in every state. Trash › Select, Tags › search, the Library's FAB, search field and Tags follow it (DEV-309); the 0.38 dim is for a control that exists but cannot act right now.

## Elevation & Depth

Tonal. Depth is a step in tone: a card on `cardSurface`, a recessed face on `surface-container-low`. Nothing rests on a shadow in either theme (spec §4.8); shadows are built on the scheme's `shadow` role (#000000, never brand-tinted) and appear only on surfaces that float: dialogs, sheets, the floating notice and the FAB.

### Shadow Vocabulary
- **Whisper** (`shadow-raised`): none, in both themes.
- **Chrome** (`0 -2px 12px` at 5% light, `0 -2px 14px` at 36% dark): bottom sheet, cast upward. The snackbar is flat (SW-REV-007).
- **Overlay** (`0 12px 32px` at 10% light, `0 16px 40px` at 42% dark): dialogs and the floating notice.
- **FAB** (`0 8px 24px` at 12% light, `0 10px 28px` at 50% dark): the floating action.
- **Scrim** (scheme `scrim`, #000000, at 56%): behind every dialog and sheet. The bottom bar is the page surface edged on top by the divider: it floats over nothing, since the body ends where it starts (audit 2026-10-08, DEV-302).

### Named Rules
**The Tone Before Shadow Rule.** A card, the search field and navigation rise by tone alone, with no edge and no shadow, the same in both themes; a shadow is only for a surface that floats above content.

## Shapes

The Material 3 shape scale (spec §4.2): 4 (`xs`) for small details and the checkbox, 8 (`sm`) for a deck's icon tile and a banner, 12 (`md`) for every card, a match tile, an input and the snackbar, 16 (`lg`) for the FAB and a large sheet's edge, 28 (`xl`) for dialogs and sheet top corners, and a pill (999) for buttons, the search field, progress tracks, the navigation pill, chips, badges, toggle tracks and grabbers. Borders are 1px hairlines; the focus ring is 2px with a 2px offset; radio and checkbox controls use a 2px stroke, and a selected radio thickens its ring to 6 without moving.

## Components

Calm and exact. All widgets are `Mx*` in `lib/shared/widgets/`; they hold no copy (callers pass localized strings) and read colour only from the theme.

### Actions
- **MxButton**: tones primary, secondary, outline, text (no fill and no edge, `primaryText`: the quiet action beside a decision's fill), destructive, dangerSoft, warning; two sizes, every one a pill (spec §6): regular (40, 24 pad: a button standing alone, the study action bar, one the width of its card; `study` is this size) and small (32, 12 pad: one in a row with other content; `compact` is this size), plus the chip geometry (28 pill, the neutral chip). A card uses one size. One label style (`labelLarge`, 400) at every size, icon at 16, an optional brand mark (an image at 18 in the icon's place, such as Google's G, never read aloud), optional detail line, `isLoading` swaps the label for a spinner at the same width and is never dimmed, whatever `onPressed` is (SW-REV-003), disabled is 0.38 opacity (`AppOpacity.disabled`, for controls that cannot be used), `semanticLabel` names the button to TalkBack when its painted label does not say it, on its own node with the tap and the state (SW-REV-005), the Material 3 state layers (hover 8%, focus 10%, pressed 10%), a 2px focus ring in `focusRing` 2px outside its edge. Regular labels wrap to two lines; others stay single line. The outline tone's edge is `outline`. The dangerSoft tone is the danger soft ground with its `dangerBorder` and an `onDangerSoft` label.
- **MxIconButton**: 20 glyph in a 36 round ink box with a 48 hit area; its long-press tooltip is the caption on the inverse surface at radius 8, as the snackbar's ground (SW-REV-007). **MxFab**: square 52, r16, icon only, no extended form.
- **MxActionPair** (two footer actions, side by side in their flex shares, or split by their labels' widths when a share is too narrow; stacked only as the last resort of The Short Label Rule; a screen footer's Cancel and its action share the row 1 : 1, as Card editor and Import do, DEV-169) and **MxSheetActions** (dialog and sheet footer; Cancel and the confirm share the row 1 : 1, the confirm being the verb alone, and neither carries an icon, since the tone already tells the weight, owner 2026-10-06, DEV-179; `MxSheetActions.single` is one action across the row, a lone Close, Done or OK, primary unless it dismisses beside choices, SW-REV-008). In a dialog it is inset 16 all round, on the edge the dialog's title and body share (DEV-166); the sheet form stays 8 / 16 / 16 under a border rule.

### Containers
- **MxCard**: raised (`cardSurface`, r12, no edge and no shadow in either theme, spec §6), plus hero (`primarySoft`, owner 2026-10-13), warning, success and danger (their soft grounds) and recessed (`surface-container-low`) tones (one at a time), all flat and edgeless; content renders in the current theme. `isSelected` draws a primary 2px edge, `isFullBleed` runs rows edge to edge, `isCompact` takes the overview's 16 interior. Card interior 24; a rule inside a card reads `border`.
- **MxDialog** (`cardSurface`, r28; widths 340, 320, 300; scale-in; centres in the room the keyboard leaves and scrolls its text when that room is short, SW-REV-002; `isHeld` refuses Back and the scrim while its work runs, as MxBottomSheet's and MxDeckPickerSheet's do, SW-REV-004; `showMxConfirm` asks a yes/no question, true only on the confirm, the tone on the confirm alone, SW-REV-009; title and body 16 in at the sides and 20 down, on the action pair's edge, DEV-166), **MxBottomSheet** (`cardSurface`, top corners 28, chrome shadow, grabber; `title` and `subtitle` draw the head every sheet shares: the compact title 20 in and 4 down, at most two lines, a heading to TalkBack, the subtitle 4 under it in the note role and 12 above the content, SW-REV-008; a head that is not a title and a line keeps `header`), **MxDeckPickerSheet** (with its loading and error sheets, which keep its head; the error sheet adds Retry and a dismiss, SW-REV-008), **MxSection** (overline plus card; its note is an `MxNote.hint`), **MxDividedColumn** (rows with the border hairline between them, none after the last: the one owner of list dividers, DEV-305; a row draws no edge of its own), **MxNote** (one calm info line; `onDismiss` with a required `dismissLabel` adds a close button for a one-time note, stored as dismissed on the device; `MxNote.hint` is the footnote form with no fill and no border, and the one form for a footnote under a card, a section or an empty state (`MxSection.note`, `MxEmptyState.footnote`); the boxed note stands on its own in the flow, never inside another surface, DEV-303), **MxDashedNote** (placeholder for a chart or figure to come), **MxFooterBar** (in-flow commit bar; its caption in `footerCaption` at full strength, 4.5:1 or more, since it can carry a reason such as the offline note; sign-in redesign 2026-10-05; one line at a 360dp phone in English and Vietnamese, so a caption that does not fit is shortened, never wrapped, as `test/l10n/footer_caption_length_test.dart` asserts, owner 2026-10-05), **MxScrollFade** (a 24 fade over the edge of a scroll view while more lies past it: the bottom of a study face, both ends of a horizontal row such as the breadcrumb or a chip row; it takes no taps and says nothing to TalkBack, DEV-306).

### Inputs
- **MxTextField**: one box for every entry: 52 floor, muted fill that lightens on focus, r12, 12 padding, the body role. Variants form (one line), detail (multi-line, grows with its lines on a 12 padding; a card's meaning and details, pasted rows), term (wraps like detail, Enter moves on; a card's term, in the body role like every field, DEV-169), code (six slots, 48 wide at most and 56 tall at least, r12 on the form fill, edged in `outline` (the border hairline when disabled), the slot that takes the next digit in a 2dp `focusRing` edge, every slot in `error` on a wrong code, the next one still 2dp wide; read-only while a code is checked, at full strength; one hidden field under them keeps the numeric keyboard, one-time-code autofill, paste and the TalkBack label; headline role with tabular figures; sign-in redesign 2026-10-05) and study (bare). Every edged variant, and rests on `outline`, a disabled one on the border hairline; the `focusRing` edge on focus, error edge plus **MxFieldMessage** (error or warning) below.
- **MxSearchField** (56 tall, a pill on `searchSurface`, no edge and no shadow at rest, the focus ring's colour on focus; a 24 glyph; value and placeholder in `labelMedium`, the placeholder in `on-surface-variant`), **MxStepper** (bounded integer, press-and-hold repeat; `minDigits` zero-pads the value, as the reminder's "07" : "05", critique 2026-09-30 part 3d-2), **MxToggle** (44x26 track, 20 thumb: `primaryTrack` and an `on-primary` thumb on, `neutralTrack` and an `outline` thumb off), **MxOptionRow** (single-choice radio row; a dimmed row dims only its radio and title, never the description that says why, and the selected row is never dimmed, so a locked current choice reads), **MxSelectionCheckbox**, **MxSegmentedTray**, **MxFilterChip** (28 pill; at rest the neutral chip, `neutralSoft` with `onNeutralSoft` and no edge; selected fills primary with on-primary text), **MxChipTrigger** (ghost chip that opens a menu).

### Navigation
- **MxAppBar** (64, sides on the screen margin; screen density titles in `titleLarge`, content density in `titleMedium`; a search field fills it with 4 above and below; a form's single save lives in its footer, never also in the bar), **MxStudyTopBar** (close, mode badge, thin progress, Indigo in every mode; the session context line under it names deck, kind, stage and round in two lines at most, never the mode again; critique 2026-09-30 part 3c-2), **MxBottomNav** (64, the page surface edged on top by the `divider` hairline, no shadow and no rounding; outlined resting glyph and label in `on-surface-variant`; the selected glyph filled in `on-secondary-container` on a 56x32 `secondary-container` pill, its label in `on-surface`, labels in `labelSmall`; the pill changes over 300ms on the standard easing), **MxNavRail** (80 wide, the page surface edged on its trailing side by the `divider`, the bottom bar's items; from 600dp), **MxBreadcrumb** (on a form it is the only statement of the deck: the path ends in the deck and the operation; a deep path fades its start edge, its hidden ancestors still reachable buttons to TalkBack, DEV-306), **MxAppShell** and **MxScreenScroll** (tail clearance for FAB and nav).

### Feedback and Status
- **MxSnackbar** (inverse surface, one optional action, 4s; 8s when offering Undo), **MxFloatingNotice** (the warning soft ground with the overlay shadow; floats over a screen that does not own the problem, as Study home's sync notice; the screen that owns it shows an `MxInlineBanner` in place), **MxInlineBanner** (warning or danger; its soft ground at r8 with no edge: the glyph and the title read `onWarningSoft` or `onDangerSoft`, and the message stays neutral in the current theme, critique 2026-09-30 tone pass; its actions put the primary last, as Material 3 does, so screen 24's permission banner reads Try again then Open system settings; critique 2026-09-30 part 3a, R5 amends FE-B6; it keeps 16 below itself, which `hasBottomMargin: false` drops when it ends a dialog's content, as in the sign-in confirms, 2026-10-05 L3), **MxEmptyState** (tones primary, neutral, success, warning, danger; each tone's tile is its soft ground with its `on…Soft` glyph), **MxErrorState** (inline load failure with Retry, its title a live region; a gone item is not a failure but an `MxEmptyState` in the neutral tone, owner 2026-10-08; the alert glyph by default, cloud-off only for a network failure), **MxSpinner** (4 sizes, 800ms cycle), **MxSkeleton** family (pulse 0.45 to 0.75 over 1.4s), **MxBadge** (primary, mastery, success, warning, danger, neutral; each on its soft ground with its `on…Soft` label; mastery is learning progress, success a right answer or a finished, fine state; critique 2026-09-30 tone pass), **MxStatusBadge** (new, learning, reviewing, mastered).

### Study-specific
- **MxMasteryDonut** (its label in the band's text token, `MasteryRamp.label`, in `labelSmall`) and the single **MasteryRamp** threshold function: below 34% learning orange, 34 to 66% reviewing indigo, from 67% mastered green, a flat fill on the `surface-container-highest` track, never a gradient; percent never rounds to 0 or 100 falsely. **MxLinearProgress** (spec §6): 4 tall, a pill, the `mastery` fill on the `surface-container-highest` track for a session and a deck alike, never narrower than it is tall; a deck not wholly mastered stops short of full.
- **MxOutcomeTile** (what a reset keeps, in success, or loses, in warning; critique 2026-09-30 tone pass), **MxWorkloadBreakdownLine** ("overdue, today, new" with one colour each), study choice surfaces (idle, selected, right, wrong; an answered option out of play fades to `AppOpacity.muted`, 0.7, and stays readable) and the recessed answer face, whose ground Match's idle meaning tiles share while its terms stay raised (part 3c-2).
- **StudyCtaRow**: two actions share the row at up to 160 each and stack at text scale 1.3; a lone button spans the width of that pair (2 × 160 + 8), so Continue weighs what a pair does. Grades that judge the learner (Forgot, Remembered) share one tone. An action swapped in place under the finger (Show answer to the grades, Show meaning to Forgot · Remembered, Check to Continue) settles for 400 ms, easing in from `AppOpacity.muted`, before it takes a tap (critique 2026-09-30 part 3c-2).
- **SessionFooterHint**: the glyph sits inline before the first line and wraps with the text; every hint is one line at normal size in English and Vietnamese, so the CTA above it stands in one place in every mode with no empty line under it (critique 2026-09-30 part 3c-2).

### Data Display
- **MxSelectableCardRow** (the card that is one item of a list: the raised card, the ink over all of it, the checkbox while selecting, 16 in and 12 down, one TalkBack node with the checked state, a ⋮ outside the ink 4 from the edge; the deck, card and Trash rows are its content, DEV-304), **MxListRow** (48 minimum, grows to two title lines; a trailing badge or the chevron, never both; a disabled row dims its leading, title and chevron, never the subtitle or meta that says why, DEV-230; no edge of its own, the list's `MxDividedColumn` divides, DEV-305), **MxSettingsRow** (a value that only follows another setting reads as plain trailing text at full contrast, not as a dimmed control; a disabled row dims its tile, label and chevron, never the subtitle that says why; a trailing control that draws its own disabled state (`MxButton`, `MxToggle`, `MxStepper`) is not dimmed again (critique 2026-09-30 part 3a); an `isAction` row, which runs an action or opens a dialog, shows no chevron; `iconTone` sets the lead tile's tone, tinted by default (critique 2026-09-30 tone pass); a `message`, such as a field error, runs under the row from the label's start to the row's end, so a trailing control does not squeeze it (owner 2026-10-07)), **MxListSectionHeader**, **MxStatTile** (boxed or inline; a boxed tile fills with the Muted Fill so it stays a box on a plain card, DEV-231; emphasis primary, plain, muted; its value keeps one line and scales down in a narrow column, critique 2026-09-30 part 3c-1), **MxStackedDayBars** (every day at full strength, each series in its fill; the current day is told by its bold label, critique 2026-10-02), **MxTagChip** (22 or 18; the neutral chip, `neutralSoft` with `onNeutralSoft`), the card history timeline (screen 10, a card-feature widget, DEV-170: a 2dp rail on the centre of a leading 24, 14dp dots ringed 2dp in the outcome's colour, hollow marks for a cycle and the beginning; `AppSize.timelineDot`), **MxIconTile** (small, medium, large, and deck: a deck's 64 tile at r8 on `tileSurface` with a 32 glyph in `info` (light) or `info-container` (dark); tones tinted, primary, warning, success, caution, danger, neutral, deck; a seed holds 3:1 on the primary soft ground; an idle glyph takes the neutral tone), **MxActionSheetCommandRow**, **MxRowInk** (shared row ripple and press, pressed in `onSurface` at the 10% state layer; `onLongPress` for a row that selects on a long-press, SW-REV-005, SW-REV-007).
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
- **Do** separate groups with tone first; use the named shadows only for floating surfaces.
- **Do** use 12 for every card and the spacing steps (4, 8, 12, 16, 24, 32, 48) rather than ad-hoc values; a screen's side margin is `context.screenMargin`.
- **Do** keep a 599dp column on a compact window and in a session, a 1040dp centred area from 600dp, and switch to the navigation rail from 600dp.

### Don't:
- **Don't** use a fill colour as text (primary fill, warning fill, success fill, status colour); use its text token.
- **Don't** use violet or green as decoration, or green for anything but progress and success.
- **Don't** tint shadows with the brand colour, and don't add an edge or a shadow to a card, the search field or navigation.
- **Don't** add hover states (Android only) or a global text style for one component.
- **Don't** stack a pair of actions to make room for a long label; shorten the label (The Short Label Rule).
- **Don't** put text below 12px or a fixed height around text.
- **Don't** put failure copy in a component, or word a load failure as though data was lost.
- **Don't** introduce an all-caps overline above headings as decoration; the section label introduces a list or settings group, the eyebrow is the one context line above a title or number, and user data is never upper-cased.
