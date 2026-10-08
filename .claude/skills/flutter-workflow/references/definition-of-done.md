# Definition of Done

A task is done when every line below is true. "Mostly done" is not a state that
exists here — a task marked Done on Linear is one the next person will build on
without re-checking.

## Scope
- [ ] The work matches its Linear issue — no more, no less.
- [ ] Acceptance criteria from the Linear issue all pass.
- [ ] No refactoring outside the stated scope leaked in. If you found something
      that needs fixing, open a separate Linear issue (`DEV-n`) rather than
      widening this one. Moving a fix down to its shared owner and fixing the
      same-cause hits of check similar are in scope (below).
- [ ] Existing architecture was not broken to make this fit. If the architecture
      genuinely blocked the task, that is a design conversation, not a workaround.

## Bug fix or improvement (CLAUDE.md, "Fixing bugs and improving")
- [ ] Root cause proven through `superpowers:systematic-debugging` and written
      as a mechanism: `file:line`, why it happens, the invariant or contract it
      breaks, why the change removes it, which symptoms it explains. No guess,
      retry, guard or delay that hides it.
- [ ] A regression test fails before the fix and passes after it.
- [ ] The fix sits at the lowest shared owner of the cause, so every consumer
      inherits it; no per-screen patch over a shared defect. A local fix states
      why the shared layer is not the owner, and adds no override, magic value
      or conditional that hides a shared defect.
- [ ] **Check degrade** done: every consumer of what changed listed, and each
      proven unchanged (its tests, the gate, goldens when UI changed). No test
      or assertion weakened or removed to get green.
- [ ] **Check similar** done: the codebase searched for the same mechanism, by
      symbol and by behaviour; each hit classed as same root cause, similar
      but unaffected, suspect (then verified) or unrelated; same-cause hits
      fixed in this PR, other-cause hits filed as sub-issues.
- [ ] Any change made after the checks reran both on the final diff.
- [ ] Both checks, with their consumer and hit lists, and the final state
      (`VERIFIED`, `BLOCKED` or `UNRESOLVED`) written in the PR and in the
      issue's Done comment; a bug's issue has sections I to V of the Bug
      template filled, an improvement's issue sections II to V of the
      Chore/Docs template, and both section VI when a screen or its state
      is touched ([linear-templates.md](linear-templates.md)).
      `VERIFIED` only when every line above holds.

## Code
- [ ] `dart format` produces no changes — run `check_format.sh`, not
      `dart format .`, which walks into the worktrees under `.claude/` and
      formats other branches' source (and crashes on their build output).
- [ ] `flutter analyze` is clean — zero errors *and* zero warnings.
- [ ] No new dependency without a stated reason.
- [ ] Layer boundaries hold (`check_architecture.sh` passes).
- [ ] No `catch (_) {}`, no unexplained `// ignore:`, no leftover `print`.

## Tests
- [ ] Tests for the business logic this task added or changed.
- [ ] The failure paths are tested, not just the happy path.
- [ ] Full suite passes, not only the new tests.

## UI (skip only if the task touched no UI)
- [ ] All colours, text styles, spacing and radii come from design tokens.
- [ ] Light mode and dark mode both checked.
- [ ] Small screen checked — nothing overflows, nothing is hidden behind the
      bottom navigation or the keyboard.
- [ ] Default text scale checked; large text is not a design target (PRODUCT.md, 2026-09-30).
- [ ] Loading, empty, error and success states all render correctly. An
      unhandled empty state is the single most common gap here.
- [ ] Every state and transition the work touches is checked (CLAUDE.md, "A
      screen is a state machine"): the screen's States and Transitions tables
      match the code, each touched row is `VERIFIED`, `FAILED`, `UNVERIFIED`
      or `N/A` with its evidence, and a state without a golden was rendered
      for the audit or is reported `UNVERIFIED`.
- [ ] Icon-only controls have semantic labels; touch targets are at least 48dp.
- [ ] The screen's geometry contract identifies its content gutters, alignment
      groups, relative widths/heights and important baselines. Every material
      relationship is asserted by a widget test that measures the production
      tree with `getRect` — not by looking at a golden. A container can be
      full-width while its children are not (`Wrap` and bare `Row` size children
      to their intrinsic width), and that defect is invisible to the analyzer,
      the guard, the colour audit and to a golden that was first recorded while
      wrong. See the Responsive section of `flutter-design-system`. The widget
      test is the authority for headings, fields, exact gutters, gaps and
      baselines.
- [ ] A new or updated golden was compared state-by-state with the actual
      concept or canonical reference. The review records approved differences;
      regenerating a baseline and reviewing it in isolation is not visual
      parity evidence.
- [ ] No user-visible string outside the ARB files.

## Paperwork
- [ ] The item's Linear issue (project MemoX, ADR-021): In Progress, then In Review, while the
      branch and PR name its `DEV-n`; Done once merged into `master`, with the
      evidence (PR, commit, tests) and anything descoped with the reason; for a screen, its row in the screen handoff index
      updated in this commit.
- [ ] Any doc the change invalidates (data model, API spec, design system) updated
      in this commit too.
- [ ] Code reviewed.
- [ ] CI green.

## Running the mechanical checks

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

The script covers format, analyze, tests and layer boundaries. Everything under
Scope, UI and Paperwork needs a human to look — those are also where the real
defects hide, so do not let a green script stand in for that review.
