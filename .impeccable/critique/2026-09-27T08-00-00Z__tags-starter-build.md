---
target: built screens 03 Starter decks, 05 Tags, 07's tag filter and 01's app bar and rootEmpty (post-build audit)
target_identity: "dir:test/features/{starter_decks,tags,card,deck}/presentation/goldens"
timestamp: 2026-09-27T08-00-00Z
slug: tags-starter-build
p0_count: 0
p1_count: 1
---
Method: one batched pass. The 46 goldens of screens 03 and 05 (light and dark: the 22 kit states and the Tags read error), the 10 of the tag filter sheet and the changed goldens of screens 01 and 07 were read beside the kit captures in `docs/shared/ui/screen-handoff/img/{01-deck-list,03-starter-decks,05-tags,07-card-list}/` and the detail files. Throwaway captures of 03 and 05 at text scale 2 in Vietnamese (360 dp) were added for the hardest case. The visual audits already enforce 48 dp targets, labelled targets and no overflow at 1x and 2x, in English and Vietnamese.

## Findings

- **[P1] At large text in Vietnamese the starter card's add lost a word.** "Thêm một bản nữa" is a small button, one line, so at 2x it read "Thêm một bản". The visual audit passed, because a clipped label is not an overflow.
  - *Fixed in this pass:* the card keeps the small button while its label fits one line (`MxButton.naturalWidth`), and takes the regular step, which wraps, when it would not. At 1x nothing changes and no golden changes.
  - *Test:* "at text scale 2 in Vietnamese an add keeps its whole label (post-build audit)" (RED without the fix, GREEN with it).
- **[P3, recorded] Tags in the store's folded order.** "động từ" sorts after the ASCII names (UI-base row 137; BR-TAG-003).

## Checked and matching the kit (with the recorded deviations)

- **03:** the note, the cards with "In library" following the title and the suggestion whole (row 135); the sheet, adding (spinner alone, row 136; held against Back, the scrim and a drag), added, already present, second copy, add failed, loading, none, load failed.
- **05:** the catalog with "A→Z" as text, the sheet, rename, merge (the union, the warning tone, row 134), name too long, delete (row 139), busy, op error and tag gone as one sentence (row 138), empty, search empty, loading, and the read error the kit lacks.
- **07:** the Tags chip selected with its count (row 140); the sheet as the shape brief draws it: none, one, several, applied, no card (A7).
- **01:** the app bar's sparkles, tag and trash; rootEmpty with "Browse starter decks".

## Score

Accessibility 4 · Performance 4 · Theming 4 · Conformance 4 · Adaptivity 3 (phone only, by ADR) = 19/20 after the fix.
