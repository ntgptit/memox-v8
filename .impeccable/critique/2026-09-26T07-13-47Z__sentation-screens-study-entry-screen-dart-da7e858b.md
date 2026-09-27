---
target: screen 14 Study Entry post-build
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/user/memox-v8/lib/features/study/presentation/screens/study_entry_screen.dart"
target_fingerprint: "sha256:454e6fbe650b15ae22d9e39a61d406d442c0792918272d096ff8b4d0fcfde926"
target_path: /home/user/memox-v8/lib/features/study/presentation/screens/study_entry_screen.dart
timestamp: 2026-09-26T07-13-47Z
slug: sentation-screens-study-entry-screen-dart-da7e858b
---
Method: dual-agent (A: design review · B: detector evidence). Detector does not scan Dart (control file with raw colours returned []), so B's signal is the repo guard (83 rules, 0 violations) and the screen-14 visual audit (2/2 pass: contrast, targets, text scale 2).

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 2 | Loading skeleton is a generic list, not the kit's hero + option-card shapes; `nothing` drops the hero so New 0 / Due 0 is never shown |
| 2 | Match system / real world | 3 | Overdue note lost the kit's warning ink |
| 3 | User control and freedom | 3 | Back works; nothing destructive |
| 4 | Consistency and standards | 1 | "Coming soon" review rows dimmed like "Not available" rows, while the Learn row stays full contrast; kit dims only unavailable rows |
| 5 | Error prevention | 3 | Unbuilt actions are not tappable |
| 6 | Recognition rather than recall | 3 | Reasons per row |
| 7 | Flexibility and efficiency | 2 | Single-mode skip works (SM-2) |
| 8 | Aesthetic and minimalist design | 2 | Cards match kit spacing; nothing/loading states miss kit content |
| 9 | Error recovery | 3 | MxErrorState + Retry |
| 10 | Help and documentation | 1 | Nothing explains Coming soon beyond the badge |
| Total | | 23/40 | Needs work |

## Priority issues (all kit mismatches, verified against the kit frames)
1. [P1] `nothing` drops the hero — kit keeps hero (0/0) above the empty state. Fix: render the hero before the empty state (study_entry_body_widget.dart).
2. [P1] Loading skeleton shape — kit: hero card (overline bar + block) and a card of three option-row skeletons (circle + two bars). Fix: a screen-shaped skeleton; handoff 14 already claims it.
3. [P1] Coming-soon review rows dimmed — kit draws runnable modes full contrast with their badge; only unavailable rows dim. Fix: MxOptionRow needs a non-dimmed, non-selectable state; dim only `unavailable`.
4. [P2] Overdue note in plain ink — kit uses warning ink. Fix: warningInk via a text-style role (no per-site restyle).
5. [P2] Stat emphasis — kit: Due > 0 primary, New > 0 muted, 0 plain (eightBox, onlyNew, sm2, nothing). V8 colours every non-zero figure primary.
6. [P3] Action sheet row says "Study"; kit says "Study this deck" (count subtitle already a registered deviation).
7. [P3] Handoff claims `onlyNew` built but no golden exists.

## Persona red flags
- First-timer: four rows that all look dead read as "broken", not "not built yet".
- Low vision: dimming is the only cue separating blocked from unbuilt; TalkBack reads both the same.

## Minor / declined
- Empty space under nothing/loading: the kit has the same; no change.
- An explanation of "Coming soon" beyond the badge: outside the kit; spec §3 rules the badge; no change.
- Earlier deviations on 01/07 (Delete vs Trash, no progress ring) predate P1b.
