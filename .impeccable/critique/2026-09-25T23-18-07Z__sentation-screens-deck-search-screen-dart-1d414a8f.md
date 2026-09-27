---
target: screen 04 Library search (FE-A10)
total_score: 32
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 2
target_identity: "file:/home/user/memox-v8/lib/features/deck/presentation/screens/deck_search_screen.dart"
target_fingerprint: "sha256:87f2ed6734cfb338f57ab0c0fc3dc0c85f085fe49403a94da688e0153fb511e3"
target_path: /home/user/memox-v8/lib/features/deck/presentation/screens/deck_search_screen.dart
timestamp: 2026-09-25T23-18-07Z
slug: sentation-screens-deck-search-screen-dart-1d414a8f
---
Method: dual-agent (A: design review · B: detector + golden evidence)

# Critique — screen 04 Library search (FE-A10), before the plan

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Kit loading draws two skeleton groups; spec D14 says one |
| 2 | Match system / real world | 4 | Hint card uses the learner's own content examples |
| 3 | User control and freedom | 3 | Clear, Back, Retry present; no decks/cards filter (row 74, accepted) |
| 4 | Consistency and standards | 2 | Tile tone and card sub-line (subtitle vs meta) unruled, rows would diverge |
| 5 | Error prevention | 4 | E1/E2 split correct |
| 6 | Recognition rather than recall | 4 | SEARCH FINDS teaches the fields before typing |
| 7 | Flexibility and efficiency | 2 | No history, no field filter (out of scope) |
| 8 | Aesthetic and minimalist | 3 | One-line "front · back" can clip the match on long content |
| 9 | Error recovery | 4 | Reassurance-first copy |
| 10 | Help and documentation | 3 | Hint card is enough |
| **Total** | | **32/40** | Good |

## Design specificity
Flow and copy are specific (D1–D18, kit copy exact for 4 of 5 states). Two gaps would cause bugs or drift: how the "front · back" match is computed, and tile colour vs the semantic-colour contract.
Detector: exit 0, no findings on the three Dart files — the detector has no Dart rules; coverage gap, not a pass. Golden vs kit: unrecorded differences — no glyph before "SEARCH FINDS"; loading rows not in a card and no group-header bar; noResults uses plain search glyph, kit uses search-off. False positives checked: the "light band" in dark goldens is not visible; the uniform deck tile is the fixture (both decks hold sub-decks).

## Priority issues
- [P0] Kit colours tiles by content type (green card, orange tag). Green is mastery-only (`mx_semantic_colors.dart:9`), amber is warning. Fix: every tile tinted primary; decks vs cards differ by glyph and group label. Record deviation.
- [P1] D12 matches over the assembled "front · back" string: a highlight can span the separator, and a tag-only hit may highlight by accident. Fix: match front and back separately, map the range into the title; none → no highlight.
- [P1] One-line title (MxListRow invariant) can clip a match on the back face. Fix: accept trailing ellipsis, record deviation; the tag/back reason stays in the semantics label.
- [P2] MxListRow forbids subtitle+meta; tag rows vs plain rows would differ. Fix: card sub-line always through `meta` with the rowSubtitle role.
- [P3] Copy: accent note lacks the second sentence; noResults body needs all four fields; "+" count needs a new key; EN+VI.

## Persona red flags
- Exam crammer: clipped back-face match hides why a card surfaced; inconsistent sub-lines slow scanning.
- Screen-reader user: a tag-only hit has no spoken reason (MxTagChip is a bare label); "DECKS" and its count badge are two unmerged nodes (pre-existing, shared widget).

## Minor
- Library root trigger (`deck_library_root_widget.dart:88`) shares the hint; add it and its golden to the plan.
- Load-more-failed has no kit image: extrapolate from MxInlineBanner(danger), record as extrapolated.
- noResults glyph: use `AppIcons.searchOff` (exists) as the kit does.
- Loading: two groups, each a header bar and rows inside a card, as the kit.
- "SEARCH FINDS" glyph: MxListSectionHeader has no glyph slot; covered by the existing group-label deviation, extend its wording.
