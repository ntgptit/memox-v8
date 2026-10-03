# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

MemoX is built for the public, on Google Play first (owner 2026-10-03). Its owner is the first user and the first admin.

The product documents two user profiles (`docs/README.md`, Target users):

- **Self-learner.** Studies vocabulary on a phone in scattered moments, often with an unreliable connection. Needs each word resurfaced at the right time, anywhere, offline included.
- **Exam crammer.** Has a large word volume and a deadline. Needs to see progress and to have the words closest to being forgotten come first.

Cards are language-agnostic term/meaning pairs (`BR-CARD-002`), so learners of any language are in scope. Most worked examples and fixtures are Korean vocabulary. That is sample content, not a market restriction.

Not the target: classrooms managed by a teacher, and learners who want ready-made curated content.

## Product Purpose

People forget most new vocabulary unless they review it at the right moment. Reviewing by hand from a notebook or a file never says *when* a word is due, so learners review too early (wasted effort) or too late (already forgotten).

MemoX schedules each card with spaced repetition. It shows only what is due, and every result updates the next review date.

Core value: review the right word at the right time, fully working without a network, and the same library on every device the learner signs in on (`docs/README.md`, Core value; owner 2026-10-03).

Success is the MVP "done when" checklist in `docs/README.md` (M1–M5, S1–S3): decks and cards persist, study sessions follow the SRS schedule, each deck shows today's due count, and everything works in airplane mode. No usage metrics are defined.

## Positioning

The mechanism, as built:

- **Offline-first, online when it can.** Every study path runs from the device without a network; when a connection is available, the library syncs through Supabase and follows the learner across devices.
- **The scheduler is a per-deck choice.** Each root deck picks `eight_box` (Leitner boxes) or `sm2`, locked after its first review.
- **How a card is asked is its own axis.** New cards pass through a fixed sequence of StudyModes before scheduled review.
- **No account needed to start.** An install begins anonymous; signing in is optional and keeps the same data.

No competitive claim against Anki, Quizlet or other flashcard apps is decided. Do not invent one.

## Operating Context

- Study happens on a phone, in short and interrupted sessions, often offline.
- The user creates their own decks and cards. Starter decks exist only as templates to copy; the current starter content is a development and test fixture, not production content (`ADR-005`, `BR-STARTER-010`).
- Decks form a tree; a root deck owns its subtree (`docs/glossary.md`).
- Each root deck chooses one of two schedulers, locked after its first review (`ADR-003`, `ADR-004`):
  - `eight_box`: Leitner-style boxes 1–8, answered remembered or forgotten.
  - `sm2`: SM-2, answered again, hard, good or easy.
- How a card is asked is a separate axis, the StudyMode: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`. New cards go through a fixed stage sequence before scheduled review (`docs/features/study-mode/README.md`).
- The app has four top-level destinations: Library (`/decks`), Study, Progress, Settings (`docs/shared/ui/navigation.md`). Account, Sync and the admin-only Monitoring and Users screens live under Settings.

## Capabilities and Constraints

- **Offline-first, server-backed.** User data is persisted in Drift (SQLite) on each device and synchronized with a Supabase project when connectivity is available (`ADR-013`, `ADR-015`). The server is the canonical cross-device store and checks integrity only; business rules and SRS live in the app alone. `memox-api-services/` is frozen as a reference (`ADR-015`).
- **What syncs:** decks, cards, tags and card–tag links, review history, SRS schedules, and account settings (card limit, new-card order, theme, language). Daily-reminder settings stay on the device (`docs/wbs_supabase.md`, SB-S2–SB-S5).
- **Accounts.** An install signs in anonymously. Signing in with email OTP or Google attaches an identity to the same user, so no data moves. A second device that signs in pulls the library, and its anonymous data is merged. Signing out clears the device's data. Account deletion removes every row of the user (auth spec `docs/superpowers/specs/2026-09-30-auth-design.md`). Status: code done; on-device checks wait on the Auth setup (SB-A2, SB-A3, SB-A5 after SB-A4).
- **Roles.** `user` by default and `admin`, stored in `public.profiles.role`. Only an admin grants roles. Admins see Monitoring (the server log) and Users under Settings.
- **Platforms.** Android is the release target. iOS follows once Android is stable and ships the same Material 3 design, honouring iOS guarantees: safe-area insets, Reduce Motion, edge-swipe back (`ADR-001`; owner 2026-10-03). There is no per-OS design language. Web is used only for development (E2E, visual regression) and is never shipped. Desktop is out of scope.
- **Phones first; tablets get a rail and a column.** From a window width of 600 dp the four destinations move to a navigation rail and every screen keeps its phone layout in a centred column of at most 720 dp (FE-C5; spec `2026-09-28-tablet-rail-design.md`). There are no two-pane or tablet-specific layouts.
- **UI languages:** follow the system, English or Vietnamese; the fallback is English (`BR-SETTINGS-006`). Vietnamese strings currently trail the English ones.
- **Features:** deck, card, srs, study-mode, study, progress, settings, library search (`ADR-009`), tags with a catalogue and filters, Trash (a delete is recoverable for 30 days, `BR-TRASH-009`), card import (CSV/TSV/XLSX or pasted text) and export, starter decks (development fixtures only), and a daily reminder (opt-in, off by default, permission asked only after the user turns it on, `BR-REMINDER-011`). Progress: `docs/wbs_FE.md`, `docs/wbs_BE.md`, `docs/wbs_supabase.md`.
- **Cards are text only.** Audio and images are out of scope. Deck sharing between users is out of scope.
- **Data handling:**
  - Everything is logged, user content and tokens included, to a server table only an admin can read (`ADR-018`, which retired `BR-CORE-002`).
  - Export to a file happens only on explicit request (`BR-CORE-004`).
  - Error messages never expose SQL, paths or ids (`BR-CORE-005`).
  - The database is not encrypted at MVP, and its open path is centralized for later encryption (`ADR-002`).
  - Datetimes are stored in UTC (`ADR-008`).
- **No V7 data compatibility or migration.** V7 is an architecture reference only.

### Open decisions

- **Logging for public users.** `ADR-018` decision 1 was made while the only user was the admin, and it says to revisit it once real users exist. A new ADR on what the log may hold must land before the public release (owner 2026-10-03).
- **Business model.** No price, ads or paid tier is decided. Future work must not invent one.
- **Competitive positioning.** See Positioning.

## Brand Commitments

- **The name is "MemoX"** (`lib/l10n/app_en.arb` `appTitle`).
- **Copy voice for failures is local-first:** say first that nothing was lost, then offer the retry (`DESIGN.md`, Do's and Don'ts).
- **Copy is caller-supplied and localized.** Components hold no copy.
- No brand guide, logo system or tone document exists beyond these points. The only identity asset is the Android launcher icon (`android/app/src/main/res/mipmap-*/ic_launcher.png`).
- The visual system is recorded in `DESIGN.md`, generated from the Flutter UI base (`ADR-019`). It is recorded there, not here.

## Evidence on Hand

- `DESIGN.md`: foundations, theme binding, the shared widgets and the copy voice, generated from the code.
- Goldens for the implemented UI, light and dark, at 3x: components (`test/shared/widgets/goldens/`, `test/app/goldens/`) and every screen (`test/features/*/presentation/goldens/`), written on Linux.
- Each screen's detail file with its states, goldens and rulings (`docs/shared/ui/screen-handoff/`, 33 screens in `00-index.md`).
- Known UI debt in the UI-base register (§9 of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`).
- There are no testimonials, users beyond the owner, pricing, marketing screenshots, store listing, press, or production starter-deck content. Future work must not fabricate any of them.

## Product Principles

1. **The right word at the right time, anywhere.** Every study path works offline, and the schedule, not the user's memory, decides what comes next.
2. **Local first, synced second.** The device is never blocked on the network; sync catches up when a connection appears, and its failures are visible, never silent.
3. **Start without an account.** Anonymous use is complete; signing in adds devices, not features.
4. **Phone first.** Layouts are designed for one-handed phone use in short sessions.
5. **Accessible by default.** Accessibility is a requirement, not a polish pass.

## Accessibility & Inclusion

- **Standard: WCAG 2.2 AA.**
  - Text contrast is at least 4.5:1, and 3:1 for large text and meaningful non-text elements.
  - TalkBack labels, states and reading order are complete.
  - Touch targets are 48 × 48 dp.
  - The default system font scale is the committed target. Larger scales are not a design target (owner 2026-09-30, confirmed for public users 2026-10-03); text still grows with the system setting and is never clamped, but a cut line at large text is not a defect, and tests (widget, golden, visual audit) run at the default scale only.
  - The system "remove animations" setting is honored.
- **Mixed-script content:** vocabulary in any script (Korean, Vietnamese with stacked diacritics, Latin) must render without clipping.
- **Known gaps against this standard** are recorded in the UI-base register (spec §9).
