---
target: screens 16 and 21 post-build
total_score: 26
max_score: 36
na_heuristics: 7
p0_count: 0
p1_count: 1
target_identity: "file:/home/user/memox-v8/lib/features/study/presentation/screens/study_session_screen.dart"
target_fingerprint: "sha256:c2822316b1951b2315468c132333544f4918d5b450ba4dd9241f4fce3d051cc3"
target_path: /home/user/memox-v8/lib/features/study/presentation/screens/study_session_screen.dart
timestamp: 2026-09-26T08-35-40Z
slug: ntation-screens-study-session-screen-dart-f46074dd
---
Method: dual-agent (A: design review · B: detector evidence). The detector does not scan Dart (a control file with raw colours returned []), so B's signal is the repo guard (83 rules, 0 violations) and the study visual audits (4/4: tap targets, text scale 2, light/dark; contrast is not audited until FE-C1).

## Design Health Score (H7 n/a: P1c offers no start path)
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Facts icons do not echo the wrong-turns warning |
| 2 | Match system / real world | 4 | |
| 3 | User control and freedom | 3 | ✕ ends at once (owner ruling); look-back is a cheap undo |
| 4 | Consistency and standards | 2 | Facts icon tone never varies (the hero's does) |
| 5 | Error prevention | 3 | |
| 6 | Recognition rather than recall | 4 | |
| 7 | Flexibility and efficiency | n/a | |
| 8 | Aesthetic and minimalist design | 2 | Blank band under a short summary |
| 9 | Error recovery | 3 | saveError plain and honest |
| 10 | Help and documentation | 2 | Browse's hint is the only guidance |
| Total | | 26/36 | Good |

## Priority issues (verified against the kit)
1. [P1] Facts rows' glyph tiles stay tinted; the kit inks the finished glyph green and the wrong-turns glyph in the warning ink when wrong > 0 (ResultRow). Fix: tone success / caution on those tiles.
2. Declined — footer buttons of unequal height: the kit wraps "Study this deck" to two lines too, and both buttons are the same height in the goldens (checked).
3. Declined — the blank band under a short summary: the kit top-aligns too; the difference is the canvas ratio. A taste call, not a kit mismatch.

## Minor
- "Cards answered" uses the card-deck glyph where the kit draws "copy" (no copy glyph in AppIcons; the nearest).
- Already registered: muted app-bar title, 44 hero tile, wrapped wrong-turns line, no drag tilt, no monospace.
