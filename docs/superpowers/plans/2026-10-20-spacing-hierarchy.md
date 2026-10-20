# One spacing per layout level Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give each layout level one spacing value across the app, at the
current density.

**Architecture:**
- `MxScreenScroll` takes over the gap under the app bar (`top`, default
  `space8`), so screens stop choosing it.
- `MxErrorState` takes `MxEmptyState`'s insides.
- `MxSettingsRow`'s tile gap follows `MxListRow`.
- The rest is a token choice at each site, from the spec's §3 table.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6.

**Spec:** `docs/superpowers/specs/2026-10-20-spacing-hierarchy-design.md`

Execution: native, in the main loop (owner, 2026-10-20: "Duyệt, viết plan
và làm luôn").

## Global Constraints

- Token values do not change. Card padding stays 24 and the gap between
  blocks stays 16 (S2).
- Spacing comes only from `context.dimens` and `context.screenMargin` (the
  guard).
- A deliberate exception keeps its value and cites its ruling in a comment:
  the welcome hero, the Library list's 0 top, the study and TOPIK panes,
  and the sign-in way out.

## Review Focus

1. A screen whose first child is a banner (Settings with an account banner,
   Account in reauth): the banner sits 8 under the app bar, not 0 and not
   16. Pinned by the Settings and Account goldens in Task 2.
2. A body that swaps loading → content → error: all three start at the same
   top, so nothing jumps. Pinned in Task 2 (each screen's branches share
   `MxScreenScroll`'s default).
3. Library under its search field: the list, its loading and its error stay
   at 0 together. Pinned in Task 2.
4. Pull to refresh on a list: the top gap is inside the scroll and moves
   with it. `MxScreenScroll` pads its `ListView`. Pinned in Task 1.
5. An empty state right under the app bar gets the same 8 as content.
   Pinned in Task 2.

---

### Task 1: Shared owners (F1, F5 shared, F7)

**Files:**
- `lib/shared/widgets/mx_screen_scroll.dart`: `top`, default `space8`, in
  the `ListView`'s padding.
- `lib/shared/widgets/mx_error_state.dart`: padding 44/32, tile→title 16,
  title→body 8, body→retry 24, as `MxEmptyState`'s regular layout.
- `lib/shared/widgets/mx_settings_row.dart`: tile→text 12.
- Tests: `mx_screen_scroll_test.dart`, `mx_error_state_test.dart`,
  `mx_settings_row_test.dart`.

- [ ] Step 1: Write the failing tests: the scroll's first child starts
  `space8` below its top, or 0 with `top: 0`; the error state's gaps equal
  the empty state's; the settings row's text starts 12 after its tile.
- [ ] Step 2: Implement; the tests pass.

### Task 2: Screen tops and block gaps (F1–F3, F11)

- [ ] Step 1: At every `MxScreenScroll` call site, remove a leading
  `SizedBox(height: …space8)`. A leading 4 goes too, so card import and
  the deck algorithm screen get 8. A different deliberate top becomes
  `top:`: welcome `space32`; the TOPIK panes `space16`; Library's list,
  loading and error `0`.
- [ ] Step 2: Bodies outside `MxScreenScroll` with their own top padding
  (card detail, card editor, card list section, the monitoring and users
  tabs, the Library root): set the top to `space8`.
- [ ] Step 3: Gaps of 12 or 24 between top-level blocks become 16: card
  list deck hero, deck algorithm, search results, starter, Trash, Tags,
  Users, the TOPIK summary and overview.
- [ ] Step 4: Starter cards become 8 apart. Stacked footer buttons become
  8 apart (welcome, sign-in, account transition layer).
- [ ] Step 5: Run `dod_check.sh --changed`.

### Task 3: Inside cards, rows, dialogs and sheets (F4–F6, F8–F10)

- [ ] Step 1: Hand-built rows: title→subtitle 2 (deck, card, TOPIK history,
  monitoring detail, log, search card hit). There is no `space2` token; the
  2 is a private constant in each shared row. Ask the owner first, because
  it touches `lib/shared/` or `lib/core/`: expose one shared value (the
  recommendation), or leave these rows at 4.
- [ ] Step 2: Tile→text 12: the deck row, the monitoring detail row and
  header, and the TOPIK summary hero.
- [ ] Step 3: Content→closing action 16: deck start over, card trash
  section, session summary hero, progress today, study entry resume,
  starter template card.
- [ ] Step 4: Dialog content gaps 12: reminder time, tag rename, card
  delete, deck reset.
- [ ] Step 5: Sheets: the starter algorithm head's bottom becomes 12;
  banners in sheets get 16/12/16/0 (export, starter algorithm).
- [ ] Step 6: Add run spacing to the card tag editor and card schedule
  wraps.

### Task 4: Docs, goldens, verification

- [ ] Step 1: DESIGN.md Layout states the levels, and the screen detail
  files that state a changed value follow. Regenerate the frontmatter if it
  changed.
- [ ] Step 2: Run `run_goldens.sh --update`, then `dod_check.sh` and
  `run_goldens.sh` on the final tree.
- [ ] Step 3: Run the final whole-branch review on Opus, fix its findings
  in one batch, then rerun check degrade and check similar.
- [ ] Step 4: Build the golden-compare pages and get the owner's approval;
  then open the pull request, merge it and comment on Linear.
