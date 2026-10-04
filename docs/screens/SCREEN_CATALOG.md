# Screen catalog

Every screen of the app; one spec per screen in `spec/`. The visual system is in
[`DESIGN.md`](../../DESIGN.md); the authority order is
[ADR-021](../shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md).

## Screens

| ID | Screen | Domain | Route | Status | Spec |
|---|---|---|---|---|---|
| SCR-DECK-001 | Deck list | deck | `/decks`, `/decks/deck/:deckId` | ready | `spec/SCR-DECK-001-deck-list.md` |

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
