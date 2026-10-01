# Whole-app critique 2026-09-30, part 3c-2: the session screens — design

Status: approved 2026-10-01 ·
Path: architectural (two shared widgets narrowed, three new study-local behaviours, five
screens) · Owner rulings 2026-10-01 (§2): R1–R9

## 1. Intent

Part 3c-2 takes the critique's findings on the session screens, Browse (16), Self-assess (16a),
Match (17), Guess (18), Recall (19) and Fill (20), and the two decisions left for it: the
mastery accent on Recall and Fill (part 1 R6, tone pass T8) and the context line's length
(part 2 §6).

The critique rated each of these screens "Balanced" and named one or two faults each:

- 16: the footer hint wraps with its glyph detached, and the CTA sits about 17 dp higher or
  lower than in other modes;
- 16a: Reveal swaps its button for the grades in place with no settle guard, so a double tap
  grades Hard or Good; the grades are rounded rectangles where other session buttons are pills;
- 17: a meaning tapped first does nothing, and the two columns differ only by weight;
- 18: the context line's "FIRST PICK COUNTS" wraps and repeats the footer; the blocked state is
  top-heavy and shows three × glyphs; a wrong answer is held 1200 ms where Fill and Recall wait;
- 19 and 20: the outcome tags lose their warning colour in light; the mastery-green accent has
  no recorded ruling; Fill's hint is 12 px and pushes the typed text down about 14 dp.

Success means:

- every item in §3 is built as written, each pinned by a widget test or a golden;
- a double tap on a button that swaps in place commits nothing;
- no layout change beyond what an item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review page;
  the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file.
BR-STUDY-062 requires Match to accept a meaning tapped first; the app breaks it today, so §3.3
is a fix, not a choice. No BR fixes the accent, the hint or the guard.

## 2. Owner rulings (2026-10-01)

- **R1.** Settle guard: for 400 ms after a session screen swaps its actions in place, taps on
  them are ignored, and the new buttons rise from muted to full. It covers every such swap: 16a's
  Show answer becoming the grades, 19's Show meaning becoming Forgot · Remembered (and its
  timeout becoming Continue), and 20's Check becoming Continue on a wrong answer.
- **R2.** Guess keeps its hold: 1200 ms or until a tap, right or wrong (FE-A6 G1 stands).
- **R3.** Match: meaning cells take the recessed ground of an answer face; term cells stay raised.
  The hint reads "Tap a term and its meaning, in either order".
- **R4.** Fill: the card's hint takes a Material 3 type-scale role larger than the footer's
  12 px, and its line is reserved before it shows, so the typed text never moves.
- **R5.** Guess blocked: the notice is centred vertically, and "Close the session" carries no ×
  glyph; the top bar's × and the notice's glyph remain.
- **R6.** Footer hint: the glyph sits inline before the text's first line and wraps with it; the
  hint always reserves two lines, so the CTA stands in one place in every mode.
- **R7.** 16a's grades keep their rounded-rectangle shape.
- **R8.** Recall and Fill take Indigo, the default accent (part 1 R6, tone pass T8).
- **R9.** The context line holds at most two lines; Guess drops "first pick counts", which its
  footer hint already states.

## 3. Items

### 3.1 Settle guard (R1)

- A study-local support widget, `StudySettleGuardWidget`, wraps a screen's CTA row and takes a
  `phase` value. When the phase changes after the first build, the row ignores pointers for
  400 ms (a constant of the widget, as Guess's hold and Match's flash are) while its opacity eases from
  `AppOpacity.muted` to 1. Under Remove animations the row shows at full opacity at once and
  still ignores taps for the 400 ms. The first build never guards: a turn's first actions are
  not a swap.
- The guard runs on an animation controller, so `pumpAndSettle` and the goldens see it finished.
- Callers and their phase:
  - 16a `StudySelfAssessWidget`: revealed or not;
  - 19 `StudyRecallWidget`: counting, revealed, or timed out;
  - 20 `StudyFillWidget`: wrong or not.
- TalkBack: the guarded row keeps its semantics; focus moves too slowly for a double tap, and a
  tap that lands inside the window is simply ignored.
- DESIGN.md's `StudyCtaRow` line records the rule (it has no Motion section): an action swapped in place under the finger settles for
  400 ms before it takes a tap.

### 3.2 Footer hint (R6)

- `SessionFooterHintWidget` draws one centred `Text.rich`: the glyph as an inline span before
  the text, aligned to the first line's middle, then the text. A wrapped line starts under the
  glyph, not beside a detached one.
- The hint's box is at least two lines of `sessionHint` at the current text scale, so a one-line
  hint and a two-line hint put the CTA row at the same height. A third line still grows the box
  (the Text Grows Rule).
- The glyph stays excluded from semantics; the text is read as before. The hint still steps aside
  while the keyboard is up.

### 3.3 Match (R3, BR-STUDY-062)

- Either side may be tapped first. A tapped tile is selected; tapping a tile of the same column
  moves the selection; tapping a tile of the other column makes the pair, which is answered on
  the term's card whichever side came first (BR-STUDY-062). A matched tile stays inert.
- An idle meaning tile has the recessed ground (`surfaceContainerLow`, as the answer face);
  an idle term tile stays raised (`surfaceContainerLowest`). Selected, right and wrong tiles keep
  the surfaces they have today in both columns: those states carry their own colour, and their
  inks were measured on those grounds.
- `studyMatchHint`: "Tap a term and its meaning, in either order" / "Chạm một thuật ngữ và nghĩa
  của nó, theo thứ tự nào cũng được".
- TalkBack: a selected meaning reads as selected, as a term does today.

### 3.4 Fill's hint (R4)

- The card's hint row uses `studyDetail`, the Material 3 body-medium role (14/400, variant
  ink) that a study card already gives its pronunciation and example. The owner ruled for the
  M3 type scale (2026-10-01): the popup's "13 px, caption size" has no role in it, as the
  caption is 12 px.
- When the card has a hint, its row is laid out from the start and stays invisible, without
  semantics, until the hint is shown. The field never moves. A card without a hint reserves
  nothing.

### 3.5 Guess blocked (R5)

- The notice sits centred in the body when it fits and scrolls from the top when it does not,
  as the summary does (3c-1 R4). The summary's private `_CentredScroll` moves to a study-local
  support widget, `StudyCentredScrollWidget`, and both screens use it. It stays in the study
  feature: both callers are there.
- The button reads "Close the session" alone. `MxErrorState.actionIcon` defaults to the retry
  glyph and cannot be empty today, so it becomes nullable: null draws no glyph, and the
  default stays.

### 3.6 Recall and Fill accent (R8)

- `StudySessionScreen` passes no accent: every mode's top bar is Indigo, its chip text in
  `primaryInk`.
- `MxStudyTopBar` loses `accent` and `accentInk`: no product screen passes them any more (no
  speculative structure; owner, 2026-10-01). The gallery's Recall sample keeps its full track and drops the accent.
- The detail files of 16, 19 and 20 drop "mastery accent"; DESIGN.md's `MxStudyTopBar` line
  says the bar is Indigo in every mode.

### 3.7 Context line (R9)

- `SessionContextLineWidget` sets two lines at most, with an ellipsis; a screen reader still
  hears the whole sentence.
- Guess's line stops at the round: "Nhà hàng · REVIEW · ROUND 1". The `studyContextFirstPick`
  key goes from both ARBs; the footer's "Only your first pick counts" stays.

### 3.8 Recorded, no code change

- **R2.** Guess's hold stays; the 18 detail file records the ruling.
- **R7.** 16a's grades keep their rounded rectangles: they judge the learner rather than act,
  and the shape keeps them apart from the pills. The 16a detail file records it.
- **19, 20 outcome tags.** The tone pass (T1) restored their warning colour in light; nothing
  remains.

## 4. Verification

- A test written first for each behaviour:
  - the guard: a tap at 100 ms after a swap does nothing, a tap at 450 ms commits; the first
    build takes a tap at once; under Remove animations the row is at full opacity and still
    guarded; on 16a, 19 and 20 a second tap on the swapped row inside the window commits
    nothing;
  - the footer hint: one-line and two-line hints put the CTA at the same y; the glyph is an
    inline span on the first line;
  - Match: meaning then term makes the pair on the term's card; a second meaning moves the
    selection; the idle meaning ground is `surfaceContainerLow` and the idle term ground is
    `surfaceContainerLowest`;
  - Fill: the field's y is the same before and after Show hint; the hint row uses `studyDetail`;
  - Guess blocked: the notice is centred on a tall screen, and its button has no icon;
  - the accent: Recall and Fill bars draw the primary fill and the `primaryInk` chip;
  - the context line: two lines at most with an ellipsis, Guess's line without the first-pick
    words, in English and Vietnamese.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare` page
  before merge.
- The gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `TZ=UTC flutter test --tags golden`.

## 5. Records

- DESIGN.md: the settle rule on the `StudyCtaRow` line, the footer hint's inline glyph and two-line reserve,
  `MxStudyTopBar` Indigo in every mode, Match's recessed meaning column.
- Detail files 16, 16a, 17, 18, 19 and 20: one ruling line each.
- `docs/wbs_FE.md`: a row FE-D14 for part 3c-2.

## 6. Out of scope

3d (per-screen flows), the grade buttons' shape (R7), and Guess's hold (R2).
