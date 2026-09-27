---
target: built screen 15 Study options, and its ways in on screens 01 and 14 (post-build audit)
target_identity: "dir:test/features/settings/presentation/goldens"
timestamp: 2026-09-27T03-00-00Z
slug: study-options-build
p0_count: 0
p1_count: 0
---
Method: one batched pass. The 14 screen 15 goldens (light and dark, every kit state) were read beside the kit captures in `docs/shared/ui/screen-handoff/img/15-study-options/` and `15-study-options.md`. The changed goldens of the ways in were read too: `library_deck_actions_*`, `library_coming_soon_*` and `study_entry_*` beside kit 14. The visual audit (`test/visual_audit/screens/features/settings/screens/study_options_screen_visual_audit_test.dart`) already enforces 48 dp targets, labelled targets and no overflow at 1x and 2x on a 360 dp phone.

## Findings

No P0 or P1. Nothing was fixed in this pass.

- **[P3, not a product defect] The toggle keeps a focus halo in the `save_failed` golden.** This is the plan 1 finding again: the test binding uses traditional focus highlighting after a tap, and a touch device shows none.

## Checked and matching the kit (with the recorded deviations)

- **override:** the breadcrumb ends at "Study options". The note names the root. The toggle is off, with "This deck", 50 and Random. Save is disabled until something changes (D9, plan C3), where the kit draws it enabled.
- **defaults:** the toggle is on and reads "Following Settings · 20 cards, created order". The options are dimmed under "App defaults (read-only here)".
- **invalid:** the message sits under the stepper and the row's sub-line stays (plan 1 C3). The caption says "Fix the limit to enable save."
- **saving:** the controls keep their look, as the kit draws them. The stepper and the button spin, and the button shows no "Saving…" text (C5, C8).
- **saved / saveFailed:** the toast reads "Saved · applies to the next session". A failure shows Retry save, and the caption names what the deck still uses (E4).
- **loading:** `MxSkeletonList` under the breadcrumb, not the kit's in-place skeleton (plan 1 C7).
- **Kit 01 sheet:** the Study options row sits below Rename, with the sliders icon and its sub-line. Coming soon no longer lists it.
- **Kit 14:** the sliders icon sits at the end of the app bar.
- The note's root name is plain, where the kit bolds it (C8, `MxNote` carries one string).

## Score

Accessibility 4 · Performance 4 · Theming 4 · Conformance 4 · Adaptivity 3 (phone only, by ADR) = 19/20.
