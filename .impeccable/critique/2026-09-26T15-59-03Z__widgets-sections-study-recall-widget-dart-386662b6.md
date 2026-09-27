---
phase: after-build
plan: 2026-09-26-study-p4-recall-fill
score: 26/32
target_identity: "file:/home/user/memox-v8/lib/features/study/presentation/widgets/sections/study_recall_widget.dart"
target_fingerprint: "sha256:9f87b34a80f7d5664ebafb95e52249357e4b1fc05d3130d893895b50817c26e3"
target_path: /home/user/memox-v8/lib/features/study/presentation/widgets/sections/study_recall_widget.dart
timestamp: 2026-09-26T15-59-03Z
slug: widgets-sections-study-recall-widget-dart-386662b6
---
# Impeccable after the build — FE-A6 P4 (Recall 19, Fill 20)

A (design critique of the goldens against the kit): 26/32. B (native audit): 17/20; guard clean.

## Findings
1. P0 — "Remembered" clipped to "Remembere" in the two-up self-check row: MxButton's study size kept the kit's 36 hug padding when it was a block action given 160 by its row. Fixed: block study buttons pad by the gutter; test RED→GREEN; revealed goldens re-rendered.
2. P2 — the two-up CTA row's budget: covered by the same fix (the padding follows the block, not the label).
3. P3 — Fill's footer pencil glyph: kept (it marks typing, not editing the card).

## Confirmed
V1, V2, V4, V6, V7, V9, V10 as drawn in the goldens; the eight_box entry shows Recall and Fill as live rows.
