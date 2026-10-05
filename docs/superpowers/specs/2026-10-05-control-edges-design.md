# Control edges that hold 3:1 app-wide (fields, outline buttons, dialog actions) — design

Status: owner rulings 2026-10-05 (chat), spec awaiting review ·
Path: architectural (a theme default, a derived token, two shared widgets, `DESIGN.md`) ·
Linear: DEV-166 · branch `claude/dev-166-control-edges` (on PR 208's head; its PR merges after 208) ·
Follows `2026-10-05-sign-in-layout-balance-design.md` (L1, L2).

## 1. Intent

**The problem.** The resting edge of every edged `MxTextField` is the Ghost Border (primary at
14 % light, 16 % dark). It holds about 1.19:1 on the page, so a field nearly vanishes. That
fails WCAG 2.2 SC 1.4.11 (3:1 for the boundary of an input) and DESIGN.md's Contrast Floor
Rule. PR 208 fixed the sign-in email field alone, behind the opt-in `hasStrongEdge`. DEV-166
owns the rest of the app, and the same audit left two P3 items with it:

- **The outline button's edge.** In light this is `outline-variant` at about 1.5:1, fainter
  than the field beside it on screen 30.
- **The dialog's action pair.** It is inset 16 dp, while the dialog's title and body are inset
  20 dp, so the buttons do not line up with the text above them.

**Success means:**

- Every edged input's resting edge and the outline button's edge hold ≥3:1 on every ground
  they sit on (page, field fill, card, sheet and dialog) in both themes. The contrast test
  pins this; its new rows fail before the change and pass after it.
- A dialog's action pair lines up with its text.
- `DESIGN.md` says so.
- The goldens are regenerated in the Linux container and reviewed on a golden review page,
  and the gate passes.

## 2. Owner rulings (2026-10-05)

- **E1 · Branch.** The work goes on a new branch with its own PR, cut from PR 208's head (it
  removes 208's opt-in). It merges after 208.
- **E2 · Scope of the field edge.** Every edged variant takes the strong edge: form, detail,
  meaning and term. The bare study field is unchanged.
- **E3 · Outline button.** Its edge holds 3:1 in light too.
- **E4 · Dialog actions.** The pair is inset 20 dp at the sides and the bottom. The 16 dp above
  it stays, so the L3 gap is unchanged. Sheets keep 16 dp.
- **E5 · One edge token.** Plain `outline` fails 3:1 on the sheet and dialog ground
  (`surface-container-high`): 2.92:1 light, 2.25:1 dark. So fields, the outline button and the
  six code slots all take the derived **Outline Edge**, retuned to hold everywhere.

## 3. Design

### 3.1 Outline Edge, retuned (`MxDerivedColors.outlineEdge`)

| Theme | Before | After | Page | Field fill (low) | Lowest | Sheet / dialog (high) |
|---|---|---|---|---|---|---|
| Light | `outline-variant` #C5CBE3 (≈1.5:1) | `outline` pulled 10 % toward `on-surface`, ≈ #717AA0 | 3.99 | 3.82 | 4.21 | 3.40 |
| Dark | `outline` pulled 25 % toward `on-surface`, ≈ #7C8AC1 | unchanged | 5.67 | 4.57 | 5.06 | 3.40 |

The light value replaces owner ruling R7's "light keeps `outline-variant`" (critique
2026-09-30 part 1). The warning ground is asserted too. If the light step fails 3:1 there, the
implementer raises the 10 % to the least value that holds, and records the result.

### 3.2 Fields (`AppComponentThemes.fields`, `MxTextField`)

**Resting edge.** The theme's `border` and `enabledBorder` become 1 dp `outlineEdge`, so every
`TextField` the theme carries gets it. This covers the form, detail, meaning and term variants,
and the 52 / 48 / 76 boxes.

**States.**

| State | Edge |
|---|---|
| Focus | 2 dp primary ink, unchanged |
| Error | `error`, unchanged |
| Disabled | Ghost Border, unchanged; a disabled control is exempt from 1.4.11 |

**Study field.** It stays bare: no edge.

**Removing the opt-in.** `MxTextField.hasStrongEdge` and its `_strongEdge` helper go, because
the default now does what they did. The sign-in email field drops the argument. Its edge
becomes `outlineEdge` (3.99:1 light, 5.67:1 dark, up from 3.44 / 3.75), the same as every
other field.

### 3.3 Code slots (`MxCodeField`)

The resting slot edge becomes `outlineEdge` instead of `outline`, the same edge as the fields.
The next-slot 2 dp primary ink and the error edge are unchanged. This changes goldens the owner
approved in PR 208 (`code_*`, `mx_text_field_code_*`): the slots get a slightly stronger edge,
and nothing else moves.

### 3.4 Outline button (`MxButton`, outline tone)

The edge is already `outlineEdge`, so §3.1 alone changes it. That is a light-only change
("Continue with Google", "Continue with email", Cancel in a dialog pair, and every outline
button). The disabled outline button keeps its dimmed edge (0.38).

### 3.5 Dialog actions (`MxSheetActions`, dialog form)

**Insets.** The dialog form's padding goes from 16 all round to 16 on top and 20 at the start,
end and bottom (`gutter` on top, `card` elsewhere).

**Effects.**
- The pair lines up with the title and body (20).
- Its bottom matches the dialog's top inset (20).
- The gap above it stays 16 (L3).

**Unchanged.**
- The sheet form (8 / 16 / 16 under a ghost rule).
- `MxSheetActions.custom` (a single OK, Trash's footer), which uses the same dialog form and
  takes the same insets.

### 3.6 What stays on Ghost Border

Ghost Border stays the everyday hairline:
- cards, list sections and dividers;
- the sheet's action rule;
- a disabled field.

None of these is a control boundary that 1.4.11 asks to hold 3:1.

Out of scope, each on `outline` with a 2 dp stroke against its own ground:
- toggles;
- checkboxes;
- option rows.

## 4. Documents

- **`DESIGN.md`:**
  - **Colors.** The Outline Edge line takes the §3.1 values. Ghost Border is no longer the
    field's edge.
  - **Inputs.** Every edged variant rests on Outline Edge. The `hasStrongEdge` sentence goes,
    and the code variant's edge is Outline Edge.
  - **MxButton.** The outline tone's edge holds 3:1 in both themes.
  - **MxSheetActions / MxDialog.** The dialog form is inset 16 above and 20 at the sides and
    bottom.
- **Detail files.** Only where one names the field's or the dialog's edge or inset. The
  implementer greps for "ghost" and "16" next to "field" and "dialog actions" and fixes what
  it finds.
- **Linear.** DEV-166 gets the PR, and is Done on merge.

## 5. Testing

**Contrast test (`token_contrast_test.dart`).**
- New rows: the outline edge on the page, the field fill, the lowest ground, the sheet and the
  warning ground, in both themes. The light rows fail today (about 1.5:1); the dark rows that
  exist stay.

The code-slot rows move from `outline` to `outlineEdge` and gain the sheet row.

**Theme test (`app_component_themes_test.dart`).** Pins the fields theme:
- the enabled and resting border is `outlineEdge`;
- disabled is the Ghost Border;
- focus is primary ink.

**Widget tests.**
- `MxTextField`: a form, meaning and term field rest on `outlineEdge`; a study field has no
  edge; the `hasStrongEdge` tests go.
- `MxCodeField`: the resting slot edge is `outlineEdge`.
- `MxSheetActions`: in its dialog form, the pair sits 20 from the dialog's start, end and bottom
  and 16 under the content; the sheet form is unchanged.

**Goldens.** Expected to change:
- every golden that shows an edged field, an outline button in light, or a dialog's action
  pair;
- the sign-in and code goldens of PR 208.

Any golden whose diff shows something other than a field edge, an outline-button edge, or a
dialog pair's 4 dp shift is a regression. The golden review page groups them by those three
causes.

**Gate.** `dod_check.sh`, then `run_goldens.sh --update` and the golden review.

## 6. Out of scope

- Toggles, checkboxes and option rows (§3.6).
- Sheet action insets.
- Any change to the field fill, its focus fill, or the error and focus edges.
- Re-running the Impeccable critique of each screen. One `impeccable audit` of the changed
  goldens ends the work, per CLAUDE.md.
