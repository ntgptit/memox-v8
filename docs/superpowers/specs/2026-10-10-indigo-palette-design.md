# Indigo palette: explicit colour tokens, no derived inks

Date: 2026-10-10 · Owner decisions in the brainstorm of 2026-10-10 · Status: draft for owner review

## 1. Goal

Replace the Tokyo Pure Light / Tokyo Nebula palette with the reference palette the
owner supplied (a study-app style guide, light and dark), and remove the derived
**ink** mechanism: no colour in the app is computed any more by pulling a role
toward `onSurface` or by laying a role over a ground at an alpha. Every colour a
widget paints is a literal token, one value per theme.

The two themes are renamed **Indigo Day** (light) and **Indigo Night** (dark).
The reference's brand is never named in the repository.

## 2. Owner decisions (2026-10-10)

| # | Decision |
|---|---|
| D1 | Scope is colour only. Typography (Plus Jakarta Sans and its seven roles), radii, border widths, spacing, sizes and elevation alphas stay as they are. |
| D2 | "Remove ink" means removing the derivation: `primaryInk`, `warningInk`, `dangerInk`, `successInk`, `status{New,Learning,Reviewing,Mastered}Ink`, `MasteryRamp.ink`, `primaryInkOf`. Each text or glyph role reads its own literal token. |
| D3 | The reference values are used exactly, even where a pair falls below WCAG AA. The contrast test keeps every pair that passes and records each pair that does not as a named exception with its measured ratio (§7). |
| D4 | Fully explicit (approach B): `MxDerivedColors` is deleted. Soft grounds (tints) are the reference's `/50` tokens in **both** themes, so in Indigo Night a banner, a tinted badge or an outcome tile is a light box with dark text, as the reference's stat boxes are. |
| D5 | The token mapping of §4 and §5 was approved as presented. |
| D6 | Theme names: Indigo Day / Indigo Night. |

## 3. What stays a derivation

Interaction states are not palette colours and keep their alphas:
pressed overlay (`AppOpacity.pressed`), disabled (`AppOpacity.disabled`),
muted (`AppOpacity.muted`), the scrim's opacity, shadow alphas, the scroll fade's
transparent end, the FAB's pressed overlay and the filter chip's resting
count opacity. Nothing else may call
`withValues(alpha:)`, `Color.lerp` or `Color.alphaBlend` on a palette colour
outside `lib/core/theme/` lerp methods.

## 4. ColorScheme

Seed: `#4255FF` (only the `*Fixed` family, which Material requires and MemoX
never reads, is still seed-generated). Every other role is set explicitly.

| Role | Indigo Day | Indigo Night | Reference token | Used for |
|---|---|---|---|---|
| `primary` | `#4255FF` | `#4255FF` | primary/500 | primary fill, FAB, selected chip, progress fill |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | text/on-primary | |
| `primaryContainer` | `#EDEFFF` | `#14125C` | primary/50 · bg/selected | hero card ground (replaces `surfaceHero`), selected ground |
| `onPrimaryContainer` | `#4255FF` | `#EDEFFF` | | |
| `secondary` / `onSecondary` | `#586380` / `#FFFFFF` | `#586380` / `#F6F7FB` | neutral/500 | not read today |
| `secondaryContainer` / `on…` | `#EDEFF4` / `#2E3856` | `#2E3856` / `#D9DDE8` | | not read today |
| `tertiary` / `onTertiary` | `#9C63FF` / `#FFFFFF` | `#9C63FF` / `#FFFFFF` | accent/purple | not read today |
| `tertiaryContainer` / `on…` | `#FAA6FF` / `#282E3E` | `#FAA6FF` / `#282E3E` | accent/pink | not read today |
| `error` | `#B00020` | `#FC3C60` | danger/700 · error/strong | error text, glyph and field edge (replaces `dangerInk`) |
| `onError` | `#FFFFFF` | `#FFFFFF` | | |
| `errorContainer` / `on…` | `#FFE8D8` / `#B00020` | `#FFE8D8` / `#B00020` | danger/50 | |
| `surface` | `#FFFFFF` | `#0A092D` | bg/container | page, app bar, bottom bar |
| `surfaceDim` | `#EDEFF4` | `#0A092D` | | |
| `surfaceBright` | `#FFFFFF` | `#2E3856` | | |
| `surfaceContainerLowest` | `#FFFFFF` | `#202040` | bg/card | card, row, **dialog and sheet** |
| `surfaceContainerLow` | `#F6F7FB` | `#2E3856` | bg/surface | field fill, track, recessed face, nav rail |
| `surfaceContainer` | `#F6F7FB` | `#2E3856` | bg/surface | secondary button, chips, segmented tray, stepper |
| `surfaceContainerHigh` | `#EDEFF4` | `#282E3E` | bg/hover | skeleton, neutral muted fills |
| `surfaceContainerHighest` | `#D9DDE8` | `#586380` | border/strong | |
| `onSurface` | `#282E3E` | `#F6F7FB` | text/primary | |
| `onSurfaceVariant` | `#586380` | `#D9DDE8` | text/secondary | |
| `outline` | `#939BB4` | `#586380` | neutral/400 · 500 | every control edge at rest (replaces `outlineEdge`) |
| `outlineVariant` | `#D9DDE8` | `#586380` | border/strong | dashed note, strong rules |
| `inverseSurface` | `#1A1D28` | `#EDEFF4` | toast | snackbar, tooltip — no longer invariant |
| `onInverseSurface` | `#F6F7FB` | `#282E3E` | | |
| `inversePrimary` | `#F6F7FB` | `#586380` | toast action | snackbar action |
| `scrim` | `#010110` | `#010110` | bg/overlay | drawn at 56 % (was 45 %) |
| `shadow` | `#282E3E` | `#282E3E` | elevation tint | |

Dialogs and bottom sheets move from `surfaceContainerHigh` to
`surfaceContainerLowest` (`app_component_themes.dart`), since the reference's
dialog is bg/card. `surfaceContainerHigh` becomes the neutral muted fill.

## 5. MxSemanticColors

`MxSemanticColors` becomes the one home of every colour Material has no role
for. Fields keep `copyWith` and `lerp`.

### 5.1 Fills and status (existing fields, new values)

| Field | Indigo Day | Indigo Night | Reference |
|---|---|---|---|
| `mastery` | `#18AE79` | `#18AE79` | success/500 |
| `onMastery` | `#FFFFFF` | `#FFFFFF` | |
| `success` | `#12815A` | `#59E8B5` | success/700 · bright |
| `warning` | `#FFCD1F` | `#FFCD1F` | premium/500 |
| `onWarning` | `#282E3E` | `#282E3E` | text/on-yellow |
| `statusNew` | `#939BB4` | `#586380` | neutral |
| `statusLearning` | `#FF983A` | `#FF983A` | learning/500 |
| `statusReviewing` | `#4255FF` | `#4255FF` | primary/500 |
| `statusMastered` | `#18AE79` | `#18AE79` | success/500 |
| `errorFill` | `#B00020` | `#B00020` | danger/700 |
| `onErrorFill` | `#FFFFFF` | `#FFFFFF` | |
| `streak` | `#F6406C` | `#F6406C` | trending |

### 5.2 Text, edge and track (new fields)

| Field | Indigo Day | Indigo Night | Reference | Replaces |
|---|---|---|---|---|
| `primaryText` | `#4255FF` | `#7583FF` | text/link | `primaryInk` as text and glyph |
| `masteryText` | `#12815A` | `#59E8B5` | success/700 · bright | `statusMasteredInk` |
| `learningText` | `#CC4E00` | `#FF983A` | learning/700 · 500 | `statusLearningInk` |
| `warningText` | `#997700` | `#FFCD1F` | hint icon · premium/500 | `warningInk` |
| `focusRing` | `#A8B1FF` | `#A8B1FF` | primary/300 | `primaryInk` as focus ring |
| `border` | `#EDEFF4` | `#282E3E` | border/default | `ghostBorder` |
| `primaryTrack` | `#DBDFFF` | `#DBDFFF` | primary/100 | toggle track on |
| `neutralTrack` | `#939BB4` | `#939BB4` | neutral/400 | toggle track off |

`statusReviewingInk` → `primaryText`; `statusNewInk` → `onSurfaceVariant` on a
plain ground; `successInk` → `success`; `dangerInk` → `error` on a plain ground,
`onDangerSoft` on the danger ground.

### 5.3 Soft grounds (new fields, same value in both themes per D4)

| Family | Soft | Border | Text on soft |
|---|---|---|---|
| primary | `primarySoft` `#EDEFFF` | — | `onPrimarySoft` `#4255FF` |
| success / mastery | `successSoft` `#E6FCF4` | `successBorder` `#98F1D1` | `onSuccessSoft` `#12815A` |
| learning | `learningSoft` `#FFF6EF` | `learningBorder` `#FFC38C` | `onLearningSoft` `#CC4E00` |
| warning | `warningSoft` `#FFEDAB` | `warningBorder` `#FFDC62` | `onWarningSoft` `#997700` |
| danger | `dangerSoft` `#FFE8D8` | `dangerBorder` `#FFC38C` | `onDangerSoft` `#B00020` |
| neutral | `neutralSoft` Day `#EDEFFF` · Night `#586380` | — | `onNeutralSoft` Day `#2E3856` · Night `#F6F7FB` |

`onSoft` (`#282E3E`, both themes) is body text laid on any light soft ground
(a banner message, an outcome tile's text), since that ground is light in
Indigo Night too. The reference defines no danger border; `dangerBorder` borrows
the learning family's `#FFC38C`, the peach edge of the same peach ground.

## 6. Code changes

### 6.1 Theme layer (`lib/core/theme/`)

- `app_color_schemes.dart`: the two schemes of §4; doc comment names Indigo Day
  and Indigo Night.
- `mx_semantic_colors.dart`: the fields and values of §5.
- `mx_derived_colors.dart`: deleted, with its test.
- `theme_context.dart`: `derivedColors` and its `Expando` removed;
  `textStyles` passes the semantic colours.
- `mx_text_styles.dart`: takes `MxSemanticColors`; `_primaryInk` becomes
  `semantic.primaryText`.
- `app_component_themes.dart`: field edges rest on `outline`, focus on
  `focusRing`, ghost edges on `border`; text and outline buttons read
  `primaryText`; dialog and sheet grounds `surfaceContainerLowest`.
- `app_decorations.dart`: every builder takes `MxSemanticColors` in place of
  `MxDerivedColors`; `heroCard` fills `primaryContainer`; warning, success and
  danger cards and the study choice tones fill their soft token outright (no
  `alphaBlend`); `studyChoiceInk` is renamed `studyChoiceForeground` and returns
  `onSuccessSoft` / `onDangerSoft` on the right / wrong grounds.
- `mastery_ramp.dart`: `fill(semantic, fraction)` returns `statusLearning`,
  `statusReviewing`, `statusMastered`; `ink` is renamed `label(semantic,
  fraction)` and returns `learningText`, `primaryText`, `masteryText`.
- `app_effects.dart`: scrim opacity 0.56.

### 6.2 Widgets that tinted a role locally

Each reads a soft token in place of `role.withValues(alpha: …)`:
`MxBadge`, `MxStatusBadge`, `MxIconTile`, `MxEmptyState` (tile),
`MxStudyTopBar` (mode badge), `MxOutcomeTile`, `MxActionSheetCommandRow` (tile),
`card_removable_tag_chip_widget`, `card_schedule_widget` (past bars read
`primaryTrack`). Text on those grounds reads the matching `on…Soft`
token, and neutral body text on them reads `onSoft`.

`MxInlineBanner`, `MxFloatingNotice`, `MxErrorState`, `MxOutcomeTile` and
`MxCard`'s toned variants paint on light soft grounds in both themes, so their
title reads `on…Soft` and their message `onSoft`.

`MxToggle`: on — track `primaryTrack`, thumb `primary`; off — track
`neutralTrack`, thumb `onPrimary` (`#FFFFFF`); focus `focusRing`.

### 6.3 Every other consumer

The remaining reads of `context.derivedColors.*` (about 53 files in `lib/`,
listed by `grep -rl "derivedColors\|MxDerivedColors\|primaryInkOf" lib`) move to
the token that replaces them (§5.2). No consumer keeps a local colour constant.

### 6.4 Vocabulary

Colour parameters and locals named `ink` or `…Ink` (`ink:` in
`AppButtonStyle`, `accentInk`, `titleInk`, `studyChoiceInk`, …) are renamed
`foreground` / `…Foreground`. Material's splash vocabulary (`InkWell`, `Ink`,
`MxRowInk`, `AppSize.iconButtonInk`) is not a colour and stays.

## 7. Tests

- `test/core/theme/mx_derived_colors_test.dart`: deleted.
- `app_color_schemes_test.dart`, `mx_semantic_colors_test.dart`: assert every
  value of §4 and §5 in both themes.
- `token_contrast_test.dart`: the pairs it checks today are re-expressed on the
  new tokens. A pair at or above its floor stays an assertion. A pair below
  (D3) moves to an `_exceptions` table with its name, its ratio rounded to two
  decimals and "owner 2026-10-10"; the test asserts that each exception still
  measures what the table says, so a palette edit that worsens a pair, or one
  that newly fails, turns the test red.
- `mastery_ramp_test.dart`: `fill` and `label` per band.
- Every test reading `primaryInkOf`, `derivedColors` or an `*Ink` (about 59
  files) reads the new token. No assertion is removed or weakened beyond the
  contrast exceptions of D3.
- Goldens: every golden is regenerated in the Linux container
  (`run_goldens.sh --update`); the owner gets the `golden-compare` page before
  approval.

## 8. Documentation

- `DESIGN.md`: frontmatter colours to §4 and §5 (Indigo Day values); the
  description and Overview name Indigo Day and Indigo Night; the Colors section
  is rewritten on the new tokens; **The Ink Is Not The Fill Rule** is replaced
  by **The Text Token Rule** (text and glyphs read a text token —
  `onSurface`, `onSurfaceVariant`, `primaryText`, `masteryText`, `learningText`,
  `warningText`, `success`, `error`, an `on…Soft` — never a fill);
  **The Contrast Floor Rule** becomes "the palette is fixed; the pairs below the
  floor are the listed exceptions (owner 2026-10-10)"; component paragraphs that
  name an ink are updated.
- `.impeccable/design.json`: theme names and colour metadata.
- Screen detail files that name an ink (`01-deck-list`, `02-review-algorithm`,
  `18-study-guess`, `19-study-recall`, `25-theme`): the token that replaces it.

## 9. Risks

- **Night shadows.** The reference tints shadows `#282E3E`, lighter than the
  Night page. With today's dark shadow alphas (36–50 %) a floating surface casts
  a faint light halo. Elevation is out of scope (D1); the golden review shows
  it, and the owner may rule to keep black for Night shadows.
- **Light boxes in Night (D4).** Banners, outcome tiles, tinted badges and
  study right / wrong tiles turn light in Indigo Night.
- **Contrast exceptions (D3).** Expected: Day `#939BB4` placeholder and control
  edges, Day `#CC4E00` / `#997700` text on `#F6F7FB`, Night `#7583FF` on
  `#2E3856`. The test lists the exact set.
- **Blast radius.** About 53 lib files, 59 test files and every golden.

## 10. Out of scope

Typography, radii, border widths, spacing, sizes, elevation alphas, component
geometry (pill buttons, 2px borders), and the reference's study-mode behaviour.

## 11. Verification

`dod_check.sh` green; goldens regenerated and reviewed through
`golden-compare`; one `impeccable audit` of the regenerated goldens against the
updated `DESIGN.md`; the final whole-branch review.
