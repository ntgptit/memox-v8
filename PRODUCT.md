# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

MemoX is a personal app. Its owner builds it for their own study and uses it first.

The product documents two user profiles (`docs/README.md`, Target users). The owner fits both:

- **Self-learner.** Studies vocabulary on a phone in scattered moments, often with an unreliable connection. Needs each word resurfaced at the right time, anywhere, offline included.
- **Exam crammer.** Has a large word volume and a deadline. Needs to see progress and to have the words closest to being forgotten come first.

Cards are language-agnostic term/meaning pairs (`BR-CARD-002`), so learners of any language are in scope. Most worked examples and fixtures are Korean vocabulary. That is sample content, not a market restriction.

Not the target: classrooms managed by a teacher, and learners who want ready-made curated content.

## Product Purpose

People forget most new vocabulary unless they review it at the right moment. Reviewing by hand from a notebook or a file never says *when* a word is due, so learners review too early (wasted effort) or too late (already forgotten).

MemoX schedules each card with spaced repetition. It shows only what is due, and every result updates the next review date.

Core value: review the right word at the right time, fully working without a network (`docs/README.md`, Core value).

Success is the MVP "done when" checklist in `docs/README.md` (M1–M5, S1–S3): decks and cards persist, study sessions follow the SRS schedule, each deck shows today's due count, and everything works in airplane mode. No usage metrics are defined.

## Positioning

This is not a market product. It is a personal app its owner builds so they can customize it freely. No competitive positioning against Anki or other flashcard apps is claimed, and none should be invented.

## Operating Context

- Study happens on an Android phone, in short and interrupted sessions, often offline.
- The user creates their own decks and cards. Starter decks exist only as templates to copy; the current starter content is a development and test fixture, not production content (`ADR-005`, `BR-STARTER-010`).
- Decks form a tree; a root deck owns its subtree (`docs/glossary.md`).
- Each root deck chooses one of two schedulers, locked after its first review (`ADR-003`, `ADR-004`):
  - `eight_box`: Leitner-style boxes 1–8, answered remembered or forgotten.
  - `sm2`: SM-2, answered again, hard, good or easy.
- How a card is asked is a separate axis, the StudyMode: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`. New cards go through a fixed stage sequence before scheduled review (`docs/features/study-mode/README.md`).
- The app has four top-level destinations: Library (`/decks`), Study, Progress, Settings (`docs/shared/ui/navigation.md`).

## Capabilities and Constraints

- **Local-only.** No network, no account, and one local profile. Drift (SQLite) is the source of truth (`ADR-001`). Login, multi-device sync, deck sharing and role permissions are out of MVP until a backend exists.
- **Android release target.** iOS is deferred until Android is stable. Web is used only for development (E2E, visual regression) and is never shipped. Desktop is out of scope (`ADR-001`).
- **Phones only, for now.** Tablet layouts (navigation rail, two-pane, wide layouts) are deferred by the owner (2026-09-24). On a tablet the app only needs to stay usable; the adaptive gap stays recorded in spec §9 row 63 until tablets are picked up.
- **UI languages:** follow the system, English or Vietnamese; the fallback is English (`BR-SETTINGS-006`). Vietnamese strings currently trail the English ones.
- **Data handling:**
  - User content is never logged (`BR-CORE-002`).
  - Export happens only on explicit request (`BR-CORE-004`).
  - Error messages never expose SQL, paths or ids (`BR-CORE-005`).
  - The database is not encrypted at MVP, and its open path is centralized for later encryption (`ADR-002`).
  - Datetimes are stored in UTC (`ADR-008`).
- **Cards are text only.** Audio and images are out of MVP.
- **In scope for V8.0 (`docs/features/*/README.md`):** deck, card, srs, study-mode, study, progress, settings, search (`ADR-009`), card tags (`ADR-009`).
- **Deferred sub-projects:** full tag management, starter decks, daily reminders (opt-in, off by default), CSV/TSV/XLSX import and export, and Trash (today a delete cascades permanently).
- **No V7 data compatibility or migration.** V7 is an architecture reference only (`CLAUDE.md`).

## Brand Commitments

- **The name is "MemoX"** (`lib/l10n/app_en.arb` `appTitle`).
- **Copy voice for failures is local-first:** say first that nothing was lost, then offer the retry (`docs/shared/ui/design-handoff/widgets/error-state.md`).
- **Copy is caller-supplied and localized.** Components hold no copy.
- No brand guide, logo system or tone document exists beyond these points. The only identity asset is the Android launcher icon (`android/app/src/main/res/mipmap-*/ic_launcher.png`).
- The visual system is the V3 design handoff (`docs/shared/ui/design-handoff/`), implemented by the Flutter UI base. It is recorded there, not here.

## Evidence on Hand

- The V3 design handoff: foundations, theme binding and 46 widget contracts (`docs/shared/ui/design-handoff/`).
- Component goldens for the implemented UI, light and dark, at 3x (`test/shared/widgets/goldens/`, `test/app/goldens/`).
- The phase 6 native audit: score 13/20, findings in spec §9 rows 56–66 (`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`).
- There are no testimonials, users, pricing, monetization, marketing screenshots, press, or production starter-deck content. Future work must not fabricate any of them.

## Product Principles

1. **Built to be changed by its owner.** Prefer simple, well-bounded mechanisms the owner can read and customize over generality nobody asked for.
2. **The right word at the right time, anywhere.** Every study path works offline, and the schedule, not the user's memory, decides what comes next.
3. **The learner's content stays the learner's.** Decks live on the device, are never logged, and leave it only on explicit request.
4. **Phone first.** Layouts are designed for one-handed phone use in short sessions.
5. **Accessible by default.** Accessibility is a requirement, not a polish pass.

## Accessibility & Inclusion

- **Standard: WCAG 2.2 AA.**
  - Text contrast is at least 4.5:1, and 3:1 for large text and meaningful non-text elements.
  - TalkBack labels, states and reading order are complete.
  - Touch targets are 48 × 48 dp.
  - Layouts hold at large system font scales.
  - The system "remove animations" setting is honored.
- **Mixed-script content:** vocabulary in any script (Korean, Vietnamese with stacked diacritics, Latin) must render without clipping. Tight line-heights are a known risk (spec §9 row 5).
- **Known gaps against this standard** are recorded in spec §9 rows 1–5 and 56–66: contrast of several status and warning colours, and missing loading semantics.
