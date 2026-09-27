---
name: flutter-workflow
description: Entry point and router for all development work on this Flutter app. Use this skill whenever work starts on MemoX V8 and the next step is not already obvious — "what's next", "let's build X", "continue the app", "add a feature", "is this done", "review before commit" — and whenever you need to know which of the other flutter-* skills applies. It maps each kind of work to the skill that covers it, enforces the dependency order between kinds of work, and holds the Definition of Done. Consult it before starting any non-trivial task so work does not begin on something whose prerequisites are still open.
---

# Flutter workflow router

This skill decides *what to work on next* and *which skill to load*. It does
not contain implementation detail — that lives in the specialised skills.

## First: find out where the project actually is

Do not trust memory or assumption about project state. Check:

```bash
sed -n '1,60p' docs/wbs_BE.md   # backend progress: done, remaining, order
sed -n '1,60p' docs/wbs_FE.md   # frontend progress: done, remaining, order
ls lib/features/                # which features exist
git log --oneline -10
```

`docs/wbs_BE.md` and `docs/wbs_FE.md` are authoritative for progress, and a
screen's row in the
[screen handoff index](../../../docs/shared/ui/screen-handoff/00-index.md) is
authoritative for that screen. If one is clearly stale relative to the code, say
so and fix it before building anything else — every later decision depends on it
being true.

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
| Dio, API contracts, repository shape, DTO/entity split, cache, sync, secure storage | `flutter-data-layer` |
| Anything under `lib/core/database/` or a `data/` folder — `.drift` schema and queries, indexes, migrations, DAOs, transactions, stream invalidation — and reviewing a database PR | `flutter-drift` |
| Building one feature end to end | `flutter-feature-slice` |
| Any kind of test | `flutter-testing` |
| Security, performance, logging, analytics, CI/CD, release, post-release | `flutter-ship` |

When a task spans several rows — which most real tasks do — `flutter-feature-slice`
is usually the right entry point; it pulls in the others in the right order.

**Before building a feature, read the two that went first.** Deck and Card are
the worked examples: `lib/features/deck/` and `lib/features/card/` are the
slices, and `flutter-feature-slice` states the method they follow. Take the
**method** from them — layering, where a rule is enforced, what a use case may
know, which test sits at which level — and not the business. Neither feature's
data shape is a template: a third feature that grows a tree or a
`content_type` because Deck has one has copied the wrong half.

## The order of work is a dependency graph, not a suggestion

The recommended order is:

```
business requirements → use cases + business rules → WBS → project foundation
→ architecture boundaries → theme & tokens → minimal shared components → router
→ database/network foundation → features as vertical slices → automated tests
→ pixel comparison → CI/CD → internal testing → production release → monitoring
```

The expensive mistakes this ordering prevents are specific, and worth naming so
you can recognise when someone is about to make one:

- **UI before business rules are settled.** The screens get built around an
  assumption, the rule lands differently, and the state model has to be redone.
  If the rules for a flow are still open, build something else.
- **Features before tokens and the router.** Every feature then hardcodes colours
  and navigation, and you pay to unpick it in every file.
- **Shared components before two real callers exist.** A component abstracted from
  one usage is a guess. Wait for the second caller — it tells you what actually
  varies. Two similar-looking widgets is not a reason to merge them.
- **Tests deferred to "after the feature works".** They then get written against
  whatever the code happens to do, which is not the same as what it should do.

If asked to jump ahead, do not silently refuse and do not silently comply. Say
which prerequisite is open, what the concrete risk is, and offer the smallest
unblocking step. If the user confirms after hearing that, proceed — it is their
call, and a documented deliberate shortcut is fine. Note it in the WBS.

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

Update `docs/wbs_BE.md` or `docs/wbs_FE.md` in the same commit as the work it
describes, and a screen's row in the screen handoff index when the screen is
built. Mark items done only when they are done by the Definition of Done, not
when the code first runs. If something was descoped or deferred, write that down
with the reason — a future session reading "done" on a half-finished item will
build on sand.
