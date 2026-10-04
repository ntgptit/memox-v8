# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

MemoX is a personal app. Its owner builds it for their own study and uses it first.

The product has two user profiles. The owner fits both:

- **Self-learner.** Studies vocabulary on a phone in scattered moments, often with an unreliable connection. Needs each word resurfaced at the right time, anywhere, offline included.
- **Exam crammer.** Has a large word volume and a deadline. Needs to see progress and to have the words closest to being forgotten come first.

Cards are language-agnostic term/meaning pairs (`BR-CARD-002`), so learners of any language are in scope. Most worked examples and fixtures are Korean vocabulary. That is sample content, not a market restriction.

Not the target: classrooms managed by a teacher, and learners who want ready-made curated content.

## Product Purpose

People forget most new vocabulary unless they review it at the right moment. Reviewing by hand from a notebook or a file never says *when* a word is due, so learners review too early (wasted effort) or too late (already forgotten).

MemoX schedules each card with spaced repetition. It shows only what is due, and every result updates the next review date.

Core value: review the right word at the right time, fully working without a network.

Success is the MVP "done when" checklist in MVP Scope below (M1–M5, S1–S3): decks and cards persist, study sessions follow the SRS schedule, each deck shows today's due count, and everything works in airplane mode. No usage metrics are defined.

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

- **Offline-first, server-backed.** MemoX stays fully usable without a network connection: user data is persisted in Drift (SQLite) on each device and synchronized with a Supabase project when connectivity is available (`ADR-013`, `ADR-015`). The server is the canonical cross-device store and checks integrity only; business rules and SRS live in the app alone. Decks sync today; each install signs in anonymously until login lands. Deck sharing and role permissions remain out of scope. `memox-api-services/` is frozen as a reference (`ADR-015`).
- **Android release target.** iOS is deferred until Android is stable. Web is used only for development (E2E, visual regression) and is never shipped. Desktop is out of scope (`ADR-001`).
- **Phones first; tablets get a rail and a column.** From a window width of 600 dp (tablets, and phones in landscape) the four destinations move to a navigation rail and every screen keeps its phone layout in a centred column of at most 720 dp (FE-C5, owner 2026-09-28; spec `2026-09-28-tablet-rail-design.md`). There are no two-pane or tablet-specific layouts.
- **UI languages:** follow the system, English or Vietnamese; the fallback is English (`BR-SETTINGS-006`). Vietnamese strings currently trail the English ones.
- **Data handling:**
  - Everything is logged, user content included, to a server table only an admin can read (`ADR-018`, which retired `BR-CORE-002`).
  - Export happens only on explicit request (`BR-CORE-004`).
  - Error messages never expose SQL, paths or ids (`BR-CORE-005`).
  - The database is not encrypted at MVP, and its open path is centralized for later encryption (`ADR-002`).
  - Datetimes are stored in UTC (`ADR-008`).
- **Cards are text only.** Audio and images are out of MVP.
- **In scope for V8.0 (`docs/features/*/README.md`):** deck, card, srs, study-mode, study, progress, settings, search (`ADR-009`), card tags (`ADR-009`).
- **Built after V8.0:** full tag management, starter decks (development fixtures, not production content), daily reminders (opt-in, off by default; Android only, the on-device check pending), CSV/TSV/XLSX import and export, and Trash (a delete is recoverable for 30 days, `BR-TRASH-009`). Progress: `docs/wbs_FE.md`, `docs/wbs_BE.md`; sync and login: `docs/wbs_supabase.md`.
- **No V7 data compatibility or migration.** V7 is an architecture reference only (`CLAUDE.md`).

## MVP Scope

Principle: the MVP is **one vertical slice that runs from Drift to the screen**, enough to prove the offline-first architecture (every action runs from Drift and needs no network, [ADR-013](docs/shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md)) and that Drift migrations work. It is not the full feature set.

### Must

| # | Feature | Done when |
|---|---|---|
| M1 | Create, edit and delete decks | A deck still exists after the app restarts; deleting a deck asks for confirmation and at once permanently cascades to all its cards, without going through the Trash (BR-DECK-022, BR-DECK-023) |
| M2 | Create, edit and delete cards in a deck | A card has a front and a back; editing it does not lose its review history |
| M3 | Study sessions on the SRS schedule | Only due cards are shown; rating a result updates the next review date |
| M4 | Deck list with progress | Each deck shows how many cards are due today |
| M5 | Fully working offline | With airplane mode on, every function above still works normally |

Two independent axes (the SRS algorithm and the StudyMode) and two session kinds: see [`docs/features/study-mode/README.md`](docs/features/study-mode/README.md).

### Should

| # | Feature | Done when |
|---|---|---|
| S1 | Search cards in a deck | In scope: search the front and back text in the open deck, case-insensitive and keeping diacritics. Library-wide search is UC-SEARCH-001 |
| S2 | Basic review statistics | In scope (UC-PROGRESS-001, BR-PROGRESS-009…BR-PROGRESS-018): cards studied today split into Learning and Reviewing, the day streak, and the last seven days of activity. Out of scope: accuracy, longest streak, goal, XP, heatmap and per-deck filtering (BR-PROGRESS-010) |
| S3 | Reverse a card (meaning → term) | In scope (UC-STUDY-003, BR-MODE-013…BR-MODE-019): choose the question direction before the first turn, only for a `self_assess` review session of an `sm2` deck |

### Nice to have

| # | Feature | Notes |
|---|---|---|
| N1 | Import and export | In V8.0 per the [card transfer spec](docs/superpowers/specs/2026-09-26-card-transfer-design.md) (UC-TRANSFER-001, UC-TRANSFER-002, BR-TRANSFER-001…BR-TRANSFER-014): import CSV, TSV, XLSX or pasted text (SCR-TRANSFER-001), export the content (SCR-TRANSFER-002) — not a backup. Backend BE-B3 and UI FE-B3 are done |
| N2 | Daily study reminder | A later sub-project (UC-REMINDER-001, BR-REMINDER-001…BR-REMINDER-012): opt-in, off by default, one digest a day built from the workload due at that moment. The notification permission is asked only **after** the person turns the reminder on (BR-REMINDER-011) |
| N3 | Card tags | A later sub-project (UC-TAG-001, BR-TAG-003…BR-TAG-011): a library-wide catalog, filtering by several tags with OR, renaming with merge, and deleting. Out of scope: tag hierarchies, tag colours, a shared taxonomy |

### Out of scope

| Feature | Why deferred | Revisit when |
|---|---|---|
| Sign-in and accounts | No backend; adding auth now builds UI for something not usable yet | When the Spring Boot backend is ready |
| Multi-device sync | Needs a backend and conflict resolution | Together with auth |
| iOS | Stabilize Android first, so bugs are not fixed on two platforms at once | Once Android is stable in UX, migrations and tests |
| Role-based permissions | Only one kind of user, even after auth | Not planned |
| Sharing decks between users | Needs a backend | After sync |
| Audio and images in cards | Brings file storage, file sync and image compression — a body of work of its own | After the MVP |

**Later decisions.** The tables above are the MVP as it was scoped; work built after V8.0 changed some of it, and the decisions win:

- Deleting a deck or a card moves it to the Trash for 30 days (BR-DECK-022, BR-TRASH-001, BR-TRASH-009); M1's permanent cascade no longer holds.
- The backend is Supabase, not Spring Boot ([ADR-015](docs/shared/decisions/ADR-015-supabase-lam-backend.md)). Sync and sign-in (email code and Google) were built after V8.0 ([`docs/wbs_supabase.md`](docs/wbs_supabase.md); their functions are in [`docs/functional-spec/account.md`](docs/functional-spec/account.md)).
- An admin role exists for the log and users screens ([ADR-018](docs/shared/decisions/ADR-018-log-tap-trung-va-monitoring.md)).

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
