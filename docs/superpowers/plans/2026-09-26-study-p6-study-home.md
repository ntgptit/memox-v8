# Study P6 — FE-A8 Study Home (13) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the Study tab shows screen 13, Study Home: the session Resume card, the library's workload, and every root deck with its whole-tree workload. It replaces the placeholder (UC-STUDY-002).

**Architecture:** a read-only screen over the existing BE-A6 read model (`WatchStudyHomeUseCase`, BR-STUDY-075). It adds:

- two providers, one for the use case and one for the stream;
- a small controller for Resume, whose only write is the resume use case (H3, D4);
- presentational sections for the Resume card, the workload hero, the deck list, the empty states, loading and error.

`app/` composes the screen into the Study branch and wires its three destinations: the session route, a deck's Study Entry, and the Library.

The shared layer gains two things:

- `MxLinearProgress`, the themed track, used by 13's Resume card and 14's resume banner (H2);
- a fourth, muted "scheduled" term on `MxWorkloadBreakdownLine` (H1, BR-STUDY-068).

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, go_router, Drift (in-memory in tests), `flutter gen-l10n`.

**Spec / brief:** FE-A8 has no spec of its own. The brief is the handoff [13-study-home.md](../../shared/ui/screen-handoff/13-study-home.md) with UC-STUDY-002 and BR-STUDY-008, 068, 074–077. Roadmap rulings H1–H4 are in [2026-09-26-study-chain-roadmap.md](2026-09-26-study-chain-roadmap.md) (approved by the owner). Pre-plan critique: `.impeccable/critique/` (P6 snapshot, written in Task 1).

**Rulings added by the pre-plan critique** (ledgered at Task 1; recorded in 13 at Task 7):

- **S1 (P0) = H1, refined:**
  - "Scheduled" is `total − New − Due` of the same snapshot (BR-STUDY-068). It is derived on `RootDeckWorkload` as `scheduledCount`, with no new query.
  - `MxWorkloadBreakdownLine` gains an optional fourth term in `onSurfaceVariant`: no headline and no warning tone.
  - Only the hero passes it; deck rows keep three terms (BR-STUDY-076).
- **S2 (P0):** the caught-up body is built from `nextDueAt` against the local day (BR-STUDY-074):
  - "…becomes due tomorrow." when it falls on the next local day;
  - "…becomes due on {date}." (`DateFormat.MMMd`) when it falls later;
  - "Every card is resting." alone when it is null.
  - The kit's static "tomorrow at 00:00" is not kept.
- **S3:** the "Continue studying" dot is static and decorative (`ExcludeSemantics`), as 14's already is. The kit's pulse is recorded as a deviation on 13 and 14. Screen 13 gets its own Accessibility section.
- **S4:** a deck row with no card (`canStudy == false`) is `MxListRow(onTap: null, isEnabled: false)`: dimmed, and announced as disabled.
- **S5:** the hero title, "across N decks" and the row badge are ICU plurals.
- **S6:** at 2x text a row's breakdown ellipsizes (single line, D19/row 102). A 2x golden with the kit's longest deck name must still show the first term.
- **S7:** `MxLinearProgress` carries no semantics of its own; the text beside it states the fraction.
- **S8:** a refused Resume shows the toast "This session can't be continued any more", and the stream refreshes by itself (H3).
- **S9:** Resume is `MxButton` primary, block, with the play glyph, as the handoff's layout names it. The kit's soft-primary pill has no V8 tone: `primary-soft` is PRESERVE_ONLY in the theme binding.
- **S10:** a deck row and the caught-up/empty states' "Library" actions navigate as the session summary's "Study this deck" does: `context.go` to the Library branch (`AppRoutes.studyEntry(deckId)`, `AppRoutes.decks`). Back from that entry leads to the deck.
- **S11:** the loading state uses `MxSkeleton` shapes (it pulses; tests never `pumpAndSettle` on it). A loading golden overrides the stream with one that never emits.

## Global Constraints

- `study` imports only `study_mode`, `srs`, `settings`, `card`. `presentation/` never imports `data/`, and `app/` composes.
- Presentation files end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
- Every user-facing string is an ARB key in `app_en.arb` and `app_vi.arb`, semantics labels included.
- Controllers and build methods:
  - no `ref.read` in `build()`;
  - `if (!ref.mounted) return;` after every await in a controller.
- Booleans read as predicates. No source file exceeds 400 physical lines.
- Features pass no `Color`, `TextStyle`, radius or padding to shared widgets, and never restyle text.
  - No raw Material buttons, `InkWell`, `Card` or `ListTile` in features.
  - No `Icon(color:)`; use `IconTheme`.
- Study Home writes nothing but the Resume use case (BR-STUDY-075, H4).
- Tests never read the wall clock (`libraryToday`). Goldens run on Linux with `TZ=UTC`.

## Review Focus

1. The caught-up body's day arithmetic at the local-day boundary: `nextDueAt` at 00:00 the next day says "tomorrow", and at 00:00 two days later it gives the date (BR-STUDY-074).
2. "Scheduled" never goes negative, and the four terms add up to the total. A deck with overdue cards must not count them twice.
3. Resume is busy-guarded: a double tap starts one resume and opens one route.
4. A deck with no card cannot be tapped and is announced as disabled.
5. Loading never hangs a test: no `pumpAndSettle` while the skeleton shows.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | 13 copy |
| `lib/features/study/domain/models/study_home_model.dart` | modify | `RootDeckWorkload.scheduledCount` |
| `lib/shared/widgets/mx_linear_progress.dart` | create | the themed track (H2) |
| `lib/shared/widgets/mx_workload_breakdown_line.dart` | modify | the fourth, muted term (S1) |
| `lib/features/study/presentation/providers/watch_study_home_use_case_provider.dart`, `study_home_provider.dart` | create | the read side |
| `lib/features/study/presentation/controllers/study_home_controller.dart` | create | Resume (H3) |
| `lib/features/study/presentation/states/study_home_caught_up_state.dart` | create | the S2 day rule, a pure function |
| `lib/features/study/presentation/screens/study_home_screen.dart` | create | 13 |
| `lib/features/study/presentation/widgets/sections/study_home_{resume,workload,decks,empty}_widget.dart` | create | 13's sections |
| `lib/features/study/presentation/widgets/sections/study_entry_resume_widget.dart` | modify | the track (H2) |
| `lib/app/router/app_router.dart` | modify | the Study branch |
| tests, goldens, companions, docs | create/modify | proofs and records |

---

### Task 1: Strings, the read model's scheduled count, and the two shared widgets

First, write the pre-plan critique snapshot and ledger S1–S11.

**Files:**
- Modify: ARB files, `study_home_model.dart`, `mx_workload_breakdown_line.dart`.
- Create: `mx_linear_progress.dart`.
- Tests:
  - `test/features/study/domain/study_home_test.dart`;
  - `test/shared/widgets/mx_workload_breakdown_line_test.dart` (create if absent);
  - `test/shared/widgets/mx_linear_progress_test.dart`.

**Strings** (en · vi; `@` descriptions "Screen handoff 13 (FE-A8): …"):

| Key | English | Vietnamese |
|---|---|---|
| `studyHomeTitle` | `Study` | `Học` |
| `studyHomeResumeOverline` | `Continue studying` | `Học tiếp` |
| `studyHomeResume` | `Resume` | `Học tiếp` |
| `studyHomeResumeRefused` | `This session can't be continued any more` | `Không thể tiếp tục phiên này nữa` |
| `studyHomeWaiting` | `Waiting for you` | `Đang chờ bạn` |
| `studyHomeDueTitle` | `{count, plural, =1{1 card due} other{{count} cards due}}` | `{count} thẻ đến hạn` |
| `studyHomeAcrossDecks` | `{count, plural, =1{across 1 deck} other{across {count} decks}}` | `trong {count} bộ thẻ` |
| `workloadScheduled` | `{count} scheduled` | `{count} đã lên lịch` |
| `studyHomeCaughtUpTitle` | `Nothing due right now` | `Hiện chưa có thẻ đến hạn` |
| `studyHomeCaughtUpTomorrow` | `Every card is resting. The next one becomes due tomorrow.` | `Mọi thẻ đang nghỉ. Thẻ tiếp theo đến hạn vào ngày mai.` |
| `studyHomeCaughtUpOn` | `Every card is resting. The next one becomes due on {date}.` | `Mọi thẻ đang nghỉ. Thẻ tiếp theo đến hạn vào {date}.` |
| `studyHomeCaughtUpResting` | `Every card is resting.` | `Mọi thẻ đang nghỉ.` |
| `studyHomeDecks` | `Your decks` | `Bộ thẻ của bạn` |
| `studyHomeLibrary` | `Library` | `Thư viện` |
| `studyHomeRowDue` | `{count} due` | `{count} đến hạn` |
| `studyHomeNoDecksTitle` | `Nothing to study yet` | `Chưa có gì để học` |
| `studyHomeNoDecksBody` | `Your library is empty. Create a deck in Library to get started.` | `Thư viện đang trống. Hãy tạo một bộ thẻ trong Thư viện để bắt đầu.` |
| `studyHomeNoCardsTitle` | `Your decks have no cards yet` | `Các bộ thẻ chưa có thẻ nào` |
| `studyHomeNoCardsBody` | `Add cards to a sub-deck, or import them from a file, and they will show up here.` | `Thêm thẻ vào một bộ thẻ con, hoặc nhập từ tệp, thẻ sẽ hiện ở đây.` |
| `studyHomeGoToLibrary` | `Go to Library` | `Mở Thư viện` |
| `studyHomeErrorTitle` | `Couldn't load your study overview` | `Không tải được tổng quan học tập` |
| `studyHomeErrorBody` | `Your cards are safe on this device. You can still open Library directly.` | `Thẻ của bạn vẫn an toàn trên thiết bị. Bạn vẫn có thể mở Thư viện.` |

(`studyHomeDueTitle` and `workloadScheduled` take `count` int; `studyHomeCaughtUpOn` takes `date` String.)

**Interfaces — Produces:**
- `RootDeckWorkload.scheduledCount`: the sum of each deck's `cardCount − newCount − overdueCount − dueTodayCount`, each floored at 0.
- `MxWorkloadBreakdownLine(..., int scheduledCount = 0, String Function(int)? scheduledLabel)`:
  - the fourth term comes last, in `onSurfaceVariant`, and only when its count is above 0 and a label is given;
  - it never on its own replaces the fallback, because the fallback shows only when all shown terms are 0.
- `MxLinearProgress({required double value})`, `value` in `0..1`:
  - a 4-tall rounded track (`MasteryRamp.track`) with a `primary` fill;
  - it eases over `AppDurations.standard`, at once under Remove animations;
  - it carries no semantics of its own (S7). This is the top bar's drawing, as a widget.

- [ ] **Step 1: Failing tests.**
  - `scheduledCount` on a snapshot of two decks (10 cards: 2 overdue, 3 today, 1 new → 4; and 5 cards all new → 0) is 4.
  - The breakdown with `scheduledCount: 4` shows "4 scheduled" after "1 new", with the muted ink (the span's colour is `onSurfaceVariant`); without a label, no fourth term.
  - `MxLinearProgress(value: 0.6)` has a fill width factor of 0.6, `find.bySemanticsLabel` finds nothing of its own, and a value above 1 asserts.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement, then run `flutter gen-l10n`.
- [ ] **Step 4:** Run the tests and `flutter test test/shared test/features/study/domain`. Expected: PASS, with no golden moved.
- [ ] **Step 5:** Commit: `feat(study): Study Home strings, scheduled count, MxLinearProgress, a fourth workload term (FE-A8 P6)`.

---

### Task 2: The read side and Resume (H3)

**Files:**
- Create: the two providers, `study_home_controller.dart`, `states/study_home_caught_up_state.dart`.
- Tests: `test/features/study/presentation/study_home_controller_test.dart`, `study_home_caught_up_state_test.dart`.

**Interfaces — Produces:**
- `@riverpod WatchStudyHomeUseCase watchStudyHomeUseCase(Ref)` over `studyHomeRepositoryProvider` and `dayClockProvider`.
- `@riverpod Stream<StudyHome> studyHome(Ref)`.
- `@riverpod class StudyHomeController`:
  - `build() => false` (is resuming);
  - `Future<Outcome<String, StudyRejection>?> resume(String sessionId)`: null when dropped while one runs; otherwise `Ok(sessionId)` or `Rejected`.
- `sealed class CaughtUpWhen { Tomorrow; OnDay(DateTime day); Resting }` and `CaughtUpWhen caughtUpWhenOf(DateTime? nextDueAt, DateTime now)`, using `startOfLocalDay` from `srs/domain/models/due_date_model.dart`.

- [ ] **Step 1: Failing tests.**
  - `caughtUpWhenOf(null, now)` → `Resting`.
  - Tomorrow 00:00 → `Tomorrow`, and tomorrow 23:59 → `Tomorrow`.
  - The day after tomorrow 00:00 → `OnDay(that day)`.
  - Today later (impossible when caught up, but defined) → `Tomorrow`.
  - The controller:
    - resumes today's session (seeded by opening one): `Ok(id)`;
    - two concurrent calls → one `Ok`, one null;
    - a session from yesterday → `Rejected`, and `isResuming` is false after.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3:** Implement, then run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(study): Study Home read side and Resume (FE-A8 P6, H3)`.

---

### Task 3: Screen 13

**Files:**
- Create: `study_home_screen.dart` and the four section widgets.
- Test: `test/features/study/presentation/study_home_screen_test.dart`.

**Interfaces — Produces:** `StudyHomeScreen({required ValueChanged<String> onOpenSession, required ValueChanged<String> onOpenDeck, required VoidCallback onOpenLibrary})`.

**Layout:**
- `MxAppShell` with `MxAppBar(title: studyHomeTitle, density: screen)`.
- The body is an `MxScreenScroll`:
  - the Resume card (when `resumable != null`);
  - then, by `content`:
    - `NoRootDecks` → `MxEmptyState` (primary tone, "Go to Library");
    - `NoCards` → `MxEmptyState` (neutral, "Go to Library");
    - `RootDeckWorkload` → the hero, the section header with the Library button (`MxButton` compact secondary), and the deck list.
- Loading shows skeleton shapes. An error shows `MxErrorState` with Retry, which invalidates `studyHomeProvider`.

**The Resume card:**
- an overline with a static dot;
- an `MxIconTile(icon: pause, tone: primary)`;
- the deck name (row title);
- `studyEntryResumeLine` or `…NoProgress` (reused copy);
- `MxLinearProgress(completed / total)`;
- a primary block `MxButton(studyHomeResume, icon: play)`, disabled while resuming.

Resume awaits the controller: `Ok` → `onOpenSession(id)`; `Rejected` → `showMxSnackbar(studyHomeResumeRefused)`.

**The hero:**
- workload > 0: an `MxCard(isHero)`. It holds the overline "Waiting for you" (with a primary glyph in `IconTheme`), the title `studyHomeDueTitle(dueCount)`, and a breakdown with scheduled plus the suffix `studyHomeAcrossDecks(workloadDeckCount)`.
- caught up: an `MxCard` with an `MxIconTile(check, success tone)`, the title `studyHomeCaughtUpTitle`, and the S2 body.

**Rows:**
- an `MxListRow`: title = name; meta = the three-term breakdown (fallback `workloadNothingDue(cardCount)`, or `workloadNoCards` when there is no card); leading `MxIconTile(layers, small)`;
- trailing: `MxBadge(studyHomeRowDue(due))` when due > 0, else the chevron;
- `onTap` and `isEnabled` follow `canStudy` (S4).

- [ ] **Step 1: Failing tests** (`libraryTest` with the real backend; pump a `Scaffold`-free `StudyHomeScreen` through `pumpLibraryScreen`; never `pumpAndSettle` before data).
  - **loaded:** open a session on one deck, answer one turn. Then:
    - "Continue studying" shows, with the deck name, "Review · Match · 1 of 5 cards" (or the fixture's kind and mode), a track at 0.2, and Resume;
    - the hero reads "{n} cards due" with its breakdown and "across {k} decks";
    - rows are in BR-STUDY-076 order, with the badge "{n} due".
  - **noResume:** no Resume card.
  - **zero:** decks with only resting learned cards, next due tomorrow → the caught-up card says "tomorrow". Next due in 3 days → "on {MMMd}".
  - **noDecks:** "Nothing to study yet"; the starter line is absent; "Go to Library" calls `onOpenLibrary`.
  - **noCards:** "Your decks have no cards yet"; no number shows anywhere.
  - **Disabled row:** a root with no card is dimmed. Tapping it does nothing, and its semantics node has `isEnabled: false` (S4).
  - **Row tap** → `onOpenDeck(rootId)`. The Library button → `onOpenLibrary`.
  - **Resume:** Ok → `onOpenSession(id)`. A refused resume (a session from yesterday) shows the toast, and `onOpenSession` is not called.
  - **2x:** no overflow; every row stays at least 48 tall; the Resume button is reachable.
  - **error:** override `studyHomeProvider` with a stream that errors → `studyHomeErrorTitle`; Retry reads again.
  - **loading:** override with a never-emitting stream → skeletons, with no `pumpAndSettle`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement, splitting sections to keep each file under 400 lines.
- [ ] **Step 4:** Run `flutter test test/features/study`. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(study): screen 13, Study Home (FE-A8 P6)`.

---

### Task 4: The Study tab, and 14's track (H2)

**Files:**
- Modify: `lib/app/router/app_router.dart`, `study_entry_resume_widget.dart`.
- Tests:
  - `test/app/study_routes_test.dart` (the tab);
  - `test/features/study/presentation/study_entry_screen_test.dart` (the track);
  - `test/app/app_test.dart`, if it asserts the Study placeholder.

- [ ] **Step 1: Failing tests.**
  - The Study tab shows `StudyHomeScreen`, not the placeholder.
  - A deck row opens that deck's `StudyEntryScreen` (the session count stays 0).
  - Resume opens `StudySessionScreen`.
  - "Library" shows the Library root.
  - 14's resume banner shows an `MxLinearProgress` at `completed / total` when progress is known, and none when it is not.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement:
  - the Study branch builds `StudyHomeScreen`, wiring `onOpenSession: (id) => context.go(AppRoutes.studySession(id))`, `onOpenDeck: (id) => context.go(AppRoutes.studyEntry(id))` and `onOpenLibrary: () => context.go(AppRoutes.decks)`;
  - 14's banner inserts the track under its line.

  Remove any test that asserted the Study placeholder, and ledger it.
- [ ] **Step 4:** Run `flutter test test/app test/features/study`, then the entry goldens (the resume golden moves by the track; view it). Expected: PASS.
- [ ] **Step 5:** Commit: `feat(app): the Study tab shows Study Home; 14's resume banner gains its track (FE-A8 P6, H2)`.

---

### Task 5: Goldens and the visual audit

- [ ] **Step 1: Goldens** in `test/features/study/presentation/study_home_golden_test.dart`, light and dark, against the kit's data where it matters:
  - `study_home_{loaded,no_resume,zero,no_decks,no_cards,loading,error}`;
  - `study_home_large_text` (2x, loaded, with the kit's longest deck name).
  - Render with `TZ=UTC flutter test --tags golden --update-goldens`, and view every image against `img/13-study-home/*`.
  - Regenerate 14's resume golden and view it.
- [ ] **Step 2: Visual-audit companion:** "screen 13, Study Home loaded" in `test/visual_audit/screens/features/study/screens/`, a new `study_home_screen_visual_audit_test.dart` in the existing pattern. The coverage test requires one per production screen.
- [ ] **Step 3:** Run `flutter test test/visual_audit`. Expected: PASS.
- [ ] **Step 4:** Commit: `test(study): Study Home goldens and visual audit (FE-A8 P6)`.

---

### Task 6: Records

- [ ] **Step 1:**
  - Handoff 13:
    - a Built note, with the goldens;
    - the Deviations table plus S2 (no "at 00:00"), S3 (the static dot), S9 (the Resume button), and S10 (navigation to the Library branch);
    - an Accessibility section (S3, S4, S5, S7);
    - the Copy corrected to V8's.
  - Handoff 14: the track, and the static-dot deviation.
  - The rest of the records:
    - index row 13 → `built (P6)`;
    - the screen-state checklist: all 7 of 13's states done, with the totals re-summed;
    - `wbs_FE.md`: FE-A8 → `xong`, with the next step and the overview paragraphs updated, including P5's leftover minor on FE-A8's cell;
    - the roadmap: P6 marked done.
- [ ] **Step 2:** Run `python3 tools/docs/generate.py && python3 tools/docs/check.py`. Expected: PASS.
- [ ] **Step 3: Gate:** `dod_check.sh` and `TZ=UTC flutter test --tags golden`. Expected: green.
- [ ] **Step 4:** Commit: `docs(study): FE-A8 records — handoffs 13, 14, index, checklist, WBS (P6)`.
