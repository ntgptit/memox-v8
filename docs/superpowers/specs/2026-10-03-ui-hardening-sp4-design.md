# UI hardening SP4 — study UX (screens 13–22) — design

Status: draft for owner approval ·
Path: architectural, sub-project SP4 of [the UI hardening spec](2026-10-03-ui-hardening-design.md) (§6.3, rows 4.01–4.37) ·
Owner rulings used: R1, R2 (footer caption), R7, V1–V5 and the approval mode (that spec §3, §7) ·
WBS row: FE-D31

## 1. Intent

SP4 fixes the 37 backlog rows of §6.3 for the study surfaces: Study home (13), entry (14),
options (15), Browse (16), Self-assess (16a), Match, Guess, Recall, Fill (17–20), the session
summary (21) and Progress (22). It also builds the one new action of V2.

The rows are UX findings, not data-safety ones (SP2a closed those on the same screens). The
visible design changes are small and follow DESIGN.md and the SP1 rules: a note says something
new, a footer caption adds a fact, an eyebrow sits inside its card, no overline over a
one-row group.

Success:

- every behaviour row has a widget or unit test that fails before its fix;
- `dod_check.sh` is green, then the Linux goldens are green;
- the owner approves the golden-compare page before the merge;
- the WBS row FE-D31 tells the truth and the detail files of §9 describe the app after the fix.

SP2a already changed these screens (2.01–2.13, 2.49–2.51). Each row below was checked against
the current code. Rows whose finding no longer holds would say "Already fixed"; none does.

## 2. Owner rulings used here

- **R1.** Every finding is in scope, Minor included.
- **R2.** `MxFooterBar`'s caption is full-contrast and must add a fact (4.08, 4.26).
- **V1.** "Keep the terms and add a one-line definition where each first appears on a screen."
  Applied in 14 (algorithm, stage, round), 21 (turn, cycle) and 22 (card-days). Interpretation
  for the session screens 16–20: they are reached only from 14, so the stage and round
  definitions live there, not on every mode screen. The owner can overrule this in the approval.
- **V2.** "Study home gains one action that opens the deck with the most overdue cards, in the
  existing row order; sessions stay per deck."
- **V3.** "No change; the Guess hold stays 1200 ms or until a tap." Closes the pacing clause of
  4.34. 4.18 is a separate finding (visibility) and does not touch the hold.
- **V4.** "No change; the Recall turn stays 20 seconds (BR-STUDY-031)." Closes the "Open for the
  owner" paragraph of `19-study-recall.md`; no backlog row depends on the duration.
- **V5.** "The Fill judge keeps accents and states the rule before the first answer" (4.20).

## 3. Design

Paths: **S** = `lib/features/study/presentation/widgets/sections`, **U** =
`lib/features/study/presentation/widgets/support`, **SCR** = `lib/features/study/presentation/screens`,
**P** = `lib/features/progress/presentation`, **O** = `lib/features/settings/presentation`.
Every new string is written in English and Vietnamese in `app_en.arb` and `app_vi.arb`.

### 3.1 Study home (13)

| # | Fix | Where |
|---|---|---|
| 4.01 | The Resume overline (dot + "Continue studying") moves inside the Resume card, above its row, as the workload card's eyebrow already is. | S/study_home_resume_widget.dart:46 |
| 4.02 | The pause tile is `MxIconTileTone.tinted`, not the filled `primary`; Resume is the card's one primary. | S/study_home_resume_widget.dart:59 |
| V2 | The workload card gets one block `MxButton` under the breakdown: "Study {deck}" / "Học {deck}". The deck is the first row of `RootDeckWorkload.decks` (BR-STUDY-076 order) with `overdue + dueToday > 0` and `canStudy`; a new getter `firstDueDeck` on `RootDeckWorkload` returns it. No such deck (only New or nothing due): no button. The tap calls `onOpenDeck(deckId)`, which opens that deck's Study Entry (14); no session starts here. Tone: primary, but secondary while the Resume card shows (One Indigo). The caught-up card has no button. | study_home_model.dart (getter), S/study_home_workload_widget.dart:42, SCR/study_home_screen.dart:111 |

### 3.2 Study entry (14) and options (15)

| # | Fix | Where |
|---|---|---|
| 4.03 | While a resume banner shows, the footer's start reads "End it and start a review" / "Kết thúc và bắt đầu ôn mới" (key `studyEntryReviewInstead`), naming the loss as the cross-deck dialog does. The banner body stays. | S/study_entry_footer_widget.dart:66, ARB |
| 4.04 | The hero's New and Due figures start at the card's text edge, with no inner surface (DECISION D1). | S/study_entry_hero_widget.dart:65,76 |
| 4.05 | Only-new: the Learn row is the door. With no trailing button it takes `onTap: onLearn` and a chevron; with a review leading the footer it keeps its button and no row tap. The footer caption becomes "Review opens when cards come due" / "Ôn tập mở khi có thẻ đến hạn" (≤ 34 characters, one line at 360dp; it no longer restates Due 0). | S/study_entry_learn_widget.dart:55, S/study_entry_footer_widget.dart:78, ARB `studyEntryNothingDueCaption` |
| 4.06 | The "A mode that is not available…" note is removed; each unavailable row already states its reason. V1 uses the slot: for Eight boxes, one `MxNote.hint` below the options: "In a learning session each stage is one mode; in a round every card is asked once and misses come back in the next." / "Trong phiên học mỗi giai đoạn là một chế độ; trong mỗi vòng mọi thẻ được hỏi một lần và thẻ sai quay lại ở vòng sau." It sits after the options, not before the decision. SM-2's stage is already named by the Learn row ("Browse, then self-assess"). | S/study_entry_review_widget.dart:68, ARB `studyEntryUnavailableNote` → `studyEntryGlossaryEightBox` |
| V1 (14) | The hero's second line reads the algorithm's definition, reusing `algorithmSm2Description` / `algorithmEightBoxDescription`, above "Up to {n} cards per session". | S/study_entry_hero_widget.dart:42 |
| 4.07 | The scope note moves below the options section and shortens: "For {root} and every sub-deck in it. A session already open keeps its options." / "Áp dụng cho {root} và mọi bộ con. Phiên đang mở giữ tùy chọn cũ." ("Applies from now on" is the toast's job.) The 16 gap above the first section goes with it. | O/widgets/sections/study_options_form_widget.dart:74, ARB `studyOptionsBelongTo` |
| 4.08 | The footer caption adds a fact or is absent. Invalid limit: "Fix the limit to enable save." Valid change pending: "Saves to this device only." / "Chỉ lưu trên thiết bị này." Nothing changed, or a failed save (its banner speaks): no caption. | O/widgets/sections/study_options_footer_widget.dart:36, ARB `studyOptionsLocalOnly` |
| 4.09 | The read-error page gets its own copy: "Couldn't open study options" / "Chưa mở được tùy chọn học" and "Your options are safe on this device. Try again in a moment." / "Tùy chọn vẫn an toàn trên thiết bị này. Hãy thử lại sau giây lát." (`studyOptionsLoadErrorTitle/Body`). `typeCardLimit` ignores an emptied field: the number stays as it was and no error shows, so an invalid message never sits beside a stale number. | O/screens/study_options_screen.dart:104, O/controllers/study_options_controller.dart:61 |

### 3.3 Browse (16) and Self-assess (16a)

| # | Fix | Where |
|---|---|---|
| 4.10 | On the stage's last card (`progress.completed + 1 >= progress.total`, not looking back) the button reads "Next stage" / "Sang giai đoạn tiếp"; every other card keeps "Next card". | S/study_browse_widget.dart:136, ARB |
| 4.11 | A visible "Previous card" button (outline) shares the CTA row with Next. It is disabled on the round's first card, and a look-back step enabled it, so the row never reflows. Both sit in the settle guard. The swipe and the TalkBack actions stay. | S/study_browse_widget.dart:128-136 |
| 4.13 | A relearning turn (`turnKindOf(...) == ReviewKind.relearning`) shows a neutral badge "Another try" / "Thử lại" on the prompt face, as Browse's "Looking back" badge, and once revealed the footer hint reads "Another try: the schedule stays as it is" / "Thử lại: lịch ôn giữ nguyên". | S/study_self_assess_widget.dart, SCR/study_session_screen.dart:443 |

### 3.4 Match (17), Guess (18)

| # | Fix | Where |
|---|---|---|
| 4.14 | A matched tile is out of play: it keeps the success tone and check but takes `isFaded: true` (the Guess treatment), so the pending tiles are the loudest. | S/study_match_widget.dart:225, U/study_choice_widget.dart |
| 4.15 | Tapping the selected tile again clears the selection. Selecting another tile in the same column still moves it. | S/study_match_widget.dart:104-125 |
| 4.16 | Rows size to their own content, with a floor of an equal share of the viewport, in a scroll view: a short board still fills the height; one long meaning grows only its own row. | S/study_match_widget.dart:145 |
| 4.17 | The prompt card takes at most one third of the body (its content, floor 112); the five options share the rest equally, each at least 48. | S/study_guess_widget.dart:131-150 |
| 4.18 | When the answer is wrong, the right option is scrolled into view with `Scrollable.ensureVisible` (centred, `AppDurations.standard`, none under Remove animations). The hold stays 1200 ms or a tap (V3). | S/study_guess_widget.dart:93-105 |

### 3.5 Recall (19), Fill (20)

| # | Fix | Where |
|---|---|---|
| 4.19 | The turn clock stops looking like the session track. Counting: a clock glyph, "14s" and a short track on one row (no caption text; the caption stays in the semantics value). Revealed: one static line "Revealed with {n}s left" / "Đã mở khi còn {n}s", no track, no fraction. Timed out: "Time is up" in warning ink, no track. `studyRecallClock` ("9s / 20s") goes. The 20 s stays (V4). | U/recall_countdown_bar_widget.dart, S/study_recall_widget.dart:206, ARB |
| 4.20 | V5: the input state's footer states the rule before the first answer: "Case and spaces are ignored; accents count" / "Bỏ qua hoa thường và khoảng trắng; dấu được tính". `studyFillHintInput` carries it. | S/study_fill_widget.dart:174-181, ARB |
| 4.21 | A wrong answer marks where it differs. A pure `differingIndexesOf(typed, term)` (grapheme LCS on lower-cased clusters) returns the indices outside the common run; those characters draw bold in both the struck answer and the correct term. "cong" against "công" marks the o. The wrong-state footer reads "Bold letters show where yours differs" / "Chữ đậm là chỗ khác với bài bạn gõ" with the info glyph. | new `states/spelling_diff_state.dart`, S/study_fill_widget.dart:264 (`_Corrected`) |
| 4.22 | Show hint keeps its slot after use, disabled and labelled "Hint shown" / "Đã xem gợi ý", so Check stays where it was. "Using the hint is noted…" goes (`studyFillHintUsed`); the input hint stays. | S/study_fill_widget.dart:205-221, ARB |
| 4.23 | `MxTextFieldVariant.study` is multi-line (`isMultiline: true`, no max), like `term`: a long answer wraps and its start stays visible; Enter still checks (DECISION D2). | lib/shared/widgets/mx_text_field.dart:124 |
| 4.24 | Fill's body takes Guess's pattern: faces at natural height inside a scroll view that fills the viewport when it is large, the CTA row pinned. With the keyboard up in landscape the faces scroll and the focused field stays visible. | S/study_fill_widget.dart:125-165 |

### 3.6 Session summary (21)

| # | Fix | Where |
|---|---|---|
| 4.25 | The hero's last tile is "Right answers {pct}%" ("Trả lời đúng"), `(turns − wrong) / turns` rounded. One line under the tiles, always: "{w} wrong of {t} turns. A turn is one answer to one card." / "{w} sai trên {t} lượt. Một lượt là một câu trả lời cho một thẻ." (V1); "Wrong cards came back in later rounds." follows it only for a finished session, as now. A review with answers and nothing due now adds "Next cards fall due tomorrow." / "…on {date}." / nothing when none is learned: `SessionSummary.nextDueAt`, read with the `subtreeCounts` that `_remainingDueOf` already reads, now for every review summary with answers, shown through `caughtUpWhenOf`. The ended/failed facts card is unchanged. | S/session_summary_hero_widget.dart:218-263, study_session_view_model.dart:200, study_session_view_repository_impl.dart:66, study_session_view_mapper.dart:41 |
| 4.26 | The footer has no caption ("Done returns you to the deck." restated the button). | S/session_summary_widget.dart:78, ARB `summaryDoneCaption` |
| 4.27 | Plural bodies: "The 1 card you reviewed is kept. The other 4 are still due." (ICU plural on kept and left, review and learning). A left-early learning session with no finished card: "None of the cards finished learning yet. Your {n} answers are kept." / "Chưa thẻ nào học xong. {n} câu trả lời của bạn được giữ." so "0 finished" never sits beside Answered. | S/session_summary_hero_widget.dart:128-135, ARB |
| 4.28 | "— the session limit" appears only when the limit actually cut the review (`remainingDueCount > 0`). Due equal to the limit with nothing left reads the plain finished body. `summaryReviewAtLimitBody` and `isAtCardLimit` go. | S/session_summary_hero_widget.dart:117, study_session_view_model.dart:234 |
| V1 (21) | The reset body defines its cycle: "…stay in the history, apart from the new cycle (a cycle runs from one reset to the next)." | ARB `summaryResetBody` |

### 3.7 Progress (22)

| # | Fix | Where |
|---|---|---|
| 4.29 | The Streak card has one eyebrow and one level: the recessed tile and its "Current" label go; the flame tile, "{n} days" and its sub sit directly in the card, as Today's figure does. | P/widgets/sections/progress_streak_widget.dart:66-122, ARB `progressStreakCurrent` |
| 4.30 | The figure has its noun: "17 cards" (`progressTodayCards`). The sub line is "{l} learning · {r} reviewing" and stays on one line; the once-a-day rule moves to 4.32's footer. | P/widgets/sections/progress_today_widget.dart:44-52, ARB `progressTodaySplit` |
| 4.31 | The chart's day labels use `DateFormat.E` ("Mon", "Th 2"), not the narrow initial, so Tuesday and Thursday, Saturday and Sunday differ. The label already scales down to fit. | P/widgets/sections/progress_today_widget.dart:76 |
| 4.32 | The footer is the V1 definition: "A card-day is one card studied on one day." / "Một lượt theo ngày là một thẻ được học trong một ngày." ("Read-only · resets change nothing here" goes.) | P/widgets/sections/progress_level_list_widget.dart:77, ARB `progressFooter` |
| 4.33 | Never studied: one message. Today shows its eyebrow, the dashed note "Your last seven days and your streak start with your first study day. Browsing cards does not count." / "Bảy ngày gần nhất và chuỗi ngày học bắt đầu từ ngày học đầu tiên. Chỉ lướt thẻ thì không tính." and Start studying. The "0", "Nothing studied yet" and the Streak card are not drawn in this state. | P/widgets/sections/progress_today_widget.dart:32-60, P/screens/progress_screen.dart:97 |

### 3.8 Shared session chrome (16–20) and the back gesture

| # | Fix | Where |
|---|---|---|
| 4.34 | Five clauses. (a) Pacing differs per mode: **ruled out by V3** (Match 600 ms, Guess 1200 ms or tap, Recall and Fill until Continue stay). (b) Again against Forgot: **DECISION D4**, recommended: Again is `secondary` like the other grades; the label and the interval name it. (c) Footer glyph rule: `info` for every instruction (Browse's swipe glyph and Fill's edit glyph become `info`), `repeat` only for a card that comes back. (d) Copy: "Be honest — grade how well you remembered" → "Grade how well you remembered"; "Be honest — the next card follows automatically" → "Pick one; the next card follows at once" (VI follows). (e) The mode badge keeps one minimum width (96) so the track's left edge does not shift between "MATCH" and "SELF-ASSESS" (DECISION D3). | U/study_grade_row_widget.dart:75, S/study_browse_widget.dart:145, S/study_fill_widget.dart:175, lib/shared/widgets/mx_study_top_bar.dart:48, ARB |
| 4.35 | `StudyWholeWordTextWidget` never scales below 0.6; past that floor the word breaks inside, as ordinary text does. | U/study_whole_word_text_widget.dart:85 |
| 4.36 | The busy banner names the mode: title "Couldn't move on" for Browse, else "Couldn't save that answer"; body by mode via ICU select: browse "The device is busy. Nothing was lost; tap Retry.", match "…Your pair is kept; tap Retry.", guess "…Your pick is kept…", self-assess "…Your grade is kept…", else "…Your answer is kept…" (VI follows). While an answer is unsaved, Guess and Match take no tap; Guess shows the pending pick as selected, Match the pending pair. | SCR/study_session_screen.dart:372, S/study_guess_widget.dart:213, S/study_match_widget.dart:68, ARB `studyAnswerBusy*` |
| 4.12 | **Merged into 4.36**: Browse's busy banner no longer says "Your answer is kept". | as 4.36 |
| 4.37 | Import: `PopScope.canPop` is true at step 1 and on a result (the route closes by `context.pop()`), false on later steps and while writing, so Android's back preview runs where Back only closes. Session: **ruled out**; an open session must confirm Stop, and the route is entered with `go()`, so a preview would show the wrong destination. Coordinate with SP3, which edits the same screen. | lib/features/transfer/presentation/screens/card_import_screen.dart:72 |

## 4. Shared code

All three change `lib/shared/`; none touches `lib/core/`. The owner approves them in one popup.

- **DECISION (owner) D1: `MxStatTile` boxed layout.** Recommended: drop the inner surface and
  padding, keep start alignment (rename `boxed` to `start`). Two callers: the entry hero and the
  gallery. Why: 4.04 is the surface pushing the figures off the card's text edge; a flat tile
  needs no new API. Alternative: keep the box and inset the overline, which leaves the nesting.
- **DECISION (owner) D2: `MxTextField` study variant multi-line.** Recommended: yes. Only Fill
  uses the variant. Why: the `term` variant already wraps with Enter acting as the action; a
  one-line answer field hides the start of "ăn cơm rồi" while it is typed.
- **DECISION (owner) D3: `MxStudyTopBar` badge minimum width 96.** Recommended: yes. Why: a
  constant removes the track's shift without measuring every mode label.
- **DECISION (owner) D4: Again is neutral (4.34b).** Not shared code, but it revises the 16a
  ruling "Again is error-tinted" and DESIGN.md's "grades that judge the learner share one tone".
  Recommended: neutral, so Self-assess and Recall judge alike and the screen stays calm
  (audience: working adults); the interval under each grade still tells them apart.

Feature-local, no decision needed: `RootDeckWorkload.firstDueDeck`, `differingIndexesOf`,
`SessionSummary.nextDueAt`, the Recall clock bar, `StudyWholeWordText`'s floor.

## 5. Business-rule changes

- **UC-STUDY-002** (`docs/features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md`),
  main flow, new step 3b: "Nếu có thẻ đến hạn, workload card có **một** hành động Study mở
  study entry của deck đứng đầu danh sách (BR-STUDY-076) còn thẻ Overdue hoặc Due today. Hành
  động không tạo session; phiên vẫn mở theo từng deck." Acceptance: "**Given** có thẻ đến hạn,
  **when** người dùng chạm hành động Study của workload card, **then** study entry của deck đứng
  đầu danh sách còn thẻ đến hạn được mở và không có session nào được ghi (V2, BR-STUDY-076)."
- **BR-STUDY-076**: one sentence: "Deck đứng đầu danh sách mà còn Overdue hoặc Due today MUST là
  đích của hành động Study ở workload card."
- **BR-STUDY-026**: add "Giao diện MUST nêu quy tắc giữ dấu trước câu trả lời đầu tiên của lượt
  `fill`, không chỉ sau khi sai (chủ dự án 2026-10-03, V5). Khi sai, giao diện MUST đánh dấu chỗ
  khác giữa câu đã gõ và đáp án." Enforced by becomes `rule + UI`.
- **BR-STUDY-031**: add "20 giây giữ nguyên cho mọi người dùng, kể cả TalkBack (chủ dự án
  2026-10-03, V4)."
- **UC-STUDY-001** step 13 (summary) and its acceptance list: the review summary states the
  right-answer rate and, when no card is due now, the day the next falls due (4.25).

## 6. Testing

Test-first for every behaviour row. Run subsets with `run_tests.sh`.

| Cluster | Tests | Review Focus (inputs no row's own test exercises) |
|---|---|---|
| 13 Home | `study_home_screen_test.dart`, `study_home_workload_ink_test.dart`, `study_home_golden_test.dart`, a model test for `firstDueDeck` | Two decks tied on overdue and due today (name order decides); the first row has only New; the first deck has no card; a Resume card present (button secondary); a very long deck name |
| 14–15 | `study_entry_actions_test.dart`, `study_entry_screen_test.dart`, `study_entry_golden_test.dart`, `study_options_screen_test.dart`, `study_options_controller_test.dart`, `study_options_golden_test.dart` | Only-new with a resume banner (row without button, footer outline); Eight boxes with every mode unavailable (glossary note still last); an emptied limit field then Save; invalid "500" then Back; VI caption widths at 360dp |
| 16 / 16a | `study_browse_test.dart`, `study_self_assess_test.dart`, `study_session_screen_test.dart` | A one-card stage (first and last at once); look back on the last card (label returns to "Next card"); a card in round 2 revealed (badge and hint); a double tap on Next after the swap |
| 17–18 | `study_match_test.dart`, `study_guess_test.dart`, `study_guess_match_golden_test.dart` | Deselect then pick the other column; a board with one 80-character meaning among short ones; five long options on a 640dp-high screen with a wrong pick (right option scrolled in); an unsaved pick then a tap on another option |
| 19–20 | `study_recall_test.dart`, `study_fill_test.dart`, `study_recall_fill_golden_test.dart`, `spelling_diff_state_test.dart` (new) | Reveal at 0.4 s left ("Revealed with 1s left"); the clock under the exit dialog; typed "cong" or "CÔNG " against "công"; a 60-character multi-word answer; a hint used then Check; Fill at 700×360 with a 220dp inset |
| 21 | `session_summary_test.dart`, `session_summary_truth_test.dart`, `summary_remaining_due_test.dart` | Due equal to the limit exactly, then limit plus one; 1 kept and 1 left; learning left early with 0 finished and 3 answered; 23 turns, 0 wrong (100%) and 23 wrong (0%); next due today, tomorrow and 10 days out |
| 22 | `progress_screen_test.dart`, `deck_progress_screen_test.dart`, goldens | Never studied (one message only, no Streak card); a held and a lost streak without the tile; Sat/Sun and Tue/Thu labels in en and vi at 360dp |
| Shared | `mx_stat_tile_test.dart`, `mx_text_field_test.dart`, `mx_study_top_bar_test.dart`, `study_whole_word_text` in `study_support_widgets_test.dart`, `card_import_screen_test.dart` | A 40-character unbroken word at 0.6 scale; the study field's Enter and IME Done; the import wizard's Back at step 1, step 2 and on the result |

## 7. Goldens

Default text scale only. Regenerated in the Linux container; the owner gets the
`golden-compare` page before the merge.

- **Move:** `study_home_{loaded,no_resume}_*`; `study_entry_{sm2,eight_box,only_new,resume}_*`;
  all `study_options_*` (note position, caption); `study_browse_*`; `study_self_assess_*`
  (grades neutral); `study_match_*`; `study_guess_*`; `study_recall_{counting,revealed,timed_out}_*`;
  `study_fill_*`; every `summary_*` (no caption; stats on the ones with answers);
  `progress_{week,month,held,lost,never,quiet}_*`, `deck_progress_*` (footer line).
- **New:** `study_browse_last_card`, `study_self_assess_relearning` (badge; the file exists and
  moves), `study_fill_wrong_marked`, `study_fill_landscape_keyboard`, `summary_review_next_due`,
  `progress_never` (moves), `study_home_loaded_with_resume` (secondary action beside Resume).

## 8. Out of scope

- SP3, SP5. `settings_controller.dart`'s `typeCardLimit` has the same emptied-field gap as 4.09
  and belongs to 5.05.
- Large text scales; two-pane layouts; any change to scheduling, the Recall duration (V4) or
  the Guess hold (V3).
- A session-wide predictive-back preview (4.37, session part).

## 9. Docs and WBS

Update in the same PR: detail files `13-study-home.md`, `14-study-entry.md`, `15-study-options.md`,
`16-study-browse.md`, `16a-study-self-assess.md`, `17-study-match.md`, `18-study-guess.md`,
`19-study-recall.md` (close "Open for the owner" by V4), `20-study-fill.md`, `21-session-summary.md`,
`22-progress.md`; `DESIGN.md` (MxStatTile, StudyCtaRow grade tones, SessionFooterHint glyph rule,
MxStudyTopBar badge width); the files of §5; the screen index rows only if a state is added.
`docs/wbs_FE.md`: add FE-D31 (SP4), "xong" only after the gate and Linux goldens are green.

## 10. Row ledger

| Outcome | Rows |
|---|---|
| Fixed (36) | 4.01–4.11, 4.13–4.37 (4.34 with its pacing clause ruled out by V3, 4.37 with its session part ruled out) |
| Merged (1) | 4.12 into 4.36 |
| Already fixed (0) | none |
| Ruled out (0 whole rows) | 4.34a by V3; 4.37 session part; V4 closes a doc note, not a row |

## Owner decisions (2026-10-03, `AskUserQuestion`)

- **D1, D2, D3:** approved — `MxStatTile` boxed loses its inner surface; the study
  `MxTextField` variant wraps; the `MxStudyTopBar` mode badge has a 96 dp minimum width.
- **D4:** declined — Self-assess "Again" keeps its current tone; 4.34b is ruled out.
- **V1 placement:** "stage" and "round" are defined once, on screen 14.
