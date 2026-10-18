# Screen and state coverage

Closing acceptance of the ForUI migration, 2026-10-18. Branch `claude/ecstatic-lovelace-s80gci`, from master `aa4d943a`. Companion of [POST_MIGRATION_ACCEPTANCE.md](POST_MIGRATION_ACCEPTANCE.md) and [REGRESSION_FINDINGS.md](REGRESSION_FINDINGS.md).

## How this was built

- **Screen inventory.** Read from the router (`lib/app/router/`), every `*_screen.dart` and the screen detail files in `docs/shared/ui/screen-handoff/`. 37 screen files and 38 `GoRoute`s in one four-branch `StatefulShellRoute` map to 43 detail files (01–41 with 16a, 23a and 23b). Three surfaces had no detail file. Two were given one in this cycle (40, 41). The third, the debug-only gallery, is not shipped.
- **States.** One row per row of each detail file's States tables, after this cycle reconciled every table with its Transitions table, the goldens and the code. A state named in Transitions, drawn by the code or shown by a committed golden now has exactly one States row. The index's state counts equal the tables. The per-screen tables below are generated from the detail files by a script (`gen_coverage.py`, kept with the acceptance working notes), so they match the files at the commit they were run on.
- **Verification method,** in this order:
  - **Golden.** The row cites a committed golden that exists. `run_goldens.sh` passed 615 of 615 on the final tree.
  - **Executed test.** The row cites a widget, controller or integration test that exists in `test/`. It passed in the full suite (`dod_check.sh`).
  - **Via a verified transition.** The state has no citation of its own, but a Transitions row of the same file that is VERIFIED by a cited test enters or leaves it. The match is by state name, so it is a heuristic. Each such state's own row stays readable in its detail file.
  - **Code read only** or **No evidence cited.** Unverified.
- **Not applicable.** The tables list the states that apply to a screen. A state category with no row (for example "empty" on Theme, which always has its three choices) does not apply. The screen's detail file says so where the reason is not obvious.
- **What this does not prove:**
  - Behaviour on an Android device or emulator. None was available (no KVM, no system image).
  - TalkBack. It was not exercised; semantics were checked by widget tests only.
  - Text scales above 1.0. They are outside the product's design target (PRODUCT.md, owner 2026-09-30); see the responsive sweep in the acceptance report.

## Screen inventory

| # | Screen | Detail file | Route / entry (who pushes it) | Exit / Back | Code file |
|---|---|---|---|---|---|
| 01 | Deck list (root level + open deck level, recursive) | 01-deck-list.md | `/decks` (Library tab root; initialLocation) and `/decks/deck/:deckId` (one page per level, `context.push` from a row) | Back pops one level; tab re-tap returns to root; deleting the open deck steps to parent; breadcrumb pops to level (`_openAncestor`) | lib/features/deck/presentation/screens/deck_level_screen.dart (+ widgets/sections/deck_level_*; wired in lib/app/router/app_router.dart `_deckLevel`) |
| 02 | Review algorithm & reset | 02-review-algorithm.md | `/decks/deck/:deckId/algorithm` (in shell, pushed from deck ⋮ "Review algorithm", root decks only) | Back to the deck; breadcrumb ancestors | lib/features/deck/presentation/screens/deck_algorithm_screen.dart |
| 03 | Starter decks | 03-starter-decks.md | `/decks/starter` (root navigator; Library app bar, rootEmpty "Browse starter decks", Study home empty state via `context.go`) | Back pops; Open → `go(/decks/deck/:id)`; "Create a deck" → `pop` + create dialog | lib/features/starter_decks/presentation/screens/starter_library_screen.dart |
| 04 | Library search | 04-library-search.md | `/decks/search[?q=]` (in shell; `context.push` from Library search field; Tags "Find cards" `context.go`) | Back to Library; deck/card rows `push` | lib/features/search/presentation/screens/library_search_screen.dart |
| 05 | Tags | 05-tags.md | `/decks/tags` (root navigator; Library app bar) | Back pops; "Find cards" → `go(/decks/search?q=)` | lib/features/tags/presentation/screens/tags_screen.dart |
| 06 | Trash | 06-trash.md | `/decks/trash` (root navigator; app bar, undo toasts, "gone" states `_openTrash`) | Back pops | lib/features/trash/presentation/screens/trash_screen.dart |
| 07 | Card list (inside an open card-deck level; no own route/screen file) | 07-card-list.md | Rendered by `CardListSectionWidget` inside `/decks/deck/:deckId` when the deck holds cards | as 01; card row `push(/decks/card/:id)`; Back leaves selection first, then the deck | lib/features/card/presentation/widgets/sections/card_list_section_widget.dart |
| 08 | Card create | 08-card-create.md | `/decks/deck/:deckId/cards/new` (in shell; FAB / empty state `push`) | Back/Close asks Discard when dirty; Save keeps form (adds another) | lib/features/card/presentation/screens/card_editor_screen.dart (`CardEditorScreen.create`) |
| 09 | Card edit | 09-card-edit.md | `/decks/card/:cardId/edit` (in shell; detail Edit → `context.push<bool>`) | Back/Cancel asks Discard when dirty; pops true when card gone → detail also pops | lib/features/card/presentation/screens/card_editor_screen.dart (`CardEditorScreen.edit`) |
| 10 | Card detail | 10-card-detail.md | `/decks/card/:cardId` (in shell; list/search row `push`) | Back to list/search as it was | lib/features/card/presentation/screens/card_detail_screen.dart |
| 11 | Card import | 11-card-import.md | `/decks/deck/:deckId/cards/import` (root navigator; deck ⋮ / empty state `push`) | Back steps back one step, closes at step 1; Close/"View cards" → `pop` | lib/features/transfer/presentation/screens/card_import_screen.dart |
| 12 | Card export (bottom sheet, no route) | 12-card-export.md | `showDeckExportSheet` / `showCardExportSheet` from deck ⋮ and the card bulk bar | Close/scrim/Back closes sheet; held while file prepared | lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart |
| 13 | Study home | 13-study-home.md | `/study` (Study tab root) | Tab root; exits via `go` to session, entry, Library, Starter, Sync | lib/features/study/presentation/screens/study_home_screen.dart |
| 14 | Study entry | 14-study-entry.md | `/decks/deck/:deckId/study` (in shell, Library branch; deck "Study this deck" `push`, Study home deck row `go`) | Back to the deck, no session made; Start → `go(/study/session/:id)` | lib/features/study/presentation/screens/study_entry_screen.dart (wired in lib/app/router/study_route_screens.dart) |
| 15 | Study options (per deck) | 15-study-options.md | `/decks/deck/:deckId/options` (root navigator; Study entry app-bar icon `push`) | Back asks Discard when dirty | lib/features/settings/presentation/screens/study_options_screen.dart |
| 16 | Study · Browse (+ shared session route states) | 16-study-browse.md | `/study/session/:sessionId` (top-level route on root navigator, no tab bar; `go` from Study entry / Study home Resume) | ✕ and system Back → exit dialog (Keep going / Stop); Stop → summary on same route; deck gone/stale → `onLeave` toast + `go` | lib/features/study/presentation/screens/study_session_screen.dart + widgets/sections/study_browse_widget.dart |
| 16a | Study · Self-assess | 16a-study-self-assess.md | same route as 16 (stage body) | as 16 | lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart |
| 17 | Study · Match | 17-study-match.md | same route as 16 (stage body) | as 16 | lib/features/study/presentation/widgets/sections/study_match_widget.dart |
| 18 | Study · Guess | 18-study-guess.md | same route as 16 (stage body) | as 16 | lib/features/study/presentation/widgets/sections/study_guess_widget.dart |
| 19 | Study · Recall | 19-study-recall.md | same route as 16 (stage body) | as 16; clock pauses behind exit dialog | lib/features/study/presentation/widgets/sections/study_recall_widget.dart |
| 20 | Study · Fill | 20-study-fill.md | same route as 16 (stage body; only mode with keyboard/IME) | as 16 | lib/features/study/presentation/widgets/sections/study_fill_widget.dart |
| 21 | Session summary | 21-session-summary.md | same route as 16, shown once the session has ended (spec D3) | Done → `go(deck)`; Study this deck → `go(entry)`; system Back = Done | lib/features/study/presentation/widgets/sections/session_summary_widget.dart |
| 22 | Progress (+ deck progress levels) | 22-progress.md | `/progress` (tab root) and `/progress/:deckId` (in shell, `push` per level) | Back climbs one level; "Start studying" → `go(/study)` | lib/features/progress/presentation/screens/progress_screen.dart, deck_progress_screen.dart |
| 23 | Settings hub | 23-settings.md | `/settings` (Settings tab root) | Tab root; rows `push` pages above the shell | lib/features/settings/presentation/screens/settings_screen.dart |
| 23a | Settings · Study options (defaults) | 23a-study-defaults.md | `/settings/study` (root navigator) | Back pops | lib/features/settings/presentation/screens/study_defaults_screen.dart |
| 23b | Settings · Admin (admin only) | 23b-admin.md | `/settings/admin` (root navigator, behind `MonitoringAdminGateWidget`) | Back pops | lib/features/settings/presentation/screens/admin_screen.dart (routes: lib/app/router/admin_routes.dart) |
| 24 | Daily reminder | 24-daily-reminder.md | `/settings/reminder` (root navigator) | Back pops | lib/features/reminders/presentation/screens/reminder_screen.dart |
| 25 | Theme | 25-theme.md | `/settings/theme` (root navigator) | Back pops | lib/features/settings/presentation/screens/theme_screen.dart |
| 26 | Language | 26-language.md | `/settings/language` (root navigator) | Back pops | lib/features/settings/presentation/screens/language_screen.dart |
| 27 | Sync | 27-sync.md | `/settings/sync` (root navigator; Settings row `push`, Study home notice `go`) | Back pops (to Settings) | lib/features/settings/presentation/screens/sync_screen.dart |
| 28 | Monitoring (list + log detail; admin only) | 28-monitoring.md | `/settings/monitoring` and `/settings/monitoring/:logId[?local=1]` (root navigator, admin gate, deep-linkable) | Back climbs one page | lib/features/monitoring/presentation/screens/monitoring_screen.dart, monitoring_detail_screen.dart |
| 29 | Welcome (first launch) | 29-welcome.md | `/welcome[?from=]` top-level; account redirect forces it until answered (`lib/app/router/account_redirect.dart`) | `onDone` → `go(from)`; Email → `go(from)` then `push(sign-in?mode=link&from=)` | lib/features/account/presentation/screens/welcome_screen.dart (route: lib/app/router/account_routes.dart) |
| 30 | Sign-in (+ merge sheet + account transition layer) | 30-sign-in.md | `/settings/sign-in?mode=link\|reauth&from=` (root navigator); transition layer is an app-root overlay | link ends on `/settings/account` or `from`; reauth returns to `from`; redirect closes attach flow on a device with an account | lib/features/account/presentation/screens/sign_in_screen.dart; widgets/sections/account_transition_layer_widget.dart |
| 31 | Sign-in code | 31-code.md | `/settings/sign-in/code?email=&mode=&from=` (push from 30) | Back held while the code is checked; Back to 30 otherwise | lib/features/account/presentation/screens/code_screen.dart |
| 32 | Account | 32-account.md | `/settings/account` (root navigator; redirected to `/settings` on an anonymous device) | Back pops; sign-out lands on Settings | lib/features/account/presentation/screens/account_screen.dart |
| 33 | Users (admin) | 33-users.md | `/settings/users` (root navigator, admin gate) | Back pops | lib/features/account/presentation/screens/users_screen.dart |
| 34 | TOPIK home | 34-topik-home.md | `/study/topik` (in shell, Study branch; Study home Practice card `push`) | Back to Study home | lib/features/topik/presentation/screens/topik_home_screen.dart |
| 35 | TOPIK test list | 35-topik-test-list.md | `/study/topik/:level` (in shell; unknown level → RouteNotFoundScreen) | Back climbs one level | lib/features/topik/presentation/screens/topik_test_list_screen.dart |
| 36 | TOPIK test detail | 36-topik-test-detail.md | `/study/topik/test/:testId` (in shell) | Back climbs; "Back to tests" → `go(/study/topik)` | lib/features/topik/presentation/screens/topik_test_detail_screen.dart |
| 37 | TOPIK attempt | 37-topik-attempt.md | `/study/topik/attempt/:attemptId` (root navigator, full screen) | Close → `pop` or `go(/study/topik)` if opened alone; Submit → `pushReplacement` to 38 | lib/features/topik/presentation/screens/topik_attempt_screen.dart |
| 38 | TOPIK summary | 38-topik-summary.md | `/study/topik/attempt/:attemptId/summary` (root navigator) | Done/Back → test (36); row/"Review answers" → `push` 39 | lib/features/topik/presentation/screens/topik_summary_screen.dart |
| 39 | TOPIK review | 39-topik-review.md | `/study/topik/attempt/:attemptId/review[?q=]` (root navigator) | Back → previous page; "Back to summary" → `go(summary)` | lib/features/topik/presentation/screens/topik_review_screen.dart |
| 40 | Route not found (404) | 40-route-not-found.md | `GoRouter.errorBuilder` (any unknown location or deep link); TOPIK unknown level | "Back to Library" → `go(/decks)` | lib/app/router/route_not_found_screen.dart |
| 41 | Startup failure (database unavailable) | 41-startup-failure.md | `AppRoot` swaps it in for `MemoxApp` on `StartupDatabaseUnavailable` (DEV-195) | Retry re-runs start; Send report queues the log buffer | lib/app/startup_failure_app.dart, lib/app/app_root.dart |
| — | Gallery (debug builds only) | none (a row in 23-settings.md) | `/gallery`, registered only in debug builds | Back pops | lib/app/gallery/gallery_screen.dart; exempt from the audit, not shipped |

Router-level behaviour (not screens): `StatefulShellRoute.indexedStack` with 4 branches (Library `/decks`, Study `/study`, Progress `/progress`, Settings `/settings`), each with its own `LogNavigatorObserver`; tab bar below 600 dp, rail from 600 dp (`AppTabShell`); `initialLocation: /decks`; single redirect `accountRedirect` (Welcome until answered keeping the asked location; attach flow closed when the device holds an account; `/settings/account` closed on an anonymous device); `errorBuilder` → `RouteNotFoundScreen`; reminder notification tap → `_router.go(/study)` (`lib/app/app.dart:154`); Android manifest takes `memox://app` deep links.

## Summary per screen

| Detail file | Screen | States | Golden-backed | Test-backed (own row or a verified transition) | Unverified |
|---|---|---:|---:|---:|---:|
| 01-deck-list.md | 01 · Deck list | 38 | 12 | 26 | 0 |
| 02-review-algorithm.md | 02 · Review algorithm & reset | 17 | 3 | 14 | 0 |
| 03-starter-decks.md | 03 · Starter decks | 11 | 10 | 1 | 0 |
| 04-library-search.md | 04 · Library search | 8 | 6 | 2 | 0 |
| 05-tags.md | 05 · Tags | 13 | 13 | 0 | 0 |
| 06-trash.md | 06 · Trash | 26 | 9 | 17 | 0 |
| 07-card-list.md | 07 · Card list | 29 | 12 | 17 | 0 |
| 08-card-create.md | 08 · Card create | 14 | 3 | 11 | 0 |
| 09-card-edit.md | 09 · Card edit | 16 | 4 | 12 | 0 |
| 10-card-detail.md | 10 · Card detail | 10 | 2 | 8 | 0 |
| 11-card-import.md | 11 · Card import | 26 | 9 | 17 | 0 |
| 12-card-export.md | 12 · Card export | 10 | 3 | 7 | 0 |
| 13-study-home.md | 13 · Study home | 10 | 10 | 0 | 0 |
| 14-study-entry.md | 14 · Study entry | 12 | 10 | 2 | 0 |
| 15-study-options.md | 15 · Study options | 11 | 7 | 4 | 0 |
| 16-study-browse.md | 16 · Study · Browse | 12 | 2 | 10 | 0 |
| 16a-study-self-assess.md | 16a · Study · Self-assess | 7 | 4 | 3 | 0 |
| 17-study-match.md | 17 · Study · Match | 5 | 2 | 3 | 0 |
| 18-study-guess.md | 18 · Study · Guess | 5 | 4 | 1 | 0 |
| 19-study-recall.md | 19 · Study · Recall | 4 | 3 | 1 | 0 |
| 20-study-fill.md | 20 · Study · Fill | 4 | 3 | 1 | 0 |
| 21-session-summary.md | 21 · Session summary | 9 | 9 | 0 | 0 |
| 22-progress.md | 22 · Progress | 13 | 12 | 1 | 0 |
| 23-settings.md | 23 · Settings | 15 | 12 | 3 | 0 |
| 23a-study-defaults.md | 23a · Settings · Study options | 9 | 8 | 1 | 0 |
| 23b-admin.md | 23b · Settings · Admin (admin only) | 2 | 1 | 1 | 0 |
| 24-daily-reminder.md | 24 · Daily reminder | 14 | 12 | 2 | 0 |
| 25-theme.md | 25 · Theme | 5 | 3 | 2 | 0 |
| 26-language.md | 26 · Language | 5 | 3 | 2 | 0 |
| 27-sync.md | 27 · Sync | 14 | 8 | 6 | 0 |
| 28-monitoring.md | 28 · Monitoring | 25 | 10 | 15 | 0 |
| 29-welcome.md | 29 · Welcome | 6 | 2 | 4 | 0 |
| 30-sign-in.md | 30 · Sign-in, the merge sheet and the transition layer | 22 | 14 | 8 | 0 |
| 31-code.md | 31 · Code | 7 | 3 | 4 | 0 |
| 32-account.md | 32 · Account | 12 | 9 | 3 | 0 |
| 33-users.md | 33 · Users (admin) | 14 | 6 | 8 | 0 |
| 34-topik-home.md | 34 · TOPIK home | 6 | 4 | 2 | 0 |
| 35-topik-test-list.md | 35 · TOPIK test list | 7 | 7 | 0 | 0 |
| 36-topik-test-detail.md | 36 · TOPIK test detail | 10 | 9 | 1 | 0 |
| 37-topik-attempt.md | 37 · TOPIK attempt | 19 | 13 | 6 | 0 |
| 38-topik-summary.md | 38 · TOPIK summary | 10 | 10 | 0 | 0 |
| 39-topik-review.md | 39 · TOPIK review | 13 | 9 | 4 | 0 |
| 40-route-not-found.md | 40 · Route not found | 2 | 0 | 2 | 0 |
| 41-startup-failure.md | 41 · Startup failure | 4 | 0 | 4 | 0 |
| **Total** | | **531** | **295** | **236** | **0** |

All 531 states have executed evidence:
- 31 have a golden and a test;
- 264 have a golden only;
- 150 have an executed test cited on their own row;
- 86 are covered through a verified transition.

The 33 states that had no evidence when this cycle began were given tests or citations. That is 23 new tests and 10 existing tests that were not cited. Two of them exposed defects (REG-E9 and the 01 deckLoading row; see [REGRESSION_FINDINGS.md](REGRESSION_FINDINGS.md)).

## States per screen


### 01-deck-list.md — 01 · Deck list

| State | Verification method | Result | Note |
|---|---|---|---|
| rootLoaded | Golden | PASS (goldens 615/615) |  |
| rootInApp | Golden + executed test | PASS (goldens 615/615; suite) |  |
| rootTabletLandscape | Golden + executed test | PASS (goldens 615/615; suite) |  |
| deckTabletPortrait | Golden + executed test | PASS (goldens 615/615; suite) |  |
| rootLoading | Executed test | PASS (suite) |  |
| rootEmpty | Golden | PASS (goldens 615/615) |  |
| rootError | Executed test | PASS (suite) |  |
| rootSearch | Executed test | PASS (suite) |  |
| rootSortFilter | Golden | PASS (goldens 615/615) |  |
| rootDueEmpty | Via a verified transition (test) | PASS (suite, via transition) |  |
| rootOverflow | Golden | PASS (goldens 615/615) |  |
| rootCreate | Via a verified transition (test) | PASS (suite, via transition) |  |
| rootCreateSchedulerMissing | Via a verified transition (test) | PASS (suite, via transition) |  |
| rootCreateDiscard | Via a verified transition (test) | PASS (suite, via transition) |  |
| rootRename | Via a verified transition (test) | PASS (suite, via transition) |  |
| subDeckCreate | Executed test | PASS (suite) |  |
| rootDelete | Golden | PASS (goldens 615/615) |  |
| rootTrashed | Golden | PASS (goldens 615/615) |  |
| deckLoaded | Golden | PASS (goldens 615/615) |  |
| deckEmpty | Golden | PASS (goldens 615/615) |  |
| deckEmptyTopLevel | Executed test | PASS (suite) |  |
| deckEmptyDeepest | Executed test | PASS (suite) |  |
| deckMaxDepth | Executed test | PASS (suite) |  |
| deckLoading | Executed test | PASS (suite) |  |
| deckError | Executed test | PASS (suite) |  |
| deckNotFound | Via a verified transition (test) | PASS (suite, via transition) |  |
| deckOverflow | Via a verified transition (test) | PASS (suite, via transition) |  |
| deckMove | Executed test | PASS (suite) |  |
| deckMoveLoading | Via a verified transition (test) | PASS (suite, via transition) |  |
| deckMoveError | Via a verified transition (test) | PASS (suite, via transition) |  |
| deckMoveEmpty | Executed test | PASS (suite) |  |
| deckDelete | Executed test | PASS (suite) |  |
| deckTrashed | Executed test | PASS (suite) |  |
| deleteSummaryPending | Executed test | PASS (suite) |  |
| deleteSummaryFailed | Executed test | PASS (suite) |  |
| deckActionsGone | Executed test | PASS (suite) |  |
| rootReorder | Golden | PASS (goldens 615/615) |  |
| deckReorder | Executed test | PASS (suite) |  |

### 02-review-algorithm.md — 02 · Review algorithm & reset

| State | Verification method | Result | Note |
|---|---|---|---|
| locked | Golden | PASS (goldens 615/615) |  |
| unlocked | Golden | PASS (goldens 615/615) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| error | Via a verified transition (test) | PASS (suite, via transition) |  |
| gone | Executed test | PASS (suite) |  |
| switchConfirm | Executed test | PASS (suite) |  |
| switching | Via a verified transition (test) | PASS (suite, via transition) |  |
| switched | Via a verified transition (test) | PASS (suite, via transition) |  |
| switchFailed | Executed test | PASS (suite) |  |
| resetConfirm | Golden | PASS (goldens 615/615) |  |
| resetting | Via a verified transition (test) | PASS (suite, via transition) |  |
| resetDone | Via a verified transition (test) | PASS (suite, via transition) |  |
| nothingToLose | Executed test | PASS (suite) |  |
| resetSummaryLoading | Executed test | PASS (suite) |  |
| resetSummaryRejected | Executed test | PASS (suite) |  |
| resetSummaryError | Executed test | PASS (suite) |  |
| resetFailed | Executed test | PASS (suite) |  |

### 03-starter-decks.md — 03 · Starter decks

| State | Verification method | Result | Note |
|---|---|---|---|
| list | Golden | PASS (goldens 615/615) |  |
| choose | Golden | PASS (goldens 615/615) |  |
| adding | Golden | PASS (goldens 615/615) |  |
| added | Golden | PASS (goldens 615/615) |  |
| alreadyPresent | Golden | PASS (goldens 615/615) |  |
| secondCopy | Golden | PASS (goldens 615/615) |  |
| addFailed | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| none | Golden | PASS (goldens 615/615) |  |
| loadFailed | Golden | PASS (goldens 615/615) |  |
| noteDismissed | Executed test | PASS (suite) |  |

### 04-library-search.md — 04 · Library search

| State | Verification method | Result | Note |
|---|---|---|---|
| emptyQuery | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| results | Golden | PASS (goldens 615/615) |  |
| noResults | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |
| loadingMore | Executed test | PASS (suite) |  |
| loadMoreFailed | Golden | PASS (goldens 615/615) |  |
| arrivedWithTerm | Executed test | PASS (suite) |  |

### 05-tags.md — 05 · Tags

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| empty | Golden | PASS (goldens 615/615) |  |
| searchEmpty | Golden | PASS (goldens 615/615) |  |
| sheet | Golden | PASS (goldens 615/615) |  |
| rename | Golden | PASS (goldens 615/615) |  |
| renameMerge | Golden | PASS (goldens 615/615) |  |
| nameTooLong | Golden | PASS (goldens 615/615) |  |
| del | Golden | PASS (goldens 615/615) |  |
| busy | Golden | PASS (goldens 615/615) |  |
| opError | Golden | PASS (goldens 615/615) |  |
| tagGone | Golden | PASS (goldens 615/615) |  |
| read error | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 06-trash.md — 06 · Trash

| State | Verification method | Result | Note |
|---|---|---|---|
| all | Golden | PASS (goldens 615/615) |  |
| cards | Executed test | PASS (suite) |  |
| decks | Via a verified transition (test) | PASS (suite, via transition) |  |
| actions | Golden | PASS (goldens 615/615) |  |
| restoreTarget | Golden + executed test | PASS (goldens 615/615; suite) |  |
| noTarget | Golden | PASS (goldens 615/615) |  |
| restored | Executed test | PASS (suite) |  |
| restoring | Via a verified transition (test) | PASS (suite, via transition) |  |
| restoreTargetsLoading | Via a verified transition (test) | PASS (suite, via transition) |  |
| restoreTargetsError | Via a verified transition (test) | PASS (suite, via transition) |  |
| restoreRefused | Via a verified transition (test) | PASS (suite, via transition) |  |
| undoRefused | Executed test | PASS (suite) |  |
| selection | Golden | PASS (goldens 615/615) |  |
| selectionNone | Executed test | PASS (suite) |  |
| kindLock | Executed test | PASS (suite) |  |
| selectionShrinks | Executed test | PASS (suite) |  |
| selectionEmptied | Executed test | PASS (suite) |  |
| purgeConfirm | Golden | PASS (goldens 615/615) |  |
| purged | Executed test | PASS (suite) |  |
| purging | Executed test | PASS (suite) |  |
| purgeFailed | Executed test | PASS (suite) |  |
| youngerInside | Golden + executed test | PASS (goldens 615/615; suite) |  |
| noteDismissed | Executed test | PASS (suite) |  |
| empty | Golden | PASS (goldens 615/615) |  |
| loading | Executed test | PASS (suite) |  |
| error | Golden | PASS (goldens 615/615) |  |

### 07-card-list.md — 07 · Card list

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| empty | Executed test | PASS (suite) |  |
| filterEmpty | Executed test | PASS (suite) |  |
| searchEmpty | Golden | PASS (goldens 615/615) |  |
| searchResults | Golden | PASS (goldens 615/615) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| error | Executed test | PASS (suite) |  |
| notFound | Via a verified transition (test) | PASS (suite, via transition) |  |
| deckActions | Executed test | PASS (suite) |  |
| selection | Golden | PASS (goldens 615/615) |  |
| moveTargets | Executed test | PASS (suite) |  |
| moveTargetsLoading | Via a verified transition (test) | PASS (suite, via transition) |  |
| moveTargetsError | Via a verified transition (test) | PASS (suite, via transition) |  |
| noMoveTarget | Via a verified transition (test) | PASS (suite, via transition) |  |
| sortSheet | Executed test | PASS (suite) |  |
| flagSheet | Executed test | PASS (suite) |  |
| tagDialog | Executed test | PASS (suite) |  |
| tagFilterLoading | Via a verified transition (test) | PASS (suite, via transition) |  |
| tagFilterError | Executed test | PASS (suite) |  |
| tagFilterNone | Golden + executed test | PASS (goldens 615/615; suite) |  |
| tagFilterOne | Golden + executed test | PASS (goldens 615/615; suite) |  |
| tagFilterSeveral | Golden | PASS (goldens 615/615) |  |
| tagFilterNoTags | Executed test | PASS (suite) |  |
| tagFilterApplied | Golden + executed test | PASS (goldens 615/615; suite) |  |
| tagFilterNoCard | Golden + executed test | PASS (goldens 615/615; suite) |  |
| bulkFailed | Golden | PASS (goldens 615/615) |  |
| delCard | Golden | PASS (goldens 615/615) |  |
| delDeck | Executed test | PASS (suite) |  |
| trashed | Golden | PASS (goldens 615/615) |  |

### 08-card-create.md — 08 · Card create

| State | Verification method | Result | Note |
|---|---|---|---|
| emptyForm | Golden | PASS (goldens 615/615) |  |
| keyboard | Golden + executed test | PASS (goldens 615/615; suite) |  |
| valid | Executed test | PASS (suite) |  |
| details | Via a verified transition (test) | PASS (suite, via transition) |  |
| validationErr | Golden | PASS (goldens 615/615) |  |
| frontTooLong | Via a verified transition (test) | PASS (suite, via transition) |  |
| tagLimit | Via a verified transition (test) | PASS (suite, via transition) |  |
| deckRejects | Via a verified transition (test) | PASS (suite, via transition) |  |
| saving | Via a verified transition (test) | PASS (suite, via transition) |  |
| saveFailed | Executed test | PASS (suite) |  |
| saved | Executed test | PASS (suite) |  |
| pendingTag | Executed test | PASS (suite) |  |
| discardNew | Executed test | PASS (suite) |  |
| deckGone | Via a verified transition (test) | PASS (suite, via transition) |  |

### 09-card-edit.md — 09 · Card edit

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden + executed test | PASS (goldens 615/615; suite) |  |
| dirty | Executed test | PASS (suite) |  |
| more | Golden + executed test | PASS (goldens 615/615; suite) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| loadError | Executed test | PASS (suite) |  |
| notFound | Via a verified transition (test) | PASS (suite, via transition) |  |
| validationErr | Golden + executed test | PASS (goldens 615/615; suite) |  |
| dirtySaving | Via a verified transition (test) | PASS (suite, via transition) |  |
| saveFailed | Executed test | PASS (suite) |  |
| flagToggled | Executed test | PASS (suite) |  |
| missingField | Executed test | PASS (suite) |  |
| pendingTag | Executed test | PASS (suite) |  |
| savedEdit | Via a verified transition (test) | PASS (suite, via transition) |  |
| goneOnSave | Executed test | PASS (suite) |  |
| discard | Via a verified transition (test) | PASS (suite, via transition) |  |
| delConfirm | Golden | PASS (goldens 615/615) |  |

### 10-card-detail.md — 10 · Card detail

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden + executed test | PASS (goldens 615/615; suite) |  |
| history | Golden + executed test | PASS (goldens 615/615; suite) |  |
| historyLoading | Via a verified transition (test) | PASS (suite, via transition) |  |
| historyError | Executed test | PASS (suite) |  |
| loadMore | Executed test | PASS (suite) |  |
| loadMoreFailed | Executed test | PASS (suite) |  |
| empty | Executed test | PASS (suite) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| error | Executed test | PASS (suite) |  |
| notFound | Executed test | PASS (suite) |  |

### 11-card-import.md — 11 · Card import

| State | Verification method | Result | Note |
|---|---|---|---|
| empty (Source) | Golden | PASS (goldens 615/615) |  |
| pasted | Via a verified transition (test) | PASS (suite, via transition) |  |
| fileSelected | Via a verified transition (test) | PASS (suite, via transition) |  |
| badEncoding | Via a verified transition (test) | PASS (suite, via transition) |  |
| emptySheet | Via a verified transition (test) | PASS (suite, via transition) |  |
| parsing | Via a verified transition (test) | PASS (suite, via transition) |  |
| mapping | Golden | PASS (goldens 615/615) |  |
| mappingNoHeader | Golden | PASS (goldens 615/615) |  |
| mappingIncomplete | Via a verified transition (test) | PASS (suite, via transition) |  |
| previewAll | Via a verified transition (test) | PASS (suite, via transition) |  |
| previewMix | Golden | PASS (goldens 615/615) |  |
| importing | Via a verified transition (test) | PASS (suite, via transition) |  |
| success | Via a verified transition (test) | PASS (suite, via transition) |  |
| partial | Golden | PASS (goldens 615/615) |  |
| sectionsUndecided | Golden | PASS (goldens 615/615) |  |
| sectionsDecided | Golden | PASS (goldens 615/615) |  |
| sectionsChooseAll | Golden | PASS (goldens 615/615) |  |
| sectionsResult | Golden | PASS (goldens 615/615) |  |
| sectionsRefused | Executed test | PASS (suite) |  |
| sectionTargetChanged | Executed test | PASS (suite) |  |
| none | Via a verified transition (test) | PASS (suite, via transition) |  |
| failed | Executed test | PASS (suite) |  |
| rejects | Executed test | PASS (suite) |  |
| pickerCancelled | Executed test | PASS (suite) |  |
| unsupportedFile | Executed test | PASS (suite) |  |
| previewRefused | Executed test | PASS (suite) |  |

### 12-card-export.md — 12 · Card export

| State | Verification method | Result | Note |
|---|---|---|---|
| wholeDeck | Golden + executed test | PASS (goldens 615/615; suite) |  |
| selection | Executed test | PASS (suite) |  |
| countFailed | Via a verified transition (test) | PASS (suite, via transition) |  |
| preparing | Executed test | PASS (suite) |  |
| handedOver | Executed test | PASS (suite) |  |
| shareClosed | Executed test | PASS (suite) |  |
| failed | Golden + executed test | PASS (goldens 615/615; suite) |  |
| noShareTarget | Executed test | PASS (suite) |  |
| staleSelection | Golden + executed test | PASS (goldens 615/615; suite) |  |
| nothingToExport | Executed test | PASS (suite) |  |

### 13-study-home.md — 13 · Study home

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| noResume | Golden | PASS (goldens 615/615) |  |
| zero | Golden | PASS (goldens 615/615) |  |
| noDecks | Golden | PASS (goldens 615/615) |  |
| noCards | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |
| syncRejected | Golden | PASS (goldens 615/615) |  |
| syncStale | Golden | PASS (goldens 615/615) |  |
| reauth | Golden | PASS (goldens 615/615) |  |

### 14-study-entry.md — 14 · Study entry

| State | Verification method | Result | Note |
|---|---|---|---|
| sm2 | Golden | PASS (goldens 615/615) |  |
| eightBox | Golden | PASS (goldens 615/615) |  |
| onlyNew | Golden | PASS (goldens 615/615) |  |
| nothing | Golden | PASS (goldens 615/615) |  |
| resume | Golden | PASS (goldens 615/615) |  |
| directionSheet | Golden + executed test | PASS (goldens 615/615; suite) |  |
| starting | Golden | PASS (goldens 615/615) |  |
| refused | Golden | PASS (goldens 615/615) |  |
| startFailed | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Executed test | PASS (suite) |  |
| deckGone | Executed test | PASS (suite) |  |

### 15-study-options.md — 15 · Study options

| State | Verification method | Result | Note |
|---|---|---|---|
| override | Golden | PASS (goldens 615/615) |  |
| defaults | Golden | PASS (goldens 615/615) |  |
| invalid | Golden | PASS (goldens 615/615) |  |
| saving | Golden | PASS (goldens 615/615) |  |
| saved | Golden | PASS (goldens 615/615) |  |
| saveFailed | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| unreadableOverride | Executed test | PASS (suite) |  |
| gone | Executed test | PASS (suite) |  |
| read error | Executed test | PASS (suite) |  |
| discardAsk | Executed test | PASS (suite) |  |

### 16-study-browse.md — 16 · Study · Browse

| State | Verification method | Result | Note |
|---|---|---|---|
| sessionLoading | Via a verified transition (test) | PASS (suite, via transition) |  |
| sessionReadError | Executed test | PASS (suite) |  |
| unsavedAnswer | Executed test | PASS (suite) |  |
| heldTurn | Executed test | PASS (suite) |  |
| stalledRound | Executed test | PASS (suite) |  |
| exitDialog | Executed test | PASS (suite) |  |
| deckGone | Executed test | PASS (suite) |  |
| stopFailed | Executed test | PASS (suite) |  |
| staleGeneration | Executed test | PASS (suite) |  |
| summary | Executed test | PASS (suite) |  |
| default | Golden | PASS (goldens 615/615) |  |
| lookingBack | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 16a-study-self-assess.md — 16a · Study · Self-assess

| State | Verification method | Result | Note |
|---|---|---|---|
| prompt | Golden | PASS (goldens 615/615) |  |
| meaningFirst | Golden + executed test | PASS (goldens 615/615; suite) |  |
| revealed | Golden | PASS (goldens 615/615) |  |
| relearning | Golden | PASS (goldens 615/615) |  |
| saving | Via a verified transition (test) | PASS (suite, via transition) |  |
| saveFailed | Executed test | PASS (suite) |  |
| stale | Via a verified transition (test) | PASS (suite, via transition) |  |

### 17-study-match.md — 17 · Study · Match

| State | Verification method | Result | Note |
|---|---|---|---|
| default | Golden | PASS (goldens 615/615) |  |
| selected | Executed test | PASS (suite) |  |
| answering | Via a verified transition (test) | PASS (suite, via transition) |  |
| matched | Executed test | PASS (suite) |  |
| wrong flash | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 18-study-guess.md — 18 · Study · Guess

| State | Verification method | Result | Note |
|---|---|---|---|
| default | Golden | PASS (goldens 615/615) |  |
| answering | Via a verified transition (test) | PASS (suite, via transition) |  |
| right | Golden + executed test | PASS (goldens 615/615; suite) |  |
| wrong | Golden + executed test | PASS (goldens 615/615; suite) |  |
| blocked | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 19-study-recall.md — 19 · Study · Recall

| State | Verification method | Result | Note |
|---|---|---|---|
| countingDown | Golden | PASS (goldens 615/615) |  |
| revealed | Golden | PASS (goldens 615/615) |  |
| timedOut | Golden | PASS (goldens 615/615) |  |
| answered | Executed test | PASS (suite) |  |

### 20-study-fill.md — 20 · Study · Fill

| State | Verification method | Result | Note |
|---|---|---|---|
| input | Golden | PASS (goldens 615/615) |  |
| hint | Golden | PASS (goldens 615/615) |  |
| answering | Executed test | PASS (suite) |  |
| wrong | Golden | PASS (goldens 615/615) |  |

### 21-session-summary.md — 21 · Session summary

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| learning | Golden | PASS (goldens 615/615) |  |
| large | Golden | PASS (goldens 615/615) |  |
| leftEarly | Golden | PASS (goldens 615/615) |  |
| interrupted | Golden | PASS (goldens 615/615) |  |
| reset | Golden | PASS (goldens 615/615) |  |
| schedulerChanged | Golden | PASS (goldens 615/615) |  |
| saveError | Golden | PASS (goldens 615/615) |  |
| contentDeleted | Golden | PASS (goldens 615/615) |  |

### 22-progress.md — 22 · Progress

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| month | Golden | PASS (goldens 615/615) |  |
| held | Golden | PASS (goldens 615/615) |  |
| lost | Golden | PASS (goldens 615/615) |  |
| deck | Golden | PASS (goldens 615/615) |  |
| never | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |
| deck error | Executed test | PASS (suite) |  |
| quiet range | Golden | PASS (goldens 615/615) |  |
| no decks | Golden | PASS (goldens 615/615) |  |
| no sub-decks | Golden | PASS (goldens 615/615) |  |
| deck gone | Golden | PASS (goldens 615/615) |  |

### 23-settings.md — 23 · Settings

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| admin row | Golden | PASS (goldens 615/615) |  |
| resetConfirm | Golden | PASS (goldens 615/615) |  |
| resetDone | Golden | PASS (goldens 615/615) |  |
| resetting | Via a verified transition (test) | PASS (suite, via transition) |  |
| resetFailed | Via a verified transition (test) | PASS (suite, via transition) |  |
| syncSynced | Golden | PASS (goldens 615/615) |  |
| syncFailed | Golden | PASS (goldens 615/615) |  |
| syncRejected | Golden | PASS (goldens 615/615) |  |
| account | Golden | PASS (goldens 615/615) |  |
| account, signed in | Golden | PASS (goldens 615/615) |  |
| account, re-auth | Golden | PASS (goldens 615/615) |  |
| read error | Via a verified transition (test) | PASS (suite, via transition) |  |
| gallery (debug build) | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 23a-study-defaults.md — 23a · Settings · Study options

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| saving | Golden | PASS (goldens 615/615) |  |
| saved | Golden | PASS (goldens 615/615) |  |
| invalidLimit | Golden | PASS (goldens 615/615) |  |
| saveFailed | Golden | PASS (goldens 615/615) |  |
| new-card order sheet | Golden | PASS (goldens 615/615) |  |
| speech language sheet | Golden | PASS (goldens 615/615) |  |
| read error | Via a verified transition (test) | PASS (suite, via transition) |  |

### 23b-admin.md — 23b · Settings · Admin (admin only)

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| gate | Via a verified transition (test) | PASS (suite, via transition) |  |

### 24-daily-reminder.md — 24 · Daily reminder

| State | Verification method | Result | Note |
|---|---|---|---|
| off | Golden | PASS (goldens 615/615) |  |
| turningOn | Golden | PASS (goldens 615/615) |  |
| on | Golden | PASS (goldens 615/615) |  |
| previewDue | Golden | PASS (goldens 615/615) |  |
| changingTime | Golden | PASS (goldens 615/615) |  |
| permDenied | Golden | PASS (goldens 615/615) |  |
| couldNotSchedule | Golden | PASS (goldens 615/615) |  |
| offMayShow | Golden | PASS (goldens 615/615) |  |
| couldNotChangeTime | Executed test | PASS (suite) |  |
| savingTime | Via a verified transition (test) | PASS (suite, via transition) |  |
| turningOff | Golden | PASS (goldens 615/615) |  |
| unavailable | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| read error | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 25-theme.md — 25 · Theme

| State | Verification method | Result | Note |
|---|---|---|---|
| system | Golden | PASS (goldens 615/615) |  |
| light | Golden | PASS (goldens 615/615) |  |
| dark | Golden | PASS (goldens 615/615) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| read error | Via a verified transition (test) | PASS (suite, via transition) |  |

### 26-language.md — 26 · Language

| State | Verification method | Result | Note |
|---|---|---|---|
| english | Golden | PASS (goldens 615/615) |  |
| vietnamese | Golden | PASS (goldens 615/615) |  |
| system | Golden | PASS (goldens 615/615) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| read error | Via a verified transition (test) | PASS (suite, via transition) |  |

### 27-sync.md — 27 · Sync

| State | Verification method | Result | Note |
|---|---|---|---|
| synced | Golden | PASS (goldens 615/615) |  |
| neverSynced | Golden | PASS (goldens 615/615) |  |
| pending | Golden | PASS (goldens 615/615) |  |
| failedNetwork | Golden | PASS (goldens 615/615) |  |
| failedServer | Golden | PASS (goldens 615/615) |  |
| rejected | Golden | PASS (goldens 615/615) |  |
| keepDialog | Golden | PASS (goldens 615/615) |  |
| syncing | Golden | PASS (goldens 615/615) |  |
| retrying | Via a verified transition (test) | PASS (suite, via transition) |  |
| keeping | Via a verified transition (test) | PASS (suite, via transition) |  |
| change failed | Executed test | PASS (suite) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| read error | Via a verified transition (test) | PASS (suite, via transition) |  |
| unavailable | Executed test | PASS (suite) |  |

### 28-monitoring.md — 28 · Monitoring

| State | Verification method | Result | Note |
|---|---|---|---|
| list, loaded | Golden | PASS (goldens 615/615) |  |
| list, every level | Golden | PASS (goldens 615/615) |  |
| list, empty | Golden | PASS (goldens 615/615) |  |
| list, offline | Golden | PASS (goldens 615/615) |  |
| Not sent | Golden | PASS (goldens 615/615) |  |
| Level sheet | Golden | PASS (goldens 615/615) |  |
| detail, open error | Golden | PASS (goldens 615/615) |  |
| detail, scrolled to the end | Golden | PASS (goldens 615/615) |  |
| detail, fixed with a note | Golden | PASS (goldens 615/615) |  |
| detail, a row of the buffer | Golden | PASS (goldens 615/615) |  |
| list, refresh failed | Executed test | PASS (suite) |  |
| list, loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| list, loading more | Via a verified transition (test) | PASS (suite, via transition) |  |
| list, load more failed | Executed test | PASS (suite) |  |
| list, end | Executed test | PASS (suite) |  |
| Not sent, loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| Not sent, error | Via a verified transition (test) | PASS (suite, via transition) |  |
| Not sent, empty | Executed test | PASS (suite) |  |
| detail, changing | Via a verified transition (test) | PASS (suite, via transition) |  |
| status sheet | Executed test | PASS (suite) |  |
| detail, change failed | Via a verified transition (test) | PASS (suite, via transition) |  |
| list, no match | Via a verified transition (test) | PASS (suite, via transition) |  |
| list, error | Executed test | PASS (suite) |  |
| list, not an admin | Executed test | PASS (suite) |  |
| detail, loading / error / offline / gone | Executed test | PASS (suite) |  |

### 29-welcome.md — 29 · Welcome

| State | Verification method | Result | Note |
|---|---|---|---|
| ready | Golden | PASS (goldens 615/615) |  |
| starting | Executed test | PASS (suite) |  |
| offline | Golden | PASS (goldens 615/615) |  |
| Google running | Executed test | PASS (suite) |  |
| Google failed | Via a verified transition (test) | PASS (suite, via transition) |  |
| identity taken | Executed test | PASS (suite) |  |

### 30-sign-in.md — 30 · Sign-in, the merge sheet and the transition layer

| State | Verification method | Result | Note |
|---|---|---|---|
| link | Golden | PASS (goldens 615/615) |  |
| invalid | Golden | PASS (goldens 615/615) |  |
| merge sheet, merge | Golden | PASS (goldens 615/615) |  |
| merge sheet, discard | Golden | PASS (goldens 615/615) |  |
| layer, sending | Golden | PASS (goldens 615/615) |  |
| layer, merging | Golden | PASS (goldens 615/615) |  |
| layer, offline | Golden | PASS (goldens 615/615) |  |
| layer, target sign-in | Golden | PASS (goldens 615/615) |  |
| layer, sign-out offline | Golden | PASS (goldens 615/615) |  |
| reauth | Golden | PASS (goldens 615/615) |  |
| reauth, unsent loss | Golden | PASS (goldens 615/615) |  |
| reauth, continue without | Golden | PASS (goldens 615/615) |  |
| layer, stuck | Golden | PASS (goldens 615/615) |  |
| ready | Executed test | PASS (suite) |  |
| sending | Via a verified transition (test) | PASS (suite, via transition) |  |
| Google running | Executed test | PASS (suite) |  |
| problem under the field | Executed test | PASS (suite) |  |
| waiting | Executed test | PASS (suite) |  |
| layer, merge stopped on refused changes | Executed test | PASS (suite) |  |
| way-out running | Executed test | PASS (suite) |  |
| layer, running | Golden + executed test | PASS (goldens 615/615; suite) |  |
| layer, error | Executed test | PASS (suite) |  |

### 31-code.md — 31 · Code

| State | Verification method | Result | Note |
|---|---|---|---|
| waiting | Golden | PASS (goldens 615/615) |  |
| wrong | Golden | PASS (goldens 615/615) |  |
| verifying | Via a verified transition (test) | PASS (suite, via transition) |  |
| resend ready | Executed test | PASS (suite) |  |
| resending | Executed test | PASS (suite) |  |
| resend failed | Executed test | PASS (suite) |  |
| resend loss dialog | Golden + executed test | PASS (goldens 615/615; suite) |  |

### 32-account.md — 32 · Account

| State | Verification method | Result | Note |
|---|---|---|---|
| ready | Golden | PASS (goldens 615/615) |  |
| validating | Golden | PASS (goldens 615/615) |  |
| reauth | Golden | PASS (goldens 615/615) |  |
| switch dialog | Golden | PASS (goldens 615/615) |  |
| sign-out dialog | Golden | PASS (goldens 615/615) |  |
| sign-out, loss | Golden | PASS (goldens 615/615) |  |
| delete dialog | Golden | PASS (goldens 615/615) |  |
| delete, offline | Golden | PASS (goldens 615/615) |  |
| last admin | Golden | PASS (goldens 615/615) |  |
| command running | Executed test | PASS (suite) |  |
| transitioning | Executed test | PASS (suite) |  |
| command refused | Executed test | PASS (suite) |  |

### 33-users.md — 33 · Users (admin)

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| no match | Golden | PASS (goldens 615/615) |  |
| offline | Golden | PASS (goldens 615/615) |  |
| role sheet | Golden | PASS (goldens 615/615) |  |
| role sheet, changed | Golden | PASS (goldens 615/615) |  |
| role sheet, refused | Golden | PASS (goldens 615/615) |  |
| loading | Via a verified transition (test) | PASS (suite, via transition) |  |
| loading more | Via a verified transition (test) | PASS (suite, via transition) |  |
| load more failed | Executed test | PASS (suite) |  |
| end | Executed test | PASS (suite) |  |
| role sheet, saving | Executed test | PASS (suite) |  |
| no accounts | Via a verified transition (test) | PASS (suite, via transition) |  |
| error | Via a verified transition (test) | PASS (suite, via transition) |  |
| not an admin | Via a verified transition (test) | PASS (suite, via transition) |  |

### 34-topik-home.md — 34 · TOPIK home

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| noTests | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |
| retrying | Executed test | PASS (suite) |  |
| error after data | Executed test | PASS (suite) |  |

### 35-topik-test-list.md — 35 · TOPIK test list

| State | Verification method | Result | Note |
|---|---|---|---|
| reading | Golden | PASS (goldens 615/615) |  |
| listening | Golden | PASS (goldens 615/615) |  |
| withStatus | Golden | PASS (goldens 615/615) |  |
| sortSheet | Golden | PASS (goldens 615/615) |  |
| empty | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |

### 36-topik-test-detail.md — 36 · TOPIK test detail

| State | Verification method | Result | Note |
|---|---|---|---|
| overview | Golden | PASS (goldens 615/615) |  |
| overviewEmpty | Golden | PASS (goldens 615/615) |  |
| history | Golden | PASS (goldens 615/615) |  |
| historyEmpty | Golden | PASS (goldens 615/615) |  |
| deleteConfirm | Golden | PASS (goldens 615/615) |  |
| continueOrNew | Golden | PASS (goldens 615/615) |  |
| startNewConfirm | Via a verified transition (test) | PASS (suite, via transition) |  |
| testMissing | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |

### 37-topik-attempt.md — 37 · TOPIK attempt

| State | Verification method | Result | Note |
|---|---|---|---|
| answering | Golden | PASS (goldens 615/615) |  |
| answeringListening | Golden | PASS (goldens 615/615) |  |
| scriptShown | Golden | PASS (goldens 615/615) |  |
| collapsed | Golden | PASS (goldens 615/615) |  |
| grid | Golden | PASS (goldens 615/615) |  |
| submitConfirm | Golden | PASS (goldens 615/615) |  |
| submitting | Golden | PASS (goldens 615/615) |  |
| speedSheet | Executed test | PASS (suite) |  |
| audioLoading | Executed test | PASS (suite) |  |
| audioPlaying | Executed test | PASS (suite) |  |
| collapsedListening | Executed test | PASS (suite) |  |
| pictureGroup | Executed test | PASS (suite) |  |
| deleteConfirm | Executed test | PASS (suite) |  |
| audioError | Golden | PASS (goldens 615/615) |  |
| attemptMissing | Golden | PASS (goldens 615/615) |  |
| contentMissing | Golden | PASS (goldens 615/615) |  |
| submitted | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |

### 38-topik-summary.md — 38 · TOPIK summary

| State | Verification method | Result | Note |
|---|---|---|---|
| loaded | Golden | PASS (goldens 615/615) |  |
| loaded, chart in view | Golden | PASS (goldens 615/615) |  |
| perfect | Golden | PASS (goldens 615/615) |  |
| zero | Golden | PASS (goldens 615/615) |  |
| topik1Reading | Golden | PASS (goldens 615/615) |  |
| correctHidden | Golden | PASS (goldens 615/615) |  |
| filterEmpty | Golden | PASS (goldens 615/615) |  |
| attemptMissing | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |

### 39-topik-review.md — 39 · TOPIK review

| State | Verification method | Result | Note |
|---|---|---|---|
| wrong | Golden | PASS (goldens 615/615) |  |
| correct | Golden | PASS (goldens 615/615) |  |
| unanswered | Golden | PASS (goldens 615/615) |  |
| listening | Golden | PASS (goldens 615/615) |  |
| contentUpdated | Golden | PASS (goldens 615/615) |  |
| contentMissing | Golden + executed test | PASS (goldens 615/615; suite) |  |
| attemptMissing | Golden | PASS (goldens 615/615) |  |
| loading | Golden | PASS (goldens 615/615) |  |
| error | Golden | PASS (goldens 615/615) |  |
| lastQuestion | Executed test | PASS (suite) |  |
| groupCollapsed / scriptHidden | Executed test | PASS (suite) |  |
| audioFailed / audioLoading / speedSheet | Executed test | PASS (suite) |  |
| pictureOption | Executed test | PASS (suite) |  |

### 40-route-not-found.md — 40 · Route not found

| State | Verification method | Result | Note |
|---|---|---|---|
| notFound | Executed test | PASS (suite) |  |
| shortWindow | Executed test | PASS (suite) |  |

### 41-startup-failure.md — 41 · Startup failure

| State | Verification method | Result | Note |
|---|---|---|---|
| failed | Executed test | PASS (suite) |  |
| migrationStopped | Executed test | PASS (suite) |  |
| retrying | Via a verified transition (test) | PASS (suite, via transition) |  |
| reportQueued | Executed test | PASS (suite) |  |

