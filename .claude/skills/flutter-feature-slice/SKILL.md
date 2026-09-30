---
name: flutter-feature-slice
description: Use when a request asks to build, add, implement or finish a feature or screen in this Flutter app — "add login", "build the deck list", "implement search", "finish the profile screen" — and when a coding task turns out to rest on a missing use case, an undefined state, or an unagreed API contract. It is the usual entry point for feature work.
---

# Building a feature as a vertical slice

This is the loop you run for every feature, and it composes the other skills
rather than repeating them.

**Vertical slice means: database to screen, one feature at a time.** One feature
working end to end proves the architecture and surfaces integration problems
while they are still cheap. Four features each half-built prove nothing and hide
the same problems until they are expensive.

## Step 0 — Pre-flight, before writing any code

Do not skip this because the feature "seems obvious". Every item here that turns
out to be open becomes rework, and the rework is always larger than the check.

- [ ] **Use case approved** — exists in `docs/features/<feature>/usecases/` with main,
      alternative and error flows.
- [ ] **Business rules clear** — the `BR-xx` rules this feature enforces are
      written, and validation rules have their exact user-facing messages.
- [ ] **Design available** — or an explicit agreement to use existing components
      with no new visual design.
- [ ] **State matrix decided** — which of initial / loading / loaded / empty /
      error / refreshing / submitting occur, and what each shows.
- [ ] **API contract known** — N/A until the slice calls the API (ADR-012).
      When it does: endpoints, shapes, error format and pagination in
      `docs/features/<feature>/api.md` first, and build against a fake
      implementing the same interface.
- [ ] **Data model known** — entities, tables, whether a migration is needed.
- [ ] **Acceptance criteria written** in the WBS entry, checkable by someone
      else.
- [ ] **Dependencies identified** — which features or shared components this
      needs, and whether they exist yet.
- [ ] **Existing code known** — what `lib/core/` (`clock`, `id`, `text`,
      `error`, `database`, `sync`, `theme`), `lib/shared/widgets/` and the
      touched features already offer for this slice. Routine choices, such as
      reusing an existing helper or writing feature-local code the task asks
      for, are the agent's own. Only adding or promoting code into
      `lib/core/` or `lib/shared/`, or a shortcut in place of requested code,
      is a reuse-or-write call: recommend one and ask the owner (CLAUDE.md,
      Asking the owner).

If something is missing, stop and get it. Load `flutter-product-spec` if the
gap is a use case or business rule. Report which item is open and what you need
— building on an assumption and being wrong costs far more than asking.

The exception worth naming: if the user has heard the gap and says build it
anyway, build it. State the assumption you are proceeding on, record it in the
WBS entry, and continue with the full scope.

## Step 1 — Domain

Layer rules: `flutter-architecture`. No Flutter, no Dio, no Drift here.

```
features/<feature>/domain/
├── entities/       <name>_entity.dart
├── repositories/   <name>_repository.dart          # abstract contract
├── models/         <name>_model.dart               # read model / value object / enum
├── usecases/       <verb>_<noun>_use_case.dart     # one per UI interaction (ADR-011 D4)
└── failures/       <name>_failure.dart             # the feature's rejection enum
```

**The folder does not replace the suffix.** `entities/deck_entity.dart`, not
`entities/deck.dart`: the role is carried by the *file name*, which
`memox.naming.domain_file_role_suffix` enforces and which several guard scopes
select on. `check_architecture.py` additionally pairs each folder with its
required suffix. The authority on layout is ADR-011
(`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`), and this block is a
summary of it. `lib/features/deck/` and `lib/features/card/` are the worked
examples.

- Entities are immutable, with value equality, in domain language. Entity state
  is the enum or sealed class from `docs/features/<feature>/data.md` (state
  machines), so illegal states
  are unrepresentable rather than merely unlikely.
- The repository contract is written from what presentation needs, not from what
  the API happens to offer. If the API needs three calls for one screen, the
  contract still has one method and the implementation makes three.
- Business validation belongs here — it is the same regardless of UI, and here
  it can be unit-tested without a widget or a server.
- **One use case per interaction** (ADR-011 D4). It takes the repository
  *contract*, never an implementation, and it is where the input validation
  lives — a controller that validates and a repository that validates the same
  rule again is the shape this replaced.
- **A rule that needs the tree as it stands at the moment of writing stays in the
  repository**, inside `runInTransaction`. Depth limits, content locks, emptiness
  checks, subtree moves. A use case above the repository would put the check
  outside the transaction, which is a race between the check and the write.
- **A pass-through use case with optional parameters must forward every one of
  them, and gets a test proving it.** Optional params have defaults, so a
  dropped `sort:` or `searchTerm:` compiles clean and analyzes clean, and
  only an end-to-end run would catch it. The lock is cheap: a fake repository
  that records every parameter it receives, one assert per param.

## Step 2 — Data

Details: `flutter-data-layer`.

```
features/<feature>/data/
├── repositories/   <name>_repository_impl.dart
├── mappers/        <name>_mapper.dart              # Row → Entity, AggregateResult → ReadModel
├── datasources/    <name>_dao.dart
└── models/         <name>_model.dart               # DTOs, with the first wire format
```

No feature has `models/` yet: **there is no DTO layer in a feature**, and a
folder appears with its first real file (ADR-011 D1). DTOs are the wire format,
`json_serializable` classes, never Freezed (ADR-012), and only sync calls the
API: its DTOs are in `lib/core/sync/sync_models.dart`. A feature's only data
shape besides its entity is Drift's generated row.

Order: the DAO first, then the mapper, then the repository. The repository is
where Drift exceptions become `Failure`s — nowhere else. **There is no cache
policy to apply.** Reads come from `watch()` streams straight off the table:
Drift is the app's durable store, not a cache in front of the server, so a
cache layer here would be a guess at a requirement that does not exist. Nor is
sync built per feature: triggers in `sync.drift` queue a synced table's
writes, and one app-wide `SyncCoordinator` in `lib/core/sync/` pushes and
pulls (ADR-013, ADR-015).

SQL goes in `.drift` files under `lib/core/database/` so `drift_dev` type-checks
it at build time. No business SQL in Dart. Multi-step writes run inside
`dao.runInTransaction`, and every guard that can refuse runs *before* the first
mutation.

## Step 3 — Presentation

Details: `flutter-state-riverpod` for state, `flutter-design-system` for UI,
`flutter-navigation` for routes.

```
features/<feature>/presentation/
├── screens/        <name>_screen.dart
├── controllers/    <name>_controller.dart
├── states/         <name>_state.dart
├── widgets/        <section>_widget.dart
└── providers/      # only when a provider is not a controller
```

MX-VIS-001 derives each screen's required audit path by stripping **only** the
`presentation` segment, so the `screens/` folder is preserved in the companion
path: `test/visual_audit/screens/features/<f>/screens/<name>_visual_audit_test.dart`.
A file holding a provider must still be named `_controller.dart`, not
`_provider.dart` — the guard's widget scopes forbid
`ref.watch(...RepositoryProvider)` and exempt controllers by that suffix, which is
where that read belongs.

Build state and controller before the screen. Writing the state model first
forces the state matrix to be real, and the screen then becomes a rendering of
something already decided rather than the place where the decisions get made
implicitly.

While building the screen:

- Use existing components and tokens. Do not invent visual design mid-feature —
  if the design is genuinely missing, raise it rather than improvising, because
  an improvised variant becomes another thing to reconcile later.
- Do not create a shared component for this feature's first use. Build it
  locally; promote it to `shared/` when a second real caller appears and shows
  you what actually varies.
- Split the screen into section widgets — separate classes, not `_buildX()`
  methods.
- **Render every state in the matrix.** Empty is the one that gets skipped, and
  it is the first thing a new user sees.
- Check dark mode, a 320px screen, and keyboard-open (default text scale) before
  calling the screen done — not in a later pass, when fixing it means
  restructuring.

## Step 4 — Tests

Details: `flutter-testing`.

Minimum for a feature to be done:

- [ ] Unit tests for domain logic and validation, including the rule violations.
      Pure input/output — no database, no widget.
- [ ] Repository tests against **real in-memory SQLite**, not a mocked executor.
      What is in doubt is the SQL: the cascade, the transaction rollback, the NULL
      semantics of a predicate. A mocked data source would only prove the code
      calls the API it was written to call, which is the one thing nobody doubts.
      Use `test/support/test_database.dart` and a per-feature harness.
      There is no cache fallback to cover — see Step 2.
- [ ] Mapper tests, including a null field and an unknown enum value.
- [ ] Controller tests: initial state, loading→loaded, loading→error, refresh,
      submit success, submit failure, duplicate submit.
- [ ] Widget tests for the states that matter — at least loaded, empty, error —
      against a **fake of the domain contract**, not a real database. Driving Drift
      from a widget test leaves its stream-notification timer pending at teardown
      and `flutter_test` fails the test for that rather than for the behaviour.
- [ ] Route tests through the real router: cold start, deep link, back, and the
      branch state if the route sits in the navigation shell.
- [ ] A strict visual audit companion per production screen (MX-VIS-001), one
      call per state, PASS in light and dark.
- [ ] Golden tests if this feature added a shared component.
- [ ] Each golden compared, state by state, with the screen in the kit (the
      Definition of Done's UI section): the machine checks catch overlap and
      contrast; this is where a person *looks*.

`test/features/deck/` and `test/features/card/` show which test sits at which
level, and their size is a reference for a slice of that weight.

## Step 5 — Close it out

- [ ] `.claude/skills/flutter-workflow/scripts/dod_check.sh` passes.
- [ ] `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean
      (`flutter analyze` does not cover the Riverpod and layering rules).
- [ ] `docs/wbs_BE.md` or `docs/wbs_FE.md` updated in this commit — status, and
      anything descoped with the reason; for a screen, its row in the screen
      handoff index.
- [ ] Docs the feature changed (data model, API spec, architecture decisions)
      updated in the same commit.
- [ ] Full Definition of Done reviewed:
      `.claude/skills/flutter-workflow/references/definition-of-done.md`.
- [ ] Conventional commit scoped to the feature: `feat(<feature>): ...`.

`assets/feature_checklist.md` is a copy-paste version of all of the above to
paste into a WBS entry or PR description.

## What does not transfer from Deck and Card

Deck and Card are worked examples of the **method**, not templates for the
data. Everything below exists in one of them **because that feature's business
asked for it**; a new feature that acquires one without its own reason has been
scaffolded, not designed.

| Belongs to | What it is | Why it is not yours |
|---|---|---|
| Deck | The recursive tree (`parent_id`, `root_id`) | A feature whose objects do not *contain* other objects of the same kind has no tree. Most do not. |
| Deck | The content type a deck settles on its first child | A business rule of Deck (ADR-006), not a pattern. |
| Deck | The scheduler on the root deck and its lock | Study's business (ADR-003, ADR-004). It reaches Deck only because a deck is what gets studied. |
| Deck | `DeckRejection` and its values | The *idea* — a refusal carries its reason as a value (ADR-011 D6) — transfers. The values do not. |
| Card | Tags, the flag and the optional detail fields | Card content. A tag table is not a layer. |
| Card | The card statuses derived at read time | Derived-not-stored is decided per feature; *these statuses* answer Card's. |
| Both | The literal folder contents | The buckets are fixed (ADR-011 D8); which of them a feature fills is decided by what it renders. An empty bucket is not a gap. |

**The test to apply instead of copying.** For each thing you are about to bring
across, ask: *"if I delete this, does my feature stop being correct, or does it
stop resembling Deck?"* Only the first is a reason to keep it.

**Where Deck and Card disagree, the disagreement is the answer.** Two examples
exist so the method can be told apart from one feature's habits — a single
example cannot distinguish "this is the rule" from "this is how that one was
built".

## The failure modes this ordering prevents

- **Screen first, then data.** The state model ends up shaped by widget
  convenience, and the error states never appear because the fake never failed.
- **All features' domains, then all their data.** Nothing is demonstrable, and
  the first integration reveals problems in every feature at once.
- **Tests last, after the demo.** They get written to match what the code does,
  which is not the same as what the acceptance criteria say.
- **Promoting a component on first use.** The abstraction is a guess; the second
  caller then needs a parameter, and the third needs a flag that changes the
  layout.
