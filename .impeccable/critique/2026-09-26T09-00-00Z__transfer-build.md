---
target: built screens 11 Card import and 12 Card export (post-build)
total_score: 34
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "dir:lib/features/transfer/presentation"
timestamp: 2026-09-26T09-00-00Z
slug: transfer-build
---
Method: single pass (goldens + throwaway captures of the uncovered states, compared with the kit captures in docs/shared/ui/screen-handoff/img/11-card-import and 12-card-export; native audit from source). No browser detector: Flutter.

## Design Health Score: 34/40

| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 4 | Tracker, Reading, Preparing, results all say what has and has not happened |
| 2 | Match system / real world | 3 | "Your file is read…" shown for pasted text |
| 3 | User control and freedom | 4 | Back steps back; Cancel/Back stop an export in progress |
| 4 | Consistency and standards | 4 | Mx components throughout; 20 dp alignment matches the kit |
| 5 | Error prevention | 3 | Read stayed enabled on a file that had just failed to read |
| 6 | Recognition vs recall | 4 | Source chip, header sample, row reasons |
| 7 | Flexibility and efficiency | 2 | No remembered mapping (critique 2026-09-26, deferred) |
| 8 | Aesthetic and minimalist | 4 | Step 1 collapses (K1); sheet is one screen |
| 9 | Error recovery | 3 | "Mapped for you" note shown when nothing was mapped |
| 10 | Help and documentation | 3 | Helper note on step 1; no example file |

## Priority issues (all fixed in the same batch)
- [P1] Accessibility verification gap: `test/support/library_harness.dart` applied the text scale to `home` only, so sheets and dialogs were never audited at 2x. Moved to `MaterialApp.builder`; the full suite and every golden still pass, and the export sheet audit now runs at 2x for real.
- [P2] Step 1 after a failed read: Read stayed enabled and re-read the same file. Now locked, with the kit's caption ("Nothing was read. Choose another file to continue."; pasted text: "Edit the text").
- [P2] Mapping: "Known header names were mapped for you" showed while nothing was mapped. Now shown only once the mapping is complete.
- [P3] Step 1 caption said "Your file" for pasted text. Now "Your text is read on this device only."

## Audit (native, from source): 17/20
Accessibility 4 · Performance 3 (preview capped at 50 rows; codecs off the UI isolate) · Theming 4 · Platform conformance 3 (Back behaves; share via system sheet) · Adaptivity 3 (phones only, by decision).

## Positive findings
- Every result and failure copy leads with "nothing was lost" (local-first voice).
- Status never by colour alone (K3); tap targets and 2x text pass on 360 dp.
- Export never claims where a file was saved (BR-TRANSFER-014).
