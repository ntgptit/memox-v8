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

## No speculative structure

Avoid speculative abstractions.

- Do not scaffold layers or folders "for later".
- Do not create pass-through layers or single-implementation interfaces
  without a concrete architectural reason.

## Language

Always reply to the user in Vietnamese. Code, identifiers, commit messages and
PR text keep their existing language conventions.
