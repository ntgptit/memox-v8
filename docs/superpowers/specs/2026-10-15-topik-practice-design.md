# TOPIK Practice: past-paper practice with official scoring

Date: 2026-10-15 · Owner decisions in the brainstorm of 2026-10-15 · Status: approved by the owner 2026-10-15 (§13); built by plans 1–6c (DEV-394); plan 7 (the round-96 pack) waits on the NIIED files. As built, Summary shows one row per answer and the eye hides "Right answer" (screen 38, S5 and S9).

## 1. Goal

A new feature, `topik`, lets the learner practise the published TOPIK past papers
(NIIED, PBT) inside MemoX: choose TOPIK I or II, a section (듣기 Listening /
읽기 Reading), a round (회차), take the test, then read the result, the history,
the progress on that test and a review of each question.

The score must be computed **exactly as the real exam does**, from the official
per-question points (배점), because the learner uses it to judge their level.

Nothing that exists changes behaviour. The only touch on existing code is one
entry region on Study home (screen 13), the router, the account-switch reset and
the sync registry. Every other piece is new and lives in `lib/features/topik/`
and its own tables.

## 2. Owner decisions (2026-10-15)

| # | Decision |
|---|---|
| D1 | Entry: one TOPIK entry card on Study home (screen 13). The four top-level destinations stay as they are (`navigation.md`, ADR-009 #3). |
| D2 | Content ships as bundled assets for the MVP (`assets/topik/`), with no refresh button. Downloadable content packs come in Phase B with their own spec, because twelve rounds of MP3 do not fit an APK. |
| D3 | This repository holds the content schema, the validator, the lint and the validated packs. The authoring pipeline (PDF/MP3 → JSON) lives in a separate repository, `memox-topik-content`. |
| D4 | TOPIK user data **syncs from the start** (§7). |
| D5 | The first real round is **96 (2024)**. The owner supplies the official files (문제지 PDF, 정답·배점표, MP3, 듣기 대본); this container cannot reach `topik.go.kr`. Until then the code is built and tested on a synthetic fixture. |
| D6 | Explanations and translations are optional per question, but every multilingual text that exists carries **both `vi` and `en`**. |
| D7 | Practice mode offers audio speed 0.75 / 1.0 / 1.25 / 1.5. |
| D8 | Time does not count while the app is in the background. |
| D9 | The estimated grade (급) is Phase B. |
| D10 | Writing (쓰기 51–54) is Phase C: save the text, count characters by the 원고지 rules, show the official model answer; no automatic grading. |
| D11 | Charts are drawn by hand (CustomPaint or widgets, as `MxMasteryDonut` and `MxStackedDayBars` are); no chart package. |
| D12 | The duration formatter (`1h 02m 11s`, to the second) is shared, in `lib/core/text/`. |
| D13 | Content is held in memory, never imported into Drift (§3.1). |
| D14 | Only **completed** attempts sync, as one immutable record; an in-progress attempt stays on its device (§7, approach A). The `abandoned` status of the original brief is dropped: no transition leads to it. |
| D15 | Practice mode shows no right/wrong before submit. The listening script opens once the question is answered, or through a "Show script" toggle, without the answer. |
| D16 | The per-question-type breakdown on Summary is in the MVP. |

## 3. Architecture

### 3.1 Content is data, not schema

The exam content is read-only, versioned and shipped as assets. It is loaded from
JSON, validated, and held in memory as immutable domain models (`TopikTest`,
`QuestionGroup`, `Question`, `Option`). Drift stores only what the user did.

Rejected: importing the content into Drift. Every new round would need a
migration or an import step, the content would exist twice, and nothing reads it
with SQL.

An attempt records the `test_id` and the `content_version` it was scored on. At
submit, the result is **snapshotted** into the attempt and its answers (§5.3), so
a later correction of the content never changes a past score, and Summary renders
from the snapshot alone.

### 3.2 Feature layout (ADR-010, ADR-011)

```
lib/features/topik/
  domain/models/        TopikTest, QuestionGroup, Question, TopikAttempt, AttemptAnswer, stats models
  domain/repositories/  TopikContentRepository, TopikAttemptRepository (contracts)
  domain/failures/      TopikRejection (Outcome reasons)
  domain/usecases/      one use case per interaction (§3.3)
  data/datasources/     content asset data source, attempt DAO, sync DAO
  data/mappers/         content JSON → models (shape and language rules), rows ↔ models
  data/repositories/    *_repository_impl.dart
  di/                   repository providers
  presentation/         screens 34–39, controllers, states, providers, widgets
lib/core/database/tables/topik.drift, queries/topik_queries.drift
lib/core/text/        duration formatter (D12)
```

`topik` depends on no other feature in the MVP (`depends_on: []`); Phase B adds
`deck` and `card` for "Create deck from this test". Study home receives the entry
card from `lib/app/` the way it receives the account feature's `reauthNotice`, so
`study` does not import `topik`.

The checker (`checkTopikTest`, `domain/models/topik_content_check_model.dart`) is pure Dart in `domain/`. The app's
loader and the gate's lint run the same code (§4.3).

### 3.3 Use cases (MVP)

`WatchTopikCatalogUseCase` (levels, tests per section with the user's status),
`WatchTopikTestDetailUseCase` (Overall Progress, Recent Attempts, History),
`StartTopikAttemptUseCase`, `WatchTopikAttemptUseCase`,
`AnswerTopikQuestionUseCase`, `MoveTopikQuestionUseCase` (records time and the
current question), `RecordTopikTimeUseCase` (background, exit),
`SubmitTopikAttemptUseCase`, `DeleteTopikAttemptUseCase`,
`WatchTopikSummaryUseCase`, `WatchTopikReviewUseCase`, as built in
`lib/features/topik/domain/usecases/` (plan `2026-10-15-topik-statistics-use-cases.md`).
Start new is `StartTopikAttemptUseCase(…, replaceInProgress: true)`; a test the
catalog no longer has is refused `testUnavailable` (BR-TOPIK-019).

## 4. Content

### 4.1 Schema (version 1)

```jsonc
{
  "schemaVersion": 1,
  "contentVersion": 1,                 // +1 on every content correction
  "testId": "topik2-96-listening",     // topik{1|2}-{round}-{section}
  "level": "topik2",                   // topik1 | topik2
  "round": 96,
  "section": "listening",              // listening | reading (writing: Phase C)
  "format": "pbt",
  "form": "B-홀수형",
  "titleKo": "제96회 한국어능력시험 II 듣기",
  "officialTimeLimitSec": 3600,
  "source": { "publishedBy": "NIIED", "url": "https://www.topik.go.kr/...", "publishedAt": "2025-..." },
  "assets": { "audio": "assets/topik/topik2/96/listening.mp3" },
  "groups": [
    {
      "groupId": "g21-22",
      "instructionKo": "※ [21～22] 다음을 듣고 물음에 답하십시오.",
      "questionNos": [21, 22],
      "passage": null,                 // { "textKo": "...", "image": "assets/..." } for reading
      "audio": { "startMs": 812000, "endMs": 905000, "playCount": 2 },
      "script": "남자: ... 여자: ...",
      "scriptTranslation": { "vi": "...", "en": "..." }
    }
  ],
  "questions": [
    {
      "no": 21,
      "groupId": "g21-22",
      "questionType": "L2_paired",
      "points": 2,
      "stemKo": "남자의 중심 생각으로 맞는 것을 고르십시오.",
      "options": [ { "idx": 1, "textKo": "...", "image": null }, { "idx": 2, "textKo": "..." },
                   { "idx": 3, "textKo": "..." }, { "idx": 4, "textKo": "..." } ],
      "answerIdx": 3,
      "explanation": { "vi": "...", "en": "..." },
      "translation": { "vi": "...", "en": "..." },
      "words": [ { "ko": "기획", "vi": "kế hoạch", "en": "planning", "pos": "n" } ],
      "grammars": [ { "pattern": "-(으)ㄹ 테니까", "vi": "...", "en": "..." } ]
    }
  ]
}
```

`totalScore` and `availableContent` from the original brief are **not authored**:
the total is the sum of `points`, and the content tags (explanation, translation,
words, grammars, script) are derived from the data, so neither can disagree with
it. A manifest (`assets/topik/manifest.json`) lists the pack files, as the starter
decks do.

### 4.2 Validation rules

| Area | Rule |
|---|---|
| Identity | `testId` matches `topik{1|2}-{round}-{section}` and the fields; unique across packs (a second file with the same id is rejected). |
| Metadata | `schemaVersion = 1`, `contentVersion ≥ 1`, `format = pbt`, non-empty `form`, `source.publishedBy = "NIIED"`, non-empty `source.url`. |
| Counts and numbers | T1 listening: 30 questions, 1–30. T1 reading: 40, **31–70**. T2 listening and reading: 50, 1–50. Numbers contiguous and unique. |
| Points | Positive integers summing to 100. T2: every question 2. T1 listening: each 3 or 4. T1 reading: each 2 or 3. |
| Options | Exactly four, `idx` 1–4 once each, each with `textKo` or `image`; `answerIdx` in 1–4. |
| Groups | Every question in exactly one group; a group's `questionNos` equal its questions' numbers; `groupId` unique. |
| Listening audio | Every group has `audio` with `0 ≤ startMs < endMs`; the section file exists. `playCount`: T1 every group 2; T2 questions 1–20: 1, 21–50: 2. |
| Question type | `questionType` belongs to the enum of its level and section (§4.4). A mismatch with the default number map is a **warning**, not an error. |
| Languages | Every multilingual object (`explanation`, `translation`, `scriptTranslation`, word and grammar meanings) has non-empty `vi` **and** `en` (D6). |
| Assets | Every referenced audio and image file exists in the bundle. |

The `playCount` and per-question-point rules come from the owner's investigation
(the brief's §2.2 and §2.4) and are **pending verification against round 96**:
they could not be checked against the official files from this container. When
the round-96 pack is linted, any mismatch fails the lint and is reported to the
owner. The rule is then corrected in this spec and its BR, never silently in
code.

### 4.3 One validator, two callers

- **App:** the loader validates each pack. An invalid test is skipped, logged as
  a warning (`topik.content_rejected`, with the test id and the first broken
  rule), and absent from every list; the other tests still load. Nothing throws
  to the UI for content.
- **Gate:** a test in the suite validates every pack under `assets/topik/`, so an
  invalid pack cannot merge. `dart run tools/topik/topik_lint.dart [contentRoot] [bundleRoot]` runs the same
  validator for the content repository and prints every broken rule. The gate test also requires every folder holding a pack or a referenced asset to be declared in `pubspec.yaml`, because Flutter does not read asset subfolders.

Rejected: a separate Python lint, which would be a second validator that drifts.

### 4.4 Question types

The enums are the brief's §2.5 tables: `L1_*` (8 values), `R1_*` (8), `L2_*` (7),
`R2_*` (13), each with the default question-number map used for the warning. Writing
types are added in Phase C.

### 4.5 Fixtures

The test fixture is synthetic: made-up short Korean-like text, structurally
complete (30/40/50 questions), with one broken variant per validation rule. It
lives under `test/`, is never bundled, and is not presented as real content.

## 5. Attempt

### 5.1 State machine (MVP, Practice mode)

| From | Event | To | Rule |
|---|---|---|---|
| — | Start | `inProgress` | Only for a valid test. When this device already has an `inProgress` attempt for the test, the user chooses **Continue** or **Start new**; Start new is confirmed, then deletes the old attempt and creates the new one in one transaction. |
| `inProgress` | Choose or change an answer | `inProgress` | Saved at once; the new choice replaces the old one. There is no "clear answer". |
| `inProgress` | Move to another question | `inProgress` | Time of the question left is saved; `current_question_no` is saved. |
| `inProgress` | Leave the screen, background, process death | `inProgress` | Continue from Test detail or History, on this device only. |
| `inProgress` | Submit | `completed` | Confirmed when a question is unanswered. Scored and snapshotted (§5.3); queued for sync. |
| `inProgress` | Delete (confirmed) | removed | Answers removed in the same transaction. Nothing to sync. |
| `completed` | Delete (confirmed) | removed | Answers removed in the same transaction; a final delete is synced. |
| `inProgress` | Time up (Exam mode, Phase B) | `completed` | Auto-submit. |

`completed` is immutable: no answer, time or score changes after submit.

### 5.2 Answers

An answer is the chosen option index (1–4) or none. In Practice mode nothing
tells the user whether a choice is right before submit (D15).

### 5.3 Scoring at submit

Per question, from the current content:

- status: `correct` when `selected_idx = answerIdx`, `wrong` when another index
  is chosen, `unanswered` when none;
- `points_earned = points` when correct, otherwise 0.

Per attempt: `score = Σ points_earned`, `max_score = Σ points` (100),
`correct_count`, `answered_count`, `question_count`, `content_version`,
`completed_at`.

Each answer row also stores the snapshot `correct_idx`, `points` and
`question_type`, so Summary needs no content. Nothing about correctness is stored
while the attempt is in progress; a content correction made before submit is the
one that scores.

### 5.4 Time

- Exactly one question is current at any moment: the attempt shows one question
  per page, with its group's shared instruction, passage and audio above it.
- Time accrues to the current question only while the attempt screen is in the
  foreground (D8). It adds up when the user returns to a question.
- `total_time_ms = Σ time_spent_ms`.
- Time is written on every answer change, question change, background transition
  and exit. A crash loses at most the time since the last of those.
- Stored in milliseconds; shown to the second through the shared formatter:
  `42s`, `3m 05s`, `1h 02m 11s`. Never milliseconds.

### 5.5 Audio (Practice mode)

- A group plays only its own range `[startMs, endMs]` of the section file:
  play, pause, seek inside the range, replay, speed 0.75 / 1.0 / 1.25 / 1.5 (D7).
- No autoplay. Moving between the questions of one group keeps the audio as it is;
  entering another group stops the previous group's audio.
- The script (듣기 대본) and its translation open once the current question is
  answered, or through the "Show script" toggle (D15).
- A file that fails to play shows an error with Retry inside the player; the
  attempt and its answers are untouched.

Exam mode (Phase B): the play count of §4.2, no seek, no pause, an answer
countdown after each group, auto-advance, and auto-submit at the section's time
limit. Not built in the MVP.

## 6. Statistics

All statistics are pure domain functions over a list of attempts (and, for Review,
the content). Scope is one test. Completed attempts include those synced from other
devices; in-progress attempts exist only on this device.

### 6.1 Overall Progress (MVP)

| Figure | Definition | No data |
|---|---|---|
| Sessions | number of attempts, any status | the card becomes an empty state with Start |
| Completed | number of `completed` | 0 |
| Completion | Completed / Sessions, whole percent | — |
| Accuracy | Σ `correct_count` / Σ `question_count` over completed, whole percent | — |
| Best | max `score` over completed | — |
| Average | mean `score` over completed, rounded half up to an integer | — |
| Last activity | max `updated_at`, as relative time | — |
| Total time | Σ `total_time_ms` over all attempts | 0s |

The card says "Scores use completed tests only".

### 6.2 Recent attempts and History (MVP)

Recent: the five latest attempts by `started_at`, newest first. History: all of
them, same order. The attempt number `#n` is the rank of the attempt among the
test's current attempts in ascending `started_at`; deleting one renumbers the
rest. A completed row shows `score / max_score`, the date and time, the duration,
`correct_count / question_count`; it opens Summary or Review. An in-progress row
shows "In progress" and opens the attempt (Continue).

### 6.3 Test list (MVP)

Each test shows its badge (`#96`), its Korean title, the derived content tags, and
the user's status: not started, in progress, or best score with the number of
completed attempts. Sort: round descending (default), round ascending, latest
activity (tests never taken last, then round descending).

### 6.4 Summary (MVP)

`score / max_score`; a donut of `correct_count / question_count`; Average per
question (total time over the number of questions; owner 2026-10-17, Impeccable
audit), Answered, Unanswered; Longest (most time; ties to the lower number); filters All,
Wrong, Unanswered, Correct; a horizontally scrolling bar per question coloured by
status; a table No · Your · Correct · Time · Status where Your and Correct are
option numbers (①–④), never option text; an eye toggle that hides Correct. Every
question number is the real one (TOPIK I reading starts at 31).

Per question type (D16): for each `question_type` in the attempt, correct / total.
The weakest type is the lowest accuracy among types with at least two questions;
ties go to the type with more questions, then to enum order. No weakest type is
named when no type has two questions or every type is at 100%.

### 6.5 Phase B formulas (fixed now, built later)

- **Trend:** needs n ≥ 2 completed. k = min(2, ⌊n/2⌋). Δ = mean of the latest k
  scores − mean of the k before them. Δ > 3 Improving, Δ < −3 Declining,
  otherwise Stable. Latest, Best and Average as in §6.1.
- **Hardest question:** most `wrong` across completed attempts (unanswered not
  counted); ties to more total time, then the lower number; hidden when no
  question was ever wrong.
- **Most skipped:** most `unanswered`; ties to the lower number; "—" when none.
- **Best mastered:** longest run of `correct` ending at the latest completed
  attempt; ties to the lower number; "—" when the latest attempt has no correct
  answer.
- **Estimated grade:** only when every section of the same level and round has a
  completed attempt (the best of each); sum, then TOPIK I: 80–139 → 1급, ≥ 140 →
  2급; TOPIK II: 120–149 → 3급, 150–189 → 4급, 190–229 → 5급, ≥ 230 → 6급; below
  the lowest threshold, no grade. Always labelled "estimated".

## 7. Data and sync

### 7.1 Tables (schema v16 → v17, create only)

`topik_attempt`: `id` (UUID v7), `test_id`, `level`, `section`, `round`, `mode`
(`practice`; `exam` added with Phase B), `status` (`in_progress`, `completed`),
`started_at`, `completed_at` (null while in progress), `updated_at`,
`total_time_ms`, `current_question_no`, `score`, `max_score`, `correct_count`,
`answered_count`, `question_count` (snapshot columns null while in progress except
`question_count` and `max_score`), `content_version`, `server_version`.

`topik_attempt_answer`: `attempt_id` (FK → `topik_attempt`, `ON DELETE
CASCADE`), `question_no`, `selected_idx` (1–4 or null), `time_spent_ms`,
`answered_at`, snapshot `correct_idx`, `points`, `points_earned`,
`question_type` (null while in progress). Primary key (`attempt_id`,
`question_no`).

Timestamps are UTC (ADR-008) in Drift's default storage; durations are integer
milliseconds. Exact types, checks and indexes are fixed in the engineering design
(deliverable 4).

Rollback: drop both tables and delete the outbox rows of the `topik_attempt`
entity type. No existing table changes.

### 7.2 Sync (approach A)

- Only `completed` attempts sync. Submit writes the attempt, its answers and one
  outbox operation in one transaction; the payload carries the attempt and all its
  answers (one entity type, `topik_attempt`).
- The server is **insert-only** for this type: a second push of the same id is
  idempotent; a delete is a final tombstone (ADR-013 #9). Completed attempts never
  conflict, like `review_log` (ADR-013 #7).
- An in-progress attempt is never pushed and is bound to its device, like a study
  session (ADR-013 #10).
- The server checks integrity only (ADR-015): `status = completed`,
  `score = Σ points_earned ≤ max_score`, counts consistent with the answers,
  indices in range, question numbers unique. Scoring stays in the app.
- Supabase: one migration adds the table, the four dispatch functions' new branch
  and the pgTAP pin of the entity set.

### 7.3 Account switch

Both tables join `LocalDataReset`. After a switch or sign-out the new account's
completed attempts arrive by pull. An in-progress attempt is lost on switch or
sign-out, as an in-progress study session is.

## 8. Screens and navigation

| # | Screen | Route | Navigator | MVP content |
|---|---|---|---|---|
| 13 | Study home (exists) | `/study` | Study branch | One new region: the TOPIK entry card. |
| 34 | TOPIK home | `/study/topik` | Study branch | Practice: TOPIK I and TOPIK II cards, each with its number of valid tests. Level drills and Simulated exams are absent until they exist. |
| 35 | Test list | `/study/topik/:level` | Study branch | Section switch (Reading, Listening), header card, sort, one row per test with its status. |
| 36 | Test detail | `/study/topik/test/:testId` | Study branch | Overview (Overall Progress, Recent Attempts) and History; FAB starts or continues. |
| 37 | Attempt | `/study/topik/attempt/:attemptId` | Root | One question per page with its group's material, progress, navigator grid, audio player, submit. |
| 38 | Summary | `/study/topik/attempt/:attemptId/summary` | Root | §6.4. |
| 39 | Review | `/study/topik/attempt/:attemptId/review` (`?q=`) | Root | One question per page: options marked chosen and correct, explanation, translation, words, grammars, script with group audio; status filter; previous and next. |

Main states per screen (each detail file holds the full States and Transitions
tables, written with the design mapping, deliverable 5):

- 34, 35: loading; loaded; no valid test for the level or section (neutral empty);
  read error with Retry. Rejected content is absent, not an error.
- 36: no attempts (empty, Start); with attempts; test missing or invalid (deep
  link; empty with a way back); delete confirmation; Continue or Start new.
- 37: loading; answering; audio error; submit confirmation; submitting (a second
  tap and Back do nothing); attempt missing (deleted elsewhere, account switched);
  content missing on Continue (offer delete).
- 38: loaded; filter with no rows; attempt missing.
- 39: loaded; content updated since the attempt (banner); content missing (Review
  unavailable; Summary still works); question not in the current filter.
- All: a language change relabels the UI without losing data; Korean content is
  never localized.

Every user-visible string goes through the ARB files (`topik*` keys, English first,
Vietnamese with the screen). No advertising.

## 9. Edge cases (brief §9) → where they are pinned

| # | Edge case | Rule |
|---|---|---|
| 1 | Submit with unanswered questions | BR-TOPIK-014 |
| 2 | Leave mid-attempt, reopen | BR-TOPIK-010, BR-TOPIK-012, BR-TOPIK-015 |
| 3 | Listening test without its audio file | BR-TOPIK-008, BR-TOPIK-017 |
| 4 | Content total ≠ 100 | BR-TOPIK-002, BR-TOPIK-008 |
| 5 | TOPIK I reading starts at 31 | BR-TOPIK-001, BR-TOPIK-023 |
| 6 | 100/100 and 0/100 | BR-TOPIK-023 (goldens) |
| 7 | Duration over an hour | BR-TOPIK-025 |
| 8 | Delete an in-progress attempt | BR-TOPIK-018 |
| 9 | Return to a question and change the answer | BR-TOPIK-012, BR-TOPIK-015 |
| 10 | Two questions on one audio | BR-TOPIK-017 |
| 11 | No network | ADR-013; everything reads and writes Drift |
| 12 | Language changed mid-attempt | UC-TOPIK-003 A-flows |

## 10. Scope

**MVP (Phase A):** entry on screen 13; screens 34–39; Practice mode; scoring;
Overall Progress, Recent Attempts, History with delete; Summary with the question
type breakdown; Review; sync of completed attempts; the round-96 pack for TOPIK I
and II, 듣기 and 읽기, once the owner supplies the files.

**Phase B:** Score Trend's Improving / Declining label (the line of scores shipped on 2026-10-19, follow-ups spec G8), Needs Review, Bookmarks, Notes, Words with "Create deck
from this test" (through `DeckRepository` and `CardRepository.insertCards`, as
`addStarterDeck` does), Exam mode, estimated grade, more rounds, downloadable
packs (own spec).

**Phase C:** Level drills by question type and level, Writing (D10), IBT if NIIED
publishes papers.

**Never:** advertising; changes to existing features' behaviour; content without a
published NIIED source.

## 11. Verification

- Domain unit tests: validator (one case per rule), scoring, time accrual,
  statistics (each formula, each "no data" case), duration formatter.
- Data: in-memory Drift repository tests; migration v16 → v17; `LocalDataReset`;
  the sync adapter's payload; pgTAP for the server's integrity checks.
- Presentation: controller tests for every transition of §5.1; widget tests and
  goldens (light and dark, 360 dp) for every state of §8.
- IT scenarios in `docs/features/topik/it-scenarios.md`.
- The gate (`dod_check.sh`), goldens, `npx supabase test db`.
- Final check (deliverable 8): a simulated attempt with known answers scored
  against the official round-96 정답·배점표.

## 12. Risks

| Risk | Handling |
|---|---|
| The brief's playCount and per-question-point rules are not verified against an official paper | The lint enforces them; a mismatch on round 96 is reported to the owner and fixed in the spec and BR first (§4.2). |
| Round 96 files not supplied | MVP code and tests run on the synthetic fixture; the content pack is its own PR. |
| APK size | One round re-encoded to mono at a low bitrate for the MVP; downloadable packs in Phase B. |
| Goldens and Hangul | `flutter_test_config.dart` loads Noto Sans KR, but older golden tests avoid Hangul. Probed before the first TOPIK golden; the result is recorded in the plan. |
| Copyright | NIIED publishes the papers for study; MemoX is a personal app (`PRODUCT.md`). Recorded in ADR-023. |
| New dependency for audio | Proposed with its reasons in the engineering design (deliverable 4) and approved by the owner before it enters `pubspec.yaml`. |

## 13. Engineering design (deliverable 4, owner approval 2026-10-15)

### 13.1 Local schema v16 → v17

Tables are singular, like `card`, `deck` and `review_log`, and like the sync entity type
(this replaces the plural names of the first draft of §7.1).

- `topik_attempt`: `id TEXT PRIMARY KEY` (UUID v7), `test_id`, `level`, `section`, `round`,
  `mode` (`CHECK IN ('practice')`), `status` (`CHECK IN ('in_progress', 'completed')`),
  `started_at`, `completed_at`, `updated_at` (`DATETIME`, UTC), `total_time_ms`,
  `current_question_no`, `question_count`, `max_score`, snapshot `score`, `correct_count`,
  `answered_count` (null exactly while `in_progress`, by `CHECK`), `content_version`,
  `server_version INTEGER NULL`. Index `idx_topik_attempt_test_started (test_id, started_at)`.
- `topik_attempt_answer`: primary key (`attempt_id` → `topik_attempt` `ON DELETE CASCADE`,
  `question_no`), `selected_idx` (`CHECK` 1–4 or null), `time_spent_ms`, `answered_at`,
  snapshot `correct_idx`, `points`, `points_earned`, `question_type`.
- Start inserts the attempt and one answer row per question (`selected_idx` null, time 0) in
  one transaction; answering and time are updates only.
- Immutability is enforced in the database, as `review_log_append_only` does: a
  `BEFORE UPDATE` trigger on `topik_attempt` aborts when the old row is `completed` and any
  column other than `server_version` changes; a `BEFORE UPDATE` trigger on
  `topik_attempt_answer` aborts when its attempt is `completed`.
- Migration `from16To17`: `m.createTable` and `m.createTrigger` only; no outbox seed (the
  tables are new). Snapshot `drift_schemas/drift_schema_v17.json`, `schema_versions.dart`, and
  `test/drift/migration_test.dart` targets move to 17.
- Rollback: drop both tables and their triggers; `DELETE FROM sync_outbox WHERE entity_type =
  'topik_attempt'`.
- `LocalDataReset` deletes `topik_attempt` (answers cascade) and lists both tables in
  `markTablesUpdated`; `local_data_reset_test` seeds and checks them.

### 13.2 Sync, client

- `lib/features/topik/data/datasources/topik_attempt_sync_dao.dart`, `TopikAttemptSyncDao`,
  registered last in `appSyncAdaptersOf`; queries in `queries/sync_topik_attempt_queries.drift`.
- Triggers, each with the `applying_remote` guard: an update from `in_progress` to
  `completed` enqueues an `upsert`; a delete `WHEN old.status = 'completed'` enqueues a
  `delete`. No insert trigger (a local insert is always `in_progress`) and no trigger on
  answers, so an in-progress attempt never reaches the outbox — the coordinator would push a
  `readRow == null` entry as a delete.
- `readRow`: the attempt in camelCase plus `answers: [...]`; times without fractions, as the
  other adapters write them. `upsertFromServer`: `INSERT OR IGNORE` the attempt, then the
  answers only when the attempt was new. `deleteFromServer`: a plain delete, a no-op for an
  unknown id. `markAcknowledged`: `server_version` only.
- `SyncStore.markAllPending` gains `seedTopikAttemptOutbox … WHERE status = 'completed'`.
- Registering the type changes `pull_entity_types`, so every existing install re-pulls from
  zero once (accepted by the owner).

### 13.3 Sync, server

- Migration `supabase/migrations/20261016000000_topik_attempt_sync.sql`: `public.topik_attempt`
  (`user_id` → `auth.users` `ON DELETE CASCADE`, `server_version` unique per user, `deleted_at`,
  `last_device_id`, checks mirroring Drift) and `public.topik_attempt_answer` (child, no
  version, `ON DELETE CASCADE`, as `card_tags`); RLS on, no policy, no client privilege.
- `private.topik_attempt_upsert`: insert-only; the same id of the same user is idempotent,
  another user's id raises `SYNC_ENTITY_CONFLICT`, an upsert onto a tombstone is refused
  (`ENTITY_TOMBSTONED`). Integrity (BR-TOPIK-028) over `jsonb_array_elements(r->'answers')`,
  raising `VALIDATION_FAILED`. `topik_attempt_delete`: a final tombstone as `tag_delete`, the
  answers deleted physically. `topik_attempt_change` for pulls.
- The four dispatch functions are rewritten in full with the literal forms
  `supabase/tests/database/15_sync_entity_dispatch.sql` parses; `merge_user_data` moves the
  new tables; pgTAP `01`, `12` and `15` are updated and `17_topik_attempt_sync.sql` added
  (idempotency, tombstone, each integrity check, the previous wire still applied).
- The server-sync spec's contract-key and conflict tables gain the type ("append-only with a
  final tombstone").

### 13.4 Content loading

- `data/datasources/topik_content_asset_data_source.dart` reads `assets/topik/manifest.json`
  and each pack through `AssetBundle`, then runs `topikTestOf(json, origin: path)`,
  `checkTopikTest` through the shared pipeline `topikContentOf`
  (`data/mappers/topik_content_pack_mapper.dart`, asset existence from the `AssetManifest`).
  Among duplicate ids the first valid one wins; the lint runs the same pipeline. A rejected test is logged `topik.content_rejected`
  with its id and first error rule, and left out.
- `pubspec.yaml` lists every pack folder (asset folders are not recursive); a gate test checks
  that each folder holding a manifest entry or a referenced asset is declared.
- `topikContentRepositoryProvider` is `keepAlive` and its implementation reads the packs once (a failed read is retried on the next call) (owner approval 2026-10-15): the content never changes
  while the app runs, and Phase B's packs would be re-parsed on every screen otherwise.

### 13.5 Domain, use cases, repositories

- Contracts `TopikContentRepository` (`catalog()`) and `TopikAttemptRepository` (reads
  `watchAttemptsOfTest`, `watchAttempt`, `watchTestStatuses`; writes `start` →
  `Outcome<…, TopikRejection>` with `inProgressExists`, `replaceInProgressAndStart`, `answer`,
  `move`, `recordTime`, `submit`, `delete`, each in `mappedTransaction`).
- Pure functions: `scoreTopikAttempt(test, answers)` (§5.3) and the statistics of §6.
- One use case per interaction (§3.3), `DayClock` for the time.

### 13.6 Presentation state

- `topikAttemptControllerProvider(attemptId)`: `@riverpod`, auto-dispose family. It holds the
  attempt, the test, the current question and `currentSince`. Time comes from events, not a
  ticking timer: on an answer, a move, a background transition or leaving, `clock.now() −
  currentSince` is added to the current question and written. The screen's
  `AppLifecycleListener` calls `pause()` and `resume()`. Double submit is guarded and every
  write after an `await` checks `ref.mounted`.
- Screens 34–36, 38 and 39 read stream providers, as `progress` does.

### 13.7 Navigation

`AppRoutes`: `topik = '/study/topik'`, `topikLevel(level)`, `topikTest(testId)` in the Study
branch; `topikAttempt(id)`, its `summary` and `review` (`?q=`) on the root navigator. Study
home gains one optional slot, `Widget? practiceEntry`, which `lib/app/` fills with the topik
feature's entry card, so `study` never imports `topik` (as `reauthNotice`). Its place on the
screen is decided in the design mapping.

### 13.8 Audio

- Dependency `just_audio ^0.10.6` (owner approval 2026-10-15): `ClippingAudioSource` plays
  exactly `[startMs, endMs)` natively, plus `setSpeed`, seek and asset playback; Flutter
  ≥ 3.27; its dependencies fit `uuid ^4`. Rejected: `audioplayers` 6.8.1, which has no
  clipping.
- Inside the topik feature (owner approval 2026-10-15): an interface in `domain/` (file name
  per the guard's suffix rule), one door file in `data/datasources/` that alone imports
  `just_audio` (a guard rule `audio_plugin_has_one_door`, as for `flutter_tts`), its provider
  in `di/`, and a fake for tests. It moves to `lib/core/` when a second feature needs audio.
- The seek bar is a new shared `MxSlider` (owner 2026-10-15, after PR #283): the guard bans a
  raw `Slider` in feature code. It is built through the `material3-shared-widgets` BUILD
  workflow and the flutter-theme-design admission rule: `sliderTheme` in `lib/core/theme`,
  active track `primary`, inactive track `surfaceContainerHighest` set explicitly (the M3
  spec leaves it `D=Check`; this matches `MxLinearProgress`), a ledger row in
  `docs/shared/design/m3-adoption-ledger.md`, tests for every state and light and dark goldens.
- Built (plan 5): `TopikAudioRepository` and `topik_audio_model.dart` (domain);
  `TopikAudioPlayerDataSource` with its door `PluginTopikAudioPlayerDataSource` and
  `TopikAudioRepositoryImpl` (data); `topikAudioRepositoryProvider` (di); the guard rule is
  `memox_v8.architecture.topik_audio_plugin_has_one_door`. A playback failure, at load or
  later (just_audio 0.10 reports the later ones only on `errorStream`), is the `failed`
  state with one `topik.audio_failed` warning; a load overtaken by another group, or still
  pending when the player goes, changes nothing and logs nothing. Another group pauses the
  previous one (the plugin keeps playing across a new source); stop returns to the start;
  a clip that ends is paused, so a drag does not restart it. The door's provider owns the
  door. Tests run the real `AudioPlayer` over its channels
  (`test/support/fake_just_audio_platform.dart`); copying a bundled asset to the cache
  file and audio focus stay UNVERIFIED (device). `MxSlider` with `sliderTheme`.

### 13.9 Phase 2 plans

1. Content loading, `pubspec` folders, catalog.
2. Drift v17, attempt repository, `LocalDataReset`.
3. Sync adapter, Supabase migration, pgTAP.
4. Scoring, statistics, use cases, the shared duration formatter.
5. Audio player and the shared `MxSlider`.
6. Screens 13 (entry), 34, 35, 36, 37, 38, 39, each through CLAUDE.md's screen workflow.
7. The round-96 pack, once the files arrive.

### 13.10 Material 3 conformance (PR #283, merged 2026-10-15)

- Shared widgets this feature adds or promotes (`MxChoiceTile` from `StudyChoiceWidget`,
  `MxSlider`) go through the `material3-shared-widgets` BUILD workflow: its twelve steps, a
  ledger row, `tools/m3_lint` clean, every state tested, goldens in light and dark at 360 dp,
  and the golden review. The study goldens must not change when `MxChoiceTile` moves.
- The topik widgets (`TopikTwoPaneLayout`, `TopikAudioBar`, `TopikQuestionGrid`,
  `TopikQuestionBarChart`, `TopikScoreDonut`) use no raw Material component and no bare
  `Icon` or `InkWell`: a tappable cell or bar is an `MxRowInk`, a glyph an `MxIconButton` or
  `MxIconTile`. Each publishes the semantics of what it replaces (button, selected, position,
  tooltip) and a test asserts them (pitfall 19).
- Bodies and bars at the screen edge read `context.screenMargin`; filter counts use
  `MxFilterChip`'s count slot.
