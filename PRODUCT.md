# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

MemoX is a personal app. Its owner builds it for their own study and uses it first.

The two user profiles, the self-learner and the exam crammer, are defined once in `docs/README.md` › Target users (context, need, who is not the target). The owner fits both.

Cards are term/meaning pairs with no language field (`docs/shared/data/schema.md`, table `card`), so learners of any language are in scope. Most worked examples and fixtures are Korean vocabulary. That is sample content, not a market restriction.

Not the target: classrooms managed by a teacher, and learners who want ready-made curated content.

## Product Purpose

The problem and the core value are stated once in `docs/README.md` › Problem and › Core value, and are not repeated here. In one line: MemoX schedules each card with spaced repetition, shows only what is due, and works fully without a network.

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

- **Offline-first, server-backed.** MemoX stays fully usable without a network connection: user data is persisted in Drift (SQLite) on each device and synchronized with a Supabase project when connectivity is available (`ADR-013`, `ADR-015`). The server is the canonical cross-device store and checks integrity only; business rules and SRS live in the app alone. Every user data type syncs (decks, cards, tags, Trash batches, reviews, schedules, account settings). Each install starts with an anonymous session; signing in with email OTP or Google attaches it to an account, and an admin role manages users (`ADR-015`). Deck sharing remains out of scope. `memox-api-services/` is frozen as a reference (`ADR-015`).
- **Android release target.** iOS is deferred until Android is stable. Web is used only for development (E2E, visual regression) and is never shipped. Desktop is out of scope (`ADR-001`).
- **Phones first; tablets get a rail and a column.** The adaptive behaviour (the navigation rail from 600 dp, the centred content column) is recorded in `DESIGN.md` › Layout, not here. There are no two-pane or tablet-specific layouts (FE-C5, owner 2026-09-28; spec `2026-09-28-tablet-rail-design.md`).
- **UI languages:** follow the system, English or Vietnamese; the fallback is English (`BR-SETTINGS-006`).
- **Data handling:**
  - Everything is logged, user content included, to a server table only an admin can read (`ADR-018`, which retired `BR-CORE-002`).
  - Export happens only on explicit request (`BR-CORE-004`).
  - Error messages never expose SQL, paths or ids (`BR-CORE-005`).
  - The database is not encrypted at MVP, and its open path is centralized for later encryption (`ADR-002`).
  - Datetimes are stored in UTC (`ADR-008`).
- **Cards are text only.** Audio and images are out of MVP.
- **In scope for V8.0 (`docs/features/*/README.md`):** deck, card, srs, study-mode, study, progress, settings, search (`ADR-009`), card tags (`ADR-009`).
- **Built after V8.0:** full tag management, starter decks (development fixtures, not production content), daily reminders (opt-in, off by default; Android only, the on-device check pending), CSV/TSV/XLSX import and export, and Trash (a delete is recoverable for 30 days, `BR-TRASH-009`). Progress: the Linear project MemoX (ADR-021).
- **No V7 data compatibility or migration.** V7 is an architecture reference only (`ADR-011`).

## Brand Commitments

- **The name is "MemoX"** (`lib/l10n/app_en.arb` `appTitle`).
- **Copy voice for failures is local-first:** say first that nothing was lost, then offer the retry (`DESIGN.md`, Do's and Don'ts).
- **Copy is caller-supplied and localized.** Components hold no copy.
- No brand guide, logo system or tone document exists beyond these points. The only identity asset is the Android launcher icon (`android/app/src/main/res/mipmap-*/ic_launcher.png`).
- The visual system is recorded in `DESIGN.md`, generated from the Flutter UI base (ADR-019). It is recorded there, not here.

## Evidence on Hand

- `DESIGN.md`: foundations, theme binding, the shared widgets and the copy voice, generated from the code.
- Goldens for the implemented UI, light and dark, at 3x: components (`test/shared/widgets/goldens/`, `test/app/goldens/`) and every screen (`test/features/*/presentation/goldens/`), written on Linux.
- Each screen's detail file with its states, goldens and rulings (`docs/shared/ui/screen-handoff/`).
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
  - The default system font scale is the committed target. Larger scales are not a design target (owner 2026-09-30: the users are young and keep the default size); text still grows with the system setting and is never clamped, but a cut line at large text is not a defect, and tests (widget, golden, visual audit) run at the default scale only.
  - The system "remove animations" setting is honored.
- **Mixed-script content:** vocabulary in any script (Korean, Vietnamese with stacked diacritics, Latin) must render without clipping. Tight line-heights are a known risk (spec §9 row 5).
- **Known gaps against this standard** are recorded in spec §9 rows 1–5 and 56–66: contrast of several status and warning colours, and missing loading semantics.
