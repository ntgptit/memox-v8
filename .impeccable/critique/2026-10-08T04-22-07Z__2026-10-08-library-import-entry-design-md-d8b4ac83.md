---
target: Import from the Library (planned)
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/home/user/memox-v8/docs/superpowers/specs/2026-10-08-library-import-entry-design.md"
target_fingerprint: "sha256:f87164441b2b582d0efae43921ba53184df6e94bd6434556166e64c2e4b6053e"
target_path: /home/user/memox-v8/docs/superpowers/specs/2026-10-08-library-import-entry-design.md
timestamp: 2026-10-08T04-22-07Z
slug: 2026-10-08-library-import-entry-design-md-d8b4ac83
---
Method: dual-agent (A: design review · B: detector), Sonnet.

Target: planned "Import from the Library" (spec 2026-10-08 §4, §6), not built.

| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility | 3 | decks created silently before the wizard (D1) |
| 2 | Match | 3 | root/sub-deck model leaks; app vocabulary |
| 3 | Control | 2 | empty decks after cancel; sheet over dialog |
| 4 | Consistency | 3 | MxChipTrigger as a form field; icon hidden when empty |
| 5 | Error prevention | 2 | lock-in algorithm inside import; default root undefined |
| 6 | Recognition | 2 | Deck chip has no field label |
| 7 | Flexibility | 3 | two entries; existing target writes nothing |
| 8 | Minimalist | 2 | ~5 controls, ~520dp in New-deck mode |
| 9 | Recovery | 3 | reuses rejections and snackbar |
| 10 | Help | 2 | one subtitle must explain root/sub-deck |
| Total | | 25/40 | |

Detector: [] exit 0 on 5 Dart files (HTML-oriented detector; not proof of coverage). No browser target.

Priority issues
- P1 Deck MxChipTrigger used as a form field -> MxSettingsRow value row (title, value subtitle, chevron) opening MxDeckPickerSheet; same for Existing sub-deck.
- P1 Sub-deck name follows the deck name -> static prefill or empty required; no following.
- P2 App bar icon -> order Starter · Import · Tags · Trash; shown in empty and deck states.
- P2 Undefined defaults and TalkBack -> first root preselected; tray defaults Existing when eligible exists, single one preselected; "Sub-deck" label over tray "New · Existing"; body "Cards go into a sub-deck."; leaf in row, path in sheet and semantics; focus returns to row.
- P3 Empty-state body -> keep unchanged.
