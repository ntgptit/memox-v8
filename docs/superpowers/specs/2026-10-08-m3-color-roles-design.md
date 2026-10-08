# Colour roles: Material 3 roles only, the derived ink layer removed — design

Status: owner rulings 2026-10-08 (chat), revised after the owner's spec review of the same
day (R12–R16, §4.12, §4.13, §6.1–6.3), awaiting review ·
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
(`dangerSoft`, `dangerBorder`, …), `surfaceHero`, `ghostBorder` and `outlineEdge`. Sixty-one
`lib/` files read them (eight in `core/theme`, 33 shared widgets, 20 feature files); eleven
more mix their own tints with `withValues(alpha:)` at a literal or private alpha. Every one of those colours exists because an approved fill
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
- **R12 · The guard forbids the layer, not colour maths** (owner, spec review 2026-10-08).
  `Color.lerp`, `HSLColor` and `HSVColor` are banned only where they would rebuild a
  semantic or derived colour outside the approved theme architecture; `ThemeExtension.lerp`,
  animation, state-layer composition and other legitimate colour handling stay allowed, and
  the rule ships with positive and negative fixtures (§6.1).
- **R13 · Screen-level state coverage.** Shared-widget states are not enough: every affected
  screen is listed with the states its detail file and its code really have, the widgets and
  roles that move, the grounds and overlays, the transitions that repaint, light and dark,
  and the evidence or the reason it cannot be verified (§4.12). Widgets are checked in the
  screen they live on.
- **R14 · The dark hero CTA is judged, not assumed.** 2.51:1 between the button fill and the
  dark `primaryContainer` is neither declared a WCAG failure nor excused by the label's
  contrast; an Impeccable critique and native audit judge affordance, hierarchy and the
  interaction states, and the role or the presentation changes if they fail, with the brand
  #5265F5 kept (§4.6).
- **R15 · Incremental visual verification.** The goldens regenerate once at the end, but the
  pre-migration baseline is kept; after each shared-widget group, targeted widget and state
  tests run and representative previews and diffs are produced; the final golden diff is
  classified expected / unexpected / unresolved, and no golden is approved automatically
  (§6.2).
- **R16 · Gates with evidence.** ROOT CAUSE FIRST, COMMON FIRST, CHECK STATE COVERAGE,
  CHECK STATE TRANSITIONS, CHECK DEGRADE, CHECK SIMILAR and an independent verification each
  leave an executed artefact (a test run, a rendered image, a grep output, a review from a
  fresh context), never a self-ticked checklist (§6.3).
- **R17 · Selected fills on dark sheets (open, for the owner).** `primary` as the fill of a
  selected chip, a checked box or an on toggle is 2.46:1 against the dark sheet and 2.90
  against `surfaceContainer` (§4.2). The spec recommends accepting these as measured
  exemptions identified by their on-colour mark (the white check, thumb or label, 4.63:1),
  recorded in `DESIGN.md` beside the hero's, because the alternatives either change the
  brand fill (R1) or add a `primaryForeground` edge to every selected control; the owner
  decides at approval.

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
the fill of a selected control; where such a control sits on a dark sheet or
`surfaceContainer` (the tag filter chips in the card filter sheet, a checked box in a
picker) the fill-vs-ground pair is 2.46 / 2.90 and R17 applies. It is never text (4.39
light, 4.11 dark on the page).

`inversePrimary` (#A0ACFF on the invariant `inverseSurface`, 5.21:1) is the snackbar action
and is out of scope.

### 4.3 `MxSemanticColors`: the custom-colour sets

Values are HCT tones of the current hues (`material_color_utilities`, the same palette M3
seeds from), tone 40 / 100 / 90 / 10 in light and 80 / 20 / 30 / 90 in dark, each pair
measured. Ratios are against surface · lowest · low · container · high unless named.

| Role | Light | Measured | Dark | Measured |
|---|---|---|---|---|
| `primaryForeground` | #384CDD (indigo tone 40) | 6.14 · 6.47 · 5.88 · 5.52 · 5.22; on `primaryContainer` 5.18, `warningContainer` 5.02, `errorContainer` 5.10, `successContainer` 5.01, `masteryContainer` 5.02 | #BCC2FF (tone 80) | 11.13 · 9.95 · 8.97 · 7.86 · 6.68; on `primaryContainer` 6.79, `warningContainer` 5.48, `errorContainer` 5.89, `successContainer` 5.46, `masteryContainer` 5.46 |
| `warning` | #855300 (amber tone 40) | 6.16 · 6.49 · 5.90 · 5.54 · 5.24; on `warningContainer` 5.04, `primaryContainer` 5.20, `successContainer` 5.03, `errorContainer` 5.12; vs low track 5.90 | #FFB95F (tone 80) | 11.18 · 9.99 · 9.01 · 7.90 · 6.71; on `warningContainer` 5.51, `primaryContainer` 6.82, `successContainer` 5.48, `errorContainer` 5.92; vs low track 9.01 |
| `onWarning` | #FFFFFF | 6.49 on `warning` | #472A00 (tone 20) | 7.73 on `warning` |
| `warningContainer` | #FFDDB8 (tone 90) | ground | #653E00 (tone 30) | ground |
| `onWarningContainer` | #2A1700 (tone 10) | 13.34 on its container | #FFDDB8 (tone 90) | 7.26 on its container |
| `success` | #006B57 (teal tone 40) | 6.15 · 6.48 · 5.89 · 5.53 · 5.23; on `successContainer` 5.02 | #67DABB (tone 80) | 11.15 · 9.97 · 8.98 · 7.88 · 6.69; on `successContainer` 5.47 |
| `onSuccess` | #FFFFFF | 6.48 on `success` | #00382C (tone 20) | 7.69 on `success` |
| `successContainer` | #85F7D6 (tone 90) | ground | #005141 (tone 30) | ground |
| `onSuccessContainer` | #002019 (tone 10) | 13.33 on its container | #85F7D6 (tone 90) | 7.22 on its container |
| `mastery` | #006D44 (green tone 40) | 6.09 · 6.42 · 5.83 · 5.48 · 5.18; on `masteryContainer` 4.98, `primaryContainer` 5.14; vs low track 5.83 | #77DAA4 (tone 80) | 11.18 · 9.99 · 9.00 · 7.89 · 6.71; vs low track 9.00 |
| `onMastery` | #FFFFFF | 6.42 on `mastery` | #003921 (tone 20) | 7.68 on `mastery` |
| `masteryContainer` | #93F7BE (tone 90) | ground | #005232 (tone 30) | ground |
| `onMasteryContainer` | #002111 (tone 10) | 13.29 on its container | #93F7BE (tone 90) | 7.23 on its container |
| `streak` | #9D4300 (orange tone 40) | 6.16 · 6.49 · 5.89 · 5.54 · 5.24 | #FFB690 (tone 80) | 11.17 · 9.98 · 9.00 · 7.89 · 6.70 |

`streak` declares its one consumed member (the Progress flame); it is a set by shape and
takes `onStreak` / `streakContainer` / `onStreakContainer` only when a consumer paints them,
as this section's first paragraph says for every set. `ColorScheme` pairs the table relies
on, for the contrast test: `onPrimary` on `primary` 4.63; `onError` on `error` 5.86 / 6.93;
`primary` as a fill against the sheet 3.74 light / 2.46 dark and against
`surfaceContainer` 3.95 / 2.90 (§4.2, R17).

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
`foregroundColor`, hence the name; "ink" is retired with the layer. It succeeds
`primaryInk` in most of its consumers, and that is the point of R8: the same need, met by a
role that is a literal M3 tone defined once per theme and measured in the table, instead of
a mix computed from the fill at runtime; nothing else of the derived layer survives. Where
it is painted:

- text on a neutral ground: outline and text buttons, the selected tab label,
  `disclosureLabel`, `rowTitleMatch`, `MxStatTile`'s emphasised value, the reviewing term of
  `MxWorkloadBreakdownLine`, the reviewing caption of the Progress deck row, the Monitoring
  code frame, the action sheet command label (text on `primaryContainer`, such as the Study
  top bar badge or a tonal primary badge, is `onPrimaryContainer`, the pair of R8);
- icons: the focused search icon, `MxIconTile` tinted glyph (on `primaryContainer`), the add-details and removable-tag
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
| `ghostBorder` | decorative hairline: dark raised card and recessed card edge, section and list dividers (`MxDividedColumn`), the bottom nav, sheet actions and footer bar top edges, `MxNote`, the Study browse hairline, the import step track, a disabled field and a disabled code slot | `outlineVariant` (#C5CBE3 light 1.53:1, #2A3267 dark 1.58:1) | the M3 divider and decorative edge; no floor applies (R7, SC 1.4.11 exempts the disabled control) |
| `outlineEdge` | the edge that identifies a control: a field at rest, the outline button, the unchecked box, the unselected radio ring, the off toggle, the code slots, the add-details tile | `outline` (§4.2 values) | the M3 control edge; 3:1 on every ground a control sits on, in both themes |
| `ghostBorder` on `MxFilterChip` / `MxChipTrigger` unselected, on the ghost button, on the idle study choice | the control's only boundary | `outline` | M3's unselected filter chip edge; a chip, a ghost button and a tappable choice card are controls (3.89 / 5.03 on the raised ground) |
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
| `primary` at 8–16 % | `MxIconTile` tinted, action sheet command tile, Study top bar badge, removable tag chip, `MxBadge.primary` tonal | `primaryContainer` | `onPrimaryContainer` (the badge and chip labels) | `primaryForeground` (the tile and chip glyphs) |
| `primary` at 14 / 20 % | the nav rail and bottom nav selected pill | `primaryContainer` | `onPrimaryContainer` icon and label 10.37 / 8.81 | — |
| `mastery` / `warning` / `success` at 12 % | `MxBadge` tonal tones | the role's container | its on-container | the role |
| study choice right / wrong | `AppDecorations.studyChoice` | `successContainer` / `errorContainer`, no edge | `onSuccessContainer` / `onErrorContainer` | — |
| `MxEmptyState` tile at `_tileTint` | every empty state | the tone's container (`primaryContainer`, `successContainer`, `warningContainer`, `errorContainer`, neutral `surfaceContainerHigh`) | — | the tone's foreground (§4.4, §4.3; `error` 4.62 / 4.65) |
| `card_schedule` past boxes (`primary` at `_pastAlpha`) | Card detail schedule | `primary` for past and current boxes (the current one is already taller, and the box number is text); future `surfaceContainerHigh` (`primaryContainer` was measured 1.01 against it and rejected) | — | — |
| `MxFilterChip` resting count (`ink` at `_countOpacityResting`) | chip rows | — | `onSurfaceVariant` (7.20 / 8.50) | — |
| study choice idle | same | raised or recessed ground, `outline` edge (a tappable card is a control, R9: 3.89 / 5.03 on the raised ground) | `onSurface` | — |

On the dark hero the primary button's fill is 2.51:1 against `primaryContainer`. The hero
keeps its filled action, not by a rule but by the judgement R14 asked for: the Impeccable
critique of §4.13 rendered the proposal and found the CTA still the loudest object (hue and
chroma against a muted ground, the label, the glyph, the block shape) with the hierarchy
intact. `DESIGN.md` records this one pair as a measured exemption to the 3:1 non-text floor,
with the critique as its evidence; it is not a general licence for filled controls (R7). The
hero's supporting text in `onSurfaceVariant` (6.07 / 5.19) is the one exception to "a
container's text is its on-container"; every other container reads in its on-container
only, because `onSurfaceVariant` is 4.19 on the dark `warningContainer` and 4.17 on the dark
`successContainer`. The hero's title and body reach `onPrimaryContainer` through the text
styles' `…In(color)` variants (`rowTitleIn`, `captionIn`, as `statusNote(color)` already
does), never through a `DefaultTextStyle`, since the styles set their colour explicitly.

The alpha constants that mixed these grounds (`_tint`, `_tileTint`, `_badgeTint`,
`_pillTint*`, `_primaryTint*`, `_seedTint`, `_keptTint`) are deleted. `MxIconTile.seed`
(one gallery call, `mastery`) becomes `MxIconTileTone.mastery` (`masteryContainer` /
`mastery`).

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
| `ghostBorder` | `app_decorations` raised (dark) / recessed / hero edge; `mx_card` (every tone through `AppDecorations`); `mx_divided_column`; `mx_bottom_nav`; `mx_sheet_actions`; `mx_footer_bar`; `mx_note`; `study_browse` hairline; `import_step_tracker` track; `app_component_themes` disabledBorder; `mx_code_field` disabled; `mx_outcome_tile` kept edge | D | `outlineVariant` (hero and kept tile: no edge) | — |
| `ghostBorder` | `mx_filter_chip`, `mx_chip_trigger` unselected edge; `mx_button` ghost edge; `studyChoice.idle` (`study_choice_widget`) | E | `outline` | 3.70 / 5.63 (page); 3.89 / 5.03 (raised) |
| `MasteryRamp.fill / ink` (derived argument) | `mx_linear_progress`, `mx_mastery_donut`, deck rows | F/T | the ramp takes the scheme and the extension; §4.7 | §4.7 |
| `semantic.mastery` seed | `gallery_surfaces_section` `MxIconTile(seed:)` | ground | `MxIconTileTone.mastery` | 13.29 / 7.23 |
| `semantic.success` solid | `mx_badge` solid success tone | F | `success` / `onSuccess` | 6.48 / 7.69 |
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
| `semantic.streak` | `progress_streak` flame | G | `streak` | 5.24 / 6.70 (sheet) |
| `errorFill` / `onErrorFill` | `mx_button.destructive` | F | `error` / `onError` | 5.86 / 6.93 |
| `primary` at alpha | §4.6 | ground | containers | §4.6 |

Every pair in the "New" and "Measured" columns is an assertion of
`test/core/theme/token_contrast_test.dart`, by role and ground, in both themes.

### 4.9 State coverage (shared widgets)

| Widget | Default | Selected / on | Focused | Pressed | Disabled | Error | Other |
|---|---|---|---|---|---|---|---|
| `MxButton` primary | `primary` / `onPrimary` | — | ring `primaryForeground` | `onSurface` 12 % layer | 0.38 | — | — |
| `MxButton` outline / text | ink `primaryForeground`, edge `outline` / none | — | ring | layer | 0.38 | — | — |
| `MxButton` ghost | `surfaceContainerLowest` / `onSurface`, edge `outline` | — | ring | layer | 0.38 | — | — |
| `MxButton` destructive / dangerSoft / warning | `error`/`onError` · `errorContainer`/`onErrorContainer` · `warning`/`onWarning` | — | ring | layer | 0.38 | — | — |
| Text field | fill `surfaceContainerLow`, edge `outline`, hint `onSurfaceVariant` | — | fill `surfaceContainerLowest`, edge `primaryForeground` | — | edge `outlineVariant`, 0.38 | edge `error`, message `error` | — |
| `MxCodeField` | slot edge `outline` | next slot `primaryForeground` | same | — | `outlineVariant` | `error` | — |
| `MxToggle` | off: `surfaceContainerHighest`, edge `outline` | on: `primary`, thumb `onPrimary` | ring | — | 0.38 | — | — |
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
| `MxInlineBanner`, `MxFloatingNotice`, `MxDialog` warning (the whole dialog ground is the container, as `MxCard.isWarning` is today) | container, on-container text, role glyph | — | action: primary (filled) or text tone in `primaryForeground` (≥ 5.01 / ≥ 5.46 on every container); never the outline tone on a container (dark `outline` 2.77 / 2.98, §4.2) | — | — | — | — |
| `MxEmptyState` | neutral `onSurfaceVariant` | — | — | — | — | danger `error` | primary `primaryForeground`, success `success`, warning `warning` |
| `MxErrorState` | tile `errorContainer`, glyph `error` | — | — | — | — | — | — |
| `MxSpinner` | fill `primary` on `onPrimary`; off-fill `primaryForeground` | — | — | — | — | — | loading |
| `MxLinearProgress`, `MxMasteryDonut` | track `surfaceContainerLow`, fill §4.7 | — | — | — | — | — | empty: track only |
| `MxOutcomeTile` | kept `successContainer`, lost `warningContainer` | — | — | — | — | — | — |
| `MxSnackbar` | inverse roles, unchanged | — | `inversePrimary` | — | — | — | — |
| Study choice | idle: ground + `outline` edge | `primary` / `onPrimary` | ring | layer | — | wrong `errorContainer` | right `successContainer` |

"Ring" is the focus ring: `primaryForeground`, drawn outside the control with
`AppStroke.focusOffset` by one shared painter (§4.13 P1), so it is always measured against
the ground, never against the control's fill. Each row is a widget test per state, on the
ground the widget sits on, in both themes (CHECK STATE COVERAGE).

### 4.10 Files

Core: `mx_semantic_colors.dart` (new shape), `app_color_schemes.dart` (`outline`),
`app_component_themes.dart`, `app_button_style.dart` (the outer focus ring, §4.13),
`app_decorations.dart`, `mastery_ramp.dart`, `mx_text_styles.dart` (takes the extension;
`…In(color)` variants for the hero), `theme_context.dart`; `mx_derived_colors.dart`
deleted. Shared: the 33 widgets in §4.8 plus `mx_status_badge.dart` (resolver) and the
eleven tint owners in §4.6. Features: the 20 files in §4.8 and
`card_display_status_model.dart`. Tests: `token_contrast_test.dart` (the table),
`mx_semantic_colors_test.dart`, `app_decorations_*_test.dart`, `mastery_ramp_test.dart`,
`mx_text_styles_ink_test.dart` (renamed `mx_text_styles_foreground_test.dart`), the 52 tests naming `MxDerivedColors`, the 32
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

### 4.12 Screen-level state coverage (R13)

The migration repaints every screen, so the screen's detail file (its States table) and
its code are the inventory, as CLAUDE.md's "A screen is a state machine" requires. The
table lists, per screen: the states the detail file records and how many have both goldens
today (`n / g`); the widgets and roles that move on that screen; the grounds the colours sit
on (page = `surface`, card = `surfaceContainerLowest`, field = `surfaceContainerLow`, sheet
or dialog = `surfaceContainerHigh`, keyboard = the field's ground with insets); the
transitions that repaint; and the evidence plan. Every state is checked in light and dark at
360 dp, default text scale. A state without a golden is rendered as a throwaway image in
the audit (phase 6) or reported `UNVERIFIED` with its reason; `N/A` where the state paints
no migrated role. The risk order is CLAUDE.md's: broken primary actions and dead ends (a
CTA or a control edge that stops reading), then stale or async state, then layout.

| # | Screen | States n / g | Widgets and roles that move | Grounds and overlays | Transitions that repaint | Evidence plan |
|---|---|---|---|---|---|---|
| 01 | Deck list · recursive | 22 / 8 | due strip and summary hero (`primaryContainer`, CTA), deck rows (mastery bar fill, due badge on `primaryContainer`, row hairline), breadcrumb chevron (`outline`), FAB, `MxEmptyState`, `MxErrorState`, actions sheet (command tiles `primaryContainer`), create / rename dialog (field `outline` → `primaryForeground` focus, `error`), reorder (selected edge `primaryForeground`), sort chip (`outline`) | page, card, sheet, dialog, keyboard | loading → loaded; loaded ↔ empty (content gate); error → retry; dialog open / field focus / error; reorder enter / exit; delete → trashed (inverse snackbar) | goldens for 8 states; 14 rendered in the audit (rootCreate, rootRename, deckMove and the loading / error / notFound ones are the risk rows); focus state by widget test |
| 02 | Review algorithm & reset | 9 / 3 | option rows (radio `outline` / `primaryForeground`), lock strip (`warningContainer`), reset dialog (`warningContainer`, destructive `error` / `onError`), spinner | page, card, dialog | locked ↔ unlocked; switching → switched / switchFailed; resetConfirm → resetting → resetDone | 3 goldens; switching / resetting by widget test (spinner off-fill); the rest rendered |
| 03 | Starter decks | 10 / 10 | rows, `MxBadge` (tonal containers), choose sheet, `MxInlineBanner` (alreadyPresent, addFailed), `MxEmptyState`, `MxErrorState` | page, card, sheet | list → choose → adding → added; addFailed → retry | goldens for all; banner text on container by contrast test |
| 04 | Library search | 6 / 6 | search field (`outline`, focus), result rows, tag chips, `MxEmptyState`, `MxErrorState`, load-more failure banner | page, card, keyboard | emptyQuery → results / noResults; error → retry; loadMoreFailed | goldens for all; focused field by widget test |
| 05 | Tags | 13 / 12 | tag rows, search field, rename dialog (field on sheet, merge note `warningContainer`), delete confirm (`error`), busy spinner, `MxEmptyState` | page, card, dialog, keyboard | loaded ↔ empty / searchEmpty; rename → renameMerge / nameTooLong; del → busy → opError | 12 goldens; read error rendered; field focus and error on the dialog by widget test |
| 06 | Trash | 15 / 9 | filter chips (`outline` / `primary`), selectable rows (checkbox `outline` / `primary`, selected edge `primaryForeground`), actions sheet, deck picker sheet, purge confirm (`error`), `MxEmptyState`, snackbar (inverse, unchanged) | page, card, sheet, dialog | all ↔ cards / decks; selection enter / exit; restoreTarget → restored / undoRefused; purgeConfirm → purged | 9 goldens; cards / decks / restored / undoRefused / purged / loading rendered; checkbox states by widget test |
| 07 | Card list | 15 / 7 | deck summary hero + CTA, filter chips, card rows (`MxStatusBadge` §4.7, flag glyph, due badge), selection (checkbox, selected edge), actions sheet, move picker, `MxInlineBanner` bulkFailed, delete confirms | page, card, sheet, dialog | loaded ↔ empty / search; selection enter / exit; moveTargets → noMoveTarget; bulkFailed; delCard / delDeck → trashed | 7 goldens; empty / loading / error / notFound / deckActions / moveTargets / noMoveTarget / delDeck rendered; status badge four states by widget test |
| 08 | Card create | 9 / 2 | text fields (`outline`, focus `primaryForeground`, `error`), add-details tile (`outline`, glyph `primaryForeground`), tag chips (`primaryContainer`), `MxFieldMessage` (`warning`), footer bar hairline, save button, `MxInlineBanner` saveFailed | page, field, keyboard | emptyForm → valid → saving → saveFailed; validationErr / frontTooLong / tagLimit / deckRejects | 2 goldens; every validation state rendered (the error edge on the field ground is a risk row); keyboard state by the existing keyboard golden |
| 09 | Card edit | 9 / 3 | as 08 plus discard dialog, delete confirm, loading skeleton, `MxErrorState` | page, field, dialog, keyboard | loaded → dirtySaving → saveFailed; discard; delConfirm; loadError / notFound | 3 goldens; the rest rendered; dialog destructive button by contrast test |
| 10 | Card detail | 7 / 1 | schedule boxes (`primary` / `primaryContainer`), history rail (`outline`), history events (`warning` / `success` glyphs on badges), status badge, load-more banner, `MxEmptyState`, `MxErrorState` | page, card | loaded → loadMore → loadMoreFailed; empty; error / notFound | 1 golden; six rendered; history glyphs by contrast test |
| 11 | Card import | 23 / 9 | step tracker (`mastery`, `outlineVariant` track), preview rows (`success` / `warning` glyphs and notes), section rows, option rows, `MxInlineBanner` (badEncoding, refused, failed), footer / commit bar, toggles (`outline`) | page, card, sheet, keyboard (paste) | source → parsing → mapping → preview → importing → success / partial / failed; sections undecided → decided → result / refused | 9 goldens; 14 rendered; the preview row invalid note and the step tracker are contrast-test rows |
| 12 | Card export | 9 / 3 | option rows, preparing spinner, `MxInlineBanner` failed / noShareTarget / staleSelection, `MxEmptyState` nothingToExport | page, card | wholeDeck ↔ selection; preparing → handedOver / failed; shareClosed | 3 goldens; six rendered |
| 13 | Study home | 10 / 10 | deck rows, resume banner (`primaryContainer`, dot `primary`), sync banner (outline action), `MxEmptyState` (noDecks, noCards, zero), `MxErrorState`, reauth banner | page, card | loaded ↔ noResume / zero; syncRejected / syncStale / reauth; error → retry | goldens for all; banner text on container by contrast test |
| 14 | Study entry | 9 / 9 | stat tiles (`primaryForeground` emphasis), overdue note (`warning`), mode option rows (radio), resume banner, footer (primary / outline, spinner), `MxInlineBanner` refused (`warningContainer`) / startFailed (`errorContainer`), direction sheet, skeleton | page, card, sheet | sm2 / eightBox / onlyNew / nothing; resume; starting → refused / startFailed → retry | goldens for all; the starting spinner off-fill and the refused banner are contrast-test rows |
| 15 | Study options | 9 / 7 | option rows, stepper (`primaryForeground` edge, `error`), toggles, field message, save footer, `MxInlineBanner` saveFailed | page, card, keyboard | override ↔ defaults; invalid; saving → saved / saveFailed; gone | 7 goldens; gone and read error rendered; stepper states by widget test |
| 16 | Study · Browse | 1 / 1 | Study top bar (badge `primaryContainer` / `onPrimaryContainer`, track `primary`), face cards (raised / recessed edges), browse hairline (`outlineVariant`), footer | page, card | page turn; scroll fade | golden; top bar by widget test |
| 16a | Study · Self-assess | 6 / 0 | top bar, face card, reveal, answer buttons (primary / outline / dangerSoft `errorContainer`), relearning note (`warning`), `MxInlineBanner` saveFailed, stale state | page, card | prompt → revealed → saving → saveFailed; relearning; stale | no goldens today: all six rendered in the audit (risk: the answer buttons are the primary action) |
| 17 | Study · Match | 1 / 1 | choice cards (idle `outlineVariant`, selected `primary`, right `successContainer`, wrong `errorContainer`), top bar | page, card | idle → selected → right / wrong (animated `ColorTween`) | golden; the four choice tones by `app_decorations_study_choice_test.dart` |
| 18 | Study · Guess | 1 / 1 | as 17 | page, card | same | golden; same test |
| 19 | Study · Recall | 3 / 3 | countdown bar (`warning` fill and ink when timed out), status label (`warning`), outcome tile (`successContainer` / `warningContainer`), text field | page, card, keyboard | countingDown → revealed / timedOut | goldens; the timed-out bar fill on its track is a contrast-test row |
| 20 | Study · Fill | 3 / 3 | text field (focus), hint, wrong label (`warning`), outline button | page, card, keyboard | input → hint → wrong | goldens; field focus by widget test |
| 21 | Session summary | 10 / 9 | summary hero (`successContainer` / `warningContainer` / `errorContainer`), facts (`warning` wrong count), outcome tiles, `MxInlineBanner` saveError, buttons | page, card | loaded / learning / large; leftEarly / interrupted / reset / schedulerChanged; saveError; contentDeleted | 9 goldens; loading rendered; the three hero tones are contrast-test rows |
| 22 | Progress | 12 / 8 | streak tile (`streak`), today bars (`primary` / `warning` on the track), deck rows (status captions), dashed note (`outlineVariant`), breadcrumb, `MxEmptyState`, `MxErrorState` | page, card | 7 days ↔ 30 days; held / lost / never; loading / error; deck → no sub-decks / deck gone | 8 goldens; quiet range / no decks / no sub-decks / deck gone rendered |
| 23 | Settings | 12 / 11 | settings rows (hairlines), sync row glyph (`success`), admin row, reset dialog (`warningContainer`), account rows, `MxInlineBanner` syncFailed / syncRejected / re-auth | page, card, dialog | loaded; resetConfirm → resetDone; sync states; account states | 11 goldens; read error rendered |
| 23a | Settings · Study options | 9 / 8 | as 15 plus two sheets (option rows on the sheet ground) | page, card, sheet, keyboard | loaded → saving → saved / saveFailed; invalidLimit; sheets open | 8 goldens; read error rendered; radio ring on the sheet is a contrast-test row |
| 23b | Settings · Admin | 2 / 1 | settings rows, toggle, gate `MxEmptyState` | page, card | loaded ↔ gate | 1 golden; gate rendered |
| 24 | Daily reminder | 10 / 10 | toggle (`outline` off / `primary` on), time row, `MxInlineBanner` permDenied / couldNotSchedule / offMayShow / unavailable, stepper | page, card, dialog | off → turningOn → on; changingTime; permDenied / couldNotSchedule | goldens for all; the toggle states by widget test |
| 25 | Theme | 4 / 3 | theme choice cards (preview blocks `outlineVariant`, check `primaryForeground`, selected edge) | page, card | system ↔ light ↔ dark | 3 goldens; read error rendered |
| 26 | Language | 4 / 3 | option rows (radio) | page, card | pick | 3 goldens; read error rendered |
| 27 | Sync | 10 / 8 | status rows, notice banners (`warningContainer`, `errorContainer`), keep dialog (`warningContainer`), outline / primary actions, spinner | page, card, dialog | synced / pending / failed / rejected; keepDialog; syncing | 8 goldens; loading / read error rendered |
| 28 | Monitoring | 15 / 10 | search field, level chips, log rows, badges, code card (frame `primaryForeground`), sheets, `MxEmptyState`, `MxErrorState`, offline banner | page, card, sheet, keyboard | list ↔ detail; filters; offline; loading / error / not an admin | 10 goldens; five rendered; code frame is a contrast-test row |
| 29 | Welcome | 2 / 2 | primary and outline buttons, offline banner | page | ready ↔ offline | goldens |
| 30 | Sign-in, merge sheet, layer | 13 / 13 | text field (focus, `error`), buttons, merge sheet (option rows on the sheet), transition layer (spinner), banners | page, sheet, keyboard | link → invalid; sending → merging / offline; merge → discard; reauth; stuck | goldens for all; field states on the sheet by widget test |
| 31 | Code | 3 / 2 | code field (slots `outline`, next `primaryForeground`, `error`, disabled `outlineVariant`), resend text button | page, keyboard | waiting → wrong → verifying | 2 goldens; verifying rendered; slot states by widget test |
| 32 | Account | 9 / 9 | rows, badges, dialogs (switch, sign-out, delete: `error` / `onError`, `warningContainer`), banners (offline, last admin) | page, card, dialog | ready → validating → reauth; dialogs; loss | goldens for all |
| 33 | Users | 10 / 6 | search field, user rows, role sheet (option rows), badges, `MxEmptyState`, `MxErrorState`, offline banner | page, card, sheet, keyboard | loaded ↔ no match; role sheet → changed / refused; loading / error / not an admin | 6 goldens; four rendered |
| — | App shell, gallery | — | nav rail and bottom nav (pill `primaryContainer`, top hairline), snackbar (unchanged), the debug gallery (every tone) | page, sheet | tab change; snackbar | shell goldens; the gallery renders every shared-widget tone in both themes and is the first image reviewed |

Totals: 315 states over 36 screens; 211 rows have a light and a dark golden, and the other
104 (DEV-317 counts 74 with no golden at all; this table asks for both themes) are rendered
as throwaway images in the phase-6 audit or reported `UNVERIFIED` by name. The detail files'
Transitions tables are reconciled with the code in the same audit; a transition found in
the code and missing from a table is a finding written into that table.

### 4.13 Critique of the dark hero CTA (R14)

Method: the Impeccable `critique` command's dual-agent form (Assessment A design review,
Assessment B the native audit of `audit.native.md`), run on the spec's proposal before any
code: Assessment A rendered the
deck summary hero in both themes with a throwaway golden test (current, proposal, and an
outline-CTA alternative; images in the session scratchpad, test deleted, tree clean) and
scored it; Assessment B audited the hero's reachable states from the source
(`mx_button.dart`, `app_button_style.dart`, `mx_row_ink.dart`, `mx_mastery_donut.dart`,
`mx_workload_breakdown_line.dart`) and computed every pair the spec had not measured. Both
sets of numbers were re-computed by the author; they agree.

**Verdict: keep the filled CTA on `primaryContainer`.** In dark the button stays the obvious
primary action (saturated fill on a muted violet ground; label 4.63:1, play glyph, full-width
block), the hierarchy is button → title (8.81) → eyebrow → workload line, and the ground
reads as a card without an edge (1.64:1 against the page, against 1.20 today). The
outline-CTA alternative collapses the hierarchy (the ink is the title's family) and breaks
R1. Heuristics 1 / 4 / 6 / 8 scored 3 / 3 / 3 / 3.

Findings and rulings (each a row of the plan; severities are the critique's):

| # | Finding | Measured | Ruling |
|---|---|---|---|
| P1 | The focus ring is drawn on the button's own edge, so against a filled button it is a ring-vs-fill pair: `primaryForeground` 2.71 dark / 1.40 light against `primary`; today's `primaryInk` fails the same way (1.90 / 1.41) on every filled button. `onSurface` as the ring passes on `primary` (3.79 / 3.81) but not on the other fills (`error` dark 1.77, `warning` 2.71 / 1.39). | ring vs fill | **COMMON FIRST:** the ring moves outside the control, separated by `AppStroke.focusOffset` (declared, unused today), in one shared painter used by buttons, `MxRowInk`, chips, the toggle and the stepper; it is then always a ring-vs-ground pair, `primaryForeground` ≥ 5.01 light / ≥ 5.46 dark on every ground including the containers (§4.3). A pre-existing same-cause defect, fixed by the migration; a widget test pins the ring colour over each filled tone and a golden shows the offset ring. |
| P2 | The donut track (`surfaceContainer`) is 1.16 dark / 1.07 light on `primaryContainer`; at 0 % only the track and the "0 %" label paint. No neutral role does better than 1.64 on the dark container or 1.25 on the light one. | decoration | The track is decoration (R7, no floor) and the label carries the value, as on today's cards (1.17 / 1.27). Role unchanged; recorded, no change. |
| P2 | The pressed state layer is the ink at 12 % over the fill (M3's own state layer), so the label is 3.79:1 while held; identical today and global to every filled button. | transient text | Out of this migration's scope: a Material 3 state layer, transient, unchanged. A UI-base register row records it with the measured alternative (black at 12 %: label 5.68, fill 2.04 against the dark container). |
| P2 | The donut's label must stay the ramp band's foreground (SW-REV-001), not `primaryForeground`. | — | §4.7 names the band foreground for the donut label; measured on `primaryContainer`: `warning` 5.20 / 6.82, `mastery` 5.14 / 6.82, `primaryForeground` 5.18 / 6.79. |
| P2 | The tappable due strip's pressed layer (`onSurface` 12 % over the container) drops small text to 3.37–4.07 for the touch's duration. | transient text | Transient, M3 state layer, unchanged; the status term in question becomes `onSurfaceVariant` (§4.7) and is 3.75 dark while pressed. Recorded, no change. |
| P2 | The hero text styles are `onSurface` / `onSurfaceVariant` by construction; `onPrimaryContainer` needs a path. | — | §4.6: the `…In(color)` variants. |
| P3 | The dark fill-vs-container 2.51:1. | non-text | Exemption recorded in `DESIGN.md` (§4.6). |
| P3 | `MxRowInk`'s focus ring is rectangular inside the card's rounded clip, so its corners thin; the due strip's tap has no destination label. | — | Not colour: two small defects found along the way, each filed as a sub-issue of this epic; the ring corners are closed by the shared ring painter's task, the label by its own one-line task. |

Not verified by the critique: real pressed, focus and disabled renders (computed from the
code), device perception, the card-list variant (same widget shape, not rendered). The plan's
phase-6 audit renders both heroes in both themes with the focus ring.

## 5. Impact assessment

| Area | Size | Nature |
|---|---|---|
| `lib/core/theme` | 7 files, 1 deleted | the layer, the extension's shape, `outline`, the text styles' signature |
| Shared widgets | 33 + 11 tint owners + the resolver | colour arguments and the alpha constants; no layout or behaviour change except the focus ring's offset (§4.13 P1) |
| Features | 19 files + 1 model | colour arguments; `card_row` loses its switch |
| Tests | 52 derived + 32 semantic references; `token_contrast_test.dart` becomes the table; state tests added | mechanical where a test named a token; new where a state was untested |
| Goldens | 546 images; nearly all change, since every hairline, edge, focus ring and semantic fill moves by a few values | one regeneration after the last consumer task, one `golden-compare` review page grouped by screen, approved by the owner image by image |
| Visible changes a person notices | light: deeper amber / teal / green, dark-amber warning button, stronger hero and pill wash, chip edges, slightly darker `outline`; dark: periwinkle focus rings and selected marks, washed pills and heroes | listed per screen on the review page |
| Documents | `DESIGN.md`, `design.json`, UI-base spec, detail files | §4.11 |
| Risk | a pair not in the table | the contrast test is the gate: a role painted on a ground the table lacks fails the test |

## 6. Migration plan (phases; each a plan task group, one epic)

0. **Freeze.** `MxDerivedColors.resolve` stops computing: it returns today's resolved values
   as literals per brightness (a snapshot pinned by its existing test), so changing a role's
   value in phase 1 moves no unmigrated consumer, and every later diff is exactly its §4.8
   mapping.
1. **Roles.** `MxSemanticColors` in its new shape with the old members kept for one phase;
   `outline` values; `primaryForeground`; `token_contrast_test.dart` asserting the whole
   §4.3 / §4.8 table (RED first: the new roles do not exist). No consumer moves.
2. **Core consumers.** `AppComponentThemes`, `AppDecorations`, `MasteryRamp`,
   `MxTextStyles`, the status resolver; their tests. `MxDerivedColors` still compiles,
   unused by core.
3. **Shared widgets**, in three groups with their state tests (§4.9) and a preview after
   each group (§6.2): edges and hairlines; brand foreground and focus; containers and the
   alpha tints.
4. **Features** (19 files, the card status model), screen by screen in the order of §4.12's
   risk rows, each with its screen-level check (§6.3).
5. **Delete** `MxDerivedColors`, `derivedColors`, its test, the old extension members and
   the status / errorFill tokens; the guard rule of §6.1 lands with its fixtures.
6. **Goldens and documents.** One `run_goldens.sh --update`, the classified golden review
   (§6.2), `DESIGN.md`, `design.json`, the UI-base spec, the detail files (States and
   Transitions reconciled, §4.12); one `impeccable audit` of the changed system.

### 6.1 The guard rule (R12)

The rule catches the three ways a derived colour was built here, and nothing else:

- `memox.design_token.no_derived_color` (`code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml`),
  `type: regex`, `severity: error`, scope `color_role_surfaces` =
  `lib/features/*/presentation/**`, `lib/shared/**`, `lib/app/**`, `lib/core/theme/**`,
  excluding `lib/core/theme/mx_semantic_colors.dart` (the `ThemeExtension.lerp` body) and
  generated files.
- Patterns, each a rebuild and not colour maths in general:
  - a mix with a constant factor: `\bColor\.lerp\s*\([^;]*,\s*(?:0?\.\d+|1(?:\.0)?|0)\s*\)`
    (`Color.lerp(a, b, t)` with a variable `t`, the animation form, does not match;
    `ColorTween` never matches);
  - a hue / saturation / lightness rewrite of a role: `\bHS[LV]Color\s*\.\s*fromColor\s*\(`
    (no legitimate use exists in `lib/`; a future colour picker would get its own scope row);
  - a tint at a literal or private alpha over a ground: `\bColor\.alphaBlend\s*\(` and
    `\.withValues\(\s*alpha:\s*(?!AppOpacity\.|[A-Za-z_]+\.a\s*\*\s*AppOpacity\.|0\s*[,)])`
    (an alpha that is an `AppOpacity` token, `color.a * AppOpacity.x` for the disabled dim, or
    the literal 0 of a fade's clear end stays allowed: those are the state layers, the scrim,
    the scroll fade and the shadows named in R12).
- Message: a colour is a `ColorScheme` or `MxSemanticColors` role; a foreground or ground is
  never mixed from another role, and an overlay's alpha is an `AppOpacity` token.
- Fixtures under `code-verification-guard-v2/tests/fixtures/derived_color/`: `valid.dart`
  (a `ColorTween`, `Color.lerp(from, to, animation.value)`,
  `ink.withValues(alpha: AppOpacity.pressed)`, `color.withValues(alpha: color.a * AppOpacity.disabled)`,
  `ground.withValues(alpha: 0)`) and `invalid.dart` (`Color.lerp(scheme.primary, scheme.onSurface, 0.25)`,
  `HSLColor.fromColor(scheme.outline)`, `Color.alphaBlend(error.withValues(alpha: 0.08), surface)`,
  `primary.withValues(alpha: _tint)`, one finding per line). A pytest beside
  `test_memox_v8_design_token_guard_rules.py` asserts zero findings on the valid fixture, one
  per line on the invalid one, and zero when the invalid fixture's content is scanned under
  the excluded path (`lib/core/theme/mx_semantic_colors.dart`, the `ThemeExtension.lerp`
  case); the rule joins the ruleset-contract test.

### 6.2 Incremental visual verification (R15)

- **Baseline.** The merge base's goldens are the pre-migration baseline; before phase 1
  they are copied to `.superpowers/sdd/<plan>/baseline/` (git-ignored) so a diff is possible
  while the branch's own goldens are stale.
- **After each shared-widget group (phase 3)** and after each feature (phase 4): the
  group's widget and state tests run (`run_tests.sh` on the named files); a representative
  preview is rendered (the debug gallery section for the group, plus the §4.12 risk rows the
  group touches, light and dark) with a throwaway golden test writing into the workspace,
  and diffed against the baseline with the `golden-compare` skill's renderer. A difference
  that is not in §4.8 is a regression and stops the phase.
- **After phase 6:** every changed golden is classified on the review page as **expected**
  (the diff is a §4.8 mapping, or the focus ring's offset of §4.13 P1, and nothing else
  moved), **unexpected** (anything else:
  layout, a missing edge, a wrong role) or **unresolved** (the reviewer cannot tell from the
  image; rendered larger or re-tested). Unexpected diffs are fixed before the review goes
  to the owner; the page lists each image with its class; the owner approves image by image,
  never a batch, and no `--update` run is accepted without that page.

### 6.3 The gates and their evidence (R16)

| Gate | When | Evidence that must exist |
|---|---|---|
| ROOT CAUSE FIRST | this spec (§3) and any defect met during migration | §3; for a defect, a `systematic-debugging` note with mechanism, `file:line`, the contract broken and the lowest shared owner, in the plan's ledger |
| COMMON FIRST | every task | the fix lives in `lib/core/theme` or the shared widget, never per screen; the status resolver and the containers in `AppDecorations` are the proof; a per-screen colour is a finding |
| CHECK STATE COVERAGE | after phases 3, 4, 6 | a test run per §4.9 cell (`run_tests.sh` output in the ledger) and, per §4.12 row, the golden or the rendered image or the `UNVERIFIED` line |
| CHECK STATE TRANSITIONS | after phases 4 and 6 | the §4.12 transitions exercised by widget tests where a repaint is a risk row (loading → content, error → retry, selection enter / exit, field focus / error, dialog open) and the detail files' Transitions tables reconciled with the code |
| CHECK DEGRADE | after phases 3, 4, 6 | the unchanged consumers of `outline`, `onPrimaryContainer`, `errorContainer` and `inversePrimary` (snackbar, breadcrumb, history rail, dashed note, theme preview) rendered and read; the contrast test green |
| CHECK SIMILAR | after phases 4 and 6 | the grep for `Color.lerp`, `HSLColor`, `withValues(alpha:` and `Color(0x` outside `lib/core/theme` pasted into the ledger with each hit classed (state layer, scrim, fade, shadow, or a finding fixed); the hits known today are the `MxEmptyState` warning / success glyphs at 2.04 and 2.82:1 (closed by the tone-40 roles of §4.3) and the focus ring at 1.41 / 1.90 against every filled button (closed by §4.13 P1) |
| Independent verification | end of branch | the final whole-branch review on a fresh context (Opus, per the hooks) rebuilds the states and transitions from the code and the test runs, not from this spec; the owner's golden review |

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
- The guard rule of §6.1, with its valid and invalid fixtures and its pytest.
- The screen-level checks of §4.12: a widget test per risk row (focus and error on the
  field in a dialog, the selected edge, the four status badges, the three summary heroes,
  the choice tones), light and dark.
- Goldens: regenerated once, reviewed once.

## 8. Rejected and out of scope

- **`primary` at tone 40 / 80** (M3 by the book): rejected by the owner (R1); the brand fill
  stays, hence `primaryForeground`.
- **`surfaceTint` elevation overlay for the hero** (Flutter's `ElevationOverlay`): it
  reproduces today's 5 % tint with an M3 role, but Material 3 retired tint overlays for the
  surface-container roles, and the hero's content would still have no on-colour.
- **Keeping the saturated amber / teal as a fifth member** of each set: that is the derived
  layer under a new name (R4); the sets use M3 tones and the dark theme already did.
- **Splitting the guard rule, the focus-ring owner and the Transitions reconciliation into
  other epics** (independent review 2026-10-08): rejected. The owner asked for the guard
  (R12) and the screen-level coverage (R13) in this spec; the focus ring is a same-cause
  defect, in scope by CLAUDE.md ("fixing same-cause hits is in scope, never scope creep");
  only the pressed-layer label contrast leaves as a register row.
- **Neutral text + coloured dot for status** (no coloured status text): possible, but the
  status foregrounds pass as roles (§4.7) and the approved design reads status in colour.
- Out of scope: `inversePrimary`'s dark value, `secondary` / `tertiary` usage, typography,
  layout, the `memox-api-services` reference, the pressed state layer's transient label
  contrast (§4.13, a register row).
- Found along the way (§4.13), filed as sub-issues of this epic: the rectangular `MxRowInk`
  ring inside a rounded card, the due strip's missing destination label.
