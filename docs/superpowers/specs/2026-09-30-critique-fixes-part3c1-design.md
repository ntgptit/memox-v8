# Whole-app critique 2026-09-30, part 3c-1: Study home, Study entry, Session summary — design

Status: approved 2026-09-30 ·
Path: architectural (two shared widgets and three screens) · Owner rulings 2026-09-30 (§2): R1–R5

## 1. Intent

Part 3c takes the critique's study findings and the three decisions part 1 left for it
(part 1 R6: the Study home hero, the mastery accent on Recall and Fill, the context line).
The owner split it in two: 3c-1 (Study home 13, Study entry 14, Session summary 21) and
3c-2 (the session screens 16 to 20 and what they share, including the accent and the
context line). This spec is 3c-1.

The critique called the summary "Too Empty": a hero anchored at the top over a void, the
same count three times, and "3 of 23 wrong turns" with its explanation hidden.

Success means:

- every item in §3 is built as written, each pinned by a widget test or a golden;
- no layout changes beyond what an item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review
  page; the gates pass.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file. No BR
or UC fixes the summary's tiles or the entry's overline; the tiles come from FE-A6 D17
(the study UI spec), a detail-file-level ruling this spec amends.

## 2. Owner rulings (2026-09-30)

- **R1.** 3c splits into 3c-1 (13, 14, 21) and 3c-2 (16 to 20 and shared session widgets),
  each with its own spec, plan and golden review.
- **R2.** 13: the workload block is a summary, not a door: a plain card, no hero ground and
  no chevron (DESIGN.md's "a hero leads somewhere tappable" stands).
- **R3.** 21: a tile states only a number the body does not. The finished tile goes (the
  body bolds that count); Answered shows only when it differs from the finished count; Wrong
  turns always shows, with its explanation. This amends FE-A6 D17's "three stats".
- **R4.** 21: when the content fits, the hero and its note sit centred in the space above
  the footer; longer content scrolls from the top as before.
- **R5.** 14: the hero's overline names the algorithm only; "Up to {limit} cards per
  session" is its own plain line under it.

## 3. Items

### 3.1 Screen 13, Study home

- The "Waiting for you" workload block is an `MxCard` without `isHero`: the same content
  (overline, "{n} cards due", overdue · today · across n decks), no hero ground (R2).
- DESIGN.md: no change to the rule; the 13 detail file records the block as a summary card.

### 3.2 Screen 14, Study entry

- The hero's overline reads the algorithm alone ("EIGHT BOXES", "SM-2"); a plain line under
  it reads "Up to {limit} cards per session" (R5). The combined `studyEntryOverline` key is
  replaced by the two strings.
- The direction sheet's note sits above the three options and leads with the lock: "The
  direction can't change once the session starts. SM-2 has one review mode: reveal, then
  grade yourself again · hard · good · easy." (BR-MODE-017 keeps the lock stated; this only
  moves it first.)

### 3.3 Screen 21, Session summary

- **Tiles (R3).** The finished tile (Reviewed or Learned) is gone: the body states that
  count in bold. Answered shows only when it differs from the finished count (always equal
  in a review; can differ in learning). Wrong turns ("{wrong} of {total}") always shows
  when the hero has stats.
- **Wrong turns explained.** Under the tiles, when wrong > 0, one line in the body's muted
  style: "Wrong cards came back in later rounds." (the facts card that said so is hidden
  whenever the hero has stats, part 1 R3).
- **Layout (R4).** The body is a scroll view whose content, when shorter than the viewport,
  is centred vertically above the footer; when longer, it scrolls from the top.
- **Stat value.** `MxStatTile`'s value keeps one line and scales down to fit its column
  ("41 of 241" no longer wraps). The tiles are top-aligned, so a two-line label never pushes
  a neighbour's value down.
- **App bar.** `MxAppBar` with no leading control starts its title on the gutter (16), not
  on the content density's 8, so the title lines up with the body. Every bar without a
  leading control gets this.
- **schedulerChanged copy.** "The deck switched to a different review algorithm, so its
  learning sequence changed. Every card is new again; Done takes you back to the deck to
  start learning." The footer hides "Study this deck" there, so the copy no longer points at
  it.

## 4. Verification

- A test written first for each behaviour change: 13 block not a hero; 14 overline and
  limit line, note first with the lock first; 21 tiles per case (review finished, learning
  with answered = learned, learning with answered ≠ learned, wrong = 0), the explanation
  line, centring when short and scrolling when long, the stat value on one line at 360 dp,
  the app bar title on the gutter, the schedulerChanged copy.
- vi strings for every changed key.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare`
  page before merge.
- `dart format`, `flutter analyze`, the architecture check, the guard, the full
  `flutter test` with goldens, and `tools/docs/check.py`.

## 5. Records

- DESIGN.md: `MxStatTile` (one-line value that scales down), `MxAppBar` (a bar without
  leading starts on the gutter).
- Detail files 13, 14, 21; the FE-A6 D17 amendment recorded in 21's Rulings.
- `docs/wbs_FE.md`: a line FE-D11 for part 3c-1.

## 6. Out of scope

3c-2 (session screens 16 to 20: the settle guard, pill grades, Match's meaning-first tap,
Guess's blocked state, Recall/Fill tags and accent, Fill's hint, the footer hint and the
context line), 3d (flows, including Learn offered twice on 14), part 2 (typography).
