---
target: kit screens 03 Starter decks and 05 Tags, and the screen 07 tag filter (pre-plan)
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "dir:docs/shared/ui/screen-handoff/img/03-starter-decks+05-tags"
timestamp: 2026-09-27T06-00-00Z
slug: tags-starter-kit
---
Method: one pass. The 44 captures (10 states of 03 and 12 of 05, light and dark) were read against spec `docs/superpowers/specs/2026-09-27-tags-starter-ui-design.md` (D1–D13), UC-STARTER-001 and UC-TAG-001, and against the shared widgets that exist at #93 (`MxOptionRow`, `MxListRow`, `MxSelectionCheckbox`, `MxChipTrigger`, `MxFilterChip`, `MxSheetActions`, `MxSemanticColors`). There is no Flutter build yet, and no browser detector (Flutter). The kit does not draw screen 07's filter overlay, so it is shaped here (Shape brief, below).

## Design Health Score: 31/40

| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Adding, busy rows and toasts say what happens; an applied tag filter has no visible state on the kit's ghost chip (P1b) |
| 2 | Match system / real world | 4 | "Merge", "the cards stay", "Tags are not kept in Trash" speak the person's worry |
| 3 | User control and freedom | 4 | Cancel everywhere; closing the filter without Apply keeps what was applied (A5) |
| 4 | Consistency and standards | 3 | A sort glyph beside "A→Z" reads as a control that does nothing (P2b) |
| 5 | Error prevention | 4 | The merge is disclosed before confirming (A1); the delete says no card is deleted |
| 6 | Recognition vs recall | 3 | "Suggests …" is cut to "Suggests…" beside "Add another copy" (P2a) |
| 7 | Flexibility and efficiency | 3 | Find cards with this tag jumps to the search; no bulk tag work (out of scope) |
| 8 | Aesthetic and minimalist | 3 | Clean; the merge panel is dense but every line answers a fear |
| 9 | Error recovery | 3 | Retry on the toast and the banner; the kit has no catalog read error (D10) |
| 10 | Help and documentation | 3 | The fixture note (BR-STARTER-010) and the case-insensitive hints |

## Design specificity
Both screens are specific to MemoX:
- starter decks are development fixtures that become the person's own deck, never a course (BR-STARTER-010), and a second copy is a separate deck with its own progress;
- a tag rename onto an existing name merges, keeps the target's spelling, dedupes, and never pushes a card past 10 tags (BR-TAG-007, BR-TAG-002);
- tag deletion never touches a card and has no Trash (BR-TAG-008).

## Priority issues

- **[P1a] "Merge tags" fails contrast as the kit paints it.**
  - *Problem:* the kit fills the button orange with white text, about 2.8:1, under 4.5:1 for a 14 sp label. The app's warning role is amber (`#F59E0B` light, `#FFC658` dark) with `onWarning` dark ink, which clears AA in both themes.
  - *Fix:* D9's `MxButtonTone.warning` paints `warning` with `onWarning`, not the kit's orange and white. Recorded as a deviation (UI-base §9). `MxSheetActions` gains the same tone for the dialog's confirm.
  - *Command:* `/impeccable audit`
- **[P1b] An applied tag filter is invisible on the kit's chip.**
  - *Problem:* kit 07 draws "Tags" as a ghost `MxChipTrigger`, which by contract "never reads as selected". With tags applied the list shrinks, and the only cue is a count in the label. The status filters beside it show selection by fill, so the tag filter reads as off when it is on.
  - *Fix:* the owner rules. Recommended: `MxFilterChip` with a tag glyph, `isSelected` when one tag or more is applied, label "Tags" and count k. Its tap opens the sheet; it does not toggle.
  - *Command:* `/impeccable clarify`
- **[P2a] The suggested algorithm is truncated.**
  - *Problem:* on a 360 dp card, "Add another copy" leaves "Suggests…" with no algorithm, which is the line that tells the person what to pick.
  - *Fix:* the button and "Suggests {algorithm}" sit in a `Wrap`; when both do not fit on one line, the suggestion drops below the button, whole. Never an ellipsis.
  - *Command:* `/impeccable layout`
- **[P2b] The catalog header draws a sort glyph that does nothing.**
  - *Problem:* "↓ A→Z" looks like the card list's sort trigger, but the catalog has one order (BR-TAG-003).
  - *Fix:* "A→Z" is plain trailing caption text, no glyph and no target (spec §5.2 already says static).
  - *Command:* `/impeccable distill`
- **[P2c] `MxOptionRow` is a radio, not a checkbox.**
  - *Problem:* D3 names `MxOptionRow` checkboxes, but the row is single-choice (a ring, `inMutuallyExclusiveGroup`). A multi-select sheet built on it would announce radios.
  - *Fix:* the filter rows are `MxListRow`s with a leading `MxSelectionCheckbox` (painted only), the row carrying `checked` semantics, as the card list's selection mode does. No new shared widget.
  - *Command:* none; recorded as a ruling on D3.
- **[P3] Smaller points the plan adopts.**
  - A tag name longer than a row ends in an ellipsis; the full name is in the row's semantics and in the action sheet's chip.
  - Rename is disabled while the field equals the current name exactly; a case-only change is a rename (A2), not a merge.
  - While a new plan settles, the dialog keeps the last plan's panel and button. The write carries the confirmed target, so a race returns `mergeNotConfirmed`, which plans again (D8).
  - The rename field does not cap input at 50: the kit lets the person see the whole name in error ("57 / 50").
  - "In library" and a long title: the title wraps, and nothing overflows at text scale 2.
  - The kit's `loadFailed` title is missing "load" ("Couldn't starter decks"); the spec's "Couldn't load starter decks" stands.
  - The busy row is not tappable; its ⋮ is a spinner (`MxListRow.isBusy`).
- **[P3] Semantics.**
  - A template card is one node: "{title}, {languages}, {n} cards, {m} sub-decks, in library", then its button.
  - A tag row is one button node: "{tag}, {n} cards"; ⋮ is its own node "Actions for {tag}".
  - A filter row is one checkbox node: "{tag}, {n} cards in this deck, checked/not checked".

## Shape brief: screen 07's tag filter sheet (D3)

1. **Job and audience.** Someone in a deck's card list who wants only the cards carrying one or more tags, often mid-review of a topic. Operate mode: a quick, reversible narrowing.
2. **Outcome and proof.** They pick tags, apply, and see the list narrowed with the chip showing it is on. Success: the result is predictable before Apply, because each row's count is what that tag alone shows in this deck (BE-B2 D3).
3. **Direction.** Inside the established kit world: an `MxBottomSheet` like the sort and flag sheets, no new visual language. The one thing it must make clear that a sort sheet need not: the choice is OR ("any of"), and it combines with the status filter and the search.
4. **Scope and boundaries.** One sheet, three states (none, one, several chosen). No tag editing here (the catalog owns it), no "match all" mode (BR-TAG-004 is OR), no reordering chosen tags to the top: rows keep the catalog's order, so a checked row never jumps under the finger.
5. **States and ranges.**
   - Tags in the catalog: 0, typical 5–20, up to a few hundred. A row's count: 0 up to the deck's size.
   - **None chosen:** title "Filter by tags", sub-line "Show cards with any of the chosen tags". Clear is disabled; Apply is enabled (applying none returns the list to unfiltered, A4).
   - **One chosen / several:** the sub-line becomes "{k} chosen · cards with any of them". Clear enabled.
   - **More than 8 tags:** an `MxSearchField` "Search tags" heads the list, filtering by the catalog's fold. Searching never drops a chosen tag; a chosen tag that the search hides still counts in "{k} chosen".
   - **No tag at all:** the chip still opens the sheet, which shows one line "No tags yet. Add tags while creating or editing cards." and only a Close action.
   - **A tag with 0 cards in this deck:** listed at full contrast; its count reads "0" in `onSurfaceVariant`. Choosing it alone leads to A7.
   - **A tag deleted or merged while open:** its row leaves the list and the draft (D12).
6. **Interaction and layout.**
   - Header: the title and the sub-line. Body: the optional search, then the rows, scrolling; the footer stays pinned above the keyboard.
   - A row: the checkbox, the name (one line, ellipsis), the count as trailing tabular figure. The whole row toggles; 48 dp minimum.
   - Footer: `MxSheetActions.custom` with "Clear" (outline, empties the draft, does not close) and "Apply" (primary, closes and applies).
   - Dismissing by scrim, drag or Back discards the draft (A5).
   - After Apply: the window resets, the selection clears (BR-TAG-005), and the chip shows k.
7. **Constraints and open decisions.**
   - Rows reuse `MxListRow` and `MxSelectionCheckbox` (P2c); the sheet reuses `MxBottomSheet` and `MxSheetActions`; no new shared widget.
   - Every string in en and vi; the vi sub-line must fit at 360 dp, text scale 2, by wrapping.
   - The chip's look when applied is the owner's ruling (P1b).

## Plan must adopt or rule on
1. The merge button's colours (P1a): adopt the token, record the deviation.
2. The Tags chip when applied (P1b): the owner rules.
3. The suggestion line (P2a), the header glyph (P2b), the filter rows (P2c) and the P3 points: adopt.
4. The filter sheet as shaped above: the owner confirms.
