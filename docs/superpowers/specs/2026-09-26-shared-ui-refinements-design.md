# MemoX V8 — Shared UI refinements, phase 1 (common widgets and tokens)

Status: approved 2026-09-26 · Path: architectural

## 1. Intent

The owner reviewed screen 06 (Trash) running from the FE-B1 branch
(`claude/lexilize-flashcard-app-lpklbs`, not yet merged) and listed what reads badly.
Several of these problems come from shared widgets and tokens, so they also affect
other screens. This package fixes that shared half on `master`, before FE-B1 lands,
so the Trash screen and every other screen get it once.

The Trash-only half is phase 2. It is designed after FE-B1 merges and is out of scope
here (§7).

The kit is a reference here, not an authority: the owner judged it not yet stable
(2026-09-26). Each deviation from it is recorded in the UI-base debt register (§6).

Success means:

- a pair of footer buttons never truncates or wraps a label: the two buttons sit side
  by side when both labels fit on one line, and stack otherwise, at any text scale;
- cards, banners, notes and buttons share one corner radius, 12;
- a selecting row's checkbox is vertically centred on the row;
- a group title (`overline`) reads as a boundary between sections;
- every golden that changes is re-rendered in the Linux container and checked by eye.

## 2. Evidence (2026-09-26)

Traced from FE-B1's `trash_selection_light.png` golden and the code on `master`:

| Owner's point | Cause | Shared? |
|---|---|---|
| "Restore 2…" truncated, "Delete for good" wraps to two lines, icon off the text | Two `MxButton`s (size md, `canWrap: true`, icon in a `Row` with the text `Flexible`) in `Expanded` 13:10 shares, about 150dp each | Yes: the button pair |
| Card, info box and buttons use different radii | `MxCard` is `AppRadius.xl` (20); `MxInlineBanner`, `MxNote` and md buttons are `AppRadius.md` (12) | Yes: token use |
| Checkbox pushed up | The checkbox is top-aligned with the title (`CrossAxisAlignment.start` + `micro` top padding). `card_row_widget.dart` does the same | Yes: a repeated pattern |
| "2 OF 2 CARDS" too faint | `overline` is 12/700 in `onSurfaceVariant` | Yes: the text role |
| "2 days left" low contrast | Measured at 13.9:1 in light (`#3A2A00` on `#FFFFFF`) and 10.9:1 in dark: it passes AA. It fails as a *signal*, because the dark brown reads as black | Phase 2 (§7) |
| Meta line ellipsized, lines too close, banners too tall | Trash row and screen code | Phase 2 (§7) |

## 3. Decisions

| # | Decision | Owner |
|---|---|---|
| D1 | Shared fixes first, on `master`, in their own PR. Trash-only fixes wait for FE-B1 | Owner, 2026-09-26 |
| D2 | `MxCard` uses `AppRadius.md` (12). Dialogs, bottom sheets and the 64 empty-state tile keep `AppRadius.xl` (20): they float above the content | Owner, 2026-09-26 |
| D3 | A new shared `MxActionPair` lays out a footer's two buttons: side by side when both labels fit on one line, otherwise stacked full width. Labels in a pair never wrap or ellipsize | Owner, 2026-09-26 |
| D4 | A selecting row's checkbox is vertically centred on the row | Owner, 2026-09-26 |
| D5 | `overline` becomes 13/700 in `onSurface`, still upper-cased with 0.6 tracking. It is one role, so every overline follows, including the card editor's field labels and the sort sheet header | Owner, 2026-09-26 |
| D6 | `warningInk` is not changed. It already passes AA, and nine call sites paint it, some on a warning fill | Owner, 2026-09-26 |

## 4. Design

### 4.1 Card radius (D2)

- `MxCard` paints and clips at `AppRadius.md` instead of `AppRadius.xl`. This covers
  its selected edge and the full-bleed children whose dividers meet the corners.
- `AppRadius`'s doc comments move "Card" from `xl` to `md`. The `xl` value stays 20.
- No call site changes. A call site that set its own radius for a card look is found by
  searching for `AppRadius.xl` and is moved to `md` only if it paints a card.

### 4.2 `MxActionPair` (D3)

`lib/shared/widgets/mx_action_pair.dart`, used as `MxFooterBar`'s child.

- **Input:** a required `trailing` `MxButton` and an optional `leading` `MxButton`,
  plus optional flex shares for the side-by-side layout (default 1:1). Without
  `leading`, it shows `trailing` alone at full width.
- **Fit rule:** the two buttons sit side by side when each button's single-line natural
  width fits inside its share of the bar (width minus the `AppSpacing.control` gap).
  Otherwise they stack, `leading` on top, each full width, with the same gap. The
  natural width is measured from the laid-out button, not estimated from the string,
  so it follows the locale, the font and the text scale.
- **Single line:** a button inside a pair renders its label on one line. `MxButton`
  gets `isSingleLine` (default false), which turns wrapping off whatever the size, and
  the pair's callers set it. Because the pair stacks whenever a label would not fit, the
  label is never ellipsized, and the icon stays centred on the one line.
- **Call sites moved to it:**
  - `session_summary_widget.dart` (Study this deck 5 : Done 6);
  - `card_import_screen.dart` (results: secondary and primary, equal).
- **Call sites left as they are:**
  - `card_editor_footer_widget.dart` and `import_commit_bar_widget.dart` pair a compact
    button with a block button, which is not a pair of equals;
  - `card_bulk_bar_widget.dart` shows icons over labels.

### 4.3 Selecting row checkbox (D4)

`card_row_widget.dart`: while selecting, the leading checkbox is centred vertically on
the row. The non-selecting leading tile keeps its current alignment. The Trash row gets
the same treatment in phase 2.

### 4.4 Overline (D5)

`MxTextStyles.overline` becomes 13 (a size override on `labelSmall`), weight 700,
tracking 0.6, tabular figures, colour `onSurface`. The doc comment says so.

## 5. Testing

- **`MxActionPair` widget tests:**
  - short labels at 360 wide: both buttons sit in one row, at equal widths or the
    given shares;
  - a long label (the Vietnamese "Xoá vĩnh viễn" beside a count label, or an English
    label that cannot fit) stacks them, and no `Text` inside overflows or reports
    `didExceedMaxLines`;
  - text scale 2.0 stacks them;
  - no `leading`: one full-width button.
- **Style tests:** update the existing `overline` test in `mx_text_styles_test.dart`
  (13/700, `onSurface`). Add a test that `MxCard`'s decoration radius is
  `AppRadius.md`.
- **Row test:** in the card list, while selecting, the checkbox's centre y equals the
  row's centre y.
- **Goldens:** re-render in the Linux container (`golden.Dockerfile`), never on Windows.
  Many goldens change, because cards and group titles are on most screens. Each
  changed golden is opened and checked for the radius, the overline and the footer, and
  nothing else may differ.
- **Gate:** one full `dod_check.sh` run before the PR.

## 6. Register rows

These rows are added to [§9 of the UI-base spec](2026-09-23-flutter-ui-base-design.md).
Numbering starts at 113, because FE-B1's branch already uses 108–112.

- **113:** `MxCard` radius 12 (kit: 20), so a card matches banners, notes and buttons
  (owner 2026-09-26).
- **114:** `overline` 13/700 `onSurface` (kit: 12/700 `onSurfaceVariant`) (owner
  2026-09-26).
- **115:** a selecting row's checkbox is centred vertically (kit: top-aligned with the
  title) (owner 2026-09-26).
- **116:** a footer pair stacks when a label does not fit on one line (kit: always side
  by side) (owner 2026-09-26).

## 7. Out of scope: phase 2 (Trash, after FE-B1 merges)

Each item below is decided with the owner in phase 2:

- the button labels "Restore (n)" and "Delete (n)", in en and vi, inside `MxActionPair`;
- the meta line allowed to wrap to two lines, and more spacing between the row's lines;
- the checkbox centred (D4);
- an `MxBadge` warning pill for an entry that expires soon;
- a shorter or conditional top banner and selection note. Check BR-TRASH-011 before
  removing the note.
