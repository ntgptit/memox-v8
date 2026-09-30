# Whole-app critique 2026-09-30, tone pass: success and warning back in colour — design

Status: draft 2026-09-30 ·
Path: architectural (one token, three shared widgets, five screens) · Owner rulings 2026-09-30 (§2): T1–T8

## 1. Intent

The owner found the app flat and washed out: the success and warning tones no longer read.
An audit of the 475 goldens and of the code that paints status (proposal page, 2026-09-30)
found one main cause and four smaller ones.

- **Main cause.** In light theme `warningInk` is `semantic.onWarning` (#3A2A00), the ink
  *on an amber fill*, borrowed as the amber *text* colour. At 12–14:1 it reads as body text,
  so every "overdue", "wrong", "time is up" and warning glyph looks neutral. Dark theme is
  unaffected (its `warningInk` is the amber itself).
- **Smaller causes.** States that mean "done" or "fine" are drawn neutral, in Indigo, or in
  mastery green, which DESIGN.md keeps for learning progress: a synced Sync screen, a card's
  remembered reviews, an import's ready rows, a fixed log and the success empty state.

Success means:

- every item in §3 is built as written, each pinned by a widget or unit test and by the
  goldens;
- light `warningInk` reads as amber and holds 4.5:1 on every ground it is used on;
- no layout change anywhere; dark theme changes only where §3 says;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review
  page; the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file. No BR or
UC fixes a colour here. DESIGN.md's rules stand and this pass applies them: the Ink Is Not The
Fill, Green Means Progress, and "a right answer is success, never mastery".

## 2. Owner rulings (2026-09-30)

- **T1.** Light `warningInk` is #895806 (amber's hue at 28% lightness; option B on the
  proposal page). Dark keeps the amber.
- **T2.** A banner's title takes its tone's ink: warning in `warningInk`, danger in `error`.
  The message keeps its current style.
- **T3.** Screen 27: when sync is settled (§3.4), the "Waiting to sync" row shows a success
  check at its end.
- **T4.** Screen 23: when sync is settled, the Sync row's icon tile is the success tone.
  `MxSettingsRow` gains an `iconTone` for it.
- **T5.** Screen 10: a review that did not lapse carries the success tone; a lapse stays
  warning; relearning stays neutral.
- **T6.** `MxBadge` gains a success tone. Screen 11's ready chip and ready-row mark use it.
- **T7.** Screen 28's Fixed status and `MxEmptyState`'s success tone draw in success, not
  mastery.
- **T8.** 3c-2's R6 stands: Recall and Fill move to Indigo there. The Study home workload card
  keeps its plain ground (3c-1 R2). Neither is part of this pass.

## 3. Items

### 3.1 Token: `warningInk` (T1)

- `MxDerivedColors.warningInk` is `#895806` in light and `semantic.warning` in dark.
  `semantic.onWarning` stays #3A2A00: it is still the ink on an amber fill (`MxButton`
  warning tone).
- Measured contrast of #895806: 5.76 on the page, 6.07 on a card, 5.28 on the warning tint
  over the page and 5.54 over a card. A test pins 4.5:1 or more on each of those four grounds.
- Every consumer follows without code changes (badge, field message, icon tile, banner glyph,
  workload line, outcome tile, study entry note, Recall and Fill status, countdown bar, import
  row, tag rename, summary facts).

### 3.2 `MxInlineBanner` title (T2)

- The bold title line is drawn in the banner's ink: `warningInk` for warning, `error` for
  danger. Measured contrast: `error` on the danger tint is 4.91 over the page and 5.16 over a
  card in light, and 6.79 in dark.
- A banner without a title is unchanged: its lead message keeps `onSurface`.

### 3.3 `MxBadge` success tone (T6)

- `MxBadgeTone.success`: the tint is `semantic.success` at the badge's 12%, and the label and
  glyph use `successInk` (5.10 over the page and 5.35 over a card on that tint in light).
- DESIGN.md's badge list reads: primary, mastery, success, warning, danger, neutral.
  Mastery stays for learning progress only.

### 3.4 Sync settled (T3, T4)

- One predicate in the sync labels support file: sync is **settled** when something has
  synced (`lastSuccessAt` set), nothing waits (`pendingCount == 0`), nothing was refused
  (`rejectedCount == 0`) and the last attempt did not fail (`lastFailure == null`).
- **27 Sync:** when settled, the "Waiting to sync" row's trailing slot holds a check glyph in
  `successInk`, excluded from semantics, since the subtitle "Nothing waiting" already says it.
  Any other state shows no glyph.
- **23 Settings:** when settled, the Sync row's icon tile uses `MxIconTileTone.success`;
  otherwise it stays tinted.
- **`MxSettingsRow.iconTone`:** an `MxIconTileTone` defaulting to `tinted` and passed to the
  lead tile. It is the only new parameter; a disabled row still dims the tile.

### 3.5 Screen 10, card history (T5)

- The kind badge's tone: a lapse (Forgotten, Again) is warning, relearning is neutral, and
  every other review is success (it was primary).

### 3.6 Screen 11, import preview (T6)

- The "Ready · n" chip uses `MxBadgeTone.success` (it was mastery).
- A ready row's check mark uses `successInk` (it was the mastery fill).
- The step tracker's finished steps keep mastery: they count progress through the flow.

### 3.7 Screen 28 and `MxEmptyState` (T7)

- `monitoringStatusTone(LogStatus.fixed)` is `MxBadgeTone.success`.
- `MxEmptyState`'s success tone tints with `semantic.success` and draws its glyph in
  `successInk` (it tinted and inked with the mastery fill). This reaches the caught-up states
  of screens 13 and 14, the import result (11) and Monitoring's empty lists (28).

## 4. Verification

- A test written first for each behaviour: the `warningInk` value and its four contrast
  ratios; the banner title colour per tone and a titleless banner unchanged; the success
  badge's tint and ink; the settled predicate across its five cases (settled, never synced,
  pending, refused, failed); 27's check shown only when settled; 23's tile tone per state;
  `MxSettingsRow.iconTone` passed to the tile; 10's badge tone per kind; 11's chip and mark;
  28's Fixed tone; `MxEmptyState`'s success tint and ink.
- `test/core/theme/mx_derived_colors_test.dart` changes its `warningInk` expectation;
  `token_contrast_test.dart` stays green.
- Goldens regenerated in the Linux container (about 52 light goldens from §3.1 plus those for
  §3.2 to §3.7, in both themes where the tone changes in dark); the owner reviews them on a
  `golden-compare` page before merge.
- The gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `TZ=UTC flutter test --tags golden`.

## 5. Records

- DESIGN.md: the `warning-ink` token (#895806 light) and the Warning Amber line; `MxBadge`
  tones; `MxInlineBanner` title ink; `MxSettingsRow.iconTone`; `MxEmptyState` success tone.
- Detail files 10, 11, 23, 27 and 28, each with a ruling line for its change.
- `docs/wbs_FE.md`: a line FE-D11 for the tone pass.

## 6. Out of scope

- `MxEmptyState`'s warning glyph, which still draws the amber fill on its tint (an Ink rule
  gap noted for 3d).
- A tone for failed or refused sync on screen 23's tile.
- 3c-2, 3d and part 2, and T8's two held decisions.
