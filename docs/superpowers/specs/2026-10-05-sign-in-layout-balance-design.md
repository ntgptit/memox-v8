# Sign-in flow layout balance (field edge, even pairs, spacing) — design

Status: approved by the owner 2026-10-05 (items L1–L5 in chat) ·
Path: architectural (two shared widgets gain an opt-in, the transition layer's stopped states) ·
Linear: DEV-166 (the field edge, sign-in part) · branch `claude/nifty-maxwell-nz5nl3`, PR 208 ·
Follows `2026-10-05-sign-in-flow-redesign-design.md`.

## 1. Intent

The owner asked for the field edge (DEV-166), side-by-side buttons of one width and height,
and a more balanced layout, **for the sign-in function only**. The goldens of 29 · 30 · 31,
the merge sheet, the confirm dialogs and the transition layer show:

- the email field's resting edge is the ghost border, 1.19:1 light and 1.17:1 dark, so the
  field nearly vanishes, beside the code slots whose `outline` edge holds 3.44:1;
- a dialog or sheet pair splits 10:13 (`MxSheetActions`), so Cancel is narrower than the
  confirm ("Lose 2 changes?", the merge sheet);
- "Continue without this account?" leaves about 34 dp between its danger banner and the
  actions, where a dialog without a note leaves about 20 dp;
- the merge sheet's title starts 20 dp in, its option rows and banner 16 dp;
- a stopped layer (offline, error, sign-out offline) keeps its actions in the body, centred
  with the banner, where every other sign-in screen holds its actions in an `MxFooterBar`.

Button heights already match (48 dp); nothing changes there.

Success means:

- every item in §2 is built as written, pinned by a widget test or a golden;
- no screen outside the sign-in function changes, and no golden outside it changes
  (shared widgets change only behind an opt-in that defaults to today's behaviour);
- goldens regenerated in the Linux container and reviewed on a golden review page; the gate
  passes.

## 2. Items (owner rulings L1–L5)

**L1 · A strong field edge, opt-in.** `MxTextField` gains `hasStrongEdge` (default false).
When true, the resting edge (enabled, no error) is 1 dp `outline` instead of the theme's ghost
border: 3.44:1 on the page and 3.29:1 on the field fill in light, 3.75:1 and 3.02:1 in dark, the
code slots' edge. Focus (2 dp primary ink), error and disabled edges are unchanged. The sign-in
email field (`SignInFormWidget`: screen 30, re-auth, the layer's target) sets it. DEV-166 stays
open for the rest of the app.

**L2 · Even pairs, opt-in.** `MxSheetActions` gains `isEvenSplit` (default false). When true,
the pair's shares are 1:1. When a label does not fit its half on one line, the pair stacks full
width, Cancel on top, as `MxActionPair` already does. `confirmAccountStep` gains the same
named parameter, passed through. Set by the sign-in function's confirms only:
`confirmUnsentLoss` (30, 31), "Continue without this account?" (30 re-auth), and the merge
sheet. Screen 32's confirms keep 10:13.

**L3 · One gap above the actions.** In the account confirm dialog, the space between the last
content block (the body, or the note under it) and the actions is the same with a note as
without one (about 20 dp, the dialog's `card` padding). The fix stays in the account code. If
the cause is in the shared `MxDialog`, the implementer reports it and changes nothing there.

**L4 · The merge sheet's one edge.** The sheet title's horizontal padding becomes `gutter`
(16), the edge its option rows and banner already use.

**L5 · A stopped layer keeps its actions in the footer.** When the layer has stopped
(network error, other error, sign-out stopped offline, stuck), the actions move into an
`MxFooterBar`:

- **Footer content:** Retry (primary) and, for a sign-out stopped offline, "Sign out now and
  lose {n} changes" (`dangerSoft`) under it.
- **Body:** the banner, and its message, stays centred in the body.
- **Running state:** the spinner, step and "Nothing is lost…" line stay centred with no
  footer.
- **Cancel:** stays at the top.
- **Ruling F1:** this amends F1 (30's detail file). Content stays centred, and the stopped
  states' actions sit in the footer.

## 3. Documents

- **`DESIGN.md`:**
  - Inputs gains `hasStrongEdge` (the `outline` resting edge, sign-in today, DEV-166 for the
    rest).
  - `MxSheetActions` gains `isEvenSplit` (1:1, the sign-in confirms).
- **Detail files:**
  - 30 records L2–L5 (the F1 amendment included).
  - 31 records L2 for the loss dialog.
- **Linear:** DEV-166 gets a comment saying the sign-in part is done in PR 208 and the
  app-wide part stays open.

## 4. Testing

**Widget tests**
- `hasStrongEdge` paints the `outline` resting edge, and its default paints the ghost border.
- `isEvenSplit` gives two equal widths, and stacks a long label.
- The sign-in confirms pass `isEvenSplit`, and screen 32's do not.
- The dialog's gap above the actions is equal with and without a note.
- The merge sheet title sits 16 dp in, at the option rows' edge.
- A stopped layer's Retry and sign-out-now live in the `MxFooterBar`. The running layer has
  no footer.

**Contrast test**
- `outline` on the field fill (`surfaceContainerLow`) is already pinned as the code slot
  pair, so it needs no new row.

**Goldens**
- Expected to change: `sign_in_*`, `layer_target_*`, `layer_offline_*`,
  `layer_sign_out_offline_*`, `layer_stuck_*`, `merge_sheet_*`, `code_*` (the loss dialog
  only if a golden shows it), and `input_widgets` only if a new case is added.
- Any other changed golden is a regression.

**Gate**
- `dod_check.sh`.

## 5. Out of scope

- The field edge and pair split for the rest of the app (DEV-166, the owner's later call).
- Screen 32's dialogs and layer flows that start there keep their footers as they are,
  except that the layer's stopped states are shared code. L5 applies to them too, because the
  layer is one widget.
