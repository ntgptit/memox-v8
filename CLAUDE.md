# CLAUDE.md — MemoX V8

## Layers and authority

Each layer answers one question; none takes over another's.

| Layer | Answers | Owns |
|---|---|---|
| Superpowers | What happens next, and is it done? | brainstorming, specs, architecture, plans, worktrees, TDD, debugging, implementation, code review, verification, branch completion |
| Impeccable | Is the UI right? | product definition, UX, UI design, design system, accessibility, adaptive/responsive behaviour, visual quality |
| Repo rules | What must always hold? | the guard (`memox-v8` ruleset), the ADRs, the `flutter-*` skills, this file |
| ECC skills | What does good practice look like here? | reference knowledge only (see [Vendored ECC skills](#vendored-ecc-skills)) |

- **Superpowers is the sole process controller.** Nothing else plans,
  sequences or gates work, and no other layer repeats its methodology.
- **Impeccable judges UI against the kit, not against its own taste.** The kit
  is the design authority ([UI source of truth](#ui-source-of-truth)).
  Impeccable checks the work against the kit and against the quality floor.
- **Repo rules hold project invariants only**, such as the architecture,
  stack, data rules and quality bars. They never restate a workflow.
- **ECC skills are read on demand** by whoever does the task. They are never
  routed to as agents, and they never override a layer above.

### A screen's workflow

1. Read the screen and all its states in the kit.
2. Run `superpowers:brainstorming`: goal, scope, business rules (BR/UC),
   constraints.
3. Run Impeccable before the plan:
   - critique the design against the kit (what the plan must adopt or rule
     on);
   - use `shape` only for a screen or state that the kit does not cover.
4. Run `superpowers:writing-plans`, then execute it, subagent-driven or
   native, as the user chooses.
5. Run Impeccable after the build: critique and audit the goldens against
   the kit.
   - Fix everything found in one batch, then confirm once. Never loop on
     polish.
6. Run the final whole-branch review, then complete the branch.

### Where knowledge lives

| Knowledge | Home |
|---|---|
| Architecture and product decisions | an ADR in `docs/shared/decisions/` |
| Deviations from the kit or a UI spec | the screen's detail file or the UI-base register (§9) |
| Plan-time rulings | the plan and its execution ledger, then the PR |
| The agent's working preferences and lessons | Claude Code auto-memory |

Do not add another store, such as `.ecc/memory/`. Anything meant to outlive
a session and bind the project goes into the repo through a PR. Handoff to
another harness goes through `AGENTS.md` or `docs/`.

### Hooks

- Hooks are repo-owned and small: `.claude/hooks/` and `.claude/settings.json`.
- They run the repo's own tools, such as `dart format`, `flutter analyze` and
  the guard. They never run third-party scripts, including ECC's hooks.
- The full test suite stays at the task gate, not at every edit or commit.
  Goldens render in the Linux container only
  (`.claude/skills/flutter-testing/scripts/golden.Dockerfile`); on Windows the
  gate runs `flutter test --exclude-tags golden` and never `--update-goldens`.

## V7 is a reference, not a template

V7 is a reference implementation only.

Do not copy V7 architecture, folder structure, state management, routing,
dependency wiring, UI implementation, or abstractions.

Exception: the layer architecture (`domain/ data/ presentation/ di/` with
repository contracts, Drift tables in `lib/core/database/`), feature folder
names and the Flutter version follow
[ADR-010](docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md).

Preserve V7 business behavior and required data compatibility unless an
approved V8 specification explicitly changes them.

## UI source of truth

The visual authority for every V8 screen is the artifact "MemoX — Mobile UI
Kit v3": <https://claude.ai/artifact/UCesgHkzYHKsZwhwVshKRE>.

- **Precedence:** a BR or UC beats the kit; the kit beats a UI spec's layout
  and copy. Record every deviation from the kit, either in the screen's detail
  file or in the UI-base debt register
  ([§9](docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md)).
- **Where it is described:**
  - the [screen handoff index](docs/shared/ui/screen-handoff/00-index.md)
    holds the screen numbers, states, FE items, status, and the rules every
    screen shares;
  - the [design handoff](docs/shared/ui/design-handoff/00-index.md) holds the
    foundations, the theme binding and the widgets.
- **Reading it:** use the Artifact tool's `read` action, not a web fetch. The
  page is a bundle: each screen and each of its states is its own module.
- **Before planning a screen,** read that screen and all its states in the
  kit.
- **After building a screen,** update its row in the screen handoff index.

## Vendored ECC skills

`.claude/skills/` holds 19 skills copied, unchanged, from
[affaan-m/ECC](https://github.com/affaan-m/ECC) (MIT) at commit
`bf70150eb2df8070024e5bdf08e4aa08959e2735`:

| Area | Skills |
|---|---|
| Flutter/Dart | `dart-flutter-patterns`, `flutter-dart-code-review` |
| Java/Spring | `java-coding-standards`, `jpa-patterns`, `springboot-patterns`, `springboot-security`, `springboot-tdd`, `springboot-verification` |
| Security | `security-review` |
| Mobile | `android-clean-architecture`, `compose-multiplatform-patterns`, `kotlin-coroutines-flows`, `swiftui-patterns`, `swift-concurrency-6-2`, `swift-actor-persistence`, `swift-protocol-di-testing`, `react-native-patterns`, `foundation-models-on-device`, `liquid-glass-design` |

- **They are reference material, not process.** When one conflicts with the
  rest of this file, this file wins: Superpowers and Impeccable own the
  workflows. The same holds for the repo's own skills (`flutter-*`), the ADRs
  (ADR-010, ADR-011) and the guard. For example, V8 uses Riverpod and Drift,
  not BLoC, Dio or Freezed.
- **Java/Spring skills wait for a backend.** V8.0 is local-only (ADR-001), so
  it has no backend to use them on yet. They apply once a server-side
  sub-project starts, under that sub-project's ADRs.
- **Skills only.** ECC's agents, rules, hooks, commands and memory are not
  used here. A plan task never delegates to an ECC agent; its implementer
  reads the relevant skill instead.
- **Not vendored:** `ios-icon-gen` ships executable scripts, and `security-scan`
  runs the npm package `ecc-agentshield`. Both run third-party code.
- **To update:** copy the new versions from a pinned ECC commit, review the
  diff, and update the commit above.

## No speculative structure

Avoid speculative abstractions.

- Do not scaffold layers or folders "for later".
- Do not create pass-through layers or single-implementation interfaces
  without a concrete architectural reason.

## Language

Always reply to the user in Vietnamese. Code, identifiers, commit messages and
PR text keep their existing language conventions.

Messages printed by the scripts in `tools/` (errors, warnings, status lines,
CLI help) are in English. Strings that belong to a document format, such as the
Vietnamese section headings a script checks or text it writes into generated
docs, follow the docs.
