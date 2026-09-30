# Whole-app critique 2026-09-30, part 3a: quick, safe Minors — design

Status: approved 2026-09-30 ·
Path: architectural (small shared-widget and copy changes across screens) · Owner rulings 2026-09-30 (§2): R1–R4

## 1. Intent

Part 1 (`2026-09-30-critique-fixes-part1-design.md`, PR #167) fixed the six Majors. The owner
split what is left into 3a (quick, safe Minors), 3b (a number stated once), 3c (study and
the session summary) and 3d (per-screen flows), in that order; typography is part 2.

3a clears the Minors that need no layout decision: the deferred findings of part 1's final
review and the snapshot's mechanical findings (copy, glyphs, fixtures, doc drift).

Success means:

- every item in §3 is built as written, each pinned by a widget test or a golden;
- nothing in §3 changes a layout beyond what the item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review
  page; `dod_check.sh` passes.

## 2. Owner rulings (2026-09-30)

- **R1.** Order: 3a, 3b, 3c, 3d; each its own spec, plan and golden review.
- **R2.** The new-card order is "In order" on the segment and "in creation order" in running
  text, everywhere.
- **R3.** The refused title says what happened: "{n} changes weren't accepted", on screen 27,
  the Settings sync row and the Study home notice.
- **R4.** Out of 3a (no clear problem): the headerless sample's ink, the "Recommended" badge
  on a locked row, the Keep dialog's count frozen at open time, sharing the reminder sentence
  builder with the notification mapper.

## 3. Items

### 3.1 Shared

- **`MxSettingsRow`**: while disabled, the `trailing` and `wideControl` controls are not
  wrapped in the row's dim; the tile, the label and the chevron are. `MxButton`, `MxToggle`
  and `MxStepper` already draw their own disabled opacity, so the reminder's time button now
  reads at 0.38, not about 0.14. Doc: "a trailing control draws its own disabled state".
- **`MxInlineBanner` action order**: the primary action comes last (Material 3: the
  confirming action at the end). Screen 24's permission-denied banner becomes Try again
  (outline) then Open system settings (primary), as screen 27 already is. DESIGN.md records
  the order.
- **Test helper**: `expectOnePrimaryPerDecision(WidgetTester tester, {int expected = 1})`
  asserts exactly `expected`, so a screen with no primary where one is due fails.

### 3.2 Copy (en and vi)

| Key | en | vi |
|---|---|---|
| `settingsOrderCreated` | In order | Theo thứ tự tạo |
| `studyOptionsOrderCreatedShort` | in creation order | theo thứ tự tạo |
| `settingsStudyDefaultsNote` | Applies to sessions started from now on. A deck with its own study options keeps them. | unchanged (the vi sentence is already correct) |
| `syncRejectedTitle` | {count, plural, =1{1 change wasn't accepted} other{{count} changes weren't accepted}} | {count, plural, other{{count} thay đổi chưa được máy chủ nhận}} |
| `syncStatusRejected` | {count, plural, =1{1 change wasn't accepted} other{{count} changes weren't accepted}} | {count, plural, other{{count} thay đổi chưa được máy chủ nhận}} |
| `studyHomeSyncRejected` | {count, plural, =1{1 change wasn't accepted.} other{{count} changes weren't accepted.}} | {count, plural, other{{count} thay đổi chưa được máy chủ nhận.}} |

- The eight en strings with a curly apostrophe (`algorithmSwitchFailedTitle`,
  `importCaptionColumns`, `importProblemUnreadableTitle`, `importFailedTitle`,
  `exportFailedTitle`, `exportShareFailedTitle`, `reminderCouldNotTurnOnTitle`,
  `reminderCouldNotChangeTimeTitle`) use the straight `'` the other 87 use.
- `studyEntryLearnCount` already reads "in creation order" and stays.

### 3.3 Glyphs and notes

- 08 "Add details" uses the plus glyph instead of the sparkle (it implies AI).
- 11 an invalid preview row uses `AppIcons.alert`, as its legend badge does, not the X that
  reads as a dismiss control.
- 25 Theme's note is `MxNote.hint`, as Language's and Settings' notes are.
- The gallery shows an `MxErrorState` with `icon: AppIcons.offline`.

### 3.4 Tests and fixtures

- 11 import: a blank or missing sample cell renders no sample line (assert the row's text
  count), in addition to not throwing.
- 24 reminder preview: the loading branch keeps the row and shows no error.
- 07 card search: a golden `card_list_search_results` with matches and a 300 dp keyboard
  inset, so the part 1 fix is pictured.
- 01 library: the golden fixture wires `onOpenStudyHome`, so the due strip's chevron is in
  `library_decks`; the detail file's stale Pending row goes.
- 04 search: `search_load_more_failed` asserts the danger banner before it captures.
- 10 card detail: the fixture's schedule cycle and history cycles agree.

### 3.5 Records

- DESIGN.md: the banner action order (§3.1).
- Detail files: 01 (Pending row, chevron), 07 (legend and sort chip wording match the app),
  08 (the single Save is in the footer, not the app bar), 16 and 16a (one name for the mode,
  as the app shows it), 23 (the reminder row and the reset copy), 24 (banner order), 25
  (note form), 27 and 13 (refused copy), 15 (order names).
- `docs/wbs_FE.md`: a line FE-D9 for part 3a.

## 4. Verification

- A test written first for each behaviour change: the settings-row dim, the banner order,
  the helper's `expected`, the refused copy on 27, 23 and 13, the import blank cell, the
  preview loading branch.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare`
  page before merge.
- `dart format`, `flutter analyze`, the architecture guard, the full `flutter test` with
  goldens, and `dod_check.sh`.

## 5. Out of scope

Part 2 (typography), 3b, 3c, 3d, and R4's items.
