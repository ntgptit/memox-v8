---
target: MxStackedDayBars on Progress
total_score: 16
max_score: 28
na_heuristics: 3,5,9
p0_count: 0
p1_count: 2
target_identity: "file:/home/user/memox-v8/lib/shared/widgets/mx_stacked_day_bars.dart"
target_fingerprint: "sha256:b5e89aeabd0ae9c09b7cfef80f69c0de29ff2f11f37b95e0261abfc6a2d9fbdd"
target_path: /home/user/memox-v8/lib/shared/widgets/mx_stacked_day_bars.dart
timestamp: 2026-10-19T03-59-41Z
slug: lib-shared-widgets-mx-stacked-day-bars-dart
---
Method: dual-agent (A: design review · B: detector)

Score 16/28 (n/a: 3, 5, 9). Detector: 0 findings (likely no Dart rules); ui_lint clean.

P1 Numbers unreadable: no value per bar, no scale; heights relative to the fullest day only (mx_stacked_day_bars.dart:59,110). Fix: one faint guide at the max with a meta label; tap a bar for its three numbers.
P1 Fill contrast vs card (WCAG 1.4.11): learning #F59E0B on white 2.15:1 (owner exception 2026-10-10); reviewing #564BCB on dark card #171538 2.7:1 (not covered by the exception). Token finding, owner decides; rebuild adds a card-coloured gap between segments.
P2 Reviewing uses primary (One Accent Rule); token/theme ruling, not changed in rebuild.
P2 Slivers: a 1-card slice under an 80-card day is <1dp; each slice rounds its own corners. Fix: minimum visible segment, round only the stack's outer corners.
P3 isCurrent doc says bold, code uses colour; legend dots 6dp; no chart-level heading.
Personas: daily learner cannot compare days; TalkBack user hears seven bars, no overview.
