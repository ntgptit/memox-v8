# Colour roles: Material 3 roles only, the derived ink layer removed — design

Status: owner rulings 2026-10-08 (chat), spec awaiting review ·
Path: architectural (one theme layer deleted, one extension reshaped, every colour consumer
remapped, `DESIGN.md` rewritten) ·
Linear: a new epic once this spec is approved; its plan's tasks become the sub-issues.

## 1. Intent

**The problem.** The app paints from three colour sources: the Material 3 `ColorScheme`
(`lib/core/theme/app_color_schemes.dart`), the `MxSemanticColors` extension
(`lib/core/theme/mx_semantic_colors.dart`) and `MxDerivedColors`
(`lib/core/theme/mx_derived_colors.dart`), seventeen colours computed at runtime by
`Color.lerp`, alpha and saturation tricks: the "inks" (`primaryInk`, `warningInk`,
`dangerInk`, `successInk`, four status inks), the "soft" grounds and "borders"
(`dangerSoft`, `dangerBorder`, …), `surfaceHero`, `ghostBorder` and `outlineEdge`. Forty-six
`lib/` files read them; seven more shared widgets and feature files mix their own tints with
`withValues(alpha:)`. Every one of those colours exists because an approved fill
(brand indigo #5265F5, amber #F59E0B, teal #2BA88B, slate #8C95B8) fails 4.5:1 as text or
3:1 as an edge somewhere, and the fix was a derived colour next to the fill instead of a
second role. The result is a vocabulary nobody outside the repo knows, pairs that are
measured in comments rather than in one place, and a `DESIGN.md` whose Colors section is
mostly about the derivations.

**The owner's decision (2026-10-08).** The project paints with Material 3 roles only: the
`ColorScheme` roles and Material 3 custom-colour sets held centrally in `MxSemanticColors`.
No derived layer, no runtime mixing, no per-widget alpha tints standing in for a role.

**What this is not.** It is not a re-theming. The brand indigo stays #5265F5 in both themes
as the one brand fill; the neutral field, the surfaces, the typography and the layout do not
move. It is a change of *which role paints what*, measured, with one new semantic role where
Material 3 has none.

**Success means:** `MxDerivedColors` and every `withValues(alpha:)` tint that grounds a
foreground are gone; every colour a widget paints is a `ColorScheme` role or a
`MxSemanticColors` role; every foreground/ground pair the app paints is listed in §4.8 with
its measured ratio and pinned by `test/core/theme/token_contrast_test.dart`; the state
matrix in §4.9 is covered by widget tests; `DESIGN.md` names the roles and the rules; the
gate passes and the golden review (every changed image, before · after · diff) is approved
by the owner, never auto-accepted.

## 2. Owner rulings (2026-10-08)

- **R1 · Material 3 first, brand preserved.** Only M3 roles exist in the project. Approved
  design decisions stay where still in force; `primary` is the brand indigo #5265F5 in both
  themes and is not moved to tone 40/80.
- **R2 · Three kinds of colour, never confused.** The brand fill, a foreground (text, icon,
  focus ring) and a semantic pair (fill + on-colour, container + on-container) are different
  things. Where `primary` fails as a foreground it is not used as one; a real role takes its
  place and its contrast is measured, not assumed.
- **R3 · Business semantics stay, as M3 custom colours.** Success, warning, mastery, streak
  and the card-status colours remain product semantics, shaped as M3 custom-colour sets
  (`x`, `onX`, `xContainer`, `onXContainer`) and managed in one place.
- **R4 · No mechanical renames.** `surfaceHero`, `ghostBorder`, `outlineEdge`, the `*Soft`
  grounds and `*Border` edges are mapped only after their semantics, states and real
  consumers are known (§4.5, §4.6, §4.8). Nothing is recreated under a new name.
- **R5 · Inventory first, then the mapping.** Every `MxDerivedColors` usage is listed and
  classified by purpose; the old → new mapping is per usage, not per token. No abstraction is
  added to hide a redundant token.
- **R6 · Every state.** Default, selected, focused, pressed, disabled, error, loading, empty,
  success, in light and dark, on the grounds the widget really sits on.
- **R7 · Measured contrast, three floors.** Text 4.5:1; non-text that identifies a control or
  carries meaning (edges, glyphs, focus rings, progress fill on its track) 3:1; a purely
  decorative hairline has no floor. M3 tones are measured, never trusted.
- **R8 · The brand foreground.** `primary` is the brand fill; `onPrimary` reads on it;
  `primaryContainer` / `onPrimaryContainer` are used as a pair; neutral text is `onSurface` /
  `onSurfaceVariant`. `primary` is never text where it is under 4.5:1, and
  `onPrimaryContainer` is never put on `surface` because it happens to be darker. For indigo
  text, icons and focus rings a per-theme foreground is chosen from existing roles first,
  and one minimal semantic role is added only because no existing role fits both the
  semantics and the contrast (§4.4).
- **R9 · Edges.** `outlineVariant` is the decorative hairline and divider; `outline` is the
  edge of a control that must be recognised. Tone 50 is not assumed to pass: `outline` is
  measured on `surface`, the containers and the sheet in both themes, and its value is
  adjusted where it fails (§4.5). `ghostBorder` and `outlineEdge` are not recreated.
- **R10 · After the migration.** CHECK STATE COVERAGE, CHECK DEGRADE and CHECK SIMILAR run
  on the shared widgets, on every consumer and on the goldens; a new golden is never
  accepted without its visual diff being reviewed.
- **R11 · No implementation before approval.** This spec, the mapping, the impact assessment
  and the migration plan come first; code follows the approved plan.

## 3. Root cause analysis

1. **Fills were chosen at tones Material 3 does not use for a role, and foregrounds were
   derived from them.** In M3 a colour role is a tone chosen so that the role and its
   on-colour, and the role on `surface`, pass: tone 40 in light, tone 80 in dark, and the
   same role paints a fill, a text and an icon. MemoX's approved fills sit at HCT tone 49
   (indigo), 72 (amber), 62 (teal) and 62 (slate). Measured as text on the light page they
   give 4.39, 2.04, 2.82 and 2.81:1; in dark the indigo gives 4.11 on the page and 2.46 on
   the sheet. Each failure was answered by a derived colour: the `_ink()` mixes in
   `mx_derived_colors.dart:60-120`, `warningInk` as a literal, `successInk` at 40 %, status
   inks at 25–50 %, `primaryInk` at 25 / 45 %. The fill kept its name; the thing that
   actually reads, the foreground, had no role.
2. **Grounds and edges were tints of a role rather than roles.** `dangerSoft` is `error` at
   8 / 16 % over the card, `warningSoft` 12 / 18 %, `surfaceHero` `primary` at 5 / 18 %,
   `ghostBorder` `primary` at 14 / 16 %; `MxBadge`, `MxIconTile`, `MxStudyTopBar`,
   `MxNavRail`, `MxBottomNav`, `MxActionSheetCommandRow`, `MxOutcomeTile` and the removable
   tag chip each mix their own at 8–20 %. M3 names these grounds (`errorContainer`,
   `primaryContainer`, a custom colour's container) and their on-colours; a tint has no
   on-colour, so each consumer chose its foreground by hand.
3. **One edge token answered two questions.** `outline` light (#7C85AB) is 3.44:1 on the
   page but 2.92 on the sheet; `outline` dark (#5A6BAE) is 3.75 on the page and 2.25 on the
   sheet. Rather than correct the role, DEV-166 derived `outlineEdge` and kept
   `ghostBorder` for everything decorative, so "edge" meant two derived colours and no M3
   role.
4. **The contract was in comments.** Each ratio lives in a code comment or a register row
   (UI-base spec §9 rows 3, 20, 30, 58, 60, 67, 105, 121, 122, 141, 145);
   `token_contrast_test.dart` pins some pairs; nothing lists which role may sit on which
   ground.

The fix at the lowest shared owner: give every foreground, ground and edge a role, measured
in one table, and delete the layer that derived them.

## 4. Design

### 4.1 Architecture: two sources, one rule

- **`ColorScheme`** paints everything Material 3 names: the brand (`primary`,
  `onPrimary`, `primaryContainer`, `onPrimaryContainer`), `secondary`, `tertiary`, `error`
  and its container, every surface, `onSurface`, `onSurfaceVariant`, `outline`,
  `outlineVariant`, the inverse roles.
- **`MxSemanticColors`** (ThemeExtension, literal values per theme, no computation) holds
  the M3 custom-colour sets the product needs and Material has no role for: `warning`,
  `success`, `mastery`, `streak`, and the one brand foreground `primaryForeground` (§4.4).
  Each set declares the members a consumer paints; an unconsumed member is not declared.
- **`MxDerivedColors`** is deleted, with `ThemeContext.derivedColors`, the static
  `primaryInkOf` / `outlineEdgeOf`, and `test/core/theme/mx_derived_colors_test.dart`.
  `AppDecorations`, `MasteryRamp`, `MxTextStyles` and `AppComponentThemes` take the scheme
  and the semantic extension, never a derived set.
- **One rule, The Role Pair Rule** (replaces The Ink Is Not The Fill Rule and absorbs The
  Contrast Floor Rule in `DESIGN.md`): a colour is painted only as a role, on a ground that
  is a role, and the pair is in the measured table (§4.8). A fill role (`primary`,
  `warning`, `error`, …) is text only where the table says 4.5:1 holds; a container's text
  is its on-container; a foreground is never mixed from a fill. No `Color.lerp`, no
  `withValues(alpha:)` to make a ground or a foreground; alpha stays for M3 state layers
  (pressed / hover overlays over `onSurface`, `AppOpacity`) and for the 0.38 disabled dim.

### 4.2 `ColorScheme`: values

Unchanged, except `outline`, which must hold 3:1 as a control edge on every ground a control
sits on (R9). Measured (ratio against surface · lowest · low · container · high):

| Role | Today | Measured | New | Measured |
|---|---|---|---|---|
| `outline` light | #7C85AB | 3.44 · 3.62 · 3.29 · 3.09 · **2.92** | **#7580A6** | 3.70 · 3.89 · 3.54 · 3.32 · 3.14 |
| `outline` dark | #5A6BAE | 3.75 · 3.36 · 3.02 · **2.65** · **2.25** | **#7A89C6** | 5.63 · 5.03 · 4.54 · 3.98 · 3.38 |

The new values are the lightest that pass on `surfaceContainerHigh` (the sheet) with a
margin. They also hold on `primaryContainer` (3.12 light, 3.44 dark), and in light on
`warningContainer` (3.02) and `errorContainer` (3.07). In dark `outline` is 2.77 on
`warningContainer` and 2.98 on `errorContainer`: a control is never placed on a semantic
container (a warning card carries text and an action, not a field), and the table says so.
`surfaceContainerHighest` is the off-toggle track only, never a ground under an edge.
Direct consumers of `outline` today: the breadcrumb chevron (decorative) and the card
history rail (decorative); both darken a little and nothing else moves.

`primary` stays #5265F5 (R1). As a non-text identifier it holds 3:1 on `surface`,
`surfaceContainerLowest` and `surfaceContainerLow` in both themes (light 4.39 · 4.63 · 4.20,
dark 4.11 · 3.67 · 3.31) and on `surfaceContainer` / `High` in light only (3.95 · 3.74;
dark 2.90 · 2.46). So `primary` is a fill, a progress fill on the `surfaceContainerLow` track
(4.20 light, 3.31 dark), the dot of `MxDotOverline`, the status dot of a reviewing card, and
nothing that must be recognised on a sheet. It is never text (4.39 light, 4.11 dark on the
page).

`inversePrimary` (#A0ACFF on the invariant `inverseSurface`, 5.21:1) is the snackbar action
and is out of scope.

### 4.3 `MxSemanticColors`: the custom-colour sets

Values are HCT tones of the current hues (`material_color_utilities`, the same palette M3
seeds from), tone 40 / 100 / 90 / 10 in light and 80 / 20 / 30 / 90 in dark, each pair
measured. Ratios are against surface · lowest · low · container · high unless named.

| Role | Light | Measured | Dark | Measured |
|---|---|---|---|---|
| `primaryForeground` | #384CDD (indigo tone 40) | 6.14 · 6.47 · 5.88 · 5.52 · 5.22; on `primaryContainer` 5.18; on `warningContainer` 5.02 | #BCC2FF (tone 80) | 11.13 · 9.95 · 8.97 · 7.86 · 6.68; on `primaryContainer` 6.79; on `warningContainer` 5.48 |
| `warning` | #855300 (amber tone 40) | 6.16 · 6.49 · 5.90 · 5.54 · 5.24; on `warningContainer` 5.04; vs low track 5.90 | #FFB95F (tone 80) | 11.18 · 9.99 · 9.01 · 7.90 · 6.71; on `warningContainer` 5.51; vs low track 9.01 |
| `onWarning` | #FFFFFF | 6.49 on `warning` | #472A00 (tone 20) | 7.73 on `warning` |
| `warningContainer` | #FFDDB8 (tone 90) | ground | #653E00 (tone 30) | ground |
| `onWarningContainer` | #2A1700 (tone 10) | 13.34 on its container | #FFDDB8 (tone 90) | 7.26 on its container |
| `success` | #006B57 (teal tone 40) | 6.15 · 6.48 · 5.89 · 5.53 · 5.23; on `successContainer` 5.02 | #67DABB (tone 80) | 11.15 · 9.97 · 8.98 · 7.88 · 6.69; on `successContainer` 5.47 |
| `onSuccess` | #FFFFFF | 6.48 on `success` | #00382C (tone 20) | 7.69 on `success` |
| `successContainer` | #85F7D6 (tone 90) | ground | #005141 (tone 30) | ground |
| `onSuccessContainer` | #002019 (tone 10) | 13.33 on its container | #85F7D6 (tone 90) | 7.22 on its container |
| `mastery` | #006D44 (green tone 40) | 6.09 · 6.42 · 5.83 · 5.48 · 5.18; on `masteryContainer` 4.98; vs low track 5.83 | #77DAA4 (tone 80) | 11.18 · 9.99 · 9.00 · 7.89 · 6.71; vs low track 9.00 |
| `onMastery` | #FFFFFF | 6.42 on `mastery` | #003921 (tone 20) | 7.68 on `mastery` |
| `masteryContainer` | #93F7BE (tone 90) | ground | #005232 (tone 30) | ground |
| `onMasteryContainer` | #002111 (tone 10) | 13.29 on its container | #93F7BE (tone 90) | 7.23 on its container |
| `streak` | #9D4300 (orange tone 40) | 6.16 · 6.49 · 5.89 · 5.54 · 5.24 | #FFB690 (tone 80) | 11.17 · 9.98 · 9.00 · 7.89 · 6.70 |

Deleted from the extension: `statusNew`, `statusLearning`, `statusReviewing`,
`statusMastered` (§4.7 resolves a status to the roles above), `errorFill` and `onErrorFill`
(the destructive button is `error` / `onError`: white on #C02447 5.86 light; #52061B on
#FF8FA3 6.93 dark; `error` on the page 5.56 light, 8.79 dark).

What changes to the eye: in light, amber, teal and green darken to their tone-40 values
wherever they are painted (the warning button is dark amber with white text instead of
amber with brown text; the success and mastery fills are deeper). In dark the sets are
within a few points of today's values (#FFC658 → #FFB95F, #6FE0BD → #67DABB / #77DAA4).
Mastery and success stay two roles (The Green Means Progress Rule): hue 161 against 176,
distinct in both themes.

### 4.4 The brand foreground: `primaryForeground`

Indigo text, icons, focus rings and selected marks need a role that reads on every neutral
ground in both themes. Existing roles, measured as a foreground on surface … high:

| Candidate | Light | Dark | Verdict |
|---|---|---|---|
| `primary` #5265F5 | 4.39 … 3.74 | 4.11 … 2.46 | fails as text in both; fails 3:1 on dark sheets |
| `onPrimaryContainer` | #1A2580, 12.30 … 10.47 | #D9DFFF, 14.43 … 8.66 | passes, but it is the on-colour of `primaryContainer`; on `surface` it is a misuse (R8) and in light it reads navy, not indigo |
| `inversePrimary` | fails in light | 8.90 … 5.34 | the snackbar's role on `inverseSurface`; a misuse on `surface` |
| `secondary` | 3.59 … 3.06 | 8.33 … 5.00 | fails in light; and it is not the brand |
| `primaryFixedDim` / `onPrimaryFixedVariant` | tone 80 / tone 30 | same | defined for use on the fixed containers, not on `surface` |

No existing role fits both the semantics and the contrast, so one semantic role is added
(R8): `primaryForeground`, the brand hue at tone 40 in light and tone 80 in dark, the tones
M3 itself would give `primary`. Flutter's own vocabulary names text-and-icon colour
`foregroundColor`, hence the name; "ink" is retired with the layer. Where it is painted:

- text on a neutral ground: outline and text buttons, the selected tab label,
  `disclosureLabel`, `rowTitleMatch`, `MxStatTile`'s emphasised value, the reviewing term of
  `MxWorkloadBreakdownLine`, the reviewing caption of the Progress deck row, the Monitoring
  code frame, the action sheet command label (text on `primaryContainer`, such as the Study
  top bar badge or a tonal primary badge, is `onPrimaryContainer`, the pair of R8);
- icons: the selected rail / bottom-nav icon (on `primaryContainer`), the focused search
  icon, `MxIconTile` tinted glyph (on `primaryContainer`), the add-details and removable-tag
  glyphs, the theme-choice check, `MxEmptyState`'s primary-tone illustration, the off-fill
  spinner;
- rings and marks: every focus ring (`MxRowInk`, buttons, chips, the stepper, the toggle,
  the code field's next slot, the focused field edge), the selected radio ring, the selected
  card edge (`MxCard.isSelected`, 2 dp), the stepper's edge.

`primary` keeps the fills: primary buttons, the FAB, the selected chip, the checked box,
the on toggle, progress fills, the selected study choice.

### 4.5 Edges and hairlines

| Today | Purpose | New | Why |
|---|---|---|---|
| `ghostBorder` | decorative hairline: dark raised card and recessed card edge, section and list dividers (`MxDividedColumn`), the bottom nav, sheet actions and footer bar top edges, `MxNote`, the Study browse hairline, the import step track, the ghost button edge, a disabled field and a disabled code slot | `outlineVariant` (#C5CBE3 light 1.53:1, #2A3267 dark 1.58:1) | the M3 divider and decorative edge; no floor applies (R7, SC 1.4.11 exempts the disabled control) |
| `outlineEdge` | the edge that identifies a control: a field at rest, the outline button, the unchecked box, the unselected radio ring, the off toggle, the code slots, the add-details tile | `outline` (§4.2 values) | the M3 control edge; 3:1 on every ground a control sits on, in both themes |
| `ghostBorder` on `MxFilterChip` / `MxChipTrigger` unselected | the chip's only boundary | `outline` | M3's unselected filter chip edge; a chip is a control |
| focused field, focus rings (`primaryInkOf`) | focus indicator, 3:1 | `primaryForeground` | 5.22 / 6.68 on the sheet, the worst ground |
| error edge (`error`) | error indicator | `error` | unchanged: 5.56 … 4.73 light, 8.79 … 5.27 dark |
| `dangerBorder`, `warningBorder`, `successBorder` | the edge of a tinted card or tile | none | an M3 container has no edge; the ground and its on-colour identify it (§4.6). The dark raised-card hairline does not apply to a container |

### 4.6 Tonal grounds: containers, not tints

Every tinted ground becomes the role's container, with its on-container as text and the
role as glyph. Measured text on container · glyph on container, light / dark:

| Today | Consumers | New ground | Text | Glyph |
|---|---|---|---|---|
| `surfaceHero` (`MxCard.isHero`) | deck summary, deck due strip, card deck summary, gallery | `primaryContainer` | `onPrimaryContainer` 10.37 / 8.81; supporting text may be `onSurfaceVariant` 6.07 / 5.19 | `primaryForeground` 5.18 / 6.79 |
| `dangerSoft` (+ `dangerBorder`) | danger card, inline banner danger, `MxErrorState` tile, action sheet destructive tile, `MxIconTile.danger`, `MxButtonTone.dangerSoft` | `errorContainer` | `onErrorContainer` 8.73 / 7.78 | `error` 4.62 / 4.65 |
| `warningSoft` (+ `warningBorder`) | warning card, `MxDialog` warning, floating notice, inline banner warning, `MxIconTile.caution`, outcome tile lost, lock strip, tag rename note, sync keep dialog | `warningContainer` | `onWarningContainer` 13.34 / 7.26 | `warning` 5.04 / 5.51 |
| `successSoft` (+ `successBorder`), `success` at 8 % | success card, session summary hero, outcome tile kept, `MxIconTile.success` | `successContainer` | `onSuccessContainer` 13.33 / 7.22 | `success` 5.02 / 5.47 |
| `primary` at 8–16 % | `MxIconTile` tinted, action sheet command tile, Study top bar badge, removable tag chip, `MxBadge.primary` tonal | `primaryContainer` | `onPrimaryContainer` / `primaryForeground` as above | `primaryForeground` |
| `primary` at 14 / 20 % | the nav rail and bottom nav selected pill | `primaryContainer` | `onPrimaryContainer` icon and label 10.37 / 8.81 | — |
| `mastery` / `warning` / `success` at 12 % | `MxBadge` tonal tones | the role's container | its on-container | the role |
| study choice right / wrong | `AppDecorations.studyChoice` | `successContainer` / `errorContainer`, no edge | `onSuccessContainer` / `onErrorContainer` | — |
| study choice idle | same | raised or recessed ground, `outlineVariant` edge | `onSurface` | — |

On the dark hero the primary button's fill is 2.51:1 against `primaryContainer`; a filled
button is identified by its label (`onPrimary` 4.63), so no floor applies and the hero keeps
its filled action (The One Indigo Rule). The hero's supporting text in `onSurfaceVariant`
(6.07 / 5.19) is the one exception to "a container's text is its on-container"; every other
container reads in its on-container only, because `onSurfaceVariant` is 4.19 on the dark
`warningContainer` and 4.17 on the dark `successContainer`.

The alpha constants that mixed these grounds (`_tint`, `_tileTint`, `_badgeTint`,
`_pillTint*`, `_primaryTint*`, `_seedTint`, `_keptTint`) are deleted. `MxIconTile.seed`
(one gallery call) becomes a tone.

### 4.7 Card status and the mastery ramp

The four status tokens are replaced by one resolver next to `MxCardStatus`
(`lib/shared/widgets/mx_status_badge.dart`), used by the status badge, the card row, the
workload line and the Progress rows; `MasteryRamp` keeps its thresholds and paints the same
roles by band:

| Status / band | Fill (dot, bar, donut) | Foreground on a neutral ground (text, percentage) | Tonal ground, and its label |
|---|---|---|---|
| new | `outline` | `onSurfaceVariant` (7.20 / 8.50 on the page; 6.12 / 5.10 on the sheet) | `surfaceContainerHigh`, label `onSurfaceVariant` (6.12 / 5.10) |
| learning (< 34 %) | `warning` (vs low track 5.90 / 9.01) | `warning` | `warningContainer`, label `onWarningContainer` (13.34 / 7.26) |
| reviewing (34–66 %) | `primary` (4.20 / 3.31 on the track) | `primaryForeground` | `primaryContainer`, label `onPrimaryContainer` (10.37 / 8.81) |
| mastered (≥ 67 %) | `mastery` (5.83 / 9.00) | `mastery` | `masteryContainer`, label `onMasteryContainer` (13.29 / 7.23) |

The pill of `MxStatusBadge` is the tonal ground with its label; the dot keeps the fill.

`CardDisplayStatus` (feature `card`) maps onto `MxCardStatus` before painting, so the card
row stops carrying its own switch.

### 4.8 Old → new, per usage

Classification: **T** text 4.5:1 · **G** glyph or mark that carries meaning 3:1 · **E**
control edge 3:1 · **D** decorative, no floor · **F** fill with its own on-colour. Ratios are
light / dark on the worst ground the consumer uses.

| Old | Consumer (file) | Class | New | Measured |
|---|---|---|---|---|
| `primaryInk` | `mx_button` outline/text ink, `app_component_themes` outlined/text buttons | T | `primaryForeground` | 5.22 / 6.68 (sheet) |
| `primaryInk` | `app_component_themes` focusedBorder, focusColor, icon-button focus ring; `mx_row_ink`, `mx_chip_trigger`, `mx_filter_chip`, `mx_toggle`, `mx_stepper`, `mx_button` focus | G | `primaryForeground` | 5.22 / 6.68 |
| `primaryInk` | `mx_text_styles` `_primaryInk` (selected tab, `disclosureLabel`, `rowTitleMatch`) | T | `primaryForeground` | 5.88 / 8.97 (low) |
| `primaryInk` | `mx_nav_rail`, `mx_bottom_nav` selected icon on the pill | G | `onPrimaryContainer` on `primaryContainer` | 10.37 / 8.81 |
| `primaryInk` | `mx_study_top_bar` badge text on the primary tint; `mx_badge` primary tonal label | T | `onPrimaryContainer` on `primaryContainer` | 10.37 / 8.81 |
| `primaryInk` | `mx_spinner` off-fill, `mx_search_field` focused icon, `mx_stat_tile` emphasis, `mx_action_sheet_command_row` label and tile glyph, `mx_icon_tile` tinted glyph, `mx_code_field` next slot, `mx_workload_breakdown_line` reviewing, `monitoring_code_card`, `progress_deck_row` reviewing caption, `card_add_details` glyph, `card_removable_tag_chip` glyph, `theme_choice_card` check, `mx_empty_state` primary tone | T/G | `primaryForeground` | ≥ 5.18 / ≥ 6.68 |
| `primaryInk` | `mx_option_row` selected radio ring | G | `primaryForeground` | 5.22 / 6.68 |
| `outlineEdge` | `app_component_themes` enabledBorder; `mx_button` outline edge; `mx_option_row` unselected ring; `mx_selection_checkbox` unchecked; `mx_toggle` off edge; `mx_code_field` slot; `card_add_details` tile | E | `outline` | 3.14 / 3.38 (sheet); 3.54 / 4.54 (field fill) |
| `ghostBorder` | `app_decorations` raised (dark) / recessed / hero edge; `mx_divided_column`; `mx_bottom_nav`; `mx_sheet_actions`; `mx_footer_bar`; `mx_note`; `mx_button` ghost edge; `study_browse` hairline; `import_step_tracker` track; `app_component_themes` disabledBorder; `mx_code_field` disabled; `mx_outcome_tile` kept edge | D | `outlineVariant` (hero and kept tile: no edge) | — |
| `ghostBorder` | `mx_filter_chip`, `mx_chip_trigger` unselected edge | E | `outline` | 3.70 / 5.63 (page) |
| `surfaceHero` | `app_decorations.heroCard` | ground | `primaryContainer` | §4.6 |
| `dangerSoft` / `dangerBorder` | `app_decorations.dangerCard`, `studyChoice.wrong`; `mx_button.dangerSoft`; `mx_error_state`; `mx_action_sheet_command_row` destructive tile; `mx_icon_tile.danger`; `mx_inline_banner` danger | ground | `errorContainer`, text `onErrorContainer`, glyph `error` | 8.73 / 7.78 · 4.62 / 4.65 |
| `dangerInk` | `mx_inline_banner` danger title | T | `onErrorContainer` | 8.73 / 7.78 |
| `warningSoft` / `warningBorder` | `app_decorations.warningCard`; `mx_inline_banner` warning; `mx_icon_tile.caution`; `mx_outcome_tile` lost; `mx_floating_notice` | ground | `warningContainer`, text `onWarningContainer`, glyph `warning` | 13.34 / 7.26 · 5.04 / 5.51 |
| `warningInk` | `mx_field_message`, `mx_badge` warning tonal label (`onWarningContainer`), `mx_workload_breakdown_line` learning, `card_history_event` lapse glyph, `study_entry_hero` overdue, `study_fill` / `study_recall` status label, `session_summary_facts` wrong count, `recall_countdown_bar` timed-out ink, `tag_rename_dialog` note (on `warningContainer`), `import_preview_row` invalid note and glyph | T/G | `warning` on the page; `onWarningContainer` for text on the container | 5.24 / 6.71 (sheet); 5.04 / 5.51 on container |
| `successSoft` / `successBorder` | `app_decorations.successCard`, `studyChoice.right`; `mx_icon_tile.success`; `mx_outcome_tile` kept | ground | `successContainer`, text `onSuccessContainer`, glyph `success` | 13.33 / 7.22 · 5.02 / 5.47 |
| `successInk` | `studyChoice.right` ink, `mx_outcome_tile` kept ink, `mx_badge` success tonal label (text on the container); `mx_icon_tile.success` glyph; `sync_status_section` check, `import_preview_row` ready glyph, `card_history_event` glyph | T/G | `onSuccessContainer` for text on the container; `success` as a glyph and on the page | 13.33 / 7.22 · 5.02 / 5.47 · 5.23 / 6.69 |
| `statusNewInk` … `statusMasteredInk` | `mx_status_badge`, `card_row`, `mx_workload_breakdown_line` new, `progress_deck_row` learning caption, `progress_today` learning bar, `mx_mastery_donut`, `mastery_ramp.ink` | T/G | §4.7 | §4.7 |
| `semantic.warning` #F59E0B | `mx_button.warning` fill, `mx_icon_tile.warning` fill, `mx_empty_state` warning tone, `recall_countdown_bar` fill, `mx_badge` warning tone, `mx_status_badge` learning dot | F/G | `warning` (tone 40 / 80) with `onWarning` | 6.49 / 7.73 on the fill; ≥ 5.24 / 6.71 as a glyph |
| `semantic.success` #2BA88B | `mx_empty_state` success tone, `mx_badge` success | G | `success` | 5.23 / 6.69 |
| `semantic.mastery` #1F8A5B | `import_step_tracker` done fill and track, `mx_badge` mastery, gallery seed, `mastery_ramp` mastered fill | F/G | `mastery` / `onMastery` | 6.42 / 7.68 on the fill |
| `semantic.streak` | `progress_streak` flame | G | `streak` | 6.47 / 9.98 (lowest) |
| `errorFill` / `onErrorFill` | `mx_button.destructive` | F | `error` / `onError` | 5.86 / 6.93 |
| `primary` at alpha | §4.6 | ground | containers | §4.6 |

Every pair in the "New" and "Measured" columns is an assertion of
`test/core/theme/token_contrast_test.dart`, by role and ground, in both themes.

### 4.9 State coverage (shared widgets)

| Widget | Default | Selected / on | Focused | Pressed | Disabled | Error | Other |
|---|---|---|---|---|---|---|---|
| `MxButton` primary | `primary` / `onPrimary` | — | ring `primaryForeground` | `onSurface` 12 % layer | 0.38 | — | — |
| `MxButton` outline / text | ink `primaryForeground`, edge `outline` / none | — | ring | layer | 0.38 | — | — |
| `MxButton` ghost | `surfaceContainerLowest` / `onSurface`, edge `outlineVariant` | — | ring | layer | 0.38 | — | — |
| `MxButton` destructive / dangerSoft / warning | `error`/`onError` · `errorContainer`/`onErrorContainer` · `warning`/`onWarning` | — | ring | layer | 0.38 | — | — |
| Text field | fill `surfaceContainerLow`, edge `outline`, hint `onSurfaceVariant` | — | fill `surfaceContainerLowest`, edge `primaryForeground` | — | edge `outlineVariant`, 0.38 | edge `error`, message `error` | — |
| `MxCodeField` | slot edge `outline` | next slot `primaryForeground` | same | — | `outlineVariant` | `error` | — |
| `MxToggle` | off: `surfaceContainerHighest`, edge `outline` | on: `primary`, thumb white | ring | — | 0.38 | — | — |
| `MxOptionRow` radio | ring `outline` | ring `primaryForeground` | ring | layer | 0.38 | — | — |
| `MxSelectionCheckbox` | edge `outline` | fill `primary`, check `onPrimary` | ring | — | 0.38 | — | — |
| `MxFilterChip` / `MxChipTrigger` | edge `outline`, label `onSurface` | fill `primary`, label `onPrimary` | ring | layer | 0.38 | — | — |
| `MxStepper` | edge `primaryForeground` | — | ring | layer | 0.38 | edge `error` | — |
| `MxRowInk` / list rows | — | — | ring | layer | 0.38 | — | — |
| `MxNavRail` / `MxBottomNav` | icon `onSurfaceVariant` | pill `primaryContainer`, icon `onPrimaryContainer` | ring | layer | — | — | top edge `outlineVariant` |
| `MxCard` | raised: lowest (+ `outlineVariant` edge in dark) · recessed: low + edge | edge `primaryForeground` 2 dp | — | — | — | danger: `errorContainer` | hero `primaryContainer` · warning `warningContainer` · success `successContainer` |
| `MxBadge` tonal / solid | container + on-container label, role dot / role + on-role | — | — | — | — | danger: `errorContainer` / `onErrorContainer` | — |
| `MxStatusBadge` | §4.7 | — | — | — | — | — | — |
| `MxIconTile` | tinted: `primaryContainer` / `primaryForeground` | — | — | — | — | danger: `errorContainer` / `error` | primary · warning · success · caution per §4.6 |
| `MxInlineBanner`, `MxFloatingNotice`, `MxDialog` warning | container, on-container text, role glyph | — | action: button states | — | — | — | — |
| `MxEmptyState` | neutral `onSurfaceVariant` | — | — | — | — | danger `error` | primary `primaryForeground`, success `success`, warning `warning` |
| `MxErrorState` | tile `errorContainer`, glyph `error` | — | — | — | — | — | — |
| `MxSpinner` | fill `primary` on `onPrimary`; off-fill `primaryForeground` | — | — | — | — | — | loading |
| `MxLinearProgress`, `MxMasteryDonut` | track `surfaceContainerLow`, fill §4.7 | — | — | — | — | — | empty: track only |
| `MxOutcomeTile` | kept `successContainer`, lost `warningContainer` | — | — | — | — | — | — |
| `MxSnackbar` | inverse roles, unchanged | — | `inversePrimary` | — | — | — | — |
| Study choice | idle: ground + `outlineVariant` | `primary` / `onPrimary` | ring | layer | — | wrong `errorContainer` | right `successContainer` |

Each row is a widget test per state, on the ground the widget sits on, in both themes
(CHECK STATE COVERAGE).

### 4.10 Files

Core: `mx_semantic_colors.dart` (new shape), `app_color_schemes.dart` (`outline`),
`app_component_themes.dart`, `app_decorations.dart`, `mastery_ramp.dart`,
`mx_text_styles.dart` (takes the extension), `theme_context.dart`; `mx_derived_colors.dart`
deleted. Shared: the 27 widgets in §4.8 plus `mx_status_badge.dart` (resolver) and the
seven tint owners in §4.6. Features: the 19 files in §4.8 and
`card_display_status_model.dart`. Tests: `token_contrast_test.dart` (the table),
`mx_semantic_colors_test.dart`, `app_decorations_*_test.dart`, `mastery_ramp_test.dart`,
`mx_text_styles_ink_test.dart` (renamed), the 52 tests naming `MxDerivedColors`, the 32
naming the extension, state tests per §4.9, goldens. Docs: `DESIGN.md`,
`.impeccable/design.json`, UI-base spec §4 and §9, the screen index where a screen's
colours are named.

### 4.11 `DESIGN.md` and the documents

- **Colors** is rewritten around roles: Primary (`primary` the brand fill, `primaryForeground`
  the brand foreground, `primaryContainer` / `onPrimaryContainer` the wash), Neutral
  (`outline` the control edge with its new values, `outlineVariant` the hairline), Semantic
  (the four sets with their members and tones, status as a mapping). The frontmatter drops
  `warning-ink`, `status-*`, `error-fill`, `on-error-fill` and adds `primary-foreground`,
  the container and on-container members, and the new `outline`.
- **Named Rules:** The One Indigo Rule and The Green Means Progress Rule stay. The Ink Is
  Not The Fill Rule and The Contrast Floor Rule become **The Role Pair Rule** (§4.1) with
  the three floors (R7).
- **Components** rows that name an ink, a ghost edge, an outline edge or a soft ground are
  reworded to the role.
- `.impeccable/design.json`: the narrative sentences on derived inks and ghost borders, the
  component CSS values (focus ring #4151C6 → #384CDD, edges, tints).
- UI-base spec: §4's `DERIVED_COLOR` paragraph is replaced by a pointer to this spec; §9
  gets row 174 closing the derived layer and citing rows 3, 20, 30, 58, 60, 67, 105, 121,
  122, 141 and 145 as superseded.
- Detail files in `docs/shared/ui/screen-handoff/` that name a derived colour are updated
  in the task that touches their screen.

## 5. Impact assessment

| Area | Size | Nature |
|---|---|---|
| `lib/core/theme` | 7 files, 1 deleted | the layer, the extension's shape, `outline`, the text styles' signature |
| Shared widgets | 27 + 7 tint owners + the resolver | colour arguments and the alpha constants; no layout or behaviour change |
| Features | 19 files + 1 model | colour arguments; `card_row` loses its switch |
| Tests | 52 derived + 32 semantic references; `token_contrast_test.dart` becomes the table; state tests added | mechanical where a test named a token; new where a state was untested |
| Goldens | 546 images; nearly all change, since every hairline, edge, focus ring and semantic fill moves by a few values | one regeneration after the last consumer task, one `golden-compare` review page grouped by screen, approved by the owner image by image |
| Visible changes a person notices | light: deeper amber / teal / green, dark-amber warning button, stronger hero and pill wash, chip edges, slightly darker `outline`; dark: periwinkle focus rings and selected marks, washed pills and heroes | listed per screen on the review page |
| Documents | `DESIGN.md`, `design.json`, UI-base spec, detail files | §4.11 |
| Risk | a pair not in the table | the contrast test is the gate: a role painted on a ground the table lacks fails the test |

## 6. Migration plan (phases; each a plan task group, one epic)

1. **Roles.** `MxSemanticColors` in its new shape with the old members kept for one phase;
   `outline` values; `primaryForeground`; `token_contrast_test.dart` asserting the whole
   §4.3 / §4.8 table (RED first: the new roles do not exist). No consumer moves.
2. **Core consumers.** `AppComponentThemes`, `AppDecorations`, `MasteryRamp`,
   `MxTextStyles`, the status resolver; their tests. `MxDerivedColors` still compiles,
   unused by core.
3. **Shared widgets**, in three groups with their state tests (§4.9): edges and hairlines;
   brand foreground and focus; containers and the alpha tints.
4. **Features** (19 files, the card status model).
5. **Delete** `MxDerivedColors`, `derivedColors`, its test, the old extension members and
   the status / errorFill tokens; a `code-verification` guard rule then forbids
   `Color.lerp`, `HSLColor` and `HSVColor` in `lib/` (so the layer cannot grow back), and
   `withValues(alpha:)` is held to `AppOpacity` state layers and the disabled dim by the
   CHECK SIMILAR grep below and by review.
6. **Goldens and documents.** One `run_goldens.sh --update`, the `golden-compare` page,
   `DESIGN.md`, `design.json`, the UI-base spec, the detail files; one `impeccable audit` of
   the changed system.

After phases 3, 4 and 6: **CHECK STATE COVERAGE** (every §4.9 cell has a test that paints
the role), **CHECK DEGRADE** (the direct consumers of `outline`, `onPrimaryContainer`,
`errorContainer` and `inversePrimary` that did not change still read as before; the
snackbar, the breadcrumb and the history rail are the named ones), **CHECK SIMILAR** (a
`grep` for `withValues(alpha:`, `Color.lerp`, `HSLColor` and literal `Color(0x` outside
`lib/core/theme` finds nothing new; the hits found at spec time, `mx_empty_state`'s
`warning` and `success` glyphs at 2.04 and 2.82:1, are closed by §4.3). The PR and the
Done comment carry all three.

## 7. Tests

- `token_contrast_test.dart`: for each theme, each row of §4.3 and §4.8, `contrast(fg, bg)
  >= floor`; the table is the oracle and a new pair is added here first.
- `mx_semantic_colors_test.dart`: the shape (members, `lerp`, `copyWith`), the deleted
  members gone.
- `app_color_schemes_test.dart`: `outline` on the five grounds ≥ 3:1 in both themes;
  `primary` unchanged.
- `app_decorations_test.dart`, `app_decorations_study_choice_test.dart`: grounds are the
  containers, edges `outlineVariant` or none.
- `mastery_ramp_test.dart`, the status resolver test: §4.7.
- Widget state tests per §4.9 row, light and dark, `pumpWidget` on the widget's real ground.
- The guard rule from phase 5, with its own fixture.
- Goldens: regenerated once, reviewed once.

## 8. Rejected and out of scope

- **`primary` at tone 40 / 80** (M3 by the book): rejected by the owner (R1); the brand fill
  stays, hence `primaryForeground`.
- **`surfaceTint` elevation overlay for the hero** (Flutter's `ElevationOverlay`): it
  reproduces today's 5 % tint with an M3 role, but Material 3 retired tint overlays for the
  surface-container roles, and the hero's content would still have no on-colour.
- **Keeping the saturated amber / teal as a fifth member** of each set: that is the derived
  layer under a new name (R4); the sets use M3 tones and the dark theme already did.
- **Neutral text + coloured dot for status** (no coloured status text): possible, but the
  status foregrounds pass as roles (§4.7) and the approved design reads status in colour.
- Out of scope: `inversePrimary`'s dark value, `secondary` / `tertiary` usage, typography,
  layout, the `memox-api-services` reference.
