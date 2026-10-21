# Study home and Study entry: minimal UI, details on demand

Status: approved by the owner (2026-10-21), then revised the same day after
the Impeccable critique and the owner's rulings D9–D13 (marked "rev").
Tier 2: it changes the information architecture of two screens (13, 14),
adds a shared sheet and two shared-widget changes, and supersedes rulings
made earlier the same day. It is built on its own branch and PR, after
pull request 326 (DEV-323) merged.

## 1. Problem

The owner reviewed screen 14's goldens on 2026-10-21 and found that the
screens show too much at once and lean on weight for hierarchy:

- **P1, weight.** In the resume banner, two lines compete: the deck path
  (`itemTitle`, 500) and the session line (`sectionTitle`, 600). A user
  does not need to read two strong lines to decide to continue.
- **P1, full path in the card.** The path proves which deck a session
  belongs to. It is reference data, not decision data. In the card it costs
  lines and needs a fitting algorithm.
- **P1, repeated content.** Three things say the same: the section header,
  the note "Starting one ends today's session. Its answers are kept.", and
  the footer caption "Ends today's session · …". "Continue where you
  stopped." repeats the overline and the button.
- **P2, size.** Two large stat tiles that read 0 and 0 take room and say
  little. The empty state is tall for what it says.

The fix is a change of structure, not of weight or of the fitting
algorithm. Show what the decision needs, and give the details to whoever
asks for them (progressive disclosure).

## 2. Decisions (owner, 2026-10-21)

| # | Decision |
|---|---|
| D1 | The cards use at most three levels: the most important line at 500, content and metadata at 400, section labels at 500. Weights come from the theme's roles, and nothing sets `fontWeight` outside the theme. Key figures may keep their emphasis. |
| D2 | A Resume or Continue card shows the session deck's **name only**, at most two lines, then an ellipsis. It never shows the path, not even for two decks of one name: no duplicate-name query and no parent in the card. A deck is identified and opened by its id, never by its name. Where a user has to choose between decks of one name, that choice screen gives the context. |
| D3 (rev) | An ⓘ button beside the name opens a modal bottom sheet, **"Deck location"**, with the deck's **full path only**: every level, no ellipsis, scrolling. It does not repeat the session's mode or progress, which the card already shows. Screens 13 and 14 share it. |
| D4 | Repeated sentences go, but no business fact is lost. |
| D5 (rev) | When New = Due = 0, the hero keeps only the algorithm. The two tiles, the limit line and any "0 new · 0 due" line go, because the empty state below already says that nothing is left to study. |
| D6 | The shared compact metrics stay. No shared widget changes beyond what this needs. |
| D7 | "No cards yet" gets one secondary action, "Open in Library". It opens this deck in the Library, where cards are added or imported. It works for a root and for a leaf. It starts nothing and ends nothing, and Study entry gains no card management. It shows only when the deck truly has no card, never when cards are resting. |
| D8 | Responsive layout, text scaling, TalkBack and no overflow. No change to colour, the SRS, the session lifecycle, business rules or navigation (D7's link aside). |
| D9 (rev) | Screen 13: the deck name takes precedence over the decorative paused tile. The tile hides at text scale 1.3 or more, **or** when the width beside it is too narrow for the name. That is measured: the name, as drawn, must fit two lines beside the tile. The ⓘ button always stays. |
| D10 (rev) | `MxEmptyState` action spacing is fixed at the shared owner. The first rendered action sits 24 dp under the body, whatever its tone. A second rendered action sits 8 dp under the first. No action, no gap. |
| D11 (rev) | The empty-state title on screen 14 is at 500, through a **quiet-title variant** of `MxEmptyState`. The global compact title stays at 600: it is used in about 18 files, and the owner prefers a fitting variant over a global change. |
| D12 (rev) | The ⓘ glyph (`AppIcons.info`) stays for the details button, although 14's note uses the same glyph, statically. |

These supersede several earlier rulings:

- the full deck path inside the card (the BR-STUDY-072 wording of
  2026-10-21; detail files 13 and 14);
- `StudyDeckPathWidget`'s path shapes;
- 14's hierarchy ruling that the banner leads with the session line in
  `sectionTitle` (2026-10-21);
- the 13 Resume card's "paused tile unchanged" (ruling S9 keeps Resume's
  placement).

## 3. Design

### 3.1 The deck name and its location (shared)

- `StudyDeckPathWidget`, its fitting algorithm and its tests are removed.
  Its ARB keys go with it: `studyHomeResumeTitle` and
  `studyHomeResumeTitleSpoken`.
- The data stays:
  - `ResumableSession.deckPath` (root first) feeds the sheet;
  - `deckPath.last` is the name.
- **`StudySessionTitleWidget`**, new, in
  `lib/features/study/presentation/widgets/support/`:
  - It draws the deck's name in `itemTitle` (500), at most two lines, then
    an ellipsis on screen. TalkBack reads the whole name, because a
    `Text`'s semantics are not cut.
  - It also takes a `line` slot: the session line under the name, at
    `spaceRowLine`.
  - The `MxIconButton` (`AppIcons.info`, 48 dp target, label "Deck
    location") trails the whole name-and-line block: a `Row`, centred, of
    `Expanded(Column(name, line))` and ⓘ. That way the 48 dp box does not
    pad a one-line name (critique B10).
  - The row has no spacing of its own. The glyph's padding is the gap, at
    least `space8`.
  - The button's focus outline must stay inside the card's padding
    (`context.focusOutlineReach`).
  - ⓘ is disabled while a start or a Resume runs, so that the session route
    never lands over an open sheet (critique A9). Everything else on the
    screen is locked then too (BR-STUDY-004).
- **`StudyDeckLocationSheet`**, new, in
  `lib/features/study/presentation/widgets/overlays/`:
  - It opens through `showMxBottomSheet` on `MxBottomSheet(title: "Deck
    location")`. The title is the sheet head in `sectionTitle`, as every
    sheet's is. There is no footer, and it is dismissed by grabber, scrim or
    drag.
  - The child is padded by `context.screenMargin` and holds one card of an
    `MxDividedColumn`, with one row per level, root first:
    - Each row is a plain `Text`, with no `maxLines` and no ellipsis,
      wrapping as words do. Padding is `space12` vertical and `space16`
      horizontal.
    - The hairlines between rows mark the levels. There is no indent: ten
      levels at text scale 2.0 would starve the width.
    - The levels above are `body` (400) in `mutedForeground`. The session's
      deck is `itemTitle` (500).
  - **Semantics:** each level is one node, labelled with its depth:
    - "{name}, level {i} of {n}";
    - the session's deck: "{name}, the session's deck, level {n} of {n}".
    - These are ARB keys, en and vi.
    - The title keeps `header` and names the route.
    - Dismissing the sheet returns focus to ⓘ.
  - Only the child scrolls, and the head stays. A ten-level path at 2.0, in
    bold, on 320 dp scrolls to its last level.
  - It is a snapshot: it shows the `deckPath` the card held when it opened,
    with no read of its own and no write (BR-STUDY-075). Renaming a level
    or ending the session while it is open changes nothing in it. That is
    recorded in the Transitions tables.

### 3.2 Screen 13: the Resume card

- The heading is the paused tile, then `StudySessionTitleWidget` with the
  session line "{kind} · {mode}" (`body`, 400, muted) in its `line` slot.
- **D9.** The tile shows only while the text scale is under 1.3 **and**
  the name, as drawn, fits two lines in the width left beside the tile:
  - The check measures with `drawnTextPainter` in the name's own role,
    inside a `LayoutBuilder`.
  - Otherwise the tile is gone and the name starts at the card's edge.
  - The name never measures more than two lines, because the cut is its
    `maxLines`.
- The progress row and Resume are unchanged (ruling S9).
- The count "{done} / {total} cards" stays `meta` (500). DESIGN names
  counts `meta`, and a role is never restyled. Recorded as a ruling: the
  same fact is `meta` on 13, part of the session line on 14.

### 3.3 Screen 14: the resume banner

The banner, top to bottom:

1. **Overline.** It is unchanged: "Session from today", or "Session in
   another deck".
2. **The session.**
   - For another deck's session, `StudySessionTitleWidget`: the name plus
     ⓘ, with the session line "{kind} · {mode} · {done} / {total} cards"
     (`body`, 400, muted, `MxTermLine`) in its `line` slot.
   - For this deck's session, the session line alone, in `itemTitle` (500,
     foreground, `MxTermLine`). App bar and breadcrumb already name the
     deck, so it has no name row and no ⓘ.
   - Recorded as a ruling: "the card's lead line is `itemTitle`". The role
     follows which line leads (a sibling), not a state.
3. **The progress track.** Unchanged.
4. **Continue** (the one primary). It sits `space16` under the track, or
   under the line when there is no track.

Removed: "Continue where you stopped." (`studyEntryResumeBody`) and its
`space4` gap.

Recorded risk (accepted, D2): another deck's session can share a name with
the deck the app bar names. The overline and ⓘ tell them apart.

### 3.4 Screen 14: one place for the warning

- **One predicate.** "The note is shown" is computed once, in
  `study_entry_offer_state.dart`:
  - it holds when a session can be continued and the body offers a choice;
  - the body's section and note read it;
  - so does the footer's caption.
- The section "Or start another session" and its note stay. The note is the
  full explanation: a start ends today's session and keeps its answers.
- The footer caption leads with "Ends today's session" **only when the note
  is not shown and a session can be continued**. Examples:
  - SM-2 with due cards only;
  - Eight boxes with one mode available.
- With the note shown, the caption gives only the start's facts:
  - "{shown} of {due} due · oldest first";
  - "{mode} · oldest first";
  - Learn: "Nothing due. Review opens once cards are due." when Due = 0.
    It keeps today's caption for Learn and does not drop it (critique E20).
- The failed footer (Try again) follows the same rule. With no note shown,
  its caption leads with "Ends today's session", so a retry never ends a
  session unannounced.
- Starting: "Starting…" replaces the caption, as today.
- Nothing states: no footer and no note. Nothing can start.

### 3.5 Screen 14: the hero at 0 and 0

- When New = Due = 0, the hero is its algorithm overline alone (D5).
- When any count is above 0, the hero is unchanged: two tiles in `figure`
  (D1's key figures).
- No change to `MxStatTile`.

### 3.6 Screen 14: the nothing states and `MxEmptyState`

- **D10, the shared spacing fix in `MxEmptyState`.**
  - The first rendered action, of any tone, sits `space24` under the body
    (or the title).
  - Each later action sits `space8` under the one before.
  - With no action, there is no gap.
  - Verification:
    - one widget test per combination: none; primary; secondary; primary
      and secondary (and a tertiary under them, as today);
    - goldens for the four combinations in the gallery's empty-state
      section, compact and full;
    - every consumer checked for no pixel change: today none renders a lone
      secondary, so only the new use moves.
- **D11, a quiet-title variant of `MxEmptyState`.** The plan names the
  parameter, in the sense of `isQuiet` / a title-emphasis enum.
  - The title is drawn in `itemTitle` (500) in place of `sectionTitle`
    (600).
  - It is opt-in. Only 14's two nothing states use it.
  - The compact metrics are unchanged.
  - Its gallery entry and test are added.
- **nothing** (cards resting): "Nothing to study in this deck" with the
  body unchanged, quiet title, no action.
- **nothingEmpty** ("No cards yet"): quiet title, plus one secondary action,
  "Open in Library":
  - `StudyEntryScreen` gains `onOpenInLibrary`, and `lib/app/` wires it to
    `context.go(AppRoutes.deck(deckId))`. Screen 14 is that route's child,
    so this is one level up the same stack. A second tap does the same.
  - It is disabled while a start runs (BR-STUDY-004).
  - It touches no session.

## 4. States and transitions

**Screen 13**

- `loaded` and `resumeLargeText`: the heading changes (§3.2). At 1.3 the
  tile is gone.
- New: loaded (Resume card), tap ⓘ → the Deck location sheet → dismiss →
  back. Nothing is written.
- ⓘ while Resume runs: disabled.

**Screen 14**

- resume:
  - the banner as in §3.3;
  - the caption as in §3.4;
  - another deck's session: ⓘ → the sheet → dismiss.
- nothing: the hero as in §3.5; quiet title.
- nothingEmpty:
  - the hero as in §3.5; quiet title;
  - "Open in Library" → the deck's Library level, with the session
    untouched.
- nothing beside another deck's session: the banner as in §3.3 and the
  hero as in §3.5.
- starting: ⓘ and "Open in Library" are disabled with every start
  (BR-STUDY-004).
- The note appears or vanishes live (the counts change, a refused start).
  The caption gains or drops its lead in the same frame.
- Unchanged: loading, error, refused, startFailed (apart from §3.4's
  lead), deckGone, and the direction sheet.

**The sheet**

| State | Shows | Evidence to add |
|---|---|---|
| open | the levels, root first, the deck marked | widget test and golden, light and dark |
| long path | 10 levels at 2.0, in bold, on 320 dp, scrolling | widget test |
| session ends or a level is renamed while open | the snapshot it opened with | widget test |

## 5. Accessibility and layout

- ⓘ: a 48 dp target, reading "Deck location, button"
  (`expectAccessibleTargets`).
- Focus order:
  - 13: overline, name, ⓘ, session line, count, Resume;
  - 14 (another deck): overline, name, ⓘ, session line, Continue.
- The name: two lines and an ellipsis on screen; TalkBack reads it whole.
- In the sheet, every level is drawn whole at text scale 1.0, 1.3 and 2.0,
  in bold, on 320 dp. Nothing is cut (`expectNoTextCut`), and each level
  is one node labelled with its depth.
- No overflow on 320 and 360 dp phones at 1.0, 1.3 and 2.0, in bold. D9
  is tested for long Vietnamese names: the tile hides when the name needs
  the room.
- No `FontWeight` literal in the touched feature widgets (the guard).

## 6. What does not change

- **Data.** `deckPath` and `ResumableSession`.
- **Rules.** BR-STUDY-072: there is one open session, a start ends it, and
  looking ends nothing. BR-STUDY-075, BR-STUDY-008 and the SRS also hold.
- **Look.** The colours and tones, and the shared compact metrics (D11 is
  opt-in).
- **The shared measurement helper.** `drawnTextStyle` stays; D9 uses it
  too.

## 7. Verification

- **Widget tests.** Each extends the test that already owns its inputs
  (one behaviour, one test). Cases:
  - **The name.** Two lines and an ellipsis, plus ⓘ: on 13, and on 14 for
    another deck's session only.
  - **D9.** On 13 at 320 and 360 dp, scales 1.0, 1.3 and 2.0, with bold
    on: the tile shows or hides as the rule says; there is no overflow; ⓘ
    always shows.
  - **The sheet.**
    - ⓘ opens it with every level. Dismissing writes nothing: the session
      is still `in_progress`, with the same id.
    - At 1.0, 1.3 and 2.0, in bold, on 320 dp: nothing is cut, the sheet
      scrolls, and each level reads with its depth.
    - It is a snapshot.
  - **Two decks of one name.** Each card's Continue or Resume opens its own
    session id.
  - **The predicate.** As a table: SM-2 due-only; Eight boxes with one mode;
    Eight boxes with several modes; Learn with Due = 0; no session; the
    failed footer; the live flip. In each, the note shows exactly when the
    caption does not lead.
  - **The banner.** "Continue where you stopped." is gone, and Continue
    sits `space16` under the track.
  - **The hero at 0 and 0.** It is the overline alone. With counts, the
    tiles show.
  - **"Open in Library".**
    - It shows only on nothingEmpty, and it is secondary.
    - It calls `onOpenInLibrary` with the deck id, and the open session is
      untouched.
    - It is disabled while a start runs.
  - **`MxEmptyState`.** The four action combinations (D10) and the quiet
    title (D11).
  - **Accessibility.** Semantics labels, focus order, and 48 dp targets.
- **Goldens.**
  - Re-rendered on 13: loaded, resume large text, resume deep deck.
  - Re-rendered on 14: resume, resume eight box, resume other deck, resume
    deep deck, nothing, nothing empty deck, nothing beside another deck's
    session.
  - New: the sheet, light and dark; the `MxEmptyState` action
    combinations and quiet title in the gallery.
  - Any other golden that moves must be explained, or it is a regression
    (D10).
  - The owner reviews them on the golden-compare page.
- **Docs.**
  - BR-STUDY-072: the card names the deck, and its location is one tap
    away.
  - Detail files 13 and 14: layout, states, transitions, rulings, copy and
    the index count.
  - DESIGN.md / forui-shared-widgets: `MxEmptyState`'s action spacing and
    quiet-title variant.
  - ARB: removed `studyHomeResumeTitle`, `studyHomeResumeTitleSpoken` and
    `studyEntryResumeBody`. Added the sheet title, the level labels and
    "Open in Library".
- **Review.** An audit of every changed state after the build. Then the
  final whole-branch review.

## 8. Out of scope

- The weights of 13's other cards, such as the workload card and the deck
  rows, which the owner judged done.
- The success tone on the empty deck's tile (owner 2026-10-21: kept).
- Follow-ups A and B on DEV-323.
