# Whole-app critique 2026-10-02 (28/40): P1s and single-screen P2s — design

Status: draft 2026-10-02, awaiting owner review ·
Path: architectural (one coordinator path in `lib/core/auth`, one shared widget changed, nine
screens) · Owner rulings 2026-10-02 (§2): F1–F10

## 1. Intent

The whole-app critique of 2026-10-02 (snapshot
`.impeccable/critique/2026-10-02T04-11-02Z__docs-shared-ui-screen-handoff-00-index-md.md`)
scored 28/40 over screens 01–33 and named three P1s and a set of P2s that each sit on one
screen. The owner chose to fix those now (scope: the P1s and the single-screen P2s); the
vocabulary (H2/H10) and core-loop (H7) findings wait, and rulings C5, BR-SEARCH-002 and D2 stay.

The findings:

- **21 (P1):** "Wrong cards came back in later rounds." shows for interrupted, left-early and
  save-error sessions, which had no later rounds; the facts card's green "Schedules updated"
  (or "Now scheduled, due tomorrow") shows under reset, content-deleted and save-error heroes.
- **30/32 (P1):** a sign-out stopped offline offers only Retry (needs a connection) or "Sign out
  now and lose N changes", under "Your data is safe"; no local data has been touched at that
  point. The Sign out row says only "Your changes are sent first"; the online confirm is primary.
- **11 (P1):** the import result shows counts only; nothing says which rows were skipped or why.
- **16a–19:** the footer hint glyph is a check in every state, "Not a match" and "Time is up"
  included.
- **22:** past-day bars are drawn at 55–70 % alpha (indigo ≈2.3:1 on the card) and the learning
  amber is ≈1.7:1 even at full strength, under the 3:1 non-text floor.
- **01:** the Library due strip reads "4 cards due" over "3 overdue · 1 today · 2 new"; New is not
  part of the total, and BR-STUDY-068 keeps New out of a hero.
- **07/09/10:** the flag is amber in the card list (≈2:1, the same hue as Learning) and plain ink
  in the editor and the detail.
- **32:** Switch account, Sign out and Delete account show chevrons, though each opens a dialog.
- **27:** a network failure shows as an amber warning with Sync now still primary; "Keep on this
  device", irreversible, confirms in primary.
- **11:** at the source step the "Choose a file" card does nothing when tapped (it is preselected),
  while the empty state below it carries its own "Choose file" primary.

Success means:

- every item in §3 is built as written, each pinned by a widget or unit test, or a golden;
- no layout change beyond what an item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review page;
  the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file.
BR-STUDY-068 keeps New out of a hero (§3.6 conforms the strip). BR-STUDY-004/019/053 fix what an
ended session keeps (§3.1 only changes what the summary says about it). UC-TRANSFER-001 step 8
asks for counts; §3.4 adds the rows and updates the UC. The auth spec's transition table
(`2026-09-30-auth-design.md`, rows #39–#41) gains a cancel row for a sign-out (§3.2).

## 2. Owner rulings (2026-10-02)

- **F1.** 21: copy and tone follow the outcome. The came-back note shows only for a finished
  session; the facts sub-line under reset, content-deleted and save-error says the answers are
  kept, on a neutral tile.
- **F2.** 30/32: a sign-out stopped before anything local was removed can be cancelled; the user
  stays signed in with every deck.
- **F3.** 32: the Sign out row names the outcome; the online confirm is warning, the offline loss
  confirm stays destructive.
- **F4.** 11: the result lists the skipped rows under their counts.
- **F5.** 22: every day's bars draw at full strength in colours that hold 3:1; Today stays marked
  by its bold label.
- **F6.** 07/09/10: the flag draws in plain ink everywhere; the filled glyph carries the state.
- **F7.** 16a–19: instructional hints take the info glyph; "comes back" lines take the repeat glyph.
- **F8.** 27: a network failure reads as a neutral note and Sync now steps down to outline; the
  Keep confirm is warning.
- **F9.** 11: tapping the "Choose a file" card opens the picker; the empty state loses its button.
- **F10.** Shared widget: `MxStackedDayBars` changes as F5 says (owner approval for
  `lib/shared`).

## 3. Items

### 3.1 Session summary tells the truth per outcome (21, F1)

- `summaryWrongExplained` ("Wrong cards came back in later rounds.") under the hero tiles shows
  only for `reviewFinished` and `learningFinished`. Left-early and interrupted heroes already say
  which cards stay due or new; they show the tiles without the note.
- The facts card (shown for reset, contentDeleted and saveError) keeps its three rows, but:
  - the first row's sub-line reads a new key `summaryFactKeptSub`: en "Kept in the history",
    vi "Đã lưu trong lịch sử", for those three outcomes;
  - its tile and its value take the neutral tone (default `MxIconTile`, `onSurface` value), not
    success;
  - the wrong-turns row's meta reads `summaryFactWrongSub` ("of {total} turns") for those
    outcomes, never `summaryFactWrongCameBack`.
- `summaryFactReviewedSub` and `summaryFactLearnedSub` stay for any outcome that still shows them
  in future; no finished outcome shows the facts card today.

### 3.2 Cancel a stopped sign-out (30/32, F2)

- A sign-out transition whose stage is still `started` (the SDK session signed in, no
  `signOutLocal`, no local reset) can be cancelled. The coordinator gains `cancelSignOut()`,
  beside `cancelSwitch()`:
  - it refuses (throws `StateError`) unless the transition is a sign-out at `started`;
  - it drops the transition record and reopens the write gate (`_drop`), then validates the
    session as `cancelSwitch` does (#22): online, the state goes Ready and sync resumes (#9);
    offline, it stays Validating on the last-known user, as an offline start does (#8), and the
    reconnect listener validates and resumes sync;
  - the user lands on Account, signed in, with every deck and every unsent change still queued.
- A predicate `canCancelSignOut(AccountTransition t)` beside `canCancelSwitch` states the rule:
  kind `signOut` and stage `started`. The transition layer shows its Cancel when
  `canCancelSwitch(t) && !isStuck` (unchanged) or `canCancelSignOut(t)` (stuck or not: nothing
  local is gone at `started`); for a sign-out it calls `cancelSignOut()`.
- The stopped banner's message, beside the "Sign out now and lose N changes" button, no longer
  says "Your data is safe on this phone." For a stopped sign-out it reads a new key
  `accountSignOutStoppedOffline`: en "No connection. Nothing has been removed yet.", vi "Không có
  kết nối. Chưa có gì bị xoá." The switch and other layers keep their copy.
- The auth spec gains a row after #39: "Sign-out | cancelled at started | drop record; open gate;
  resume sync | READY(A)".

### 3.3 Sign out row and confirm (32, F3)

- `accountSignOutHint`: en "Removes this phone's data · sign in again to get it back", vi "Xoá
  dữ liệu trên máy này · đăng nhập lại để lấy lại".
- The online Sign out confirm (`accountSignOutTitle` dialog) sets `isWarning: true`; the offline
  loss confirm keeps `isDestructive: true`.

### 3.4 The rows an import skipped (11, F4)

- The import's commit result carries the skipped rows: for each invalid or duplicate row, its
  source row number, its first cell (the term as read) and its kind (and the rejection reason for
  an invalid row). Blank rows stay counted only (BR-TRANSFER-002: they are not errors).
- Under "Skipped — duplicates" and "Skipped — invalid rows" the result lists those rows, each
  "Row {n} · {term}" with the reason (invalid) or "already in the deck" / "repeated in the file"
  (duplicate), reusing the preview's row reasons. Each list shows its first five rows; "Show all
  {count}" expands it in place.
- `importSkipNote` drops "Fix the invalid rows in your source and import again; " and keeps the
  duplicate rule: en "Duplicates are skipped by the case-insensitive term + meaning.", vi following
  the existing translation of that clause.
- UC-TRANSFER-001 step 8 adds: the result lists the skipped rows with their row number and reason.

### 3.5 Footer hint glyphs (16a–19, F7)

- 16a (both states), 17 idle, 18 (both states), 19 counting and revealed: `AppIcons.info`.
- 17 wrong pair ("Not a match — this pair comes back next round") and 19 timed out ("This card
  comes back in a later round"): `AppIcons.repeat`.
- 16 Browse keeps `swipe`; 20 Fill keeps `edit`.

### 3.6 Library due strip (01, BR-STUDY-068)

- The due strip's breakdown shows overdue and today only (the two halves of its total); New
  leaves the strip. New stays on each deck's row and on the deck summary card, as today.

### 3.7 Progress day bars (22, F5, F10)

- `MxStackedDayBars` draws every day at full strength (no alpha fade); Today stays marked by its
  bold label and "Today" text.
- The Progress caller passes series colours that hold 3:1 on the card in both themes: reviewing
  stays `primary`; learning takes `statusLearningInk` in light (the amber kept for dark, where it
  already holds). The legend dots take the same colours.
- A test asserts each series colour's contrast on the card ground ≥ 3:1, light and dark.

### 3.8 One flag treatment (07, 09, 10, F6)

- The card list row's flag draws in the row's default icon ink (no warning colour); the filled
  `flagged` glyph carries the state, as in the editor and the detail. Ruling E-L2 is superseded.

### 3.9 Account action rows (32)

- Switch account, Sign out and Delete account set `isAction: true`: no chevron, as DESIGN.md's
  `MxSettingsRow` line asks for a row that opens a dialog.

### 3.10 Sync offline and Keep (27, F8)

- When the last failure's kind is `network` and nothing was refused, the screen shows an `MxNote`
  with the existing `syncFailedNetwork` sentence instead of the warning `MxInlineBanner`; Sync
  now is outline in that state. Server, sign-in and unknown failures keep the warning banner.
- The Keep dialog's confirm sets `isWarning: true`.

### 3.11 Import source picks from its card (11, F9)

- Tapping the "Choose a file" option card opens the file picker (the same path as today's
  empty-state action), whether or not the card is already selected; tapping "Paste text" still
  switches to the paste field.
- The empty state below keeps its title and body and loses its action button.
- The 11 detail file's line "The file option picks through `file_picker`" becomes true.

## 4. Verification

- A test written first for each behaviour:
  - 21: an interrupted, a left-early and a save-error summary with wrong turns show no came-back
    note; a finished one does; reset and save-error facts show "Kept in the history" on a neutral
    tile and the plain turns line;
  - 30/32: the coordinator cancels a sign-out stopped offline (record dropped, gate open, still
    signed in, Validating until the reconnect, then Ready with sync resumed) and refuses after
    `started`; the layer shows Cancel for that state
    and the stopped-offline copy;
  - 32: the Sign out hint copy; the online confirm is warning, the offline loss confirm
    destructive; the three command rows show no chevron;
  - 11: a partial import lists its invalid and duplicate rows with row numbers and reasons,
    five at first, all after "Show all"; tapping the "Choose a file" card opens the picker; the
    empty state has no button;
  - 16a–19: each state's glyph;
  - 01: the due strip shows no "new";
  - 22: every bar at full alpha; the series colours hold 3:1 in both themes;
  - 07: the row flag is not the warning colour;
  - 27: a network failure shows a note and an outline Sync now; the Keep confirm is warning.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare` page
  before merge.
- The gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `TZ=UTC flutter test --tags golden`.

## 5. Records

- DESIGN.md: `MxStackedDayBars` (full strength, Today by label, series colours at 3:1).
- Detail files 01, 07, 09, 10, 11, 16a, 17, 18, 19, 21, 22, 27, 30, 32: one ruling line each, and
  any stale row.
- `docs/features/transfer/usecases` UC-TRANSFER-001 step 8; the auth spec's transition table.
- `docs/wbs_FE.md`: a row FE-D17.

## 6. Out of scope

Vocabulary and help (H2/H10), the core loop (H7: C5, BR-SEARCH-002, D2), Welcome (29), and the
other multi-screen findings of the 2026-10-02 critique.
