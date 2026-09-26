---
target: "study flow P1: screens 14, 16, 21"
total_score: 35
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 3
target_identity: "file:/home/user/memox-v8/docs/superpowers/specs/2026-09-26-study-ui-design.md"
target_fingerprint: "sha256:2263a7d25474a2311cc7d71b1da8ba00ef444bebf50bee6089927aa8f9e64fe2"
target_path: /home/user/memox-v8/docs/superpowers/specs/2026-09-26-study-ui-design.md
timestamp: 2026-09-26T05-57-08Z
slug: owers-specs-2026-09-26-study-ui-design-md-2e21b6c9
---
Method: dual-agent (A: design review · B: kit inventory + detector)

# Critique — study flow phase P1 (screens 14, 16, 21 + session shell), before the plan

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | No commit-in-flight indicator specified for the session shell beyond the feedback hold |
| 2 | Match system / real world | 4 | Plain, outcome-specific copy |
| 3 | User control and freedom | 3 | ✕/Back abandon with no confirm (owner ruling); recovery only via Continue |
| 4 | Consistency and standards | 3 | MxIconTile/MxCard lack the summary hero's ok/error tones |
| 5 | Error prevention | 4 | Single in-flight flag, refused/startFailed banners |
| 6 | Recognition rather than recall | 4 | Badges, counters, direction-lock note |
| 7 | Flexibility and efficiency | 3 | Single-mode auto-skip; nothing more |
| 8 | Aesthetic and minimalist | 4 | Calm hero, one quiet overdue line |
| 9 | Error recovery | 4 | saveError/startFailed/refused say what is kept and what next |
| 10 | Help and documentation | 3 | Captions suffice |
| **Total** | | **35/40** | Excellent |

Detector: exit 0, no findings (no Dart rules; not evidence).

## Priority issues
- [P0] Summary hero needs ok (green) and error (red) tones: MxIconTileTone has tinted/primary/warning; MxCard hero excludes warning; `success` is PRESERVE_ONLY, `errorFill` exists unwired.
- [P0] StudyEntry lacks an overdue count and the resume banner's kind/mode/progress (ResumableSession on Study Home has the shape); no deck name or path either (study may not import deck).
- [P1] No stat-tile widget: 14 (New/Due) and 21 (three stats) both draw it — a second caller exists.
- [P1] Accessibility sections missing for 14/16/21 (16a has one).
- [P1] Summary of a session left at turn 0 unspecified.
- [P2] Browse footer hint at queue edges; resume+direction kit frame vs the sheet deviation.
