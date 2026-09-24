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
