# Study home and Study entry: minimal UI, details on demand

Status: draft for the owner's review (2026-10-21). Tier 2: it changes the
information architecture of two screens (13, 14), adds a shared sheet, and
supersedes rulings made earlier the same day. Work goes on its own branch
and PR, after pull request 326 (DEV-323) merged.

## 1. Problem

The owner's review of screen 14's goldens (2026-10-21) found that the
screens show too much at once and lean on weight for hierarchy:

- **P1, weight.** In the resume banner two lines compete: the deck path
  (`itemTitle`, 500) and the session line (`sectionTitle`, 600). A user
  does not need to read two strong lines to decide to continue.
- **P1, full path in the card.** The path proves which deck a session
  belongs to. It is reference data, not decision data. In the card it costs
  lines and needs a fitting algorithm.
- **P1, repeated content.** Three things say the same: the section header,
  the note "Starting one ends today's session. Its answers are kept.", and
  the footer caption "Ends today's session · …". "Continue where you
  stopped." repeats the overline and the button.
- **P2, size.** Two large stat tiles reading 0 and 0 take room and say
  little. The empty state is tall for what it says.

The fix is a change of structure, not of weight or of the fitting
algorithm: show what the decision needs, and give the details to whoever
asks for them (progressive disclosure).

## 2. Decisions (owner, 2026-10-21)

| # | Decision |
|---|---|
| D1 | The cards use at most three levels: the most important line at 500, content and metadata at 400, section labels at 500. Weights come from the theme's roles; nothing sets `fontWeight` outside the theme. Key figures may keep their emphasis. |
| D2 | A Resume or Continue card shows the session deck's **name only**, at most two lines. It never shows the path, **not even for two decks of one name**: no duplicate-name query and no parent added in the card. A deck is identified and opened by its id, never by its name. Where a user has to choose between decks of one name, that choice screen gives the context. |
| D3 | An ⓘ button beside the name opens a modal bottom sheet, "Session details". It shows the full path (every level, no ellipsis, it scrolls), the session's mode and its progress. Screens 13 and 14 share it. |
| D4 | Repeated sentences go, but no business fact is lost. |
| D5 | With New = Due = 0, the hero gives up its two tiles for one inline line. |
| D6 | The shared compact metrics stay. No shared widget changes beyond what this needs. |
| D7 | "No cards yet" gets one secondary action, "Open in Library". It opens this deck in the Library, where cards are added or imported. It works for a root and for a leaf. It starts nothing and ends nothing, and Study entry gains no card management. |
| D8 | Responsive, text scaling, TalkBack and no overflow. No change to colour, the SRS, the session lifecycle, business rules or navigation (D7's link aside). |

These supersede these earlier rulings:
- the full deck path inside the card (BR-STUDY-072 wording of
  2026-10-21; detail files 13 and 14);
- the path shapes of `StudyDeckPathWidget`;
- 14's hierarchy ruling, "the banner leads with the session line in
  `sectionTitle`" (2026-10-21).

## 3. Design

### 3.1 The deck name and its details (shared)

- `StudyDeckPathWidget`, its fitting algorithm and its tests are removed.
  The data stays: `ResumableSession.deckPath` (root first) feeds the sheet,
  and `deckPath.last` is the name.
- New, in `lib/features/study/presentation/widgets/support/`:
  `StudySessionTitleWidget`.
  - It shows the session deck's name in `itemTitle` (500), at most two
    lines, then an ellipsis.
  - An `MxIconButton` (48 dp target, `AppIcons.info`) sits at the row's
    end.
    Its semantic label is "Session details". It opens the sheet.
  - The name reads as itself; the button reads its own label.
- New, in `lib/features/study/presentation/widgets/overlays/`:
  `StudySessionDetailsSheet`, opened through `showMxBottomSheet`, built on
  `MxBottomSheet`. Title: "Session details".
  - **Deck location:** a section label, then one row per level, root first.
    Each name is drawn whole: no `maxLines`, no ellipsis, wrapping as words
    do.
    - The levels above are `body` (400, muted).
    - The session's deck is `itemTitle` (500).
    - Each level is its own semantics node, in reading order.
  - **Session:** a section label, then "Mode" with "{kind} · {mode}", and
    "Progress" with "{done} / {total} cards". The progress row is absent
    while the round serves nothing, as in the card.
  - Only the sheet's child scrolls (ruling O12), so a ten-level path at
    text scale 2.0 scrolls inside the 85% sheet.
  - It reads the `ResumableSession` the card already holds. It does no read
    of its own and writes nothing (BR-STUDY-075).
- The ⓘ button is a reference, not a decision. While a start runs it stays
  enabled, because it changes nothing.

### 3.2 Screen 13: the Resume card

- The title row is now `StudySessionTitleWidget`: the name plus ⓘ, in
  place of "{root} › … › {deck}".
- Everything else is unchanged:
  - the paused tile;
  - the session line "{kind} · {mode}" (`body`, 400, muted);
  - the progress row;
  - Resume beside it or under it (ruling S9).

### 3.3 Screen 14: the resume banner

The banner, top to bottom:

1. **Overline** (unchanged): "Session from today", or "Session in another
   deck".
2. **Another deck's session only:** `StudySessionTitleWidget` (the name plus
   ⓘ).
3. **The session line**, "{kind} · {mode} · {done} / {total} cards":
   - another deck's session: `body` (400, muted), because the name above
     leads;
   - this deck's session: `itemTitle` (500), because it is the main line.
     The deck is already named by the app bar and the breadcrumb, so it has
     neither a name row nor ⓘ.
4. **The progress track** (unchanged).
5. **Removed:** "Continue where you stopped." (`studyEntryResumeBody`).
6. **Continue** (unchanged, the one primary).

With no `sectionTitle` (600) left in the banner, none of 14's cards draws a
line at 600 apart from the hero's figures.

### 3.4 Screen 14: one place for the warning

- The section "Or start another session" and its note stay. The note is
  the full explanation: a start ends today's session and keeps its answers.
- The footer caption leads with "Ends today's session" only when no note
  is shown. That happens when the body offers no choice, for example SM-2
  with due cards only (final review I2). When the note shows, the caption
  gives just the start's facts ("{shown} of {due} due · oldest first",
  "{mode} · oldest first", or no caption for Learn).
- Facts kept:
  - a start ends the open session and keeps its answers, said once where it
    applies;
  - Continue opens that session.

### 3.5 Screen 14: the hero at 0 and 0

- With New = Due = 0, the hero keeps the algorithm overline. It replaces the
  limit line and the two tiles with one line, "0 new · 0 due" (`body`, 400,
  muted, `MxTermLine`).
  - The limit is dropped there because no session can start.
  - The line reads as it is written.
- With any count above 0 the hero is unchanged, two tiles in `figure`
  (D1's key figures).
- No change to `MxStatTile`.

### 3.6 Screen 14: the nothing states

- Both keep `MxEmptyState` compact with its shared metrics (D6) and their
  titles and bodies.
- **nothingEmpty** ("No cards yet") gets a secondary action, "Open in
  Library", through `MxEmptyState`'s secondary slot (`MxButtonTone.secondary`).
  - `StudyEntryScreen` gains `onOpenInLibrary`.
  - `lib/app/` wires it to the deck's Library route,
    `context.go(AppRoutes.deck(deckId))`. Screen 14 is that route's child,
    so this is one level up the same stack.
  - The action touches no session.
- **nothing** (cards resting) gets no action.

## 4. States and transitions

### Screen 13
- `loaded` and `resumeLargeText`: the title row changes.
- New transition: loaded (Resume card) → ⓘ → the sheet; dismiss → back,
  nothing written.

### Screen 14
- **resume:**
  - the banner as in §3.3;
  - the caption as in §3.4;
  - new transition: ⓘ → the sheet → dismiss (another deck's session only).
- **nothing:** the hero line in §3.5.
- **nothingEmpty:**
  - the hero line;
  - "Open in Library" → the deck's Library level, with the session
    untouched.
- **nothing beside another deck's session:** the banner as in §3.3 and the
  hero line.
- **starting:** while a start runs, ⓘ still opens the sheet. Continue and the
  starts stay locked (BR-STUDY-004).
- Unchanged: loading, error, refused, startFailed, deckGone, and the
  direction sheet.

### The sheet's own states
| State | Shows | Evidence to add |
|---|---|---|
| open | location, then session | widget test and golden, light and dark |
| long path | 10 levels at 2.0, scrolling | widget test |
| no progress | no progress row | widget test |

Dismissing the sheet changes nothing.

## 5. Accessibility and layout

- The ⓘ target is 48 dp with the label "Session details" (`expectAccessibleTargets`).
- The name has two lines, then an ellipsis on screen. TalkBack reads the
  whole name, because a `Text`'s semantics are not cut. The sheet shows it
  whole too.
- In the sheet, every level is drawn whole, at text scale 1.0, 1.3 and 2.0,
  in bold, on a 320 dp width. Nothing is cut (`expectNoTextCut`), and each
  level reads as its own node.
- No overflow on a 360 dp phone at 1.0, 1.3 and 2.0, in bold.

## 6. What does not change

- The data: `deckPath` and `ResumableSession`.
- The rules: BR-STUDY-072 (one open session, a start ends it, nothing ends
  it by looking), BR-STUDY-075, BR-STUDY-008, the SRS.
- The colours, the tones and the shared metrics.
- The shared measurement helper (`drawnTextStyle`) stays for its other
  sites.

## 7. Verification

- **Widget tests.** Each extends the test that already owns its inputs (one
  behaviour, one test):
  - the name, two lines with an ellipsis, plus ⓘ, on 13 and on 14 (another
    deck's session only);
  - ⓘ opens the sheet with the full path, mode and progress. Dismissing it
    writes nothing (the session is still `in_progress`, the same id);
  - the sheet at 1.0, 1.3 and 2.0, in bold, on 320 dp: nothing cut, it
    scrolls, one node per level;
  - two decks of one name: each card's Continue opens its own session id;
  - the caption leads with "Ends today's session" exactly when no note
    shows, as a table over SM-2 due-only, Eight boxes, Learn and no
    session;
  - "Continue where you stopped." is gone;
  - the hero at 0 and 0 shows the one line, and with counts the tiles;
  - "Open in Library" calls `onOpenInLibrary` with the deck id. It is
    secondary, and the open session is untouched;
  - the semantics labels and 48 dp targets.
- **Goldens, re-rendered:**
  - 13: loaded, resume large text, resume deep deck;
  - 14: resume, resume eight box, resume other deck, resume deep deck,
    nothing, nothing empty deck, nothing beside another deck's session;
  - new: the sheet, light and dark.
  The owner reviews them on the golden-compare page.
- **Docs:**
  - BR-STUDY-072: the card names the deck, and the path is one tap away;
  - detail files 13 and 14: layout, states, transitions, rulings and copy,
    the screen index count, and the ARB keys. Removed:
    `studyHomeResumeTitle`, `studyHomeResumeTitleSpoken`,
    `studyEntryResumeBody`. Added: the sheet's labels, "Open in Library"
    and the hero's line.
- **Review:** an Impeccable critique of 13 and 14 against DESIGN.md before
  the plan; an audit of every changed state after the build; then the final
  whole-branch review.

## 8. Out of scope

- Other cards' weights on 13 (the workload card, the deck rows), which the
  owner judged done.
- The success tone on the empty deck's tile (owner 2026-10-21: kept).
- Follow-ups A and B on DEV-323.
