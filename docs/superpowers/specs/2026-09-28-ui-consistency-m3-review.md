# UI consistency review against Material 3 — findings and rulings

**Date:** 2026-09-28 · **Run:** workflow `review-verify` `wf_799af2b3-dce` (34 units, 144 agents)

## Rubric

Cross-app design consistency measured against Material 3. The UI kit and the
handoff images were **not** a source: the owner ruled that parts of the kit are
wrong. Aesthetics were out of scope. Dimensions: text inputs, buttons, sizes and
touch targets, gaps and spacing (AppSpacing), typography roles, colour and shape
tokens, component choice (the same Mx widget for the same pattern).

A finding counts only if it names `file:line` evidence and a sibling screen that
does the same role differently. Every finding was re-verified by two independent
passes. A deviation recorded in UI-base §9 or in a doc comment was refuted.

## Coverage

Units: the 28 screens of `docs/shared/ui/screen-handoff/00-index.md` (08 and 09
share the editor; 01 and 07 split out their overlays; the study session shell
went with 16), plus five cross-cuts: dialogs, bottom sheets,
bars/banners/empty/error, theme and tokens, the Mx library.

Result: 55 findings → 11 confirmed, 16 revised target, 28 refuted → **23 defects
after de-duplication**. Screens with no defect left: 03, 04, 05, 08/09, 10, 13,
14, 20, 21, 27. Theme/tokens (X4) and the Mx library (X5): every finding refuted.

## Defects

Key: **S** = needs a `lib/shared/` change (owner approved all four).

### A. Bottom sheets
- **A1 (P1)** `card_flag_sheet_widget.dart` is the only MxBottomSheet without a
  header. Add the shared header (`fromLTRB(card, micro, card, grouped)` +
  `compactTitle`), title `cardFlag`.
- **A2 (P1)** `deck_level_query_sheets_widget.dart`: header bottom is
  `AppSpacing.control`; seven sibling sheets use `grouped`. The "Sort by" overline
  is a raw `Text`; `card_export_sheet_widget.dart` uses `MxListSectionHeader`.
- **A3 (P1)** Same sheet: footer is a raw `Padding(all: gutter)`; every other sheet
  footer goes through `MxSheetActions(isInSheet: true)`.
- **A4 (P1)** Same sheet: the due-only row sits at `AppSpacing.card` (20) while the
  `MxOptionRow`s above it sit at 16. Use `MxSettingsRow` + `MxToggle`.
- **A5 (P1, S)** Card move, deck move and Trash restore drop their title while
  loading; the tag-filter sheet keeps it. Add a loading form to
  `MxDeckPickerSheet`.

### B. Dialogs
- **B1 (P1)** Four confirm dialogs force `MxDialogWidth.medium` (320); seven use the
  340 default. Remove the override in card discard, deck discard, study exit and
  settings reset.
- **B2 (P1)** `deck_reset_dialog_widget.dart` swaps its confirm label to "Resetting…"
  with no spinner and passes a no-op cancel. Use `isConfirmLoading` and a null
  `onCancel`, as the deck delete and starter algorithm confirms do.
- **B3 (P2)** `settings_reset_dialog_widget.dart` hand-copies `MxSheetActions`,
  including its 10/13 shares. Use the default constructor.

### C. Buttons
- **C1 (P1)** Export sheet's terminal "Close" is outline; import's is primary. Drop
  the outline tone.
- **C2 (P1)** Import's warning-banner action is outline/small; seven of eight banner
  actions are primary/compact (MxInlineBanner contract, ruling O6).
- **C3 (P2)** Self-assess hand-builds the CTA row; Recall and Fill use
  `StudyCtaRowWidget`.

### D. Rows, cards, spacing
- **D1 (P1)** Card row and Trash row pad with a raw `12` on all sides.
  **Owner ruling:** `EdgeInsets.symmetric(horizontal: AppSpacing.gutter,
  vertical: AppSpacing.grouped)`, which matches `MxListRow`'s 16dp content edge.
- **D2 (P1)** Deck reorder mode draws a divided list; browse mode draws one
  `MxCard` per deck, 8 apart (handoff 01). Reorder rows take the browse shape.
  `DeckRowWidget` stays.
- **D3 (P1)** Progress overview: Today→Streak gap is `grouped`; every other section
  gap is `gutter`.
- **D4 (P1)** Language hand-builds its card and a centred footnote instead of
  `MxSection(note:)`; Theme's footnote is also a centred `Text`. Both use the
  `MxNote` form.
- **D5 (P1, S)** Deck unset state (02) draws a horizontal button row outside the
  card; every other empty state stacks block buttons inside it. Add a third
  action slot to `MxEmptyState`.
- **D6 (P1, S)** Guess's blocked question puts Close outside `MxErrorState`; every
  other error state uses the built-in slot. Make the slot's icon configurable.

### E. Settings forms
- **E1 (P1, S)** Study options renders new-card order as two `MxOptionRow`s;
  Settings renders the same choice as `MxSegmentedTray`. Give the tray a disabled
  state and use it in both.
- **E2 (P2)** Study options' rows carry no icon; Settings' same rows do.

### F. Study session
- **F1 (P1)** Match marks a wrong tile with colour only; Guess adds ✕. Drive the
  icon from the tone.
- **F2 (P1)** Recall's countdown track is 6dp; every other thin track and M3 are
  4dp.
- **F3 (P1)** Browse positions the face label over the content (`Stack` +
  `Positioned`); the label (~35dp) can overlap the 32dp top inset. Put the label
  in flow. Keep the split card (handoff 16).

### G. Typography
- **G1 (P1)** Theme hint uses `rowSubtitle` (ListRow's ellipsizing sub-line);
  every other hint under a choice uses `rowDescription`.
