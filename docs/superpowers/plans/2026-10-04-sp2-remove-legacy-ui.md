# SP2 — Remove the Legacy UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the old UI so SP3 rebuilds from a clean slate:
- delete feature UI, `Mx*`, theme, gallery, the UI tests, `integration_test/` and the 526 goldens;
- keep every non-UI behaviour;
- keep the app building with a four-tab placeholder shell, with the gate green.

**Architecture:**
- **Matrix first.** A script classifies every UI-adjacent file (UI → delete; infrastructure → keep; test → follows its subject; mixed → split) into a migration matrix. The owner reviews it before anything is deleted.
- **Placeholder app.** A placeholder shell and a minimal `GoRouter` replace the old router:
  - every catalog route is still registered and shows a page that names its SCR id;
  - `/welcome` keeps "Continue" (FN-ACCOUNT-001).
- **Deletion.** The deletion follows the matrix. The goldens go only after the recovery tag is on GitHub.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13, Riverpod 3 codegen, go_router, Drift, Python 3 docs tooling (`tools/docs/`), the `memox-v8` guard ruleset.

**Spec:** `docs/superpowers/specs/2026-10-04-sp2-remove-legacy-ui-design.md` (approved 2026-10-04, rulings S1–S12).

## Global Constraints

- **No behaviour change below the UI.** No change to `lib/features/*/domain/`, `lib/features/*/data/`, `lib/features/*/di/`, `lib/core/` (except deleting `lib/core/theme/`), `supabase/`, BR content or `pubspec.yaml`.
- **Kept tests stay green as written.** A kept test's assertions about non-UI behaviour do not change. A mixed test is split (spec §4.1 rule 4): its non-UI assertions stay word for word, and only assertions about a deleted screen leave.
- **No new visual system.** No tokens, no `Mx*`, no raw `Color(...)`, no raw numbers in `EdgeInsets` / `SizedBox` / radius / `Duration`.
  - The placeholder uses Flutter Material defaults with `ThemeData(useMaterial3: true)` (light, and dark with `brightness: Brightness.dark`).
- **Placeholder classes are never named `*Screen` or `*Page`** (guard `memox.screen_shell.use_mx_scaffold_family`).
  - Every `GoRoute(` lives in `lib/app/router/app_router.dart` (guard `memox.routing.no_route_definition_outside_router`).
- **Providers stay where ADR-011 puts them (S12).** Kept providers stay in `presentation/providers/`.
- **Tabs (S10):** Library · Study · Progress · Settings, in that order, labelled `navLibrary`, `navStudy`, `navProgress`, `navSettings`.
- **Welcome (S11):** the `/welcome` placeholder keeps one action, labelled `accountContinue`.
  - The action calls `welcomeDueProvider.notifier.dismiss()`, then `context.go(from)`, where `from = AppRoutes.inAppOr(query['from'], AppRoutes.decks)`.
- **ARB (S5):** keep both files. Add exactly one key, `placeholderBeingRebuilt`:
  - `app_en.arb`: `"Being rebuilt"`;
  - `app_vi.arb`: `"Đang được dựng lại"`;
  - with a `@placeholderBeingRebuilt` description.
- **Recovery tag (S7):** no golden PNG is deleted before
  `git ls-remote --tags origin legacy-ui-v8-goldens` prints a line ending in `refs/tags/legacy-ui-v8-goldens`
  that peels (`^{}`) to `ac57dc47e3f6ee1bc4fc62eb59a7ca679a3ecd79`.
- **Commits:**
  - Follow the repo convention (`type(scope): summary`).
  - End every commit with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421`.
  - No model name in commit text.
- **Branch:** `ccr-841d461f-jofe0s`. Push after each task. No PR until the owner asks.
- **Gate** (every task ends with it): `export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH; bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → `✓ mechanical gates passed`.
  - Docs: `python3 tools/docs/generate.py && python3 tools/docs/check.py` → `PASS`.

## Review Focus

- **Welcome on a build that can sign in.** Every launch shows the Welcome placeholder until "Continue" is pressed. Then the app lands on `from` and does not show Welcome again in that run.
  - Test: Task 3, `welcome placeholder continues to where the launch was headed`.
- **A deep link with an unknown id** (`/decks/deck/no-such-id`, `/settings/monitoring/x?local=1`) shows the screen's placeholder, never an exception or a blank page.
  - Test: Task 3, `every catalog route shows its screen's placeholder`, with arbitrary ids.
- **A reminder tap** while running and at launch still opens the Study tab and opens no session (BR-REMINDER-008).
  - Test: Task 3 keeps `test/app/reminder_tap_test.dart`, with its finder moved to the Study placeholder.
- **Startup and lifecycle work without any UI:**
  - the Trash purge at start and at resume;
  - closing stale sessions;
  - reminder reconcile;
  - lifecycle logs.

  Tests: Task 3 keeps the batch assertions of `trash_auto_purge_test.dart`; `lifecycle_logging_test.dart`, `reminder_reconcile_test.dart` and `startup_*_test.dart` stay untouched.
- **The stored theme mode and language still drive `MaterialApp`.**
  - Test: Task 3 splits `app_appearance_test.dart`. Its brightness and locale assertions stay; the tab-label finder moves to `NavigationBar`.

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui/sp2_matrix.py` (git-ignored workspace) | Classifies files; writes the matrix and `delete-list.txt` | 1 |
| `docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md` | The migration matrix the owner reviews | 1 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/l10n/generated/*` | `placeholderBeingRebuilt` | 3 |
| `lib/app/placeholder/rebuild_placeholder.dart` | `RebuildPlaceholder` (names an SCR) and `UnknownRoutePlaceholder` | 3 |
| `lib/app/placeholder/welcome_placeholder.dart` | `WelcomePlaceholder` with "Continue" | 3 |
| `lib/app/placeholder/placeholder_shell.dart` | `PlaceholderShell`: four tabs over a `StatefulNavigationShell` | 3 |
| `lib/app/router/app_router.dart` | Rewritten: every catalog route → placeholder | 3 |
| `lib/app/app.dart` | Default Material themes; no layer host, no gallery | 3 |
| `test/app/placeholder_app_test.dart` | Smoke test of the placeholder app | 3 |
| `test/app/reminder_tap_test.dart`, `trash_auto_purge_test.dart`, `app_appearance_test.dart` | Split: non-UI assertions kept | 3 |
| `test/support/library_harness.dart`, `test/support/account_harness.dart` | Split: UI helpers removed, environment helpers kept | 4 |
| `tools/docs/check.py`, `tools/docs/test_ui_docs_layout.py` | Legacy-golden and legacy-path guard | 5 |
| `DESIGN.md`, `PRODUCT.md`, `docs/wbs_FE.md`, other live docs | S8 wording, rebuild rows, references | 6 |

---

### Task 0: Workspace and recovery-tag status

**Files:** none in the repo.

- [ ] **Step 1: Create the plan workspace and ledger**

Run:
```bash
cd /home/user/memox-v8
bash .claude/skills/subagent-driven-development/scripts/sdd-workspace docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui.md
```
Expected: prints `.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui/`.

Create `progress.md` there. Its first line is `# SDD ledger — plan: docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui.md`.

- [ ] **Step 2: Record the tag status (does not block Tasks 1–4)**

Run: `git ls-remote --tags origin legacy-ui-v8-goldens`
Expected:
- Two lines, the second ending `refs/tags/legacy-ui-v8-goldens^{}` with sha `ac57dc47e3f6ee1bc4fc62eb59a7ca679a3ecd79`.
- Or nothing yet. In that case, ledger `Task 0: tag not yet on GitHub — Task 5 waits`.

---

### Task 1: Migration matrix and owner review

**Files:**
- Create: `.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui/sp2_matrix.py`
- Create: `docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md`
- Create: `.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui/delete-list.txt`

**Interfaces:**
- Produces: `delete-list.txt` (one repo-relative path per line: every `delete` row except goldens and `integration_test/`, which Task 5 deletes). The matrix's classifications for Tasks 3–5.

- [ ] **Step 1: Write the classifier**

Write `.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui/sp2_matrix.py`:

```python
#!/usr/bin/env python3
"""SP2 migration matrix (spec 2026-10-04-sp2 §4). Run from the repo root."""
import re
import sys
from pathlib import Path

ROOT = Path.cwd()
OUT = Path("docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md")
DELETE_LIST = Path(sys.argv[1])
IMPORT = re.compile(r"^(?:import|export) '([^']+)'", re.M)

NON_UI_PROVIDERS = {
    "lib/features/account/presentation/providers/device_account_provider.dart",
    "lib/features/account/presentation/providers/welcome_due_provider.dart",
    "lib/features/reminders/presentation/providers/reconcile_reminder_provider.dart",
    "lib/features/settings/presentation/providers/app_settings_provider.dart",
}
APP_KEEP = {
    "lib/app/app.dart": ("modify", "lifecycle, settings, redirect inputs; default Material themes (Task 3)"),
    "lib/app/font_license.dart": ("keep", "font licence registration"),
    "lib/app/logging_bootstrap.dart": ("keep", "logging bootstrap"),
    "lib/app/startup_settings.dart": ("keep", "settings read before the first frame"),
    "lib/app/startup_welcome.dart": ("keep", "Welcome flag read before the first frame"),
    "lib/app/router/app_routes.dart": ("modify", "the route contract; drop `gallery` (Task 4)"),
    "lib/app/router/account_redirect.dart": ("keep", "the account guard"),
    "lib/app/router/log_navigator_observer.dart": ("keep", "navigation logging (ADR-018)"),
    "lib/app/router/app_router.dart": ("modify", "rewritten: catalog routes → placeholders (Task 3)"),
}
SPLIT = {
    "test/app/reminder_tap_test.dart": "keep BR-REMINDER-008 tap behaviour; finder → Study placeholder",
    "test/app/trash_auto_purge_test.dart": "keep the purge batch assertions; drop Trash-screen assertions",
    "test/app/app_appearance_test.dart": "keep brightness and locale assertions; tab finder → NavigationBar",
    "test/support/library_harness.dart": "keep LibraryEnv, libraryTest, libraryContainer, pumpMemoxApp; drop screen helpers",
    "test/support/account_harness.dart": "keep the account environment; drop screen helpers",
}
REPLACED = {
    "test/app/app_test.dart": "covered by test/app/placeholder_app_test.dart (Task 3)",
    "test/app/route_not_found_test.dart": "covered by test/app/placeholder_app_test.dart (Task 3)",
    "test/app/tab_shell_test.dart": "covered by test/app/placeholder_app_test.dart (Task 3)",
}
DEAD_TEST_DIRS = ("test/shared/widgets/", "test/core/theme/", "test/visual_audit/")


def files(pattern: str) -> list[str]:
    return sorted(p.as_posix() for p in ROOT.glob(pattern) if p.is_file())


def imports(path: str) -> list[str]:
    found = []
    for spec in IMPORT.findall((ROOT / path).read_text(encoding="utf-8")):
        if spec.startswith("package:memox/"):
            found.append("lib/" + spec[len("package:memox/"):])
        elif not spec.startswith(("package:", "dart:")):
            found.append((Path(path).parent / spec).as_posix())
    return [str(Path(p)) for p in found]


def kept_presentation() -> set[str]:
    pres = set(files("lib/features/*/presentation/**/*.dart"))
    roots = {p for p in pres if p.endswith("_use_case_provider.dart")} | NON_UI_PROVIDERS
    keep, todo = set(), list(roots)
    while todo:
        path = todo.pop()
        if path in keep:
            continue
        keep.add(path)
        todo += [p for p in imports(path) if p in pres and p not in keep]
    return keep | {p[:-5] + ".g.dart" for p in keep if (ROOT / (p[:-5] + ".g.dart")).exists()}


def main() -> None:
    rows: list[tuple[str, str, str, str, str]] = []
    keep_pres = kept_presentation()
    for path in files("lib/features/*/presentation/**/*.dart"):
        if path in keep_pres:
            reason = "use-case provider (ADR-011)" if "_use_case_provider" in path else "provider needed with no screen"
            rows.append((path, "infrastructure", "keep", "—", reason))
            continue
        flag = "UI (review)" if "/providers/" in path and not path.endswith(".g.dart") else "UI"
        reason = "provider whose consumers are all UI; confirm no non-UI behaviour" if flag == "UI (review)" else "screen-specific presentation"
        rows.append((path, flag, "delete", "—", reason))
    for path in files("lib/app/**/*.dart"):
        outcome, reason = APP_KEEP.get(path, ("delete", "old router, shell, gallery or UI wiring"))
        rows.append((path, "infrastructure" if outcome != "delete" else "UI", outcome, "—", reason))
    for path in files("lib/shared/widgets/**/*.dart") + files("lib/core/theme/**/*.dart"):
        rows.append((path, "UI", "delete", "—", "legacy Mx*/theme implementation (S1)"))
    for path in files("lib/l10n/**/*"):
        rows.append((path, "infrastructure", "keep", "—", "language data (S5)"))
    deleted_lib = {r[0] for r in rows if r[2] == "delete"}
    tests = files("test/**/*.dart")
    dead: set[str] = set()
    changed = True
    while changed:
        changed = False
        for path in tests:
            if path in dead or path in SPLIT:
                continue
            text = (ROOT / path).read_text(encoding="utf-8")
            deps = imports(path)
            if (path.startswith(DEAD_TEST_DIRS) or path in REPLACED or "matchesGoldenFile" in text
                    or any(d in deleted_lib or d in dead for d in deps)):
                dead.add(path)
                changed = True
    for path in tests:
        if path in SPLIT:
            rows.append((path, "test (mixed)", "split", path, SPLIT[path]))
        elif path in REPLACED:
            rows.append((path, "test (UI)", "delete", "—", REPLACED[path]))
        elif path in dead:
            rows.append((path, "test (UI)", "delete", "—", "tests deleted UI, a golden, or uses a deleted helper"))
        else:
            rows.append((path, "test", "keep", "—", "tests kept code"))
    for path in files("integration_test/**/*"):
        rows.append((path, "test (UI)", "delete", "—", "drives the old UI; scenario catalogue kept (S6)"))
    goldens: dict[str, int] = {}
    for path in files("test/**/goldens/*.png"):
        folder = path.rsplit("/", 1)[0]
        goldens[folder] = goldens.get(folder, 0) + 1
    lines = [
        "# SP2 migration matrix",
        "",
        "Generated by the SP2 plan's Task 1 classifier from the spec's §4.1 rules; `UI (review)` rows",
        "are the ones the owner checks first. Goldens are listed per folder (Task 5 deletes them",
        "after the recovery tag is on GitHub).",
        "",
        "| Outcome | Rows |", "|---|---|",
    ]
    for outcome in ("keep", "modify", "split", "delete"):
        lines.append(f"| {outcome} | {sum(1 for r in rows if r[2] == outcome)} |")
    lines += [f"| goldens (delete, Task 5) | {sum(goldens.values())} |", "",
              "## Files", "", "| Source | Classification | Outcome | Target | Reason |", "|---|---|---|---|---|"]
    lines += [f"| `{s}` | {c} | {o} | {t if t == '—' else '`' + t + '`'} | {r} |" for s, c, o, t, r in rows]
    lines += ["", "## Goldens", "", "| Folder | PNG files | Outcome |", "|---|---|---|"]
    lines += [f"| `{folder}/` | {n} | delete (Task 5) |" for folder, n in sorted(goldens.items())]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    DELETE_LIST.write_text("\n".join(r[0] for r in rows if r[2] == "delete" and not r[0].startswith("integration_test/")) + "\n", encoding="utf-8")
    print(f"rows={len(rows)} delete={sum(1 for r in rows if r[2] == 'delete')} goldens={sum(goldens.values())}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run it**

Run:
```bash
W=.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui
python3 $W/sp2_matrix.py $W/delete-list.txt
grep -c '| keep |' docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md
grep -c 'UI (review)' docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md
```
Expected:
- the first line ends `goldens=526`;
- at least 83 `presentation/` keep rows (79 use-case providers + 4) plus their `.g.dart` files;
- a non-zero `UI (review)` count.

- [ ] **Step 3: Check the matrix for misplaced non-UI logic**

Every `UI (review)` row is a provider the classifier would delete. For each one, run:
```bash
grep -n "ref.listen\|Timer\|scheduleAlarm\|syncNow\|purge\|reconcile\|abandon" <path>
```
- If a row shows behaviour that must run with no screen open (the spec's §4.1 rule 3), change its outcome to `move`, with the target and the reason. Ledger `Task 1: Ruling: move <path> → <target> — <why>`.
- Otherwise leave it `delete`.

Expected: no `move` row. The spec's analysis found none: no file outside `presentation/` imports a deleted provider except the old router.

- [ ] **Step 4: Commit the matrix**

```bash
git add docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md
git commit -m "docs(sp2): migration matrix for removing the legacy UI" -m "<trailers>"
git push -u origin ccr-841d461f-jofe0s
```

- [ ] **Step 5: Owner review gate (AskUserQuestion)**

Present:
- the outcome counts;
- the `UI (review)` rows;
- every `split` and `modify` row;
- any `move` row.

Options:
- "Approve the matrix" (recommended);
- "Approve with changes" (owner names rows; apply, regenerate, ask again);
- "Stop".

Nothing in Tasks 2–5 runs before the approval.

After approval, add one line under the matrix title: `Approved by the owner <date>.` Then commit `docs(sp2): matrix approved`.

---

### Task 2: Move misplaced non-UI logic

**Files:** whatever the approved matrix lists with outcome `move` (expected: none).

- [ ] **Step 1: Read the approved matrix**

Run: `grep -c '| move |' docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md`

- If it prints `0`, ledger `Task 2: no move rows in the approved matrix — nothing to do` and go to Task 3.
- Otherwise, for each `move` row:
  - write a failing test of the behaviour at its target;
  - move the code (`git mv`, then fix its imports);
  - run the test;
  - run the gate;
  - commit `refactor(sp2): move <what> out of presentation`.

---

### Task 3: Placeholder app

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (+ regenerated `lib/l10n/generated/`)
- Create: `lib/app/placeholder/rebuild_placeholder.dart`, `lib/app/placeholder/welcome_placeholder.dart`, `lib/app/placeholder/placeholder_shell.dart`
- Modify (rewrite): `lib/app/router/app_router.dart`
- Modify: `lib/app/app.dart`
- Test: create `test/app/placeholder_app_test.dart`; split `test/app/reminder_tap_test.dart`, `test/app/trash_auto_purge_test.dart`, `test/app/app_appearance_test.dart`; delete `test/app/app_test.dart`, `test/app/route_not_found_test.dart`, `test/app/tab_shell_test.dart`, and every other test that pumps the old router: `test/app/*_routes_test.dart`, `test/app/gallery_test.dart`, `test/app/app_golden_test.dart`.

**Interfaces:**
- Produces:
  - `GoRouter buildAppRouter({Listenable? refreshListenable, GoRouterRedirect? redirect})` (the `hasGallery` parameter is gone);
  - `RebuildPlaceholder({required String scrId})`;
  - `UnknownRoutePlaceholder()`;
  - `WelcomePlaceholder({required String from})`;
  - `PlaceholderShell({required StatefulNavigationShell navigationShell})`.
- `MemoxApp({AppSettingsEntity? initialSettings})`: the `hasGallery` parameter is gone.

- [ ] **Step 1: Write the failing smoke test**

Create `test/app/placeholder_app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Every route of docs/screens/SCREEN_CATALOG.md → the SCR id its placeholder names
/// (spec 2026-10-04-sp2 §5.2). Ids are arbitrary: a placeholder reads nothing.
const _routes = <String, String>{
  '/decks': 'SCR-DECK-001',
  '/decks/deck/no-such-id': 'SCR-DECK-001 · SCR-CARD-001',
  '/decks/deck/d1/algorithm': 'SCR-SRS-001',
  '/decks/deck/d1/cards/new': 'SCR-CARD-002',
  '/decks/deck/d1/cards/import': 'SCR-TRANSFER-001',
  '/decks/deck/d1/study': 'SCR-STUDY-002',
  '/decks/deck/d1/options': 'SCR-SETTINGS-001',
  '/decks/starter': 'SCR-STARTER-001',
  '/decks/search?q=bap': 'SCR-SEARCH-001',
  '/decks/tags': 'SCR-TAG-001',
  '/decks/trash': 'SCR-TRASH-001',
  '/decks/card/c1': 'SCR-CARD-004',
  '/decks/card/c1/edit': 'SCR-CARD-003',
  '/study': 'SCR-STUDY-001',
  '/study/session/s1': 'SCR-STUDY-003…SCR-STUDY-009',
  '/progress': 'SCR-PROGRESS-001',
  '/progress/d1': 'SCR-PROGRESS-001',
  '/settings': 'SCR-SETTINGS-002',
  '/settings/theme': 'SCR-SETTINGS-003',
  '/settings/language': 'SCR-SETTINGS-004',
  '/settings/reminder': 'SCR-REMINDER-001',
  '/settings/sync': 'SCR-ACCOUNT-001',
  '/settings/sign-in?mode=reauth&from=/study': 'SCR-ACCOUNT-003',
  '/settings/sign-in/code?mode=reauth&email=a@b.c': 'SCR-ACCOUNT-004',
  '/settings/users': 'SCR-ACCOUNT-006',
  '/settings/monitoring': 'SCR-MONITORING-001',
  '/settings/monitoring/x?local=1': 'SCR-MONITORING-001',
};

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

void main() {
  libraryTest('cold start lands on the Library placeholder with the four tabs', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);

    expect(find.text('SCR-DECK-001'), findsOneWidget);
    expect(find.text(_en.placeholderBeingRebuilt), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.destinations.map((d) => (d as NavigationDestination).label),
      [_en.navLibrary, _en.navStudy, _en.navProgress, _en.navSettings],
    );
    expect(bar.selectedIndex, 0);
  });

  libraryTest('a tab tap opens that tab, and a second tap returns it to its root', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);

    await tester.tap(find.text(_en.navProgress));
    await tester.pumpAndSettle();
    expect(find.text('SCR-PROGRESS-001'), findsOneWidget);

    _router(tester).go('/progress/d1');
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.navProgress));
    await tester.pumpAndSettle();
    expect(
      _router(tester).routerDelegate.currentConfiguration.uri.path,
      '/progress',
    );
  });

  libraryTest('every catalog route shows its screen placeholder', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);

    for (final entry in _routes.entries) {
      _router(tester).go(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  libraryTest('an unknown location offers the way back to the Library', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);

    _router(tester).go('/nowhere');
    await tester.pumpAndSettle();
    expect(find.text(_en.routeNotFoundTitle), findsOneWidget);
    expect(find.textContaining('/nowhere'), findsNothing);

    await tester.tap(find.text(_en.deckBackToLibrary));
    await tester.pumpAndSettle();
    expect(find.text('SCR-DECK-001'), findsOneWidget);
  });

  libraryTest('welcome placeholder continues to where the launch was headed', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );

    container.read(welcomeDueProvider.notifier).show();
    _router(tester).go('/progress');
    await tester.pumpAndSettle();
    expect(find.text('SCR-ACCOUNT-002'), findsOneWidget);

    await tester.tap(find.text(_en.accountContinue));
    await tester.pumpAndSettle();
    expect(container.read(welcomeDueProvider), isFalse);
    expect(find.text('SCR-PROGRESS-001'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH; flutter test test/app/placeholder_app_test.dart`
Expected: a compile error: `placeholderBeingRebuilt` is not defined on `AppLocalizations`.

- [ ] **Step 3: Add the ARB key**

In `lib/l10n/app_en.arb`, after `"navSettings"` and its `@navSettings` block, add:
```json
  "placeholderBeingRebuilt": "Being rebuilt",
  "@placeholderBeingRebuilt": {
    "description": "Temporary placeholder line under a screen id while SP3 rebuilds the UI (spec 2026-10-04-sp2 §5.2)."
  },
```
In `lib/l10n/app_vi.arb`, at the matching place, add `"placeholderBeingRebuilt": "Đang được dựng lại",`.

Run: `flutter gen-l10n`
Expected: `lib/l10n/generated/` regenerated with `placeholderBeingRebuilt`.

- [ ] **Step 4: Write the placeholders**

`lib/app/placeholder/rebuild_placeholder.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/l10n/l10n_context.dart';

/// SP2 (spec 2026-10-04-sp2 §5.2): stands in for a screen until SP3 rebuilds
/// it. It names the screen and reads nothing; SP3b deletes this folder.
class RebuildPlaceholder extends StatelessWidget {
  const RebuildPlaceholder({super.key, required this.scrId});

  final String scrId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(scrId), Text(context.l10n.placeholderBeingRebuilt)],
        ),
      ),
    ),
  );
}

/// A location no route matches: no exception text, one way to the Library.
class UnknownRoutePlaceholder extends StatelessWidget {
  const UnknownRoutePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.routeNotFoundTitle),
              Text(l10n.routeNotFoundBody),
              TextButton(
                onPressed: () => context.go(AppRoutes.decks),
                child: Text(l10n.deckBackToLibrary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/app/placeholder/welcome_placeholder.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/l10n/l10n_context.dart';

/// SP2 (S11): Welcome's one preserved action. "Continue" answers Welcome
/// (FN-ACCOUNT-001) and goes on to where the launch was headed.
class WelcomePlaceholder extends ConsumerWidget {
  const WelcomePlaceholder({super.key, required this.from});

  final String from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SCR-ACCOUNT-002'),
              Text(l10n.placeholderBeingRebuilt),
              TextButton(
                onPressed: () => _continue(context, ref),
                child: Text(l10n.accountContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue(BuildContext context, WidgetRef ref) {
    unawaited(ref.read(welcomeDueProvider.notifier).dismiss());
    context.go(from);
  }
}
```

`lib/app/placeholder/placeholder_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/l10n/l10n_context.dart';

/// SP2 (S10): the four tabs of docs/NAVIGATION.md over the branch stacks.
/// Re-tapping the current tab returns its branch to its root.
class PlaceholderShell extends StatelessWidget {
  const PlaceholderShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == current),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            label: l10n.navLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            label: l10n.navStudy,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            label: l10n.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Rewrite the router**

Replace the whole of `lib/app/router/app_router.dart` with:

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/placeholder/placeholder_shell.dart';
import 'package:memox/app/placeholder/rebuild_placeholder.dart';
import 'package:memox/app/placeholder/welcome_placeholder.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/app/router/log_navigator_observer.dart';

/// SP2 (spec 2026-10-04-sp2 §5.2): every route of
/// docs/screens/SCREEN_CATALOG.md stays registered and shows a placeholder
/// naming its screen, so deep links, the reminder tap and the account
/// redirect keep their contract until SP3 rebuilds each screen. The four
/// tabs follow docs/NAVIGATION.md; a route that covers the shell there sits
/// on the root navigator here too.
GoRouter buildAppRouter({
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  final rootNavigator = GlobalKey<NavigatorState>();
  GoRoute page(
    String path,
    String scrId, {
    bool isOverShell = false,
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    parentNavigatorKey: isOverShell ? rootNavigator : null,
    builder: (context, state) => RebuildPlaceholder(scrId: scrId),
    routes: routes,
  );
  StatefulShellBranch branch(GoRoute root) =>
      StatefulShellBranch(observers: [LogNavigatorObserver()], routes: [root]);
  return GoRouter(
    navigatorKey: rootNavigator,
    observers: [LogNavigatorObserver()],
    initialLocation: AppRoutes.decks,
    refreshListenable: refreshListenable,
    redirect: redirect,
    errorBuilder: (context, state) => const UnknownRoutePlaceholder(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PlaceholderShell(navigationShell: navigationShell),
        branches: [
          branch(
            page(
              AppRoutes.decks,
              'SCR-DECK-001',
              routes: [
                page(
                  AppRoutes.deckChild,
                  'SCR-DECK-001 · SCR-CARD-001',
                  routes: [
                    page(AppRoutes.cardNewChild, 'SCR-CARD-002'),
                    page(
                      AppRoutes.cardImportChild,
                      'SCR-TRANSFER-001',
                      isOverShell: true,
                    ),
                    page(AppRoutes.studyChild, 'SCR-STUDY-002'),
                    page(
                      AppRoutes.studyOptionsChild,
                      'SCR-SETTINGS-001',
                      isOverShell: true,
                    ),
                    page(AppRoutes.algorithmChild, 'SCR-SRS-001'),
                  ],
                ),
                page(AppRoutes.trashChild, 'SCR-TRASH-001', isOverShell: true),
                page(
                  AppRoutes.starterDecksChild,
                  'SCR-STARTER-001',
                  isOverShell: true,
                ),
                page(AppRoutes.tagsChild, 'SCR-TAG-001', isOverShell: true),
                page(AppRoutes.searchChild, 'SCR-SEARCH-001'),
                page(
                  AppRoutes.cardChild,
                  'SCR-CARD-004',
                  routes: [page(AppRoutes.cardEditChild, 'SCR-CARD-003')],
                ),
              ],
            ),
          ),
          branch(page(AppRoutes.study, 'SCR-STUDY-001')),
          branch(
            page(
              AppRoutes.progress,
              'SCR-PROGRESS-001',
              routes: [page(AppRoutes.progressDeckChild, 'SCR-PROGRESS-001')],
            ),
          ),
          branch(
            page(
              AppRoutes.settings,
              'SCR-SETTINGS-002',
              routes: [
                page(
                  AppRoutes.settingsThemeChild,
                  'SCR-SETTINGS-003',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsLanguageChild,
                  'SCR-SETTINGS-004',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsReminderChild,
                  'SCR-REMINDER-001',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsSyncChild,
                  'SCR-ACCOUNT-001',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsSignInChild,
                  'SCR-ACCOUNT-003',
                  isOverShell: true,
                  routes: [
                    page(
                      AppRoutes.settingsSignInCodeChild,
                      'SCR-ACCOUNT-004',
                      isOverShell: true,
                    ),
                  ],
                ),
                page(
                  AppRoutes.settingsAccountChild,
                  'SCR-ACCOUNT-005',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsUsersChild,
                  'SCR-ACCOUNT-006',
                  isOverShell: true,
                ),
                page(
                  AppRoutes.settingsMonitoringChild,
                  'SCR-MONITORING-001',
                  isOverShell: true,
                  routes: [
                    page(
                      AppRoutes.monitoringLogChild,
                      'SCR-MONITORING-001',
                      isOverShell: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomePlaceholder(
          from: AppRoutes.inAppOr(
            state.uri.queryParameters[AppRoutes.welcomeFromParam],
            AppRoutes.decks,
          ),
        ),
      ),
      page(AppRoutes.studySessionPath, 'SCR-STUDY-003…SCR-STUDY-009'),
    ],
  );
}
```

- [ ] **Step 6: Rewire `app.dart`**

In `lib/app/app.dart`, make these changes and nothing else:
1. Remove the imports of `package:memox/core/theme/...` and of `account_layer_host_widget.dart`.
2. Remove the `hasGallery` field, its constructor parameter and its doc comment. Change `buildAppRouter(hasGallery: widget.hasGallery, refreshListenable: …, redirect: …)` to `buildAppRouter(refreshListenable: …, redirect: …)`.
3. Replace `theme: buildLightTheme(),` with `theme: ThemeData(useMaterial3: true),`, and `darkTheme: buildDarkTheme(),` with `darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),`.
4. Delete the `builder: (context, child) => AccountLayerHostWidget(...)` argument and its comment. Add one line to the class doc: `/// SP2: the account transition layer has no UI until SP3 rebuilds it; transitions still run through the coordinator.`
5. If `kDebugMode` / `foundation.dart` is now unused, remove that import.

Keep every lifecycle, reminder, purge, stale-session, log and redirect line exactly as it is.

- [ ] **Step 7: Run the smoke test to verify it passes**

Run: `flutter test test/app/placeholder_app_test.dart`
Expected: `All tests passed!` (5 tests).

- [ ] **Step 8: Split the mixed app tests; delete the tests of the old router**

1. **`test/app/reminder_tap_test.dart`.** Delete the import of `study_home_screen.dart`. Then run:
   ```bash
   sed -i "s/find.byType(StudyHomeScreen)/find.text('SCR-STUDY-001')/g" test/app/reminder_tap_test.dart
   ```
   The `findsNothing` / `findsOneWidget` matchers stay as they are.
2. **`test/app/trash_auto_purge_test.dart`.** Keep every test and assertion that reads `_batches(env)`. Delete each assertion that finds Trash-screen text (`find.text('bap · rice')`, `_en.trashEmptyTitle`), and delete the steps that only exist to open the Trash screen. If a test is left with no assertion, delete the test.
   - Ledger `Task 3: Ruling: trash_auto_purge_test keeps <n> batch assertions, drops <m> screen assertions`.
3. **`test/app/app_appearance_test.dart`.**
   - Keep the brightness and locale tests.
   - Replace `_tab(label)` with `find.descendant(of: find.byType(NavigationBar), matching: find.text(label))`.
   - Delete `_barTitle` and each assertion that uses it (it reads a deck title through the old `MxAppBar`).
   - Delete the `mx_app_bar` / `mx_bottom_nav` imports.
4. **Delete** these tests (each pumps the old router or its screens):
   ```bash
   git rm test/app/app_test.dart test/app/route_not_found_test.dart test/app/tab_shell_test.dart \
     test/app/account_routes_test.dart test/app/library_routes_test.dart test/app/monitoring_routes_test.dart \
     test/app/progress_routes_test.dart test/app/settings_routes_test.dart test/app/starter_tags_routes_test.dart \
     test/app/study_routes_test.dart test/app/trash_routes_test.dart test/app/gallery_test.dart test/app/app_golden_test.dart
   ```

- [ ] **Step 9: Run the app tests and the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app`
Expected: all pass.

Run the gate. Expected:
- `✓ mechanical gates passed`;
- the old UI files still exist, now unreferenced by the router;
- `flutter analyze` is clean, apart from unused-file lints, which the analyzer does not raise.

If the suite fails only on a test outside `test/app/` that pumps `MemoxApp` and finds an old
screen, that test is a `delete` row of the matrix: `git rm` it here instead of in Task 4, and
ledger `Task 3: Ruling: deleted <test> early — it drove the old router`. Any other failure is
debugged (systematic-debugging), never deleted.

- [ ] **Step 10: Commit**

```bash
git add -A lib/app lib/l10n test/app
git commit -m "feat(sp2): placeholder shell and router stand in for the legacy UI" -m "<body: catalog routes → placeholders, /welcome keeps Continue, tabs per NAVIGATION.md; mixed app tests split>" -m "<trailers>"
git push
```

---

### Task 4: Delete the legacy UI, `Mx*`, theme and UI tests

**Files:**
- Delete: every path in `.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui/delete-list.txt` that still exists.
- Split: `test/support/library_harness.dart`, `test/support/account_harness.dart`.
- Modify: `lib/app/router/app_routes.dart` (remove the `gallery` constant).

**Interfaces:**
- Consumes: `delete-list.txt` (Task 1).
- Produces: a tree with no `lib/shared/widgets/`, no `lib/core/theme/`, no `lib/app/gallery/` and no `screens|widgets|controllers|states` folder under any `presentation/`.

- [ ] **Step 1: Split the two support harnesses**

1. **`test/support/library_harness.dart`.**
   - Keep `libraryToday`, `LibraryEnv`, `libraryTest`, `_backend`, `libraryContainer`, `pumpMemoxApp` and `_noRetry`.
   - Delete `_app`, `pumpLibraryScreen`, `pumpLibraryGolden`, `deckScreen`, `cardDeckScreen` and `deckAlgorithmScreen`.
   - Delete every import that only these used: `core/theme/app_theme.dart`, `shared/widgets/mx_app_bar.dart`, the card `presentation/widgets/...` imports, `deck_algorithm_screen.dart`, `deck_level_screen.dart`, `deck_view_model.dart` if now unused, and `golden_harness.dart`.
2. **`test/support/account_harness.dart`.** Run `grep -n "import" test/support/account_harness.dart`.
   - Delete every function that builds a screen or imports a deleted UI file.
   - Keep the fakes and environment that `test/app/account_redirect_test.dart` and `startup_welcome_test.dart` use. Confirm with `grep -n "account_harness" test -r`.

- [ ] **Step 2: Delete the listed files**

Run:
```bash
W=.superpowers/sdd/2026-10-04-sp2-remove-legacy-ui
while read -r path; do [ -e "$path" ] && git rm -q "$path"; done < $W/delete-list.txt
find lib/features -path '*/presentation/*' -type d -empty -delete
git rm -rq lib/shared/widgets lib/core/theme lib/app/gallery 2>/dev/null || true
```
Remove `static const String gallery = '/gallery';` from `lib/app/router/app_routes.dart`.

- [ ] **Step 3: Regenerate code and verify the tree**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
find lib -path '*/presentation/*' -type d \( -name screens -o -name widgets -o -name controllers -o -name states \)
ls lib/shared/widgets lib/core/theme lib/app/gallery 2>&1 | grep -c 'No such file'
grep -rlE "package:memox/(shared/widgets|core/theme)/" lib test integration_test
```
Expected:
- `build_runner` succeeds with no new outputs;
- the `find` prints nothing, unless the matrix kept a state class, in which case it prints that folder alone;
- the `ls` prints `3`;
- the final `grep` prints nothing, or only files under `integration_test/`, which Task 5 deletes.

- [ ] **Step 4: Prove the kept tests still pass unchanged**

Run:
```bash
git diff --stat ac57dc4 -- lib/features/*/domain lib/features/*/data lib/features/*/di lib/core supabase pubspec.yaml | tail -1
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test
```
Expected:
- the diff touches only `lib/core/theme/` (deleted);
- every test passes.

- [ ] **Step 5: Gate, guard, commit**

Run the gate.
Run: `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: `Code verification passed.`

```bash
git add -A
git commit -m "refactor(sp2): delete the legacy UI, Mx widgets, theme and UI tests" -m "<body: counts from the matrix; harness splits>" -m "<trailers>"
git push
```

---

### Task 5: Delete `integration_test/` and the goldens; guard against legacy goldens

**Files:**
- Delete: `integration_test/**`, every `test/**/goldens/*.png`
- Modify: `tools/docs/check.py`, `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Produces: `check.py` ERROR `legacy golden (SP2): …` for any `test/**/goldens/*.png` not named `scr_…`, and ERROR `retired home` for `lib/app/gallery/` or `test/visual_audit/`.

- [ ] **Step 1: Verify the recovery tag (blocking)**

Run: `git ls-remote --tags origin legacy-ui-v8-goldens`
Expected: a line `ac57dc47e3f6ee1bc4fc62eb59a7ca679a3ecd79	refs/tags/legacy-ui-v8-goldens^{}`.

If it is missing, stop. Ask the owner (AskUserQuestion) to push the tag:
```bash
git fetch origin && git tag -a legacy-ui-v8-goldens ac57dc4 -m "Last commit with the V8 UI and its 526 goldens" && git push origin legacy-ui-v8-goldens
```
Re-run the check after their answer.

- [ ] **Step 2: Write the failing docs-tool test**

In `tools/docs/test_ui_docs_layout.py`, next to `test_a_file_in_a_retired_home_is_an_error`, add:

```python
    def test_a_legacy_golden_is_an_error_and_an_scr_golden_is_not(self):
        legacy = errors(base(**{"test/features/deck/presentation/goldens/library_root_light.png": ""}))
        self.assertTrue(has(legacy, "library_root_light.png", "legacy golden (SP2)"))

    def test_the_gallery_and_visual_audit_are_retired_homes(self):
        for path in ("lib/app/gallery/gallery_screen.dart", "test/visual_audit/screens/x_test.dart"):
            self.assertTrue(has(errors(base(**{path: "// old\n"})), "retired home"), path)
```

If `base()` does not create files outside `docs/`, add the files through the same `tree()` helper the fixture uses (check `def tree` in the test file). Do not add a second fixture mechanism.

- [ ] **Step 3: Run it to verify it fails**

Run: `python3 -m unittest tools/docs/test_ui_docs_layout.py -k legacy_golden -k gallery_and_visual`
Expected: 2 failures (no such ERROR yet).

- [ ] **Step 4: Implement the guard**

In `tools/docs/check.py`, beside `check_retired_homes`:

```python
# SP2 removed the legacy goldens and these UI homes (spec 2026-10-04-sp2 §6); a
# golden is named scr_<screen>__<state>__<variant>.png from now on (R16).
RETIRED_UI_HOMES = ("lib/app/gallery/**/*", "test/visual_audit/**/*")


def check_legacy_ui(report: Report) -> None:
    for path in sorted(g.ROOT.glob("test/**/goldens/*.png")):
        if not path.name.startswith("scr_"):
            report.error(path, "legacy golden (SP2): new goldens are named scr_<screen>__<state>__<variant>.png")
    for pattern in RETIRED_UI_HOMES:
        for path in sorted(g.ROOT.glob(pattern)):
            if path.is_file():
                report.error(path, "retired home (SP2): the legacy gallery and visual audits are gone")
```

Call `check_legacy_ui(report)` in `run()`, right after `check_retired_homes(report)`. Add to the module docstring's ERROR list: `- a legacy-named golden, or a file under lib/app/gallery/ or test/visual_audit/ (SP2)`.

- [ ] **Step 5: Run it to verify it passes; then expect the real tree to fail**

Run:
```bash
python3 -m unittest discover -s tools/docs -p 'test_*.py'
python3 tools/docs/check.py | tail -1
```
Expected:
- the tests print `OK`;
- `check.py` prints `FAIL — 526 error(s)`: the goldens are still there, which proves the guard bites.

- [ ] **Step 6: Delete the goldens and `integration_test/`**

Run:
```bash
git rm -rq integration_test
find test -path '*/goldens/*.png' -print0 | xargs -0 git rm -q
find test -type d -name goldens -empty -delete
python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1
```
Expected: `PASS — 0 error(s), …`.

- [ ] **Step 7: Gate and commit**

Run the gate. Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`. Expected: no golden test left, exit 0.

```bash
git add -A
git commit -m "chore(sp2): delete integration_test and the 526 legacy goldens; guard against their return" -m "<trailers>"
git push
```

---

### Task 6: Documents, guard and WBS

**Files:**
- Modify: `DESIGN.md`, `PRODUCT.md`, `docs/wbs_FE.md`, `docs/shared/testing/*` (only references to deleted test paths), and any live doc that `check.py` or the grep below finds naming a deleted path.

- [ ] **Step 1: DESIGN.md is canonical (S8)**

Under `# Design System: MemoX V8`, before `## Overview`, insert:
```markdown
This document is the canonical visual source of truth ([ADR-021](docs/shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md)).
Code implements it; it is never derived from code. SP2 (2026-10-04) removed the previous
implementation; SP3a rebuilds tokens, the Material 3 colour scheme, the light and dark themes,
primitives and the `Mx*` components from this document.
```
In `## Components`, replace `All widgets are \`Mx*\` in \`lib/shared/widgets/\`; they hold` with `All shared widgets are \`Mx*\` (rebuilt in \`lib/shared/widgets/\` by SP3a); they hold`.

Run `python3 tools/docs/check.py`. If the ADR link breaks because of where DESIGN.md sits at the repo root, use `docs/shared/decisions/ADR-021-…` exactly as CLAUDE.md links it.

- [ ] **Step 2: PRODUCT.md**

Replace `The visual system is recorded in \`DESIGN.md\`, generated from the Flutter UI base (ADR-021).` with:

`The visual system is defined in \`DESIGN.md\`, the canonical source the UI implements (ADR-021).`

In "Evidence on Hand":
- Replace the `DESIGN.md: …, generated from the code.` item with `- \`DESIGN.md\`: foundations, theme binding, the shared widgets and the copy voice — the source the rebuild implements.`
- Replace the goldens item with `- The 526 goldens of the V8 UI before the rebuild, recoverable at the git tag \`legacy-ui-v8-goldens\`.`

- [ ] **Step 3: Find every other live reference to a deleted path**

Run:
```bash
grep -rnE "lib/shared/widgets|lib/core/theme|lib/app/gallery|test/visual_audit|integration_test/|/presentation/(screens|widgets)|_golden_test|goldens/" \
  --include='*.md' --include='*.yaml' --include='*.sh' --include='*.py' . \
  | grep -v '^./docs/superpowers\|^./.impeccable\|^./.git/\|^./.superpowers\|^./.claude/skills/flutter-design-system\|^./.claude/skills/flutter-theme-design\|^./code-verification-guard-v2/registries'
```
For each hit in a live doc or script:
- point it at the new home (DESIGN.md, the screen spec, the IT scenario catalogue); or
- say the path was removed by SP2.

The guard registry is excluded: its rules keep their scopes for the rebuild (spec §6). The two design skills are out of scope (spec §3).

- [ ] **Step 4: CLAUDE.md note (spec §6)**

Do not edit CLAUDE.md. Ledger `Task 6: CLAUDE.md "Known UI debt" still names the UI-base register of the deleted UI; it stays as a record until SP3a defines the new register (spec §6)`, so the SP3a spec picks it up.

- [ ] **Step 5: WBS rows**

In `docs/wbs_FE.md`, add a section `## Rebuild (2026-10-04)` with four rows in the table format the file already uses:
- `SP2 | Gỡ UI cũ (spec 2026-10-04-sp2) | xong |`, evidence: the branch commits;
- `SP3a | Design-system foundation | chưa |`;
- `SP3b | App shell + SCR-DECK-001 | chưa |`;
- `SP3c | 33 màn còn lại | chưa |`.

- [ ] **Step 6: Guard, docs, gate, commit**

Run:
```bash
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 | tail -3
python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1
python3 tools/docs/check.py --ledger docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md | tail -1
```
Expected:
- `Code verification passed.`;
- two `PASS` lines.

Then run the gate.

```bash
git add -A
git commit -m "docs(sp2): DESIGN.md is the canonical source; references and WBS after the UI removal" -m "<trailers>"
git push
```

---

### Task 7: Final whole-branch review and report

- [ ] **Step 1: Build the review package**

Run: `bash .claude/skills/subagent-driven-development/scripts/review-package docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui.md ac57dc4 HEAD`

- [ ] **Step 2: Dispatch the final review on Opus**

Use `Agent` with `model: "opus"` and a description starting `Final whole-branch review`. Give it:
- the spec;
- this plan's Review Focus, verbatim;
- the matrix;
- the ledger's `Ruling:` lines.

Ask it to confirm, in particular:
1. no non-UI behaviour was deleted;
2. `domain/`, `data/` and `di/` are unchanged;
3. every catalog route resolves;
4. `/welcome` cannot trap a launch.

- [ ] **Step 3: One fix pass**

Re-grade the findings by effect.
- Fix every Critical and Important finding with a test that fails first, then the gate.
- Ledger each Minor as `Final: minor (deferred)`.

- [ ] **Step 4: Report to the owner**

Report:
- the matrix counts;
- what was deleted;
- the rulings, each with what it costs if wrong;
- the deferred minors.

The APK build is not run in the cloud container (spec §8). Ask the owner (AskUserQuestion) to:
- run `build-apk.yml`, or `flutter build apk` locally;
- choose to open the PR.
