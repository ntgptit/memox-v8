# Study home scan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let screen 13 say at a glance what to study first and where to
start, with less to read.

**Architecture:** The data layer adds the root's name to the Resume read.
The domain model names the priority due deck. The three widgets change
their layout; the screen wires them.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6, Riverpod, Drift.

**Spec:** `docs/superpowers/specs/2026-10-20-study-home-scan-design.md`

Execution: native (owner, 2026-10-20: "Duyệt, viết plan và làm luôn").

## Global Constraints

- Nothing on screen 13 writes, except Resume (BR-STUDY-075). The new CTA
  navigates only.
- Order: Resume, workload, decks, Practice. Overdue → Today → New inside a
  line.
- Touch targets are 48 dp at least; nothing overflows at 360 dp or at a 1.3
  text scale.
- The copy below is exact:
  - en "Nothing due" / vi "Chưa có thẻ đến hạn";
  - en "Review {deck}" / vi "Ôn {deck}";
  - en "{done} / {total} cards" / vi "{done} / {total} thẻ".

## Review Focus

1. Two decks tied for priority: the CTA picks the one listed first (name
   fold, then id). Pinned in Task 2.
2. Only new cards in the library: no CTA. Pinned in Task 2.
3. A deck name of 80 characters on the CTA and the Resume title: two lines,
   then an ellipsis; no overflow. Pinned in Task 3.
4. A double tap on the CTA opens one Study entry. The deck row's callback
   is reused, which `go`es (no stacking): a code read, as for the rows; the
   screen test pins that the CTA calls it.
5. Text scale 1.3 at 360 dp: Resume drops under the content. Pinned in
   Task 3.

---

### Task 1: The root's name on the Resume read; rows without zeros (H1)

- `study_view_queries.drift`: `r.name AS root_name` in `resumableSession`
  and `resumableSessionOfDeck`. `ResumableRow` gains `rootName`. The
  mapper sets `ResumableSession.rootName` to null when
  `session.deckId == session.rootId`.
- `MxWorkloadBreakdownLine` loses `shouldKeepZeroTerms`: this row was its
  last caller, so a zero term always drops. In `study_home_decks_widget.dart`
  the fallback is "Nothing due" for a deck with cards and "No cards yet" for
  one without.
- ARB keys `studyHomeNothingDue` (en and vi); run gen-l10n.
- Tests: the DAO or repository test for `rootName`. The screen test: zeros
  drop, the order holds, all zero reads "Nothing due". Update the tests that
  pinned all three counts.

### Task 2: The workload card's CTA (H2, H4)

- `RootDeckWorkload.priorityDueDeck`: the first deck with a due card, or
  null.
- `StudyHomeWorkloadWidget` takes `onOpenDeck` and `hasResume`. The CTA is
  "Review {deck}" (`studyHomeReviewDeck`), primary without Resume and
  outline with it, block, 16 under the breakdown. There is none while
  nothing is due.
- Tests: the target, ties, only new cards, the tone, and a tap opening the
  deck.

### Task 3: The compact Resume card (H3)

- Title "{root} › {deck}" (`studyHomeResumeTitle`), at most two lines.
- Session line "{kind} · {mode}" (`studyEntryResumeLineNoProgress`).
- Last row: the track and "{done} / {total} cards"
  (`studyHomeResumeProgress`), Resume at the end. The row goes under the
  content as a block below a 280 content width or at a text scale of 1.3
  or more.
- Tests: both layouts, the 48 dp target, the title with and without a root,
  a long name.

### Task 4: Docs, goldens, verification

- BR-STUDY-076 and UC-STUDY-002 step 3. Detail file 13: Layout, States,
  Transitions, Rulings (R2, S9, BR-STUDY-076), Copy. Regenerate
  `docs/_generated`.
- Run `run_goldens.sh --update`, then the full gate and goldens. Add a
  golden of the Resume card at a 1.3 text scale.
- One Impeccable audit of screen 13's states, the final Opus review, and
  the golden-compare page. Then the PR, after the owner's approval.
