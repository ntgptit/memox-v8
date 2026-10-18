<!-- Hand-written screen record. -->

# 17 · Study · Match

A round-based graded stage: `eight_box` only — `sm2` never runs `match`
(BR-MODE-004). Pair each term tile with its meaning tile, up to five pairs a
board (BR-STUDY-049). FE-A6; UC-STUDY-001 (steps 6–9, A0c). Shared session
chrome and rules (top bar, exit, rounds, result-after-commit, keyboard, the
icon-colour guard): [16-study-browse.md § Shared by the session
screens](16-study-browse.md#shared-by-the-session-screens).

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Indigo, as every mode (3c-2 R8); see the shared section. |
| Context line | `SessionContextLine` | "{deck} · Review · round {n}"; a learning session adds its stage: "{deck} · Learning · stage {n} of {total} · round {n}" (`session_context_state.dart`). |
| Board | grid, up to 10 tiles (5 pairs); new: `MatchBoardTile` (feature-local; not `MxCard` — a small grid tile, not a padded card) | Term tile (front) and meaning tile (back) per pair; states `idle` / `selected` / `matched`, plus a wrong-pair state (see Rulings). A board with an odd remainder may hold one pair (BR-STUDY-049). |
| Footer hint | `SessionFooterHint` | "Tap a term and its meaning, in either order". |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| default | `study_match_board_light.png` | `study_match_board_dark.png` | — |
Other goldens: `study_match_wrong_light.png` / `study_match_wrong_dark.png` (the wrong-pair flash).

Not captured: the tile's `idle`/`selected`/`matched` micro-states and the
wrong-pair flash are interactions inside `default`, not separate screen
states.

**Built (FE-A6 P3):** `StudyMatchWidget` in the session route's mode switch: the board's
terms on the left and its meanings on the right, in their stored order, as
`MxChoiceTile` tiles. Tap a term and a meaning, in either order; the pair is answered on that term
through the session controller, on any pending pair of the board (BR-STUDY-049). Goldens:
`test/features/study/presentation/goldens/study_match_{board,wrong}_*`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| default | tap a term, or a meaning | that tile `selected`; the other side waits | VERIFIED `study_match_test.dart::a term, then its meaning: both are matched, in the success tone, and the match is announced (M1, C1, C3)`, `::a meaning first, then its term: the pair is matched and answered on the term (BR-STUDY-062; critique 2026-09-30 part 3c-2, R3)` |
| selected | tap another tile on the same side | the selection moves | VERIFIED `::a second meaning moves the selection (R3)`, `::a second term moves the selection (M1, R3)` |
| selected | tap the tile on the other side | the pair is answered on the term's card; the selection clears | VERIFIED the tests above |
| answering | the pair is right | both tiles `matched` (success tone, check), "Matched" announced, the hold released at once | VERIFIED `::a term, then its meaning: both are matched, in the success tone, and the match is announced (M1, C1, C3)` |
| answering | the pair is wrong | both tiles flash wrong for 600 ms, the hint swaps to "Not a match — it returns next round", "…" announced; then both are idle and still pending | VERIFIED `::a wrong pair flashes wrong with the hint swapped, then both go back to idle and stay unmatched (M2, C7, BR-STUDY-062)`, `::a meaning, then the wrong term: both flash wrong, the turn is the term's, and nothing stays selected (Review Focus 3)`, `::a wrong tile carries its state in its label during the flash (C3; Impeccable after P3)` |
| wrong flash | a tap on any tile | dropped (BR-STUDY-004) | VERIFIED `::tiles take no tap while a wrong pair flashes (BR-STUDY-004)` |
| answering | a tap while the write runs | dropped | `UNVERIFIED (code read)`: `_canTap` is false while `isBusy` |
| default | the last right pair of a board | the next board, whose tiles take taps | VERIFIED `::the last right pair of a board leads to the next board, whose tiles take taps (Review Focus 4; final review, critical)` |
| default | five right pairs finish the round | the review ends with nothing selected (summary) | VERIFIED `::five right pairs finish the board, and the review ends with nothing selected` |
| round n | a pair was wrong | asked again in the next round (BR-STUDY-060, BR-STUDY-062) | VERIFIED `::a wrong pair carried into round 2 is asked there, and the round answers (BR-STUDY-060, BR-STUDY-062)` |
| answering | the busy database refuses the write | the unsaved-answer banner; the selection is already cleared, the pair is kept for Retry | the banner path is VERIFIED from Browse (16); the controller resends the same pair `study_session_controller_test.dart::Retry resends the same pair the busy database refused (E2)`; this screen's frame in that state is `UNVERIFIED (code read)` |
| wrong flash | leave the screen (✕, Back) before the 600 ms end | the timer is cancelled with the widget; nothing settles late | `UNVERIFIED (code read)`: `dispose` cancels `_timer` |
| default | ✕, system Back, deck deleted, stale write | the route states of [16](16-study-browse.md#session-route-states) | see 16 |

## Rulings

- **FE-A6 spec D14 (P3 ruling C1):** a matched tile uses the `success` semantic; green is mastery-only.
- **P3 ruling C7:** during a wrong pair's flash the footer hint reads "Not a match — it returns next round".
- **BR-STUDY-063, BR-STUDY-070:** a wrong pair flashes the error tone on both tiles after the write commits, then both settle back to `idle` and stay pending on the board.
- **BR-STUDY-060, BR-STUDY-062:** a wrong pair keeps its row `pending` for this board and is guaranteed one slot in the next round, even if matched correctly later in this round.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the session context line is an eyebrow; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** a meaning may be tapped first, as BR-STUDY-062 requires; idle meanings sit on the recessed ground, terms stay raised; hint "Tap a term and its meaning, in either order" (R3).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is info, and repeat while a wrong pair's "comes back next round" shows (F7).

## Accessibility

- TalkBack reads the terms first, then the meanings (P3 ruling C8); each tile reads "Term: {text}" or "Meaning: {text}", with ", selected", ", matched" or, during a wrong pair's flash, ", not a match".
- Each outcome is announced when its write commits: "Matched", or the wrong-pair line (C3).
- The board scrolls once it outgrows the screen at large text, and a soft fade over its bottom edge says more is below; each tile is at least 48 tall (C4).
- A word too wide for its tile is drawn just small enough to stay whole; tiles wrap between words and never ellipsize (FE-A6 D19).
- A tile eases into its tone, surface and foreground together (standard duration; at once under Remove animations).
- Keyboard: Tab reaches each tile and Enter presses it; ForUI's focus outline is drawn outside the tile and the board leaves its reach (`focusOutlineReach`) above and below, so the scroll view never cuts it (`study_choice_focus_ring_test.dart::Match: Tab gives each of the ten tiles a whole ring…`).

## Copy

- Context line: "{deck} · Review · round {n}" · "{deck} · Learning · stage {n} of {total} · round {n}".
- Footer hint: "Tap a term and its meaning, in either order" · "Not a match — it returns next round" (during a wrong pair's flash).
- TalkBack: "Term: {text}" · "Meaning: {text}" · "{tile}, selected" · "{tile}, matched" · "{tile}, not a match" · "Matched".
