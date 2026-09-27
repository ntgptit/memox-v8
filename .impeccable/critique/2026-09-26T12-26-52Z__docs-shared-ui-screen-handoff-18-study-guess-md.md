---
target: "P3 kit before plan: Guess 18, Match 17, entry picker"
total_score: 22
max_score: 36
na_heuristics: 10
p0_count: 1
p1_count: 3
target_identity: "file:/home/user/memox-v8/docs/shared/ui/screen-handoff/18-study-guess.md"
target_fingerprint: "sha256:d86b06b73b56464b5a9168cde0c51fd5e2567d29a54681737b60e01822ba4fd0"
target_path: /home/user/memox-v8/docs/shared/ui/screen-handoff/18-study-guess.md
timestamp: 2026-09-26T12-26-52Z
slug: docs-shared-ui-screen-handoff-18-study-guess-md
---
Method: dual-agent (A: design review, opus · B: detector + kit measurement + read model, sonnet)

# Critique before plan — P3: Guess 18, Match 17, entry mode picker

Score (A): 22/36 (heuristic 10 n/a). Detector: null signal (markdown/PNG and kit JSX inline styles are not scanned).

Rulings adopted into the P3 plan:
- Correct option and matched tile use the `success` semantic (D14), not the kit's `mastery` (P0).
- A blocked guess question's Close ends the session like ✕ (BR-STUDY-040: no skip, no advance) (P1).
- Guess and Match announce their outcome to TalkBack on commit; tiles and options carry state in their labels (P1).
- Guess options and the Match board scroll when they outgrow the viewport at large text; rows ≥ 48; 2x goldens (P1).
- The default review mode (first available) deviates from the kit frame's Recall pre-selection; recorded in 14 (P2).
- With TalkBack on (accessibleNavigation), Guess waits for a Next action instead of auto-advancing (P2).
- A wrong pair swaps the footer hint to a one-line explanation during its flash (P3).
- Match reads terms, then meanings; each tile names its side and state (P3).
Kit measurements (B): option rows 50 dp / radius 12 / badge 28; tiles 2 columns, gap 8, radius 12; option label 16/500 −0.1, tile term 18/700 −0.4, tile meaning 14/600.
