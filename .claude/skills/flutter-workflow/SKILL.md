---
name: flutter-workflow
description: Router for development work on MemoX V8 — which `flutter-*` skill applies to a task, where progress is recorded (`docs/wbs_BE.md`, `docs/wbs_FE.md`), and the Definition of Done. Use it when work starts and the owning skill is not obvious — "what's next", "let's build X", "add a feature", "is this done", "review before commit". Process (brainstorm, plan, execute, review) belongs to Superpowers, per CLAUDE.md.
---

# Flutter workflow router

This skill decides *which skill to load* and *where progress is recorded*. It
does not contain implementation detail — that lives in the specialised skills —
and it does not sequence work: brainstorming, plans, execution and review are
Superpowers', and UI judgement is Impeccable's (CLAUDE.md, "Layers and
authority").

## First: find out where the project actually is

Do not trust memory or assumption about project state. Check:

```bash
sed -n 1,40p docs/wbs_BE.md   # backend: domain, data, use cases
sed -n 1,40p docs/wbs_FE.md   # frontend: screens, theme, shared widgets
git log --oneline -10
```

The two WBS files are authoritative for progress: `wbs_BE.md` for `domain/`,
`data/` and use cases, `wbs_FE.md` for presentation. A screen's row in the
[screen handoff index](../../../docs/shared/ui/screen-handoff/00-index.md) is
authoritative for that screen. If one is clearly stale relative to the code,
say so and fix it before building anything else — every later decision
depends on it being true.

## Routing table

| You are doing | Load skill |
|---|---|
| Defining the product, users, MVP scope, use cases, business rules, WBS, docs | `flutter-product-spec` |
| Creating the Flutter project, dependencies, flavors, bootstrap, error model | `flutter-project-setup` |
| Folder structure, layer boundaries, lint config, naming, code conventions | `flutter-architecture` |
| Design tokens, theming, shared components, responsive, localization, a11y | `flutter-design-system` |
| A component theme in `lib/core/theme/`, an `Mx*` widget's API, admitting a new Material widget, theme ↔ widget parity | `flutter-theme-design` |
| Routes, guards, deep links, nested shells, back behaviour | `flutter-navigation` |
| Providers, controllers, UI state modelling, side effects | `flutter-state-riverpod` |
| Retrofit API clients on the shared Dio (ADR-012), repository shape, DTO/entity split, cache, sync, secure storage | `flutter-data-layer` |
| Anything under `lib/core/database/` or a `data/` folder — `.drift` schema and queries, indexes, migrations, DAOs, transactions, stream invalidation — and reviewing a database PR | `flutter-drift` |
| Building one feature end to end | `flutter-feature-slice` |
| Any kind of test | `flutter-testing` |
| Security, performance, logging, analytics, CI/CD, release, post-release | `flutter-ship` |

When a task spans several rows — which most real tasks do — `flutter-feature-slice`
is usually the right entry point; it pulls in the others in the right order.

**Before building a feature, read the two that already went the whole way.** Deck
and Card are the worked examples: `docs/features/deck/` and `docs/features/card/`
hold their use cases, rules and data, `lib/features/deck/` and
`lib/features/card/` their code. Take the **method** from them — layering, where
a rule is enforced, what a use case may know, which test sits at which level —
and not the business. Neither feature's data shape is a template: a third
feature that grows a tree or a `content_type` because Deck has one has copied
the wrong half.

## Definition of Done

Read `references/definition-of-done.md` before marking anything complete. The
mechanical half is automated:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

That runs the full mechanical gate — codegen freshness, format, analyze, tests, the architecture boundary check, the code-verification guard and the docs guard (see the script header for the exact list). It cannot
judge whether the acceptance criteria are met, whether the UI matches the design,
or whether the WBS entry is honest — that part is on you, and it is the half
that actually catches problems.

## Keeping the ledger honest

Update the WBS row (`docs/wbs_BE.md` or `docs/wbs_FE.md`) in the PR that does the
work it describes, and a screen's row in the screen handoff index when the
screen is built. Mark items `xong` only when they are done by the Definition of
Done, not when the code first runs. If something was descoped or deferred, write
that down with the reason — a future session reading "done" on a half-finished
item will build on sand.
