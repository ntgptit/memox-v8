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
| ECC skills | What does good practice look like here? | reference knowledge only (see [docs/agent/vendored-ecc.md](docs/agent/vendored-ecc.md); `diagram-design`: [docs/agent/vendored-diagram-design.md](docs/agent/vendored-diagram-design.md)) |

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

1. Read the screen's detail file (its States and Transitions tables), its
   goldens and `DESIGN.md`.
2. Run `superpowers:brainstorming`: goal, scope, business rules (BR/UC),
   constraints.
3. Run Impeccable before the plan:
   - critique the design against `DESIGN.md` (what the plan must adopt or
     rule on);
   - use `shape` only for a screen or state not built yet.
4. Run `superpowers:writing-plans`, then execute it, subagent-driven or
   native, as the user chooses.
5. Run Impeccable after the build: critique and audit every state of the
   screen's States table against `DESIGN.md`, not only the ones with a golden.
   A state without a golden is rendered for the audit (a widget test or a
   throwaway golden) or reported `UNVERIFIED`.
   - Fix everything found in one batch; that fix ends with its one
     `impeccable audit`, as above. Never loop on polish.
6. Run the final whole-branch review, then complete the branch. If goldens
   changed, the owner gets the [golden review](#the-gate) page first.

### Where knowledge lives

| Knowledge | Home |
|---|---|
| Architecture and product decisions | an ADR in `docs/shared/decisions/` (read its `status:`) |
| The visual system | `DESIGN.md` |
| A screen's layout, states, transitions, rulings and copy | its detail file in `docs/shared/ui/screen-handoff/` |
| Known UI debt | the UI-base register (§9 of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`) |
| Work progress | the Linear project MemoX, team `DEV`: epics (label `Epic`) and their sub-issues (label group `WBS`: `BE`, `FE`, `Supabase`) ([ADR-021](docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md), `flutter-workflow`); the `docs/wbs_*.md` files are frozen history |
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
  to rewrite them); on Windows run the gate alone and never `--update-goldens`.
- Part of the suite runs through
  `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file|dir>…`
  (bundled, failures only), once; `flutter test` on a directory or the whole
  suite compiles every file on its own and is several times slower.
- **Auth on a real stack:** a PR that changes `lib/core/auth/`,
  `lib/features/account/` or `supabase/migrations/` also runs
  `bash tools/supabase/run_auth_it.sh` (Docker); it is outside the gate's
  suite, as `npx supabase test db` is.
- **Golden review:** when a branch adds, updates or deletes a
  `test/**/goldens/*.png`, the owner gets a before · after · diff page built
  with the `golden-compare` skill before any approve or merge. Changed images
  on their own are not a review.
- Hooks are repo-owned. [.claude/hooks/README.md](.claude/hooks/README.md)
  lists them and holds the subagent rules they enforce: every subagent on
  Sonnet except the final whole-branch review and a root-cause investigation,
  which run on Opus, and a
  `Workflow` whose token floor reaches 300k offered to the owner first. CI is paused and runs by hand; the local gate is what counts.

## Progress on Linear

Progress lives in the Linear project **MemoX** (team `DevelopmentTool`, key
`DEV`), never in `docs/wbs_*.md`, which are frozen
([ADR-021](docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md)). Every
session keeps it true on its own, through the Linear connector, without being
asked. Without the connector, tell the owner and record progress nowhere else.

- **Shape:** two levels only. An **epic** is a parent issue labelled `Epic`,
  one feature or theme, in a project milestone (`V8.0`, `Sau V8.0`,
  `Sync & tài khoản`; none for infrastructure). An **item** is a sub-issue of
  exactly one epic, in the epic's milestone, with exactly one `WBS` label:
  `BE`, `FE` or `Supabase`. Never nest a sub-issue under a sub-issue.
- **Read:** before starting work, find the issue it belongs to: the open
  sub-issues of the relevant epic, ordered by priority.
- **Create:**
  - Search the project first (`list_issues` with a query); never duplicate.
  - New work is a sub-issue of an existing epic: team, project, `parentId`,
    the epic's milestone, one `WBS` label, one kind label (`Feature`, `Bug`
    or `Improvement`), a plain title with no legacy WBS code (the issue is
    known by its `DEV-n`).
  - Titles, descriptions and comments follow
    [linear-templates.md](.claude/skills/flutter-workflow/references/linear-templates.md).
  - A new epic only for a new feature or spec — one spec, one epic — created
    once the owner approves the spec. Its plan's tasks become its sub-issues,
    one per task, never split further.
  - A small defect found along the way goes into the issue in hand, or
    becomes a sub-issue of the nearest epic.
- **Update:**
  - The branch and PR name the issue's `DEV-n`.
  - The issue is In Progress when work starts, In Review while its PR is
    open, and Done only once merged into `master`, with a comment carrying
    the evidence (PR, commit, tests) and anything descoped with its reason.
  - Blockers and open questions are comments on the issue; the order of work
    is priority.
  - An epic is Done when all its sub-issues are Done or Canceled. It then
    moves, with its sub-issues, to the Completed project `MemoX · Lưu trữ`,
    where it auto-archives: Linear archives nothing by hand, and nothing in
    an open project such as MemoX.
  - After saving, check any PR link Linear made: the workspace's GitHub
    integration may point `#n` at `memox-v6`; if it does, write
    "pull request số n của `ntgptit/memox-v8`" without `#`.
- **Delete:** never delete an issue. Cut work is Canceled with the reason,
  and only on the owner's decision (`AskUserQuestion`). A duplicate is set to
  Duplicate with `duplicateOf`.

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

## Fixing bugs and improving

The app is built; the work now is fixing, improving and auditing it. A fix
that silences the symptom where it was reported is not a fix. These bars hold
for every bug fix and every improvement, whoever reports it and however small
it looks.
Their order is the order of priority: a proven root cause, then one consistent
fix at the shared owner, then no regression, then the similar defects, then
maintainability. Speed and tokens come last and never buy back a higher bar.

- **Root cause, proven.** Every bug goes through
  `superpowers:systematic-debugging`. A fix lands only on a root cause stated
  as a mechanism: where (`file:line`), why it happens, which invariant or
  contract it breaks, why the change removes it, and which reported symptoms
  it explains. A test that fails before the fix and passes after pins it.
  - The reported screen, widget or stack frame is where the investigation
    starts, not where the fix belongs.
  - Cost never ends the search: tokens and time are spent freely. Reproduce,
    instrument, read the code underneath, try hypothesis after hypothesis, and
    stop only when the cause is proven and the explanation leaves nothing
    unexplained. Never rerun the same experiment without a new hypothesis or
    new evidence.
  - An investigation may run in an Opus subagent whose description starts
    `Root-cause investigation` ([hooks](.claude/hooks/README.md)).
  - If the cause cannot be proven, tell the owner what was ruled out and what
    is left. Never ship a guess, a retry, a guard or a delay that hides it.
- **Fix at the lowest shared owner.** When the cause lives, or belongs, in
  shared code (`lib/core/`, `lib/shared/`, an `Mx*` widget, a theme slot, a
  `.drift` query, an RPC, a base class), fix it there so every consumer
  inherits the fix. A per-screen patch over a shared defect is not accepted.
  - Look from the shared layers down: tokens and theme, shared widgets,
    shared state, services, repositories and queries, feature-level
    abstractions, and the screen last. That is the order to look in, not a
    licence to move into shared code what it does not own.
  - A local fix says why the shared layer is not the owner and whether other
    callers have the same defect. It never adds a local override, magic value
    or conditional that hides a shared defect.
  - Adding or promoting code into `lib/core/` or `lib/shared/` still goes to
    the owner ([below](#asking-the-owner)), with the shared fix as the
    recommended option.
- **Check degrade and check similar, every time.** Both run after every fix
  and every improvement; neither stands in for the other, and both are written
  into the PR and the issue's Done comment
  ([linear-templates.md](.claude/skills/flutter-workflow/references/linear-templates.md)):
  - **Check degrade:** list every consumer of what changed (callers, screens,
    widgets, queries, RPCs) and prove each still behaves: its tests, the gate,
    and the goldens when UI changed. Nothing that worked before may break, and
    no test or assertion is weakened or removed to get there.
  - **Check similar:** search the codebase for the same mechanism, not the
    same symptom: the pattern, call or misuse that caused it, by symbol and by
    behaviour. Each hit is classed as same root cause, similar but unaffected,
    suspect (verify it), or unrelated. A same-cause hit is fixed in the same
    PR (the shared fix usually covers it); a hit with a different root cause
    becomes a sub-issue, named in the PR.
  - A change made after the checks, such as a fix for a hit, reruns both on
    the final diff.
- **A screen is a state machine, not a screenshot.** This bar holds for every
  fix or improvement that touches a screen and for every UI audit.
  - The screen's detail file is its inventory: the States table and the
    Transitions table (from, event, to, evidence). Both are reconciled with
    the code (the controller's state type, its branches, async callbacks,
    dialogs and sheets): a state or transition in the code but not in the
    tables, or in the tables but not in the code, is a finding.
  - Check degrade covers every state and transition the change touches, not
    only the one reported; check similar also looks for the same state or
    transition pattern on other screens.
  - An audit judges each applicable state and the transitions that matter:
    error to retry to content, empty to content, Back or a second tap while
    loading or submitting, an async result arriving after the screen is gone,
    the shown data deleted, the account switched, offline or a sync mid-way.
  - Each state or transition is `VERIFIED`, `FAILED`, `UNVERIFIED` or
    `N/A` (with the reason), and names its evidence: an executed widget or
    integration test, a golden, a run on a device, or a reading of the code.
    A reading of the code is never reported as a run. An audit with a
    material `UNVERIFIED` row is not `VERIFIED`, and `VERIFIED` means the
    coverage is proven, not that nothing was found.
  - Coverage is by risk, not by every combination: data loss, dead ends,
    broken primary actions, async races and stale state, navigation and
    account errors, then layout and accessibility. Environments are light and
    dark, a 360dp phone, the keyboard and system insets, at the default text
    scale only (`PRODUCT.md`).
- **Report one final state.** `VERIFIED` when the cause is proven and both
  checks pass; `BLOCKED` when a named limit (access, device, owner decision)
  stops verification; `UNRESOLVED` when the cause or the fix is not proven. An
  unproven fix is never reported as fixed.
- **The final whole-branch review checks these bars** against the diff, the
  tests and the commands actually run, never against the agent's own account
  of them. When the change touches a screen or its state, the reviewer
  rebuilds the states and transitions from the code and compares them with
  the screen's tables.
- Moving a fix down to its shared owner and fixing same-cause hits are in
  scope, never scope creep.

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
