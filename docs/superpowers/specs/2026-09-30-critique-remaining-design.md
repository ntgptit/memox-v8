# Critique 2026-09-30, remaining items — design

Status: draft 2026-09-30, awaiting owner review ·
Path: architectural (a new local table, a BR change) · Owner rulings 2026-09-30 (§2): R1–R6

## 1. Intent

The 2026-09-30 critique plan listed items that PR #161 did not do or did in part. The owner
asked to finish them:

- screen 27: the sync failure sits next to "Sync now";
- `MxNote`: a light hint form and a dismissible form;
- screen 13: a slimmer hero; screen 02: one sentence per algorithm;
- screen 21: "3 of 23" instead of "3/23"; a measured contrast for Guess's faded options.

Success means each item below ships with a test written first, the goldens are regenerated
in the Linux container and reviewed by the owner, `DESIGN.md`, the screen records, the BR
and its UC say what the app does, and `dod_check.sh` passes. Tests run at the default text
scale only (PRODUCT.md).

## 2. Owner rulings (2026-09-30)

- **R1.** A dismissed note is stored in a new local Drift table that never syncs.
- **R2.** Dismissible: 06 "Kept for 30 days…", 03 the fixture note, 11 the file helper
  (`importHelperBody`). Light hint: 11 the mapping note, 24 the reminder note, 27 the sync
  note. Dialog notes stay as they are.
- **R3.** Screen 13's hero shows "{n} cards due" over "{x} overdue · {y} today"; New and
  Scheduled leave the hero (BR-STUDY-068 changes).
- **R4.** Screen 27 shows a failure and refused changes inline under the status card, above
  "Sync now"; its floating notice goes. Screen 13 keeps its own floating notice.
- **R5.** Screen 02: one sentence per algorithm.
- **R6.** Screen 21: the wrong-turns value reads "{wrong} of {total}".

## 3. Design

### 3.1 Dismissed notes (R1, R2)

- **Table** `dismissed_note` in a new `lib/core/database/tables/ui_state.drift`:
  `note_key TEXT NOT NULL PRIMARY KEY`, `dismissed_at DATETIME NOT NULL`. No sync trigger,
  no `server_version`. `schemaVersion` 10 → 11; the step is `m.createTable(schema.dismissedNote)`;
  snapshot, `schema_versions.dart`, the generated verifier and `test/drift/migration_test.dart`
  follow the flutter-drift migration workflow; `docs/shared/data/schema.md` records the table.
- **Store** `lib/core/notes/`: `DismissedNoteStore` over `AppDatabase` (`watchDismissed() →
  Stream<Set<String>>`, `dismiss(String key)`), a keep-alive `dismissedNotesProvider`
  (`StreamProvider<Set<String>>`) and `dismissNoteProvider` in `core/notes/di/`, as
  `core/sync` does. Keys are constants in `core/notes/note_keys.dart`
  (`trashRetention`, `starterFixtures`, `importHelper`).
- **`MxNote`** gains an optional `onDismiss` with a required `dismissLabel` when set: a
  trailing `MxIconButton` (close glyph, 48 dp target) whose tooltip and semantics are the
  label. Components hold no copy; the label is `commonDismissNote` ("Hide this note" /
  "Ẩn ghi chú này").
- **`MxNote.hint`**: no fill and no border, the glyph and `noteText` in `onSurfaceVariant`,
  vertical padding `AppSpacing.micro`; for a footnote under a section.
- **`MxSection(note:)`** renders its note as `MxNote.hint` (every caller: 24, 27, language,
  settings reset, study defaults, import preview, gallery).
- **Screens:** 06, 03 and 11 (all three `importHelperBody` sites) watch
  `dismissedNotesProvider`; a dismissed key hides the note and its gap; the close button
  calls `dismissNoteProvider`. 11's mapping note becomes `MxNote.hint`.

### 3.2 Screen 27 inline problems (R4)

`SyncScreen` no longer passes `notice:`. Under `SyncStatusSectionWidget` it shows, when
`SyncNoticeWidget.shows(status)`, an `MxInlineBanner` (warning): the failure sentence
alone, or the refused title with "Keep on this device" (outline) and "Try again", as
the notice drew them. The banner sits between the status card and "Sync now".

### 3.3 Screen 13 hero (R3)

`study_home_workload_widget.dart` passes only the overdue and today terms (no new, no
scheduled label). BR-STUDY-068 is rewritten: the hero states the Due total with its two
disjoint halves (Overdue, Due today); New and Scheduled stay defined for the store and the
deck rows but are not in the hero. UC-STUDY-002 and the 13 record follow.

### 3.4 Copy (R5, R6)

- `algorithmEightBoxDescription`: "Remembered moves a card up a box and forgotten sends it
  back to box 1; reviews use match, guess, recall or fill." vi: "Nhớ thì thẻ lên một hộp,
  quên thì về hộp 1; ôn bằng ghép, đoán, nhớ lại hoặc điền."
- `algorithmSm2Description`: "Intervals adapt as you grade each card again, hard, good or
  easy in self-assess reviews." vi: "Khoảng cách tự điều chỉnh theo lúc bạn tự chấm lại,
  khó, tốt hoặc dễ khi ôn tự đánh giá."
- `summaryWrongOf`: "{wrong} of {total}"; vi "{wrong} trên {total}".

### 3.5 Guess contrast

`test/core/theme/token_contrast_test.dart` gains the pair "faded choice ink": ink
`_tint(onSurface, AppOpacity.muted, surface)` over ground
`_tint(surfaceContainerLowest, AppOpacity.muted, surface)`, minimum 4.5, both themes. If it
fails, `AppOpacity.muted` rises to the lowest value that passes both themes.

## 4. Records

`DESIGN.md` (MxNote hint and dismissible, section notes are hints, screen 27 inline),
screen records 02, 03, 06, 11, 13, 21, 24, 27, BR-STUDY-068, UC-STUDY-002,
`docs/shared/data/schema.md`, `docs/wbs_FE.md` (FE-D7), `python tools/docs/generate.py`.

## 5. Verification

Widget tests first for: note dismissal persists across a rebuild and hides the note;
`MxNote.hint` has no decoration; section notes render as hints; screen 27 shows the inline
banner and no floating notice; the 13 hero has no New/Scheduled term; the copy keys; the
contrast pair. Migration test v10 → v11. `dod_check.sh`; goldens in `memox-golden:3.47.5`;
golden review page before merge.
