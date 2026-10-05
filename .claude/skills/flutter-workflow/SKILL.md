---
name: flutter-workflow
description: Router for development work on MemoX V8 — which `flutter-*` skill applies to a task, where progress is recorded (the Linear project MemoX, ADR-021), and the Definition of Done. Use it when work starts and the owning skill is not obvious — "what's next", "let's build X", "add a feature", "is this done", "review before commit". Process (brainstorm, plan, execute, review) belongs to Superpowers, per CLAUDE.md.
---

# Flutter workflow router

This skill decides *which skill to load* and *where progress is recorded*. It
does not contain implementation detail — that lives in the specialised skills —
and it does not sequence work: brainstorming, plans, execution and review are
Superpowers', and UI judgement is Impeccable's (CLAUDE.md, "Layers and
authority").

## First: find out where the project actually is

Do not trust memory or assumption about project state. Check the Linear
project **MemoX** (team `DEV`) through the Linear connector — the open issues
(Todo, In Progress, Backlog) ordered by priority — and:

```bash
git log --oneline -10
```

Linear is authoritative for progress ([ADR-021](../../../docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md)).
It has two levels: an **epic** (a parent issue labelled `Epic`, one feature or
theme, inside a project milestone) and its **sub-issues** (the items). Each
sub-issue carries one label of the group `WBS`: `BE` for `domain/`, `data/` and
use cases, `FE` for presentation, `Supabase` for sync and login on Supabase
(`supabase/`, `lib/core/sync/`). The `docs/wbs_*.md` files are frozen history; never edit
them. A screen's row in the
[screen handoff index](../../../docs/shared/ui/screen-handoff/00-index.md) is
authoritative for that screen. If one is clearly stale relative to the code,
say so and fix it before building anything else — every later decision
depends on it being true. A session without the Linear connector says so to
the owner and records progress nowhere else.

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
or whether the Linear issue is honest — that part is on you, and it is the half
that actually catches problems.

## Keeping the ledger honest

The item's Linear issue is In Progress, then In Review, while the branch and PR
name its `DEV-n` (Linear's GitHub integration moves it), and Done once the PR is
merged into `master`, with the evidence (PR, commit, tests). A screen's row in
the screen handoff index is updated in that PR when the screen is built. Done
means done by the Definition of Done and merged, not that the code first runs.
If something was descoped or deferred, write that down on the issue with the
reason — a future session reading "done" on a half-finished item will build on
sand.

Keep the project small enough to read. New work is a sub-issue of an existing
epic, with its `WBS` label, a kind label and the epic's milestone, named by its
`DEV-n` only; its title, description and comments follow
[`references/linear-templates.md`](references/linear-templates.md).
Open a new epic only for a new feature or spec — one spec, one epic — and make
each task of its plan one sub-issue; never split a task further, and never nest
a sub-issue under a sub-issue. A small defect found along the way goes into the
issue in hand, or becomes a sub-issue of the nearest epic. An epic is Done when
every sub-issue is Done or Canceled.
