---
name: material3-shared-widgets
description: Material 3 conformance for this app's shared widgets and theme, against spec v2.6.1 and the project's approved decisions. Use when building or changing an Mx* shared widget, a component theme in lib/core/theme/, or a screen composition (BUILD); when auditing shared widgets, theme slots, tokens, component anatomy, states, accessibility or M3 conformance (AUDIT); when fixing a confirmed design-system violation or preventing its regression (FIX). Not for token values (tokens.json owns them) or per-component checklists (flutter-theme-design owns them).
---

# Material 3 shared widgets

This skill is the procedure for keeping the shared widgets and the theme
conformant with Material 3 as the project has approved it. The spec is an
input, not an authority: it binds the project only where the ledger says
`ADOPT`. Token values live in `design/tokens.json`; the per-component
checklist lives in `flutter-theme-design`. This skill restates neither.

## 1. Sources and precedence

The higher source wins. A fact in a lower source never changes a higher one.

| # | Source |
|---|---|
| 1 | Approved decisions: ADRs, `PRODUCT.md`, owner rulings, screen detail files |
| 2 | `design/tokens.json`, `design/app_tokens.json`, `DESIGN.md` and flutter-theme-design |
| 3 | Flutter SDK pinned in `.fvmrc`, with its source under `/root/.flutter-sdk/<version>/flutter/packages/flutter/lib/src/` |
| 4 | `docs/shared/design/m3-shared-widget-spec-v2.6.1.md` |
| 5 | Conventions |

The ledger `docs/shared/design/m3-adoption-ledger.md` records every
classification; read it before judging any rule. A `CONFLICT` or `BLOCKED`
row is never implemented, and no test or lint may assert a spec value it
rejects.

## 2. The 12 mandatory steps

Every BUILD, AUDIT and FIX walks all twelve, in order. `references/workflows.md`
says what each step means for each workflow.

1. Read specs and decisions.
2. Inspect code.
3. Ownership and call sites.
4. Pinned SDK behaviour.
5. Classify.
6. Design the correction.
7. Regression tests first.
8. The smallest shared-layer fix.
9. Targeted verification.
10. Check degrade and similar.
11. Broader gates.
12. Report evidence and blockers.

## 3. Router

| Workflow | Read |
|---|---|
| BUILD | `references/workflows.md#build`, the spec section for the component, flutter-theme-design's reference for it |
| AUDIT | `references/workflows.md#audit`, `references/flutter-m3-pitfalls.md`, the ledger |
| FIX | `references/workflows.md#fix`, `references/flutter-m3-pitfalls.md`, `superpowers:systematic-debugging` |
| Gates | `references/gates.md`, every time a check is claimed |

## 4. Definition of done

**BUILD**
- The component theme is in `lib/core/theme`.
- The widget is in `lib/shared/widgets`.
- Every state has a test.
- Goldens in light and dark.
- The ledger row is added.
- `tools/m3_lint` is clean.
- The dod gate passes.

**AUDIT**
- Every component has an inventory row.
- Every cell is backed by an executed test, a golden, or code read and marked as such.
- `UNVERIFIED` is never reported as `PASS`.

**FIX**
- The root cause is stated as a mechanism.
- A test fails first.
- The fix is at the lowest shared owner.
- Check degrade and check similar are written out.
- Goldens are reviewed.
- The ledger is updated.

## 5. Anti-patterns

- Treating a spec value as approved.
- A per-screen patch over a shared defect.
- A theme-field assertion as proof of rendered behaviour.
- Text search as proof of an AST rule.
- Adding a token silently.
- A golden update without review.
- 320 dp or 2.0x goldens (CONFLICT, ledger M3C-12).
- `Colors.black54` or any guessed scrim.
- An `.adaptive` constructor.
- A raw `AppBar` theme without `actionsIconTheme`.

## 6. Related skills

- `flutter-design-system`: the principles (tokens, l10n, a11y).
- `flutter-theme-design`: the per-component checklist, theme slot and `Mx*` widget together.
- `golden-compare`: the owner's review page for any golden change.
- `flutter-testing`: test strategy, fakes, golden tolerances.
