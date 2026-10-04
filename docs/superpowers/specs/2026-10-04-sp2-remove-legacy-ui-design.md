# SP2 — Remove the legacy UI

Status: draft for owner review · Date: 2026-10-04 · Branch: `ccr-841d461f-jofe0s` (from
`master` at `ac57dc4`, PR #196 merged)

Sub-project 2 of the UI rebuild. Sub-project 1 (PR #196) moved every piece of UI knowledge into
the canonical documents. This sub-project removes the old UI implementation so the rebuild
starts from a clean slate. It builds nothing new beyond a temporary placeholder shell.

## 1. Context and decomposition

The owner split the rebuild on 2026-10-04 into four sub-projects. Each one has its own spec,
review, plan, implementation, verification and sign-off. No plan spans two of them, and no
two of them share a branch.

| Sub-project | Scope |
|---|---|
| **SP2 — Remove legacy UI** (this spec) | Classify, then delete the old UI, `Mx*`, theme, UI tests and the 526 goldens. A placeholder shell keeps the app building and the gate green. |
| SP3a — Design-system foundation | DESIGN.md (45 M3 roles, the mapping table) → tokens → theme → primitives → `Mx*`. |
| SP3b — App shell + SCR-DECK-001 | The shell from NAVIGATION.md, then one vertical slice, audited by Impeccable, with goldens. |
| SP3c — The other 33 screens | Built in batches by domain, once SP3b is signed off. |

**Canonical sources**, in order: PRODUCT → UC → FN → BR → screen spec and NAVIGATION →
DESIGN.md → new code. The legacy UI is not a source for anything. Impeccable is a tool, not a
source.

## 2. Owner rulings (2026-10-04)

- **S1 — Clean slate.** The old UI is not refactored, restyled or reused. The scope is
  option 3: feature presentation, the `Mx*` implementations, `lib/shared/widgets/`,
  `lib/core/theme/`, the legacy UI tests and every legacy golden all go. `Mx*` survives only as
  a naming contract for SP3a.
- **S2 — Kept.** Domain, entities, BRs, use cases, repositories, data, database, sync, auth,
  account and session behaviour, background jobs, notifications, bootstrap and startup,
  lifecycle, DI, persistence, navigation contracts, other non-UI infrastructure, and the
  canonical documents.
- **S3 — Classify, never delete by folder.** No step deletes `presentation/**` wholesale.
  - Every file is first classified UI, non-UI or infrastructure.
  - The classification is recorded in a migration matrix (§4), and the owner reviews it
    before any deletion.
  - State or a controller that exists because of a screen is deleted. One still needed with no
    screen is kept or moved.
- **S4 — End state.** The app compiles, builds and passes the full gate. A temporary four-tab
  placeholder shell replaces the UI. None of the following remain: legacy feature UI, legacy
  `Mx*`, legacy ThemeData, legacy UI tests, legacy goldens.
- **S5 — ARB kept.** `app_en.arb` and `app_vi.arb` are language data, not visual
  implementation. The Vietnamese translations exist nowhere else. Unused keys are pruned in
  SP3, screen by screen.
- **S6 — Integration tests.** `integration_test/` drives the old UI and is deleted. The
  scenario catalogue in the docs stays as the target SP3 writes against.
- **S7 — Recovery tag.** Before any golden is deleted, the tag `legacy-ui-v8-goldens` exists on
  GitHub on `ac57dc4`, the last commit with the 526 goldens. The owner pushes it, because the
  session's git proxy refuses tag pushes.
- **S8 — DESIGN.md is canonical.** DESIGN.md stops describing itself as generated from, or
  reflecting, the code. Code implements DESIGN.md; DESIGN.md is never derived from code.
- **S9 — SP2 builds nothing.** No design system, theme, `Mx*`, `SCR-*` screen or new golden.

## 3. Scope

**In:**

- the migration matrix;
- deleting what it classifies UI;
- moving what it classifies non-UI but misplaced;
- the placeholder shell and a minimal router;
- deleting UI tests, `integration_test/` and all goldens;
- fixing tooling, guard rules, hooks and documents that name deleted paths;
- the DESIGN.md wording (S8);
- WBS rows for SP2 and SP3.

**Out:**

- anything SP3a, SP3b or SP3c builds;
- any change to `domain/` or `data/` behaviour, BR content or Supabase;
- pruning ARB keys;
- rewriting the IT scenario catalogue;
- rewriting the `flutter-design-system` and `flutter-theme-design` skills. They describe the
  component contract SP3a rebuilds; SP2 only fixes paths in them that would break a tool.

## 4. Migration matrix

The plan's first task produces `docs/superpowers/plans/<date>-sp2-remove-legacy-ui-matrix.md`.
It has one row per file under:

- `lib/features/*/presentation/`, `lib/app/`, `lib/shared/widgets/`, `lib/core/theme/`, `lib/l10n/`;
- `test/features/*/presentation/`, `test/shared/`, `test/core/theme/`, `test/app/`,
  `test/visual_audit/`;
- `integration_test/`;
- every `test/**/goldens/*.png` (grouped by folder).

Each row has this shape:

| Source | Classification | Outcome | Target | Reason |
|---|---|---|---|---|
| `lib/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart` | infrastructure | keep | — | `app.dart` runs the purge at start and resume |
| `lib/features/deck/presentation/screens/deck_level_screen.dart` | UI | delete | — | a screen |

### 4.1 Classification rules

1. **UI → delete.** This covers:
   - screens, widgets (sections, items, overlays, support), app bars, FABs, dialogs, sheets;
   - presentation states and controllers that serve a screen;
   - providers whose only consumers are UI files;
   - `lib/shared/widgets/` and `lib/core/theme/`;
   - the gallery, the old shell, the route-not-found screen;
   - the account transition-layer host widget. The coordinator behind it is in `lib/core/auth/`
     and stays.
2. **Infrastructure → keep in place.** This covers:
   - every use-case provider (`*_use_case_provider.dart`, 79 files today). ADR-011 places
     use-case providers in `presentation/providers/`, and they are DI, not UI.
   - every provider that a non-UI file uses, or that would still be needed with no screen.
     Found today: `app_settings_provider`, `welcome_due_provider`, `device_account_provider`,
     `is_welcome_seen_use_case_provider`, `reconcile_reminder_provider`,
     `deliver_reminder_use_case_provider`, `purge_expired_trash_use_case_provider`,
     `abandon_stale_sessions_use_case_provider`.
   - the transitive non-UI dependencies of the above;
   - `AppRoutes` (the route contract);
   - `account_redirect.dart` (the guard);
   - `startup_*.dart`, `logging_bootstrap.dart`, `font_license.dart`;
   - the lifecycle work in `app.dart`: stale sessions, Trash purge, reminder reconcile and taps,
     log upload, the account redirect inputs;
   - `lib/l10n/` (S5) and `failure_message.dart`.
3. **Non-UI misplaced → move.** This means non-UI logic that is not a provider and lives inside
   a UI file, for example orchestration inside a controller or a widget's `initState`.
   - It moves to the layer that owns it: `domain/usecases/` for business steps, a feature
     `di/` provider, or `lib/app/` for app orchestration. The matrix names the target.
   - None is known yet. The matrix task searches for it, and each move is a ruling the owner
     sees in the matrix review.
4. **Tests follow their subject.** A test of a deleted file is deleted. A test of a kept file
   is kept unchanged. A test that mixes the two is split, and the kept half stays.
5. **When in doubt, keep** and mark the row `review`. The matrix review decides it.

Placement ruling: a kept provider stays in `presentation/providers/`, ADR-011's home for
providers. Moving it to `di/` would contradict ADR-011 and widen this sub-project. A
non-provider move follows ADR-011's buckets.

## 5. End state

### 5.1 What remains

- `domain/`, `data/` and `di/` of every feature, unchanged.
- `presentation/providers/`, holding only the kept providers. No `screens/`, `widgets/`,
  `controllers/` or `states/` folder remains, unless the matrix keeps a state class that a kept
  provider needs.
- `lib/core/` without `theme/`, and `lib/shared/` without `widgets/`.
- `lib/l10n/`.
- `lib/app/` with:
  - `app.dart`, its lifecycle work unchanged;
  - `AppRoutes` and `account_redirect.dart`;
  - a minimal router;
  - the placeholder shell.

### 5.2 Placeholder shell and router

- **Tabs.** A `StatefulShellRoute` with four tabs, in NAVIGATION.md's order: Library
  (`/decks`) · Study (`/study`) · Progress (`/progress`) · Settings (`/settings`).
  - The owner's examples listed "Search" as the third tab. NAVIGATION.md, which outranks them,
    lists Progress, so the shell follows NAVIGATION.md. **Owner to confirm at review.**
- **Route contract.**
  - Every route path in SCREEN_CATALOG.md stays registered and points to one generic
    placeholder page. The page shows the route's SCR id and "Being rebuilt".
  - Deep links, the notification tap (`/study`) and the account redirect therefore keep
    working.
  - An unknown location shows the same placeholder with a way to the Library.
- **Welcome.** On a build that can sign in, the Welcome redirect would trap every launch on a
  placeholder. The `/welcome` placeholder therefore keeps one plain action, "Continue". It
  applies FN-ACCOUNT-001 (marks Welcome answered) and goes to `from`, so startup behaviour is
  unchanged. This is the only control the placeholders carry.
- **Visual.**
  - Plain Material widgets.
  - `ThemeData(useMaterial3: true)` with Flutter's default light and dark schemes, following
    the stored theme mode.
  - No tokens, no raw colours, no copy beyond the SCR id, the tab labels and "Continue". Tab
    labels and the placeholder line come from the existing ARB keys where one exists.
  - The shell and pages live in `lib/app/placeholder/`. SP3b deletes that folder when it
    builds the shell.
- **Transition layer.** No UI shows the account transition layer. A transition restored at
  start still runs through the coordinator, and no screen can start one.

### 5.3 Tests and goldens

- **Deleted:**
  - every test whose subject is deleted;
  - `test/visual_audit/`, `test/shared/` (widget tests), `test/core/theme/`;
  - the UI tests of `test/app/`;
  - `integration_test/`;
  - all 526 `test/**/goldens/*.png` and their golden tests, after S7.
- **Kept, and pass unchanged:** domain, data, `di/`, kept-provider and non-UI `test/app/` tests
  (startup settings, startup Welcome, lifecycle logging, the account redirect).
- **Added:** a smoke test that the placeholder app starts, shows the four tabs, and resolves
  every catalog route without an error. With no `scr_*` golden yet, docs tooling raises no
  orphan.

## 6. Tooling, guard, hooks and documents

- **Guard (`code-verification-guard-v2`, `memox-v8` ruleset).**
  - A rule that names a deleted path is updated so it neither errors nor goes vacuous by
    accident.
  - A rule whose subjects are all gone is kept as written: it guards the rebuild.
  - No rule is weakened while its subjects exist.
  - The plan lists each rule touched with the reason.
- **`check_architecture.sh` and `dod_check.sh`.** Adjust only what names deleted paths. The
  gate keeps every step.
- **Hooks.** `check_design_tokens.py` and the Impeccable hook stay; they act on the rebuild.
- **`tools/docs`.** `check.py` adds a guard against legacy UI paths reappearing:
  - an old-named golden (any `test/**/goldens/*.png` without the `scr_` prefix) is an ERROR
    once the legacy set is gone;
  - `lib/app/gallery/` and the deleted test folders are not recreated.

  TDD with `tools/docs` tests.
- **Documents.**
  - DESIGN.md wording, per S8.
  - `docs/wbs_FE.md` gets rows for SP2, SP3a, SP3b and SP3c.
  - `SCREEN_CATALOG.md` keeps every screen `ready`: its spec is ready and its code is not
    built.
  - References to deleted test or code paths in live docs are fixed, and `check.py` finds the
    rest.
  - CLAUDE.md's "Known UI debt" row names the UI-base register of the deleted UI. It stays as a
    record until SP3a defines the new register; SP2 notes this in the plan.

## 7. Order of work and commit boundaries

0. Verify the recovery tag on GitHub (S7). Without it, stop before step 4.
1. The migration matrix, then the owner's review of it. No code changes before the approval.
2. Move the misplaced non-UI logic (if the matrix finds any), with tests. Gate.
3. Replace the router and shell with the placeholder (§5.2). Delete feature UI, `Mx*`, theme,
   gallery and the UI tests, following the matrix. Gate.
4. Delete `integration_test/` and every golden and golden test. Add the old-golden and
   legacy-path guards in `check.py`. Gate.
5. Tooling, guard and document updates (§6). Gate, then a final whole-branch review on Opus.

Each step is one or more commits. Each step ends with format, analyze, the docs checks and
`dod_check.sh` green. The branch is one PR, opened when the owner asks.

## 8. Definition of done

- The owner approved the matrix, and every file it lists has its outcome applied.
- No legacy feature UI, `Mx*`, ThemeData, gallery, UI test, integration test or golden remains.
- Every kept test passes without changes to its assertions.
- `domain/` and `data/` show no diff.
- The app compiles: `flutter analyze` is clean, and the placeholder smoke test pumps the real
  `MemoxApp`.
- The APK build (`.github/workflows/build-apk.yml`, run by hand, or `flutter build apk` on the
  owner's machine) runs before merge. The cloud container has no Android SDK.
- `dod_check.sh` is green. `check.py` and `check.py --ledger` pass.
- The recovery tag exists on GitHub.
- The final whole-branch review is done, and its Critical and Important findings are fixed.

## 9. Risks

| Risk | Mitigation |
|---|---|
| A non-UI behaviour hides in a UI file and is deleted | §4.1 rule 3, the owner's matrix review, kept tests unchanged, the startup and lifecycle tests in `test/app/` |
| The Welcome redirect traps the placeholder app | The `/welcome` placeholder keeps "Continue" (FN-ACCOUNT-001) (§5.2) |
| The guard or the gate fails on missing paths | §6: rules that name deleted paths are updated, and the gate runs after every step |
| Goldens deleted without a recovery point | S7: step 0 blocks the deletion |
| The ARB keeps keys no code uses | Accepted (S5); the l10n generator does not fail on unused keys, and SP3 prunes them |
| A kept provider references a deleted state class | The matrix keeps that class (`review`) or the provider is split, as a ruling |

## 10. Handoff to SP3a

SP3a starts from this state:

- DESIGN.md as the only visual source;
- no theme, tokens or `Mx*` in code;
- the placeholder shell in `lib/app/placeholder/`, which SP3b removes;
- the guard rules for design tokens and shared widgets ready for the new code.

SP3a has its own spec. Its first task is the DESIGN.md mapping of the 45 Material 3 colour
roles.
