# Screen catalog

Every screen of the app; one spec per screen in `spec/`. The visual system is in
[`DESIGN.md`](../../DESIGN.md); the authority order is
[ADR-021](../shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md).

## Screens

| ID | Screen | Domain | Route | Status | Spec |
|---|---|---|---|---|---|
| SCR-DECK-001 | Deck list | deck | `/decks`, `/decks/deck/:deckId` | ready | `spec/SCR-DECK-001-deck-list.md` |
| SCR-SRS-001 | Review algorithm & reset | srs | `/decks/deck/:deckId/algorithm` | ready | `spec/SCR-SRS-001-review-algorithm.md` |
| SCR-STARTER-001 | Starter decks | starter-decks | `/decks/starter` | ready | `spec/SCR-STARTER-001-starter-decks.md` |
| SCR-SEARCH-001 | Library search | search | `/decks/search` | ready | `spec/SCR-SEARCH-001-library-search.md` |
| SCR-TAG-001 | Tags | tags | `/decks/tags` | ready | `spec/SCR-TAG-001-tags.md` |
| SCR-TRASH-001 | Trash | trash | `/decks/trash` | ready | `spec/SCR-TRASH-001-trash.md` |
| SCR-CARD-001 | Card list | card | `/decks/deck/:deckId` | ready | `spec/SCR-CARD-001-card-list.md` |
| SCR-CARD-002 | Card create | card | `/decks/deck/:deckId/cards/new` | ready | `spec/SCR-CARD-002-card-create.md` |
| SCR-CARD-003 | Card edit | card | `/decks/card/:cardId/edit` | ready | `spec/SCR-CARD-003-card-edit.md` |
| SCR-CARD-004 | Card detail | card | `/decks/card/:cardId` | ready | `spec/SCR-CARD-004-card-detail.md` |
| SCR-TRANSFER-001 | Card import | transfer | `/decks/deck/:deckId/cards/import` | ready | `spec/SCR-TRANSFER-001-card-import.md` |
| SCR-TRANSFER-002 | Card export | transfer | — | ready | `spec/SCR-TRANSFER-002-card-export.md` |
| SCR-STUDY-001 | Study home | study | `/study` | ready | `spec/SCR-STUDY-001-study-home.md` |
| SCR-STUDY-002 | Study entry | study | `/decks/deck/:deckId/study` | ready | `spec/SCR-STUDY-002-study-entry.md` |
| SCR-STUDY-003 | Study · Browse | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-003-study-browse.md` |
| SCR-STUDY-004 | Study · Self-assess | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-004-study-self-assess.md` |
| SCR-STUDY-005 | Study · Match | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-005-study-match.md` |
| SCR-STUDY-006 | Study · Guess | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-006-study-guess.md` |
| SCR-STUDY-007 | Study · Recall | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-007-study-recall.md` |
| SCR-STUDY-008 | Study · Fill | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-008-study-fill.md` |
| SCR-STUDY-009 | Session summary | study | `/study/session/:sessionId` | ready | `spec/SCR-STUDY-009-session-summary.md` |
| SCR-SETTINGS-001 | Study options | settings | — | pending | — |
| SCR-SETTINGS-002 | Settings | settings | — | pending | — |
| SCR-SETTINGS-003 | Theme | settings | — | pending | — |
| SCR-SETTINGS-004 | Language | settings | — | pending | — |
| SCR-PROGRESS-001 | Progress | progress | — | pending | — |
| SCR-REMINDER-001 | Daily reminder | reminders | — | pending | — |
| SCR-ACCOUNT-001 | Sync | account | — | pending | — |
| SCR-ACCOUNT-002 | Welcome | account | — | pending | — |
| SCR-ACCOUNT-003 | Sign-in, the merge sheet and the transition layer | account | — | pending | — |
| SCR-ACCOUNT-004 | Code | account | — | pending | — |
| SCR-ACCOUNT-005 | Account | account | — | pending | — |
| SCR-ACCOUNT-006 | Users (admin) | account | — | pending | — |
| SCR-MONITORING-001 | Monitoring | monitoring | — | pending | — |

## Invariants for every screen

Behaviour every screen holds. Visual values (touch targets, contrast, spacing, type) are in
`DESIGN.md` and are not restated here; a rule of one screen lives in that screen's spec.

| ID | Invariant | Enforced by |
|---|---|---|
| INV-UI-001 | A control whose feature is not built yet is hidden, never shown disabled. | — |
| INV-UI-002 | A data display with no data is hidden, never drawn empty: an empty mastery bar would claim 0 %. | — |
| INV-UI-003 | Deleting moves the item to the Trash and offers Undo after one item, for 8 seconds, and under TalkBack until acted on. | — |
| INV-UI-004 | A failed save keeps everything the user entered. | — |
| INV-UI-005 | The on-screen keyboard never covers the focused field. | — |
| INV-UI-006 | A floating action button never hides the last item of a list. | — |
| INV-UI-007 | A read-only control looks and announces differently from a disabled one. | — |
