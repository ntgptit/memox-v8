# Whole-app critique 2026-09-30 (31/40), part 1: shared components and the six Majors — design

Status: approved 2026-09-30 ·
Path: architectural (shared widget APIs, one new provider) · Owner rulings 2026-09-30 (§3): R1–R9

## 1. Intent

The whole-app Impeccable critique of 2026-09-30 (snapshot
`.impeccable/critique/2026-09-30T02-47-36Z__docs-shared-ui-screen-handoff-00-index-md.md`)
scored the app 31/40 with no Critical finding, six Majors and about 110 Minors. Several
Minors recur across screens because a shared widget or a missing rule allows them.

Part 1 fixes the six Majors and the shared-component patterns behind the most frequent
recurring Minors. Part 2 (a later spec) splits the typography section label.

Success means:

- each item in §4 and §5 is built as designed, with behaviour pinned by a widget or unit
  test written first;
- no screen in scope shows more than one enabled primary fill for one decision, checked by
  `expectOnePrimaryPerDecision` (§4.5);
- the golden suite is regenerated in the Linux container, and the owner sees every changed
  golden on a golden review page before merge;
- `DESIGN.md`, the affected detail files (§6.3) and `docs/wbs_FE.md` describe the result;
- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` passes.

## 2. Verified findings in scope

The parent session checked each of these against the goldens and the source.

| # | Screen | Finding | Evidence |
|---|---|---|---|
| M1 | 27 Sync | Rejected state: "Try again" (banner) and "Sync now" are both solid indigo and both start a sync; "Waiting to sync" reads "Nothing waiting" beside a banner saying 2 changes are kept on this device | `sync_rejected_light.png`; `sync_screen.dart` (`_needsSync` counts `rejectedCount`); `sync_notice_widget.dart` |
| M2 | 27 Sync | "Keep on this device" is one tap, with no reason and no consequence; the §5.4 message of the sync status spec was dropped | `sync_notice_widget.dart:41` (title only); `2026-09-28-sync-status-design.md` line 144 |
| M3 | 14 Study entry | Resume state: "Continue" and the footer "Start a new review instead" are both primary; the footer one ends the open session | `study_entry_resume_light.png`; `study_entry_footer_widget.dart` |
| M4 | 07 Card list | With search open the summary hero stays above the results, so the first matches sit under the keyboard | `card_list_search_light.png`; `card_list_section_widget.dart` hides it only when `isSelecting` |
| M5 | 11 Import | Mapping shows the column letter and, with a header row, the header; no data. Pasted text and headerless files map blind | `import_mapping_light.png`; `import_mapping_row_widget.dart` |
| M6 | 24 Reminder | "What it says" hard-codes 86 due cards, 2 other decks and a Vietnamese deck name; the detail file says "live counts" | `reminder_preview_section_widget.dart:12-13`; `24-daily-reminder.md` line 24 |
| S1 | many | Banner, notice and footer actions are primary beside another primary (13, 14, 27, 01); Export's final states keep the format rows live (12) | critique "One Indigo" pattern |
| S2 | 02, 14 | A dimmed option row dims the selected fact (02 locked) and the reason it is blocked (14, about 2.5:1) | `library_algorithm_locked_*`, `study_entry_eight_box_*`; `mx_option_row.dart` |
| S3 | 24, 23 | A disabled settings row dims its explanation (24 Time hint); the Reset row shows a chevron but opens a dialog | `reminder_off_*`, `settings_loaded_*`; `mx_settings_row.dart`, `mx_row_ink.dart` |
| S4 | 03, 06, 24 + | `MxErrorState` defaults to the cloud-off glyph; most callers report a local Drift read | `mx_error_state.dart:19`; 33 feature call sites |
| S5 | 02, 05, 24, 27 | Outline button edge in dark is `outlineVariant` #2A3267 on the sheet ground #2C356E, about 1:1 | `app_color_schemes.dart:90,95`; `mx_button.dart` outline tone |

## 3. Owner rulings (2026-09-30)

- **R1.** Shared components first; scope is the six Majors plus the shared patterns.
- **R2.** Two parts: this spec, then the typography section-label split in its own spec.
- **R3.** Approach A: fix tone at the callers, state the rule in `DESIGN.md`, extend shared
  widget APIs only where needed, and guard with a test helper. No ambient "primary scope".
- **R4.** "Keep on this device" gets the explanatory message and a confirm dialog; no Undo.
- **R5.** The reminder preview uses the real counts.
- **R6.** Decisions that touch `DESIGN.md` but lie outside part 1 (the Study home workload
  hero, the mastery accent on Recall and Fill, the study context line) are decided one by
  one when their part is planned, not here.
- **R7.** The outline edge changes in dark only; light keeps `outlineVariant` (1.53:1, but
  visible, and the label identifies the control).
- **R8.** A lone Close stays primary (ruling C1, M3 review 2026-09-28): one primary per
  decision holds. Export's final states only disable the format rows.
- **R9.** A deck with no content yet (`DeckContentType.unset`) has no FAB: its empty state
  already offers New card and New sub-deck. This amends ruling P4a-L9
  (`docs/superpowers/plans/2026-09-24-library-phase-4a-card-editor.md`); the FAB returns
  once the deck holds sub-decks.

## 4. Shared components and rules

### 4.1 `MxOptionRow`

- A selected row is never dimmed: the default for `isDimmed` becomes
  `onSelected == null && !isSelected`. An explicit `isDimmed` still wins.
- A dimmed row dims only the radio and the title (`AppOpacity.disabled`). The description
  keeps `rowDescription` at full ink, so a blocked row's reason reads at 4.5:1.
- Effect: 02 locked shows the current algorithm at full contrast and the other one dimmed;
  14 shows "Needs five different meanings…" at full contrast.

### 4.2 `MxSettingsRow`

- While `isEnabled` is false the icon tile, the label and the control draw at
  `AppOpacity.disabled`; the subtitle stays at full ink. The row still ignores taps.
  `MxRowInk` gains `shouldDimWhenDisabled` (default true); `MxSettingsRow` passes false and
  paints the opacity itself, so `MxRowInk`'s other callers keep today's look.
- New `isAction` (default false): a row with `onTap` that runs an action or opens a dialog
  shows no chevron. Screen 23's Reset row sets it.

### 4.3 `MxErrorState`

- The default `icon` becomes `AppIcons.alert`.
- Callers whose failure is a network failure pass `icon: AppIcons.offline` explicitly. The
  plan lists them by reading each of the 33 call sites; at least the Monitoring offline
  branches.

### 4.4 `MxButton` outline tone

- The outline edge holds 3:1 in dark on the grounds it sits on: the page, the sheet
  (`surface-container-high`) and the warning soft ground. The colour is a derived colour in
  `derivedColors` (`outlineEdge`): dark is `outline` pulled 25% toward `onSurface`
  (3.41:1 on the sheet, 5.69 on the page, 4.27 on the warning ground); light keeps
  `outlineVariant`. Light is 1.53:1, but its edge stays visible and the label identifies
  the control (WCAG 1.4.11), so it is left as is (owner ruling R7).

### 4.5 Rules and guard

`DESIGN.md` gains, under The One Indigo Rule:

- An action in `MxInlineBanner` or `MxFloatingNotice`, and the action in `MxFooterBar`, is
  primary only when the screen shows no other primary for the same decision; otherwise it
  is outline or secondary.

and under Components:

- `MxOptionRow` and `MxSettingsRow`: the selected fact and the explanation are never
  dimmed.
- `MxErrorState`: the default glyph is alert; cloud-off only for a network failure.

`test/shared/expect_one_primary.dart` adds `expectOnePrimaryPerDecision(WidgetTester)`: it finds the enabled,
on-screen `MxButton`s with the primary tone and the `MxFab`, and fails when more than one
is found. Widget tests of 01, 12, 13, 14 and 27 call it in the states named in §5.

## 5. Screen fixes

### 5.1 Screen 27 Sync (M1, M2)

- "Sync now" is primary only when changes wait or the last run failed, and no row was
  refused; with `rejectedCount > 0` it is outline and the banner's "Try again" is the one
  primary.
- The "Waiting to sync" row reads "No other changes waiting" when rows were refused and
  nothing else waits.
- The refused banner keeps its title and gains the message of the sync status spec, with
  the consequence: "The server didn't accept them. They're safe here. Try again, or keep
  them on this device only; they won't sync to your other devices." Final wording and the
  Vietnamese follow in the ARB.
- "Keep on this device" opens an `MxDialog`: title "Keep {n} changes on this device
  only?", body "They won't sync to your other devices. You can't undo this.", actions
  Cancel and "Keep on this device". Only the confirm calls `keepRejectedOnDevice`; Cancel
  or dismiss writes nothing. The sync layer does not change.

### 5.2 Screen 14 Study entry (M3)

While `entry.resumable != null`, the footer action ("Start a new review instead") is
outline. "Continue" in the resume card stays the one primary.

### 5.3 Screen 07 Card list (M4)

While search is open the summary card is hidden; the filter row stays so a filter still
applies to the search. Selection mode keeps its current behaviour.

### 5.4 Screen 11 Import mapping (M5)

Each mapping row shows a sample cell under the column name: the first data row's cell
(row 2 when "First row is a header" is on, else row 1), one line, ellipsised, in
`rowDescription`. With a header the row reads column letter, header, sample; without,
column letter, sample. An empty or missing cell shows no sample line.

### 5.5 Screen 24 Reminder preview (M6)

- `reminderPreviewDigestProvider` (presentation/providers, `@riverpod`, async) reads
  `reminderWorkloadRepositoryProvider.rootWorkloads(now, startOfToday)` with the times from
  `dayClockProvider`, and returns `reminderDigestOf(...)`, null when nothing is due. It
  reads once when the screen opens, as the notification reads once when it fires
  (BR-REMINDER-003). It goes through `ReadReminderPreviewUseCase` (domain), as ADR-011 D4/D5 require one use case per interaction with no exception; the spec first said "no use case", corrected at the final review.
- The row renders the quoted sentence from the digest with the strings the notification
  uses. Null renders a neutral line ("Nothing is due right now, so today's reminder would
  stay silent."). Loading keeps the row's space; a read error renders the neutral line.
- `_sampleDue`, `_sampleOtherDecks` and the ARB key `reminderPreviewDeck` are removed.

### 5.6 Caller tone fixes (S1)

- 13 Study home: the sync notice's "Details" is outline.
- 12 Export: in a final problem state (stale, empty, no share target) the format rows are
  disabled. Close stays the one primary (ruling C1 of the 2026-09-28 M3 review; R8).
- 01 Library: a deck with no content (`DeckContentType.unset`, golden
  `library_deck_unset`) shows no FAB; its empty state keeps "New card" and "New sub-deck"
  (R9).

## 6. Data, copy and records

### 6.1 Data

Only 5.5 reads data; no schema, query or migration change.

### 6.2 Copy (English and Vietnamese ARB, local-first voice)

- New: the refused-banner message; the Keep dialog title, body and actions; "No other
  changes waiting"; the reminder's nothing-due line. The import sample is plain text and
  needs no new label.
- Removed: `reminderPreviewDeck`.

### 6.3 Records updated in the same PR

- `DESIGN.md` (§4.5 rules; the outline edge colour; frontmatter and
  `.impeccable/design.json` if the edge becomes a named derived colour).
- Detail files 01, 07, 11, 12, 13, 14, 23, 24, 27: layout, states and goldens, rulings,
  copy. 24 drops "live counts" drift; 27 restores the §5.4 message.
- `docs/wbs_FE.md`: a line for this part.

## 7. Verification

- Widget tests first for: 4.1 (selected never dimmed, description full ink), 4.2 (subtitle
  full ink when disabled, `isAction` has no chevron), 4.3 default glyph, 5.1 (tones; the
  Keep dialog; `keepRejectedOnDevice` only after confirm; the Waiting row copy), 5.2, 5.3,
  5.4 (with and without header, empty cell), 5.6.
- Unit test for `reminderPreviewDigestProvider` with a fake repository: a digest, null,
  and an error.
- Contrast test: the outline edge at 3:1 on page, sheet and warning ground in dark.
- Goldens regenerated in the Linux container. New: the Keep dialog, headerless mapping,
  the reminder with nothing due. Updated: every error state (glyph), every dark outline
  button, and the screens above. The owner reviews them on a `golden-compare` page.
- Gates: `dart format`, `flutter analyze`, the architecture guard, the full `flutter test`
  with goldens, `dod_check.sh`.
- After the build: Impeccable critique and audit of the changed goldens against
  `DESIGN.md`, one fix batch, one confirm.

## 8. Out of scope

- Part 2: splitting the section label into field label, eyebrow and section label; the
  `requiredMarker` borrowing; uppercased user data (04).
- Other Minors from the snapshot, including the Study home workload hero, the Recall and
  Fill mastery accent, the Session summary layout, "state a number once" on nine screens,
  and the detail-file drift not listed in 6.3.

## 9. Risks and rollback

- **Golden churn.** The error-state glyph and the dark outline edge touch many goldens.
  Each is one visual change; the golden review page groups them.
- **`MxRowInk` change.** Other callers must keep their look; its widget tests pin that.
- **Rollback.** Every change is local to a widget, a caller or one provider; reverting the
  PR restores the previous state. No data is migrated.
