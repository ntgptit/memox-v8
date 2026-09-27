---
target: "FE-A6 P2 after build: 16a Self-assess and screen 14 actions"
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/home/user/memox-v8/lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart"
target_fingerprint: "sha256:d54956cb65d8fab8c8a4bdd32d4ddb6c04fee6b4542239d62b095ff714c5a6f1"
target_path: /home/user/memox-v8/lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart
timestamp: 2026-09-26T11-45-32Z
slug: ts-sections-study-self-assess-widget-dart-4b3d8271
---
Method: dual-agent (A: design review, opus · B: detector + guard + golden visual audit, sonnet)

# Critique — FE-A6 P2 after build: 16a Self-assess and screen 14's actions

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Starting/refused/failed well signalled; top-bar progress track shrinks to a sliver at 2x text (shared MxStudyTopBar, P1c) |
| 2 | Match system / real world | 3 | Plain grading and refusal copy |
| 3 | User control and freedom | 4 | Dismissed sheet writes nothing; Continue vs new review explicit |
| 4 | Consistency and standards | 3 | dangerSoft tone and MxButton.detail sit in the system |
| 5 | Error prevention | 4 | Grade row and starts drop a second tap |
| 6 | Recognition rather than recall | 4 | Grades always named, with the interval |
| 7 | Flexibility and efficiency | 2 | Tap-to-reveal only |
| 8 | Aesthetic and minimalist design | 2 | Large empty regions (entry after the direction rows moved to a sheet; equal face halves) |
| 9 | Error recovery | 4 | Four specific refusal titles, one next action |
| 10 | Help and documentation | 2 | Sheet note carries the one non-obvious decision |
| **Total** | | **31/40** | Good |

## Deterministic scan
Detector: null signal (engine scans HTML/CSS markup, not Dart; confirmed with positive/negative controls). Guard: 83 rules, clean. Golden vs kit (screen 14): every difference matches a documented deviation; no overflow, clipping or truncation. 16a has no kit frame; structure matches the brief.

## Re-graded findings (synthesis)
- A: "ghost app bar through the footer button" (P1) — false positive: footer crops of study_entry_start_failed_light and study_entry_direction_sheet_light show clean buttons.
- A: "entry screen empty gap" (P1) — consequence of the approved direction-sheet deviation; the kit's onlyNew frame draws the same gap above its pinned footer. Recorded in the 14 deviation row. No change.
- A: "faces forced 50/50" (P2) — the kit's StudyFaceCard owns flex:1 growth for every face; built as the kit. Recorded in 16a. No change.
- A/B: top-bar progress track collapses at 2x text (P2) — real; shared MxStudyTopBar from P1c, outside P2's scope; needs the owner's call (ellipsize the mode chip, or wrap the counter row).
- B: AbsorbPointer semantics while busy — current Flutter keeps the nodes and blocks actions only; not a defect.
- B: named design constants (placeholder bar 140×14, study padding 36) — kit contract values; fine.

## What's working
Refusal/failure copy; the grade row's merged semantics ("Good, next in 6 days"); write discipline pinned by tests (reveal writes nothing, one turn per double tap, preview reuses the scheduler).
