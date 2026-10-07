<!-- Hand-written screen index. -->

# MemoX screen index

Every screen of the app. Each detail file records the screen's layout, its states with
their goldens, its rulings and its copy. The visual system is in
[`DESIGN.md`](../../../../DESIGN.md); the authority order is
[ADR-019](../../decisions/ADR-019-app-la-chuan-ui.md).

## Status values

- **built:** the app has the screen and its detail file describes it.
- **out of V8:** belongs to a sub-project after V8.0 (`PRODUCT.md`, deferred).

## Screens

**States** is the number of states the detail file records, most of them rows of its States table.

| # | Screen | States | FE item | Status | Detail |
|---|---|---|---|---|---|
| 01 | Deck list · recursive | 22 | FE-A1 | built | [01-deck-list.md](01-deck-list.md) |
| 02 | Review algorithm & reset | 9 | FE-A4 | built | [02-review-algorithm.md](02-review-algorithm.md) |
| 03 | Starter decks | 10 | FE-B4 | built | [03-starter-decks.md](03-starter-decks.md) |
| 04 | Library search | 6 | FE-A1, FE-A10 | built | [04-library-search.md](04-library-search.md) |
| 05 | Tags | 13 | FE-B2 | built | [05-tags.md](05-tags.md) |
| 06 | Trash | 15 | FE-B1 | built | [06-trash.md](06-trash.md) |
| 07 | Card list | 15 | FE-A2 | built | [07-card-list.md](07-card-list.md) |
| 08 | Card create | 9 | FE-A2 | built | [08-card-create.md](08-card-create.md) |
| 09 | Card edit | 9 | FE-A2 | built | [09-card-edit.md](09-card-edit.md) |
| 10 | Card detail | 7 | FE-A2 | built | [10-card-detail.md](10-card-detail.md) |
| 11 | Card import | 17 | FE-B3 | built | [11-card-import.md](11-card-import.md) |
| 12 | Card export | 9 | FE-B3 | built | [12-card-export.md](12-card-export.md) |
| 13 | Study home | 10 | FE-A8, SB-U1 | built | [13-study-home.md](13-study-home.md) |
| 14 | Study entry | 9 | FE-A6, FE-A7 | built | [14-study-entry.md](14-study-entry.md) |
| 15 | Study options | 9 | FE-A3 | built | [15-study-options.md](15-study-options.md) |
| 16 | Study · Browse | 1 | FE-A6 | built | [16-study-browse.md](16-study-browse.md) |
| 16a | Study · Self-assess (`self_assess`) | 6 | FE-A6 | built | [16a-study-self-assess.md](16a-study-self-assess.md) (shape brief) |
| 17 | Study · Match | 1 | FE-A6 | built | [17-study-match.md](17-study-match.md) |
| 18 | Study · Guess | 1 | FE-A6 | built | [18-study-guess.md](18-study-guess.md) |
| 19 | Study · Recall | 3 | FE-A6 | built | [19-study-recall.md](19-study-recall.md) |
| 20 | Study · Fill | 3 | FE-A6 | built | [20-study-fill.md](20-study-fill.md) |
| 21 | Session summary | 10 | FE-A6 | built | [21-session-summary.md](21-session-summary.md) |
| 22 | Progress | 12 | FE-A9 | built | [22-progress.md](22-progress.md) |
| 23 | Settings | 16 | FE-A3, SB-U1, FE-B8, FE-B9, SQL log switch (2026-10-07) | built | [23-settings.md](23-settings.md) |
| 24 | Daily reminder | 10 | FE-B5, FE-B6 | built | [24-daily-reminder.md](24-daily-reminder.md) |
| 25 | Theme | 4 | FE-A3 | built | [25-theme.md](25-theme.md) |
| 26 | Language | 4 | FE-A3 | built | [26-language.md](26-language.md) |
| 27 | Sync | 10 | SB-U1 | built | [27-sync.md](27-sync.md) (shape brief in the spec) |
| 28 | Monitoring (admin only) | 15 | FE-B8, SQL log switch (2026-10-07) | built | [28-monitoring.md](28-monitoring.md) (shape brief in the spec) |
| 29 | Welcome (first launch) | 2 | FE-B9 | built | [29-welcome.md](29-welcome.md) (shape in the account UI spec; redesign in `2026-10-05-sign-in-flow-redesign-design.md`) |
| 30 | Sign-in, merge sheet, transition layer | 13 | FE-B9, FE-B10 | built | [30-sign-in.md](30-sign-in.md) (shape in the account UI spec; redesign in `2026-10-05-sign-in-flow-redesign-design.md`; layout balance in `2026-10-05-sign-in-layout-balance-design.md`) |
| 31 | Code | 3 | FE-B9 | built | [31-code.md](31-code.md) (redesign in `2026-10-05-sign-in-flow-redesign-design.md`; layout balance in `2026-10-05-sign-in-layout-balance-design.md`) |
| 32 | Account | 9 | FE-B10 | built | [32-account.md](32-account.md) (shape in the account UI spec §9.1) |
| 33 | Users (admin) | 10 | FE-B11 | built | [33-users.md](33-users.md) (shape in the users spec §6) |

## Rules shared by every screen

- **Controls without their feature** are hidden (spec A4, amended 2026-09-25).
- **Data displays without their data** are hidden, never drawn empty: an empty mastery
  bar would claim 0 % (spec A5).
- **Delete moves to the Trash** (UC-TRASH-001). "Move to Trash", "Recoverable for 30
  days" and "Undo" are built as follows: Undo after one item, for 8
  seconds and until acted on under TalkBack (FE-B1 D3, D14).
- **Copy** is written in English first; Vietnamese is added to the ARB with the screen.
