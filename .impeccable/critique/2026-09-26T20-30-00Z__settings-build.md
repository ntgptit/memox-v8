---
target: built screens 23 Settings, 25 Theme, 26 Language (post-build audit)
target_identity: "dir:test/features/settings/presentation/goldens"
timestamp: 2026-09-26T20-30-00Z
slug: settings-build
p0_count: 0
p1_count: 1
---
Method: one batched pass. The 30 settings goldens (light and dark, every kit state of 23, 25 and 26) were read beside the kit captures in `docs/shared/ui/screen-handoff/img/{23-settings,25-theme,26-language}/` and the detail files. Throwaway captures of the three screens at text scale 2 in Vietnamese (360 dp, light and dark) were added for the hardest case. The visual audits (`test/visual_audit/screens/features/settings/`) already enforce 48 dp targets, labelled targets and no overflow at 1x and 2x.

## Findings

- **[P1] Screen 25 at large text broke words inside themselves.** At 2x in Vietnamese the three side-by-side cards were about 100 dp wide, so "Hệ thống" wrapped as "Hệ thốn / g". The visual audit passed, because wrapping is not overflow.
  - *Fixed in this pass:* `ThemeChoiceCardWidget.minWidth` measures the longest word of each name (beside the check) and hint. When a third of the row is narrower, the cards stack one per line. At 1x they stay side by side and the goldens do not change.
  - *Tests:* "at large text in Vietnamese the cards stack, so no word breaks inside itself" (RED, then GREEN) and "at 1x the three cards sit side by side, as the kit draws them".
- **[P3, not a product defect] The + button keeps a focus tint in the saved and saveFailed goldens.** The test binding uses traditional focus highlighting after a tap. On a touch device the highlight mode is touch, and no tint shows.

## Checked and matching the kit (with the recorded deviations)

- **Screen 23:** all 8 states. The tray stacks at 2x in Vietnamese (row 123). The section tiles sit beside their labels (row 124). The reset footer pair follows row 118.
- **Screen 25:** system, light and dark. The title is "Theme" with plain descriptors (D7).
- **Screen 26:** english, vietnamese and system. D8 names what "Follow the system" resolves to. The radio rows read clearly at 2x.

## Score

Accessibility 4 · Performance 4 · Theming 4 · Conformance 4 · Adaptivity 3 (phone only, by ADR) = 19/20 after the fix.
