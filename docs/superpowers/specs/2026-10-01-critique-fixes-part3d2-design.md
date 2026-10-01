# Whole-app critique 2026-09-30, part 3d-2: low-impact and cosmetic findings — design

Status: draft 2026-10-01 ·
Path: architectural (eleven screens, two shared widgets widened) ·
Owner rulings 2026-10-01 (§2): E1–E14

## 1. Intent

Part 3d-2 closes the critique's low-impact and cosmetic per-screen findings that part 3d-1 left
for it (3d-1 spec §6, owner ruling D1), plus four minors the 3d-1 final review deferred. An
audit of 2026-10-01 re-checked each one against the code at `d7bdbb99`; all are still open.

The findings:

- 01: the sort sheet reads "Newest" over the hint "Newest first"; while decks are reordered the
  search field still opens search.
- 02: the reset confirm is a plain Indigo button for an irreversible loss of progress; the
  unlocked lock strip is a hero ground that leads nowhere.
- 03: the starter sheet repeats the card and sub-deck counts the card already states, and says
  nothing about the algorithm locking (BR-SRS-003).
- 05: with no tags at all, the screen still shows a dead search field and a "No tags · A→Z"
  header above "No tags yet"; the delete dialog's reassurance sits on a green success card beside
  a red destructive button.
- 08 and 09: a tag is added only through the keyboard's Done key; in edit, a typed but unadded
  tag turns Save on and is then dropped by the save.
- 10: a history badge is labelled with the kind ("Review") but coloured by the outcome (amber on
  a lapse); each event carries four or five glyphs; the half-width "Algorithm" fact wraps.
- 11: "Include duplicates" sits after up to 50 preview rows; the source step draws a card inside
  a card and states the file formats twice.
- 12: the stale-selection message asks to "refresh the selection", which the sheet cannot do.
- 14: the hero is a hero ground with no action.
- 24: the minute reads "5", not "05", while the preview line reads "07:05".
- 28: "Open" is said five times on one screen; a wrapped stack-trace frame returns to column 0.
- Progress (22) and Settings (23) load behind a generic four- or five-row skeleton unlike either
  layout.
- `MxEmptyState`'s warning glyph is amber on its own 10 % tint, with no ink.
- From the 3d-1 review: 07's Retry shows no progress and the bulk bar stays live while it runs;
  15's "Not saved" banner leaves on the first edit and the page jumps; 27's syncing row sizes
  itself by the touch target, not the button token.

Success means:

- every item in §3 is built as written, each pinned by a widget test or a golden;
- no layout change beyond what an item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review page;
  the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file.
BR-TAG-008 requires the delete dialog to say no card is lost (§3.5 keeps the sentence and drops
only the green). BR-SRS-030 requires the reset dialog to state what is lost and kept (§3.2
changes only the button tone). BR-TAG-001/002 bound a tag (§3.6 adds tags through the same
validation). BR-TRANSFER-003 keeps the duplicates toggle (§3.8 moves it).

## 2. Owner rulings (2026-10-01)

- **E1.** Scope: the 3d-1 §6 list and the four 3d-1 deferred minors. The lower findings the
  audit also found (06 two time forms, 09 optional fields open in edit, 10 header styles,
  14 limit behind an icon, 15 no link to Settings, 22 streak tile and deck name twice, 24 denied
  wording, 27 value in the subtitle, 05 merge density) wait in the UI-base register.
- **E2.** 01: the "recent" sort reads "Date added" / "Ngày tạo"; its hint stays "Newest first".
- **E3.** 01: the search field is hidden while decks are reordered.
- **E4.** 02: the reset confirm takes the warning tone.
- **E5.** 02 and 14: the unlocked strip and the study-entry hero become plain cards. The deck
  summaries on 01 and 07 keep the hero: they carry "Study this deck".
- **E6.** 03: the starter sheet's body is the lock sentence; the card keeps its counts.
- **E7.** 05: the delete dialog's reassurance is a neutral note.
- **E8.** 08/09: the tag input gains an "Add" button; Save first adds the tag being typed, and
  an invalid one shows its error and saves nothing.
- **E9.** 10: the badge carries the outcome, in the outcome's tone; the kind is plain text;
  the metadata is text without glyphs; "Algorithm" takes a row of its own.
- **E10.** 11: the duplicates toggle moves above the rows; the source step drops the wrapping
  card and the repeated formats.
- **E11.** 28: the default list header counts logs; stack-trace frames hang-indent.
- **E12.** Skeletons: Progress and Settings compose their own, in place, from the existing
  skeleton parts.
- **E13.** 15: a failed save's banner stays until a save succeeds.
- **E14.** Shared widgets: `MxStepper` gains `minDigits`; `MxEmptyState`'s warning glyph takes
  `warningInk`.

## 3. Items

### 3.1 Library sort and reorder (01, E2, E3)

- `deckSortRecent`: "Date added" / "Ngày tạo". `deckSortRecentHint` stays "Newest first" /
  "Mới nhất trước". The sort pill, which reads `deckSort()`, follows.
- `DeckLibraryRootWidget` leaves out the search field (and the space after it) while
  `isReordering`, as reorder mode already leaves out the summary, the due strip and the sort pill.
  It comes back with Done.

### 3.2 Reset confirm (02, E4)

- The reset dialog's `MxSheetActions` sets `isWarning: true`: the confirm "Reset and start cycle
  {n}" is amber, as the dialog's Lost tile is. Destructive red stays for deleting data.
- The copy, the tiles and the loading state are unchanged.

### 3.3 Inert heroes (02, 14, E5)

- `DeckLockStripWidget`'s unlocked strip is a plain `MxCard` (no `isHero`); the locked strip
  keeps its warning ground. The strip states status; it is not a door.
- `StudyEntryHeroWidget`'s card is a plain `MxCard`. Its tiles and lines are unchanged.
- Recorded as the same rule 3c-1 R2 applied to 13: DESIGN.md's "a hero leads somewhere tappable"
  stands.

### 3.4 Starter sheet (03, E6)

- The sheet's body is `deckSchedulerNote` ("The scheduler locks after the first review. Changing
  it later resets learning progress." / "Thuật toán sẽ khóa sau lần ôn đầu tiên. Đổi về sau sẽ
  đặt lại tiến độ học."), the line the new-deck dialog already shows. `starterSheetBody` goes
  from both ARBs.
- The card's facts line keeps its counts. The sheet's title "Add “{title}”" stays.

### 3.5 Tags (05, E7)

- With no tags at all, the screen shows only the empty state: no search field, no header. When
  tags exist and a search finds none, the field and "No matches" stay as today.
- The delete dialog's reassurance ("No card is deleted, hidden or changed — all {n} cards stay
  exactly where they are.") is an `MxNote` in the neutral tone, without the success card and its
  green glyph. The body, the count and the destructive confirm are unchanged (BR-TAG-008).

### 3.6 Tag input (08, 09, E8)

- The tag field gets an "Add" button (`cardTagConfirm`, "Add" / "Thêm") beside it, enabled while
  the field holds text. It adds through the same path as Done: the same trimming, duplicate,
  limit and name checks, and the same errors (BR-TAG-001, BR-TAG-002).
- Save, in create and in edit, first adds the text in the tag field. If the text is invalid, the
  field shows its error and nothing is saved. An empty field adds nothing.
- Save stays enabled by pending tag text in edit (the 3d-1 `_isDirty` comparison), which is now
  honest: that text is saved.
- In create, "Save and add another" clears the tag field with the rest of the form.

### 3.7 Card detail (10, E9)

- A history event's `MxBadge` reads the outcome (`cardHistoryAction`: "Again", "Hard", "Good",
  "Easy", "Forgot", "Remembered"), toned by it: warning for a lapse ("Again", "Forgot"), neutral
  for relearning, success otherwise (tone pass T5), keeping its glyph. The kind ("Learning",
  "Review", "Repeat") follows as plain text in the row-title style.
- The metadata lines (mode, box, ease, interval, hint used, timed out, next due) are text only;
  the badge is the event's one glyph.
- The schedule's "Algorithm" fact spans the card's full width, on a row of its own after the
  paired facts.

### 3.8 Import (11, E10)

- In the preview, the "Include duplicates" section sits after the badges and before the rows,
  when there are duplicates (BR-TRANSFER-003).
- In the source step, the "Pick a spreadsheet or text file" empty state is not wrapped in an
  `MxCard` (`MxEmptyState` draws its own surface). `importPickBody` reads "Nothing is added until
  you confirm." / "Chưa thêm gì cho tới khi bạn xác nhận."; the formats stay in the "Choose a
  file" option's hint.

### 3.9 Export stale copy (12)

- `exportStaleBody`: "It was moved to another deck or sent to Trash meanwhile. Nothing was
  exported. Close this sheet, check your selection and export again." / "Thẻ đó vừa được chuyển
  sang bộ thẻ khác hoặc vào Thùng rác. Chưa xuất gì. Hãy đóng bảng này, xem lại các thẻ đã chọn
  rồi xuất lần nữa." The lone Close stays.

### 3.10 Reminder time (24, E14)

- `MxStepper` takes `minDigits` (default 1): its value, its edit field's seed and its semantics
  value are padded with zeros to that many digits. Existing callers are unchanged.
- The reminder dialog passes `minDigits: 2` to the hour and minute steppers: "07" : "05",
  matching the "07:05" preview.

### 3.11 Monitoring (28, E11)

- With the default filter, the list header reads "{n} logs" / "{n}+ logs" as with any other
  filter; the chip "Status · Open" already names the filter. `monitoringCountOpen` and
  `monitoringCountOpenMore` go from both ARBs.
- A stack trace lays out one frame per row: the `#n` token in a fixed-width cell, the rest of the
  frame beside it, so a wrapped line starts under the frame's text, not at column 0. The trace
  stays selectable and keeps the `#n` colour.

### 3.12 Skeletons (22, 23, E12)

- Progress loads behind its own shape: a Today card, a Streak card and a deck-list card, built
  from `MxSkeletonPulse`, `MxCard`, `MxSkeleton` and `MxSkeletonRow`, as 13, 14 and search do.
  Deck progress keeps its range control and shows the deck-list card.
- Settings loads behind section-shaped cards of `MxSkeletonRow`s (three cards).
- No new shared widget. The semantics label stays.

### 3.13 Empty-state warning ink (E14)

- `MxEmptyState`'s warning tone draws its glyph in `warningInk` on its tint, as primary and
  success use their inks. Its one caller is the import result "This deck no longer accepts
  cards".

### 3.14 From the 3d-1 review

- **07 Retry:** while the flag write runs, the banner stays and its Retry shows the button's
  loading state; the bulk bar ignores taps. A failure keeps the banner; success clears the
  selection as today.
- **15 banner (E13):** an edit no longer clears a failed save. The banner and the footer's "Retry
  save" stay until a save succeeds; the banner's values are the deck's stored ones, so they stay
  true while the person edits.
- **27 row:** `_SyncingRow` takes `AppSize.buttonRegular`, the height of the button it stands in
  for. A screen reader hears "Syncing…" through the live region; focus returning to the button
  after the swap is not attempted (no change).

## 4. Verification

- A test written first for each behaviour:
  - 01: the sort sheet and pill read "Date added"; the search field is absent while reordering
    and back after Done;
  - 02: the reset confirm is warning; the unlocked strip is not a hero, the locked one warning;
  - 03: the sheet's body is the lock line and the counts appear once;
  - 05: the true-empty screen has no search field or header; the delete note is not a success
    card;
  - 08/09: "Add" adds a tag; Save with text in the tag field saves that tag; Save with an invalid
    one shows the error and saves nothing; save-and-add-another clears the field;
  - 10: a lapse badge reads "Again" in warning with "Review" beside it; the metadata has no
    glyphs; "Algorithm" spans the row;
  - 11: the duplicates toggle precedes the first row; the source step has one surface and states
    the formats once;
  - 12: the stale copy in en and vi;
  - 14: the hero is not a hero card;
  - 24 and `MxStepper`: `minDigits: 2` shows and announces "05"; the default shows "5";
  - 28: the default header counts logs; a wrapped frame's second line starts after the `#n` cell;
  - 22, 23: the loading screens show their shaped skeletons;
  - `MxEmptyState`: the warning glyph is `warningInk`, light and dark;
  - 07: during a Retry the banner shows a loading Retry and the bulk bar does nothing on tap;
  - 15: after a failed save, an edit keeps the banner and "Retry save"; a successful save clears
    them;
  - 27: the syncing row's height is `AppSize.buttonRegular`.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare` page
  before merge.
- The gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `TZ=UTC flutter test --tags golden`.

## 5. Records

- DESIGN.md: the `MxStepper` line gains `minDigits`; the `MxEmptyState` line its warning ink.
- Detail files 01, 02, 03, 05, 07, 08, 09, 10, 11, 12, 14, 15, 22, 23, 24, 27 and 28: one ruling
  line each, and any row the change makes stale.
- The UI-base register (§9 of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`):
  the lower findings of E1, one row each.
- `docs/wbs_FE.md`: a row FE-D16 for part 3d-2.

## 6. Out of scope

The lower findings of E1, anything a BR fixes, and focus management across 27's swap.
