<!-- Hand-written screen record. -->

# 19 · Study · Recall

A round-based graded stage: `eight_box` only (BR-MODE-004). The term is
shown, the meaning hidden behind a 20-second turn clock; revealing is not an
outcome, only the self-check after it is (BR-STUDY-031, BR-STUDY-065).
FE-A6; UC-STUDY-001 (steps 6–9, A0c). Shared session chrome and rules (top
bar, exit, rounds, result-after-commit, keyboard, the icon-colour guard):
[16-study-browse.md § Shared by the session
screens](16-study-browse.md#shared-by-the-session-screens).

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Indigo, as every mode (3c-2 R8). |
| Context line | `SessionContextLine` | "{deck} · Review · round {n}"; a learning session adds its stage: "{deck} · Learning · stage {n} of {total} · round {n}" (`session_context_state.dart`). |
| Turn clock | new: `RecallCountdownBar` (feature-local; distinct from `MxStudyTopBar`'s session-wide track — this one measures the current turn, pauses in the background, and stops for good once revealed or timed out, BR-STUDY-031, BR-STUDY-036) | Caption + "{s}s / 20s", a fill `sizeTrack` tall (the same track as `MxStudyTopBar`'s, M3F-18) that drains to 0. |
| Term face | `StudyFaceCard` (label "Term") | The prompt; always visible, with the speaker ("Read aloud · {language}", disabled with "No {language} voice on this device" when the device lacks the voice) under the term (BR-STUDY-079; 16-study-browse.md, Speech). |
| Meaning face | `StudyFaceCard` (`role: answer`) | Blurred placeholder before reveal; the meaning once revealed or timed out, with a "Counted as forgot" tag when timed out. |
| CTA row | new: `StudyCtaRow` (feature-local) | `countingDown`: one "Show the meaning" button. `revealed`: "Forgot" and "Remembered", both secondary so neither grade is the loud one (critique 2026-09-30) — the only recorded input, at most once a turn (BR-STUDY-032, BR-STUDY-065). `timedOut`: one "Continue" button that only advances, records nothing (BR-STUDY-033, BR-STUDY-066). |
| Footer hint | `SessionFooterHint` | Varies by state; see Copy. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| countingDown | `study_recall_counting_light.png` | `study_recall_counting_dark.png` | — |
| revealed | `study_recall_revealed_light.png` | `study_recall_revealed_dark.png` | Clock is stopped, not zeroed (BR-STUDY-036). |
| timedOut | `study_recall_timed_out_light.png` | `study_recall_timed_out_dark.png` | The outcome is already committed (wrong) before this paints (BR-STUDY-063). |

**Built (FE-A6 P4):** `StudyRecallWidget` in the session route's mode switch, over
`RecallCountdownBarWidget` and `StudyCtaRowWidget`. The clock is the widget's own
(spec D12): it stops whenever the app leaves the foreground, saves the time left on
pause and when the turn's screen goes (never per tick), and a resumed turn starts from
the saved time, or opens revealed with its clock stopped (BR-STUDY-036). Show the
meaning stops the clock at once and writes the reveal; Forgot and Remembered answer
and the next card follows; at zero the turn answers timed out and is held until
Continue (spec D5). Goldens:
`test/features/study/presentation/goldens/study_recall_{counting,revealed,timed_out}_*`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| countingDown | the turn opens | the clock drains from 20 s (from the saved time on a resumed turn) | VERIFIED `study_recall_test.dart::the term shows, the meaning is hidden, and the clock counts down from 20 (19 countingDown)`, `::a turn resumed with saved time starts from it (BR-STUDY-036)` |
| countingDown | tap Show the meaning | the clock stops at once, the reveal is written, then revealed (nothing recorded) | VERIFIED `::Show the meaning reveals with the time left and stops the clock; Remembered moves on at once (R2, BR-STUDY-065)` |
| revealed | the reveal commits (TalkBack) | announced "The meaning is {meaning}.": Show the meaning held the focus and goes | VERIFIED `study_recall_test.dart::the reveal is announced: the focused button goes, the meaning is read (TalkBack)` |
| countingDown | a double tap on Show the meaning | revealed only; Forgot and Remembered take no tap for 400 ms | VERIFIED `::a double tap on Show the meaning answers nothing: Forgot and Remembered settle first (critique 2026-09-30 part 3c-2, R1)` |
| countingDown | the database refuses the reveal | the clock counts down again from where it stopped; the turn is as it was | `UNVERIFIED (code read)`: `didUpdateWidget` (`isRefused`) in `study_recall_widget.dart`; the controller leaves the turn as it was |
| revealed | tap Remembered / Forgot | the answer is written and the next card follows at once, no held frame | VERIFIED `::Show the meaning reveals with the time left and stops the clock; Remembered moves on at once (R2, BR-STUDY-065)`, `::Forgot records a wrong answer and moves on` |
| countingDown | the clock reaches 0 | timedOut: the turn is written as forgot, announced "Time is up. Counted as forgot. …", held until Continue | VERIFIED `::at zero the turn counts as forgot, is announced, and waits for Continue (R2, BR-STUDY-033, BR-STUDY-066)` |
| countingDown | a tap on Show the meaning in the instant the clock runs out | the timed-out turn is not skipped | VERIFIED `::a tap in the instant the clock runs out does not skip the timed-out turn (Review Focus 2)` |
| timedOut | tap Continue | the next card; nothing more is recorded (BR-STUDY-066) | VERIFIED in the zero test above |
| countingDown | the app goes to the background | the clock stops; the time left is saved on pause; it resumes where it stopped (BR-STUDY-036) | VERIFIED `::the clock stops in the background and saves its time; it resumes where it stopped (D12, BR-STUDY-036)` |
| countingDown | tap ✕ or system Back: the exit dialog opens | the clock stops while the dialog asks (`isPaused`) | VERIFIED `::the clock stops while the exit dialog asks, and Keep going takes it up where it stopped (BR-STUDY-036)` |
| countingDown (dialog open) | Keep going | the clock resumes where it stopped; the turn does not time out behind the dialog | VERIFIED the same test (15 s left before, 12 s after 3 s more) |
| countingDown | leave the screen mid-turn (✕ then Stop, Back) | the time left is saved when the widget goes | VERIFIED `::closing the screen mid-turn saves the time left (D12)` |
| session reopened | the turn had been revealed | revealed with its clock stopped; Forgot or Remembered | VERIFIED `::a turn resumed after a reveal opens revealed, its clock stopped, and asks Forgot or Remembered (BR-STUDY-036)` |
| revealed / timedOut | the answer write is refused by a busy database | the unsaved-answer banner with Retry; the buttons are disabled while a write runs | the banner path is VERIFIED from Browse (16); this screen's frame is `UNVERIFIED (code read)` |
| any | ✕, system Back, deck deleted, stale write | the route states of [16](16-study-browse.md#session-route-states) | see 16 |

## Rulings

- **BR-STUDY-032, BR-STUDY-033, BR-STUDY-066:** the ending has two branches: a self-check advances by itself, a timeout waits for Continue.
- **FE-A6 spec D14 (P4 ruling V2):** the clock's fill and caption are a neutral `muted-foreground` while counting down and `warning` once timed out (`recall_countdown_bar_widget.dart`); the top bar is Indigo (3c-2 R8).
- **M3 review 2026-09-28 F2:** the clock track is 4dp, the app's thin track.
- **P2 face-label fix:** the answer face carries its "Meaning" label in flow, as every study face.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** Forgot · Remembered and the timed-out Continue settle for 400 ms (R1); the bar is Indigo (R8).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is info, and repeat on "This card comes back in a later round" after a timeout (F7).

## Accessibility

- The clock is one node: its caption, with "{n} seconds left" as its value. It is never announced per tick (P4 rulings V3, V5).
- A timeout is announced when its write commits: "Time is up. Counted as forgot. The meaning is {meaning}."
- Show the meaning removes the focused button, so the reveal is announced too: "The meaning is {meaning}."
- Under Remove animations the clock's fill steps once a second and the meaning appears with no fade; the time runs the same (V9).
- At large text the faces scroll inside and the two self-check buttons stack (C4).
- **Open for the owner:** the 20-second turn (BR-STUDY-031) is the same for TalkBack users, who read the chrome before they can recall. Changing it is a business-rule decision, not a UI one (V3).

## Copy

- Context line: "{deck} · Review · round {n}" · "{deck} · Learning · stage {n} of {total} · round {n}".
- Clock caption: "Time to recall" (`countingDown`) · "Revealed with time left" (`revealed`) · "Time is up" (`timedOut`).
- Meaning tag: "Counted as forgot" (`timedOut`).
- CTAs: "Show the meaning" · "Forgot" · "Remembered" · "Continue".
- Footer hint: "Recall the meaning before time is up" (`countingDown`) · "The next card follows automatically" (`revealed`) · "This card comes back in a later round" (`timedOut`).
