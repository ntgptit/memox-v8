---
phase: before-plan
plan: 2026-09-26-study-p4-recall-fill
score: 23/36
target_identity: "file:/home/user/memox-v8/docs/shared/ui/screen-handoff/19-study-recall.md"
target_fingerprint: "sha256:1fef8937338dbb4b00ef33e93ac4584c07da010cf7b241102881cf57169b0c7a"
target_path: /home/user/memox-v8/docs/shared/ui/screen-handoff/19-study-recall.md
timestamp: 2026-09-26T14-13-13Z
slug: docs-shared-ui-screen-handoff-19-study-recall-md
---
---
target: "P4 kit before plan: Recall 19, Fill 20"
total_score: 23
max_score: 36
na_heuristics: 1
---

# Critique before plan — P4: Recall 19, Fill 20

Dual pass: A (design critique of the kit states against handoffs 19, 20, 16's shared section, BR-STUDY-026..036/059/063..066/069), B (codebase fit: backend contract, theme roles, shared widgets, guard, fixtures).

| # | Heuristic | Score |
|---|---|---|
| 1 | Visibility of system status | 3 |
| 2 | Match with the real world | 3 |
| 3 | User control and freedom | 2 |
| 4 | Consistency and standards | 2 |
| 5 | Error prevention | 2 |
| 6 | Recognition over recall | 3 |
| 7 | Flexibility and efficiency | 2 |
| 8 | Aesthetic and minimalist | 3 |
| 9 | Error recovery | 3 |
| 10 | Help and documentation | n/a |

## Findings (A) → plan rulings

1. P0 — Fill's wrong text uses `--memox-rating-again`, a token V8 lacks → the error ink, as Guess's wrong option (V1).
2. P1 — the turn clock drains in mastery green; D14 keeps green for mastery → neutral fill, warning only at timeout; the top bar keeps R3's mastery accent (V2).
3. P1 — a fixed 20 s clock weighs on TalkBack users; the BR fixes it → flagged to the owner, not changed; the clock never announces per tick (V3).
4. P1 — no empty-answer state is drawn → Check disabled while the trimmed answer is empty (F2, V4).
5. P2 — the progressbar semantics are web ARIA → one node: caption + seconds left as its value (V5).
6. P2 — keyboard with long meaning at 2x unspecified → the shell resizes above the keyboard; faces scroll inside (D19) (V6).
7. P2 — focus and IME Done → the field autofocuses; Done on an empty answer does nothing (V7).
8. P2 — a resumed turn with little time left → not adopted (the clock's value reads the seconds) (V8, ruled out).
9. P3 — Remove animations → the bar steps per second, faces swap at once (V9).
10. P3 — the kit's on-card tag says "this round" → "next round" (F3, V10).

## Facts (B)

- Backend: reveal/save clamp time downward and no-op once revealed; `showFillHint` rejects `noHint`; timedOut after reveal → `alreadyRevealed`; empty fold → `emptyAnswer`. `TurnResult` is `{isCorrect}` only. The stream re-emits the served item with `isRevealed`, `remainingMs`, `isHintShown`.
- No use-case providers for reveal/save/hint yet; no strike-through role; no `MxTextField` study variant; no lifecycle listener anywhere in lib/.
- `insertFiveDue` cards carry `example N` and `hint N`; `openFiveDueReview` opens any mode.
