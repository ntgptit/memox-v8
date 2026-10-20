# One spacing per layout level

Status: draft for the owner's review (2026-10-20). Decisions S1–S2 below are
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

## 3. One value per level

| Level | Value | Owner |
|---|---|---|
| L1 Top of a screen body, under the app bar | `space8` | `MxScreenScroll` (new `top`, default `space8`; `0` for the Library list that sits close under its search field, screen 01 ruling) |
| L1 Tail | unchanged (`space24` + clearance) | `MxScreenScroll` |
| L2 Gap between top-level blocks, and before a section header | `space16` | the screen; `MxSection` already ends with `space16` |
| L3 Section header to its content | `space8` | `MxListSectionHeader` (unchanged) |
| L4 Sibling cards in a list | `space8` | the screen (DEV-304) |
| L5 Card padding | `space24`; `space16` (`isCompact`) only for cards side by side | `MxCard` (unchanged) |
| L6 Title to subtitle or metadata line, in a row | `space2` (the shared rows' `_subtitleGap`) | each row; hand-built rows follow `MxListRow` |
| L6 Title to its line, in a card | `space4` | the card |
| L6 Heading to body, in a card | `space12` | the card |
| L7 Icon tile to text | `space12` | each row and card; `MxSettingsRow` and the deck row move from 16 |
| L7 Inline glyph (`sizeIconInline`) to its words | `space8` | unchanged (`MxNote`, `MxInlineBanner`) |
| L8 Buttons side by side or stacked | `space8` | `MxActionPair`, `MxSheetActions`, `MxFooterBar` (unchanged); stacked footers move from 12 |
| L8 Content to the action at a card's end | `space16` | the card |
| L9 Empty and error state insides | the empty state's: tile→title 16, title→body 8, body→action 24, padding 44 top / 32 bottom | `MxErrorState` follows `MxEmptyState` |
| L9 Dialog: content items | `space12` | the dialog's content |
| L9 Sheet head | `MxBottomSheet`'s 24/4/24/12; heads of rows that start 16 in stay 16 (merge choice, study direction) | the hand-built heads |
| L9 Banner inside a sheet | 16 sides, 12 top, 0 bottom | the sheet |
| L10 Chip and badge wraps | run spacing equal to spacing; no wrap without run spacing | each wrap |

`space2` is the shared rows' existing constant. It does not become a token.

## 4. Fixes

The plan lists every site with `file:line`. In summary:

- F1: `MxScreenScroll` gains `top` (default `space8`). Every screen drops its
  own first `SizedBox`. Settings, Admin, Study defaults, Account, Study
  home, Progress and TOPIK screens gain the 8. Card import and the deck
  algorithm screen go from 4 to 8. Library's list keeps 0.
- F2: gaps between blocks of 12 or 24 become 16 (card list's deck hero,
  the deck algorithm screen, search results, starter, Trash, Tags, Users,
  the TOPIK summary and overview). The welcome hero keeps its 24 and 32,
  which are deliberate.
- F3: starter cards are 8 apart.
- F4: hand-built rows' title to subtitle becomes 2 (deck row, card row,
  TOPIK history row, monitoring detail row, log row, search card hit row).
- F5: tile to text becomes 12 (`MxSettingsRow`, deck row, monitoring detail
  row and header, TOPIK summary hero).
- F6: content to a card's closing action becomes 16 (deck start over, card
  trash section, session summary hero, progress today, study entry resume,
  starter template card).
- F7: `MxErrorState` takes the empty state's insides.
- F8: dialog content gaps become 12 (reminder time, tag rename, card delete,
  deck reset).
- F9: sheet heads and banners: the starter algorithm head's bottom becomes
  12, and banner insets become 16/12/16/0 (export, starter algorithm).
- F10: the two chip wraps without run spacing get it (card tag editor, card
  schedule).
- F11: stacked footer buttons become 8 apart (welcome, sign-in, account
  transition layer).
- F12: `DESIGN.md` Layout states the levels; the screen detail files that
  state a changed value follow.

Left as they are, with the reason: the welcome hero (32/24, deliberate);
the Library list's 0 top (screen 01); `isCompact` cards in `MxTwoColumns`;
the study and TOPIK panes' own paddings (session layout); the sign-in way
out's 32 (S9).

## 5. Verification

- `mx_screen_scroll_test`: the top gap is `space8` by default and `0` when
  asked; it fails before F1.
- `mx_error_state_test`: the gaps equal the empty state's; it fails before F7.
- A widget test per changed shared row pins its gap (`MxSettingsRow`).
- Goldens move on most screens. The golden-compare pages go to the owner
  before the merge.
