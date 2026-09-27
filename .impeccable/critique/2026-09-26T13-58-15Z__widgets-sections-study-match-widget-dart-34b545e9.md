---
phase: after-build
plan: 2026-09-26-study-p3-guess-match
score: 28/32
target_identity: "file:/home/user/memox-v8/lib/features/study/presentation/widgets/sections/study_match_widget.dart"
target_fingerprint: "sha256:c7b5d9eee471cb8b8024666be9a746fa78766f75fe3b444e7c8b650c4a0e91eb"
target_path: /home/user/memox-v8/lib/features/study/presentation/widgets/sections/study_match_widget.dart
timestamp: 2026-09-26T13-58-15Z
slug: widgets-sections-study-match-widget-dart-34b545e9
---
# Impeccable after the build — FE-A6 P3 (Guess 18, Match 17)

Dual pass: A (design critique of the goldens against the kit), B (detector, guard, golden audit).
Score A: 28/32. B: clean; the detector is a null signal on Dart; no undocumented difference from the kit.

## Findings, fixed in one batch (each RED→GREEN)

1. A wrong Match tile said nothing of its state during the flash → ", not a match" in its label (C3).
2. At 2x a long single word ("reservation") broke inside itself in the Guess prompt and the Match tiles → the text is drawn just small enough for its widest word to stay whole (paint-time scale; keeps intrinsic height for the scroll bodies).
3. At large text on a short phone the cut last row gave no cue → a decorative bottom fade while more is below.
4. Tones snapped → surface and ink ease together over the standard duration (at once under Remove animations). An AnimatedContainer would have inset content by the border and left white ink on a white surface mid-change; tween builders keep content in place (test).

## Confirmed

- Goldens re-rendered: guess/match large text (whole words, all five options now fit at 2x); the rest unchanged after the ease settles.
