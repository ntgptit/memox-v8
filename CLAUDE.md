# CLAUDE.md — MemoX V8

This file holds what must always hold. Procedures live in skills and in the
documents it points to; read those when the task reaches them.

## Layers and authority

Each layer answers one question; none takes over another's.

| Layer | Answers | Owns |
|---|---|---|
| Superpowers | What happens next, and is it done? | brainstorming, specs, architecture, plans, worktrees, TDD, debugging, implementation, code review, verification, branch completion |
| Impeccable | Is the UI right? | product definition, UX, UI design, design system, accessibility, adaptive/responsive behaviour, visual quality |
| Repo rules | What must always hold? | the guard (`memox-v8` ruleset), the ADRs, the `flutter-*` skills, `spring-boot-mybatis-review`, this file |
| ECC skills | What does good practice look like here? | reference knowledge only (see [docs/agent/vendored-ecc.md](docs/agent/vendored-ecc.md)) |

- **Superpowers is the sole process controller.** Nothing else plans,
  sequences or gates work, and no other layer repeats its methodology.
- **Impeccable judges UI against `DESIGN.md`, not against its own taste.**
  `DESIGN.md` is the design authority ([UI source of truth](#project-invariants)).
  Impeccable checks the work against it and against the quality floor.
- **Repo rules hold project invariants only**, such as the architecture,
  stack, data rules and quality bars. They never restate a workflow.
- **ECC skills are read on demand** by whoever does the task. They are never
  routed to as agents, and they never override a layer above.
- **An Impeccable fix ends with one `impeccable audit`** of what it changed,
  whichever command made the fix (`polish`, `layout`, `typeset`, `harden`, …).
  Skip it when an audit already ran on the current state. That audit is the
  one confirmation: if it finds something, fix it in one batch and report what
  it found to the owner; never run a further audit.

### A screen's workflow

1. Read the screen's detail file, its goldens and `DESIGN.md`.
2. Run `superpowers:brainstorming`: goal, scope, business rules (BR/UC),
   constraints.
3. Run Impeccable before the plan:
   - critique the design against `DESIGN.md` (what the plan must adopt or
     rule on);
   - use `shape` only for a screen or state not built yet.
4. Run `superpowers:writing-plans`, then execute it, subagent-driven or
   native, as the user chooses.
5. Run Impeccable after the build: critique and audit the goldens against
   `DESIGN.md`.
   - Fix everything found in one batch; that fix ends with its one
     `impeccable audit`, as above. Never loop on polish.
6. Run the final whole-branch review, then complete the branch. If goldens
   changed, the owner gets the [golden review](#the-gate) page first.

### Where knowledge lives

| Knowledge | Home |
|---|---|
| Architecture and product decisions | an ADR in `docs/shared/decisions/` (read its `status:`) |
| The visual system | `DESIGN.md` |
| A screen's layout, states, rulings and copy | its detail file in `docs/shared/ui/screen-handoff/` |
| Known UI debt | the UI-base register (§9 of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`) |
| Work progress | `docs/wbs_FE.md`, `docs/wbs_BE.md`, `docs/wbs_supabase.md` (`flutter-workflow`) |
| Plan-time rulings | the plan and its execution ledger, then the PR |
| The agent's working preferences and lessons | Claude Code auto-memory |
| Work in flight that moves to another session | a session handoff in `.claude/handoff/`, deleted before the merge ([docs/agent/session-handoff.md](docs/agent/session-handoff.md)) |

Do not add another store. Anything meant to outlive a session and bind the
project goes into the repo through a PR.

## The gate

- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` is the gate:
  format, analyze, generated code, architecture, docs, the guard and the full
  suite. Goldens run after it, in the Linux container only
  (`bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`, `--update`
  to rewrite them); on Windows run `flutter test --exclude-tags golden` and
  never `--update-goldens`.
- **Golden review:** when a branch adds, updates or deletes a
  `test/**/goldens/*.png`, the owner gets a before · after · diff page built
  with the `golden-compare` skill before any approve or merge. Changed images
  on their own are not a review.
- Hooks are repo-owned. [.claude/hooks/README.md](.claude/hooks/README.md)
  lists them and holds the subagent rules they enforce: every subagent on
  Sonnet except the final whole-branch review, which runs on Opus, and a
  `Workflow` whose token floor reaches 300k offered to the owner first. CI is paused and runs by hand; the local gate is what counts.

## Project invariants

- **Backend is Supabase** ([ADR-015](docs/shared/decisions/ADR-015-supabase-lam-backend.md)).
  Business rules and SRS live only in the app; the server checks integrity.
  Clients call only the RPCs listed in [supabase/README.md](supabase/README.md#rules);
  tables have RLS on, no policy and no client privilege. Its gate is
  `npx supabase db start` then `npx supabase test db`.
  `memox-api-services/` is frozen: a reference only, out of CI, not developed.
- **The app is the UI authority** ([ADR-019](docs/shared/decisions/ADR-019-app-la-chuan-ui.md)):
  `DESIGN.md` and the reviewed goldens. The "Mobile UI Kit v3" artifact is
  retired and never read. A BR or UC beats `DESIGN.md`; `DESIGN.md` and the
  goldens beat a screen's detail file. A PR that changes the visual system
  updates `DESIGN.md`; one that changes a screen updates its detail file and
  its row in the screen index.
- **Stack and layers:** the layer architecture and folder names follow
  [ADR-010](docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md);
  Riverpod and Drift, not BLoC or Freezed, whatever an ECC skill shows.
- **No speculative structure.** No layers or folders "for later", no
  pass-through layers, no single-implementation interfaces without a concrete
  architectural reason.

## Asking the owner

Every question to the owner goes through the `AskUserQuestion` popup, never as
plain chat text:

- clarifying questions and choices between options;
- approvals of a design, spec, plan or deviation;
- requests to act: starting a phase, running a command with side effects,
  installing a tool, adding or changing a dependency in `pubspec.yaml`,
  opening or merging a PR;
- reuse-or-write calls: adding or promoting code into `lib/core/` or
  `lib/shared/`, or taking a shortcut (reusing, skipping or trimming) in place
  of code the task asked for. Weigh the options and recommend one; the owner
  decides.

End a presented design, spec or plan with the popup (approve / request
changes), not with a question in prose.

## Language

Reply to the owner in Vietnamese. Code, identifiers, commit messages and PR
text keep their existing conventions. Messages printed by the scripts in
`tools/` are in English; strings that belong to a document format follow the
docs.
