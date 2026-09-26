---
phase: before-plan
plan: 2026-09-26-study-p6-study-home
target_identity: "file:/home/user/memox-v8/docs/shared/ui/screen-handoff/13-study-home.md"
target_fingerprint: "sha256:caf47b85a76825a70b327ad4734db9dda914e4eb240f4798e51d0a45fd8d14f3"
target_path: /home/user/memox-v8/docs/shared/ui/screen-handoff/13-study-home.md
timestamp: 2026-09-26T17-01-14Z
slug: docs-shared-ui-screen-handoff-13-study-home-md
---
---
target: "P6 kit before plan: Study Home 13"
---

# Critique before plan — P6: Study Home 13

Dual pass: A (design critique of the kit states against handoff 13, UC-STUDY-002, BR-STUDY-008/068/074–077), B (codebase fit: read model, routes, shared widgets, guard, fixtures). No finding needs a backend change.

| Dimension | Score |
|---|---|
| Rule fidelity | 3 |
| Consistency with 14 | 2 |
| Accessibility readiness | 2 |
| Disabled state | 2 |
| i18n / plurals | 2 |
| Data availability | 4 |

## Findings → rulings

1. P0 — "Scheduled" has no widget slot or colour → S1: a fourth muted term; `scheduledCount` derived on the read model; hero only.
2. P0 — the caught-up body "tomorrow at 00:00" ignores `nextDueAt` → S2: tomorrow / on {date} / resting, against the local day.
3. P1 — the kit's pulse dot vs 14's static dot; no Accessibility section → S3: static and decorative on both; 13 gets an Accessibility section.
4. P1 — a deck with no card must be disabled, not merely untappable → S4: `isEnabled: false`.
5. P1 — hardcoded "cards due" → S5: ICU plurals.
6. P2 — at 2x the breakdown ellipsizes → S6: a 2x golden with the longest name must keep the first term.
7. P2 — the progress bar would double-announce → S7: no semantics of its own.
8. P3 — the refusal toast has no copy → S8.

## Facts (B)

- The Study branch is a placeholder in `app_router.dart`; no Study Home providers exist; `RoundProgress{completed,total}`.
- `MxWorkloadBreakdownLine` has three terms and a suffix; `MxCard.isHero` exists; `MxButton` has no soft-primary tone (`primary-soft` is PRESERVE_ONLY) → S9.
- `MxSkeleton` pulses forever unless Remove animations → S11: no `pumpAndSettle` on loading.
