# Study home (13): what to study first, at a glance

Status: draft for the owner's review (2026-10-20). Decisions H1–H4 are the
owner's, from the UX review of 2026-10-20.
Tier 2: one screen, but it changes BR-STUDY-076 and two screen rulings
(R2, S9).

## 1. Problem

The owner's UX review of screen 13 gave it 7.0/10. Its weakest points were
information density (6/10), interaction (6.5/10) and scannability (6.5/10).
The main issues:

- **Deck rows show counts that need no action.** Each row states all three
  counts, zeros included (BR-STUDY-076), so "0 overdue · 0 today · 2 new"
  is read before the one count that matters.
- **The workload card leads nowhere.** "Waiting for you" states the due
  total, but there is no way into it. The user has to work out from the list
  which deck to open first (ruling R2: "a summary, not a door").
- **The Resume card is tall and vague.**
  - Its title is the session's deck alone ("Words"), with no root, so it
    does not say which deck it belongs to.
  - "Review · Match · 0 of 5 cards" mixes the session, its mode and its
    progress in one line.
  - A full-width block button takes a row of its own (ruling S9).

## 2. Decisions (owner, 2026-10-20)

| # | Decision |
|---|---|
| H1 | **Deck rows.** The order stays Overdue → Today → New. Only the zero terms drop. When all three are 0, the row shows a short empty-state label in place of the counts. A deck with no card keeps "No cards yet". |
| H2 | **The workload card gets a call to action.** It opens the Study entry (14) of the priority deck, under the existing order (BR-STUDY-076): the first deck in the list that has a due card. Ties keep the list's tie-break (folded name, then id). The CTA only shows when a card is due. It does not start a session, does not change the scheduler or SRS, and does not touch a paused session. |
| H3 | **A compact Resume card.** The title shows the deck in context; the session line and the progress are split; Resume becomes a compact CTA beside the content when it fits. When the screen is narrow or the text scale is large, it drops under the content instead. Resume's behaviour and the session states do not change. Touch targets are at least 48 dp. Nothing may overflow. Ruling S9 is updated. |
| H4 | **Priority.** With a valid paused session, "Continue studying" stays above "Waiting for you". Nothing switches to the overdue cards on its own. The workload card's CTA stays as the user's own choice (BR-STUDY-075). |

## 3. Design

### 3.1 Deck rows (H1)

- `MxWorkloadBreakdownLine` with `shouldKeepZeroTerms: false`: a zero term
  drops, and the order of what is left does not change.
- **All zero, deck has cards:** the row shows "Nothing due" ("Chưa có thẻ
  đến hạn").
  - The owner's example was "Nothing to study". "Nothing due" is proposed
    instead because the row still opens: a deck with cards can be studied
    ahead (BR-STUDY-008, UC-STUDY-002 A3), so "nothing to study" would be
    false.
  - It is muted, with no glyph. The row keeps its chevron.
- **No card:** "No cards yet" stays. The row has no chevron and no target
  (BR-STUDY-076).
- **The row's spoken label:** the line is read as its words alone. Dropping
  the zeros is then also less to listen to.
- **Library:** the Library's own rows (`deck_workload_line_widget`) already
  drop zeros and say "{n} cards · nothing due". They are unchanged.
- **BR-STUDY-076** is changed:
  - from: "Ba con số MUST luôn hiển thị kể cả khi bằng 0";
  - to: a zero count MUST NOT show; the order MUST stay Overdue → Today →
    New; with all three at zero, a deck with cards MUST state that nothing
    is due.
  - Each shown count keeps its glyph and its word, and colour is never the
    only signal.

### 3.2 The workload card's CTA (H2)

- **Target:** the first deck of `workload.decks` with
  `overdueCount + dueTodayCount > 0`. The list is already in BR-STUDY-076
  order, so ties are settled by that order. When no card is due (only new
  cards, or caught up), there is no CTA. The caught-up card is unchanged.
- **Label:** "Review {deck}" ("Ôn {deck}"). The deck name is the user's own
  text, so a long one wraps to two lines and then ends in an ellipsis (The
  One Line Rule allows it for the user's text). The button keeps its
  `sizeControl` target.
- **Tone:**
  - Primary when no Resume card is shown: it is the screen's one fill.
  - Outline when Resume is shown, so Resume stays the one primary (H4).
- **Action:** a tap calls `onOpenDeck(deckId)`, the same route as the deck's
  row. It writes nothing; the Study entry decides what to start.
- **Placement:** it closes the card, 16 under the breakdown (spacing L8),
  and stretches to the card's width.
- **TalkBack:** a button named by its label.
- **Ruling R2** ("a summary, not a door") is replaced by H2. The card
  becomes a door to the deck that needs it most, never a session of its own.

### 3.3 The Resume card (H3)

- **Title:** the deck in context, "{root} › {deck}" when the session is on
  a sub-deck, and the deck alone on a root.
  - Two lines at most, then an ellipsis (the user's text).
  - Its data: the Resume queries add `r.name AS root_name`, and
    `ResumableSession` gains `rootName` (null when the session's deck is
    its root).
- **The session line:** "{kind} · {mode}", e.g. "Review · Match", in
  `body`, muted.
- **The progress line:** the track, then "{done} / {total} cards" at its
  end, in `meta`, muted, tabular.
  - No progress line while the round serves nothing (`progress == null`).
  - The progress word moves out of the session line.
- **Resume:**
  - When it fits, Resume shares the card's last row with the progress: the
    track and its count take the room left, and Resume is a compact primary
    `MxButton` (play glyph, not block) at the row's end. This removes the
    button's own row. The tile-and-text row above keeps the full width for
    the title.
  - It fits when the card's content is at least 280 wide (a 360 dp phone)
    and the text scale is below 1.3. With no progress, Resume sits alone at
    the row's end.
  - Otherwise it drops under the content as a block button, as today.
  - It is 48 dp tall at least either way.
- **What stays:** the tile, the overline and the static dot. Resume's
  behaviour stays too: refusals, failures, the toasts, the double-tap guard
  (BR-STUDY-075). Only the layout moves.
- **Ruling S9** changes from "Resume is a primary block `MxButton`" to "a
  primary `MxButton` beside the content when it fits, a block under it when
  it does not".

### 3.4 Priority (H4)

- The order does not change: Resume, then the workload card, then the decks,
  then Practice.
- With a Resume card shown, the workload CTA is outline (§3.2).

## 4. States and transitions

| State | Change |
|---|---|
| loaded | compact Resume; the workload card with an outline "Review {deck}"; rows without zero terms |
| noResume | the workload CTA is primary |
| zero (caught up) | no CTA; rows read "Nothing due" |
| only new cards due | no CTA (nothing due); rows show "{n} new" |
| noDecks, noCards, loading, error, sync, reauth | unchanged |

New transitions:

| From | Event | To |
|---|---|---|
| loaded / noResume | tap "Review {deck}" | that deck's Study entry (14) |
| loaded | a Resume or the stream makes the priority deck's due count 0 | the CTA moves to the next due deck, or goes away |

## 5. Verification

- A widget test per change:
  - zero terms drop, in order;
  - all zero shows "Nothing due";
  - the CTA's target and its absence;
  - the CTA's tone with and without Resume;
  - Resume's two layouts by width and text scale, each with a 48 dp target;
  - the Resume title with and without a root.
- A DAO test: `rootName` is null on a root session and the root's name on a
  sub-deck session.
- Goldens: the loaded, noResume and zero Study home states move. Add a
  Resume card at a 1.3 text scale.
- The Impeccable critique and audit of screen 13's states, then the final
  review and the golden-compare page.
