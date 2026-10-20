# One spacing per layout level

Status: approved by the owner on 2026-10-20. Decisions S1–S2 below are
the owner's. Follows `2026-10-20-type-scale-and-hierarchy-design.md`.
Tier 1 at least: it changes `lib/shared/` and reaches most screens.

## 1. Problem

The owner: "Cũng kiểm soát lại spacing toàn app đi". This follows the type
scale work: the same layout level should not be spaced differently on
different screens.

An audit of the 715 `dimens.spaceN` uses (Sonnet, read-only, 2026-10-20)
found:

- The spacing tokens are used correctly. No feature has a raw number.
  Arithmetic on tokens is geometry, except one workaround (`16 - 4` in
  `deck_level_query_sheets_widget.dart:66`).
- The inconsistency comes from the screen choosing the value, not from the
  token. `MxScreenScroll` owns the side margin and the tail, but not the top
  gap under the app bar or the gap between blocks. Each screen adds its own
  `SizedBox`, so the same `MxSection` body starts 0 below the app bar on
  Settings and 8 below it on Reminder, Theme, Language and Sync.
- The same level reads two ways elsewhere too:
  - the gap between blocks is 12, 16 or 24;
  - sibling cards are 8 apart, but starter cards are 12 apart;
  - title to subtitle is 2 in the shared rows and 4 in the hand-built rows;
  - a tile to its text is 12, but 16 in `MxSettingsRow` and the deck row;
  - content to the action at a card's end is 8, 12 or 16;
  - the empty and error states have different insides;
  - a dialog's content gap is 8 or 12;
  - a banner inside a sheet is inset three ways;
  - two chip wraps have no run spacing, so wrapped lines touch.

## 2. Decisions (owner, 2026-10-20)

| # | Decision |
|---|---|
| S1 | Unify every level to the value most sites already use. |
| S2 | Keep the current density: card padding 24, gap between blocks 16. The owner saw "denser" (16/12) beside the current spacing and kept the current one. The token values do not change. |
| S3 | A row's title to its line is one shared value, `AppDimens.spaceRowLine` (2), read by the shared rows (which had private 2s) and the hand-built rows (which had 4). |
| S4 | After the final review: a search field under the app bar is 8 below it and 8 above the content; under a breadcrumb the content starts at 0 (the breadcrumb's inset is the gap, screen 01's rule everywhere); without its search field (loading, failed) the Library root takes the body's 8; Study entry's blocks are 16 apart. |

## 3. One value per level

| Level | Value | Owner |
|---|---|---|
| L1 Top of a screen body, under the app bar | `space8` | `MxScreenScroll` (new `top`, default `space8`) |
| L1 Under a search field or a breadcrumb | the field: 8 above it, 8 to the content; the breadcrumb: 0, its inset is the gap (S4) | the screen (`top: 0`) |
| L1 Tail | unchanged (`space24` + clearance) | `MxScreenScroll` |
| L2 Gap between top-level blocks, and before a section header | `space16` | the screen; `MxSection` already ends with `space16` |
| L3 Section header to its content | `space8` | `MxListSectionHeader` (unchanged) |
| L4 Sibling cards in a list | `space8` | the screen (DEV-304) |
| L5 Card padding | `space24`; `space16` (`isCompact`) only for cards side by side | `MxCard` (unchanged) |
| L6 Title to subtitle or metadata line, in a row | `spaceRowLine` (2, S3) | every row, shared or hand-built |
| L6 Title to its line, in a card | `space4` | the card |
| L6 Heading to body, in a card | `space12` | the card |
| L7 Icon tile to text | `space12` | each row and card; `MxSettingsRow` and the deck row move from 16 |
| L7 Inline glyph (`sizeIconInline`) to its words | `space8` | unchanged (`MxNote`, `MxInlineBanner`) |
| L8 Buttons side by side or stacked | `space8` | `MxActionPair`, `MxSheetActions`, `MxFooterBar` (unchanged); stacked footers move from 12 |
| L8 Content to the action at a card's end | `space16` | the card |
| L9 Empty and error state insides | the compact empty state's, whose 52 tile the error state shares: 32 above and below, tile→title 16, title→body 8, body→action 24 | `MxErrorState` follows `MxEmptyState` |
| L9 Dialog: content items | `space12` | the dialog's content |
| L9 Sheet head | `MxBottomSheet`'s 24/4/24/12; heads of rows that start 16 in stay 16 (merge choice, study direction) | the hand-built heads |
| L9 Banner inside a sheet | in line with the sheet's content edge (rows, overline); 12 below what it follows unless a head's own 12 is that gap; its own margin below | the sheet |
| L10 Chip and badge wraps | run spacing equal to spacing; no wrap without run spacing | each wrap |


## 4. Fixes

The plan lists every site. As built:

- F1: `MxScreenScroll.top` (default `space8`); every screen's own leading
  gap removed (25 sites), so loading, content and error start together.
  Card import and the deck algorithm screen went from 4 to 8. `top: 0`
  under a breadcrumb: sub-deck lists, the deck algorithm screen, the card
  list (8 while selecting, when the breadcrumb hides), card detail, the
  card editor (8 while typing), study options, Study entry, deck progress.
  The Library root: its list 0 under the search field, its loading and
  error 8, its empty state 16. Welcome keeps its hero's 32; the TOPIK
  panes their 16. Search fields: 8 above (the Library root from 4, Users
  and the monitoring server tab from 12), 8 to the content (Tags and the
  card list from 12).
- F2: blocks 16 apart: search results' groups, the Library hero and due
  strip, the card list's deck hero, the deck algorithm screen, Trash's
  note and notices, the TOPIK summary, overview and score trend (from 24),
  Study entry (from 12), Starter's note, the monitoring offline card's
  action. The welcome hero keeps its 32; footers under a list keep 12.
- F3: starter cards 8 apart; the reorder list's top 8 (from 16).
- F4: `spaceRowLine` in the shared rows and the hand-built rows (deck,
  card, TOPIK history, monitoring detail, import preview, import mapping).
- F5: tile→text 12: `MxSettingsRow`, the deck row, the monitoring detail
  header, the TOPIK test list header. The monitoring detail row and the
  TOPIK summary hero have no tile gap and are unchanged.
- F6: content→closing action 16: deck start over, card trash section,
  study entry resume, starter template card, progress today.
- F7: `MxErrorState` takes the compact empty state's insides.
- F8: dialog content gaps 12: reminder time, tag rename, card delete.
- F9: the starter algorithm head's bottom 12; banners in sheets in line
  with the content edge (export, starter algorithm).
- F10: run spacing on the card tag editor and card schedule wraps.
- F11: stacked footer buttons 8 apart (welcome, sign-in, account
  transition layer).
- F12: Study home's resume card takes the default padding (it is alone,
  full width).
- F13: `DESIGN.md` Layout states the levels; screens 29 and 30 and the
  acceptance ledger (SHARED-10) follow.

Left as they are, with the reason: the welcome hero (32); `isCompact` cards
in `MxTwoColumns`; the TOPIK panes' 16 (session layout); the sign-in way
out's 32 (S9); a list's footer (12); a note inside a section before its
choice (the deck algorithm screen, 12).

## 5. Verification

- `mx_screen_scroll_test`: the top gap is `space8` by default and `0` when
  asked; it fails before F1.
- `mx_error_state_test`: the gaps equal the empty state's; it fails before F7.
- A widget test per changed shared row pins its gap (`MxSettingsRow`).
- Goldens move on most screens. The golden-compare pages go to the owner
  before the merge.
