# CLAUDE.md — MemoX V8

## Process ownership

Superpowers is the sole software-development process controller.

Use Superpowers for:

- brainstorming
- architecture
- specifications
- implementation plans
- worktrees
- TDD
- debugging
- implementation
- code review
- branch completion

Use Impeccable for:

- product definition
- UX
- UI design
- design system
- accessibility
- adaptive/responsive behavior
- visual quality

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
